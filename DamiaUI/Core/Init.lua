-- DamiaUI Core Initialization
-- Based on ColdUI by Coldkil, updated for WoW 11.2

local addonName, ns = ...
_G.DamiaUI = ns

-- Create main addon object
ns.name = addonName
ns.modules = {}
ns.config = {}

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

-- Create main frame
local DamiaUIFrame = CreateFrame("Frame", "DamiaUIFrame", UIParent)
DamiaUIFrame:RegisterEvent("ADDON_LOADED")
DamiaUIFrame:RegisterEvent("PLAYER_LOGIN")
DamiaUIFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Event handler
DamiaUIFrame:SetScript("OnEvent", function(self, event, ...)
    print("[DEBUG] Event received: " .. event)
    if event == "ADDON_LOADED" then
        local addon = ...
        print("[DEBUG] ADDON_LOADED for: " .. tostring(addon))
        if addon == addonName then
            print("[DEBUG] DamiaUI ADDON_LOADED event processing...")
            -- Initialize saved variables
            DamiaUIDB = DamiaUIDB or {}
            DamiaUICharDB = DamiaUICharDB or {}
            DamiaUIProfileDB = DamiaUIProfileDB or {}
            print("[DEBUG] Saved variables initialized")
            
            -- Apply defaults first
            print("[DEBUG] Calling InitializeDefaults()")
            ns:InitializeDefaults()
            print("[DEBUG] InitializeDefaults() completed")
            
            -- Initialize profile system after defaults are available
            print("[DEBUG] Calling InitializeProfiles()")
            ns:InitializeProfiles()
            print("[DEBUG] InitializeProfiles() completed")
            
            -- Update profile defaults now that configDefaults is available
            if ns.Profiles and ns.Profiles.initialized then
                ns.Profiles:UpdateDefaults()
            end
            
            -- Load configuration AFTER defaults are set and profiles initialized
            print("[DEBUG] Calling LoadConfig()")
            ns:LoadConfig()
            print("[DEBUG] LoadConfig() completed")
            
            -- Apply configuration to ensure ns.config is populated
            print("[DEBUG] Calling ApplyConfig()")
            ns:ApplyConfig()
            print("[DEBUG] ApplyConfig() completed")
            
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        print("[DEBUG] PLAYER_LOGIN event - starting module initialization")
        -- Initialize modules AFTER config is loaded
        ns:InitializeModules()
        print("[DEBUG] Module initialization completed")
        
        -- Setup slash commands
        print("[DEBUG] Setting up slash commands")
        ns:SetupSlashCommands()
        print("[DEBUG] Slash commands setup completed")
        
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
        },
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
    print("[DEBUG] InitializeModules called")
    
    -- Ensure config is loaded
    if not ns.config then
        print("[DEBUG] Config not found, applying config")
        ns:ApplyConfig()
    else
        print("[DEBUG] Config is available")
    end
    
    -- Debug: Show registered modules
    print("[DEBUG] Registered modules:")
    for name in pairs(ns.modules) do
        print("[DEBUG]   - " .. name)
    end
    
    local initOrder = {"ActionBars", "UnitFrames", "Minimap"} -- Priority order
    local initializedModules = {}
    local failedModules = {}
    
    -- Initialize priority modules first
    for _, moduleName in ipairs(initOrder) do
        print("[DEBUG] Trying to initialize priority module: " .. moduleName)
        local module = ns.modules[moduleName]
        if module then
            print("[DEBUG] Module " .. moduleName .. " found, initializing...")
            initializedModules[moduleName] = ns:InitializeSingleModule(moduleName, module)
            if not initializedModules[moduleName] then
                failedModules[#failedModules + 1] = moduleName
                print("[DEBUG] Module " .. moduleName .. " FAILED to initialize")
            else
                print("[DEBUG] Module " .. moduleName .. " initialized successfully")
            end
        else
            print("[DEBUG] Priority module " .. moduleName .. " NOT FOUND in registered modules")
        end
    end
    
    -- Initialize remaining modules
    for name, module in pairs(ns.modules) do
        if not initializedModules[name] then
            print("[DEBUG] Trying to initialize remaining module: " .. name)
            initializedModules[name] = ns:InitializeSingleModule(name, module)
            if not initializedModules[name] then
                failedModules[#failedModules + 1] = name
                print("[DEBUG] Module " .. name .. " FAILED to initialize")
            else
                print("[DEBUG] Module " .. name .. " initialized successfully")
            end
        end
    end
    
    -- Report initialization results
    local successCount = 0
    for _, success in pairs(initializedModules) do
        if success then successCount = successCount + 1 end
    end
    
    ns:Print("Initialized " .. successCount .. " modules successfully")
    
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
    print("[DEBUG] InitializeSingleModule called for: " .. name)
    if not module then
        print("[DEBUG] ERROR: Module " .. name .. " is nil")
        return false
    end
    
    -- Check if module is disabled in config
    if ns.config.modules and ns.config.modules[name] == false then
        print("[DEBUG] Module " .. name .. " is disabled in config")
        module.initialized = false
        module.enabled = false
        return true -- Not an error, just disabled
    else
        print("[DEBUG] Module " .. name .. " is enabled (or not explicitly disabled)")
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
            print("[DEBUG] Calling Initialize() for module: " .. name)
            module:Initialize()
            module.initialized = true
            module.enabled = true
            initSuccess = true
            print("[DEBUG] Initialize() completed for module: " .. name)
        else
            print("[DEBUG] Module " .. name .. " has no Initialize function")
            module.initialized = true
            module.enabled = true
            initSuccess = true
        end
    end
    
    -- Protected call with error capture
    local success, err = pcall(initFunction)
    
    print("[DEBUG] pcall result for " .. name .. ": success=" .. tostring(success) .. ", initSuccess=" .. tostring(initSuccess))
    if err then
        print("[DEBUG] pcall error for " .. name .. ": " .. tostring(err))
    end
    
    if success and initSuccess then
        print("[DEBUG] Module " .. name .. " initialized successfully")
        
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
        print("[DEBUG] INITIALIZATION FAILED for " .. name .. ": " .. initError)
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
    
    ns:Debug("Attempting recovery for", #failedModules, "failed modules")
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
        else
            print("|cff00FF7FDamiaUI|r Commands:")
            print("  /dui config - Open configuration panel")
            print("  /dui reset - Reset all settings")
            print("  /dui test - Test mode")
            print("  /dui modules [list|enable|disable|toggle|status] [name] - Module management")
            print("  /dui profiles [list|create|set|delete|copy|reset|export|import] [name] - Profile management")
            print("  /dui dbm [status|enable|disable|force|config] - DBM skin management")
            print("  /dui status - Show addon status")
            print("  /dui reload - Reload all modules")
        end
    end
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

-- Module registration function
function ns:RegisterModule(name, module)
    print("[DEBUG] Registering module: " .. name)
    ns.modules[name] = module
    -- Don't initialize here, wait for PLAYER_LOGIN
    print("[DEBUG] Module " .. name .. " registered successfully")
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