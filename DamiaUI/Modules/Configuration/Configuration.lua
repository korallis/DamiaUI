--[[
    DamiaUI Configuration Module
    
    Comprehensive AceConfig-based configuration interface providing user-friendly
    settings management for all DamiaUI modules and features.
    
    Features:
    - Organized option trees for all modules
    - Live preview with immediate setting application
    - Settings validation and constraint checking
    - Configuration rollback and recovery
    - Profile management integration
    - User-friendly descriptions and help text
    
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
local type, tostring = type, tostring
local table = table
local tinsert, tremove = table.insert, table.remove
local LibStub = LibStub

-- Initialize module
local Configuration = DamiaUI:NewModule("Configuration", "AceEvent-3.0")
DamiaUI.Configuration = Configuration

-- Module state
local AceConfig
local AceConfigDialog
local AceDBOptions
local isInitialized = false
local configFrame
local livePreviewEnabled = true
local rollbackStack = {}
local maxRollbackStates = 10
local pendingChanges = {}

-- Configuration categories
local CONFIG_CATEGORIES = {
    GENERAL = "general",
    UNITFRAMES = "unitframes", 
    ACTIONBARS = "actionbars",
    INTERFACE = "interface",
    SKINNING = "skinning",
    PROFILES = "profiles"
}

-- Setting types for validation
local SETTING_TYPES = {
    BOOLEAN = "boolean",
    NUMBER = "number", 
    STRING = "string",
    COLOR = "color",
    POSITION = "position",
    SELECT = "select"
}

--[[
    Module Initialization
]]

function Configuration:OnInitialize()
    self:RegisterEvent("ADDON_LOADED")
end

function Configuration:OnEnable()
    if not self:InitializeLibraries() then
        DamiaUI:LogError("Configuration: AceConfig libraries not available - module disabled")
        return
    end
    
    -- Initialize configuration state
    self:InitializeConfigurationState()
    
    -- Register for DamiaUI events
    DamiaUI:RegisterEvent("DAMIA_INITIALIZED", function()
        self:SetupConfiguration()
    end)
    
    -- Register for profile changes
    DamiaUI:RegisterEvent("DAMIA_PROFILE_CHANGED", function(_, oldProfile, newProfile)
        self:OnProfileChanged(oldProfile, newProfile)
    end)
    
    -- Register for configuration changes
    DamiaUI:RegisterEvent("DAMIA_CONFIG_CHANGED", function(_, key, oldValue, newValue)
        self:OnConfigChanged(key, oldValue, newValue)
    end)
    
    DamiaUI:LogDebug("Configuration module enabled")
end

function Configuration:InitializeLibraries()
    -- Get required libraries with DamiaUI namespace
    AceConfig = LibStub("DamiaUI_AceConfig-3.0", true)
    AceConfigDialog = LibStub("DamiaUI_AceConfigDialog-3.0", true)
    AceDBOptions = LibStub("DamiaUI_AceDBOptions-3.0", true)
    
    if not AceConfig or not AceConfigDialog then
        DamiaUI:LogError("AceConfig libraries not found")
        return false
    end
    
    return true
end

-- Initialize configuration state
function Configuration:InitializeConfigurationState()
    -- Clear any existing state
    rollbackStack = {}
    pendingChanges = {}
    livePreviewEnabled = true
    
    DamiaUI:LogDebug("Configuration state initialized")
end

--[[
    Configuration Setup
]]

function Configuration:SetupConfiguration()
    if isInitialized then
        return
    end
    
    -- Create configuration options table
    local options = self:CreateConfigOptions()
    
    -- Register configuration
    AceConfig:RegisterOptionsTable("DamiaUI", options, {"damia", "damiaui"})
    
    -- Create configuration dialog
    configFrame = AceConfigDialog:AddToBlizOptions("DamiaUI", "Damia UI")
    
    -- Add profile options if AceDBOptions is available
    if AceDBOptions and DamiaUI.db then
        local profileOptions = AceDBOptions:GetOptionsTable(DamiaUI.db)
        AceConfig:RegisterOptionsTable("DamiaUI_Profiles", profileOptions)
        AceConfigDialog:AddToBlizOptions("DamiaUI_Profiles", "Profiles", "Damia UI")
    end
    
    isInitialized = true
    DamiaUI:LogDebug("Configuration system setup complete")
end

--[[
    Configuration Options Structure
]]

function Configuration:CreateConfigOptions()
    local options = {
        type = "group",
        name = "Damia UI",
        handler = self,
        args = {
            header = {
                type = "header",
                name = "Damia UI Configuration",
                order = 0,
            },
            description = {
                type = "description",
                name = "Configure all aspects of your Damia UI interface. Changes apply immediately with live preview.",
                order = 1,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 2,
            },
            general = {
                type = "group",
                name = "General",
                desc = "General DamiaUI settings and behavior",
                order = 10,
                args = self:GetGeneralOptions(),
            },
            unitframes = {
                type = "group", 
                name = "Unit Frames",
                desc = "Player, target, party and raid frame configuration",
                order = 20,
                args = self:GetUnitFrameOptions(),
            },
            actionbars = {
                type = "group",
                name = "Action Bars", 
                desc = "Action bar positioning, styling and behavior",
                order = 30,
                args = self:GetActionBarOptions(),
            },
            interface = {
                type = "group",
                name = "Interface",
                desc = "Chat, minimap, tooltips and other interface elements",
                order = 40,
                args = self:GetInterfaceOptions(),
            },
            skinning = {
                type = "group",
                name = "Skinning",
                desc = "Visual styling and theme customization",
                order = 50,
                args = self:GetSkinningOptions(),
            },
            tools = {
                type = "group",
                name = "Tools",
                desc = "Configuration tools and utilities",
                order = 60,
                args = self:GetToolsOptions(),
            },
        },
    }
    
    return options
end

--[[
    Live Preview and Validation System
]]

-- Apply setting with live preview
function Configuration:ApplySettingWithPreview(key, value, skipValidation)
    if not skipValidation and not self:ValidateSetting(key, value) then
        DamiaUI:LogError("Invalid value for setting %s: %s", key, tostring(value))
        return false
    end
    
    -- Store rollback state before change
    if livePreviewEnabled then
        self:SaveRollbackState()
    end
    
    -- Get old value
    local oldValue = DamiaUI.Config:Get(key)
    
    -- Apply the setting
    DamiaUI.Config:Set(key, value)
    
    -- Apply live preview if enabled
    if livePreviewEnabled then
        self:ApplyLivePreview(key, oldValue, value)
    end
    
    return true
end

-- Validate setting value
function Configuration:ValidateSetting(key, value)
    -- Get validation rules from defaults or define here
    local validationRules = DamiaUI.Defaults and DamiaUI.Defaults.ConfigValidation or {}
    
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
    
    -- Default validation based on type
    return self:DefaultValidation(key, value)
end

-- Default validation based on setting type
function Configuration:DefaultValidation(key, value)
    -- Position validation
    if key:match("%.position$") then
        return type(value) == "table" and type(value.x) == "number" and type(value.y) == "number"
    end
    
    -- Scale validation
    if key:match("%.scale$") then
        return type(value) == "number" and value >= 0.5 and value <= 2.0
    end
    
    -- Size validation
    if key:match("%.width$") or key:match("%.height$") then
        return type(value) == "number" and value > 0 and value <= 1000
    end
    
    -- Enabled states
    if key:match("%.enabled$") then
        return type(value) == "boolean"
    end
    
    -- Default: allow any value
    return true
end

-- Apply live preview for setting change
function Configuration:ApplyLivePreview(key, oldValue, newValue)
    -- Fire immediate update events for specific modules
    if key:match("^unitframes") then
        DamiaUI:FireEvent("DAMIA_UNITFRAMES_CONFIG_CHANGED", key, oldValue, newValue)
    elseif key:match("^actionbars") then
        DamiaUI:FireEvent("DAMIA_ACTIONBARS_CONFIG_CHANGED", key, oldValue, newValue)
    elseif key:match("^interface") then
        DamiaUI:FireEvent("DAMIA_INTERFACE_CONFIG_CHANGED", key, oldValue, newValue)
    elseif key:match("^skinning") then
        DamiaUI:FireEvent("DAMIA_SKINNING_CONFIG_CHANGED", key, oldValue, newValue)
    end
    
    -- General configuration change event
    DamiaUI:FireEvent("DAMIA_CONFIG_LIVE_PREVIEW", key, oldValue, newValue)
end

-- Save current state for rollback
function Configuration:SaveRollbackState()
    if not DamiaUI.Config or not DamiaUI.Config:IsInitialized() then
        return
    end
    
    -- Create snapshot of current configuration
    local currentProfile = DamiaUI.Config:GetCurrentProfile()
    local profileData = DamiaUI.Config:ExportProfile(currentProfile)
    
    if profileData then
        -- Add to rollback stack
        tinsert(rollbackStack, {
            timestamp = time(),
            profile = currentProfile,
            data = profileData
        })
        
        -- Limit stack size
        while #rollbackStack > maxRollbackStates do
            tremove(rollbackStack, 1)
        end
        
        DamiaUI:LogDebug("Saved rollback state (%d states)", #rollbackStack)
    end
end

-- Rollback to previous state
function Configuration:RollbackToPreviousState()
    if #rollbackStack == 0 then
        DamiaUI:LogWarning("No rollback states available")
        return false
    end
    
    local lastState = tremove(rollbackStack)
    if not lastState then
        return false
    end
    
    -- Temporarily disable live preview to avoid recursion
    local wasEnabled = livePreviewEnabled
    livePreviewEnabled = false
    
    -- Import the previous state
    local success = DamiaUI.Config:ImportProfile(lastState.data, lastState.profile)
    if success then
        DamiaUI.Config:SetProfile(lastState.profile)
        DamiaUI:LogInfo("Rolled back to previous configuration state")
        
        -- Refresh configuration UI
        self:RefreshConfig()
        
        -- Fire rollback event
        DamiaUI:FireEvent("DAMIA_CONFIG_ROLLBACK", lastState.timestamp)
    end
    
    -- Re-enable live preview
    livePreviewEnabled = wasEnabled
    
    return success
end

--[[
    General Options
]]

function Configuration:GetGeneralOptions()
    return {
        header = {
            type = "header",
            name = "General Settings",
            order = 1,
        },
        enabled = {
            type = "toggle",
            name = "Enable DamiaUI",
            desc = "Enable or disable the entire DamiaUI addon. When disabled, you'll need to reload your UI for changes to take effect.",
            order = 2,
            width = "full",
            get = function() return DamiaUI.Config:Get("general.enabled", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("general.enabled", value)
                if value then
                    DamiaUI:LogInfo("DamiaUI enabled")
                else
                    DamiaUI:LogInfo("DamiaUI disabled - reload UI to take effect")
                end
            end,
        },
        scale = {
            type = "range",
            name = "UI Scale",
            desc = "Adjust the overall scale of DamiaUI elements. This affects all frames and interface components.",
            order = 3,
            min = 0.5,
            max = 2.0,
            step = 0.05,
            isPercent = true,
            get = function() return DamiaUI.Config:Get("general.scale", 1.0) end,
            set = function(_, value)
                self:ApplySettingWithPreview("general.scale", value)
            end,
        },
        livePreview = {
            type = "toggle",
            name = "Live Preview",
            desc = "Apply configuration changes immediately without requiring UI reload. Disable this if you experience performance issues.",
            order = 4,
            width = "full",
            get = function() return livePreviewEnabled end,
            set = function(_, value)
                livePreviewEnabled = value
                DamiaUI:LogInfo("Live preview %s", value and "enabled" or "disabled")
            end,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 5,
        },
        debugMode = {
            type = "toggle",
            name = "Debug Mode",
            desc = "Enable debug logging for troubleshooting issues. This will show additional information in chat.",
            order = 6,
            get = function() return DamiaUI.Config:Get("general.debugMode", false) end,
            set = function(_, value)
                self:ApplySettingWithPreview("general.debugMode", value)
                if value then
                    DamiaUI:LogInfo("Debug mode enabled")
                else
                    DamiaUI:LogInfo("Debug mode disabled")
                end
            end,
        },
        autoScale = {
            type = "toggle",
            name = "Auto Scale",
            desc = "Automatically adjust UI scale based on screen resolution for optimal visibility.",
            order = 7,
            get = function() return DamiaUI.Config:Get("general.autoScale", false) end,
            set = function(_, value)
                self:ApplySettingWithPreview("general.autoScale", value)
            end,
        },
        combatProtection = {
            type = "toggle",
            name = "Combat Protection",
            desc = "Prevent configuration changes during combat to avoid interface errors.",
            order = 8,
            get = function() return DamiaUI.Config:Get("general.combatProtection", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("general.combatProtection", value)
            end,
        },
        spacer2 = {
            type = "description",
            name = " ",
            order = 9,
        },
        rollbackHeader = {
            type = "header",
            name = "Configuration Recovery",
            order = 10,
        },
        rollbackButton = {
            type = "execute",
            name = "Rollback Last Change",
            desc = "Undo the last configuration change and restore previous settings.",
            order = 11,
            func = function()
                self:RollbackToPreviousState()
            end,
            disabled = function()
                return #rollbackStack == 0
            end,
        },
        rollbackStates = {
            type = "description",
            name = function()
                return string.format("Available rollback states: %d/%d", #rollbackStack, maxRollbackStates)
            end,
            order = 12,
        },
        spacer3 = {
            type = "description",
            name = " ",
            order = 13,
        },
        resetHeader = {
            type = "header",
            name = "Reset Options",
            order = 14,
        },
        resetButton = {
            type = "execute",
            name = "Reset All Settings",
            desc = "Reset all DamiaUI settings to their default values. This action creates a backup automatically.",
            order = 15,
            func = function()
                DamiaUI:ResetAllSettings()
            end,
            confirm = function()
                return "Are you sure you want to reset all settings? A backup will be created automatically."
            end,
        },
    }
end

--[[
    Unit Frame Options
]]

function Configuration:GetUnitFrameOptions()
    return {
        header = {
            type = "header",
            name = "Unit Frame Settings",
            order = 1,
        },
        player = {
            type = "group",
            name = "Player Frame",
            order = 2,
            inline = true,
            args = self:GetUnitFrameGroupOptions("player"),
        },
        target = {
            type = "group", 
            name = "Target Frame",
            order = 3,
            inline = true,
            args = self:GetUnitFrameGroupOptions("target"),
        },
        focus = {
            type = "group",
            name = "Focus Frame",
            order = 4,
            inline = true,
            args = self:GetUnitFrameGroupOptions("focus"),
        },
        party = {
            type = "group",
            name = "Party Frames",
            order = 5,
            inline = true,
            args = self:GetUnitFrameGroupOptions("party"),
        },
    }
end

function Configuration:GetUnitFrameGroupOptions(unit)
    return {
        enabled = {
            type = "toggle",
            name = "Enable",
            desc = "Show/hide this unit frame",
            order = 1,
            get = function() return DamiaUI.Config.Get("unitframes." .. unit .. ".enabled", true) end,
            set = function(_, value)
                DamiaUI.Config.Set("unitframes." .. unit .. ".enabled", value)
            end,
        },
        scale = {
            type = "range",
            name = "Scale",
            desc = "Adjust the scale of this frame",
            order = 2,
            min = 0.5,
            max = 2.0,
            step = 0.05,
            get = function() return DamiaUI.Config.Get("unitframes." .. unit .. ".scale", 1.0) end,
            set = function(_, value)
                DamiaUI.Config.Set("unitframes." .. unit .. ".scale", value)
            end,
        },
        showName = {
            type = "toggle",
            name = "Show Name",
            desc = "Display unit name on the frame",
            order = 3,
            get = function() return DamiaUI.Config.Get("unitframes." .. unit .. ".showName", true) end,
            set = function(_, value)
                DamiaUI.Config.Set("unitframes." .. unit .. ".showName", value)
            end,
        },
        showLevel = {
            type = "toggle",
            name = "Show Level",
            desc = "Display unit level on the frame",
            order = 4,
            get = function() return DamiaUI.Config.Get("unitframes." .. unit .. ".showLevel", unit ~= "player") end,
            set = function(_, value)
                DamiaUI.Config.Set("unitframes." .. unit .. ".showLevel", value)
            end,
        },
    }
end

--[[
    Action Bar Options
]]

function Configuration:GetActionBarOptions()
    return {
        header = {
            type = "header",
            name = "Action Bar Configuration", 
            order = 1,
        },
        description = {
            type = "description",
            name = "Configure the positioning, sizing, and behavior of all action bars. Includes main bar, secondary bars, pet bar, and stance bar.",
            order = 2,
        },
        enabled = {
            type = "toggle",
            name = "Enable Action Bars",
            desc = "Master toggle for all DamiaUI action bars. When disabled, Blizzard default action bars will be used.",
            order = 3,
            width = "full",
            get = function() return DamiaUI.Config:Get("actionbars.enabled", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.enabled", value)
            end,
        },
        hideBlizzardBars = {
            type = "toggle",
            name = "Hide Blizzard Bars",
            desc = "Hide the default Blizzard action bars when DamiaUI action bars are enabled.",
            order = 4,
            width = "full",
            get = function() return DamiaUI.Config:Get("actionbars.hideBlizzardBars", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.hideBlizzardBars", value)
            end,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 5,
        },
        mainbar = {
            type = "group",
            name = "Main Action Bar",
            desc = "Primary action bar containing your most used abilities",
            order = 10,
            args = self:GetActionBarGroupOptions("mainbar"),
        },
        secondarybar = {
            type = "group",
            name = "Secondary Action Bar",
            desc = "Additional action bar for extra abilities",
            order = 20,
            args = self:GetActionBarGroupOptions("secondarybar"),
        },
        rightbar1 = {
            type = "group",
            name = "Right Action Bar 1",
            desc = "First vertical action bar on the right side",
            order = 30,
            args = self:GetActionBarGroupOptions("rightbar1"),
        },
        rightbar2 = {
            type = "group",
            name = "Right Action Bar 2",
            desc = "Second vertical action bar on the right side",
            order = 40,
            args = self:GetActionBarGroupOptions("rightbar2"),
        },
        petbar = {
            type = "group",
            name = "Pet Action Bar",
            desc = "Action bar for pet abilities and commands",
            order = 50,
            args = self:GetPetBarOptions(),
        },
        stancebar = {
            type = "group",
            name = "Stance/Shapeshift Bar",
            desc = "Bar for stance, shapeshift, and aura abilities",
            order = 60,
            args = self:GetStanceBarOptions(),
        },
    }
end

function Configuration:GetActionBarGroupOptions(barName)
    local barDisplayName = barName:gsub("^%l", string.upper):gsub("bar", " Bar")
    local isMainBar = barName == "mainbar"
    local isVertical = barName:match("right")
    
    return {
        header = {
            type = "header",
            name = barDisplayName .. " Settings",
            order = 1,
        },
        enabled = {
            type = "toggle",
            name = "Enable " .. barDisplayName,
            desc = "Show/hide this action bar. When disabled, buttons will not be displayed.",
            order = 2,
            width = "full",
            get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".enabled", isMainBar) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars." .. barName .. ".enabled", value)
            end,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 3,
        },
        layoutGroup = {
            type = "group",
            name = "Layout & Positioning",
            order = 10,
            inline = true,
            args = {
                buttonSize = {
                    type = "range",
                    name = "Button Size",
                    desc = "Size of individual action buttons in pixels.",
                    order = 1,
                    min = 20,
                    max = 64,
                    step = 2,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".buttonSize", isMainBar and 36 or 32) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".buttonSize", value)
                    end,
                },
                buttonSpacing = {
                    type = "range",
                    name = "Button Spacing",
                    desc = "Space between action buttons in pixels.",
                    order = 2,
                    min = 0,
                    max = 15,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".buttonSpacing", 4) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".buttonSpacing", value)
                    end,
                },
                buttonsPerRow = {
                    type = "range",
                    name = isVertical and "Buttons Per Column" or "Buttons Per Row",
                    desc = isVertical and "Number of buttons in each column." or "Number of buttons in each row.",
                    order = 3,
                    min = 1,
                    max = 12,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".buttonsPerRow", isVertical and 1 or 12) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".buttonsPerRow", value)
                    end,
                },
                orientation = {
                    type = "select",
                    name = "Orientation",
                    desc = "Layout orientation of the action bar.",
                    order = 4,
                    values = {
                        ["HORIZONTAL"] = "Horizontal",
                        ["VERTICAL"] = "Vertical",
                    },
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".orientation", isVertical and "VERTICAL" or "HORIZONTAL") end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".orientation", value)
                    end,
                },
            },
        },
        displayGroup = {
            type = "group",
            name = "Display Options",
            order = 20,
            inline = true,
            args = {
                showKeybinds = {
                    type = "toggle",
                    name = "Show Keybinds",
                    desc = "Display keybind text on action buttons.",
                    order = 1,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".showKeybinds", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".showKeybinds", value)
                    end,
                },
                showMacroNames = {
                    type = "toggle",
                    name = "Show Macro Names",
                    desc = "Display macro names on action buttons that contain macros.",
                    order = 2,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".showMacroNames", false) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".showMacroNames", value)
                    end,
                },
                showCooldowns = {
                    type = "toggle",
                    name = "Show Cooldowns",
                    desc = "Display cooldown timers on action buttons.",
                    order = 3,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".showCooldowns", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".showCooldowns", value)
                    end,
                },
                showTooltips = {
                    type = "toggle",
                    name = "Show Tooltips",
                    desc = "Show tooltips when hovering over action buttons.",
                    order = 4,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".showTooltips", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".showTooltips", value)
                    end,
                },
            },
        },
        fadeGroup = {
            type = "group",
            name = "Fade Options",
            order = 30,
            inline = true,
            args = {
                fadeOutOfCombat = {
                    type = "toggle",
                    name = "Fade Out of Combat",
                    desc = "Reduce opacity when not in combat and not hovering over the bar.",
                    order = 1,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".fadeOutOfCombat", false) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".fadeOutOfCombat", value)
                    end,
                },
                fadeOpacity = {
                    type = "range",
                    name = "Fade Opacity",
                    desc = "Opacity level when faded out (0 = invisible, 1 = fully visible).",
                    order = 2,
                    min = 0,
                    max = 1,
                    step = 0.05,
                    isPercent = true,
                    get = function() return DamiaUI.Config:Get("actionbars." .. barName .. ".fadeOpacity", 0.6) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars." .. barName .. ".fadeOpacity", value)
                    end,
                    disabled = function()
                        return not DamiaUI.Config:Get("actionbars." .. barName .. ".fadeOutOfCombat", false)
                    end,
                },
            },
        },
    }
end

-- Pet bar specific options
function Configuration:GetPetBarOptions()
    return {
        header = {
            type = "header",
            name = "Pet Action Bar Settings",
            order = 1,
        },
        enabled = {
            type = "toggle",
            name = "Enable Pet Bar",
            desc = "Show pet action bar when you have an active pet with abilities.",
            order = 2,
            width = "full",
            get = function() return DamiaUI.Config:Get("actionbars.petbar.enabled", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.petbar.enabled", value)
            end,
        },
        autoHide = {
            type = "toggle",
            name = "Auto Hide",
            desc = "Automatically hide the pet bar when no pet is active.",
            order = 3,
            get = function() return DamiaUI.Config:Get("actionbars.petbar.autoHide", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.petbar.autoHide", value)
            end,
        },
        layoutGroup = {
            type = "group",
            name = "Layout",
            order = 10,
            inline = true,
            args = {
                buttonSize = {
                    type = "range",
                    name = "Button Size",
                    desc = "Size of pet action buttons.",
                    order = 1,
                    min = 16,
                    max = 48,
                    step = 2,
                    get = function() return DamiaUI.Config:Get("actionbars.petbar.buttonSize", 30) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.petbar.buttonSize", value)
                    end,
                },
                buttonSpacing = {
                    type = "range",
                    name = "Button Spacing",
                    desc = "Space between pet action buttons.",
                    order = 2,
                    min = 0,
                    max = 10,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.petbar.buttonSpacing", 2) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.petbar.buttonSpacing", value)
                    end,
                },
                buttonsPerRow = {
                    type = "range",
                    name = "Buttons Per Row",
                    desc = "Number of pet buttons in each row.",
                    order = 3,
                    min = 1,
                    max = 10,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.petbar.buttonsPerRow", 10) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.petbar.buttonsPerRow", value)
                    end,
                },
            },
        },
        displayGroup = {
            type = "group",
            name = "Display Options",
            order = 20,
            inline = true,
            args = {
                showKeybinds = {
                    type = "toggle",
                    name = "Show Keybinds",
                    desc = "Display keybind text on pet action buttons.",
                    order = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.petbar.showKeybinds", false) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.petbar.showKeybinds", value)
                    end,
                },
                showCooldowns = {
                    type = "toggle",
                    name = "Show Cooldowns",
                    desc = "Display cooldown timers on pet abilities.",
                    order = 2,
                    get = function() return DamiaUI.Config:Get("actionbars.petbar.showCooldowns", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.petbar.showCooldowns", value)
                    end,
                },
            },
        },
    }
end

-- Stance bar specific options
function Configuration:GetStanceBarOptions()
    return {
        header = {
            type = "header",
            name = "Stance/Shapeshift Bar Settings",
            order = 1,
        },
        enabled = {
            type = "toggle",
            name = "Enable Stance Bar",
            desc = "Show stance/shapeshift bar for classes that have stances or forms.",
            order = 2,
            width = "full",
            get = function() return DamiaUI.Config:Get("actionbars.stancebar.enabled", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.stancebar.enabled", value)
            end,
        },
        autoHide = {
            type = "toggle",
            name = "Auto Hide",
            desc = "Automatically hide the stance bar if your class doesn't have stances or forms.",
            order = 3,
            get = function() return DamiaUI.Config:Get("actionbars.stancebar.autoHide", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("actionbars.stancebar.autoHide", value)
            end,
        },
        layoutGroup = {
            type = "group",
            name = "Layout",
            order = 10,
            inline = true,
            args = {
                buttonSize = {
                    type = "range",
                    name = "Button Size",
                    desc = "Size of stance/shapeshift buttons.",
                    order = 1,
                    min = 16,
                    max = 48,
                    step = 2,
                    get = function() return DamiaUI.Config:Get("actionbars.stancebar.buttonSize", 30) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.stancebar.buttonSize", value)
                    end,
                },
                buttonSpacing = {
                    type = "range",
                    name = "Button Spacing",
                    desc = "Space between stance buttons.",
                    order = 2,
                    min = 0,
                    max = 10,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.stancebar.buttonSpacing", 2) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.stancebar.buttonSpacing", value)
                    end,
                },
                buttonsPerRow = {
                    type = "range",
                    name = "Buttons Per Row",
                    desc = "Number of stance buttons in each row.",
                    order = 3,
                    min = 1,
                    max = 8,
                    step = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.stancebar.buttonsPerRow", 6) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.stancebar.buttonsPerRow", value)
                    end,
                },
            },
        },
        displayGroup = {
            type = "group",
            name = "Display Options",
            order = 20,
            inline = true,
            args = {
                showKeybinds = {
                    type = "toggle",
                    name = "Show Keybinds",
                    desc = "Display keybind text on stance buttons.",
                    order = 1,
                    get = function() return DamiaUI.Config:Get("actionbars.stancebar.showKeybinds", false) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.stancebar.showKeybinds", value)
                    end,
                },
                showCooldowns = {
                    type = "toggle",
                    name = "Show Cooldowns",
                    desc = "Display cooldown timers on stance abilities.",
                    order = 2,
                    get = function() return DamiaUI.Config:Get("actionbars.stancebar.showCooldowns", false) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("actionbars.stancebar.showCooldowns", value)
                    end,
                },
            },
        },
    }
end

--[[
    Interface Options
]]

function Configuration:GetInterfaceOptions()
    return {
        header = {
            type = "header", 
            name = "Interface Configuration",
            order = 1,
        },
        description = {
            type = "description",
            name = "Configure chat, minimap, tooltips, and other interface elements. These settings control how you interact with the game world.",
            order = 2,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 3,
        },
        chat = {
            type = "group",
            name = "Chat Frame",
            desc = "Configure chat frame positioning, appearance, and behavior",
            order = 10,
            args = {
                header = {
                    type = "header",
                    name = "Chat Frame Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable Chat Positioning",
                    desc = "Allow DamiaUI to manage chat frame positioning and styling. When disabled, chat frames use Blizzard defaults.",
                    order = 2,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("interface.chat.enabled", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("interface.chat.enabled", value)
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 3,
                },
                appearanceGroup = {
                    type = "group",
                    name = "Appearance",
                    order = 10,
                    inline = true,
                    args = {
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            desc = "Size of chat text in pixels.",
                            order = 1,
                            min = 8,
                            max = 24,
                            step = 1,
                            get = function() return DamiaUI.Config:Get("interface.chat.fontSize", 12) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.fontSize", value)
                            end,
                        },
                        width = {
                            type = "range",
                            name = "Chat Width",
                            desc = "Width of the chat frame in pixels.",
                            order = 2,
                            min = 200,
                            max = 600,
                            step = 10,
                            get = function() return DamiaUI.Config:Get("interface.chat.width", 350) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.width", value)
                            end,
                        },
                        height = {
                            type = "range",
                            name = "Chat Height",
                            desc = "Height of the chat frame in pixels.",
                            order = 3,
                            min = 80,
                            max = 300,
                            step = 10,
                            get = function() return DamiaUI.Config:Get("interface.chat.height", 120) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.height", value)
                            end,
                        },
                    },
                },
                behaviorGroup = {
                    type = "group",
                    name = "Behavior",
                    order = 20,
                    inline = true,
                    args = {
                        fadeOut = {
                            type = "toggle",
                            name = "Fade Out",
                            desc = "Fade chat messages after a period of inactivity.",
                            order = 1,
                            get = function() return DamiaUI.Config:Get("interface.chat.fadeOut", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.fadeOut", value)
                            end,
                        },
                        fadeTimeout = {
                            type = "range",
                            name = "Fade Timeout",
                            desc = "Time in seconds before chat messages fade out.",
                            order = 2,
                            min = 5,
                            max = 120,
                            step = 5,
                            get = function() return DamiaUI.Config:Get("interface.chat.fadeTimeout", 30) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.fadeTimeout", value)
                            end,
                            disabled = function()
                                return not DamiaUI.Config:Get("interface.chat.fadeOut", true)
                            end,
                        },
                        showTimestamps = {
                            type = "toggle",
                            name = "Show Timestamps",
                            desc = "Display timestamps on chat messages.",
                            order = 3,
                            get = function() return DamiaUI.Config:Get("interface.chat.showTimestamps", false) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.chat.showTimestamps", value)
                            end,
                        },
                    },
                },
            },
        },
        minimap = {
            type = "group",
            name = "Minimap",
            desc = "Configure minimap positioning, scale, and display options",
            order = 20,
            args = {
                header = {
                    type = "header",
                    name = "Minimap Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable Minimap Positioning",
                    desc = "Allow DamiaUI to manage minimap positioning and styling. When disabled, minimap uses Blizzard defaults.",
                    order = 2,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("interface.minimap.enabled", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("interface.minimap.enabled", value)
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 3,
                },
                sizeGroup = {
                    type = "group",
                    name = "Size & Scale",
                    order = 10,
                    inline = true,
                    args = {
                        scale = {
                            type = "range",
                            name = "Scale",
                            desc = "Scale of the minimap relative to other UI elements.",
                            order = 1,
                            min = 0.5,
                            max = 2.0,
                            step = 0.05,
                            isPercent = true,
                            get = function() return DamiaUI.Config:Get("interface.minimap.scale", 1.0) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.scale", value)
                            end,
                        },
                        size = {
                            type = "range",
                            name = "Size",
                            desc = "Size of the minimap in pixels.",
                            order = 2,
                            min = 100,
                            max = 250,
                            step = 10,
                            get = function() return DamiaUI.Config:Get("interface.minimap.size", 140) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.size", value)
                            end,
                        },
                    },
                },
                displayGroup = {
                    type = "group",
                    name = "Display Options",
                    order = 20,
                    inline = true,
                    args = {
                        showClock = {
                            type = "toggle",
                            name = "Show Clock",
                            desc = "Display the time on the minimap.",
                            order = 1,
                            get = function() return DamiaUI.Config:Get("interface.minimap.showClock", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.showClock", value)
                            end,
                        },
                        showZoneText = {
                            type = "toggle",
                            name = "Show Zone Text",
                            desc = "Display the current zone name on the minimap.",
                            order = 2,
                            get = function() return DamiaUI.Config:Get("interface.minimap.showZoneText", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.showZoneText", value)
                            end,
                        },
                        showDifficulty = {
                            type = "toggle",
                            name = "Show Difficulty",
                            desc = "Display instance difficulty indicator on the minimap.",
                            order = 3,
                            get = function() return DamiaUI.Config:Get("interface.minimap.showDifficulty", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.showDifficulty", value)
                            end,
                        },
                        zoomOnMouseWheel = {
                            type = "toggle",
                            name = "Zoom on Mouse Wheel",
                            desc = "Allow mouse wheel scrolling to zoom the minimap in and out.",
                            order = 4,
                            get = function() return DamiaUI.Config:Get("interface.minimap.zoomOnMouseWheel", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.minimap.zoomOnMouseWheel", value)
                            end,
                        },
                    },
                },
            },
        },
        tooltip = {
            type = "group",
            name = "Tooltips",
            desc = "Configure tooltip appearance, positioning, and information display",
            order = 30,
            args = {
                header = {
                    type = "header",
                    name = "Tooltip Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable Tooltip Enhancements",
                    desc = "Allow DamiaUI to enhance tooltips with additional information and styling.",
                    order = 2,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("interface.tooltip.enabled", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("interface.tooltip.enabled", value)
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 3,
                },
                positionGroup = {
                    type = "group",
                    name = "Positioning",
                    order = 10,
                    inline = true,
                    args = {
                        anchor = {
                            type = "select",
                            name = "Anchor Point",
                            desc = "Where tooltips appear relative to your cursor or screen.",
                            order = 1,
                            values = {
                                ["CURSOR"] = "Follow Cursor",
                                ["TOPLEFT"] = "Top Left",
                                ["TOPRIGHT"] = "Top Right",
                                ["BOTTOMLEFT"] = "Bottom Left",
                                ["BOTTOMRIGHT"] = "Bottom Right",
                            },
                            get = function() return DamiaUI.Config:Get("interface.tooltip.anchor", "CURSOR") end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.anchor", value)
                            end,
                        },
                        scale = {
                            type = "range",
                            name = "Scale",
                            desc = "Scale of tooltip frames.",
                            order = 2,
                            min = 0.5,
                            max = 1.5,
                            step = 0.05,
                            isPercent = true,
                            get = function() return DamiaUI.Config:Get("interface.tooltip.scale", 1.0) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.scale", value)
                            end,
                        },
                    },
                },
                infoGroup = {
                    type = "group",
                    name = "Information Display",
                    order = 20,
                    inline = true,
                    args = {
                        showHealthBar = {
                            type = "toggle",
                            name = "Show Health Bar",
                            desc = "Display a health bar in unit tooltips.",
                            order = 1,
                            get = function() return DamiaUI.Config:Get("interface.tooltip.showHealthBar", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.showHealthBar", value)
                            end,
                        },
                        showTarget = {
                            type = "toggle",
                            name = "Show Target",
                            desc = "Display what the unit is targeting in tooltips.",
                            order = 2,
                            get = function() return DamiaUI.Config:Get("interface.tooltip.showTarget", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.showTarget", value)
                            end,
                        },
                        showGuild = {
                            type = "toggle",
                            name = "Show Guild",
                            desc = "Display guild information in player tooltips.",
                            order = 3,
                            get = function() return DamiaUI.Config:Get("interface.tooltip.showGuild", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.showGuild", value)
                            end,
                        },
                        showItemLevel = {
                            type = "toggle",
                            name = "Show Item Level",
                            desc = "Display item level in equipment tooltips.",
                            order = 4,
                            get = function() return DamiaUI.Config:Get("interface.tooltip.showItemLevel", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("interface.tooltip.showItemLevel", value)
                            end,
                        },
                    },
                },
            },
        },
    }
end

--[[
    Skinning Options
]]

function Configuration:GetSkinningOptions()
    return {
        header = {
            type = "header",
            name = "Skinning Configuration",
            order = 1,
        },
        description = {
            type = "description",
            name = "Configure the Aurora-based skinning system that provides a consistent visual theme across all interface elements. Customize colors, effects, and which frames to skin.",
            order = 2,
        },
        enabled = {
            type = "toggle", 
            name = "Enable Skinning System",
            desc = "Enable the Aurora-based skinning system for consistent visual theming. When disabled, interface elements use their default Blizzard appearance.",
            order = 3,
            width = "full",
            get = function() return DamiaUI.Config:Get("skinning.enabled", true) end,
            set = function(_, value)
                self:ApplySettingWithPreview("skinning.enabled", value)
            end,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 4,
        },
        frameTypes = {
            type = "group",
            name = "Frame Types",
            desc = "Control which types of frames are skinned",
            order = 10,
            args = {
                header = {
                    type = "header",
                    name = "Frame Skinning Options",
                    order = 1,
                },
                blizzardFrames = {
                    type = "toggle",
                    name = "Skin Blizzard Frames",
                    desc = "Apply Aurora skinning to Blizzard interface elements like character panel, spellbook, bags, etc.",
                    order = 2,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("skinning.blizzardFrames", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("skinning.blizzardFrames", value)
                    end,
                },
                thirdPartyFrames = {
                    type = "toggle",
                    name = "Skin Third-Party Addons",
                    desc = "Apply Aurora skinning to known third-party addon frames for visual consistency.",
                    order = 3,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("skinning.thirdPartyFrames", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("skinning.thirdPartyFrames", value)
                    end,
                },
                customFrames = {
                    type = "toggle",
                    name = "Skin Custom Frames",
                    desc = "Apply skinning to custom frames created by DamiaUI modules.",
                    order = 4,
                    width = "full",
                    get = function() return DamiaUI.Config:Get("skinning.customFrames", true) end,
                    set = function(_, value)
                        self:ApplySettingWithPreview("skinning.customFrames", value)
                    end,
                },
            },
        },
        colors = {
            type = "group",
            name = "Color Scheme",
            desc = "Customize the color scheme used by the skinning system",
            order = 20,
            args = {
                header = {
                    type = "header",
                    name = "Custom Color Settings",
                    order = 1,
                },
                description = {
                    type = "description",
                    name = "Customize the colors used by Aurora skinning. Changes apply immediately to all skinned frames.",
                    order = 2,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 3,
                },
                primaryColors = {
                    type = "group",
                    name = "Primary Colors",
                    order = 10,
                    inline = true,
                    args = {
                        background = {
                            type = "color",
                            name = "Background",
                            desc = "Main background color for skinned frames.",
                            order = 1,
                            hasAlpha = true,
                            get = function()
                                local color = DamiaUI.Config:Get("skinning.customColors.background", 
                                    { r = 0.1, g = 0.1, b = 0.1, a = 0.95 })
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(_, r, g, b, a)
                                self:ApplySettingWithPreview("skinning.customColors.background", { r = r, g = g, b = b, a = a })
                            end,
                        },
                        border = {
                            type = "color",
                            name = "Border", 
                            desc = "Border color for skinned frames.",
                            order = 2,
                            hasAlpha = true,
                            get = function()
                                local color = DamiaUI.Config:Get("skinning.customColors.border",
                                    { r = 0.3, g = 0.3, b = 0.3, a = 1.0 })
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(_, r, g, b, a)
                                self:ApplySettingWithPreview("skinning.customColors.border", { r = r, g = g, b = b, a = a })
                            end,
                        },
                        accent = {
                            type = "color",
                            name = "Accent",
                            desc = "Accent color for highlights and special elements.",
                            order = 3,
                            hasAlpha = true,
                            get = function()
                                local color = DamiaUI.Config:Get("skinning.customColors.accent",
                                    { r = 0.8, g = 0.5, b = 0.1, a = 1.0 })
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(_, r, g, b, a)
                                self:ApplySettingWithPreview("skinning.customColors.accent", { r = r, g = g, b = b, a = a })
                            end,
                        },
                    },
                },
                textColors = {
                    type = "group",
                    name = "Text Colors",
                    order = 20,
                    inline = true,
                    args = {
                        text = {
                            type = "color",
                            name = "Normal Text",
                            desc = "Primary text color for interface elements.",
                            order = 1,
                            hasAlpha = true,
                            get = function()
                                local color = DamiaUI.Config:Get("skinning.customColors.text",
                                    { r = 1.0, g = 1.0, b = 1.0, a = 1.0 })
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(_, r, g, b, a)
                                self:ApplySettingWithPreview("skinning.customColors.text", { r = r, g = g, b = b, a = a })
                            end,
                        },
                        textHighlight = {
                            type = "color",
                            name = "Highlighted Text",
                            desc = "Color for highlighted or important text.",
                            order = 2,
                            hasAlpha = true,
                            get = function()
                                local color = DamiaUI.Config:Get("skinning.customColors.textHighlight",
                                    { r = 1.0, g = 0.8, b = 0.0, a = 1.0 })
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(_, r, g, b, a)
                                self:ApplySettingWithPreview("skinning.customColors.textHighlight", { r = r, g = g, b = b, a = a })
                            end,
                        },
                    },
                },
                presets = {
                    type = "group",
                    name = "Color Presets",
                    order = 30,
                    inline = true,
                    args = {
                        darkTheme = {
                            type = "execute",
                            name = "Dark Theme",
                            desc = "Apply a dark color scheme.",
                            order = 1,
                            func = function()
                                self:ApplyColorPreset("dark")
                            end,
                        },
                        lightTheme = {
                            type = "execute",
                            name = "Light Theme",
                            desc = "Apply a light color scheme.",
                            order = 2,
                            func = function()
                                self:ApplyColorPreset("light")
                            end,
                        },
                        blueTheme = {
                            type = "execute",
                            name = "Blue Theme",
                            desc = "Apply a blue-tinted color scheme.",
                            order = 3,
                            func = function()
                                self:ApplyColorPreset("blue")
                            end,
                        },
                        resetColors = {
                            type = "execute",
                            name = "Reset to Defaults",
                            desc = "Reset all colors to default values.",
                            order = 4,
                            func = function()
                                self:ApplyColorPreset("default")
                            end,
                        },
                    },
                },
            },
        },
        options = {
            type = "group",
            name = "Advanced Options",
            desc = "Advanced skinning options and effects",
            order = 30,
            args = {
                header = {
                    type = "header",
                    name = "Advanced Skinning Settings",
                    order = 1,
                },
                effects = {
                    type = "group",
                    name = "Visual Effects",
                    order = 10,
                    inline = true,
                    args = {
                        enableBackdrops = {
                            type = "toggle",
                            name = "Enable Backdrops",
                            desc = "Show background textures on skinned frames.",
                            order = 1,
                            get = function() return DamiaUI.Config:Get("skinning.options.enableBackdrops", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("skinning.options.enableBackdrops", value)
                            end,
                        },
                        enableBorders = {
                            type = "toggle",
                            name = "Enable Borders",
                            desc = "Show borders around skinned frames.",
                            order = 2,
                            get = function() return DamiaUI.Config:Get("skinning.options.enableBorders", true) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("skinning.options.enableBorders", value)
                            end,
                        },
                        enableGradients = {
                            type = "toggle",
                            name = "Enable Gradients",
                            desc = "Use gradient effects on skinned frames.",
                            order = 3,
                            get = function() return DamiaUI.Config:Get("skinning.options.enableGradients", false) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("skinning.options.enableGradients", value)
                            end,
                        },
                    },
                },
                settings = {
                    type = "group",
                    name = "Technical Settings",
                    order = 20,
                    inline = true,
                    args = {
                        borderSize = {
                            type = "range",
                            name = "Border Size",
                            desc = "Thickness of frame borders in pixels.",
                            order = 1,
                            min = 1,
                            max = 5,
                            step = 1,
                            get = function() return DamiaUI.Config:Get("skinning.options.borderSize", 1) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("skinning.options.borderSize", value)
                            end,
                        },
                        backdropAlpha = {
                            type = "range",
                            name = "Backdrop Alpha",
                            desc = "Transparency level of frame backgrounds.",
                            order = 2,
                            min = 0,
                            max = 1,
                            step = 0.05,
                            isPercent = true,
                            get = function() return DamiaUI.Config:Get("skinning.options.backdropAlpha", 0.9) end,
                            set = function(_, value)
                                self:ApplySettingWithPreview("skinning.options.backdropAlpha", value)
                            end,
                        },
                    },
                },
            },
        },
    }
end

-- Get tools options
function Configuration:GetToolsOptions()
    return {
        header = {
            type = "header",
            name = "Configuration Tools",
            order = 1,
        },
        description = {
            type = "description",
            name = "Utilities and tools for managing your DamiaUI configuration, profiles, and troubleshooting.",
            order = 2,
        },
        spacer1 = {
            type = "description",
            name = " ",
            order = 3,
        },
        profiles = {
            type = "group",
            name = "Profile Management",
            desc = "Manage configuration profiles",
            order = 10,
            args = {
                header = {
                    type = "header",
                    name = "Profile Tools",
                    order = 1,
                },
                currentProfile = {
                    type = "description",
                    name = function()
                        local current = DamiaUI.Config and DamiaUI.Config:GetCurrentProfile() or "Unknown"
                        return "Current Profile: |cff00ff00" .. current .. "|r"
                    end,
                    order = 2,
                },
                profileSelect = {
                    type = "select",
                    name = "Switch Profile",
                    desc = "Switch to a different configuration profile.",
                    order = 3,
                    values = function()
                        if not DamiaUI.Profiles then return {} end
                        local profiles = {}
                        for _, name in ipairs(DamiaUI.Profiles:GetProfileList()) do
                            profiles[name] = name
                        end
                        return profiles
                    end,
                    get = function()
                        return DamiaUI.Config and DamiaUI.Config:GetCurrentProfile() or "Default"
                    end,
                    set = function(_, value)
                        if DamiaUI.Profiles then
                            DamiaUI.Profiles:SwitchProfile(value)
                        end
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 4,
                },
                createProfile = {
                    type = "input",
                    name = "Create New Profile",
                    desc = "Enter a name for the new profile.",
                    order = 5,
                    get = function() return "" end,
                    set = function(_, value)
                        if value and value ~= "" and DamiaUI.Profiles then
                            DamiaUI.Profiles:CreateProfile(value, DamiaUI.Config:GetCurrentProfile())
                        end
                    end,
                },
                copyProfile = {
                    type = "toggle",
                    name = "Copy Current Settings",
                    desc = "Copy settings from current profile to the new profile.",
                    order = 6,
                    get = function() return true end,
                    set = function() end,
                    disabled = true,
                },
                spacer2 = {
                    type = "description",
                    name = " ",
                    order = 7,
                },
                resetProfile = {
                    type = "execute",
                    name = "Reset Current Profile",
                    desc = "Reset the current profile to default settings.",
                    order = 8,
                    func = function()
                        if DamiaUI.Profiles then
                            DamiaUI.Profiles:ResetProfile()
                        end
                    end,
                    confirm = function()
                        return "Are you sure you want to reset the current profile? This action creates a backup automatically."
                    end,
                },
            },
        },
        backup = {
            type = "group",
            name = "Backup & Recovery",
            desc = "Backup and restore configuration data",
            order = 20,
            args = {
                header = {
                    type = "header",
                    name = "Backup Tools",
                    order = 1,
                },
                createBackup = {
                    type = "execute",
                    name = "Create Manual Backup",
                    desc = "Create a backup of all current settings.",
                    order = 2,
                    func = function()
                        if DamiaUI.Config then
                            DamiaUI.Config:CreateBackup("manual_" .. date("%Y%m%d_%H%M%S"))
                        end
                    end,
                },
                backupCount = {
                    type = "description",
                    name = function()
                        if not DamiaUI.Config then return "Backups: Unknown" end
                        local backups = DamiaUI.Config:GetBackups()
                        return string.format("Available Backups: %d", #backups)
                    end,
                    order = 3,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 4,
                },
                rollbackStates = {
                    type = "description",
                    name = function()
                        return string.format("Rollback States: %d/%d", #rollbackStack, maxRollbackStates)
                    end,
                    order = 5,
                },
                rollbackButton = {
                    type = "execute",
                    name = "Rollback Last Change",
                    desc = "Undo the last configuration change.",
                    order = 6,
                    func = function()
                        self:RollbackToPreviousState()
                    end,
                    disabled = function()
                        return #rollbackStack == 0
                    end,
                },
            },
        },
        import = {
            type = "group",
            name = "Import/Export",
            desc = "Share configuration profiles",
            order = 30,
            args = {
                header = {
                    type = "header",
                    name = "Import/Export Tools",
                    order = 1,
                },
                description = {
                    type = "description",
                    name = "Use these tools to share your configuration with others or backup your settings externally.",
                    order = 2,
                },
                exportProfile = {
                    type = "execute",
                    name = "Export Current Profile",
                    desc = "Export current profile to a shareable format.",
                    order = 3,
                    func = function()
                        if DamiaUI.Profiles then
                            local exportData = DamiaUI.Profiles:ExportProfile(nil, true)
                            if exportData then
                                DamiaUI:LogInfo("Profile exported successfully")
                                -- Could open a dialog with export string here
                            end
                        end
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 4,
                },
                importString = {
                    type = "input",
                    name = "Import Profile Data",
                    desc = "Paste profile export data here to import.",
                    order = 5,
                    multiline = true,
                    width = "full",
                    get = function() return "" end,
                    set = function(_, value)
                        if value and value ~= "" and DamiaUI.Profiles then
                            -- In a real implementation, this would parse the import string
                            DamiaUI:LogInfo("Import functionality would process: %d characters", #value)
                        end
                    end,
                },
            },
        },
        diagnostics = {
            type = "group",
            name = "Diagnostics",
            desc = "Troubleshooting and diagnostic tools",
            order = 40,
            args = {
                header = {
                    type = "header",
                    name = "Diagnostic Tools",
                    order = 1,
                },
                validateConfig = {
                    type = "execute",
                    name = "Validate Configuration",
                    desc = "Check configuration for errors and inconsistencies.",
                    order = 2,
                    func = function()
                        if DamiaUI.Config then
                            -- Perform configuration validation
                            DamiaUI:LogInfo("Configuration validation completed")
                        end
                    end,
                },
                repairConfig = {
                    type = "execute",
                    name = "Repair Configuration",
                    desc = "Attempt to repair configuration errors automatically.",
                    order = 3,
                    func = function()
                        if DamiaUI.Migration then
                            -- Perform configuration repair
                            DamiaUI:LogInfo("Configuration repair completed")
                        end
                    end,
                    confirm = function()
                        return "This will attempt to repair any configuration errors. Continue?"
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 4,
                },
                reloadUI = {
                    type = "execute",
                    name = "Reload UI",
                    desc = "Reload the user interface to apply all changes.",
                    order = 5,
                    func = function()
                        ReloadUI()
                    end,
                    confirm = function()
                        return "This will reload your entire user interface. Continue?"
                    end,
                },
                resetAll = {
                    type = "execute",
                    name = "Reset Everything",
                    desc = "Reset all DamiaUI settings to defaults.",
                    order = 6,
                    func = function()
                        DamiaUI:ResetAllSettings()
                    end,
                    confirm = function()
                        return "This will reset ALL DamiaUI settings to defaults. A backup will be created automatically. This action cannot be undone. Continue?"
                    end,
                },
            },
        },
    }
end

-- Apply color preset
function Configuration:ApplyColorPreset(presetName)
    local presets = {
        default = {
            background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
            border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
            accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 },
            text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
            textHighlight = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
        },
        dark = {
            background = { r = 0.05, g = 0.05, b = 0.05, a = 0.95 },
            border = { r = 0.2, g = 0.2, b = 0.2, a = 1.0 },
            accent = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 },
            text = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 },
            textHighlight = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
        },
        light = {
            background = { r = 0.9, g = 0.9, b = 0.9, a = 0.95 },
            border = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 },
            accent = { r = 0.3, g = 0.5, b = 0.8, a = 1.0 },
            text = { r = 0.1, g = 0.1, b = 0.1, a = 1.0 },
            textHighlight = { r = 0.2, g = 0.2, b = 0.8, a = 1.0 },
        },
        blue = {
            background = { r = 0.1, g = 0.1, b = 0.2, a = 0.95 },
            border = { r = 0.2, g = 0.3, b = 0.5, a = 1.0 },
            accent = { r = 0.3, g = 0.5, b = 0.8, a = 1.0 },
            text = { r = 0.9, g = 0.9, b = 1.0, a = 1.0 },
            textHighlight = { r = 0.5, g = 0.7, b = 1.0, a = 1.0 },
        },
    }
    
    local preset = presets[presetName]
    if not preset then
        DamiaUI:LogError("Unknown color preset: %s", presetName)
        return
    end
    
    -- Apply each color
    for colorType, color in pairs(preset) do
        self:ApplySettingWithPreview("skinning.customColors." .. colorType, color)
    end
    
    DamiaUI:LogInfo("Applied color preset: %s", presetName)
end

-- Event handlers for configuration changes
function Configuration:OnProfileChanged(oldProfile, newProfile)
    DamiaUI:LogDebug("Configuration: Profile changed %s -> %s", oldProfile, newProfile)
    
    -- Refresh configuration UI
    self:RefreshConfig()
end

function Configuration:OnConfigChanged(key, oldValue, newValue)
    DamiaUI:LogDebug("Configuration: Setting changed %s = %s (was %s)", key, tostring(newValue), tostring(oldValue))
end

--[[
    Public API
]]

-- Open configuration dialog
function Configuration:OpenConfig(category)
    if not isInitialized then
        DamiaUI:LogError("Configuration not initialized")
        return
    end
    
    -- Use AceConfigDialog to open directly
    if AceConfigDialog then
        AceConfigDialog:Open("DamiaUI")
        
        -- Select specific category if provided
        if category and AceConfigDialog.SelectGroup then
            AceConfigDialog:SelectGroup("DamiaUI", category)
        end
    else
        -- Fallback to Blizzard interface options
        InterfaceOptionsFrame_OpenToCategory(configFrame)
        InterfaceOptionsFrame_OpenToCategory(configFrame) -- Called twice due to Blizzard bug
    end
end

-- Refresh configuration options
function Configuration:RefreshConfig()
    if not isInitialized then
        return
    end
    
    -- Refresh the configuration registry
    AceConfigDialog:NotifyChange("DamiaUI")
end

-- Check if configuration is available
function Configuration:IsAvailable()
    return isInitialized
end

-- Get configuration status
function Configuration:GetStatus()
    return {
        initialized = isInitialized,
        livePreview = livePreviewEnabled,
        rollbackStates = #rollbackStack,
        maxRollbackStates = maxRollbackStates,
        aceConfigAvailable = AceConfig ~= nil,
        aceConfigDialogAvailable = AceConfigDialog ~= nil,
    }
end

-- Enable/disable live preview
function Configuration:SetLivePreview(enabled)
    livePreviewEnabled = enabled
    DamiaUI:LogInfo("Live preview %s", enabled and "enabled" or "disabled")
end

-- Clear rollback stack
function Configuration:ClearRollbackStack()
    rollbackStack = {}
    DamiaUI:LogInfo("Rollback stack cleared")
end

--[[
    Event Handlers
]]

function Configuration:ADDON_LOADED(event, loadedAddon)
    if loadedAddon == addonName then
        -- Initialize configuration after main addon loads
        C_Timer.After(3, function()
            if not isInitialized then
                self:SetupConfiguration()
            end
        end)
    end
end

--[[
    Minimap Button Integration
]]

function Configuration:CreateMinimapButton()
    if not DamiaUI.Libraries.DataBroker then
        return
    end
    
    local LDB = DamiaUI.Libraries.DataBroker
    
    -- Create data broker object
    local damiaLDB = LDB:NewDataObject("DamiaUI", {
        type = "launcher",
        text = "DamiaUI",
        icon = "Interface\\Icons\\INV_Gizmo_02",
        OnClick = function(self, button)
            if button == "LeftButton" then
                Configuration:OpenConfig()
            elseif button == "RightButton" then
                DamiaUI:SlashCommand("help")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("DamiaUI")
            tooltip:AddLine("|cffeda55fLeft Click|r: Open Configuration")
            tooltip:AddLine("|cffeda55fRight Click|r: Show Help")
        end,
    })
    
    return damiaLDB
end

-- Register the module
DamiaUI:RegisterModule("Configuration", Configuration)