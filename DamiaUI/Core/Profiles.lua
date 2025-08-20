-- DamiaUI Profile Management
-- Based on ColdUI profile system

local addonName, ns = ...

-- Profile system
ns.profiles = {}

-- Default profiles from ColdUI
ns.profiles.default = {
    name = "Default",
    data = ns.configDefaults
}

ns.profiles.minimal = {
    name = "Minimal",
    data = {
        actionbar = {
            size = 32,
            spacing = 2,
            bar3 = { enable = false },
            bar4 = { enable = false },
            bar5 = { enable = false },
        },
        unitframes = {
            scale = 0.9,
        },
        minimap = {
            scale = 0.9,
            size = 120,
        },
    }
}

ns.profiles.raid = {
    name = "Raid",
    data = {
        actionbar = {
            size = 30,
            spacing = 2,
        },
        unitframes = {
            scale = 0.8,
            raid = {
                width = 60,
                height = 20,
            },
        },
    }
}

-- Load profile
function ns:LoadProfile(profileName)
    if ns.profiles[profileName] then
        local profile = ns.profiles[profileName]
        
        -- Apply profile data
        for category, settings in pairs(profile.data) do
            for key, value in pairs(settings) do
                ns:SetConfig(category, key, value)
            end
        end
        
        ns:Print("Profile '" .. profile.name .. "' loaded")
        ReloadUI()
    else
        ns:Print("Profile '" .. profileName .. "' not found")
    end
end

-- Save current settings as profile
function ns:SaveProfile(profileName)
    ns.profiles[profileName] = {
        name = profileName,
        data = CopyTable(DamiaUIDB)
    }
    
    -- Save to character DB
    if not DamiaUICharDB.profiles then
        DamiaUICharDB.profiles = {}
    end
    DamiaUICharDB.profiles[profileName] = ns.profiles[profileName]
    
    ns:Print("Profile '" .. profileName .. "' saved")
end

-- Delete profile
function ns:DeleteProfile(profileName)
    if profileName == "default" then
        ns:Print("Cannot delete default profile")
        return
    end
    
    ns.profiles[profileName] = nil
    if DamiaUICharDB.profiles then
        DamiaUICharDB.profiles[profileName] = nil
    end
    
    ns:Print("Profile '" .. profileName .. "' deleted")
end

-- List profiles
function ns:ListProfiles()
    ns:Print("Available profiles:")
    for name, profile in pairs(ns.profiles) do
        print("  - " .. profile.name)
    end
end

-- Initialize profiles on load
function ns:InitializeProfiles()
    -- Load saved profiles from character DB
    if DamiaUICharDB.profiles then
        for name, profile in pairs(DamiaUICharDB.profiles) do
            ns.profiles[name] = profile
        end
    end
end