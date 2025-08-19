--[[
    DamiaUI Embedded oUF Library
    
    A lightweight, flexible unit frame framework for World of Warcraft.
    This is a namespaced version embedded within DamiaUI to avoid conflicts
    with standalone oUF installations.
    
    Author: DamiaUI Development Team (Based on oUF by Haste)
    Version: 1.0.0
    Compatible with: WoW 11.2+
]]

local addonName = ...
local _G = _G
local pairs, ipairs, next = pairs, ipairs, next
local type, tostring, tonumber = type, tostring, tonumber
local format, gsub, match = string.format, string.gsub, string.match
local tinsert, tremove, twipe, tsort = table.insert, table.remove, table.wipe, table.sort
local CreateFrame, UIParent = CreateFrame, UIParent
local UnitExists, UnitGUID = UnitExists, UnitGUID
local GetTime, InCombatLockdown = GetTime, InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

-- LibStub integration with namespace isolation
local LibStub = LibStub or _G.LibStub
if not LibStub then
    error("DamiaUI_oUF requires LibStub")
end

-- Create the main oUF object with DamiaUI namespace
local oUF = {}
local version = 1

-- Register with LibStub using DamiaUI namespace
if LibStub then
    -- Check for existing oUF and version conflict resolution
    local existingLib = LibStub:GetLibrary("oUF", true)
    if existingLib and existingLib.version >= version then
        return existingLib
    end
    
    LibStub:NewLibrary("oUF", version)
    oUF = LibStub("oUF")
end

-- Constants and configuration
local ADDON_NAME = "DamiaUI_oUF"
local MAJOR_VERSION = "1.0"
local DEBUG_MODE = false

-- Core data structures
oUF.objects = {}           -- All spawned frames
oUF.headers = {}          -- Group headers
oUF.styles = {}           -- Registered styles
oUF.callbacks = {}        -- Event callbacks
oUF.elements = {}         -- Element handlers
oUF.colors = {}           -- Color tables

-- Current active style
oUF.activeStyle = nil

-- Version information
oUF.version = version
oUF.versionString = MAJOR_VERSION

-- Debug and logging functions removed
local function DebugPrint(...)
    -- Debug logging removed
end

local function ErrorPrint(...)
    -- Error logging removed
end

local function InfoPrint(...)
    -- Info logging removed
end

-- Utility functions
local function ValidateUnit(unit)
    return type(unit) == "string" and unit ~= ""
end

local function ValidateFrame(frame)
    return type(frame) == "table" and frame.GetObjectType and frame:GetObjectType() == "Frame"
end

--[[
    Core Element System
]]

-- Element update throttling system
local elementThrottle = {}
local throttleFrame = CreateFrame("Frame")
local throttleCurrent = 0
local throttleInterval = 0.1

throttleFrame:SetScript("OnUpdate", function(self, elapsed)
    throttleCurrent = throttleCurrent + elapsed
    if throttleCurrent >= throttleInterval then
        throttleCurrent = 0
        
        for element, data in pairs(elementThrottle) do
            if data.needsUpdate and (not data.lastUpdate or GetTime() - data.lastUpdate >= data.throttle) then
                data.needsUpdate = false
                data.lastUpdate = GetTime()
                
                if data.callback then
                    local success, err = pcall(data.callback, data.frame, data.unit, data.args)
                    if not success then
                        ErrorPrint("Element update error:", element, err)
                    end
                end
            end
        end
    end
end)

-- Register an element for throttled updates
local function ThrottleElement(frame, unit, element, callback, throttle, ...)
    local key = tostring(frame) .. "_" .. element
    elementThrottle[key] = {
        frame = frame,
        unit = unit,
        callback = callback,
        throttle = throttle or 0.1,
        needsUpdate = true,
        args = {...}
    }
end

-- Element registration system
function oUF:RegisterElement(name, update, enable, disable)
    if type(name) ~= "string" then
        ErrorPrint("Element name must be a string")
        return false
    end
    
    if type(update) ~= "function" then
        ErrorPrint("Element update function must be a function")
        return false
    end
    
    self.elements[name] = {
        update = update,
        enable = enable,
        disable = disable
    }
    
    DebugPrint("Registered element:", name)
    return true
end

-- Get registered element
function oUF:GetElement(name)
    return self.elements[name]
end

-- Enable element on a frame
function oUF:EnableElement(frame, element, unit)
    if not ValidateFrame(frame) or not ValidateUnit(unit) then
        return false
    end
    
    local elementData = self.elements[element]
    if not elementData then
        DebugPrint("Element not found:", element)
        return false
    end
    
    if elementData.enable then
        local success, err = pcall(elementData.enable, frame, unit)
        if not success then
            ErrorPrint("Failed to enable element", element, ":", err)
            return false
        end
    end
    
    -- Mark element as enabled
    frame.elementStates = frame.elementStates or {}
    frame.elementStates[element] = true
    
    DebugPrint("Enabled element", element, "for", unit)
    return true
end

-- Disable element on a frame
function oUF:DisableElement(frame, element, unit)
    if not ValidateFrame(frame) then
        return false
    end
    
    local elementData = self.elements[element]
    if not elementData then
        return false
    end
    
    if elementData.disable then
        local success, err = pcall(elementData.disable, frame, unit)
        if not success then
            ErrorPrint("Failed to disable element", element, ":", err)
            return false
        end
    end
    
    -- Mark element as disabled
    if frame.elementStates then
        frame.elementStates[element] = false
    end
    
    DebugPrint("Disabled element", element, "for", unit)
    return true
end

-- Update element
function oUF:UpdateElement(frame, element, unit, ...)
    if not ValidateFrame(frame) or not ValidateUnit(unit) then
        return false
    end
    
    local elementData = self.elements[element]
    if not elementData or not elementData.update then
        return false
    end
    
    -- Check if element is enabled
    if frame.elementStates and not frame.elementStates[element] then
        return false
    end
    
    local success, err = pcall(elementData.update, frame, unit, ...)
    if not success then
        ErrorPrint("Element update failed", element, ":", err)
        return false
    end
    
    return true
end

--[[
    Style System
]]

-- Register a new style
function oUF:RegisterStyle(name, func)
    if type(name) ~= "string" then
        ErrorPrint("Style name must be a string")
        return false
    end
    
    if type(func) ~= "function" then
        ErrorPrint("Style function must be a function")
        return false
    end
    
    self.styles[name] = func
    DebugPrint("Registered style:", name)
    return true
end

-- Set active style
function oUF:SetActiveStyle(name)
    if not self.styles[name] then
        ErrorPrint("Style not found:", name)
        return false
    end
    
    self.activeStyle = name
    DebugPrint("Active style set to:", name)
    return true
end

-- Get active style
function oUF:GetActiveStyle()
    return self.activeStyle
end

-- Get style function
function oUF:GetStyle(name)
    return self.styles[name or self.activeStyle]
end

--[[
    Frame Management System
]]

-- Initialize a new oUF frame
local function InitializeFrame(frame, unit, style)
    if not ValidateFrame(frame) or not ValidateUnit(unit) then
        return false
    end
    
    -- Set frame properties
    frame.unit = unit
    frame.style = style
    frame.elementStates = {}
    frame.__ouf = true
    
    -- Store reference to oUF
    frame.oUF = oUF
    
    -- Add frame methods
    frame.UpdateElement = function(self, element, ...)
        return oUF:UpdateElement(self, element, self.unit, ...)
    end
    
    frame.EnableElement = function(self, element)
        return oUF:EnableElement(self, element, self.unit)
    end
    
    frame.DisableElement = function(self, element)
        return oUF:DisableElement(self, element, self.unit)
    end
    
    -- Initialize frame with style
    local styleFunc = oUF:GetStyle(style)
    if styleFunc then
        local success, err = pcall(styleFunc, frame, unit)
        if not success then
            ErrorPrint("Style initialization failed:", err)
            return false
        end
    end
    
    -- Store in objects table
    oUF.objects[frame] = true
    
    return true
end

-- Spawn a single unit frame
function oUF:Spawn(unit, name, template)
    if not ValidateUnit(unit) then
        ErrorPrint("Invalid unit:", tostring(unit))
        return nil
    end
    
    if not self.activeStyle then
        ErrorPrint("No active style set")
        return nil
    end
    
    -- Create frame
    local frame = CreateFrame("Frame", name, UIParent, template)
    if not frame then
        ErrorPrint("Failed to create frame for unit:", unit)
        return nil
    end
    
    -- Initialize the frame
    if not InitializeFrame(frame, unit, self.activeStyle) then
        ErrorPrint("Failed to initialize frame for unit:", unit)
        frame:Hide()
        return nil
    end
    
    -- Set up event handling
    frame:SetScript("OnEvent", function(self, event, ...)
        oUF:OnEvent(self, event, ...)
    end)
    
    -- Register for essential events
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH") 
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("UNIT_LEVEL")
    
    -- Show the frame
    frame:Show()
    
    DebugPrint("Spawned frame for unit:", unit, "with style:", self.activeStyle)
    return frame
end

--[[
    Event Handling System
]]

-- Event dispatcher
function oUF:OnEvent(frame, event, ...)
    if not ValidateFrame(frame) or not event then
        return
    end
    
    local unit = ...
    if not unit or not ValidateUnit(unit) then
        return
    end
    
    -- Only process events for this frame's unit
    if frame.unit ~= unit then
        return
    end
    
    -- Dispatch to appropriate handlers
    if event == "UNIT_HEALTH" then
        self:UpdateElement(frame, "Health", unit)
    elseif event == "UNIT_MAXHEALTH" then
        self:UpdateElement(frame, "Health", unit)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        self:UpdateElement(frame, "Power", unit)
    elseif event == "UNIT_NAME_UPDATE" then
        self:UpdateElement(frame, "Name", unit)
    elseif event == "UNIT_LEVEL" then
        self:UpdateElement(frame, "Level", unit)
    end
    
    -- Fire custom callbacks if registered
    if self.callbacks[event] then
        for _, callback in ipairs(self.callbacks[event]) do
            local success, err = pcall(callback, frame, event, unit, ...)
            if not success then
                ErrorPrint("Event callback error:", event, err)
            end
        end
    end
end

-- Register event callback
function oUF:RegisterCallback(event, callback, priority)
    if type(event) ~= "string" or type(callback) ~= "function" then
        ErrorPrint("Invalid callback registration")
        return false
    end
    
    priority = priority or 5
    
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    
    tinsert(self.callbacks[event], {
        callback = callback,
        priority = priority
    })
    
    -- Sort by priority
    tsort(self.callbacks[event], function(a, b)
        return a.priority < b.priority
    end)
    
    return true
end

--[[
    Color System
]]

-- Default color tables
oUF.colors.class = {
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
    ["DRUID"]       = {1.00, 0.49, 0.04},
    ["EVOKER"]      = {0.20, 0.58, 0.50},
    ["HUNTER"]      = {0.67, 0.83, 0.45},
    ["MAGE"]        = {0.25, 0.78, 0.92},
    ["MONK"]        = {0.00, 1.00, 0.59},
    ["PALADIN"]     = {0.96, 0.55, 0.73},
    ["PRIEST"]      = {1.00, 1.00, 1.00},
    ["ROGUE"]       = {1.00, 0.96, 0.41},
    ["SHAMAN"]      = {0.00, 0.44, 0.87},
    ["WARLOCK"]     = {0.53, 0.53, 0.93},
    ["WARRIOR"]     = {0.78, 0.61, 0.43},
}

oUF.colors.power = {
    ["MANA"]         = {0.31, 0.45, 0.63},
    ["RAGE"]         = {0.69, 0.31, 0.31},
    ["FOCUS"]        = {0.71, 0.43, 0.27},
    ["ENERGY"]       = {0.65, 0.63, 0.35},
    ["RUNIC_POWER"]  = {0.00, 0.82, 1.00},
    ["SOUL_SHARDS"]  = {0.50, 0.32, 0.55},
    ["LUNAR_POWER"]  = {0.30, 0.52, 0.90},
    ["HOLY_POWER"]   = {0.95, 0.90, 0.60},
    ["MAELSTROM"]    = {0.00, 0.50, 1.00},
    ["INSANITY"]     = {0.40, 0.00, 0.80},
    ["CHI"]          = {0.71, 1.00, 0.92},
    ["ARCANE_CHARGES"] = {0.1, 0.1, 0.98},
    ["FURY"]         = {0.78, 0.26, 0.99},
    ["PAIN"]         = {1.00, 0.61, 0.00},
}

oUF.colors.reaction = {
    [1] = {0.78, 0.25, 0.25}, -- Hostile
    [2] = {0.78, 0.25, 0.25}, -- Hostile
    [3] = {0.75, 0.27, 0.00}, -- Unfriendly
    [4] = {0.80, 0.80, 0.00}, -- Neutral
    [5] = {0.00, 0.60, 0.10}, -- Friendly
    [6] = {0.00, 0.60, 0.10}, -- Friendly
    [7] = {0.00, 0.60, 0.10}, -- Friendly
    [8] = {0.00, 0.60, 0.10}, -- Friendly
}

oUF.colors.health = {0.25, 0.78, 0.25}

-- Get color for class
function oUF:GetClassColor(class)
    return self.colors.class[class] or {0.5, 0.5, 0.5}
end

-- Get color for power type
function oUF:GetPowerColor(powerType)
    return self.colors.power[powerType] or {0.5, 0.5, 0.5}
end

-- Get color for reaction
function oUF:GetReactionColor(reaction)
    return self.colors.reaction[reaction] or self.colors.health
end

--[[
    Utility Functions
]]

-- Format large numbers
function oUF:FormatNumber(number)
    if not number then return "0" end
    
    if number >= 1000000000 then
        return format("%.1fB", number / 1000000000)
    elseif number >= 1000000 then
        return format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return format("%.0fK", number / 1000)
    else
        return tostring(number)
    end
end

-- Format time duration
function oUF:FormatTime(seconds)
    if not seconds or seconds == 0 then
        return ""
    end
    
    if seconds < 60 then
        return format("%d", seconds)
    elseif seconds < 3600 then
        return format("%d:%02d", seconds / 60, seconds % 60)
    else
        return format("%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    end
end

-- Get unit classification text
function oUF:GetUnitClassification(unit)
    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        return "Boss"
    elseif classification == "rareelite" then
        return "Rare+"
    elseif classification == "elite" then
        return "+"
    elseif classification == "rare" then
        return "Rare"
    else
        return ""
    end
end

--[[
    Finalization
]]

-- Clean up function called on logout
local cleanup = CreateFrame("Frame")
cleanup:RegisterEvent("ADDON_LOADED")
cleanup:RegisterEvent("PLAYER_LOGOUT")
cleanup:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        DebugPrint("DamiaUI_oUF library loaded")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        -- Clean up references
        twipe(oUF.objects)
        twipe(oUF.headers)
        twipe(elementThrottle)
        DebugPrint("DamiaUI_oUF cleanup complete")
    end
end)

-- Export the library
_G.DamiaUI_oUF = oUF

-- Register with DamiaUI if available
if _G.DamiaUI and _G.DamiaUI.Libraries then
    _G.DamiaUI.Libraries.oUF = oUF
end

-- Return for LibStub
return oUF