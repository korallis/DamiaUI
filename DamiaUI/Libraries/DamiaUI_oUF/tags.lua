--[[
    DamiaUI oUF Tags System
    
    Provides flexible text formatting system for unit frame elements.
    Supports dynamic text generation using predefined tags and custom functions.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitName, UnitLevel = UnitName, UnitLevel
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitClass, UnitRace = UnitClass, UnitRace
local UnitClassification, UnitExists = UnitClassification, UnitExists
local UnitIsPlayer, UnitIsDeadOrGhost = UnitIsPlayer, UnitIsDeadOrGhost
local UnitIsConnected, UnitReaction = UnitIsConnected, UnitReaction
local format, gsub, match = string.format, string.gsub, string.match
local floor = math.floor

-- Initialize tags system
oUF.Tags = oUF.Tags or {}
oUF.Tags.Methods = oUF.Tags.Methods or {}
oUF.Tags.Events = oUF.Tags.Events or {}
oUF.Tags.SharedEvents = oUF.Tags.SharedEvents or {}

-- Pattern for finding tags in strings
local TAG_PATTERN = "%[([^%]]+)%]"

-- Cache for parsed tag strings
local tagCache = {}
local tagFrames = {}

--[[
    Core tag processing function
]]
local function ProcessTag(tag, unit)
    local method = oUF.Tags.Methods[tag]
    if method and type(method) == "function" then
        local success, result = pcall(method, unit)
        if success then
            return tostring(result or "")
        else
            return ""
        end
    end
    return "[" .. tag .. "]"  -- Return unprocessed if no method found
end

--[[
    Parse and process a tag string
]]
local function ProcessTagString(tagString, unit)
    if not tagString or tagString == "" then
        return ""
    end
    
    -- Replace all tags in the string
    local result = gsub(tagString, TAG_PATTERN, function(tag)
        return ProcessTag(tag, unit)
    end)
    
    return result
end

--[[
    Update text element with tags
]]
local function UpdateTagText(frame, unit, tagString, element)
    if not frame or not unit or not UnitExists(unit) or not element then
        return
    end
    
    local text = ProcessTagString(tagString, unit)
    element:SetText(text)
end

--[[
    Register events for a tag
]]
local function RegisterTagEvents(frame, tags)
    local events = {}
    
    -- Collect all events needed for the tags
    for tag in tagString:gmatch(TAG_PATTERN) do
        local tagEvents = oUF.Tags.Events[tag]
        if tagEvents then
            if type(tagEvents) == "string" then
                events[tagEvents] = true
            elseif type(tagEvents) == "table" then
                for _, event in ipairs(tagEvents) do
                    events[event] = true
                end
            end
        end
    end
    
    -- Register the events
    for event in pairs(events) do
        if not frame.tagEvents then
            frame.tagEvents = {}
        end
        if not frame.tagEvents[event] then
            frame:RegisterEvent(event)
            frame.tagEvents[event] = true
        end
    end
end

--[[
    Default tag methods
]]

-- Name tags
oUF.Tags.Methods["name"] = function(unit)
    return UnitName(unit) or ""
end

oUF.Tags.Methods["name:short"] = function(unit)
    local name = UnitName(unit)
    if name and #name > 12 then
        return name:sub(1, 10) .. ".."
    end
    return name or ""
end

-- Level tags  
oUF.Tags.Methods["level"] = function(unit)
    local level = UnitLevel(unit)
    return level and level > 0 and tostring(level) or "??"
end

oUF.Tags.Methods["level:short"] = function(unit)
    local level = UnitLevel(unit)
    if not level or level <= 0 then return "??" end
    
    local classification = UnitClassification(unit)
    local symbol = ""
    
    if classification == "worldboss" then
        symbol = "B"
    elseif classification == "rareelite" then
        symbol = "+"
    elseif classification == "elite" then
        symbol = "+"
    elseif classification == "rare" then
        symbol = "R"
    end
    
    return tostring(level) .. symbol
end

-- Health tags
oUF.Tags.Methods["hp"] = function(unit)
    return UnitHealth(unit) or 0
end

oUF.Tags.Methods["hp:short"] = function(unit)
    local health = UnitHealth(unit)
    return health and oUF:FormatNumber(health) or "0"
end

oUF.Tags.Methods["hp:max"] = function(unit)
    return UnitHealthMax(unit) or 0
end

oUF.Tags.Methods["hp:max-short"] = function(unit)
    local maxHealth = UnitHealthMax(unit)
    return maxHealth and oUF:FormatNumber(maxHealth) or "0"
end

oUF.Tags.Methods["hp:percent"] = function(unit)
    local current = UnitHealth(unit)
    local max = UnitHealthMax(unit)
    if not current or not max or max == 0 then return "0%" end
    return format("%.0f%%", (current / max) * 100)
end

oUF.Tags.Methods["hp:deficit"] = function(unit)
    local current = UnitHealth(unit)
    local max = UnitHealthMax(unit)
    if not current or not max then return "" end
    local deficit = max - current
    return deficit > 0 and ("-" .. oUF:FormatNumber(deficit)) or ""
end

-- Power tags
oUF.Tags.Methods["pp"] = function(unit)
    return UnitPower(unit) or 0
end

oUF.Tags.Methods["pp:short"] = function(unit)
    local power = UnitPower(unit)
    return power and oUF:FormatNumber(power) or "0"
end

oUF.Tags.Methods["pp:max"] = function(unit)
    return UnitPowerMax(unit) or 0
end

oUF.Tags.Methods["pp:max-short"] = function(unit)
    local maxPower = UnitPowerMax(unit)
    return maxPower and oUF:FormatNumber(maxPower) or "0"
end

oUF.Tags.Methods["pp:percent"] = function(unit)
    local current = UnitPower(unit)
    local max = UnitPowerMax(unit)
    if not current or not max or max == 0 then return "0%" end
    return format("%.0f%%", (current / max) * 100)
end

-- Class and race tags
oUF.Tags.Methods["class"] = function(unit)
    local _, class = UnitClass(unit)
    return class or ""
end

oUF.Tags.Methods["race"] = function(unit)
    local race = UnitRace(unit)
    return race or ""
end

-- Status tags
oUF.Tags.Methods["status"] = function(unit)
    if not UnitIsConnected(unit) then
        return "Offline"
    elseif UnitIsDeadOrGhost(unit) then
        return UnitIsGhost(unit) and "Ghost" or "Dead"
    end
    return ""
end

oUF.Tags.Methods["status:short"] = function(unit)
    if not UnitIsConnected(unit) then
        return "Off"
    elseif UnitIsDeadOrGhost(unit) then
        return UnitIsGhost(unit) and "G" or "D"
    end
    return ""
end

-- Classification tag
oUF.Tags.Methods["classification"] = function(unit)
    return oUF:GetUnitClassification(unit)
end

--[[
    Event mappings for tags
]]
oUF.Tags.Events["name"] = "UNIT_NAME_UPDATE"
oUF.Tags.Events["name:short"] = "UNIT_NAME_UPDATE"

oUF.Tags.Events["level"] = {"UNIT_LEVEL", "UNIT_CLASSIFICATION_CHANGED"}
oUF.Tags.Events["level:short"] = {"UNIT_LEVEL", "UNIT_CLASSIFICATION_CHANGED"}

oUF.Tags.Events["hp"] = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
oUF.Tags.Events["hp:short"] = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
oUF.Tags.Events["hp:max"] = "UNIT_MAXHEALTH"
oUF.Tags.Events["hp:max-short"] = "UNIT_MAXHEALTH"
oUF.Tags.Events["hp:percent"] = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
oUF.Tags.Events["hp:deficit"] = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}

oUF.Tags.Events["pp"] = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}
oUF.Tags.Events["pp:short"] = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}
oUF.Tags.Events["pp:max"] = "UNIT_MAXPOWER"
oUF.Tags.Events["pp:max-short"] = "UNIT_MAXPOWER"
oUF.Tags.Events["pp:percent"] = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}

oUF.Tags.Events["class"] = "UNIT_NAME_UPDATE"  -- Class doesn't change
oUF.Tags.Events["race"] = "UNIT_NAME_UPDATE"   -- Race doesn't change

oUF.Tags.Events["status"] = {"UNIT_HEALTH", "UNIT_CONNECTION"}
oUF.Tags.Events["status:short"] = {"UNIT_HEALTH", "UNIT_CONNECTION"}

oUF.Tags.Events["classification"] = "UNIT_CLASSIFICATION_CHANGED"

--[[
    Public API functions
]]

-- Register a new tag method
function oUF.Tags:Register(tag, method, events)
    if type(tag) ~= "string" or type(method) ~= "function" then
        return false
    end
    
    self.Methods[tag] = method
    
    if events then
        self.Events[tag] = events
    end
    
    return true
end

-- Create a tag string fontstring
function oUF:CreateTagString(parent, tagString, font, fontSize, fontFlags, justifyH)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    
    if font and fontSize then
        fontString:SetFont(font, fontSize, fontFlags)
    end
    
    if justifyH then
        fontString:SetJustifyH(justifyH)
    end
    
    -- Store the tag string for updates
    fontString.tagString = tagString
    
    return fontString
end

-- Update a tag string element
function oUF:UpdateTagString(frame, element, unit)
    if element.tagString then
        UpdateTagText(frame, unit, element.tagString, element)
    end
end

-- Process tag string directly
function oUF:ProcessTags(tagString, unit)
    return ProcessTagString(tagString, unit)
end