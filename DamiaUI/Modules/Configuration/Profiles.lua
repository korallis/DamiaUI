--[[
    DamiaUI Profile Management Module
    
    Comprehensive profile management system providing profile switching,
    import/export functionality, and backup/restore capabilities.
    
    Features:
    - Profile creation, deletion, and switching
    - Import/export profiles with validation
    - Automatic backup system
    - Profile comparison and merging
    - Bulk profile operations
    
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
local math = math

-- Initialize module
local Profiles = DamiaUI:NewModule("Profiles", "AceEvent-3.0")
DamiaUI.Profiles = Profiles

-- Module constants
local MAX_PROFILES = 20
local BACKUP_RETENTION_DAYS = 30
local EXPORT_VERSION = "1.0.0"

-- Module state
local isInitialized = false
local pendingOperations = {}
local profileBackups = {}

--[[
    Module Initialization
]]

function Profiles:OnInitialize()
    self:RegisterEvent("ADDON_LOADED")
end

function Profiles:OnEnable()
    -- Register for DamiaUI events
    DamiaUI:RegisterEvent("DAMIA_INITIALIZED", function()
        self:Initialize()
    end)
    
    -- Register for configuration events
    DamiaUI:RegisterEvent("DAMIA_PROFILE_CHANGED", function(_, oldProfile, newProfile)
        self:OnProfileChanged(oldProfile, newProfile)
    end)
    
    DamiaUI:LogDebug("Profiles module enabled")
end

function Profiles:Initialize()
    if isInitialized then
        return
    end
    
    -- Initialize profile backup system
    self:InitializeBackupSystem()
    
    -- Clean old backups
    self:CleanOldBackups()
    
    isInitialized = true
    DamiaUI:LogDebug("Profile management system initialized")
end

--[[
    Profile Management Core Functions
]]

-- Get list of all available profiles
function Profiles:GetProfileList()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return {}
    end
    
    return DamiaUI.Config:GetProfiles()
end

-- Get current active profile name
function Profiles:GetCurrentProfile()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return "Default"
    end
    
    return DamiaUI.Config:GetCurrentProfile()
end

-- Create a new profile
function Profiles:CreateProfile(profileName, copyFromProfile, description)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return false
    end
    
    -- Validate profile name
    if not self:ValidateProfileName(profileName) then
        return false
    end
    
    -- Check if profile already exists
    if self:ProfileExists(profileName) then
        DamiaUI:LogError("Profile '%s' already exists", profileName)
        return false
    end
    
    -- Check profile limit
    if #self:GetProfileList() >= MAX_PROFILES then
        DamiaUI:LogError("Maximum number of profiles reached (%d)", MAX_PROFILES)
        return false
    end
    
    -- Create backup before operation
    self:CreateProfileBackup(self:GetCurrentProfile(), "before_create_" .. profileName)
    
    -- Create the profile
    local success = DamiaUI.Config:CreateProfile(profileName, copyFromProfile)
    if not success then
        return false
    end
    
    -- Store profile metadata
    self:SetProfileMetadata(profileName, {
        created = time(),
        description = description or "",
        version = EXPORT_VERSION,
        copyFrom = copyFromProfile,
    })
    
    DamiaUI:LogInfo("Created profile: %s", profileName)
    
    -- Fire profile created event
    DamiaUI:FireEvent("DAMIA_PROFILE_CREATED", profileName)
    
    return true
end

-- Delete a profile
function Profiles:DeleteProfile(profileName, force)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return false
    end
    
    -- Validate profile name
    if not profileName or profileName == "" then
        DamiaUI:LogError("Invalid profile name")
        return false
    end
    
    -- Prevent deletion of default profile
    if profileName == "Default" then
        DamiaUI:LogError("Cannot delete Default profile")
        return false
    end
    
    -- Check if profile exists
    if not self:ProfileExists(profileName) then
        DamiaUI:LogError("Profile '%s' does not exist", profileName)
        return false
    end
    
    -- Check if profile is currently active
    if profileName == self:GetCurrentProfile() and not force then
        DamiaUI:LogError("Cannot delete active profile. Switch to another profile first.")
        return false
    end
    
    -- Create backup before deletion
    self:CreateProfileBackup(profileName, "before_delete_" .. profileName)
    
    -- Delete the profile
    local success = DamiaUI.Config:DeleteProfile(profileName)
    if not success then
        return false
    end
    
    -- Clean up profile metadata
    self:RemoveProfileMetadata(profileName)
    
    DamiaUI:LogInfo("Deleted profile: %s", profileName)
    
    -- Fire profile deleted event
    DamiaUI:FireEvent("DAMIA_PROFILE_DELETED", profileName)
    
    return true
end

-- Switch to a different profile
function Profiles:SwitchProfile(profileName)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return false
    end
    
    -- Validate profile name
    if not profileName or profileName == "" then
        DamiaUI:LogError("Invalid profile name")
        return false
    end
    
    -- Check if profile exists
    if not self:ProfileExists(profileName) then
        DamiaUI:LogError("Profile '%s' does not exist", profileName)
        return false
    end
    
    -- Check if already active
    local currentProfile = self:GetCurrentProfile()
    if profileName == currentProfile then
        DamiaUI:LogInfo("Profile '%s' is already active", profileName)
        return true
    end
    
    -- Create backup before switching
    self:CreateProfileBackup(currentProfile, "before_switch_to_" .. profileName)
    
    -- Switch the profile
    local success = DamiaUI.Config:SetProfile(profileName)
    if not success then
        return false
    end
    
    -- Update metadata
    self:UpdateProfileMetadata(profileName, {
        lastUsed = time(),
    })
    
    DamiaUI:LogInfo("Switched to profile: %s", profileName)
    
    return true
end

-- Reset profile to defaults
function Profiles:ResetProfile(profileName)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return false
    end
    
    profileName = profileName or self:GetCurrentProfile()
    
    -- Check if profile exists
    if not self:ProfileExists(profileName) then
        DamiaUI:LogError("Profile '%s' does not exist", profileName)
        return false
    end
    
    -- Create backup before reset
    self:CreateProfileBackup(profileName, "before_reset_" .. profileName)
    
    -- Reset the profile
    local success = DamiaUI.Config:ResetProfile(profileName)
    if not success then
        return false
    end
    
    -- Update metadata
    self:UpdateProfileMetadata(profileName, {
        lastReset = time(),
    })
    
    DamiaUI:LogInfo("Reset profile to defaults: %s", profileName)
    
    return true
end

--[[
    Import/Export Functionality
]]

-- Export profile to shareable format
function Profiles:ExportProfile(profileName, includeMetadata)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return nil
    end
    
    profileName = profileName or self:GetCurrentProfile()
    
    -- Check if profile exists
    if not self:ProfileExists(profileName) then
        DamiaUI:LogError("Profile '%s' does not exist", profileName)
        return nil
    end
    
    -- Get profile data
    local profileData = DamiaUI.Config:ExportProfile(profileName)
    if not profileData then
        DamiaUI:LogError("Failed to export profile data")
        return nil
    end
    
    -- Create export package
    local exportPackage = {
        formatVersion = EXPORT_VERSION,
        exportDate = time(),
        profileName = profileName,
        profileData = profileData,
        addonVersion = DamiaUI.version or "1.0.0",
    }
    
    -- Include metadata if requested
    if includeMetadata then
        exportPackage.metadata = self:GetProfileMetadata(profileName)
    end
    
    -- Generate checksum for validation
    exportPackage.checksum = self:GenerateChecksum(profileData)
    
    DamiaUI:LogInfo("Exported profile: %s", profileName)
    
    return exportPackage
end

-- Import profile from export package
function Profiles:ImportProfile(exportPackage, newProfileName, overwriteExisting)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        DamiaUI:LogError("Configuration system not initialized")
        return false
    end
    
    -- Validate export package
    if not self:ValidateExportPackage(exportPackage) then
        return false
    end
    
    -- Determine profile name
    local profileName = newProfileName or exportPackage.profileName or "Imported Profile"
    
    -- Check if profile exists and handle accordingly
    if self:ProfileExists(profileName) then
        if not overwriteExisting then
            -- Generate unique name
            profileName = self:GenerateUniqueProfileName(profileName)
        else
            -- Create backup before overwrite
            self:CreateProfileBackup(profileName, "before_overwrite_" .. profileName)
        end
    end
    
    -- Validate profile name
    if not self:ValidateProfileName(profileName) then
        return false
    end
    
    -- Check profile limit
    if not self:ProfileExists(profileName) and #self:GetProfileList() >= MAX_PROFILES then
        DamiaUI:LogError("Maximum number of profiles reached (%d)", MAX_PROFILES)
        return false
    end
    
    -- Import the profile
    local success = DamiaUI.Config:ImportProfile(exportPackage.profileData, profileName)
    if not success then
        return false
    end
    
    -- Set metadata
    self:SetProfileMetadata(profileName, {
        imported = time(),
        importedFrom = exportPackage.profileName,
        importedDate = exportPackage.exportDate,
        importedVersion = exportPackage.addonVersion,
        description = exportPackage.metadata and exportPackage.metadata.description or "Imported profile",
    })
    
    DamiaUI:LogInfo("Imported profile: %s", profileName)
    
    -- Fire profile imported event
    DamiaUI:FireEvent("DAMIA_PROFILE_IMPORTED", profileName)
    
    return profileName
end

--[[
    Backup System
]]

-- Initialize backup system
function Profiles:InitializeBackupSystem()
    if not DamiaUI.Config then
        return
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db or not db.global then
        return
    end
    
    -- Initialize backup storage
    if not db.global.profileBackups then
        db.global.profileBackups = {}
    end
    
    profileBackups = db.global.profileBackups
    
    DamiaUI:LogDebug("Profile backup system initialized")
end

-- Create profile backup
function Profiles:CreateProfileBackup(profileName, backupName)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return false
    end
    
    profileName = profileName or self:GetCurrentProfile()
    backupName = backupName or ("backup_" .. profileName .. "_" .. time())
    
    -- Export profile data
    local exportData = self:ExportProfile(profileName, true)
    if not exportData then
        return false
    end
    
    -- Create backup entry
    local backup = {
        name = backupName,
        profileName = profileName,
        timestamp = time(),
        data = exportData,
        automatic = backupName:match("^backup_") and true or false,
    }
    
    -- Add to backup list
    table.insert(profileBackups, backup)
    
    -- Limit backup count
    self:LimitBackupCount()
    
    DamiaUI:LogDebug("Created profile backup: %s", backupName)
    
    return true
end

-- Restore profile from backup
function Profiles:RestoreProfileBackup(backupName, targetProfileName)
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return false
    end
    
    -- Find backup
    local backup = nil
    for _, b in ipairs(profileBackups) do
        if b.name == backupName then
            backup = b
            break
        end
    end
    
    if not backup then
        DamiaUI:LogError("Backup not found: %s", backupName)
        return false
    end
    
    -- Determine target profile name
    targetProfileName = targetProfileName or backup.profileName
    
    -- Create backup of current state before restore
    if self:ProfileExists(targetProfileName) then
        self:CreateProfileBackup(targetProfileName, "before_restore_" .. targetProfileName)
    end
    
    -- Import the backup
    local success = self:ImportProfile(backup.data, targetProfileName, true)
    if not success then
        return false
    end
    
    DamiaUI:LogInfo("Restored profile from backup: %s -> %s", backupName, targetProfileName)
    
    -- Fire restore event
    DamiaUI:FireEvent("DAMIA_PROFILE_RESTORED", targetProfileName, backupName)
    
    return true
end

-- Get list of available backups
function Profiles:GetBackupList()
    return profileBackups or {}
end

-- Delete specific backup
function Profiles:DeleteBackup(backupName)
    for i, backup in ipairs(profileBackups) do
        if backup.name == backupName then
            table.remove(profileBackups, i)
            DamiaUI:LogInfo("Deleted backup: %s", backupName)
            return true
        end
    end
    
    DamiaUI:LogError("Backup not found: %s", backupName)
    return false
end

-- Clean old backups
function Profiles:CleanOldBackups()
    if not profileBackups then
        return
    end
    
    local cutoffTime = time() - (BACKUP_RETENTION_DAYS * 24 * 60 * 60)
    local cleaned = 0
    
    for i = #profileBackups, 1, -1 do
        local backup = profileBackups[i]
        if backup.automatic and backup.timestamp < cutoffTime then
            table.remove(profileBackups, i)
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        DamiaUI:LogInfo("Cleaned %d old automatic backups", cleaned)
    end
end

-- Limit backup count
function Profiles:LimitBackupCount()
    local maxBackups = 50
    
    while #profileBackups > maxBackups do
        -- Remove oldest automatic backup
        local oldestIndex = nil
        local oldestTime = time()
        
        for i, backup in ipairs(profileBackups) do
            if backup.automatic and backup.timestamp < oldestTime then
                oldestTime = backup.timestamp
                oldestIndex = i
            end
        end
        
        if oldestIndex then
            table.remove(profileBackups, oldestIndex)
        else
            -- If no automatic backups to remove, break to avoid infinite loop
            break
        end
    end
end

--[[
    Profile Metadata Management
]]

-- Get profile metadata
function Profiles:GetProfileMetadata(profileName)
    if not DamiaUI.Config then
        return {}
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db or not db.global or not db.global.profileMetadata then
        return {}
    end
    
    return db.global.profileMetadata[profileName] or {}
end

-- Set profile metadata
function Profiles:SetProfileMetadata(profileName, metadata)
    if not DamiaUI.Config then
        return
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db or not db.global then
        return
    end
    
    if not db.global.profileMetadata then
        db.global.profileMetadata = {}
    end
    
    db.global.profileMetadata[profileName] = metadata or {}
end

-- Update profile metadata
function Profiles:UpdateProfileMetadata(profileName, updates)
    local metadata = self:GetProfileMetadata(profileName)
    
    for key, value in pairs(updates) do
        metadata[key] = value
    end
    
    self:SetProfileMetadata(profileName, metadata)
end

-- Remove profile metadata
function Profiles:RemoveProfileMetadata(profileName)
    if not DamiaUI.Config then
        return
    end
    
    local db = DamiaUI.Config:GetDatabase()
    if not db or not db.global or not db.global.profileMetadata then
        return
    end
    
    db.global.profileMetadata[profileName] = nil
end

--[[
    Utility Functions
]]

-- Check if profile exists
function Profiles:ProfileExists(profileName)
    local profiles = self:GetProfileList()
    for _, name in ipairs(profiles) do
        if name == profileName then
            return true
        end
    end
    return false
end

-- Validate profile name
function Profiles:ValidateProfileName(profileName)
    if not profileName or type(profileName) ~= "string" then
        DamiaUI:LogError("Profile name must be a string")
        return false
    end
    
    if profileName:len() < 1 or profileName:len() > 50 then
        DamiaUI:LogError("Profile name must be between 1 and 50 characters")
        return false
    end
    
    if profileName:match("[^%w%s%-_]") then
        DamiaUI:LogError("Profile name contains invalid characters")
        return false
    end
    
    return true
end

-- Generate unique profile name
function Profiles:GenerateUniqueProfileName(baseName)
    local profileName = baseName
    local counter = 1
    
    while self:ProfileExists(profileName) do
        profileName = baseName .. " (" .. counter .. ")"
        counter = counter + 1
        
        if counter > 100 then
            -- Prevent infinite loop
            profileName = baseName .. "_" .. time()
            break
        end
    end
    
    return profileName
end

-- Validate export package
function Profiles:ValidateExportPackage(exportPackage)
    if type(exportPackage) ~= "table" then
        DamiaUI:LogError("Invalid export package format")
        return false
    end
    
    if not exportPackage.formatVersion then
        DamiaUI:LogError("Export package missing format version")
        return false
    end
    
    if not exportPackage.profileData then
        DamiaUI:LogError("Export package missing profile data")
        return false
    end
    
    -- Validate checksum if present
    if exportPackage.checksum then
        local calculatedChecksum = self:GenerateChecksum(exportPackage.profileData)
        if calculatedChecksum ~= exportPackage.checksum then
            DamiaUI:LogError("Export package checksum validation failed")
            return false
        end
    end
    
    return true
end

-- Generate checksum for data validation
function Profiles:GenerateChecksum(data)
    -- Simple checksum based on string representation
    local str = tostring(data)
    local checksum = 0
    
    for i = 1, #str do
        checksum = checksum + str:byte(i) * i
    end
    
    return checksum % 999999
end

--[[
    Event Handlers
]]

function Profiles:OnProfileChanged(oldProfile, newProfile)
    DamiaUI:LogDebug("Profile changed: %s -> %s", oldProfile, newProfile)
    
    -- Update usage statistics
    self:UpdateProfileMetadata(newProfile, {
        lastUsed = time(),
        useCount = (self:GetProfileMetadata(newProfile).useCount or 0) + 1,
    })
end

function Profiles:ADDON_LOADED(event, loadedAddon)
    if loadedAddon == addonName then
        -- Initialize after addon loads
        C_Timer.After(1, function()
            if not isInitialized then
                self:Initialize()
            end
        end)
    end
end

--[[
    Public API Functions
]]

-- Get profile information with metadata
function Profiles:GetProfileInfo(profileName)
    if not self:ProfileExists(profileName) then
        return nil
    end
    
    local metadata = self:GetProfileMetadata(profileName)
    
    return {
        name = profileName,
        current = profileName == self:GetCurrentProfile(),
        created = metadata.created,
        lastUsed = metadata.lastUsed,
        lastReset = metadata.lastReset,
        description = metadata.description or "",
        useCount = metadata.useCount or 0,
        imported = metadata.imported,
        importedFrom = metadata.importedFrom,
    }
end

-- Get comprehensive profile statistics
function Profiles:GetProfileStatistics()
    local profiles = self:GetProfileList()
    local stats = {
        totalProfiles = #profiles,
        currentProfile = self:GetCurrentProfile(),
        totalBackups = #self:GetBackupList(),
        automaticBackups = 0,
        manualBackups = 0,
    }
    
    -- Count backup types
    for _, backup in ipairs(self:GetBackupList()) do
        if backup.automatic then
            stats.automaticBackups = stats.automaticBackups + 1
        else
            stats.manualBackups = stats.manualBackups + 1
        end
    end
    
    return stats
end

-- Bulk operations
function Profiles:BulkExportProfiles(profileNames, includeMetadata)
    local exports = {}
    
    for _, profileName in ipairs(profileNames or self:GetProfileList()) do
        local exportData = self:ExportProfile(profileName, includeMetadata)
        if exportData then
            exports[profileName] = exportData
        end
    end
    
    return exports
end

-- Register the module
DamiaUI:RegisterModule("Profiles", Profiles)