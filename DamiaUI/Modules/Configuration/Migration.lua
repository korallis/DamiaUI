--[[
    DamiaUI Configuration Migration Module
    
    Handles configuration migration and version upgrades for DamiaUI settings.
    Provides automated migration between different versions and ensures backward
    compatibility while upgrading configuration structures.
    
    Features:
    - Automatic version detection and migration
    - Incremental migration system
    - Configuration validation and repair
    - Backup and rollback capabilities
    - Migration history tracking
    
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
local pairs, ipairs = pairs, ipairs
local type, tostring, tonumber = type, tostring, tonumber
local time, date = time, date
local table = table
local string = string

-- Initialize module
local Migration = DamiaUI:NewModule("Migration", "AceEvent-3.0")
DamiaUI.Migration = Migration

-- Migration constants
local CURRENT_VERSION = "1.0.0"
local MIGRATION_TIMEOUT = 30
local MIGRATION_RETRY_LIMIT = 3

-- Migration state
local isInitialized = false
local migrationHistory = {}
local migrationCallbacks = {}

-- Migration definitions
local migrations = {}

--[[
    Module Initialization
]]

function Migration:OnInitialize()
    self:RegisterEvent("ADDON_LOADED")
end

function Migration:OnEnable()
    -- Register for DamiaUI events
    DamiaUI:RegisterEvent("DAMIA_CONFIG_INITIALIZED", function()
        self:Initialize()
    end)
    
    DamiaUI:LogDebug("Migration module enabled")
end

function Migration:Initialize()
    if isInitialized then
        return
    end
    
    -- Initialize migration system
    self:InitializeMigrationSystem()
    
    -- Register migration definitions
    self:RegisterMigrations()
    
    -- Perform any pending migrations
    self:CheckAndPerformMigrations()
    
    isInitialized = true
    DamiaUI:LogDebug("Migration system initialized")
end

--[[
    Migration System Core
]]

-- Initialize migration tracking
function Migration:InitializeMigrationSystem()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db or not db.global then
        return
    end
    
    -- Initialize migration history
    if not db.global.migrationHistory then
        db.global.migrationHistory = {}
    end
    
    migrationHistory = db.global.migrationHistory
    
    DamiaUI:LogDebug("Migration tracking initialized")
end

-- Register migration definitions
function Migration:RegisterMigrations()
    -- Migration from pre-1.0.0 (initial setup)
    self:RegisterMigration("0.0.0", "1.0.0", function(fromVersion, toVersion)
        return self:MigrateTo1_0_0()
    end)
    
    -- Future migrations would be registered here
    -- Example:
    -- self:RegisterMigration("1.0.0", "1.1.0", function(fromVersion, toVersion)
    --     return self:MigrateTo1_1_0()
    -- end)
    
    DamiaUI:LogDebug("Migration definitions registered")
end

-- Register a migration function
function Migration:RegisterMigration(fromVersion, toVersion, migrationFunc)
    local migrationKey = fromVersion .. "->" .. toVersion
    
    migrations[migrationKey] = {
        fromVersion = fromVersion,
        toVersion = toVersion,
        migrationFunc = migrationFunc,
        registered = time(),
    }
    
    DamiaUI:LogDebug("Registered migration: %s", migrationKey)
end

-- Check for and perform necessary migrations
function Migration:CheckAndPerformMigrations()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Cannot perform migrations: Config not initialized")
        return false
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db then
        DamiaUI:LogError("Cannot perform migrations: Database not available")
        return false
    end
    
    local currentDBVersion = db.version or "0.0.0"
    
    if self:CompareVersions(currentDBVersion, CURRENT_VERSION) >= 0 then
        DamiaUI:LogDebug("Database is up to date (v%s)", currentDBVersion)
        return true
    end
    
    DamiaUI:LogInfo("Database migration required: v%s -> v%s", currentDBVersion, CURRENT_VERSION)
    
    -- Create backup before migration
    self:CreatePreMigrationBackup(currentDBVersion)
    
    -- Perform incremental migrations
    local success = self:PerformIncrementalMigrations(currentDBVersion, CURRENT_VERSION)
    
    if success then
        -- Update database version
        db.version = CURRENT_VERSION
        
        -- Record migration completion
        self:RecordMigration(currentDBVersion, CURRENT_VERSION, true)
        
        DamiaUI:LogInfo("Database migration completed successfully")
        
        -- Fire migration completed event
        DamiaUI:FireEvent("DAMIA_MIGRATION_COMPLETED", currentDBVersion, CURRENT_VERSION)
    else
        DamiaUI:LogError("Database migration failed")
        
        -- Record migration failure
        self:RecordMigration(currentDBVersion, CURRENT_VERSION, false)
        
        -- Fire migration failed event
        DamiaUI:FireEvent("DAMIA_MIGRATION_FAILED", currentDBVersion, CURRENT_VERSION)
    end
    
    return success
end

-- Perform incremental migrations
function Migration:PerformIncrementalMigrations(fromVersion, toVersion)
    local migrationPath = self:FindMigrationPath(fromVersion, toVersion)
    
    if not migrationPath or #migrationPath == 0 then
        DamiaUI:LogError("No migration path found from v%s to v%s", fromVersion, toVersion)
        return false
    end
    
    DamiaUI:LogInfo("Migration path: %s", table.concat(migrationPath, " -> "))
    
    local currentVersion = fromVersion
    
    for i, targetVersion in ipairs(migrationPath) do
        local migrationKey = currentVersion .. "->" .. targetVersion
        local migration = migrations[migrationKey]
        
        if not migration then
            DamiaUI:LogError("Migration not found: %s", migrationKey)
            return false
        end
        
        DamiaUI:LogInfo("Applying migration: %s", migrationKey)
        
        local success, error = self:ApplyMigration(migration)
        
        if not success then
            DamiaUI:LogError("Migration failed: %s - %s", migrationKey, error or "Unknown error")
            return false
        end
        
        currentVersion = targetVersion
        DamiaUI:LogInfo("Migration completed: %s", migrationKey)
    end
    
    return true
end

-- Find migration path between versions
function Migration:FindMigrationPath(fromVersion, toVersion)
    -- For now, implement direct path finding
    -- In the future, this could be expanded to handle complex migration graphs
    
    local path = {}
    
    -- Check for direct migration
    local directKey = fromVersion .. "->" .. toVersion
    if migrations[directKey] then
        table.insert(path, toVersion)
        return path
    end
    
    -- For initial version, always migrate to current
    if fromVersion == "0.0.0" and toVersion == CURRENT_VERSION then
        table.insert(path, CURRENT_VERSION)
        return path
    end
    
    -- Could implement more complex path finding here for multi-step migrations
    
    return nil
end

-- Apply a single migration
function Migration:ApplyMigration(migration)
    local startTime = time()
    
    -- Set up timeout protection
    local timeoutFrame = CreateFrame("Frame")
    local timedOut = false
    
    timeoutFrame:SetScript("OnUpdate", function(self, elapsed)
        if time() - startTime > MIGRATION_TIMEOUT then
            timedOut = true
            self:SetScript("OnUpdate", nil)
        end
    end)
    
    local success, result = pcall(migration.migrationFunc, migration.fromVersion, migration.toVersion)
    
    timeoutFrame:SetScript("OnUpdate", nil)
    
    if timedOut then
        return false, "Migration timed out"
    end
    
    if not success then
        return false, result
    end
    
    if result == false then
        return false, "Migration function returned false"
    end
    
    return true
end

--[[
    Specific Migration Functions
]]

-- Migration to version 1.0.0
function Migration:MigrateTo1_0_0()
    DamiaUI:LogInfo("Performing initial migration to v1.0.0")
    
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return false
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db then
        return false
    end
    
    -- Initialize new structure for v1.0.0
    if not db.profiles then
        db.profiles = {
            ["Default"] = self:CreateDefaultProfile()
        }
    end
    
    if not db.global then
        db.global = {
            firstInstall = time(),
            migrations = {},
            backups = {},
            profileBackups = {},
            profileMetadata = {},
        }
    end
    
    if not db.char then
        db.char = {}
    end
    
    -- Migrate any existing settings
    if db.profile then
        -- Old profile structure exists, migrate it
        db.profiles["Migrated Profile"] = db.profile
        
        -- Update character references (using compatibility layer)
        local Compatibility = DamiaUI.Compatibility
        local realm = Compatibility and Compatibility.GetRealmName() or GetRealmName()
        local character = UnitName("player")
        
        if not db.char[realm] then
            db.char[realm] = {}
        end
        
        if not db.char[realm][character] then
            db.char[realm][character] = {
                currentProfile = "Migrated Profile",
                firstLogin = time(),
                lastLogin = time(),
            }
        end
        
        -- Remove old profile reference
        db.profile = nil
    end
    
    -- Ensure character has a valid profile (using compatibility layer)
    local Compatibility = DamiaUI.Compatibility
    local realm = Compatibility and Compatibility.GetRealmName() or GetRealmName()
    local character = UnitName("player")
    
    if db.char[realm] and db.char[realm][character] then
        local currentProfile = db.char[realm][character].currentProfile
        if not currentProfile or not db.profiles[currentProfile] then
            db.char[realm][character].currentProfile = "Default"
        end
    end
    
    DamiaUI:LogInfo("Migration to v1.0.0 completed")
    return true
end

-- Create default profile for migration
function Migration:CreateDefaultProfile()
    -- Return the default profile structure
    if DamiaUI.Defaults and DamiaUI.Defaults.profile then
        return DamiaUI.Utils:CopyTable(DamiaUI.Defaults.profile)
    end
    
    -- Fallback minimal profile structure
    return {
        general = {
            enabled = true,
            scale = 1.0,
            debugMode = false,
        },
        unitframes = {
            enabled = true,
            player = { enabled = true },
            target = { enabled = true },
            focus = { enabled = true },
        },
        actionbars = {
            enabled = true,
            mainbar = { enabled = true },
        },
        interface = {
            chat = { enabled = true },
            minimap = { enabled = true },
        },
        skinning = {
            enabled = true,
        },
    }
end

--[[
    Migration History and Tracking
]]

-- Record migration in history
function Migration:RecordMigration(fromVersion, toVersion, success, details)
    local record = {
        fromVersion = fromVersion,
        toVersion = toVersion,
        timestamp = time(),
        success = success,
        details = details,
        addonVersion = DamiaUI.version or "unknown",
    }
    
    table.insert(migrationHistory, record)
    
    -- Limit history size
    while #migrationHistory > 50 do
        table.remove(migrationHistory, 1)
    end
    
    DamiaUI:LogDebug("Recorded migration: %s -> %s (%s)", fromVersion, toVersion, success and "success" or "failed")
end

-- Get migration history
function Migration:GetMigrationHistory()
    return migrationHistory or {}
end

-- Check if migration was previously performed
function Migration:WasMigrationPerformed(fromVersion, toVersion)
    for _, record in ipairs(migrationHistory) do
        if record.fromVersion == fromVersion and record.toVersion == toVersion and record.success then
            return true, record
        end
    end
    return false
end

--[[
    Backup and Recovery
]]

-- Create backup before migration
function Migration:CreatePreMigrationBackup(version)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return false
    end
    
    local backupName = "pre_migration_" .. version .. "_" .. time()
    
    local success = DamiaUI.Config:CreateBackup(backupName)
    if success then
        DamiaUI:LogInfo("Created pre-migration backup: %s", backupName)
    else
        DamiaUI:LogWarning("Failed to create pre-migration backup")
    end
    
    return success
end

-- Rollback migration
function Migration:RollbackMigration(toVersion)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return false
    end
    
    -- Find the most recent pre-migration backup
    local backups = DamiaUI.Config:GetBackups()
    local targetBackup = nil
    
    for _, backup in ipairs(backups) do
        if backup.name:match("pre_migration_" .. toVersion:gsub("%.", "%%%.")) then
            if not targetBackup or backup.timestamp > targetBackup.timestamp then
                targetBackup = backup
            end
        end
    end
    
    if not targetBackup then
        DamiaUI:LogError("No pre-migration backup found for version %s", toVersion)
        return false
    end
    
    DamiaUI:LogInfo("Rolling back migration using backup: %s", targetBackup.name)
    
    local success = DamiaUI.Config:RestoreBackup(targetBackup.name)
    if success then
        DamiaUI:LogInfo("Migration rollback completed")
        
        -- Record rollback
        self:RecordMigration(CURRENT_VERSION, toVersion, true, "Rollback operation")
        
        -- Fire rollback event
        DamiaUI:FireEvent("DAMIA_MIGRATION_ROLLBACK", CURRENT_VERSION, toVersion)
    else
        DamiaUI:LogError("Migration rollback failed")
    end
    
    return success
end

--[[
    Configuration Validation and Repair
]]

-- Validate configuration structure
function Migration:ValidateConfiguration(config)
    if type(config) ~= "table" then
        return false, "Configuration is not a table"
    end
    
    -- Basic structure validation
    local requiredSections = { "general", "unitframes", "actionbars", "interface", "skinning" }
    
    for _, section in ipairs(requiredSections) do
        if not config[section] or type(config[section]) ~= "table" then
            return false, "Missing or invalid section: " .. section
        end
    end
    
    -- Validate general settings
    if type(config.general.enabled) ~= "boolean" then
        return false, "Invalid general.enabled setting"
    end
    
    if type(config.general.scale) ~= "number" or config.general.scale < 0.5 or config.general.scale > 2.0 then
        return false, "Invalid general.scale setting"
    end
    
    -- Additional validation could be added here
    
    return true
end

-- Repair corrupted configuration
function Migration:RepairConfiguration(config)
    local repaired = false
    
    -- Ensure basic structure exists
    local sections = { "general", "unitframes", "actionbars", "interface", "skinning" }
    
    for _, section in ipairs(sections) do
        if not config[section] or type(config[section]) ~= "table" then
            config[section] = {}
            repaired = true
            DamiaUI:LogWarning("Repaired missing section: %s", section)
        end
    end
    
    -- Repair general settings
    if type(config.general.enabled) ~= "boolean" then
        config.general.enabled = true
        repaired = true
        DamiaUI:LogWarning("Repaired general.enabled setting")
    end
    
    if type(config.general.scale) ~= "number" or config.general.scale < 0.5 or config.general.scale > 2.0 then
        config.general.scale = 1.0
        repaired = true
        DamiaUI:LogWarning("Repaired general.scale setting")
    end
    
    -- Additional repairs could be added here
    
    if repaired then
        DamiaUI:LogInfo("Configuration repairs completed")
    end
    
    return config, repaired
end

--[[
    Utility Functions
]]

-- Compare version strings
function Migration:CompareVersions(version1, version2)
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

-- Get current database version
function Migration:GetCurrentDatabaseVersion()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return "0.0.0"
    end
    
    local db = DamiaUI.Config:GetDatabase()
    return db and db.version or "0.0.0"
end

-- Check if migration is needed
function Migration:IsMigrationNeeded()
    local currentDBVersion = self:GetCurrentDatabaseVersion()
    return self:CompareVersions(currentDBVersion, CURRENT_VERSION) < 0
end

--[[
    Event Handlers
]]

function Migration:ADDON_LOADED(event, loadedAddon)
    if loadedAddon == addonName then
        -- Initialize after addon loads
        C_Timer.After(2, function()
            if not isInitialized then
                self:Initialize()
            end
        end)
    end
end

--[[
    Public API
]]

-- Force migration check
function Migration:ForceMigrationCheck()
    return self:CheckAndPerformMigrations()
end

-- Get migration status
function Migration:GetMigrationStatus()
    local currentDBVersion = self:GetCurrentDatabaseVersion()
    
    return {
        currentDBVersion = currentDBVersion,
        targetVersion = CURRENT_VERSION,
        migrationNeeded = self:IsMigrationNeeded(),
        lastMigration = migrationHistory[#migrationHistory],
        migrationHistory = self:GetMigrationHistory(),
    }
end

-- Register callback for migration events
function Migration:RegisterMigrationCallback(event, callback, identifier)
    if not migrationCallbacks[event] then
        migrationCallbacks[event] = {}
    end
    
    migrationCallbacks[event][identifier] = callback
    
    return true
end

-- Unregister migration callback
function Migration:UnregisterMigrationCallback(event, identifier)
    if migrationCallbacks[event] then
        migrationCallbacks[event][identifier] = nil
    end
    
    return true
end

-- Register the module
DamiaUI:RegisterModule("Migration", Migration)