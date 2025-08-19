--[[
===============================================================================
Damia UI - Safe Mode Module
===============================================================================
Safe mode implementation providing minimal, stable functionality when critical
errors occur. Designed to ensure basic addon functionality even when major
components fail.

Features:
- Minimal UI functionality with only essential features
- Safe configuration management with fallback defaults
- Protected frame creation and management
- Emergency error recovery tools
- Basic user interface for error reporting and recovery
- Configuration reset and backup tools
- Safe module loading and initialization
- User communication and status reporting

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local GetTime = GetTime
local UIParent = UIParent
local GameTooltip = GameTooltip
local C_Timer = C_Timer
local table = table
local string = string
local math = math

-- Create SafeMode module
local SafeMode = {}
DamiaUI.SafeMode = SafeMode

-- Safe mode state
local safeModeState = {
    active = false,
    activatedAt = 0,
    activationReason = nil,
    fallbackFrame = nil,
    statusFrame = nil,
    emergencyTools = {},
    minimumFeatures = {},
    safeModeData = {}
}

-- Safe mode configuration
local safeModeConfig = {
    statusFramePosition = { x = 0, y = 200 },
    statusFrameSize = { width = 300, height = 60 },
    emergencyToolsPosition = { x = 0, y = 100 },
    autoHideDelay = 10, -- seconds
    blinkInterval = 1.0, -- seconds for status blinking
    maxSafeModeTime = 3600 -- 1 hour maximum in safe mode
}

-- Fallback default settings for essential functionality
local fallbackDefaults = {
    unitframes = {
        player = {
            enabled = true,
            position = { x = -200, y = -80 },
            scale = 1.0,
            width = 200,
            height = 50
        },
        target = {
            enabled = true,
            position = { x = 200, y = -80 },
            scale = 1.0,
            width = 200,
            height = 50
        }
    },
    actionbars = {
        mainbar = {
            enabled = true,
            position = { x = 0, y = -250 },
            buttonSize = 36,
            buttonSpacing = 4
        }
    },
    general = {
        autoScale = false,
        targetScale = 1.0,
        enableMovement = false,
        lockFrames = true
    }
}

--[[
===============================================================================
SAFE MODE ACTIVATION AND MANAGEMENT
===============================================================================
--]]

-- Activate safe mode with minimal functionality
function SafeMode:Activate(reason)
    if safeModeState.active then
        return true -- Already active
    end
    
    safeModeState.active = true
    safeModeState.activatedAt = GetTime()
    safeModeState.activationReason = reason or "Unknown critical error"
    
    -- Safe mode activation logging removed
    -- Safe mode reason logging removed
    
    -- Initialize safe mode components
    self:InitializeSafeModeFrames()
    self:LoadMinimalConfiguration()
    self:InitializeEmergencyTools()
    self:StartSafeModeMonitoring()
    
    -- Show status notification
    self:ShowSafeModeStatus()
    
    -- Log safe mode activation
    if DamiaUI.ErrorHandler then
        DamiaUI.ErrorHandler:ReportError(
            "Safe mode activated: " .. safeModeState.activationReason,
            DamiaUI.ErrorHandler.CATEGORY.INITIALIZATION,
            DamiaUI.ErrorHandler.SEVERITY.CRITICAL,
            "SafeMode"
        )
    end
    
    return true
end

-- Deactivate safe mode and return to normal operation
function SafeMode:Deactivate()
    if not safeModeState.active then
        return false
    end
    
    -- Safe mode deactivation logging removed
    
    -- Clean up safe mode components
    self:CleanupSafeModeFrames()
    self:StopSafeModeMonitoring()
    
    -- Reset state
    safeModeState.active = false
    safeModeState.activatedAt = 0
    safeModeState.activationReason = nil
    
    -- Log deactivation
    if DamiaUI.ErrorHandler then
        DamiaUI.ErrorHandler:LogInfo("Safe mode deactivated", "SafeMode")
    end
    
    return true
end

-- Check if safe mode is currently active
function SafeMode:IsActive()
    return safeModeState.active
end

-- Get safe mode status information
function SafeMode:GetStatus()
    return {
        active = safeModeState.active,
        activatedAt = safeModeState.activatedAt,
        activationReason = safeModeState.activationReason,
        duration = safeModeState.active and (GetTime() - safeModeState.activatedAt) or 0,
        hasEmergencyTools = #safeModeState.emergencyTools > 0
    }
end

--[[
===============================================================================
SAFE MODE FRAME MANAGEMENT
===============================================================================
--]]

-- Initialize essential safe mode frames
function SafeMode:InitializeSafeModeFrames()
    -- Create main status frame
    self:CreateStatusFrame()
    
    -- Create emergency tools panel
    self:CreateEmergencyToolsFrame()
    
    -- Initialize minimal UI elements
    self:InitializeMinimalUI()
    
    -- Safe mode frames initialization logging removed
end

-- Create status frame showing safe mode information
function SafeMode:CreateStatusFrame()
    if safeModeState.statusFrame then
        safeModeState.statusFrame:Show()
        return
    end
    
    local frame = CreateFrame("Frame", "DamiaUISafeModeStatus", UIParent)
    frame:SetSize(safeModeConfig.statusFrameSize.width, safeModeConfig.statusFrameSize.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 
                   safeModeConfig.statusFramePosition.x, 
                   safeModeConfig.statusFramePosition.y)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    
    -- Border
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(1.0, 0.2, 0.2, 1.0)
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("|cffff0000SAFE MODE ACTIVE|r")
    
    -- Reason text
    local reason = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reason:SetPoint("CENTER", frame, "CENTER", 0, -5)
    reason:SetText(string.format("|cffff8800%s|r", safeModeState.activationReason or "Unknown error"))
    reason:SetWordWrap(true)
    reason:SetJustifyH("CENTER")
    reason:SetWidth(safeModeConfig.statusFrameSize.width - 20)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Make frame moveable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    frame.title = title
    frame.reason = reason
    safeModeState.statusFrame = frame
    
    -- Auto-hide after delay
    C_Timer.After(safeModeConfig.autoHideDelay, function()
        if frame and frame:IsShown() then
            frame:Hide()
        end
    end)
end

-- Create emergency tools frame
function SafeMode:CreateEmergencyToolsFrame()
    local frame = CreateFrame("Frame", "DamiaUIEmergencyTools", UIParent)
    frame:SetSize(250, 150)
    frame:SetPoint("CENTER", UIParent, "CENTER",
                   safeModeConfig.emergencyToolsPosition.x,
                   safeModeConfig.emergencyToolsPosition.y)
    frame:Hide() -- Hidden by default
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("|cff00ccffEmergency Tools|r")
    
    -- Create emergency tool buttons
    local buttonHeight = 25
    local buttonSpacing = 5
    local startY = -40
    
    -- Reload UI button
    local reloadBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    reloadBtn:SetSize(200, buttonHeight)
    reloadBtn:SetPoint("TOP", frame, "TOP", 0, startY)
    reloadBtn:SetText("Reload UI")
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    -- Reset Configuration button
    local resetBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetBtn:SetSize(200, buttonHeight)
    resetBtn:SetPoint("TOP", reloadBtn, "BOTTOM", 0, -buttonSpacing)
    resetBtn:SetText("Reset Configuration")
    resetBtn:SetScript("OnClick", function()
        SafeMode:ResetConfiguration()
    end)
    
    -- Clear Error History button
    local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearBtn:SetSize(200, buttonHeight)
    clearBtn:SetPoint("TOP", resetBtn, "BOTTOM", 0, -buttonSpacing)
    clearBtn:SetText("Clear Error History")
    clearBtn:SetScript("OnClick", function()
        if DamiaUI.ErrorHandler then
            DamiaUI.ErrorHandler:ClearErrorHistory()
        end
        -- Error history cleared logging removed
    end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Make frame moveable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    safeModeState.emergencyToolsFrame = frame
end

-- Initialize minimal UI with basic functionality
function SafeMode:InitializeMinimalUI()
    -- Only initialize absolutely essential UI elements
    local essentialModules = { "Engine", "ErrorHandler", "SafeMode" }
    
    if DamiaUI.modules then
        for name, module in pairs(DamiaUI.modules) do
            local isEssential = false
            for _, essential in ipairs(essentialModules) do
                if name == essential then
                    isEssential = true
                    break
                end
            end
            
            if not isEssential and module.OnDisable then
                local success, err = pcall(module.OnDisable, module)
                if not success then
                    -- Module disable failure logging removed
                end
            end
        end
    end
    
    -- Initialize minimal configuration
    self:LoadMinimalConfiguration()
end

-- Clean up safe mode frames
function SafeMode:CleanupSafeModeFrames()
    if safeModeState.statusFrame then
        safeModeState.statusFrame:Hide()
        safeModeState.statusFrame = nil
    end
    
    if safeModeState.emergencyToolsFrame then
        safeModeState.emergencyToolsFrame:Hide()
        safeModeState.emergencyToolsFrame = nil
    end
    
    -- Clean up any fallback frames
    if safeModeState.fallbackFrame then
        safeModeState.fallbackFrame:Hide()
        safeModeState.fallbackFrame = nil
    end
end

--[[
===============================================================================
SAFE MODE CONFIGURATION MANAGEMENT
===============================================================================
--]]

-- Load minimal safe configuration
function SafeMode:LoadMinimalConfiguration()
    if not DamiaUI.Config then
        -- Create basic configuration fallback
        safeModeState.safeModeData = DamiaUI.Utils:CopyTable(fallbackDefaults)
        -- Fallback configuration logging removed
        return
    end
    
    -- Try to load safe defaults
    local success, result = pcall(function()
        -- Create minimal profile if needed
        local profiles = DamiaUI.Config:GetProfiles()
        local hasSafeProfile = false
        
        for _, profile in ipairs(profiles) do
            if profile == "SafeMode" then
                hasSafeProfile = true
                break
            end
        end
        
        if not hasSafeProfile then
            DamiaUI.Config:CreateProfile("SafeMode")
        end
        
        -- Switch to safe profile
        DamiaUI.Config:SetProfile("SafeMode")
        
        -- Apply safe settings
        for category, settings in pairs(fallbackDefaults) do
            for key, value in pairs(settings) do
                local configKey = category .. "." .. key
                DamiaUI.Config:Set(configKey, value)
            end
        end
        
        return true
    end)
    
    if success then
        -- Safe configuration loaded logging removed
    else
        -- Safe configuration load failure logging removed
        safeModeState.safeModeData = DamiaUI.Utils:CopyTable(fallbackDefaults)
    end
end

-- Reset configuration to safe defaults
function SafeMode:ResetConfiguration()
    if not DamiaUI.Config then
        -- Configuration module unavailable logging removed
        return false
    end
    
    local success, result = pcall(function()
        -- Create backup before reset
        DamiaUI.Config:CreateBackup("safe_mode_reset_" .. GetTime())
        
        -- Reset current profile
        DamiaUI.Config:ResetProfile()
        
        -- Apply safe defaults
        for category, settings in pairs(fallbackDefaults) do
            for key, value in pairs(settings) do
                local configKey = category .. "." .. key
                DamiaUI.Config:Set(configKey, value)
            end
        end
        
        return true
    end)
    
    if success then
        -- Configuration reset logging removed
        
        -- Ask user if they want to reload UI
        StaticPopup_Show("DAMIAUI_SAFE_RELOAD_CONFIRM")
        return true
    else
        -- Configuration reset failure logging removed
        return false
    end
end

-- Get safe configuration value
function SafeMode:GetSafeConfig(key, default)
    if DamiaUI.Config and not safeModeState.active then
        return DamiaUI.Config:Get(key, default)
    end
    
    -- Use safe mode data
    local keys = DamiaUI.Utils:Split(key, ".")
    local value = safeModeState.safeModeData or fallbackDefaults
    
    for _, k in ipairs(keys) do
        if type(value) == "table" and value[k] ~= nil then
            value = value[k]
        else
            return default
        end
    end
    
    return value
end

--[[
===============================================================================
EMERGENCY TOOLS AND RECOVERY
===============================================================================
--]]

-- Initialize emergency recovery tools
function SafeMode:InitializeEmergencyTools()
    -- Register emergency slash command
    if DamiaUI.Engine and DamiaUI.Engine.RegisterChatCommand then
        local success = pcall(DamiaUI.Engine.RegisterChatCommand, DamiaUI.Engine, "damiasafe", function(input)
            SafeMode:HandleEmergencyCommand(input)
        end)
        
        if success then
            table.insert(safeModeState.emergencyTools, "Emergency command: /damiasafe")
        end
    end
    
    -- Register emergency keybinding if possible
    if not InCombatLockdown() then
        local success = pcall(function()
            CreateFrame("Button", "DamiaUIEmergencyButton", UIParent)
            local btn = _G["DamiaUIEmergencyButton"]
            btn:RegisterForClicks("AnyUp")
            btn:SetScript("OnClick", function()
                SafeMode:ShowEmergencyTools()
            end)
            -- Hide the button but keep it functional
            btn:Hide()
            btn:SetAllPoints(UIParent)
            btn:EnableKeyboard(true)
        end)
        
        if success then
            table.insert(safeModeState.emergencyTools, "Emergency access available")
        end
    end
    
    -- Emergency tools initialization logging removed
end

-- Handle emergency slash commands
function SafeMode:HandleEmergencyCommand(input)
    if not input or input:trim() == "" then
        self:ShowEmergencyHelp()
        return
    end
    
    local command, args = input:match("^(%w+)%s*(.*)")
    command = (command or ""):lower()
    args = args or ""
    
    if command == "help" then
        self:ShowEmergencyHelp()
    elseif command == "show" or command == "tools" then
        self:ShowEmergencyTools()
    elseif command == "reload" then
        -- UI reload logging removed
        C_Timer.After(3, ReloadUI)
    elseif command == "reset" then
        self:ResetConfiguration()
    elseif command == "status" then
        self:ShowSafeModeStatus()
    elseif command == "deactivate" then
        if safeModeState.active then
            self:Deactivate()
            -- Safe mode deactivated logging removed
        else
            -- Safe mode status logging removed
        end
    elseif command == "errors" then
        self:ShowErrorSummary()
    else
        -- Unknown command logging removed
        self:ShowEmergencyHelp()
    end
end

-- Show emergency command help
function SafeMode:ShowEmergencyHelp()
    -- Emergency commands help logging removed
    -- Help command logging removed
    -- Show command logging removed
    -- Reload command logging removed
    -- Reset command logging removed
    -- Status command logging removed
    -- Deactivate command logging removed
    -- Errors command logging removed
end

-- Show emergency tools window
function SafeMode:ShowEmergencyTools()
    if safeModeState.emergencyToolsFrame then
        safeModeState.emergencyToolsFrame:Show()
    else
        self:CreateEmergencyToolsFrame()
        safeModeState.emergencyToolsFrame:Show()
    end
end

-- Show error summary
function SafeMode:ShowErrorSummary()
    if not DamiaUI.ErrorHandler then
        -- Error handler unavailable logging removed
        return
    end
    
    local stats = DamiaUI.ErrorHandler:GetErrorStatistics()
    local recentErrors = DamiaUI.ErrorHandler:GetRecentErrors(5)
    
    -- Error summary header logging removed
    -- Total errors logging removed
    -- Critical errors logging removed
    -- Safe mode status logging removed
    
    if #recentErrors > 0 then
        -- Recent errors header logging removed
        for i, error in ipairs(recentErrors) do
            local timeAgo = math.floor(GetTime() - error.timestamp)
            -- Individual error logging removed
        end
    end
end

--[[
===============================================================================
SAFE MODE STATUS AND MONITORING
===============================================================================
--]]

-- Show safe mode status
function SafeMode:ShowSafeModeStatus()
    if safeModeState.statusFrame then
        safeModeState.statusFrame:Show()
        
        -- Update status information
        local duration = GetTime() - safeModeState.activatedAt
        local durationText = string.format("Active for: %.0f seconds", duration)
        
        -- Update reason text to include duration
        if safeModeState.statusFrame.reason then
            safeModeState.statusFrame.reason:SetText(
                string.format("|cffff8800%s|r\n|cff888888%s|r", 
                             safeModeState.activationReason or "Unknown error",
                             durationText)
            )
        end
    else
        self:CreateStatusFrame()
    end
end

-- Start safe mode monitoring
function SafeMode:StartSafeModeMonitoring()
    -- Monitor safe mode duration
    local monitorFrame = CreateFrame("Frame")
    monitorFrame:SetScript("OnUpdate", function(self, elapsed)
        if not safeModeState.active then
            self:SetScript("OnUpdate", nil)
            return
        end
        
        local duration = GetTime() - safeModeState.activatedAt
        
        -- Auto-exit safe mode after maximum time
        if duration > safeModeConfig.maxSafeModeTime then
            -- Auto-exit logging removed
            SafeMode:Deactivate()
            return
        end
        
        -- Blink status frame if visible
        if safeModeState.statusFrame and safeModeState.statusFrame:IsShown() then
            local blinkTime = math.fmod(duration, safeModeConfig.blinkInterval * 2)
            local alpha = blinkTime < safeModeConfig.blinkInterval and 1.0 or 0.7
            safeModeState.statusFrame:SetAlpha(alpha)
        end
    end)
    
    safeModeState.monitorFrame = monitorFrame
end

-- Stop safe mode monitoring
function SafeMode:StopSafeModeMonitoring()
    if safeModeState.monitorFrame then
        safeModeState.monitorFrame:SetScript("OnUpdate", nil)
        safeModeState.monitorFrame = nil
    end
end

--[[
===============================================================================
STATIC POPUP DIALOGS
===============================================================================
--]]

-- Reload confirmation dialog
StaticPopupDialogs["DAMIAUI_SAFE_RELOAD_CONFIRM"] = {
    text = "Configuration has been reset to safe defaults.\n\nReload UI to apply changes?",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

--[[
===============================================================================
PUBLIC API AND INTEGRATION
===============================================================================
--]]

-- Register safe mode with error handler
if DamiaUI.ErrorHandler then
    -- Register recovery handlers for safe mode
    DamiaUI.ErrorHandler:RegisterRecoveryHandler("INIT", "SafeMode", {
        fallback = function(errorRecord, context)
            return SafeMode:Activate("Initialization failure: " .. errorRecord.message)
        end
    })
    
    DamiaUI.ErrorHandler:RegisterRecoveryHandler("CONFIG", "SafeMode", {
        reset = function(errorRecord, context)
            return SafeMode:ResetConfiguration()
        end,
        fallback = function(errorRecord, context)
            return SafeMode:LoadMinimalConfiguration()
        end
    })
end

-- Integration with main engine
function SafeMode:OnEnable()
    -- Safe mode is always enabled but inactive
    -- Safe mode ready logging removed
    return true
end

function SafeMode:OnDisable()
    -- Clean up if active
    if safeModeState.active then
        self:Deactivate()
    end
    return true
end

-- Get safe mode module info
function SafeMode:GetModuleInfo()
    return {
        name = "SafeMode",
        version = "1.0.0",
        description = "Emergency safe mode with minimal functionality",
        active = safeModeState.active,
        activationReason = safeModeState.activationReason,
        emergencyToolsCount = #safeModeState.emergencyTools
    }
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Initialize safe mode module
function SafeMode:Initialize()
    -- Safe mode module initialized logging removed
    
    -- Register with main engine if available
    if DamiaUI.RegisterModule then
        DamiaUI.RegisterModule("SafeMode", self)
    end
    
    return true
end

-- Auto-initialize
SafeMode:Initialize()

-- Export constants for external access
SafeMode.FALLBACK_DEFAULTS = fallbackDefaults