--[[
    DamiaUI DBM (Deadly Boss Mods) Integration Templates
    
    Pre-configured DBM templates with timer bar positions, warning text positions,
    and color schemes matching DamiaUI's centered layout philosophy.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Initialize DBM Templates module
local DBMTemplates = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.DBMTemplates = DBMTemplates

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type = type
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsAddOnLoaded = IsAddOnLoaded

-- DamiaUI positioning for DBM elements
local DBM_POSITIONS = {
    -- Timer bars
    timers = {
        primary = { x = 0, y = 300, anchor = "TOP", width = 220, height = 20 },
        secondary = { x = 0, y = 260, anchor = "TOP", width = 200, height = 18 }
    },
    
    -- Warning messages
    warnings = {
        special = { x = 0, y = 0, anchor = "CENTER", fontSize = 36 },
        announce = { x = 0, y = -50, anchor = "CENTER", fontSize = 24 },
        emphasize = { x = 0, y = 100, anchor = "CENTER", fontSize = 48 }
    },
    
    -- Raid warnings
    raidWarnings = {
        position = { x = 0, y = 150, anchor = "TOP" },
        fontSize = 30
    },
    
    -- Pull timer
    pullTimer = {
        position = { x = 0, y = -100, anchor = "CENTER" },
        fontSize = 40
    },
    
    -- Boss health frame
    bossHealth = {
        position = { x = -300, y = 300, anchor = "TOPRIGHT" },
        width = 200,
        height = 30
    },
    
    -- Info frame
    infoFrame = {
        position = { x = 300, y = 300, anchor = "TOPLEFT" },
        width = 150,
        height = 80
    }
}

-- DBM color scheme matching DamiaUI
local DBM_COLORS = {
    -- Timer bar colors
    timers = {
        regular = { r = 0.8, g = 0.5, b = 0.1 }, -- Damia orange
        cast = { r = 1.0, g = 0.2, b = 0.2 }, -- Red for casts
        cd = { r = 0.2, g = 0.8, b = 1.0 }, -- Blue for cooldowns
        next = { r = 1.0, g = 1.0, b = 0.2 }, -- Yellow for next abilities
        stage = { r = 0.8, g = 0.2, b = 0.8 }, -- Purple for stages
        user = { r = 0.2, g = 0.8, b = 0.2 } -- Green for user timers
    },
    
    -- Warning text colors
    warnings = {
        special = { r = 1.0, g = 0.0, b = 0.0 }, -- Red
        announce = { r = 1.0, g = 1.0, b = 0.0 }, -- Yellow
        emphasize = { r = 1.0, g = 0.6, b = 0.0 }, -- Orange
        normal = { r = 1.0, g = 1.0, b = 1.0 } -- White
    },
    
    -- Background colors
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }
}

-- DBM configuration templates
local DBM_CONFIGURATIONS = {
    -- Core DBM settings
    core = {
        -- Timer settings
        BarTexture = "Interface\\Buttons\\WHITE8X8",
        BarHeight = 20,
        BarWidth = 220,
        HugeBarsHeight = 22,
        HugeBarsWidth = 240,
        
        -- Font settings
        BarFont = "Fonts\\FRIZQT__.TTF",
        BarFontSize = 11,
        BarFontStyle = "OUTLINE",
        
        -- Timer positioning
        BarXOffset = 0,
        BarYOffset = 300,
        HugeBarXOffset = 0,
        HugeBarYOffset = 260,
        
        -- Background and border
        BarBackground = true,
        BarBackgroundTexture = "Interface\\Buttons\\WHITE8X8",
        BarBorder = true,
        BarBorderSize = 1,
        
        -- Animation
        BarSort = true,
        BarGrowUp = false,
        BarFillUp = true,
        BarClickThrough = false,
        
        -- Colors (will be set from DBM_COLORS)
        BarTextColorR = 1.0,
        BarTextColorG = 1.0,
        BarTextColorB = 1.0,
        
        -- Warning settings
        ShowWarningsInChat = true,
        ShowFakedRaidWarnings = false,
        WarningIconLeft = true,
        WarningIconRight = true,
        WarningIconChat = true,
        
        -- Pull timer
        PullTimerCountdown = true,
        PullTimerSound = true,
        
        -- Misc
        AutoRespond = false,
        StatusEnabled = true,
        DisableStatusWhisper = false,
        HideBlizzardEvents = true
    },
    
    -- Warning message settings
    warnings = {
        -- Special warnings
        SWarnNameInNote = true,
        SWarnClassColor = false,
        
        -- Font settings for warnings
        SpecialWarningFont = "Fonts\\FRIZQT__.TTF",
        SpecialWarningFontSize = 36,
        SpecialWarningFontStyle = "THICKOUTLINE",
        
        -- Position settings
        SpecialWarningX = 0,
        SpecialWarningY = 0,
        SpecialWarningPoint = "CENTER",
        
        -- Animation
        SpecialWarningFlash = true,
        SpecialWarningShake = true,
        SpecialWarningFlashCol1 = { 1, 1, 0, 0.3 },
        SpecialWarningFlashCol2 = { 1, 0, 0, 0.3 },
        SpecialWarningFlashDura1 = 0.4,
        SpecialWarningFlashDura2 = 1.1,
        
        -- Sound
        SpecialWarningSound = true,
        SpecialWarningVibrate = false
    },
    
    -- Raid warning settings
    raidWarnings = {
        RaidWarningSound = true,
        RaidWarningPosition = {
            Point = "TOP",
            X = 0,
            Y = 150
        }
    }
}

--[[
    Core Functions
]]

function DBMTemplates:Initialize()
    self.initialized = false
    
    -- Check if DBM is available
    if not self:IsDBMAvailable() then
        DamiaUI:LogDebug("DBM not available, templates disabled")
        return false
    end
    
    -- Setup DBM integration
    self:SetupDBMIntegration()
    
    self.initialized = true
    DamiaUI:LogDebug("DBM templates initialized")
    return true
end

function DBMTemplates:IsDBMAvailable()
    return IsAddOnLoaded("DBM-Core") and DBM ~= nil
end

function DBMTemplates:SetupDBMIntegration()
    -- Wait for DBM to be fully loaded
    if not DBM or not DBM.Options then
        C_Timer.After(2, function()
            self:SetupDBMIntegration()
        end)
        return
    end
    
    -- Hook into DBM events
    if DBM.RegisterCallback then
        DBM:RegisterCallback("DBM_AddonLoaded", self, "OnDBMLoaded")
        DBM:RegisterCallback("DBM_SetStage", self, "OnDBMStageSet") 
        DBM:RegisterCallback("DBM_TimerStart", self, "OnDBMTimerStart")
        DBM:RegisterCallback("DBM_TimerStop", self, "OnDBMTimerStop")
    end
    
    DamiaUI:LogDebug("DBM integration setup complete")
end

--[[
    Template Application
]]

function DBMTemplates:ApplyTemplate(templateName)
    if not self:IsDBMAvailable() then
        return false, "DBM not available"
    end
    
    templateName = templateName or "default"
    
    -- Check if user already has configured DBM (non-invasive)
    if self:HasExistingConfiguration() then
        DamiaUI:LogDebug("DBM already configured by user, skipping template application")
        return true, "User configuration detected, template not applied"
    end
    
    -- Apply core DBM settings
    local success = self:ApplyCoreSettings()
    if not success then
        return false, "Failed to apply core settings"
    end
    
    -- Apply timer bar settings
    success = self:ApplyTimerSettings()
    if not success then
        return false, "Failed to apply timer settings"
    end
    
    -- Apply warning settings
    success = self:ApplyWarningSettings()
    if not success then
        return false, "Failed to apply warning settings"
    end
    
    -- Apply color scheme
    success = self:ApplyDamiaUIColors()
    if not success then
        return false, "Failed to apply color scheme"
    end
    
    -- Mark configuration as DamiaUI template
    self:MarkAsDamiaUITemplate()
    
    DamiaUI:LogDebug("Applied DBM template: " .. templateName)
    return true, "Template applied successfully"
end

function DBMTemplates:HasExistingConfiguration()
    if not DBM or not DBM.Options then
        return false
    end
    
    -- Check if critical settings have been modified from defaults
    local defaultPositions = {
        BarXOffset = 0,
        BarYOffset = -120, -- DBM default
        SpecialWarningX = 0,
        SpecialWarningY = 75 -- DBM default
    }
    
    for setting, defaultValue in pairs(defaultPositions) do
        if DBM.Options[setting] and DBM.Options[setting] ~= defaultValue then
            -- User has customized positioning
            if not DBM.Options.DamiaUITemplate then
                return true
            end
        end
    end
    
    return false
end

function DBMTemplates:ApplyCoreSettings()
    if not DBM or not DBM.Options then
        return false
    end
    
    local coreConfig = DBM_CONFIGURATIONS.core
    
    for setting, value in pairs(coreConfig) do
        if DBM.Options[setting] ~= nil then
            DBM.Options[setting] = value
        end
    end
    
    return true
end

function DBMTemplates:ApplyTimerSettings()
    if not DBM or not DBM.Options or not DBM.Bars then
        return false
    end
    
    local timerPositions = DBM_POSITIONS.timers
    
    -- Primary timer bars
    DBM.Options.BarXOffset = timerPositions.primary.x
    DBM.Options.BarYOffset = timerPositions.primary.y  
    DBM.Options.BarWidth = timerPositions.primary.width
    DBM.Options.BarHeight = timerPositions.primary.height
    
    -- Secondary timer bars (huge bars)
    DBM.Options.HugeBarXOffset = timerPositions.secondary.x
    DBM.Options.HugeBarYOffset = timerPositions.secondary.y
    DBM.Options.HugeBarsWidth = timerPositions.secondary.width
    DBM.Options.HugeBarsHeight = timerPositions.secondary.height
    
    -- Apply bar styling
    DBM.Options.BarTexture = "Interface\\Buttons\\WHITE8X8"
    DBM.Options.BarFont = "Fonts\\FRIZQT__.TTF"
    DBM.Options.BarFontSize = 11
    DBM.Options.BarFontStyle = "OUTLINE"
    
    -- Position settings
    DBM.Options.BarPoint = timerPositions.primary.anchor
    DBM.Options.HugeBarPoint = timerPositions.secondary.anchor
    
    return true
end

function DBMTemplates:ApplyWarningSettings()
    if not DBM or not DBM.Options then
        return false
    end
    
    local warningConfig = DBM_CONFIGURATIONS.warnings
    local warningPositions = DBM_POSITIONS.warnings
    
    -- Apply warning configuration
    for setting, value in pairs(warningConfig) do
        if DBM.Options[setting] ~= nil then
            DBM.Options[setting] = value
        end
    end
    
    -- Special warning positioning
    DBM.Options.SpecialWarningX = warningPositions.special.x
    DBM.Options.SpecialWarningY = warningPositions.special.y
    DBM.Options.SpecialWarningPoint = warningPositions.special.anchor
    DBM.Options.SpecialWarningFontSize = warningPositions.special.fontSize
    
    -- Raid warning positioning
    if DBM.Options.RaidWarningPosition then
        DBM.Options.RaidWarningPosition.Point = DBM_POSITIONS.raidWarnings.position.anchor
        DBM.Options.RaidWarningPosition.X = DBM_POSITIONS.raidWarnings.position.x
        DBM.Options.RaidWarningPosition.Y = DBM_POSITIONS.raidWarnings.position.y
    end
    
    return true
end

function DBMTemplates:ApplyDamiaUIColors()
    if not DBM or not DBM.Options then
        return false
    end
    
    local colors = DBM_COLORS
    
    -- Timer bar colors
    if DBM.Options.DBMBarColor then
        DBM.Options.DBMBarColor = colors.timers.regular
    end
    
    -- Individual timer type colors
    if DBM.Options.TimerColors then
        DBM.Options.TimerColors = {
            [1] = colors.timers.regular, -- Regular timers
            [2] = colors.timers.cast, -- Cast bars
            [3] = colors.timers.cd, -- Cooldown timers
            [4] = colors.timers.next, -- Next ability
            [5] = colors.timers.stage, -- Stage timers
            [6] = colors.timers.user -- User timers
        }
    end
    
    -- Warning text colors
    DBM.Options.SpecialWarningFlashCol1 = { 1, 0.6, 0, 0.4 } -- Damia orange flash
    DBM.Options.SpecialWarningFlashCol2 = { 0.8, 0.5, 0.1, 0.4 } -- Darker orange flash
    
    return true
end

function DBMTemplates:MarkAsDamiaUITemplate()
    if not DBM or not DBM.Options then
        return false
    end
    
    -- Mark the configuration as managed by DamiaUI
    DBM.Options.DamiaUITemplate = true
    DBM.Options.DamiaUIVersion = DamiaUI.version
    
    return true
end

--[[
    Dynamic Positioning Based on UI Layout
]]

function DBMTemplates:UpdatePositionsForLayout(layout)
    if not self:IsDBMAvailable() then
        return false
    end
    
    layout = layout or DamiaUI.db.profile.resolution.layoutPreset or "classic"
    
    local adjustments = {
        classic = { x = 0, y = 0 },
        compact = { x = 0, y = -50 },
        wide = { x = 0, y = 50 },
        ultrawide = { x = 0, y = 100 }
    }
    
    local adjustment = adjustments[layout] or adjustments.classic
    
    -- Update timer positions
    if DBM.Options then
        DBM.Options.BarYOffset = DBM_POSITIONS.timers.primary.y + adjustment.y
        DBM.Options.HugeBarYOffset = DBM_POSITIONS.timers.secondary.y + adjustment.y
        DBM.Options.SpecialWarningY = DBM_POSITIONS.warnings.special.y + adjustment.y
    end
    
    DamiaUI:LogDebug("Updated DBM positions for layout: " .. layout)
    return true
end

--[[
    Event Handlers
]]

function DBMTemplates:OnDBMLoaded()
    -- DBM is fully loaded, apply any pending configurations
    if DBM.Options and DBM.Options.DamiaUITemplate then
        -- Refresh our template settings
        self:ApplyDamiaUIColors()
    end
    
    DamiaUI:LogDebug("DBM fully loaded")
end

function DBMTemplates:OnDBMStageSet(event, mod, stage)
    -- Handle stage changes if needed for dynamic positioning
    DamiaUI:LogDebug("DBM stage set: " .. tostring(stage))
end

function DBMTemplates:OnDBMTimerStart(event, id, msg, timer, icon, timerType, spellId, colorId)
    -- Handle timer start events if needed
    if DBM.Options and DBM.Options.DamiaUITemplate then
        -- Ensure proper styling is maintained
        self:ApplyTimerBarStyling(id)
    end
end

function DBMTemplates:OnDBMTimerStop(event, id)
    -- Handle timer stop events if needed
end

function DBMTemplates:ApplyTimerBarStyling(timerId)
    if not DBM or not DBM.Bars then
        return false
    end
    
    -- Apply DamiaUI styling to specific timer bar
    local bar = DBM.Bars:GetBar(timerId)
    if bar and bar.frame then
        -- Background texture (safer than SetBackdrop on Retail)
        if not bar.frame.damiaBackground then
            local bg = bar.frame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(bar.frame)
            bar.frame.damiaBackground = bg
        end
        bar.frame.damiaBackground:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar.frame.damiaBackground:SetVertexColor(
            DBM_COLORS.background.r,
            DBM_COLORS.background.g,
            DBM_COLORS.background.b,
            DBM_COLORS.background.a
        )

        -- Border frame with BackdropTemplate
        if not bar.frame.damiaBorder then
            local border = CreateFrame("Frame", nil, bar.frame, "BackdropTemplate")
            border:SetAllPoints(bar.frame)
            border:SetFrameLevel(bar.frame:GetFrameLevel() + 1)
            bar.frame.damiaBorder = border
        end
        bar.frame.damiaBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        bar.frame.damiaBorder:SetBackdropBorderColor(
            DBM_COLORS.border.r,
            DBM_COLORS.border.g,
            DBM_COLORS.border.b,
            DBM_COLORS.border.a
        )
    end
    
    return true
end

--[[
    Configuration Functions
]]

function DBMTemplates:CreateConfigurationPanel()
    if not self:IsDBMAvailable() then
        return nil
    end
    
    local panel = CreateFrame("Frame", "DamiaUIDBMTemplatesPanel")
    panel.name = "DBM Templates"  
    panel.parent = "DamiaUI"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("DBM Templates")
    
    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Pre-configured DBM positioning and styling optimized for DamiaUI")
    desc:SetWidth(600)
    desc:SetWordWrap(true)
    
    -- Apply template button
    local applyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    applyButton:SetPoint("TOPLEFT", 16, -80)
    applyButton:SetSize(180, 24)
    applyButton:SetText("Apply DamiaUI Template")
    
    applyButton:SetScript("OnClick", function()
        local success, message = self:ApplyTemplate("default")
        if success then
            DamiaUI:Print("DBM template applied successfully")
        else
            DamiaUI:Print("Failed to apply DBM template: " .. message)
        end
    end)
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", applyButton, "RIGHT", 8, 0)
    resetButton:SetSize(150, 24)
    resetButton:SetText("Reset to Defaults")
    
    resetButton:SetScript("OnClick", function()
        local success = self:ResetToDefaults()
        if success then
            DamiaUI:Print("DBM settings reset to defaults")
        else
            DamiaUI:Print("Failed to reset DBM settings")
        end
    end)
    
    -- Layout adjustment buttons
    local layoutLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    layoutLabel:SetPoint("TOPLEFT", 16, -130)
    layoutLabel:SetText("Layout Adjustments:")
    
    local layouts = { "classic", "compact", "wide", "ultrawide" }
    local xOffset = 16
    
    for _, layout in ipairs(layouts) do
        local layoutButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        layoutButton:SetPoint("TOPLEFT", xOffset, -150)
        layoutButton:SetSize(80, 20)
        layoutButton:SetText(layout:gsub("^%l", string.upper))
        
        layoutButton:SetScript("OnClick", function()
            local success = self:UpdatePositionsForLayout(layout)
            if success then
                DamiaUI:Print("DBM positions updated for " .. layout .. " layout")
            end
        end)
        
        xOffset = xOffset + 90
    end
    
    return panel
end

--[[
    Public API
]]

function DBMTemplates:GetCurrentConfiguration()
    if not self:IsDBMAvailable() then
        return nil
    end
    
    local config = {}
    
    if DBM.Options then
        config.timerPosition = {
            x = DBM.Options.BarXOffset or 0,
            y = DBM.Options.BarYOffset or 0,
            anchor = DBM.Options.BarPoint or "TOP"
        }
        
        config.warningPosition = {
            x = DBM.Options.SpecialWarningX or 0,
            y = DBM.Options.SpecialWarningY or 0,
            anchor = DBM.Options.SpecialWarningPoint or "CENTER"
        }
        
        config.isDamiaUITemplate = DBM.Options.DamiaUITemplate or false
    end
    
    return config
end

function DBMTemplates:ResetToDefaults()
    if not self:IsDBMAvailable() then
        return false
    end
    
    -- Remove DamiaUI template marker
    if DBM.Options then
        DBM.Options.DamiaUITemplate = nil
        DBM.Options.DamiaUIVersion = nil
        
        -- Reset to DBM defaults (these are typical DBM defaults)
        DBM.Options.BarXOffset = 0
        DBM.Options.BarYOffset = -120
        DBM.Options.SpecialWarningX = 0
        DBM.Options.SpecialWarningY = 75
        DBM.Options.BarPoint = "TOP"
        DBM.Options.SpecialWarningPoint = "CENTER"
        
        DamiaUI:LogDebug("DBM settings reset to defaults")
        return true
    end
    
    return false
end

function DBMTemplates:RefreshConfiguration()
    if not self:IsDBMAvailable() then
        return false
    end
    
    -- Refresh DBM display if needed
    if DBM.Options and DBM.Options.DamiaUITemplate then
        -- Reapply our template
        self:ApplyTemplate("default")
    end
    
    return true
end

-- Initialize when called
if DamiaUI.Integration then
    DamiaUI.Integration.DBMTemplates = DBMTemplates
end