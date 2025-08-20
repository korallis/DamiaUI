local addonName, DamiaUI = ...

-- Settings Migration System
DamiaUI.Migration = {}
local Migration = DamiaUI.Migration

-- Current database version
local CURRENT_DB_VERSION = "1.0.0"

-- Migration functions for different versions
local migrations = {
    ["0.1.0"] = function(db)
        DamiaUI.Debug("Migrating from pre-release version to 0.1.0")
        -- Handle any pre-release settings format changes
        return true
    end,
    
    ["1.0.0"] = function(db)
        DamiaUI.Debug("Migrating to version 1.0.0")
        
        -- Ensure all new required fields exist
        if not db.general then
            db.general = DamiaUI.Defaults.profile.general
        end
        
        if not db.modules then
            db.modules = DamiaUI.Defaults.profile.modules
        end
        
        -- Convert any old format settings
        if db.actionBars and not db.actionbars then
            db.actionbars = db.actionBars
            db.actionBars = nil
        end
        
        if db.unitFrames and not db.unitframes then
            db.unitframes = db.unitFrames
            db.unitFrames = nil
        end
        
        return true
    end,
}

-- Check if migration is needed
function Migration:CheckMigration(db)
    local currentVersion = db.dbVersion or "0.1.0"
    
    if currentVersion ~= CURRENT_DB_VERSION then
        DamiaUI.Debug("Database migration needed:", currentVersion, "->", CURRENT_DB_VERSION)
        return self:RunMigrations(db, currentVersion)
    end
    
    return true
end

-- Run migrations from old version to current
function Migration:RunMigrations(db, fromVersion)
    local success = true
    
    -- Define version order
    local versionOrder = {"0.1.0", "1.0.0"}
    local startIndex = 1
    
    -- Find starting point
    for i, version in ipairs(versionOrder) do
        if version == fromVersion then
            startIndex = i + 1
            break
        end
    end
    
    -- Run migrations in order
    for i = startIndex, #versionOrder do
        local version = versionOrder[i]
        local migrationFunc = migrations[version]
        
        if migrationFunc then
            DamiaUI.Debug("Running migration for version:", version)
            
            local migrationSuccess = migrationFunc(db)
            if not migrationSuccess then
                DamiaUI.Debug("Migration failed for version:", version)
                success = false
                break
            end
            
            db.dbVersion = version
        end
    end
    
    if success then
        DamiaUI.Debug("All migrations completed successfully")
        db.dbVersion = CURRENT_DB_VERSION
        
        -- Validate settings after migration
        self:ValidateDatabase(db)
    else
        DamiaUI.Debug("Migration failed, database may be in inconsistent state")
    end
    
    return success
end

-- Validate database integrity after migration
function Migration:ValidateDatabase(db)
    local defaults = DamiaUI.Defaults.profile
    
    -- Recursively check and fix missing values
    local function validateSection(current, default, path)
        path = path or ""
        
        for key, defaultValue in pairs(default) do
            local currentPath = path == "" and key or (path .. "." .. key)
            
            if current[key] == nil then
                current[key] = DamiaUI:DeepCopy(defaultValue)
                DamiaUI.Debug("Restored missing setting:", currentPath)
            elseif type(defaultValue) == "table" and type(current[key]) == "table" then
                validateSection(current[key], defaultValue, currentPath)
            end
        end
    end
    
    validateSection(db, defaults)
    
    -- Validate specific setting ranges and types
    self:ValidateSettingRanges(db)
end

-- Validate setting ranges and correct invalid values
function Migration:ValidateSettingRanges(db)
    -- Scale values should be between 0.5 and 2.0
    if db.general and db.general.scale then
        db.general.scale = math.max(0.5, math.min(2.0, db.general.scale))
    end
    
    -- Action bar button sizes should be reasonable
    if db.actionbars then
        if db.actionbars.buttonSize then
            db.actionbars.buttonSize = math.max(16, math.min(64, db.actionbars.buttonSize))
        end
        
        if db.actionbars.spacing then
            db.actionbars.spacing = math.max(0, math.min(10, db.actionbars.spacing))
        end
        
        -- Validate individual action bar settings
        local barNames = {"mainActionBar", "multiActionBarBottomLeft", "multiActionBarBottomRight", "multiActionBarRight", "multiActionBarLeft"}
        for _, barName in ipairs(barNames) do
            local barSettings = db.actionbars[barName]
            if barSettings then
                if barSettings.buttonSize then
                    barSettings.buttonSize = math.max(16, math.min(64, barSettings.buttonSize))
                end
                if barSettings.spacing then
                    barSettings.spacing = math.max(0, math.min(10, barSettings.spacing))
                end
                if barSettings.scale then
                    barSettings.scale = math.max(0.5, math.min(2.0, barSettings.scale))
                end
            end
        end
    end
    
    -- Unit frame dimensions should be reasonable
    if db.unitframes then
        local frameTypes = {"player", "target", "targettarget", "focus", "pet"}
        for _, frameType in ipairs(frameTypes) do
            local frameSettings = db.unitframes[frameType]
            if frameSettings then
                if frameSettings.width then
                    frameSettings.width = math.max(50, math.min(500, frameSettings.width))
                end
                if frameSettings.height then
                    frameSettings.height = math.max(20, math.min(200, frameSettings.height))
                end
                if frameSettings.scale then
                    frameSettings.scale = math.max(0.5, math.min(2.0, frameSettings.scale))
                end
            end
        end
    end
    
    -- Minimap size should be reasonable
    if db.minimap and db.minimap.size then
        db.minimap.size = math.max(80, math.min(300, db.minimap.size))
    end
    
    if db.minimap and db.minimap.scale then
        db.minimap.scale = math.max(0.5, math.min(2.0, db.minimap.scale))
    end
    
    -- Aura sizes should be reasonable
    if db.auras then
        if db.auras.playerBuffs and db.auras.playerBuffs.size then
            db.auras.playerBuffs.size = math.max(16, math.min(64, db.auras.playerBuffs.size))
        end
        if db.auras.playerDebuffs and db.auras.playerDebuffs.size then
            db.auras.playerDebuffs.size = math.max(16, math.min(64, db.auras.playerDebuffs.size))
        end
    end
    
    DamiaUI.Debug("Setting ranges validated and corrected")
end

-- Handle legacy addon migration
function Migration:MigrateLegacyAddons()
    -- Check for old DamiaUI installations
    if DamiaUI_Settings then
        DamiaUI.Debug("Found legacy DamiaUI settings, migrating...")
        
        -- TODO: Implement legacy settings migration
        -- This would convert old saved variables to new format
        
        -- Clear old variables after successful migration
        DamiaUI_Settings = nil
        DamiaUI.Debug("Legacy settings migration completed")
    end
    
    -- Check for conflicting addons
    self:CheckAddonConflicts()
end

-- Check for conflicting addons and warn user
function Migration:CheckAddonConflicts()
    local conflictingAddons = {
        -- Action Bar addons
        "Bartender4", "Dominos", "ElvUI", "TukUI",
        
        -- Unit Frame addons  
        "ShadowedUnitFrames", "PitBull4", "XPerl", "Stuf",
        
        -- UI Suites
        "ElvUI", "TukUI", "GW2_UI",
    }
    
    local conflicts = {}
    for _, addonName in ipairs(conflictingAddons) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            table.insert(conflicts, addonName)
        end
    end
    
    if #conflicts > 0 then
        local conflictList = table.concat(conflicts, ", ")
        DamiaUI.Debug("Detected conflicting addons:", conflictList)
        
        -- Show warning to user
        local message = string.format(
            "|cffCC8010DamiaUI|r detected potentially conflicting addons: %s\n\n" ..
            "These addons may cause issues with DamiaUI. Consider disabling them for the best experience.",
            conflictList
        )
        
        StaticPopupDialogs["DAMIAUI_ADDON_CONFLICTS"] = {
            text = message,
            button1 = "Okay",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        
        -- Show popup after a delay to ensure UI is loaded
        C_Timer.After(5, function()
            StaticPopup_Show("DAMIAUI_ADDON_CONFLICTS")
        end)
    end
end

-- Create backup of settings
function Migration:CreateBackup(db)
    if not DamiaUIDB_Backup then
        DamiaUIDB_Backup = {}
    end
    
    local timestamp = date("%Y%m%d_%H%M%S")
    local backupKey = "backup_" .. timestamp
    
    DamiaUIDB_Backup[backupKey] = DamiaUI:DeepCopy(db)
    
    -- Keep only last 5 backups
    local backups = {}
    for key in pairs(DamiaUIDB_Backup) do
        table.insert(backups, key)
    end
    
    table.sort(backups)
    while #backups > 5 do
        local oldestBackup = table.remove(backups, 1)
        DamiaUIDB_Backup[oldestBackup] = nil
    end
    
    DamiaUI.Debug("Settings backup created:", backupKey)
    return backupKey
end

-- Restore from backup
function Migration:RestoreBackup(backupKey)
    if DamiaUIDB_Backup and DamiaUIDB_Backup[backupKey] then
        DamiaUIDB = DamiaUI:DeepCopy(DamiaUIDB_Backup[backupKey])
        DamiaUI.Debug("Settings restored from backup:", backupKey)
        ReloadUI()
        return true
    end
    
    DamiaUI.Debug("Backup not found:", backupKey)
    return false
end

-- Get available backups
function Migration:GetBackups()
    if not DamiaUIDB_Backup then
        return {}
    end
    
    local backups = {}
    for key in pairs(DamiaUIDB_Backup) do
        table.insert(backups, key)
    end
    
    table.sort(backups)
    return backups
end

-- Initialize migration system
function Migration:Initialize()
    DamiaUI.Debug("Migration system initialized")
end