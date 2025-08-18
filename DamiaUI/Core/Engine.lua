--[[
    DamiaUI Core Engine

    Main initialization and addon management system. Handles library loading,
    module registration, and provides the core API for all DamiaUI functionality.

    Author: DamiaUI Development Team
    Version: 1.0.0
]]

-- Suppress WoW API global warnings and field injection
---@diagnostic disable: undefined-global, undefined-field, inject-field, redundant-parameter

local addonName, addon = ...
local _G = _G
local pairs, ipairs, type = pairs, ipairs, type
local CreateFrame = CreateFrame
local GetTime, InCombatLockdown = GetTime, InCombatLockdown

-- Verify LibStub exists
assert(LibStub, "DamiaUI requires LibStub to be loaded")

-- Verify AceAddon exists
local AceAddon = LibStub("AceAddon-3.0", true)
assert(AceAddon, "DamiaUI requires AceAddon-3.0")

-- Create the main addon object
---@class DamiaUI : AceAddon
---@field modules table<string, any>
---@field Libraries table<string, any>
---@field callbacks table<string, table>
---@field ErrorHandler table
local DamiaUI = AceAddon:NewAddon(addon, addonName, "AceConsole-3.0")

-- Properly register global
---@diagnostic disable-next-line: inject-field
_G.DamiaUI = DamiaUI

-- Constants
local ADDON_NAME = "DamiaUI"
local VERSION = "1.0.0"
local DEBUG_MODE = false

-- Storage for modules and callbacks
DamiaUI.modules = {}
DamiaUI.Libraries = {}
DamiaUI.callbacks = {}

-- Simple error handler
DamiaUI.ErrorHandler = {
    SafeCall = function(self, func, context, info, ...)
        if type(func) == "function" then
            local success, result = pcall(func, ...)
            if not success then
                -- Log error if logging is available
                if DamiaUI.LogError then
                    DamiaUI:LogError("Error in %s: %s", context or "unknown", tostring(result))
                else
                    print("|cffCC8010DamiaUI|r [ERROR] " .. tostring(result))
                end
                return false
            end
            return result
        else
            if DamiaUI.LogError then
                DamiaUI:LogError("SafeCall: Invalid function provided for %s", context or "unknown")
            end
            return false
        end
    end
}

-- Core addon information
DamiaUI.addonName = addonName
DamiaUI.version = VERSION

-- Game version detection
local function DetectGameVersion()
    local tocVersion = select(4, GetBuildInfo()) or 0
    local gameVersion = {
        isMainline = tocVersion >= 110000,
        isClassic = tocVersion >= 11500 and tocVersion < 30000,
        isWOTLKC = tocVersion >= 30400 and tocVersion < 40000,
        isCata = tocVersion >= 40400 and tocVersion < 110000,
        tocVersion = tocVersion,
        buildNumber = select(2, GetBuildInfo()) or "0",
        versionString = select(1, GetBuildInfo()) or "Unknown"
    }

    -- Set primary game version flag
    if gameVersion.isMainline then
        gameVersion.gameType = "Mainline"
    elseif gameVersion.isCata then
        gameVersion.gameType = "Cata"
    elseif gameVersion.isWOTLKC then
        gameVersion.gameType = "WOTLKC"
    elseif gameVersion.isClassic then
        gameVersion.gameType = "Classic"
    else
        gameVersion.gameType = "Unknown"
    end

    return gameVersion
end

-- Initialize game version detection
DamiaUI.gameVersion = DetectGameVersion()

-- API compatibility layer
DamiaUI.API = {
    -- C_Timer availability check
    hasC_Timer = (C_Timer and C_Timer.After) ~= nil,

    -- Equipment manager availability (Mainline/Cata+)
    ---@diagnostic disable-next-line: undefined-global
    hasEquipmentManager = (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs) ~= nil,

    -- Talent system availability
    ---@diagnostic disable-next-line: undefined-global
    hasTalentAPI = (GetTalentInfo ~= nil),
    hasSpecialization = (GetSpecialization ~= nil), -- Mainline only

    -- Achievement system (WOTLKC+)
    hasAchievements = (GetAchievementInfo ~= nil),

    -- Calendar system (WOTLKC+)
    hasCalendar = (C_Calendar ~= nil),

    -- LFG system availability
    hasLFG = (GetLFGQueueStats ~= nil), -- WOTLKC+
    hasLFR = DamiaUI.gameVersion.isMainline, -- Mainline only

    -- Guild system differences
    hasGuildPerks = not DamiaUI.gameVersion.isClassic, -- Not in Classic Era

    -- Mount/Pet collection (Mainline)
    hasMountCollection = (C_MountJournal ~= nil),
    hasPetCollection = (C_PetJournal ~= nil),

    -- Void storage (Cata+)
    hasVoidStorage = DamiaUI.gameVersion.isCata or DamiaUI.gameVersion.isMainline,

    -- Transmogrification (Cata+ in retail timeline, but varies)
    hasTransmog = (C_Transmog ~= nil),

    -- Item upgrade system
    hasItemUpgrade = (C_ItemUpgrade ~= nil),

    -- Encounter journal (Cata+)
    hasEncounterJournal = (EncounterJournal ~= nil),
}

-- Version-specific API wrappers
DamiaUI.Compat = {
    -- Timer wrapper
    After = function(delay, callback)
        if DamiaUI.API.hasC_Timer then
            C_Timer.After(delay, callback)
        else
            -- Fallback for older versions
            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, deltaTime)
                elapsed = elapsed + deltaTime
                if elapsed >= delay then
                    self:SetScript("OnUpdate", nil)
                    callback()
                end
            end)
        end
    end,

    -- Talent API wrapper
    GetTalentInfo = function(...)
        if DamiaUI.gameVersion.isMainline and GetTalentInfo then
            -- Mainline talent system
            return GetTalentInfo(...)
        elseif DamiaUI.API.hasTalentAPI then
            -- Classic talent system
            return GetTalentInfo(...)
        end
        return nil
    end,

    -- Unit power wrapper for different versions
    GetPowerType = function(unit)
        if UnitPowerType then
            return UnitPowerType(unit)
        else
            -- Fallback for very old versions
            local powerType = UnitPowerType(unit)
            return powerType
        end
    end,
}

-- Initialize core properties
DamiaUI.isInitialized = false
DamiaUI.combatLockdown = false
DamiaUI.startTime = GetTime()

-- Initialize error handling first (before other modules)
-- This ensures error handling is available during initialization
local function InitializeErrorHandler()
    -- Fallback logging if ErrorHandler not available yet
    if not DamiaUI.ErrorHandler then
        DamiaUI.ErrorHandler = {
            SafeCall = function(_, func, _, _, ...)
                local success, result = pcall(func, ...)
                if not success then
                    -- Error logging removed
                end
                return success, result
            end,
            LogDebug = function(_, msg) end, -- Debug logging removed
            LogInfo = function(_, msg) end, -- Info logging removed
            LogWarning = function(_, msg) end, -- Warning logging removed
            LogError = function(_, msg) end -- Error logging removed
        }
    end
end

InitializeErrorHandler()

--[[
    Core API Functions
]]

-- Module registration system with error handling
function DamiaUI:RegisterModule(name, module)
    return self.ErrorHandler:SafeCall(function()
        if type(name) ~= "string" then
            error("Module name must be a string")
        end

        if self.modules[name] then
            self:LogWarning("Module '" .. name .. "' is already registered")
            return false
        end

        self.modules[name] = module
        self:LogDebug("Registered module: " .. name)
        return true
    end, "Engine", { module = name, operation = "register_module" })
end

-- Create and register a new module
function DamiaUI:NewModule(name, ...)
    local varargs = {...}
    local numArgs = select("#", ...)
    
    return self.ErrorHandler:SafeCall(function()
        if type(name) ~= "string" then
            error("Module name must be a string")
        end

        if self.modules[name] then
            self:LogWarning("Module '" .. name .. "' already exists")
            return self.modules[name]
        end

        -- Create new module object
        local module = {
            name = name,
            DamiaUI = self,
            -- Add any additional module methods here
        }

        -- Allow for additional module mixins passed as varargs
        for i = 1, numArgs do
            local mixin = varargs[i]
            if type(mixin) == "table" then
                for k, v in pairs(mixin) do
                    if not module[k] then
                        module[k] = v
                    end
                end
            end
        end

        self.modules[name] = module
        self:LogDebug("Created new module: " .. name)
        return module
    end, "Engine", { module = name, operation = "new_module" })
end

-- Module retrieval
function DamiaUI:GetModule(name)
    return self.modules[name]
end

-- Event system
function DamiaUI:RegisterEvent(event, callback, priority)
    if type(event) ~= "string" or type(callback) ~= "function" then
        self:LogError("Invalid event registration parameters")
        return false
    end

    priority = priority or 5

    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end

    table.insert(self.callbacks[event], {
        callback = callback,
        priority = priority
    })

    -- Sort by priority (lower number = higher priority)
    table.sort(self.callbacks[event], function(a, b)
        return a.priority < b.priority
    end)

    return true
end

-- Fire custom events with enhanced error handling
function DamiaUI:FireEvent(event, ...)
    if not self.callbacks[event] then
        return
    end

    for _, handler in ipairs(self.callbacks[event]) do
        self.ErrorHandler:SafeCall(handler.callback, "Engine",
            { event = event, operation = "fire_event" }, event, ...)
    end
end

-- Utility functions
function DamiaUI:GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()

    -- Calculate actual center position
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2

    -- Apply offsets and scale
    return (centerX + (offsetX or 0)) / uiScale, (centerY + (offsetY or 0)) / uiScale
end

function DamiaUI:GetScaledSize(baseSize)
    local uiScale = UIParent:GetEffectiveScale()
    return baseSize / uiScale
end

function DamiaUI:IsInCombat()
    return self.combatLockdown or InCombatLockdown()
end

--[[
    Enhanced Logging System with Error Handler Integration
]]

function DamiaUI:LogDebug(message)
    if self.ErrorHandler then
        self.ErrorHandler:LogDebug(tostring(message))
    elseif DEBUG_MODE then
        -- Debug logging removed
    end
end

function DamiaUI:LogInfo(message)
    if self.ErrorHandler then
        self.ErrorHandler:LogInfo(tostring(message))
    else
        -- Info logging removed
    end
end

function DamiaUI:LogWarning(message)
    if self.ErrorHandler then
        self.ErrorHandler:LogWarning(tostring(message))
    else
        -- Warning logging removed
    end
end

function DamiaUI:LogError(message)
    if self.ErrorHandler then
        self.ErrorHandler:LogError(tostring(message))
    else
        -- Error logging removed
    end
end

--[[
    Initialization System
]]

function DamiaUI:OnInitialize()
    self:LogInfo("Initializing DamiaUI v" .. VERSION)
    self:LogInfo("Game Version: " .. self.gameVersion.gameType .. " (" .. self.gameVersion.tocVersion .. ")")
    self:LogInfo("Build: " .. self.gameVersion.versionString .. " (" .. self.gameVersion.buildNumber .. ")")

    -- Initialize database (use DamiaUI.Defaults which is loaded from Config/Defaults.lua)
    ---@diagnostic disable-next-line: undefined-field
    self.db = LibStub("AceDB-3.0"):New("DamiaUIDB", DamiaUI.Defaults or {}, true)

    -- Register for essential events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UI_SCALE_CHANGED")

    self:LogDebug("Core initialization complete")
end

function DamiaUI:OnEnable()
    self:LogDebug("Enabling DamiaUI")

    -- Initialize embedded libraries
    self:InitializeLibraries()

    -- Enable all registered modules
    self:EnableModules()

    self:LogInfo("DamiaUI enabled successfully")
end

function DamiaUI:InitializeLibraries()
    self:LogDebug("Initializing embedded libraries")

    -- Cache library references with namespace isolation
    self.Libraries.oUF = LibStub("oUF", true)
    self.Libraries.Aurora = LibStub("Aurora", true)
    self.Libraries.ActionButton = LibStub("LibActionButton-1.0", true)
    self.Libraries.DataBroker = LibStub("LibDataBroker-1.1", true)
    
    -- Add Ace3 libraries with DamiaUI namespace
    self.Libraries.AceConfig = LibStub("DamiaUI_AceConfig-3.0", true)
    self.Libraries.AceConfigDialog = LibStub("DamiaUI_AceConfigDialog-3.0", true)
    self.Libraries.AceDBOptions = LibStub("DamiaUI_AceDBOptions-3.0", true)
    self.Libraries.AceGUI = LibStub("DamiaUI_AceGUI-3.0", true)

    -- Verify critical libraries loaded
    if not self.Libraries.oUF then
        self:LogError("oUF library failed to load - UnitFrames will be disabled")
    end

    if not self.Libraries.Aurora then
        self:LogWarning("Aurora library not found - Skinning will be limited")
    end
    
    if not self.Libraries.AceConfigDialog then
        self:LogWarning("AceConfigDialog library not found - Configuration UI may be limited")
    end

    self:LogDebug("Library initialization complete")
end

function DamiaUI:EnableModules()
    self:LogDebug("Enabling modules")

    for name, module in pairs(self.modules) do
        if module and type(module.OnEnable) == "function" then
            local success = self.ErrorHandler:SafeCall(module.OnEnable, "Engine",
                { module = name, operation = "enable_module" }, module)
            if success then
                self:LogDebug("Module enabled: " .. name)
            else
                self:LogError("Failed to enable module '" .. name .. "'")
                -- Module will be handled by error recovery system
            end
        end
    end
end

--[[
    Event Handlers
]]

function DamiaUI:PLAYER_LOGIN()
    self:LogDebug("PLAYER_LOGIN received")

    -- Mark as initialized
    self.isInitialized = true

    -- Fire initialization event
    self:FireEvent("DAMIA_INITIALIZED")

    -- Register slash commands
    ---@diagnostic disable-next-line: undefined-field
    self:RegisterChatCommand("damia", "SlashCommand")
    ---@diagnostic disable-next-line: undefined-field
    self:RegisterChatCommand("damiaui", "SlashCommand")
end

function DamiaUI:PLAYER_ENTERING_WORLD()
    self:LogDebug("PLAYER_ENTERING_WORLD received")

    -- Delayed initialization for UI elements using compatibility layer
    self.Compat.After(1, function()
        self:FireEvent("DAMIA_UI_READY")
    end)
end

function DamiaUI:PLAYER_REGEN_DISABLED()
    self.combatLockdown = true
    self:FireEvent("DAMIA_COMBAT_STATE_CHANGED", true)
end

function DamiaUI:PLAYER_REGEN_ENABLED()
    self.combatLockdown = false
    self:FireEvent("DAMIA_COMBAT_STATE_CHANGED", false)
end

function DamiaUI:UI_SCALE_CHANGED()
    local newScale = UIParent:GetEffectiveScale()
    self:FireEvent("DAMIA_SCALE_CHANGED", newScale)
end

--[[
    Slash Command Handler
]]

function DamiaUI:SlashCommand(input)
    if not input or strtrim(input) == "" then
        -- Open configuration
        if self.modules.Configuration and self.modules.Configuration.OpenConfig then
            self.modules.Configuration:OpenConfig()
        else
            self:LogInfo("Configuration module not available")
        end
        return
    end

    local command, args = input:match("^(%w+)%s*(.*)")
    command = (command or ""):lower()
    args = args or ""

    if command == "config" or command == "options" then
        if self.modules.Configuration and self.modules.Configuration.OpenConfig then
            -- Support opening specific category
            local category = strtrim(args)
            if category ~= "" then
                self.modules.Configuration:OpenConfig(category)
            else
                self.modules.Configuration:OpenConfig()
            end
        else
            self:LogInfo("Configuration module not available")
        end
    elseif command == "profile" then
        if self.modules.Profiles then
            local profileCommand, profileArgs = args:match("^(%w+)%s*(.*)")
            if profileCommand == "switch" and profileArgs ~= "" then
                if self.modules.Profiles.SwitchProfile then
                    self.modules.Profiles:SwitchProfile(strtrim(profileArgs))
                end
            elseif profileCommand == "create" and profileArgs ~= "" then
                if self.modules.Profiles.CreateProfile then
                    self.modules.Profiles:CreateProfile(strtrim(profileArgs))
                end
            elseif profileCommand == "list" then
                self:LogInfo("Available profiles:")
                if self.modules.Profiles.GetProfileList then
                    for _, name in ipairs(self.modules.Profiles:GetProfileList()) do
                        local current = ""
                        if self.modules.Profiles.GetCurrentProfile then
                            current = name == self.modules.Profiles:GetCurrentProfile() and " (current)" or ""
                        end
                        self:LogInfo("  - " .. name .. current)
                    end
                end
            else
                self:LogInfo("Profile commands: list, switch <name>, create <name>")
            end
        else
            self:LogInfo("Profiles module not available")
        end
    elseif command == "reset" then
    if strtrim(args) == "profile" then
            if self.modules.Profiles and self.modules.Profiles.ResetProfile then
                self.modules.Profiles:ResetProfile()
            else
                self:LogInfo("Profiles module not available")
            end
        else
            self:ResetAllSettings()
        end
    elseif command == "backup" then
        if self.modules.Configuration and self.modules.Configuration.SaveRollbackState then
            self.modules.Configuration:SaveRollbackState()
            self:LogInfo("Manual backup created")
        else
            self:LogInfo("Configuration module not available")
        end
    elseif command == "rollback" then
        if self.modules.Configuration and self.modules.Configuration.RollbackToPreviousState then
            if self.modules.Configuration:RollbackToPreviousState() then
                self:LogInfo("Rolled back to previous state")
            else
                self:LogInfo("No rollback states available")
            end
        else
            self:LogInfo("Configuration module not available")
        end
    elseif command == "reload" then
        ReloadUI()
    elseif command == "debug" then
    if strtrim(args) == "" then
            DEBUG_MODE = not DEBUG_MODE
            self:LogInfo("Debug mode " .. (DEBUG_MODE and "enabled" or "disabled"))
        else
            -- Set specific debug level
            local level = strtrim(args):upper()
            if level == "ON" or level == "ENABLE" then
                DEBUG_MODE = true
                self:LogInfo("Debug mode enabled")
            elseif level == "OFF" or level == "DISABLE" then
                DEBUG_MODE = false
                self:LogInfo("Debug mode disabled")
            else
                self:LogInfo("Debug mode is currently " .. (DEBUG_MODE and "enabled" or "disabled"))
            end
        end
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "version" then
        self:LogInfo("DamiaUI version: " .. VERSION)
        self:LogInfo("Game Version: " .. self.gameVersion.gameType .. " (" .. self.gameVersion.tocVersion .. ")")
        self:LogInfo("Build: " .. self.gameVersion.versionString .. " (" .. self.gameVersion.buildNumber .. ")")
    elseif command == "help" then
        self:PrintHelp()
    else
        self:PrintHelp()
    end
end

function DamiaUI:PrintHelp()
    self:LogInfo("DamiaUI Commands:")
    self:LogInfo("  /damia - Open configuration interface")
    self:LogInfo("  /damia config [category] - Open configuration (optionally to specific category)")
    self:LogInfo("  /damia profile list - List available profiles")
    self:LogInfo("  /damia profile switch <name> - Switch to profile")
    self:LogInfo("  /damia profile create <name> - Create new profile")
    self:LogInfo("  /damia reset - Reset all settings")
    self:LogInfo("  /damia reset profile - Reset current profile")
    self:LogInfo("  /damia backup - Create manual backup")
    self:LogInfo("  /damia rollback - Rollback last change")
    self:LogInfo("  /damia status - Show addon status")
    self:LogInfo("  /damia debug [on|off] - Toggle or set debug mode")
    self:LogInfo("  /damia reload - Reload user interface")
    self:LogInfo("  /damia version - Show version information")
    self:LogInfo("  /damia help - Show this help")
end

function DamiaUI:ResetAllSettings()
    if InCombatLockdown() then
        self:LogError("Cannot reset settings while in combat")
        return
    end

    StaticPopup_Show("DAMIAUI_RESET_CONFIRM")
end

-- Show addon status
function DamiaUI:ShowStatus()
    self:LogInfo("DamiaUI Status:")
    self:LogInfo("  Version: " .. (self.version or "Unknown"))
    self:LogInfo("  Game Version: " .. self.gameVersion.gameType .. " (" .. self.gameVersion.tocVersion .. ")")
    self:LogInfo("  Initialized: " .. (self.isInitialized and "Yes" or "No"))
    self:LogInfo("  Combat Lockdown: " .. (self:IsInCombat() and "Yes" or "No"))

    if self.modules.Configuration and self.modules.Configuration.GetStatus then
        local configStatus = self.modules.Configuration:GetStatus()
        self:LogInfo("  Configuration: " .. (configStatus.initialized and "Ready" or "Not Ready"))
        self:LogInfo("  Live Preview: " .. (configStatus.livePreview and "Enabled" or "Disabled"))
        self:LogInfo("  Rollback States: " .. configStatus.rollbackStates .. "/" .. configStatus.maxRollbackStates)
    end

    if self.modules.Profiles then
        if self.modules.Profiles.GetCurrentProfile then
            local currentProfile = self.modules.Profiles:GetCurrentProfile()
            self:LogInfo("  Current Profile: " .. currentProfile)
        end
        if self.modules.Profiles.GetProfileList then
            local profileList = self.modules.Profiles:GetProfileList()
            self:LogInfo("  Available Profiles: " .. #profileList)
        end
    end

    self:LogInfo("  Loaded Modules: " .. self:CountModules())
end

-- Count loaded modules
function DamiaUI:CountModules()
    local count = 0
    for _ in pairs(self.modules) do
        count = count + 1
    end
    return count
end

-- Reset confirmation dialog
StaticPopupDialogs["DAMIAUI_RESET_CONFIRM"] = {
    text = "This will reset all DamiaUI settings to defaults. A backup will be created automatically before resetting.\n\nAre you sure you want to continue?",
    button1 = "Yes, Reset",
    button2 = "Cancel",
    OnAccept = function()
        -- Create backup before reset
        if DamiaUI.modules.Configuration and DamiaUI.modules.Configuration.SaveRollbackState then
            DamiaUI.modules.Configuration:SaveRollbackState()
        end

        -- Config module backup if available (will be set by Config module when loaded)
        ---@diagnostic disable-next-line: undefined-field
        if DamiaUI.Config and DamiaUI.Config.CreateBackup then
            ---@diagnostic disable-next-line: undefined-field
            DamiaUI.Config:CreateBackup("before_full_reset_" .. time())
        end

        -- Reset database
        if DamiaUI.db then
            DamiaUI.db:ResetDB()
        end

        DamiaUI:LogInfo("Settings reset to defaults. Reloading UI...")
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--[[
    Global Reference
]]

-- Make DamiaUI globally accessible
_G[addonName] = DamiaUI

-- Create Engine reference for compatibility
DamiaUI.Engine = DamiaUI