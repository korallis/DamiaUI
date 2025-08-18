--[[
    DamiaUI - UnitFrames Main Controller
    oUF Layout Implementation with Centered Symmetrical Design
    
    This module serves as the main oUF layout controller implementing the classic
    Damia UI centered design philosophy with modern Aurora styling integration.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local CreateFrame = CreateFrame
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight

-- Module initialization
local UnitFrames = DamiaUI:NewModule("UnitFrames")

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora

-- Constants for the centered layout system
local FRAME_POSITIONS = {
    player = { x = -200, y = -80, width = 200, height = 50 },
    target = { x = 200, y = -80, width = 200, height = 50 },
    focus = { x = 0, y = -40, width = 160, height = 40, scale = 0.8 },
    party = { x = -400, y = 0, width = 180, height = 45, growth = "DOWN" },
    raid = { x = -500, y = 200, width = 160, height = 40, growth = "RIGHT" }
}

-- Frame references
local frames = {}

--[[ 
    Core positioning system for centered layout
    All frames are positioned relative to screen center (0,0)
]]
local function GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    -- Calculate actual center position accounting for UI scale
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    -- Apply offsets and return scaled coordinates
    return (centerX + offsetX) / uiScale, (centerY + offsetY) / uiScale
end

local function PositionFrame(frame, offsetX, offsetY)
    local x, y = GetCenterPosition(offsetX, offsetY)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

--[[
    Main oUF layout function implementing Damia UI design
    Creates the base frame structure with health, power, and text elements
]]
local function CreateDamiaLayout(self, unit, ...)
    -- Get frame configuration
    local config = FRAME_POSITIONS[unit] or FRAME_POSITIONS.player
    local scale = config.scale or 1.0
    
    -- Set frame dimensions and scale
    self:SetSize(config.width * scale, config.height * scale)
    self:SetScale(scale)
    
    -- Position frame using centered coordinate system
    PositionFrame(self, config.x, config.y)
    
    -- Create health bar with proper styling
    local health = CreateFrame("StatusBar", nil, self)
    health:SetHeight(20 * scale)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.2, 0.8, 0.2)
    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Create power bar positioned below health
    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(8 * scale)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -2)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -2)
    power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    power.bg = power:CreateTexture(nil, "BORDER")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    power.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Name text positioned on health bar
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 12 * scale, "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 4, 0)
    name:SetTextColor(1, 1, 1)
    name:SetJustifyH("LEFT")
    
    -- Health value text positioned on right side
    local healthValue = health:CreateFontString(nil, "OVERLAY")
    healthValue:SetFont("Fonts\\FRIZQT__.TTF", 11 * scale, "OUTLINE")
    healthValue:SetPoint("RIGHT", health, "RIGHT", -4, 0)
    healthValue:SetTextColor(1, 1, 1)
    healthValue:SetJustifyH("RIGHT")
    
    -- Power value text positioned on power bar
    local powerValue = power:CreateFontString(nil, "OVERLAY")
    powerValue:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
    powerValue:SetPoint("RIGHT", power, "RIGHT", -4, 0)
    powerValue:SetTextColor(1, 1, 1)
    powerValue:SetJustifyH("RIGHT")
    
    -- Level text for target frames
    if unit == "target" or unit == "focus" then
        local level = health:CreateFontString(nil, "OVERLAY")
        level:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
        level:SetPoint("TOPLEFT", health, "TOPLEFT", 4, 12)
        level:SetTextColor(1, 1, 0)
        self.Level = level
    end
    
    -- Register elements with oUF
    self.Health = health
    self.Health.bg = health.bg
    self.Power = power
    self.Power.bg = power.bg
    self.Name = name
    self.HealthValue = healthValue
    self.PowerValue = powerValue
    
    -- Add casting bar for target frame
    if unit == "target" then
        local castbar = CreateFrame("StatusBar", nil, self)
        castbar:SetHeight(16 * scale)
        castbar:SetPoint("TOPLEFT", power, "BOTTOMLEFT", 0, -4)
        castbar:SetPoint("TOPRIGHT", power, "BOTTOMRIGHT", 0, -4)
        castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar:SetStatusBarColor(1, 0.7, 0)
        castbar.bg = castbar:CreateTexture(nil, "BORDER")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        
        local castText = castbar:CreateFontString(nil, "OVERLAY")
        castText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
        castText:SetPoint("CENTER", castbar, "CENTER")
        castText:SetTextColor(1, 1, 1)
        
        castbar.Text = castText
        self.Castbar = castbar
    end
    
    -- Apply Aurora styling if available
    if Aurora and Aurora.CreateBorder then
        Aurora.CreateBorder(self, 8)
        if Aurora.Skin and Aurora.Skin.StatusBarWidget then
            Aurora.Skin.StatusBarWidget(health)
            Aurora.Skin.StatusBarWidget(power)
            if self.Castbar then
                Aurora.Skin.StatusBarWidget(self.Castbar)
            end
        end
    end
    
    -- Store frame reference
    frames[unit] = self
    
    return self
end

--[[
    Health update function with value formatting
]]
local function UpdateHealth(health, unit, min, max)
    if not min or not max then return end
    
    local frame = health.__owner
    if not frame or not frame.HealthValue then return end
    
    -- Format health values
    local healthText
    if max > 999999 then
        healthText = string.format("%.1fM", max / 1000000)
    elseif max > 999 then
        healthText = string.format("%.0fk", max / 1000)
    else
        healthText = tostring(max)
    end
    
    frame.HealthValue:SetText(healthText)
end

--[[
    Power update function with value formatting
]]
local function UpdatePower(power, unit, min, max, _, powerType)
    if not min or not max then return end
    
    local frame = power.__owner
    if not frame or not frame.PowerValue then return end
    
    -- Only show power value if significant
    if max > 0 then
        frame.PowerValue:SetText(tostring(max))
    else
        frame.PowerValue:SetText("")
    end
end

--[[
    Module initialization
]]
function UnitFrames:OnInitialize()
    -- Register the Damia layout with oUF
    oUF:RegisterStyle("Damia", CreateDamiaLayout)
    oUF:SetActiveStyle("Damia")
    
    -- Register custom tags for health and power display using the new tags system
    oUF.Tags.Events["healthvalue"] = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
    oUF.Tags.Events["powervalue"] = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}
    
    -- Create custom tags for health and power display
    oUF.Tags.Methods["healthvalue"] = function(unit)
        local min, max = UnitHealth(unit), UnitHealthMax(unit)
        if max > 999999 then
            return string.format("%.1fM", max / 1000000)
        elseif max > 999 then
            return string.format("%.0fk", max / 1000)
        else
            return tostring(max)
        end
    end
    
    oUF.Tags.Methods["powervalue"] = function(unit)
        local min, max = UnitPower(unit), UnitPowerMax(unit)
        return max > 0 and tostring(max) or ""
    end
end

function UnitFrames:OnEnable()
    -- Spawn the main unit frames
    self:SpawnFrames()
    
    -- Initialize contextual information filtering
    self:InitializeContextualFiltering()
    
    -- Register for configuration changes
    DamiaUI.Config.RegisterCallback("unitframes", function()
        self:RefreshAllFrames()
    end)
    
    -- Register for context changes
    if DamiaUI.Events then
        DamiaUI.Events:RegisterCustomEvent("DAMIA_CONTEXT_CHANGED", function(oldContext, newContext)
            self:OnContextChanged(oldContext, newContext)
        end, 2, "UnitFrames_ContextChanged")
        
        DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_START", function()
            self:OnCombatStateChanged(true)
        end, 2, "UnitFrames_CombatStart")
        
        DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_END", function()
            self:OnCombatStateChanged(false)
        end, 2, "UnitFrames_CombatEnd")
    end
end

--[[
    Spawn all unit frames using the Damia layout
]]
function UnitFrames:SpawnFrames()
    -- Spawn player frame
    local player = oUF:Spawn("player", "DamiaUIPlayerFrame")
    
    -- Spawn target frame
    local target = oUF:Spawn("target", "DamiaUITargetFrame")
    
    -- Spawn focus frame
    local focus = oUF:Spawn("focus", "DamiaUIFocusFrame")
    
    -- Hide default Blizzard frames
    PlayerFrame:Hide()
    PlayerFrame:UnregisterAllEvents()
    TargetFrame:Hide()
    TargetFrame:UnregisterAllEvents()
    FocusFrame:Hide()
    FocusFrame:UnregisterAllEvents()
end

--[[
    Refresh all frames when configuration changes
]]
function UnitFrames:RefreshAllFrames()
    for unit, frame in pairs(frames) do
        if frame and frame:IsShown() then
            local config = FRAME_POSITIONS[unit]
            if config then
                PositionFrame(frame, config.x, config.y)
                frame:SetScale(config.scale or 1.0)
            end
        end
    end
end

--[[
    Get frame reference by unit type
]]
function UnitFrames:GetFrame(unit)
    return frames[unit]
end

--[[
    Initialize contextual information filtering
]]
function UnitFrames:InitializeContextualFiltering()
    -- Information priority levels by context
    self.contextualPriorities = {
        SOLO = {
            high = { "health", "power", "casting", "target", "buffs" },
            medium = { "debuffs", "threat", "level" },
            low = { "group", "pvp", "classification" }
        },
        PARTY = {
            high = { "health", "power", "role", "group", "casting" },
            medium = { "buffs", "debuffs", "threat", "target" },
            low = { "level", "classification", "pvp" }
        },
        RAID = {
            high = { "health", "role", "group", "dispel", "range" },
            medium = { "debuffs", "buffs", "ready_check" },
            low = { "power", "level", "casting", "threat" }
        },
        ARENA = {
            high = { "health", "power", "casting", "trinket", "diminishing_returns" },
            medium = { "buffs", "debuffs", "spec", "interrupt_cd" },
            low = { "level", "group", "role" }
        },
        BATTLEGROUND = {
            high = { "health", "role", "group", "casting", "buffs" },
            medium = { "debuffs", "threat", "spec", "range" },
            low = { "level", "power", "classification" }
        }
    }
    
    -- Current context-based information filtering state
    self.currentFilter = {
        context = "SOLO",
        showAll = false,
        prioritizeImportant = true,
        combatMode = false
    }
    
    DamiaUI.Engine:LogDebug("Contextual information filtering initialized")
end

--[[
    Handle context changes and update information display
]]
function UnitFrames:OnContextChanged(oldContext, newContext)
    if not newContext or not newContext.typeName then return end
    
    local newContextType = newContext.typeName:upper()
    self.currentFilter.context = newContextType
    
    -- Update information display for all frames
    self:UpdateContextualInformation()
    
    -- Apply context-specific optimizations
    self:ApplyContextOptimizations(newContextType, newContext.memberCount)
    
    DamiaUI.Engine:LogInfo("Unit frames adapted to context: %s", newContextType)
end

--[[
    Handle combat state changes
]]
function UnitFrames:OnCombatStateChanged(inCombat)
    self.currentFilter.combatMode = inCombat
    
    if inCombat then
        -- In combat: prioritize critical information
        self:EnableCombatFiltering()
    else
        -- Out of combat: show more comprehensive information
        self:DisableCombatFiltering()
    end
    
    DamiaUI.Engine:LogDebug("Combat filtering %s", inCombat and "enabled" or "disabled")
end

--[[
    Update contextual information display for all frames
]]
function UnitFrames:UpdateContextualInformation()
    local context = self.currentFilter.context
    local priorities = self.contextualPriorities[context]
    
    if not priorities then return end
    
    -- Update each frame based on context priorities
    for unit, frame in pairs(frames) do
        if frame and frame:IsShown() then
            self:ApplyContextualFilter(frame, unit, priorities)
        end
    end
    
    -- Update group frames if they exist
    if DamiaUI.UnitFrames.Party then
        local partyFrames = DamiaUI.UnitFrames.Party.GetFrames()
        for i, frame in pairs(partyFrames) do
            if frame and frame:IsShown() then
                self:ApplyContextualFilter(frame, "party" .. i, priorities)
            end
        end
    end
    
    if DamiaUI.UnitFrames.Raid then
        local raidFrames = DamiaUI.UnitFrames.Raid.GetFrames()
        for i, frame in pairs(raidFrames) do
            if frame and frame:IsShown() then
                self:ApplyContextualFilter(frame, "raid" .. i, priorities)
            end
        end
    end
    
    if DamiaUI.UnitFrames.Arena then
        local arenaFrames = DamiaUI.UnitFrames.Arena.GetFrames()
        for i, frame in pairs(arenaFrames) do
            if frame and frame:IsShown() then
                self:ApplyContextualFilter(frame, "arena" .. i, priorities)
            end
        end
    end
end

--[[
    Apply contextual filtering to a specific frame
]]
function UnitFrames:ApplyContextualFilter(frame, unit, priorities)
    if not frame or not priorities then return end
    
    -- Show/hide elements based on priority levels
    local showHigh = true
    local showMedium = not self.currentFilter.combatMode or self.currentFilter.context == "SOLO"
    local showLow = not self.currentFilter.combatMode and not self.currentFilter.prioritizeImportant
    
    -- Apply visibility rules for different elements
    self:SetElementVisibility(frame, "buffs", showMedium and self:HasPriority("buffs", priorities))
    self:SetElementVisibility(frame, "debuffs", showHigh and self:HasPriority("debuffs", priorities))
    self:SetElementVisibility(frame, "casting", showHigh and self:HasPriority("casting", priorities))
    self:SetElementVisibility(frame, "threat", showMedium and self:HasPriority("threat", priorities))
    self:SetElementVisibility(frame, "role", showHigh and self:HasPriority("role", priorities))
    self:SetElementVisibility(frame, "level", showLow and self:HasPriority("level", priorities))
    self:SetElementVisibility(frame, "classification", showLow and self:HasPriority("classification", priorities))
end

--[[
    Check if an information type has priority in current context
]]
function UnitFrames:HasPriority(infoType, priorities)
    if not priorities then return false end
    
    for level, types in pairs(priorities) do
        for _, priorityType in ipairs(types) do
            if priorityType == infoType then
                return true
            end
        end
    end
    return false
end

--[[
    Set visibility of frame elements based on context
]]
function UnitFrames:SetElementVisibility(frame, elementType, shouldShow)
    if not frame then return end
    
    local element = nil
    
    -- Map element types to frame elements
    if elementType == "buffs" and frame.Buffs then
        element = frame.Buffs
    elseif elementType == "debuffs" and frame.Debuffs then
        element = frame.Debuffs
    elseif elementType == "casting" and frame.Castbar then
        element = frame.Castbar
    elseif elementType == "threat" and frame.ThreatIndicator then
        element = frame.ThreatIndicator
    elseif elementType == "role" and frame.GroupRoleIndicator then
        element = frame.GroupRoleIndicator
    elseif elementType == "level" and frame.Level then
        element = frame.Level
    elseif elementType == "classification" and frame.Classification then
        element = frame.Classification
    end
    
    if element then
        if shouldShow then
            element:SetAlpha(1)
        else
            element:SetAlpha(0.3) -- Fade instead of hide completely
        end
    end
end

--[[
    Enable combat-specific information filtering
]]
function UnitFrames:EnableCombatFiltering()
    -- In combat: hide less critical information, highlight important elements
    local combatPriorities = {
        high = { "health", "power", "casting", "debuffs", "threat", "role" },
        medium = { "buffs", "trinket", "diminishing_returns" },
        low = { "level", "classification", "group" }
    }
    
    self:ApplyFilterPriorities(combatPriorities)
end

--[[
    Disable combat-specific filtering
]]
function UnitFrames:DisableCombatFiltering()
    -- Out of combat: restore normal context-based priorities
    local context = self.currentFilter.context
    local priorities = self.contextualPriorities[context]
    
    if priorities then
        self:ApplyFilterPriorities(priorities)
    end
end

--[[
    Apply context-specific optimizations
]]
function UnitFrames:ApplyContextOptimizations(contextType, memberCount)
    -- Adjust update frequencies based on context
    local updateFrequency = 0.1 -- Default 100ms
    
    if contextType == "RAID" and memberCount > 20 then
        updateFrequency = 0.2 -- Slower updates for large raids
    elseif contextType == "ARENA" then
        updateFrequency = 0.05 -- Faster updates for arena
    elseif contextType == "SOLO" then
        updateFrequency = 0.15 -- Slightly slower for solo
    end
    
    -- Apply optimizations (placeholder for actual implementation)
    DamiaUI.Engine:LogDebug("Applied optimizations for %s context (update: %.2fs)", contextType, updateFrequency)
end

--[[
    Apply filter priorities to all frames
]]
function UnitFrames:ApplyFilterPriorities(priorities)
    for unit, frame in pairs(frames) do
        if frame and frame:IsShown() then
            self:ApplyContextualFilter(frame, unit, priorities)
        end
    end
end

--[[
    Get current contextual filter state
]]
function UnitFrames:GetContextualFilter()
    return self.currentFilter
end

--[[
    Set contextual filter configuration
]]
function UnitFrames:SetContextualFilter(key, value)
    if self.currentFilter[key] ~= nil then
        self.currentFilter[key] = value
        self:UpdateContextualInformation()
    end
end

-- Export module
DamiaUI.UnitFrames = UnitFrames