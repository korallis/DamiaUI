--[[
===============================================================================
Damia UI - Comprehensive Error Handler
===============================================================================
Advanced error handling system providing error classification, automatic recovery,
safe mode activation, and resilient addon operation. Designed to handle all types
of errors gracefully and provide recovery options.

Features:
- Error classification by severity and category
- Automatic recovery mechanisms and fallback options
- Safe mode activation for critical errors
- Configuration corruption detection and repair
- Context-aware error logging with stack traces
- User-friendly error reporting and recovery dialogs
- Integration with existing modules for seamless error handling
- Performance monitoring for error patterns

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring, tonumber = type, tostring, tonumber
local pcall, xpcall = pcall, xpcall
local error, assert = error, assert
local GetTime = GetTime
local debugstack = debugstack
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local StaticPopup_Show = StaticPopup_Show
local table = table
local string = string
local math = math

-- Create ErrorHandler module
local ErrorHandler = {}
DamiaUI.ErrorHandler = ErrorHandler

-- Error severity levels (lower number = higher severity)
local SEVERITY = {
    CRITICAL = 1,    -- Addon cannot function, must enter safe mode
    HIGH = 2,        -- Major feature failure, needs immediate attention
    MEDIUM = 3,      -- Module failure, can continue with reduced functionality
    LOW = 4,         -- Minor issues, warnings, performance concerns
    INFO = 5         -- Informational messages, debugging
}

-- Error categories for classification
local CATEGORY = {
    INITIALIZATION = "INIT",
    CONFIGURATION = "CONFIG", 
    COMBAT = "COMBAT",
    EVENT_HANDLING = "EVENT",
    FRAME_MANAGEMENT = "FRAME",
    MODULE_LOADING = "MODULE",
    MEMORY = "MEMORY",
    PERFORMANCE = "PERF",
    EXTERNAL = "EXTERNAL",
    UNKNOWN = "UNKNOWN"
}

-- Recovery strategies
local RECOVERY = {
    NONE = "NONE",              -- No automatic recovery
    RETRY = "RETRY",            -- Retry the failed operation
    FALLBACK = "FALLBACK",      -- Use fallback implementation
    RESET = "RESET",            -- Reset component to defaults
    DISABLE = "DISABLE",        -- Disable the failing component
    SAFE_MODE = "SAFE_MODE",    -- Enter safe mode
    RELOAD_UI = "RELOAD_UI"     -- Reload the entire UI
}

-- Error handling configuration
local config = {
    maxErrorsPerSession = 100,
    maxErrorsPerMinute = 20,
    maxRecoveryAttempts = 3,
    errorReportingEnabled = true,
    autoRecoveryEnabled = true,
    safeModeThreshold = 5,      -- Critical errors before safe mode
    logRetentionDays = 7,
    performanceThresholdMs = 50 -- Log slow operations
}

-- Error state tracking
local errorState = {
    totalErrors = 0,
    criticalErrors = 0,
    errorsByCategory = {},
    errorsByModule = {},
    recentErrors = {},
    suppressedErrors = {},
    recoveryAttempts = {},
    lastErrorTime = 0,
    safeModeActive = false,
    errorLogBuffer = {},
    performanceIssues = {}
}

-- Recovery handlers registry
local recoveryHandlers = {}

-- Error suppression patterns
local suppressionPatterns = {
    ["attempt to index a nil value"] = { duration = 60, maxOccurrences = 5 },
    ["Interface action failed because of an AddOn"] = { duration = 30, maxOccurrences = 3 }
}

--[[
===============================================================================
ERROR CLASSIFICATION AND SEVERITY ASSESSMENT
===============================================================================
--]]

-- Classify error by analyzing error message and context
local function ClassifyError(errorMsg, stackTrace, context)
    if not errorMsg then
        return CATEGORY.UNKNOWN, SEVERITY.LOW
    end
    
    local msg = string.lower(errorMsg)
    local category = CATEGORY.UNKNOWN
    local severity = SEVERITY.MEDIUM
    
    -- Configuration related errors
    if msg:find("config") or msg:find("setting") or msg:find("profile") or msg:find("database") then
        category = CATEGORY.CONFIGURATION
        if msg:find("corrupt") or msg:find("invalid") or msg:find("missing") then
            severity = SEVERITY.HIGH
        end
    
    -- Combat related errors
    elseif msg:find("combat") or msg:find("protected") or msg:find("taint") then
        category = CATEGORY.COMBAT
        severity = SEVERITY.MEDIUM
    
    -- Event handling errors
    elseif msg:find("event") or msg:find("callback") or msg:find("handler") then
        category = CATEGORY.EVENT_HANDLING
        if msg:find("infinite") or msg:find("recursion") then
            severity = SEVERITY.HIGH
        end
    
    -- Frame and UI errors
    elseif msg:find("frame") or msg:find("texture") or msg:find("ui") or msg:find("widget") then
        category = CATEGORY.FRAME_MANAGEMENT
        if msg:find("nil") and msg:find("index") then
            severity = SEVERITY.HIGH
        end
    
    -- Module loading errors
    elseif msg:find("module") or msg:find("addon") or msg:find("library") then
        category = CATEGORY.MODULE_LOADING
        if msg:find("failed to load") or msg:find("not found") then
            severity = SEVERITY.HIGH
        end
    
    -- Memory related errors
    elseif msg:find("memory") or msg:find("out of") or msg:find("allocation") then
        category = CATEGORY.MEMORY
        severity = SEVERITY.CRITICAL
    
    -- Performance issues
    elseif msg:find("timeout") or msg:find("slow") or msg:find("performance") then
        category = CATEGORY.PERFORMANCE
        severity = SEVERITY.LOW
    
    -- External addon conflicts
    elseif msg:find("taint") or msg:find("blocked") or context and context.external then
        category = CATEGORY.EXTERNAL
        severity = SEVERITY.MEDIUM
    
    -- Initialization errors
    elseif msg:find("init") or msg:find("startup") or msg:find("load") then
        category = CATEGORY.INITIALIZATION
        severity = SEVERITY.HIGH
    end
    
    -- Increase severity for critical patterns
    if msg:find("critical") or msg:find("fatal") or msg:find("crash") then
        severity = math.min(severity, SEVERITY.CRITICAL)
    elseif msg:find("nil") and msg:find("attempt to") then
        severity = math.min(severity, SEVERITY.HIGH)
    end
    
    -- Context-based adjustments
    if context then
        if context.module == "Engine" or context.module == "Config" then
            severity = math.max(1, severity - 1) -- Increase severity for core modules
        end
        
        if context.inCombat then
            severity = math.min(severity, SEVERITY.MEDIUM) -- Cap severity during combat
        end
        
        if context.isRecovery then
            severity = math.max(1, severity - 1) -- Recovery failures are more serious
        end
    end
    
    return category, severity
end

-- Determine appropriate recovery strategy based on error classification
local function DetermineRecoveryStrategy(category, severity, errorMsg, context)
    -- Critical errors require safe mode or UI reload
    if severity == SEVERITY.CRITICAL then
        if category == CATEGORY.MEMORY then
            return RECOVERY.RELOAD_UI
        else
            return RECOVERY.SAFE_MODE
        end
    end
    
    -- High severity errors need aggressive recovery
    if severity == SEVERITY.HIGH then
        if category == CATEGORY.CONFIGURATION then
            return RECOVERY.RESET
        elseif category == CATEGORY.MODULE_LOADING then
            return RECOVERY.DISABLE
        elseif category == CATEGORY.INITIALIZATION then
            return RECOVERY.RETRY
        else
            return RECOVERY.FALLBACK
        end
    end
    
    -- Medium severity can often use fallbacks
    if severity == SEVERITY.MEDIUM then
        if category == CATEGORY.COMBAT then
            return RECOVERY.NONE -- Don't interfere during combat
        elseif category == CATEGORY.EVENT_HANDLING then
            return RECOVERY.RETRY
        else
            return RECOVERY.FALLBACK
        end
    end
    
    -- Low severity errors just get logged
    return RECOVERY.NONE
end

--[[
===============================================================================
ERROR LOGGING AND CONTEXT CAPTURE
===============================================================================
--]]

-- Create detailed error context
local function CaptureErrorContext(level)
    level = level or 3 -- Skip this function and calling function
    
    local context = {
        timestamp = GetTime(),
        stackTrace = debugstack(level, 10, 10), -- 10 levels, 10 lines each
        gameState = {
            inCombat = InCombatLockdown and InCombatLockdown() or false,
            playerExists = UnitExists and UnitExists("player") or false,
            mapID = C_Map and C_Map.GetCurrentMapID and C_Map.GetCurrentMapID() or nil,
            instanceType = IsInInstance and select(2, IsInInstance()) or "none"
        },
        addonState = {
            initialized = DamiaUI.Engine and DamiaUI.Engine.isInitialized or false,
            moduleCount = DamiaUI.modules and DamiaUI.Utils:GetTableSize(DamiaUI.modules) or 0,
            safeModeActive = errorState.safeModeActive
        },
        performance = {
            fps = GetFramerate and GetFramerate() or 0,
            memory = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or 0,
            cpuTime = GetAddOnCPUUsage and GetAddOnCPUUsage(addonName) or 0
        },
        sessionStats = {
            totalErrors = errorState.totalErrors,
            criticalErrors = errorState.criticalErrors,
            uptime = GetTime() - (DamiaUI.startTime or GetTime())
        }
    }
    
    return context
end

-- Enhanced error logging with full context
local function LogError(severity, category, errorMsg, context, module)
    local currentTime = GetTime()
    
    -- Rate limiting check
    if currentTime - errorState.lastErrorTime < 0.1 then
        local recentCount = 0
        for i = #errorState.recentErrors, 1, -1 do
            local recentError = errorState.recentErrors[i]
            if currentTime - recentError.timestamp > 60 then
                break
            end
            recentCount = recentCount + 1
        end
        
        if recentCount >= config.maxErrorsPerMinute then
            return false -- Rate limit exceeded
        end
    end
    
    errorState.lastErrorTime = currentTime
    
    -- Update error statistics
    errorState.totalErrors = errorState.totalErrors + 1
    if severity == SEVERITY.CRITICAL then
        errorState.criticalErrors = errorState.criticalErrors + 1
    end
    
    errorState.errorsByCategory[category] = (errorState.errorsByCategory[category] or 0) + 1
    if module then
        errorState.errorsByModule[module] = (errorState.errorsByModule[module] or 0) + 1
    end
    
    -- Create detailed error record
    local errorRecord = {
        id = errorState.totalErrors,
        timestamp = currentTime,
        severity = severity,
        category = category,
        message = errorMsg,
        module = module,
        context = context,
        suppressed = false,
        recoveryAttempted = false,
        recoveryStrategy = RECOVERY.NONE
    }
    
    -- Add to recent errors buffer
    table.insert(errorState.recentErrors, errorRecord)
    if #errorState.recentErrors > 50 then
        table.remove(errorState.recentErrors, 1)
    end
    
    -- Add to persistent log buffer
    table.insert(errorState.errorLogBuffer, errorRecord)
    if #errorState.errorLogBuffer > config.maxErrorsPerSession then
        table.remove(errorState.errorLogBuffer, 1)
    end
    
    -- Console logging with color coding
    local severityColors = {
        [SEVERITY.CRITICAL] = "|cffff0000", -- Red
        [SEVERITY.HIGH] = "|cffff8800",     -- Orange
        [SEVERITY.MEDIUM] = "|cffffff00",   -- Yellow  
        [SEVERITY.LOW] = "|cff88ff88",      -- Light green
        [SEVERITY.INFO] = "|cff88ccff"      -- Light blue
    }
    
    local severityNames = {
        [SEVERITY.CRITICAL] = "CRITICAL",
        [SEVERITY.HIGH] = "HIGH",
        [SEVERITY.MEDIUM] = "MEDIUM",
        [SEVERITY.LOW] = "LOW", 
        [SEVERITY.INFO] = "INFO"
    }
    
    local color = severityColors[severity] or "|cffffffff"
    local severityName = severityNames[severity] or "UNKNOWN"
    
    local logMsg = string.format("%s[%s %s/%s]|r %s", 
                                color, addonName, severityName, category, errorMsg)
    
    if module then
        logMsg = logMsg .. " (" .. module .. ")"
    end
    
    print(logMsg)
    
    -- Additional context for high severity errors
    if severity <= SEVERITY.HIGH and context then
        if context.stackTrace then
            print("|cff666666Stack trace:|r")
            local lines = DamiaUI.Utils:Split(context.stackTrace, "\n")
            for i = 1, math.min(#lines, 5) do
                if lines[i] and lines[i]:trim() ~= "" then
                    print("|cff666666  " .. lines[i]:trim() .. "|r")
                end
            end
        end
        
        if context.gameState then
            print(string.format("|cff666666Context: Combat=%s, Instance=%s, Memory=%.1fKB|r",
                               tostring(context.gameState.inCombat),
                               context.gameState.instanceType or "unknown",
                               (context.performance.memory or 0)))
        end
    end
    
    return true
end

-- Check if error should be suppressed based on patterns
local function ShouldSuppressError(errorMsg)
    if not errorMsg then return false end
    
    local currentTime = GetTime()
    
    for pattern, suppression in pairs(suppressionPatterns) do
        if errorMsg:find(pattern) then
            local suppressionKey = "pattern_" .. pattern
            local suppressionData = errorState.suppressedErrors[suppressionKey]
            
            if not suppressionData then
                suppressionData = { count = 0, firstOccurrence = currentTime, lastOccurrence = 0 }
                errorState.suppressedErrors[suppressionKey] = suppressionData
            end
            
            -- Check if suppression period has expired
            if currentTime - suppressionData.firstOccurrence > suppression.duration then
                -- Reset suppression
                suppressionData.count = 0
                suppressionData.firstOccurrence = currentTime
            end
            
            if suppressionData.count >= suppression.maxOccurrences then
                suppressionData.lastOccurrence = currentTime
                return true
            else
                suppressionData.count = suppressionData.count + 1
                suppressionData.lastOccurrence = currentTime
            end
        end
    end
    
    return false
end

--[[
===============================================================================
RECOVERY MECHANISM IMPLEMENTATION
===============================================================================
--]]

-- Register recovery handler for specific error categories/modules
function ErrorHandler:RegisterRecoveryHandler(category, module, handler)
    if not category or not handler then
        return false
    end
    
    local key = category .. (module and (":" .. module) or "")
    recoveryHandlers[key] = handler
    
    return true
end

-- Attempt automatic recovery based on strategy
local function AttemptRecovery(errorRecord)
    if not config.autoRecoveryEnabled then
        return false
    end
    
    local recoveryKey = errorRecord.category .. ":" .. (errorRecord.module or "unknown")
    local attempts = errorState.recoveryAttempts[recoveryKey] or 0
    
    -- Check recovery attempt limits
    if attempts >= config.maxRecoveryAttempts then
        return false
    end
    
    errorState.recoveryAttempts[recoveryKey] = attempts + 1
    errorRecord.recoveryAttempted = true
    
    -- Determine recovery strategy
    local strategy = DetermineRecoveryStrategy(
        errorRecord.category,
        errorRecord.severity, 
        errorRecord.message,
        errorRecord.context
    )
    
    errorRecord.recoveryStrategy = strategy
    
    -- Execute recovery based on strategy
    local success = false
    local context = { module = errorRecord.module, isRecovery = true }
    
    if strategy == RECOVERY.RETRY then
        success = ErrorHandler:ExecuteRetryRecovery(errorRecord, context)
    elseif strategy == RECOVERY.FALLBACK then
        success = ErrorHandler:ExecuteFallbackRecovery(errorRecord, context)
    elseif strategy == RECOVERY.RESET then
        success = ErrorHandler:ExecuteResetRecovery(errorRecord, context)
    elseif strategy == RECOVERY.DISABLE then
        success = ErrorHandler:ExecuteDisableRecovery(errorRecord, context)
    elseif strategy == RECOVERY.SAFE_MODE then
        success = ErrorHandler:ActivateSafeMode(errorRecord.message)
    elseif strategy == RECOVERY.RELOAD_UI then
        ErrorHandler:ScheduleUIReload("Critical error recovery")
        success = true
    end
    
    if success then
        print(string.format("|cff00ff00[%s] Recovery successful using %s strategy|r", 
                           addonName, strategy))
    else
        print(string.format("|cffff8800[%s] Recovery failed for %s strategy|r", 
                           addonName, strategy))
    end
    
    return success
end

-- Retry recovery strategy
function ErrorHandler:ExecuteRetryRecovery(errorRecord, context)
    local handler = recoveryHandlers[errorRecord.category .. ":" .. (errorRecord.module or "")]
    if handler and handler.retry then
        local success, result = pcall(handler.retry, errorRecord, context)
        return success and result ~= false
    end
    
    -- Default retry: attempt to re-initialize the failing module
    if errorRecord.module and DamiaUI.modules and DamiaUI.modules[errorRecord.module] then
        local module = DamiaUI.modules[errorRecord.module]
        if module.OnEnable then
            local success, result = pcall(module.OnEnable, module)
            return success
        end
    end
    
    return false
end

-- Fallback recovery strategy
function ErrorHandler:ExecuteFallbackRecovery(errorRecord, context)
    local handler = recoveryHandlers[errorRecord.category .. ":" .. (errorRecord.module or "")]
    if handler and handler.fallback then
        local success, result = pcall(handler.fallback, errorRecord, context)
        return success and result ~= false
    end
    
    -- Default fallback based on category
    if errorRecord.category == CATEGORY.CONFIGURATION then
        -- Use default configuration values
        if DamiaUI.Config then
            local success = pcall(DamiaUI.Config.ResetProfile, DamiaUI.Config)
            return success
        end
    elseif errorRecord.category == CATEGORY.FRAME_MANAGEMENT then
        -- Hide problematic frames
        if errorRecord.context and errorRecord.context.frame then
            local success = pcall(errorRecord.context.frame.Hide, errorRecord.context.frame)
            return success
        end
    end
    
    return false
end

-- Reset recovery strategy
function ErrorHandler:ExecuteResetRecovery(errorRecord, context)
    local handler = recoveryHandlers[errorRecord.category .. ":" .. (errorRecord.module or "")]
    if handler and handler.reset then
        local success, result = pcall(handler.reset, errorRecord, context)
        return success and result ~= false
    end
    
    -- Default reset based on category
    if errorRecord.category == CATEGORY.CONFIGURATION then
        if DamiaUI.Config then
            DamiaUI.Config:CreateBackup("pre_error_reset_" .. GetTime())
            local success = pcall(DamiaUI.Config.ResetProfile, DamiaUI.Config)
            return success
        end
    elseif errorRecord.module and DamiaUI.modules and DamiaUI.modules[errorRecord.module] then
        -- Reset module to default state
        local module = DamiaUI.modules[errorRecord.module]
        if module.Reset then
            local success = pcall(module.Reset, module)
            return success
        end
    end
    
    return false
end

-- Disable recovery strategy
function ErrorHandler:ExecuteDisableRecovery(errorRecord, context)
    local handler = recoveryHandlers[errorRecord.category .. ":" .. (errorRecord.module or "")]
    if handler and handler.disable then
        local success, result = pcall(handler.disable, errorRecord, context)
        return success and result ~= false
    end
    
    -- Default disable: disable the failing module
    if errorRecord.module and DamiaUI.modules and DamiaUI.modules[errorRecord.module] then
        local module = DamiaUI.modules[errorRecord.module]
        if module.OnDisable then
            local success = pcall(module.OnDisable, module)
            if success then
                print(string.format("|cffffff00[%s] Module '%s' has been disabled due to errors|r", 
                                   addonName, errorRecord.module))
                return true
            end
        end
    end
    
    return false
end

--[[
===============================================================================
SAFE MODE ACTIVATION
===============================================================================
--]]

-- Activate safe mode with minimal functionality
function ErrorHandler:ActivateSafeMode(reason)
    if errorState.safeModeActive then
        return true -- Already in safe mode
    end
    
    print(string.format("|cffff0000[%s] ACTIVATING SAFE MODE|r", addonName))
    print(string.format("|cffff8800Reason: %s|r", reason or "Critical errors detected"))
    
    errorState.safeModeActive = true
    
    -- Disable all non-critical modules
    if DamiaUI.modules then
        for name, module in pairs(DamiaUI.modules) do
            if name ~= "Engine" and name ~= "ErrorHandler" and name ~= "SafeMode" then
                if module.OnDisable then
                    pcall(module.OnDisable, module)
                end
            end
        end
    end
    
    -- Activate safe mode module if available
    if DamiaUI.SafeMode then
        local success = pcall(DamiaUI.SafeMode.Activate, DamiaUI.SafeMode, reason)
        if not success then
            print("|cffff0000[" .. addonName .. "] Failed to activate safe mode module|r")
        end
    end
    
    -- Fire safe mode event
    if DamiaUI.Events then
        pcall(DamiaUI.Events.Fire, DamiaUI.Events, "DAMIA_SAFE_MODE_ACTIVATED", reason)
    end
    
    -- Show user notification
    ErrorHandler:ShowSafeModeDialog(reason)
    
    return true
end

-- Deactivate safe mode and attempt normal operation
function ErrorHandler:DeactivateSafeMode()
    if not errorState.safeModeActive then
        return false
    end
    
    print(string.format("|cff00ff00[%s] Deactivating safe mode|r", addonName))
    
    errorState.safeModeActive = false
    
    -- Clear error counters
    errorState.criticalErrors = 0
    errorState.recoveryAttempts = {}
    
    -- Reactivate safe mode module if available
    if DamiaUI.SafeMode then
        pcall(DamiaUI.SafeMode.Deactivate, DamiaUI.SafeMode)
    end
    
    -- Re-enable modules
    if DamiaUI.Engine and DamiaUI.Engine.EnableModules then
        pcall(DamiaUI.Engine.EnableModules, DamiaUI.Engine)
    end
    
    -- Fire safe mode deactivated event
    if DamiaUI.Events then
        pcall(DamiaUI.Events.Fire, DamiaUI.Events, "DAMIA_SAFE_MODE_DEACTIVATED")
    end
    
    return true
end

-- Check if safe mode should be activated
local function CheckSafeModeThreshold()
    if errorState.criticalErrors >= config.safeModeThreshold then
        ErrorHandler:ActivateSafeMode("Critical error threshold exceeded")
        return true
    end
    return false
end

--[[
===============================================================================
USER INTERFACE AND REPORTING
===============================================================================
--]]

-- Show safe mode notification dialog
function ErrorHandler:ShowSafeModeDialog(reason)
    if not StaticPopup_Show then return end
    
    if not StaticPopupDialogs["DAMIAUI_SAFE_MODE"] then
        StaticPopupDialogs["DAMIAUI_SAFE_MODE"] = {
            text = "DamiaUI has entered Safe Mode due to critical errors.\n\n" ..
                   "Reason: %s\n\n" ..
                   "Only essential functionality is available. You can:\n" ..
                   "• Continue in Safe Mode\n" ..
                   "• Try to recover (may cause more errors)\n" ..
                   "• Reload UI to reset everything",
            button1 = "Continue in Safe Mode",
            button2 = "Try Recovery",
            button3 = "Reload UI",
            OnAccept = function()
                print("|cff00ccff[" .. addonName .. "] Continuing in safe mode|r")
            end,
            OnCancel = function()
                ErrorHandler:DeactivateSafeMode()
            end,
            OnAlt = function()
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = false,
            preferredIndex = 3
        }
    end
    
    StaticPopup_Show("DAMIAUI_SAFE_MODE", reason or "Unknown error")
end

-- Show error report dialog
function ErrorHandler:ShowErrorReportDialog(errorRecord)
    if not StaticPopup_Show or not config.errorReportingEnabled then 
        return 
    end
    
    if errorRecord.severity > SEVERITY.HIGH then
        return -- Only show for high severity errors
    end
    
    if not StaticPopupDialogs["DAMIAUI_ERROR_REPORT"] then
        StaticPopupDialogs["DAMIAUI_ERROR_REPORT"] = {
            text = "DamiaUI Error Detected:\n\n%s\n\nWould you like to attempt automatic recovery?",
            button1 = "Yes, Try Recovery",
            button2 = "No, Continue",
            button3 = "Report & Disable",
            OnAccept = function(self, errorRecord)
                AttemptRecovery(errorRecord)
            end,
            OnCancel = function()
                -- Continue without recovery
            end,
            OnAlt = function(self, errorRecord)
                ErrorHandler:ExecuteDisableRecovery(errorRecord, {})
            end,
            timeout = 15,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
    end
    
    StaticPopup_Show("DAMIAUI_ERROR_REPORT", errorRecord.message, nil, errorRecord)
end

-- Schedule UI reload with notification
function ErrorHandler:ScheduleUIReload(reason)
    print(string.format("|cffff0000[%s] Scheduling UI reload in 3 seconds|r", addonName))
    print(string.format("|cffff8800Reason: %s|r", reason or "Error recovery"))
    
    C_Timer.After(3, function()
        ReloadUI()
    end)
end

--[[
===============================================================================
CONFIGURATION CORRUPTION DETECTION AND REPAIR
===============================================================================
--]]

-- Detect and repair configuration corruption
function ErrorHandler:ValidateAndRepairConfiguration()
    if not DamiaUI.Config then
        return false, "Configuration module not available"
    end
    
    local issues = {}
    
    -- Check database integrity
    local database = DamiaUI.Config:GetDatabase()
    if not database then
        table.insert(issues, "Database is missing or corrupted")
    else
        -- Validate database structure
        if not database.profiles or type(database.profiles) ~= "table" then
            table.insert(issues, "Profile data is corrupted")
        end
        
        if not database.global or type(database.global) ~= "table" then
            table.insert(issues, "Global settings are corrupted")
        end
        
        -- Validate current profile
        local currentProfile = DamiaUI.Config:GetCurrentProfile()
        if not database.profiles[currentProfile] then
            table.insert(issues, "Current profile is missing or corrupted")
        end
    end
    
    -- Attempt repairs
    local repaired = {}
    
    for _, issue in ipairs(issues) do
        local success = false
        
        if issue:find("Database is missing") then
            -- Reinitialize database
            success = pcall(DamiaUI.Config.Initialize, DamiaUI.Config)
            if success then
                table.insert(repaired, "Database reinitialized")
            end
        elseif issue:find("Profile data is corrupted") then
            -- Reset profiles to defaults
            if database then
                database.profiles = { ["Default"] = DamiaUI.Config.CreateDefaultProfile() }
                success = true
                table.insert(repaired, "Profiles reset to defaults")
            end
        elseif issue:find("Global settings are corrupted") then
            -- Reset global settings
            if database then
                database.global = {
                    minimap = { hide = false, minimapPos = 220 },
                    firstInstall = GetTime(),
                    migrations = {},
                    backups = {}
                }
                success = true
                table.insert(repaired, "Global settings restored")
            end
        elseif issue:find("Current profile is missing") then
            -- Create default profile
            success = pcall(DamiaUI.Config.CreateProfile, DamiaUI.Config, "Default")
            if success then
                pcall(DamiaUI.Config.SetProfile, DamiaUI.Config, "Default")
                table.insert(repaired, "Default profile recreated")
            end
        end
    end
    
    local hasIssues = #issues > 0
    local hasRepairs = #repaired > 0
    
    if hasIssues then
        LogError(SEVERITY.HIGH, CATEGORY.CONFIGURATION,
                string.format("Configuration issues detected: %s", table.concat(issues, ", ")),
                CaptureErrorContext(), "Config")
    end
    
    if hasRepairs then
        LogError(SEVERITY.INFO, CATEGORY.CONFIGURATION,
                string.format("Configuration repairs completed: %s", table.concat(repaired, ", ")),
                CaptureErrorContext(), "Config")
    end
    
    return hasRepairs, issues, repaired
end

--[[
===============================================================================
PUBLIC API FUNCTIONS
===============================================================================
--]]

-- Main error handling function - replacement for pcall/xpcall
function ErrorHandler:SafeCall(func, module, context, ...)
    if type(func) ~= "function" then
        LogError(SEVERITY.MEDIUM, CATEGORY.UNKNOWN,
                "SafeCall: Invalid function provided", 
                CaptureErrorContext(2), module)
        return false, "Invalid function"
    end
    
    local startTime = GetTime()
    local success, result = xpcall(func, function(err)
        return err .. "\n" .. debugstack(2)
    end, ...)
    local executionTime = (GetTime() - startTime) * 1000
    
    if not success then
        local errorMsg = tostring(result)
        
        -- Check for suppression
        if ShouldSuppressError(errorMsg) then
            return false, result
        end
        
        -- Classify and log error
        local category, severity = ClassifyError(errorMsg, result, context)
        
        local errorContext = CaptureErrorContext(2)
        if context then
            errorContext = DamiaUI.Utils:MergeTables(errorContext, context)
        end
        
        local logged = LogError(severity, category, errorMsg, errorContext, module)
        
        if logged then
            local errorRecord = errorState.recentErrors[#errorState.recentErrors]
            
            -- Attempt recovery for significant errors
            if severity <= SEVERITY.HIGH then
                AttemptRecovery(errorRecord)
            end
            
            -- Check if safe mode should be activated
            CheckSafeModeThreshold()
            
            -- Show error report for user-facing errors
            if severity <= SEVERITY.HIGH and not errorState.safeModeActive then
                ErrorHandler:ShowErrorReportDialog(errorRecord)
            end
        end
    else
        -- Performance monitoring
        if executionTime > config.performanceThresholdMs then
            LogError(SEVERITY.LOW, CATEGORY.PERFORMANCE,
                    string.format("Slow operation: %.1fms", executionTime),
                    CaptureErrorContext(2), module)
        end
    end
    
    return success, result
end

-- Enhanced error reporting function
function ErrorHandler:ReportError(message, category, severity, module, context)
    if not message then return false end
    
    category = category or CATEGORY.UNKNOWN
    severity = severity or SEVERITY.MEDIUM
    
    local errorContext = CaptureErrorContext(2)
    if context then
        errorContext = DamiaUI.Utils:MergeTables(errorContext, context)
    end
    
    return LogError(severity, category, message, errorContext, module)
end

-- Get error statistics
function ErrorHandler:GetErrorStatistics()
    return {
        totalErrors = errorState.totalErrors,
        criticalErrors = errorState.criticalErrors,
        errorsByCategory = DamiaUI.Utils:CopyTable(errorState.errorsByCategory),
        errorsByModule = DamiaUI.Utils:CopyTable(errorState.errorsByModule),
        safeModeActive = errorState.safeModeActive,
        recentErrorCount = #errorState.recentErrors,
        suppressedErrorCount = DamiaUI.Utils:GetTableSize(errorState.suppressedErrors),
        recoveryAttempts = DamiaUI.Utils:GetTableSize(errorState.recoveryAttempts)
    }
end

-- Get recent error logs
function ErrorHandler:GetRecentErrors(count, severity)
    count = count or 10
    local filtered = {}
    
    for i = #errorState.recentErrors, 1, -1 do
        local error = errorState.recentErrors[i]
        if not severity or error.severity <= severity then
            table.insert(filtered, error)
            if #filtered >= count then
                break
            end
        end
    end
    
    return filtered
end

-- Export error log for debugging
function ErrorHandler:ExportErrorLog()
    local export = {
        generatedAt = GetTime(),
        addonVersion = DamiaUI.version or "Unknown",
        gameVersion = GetBuildInfo(),
        statistics = ErrorHandler:GetErrorStatistics(),
        recentErrors = errorState.recentErrors,
        configuration = config,
        safeModeActive = errorState.safeModeActive
    }
    
    return export
end

-- Clear error history (for testing or after fixes)
function ErrorHandler:ClearErrorHistory()
    errorState.totalErrors = 0
    errorState.criticalErrors = 0
    errorState.errorsByCategory = {}
    errorState.errorsByModule = {}
    errorState.recentErrors = {}
    errorState.suppressedErrors = {}
    errorState.recoveryAttempts = {}
    errorState.errorLogBuffer = {}
    
    print(string.format("|cff00ff00[%s] Error history cleared|r", addonName))
    return true
end

-- Update error handling configuration
function ErrorHandler:UpdateConfiguration(newConfig)
    if type(newConfig) ~= "table" then
        return false
    end
    
    config = DamiaUI.Utils:MergeTables(config, newConfig)
    return true
end

--[[
===============================================================================
INTEGRATION WITH EXISTING MODULES
===============================================================================
--]]

-- Enhanced logging functions for other modules
function ErrorHandler:LogDebug(message, module)
    return LogError(SEVERITY.INFO, CATEGORY.UNKNOWN, message, CaptureErrorContext(2), module)
end

function ErrorHandler:LogInfo(message, module)
    return LogError(SEVERITY.INFO, CATEGORY.UNKNOWN, message, CaptureErrorContext(2), module)
end

function ErrorHandler:LogWarning(message, module)
    return LogError(SEVERITY.LOW, CATEGORY.UNKNOWN, message, CaptureErrorContext(2), module)
end

function ErrorHandler:LogError(message, module)
    return LogError(SEVERITY.MEDIUM, CATEGORY.UNKNOWN, message, CaptureErrorContext(2), module)
end

function ErrorHandler:LogCritical(message, module)
    return LogError(SEVERITY.CRITICAL, CATEGORY.UNKNOWN, message, CaptureErrorContext(2), module)
end

--[[
===============================================================================
INITIALIZATION AND CLEANUP
===============================================================================
--]]

-- Initialize error handler
function ErrorHandler:Initialize()
    print(string.format("|cff00ccff[%s] Error Handler initialized|r", addonName))
    
    -- Register for addon events
    if DamiaUI.Events then
        DamiaUI.Events:RegisterCustomEvent("DAMIA_ADDON_LOADED", function()
            ErrorHandler:ValidateAndRepairConfiguration()
        end, 1, "ErrorHandler_ConfigValidation")
    end
    
    -- Set up periodic cleanup
    C_Timer.NewTicker(300, function() -- Every 5 minutes
        -- Clean old error records
        local cutoffTime = GetTime() - (config.logRetentionDays * 24 * 3600)
        
        for i = #errorState.recentErrors, 1, -1 do
            if errorState.recentErrors[i].timestamp < cutoffTime then
                table.remove(errorState.recentErrors, i)
            end
        end
        
        -- Clean old suppressions
        for pattern, data in pairs(errorState.suppressedErrors) do
            if GetTime() - data.lastOccurrence > 3600 then -- 1 hour
                errorState.suppressedErrors[pattern] = nil
            end
        end
    end)
    
    return true
end

-- Check if error handler is in safe mode
function ErrorHandler:IsSafeModeActive()
    return errorState.safeModeActive
end

-- Constants for external access
ErrorHandler.SEVERITY = SEVERITY
ErrorHandler.CATEGORY = CATEGORY
ErrorHandler.RECOVERY = RECOVERY

-- Initialize the error handler
ErrorHandler:Initialize()

-- Make error handler globally accessible for early initialization
_G.DamiaUIErrorHandler = ErrorHandler