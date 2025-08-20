-- DamiaUI Core Initialization
-- Based on ColdUI by Coldkil, updated for WoW 11.2

local addonName, ns = ...
_G.DamiaUI = ns

-- Create main addon object
ns.name = addonName
-- CRITICAL FIX: Only initialize modules table if it doesn't exist
-- Module files load before Init.lua and register themselves
if not ns.modules then
    ns.modules = {}
end
ns.config = {}

-- Initialize debug log that persists to SavedVariables
ns.debugLog = {}
ns.debugLogIndex = 0

-- Embed oUF properly (remove from global namespace)
local oUF = _G.oUF
if oUF then
    ns.oUF = oUF
    _G.oUF = nil -- Hide from global namespace to prevent conflicts
end

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

-- Enhanced debug logging with fallback support
function ns:LogDebug(message)
    if not message then return end
    
    ns.debugLogIndex = (ns.debugLogIndex or 0) + 1
    local timestamp = date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, tostring(message))
    
    -- Ensure in-memory log exists
    if not ns.debugLog then
        ns.debugLog = {}
    end
    
    -- Add to in-memory log
    table.insert(ns.debugLog, logEntry)
    
    -- Keep only last 500 entries in memory
    if #ns.debugLog > 500 then
        table.remove(ns.debugLog, 1)
    end
    
    -- Print to chat if debug mode is on (with multiple fallback checks)
    local shouldPrint = false
    if ns.config and ns.config.debug then
        shouldPrint = true
    elseif ns.debugMode then  -- Fallback for early init before config is loaded
        shouldPrint = true
    elseif not DamiaUIDB then  -- Very early init - show critical messages
        shouldPrint = true
    end
    
    if shouldPrint then
        print("|cff00ff00[DamiaUI]|r " .. message)
    end
    
    -- Write to SavedVariables if available
    if DamiaUIDebugLog then
        table.insert(DamiaUIDebugLog, logEntry)
        -- Keep only last 1000 entries in saved log
        if #DamiaUIDebugLog > 1000 then
            table.remove(DamiaUIDebugLog, 1)
        end
    end
    
    -- Fallback for very early errors
    if string.find(string.lower(message), "error") or string.find(string.lower(message), "fail") then
        print("|cffff0000[DamiaUI ERROR]|r " .. message)
    end
end

-- Get list of module names for debugging
function ns:GetModuleNames()
    local names = {}
    for name in pairs(ns.modules or {}) do
        table.insert(names, name)
    end
    return names
end

-- Create main frame
local DamiaUIFrame = CreateFrame("Frame", "DamiaUIFrame", UIParent)
DamiaUIFrame:RegisterEvent("ADDON_LOADED")
DamiaUIFrame:RegisterEvent("PLAYER_LOGIN")
DamiaUIFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Initialize core systems
function ns:InitializeCore()
    ns:LogDebug("InitializeCore called")
    ns:LogDebug("Registered modules at core init: " .. table.concat(ns:GetModuleNames(), ", "))
    
    -- Apply defaults first
    ns:LogDebug("Calling InitializeDefaults()")
    ns:InitializeDefaults()
    ns:LogDebug("InitializeDefaults() completed")
    
    -- Initialize profile system after defaults are available
    ns:LogDebug("Calling InitializeProfiles()")
    ns:InitializeProfiles()
    ns:LogDebug("InitializeProfiles() completed")
    
    -- Update profile defaults now that configDefaults is available
    if ns.Profiles and ns.Profiles.initialized then
        ns.Profiles:UpdateDefaults()
    end
    
    -- Load configuration AFTER defaults are set and profiles initialized
    ns:LogDebug("Calling LoadConfig()")
    ns:LoadConfig()
    ns:LogDebug("LoadConfig() completed")
    
    -- Apply configuration to ensure ns.config is populated
    ns:LogDebug("Calling ApplyConfig()")
    ns:ApplyConfig()
    ns:LogDebug("ApplyConfig() completed")
end

-- Event handler with proper sequencing and error handling
DamiaUIFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == addonName then
            -- Wrap SavedVariables initialization in pcall
            local success, err = pcall(function()
                -- Initialize saved variables including debug log
                DamiaUIDB = DamiaUIDB or {}
                DamiaUICharDB = DamiaUICharDB or {}
                DamiaUIProfileDB = DamiaUIProfileDB or {}
                DamiaUIDebugLog = DamiaUIDebugLog or {}
                
                ns:LogDebug("DamiaUI ADDON_LOADED - SavedVariables initialized")
                ns:LogDebug("Modules registered at ADDON_LOADED: " .. table.concat(ns:GetModuleNames(), ", "))
                
                -- Initialize core systems after SavedVariables are ready
                ns:LogDebug("Initializing core...")
                ns:InitializeCore()
                ns:LogDebug("Core initialization completed")
                
                -- Setup slash commands after core is initialized
                ns:LogDebug("Setting up slash commands")
                ns:SetupSlashCommands()
                ns:LogDebug("Slash commands setup completed")
                
                -- Verify slash commands were registered
                if SLASH_DAMIAUI1 and SLASH_DAMIAUI2 then
                    ns:LogDebug("Slash commands verified: " .. SLASH_DAMIAUI1 .. ", " .. SLASH_DAMIAUI2)
                else
                    ns:LogDebug("ERROR: Slash commands not registered properly")
                end
            end)
            
            if not success then
                print("|cffFF0000DamiaUI ADDON_LOADED Error:|r " .. tostring(err))
                if ns.ErrorCapture and ns.ErrorCapture.LogError then
                    ns.ErrorCapture.LogError("ADDON_LOADED", err, debugstack())
                end
            end
            
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Wrap module initialization in pcall
        local success, err = pcall(function()
            ns:LogDebug("PLAYER_LOGIN event - starting module initialization")
            ns:LogDebug("Modules registered at PLAYER_LOGIN: " .. table.concat(ns:GetModuleNames(), ", "))
            
            -- Hide Blizzard UI first
            ns:LogDebug("Disabling Blizzard UI...")
            ns:DisableBlizzardUI()
            ns:LogDebug("Blizzard UI disabled")
            
            -- Initialize modules using ModuleSystem
            ns:LogDebug("Starting module initialization...")
            local initialized, failed = ns:InitializeModules()
            ns:LogDebug("Module initialization completed: " .. initialized .. " loaded, " .. failed .. " failed")
            
            -- Initialize configuration GUI (if it exists)
            ns:LogDebug("Checking for configuration system")
            if ns.InitializeConfig then
                ns:LogDebug("Initializing configuration system")
                ns:InitializeConfig()
                ns:LogDebug("Configuration system initialized")
            else
                ns:LogDebug("Configuration system not yet implemented")
            end
            
            -- Final status report
            if ns.config and ns.config.debug then
                print("|cff00FF7FDamiaUI|r v" .. ns.version .. " loaded successfully!")
            end
            ns:LogDebug("FINAL STATUS:")
            local moduleCount = 0
            for _ in pairs(ns.modules or {}) do
                moduleCount = moduleCount + 1
            end
            ns:LogDebug("Total registered modules: " .. moduleCount)
            for name, module in pairs(ns.modules or {}) do
                local status = (module.initialized and "INITIALIZED" or "NOT INITIALIZED") .. ", " .. (module.enabled and "ENABLED" or "DISABLED")
                ns:LogDebug("Module " .. name .. ": " .. status)
            end
            ns:LogDebug("All modules initialized. UI should be visible!")
        end)
        
        if not success then
            print("|cffFF0000DamiaUI PLAYER_LOGIN Error:|r " .. tostring(err))
            if ns.ErrorCapture and ns.ErrorCapture.LogError then
                ns.ErrorCapture.LogError("PLAYER_LOGIN", err, debugstack())
            end
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        
        -- Update modules that need world info
        for name, module in pairs(ns.modules) do
            if module.UpdateOnWorldEnter then
                local success, err = pcall(module.UpdateOnWorldEnter, module, isInitialLogin, isReloadingUi)
                if not success then
                    ns:LogDebug("Module " .. name .. " UpdateOnWorldEnter error: " .. tostring(err))
                end
            end
        end
    end
end)

-- Initialize defaults
function ns:InitializeDefaults()
    -- Store defaults in ns for other modules to use
    ns.configDefaults = {
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
        },
        debug = false,  -- Disable debug mode by default
        dbmSkin = {
            enabled = true,
            leftIcon = true,
            rightIcon = false,
            barHeight = 8,
            iconSize = 22,
            iconSpacing = 4,
            fontOutline = "OUTLINEMONOCHROME",
            fontSize = 10,
            timerFontSize = 10,
            nameJustifyH = "LEFT",
            timerJustifyH = "RIGHT",
        }
    }
    
    local defaults = ns.configDefaults
    
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
    local categories = {"actionbar", "unitframes", "minimap", "chat", "nameplates", "datatexts", "misc", "dbmSkin"}
    for _, category in ipairs(categories) do
        if not ns.config[category] then
            ns.config[category] = {}
        end
    end
end

-- Initialize modules with comprehensive error recovery
function ns:InitializeModules()
    ns:LogDebug("InitializeModules called")
    ns:LogDebug("Modules table exists: " .. tostring(ns.modules ~= nil))
    ns:LogDebug("Number of registered modules: " .. tostring(ns.modules and #ns:GetModuleNames() or 0))
    
    -- Ensure config is loaded
    if not ns.config then
        ns:LogDebug("Config not found, applying config")
        ns:ApplyConfig()
    else
        ns:LogDebug("Config is available")
    end
    
    -- Debug: Show registered modules
    ns:LogDebug("Registered modules:")
    for name in pairs(ns.modules or {}) do
        ns:LogDebug("  - " .. name)
    end
    
    local initOrder = {"ActionBars", "UnitFrames", "Minimap"} -- Priority order
    local initializedModules = {}
    local failedModules = {}
    
    -- Initialize priority modules first
    for _, moduleName in ipairs(initOrder) do
        ns:LogDebug("Trying to initialize priority module: " .. moduleName)
        local module = ns.modules[moduleName]
        if module then
            ns:LogDebug("Module " .. moduleName .. " found, initializing...")
            initializedModules[moduleName] = ns:InitializeSingleModule(moduleName, module)
            if not initializedModules[moduleName] then
                failedModules[#failedModules + 1] = moduleName
                ns:LogDebug("Module " .. moduleName .. " FAILED to initialize")
            else
                ns:LogDebug("Module " .. moduleName .. " initialized successfully")
            end
        else
            ns:LogDebug("Priority module " .. moduleName .. " NOT FOUND in registered modules")
        end
    end
    
    -- Initialize remaining modules
    for name, module in pairs(ns.modules or {}) do
        if not initializedModules[name] then
            ns:LogDebug("Trying to initialize remaining module: " .. name)
            initializedModules[name] = ns:InitializeSingleModule(name, module)
            if not initializedModules[name] then
                failedModules[#failedModules + 1] = name
                ns:LogDebug("Module " .. name .. " FAILED to initialize")
            else
                ns:LogDebug("Module " .. name .. " initialized successfully")
            end
        end
    end
    
    -- Report initialization results
    local successCount = 0
    for _, success in pairs(initializedModules) do
        if success then successCount = successCount + 1 end
    end
    
    if ns.LogDebug then
        ns:LogDebug("Initialized " .. successCount .. " modules successfully")
    end
    
    if #failedModules > 0 then
        ns:Print("|cffFFAA00Warning:|r " .. #failedModules .. " modules failed to initialize: " .. table.concat(failedModules, ", "))
        
        -- Attempt recovery for critical modules
        C_Timer.After(2, function()
            ns:AttemptModuleRecovery(failedModules)
        end)
    end
end

-- Initialize a single module with detailed error handling
function ns:InitializeSingleModule(name, module)
    ns:LogDebug("InitializeSingleModule called for: " .. name)
    if not module then
        ns:LogDebug("ERROR: Module " .. name .. " is nil")
        return false
    end
    
    -- Check if module is disabled in config
    if ns.config.modules and ns.config.modules[name] == false then
        ns:LogDebug("Module " .. name .. " is disabled in config")
        module.initialized = false
        module.enabled = false
        return true -- Not an error, just disabled
    else
        ns:LogDebug("Module " .. name .. " is enabled (or not explicitly disabled)")
    end
    
    -- Validate module structure
    if type(module) ~= "table" then
        ns:Print("|cffFF0000Error:|r Module", name, "is not a valid table")
        return false
    end
    
    -- Pre-initialization checks
    if module.PreInitialize then
        local preSuccess, preErr = pcall(module.PreInitialize, module)
        if not preSuccess then
            ns:Print("|cffFF0000Error:|r Module", name, "pre-initialization failed:", preErr)
            return false
        end
    end
    
    -- Main initialization with timeout protection
    local initSuccess = false
    local initError = nil
    
    local function initFunction()
        if module.Initialize then
            ns:LogDebug("Calling Initialize() for module: " .. name)
            module:Initialize()
            module.initialized = true
            module.enabled = true
            initSuccess = true
            ns:LogDebug("Initialize() completed for module: " .. name)
        else
            ns:LogDebug("Module " .. name .. " has no Initialize function")
            module.initialized = true
            module.enabled = true
            initSuccess = true
        end
    end
    
    -- Protected call with error capture
    local success, err = pcall(initFunction)
    
    ns:LogDebug("pcall result for " .. name .. ": success=" .. tostring(success) .. ", initSuccess=" .. tostring(initSuccess))
    if err then
        ns:LogDebug("pcall error for " .. name .. ": " .. tostring(err))
    end
    
    if success and initSuccess then
        ns:LogDebug("Module " .. name .. " initialized successfully")
        
        -- Post-initialization validation
        if module.PostInitialize then
            local postSuccess, postErr = pcall(module.PostInitialize, module)
            if not postSuccess then
                ns:Print("|cffFFAA00Warning:|r Module", name, "post-initialization failed:", postErr)
                -- Don't fail the module for post-init errors
            end
        end
        
        return true
    else
        initError = err or "Unknown initialization error"
        ns:LogDebug("INITIALIZATION FAILED for " .. name .. ": " .. initError)
        ns:Print("|cffFF0000Error initializing " .. name .. ":|r " .. initError)
        
        -- Attempt graceful degradation
        if module.Disable then
            local disableSuccess, disableErr = pcall(module.Disable, module)
            if not disableSuccess then
                ns:Print("|cffFF0000Error disabling failed " .. name .. ":|r " .. (disableErr or "unknown error"))
            end
        end
        
        -- Mark module as failed
        module.initialized = false
        module.enabled = false
        module.lastError = initError
        module.lastErrorTime = GetTime()
        
        return false
    end
end

-- Attempt to recover failed modules
function ns:AttemptModuleRecovery(failedModules)
    if not failedModules or #failedModules == 0 then
        return
    end
    
    ns:Debug("Attempting recovery for " .. #failedModules .. " failed modules")
    local recoveredModules = {}
    
    for _, moduleName in ipairs(failedModules) do
        local module = ns.modules[moduleName]
        if module and not module.initialized then
            -- Wait a bit longer for dependencies
            if ns:InitializeSingleModule(moduleName, module) then
                recoveredModules[#recoveredModules + 1] = moduleName
                ns:Print("|cff00FF00Recovered module:|r " .. moduleName)
            else
                -- Mark as permanently failed for this session
                module.recoveryAttempted = true
            end
        end
    end
    
    if #recoveredModules > 0 then
        ns:Print("Successfully recovered " .. #recoveredModules .. " modules")
    end
end

-- Enable a specific module with comprehensive error handling
function ns:EnableModule(name)
    local module = ns.modules[name]
    if not module then
        ns:Print("|cffFF0000Error:|r Module '" .. tostring(name) .. "' not found")
        return false
    end
    
    -- Check if module is already enabled
    if module.enabled then
        ns:Debug("Module", name, "is already enabled")
        return true
    end
    
    -- Validate module state
    if not module.initialized then
        ns:Print("|cffFFAA00Warning:|r Attempting to initialize module '" .. name .. "' before enabling")
        if not ns:InitializeSingleModule(name, module) then
            ns:Print("|cffFF0000Error:|r Failed to initialize module '" .. name .. "' for enabling")
            return false
        end
    end
    
    -- Pre-enable checks
    if module.PreEnable then
        local preSuccess, preErr = pcall(module.PreEnable, module)
        if not preSuccess then
            ns:Print("|cffFF0000Error:|r Module '" .. name .. "' pre-enable failed:", preErr)
            return false
        end
    end
    
    -- Attempt to enable the module
    if module.Enable then
        local success, err = pcall(module.Enable, module)
        if not success then
            ns:Print("|cffFF0000Failed to enable module '" .. name .. "':|r " .. (err or "unknown error"))
            
            -- Store error information
            module.lastError = err
            module.lastErrorTime = GetTime()
            
            -- Attempt recovery if possible
            if module.Reset then
                local resetSuccess = pcall(module.Reset, module)
                if resetSuccess then
                    ns:Print("|cffFFAA00Attempting to re-enable module '" .. name .. "' after reset")
                    local retrySuccess = pcall(module.Enable, module)
                    if retrySuccess then
                        module.enabled = true
                        ns:Print("|cff00FF00Successfully enabled module '" .. name .. "' after recovery")
                        return true
                    end
                end
            end
            
            return false
        end
        
        module.enabled = true
        module.lastError = nil
        module.lastErrorTime = nil
        
        -- Post-enable validation
        if module.PostEnable then
            local postSuccess, postErr = pcall(module.PostEnable, module)
            if not postSuccess then
                ns:Print("|cffFFAA00Warning:|r Module '" .. name .. "' post-enable failed:", postErr)
                -- Don't fail the enable for post-enable errors
            end
        end
        
        ns:Debug("Module '" .. name .. "' enabled successfully")
        
        -- Update config
        ns:SetModuleEnabled(name, true)
        
        return true
    else
        ns:Debug("Module '" .. name .. "' has no Enable function, marking as enabled")
        module.enabled = true
        ns:SetModuleEnabled(name, true)
        return true
    end
end

-- Disable a specific module with comprehensive error handling
function ns:DisableModule(name)
    local module = ns.modules[name]
    if not module then
        ns:Print("|cffFF0000Error:|r Module '" .. tostring(name) .. "' not found")
        return false
    end
    
    -- Check if module is already disabled
    if not module.enabled then
        ns:Debug("Module", name, "is already disabled")
        return true
    end
    
    -- Pre-disable checks
    if module.PreDisable then
        local preSuccess, preErr = pcall(module.PreDisable, module)
        if not preSuccess then
            ns:Print("|cffFFAA00Warning:|r Module '" .. name .. "' pre-disable failed:", preErr)
            -- Continue with disable anyway
        end
    end
    
    -- Attempt to disable the module
    if module.Disable then
        local success, err = pcall(module.Disable, module)
        if not success then
            ns:Print("|cffFF0000Failed to disable module '" .. name .. "':|r " .. (err or "unknown error"))
            
            -- Store error information
            module.lastError = err
            module.lastErrorTime = GetTime()
            
            -- Force disable by clearing critical references
            if module.ForceDisable then
                local forceSuccess = pcall(module.ForceDisable, module)
                if forceSuccess then
                    module.enabled = false
                    ns:Print("|cffFFAA00Force-disabled module '" .. name .. "' after disable failure")
                    ns:SetModuleEnabled(name, false)
                    return true
                end
            end
            
            return false
        end
        
        module.enabled = false
        module.lastError = nil
        module.lastErrorTime = nil
        
        -- Post-disable validation
        if module.PostDisable then
            local postSuccess, postErr = pcall(module.PostDisable, module)
            if not postSuccess then
                ns:Print("|cffFFAA00Warning:|r Module '" .. name .. "' post-disable failed:", postErr)
                -- Don't fail the disable for post-disable errors
            end
        end
        
        ns:Debug("Module '" .. name .. "' disabled successfully")
        
        -- Update config
        ns:SetModuleEnabled(name, false)
        
        return true
    else
        ns:Debug("Module '" .. name .. "' has no Disable function, marking as disabled")
        module.enabled = false
        ns:SetModuleEnabled(name, false)
        return true
    end
end

-- Toggle a module's enabled state
function ns:ToggleModule(name)
    local module = ns.modules[name]
    if not module then
        ns:Print("|cffFF0000Error:|r Module '" .. tostring(name) .. "' not found")
        return false
    end
    
    if module.enabled then
        return ns:DisableModule(name)
    else
        return ns:EnableModule(name)
    end
end

-- Safely set module enabled state in config
function ns:SetModuleEnabled(name, enabled)
    if not ns.config then
        ns:ApplyConfig()
    end
    
    if not ns.config.modules then
        ns.config.modules = {}
    end
    
    ns.config.modules[name] = enabled
    
    -- Update saved variables
    if not DamiaUIDB.modules then
        DamiaUIDB.modules = {}
    end
    DamiaUIDB.modules[name] = enabled
end

-- Get module status information
function ns:GetModuleStatus(name)
    local module = ns.modules[name]
    if not module then
        return {
            exists = false,
            name = name
        }
    end
    
    return {
        exists = true,
        name = name,
        initialized = module.initialized or false,
        enabled = module.enabled or false,
        lastError = module.lastError,
        lastErrorTime = module.lastErrorTime,
        recoveryAttempted = module.recoveryAttempted or false
    }
end

-- Setup slash commands
function ns:SetupSlashCommands()
    SLASH_DAMIAUI1 = "/damiaui"
    SLASH_DAMIAUI2 = "/dui"
    
    SlashCmdList["DAMIAUI"] = function(msg)
        local cmd, rest = msg:match("^(%S*)%s*(.-)$")
        cmd = cmd:lower()
        
        if cmd == "debug" then
            ns:HandleDebugCommand(rest)
        elseif cmd == "reset" then
            DamiaUIDB = nil
            DamiaUICharDB = nil
            ReloadUI()
        elseif cmd == "test" then
            print("|cff00FF7FDamiaUI|r: Test mode activated")
            -- Add test functionality here
        elseif cmd == "config" or cmd == "options" then
            ns:ShowConfigGUI()
        elseif cmd == "modules" or cmd == "module" then
            ns:HandleModuleCommand(rest)
        elseif cmd == "profiles" or cmd == "profile" then
            ns:HandleProfileCommand(rest)
        elseif cmd == "status" then
            ns:ShowAddonStatus()
        elseif cmd == "reload" then
            ns:ReloadModules()
        elseif cmd == "dbm" then
            ns:HandleDBMCommand(rest)
        elseif cmd == "errors" then
            ns:HandleErrorCommand(rest)
        else
            print("|cff00FF7FDamiaUI|r Commands:")
            print("  /dui debug [show|clear|export] - Debug log management")
            print("  /dui config - Open configuration panel")
            print("  /dui reset - Reset all settings")
            print("  /dui test - Test mode")
            print("  /dui modules [list|enable|disable|toggle|status] [name] - Module management")
            print("  /dui profiles [list|create|set|delete|copy|reset|export|import] [name] - Profile management")
            print("  /dui dbm [status|enable|disable|force|config] - DBM skin management")
            print("  /dui errors [show|clear|count|recent] - Error log management")
            print("  /dui status - Show addon status")
            print("  /dui reload - Reload all modules")
        end
    end
end

-- Handle debug commands with improved output
function ns:HandleDebugCommand(args)
    local action = args:lower()
    
    if action == "" or action == "show" then
        -- Enhanced debug output to chat with better formatting
        ns:Print("=== DamiaUI Debug Log ===")
        local logSource = DamiaUIDebugLog or ns.debugLog or {}
        
        if #logSource == 0 then
            ns:Print("Debug log is empty")
            -- Try to show some basic status if no logs
            ns:Print("SavedVariables status:")
            ns:Print("  DamiaUIDB: " .. tostring(DamiaUIDB ~= nil))
            ns:Print("  DamiaUIDebugLog: " .. tostring(DamiaUIDebugLog ~= nil))
        else
            -- Show last 20 entries with better formatting
            local startIdx = math.max(1, #logSource - 19)
            ns:Print("Showing last " .. (#logSource - startIdx + 1) .. " debug entries:")
            for i = startIdx, #logSource do
                print("|cff00ff00[DEBUG]|r " .. tostring(logSource[i]))
            end
        end
        
        -- Show comprehensive module status
        ns:Print("=== Module Status ===")
        local moduleCount = 0
        local initializedCount = 0
        local enabledCount = 0
        
        for name, module in pairs(ns.modules or {}) do
            moduleCount = moduleCount + 1
            if module.initialized then initializedCount = initializedCount + 1 end
            if module.enabled then enabledCount = enabledCount + 1 end
            
            local statusColor = "|cffff0000"  -- Red for failed
            if module.initialized and module.enabled then
                statusColor = "|cff00ff00"  -- Green for working
            elseif module.initialized then
                statusColor = "|cffffff00"  -- Yellow for init but disabled
            end
            
            local status = string.format("%s%s|r: init=%s, enabled=%s",
                statusColor,
                name,
                tostring(module.initialized),
                tostring(module.enabled))
            print(status)
            
            -- Show any errors
            if module.lastError then
                print("  |cffff0000Error:|r " .. tostring(module.lastError))
            end
        end
        
        ns:Print("Summary: " .. moduleCount .. " total, " .. initializedCount .. " initialized, " .. enabledCount .. " enabled")
        
        -- Show system status
        ns:Print("=== System Status ===")
        ns:Print("Config loaded: " .. tostring(ns.config ~= nil))
        ns:Print("oUF available: " .. tostring(ns.oUF ~= nil))
        ns:Print("Slash commands: " .. tostring(SLASH_DAMIAUI1 ~= nil))
        
    elseif action == "clear" then
        if DamiaUIDebugLog then
            DamiaUIDebugLog = {}
        end
        if ns.debugLog then
            ns.debugLog = {}
        end
        ns:Print("Debug log cleared")
        
    elseif action == "export" then
        ns:ShowDebugLog()
        
    elseif action == "verbose" then
        -- Enable verbose debug mode
        ns.debugMode = true
        if ns.config then
            ns.config.debug = true
        end
        ns:Print("Verbose debug mode enabled")
        
    elseif action == "quiet" then
        -- Disable verbose debug mode
        ns.debugMode = false
        if ns.config then
            ns.config.debug = false
        end
        ns:Print("Verbose debug mode disabled")
        
    else
        ns:Print("Debug commands:")
        ns:Print("  /dui debug show - Show debug log and status in chat")
        ns:Print("  /dui debug clear - Clear debug log")
        ns:Print("  /dui debug export - Open copyable debug window")
        ns:Print("  /dui debug verbose - Enable verbose debug logging")
        ns:Print("  /dui debug quiet - Disable verbose debug logging")
    end
end

-- Show debug log in a copyable frame
function ns:ShowDebugLog()
    -- Create or reuse debug frame
    local frame = _G.DamiaUIDebugFrame
    if not frame then
        frame = CreateFrame("Frame", "DamiaUIDebugFrame", UIParent, "BackdropTemplate")
        frame:SetSize(800, 600)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -16)
        title:SetText("DamiaUI Debug Log")
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
        closeButton:SetScript("OnClick", function() frame:Hide() end)
        
        -- Scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 48)
        frame.scrollFrame = scrollFrame
        
        -- Edit box
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontWhiteSmall)
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        scrollFrame:SetScrollChild(editBox)
        frame.editBox = editBox
        
        -- Select All button
        local selectButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        selectButton:SetSize(100, 22)
        selectButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
        selectButton:SetText("Select All")
        selectButton:SetScript("OnClick", function()
            frame.editBox:SetFocus()
            frame.editBox:HighlightText()
        end)
        
        -- Clear button
        local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        clearButton:SetSize(100, 22)
        clearButton:SetPoint("LEFT", selectButton, "RIGHT", 8, 0)
        clearButton:SetText("Clear Log")
        clearButton:SetScript("OnClick", function()
            DamiaUIDebugLog = {}
            ns.debugLog = {}
            frame:Hide()
            ns:Print("Debug log cleared")
        end)
        
        -- Refresh button
        local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        refreshButton:SetSize(100, 22)
        refreshButton:SetPoint("LEFT", clearButton, "RIGHT", 8, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            ns:UpdateDebugLogDisplay()
        end)
    end
    
    -- Update and show
    ns:UpdateDebugLogDisplay()
    frame:Show()
end

-- Update debug log display
function ns:UpdateDebugLogDisplay()
    local frame = _G.DamiaUIDebugFrame
    if not frame then return end
    
    -- Build log text
    local logText = "DamiaUI Debug Log - " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    logText = logText .. "==========================================\n\n"
    
    -- Use SavedVariables log if available, otherwise use in-memory log
    local logSource = DamiaUIDebugLog or ns.debugLog
    
    for i, entry in ipairs(logSource) do
        logText = logText .. entry .. "\n"
    end
    
    -- Add module status at the end
    logText = logText .. "\n========== Current Module Status ==========\n"
    for name, module in pairs(ns.modules or {}) do
        local status = string.format("%s: initialized=%s, enabled=%s",
            name,
            tostring(module.initialized),
            tostring(module.enabled))
        logText = logText .. status .. "\n"
    end
    
    frame.editBox:SetText(logText)
    frame.editBox:SetCursorPosition(0)
end

-- Export debug log
function ns:ExportDebugLog()
    ns:ShowDebugLog()
    ns:Print("Debug log opened. You can copy the text to share for troubleshooting.")
end

-- Handle profile-specific commands
function ns:HandleProfileCommand(args)
    local action, profileName, extraArg = args:match("^(%S*)%s*([^%s]*)%s*(.-)$")
    action = action:lower()
    
    if action == "" or action == "list" then
        ns:ListProfiles()
    elseif action == "current" then
        if ns.Profiles and ns.Profiles.initialized then
            local currentProfile = ns.Profiles:GetCurrentProfile()
            ns:Print("Current profile: " .. currentProfile)
            local info = ns.Profiles:GetProfileInfo(currentProfile)
            if info and info.description then
                print("  Description: " .. info.description)
            end
        else
            ns:Print("Profile system not initialized")
        end
    elseif action == "create" then
        if profileName and profileName ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                local description = extraArg and extraArg ~= "" and extraArg or nil
                if ns.Profiles:CreateProfile(profileName, description) then
                    ns:Print("Created and switched to profile: " .. profileName)
                end
            else
                ns:Print("Profile system not initialized")
            end
        else
            ns:Print("Usage: /dui profiles create <profile_name> [description]")
        end
    elseif action == "set" or action == "load" then
        if profileName and profileName ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                if ns.Profiles:SetProfile(profileName) then
                    C_Timer.After(0.5, ReloadUI)  -- Reload UI to apply changes
                end
            else
                ns:LoadProfile(profileName)  -- Fallback to legacy function
            end
        else
            ns:Print("Usage: /dui profiles set <profile_name>")
        end
    elseif action == "delete" then
        if profileName and profileName ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                if ns.Profiles:DeleteProfile(profileName) then
                    ns:Print("Deleted profile: " .. profileName)
                end
            else
                ns:DeleteProfile(profileName)  -- Fallback to legacy function
            end
        else
            ns:Print("Usage: /dui profiles delete <profile_name>")
        end
    elseif action == "copy" then
        local sourceProfile, targetProfile = profileName, extraArg
        if sourceProfile and sourceProfile ~= "" and targetProfile and targetProfile ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                if ns.Profiles:CopyProfile(sourceProfile, targetProfile) then
                    ns:Print("Copied profile '" .. sourceProfile .. "' to '" .. targetProfile .. "'")
                end
            else
                ns:Print("Profile system not initialized")
            end
        else
            ns:Print("Usage: /dui profiles copy <source_profile> <target_profile>")
        end
    elseif action == "reset" then
        if ns.Profiles and ns.Profiles.initialized then
            local resetProfile = profileName and profileName ~= "" and profileName or nil
            if ns.Profiles:ResetProfile(resetProfile) then
                local currentProfile = resetProfile or ns.Profiles:GetCurrentProfile()
                ns:Print("Reset profile: " .. currentProfile)
                C_Timer.After(0.5, ReloadUI)  -- Reload UI to apply changes
            end
        else
            ns:Print("Profile system not initialized")
        end
    elseif action == "export" then
        if ns.Profiles and ns.Profiles.initialized then
            local exportProfile = profileName and profileName ~= "" and profileName or nil
            local exportString = ns.Profiles:ExportProfile(exportProfile)
            if exportString then
                ns:Print("Profile exported successfully. Copy this string:")
                print(exportString)
            end
        else
            ns:Print("Profile system not initialized")
        end
    elseif action == "import" then
        if profileName and profileName ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                local newName = extraArg and extraArg ~= "" and extraArg or nil
                if ns.Profiles:ImportProfile(profileName, newName) then
                    ns:Print("Profile imported successfully")
                end
            else
                ns:Print("Profile system not initialized")
            end
        else
            ns:Print("Usage: /dui profiles import <import_string> [new_profile_name]")
        end
    elseif action == "info" then
        if profileName and profileName ~= "" then
            if ns.Profiles and ns.Profiles.initialized then
                local info = ns.Profiles:GetProfileInfo(profileName)
                if info then
                    ns:Print("Profile Information: " .. profileName)
                    print("  Description: " .. (info.description or "None"))
                    print("  Author: " .. (info.author or "Unknown"))
                    print("  Version: " .. (info.version or "Unknown"))
                    if info.created then
                        print("  Created: " .. date("%Y-%m-%d %H:%M:%S", info.created))
                    end
                    if info.modified then
                        print("  Modified: " .. date("%Y-%m-%d %H:%M:%S", info.modified))
                    end
                    print("  Protected: " .. (info.protected and "Yes" or "No"))
                else
                    ns:Print("Profile not found: " .. profileName)
                end
            else
                ns:Print("Profile system not initialized")
            end
        else
            ns:Print("Usage: /dui profiles info <profile_name>")
        end
    else
        ns:Print("Profile commands:")
        ns:Print("  /dui profiles list - List all profiles")
        ns:Print("  /dui profiles current - Show current profile")
        ns:Print("  /dui profiles create <name> [description] - Create new profile")
        ns:Print("  /dui profiles set <name> - Switch to profile")
        ns:Print("  /dui profiles delete <name> - Delete profile")
        ns:Print("  /dui profiles copy <source> <target> - Copy profile")
        ns:Print("  /dui profiles reset [name] - Reset profile to defaults")
        ns:Print("  /dui profiles export [name] - Export profile to string")
        ns:Print("  /dui profiles import <string> [name] - Import profile from string")
        ns:Print("  /dui profiles info <name> - Show profile information")
    end
end

-- Handle module-specific commands
function ns:HandleModuleCommand(args)
    local action, moduleName = args:match("^(%S*)%s*(.-)$")
    action = action:lower()
    
    if action == "" or action == "list" then
        ns:ListModules()
    elseif action == "enable" then
        if moduleName and moduleName ~= "" then
            if ns:EnableModule(moduleName) then
                ns:Print("Enabled module: " .. moduleName)
            end
        else
            ns:Print("Usage: /dui modules enable <module_name>")
        end
    elseif action == "disable" then
        if moduleName and moduleName ~= "" then
            if ns:DisableModule(moduleName) then
                ns:Print("Disabled module: " .. moduleName)
            end
        else
            ns:Print("Usage: /dui modules disable <module_name>")
        end
    elseif action == "toggle" then
        if moduleName and moduleName ~= "" then
            if ns:ToggleModule(moduleName) then
                local status = ns:GetModuleStatus(moduleName)
                ns:Print("Toggled module " .. moduleName .. " to: " .. (status.enabled and "enabled" or "disabled"))
            end
        else
            ns:Print("Usage: /dui modules toggle <module_name>")
        end
    elseif action == "status" then
        if moduleName and moduleName ~= "" then
            ns:ShowModuleStatus(moduleName)
        else
            ns:ShowAllModuleStatus()
        end
    else
        ns:Print("Module commands:")
        ns:Print("  /dui modules list - List all modules")
        ns:Print("  /dui modules enable <name> - Enable a module")
        ns:Print("  /dui modules disable <name> - Disable a module")
        ns:Print("  /dui modules toggle <name> - Toggle a module")
        ns:Print("  /dui modules status [name] - Show module status")
    end
end

-- Handle DBM skin commands
function ns:HandleDBMCommand(args)
    -- Check if DBM skin module exists
    if not ns.modules.DBMSkin then
        ns:Print("|cffFF0000Error:|r DBM Skin module not found")
        return
    end
    
    -- Delegate to DBM skin module
    ns.modules.DBMSkin:HandleSlashCommand(args)
end

-- Handle error display commands
function ns:HandleErrorCommand(args)
    local action, count = args:match("^(%S*)%s*(%d*)$")
    action = action:lower()
    count = tonumber(count) or 10
    
    if not ns.ErrorCapture then
        ns:Print("|cffFF0000Error:|r Error capture system not initialized")
        return
    end
    
    if action == "" or action == "show" then
        -- Show error display frame
        ns:ShowErrorFrame()
    elseif action == "clear" then
        ns.ErrorCapture.ClearErrors()
    elseif action == "count" then
        local errorCount = ns.ErrorCapture.GetErrorCount()
        ns:Print("Total errors captured: " .. errorCount)
    elseif action == "recent" then
        local recentErrors = ns.ErrorCapture.GetRecentErrors(count)
        if #recentErrors == 0 then
            ns:Print("No recent errors found")
            return
        end
        
        ns:Print("Recent errors (last " .. #recentErrors .. "):")
        for i, error in ipairs(recentErrors) do
            local countText = error.count > 1 and " (x" .. error.count .. ")" or ""
            print(string.format("  [%s] %s: %s%s", error.timestamp, error.source, error.error, countText))
        end
    else
        ns:Print("Error commands:")
        ns:Print("  /dui errors show - Show error display frame")
        ns:Print("  /dui errors clear - Clear all captured errors")
        ns:Print("  /dui errors count - Show total error count")
        ns:Print("  /dui errors recent [count] - Show recent errors (default: 10)")
    end
end

-- Show error display frame with copyable text
function ns:ShowErrorFrame()
    if not ns.ErrorCapture then
        ns:Print("Error capture system not available")
        return
    end
    
    local errors = ns.ErrorCapture.GetErrors()
    if #errors == 0 then
        ns:Print("No errors to display")
        return
    end
    
    -- Create or reuse error display frame
    local frame = _G.DamiaUIErrorFrame
    if not frame then
        frame = CreateFrame("Frame", "DamiaUIErrorFrame", UIParent, "BackdropTemplate")
        frame:SetSize(800, 600)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -16)
        title:SetText("DamiaUI Error Log")
        frame.title = title
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
        closeButton:SetScript("OnClick", function() frame:Hide() end)
        
        -- Scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 16)
        frame.scrollFrame = scrollFrame
        
        -- Edit box for text
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontWhiteSmall)
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        scrollFrame:SetScrollChild(editBox)
        frame.editBox = editBox
        
        -- Copy button
        local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        copyButton:SetSize(100, 22)
        copyButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 24)
        copyButton:SetText("Select All")
        copyButton:SetScript("OnClick", function()
            frame.editBox:SetFocus()
            frame.editBox:HighlightText()
        end)
        
        -- Clear button
        local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        clearButton:SetSize(100, 22)
        clearButton:SetPoint("RIGHT", copyButton, "LEFT", -8, 0)
        clearButton:SetText("Clear Errors")
        clearButton:SetScript("OnClick", function()
            ns.ErrorCapture.ClearErrors()
            frame:Hide()
            ns:Print("Error log cleared")
        end)
    end
    
    -- Build error text
    local errorText = "DamiaUI Error Log - " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    errorText = errorText .. "==========================================\n\n"
    
    for i, error in ipairs(errors) do
        local countText = error.count > 1 and " (occurred " .. error.count .. " times)" or ""
        errorText = errorText .. string.format("[%s] %s%s\n", error.timestamp, error.source, countText)
        errorText = errorText .. "Error: " .. error.error .. "\n"
        if error.stack and error.stack ~= "" then
            errorText = errorText .. "Stack: " .. error.stack .. "\n"
        end
        errorText = errorText .. "\n"
    end
    
    -- Update the edit box
    frame.editBox:SetText(errorText)
    frame.editBox:SetCursorPosition(0)
    
    -- Show frame
    frame:Show()
    
    ns:Print("Error display frame opened. You can copy the text to share with developers.")
end

-- List all registered modules
function ns:ListModules()
    local moduleList = {}
    for name in pairs(ns.modules) do
        table.insert(moduleList, name)
    end
    
    if #moduleList == 0 then
        ns:Print("No modules registered")
        return
    end
    
    table.sort(moduleList)
    ns:Print("Registered modules (" .. #moduleList .. "):")
    
    for _, name in ipairs(moduleList) do
        local status = ns:GetModuleStatus(name)
        local statusText = ""
        
        if status.initialized then
            statusText = status.enabled and "|cff00FF00Enabled|r" or "|cffFF0000Disabled|r"
        else
            statusText = "|cffFFAA00Not Initialized|r"
        end
        
        if status.lastError then
            statusText = statusText .. " |cffFF0000(Error)|r"
        end
        
        print("  " .. name .. ": " .. statusText)
    end
end

-- Show detailed status for a specific module
function ns:ShowModuleStatus(name)
    local status = ns:GetModuleStatus(name)
    
    if not status.exists then
        ns:Print("Module '" .. name .. "' not found")
        return
    end
    
    ns:Print("Module Status: " .. name)
    ns:Print("  Initialized: " .. (status.initialized and "Yes" or "No"))
    ns:Print("  Enabled: " .. (status.enabled and "Yes" or "No"))
    
    if status.lastError then
        local errorTime = status.lastErrorTime and date("%H:%M:%S", status.lastErrorTime) or "Unknown"
        ns:Print("  Last Error: " .. status.lastError .. " (at " .. errorTime .. ")")
    end
    
    if status.recoveryAttempted then
        ns:Print("  Recovery Attempted: Yes")
    end
end

-- Show status for all modules
function ns:ShowAllModuleStatus()
    local modules = {}
    for name in pairs(ns.modules) do
        table.insert(modules, name)
    end
    
    if #modules == 0 then
        ns:Print("No modules registered")
        return
    end
    
    table.sort(modules)
    
    local initialized = 0
    local enabled = 0
    local failed = 0
    
    for _, name in ipairs(modules) do
        local status = ns:GetModuleStatus(name)
        if status.initialized then
            initialized = initialized + 1
        end
        if status.enabled then
            enabled = enabled + 1
        end
        if status.lastError then
            failed = failed + 1
        end
    end
    
    ns:Print("Module Summary:")
    ns:Print("  Total: " .. #modules)
    ns:Print("  Initialized: " .. initialized)
    ns:Print("  Enabled: " .. enabled)
    ns:Print("  Failed: " .. failed)
    
    if failed > 0 then
        ns:Print("\nFailed Modules:")
        for _, name in ipairs(modules) do
            local status = ns:GetModuleStatus(name)
            if status.lastError then
                print("  " .. name .. ": " .. status.lastError)
            end
        end
    end
end

-- Show overall addon status
function ns:ShowAddonStatus()
    ns:Print("DamiaUI Status Report:")
    ns:Print("  Version: " .. ns.version)
    ns:Print("  oUF Embedded: " .. (ns.oUF and "Yes" or "No"))
    ns:Print("  Config Loaded: " .. (ns.config and "Yes" or "No"))
    
    local moduleCount = 0
    for _ in pairs(ns.modules) do
        moduleCount = moduleCount + 1
    end
    ns:Print("  Registered Modules: " .. moduleCount)
    
    ns:ShowAllModuleStatus()
end

-- Reload all modules (reinitialize)
function ns:ReloadModules()
    ns:Print("Reloading all modules...")
    
    -- Disable all modules first
    for name in pairs(ns.modules) do
        if ns.modules[name].enabled then
            ns:DisableModule(name)
        end
    end
    
    -- Wait a moment, then reinitialize
    C_Timer.After(0.5, function()
        ns:InitializeModules()
        ns:Print("Module reload complete")
    end)
end

-- Remove duplicate module registration - using ModuleSystem.lua instead
-- Module registration is now handled in ModuleSystem.lua

-- Show configuration GUI (stub for now)
function ns:ShowConfigGUI()
    ns:Print("Configuration GUI not yet implemented")
    ns:Print("Use /dui modules to manage modules")
    ns:Print("Use /dui profiles to manage profiles")
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