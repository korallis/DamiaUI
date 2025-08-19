--[[
===============================================================================
Damia UI - Configuration System
===============================================================================
SavedVariables management and profile support for DamiaUI addon.
Handles settings storage, profile management, validation, and change notifications.

Features:
- Account-wide and character-specific settings
- Profile system with import/export
- Setting validation and type checking
- Change notification through event system
- Database migration support
- Backup and restore functionality

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring, tonumber = type, tostring, tonumber
-- Use compatibility layer for deprecated API functions
local Compatibility = DamiaUI.Compatibility
local GetRealmName = Compatibility and Compatibility.GetRealmName or GetRealmName
local UnitName = UnitName
local time = time
local table = table
local string = string

-- Create Config module
local Config = {}
DamiaUI.Config = Config

-- Configuration constants
local DB_VERSION = "1.0.0"
local MAX_PROFILES = 20
local BACKUP_COUNT = 5
local MIGRATION_TIMEOUT = 30

-- Configuration state
local database = nil
local currentProfile = nil
local characterKey = nil
local isInitialized = false
local pendingChanges = {}
local validationRules = {}
local defaultSettings = {}

--[[
===============================================================================
DEFAULT CONFIGURATION SCHEMA
===============================================================================
--]]

-- Default profile structure matching technical specifications
local function CreateDefaultProfile()
    return {
        -- Unit frame settings
        unitframes = {
            player = {
                enabled = true,
                position = { x = -200, y = -80 },
                scale = 1.0,
                width = 200,
                height = 50,
                showName = true,
                showLevel = true,
                showPvPIcon = true,
                healthbar = {
                    enabled = true,
                    height = 30,
                    texture = "DamiaUI_Statusbar",
                    colorByClass = true,
                },
                powerbar = {
                    enabled = true,
                    height = 15,
                    texture = "DamiaUI_Statusbar",
                    colorByType = true,
                },
            },
            target = {
                enabled = true,
                position = { x = 200, y = -80 },
                scale = 1.0,
                width = 200,
                height = 50,
                showName = true,
                showLevel = true,
                showPvPIcon = true,
                healthbar = {
                    enabled = true,
                    height = 30,
                    texture = "DamiaUI_Statusbar",
                    colorByClass = true,
                },
                powerbar = {
                    enabled = true,
                    height = 15,
                    texture = "DamiaUI_Statusbar",
                    colorByType = true,
                },
            },
            focus = {
                enabled = true,
                position = { x = 0, y = -40 },
                scale = 0.8,
                width = 160,
                height = 40,
                showName = true,
                showLevel = false,
                showPvPIcon = false,
            },
            party = {
                enabled = true,
                position = { x = -400, y = 0 },
                scale = 0.9,
                width = 120,
                height = 40,
                growth = "DOWN",
                spacing = 45,
                showBuffs = true,
                showDebuffs = true,
            },
            raid = {
                enabled = true,
                position = { x = -500, y = 200 },
                scale = 0.8,
                width = 80,
                height = 30,
                growth = "RIGHT",
                spacing = 2,
                maxColumns = 5,
                showBuffs = false,
                showDebuffs = true,
            },
        },
        
        -- Action bar settings
        actionbars = {
            mainbar = {
                enabled = true,
                position = { x = 0, y = -250 },
                buttonSize = 36,
                buttonSpacing = 4,
                showKeybinds = true,
                showCooldowns = true,
                showMacroNames = false,
                fadeOutOfCombat = false,
                fadeOpacity = 0.6,
            },
            secondarybar = {
                enabled = false,
                position = { x = 0, y = -210 },
                buttonSize = 32,
                buttonSpacing = 4,
                showKeybinds = true,
                showCooldowns = true,
                fadeOutOfCombat = true,
                fadeOpacity = 0.4,
            },
            rightbar1 = {
                enabled = false,
                position = { x = 350, y = -150 },
                buttonSize = 30,
                buttonSpacing = 4,
                orientation = "VERTICAL",
            },
            rightbar2 = {
                enabled = false,
                position = { x = 390, y = -150 },
                buttonSize = 30,
                buttonSpacing = 4,
                orientation = "VERTICAL",
            },
            petbar = {
                enabled = true,
                position = { x = -150, y = -290 },
                buttonSize = 24,
                buttonSpacing = 2,
                fadeOutOfCombat = true,
            },
            stancebar = {
                enabled = true,
                position = { x = 150, y = -290 },
                buttonSize = 24,
                buttonSpacing = 2,
            },
        },
        
        -- Interface settings
        interface = {
            chat = {
                enabled = true,
                position = { x = -400, y = -200 },
                width = 350,
                height = 120,
                fontSize = 12,
                fadeOut = true,
                fadeTimeout = 30,
            },
            minimap = {
                enabled = true,
                position = { x = 200, y = 200 },
                scale = 1.0,
                showClock = true,
                showZoneText = true,
                showDifficulty = true,
            },
            tooltip = {
                anchor = "CURSOR",
                scale = 1.0,
                showItemLevel = true,
                showItemID = false,
                showSpellID = false,
                borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
            },
        },
        
        -- Skinning preferences
        skinning = {
            enabled = true,
            blizzardFrames = true,
            thirdPartyFrames = true,
            customColors = {
                background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
                border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
                accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 },
            },
            textures = {
                statusbar = "DamiaUI_Statusbar",
                border = "DamiaUI_Border",
                background = "DamiaUI_Background",
            },
        },
        
        -- General settings
        general = {
            autoScale = true,
            targetScale = 1.0,
            fadeInCombat = false,
            combatFadeOpacity = 0.3,
            enableMovement = true,
            lockFrames = false,
            showGridInMovement = true,
        },
    }
end

--[[
===============================================================================
VALIDATION SYSTEM
===============================================================================
--]]

-- Set up validation rules for configuration values
local function InitializeValidationRules()
    validationRules = {
        -- Position validation
        ["*.position.x"] = function(value) 
            return type(value) == "number" and value >= -2000 and value <= 2000 
        end,
        ["*.position.y"] = function(value) 
            return type(value) == "number" and value >= -2000 and value <= 2000 
        end,
        
        -- Scale validation
        ["*.scale"] = function(value) 
            return type(value) == "number" and value >= 0.5 and value <= 2.0 
        end,
        
        -- Size validation
        ["*.width"] = function(value) 
            return type(value) == "number" and value >= 50 and value <= 500 
        end,
        ["*.height"] = function(value) 
            return type(value) == "number" and value >= 20 and value <= 200 
        end,
        ["*.buttonSize"] = function(value) 
            return type(value) == "number" and value >= 16 and value <= 64 
        end,
        
        -- Color validation
        ["*.customColors.*"] = function(value)
            if type(value) ~= "table" then return false end
            return type(value.r) == "number" and type(value.g) == "number" and 
                   type(value.b) == "number" and type(value.a) == "number" and
                   value.r >= 0 and value.r <= 1 and value.g >= 0 and value.g <= 1 and
                   value.b >= 0 and value.b <= 1 and value.a >= 0 and value.a <= 1
        end,
        
        -- Enabled states
        ["*.enabled"] = function(value) 
            return type(value) == "boolean" 
        end,
        
        -- Opacity validation
        ["*.fadeOpacity"] = function(value) 
            return type(value) == "number" and value >= 0 and value <= 1 
        end,
    }
end

-- Validate configuration value against rules
local function ValidateConfigValue(key, value)
    -- Check direct key match
    if validationRules[key] then
        return validationRules[key](value)
    end
    
    -- Check wildcard patterns
    for pattern, validator in pairs(validationRules) do
        if pattern:find("*") then
            local regexPattern = pattern:gsub("%*", "[^.]+")
            if key:match("^" .. regexPattern .. "$") then
                return validator(value)
            end
        end
    end
    
    -- No validation rule found - allow by default but log warning
    DamiaUI.Engine:LogWarning("No validation rule for config key: %s", key)
    return true
end

-- Validate entire configuration structure
function Config:ValidateConfig(config)
    if type(config) ~= "table" then
        return false, "Configuration must be a table"
    end
    
    local function validateRecursive(tbl, prefix)
        for key, value in pairs(tbl) do
            local fullKey = prefix and (prefix .. "." .. key) or key
            
            if type(value) == "table" then
                local success, error = validateRecursive(value, fullKey)
                if not success then
                    return false, error
                end
            else
                if not ValidateConfigValue(fullKey, value) then
                    return false, "Invalid value for " .. fullKey .. ": " .. tostring(value)
                end
            end
        end
        return true
    end
    
    return validateRecursive(config)
end

--[[
===============================================================================
DATABASE INITIALIZATION AND MIGRATION
===============================================================================
--]]

-- Initialize database structure
local function InitializeDatabase()
    if not DamiaUIDB then
        DamiaUIDB = {
            version = DB_VERSION,
            char = {},
            profiles = {
                ["Default"] = CreateDefaultProfile(),
            },
            global = {
                minimap = {
                    hide = false,
                    minimapPos = 220,
                },
                firstInstall = time(),
                migrations = {},
                backups = {},
            },
        }
        
        DamiaUI.Engine:LogInfo("Created new DamiaUI database")
    end
    
    database = DamiaUIDB
    
    -- Set up character key
    local realm = GetRealmName()
    local character = UnitName("player")
    characterKey = realm .. "-" .. character
    
    -- Initialize character data if needed
    if not database.char[realm] then
        database.char[realm] = {}
    end
    
    if not database.char[realm][character] then
        database.char[realm][character] = {
            currentProfile = "Default",
            firstLogin = time(),
            lastLogin = time(),
        }
    else
        database.char[realm][character].lastLogin = time()
    end
    
    -- Migrate database if needed
    Config:MigrateDatabase()
    
    -- Set current profile
    local profileName = database.char[realm][character].currentProfile
    currentProfile = database.profiles[profileName] or database.profiles["Default"]
    
    DamiaUI.Engine:LogInfo("Database initialized for %s", characterKey)
end

-- Database migration system
function Config:MigrateDatabase()
    if not database then
        return false
    end
    
    local currentVersion = database.version or "0.0.0"
    
    if currentVersion == DB_VERSION then
        return true -- No migration needed
    end
    
    DamiaUI.Engine:LogInfo("Migrating database from %s to %s", currentVersion, DB_VERSION)
    
    -- Create backup before migration
    self:CreateBackup("pre_migration_" .. currentVersion)
    
    -- Perform version-specific migrations
    local migrations = {
        -- Future migrations would go here
        -- ["1.0.1"] = function() ... end,
    }
    
    -- Apply migrations in order
    for version, migration in pairs(migrations) do
        if self:CompareVersions(currentVersion, version) < 0 then
            DamiaUI.Engine:LogInfo("Applying migration: %s", version)
            local success, error = pcall(migration)
            if not success then
                DamiaUI.Engine:LogError("Migration failed for %s: %s", version, error)
                return false
            end
            table.insert(database.global.migrations, {
                version = version,
                timestamp = time(),
            })
        end
    end
    
    database.version = DB_VERSION
    DamiaUI.Engine:LogInfo("Database migration completed")
    return true
end

-- Compare version strings
function Config:CompareVersions(version1, version2)
    local function parseVersion(v)
        local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end
    
    local maj1, min1, pat1 = parseVersion(version1)
    local maj2, min2, pat2 = parseVersion(version2)
    
    if maj1 ~= maj2 then return maj1 - maj2 end
    if min1 ~= min2 then return min1 - min2 end
    return pat1 - pat2
end

--[[
===============================================================================
PROFILE MANAGEMENT
===============================================================================
--]]

-- Get list of available profiles
function Config:GetProfiles()
    if not database then return {} end
    
    local profiles = {}
    for name in pairs(database.profiles) do
        table.insert(profiles, name)
    end
    
    table.sort(profiles)
    return profiles
end

-- Get current profile name
function Config:GetCurrentProfile()
    if not database or not characterKey then return "Default" end
    
    local realm, character = characterKey:match("(.+)-(.+)")
    if database.char[realm] and database.char[realm][character] then
        return database.char[realm][character].currentProfile
    end
    
    return "Default"
end

-- Set active profile
function Config:SetProfile(profileName)
    if not database or not profileName then
        return false
    end
    
    if not database.profiles[profileName] then
        DamiaUI.Engine:LogError("Profile does not exist: %s", profileName)
        return false
    end
    
    local oldProfile = self:GetCurrentProfile()
    
    -- Update character profile setting
    local realm, character = characterKey:match("(.+)-(.+)")
    if database.char[realm] and database.char[realm][character] then
        database.char[realm][character].currentProfile = profileName
    end
    
    -- Switch to new profile
    currentProfile = database.profiles[profileName]
    
    DamiaUI.Engine:LogInfo("Switched from profile '%s' to '%s'", oldProfile, profileName)
    
    -- Fire profile change event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_PROFILE_CHANGED", oldProfile, profileName)
    end
    
    return true
end

-- Create new profile
function Config:CreateProfile(profileName, copyFrom)
    if not database or not profileName then
        return false
    end
    
    if database.profiles[profileName] then
        DamiaUI.Engine:LogError("Profile already exists: %s", profileName)
        return false
    end
    
    if #self:GetProfiles() >= MAX_PROFILES then
        DamiaUI.Engine:LogError("Maximum number of profiles reached (%d)", MAX_PROFILES)
        return false
    end
    
    -- Create new profile
    if copyFrom and database.profiles[copyFrom] then
        database.profiles[profileName] = DamiaUI.Utils:CopyTable(database.profiles[copyFrom])
    else
        database.profiles[profileName] = CreateDefaultProfile()
    end
    
    DamiaUI.Engine:LogInfo("Created profile: %s", profileName)
    
    -- Fire profile created event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_PROFILE_CREATED", profileName)
    end
    
    return true
end

-- Delete profile
function Config:DeleteProfile(profileName)
    if not database or not profileName then
        return false
    end
    
    if profileName == "Default" then
        DamiaUI.Engine:LogError("Cannot delete Default profile")
        return false
    end
    
    if not database.profiles[profileName] then
        DamiaUI.Engine:LogError("Profile does not exist: %s", profileName)
        return false
    end
    
    -- Check if any characters are using this profile
    local charactersUsing = {}
    for realm, realmData in pairs(database.char) do
        for character, charData in pairs(realmData) do
            if charData.currentProfile == profileName then
                table.insert(charactersUsing, realm .. "-" .. character)
            end
        end
    end
    
    if #charactersUsing > 0 then
        DamiaUI.Engine:LogWarning("Profile %s is in use by: %s", profileName, table.concat(charactersUsing, ", "))
        -- Switch those characters to Default profile
        for realm, realmData in pairs(database.char) do
            for character, charData in pairs(realmData) do
                if charData.currentProfile == profileName then
                    charData.currentProfile = "Default"
                end
            end
        end
    end
    
    -- Delete the profile
    database.profiles[profileName] = nil
    
    DamiaUI.Engine:LogInfo("Deleted profile: %s", profileName)
    
    -- Fire profile deleted event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_PROFILE_DELETED", profileName)
    end
    
    return true
end

-- Reset profile to defaults
function Config:ResetProfile(profileName)
    if not database then
        return false
    end
    
    profileName = profileName or self:GetCurrentProfile()
    
    if not database.profiles[profileName] then
        return false
    end
    
    -- Create backup before reset
    self:CreateBackup("before_reset_" .. profileName)
    
    -- Reset to default
    database.profiles[profileName] = CreateDefaultProfile()
    
    -- Update current profile reference if needed
    if profileName == self:GetCurrentProfile() then
        currentProfile = database.profiles[profileName]
    end
    
    DamiaUI.Engine:LogInfo("Reset profile to defaults: %s", profileName)
    
    -- Fire profile reset event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_PROFILE_RESET", profileName)
    end
    
    return true
end

--[[
===============================================================================
SETTINGS ACCESS AND MODIFICATION
===============================================================================
--]]

-- Get configuration value
function Config:Get(key, default)
    if not currentProfile then
        return default
    end
    
    local keys = DamiaUI.Utils:Split(key, ".")
    local value = currentProfile
    
    for _, k in ipairs(keys) do
        if type(value) ~= "table" or value[k] == nil then
            return default
        end
        value = value[k]
    end
    
    return value
end

-- Set configuration value with error handling
function Config:Set(key, value)
    if not currentProfile or not key then
        return false
    end
    
    return DamiaUI.ErrorHandler:SafeCall(function()
        -- Validate the value
        if not ValidateConfigValue(key, value) then
            error("Invalid value for " .. key .. ": " .. tostring(value))
        end
        
        local keys = DamiaUI.Utils:Split(key, ".")
        local target = currentProfile
        local oldValue = Config:Get(key)
        
        -- Navigate to the parent table
        for i = 1, #keys - 1 do
            local k = keys[i]
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            target = target[k]
        end
        
        -- Set the value
        local finalKey = keys[#keys]
        target[finalKey] = value
        
        DamiaUI.Engine:LogDebug("Config changed: %s = %s (was %s)", key, tostring(value), tostring(oldValue))
        
        -- Fire configuration change events
        if DamiaUI.Events then
            DamiaUI.Events:FireConfigEvent(key, oldValue, value)
        end
        
        return true
    end, "Config", { key = key, operation = "set_config" })
end

-- Register configuration change callback
function Config:RegisterCallback(key, callback, identifier)
    if not DamiaUI.Events then
        DamiaUI.Engine:LogError("Events system not available for config callbacks")
        return false
    end
    
    return DamiaUI.Events:RegisterConfigEvent(key, callback, identifier)
end

-- Unregister configuration change callback  
function Config:UnregisterCallback(key, identifier)
    if not DamiaUI.Events then
        return false
    end
    
    return DamiaUI.Events:UnregisterConfigEvent(key, identifier)
end

--[[
===============================================================================
BACKUP AND RESTORE SYSTEM
===============================================================================
--]]

-- Create configuration backup
function Config:CreateBackup(name)
    if not database then
        return false
    end
    
    name = name or ("backup_" .. time())
    
    -- Limit number of backups
    local backups = database.global.backups
    while #backups >= BACKUP_COUNT do
        table.remove(backups, 1)
    end
    
    -- Create backup
    local backup = {
        name = name,
        timestamp = time(),
        profiles = DamiaUI.Utils:CopyTable(database.profiles),
        version = database.version,
    }
    
    table.insert(backups, backup)
    
    DamiaUI.Engine:LogInfo("Created configuration backup: %s", name)
    return true
end

-- Restore from backup
function Config:RestoreBackup(name)
    if not database or not name then
        return false
    end
    
    local backup = nil
    for _, b in ipairs(database.global.backups) do
        if b.name == name then
            backup = b
            break
        end
    end
    
    if not backup then
        DamiaUI.Engine:LogError("Backup not found: %s", name)
        return false
    end
    
    -- Create current state backup before restore
    self:CreateBackup("before_restore_" .. time())
    
    -- Restore profiles
    database.profiles = DamiaUI.Utils:CopyTable(backup.profiles)
    
    -- Update current profile reference
    local profileName = self:GetCurrentProfile()
    currentProfile = database.profiles[profileName] or database.profiles["Default"]
    
    DamiaUI.Engine:LogInfo("Restored from backup: %s", name)
    
    -- Fire restore event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_CONFIG_RESTORED", name)
    end
    
    return true
end

-- Get list of available backups
function Config:GetBackups()
    if not database then
        return {}
    end
    
    return database.global.backups or {}
end

--[[
===============================================================================
IMPORT/EXPORT FUNCTIONALITY
===============================================================================
--]]

-- Export profile configuration
function Config:ExportProfile(profileName)
    if not database then
        return nil
    end
    
    profileName = profileName or self:GetCurrentProfile()
    local profile = database.profiles[profileName]
    
    if not profile then
        return nil
    end
    
    local exportData = {
        name = profileName,
        version = DB_VERSION,
        timestamp = time(),
        data = DamiaUI.Utils:CopyTable(profile),
    }
    
    return exportData
end

-- Import profile configuration
function Config:ImportProfile(exportData, newName)
    if not database or not exportData or type(exportData) ~= "table" then
        return false
    end
    
    if not exportData.data or type(exportData.data) ~= "table" then
        DamiaUI.Engine:LogError("Invalid import data format")
        return false
    end
    
    -- Validate imported configuration
    local isValid, error = self:ValidateConfig(exportData.data)
    if not isValid then
        DamiaUI.Engine:LogError("Import validation failed: %s", error)
        return false
    end
    
    local profileName = newName or exportData.name or "Imported Profile"
    
    -- Ensure unique name
    local counter = 1
    local originalName = profileName
    while database.profiles[profileName] do
        profileName = originalName .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    -- Import the profile
    database.profiles[profileName] = DamiaUI.Utils:CopyTable(exportData.data)
    
    DamiaUI.Engine:LogInfo("Imported profile: %s", profileName)
    
    -- Fire import event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_PROFILE_IMPORTED", profileName)
    end
    
    return profileName
end

--[[
===============================================================================
INITIALIZATION AND PUBLIC API
===============================================================================
--]]

-- Initialize configuration system
function Config:Initialize()
    if isInitialized then
        return true
    end
    
    InitializeValidationRules()
    InitializeDatabase()
    
    isInitialized = true
    
    DamiaUI.Engine:LogInfo("Configuration system initialized")
    
    -- Fire initialization event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_CONFIG_INITIALIZED")
    end
    
    return true
end

-- Check if configuration is initialized
function Config:IsInitialized()
    return isInitialized
end

-- Get database reference (for advanced use)
function Config:GetDatabase()
    return database
end

-- Ensure ErrorHandler fallback is available
if not DamiaUI.ErrorHandler then
    DamiaUI.ErrorHandler = {
        SafeCall = function(self, func, module, context, ...)
            local success, result = pcall(func, ...)
            if not success then
                -- Config error logging removed
            end
            return success, result
        end
    }
end

-- Initialize when addon loads
if DamiaUI.Events then
    DamiaUI.Events:RegisterCustomEvent("DAMIA_ADDON_LOADED", function()
        Config:Initialize()
    end, 1, "DamiaUI_ConfigInit")
else
    -- Fallback if events not available yet
    C_Timer.After(0.1, function()
        Config:Initialize()
    end)
end

-- Don't log at load time - Engine might not be initialized yet
-- Logging will happen during Initialize()