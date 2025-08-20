-- DamiaUI Core Initialization
-- Based on ColdUI by Coldkil, updated for WoW 11.2

local addonName, ns = ...
_G.DamiaUI = ns

-- Create main addon object
ns.name = addonName
ns.modules = {}
ns.config = {}

-- Initialize media paths BEFORE they're used anywhere (ColdUI textures)
ns.media = {
    font = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\homespun.ttf",
    texture = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\flat2.tga",
    
    -- ColdUI button textures
    gloss = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\gloss.tga",
    glossGrey = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\gloss_grey.tga",
    flash = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\flash.tga",
    hover = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\hover.tga",
    pushed = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\pushed.tga",
    checked = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\checked.tga",
    
    -- ColdUI backgrounds
    buttonBackground = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\button_background.tga",
    buttonBackgroundFlat = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\button_background_flat.tga",
    outerShadow = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\outer_shadow.tga"
}

-- Get addon version using C_AddOns API (11.2 compatible)
if C_AddOns and C_AddOns.GetAddOnMetadata then
    ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unknown"
else
    -- Fallback for older versions
    ns.version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "Unknown"
end

-- Default colors
ns.colors = {
    backdrop = {0.05, 0.05, 0.05, 0.9},
    border = {0.15, 0.15, 0.15, 1},
    health = {0.1, 0.8, 0.1, 1},
    power = {
        ["MANA"] = {0.31, 0.45, 0.63},
        ["RAGE"] = {0.69, 0.31, 0.31},
        ["FOCUS"] = {0.71, 0.43, 0.27},
        ["ENERGY"] = {0.65, 0.63, 0.35},
        ["RUNIC_POWER"] = {0, 0.82, 1},
        ["FURY"] = {0.788, 0.259, 0.992},
        ["PAIN"] = {1, 0.61, 0},
        ["MAELSTROM"] = {0, 0.5, 1},
        ["INSANITY"] = {0.4, 0, 0.8},
        ["LUNAR_POWER"] = {0.93, 0.51, 0.93},
    }
}

-- Create main frame
local DamiaUIFrame = CreateFrame("Frame", "DamiaUIFrame", UIParent)
DamiaUIFrame:RegisterEvent("ADDON_LOADED")
DamiaUIFrame:RegisterEvent("PLAYER_LOGIN")
DamiaUIFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Event handler
DamiaUIFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == addonName then
            -- Initialize saved variables
            DamiaUIDB = DamiaUIDB or {}
            DamiaUICharDB = DamiaUICharDB or {}
            
            -- Apply defaults
            ns:InitializeDefaults()
            
            -- Load configuration AFTER defaults are set
            ns:LoadConfig()
            
            -- Apply configuration to ensure ns.config is populated
            ns:ApplyConfig()
            
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Initialize modules AFTER config is loaded
        ns:InitializeModules()
        
        -- Setup slash commands
        ns:SetupSlashCommands()
        
        print("|cff00FF7FDamiaUI|r v" .. ns.version .. " loaded successfully!")
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        
        -- Update modules that need world info
        for name, module in pairs(ns.modules) do
            if module.UpdateOnWorldEnter then
                module:UpdateOnWorldEnter(isInitialLogin, isReloadingUi)
            end
        end
    end
end)

-- Initialize defaults
function ns:InitializeDefaults()
    local defaults = {
        actionbar = {
            enabled = true,
            scale = 1,
            alpha = 1,
            showgrid = 0,
            showkeybind = 1,
            showcount = 1,
            showmacro = 0,
            size = 28,  -- ColdUI size
            spacing = 0, -- ColdUI spacing (0 = 2px in game)
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
        unitframes = {
            enabled = true,
            scale = 1,
            showParty = true,
            showRaid = true,
            showArena = true,
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
        minimap = {
            enabled = true,
            scale = 1.1,
            pos = {"TOPRIGHT", UIParent, "TOPRIGHT", -10, -10},
            size = 140,
            showClock = true,
            showCalendar = true,
            showTracking = true,
        },
        chat = {
            enabled = true,
            scale = 1,
            font = ns.media.font,
            fontSize = 12,
            tabFont = ns.media.font,
            tabFontSize = 11,
            hideButtons = true,
            fadeout = true,
            fadeoutTime = 10,
            timestamps = false,
        },
        nameplates = {
            enabled = true,
            scale = 1,
            width = 110,
            height = 10,
            texture = ns.media.texture,
            showDebuffs = true,
            showCastbar = true,
        },
        datatexts = {
            enabled = true,
            font = ns.media.font,
            fontSize = 11,
            fontOutline = "OUTLINE",
            showTime = true,
            showDurability = true,
            showGold = true,
            showFPS = true,
        },
        misc = {
            autoRepair = true,
            autoSell = true,
            enhancedTooltips = true,
            hideErrors = false,
            cooldownText = true,
        }
    }
    
    -- Apply defaults to saved variables
    for key, value in pairs(defaults) do
        if DamiaUIDB[key] == nil then
            DamiaUIDB[key] = value
        end
    end
end

-- Load configuration
function ns:LoadConfig()
    ns.config = DamiaUIDB or {}
end

-- Apply configuration (ensure config exists)
function ns:ApplyConfig()
    if not ns.config then
        ns.config = DamiaUIDB or {}
    end
    
    -- Ensure all config categories exist
    local categories = {"actionbar", "unitframes", "minimap", "chat", "nameplates", "datatexts", "misc"}
    for _, category in ipairs(categories) do
        if not ns.config[category] then
            ns.config[category] = {}
        end
    end
end

-- Initialize modules
function ns:InitializeModules()
    -- Ensure config is loaded
    if not ns.config then
        ns:ApplyConfig()
    end
    
    -- Initialize each registered module
    for name, module in pairs(ns.modules) do
        if module.Initialize then
            local success, err = pcall(module.Initialize, module)
            if not success then
                print("|cffFF0000DamiaUI Error initializing " .. name .. ":|r " .. err)
            end
        end
    end
end

-- Setup slash commands
function ns:SetupSlashCommands()
    SLASH_DAMIAUI1 = "/damiaui"
    SLASH_DAMIAUI2 = "/dui"
    
    SlashCmdList["DAMIAUI"] = function(msg)
        local cmd, rest = msg:match("^(%S*)%s*(.-)$")
        cmd = cmd:lower()
        
        if cmd == "reset" then
            DamiaUIDB = nil
            DamiaUICharDB = nil
            ReloadUI()
        elseif cmd == "test" then
            print("|cff00FF7FDamiaUI|r: Test mode activated")
            -- Add test functionality here
        elseif cmd == "config" or cmd == "options" then
            print("|cff00FF7FDamiaUI|r: Configuration panel not yet implemented")
            -- Open config panel when implemented
        else
            print("|cff00FF7FDamiaUI|r Commands:")
            print("  /dui config - Open configuration panel")
            print("  /dui reset - Reset all settings")
            print("  /dui test - Test mode")
        end
    end
end

-- Module registration function
function ns:RegisterModule(name, module)
    ns.modules[name] = module
    -- Don't initialize here, wait for PLAYER_LOGIN
end

-- Utility functions
function ns:Print(...)
    print("|cff00FF7FDamiaUI|r:", ...)
end

function ns:Debug(...)
    if ns.config and ns.config.debug then
        print("|cffFF0000DamiaUI Debug|r:", ...)
    end
end

-- Get config value safely
function ns:GetConfig(category, key)
    if ns.config and ns.config[category] and ns.config[category][key] ~= nil then
        return ns.config[category][key]
    end
    return nil
end

-- Set config value safely
function ns:SetConfig(category, key, value)
    if not ns.config then
        ns.config = {}
    end
    if not ns.config[category] then
        ns.config[category] = {}
    end
    ns.config[category][key] = value
    DamiaUIDB[category][key] = value
end