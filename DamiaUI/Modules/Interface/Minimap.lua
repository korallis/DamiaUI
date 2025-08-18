--[[
    DamiaUI - Minimap Interface Module
    
    Manages minimap positioning, scaling, and Aurora integration.
    Positions minimap at top-right following the viewport-first design philosophy.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Local references for performance
local _G = _G
local math = math
local pairs, ipairs = pairs, ipairs
local type, tonumber = type, tonumber
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local Minimap = Minimap
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight

-- Initialize minimap module
local MinimapModule = {}
DamiaUI.Interface = DamiaUI.Interface or {}
DamiaUI.Interface.Minimap = MinimapModule

-- Module state
local Aurora
local isInitialized = false
local hiddenElements = {}

-- Minimap configuration based on viewport-first design
local MINIMAP_CONFIG = {
    -- Position at top-right relative to screen center
    position = { x = 200, y = 200 },
    size = 140,
    scale = 1.0,
    shape = "square", -- "square", "round"
    
    elements = {
        showZoneText = true,
        showClock = true,
        showDifficulty = true,
        showTracking = true,
        showMail = true,
        showBattlefield = true
    },
    
    behavior = {
        zoomOnMouseWheel = true,
        hideBlizzardElements = true,
        lockPosition = false
    },
    
    combat = {
        fadeAlpha = 0.8,
        hideOnCombat = false
    }
}

-- Elements to hide when hideBlizzardElements is enabled
local BLIZZARD_ELEMENTS = {
    "MinimapBorderTop",
    "MinimapBorder", 
    "MiniMapWorldMapButton",
    "MinimapBackdrop",
    "MinimapCompassTexture",
    "MiniMapTracking",
    "MiniMapLFGFrame",
    "MinimapZoomIn",
    "MinimapZoomOut"
}

--[[
    Positioning System
    Following the centered viewport-first design
]]
local function GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    return (centerX + offsetX) / uiScale, (centerY + offsetY) / uiScale
end

local function PositionMinimap()
    if not Minimap or InCombatLockdown() then
        return
    end
    
    local config = MINIMAP_CONFIG
    local x, y = GetCenterPosition(config.position.x, config.position.y)
    
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    Minimap:SetSize(config.size, config.size)
    Minimap:SetScale(config.scale)
    
    -- Set movable properties if not locked
    if not config.behavior.lockPosition then
        Minimap:SetMovable(true)
        Minimap:SetUserPlaced(true)
        Minimap:SetClampedToScreen(true)
    end
end

--[[
    Minimap Shape and Masking
]]
local function SetMinimapShape()
    local config = MINIMAP_CONFIG
    
    if config.shape == "square" then
        Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
        Minimap:SetArchBlobRingScalar(0)
        Minimap:SetQuestBlobRingScalar(0)
    else -- round
        Minimap:SetMaskTexture("Interface\\Minimap\\UI-Minimap-Background")
        Minimap:SetArchBlobRingScalar(1)
        Minimap:SetQuestBlobRingScalar(1)
    end
end

--[[
    Element Management
]]
local function SetupZoneText()
    local config = MINIMAP_CONFIG.elements
    
    if MinimapZoneText then
        if config.showZoneText then
            MinimapZoneText:ClearAllPoints()
            MinimapZoneText:SetPoint("TOP", Minimap, "TOP", 0, 15)
            MinimapZoneText:SetJustifyH("CENTER")
            MinimapZoneText:Show()
            
            -- Apply Aurora styling
            if Aurora and Aurora.Skin and Aurora.Skin.FontStringWidget then
                Aurora.Skin.FontStringWidget(MinimapZoneText)
            end
        else
            MinimapZoneText:Hide()
        end
    end
end

local function SetupClock()
    local config = MINIMAP_CONFIG.elements
    
    if TimeManagerClockButton then
        if config.showClock then
            TimeManagerClockButton:ClearAllPoints()
            TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -15)
            TimeManagerClockButton:Show()
            
            -- Apply Aurora styling
            if Aurora and Aurora.Skin and Aurora.Skin.ButtonWidget then
                Aurora.Skin.ButtonWidget(TimeManagerClockButton)
            end
        else
            TimeManagerClockButton:Hide()
        end
    end
end

local function SetupDifficultyIndicator()
    local config = MINIMAP_CONFIG.elements
    
    if MiniMapInstanceDifficulty then
        if config.showDifficulty then
            MiniMapInstanceDifficulty:ClearAllPoints()
            MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
            MiniMapInstanceDifficulty:Show()
        else
            MiniMapInstanceDifficulty:Hide()
        end
    end
    
    if GuildInstanceDifficulty then
        if config.showDifficulty then
            GuildInstanceDifficulty:ClearAllPoints()
            GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -18)
            GuildInstanceDifficulty:Show()
        else
            GuildInstanceDifficulty:Hide()
        end
    end
end

local function SetupTrackingButton()
    local config = MINIMAP_CONFIG.elements
    
    if MiniMapTrackingButton then
        if config.showTracking then
            MiniMapTrackingButton:ClearAllPoints()
            MiniMapTrackingButton:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 2, 4)
            MiniMapTrackingButton:Show()
            
            -- Apply Aurora styling
            if Aurora and Aurora.Skin and Aurora.Skin.ButtonWidget then
                Aurora.Skin.ButtonWidget(MiniMapTrackingButton)
            end
        else
            MiniMapTrackingButton:Hide()
        end
    end
end

local function SetupMailIndicator()
    local config = MINIMAP_CONFIG.elements
    
    if MiniMapMailFrame then
        if config.showMail then
            MiniMapMailFrame:ClearAllPoints()
            MiniMapMailFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
            MiniMapMailFrame:Show()
        else
            MiniMapMailFrame:Hide()
        end
    end
end

local function SetupBattlefieldIndicator()
    local config = MINIMAP_CONFIG.elements
    
    if MiniMapBattlefieldFrame then
        if config.showBattlefield then
            MiniMapBattlefieldFrame:ClearAllPoints()
            MiniMapBattlefieldFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
            MiniMapBattlefieldFrame:Show()
        else
            MiniMapBattlefieldFrame:Hide()
        end
    end
end

local function HideBlizzardElements()
    if not MINIMAP_CONFIG.behavior.hideBlizzardElements then
        return
    end
    
    for _, elementName in ipairs(BLIZZARD_ELEMENTS) do
        local element = _G[elementName]
        if element then
            element:Hide()
            element:SetParent(CreateFrame("Frame"))
            hiddenElements[elementName] = element
        end
    end
end

local function SetupMouseWheelZoom()
    if not MINIMAP_CONFIG.behavior.zoomOnMouseWheel then
        return
    end
    
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
end

--[[
    Aurora Integration
]]
local function ApplyAuroraStyling()
    if not Aurora or not Aurora.Skin then
        return
    end
    
    -- Apply Aurora skin to minimap
    if Aurora.Skin.MinimapWidget then
        Aurora.Skin.MinimapWidget(Minimap)
    end
    
    -- Style minimap buttons
    local buttons = {
        MiniMapTrackingButton,
        TimeManagerClockButton,
        GameTimeFrame
    }
    
    for _, button in pairs(buttons) do
        if button and Aurora.Skin.ButtonWidget then
            Aurora.Skin.ButtonWidget(button)
        end
    end
end

--[[
    Combat State Management
]]
local function UpdateCombatVisibility(inCombat)
    local config = MINIMAP_CONFIG.combat
    
    if not Minimap then
        return
    end
    
    if inCombat and config.hideOnCombat then
        Minimap:Hide()
    elseif inCombat and config.fadeAlpha then
        Minimap:SetAlpha(config.fadeAlpha)
    else
        Minimap:Show()
        Minimap:SetAlpha(1.0)
    end
end

--[[
    Configuration Management
]]
function MinimapModule:UpdateConfiguration(newConfig)
    if type(newConfig) ~= "table" then
        return
    end
    
    -- Merge configuration
    for key, value in pairs(newConfig) do
        if MINIMAP_CONFIG[key] then
            if type(value) == "table" and type(MINIMAP_CONFIG[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    MINIMAP_CONFIG[key][subKey] = subValue
                end
            else
                MINIMAP_CONFIG[key] = value
            end
        end
    end
    
    -- Reapply configuration
    self:Refresh()
end

function MinimapModule:GetConfiguration()
    return MINIMAP_CONFIG
end

--[[
    Public API
]]
function MinimapModule:Initialize()
    if isInitialized or not Minimap then
        return true
    end
    
    -- Get Aurora library
    Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora
    
    -- Setup minimap position and size
    PositionMinimap()
    
    -- Set minimap shape
    SetMinimapShape()
    
    -- Setup elements
    SetupZoneText()
    SetupClock()
    SetupDifficultyIndicator()
    SetupTrackingButton()
    SetupMailIndicator()
    SetupBattlefieldIndicator()
    
    -- Hide unwanted Blizzard elements
    HideBlizzardElements()
    
    -- Setup mouse wheel zoom
    SetupMouseWheelZoom()
    
    -- Apply Aurora styling
    ApplyAuroraStyling()
    
    isInitialized = true
    DamiaUI:LogDebug("Minimap module initialized")
    return true
end

function MinimapModule:Refresh()
    if not isInitialized then
        return
    end
    
    PositionMinimap()
    SetMinimapShape()
    
    -- Refresh all elements
    SetupZoneText()
    SetupClock()
    SetupDifficultyIndicator()
    SetupTrackingButton()
    SetupMailIndicator()
    SetupBattlefieldIndicator()
    
    ApplyAuroraStyling()
end

function MinimapModule:UpdatePosition()
    PositionMinimap()
end

function MinimapModule:SetCombatState(inCombat)
    UpdateCombatVisibility(inCombat)
end

function MinimapModule:SetShape(shape)
    if shape and (shape == "square" or shape == "round") then
        MINIMAP_CONFIG.shape = shape
        SetMinimapShape()
    end
end

function MinimapModule:SetSize(size)
    if type(size) == "number" and size > 50 and size < 300 then
        MINIMAP_CONFIG.size = size
        PositionMinimap()
    end
end

function MinimapModule:ToggleElement(elementName, show)
    if MINIMAP_CONFIG.elements[elementName] ~= nil then
        MINIMAP_CONFIG.elements[elementName] = show
        
        -- Refresh specific element
        if elementName == "showZoneText" then
            SetupZoneText()
        elseif elementName == "showClock" then
            SetupClock()
        elseif elementName == "showDifficulty" then
            SetupDifficultyIndicator()
        elseif elementName == "showTracking" then
            SetupTrackingButton()
        elseif elementName == "showMail" then
            SetupMailIndicator()
        elseif elementName == "showBattlefield" then
            SetupBattlefieldIndicator()
        end
    end
end

--[[
    Event Handlers
]]
local function OnMinimapEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        MinimapModule:SetCombatState(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        MinimapModule:SetCombatState(false)
    elseif event == "UI_SCALE_CHANGED" then
        C_Timer.After(0.1, function()
            MinimapModule:UpdatePosition()
        end)
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        SetupZoneText()
    elseif event == "UPDATE_INSTANCE_INFO" then
        SetupDifficultyIndicator()
    end
end

-- Register events if DamiaUI event system is available
if DamiaUI and DamiaUI.Events then
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        MinimapModule:Initialize()
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^interface%.minimap%.") then
            local configPart = key:match("interface%.minimap%.(.+)")
            if configPart then
                MinimapModule:UpdateConfiguration({[configPart] = newValue})
            end
        end
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", function(event, inCombat)
        MinimapModule:SetCombatState(inCombat)
    end, 2)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_SCALE_CHANGED", function()
        MinimapModule:UpdatePosition()
    end, 2)
end

-- Fallback event registration
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") 
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
eventFrame:SetScript("OnEvent", OnMinimapEvent)

-- Initialize on load if DamiaUI is ready
if DamiaUI and DamiaUI.IsReady then
    C_Timer.After(1, function()
        MinimapModule:Initialize()
    end)
end

return MinimapModule