-- DamiaUI Configuration
-- Handles all configuration settings

local addonName, ns = ...

-- Configuration defaults from ColdUI
ns.configDefaults = {
    -- Action Bars
    actionbar = {
        size = 36,
        spacing = 4,
        scale = 1,
        showgrid = 1,
        showkeybind = 1,
        showmacro = 0,
        mainbar = {
            pos = {"BOTTOM", UIParent, "BOTTOM", 0, 30},
        },
        bar2 = {
            enable = true,
            pos = {"BOTTOM", UIParent, "BOTTOM", 0, 70},
        },
        bar3 = {
            enable = true,
            pos = {"BOTTOM", UIParent, "BOTTOM", 0, 110},
        },
        bar4 = {
            enable = true,
            pos = {"RIGHT", UIParent, "RIGHT", -40, 0},
            orientation = "VERTICAL",
        },
        bar5 = {
            enable = true,
            pos = {"RIGHT", UIParent, "RIGHT", -80, 0},
            orientation = "VERTICAL",
        },
        petbar = {
            size = 28,
            spacing = 4,
            pos = {"BOTTOM", UIParent, "BOTTOM", 0, 150},
        },
        stancebar = {
            size = 32,
            spacing = 4,
            pos = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 150},
        },
        extrabar = {
            size = 40,
            pos = {"BOTTOM", UIParent, "BOTTOM", 0, 200},
        },
    },
    
    -- Unit Frames
    unitframes = {
        scale = 1.1,
        texture = ns.media.texture,
        font = ns.media.font,
        fontSize = 12,
        fontOutline = "OUTLINE",
        player = {
            width = 220,
            height = 30,
            pos = {"BOTTOMRIGHT", UIParent, "BOTTOM", -150, 260},
        },
        target = {
            width = 220,
            height = 30,
            pos = {"BOTTOMLEFT", UIParent, "BOTTOM", 150, 260},
        },
        focus = {
            width = 180,
            height = 25,
            pos = {"BOTTOMRIGHT", UIParent, "BOTTOM", -150, 320},
        },
        party = {
            width = 150,
            height = 25,
            pos = {"TOPLEFT", UIParent, "TOPLEFT", 20, -100},
        },
        raid = {
            width = 80,
            height = 25,
            pos = {"TOPLEFT", UIParent, "TOPLEFT", 20, -200},
        },
        arena = {
            width = 180,
            height = 30,
            pos = {"TOPRIGHT", UIParent, "TOPRIGHT", -100, -200},
        },
    },
    
    -- Minimap
    minimap = {
        scale = 1.1,
        pos = {"TOPRIGHT", UIParent, "TOPRIGHT", -10, -10},
        size = 140,
    },
    
    -- Chat
    chat = {
        font = ns.media.font,
        fontSize = 12,
        tabFont = ns.media.font,
        tabFontSize = 11,
        fadeout = true,
        fadeoutTime = 10,
    },
    
    -- Nameplates
    nameplates = {
        width = 110,
        height = 10,
        texture = ns.media.texture,
        showDebuffs = true,
        showCastbar = true,
    },
    
    -- Data Texts
    datatexts = {
        font = ns.media.font,
        fontSize = 11,
        fontOutline = "OUTLINE",
    },
    
    -- Miscellaneous
    misc = {
        autoRepair = true,
        autoSell = true,
        enhancedTooltips = true,
        hideErrors = false,
        cooldownText = true,
    },
}

-- Apply configuration
function ns:ApplyConfig()
    -- Merge saved config with defaults
    for category, settings in pairs(ns.configDefaults) do
        if not DamiaUIDB[category] then
            DamiaUIDB[category] = {}
        end
        for key, value in pairs(settings) do
            if DamiaUIDB[category][key] == nil then
                DamiaUIDB[category][key] = value
            end
        end
    end
    
    -- Update reference
    ns.config = DamiaUIDB
end

-- Get config value
function ns:GetConfig(category, key)
    if ns.config[category] and ns.config[category][key] ~= nil then
        return ns.config[category][key]
    elseif ns.configDefaults[category] and ns.configDefaults[category][key] ~= nil then
        return ns.configDefaults[category][key]
    end
    return nil
end

-- Set config value
function ns:SetConfig(category, key, value)
    if not ns.config[category] then
        ns.config[category] = {}
    end
    ns.config[category][key] = value
    DamiaUIDB[category][key] = value
end

-- Reset configuration
function ns:ResetConfig()
    DamiaUIDB = {}
    DamiaUICharDB = {}
    ns:ApplyConfig()
end