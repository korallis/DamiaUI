-- DamiaUI Profile Management System
-- Comprehensive AceDB-3.0 based profile management for WoW addons
-- Supports multiple profile types with import/export and callbacks

local addonName, ns = ...

-- Ensure AceDB-3.0 is available
local LibStub = _G.LibStub
local AceDB = LibStub and LibStub("AceDB-3.0", true)
if not AceDB then
    -- Create fallback profile system when AceDB is not available
    ns.Profiles = {
        initialized = false,
        Initialize = function() end,
        GetCurrentProfile = function() return "Default" end,
        GetProfiles = function() return {"Default"} end,
        SetProfile = function() return false end,
        CreateProfile = function() return false end,
        DeleteProfile = function() return false end,
        CopyProfile = function() return false end,
        ResetProfile = function() return false end,
        GetProfileInfo = function() return nil end,
        GetProfileConfig = function() return nil end,
        ExportProfile = function() return nil end,
        ImportProfile = function() return false end,
        RegisterCallback = function() end,
        FireCallback = function() end,
        GetAPI = function()
            return {
                GetCurrentProfile = function() return "Default" end,
                GetProfiles = function() return {"Default"} end,
                SetProfile = function() return false end,
            }
        end
    }
    ns:Print("Warning: AceDB-3.0 not found. Profile system disabled.")
    return
end

-- Profile system namespace
ns.Profiles = {}
local Profiles = ns.Profiles

-- Profile type constants
Profiles.PROFILE_GLOBAL = "global"
Profiles.PROFILE_CHAR = "char"
Profiles.PROFILE_CLASS = "class"
Profiles.PROFILE_SPEC = "spec"
Profiles.PROFILE_FACTION = "faction"
Profiles.PROFILE_REALM = "realm"

-- Profile management state
Profiles.db = nil
Profiles.callbacks = {}
Profiles.initialized = false
Profiles.profileKeys = {}

-- Default profile configurations
Profiles.defaultProfiles = {
    ["DamiaUI - Default"] = {
        description = "Default DamiaUI profile with standard settings",
        priority = 100,
        config = {}  -- Will be populated from ns.configDefaults
    },
    ["DamiaUI - Minimal"] = {
        description = "Minimal layout for maximum screen space",
        priority = 90,
        config = {
            actionbar = {
                size = 32,
                spacing = 2,
                bar3 = { enable = false },
                bar4 = { enable = false },
                bar5 = { enable = false },
            },
            unitframes = {
                scale = 0.9,
                player = { width = 200, height = 28 },
                target = { width = 200, height = 28 },
            },
            minimap = {
                scale = 0.9,
                size = 120,
            },
        }
    },
    ["DamiaUI - Raid"] = {
        description = "Optimized for raid environments with compact frames",
        priority = 80,
        config = {
            actionbar = {
                size = 30,
                spacing = 1,
            },
            unitframes = {
                scale = 0.8,
                raid = {
                    width = 60,
                    height = 20,
                },
                party = {
                    width = 100,
                    height = 22,
                },
            },
        }
    }
}

-- Initialize the profile system
function Profiles:Initialize()
    if self.initialized then
        ns:Debug("Profiles already initialized")
        return
    end
    
    -- Create database structure
    local dbDefaults = {
        global = {
            profileData = {}, -- Store custom profile configurations
            exportedProfiles = {}, -- Store exported profile strings
            version = 1,
        },
        profile = {}, -- Will be populated with config defaults
        char = {
            selectedProfile = nil,
            profileHistory = {},
        },
        class = {},
        faction = {},
        realm = {},
    }
    
    -- Populate profile defaults with config defaults
    -- Use a basic set of defaults if configDefaults is not yet available
    if ns.configDefaults then
        dbDefaults.profile = CopyTable(ns.configDefaults)
    else
        -- Basic defaults that will be updated later
        dbDefaults.profile = {
            actionbar = { enabled = true },
            unitframes = { enabled = true },
            minimap = { enabled = true },
            chat = { enabled = true },
            nameplates = { enabled = true },
            datatexts = { enabled = true },
            misc = { autoRepair = true }
        }
    end
    
    -- Create AceDB database
    self.db = AceDB:New("DamiaUIProfileDB", dbDefaults, true)
    
    if not self.db then
        error("DamiaUI: Failed to initialize profile database!")
        return
    end
    
    -- Setup profile change callback
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
    self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileDeleted")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    
    -- Initialize default profiles
    self:InitializeDefaultProfiles()
    
    -- Set up profile keys
    self:RefreshProfileKeys()
    
    self.initialized = true
    ns:Debug("Profile system initialized successfully")
    
    -- Fire initialization callback
    self:FireCallback("OnInitialized")
end

-- Initialize default profiles in the database
function Profiles:InitializeDefaultProfiles()
    if not self.db then return end
    
    local profileData = self.db.global.profileData
    
    -- Add default profiles if they don't exist
    for profileName, profileInfo in pairs(self.defaultProfiles) do
        if not profileData[profileName] then
            profileData[profileName] = {
                name = profileName,
                description = profileInfo.description,
                author = "DamiaUI",
                version = ns.version or "1.0.0",
                created = time(),
                priority = profileInfo.priority,
                protected = true, -- Prevent deletion of default profiles
                config = profileInfo.config,
            }
        end
    end
end

-- Refresh available profile keys
function Profiles:RefreshProfileKeys()
    if not self.db then return end
    
    self.profileKeys = {}
    
    -- Add AceDB profiles
    for profileKey in pairs(self.db.profiles) do
        table.insert(self.profileKeys, profileKey)
    end
    
    -- Add custom profiles
    for profileName in pairs(self.db.global.profileData) do
        if not tContains(self.profileKeys, profileName) then
            table.insert(self.profileKeys, profileName)
        end
    end
    
    table.sort(self.profileKeys)
end

-- Get current profile name
function Profiles:GetCurrentProfile()
    if not self.db then return "Default" end
    return self.db:GetCurrentProfile()
end

-- Get all available profile names
function Profiles:GetProfiles()
    self:RefreshProfileKeys()
    return self.profileKeys
end

-- Get profile information
function Profiles:GetProfileInfo(profileName)
    if not self.db or not profileName then return nil end
    
    local profileData = self.db.global.profileData[profileName]
    if profileData then
        return {
            name = profileData.name,
            description = profileData.description,
            author = profileData.author,
            version = profileData.version,
            created = profileData.created,
            modified = profileData.modified,
            protected = profileData.protected,
            priority = profileData.priority or 0,
        }
    end
    
    -- Check if it's an AceDB profile
    if self.db.profiles[profileName] then
        return {
            name = profileName,
            description = "Standard profile",
            author = "User",
            version = "1.0.0",
            created = time(),
            protected = false,
            priority = 0,
        }
    end
    
    return nil
end

-- Create a new profile
function Profiles:CreateProfile(profileName, description, baseProfile)
    if not self.db or not profileName or profileName == "" then
        ns:Print("Invalid profile name")
        return false
    end
    
    -- Check if profile already exists
    if self.db.profiles[profileName] or self.db.global.profileData[profileName] then
        ns:Print("Profile '" .. profileName .. "' already exists")
        return false
    end
    
    -- Create base config
    local config = {}
    if baseProfile and baseProfile ~= "" then
        -- Copy from base profile
        local baseConfig = self:GetProfileConfig(baseProfile)
        if baseConfig then
            config = CopyTable(baseConfig)
        end
    else
        -- Use current config
        config = CopyTable(self.db.profile)
    end
    
    -- Store custom profile data
    self.db.global.profileData[profileName] = {
        name = profileName,
        description = description or ("Custom profile: " .. profileName),
        author = UnitName("player") or "Unknown",
        version = ns.version or "1.0.0",
        created = time(),
        protected = false,
        priority = 50,
        config = config,
    }
    
    -- Create AceDB profile
    self.db:SetProfile(profileName)
    
    -- Apply the config
    self:ApplyProfileConfig(config)
    
    self:RefreshProfileKeys()
    ns:Print("Created profile: " .. profileName)
    
    self:FireCallback("OnProfileCreated", profileName)
    return true
end

-- Switch to a profile
function Profiles:SetProfile(profileName)
    if not self.db or not profileName then
        ns:Print("Invalid profile name")
        return false
    end
    
    local oldProfile = self:GetCurrentProfile()
    
    -- Check if it's a custom profile
    local customProfile = self.db.global.profileData[profileName]
    if customProfile then
        -- Switch to AceDB profile (create if necessary)
        self.db:SetProfile(profileName)
        
        -- Apply custom configuration
        if customProfile.config then
            self:ApplyProfileConfig(customProfile.config)
        end
    else
        -- Standard AceDB profile switch
        self.db:SetProfile(profileName)
    end
    
    -- Update character profile history
    local history = self.db.char.profileHistory
    if not history then
        history = {}
        self.db.char.profileHistory = history
    end
    
    table.insert(history, 1, {
        profile = profileName,
        switched = time(),
        from = oldProfile,
    })
    
    -- Keep only last 10 entries
    while #history > 10 do
        table.remove(history)
    end
    
    self.db.char.selectedProfile = profileName
    self:RefreshProfileKeys()
    
    ns:Print("Switched to profile: " .. profileName)
    
    return true
end

-- Apply profile configuration to current settings
function Profiles:ApplyProfileConfig(config)
    if not config then return end
    
    -- Deep merge configuration
    for category, settings in pairs(config) do
        if type(settings) == "table" then
            if not self.db.profile[category] then
                self.db.profile[category] = {}
            end
            
            for key, value in pairs(settings) do
                self.db.profile[category][key] = value
            end
        else
            self.db.profile[category] = settings
        end
    end
    
    -- Update ns.config reference
    if ns.config then
        for category, settings in pairs(config) do
            if type(settings) == "table" then
                if not ns.config[category] then
                    ns.config[category] = {}
                end
                
                for key, value in pairs(settings) do
                    ns.config[category][key] = value
                end
            else
                ns.config[category] = settings
            end
        end
    end
end

-- Get profile configuration
function Profiles:GetProfileConfig(profileName)
    if not self.db or not profileName then return nil end
    
    -- Check custom profiles first
    local customProfile = self.db.global.profileData[profileName]
    if customProfile and customProfile.config then
        return customProfile.config
    end
    
    -- Check AceDB profile
    if self.db.profiles[profileName] then
        return self.db.profiles[profileName]
    end
    
    return nil
end

-- Copy profile
function Profiles:CopyProfile(sourceProfile, targetProfile)
    if not self.db or not sourceProfile or not targetProfile then
        ns:Print("Invalid profile names")
        return false
    end
    
    if sourceProfile == targetProfile then
        ns:Print("Cannot copy profile to itself")
        return false
    end
    
    -- Get source configuration
    local sourceConfig = self:GetProfileConfig(sourceProfile)
    if not sourceConfig then
        ns:Print("Source profile not found: " .. sourceProfile)
        return false
    end
    
    -- Copy via AceDB
    self.db:CopyProfile(sourceProfile, true)
    
    -- Update custom profile data if target exists
    local targetCustom = self.db.global.profileData[targetProfile]
    if targetCustom then
        targetCustom.config = CopyTable(sourceConfig)
        targetCustom.modified = time()
    end
    
    ns:Print("Copied profile '" .. sourceProfile .. "' to '" .. targetProfile .. "'")
    
    self:FireCallback("OnProfileCopied", sourceProfile, targetProfile)
    return true
end

-- Delete profile
function Profiles:DeleteProfile(profileName, force)
    if not self.db or not profileName then
        ns:Print("Invalid profile name")
        return false
    end
    
    -- Check if profile is protected
    local profileInfo = self:GetProfileInfo(profileName)
    if profileInfo and profileInfo.protected and not force then
        ns:Print("Cannot delete protected profile: " .. profileName)
        return false
    end
    
    -- Cannot delete current profile
    if profileName == self:GetCurrentProfile() then
        ns:Print("Cannot delete active profile. Switch to another profile first.")
        return false
    end
    
    -- Delete custom profile data
    if self.db.global.profileData[profileName] then
        self.db.global.profileData[profileName] = nil
    end
    
    -- Delete AceDB profile
    self.db:DeleteProfile(profileName, true)
    
    self:RefreshProfileKeys()
    ns:Print("Deleted profile: " .. profileName)
    
    self:FireCallback("OnProfileDeleted", profileName)
    return true
end

-- Reset profile to defaults
function Profiles:ResetProfile(profileName)
    if not self.db then return false end
    
    profileName = profileName or self:GetCurrentProfile()
    
    -- Reset AceDB profile
    self.db:ResetProfile(true)
    
    -- Reset custom profile if it exists
    local customProfile = self.db.global.profileData[profileName]
    if customProfile then
        customProfile.config = CopyTable(ns.configDefaults or {})
        customProfile.modified = time()
        
        -- Apply the reset configuration
        self:ApplyProfileConfig(customProfile.config)
    end
    
    ns:Print("Reset profile: " .. profileName)
    
    self:FireCallback("OnProfileReset", profileName)
    return true
end

-- Export profile to string
function Profiles:ExportProfile(profileName)
    if not self.db then return nil end
    
    profileName = profileName or self:GetCurrentProfile()
    
    local profileConfig = self:GetProfileConfig(profileName)
    if not profileConfig then
        ns:Print("Profile not found: " .. profileName)
        return nil
    end
    
    local profileInfo = self:GetProfileInfo(profileName) or {}
    
    local exportData = {
        name = profileName,
        description = profileInfo.description,
        author = profileInfo.author,
        version = profileInfo.version,
        exported = time(),
        config = profileConfig,
    }
    
    -- Serialize the data using AceSerializer
    local AceSerializer = LibStub and LibStub("AceSerializer-3.0", true)
    if not AceSerializer then
        ns:Print("AceSerializer not available for export")
        return nil
    end
    
    local serialized = AceSerializer:Serialize(exportData)
    if not serialized then
        ns:Print("Failed to serialize profile data")
        return nil
    end
    
    -- Store in global exported profiles
    self.db.global.exportedProfiles[profileName] = {
        data = serialized,
        exported = time(),
        version = ns.version,
    }
    
    ns:Print("Exported profile: " .. profileName)
    return serialized
end

-- Import profile from string
function Profiles:ImportProfile(importString, profileName)
    if not self.db or not importString or importString == "" then
        ns:Print("Invalid import string")
        return false
    end
    
    -- Deserialize the data
    local AceSerializer = LibStub and LibStub("AceSerializer-3.0", true)
    if not AceSerializer then
        ns:Print("AceSerializer not available for import")
        return false
    end
    
    local success, exportData = AceSerializer:Deserialize(importString)
    if not success then
        ns:Print("Failed to deserialize import data")
        return false
    end
    
    -- Validate import data structure
    if type(exportData) ~= "table" or not exportData.name or not exportData.config then
        ns:Print("Invalid profile data structure")
        return false
    end
    
    -- Use provided name or original name
    local newProfileName = profileName or exportData.name
    if not newProfileName or newProfileName == "" then
        ns:Print("Invalid profile name in import data")
        return false
    end
    
    -- Check if profile exists
    if self:GetProfileInfo(newProfileName) then
        ns:Print("Profile already exists: " .. newProfileName .. ". Use a different name.")
        return false
    end
    
    -- Create the profile
    local success = self:CreateProfile(
        newProfileName,
        exportData.description or "Imported profile",
        nil
    )
    
    if success then
        -- Apply the imported configuration
        if exportData.config then
            self:ApplyProfileConfig(exportData.config)
            
            -- Update the stored config
            local customProfile = self.db.global.profileData[newProfileName]
            if customProfile then
                customProfile.config = CopyTable(exportData.config)
                customProfile.author = exportData.author or "Unknown"
                customProfile.version = exportData.version or "1.0.0"
                customProfile.modified = time()
            end
        end
        
        ns:Print("Imported profile: " .. newProfileName)
        self:FireCallback("OnProfileImported", newProfileName)
        return true
    end
    
    return false
end

-- Register callback function
function Profiles:RegisterCallback(event, handler)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    
    table.insert(self.callbacks[event], handler)
end

-- Fire callback event
function Profiles:FireCallback(event, ...)
    if not self.callbacks[event] then return end
    
    for _, handler in ipairs(self.callbacks[event]) do
        if type(handler) == "function" then
            local success, err = pcall(handler, ...)
            if not success then
                ns:Print("Profile callback error:", err)
            end
        end
    end
end

-- AceDB Callbacks
function Profiles:OnProfileChanged(event, database, newProfileKey)
    ns:Print("Profile changed to: " .. newProfileKey)
    
    -- Update ns.config
    ns.config = database.profile
    
    self:FireCallback("OnProfileChanged", newProfileKey)
    
    -- Reload UI to apply changes
    C_Timer.After(0.1, function()
        if ns.ReloadModules then
            ns:ReloadModules()
        end
    end)
end

function Profiles:OnProfileCopied(event, database, sourceProfileKey)
    ns:Debug("Profile copied from: " .. sourceProfileKey)
    self:FireCallback("OnProfileCopied", sourceProfileKey, self:GetCurrentProfile())
end

function Profiles:OnProfileDeleted(event, database, deletedProfileKey)
    ns:Debug("Profile deleted: " .. deletedProfileKey)
    self:FireCallback("OnProfileDeleted", deletedProfileKey)
end

function Profiles:OnProfileReset(event, database)
    ns:Debug("Profile reset: " .. self:GetCurrentProfile())
    self:FireCallback("OnProfileReset", self:GetCurrentProfile())
end

-- Get profile management API for modules
function Profiles:GetAPI()
    return {
        -- Core functions
        GetCurrentProfile = function() return self:GetCurrentProfile() end,
        GetProfiles = function() return self:GetProfiles() end,
        SetProfile = function(name) return self:SetProfile(name) end,
        
        -- Profile management
        CreateProfile = function(name, desc, base) return self:CreateProfile(name, desc, base) end,
        DeleteProfile = function(name, force) return self:DeleteProfile(name, force) end,
        CopyProfile = function(source, target) return self:CopyProfile(source, target) end,
        ResetProfile = function(name) return self:ResetProfile(name) end,
        
        -- Profile info
        GetProfileInfo = function(name) return self:GetProfileInfo(name) end,
        GetProfileConfig = function(name) return self:GetProfileConfig(name) end,
        
        -- Import/Export
        ExportProfile = function(name) return self:ExportProfile(name) end,
        ImportProfile = function(str, name) return self:ImportProfile(str, name) end,
        
        -- Callbacks
        RegisterCallback = function(event, handler) return self:RegisterCallback(event, handler) end,
    }
end

-- Update profile defaults after configDefaults is available
function Profiles:UpdateDefaults()
    if not self.db or not ns.configDefaults then return end
    
    -- Merge config defaults into current profile
    for category, settings in pairs(ns.configDefaults) do
        if not self.db.profile[category] then
            self.db.profile[category] = {}
        end
        for key, value in pairs(settings) do
            if self.db.profile[category][key] == nil then
                self.db.profile[category][key] = value
            end
        end
    end
    
    -- Update default profile configurations
    for profileName, profileInfo in pairs(self.defaultProfiles) do
        if profileInfo.config and not profileInfo.config.merged then
            -- Merge with actual config defaults
            local mergedConfig = CopyTable(ns.configDefaults)
            for category, settings in pairs(profileInfo.config) do
                if not mergedConfig[category] then
                    mergedConfig[category] = {}
                end
                for key, value in pairs(settings) do
                    mergedConfig[category][key] = value
                end
            end
            profileInfo.config = mergedConfig
            profileInfo.config.merged = true -- Mark as merged
            
            -- Update stored profile data
            if self.db.global.profileData[profileName] then
                self.db.global.profileData[profileName].config = CopyTable(mergedConfig)
            end
        end
    end
end

-- Initialize on addon loaded (called from Init.lua)
function ns:InitializeProfiles()
    if not Profiles.initialized then
        Profiles:Initialize()
        
        -- Update defaults if configDefaults is now available
        if ns.configDefaults then
            Profiles:UpdateDefaults()
        end
    end
    
    -- Make API available to namespace
    ns.ProfileAPI = Profiles:GetAPI()
    
    return Profiles.initialized
end

-- Legacy compatibility functions
function ns:LoadProfile(profileName)
    if Profiles.initialized then
        return Profiles:SetProfile(profileName)
    else
        ns:Print("Profile system not initialized")
        return false
    end
end

function ns:SaveProfile(profileName)
    if Profiles.initialized then
        return Profiles:CreateProfile(profileName, "Saved profile")
    else
        ns:Print("Profile system not initialized")
        return false
    end
end

function ns:DeleteProfile(profileName)
    if Profiles.initialized then
        return Profiles:DeleteProfile(profileName)
    else
        ns:Print("Profile system not initialized")
        return false
    end
end

function ns:ListProfiles()
    if Profiles.initialized then
        local profiles = Profiles:GetProfiles()
        if #profiles == 0 then
            ns:Print("No profiles available")
        else
            ns:Print("Available profiles (" .. #profiles .. "):")
            for _, name in ipairs(profiles) do
                local info = Profiles:GetProfileInfo(name)
                local status = (name == Profiles:GetCurrentProfile()) and " |cff00FF00(active)|r" or ""
                local protection = (info and info.protected) and " |cffFFAA00[protected]|r" or ""
                print("  " .. name .. status .. protection)
            end
        end
    else
        ns:Print("Profile system not initialized")
    end
end