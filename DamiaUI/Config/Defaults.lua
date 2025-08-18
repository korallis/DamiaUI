--[[
    DamiaUI Default Configuration
    
    Default configuration values for all DamiaUI modules and features.
    This serves as the base template for new profiles and fallback values.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...

-- Ensure DamiaUI exists in global namespace
local DamiaUI = _G.DamiaUI
if not DamiaUI then
    -- Create temporary holder if Engine hasn't loaded yet
    DamiaUI = {}
    _G.DamiaUI = DamiaUI
end

-- Initialize defaults table
DamiaUI.Defaults = {
    --[[
        Profile Structure for AceDB
    ]]
    profile = {
        --[[
            General Settings
        ]]
        general = {
            enabled = true,
            version = "1.0.0",
            firstRun = true,
            scale = 1.0,
            debugMode = false,
            autoScale = true,
            combatProtection = true,
            manualScaleOverride = false,
        },
        
        --[[
            Resolution and Display Settings
        ]]
        resolution = {
            autoDetect = true,
            forceAspectRatio = nil, -- nil = auto-detect, or "16:9", "21:9", etc.
            adaptLayoutForUltrawide = true,
            dpiScaling = true,
            maintainCenteredLayout = true,
            safezoneRespect = true,
            gridSnapping = false,
            gridSize = 10,
            collisionDetection = false,
            layoutPreset = "classic", -- "classic", "compact", "wide", "ultrawide"
        },
        
        --[[
            Unit Frame Settings
        ]]
        unitframes = {
            enabled = true,
            
            -- Player frame
            player = {
                enabled = true,
                position = { x = -200, y = -80 },
                scale = 1.0,
                width = 200,
                height = 50,
                showName = true,
                showLevel = false,
                showPvPIcon = true,
                showPortrait = true,
                showResting = true,
                showCombatIndicator = true,
                showGroupIndicator = true,
                health = {
                    enabled = true,
                    showText = true,
                    textFormat = "percent", -- "current", "max", "both", "percent", "deficit"
                    colorByHealth = false,
                    colorByClass = false,
                },
                power = {
                    enabled = true,
                    showText = true,
                    textFormat = "percent",
                    colorByType = true,
                    height = 8,
                },
            },
            
            -- Target frame
            target = {
                enabled = true,
                position = { x = 200, y = -80 },
                scale = 1.0,
                width = 200,
                height = 50,
                showName = true,
                showLevel = true,
                showPvPIcon = true,
                showPortrait = true,
                showClassification = true,
                showTargetOfTarget = true,
                health = {
                    enabled = true,
                    showText = true,
                    textFormat = "percent",
                    colorByHealth = true,
                    colorByClass = false,
                    colorByReaction = true,
                },
                power = {
                    enabled = true,
                    showText = true,
                    textFormat = "percent",
                    colorByType = true,
                    height = 8,
                },
            },
            
            -- Focus frame
            focus = {
                enabled = true,
                position = { x = 0, y = -40 },
                scale = 0.8,
                width = 160,
                height = 40,
                showName = true,
                showLevel = true,
                showPvPIcon = false,
                showPortrait = false,
                health = {
                    enabled = true,
                    showText = true,
                    textFormat = "percent",
                    colorByHealth = true,
                    colorByClass = false,
                    colorByReaction = true,
                },
                power = {
                    enabled = false,
                    showText = false,
                    height = 6,
                },
            },
            
            -- Target's target frame
            targettarget = {
                enabled = true,
                position = { x = 350, y = -40 },
                scale = 0.7,
                width = 120,
                height = 30,
                showName = true,
                showLevel = false,
                showPortrait = false,
                health = {
                    enabled = true,
                    showText = false,
                    colorByReaction = true,
                },
                power = {
                    enabled = false,
                },
            },
            
            -- Party frames
            party = {
                enabled = true,
                position = { x = -400, y = 0 },
                scale = 0.9,
                width = 120,
                height = 40,
                growth = "DOWN",
                spacing = 8,
                showName = true,
                showLevel = false,
                showPortrait = false,
                showPets = false,
                health = {
                    enabled = true,
                    showText = false,
                    colorByClass = true,
                },
                power = {
                    enabled = true,
                    showText = false,
                    height = 6,
                },
            },
            
            -- Raid frames
            raid = {
                enabled = false,
                position = { x = -500, y = 200 },
                scale = 0.8,
                width = 80,
                height = 30,
                growth = "RIGHT",
                spacing = 4,
                groupsPerRow = 8,
                showName = false,
                showLevel = false,
                health = {
                    enabled = true,
                    showText = false,
                    colorByClass = true,
                },
                power = {
                    enabled = false,
                },
            },
        },
        
        --[[
            Action Bar Settings
        ]]
        actionbars = {
            enabled = true,
            hideBlizzardBars = true,
            
            -- Main action bar
            main = {
                enabled = true,
                position = { x = 0, y = 100 }, -- Centered at bottom with 100px offset
                scale = 1.0,
                buttonCount = 12,
                buttonsPerRow = 12,
                buttonSize = 36,
                buttonSpacing = 4,
                showKeybinds = true,
                showMacroNames = true,
                showCooldowns = true,
                showTooltips = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
            
            -- Secondary action bar
            secondary = {
                enabled = false,
                position = { x = 0, y = 140 }, -- Above main bar, centered
                scale = 1.0,
                buttonCount = 12,
                buttonsPerRow = 12,
                buttonSize = 32,
                buttonSpacing = 4,
                showKeybinds = true,
                showMacroNames = false,
                showCooldowns = true,
                showTooltips = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
            
            -- Right action bar
            right = {
                enabled = false,
                position = { x = 300, y = -150 }, -- Right side, symmetrical
                scale = 1.0,
                buttonCount = 12,
                buttonsPerRow = 1,
                buttonSize = 32,
                buttonSpacing = 4,
                showKeybinds = true,
                showMacroNames = false,
                showCooldowns = true,
                showTooltips = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
            
            -- Right action bar 2
            right2 = {
                enabled = false,
                position = { x = 340, y = -150 }, -- Further right, symmetrical
                scale = 1.0,
                buttonCount = 12,
                buttonsPerRow = 1,
                buttonSize = 32,
                buttonSpacing = 4,
                showKeybinds = true,
                showMacroNames = false,
                showCooldowns = true,
                showTooltips = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
            
            -- Pet action bar
            pet = {
                enabled = true,
                position = { x = -200, y = 100 }, -- Left of main bar, symmetrical
                scale = 0.9,
                buttonCount = 10,
                buttonsPerRow = 10,
                buttonSize = 30,
                buttonSpacing = 2,
                showKeybinds = false,
                showCooldowns = true,
                autoHide = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
            
            -- Stance/shapeshift bar
            stance = {
                enabled = true,
                position = { x = -280, y = 100 }, -- Further left of pet bar, symmetrical
                scale = 0.9,
                buttonCount = 6,
                buttonsPerRow = 6,
                buttonSize = 30,
                buttonSpacing = 2,
                showKeybinds = false,
                showCooldowns = false,
                autoHide = true,
                fadeOnCombat = false,
                fadeAlpha = 0.5,
            },
        },
        
        --[[
            Interface Settings
        ]]
        interface = {
            -- Chat settings
            chat = {
                enabled = true,
                position = { x = -400, y = -200 },
                scale = 1.0,
                width = 350,
                height = 120,
                fontSize = 12,
                fadeTime = 10,
                maxLines = 200,
                showTimestamps = false,
                enableURLCopy = true,
                enableStickyChannels = true,
            },
            
            -- Minimap settings
            minimap = {
                enabled = true,
                position = { x = 200, y = 200 },
                scale = 1.0,
                size = 140,
                shape = "square", -- "square", "round"
                showZoneText = true,
                showClock = true,
                showDifficulty = true,
                showTracking = true,
                hideBlizzardElements = true,
                zoomOnMouseWheel = true,
            },
            
            -- Tooltip settings
            tooltip = {
                enabled = true,
                anchor = "CURSOR", -- "CURSOR", "TOPLEFT", "TOPRIGHT", etc.
                scale = 1.0,
                fontSize = 11,
                showHealthBar = true,
                showTarget = true,
                showGuild = true,
                showRealm = true,
                showPvPStatus = true,
                showSpecialization = true,
                showItemLevel = true,
                colorByQuality = true,
                colorByClass = true,
            },
            
            -- Bag settings
            bags = {
                enabled = false, -- Placeholder for future bag implementation
                position = { x = 300, y = -100 },
                scale = 1.0,
                sortOnOpen = false,
                showBagSlots = true,
            },
            
            -- Micro menu settings
            micromenu = {
                enabled = false,
                position = { x = -300, y = 300 },
                scale = 1.0,
                hideInCombat = false,
                fadeAlpha = 0.5,
            },
        },
        
        --[[
            Skinning Settings
        ]]
        skinning = {
            enabled = true,
            blizzardFrames = true,
            thirdPartyFrames = true,
            
            -- Custom colors
            customColors = {
                background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
                border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
                accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 },
                text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
                textHighlight = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
            },
            
            -- Skinning options
            options = {
                enableBackdrops = true,
                enableBorders = true,
                enableGradients = false,
                borderSize = 1,
                backdropAlpha = 0.9,
                useCustomTextures = false,
            },
        },
        
        --[[
            Integration Settings
        ]]
        integration = {
            enabled = true,
            autoConfiguration = true,
            verboseLogging = false,
            
            -- Template settings
            templates = {
                -- WeakAuras templates
                weakauras = {
                    enabled = true,
                    autoInstall = true,
                    installRecommended = true,
                },
                
                -- Details templates
                details = {
                    enabled = true,
                    autoInstall = true,
                    autoConfigureForGroup = true,
                },
                
                -- DBM templates
                dbm = {
                    enabled = true,
                    autoInstall = true,
                    applyColorScheme = true,
                },
            },
            
            -- Auto-configuration settings
            autoConfig = {
                enabled = true,
                configDelay = 2, -- Seconds to wait before auto-configuring
                respectUserSettings = true, -- Don't overwrite user configurations
                showNotifications = true,
            },
            
            -- Export/import settings
            sharing = {
                enabled = true,
                includePersonalData = false,
                compressionLevel = 1,
            },
        },
    },
    
    --[[
        Global Settings (Cross-character)
    ]]
    global = {
        -- Minimap button settings
        minimap = {
            hide = false,
            minimapPos = 220,
            lock = false,
        },
        
        -- First install tracking
        firstInstall = true,
        installDate = nil,
        
        -- Migration tracking
        migrations = {},
        migrationVersion = "1.0.0",
        
        -- Performance settings
        performance = {
            enableGarbageCollection = true,
            memoryOptimization = true,
            profilePerformance = false,
        },
        
        -- Debug settings
        debug = {
            enableLogging = false,
            logLevel = "INFO", -- "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"
            logToFile = false,
            showFPS = false,
            showMemory = false,
        },
    },
    
    --[[
        Character-Specific Settings
    ]]
    char = {
        -- Character initialization
        firstLogin = nil,
        lastLogin = nil,
        currentProfile = "Default",
        
        -- Character-specific UI state
        uiState = {
            chatExpanded = false,
            minimapExpanded = false,
            actionBarsVisible = true,
        },
        
        -- Temporary settings (reset on login)
        temp = {
            combatLockdown = false,
            inInstance = false,
            currentZone = nil,
        },
    },
}

-- Validation rules for configuration values
DamiaUI.ConfigValidation = {
    -- Scale validation
    ["*.scale"] = function(value)
        return type(value) == "number" and value >= 0.5 and value <= 2.0
    end,
    
    -- Position validation
    ["*.position"] = function(value)
        return type(value) == "table" 
            and type(value.x) == "number" 
            and type(value.y) == "number"
            and value.x >= -1000 and value.x <= 1000
            and value.y >= -1000 and value.y <= 1000
    end,
    
    -- Size validation
    ["*.width"] = function(value)
        return type(value) == "number" and value >= 50 and value <= 500
    end,
    
    ["*.height"] = function(value)
        return type(value) == "number" and value >= 20 and value <= 200
    end,
    
    -- Button size validation
    ["*.buttonSize"] = function(value)
        return type(value) == "number" and value >= 20 and value <= 64
    end,
    
    -- Color validation
    ["*.customColors.*"] = function(value)
        return type(value) == "table"
            and type(value.r) == "number" and value.r >= 0 and value.r <= 1
            and type(value.g) == "number" and value.g >= 0 and value.g <= 1
            and type(value.b) == "number" and value.b >= 0 and value.b <= 1
            and (value.a == nil or (type(value.a) == "number" and value.a >= 0 and value.a <= 1))
    end,
    
    -- Font size validation
    ["*.fontSize"] = function(value)
        return type(value) == "number" and value >= 8 and value <= 24
    end,
    
    -- Boolean validation
    ["*.enabled"] = function(value)
        return type(value) == "boolean"
    end,
    
    -- Resolution settings validation
    ["resolution.forceAspectRatio"] = function(value)
        return value == nil or 
               value == "4:3" or value == "5:4" or value == "16:10" or 
               value == "16:9" or value == "21:9" or value == "32:9"
    end,
    
    ["resolution.layoutPreset"] = function(value)
        return value == "classic" or value == "compact" or 
               value == "wide" or value == "ultrawide"
    end,
    
    ["resolution.gridSize"] = function(value)
        return type(value) == "number" and value >= 5 and value <= 50
    end,
}

-- Setting information for configuration UI
DamiaUI.SettingInfo = {
    ["general.scale"] = {
        name = "UI Scale",
        description = "Overall scale of all DamiaUI elements",
        type = "range",
        min = 0.5,
        max = 2.0,
        step = 0.05,
        category = "General",
    },
    
    ["unitframes.player.showName"] = {
        name = "Show Player Name",
        description = "Display player name on the unit frame",
        type = "boolean",
        category = "Unit Frames",
    },
    
    ["actionbars.main.buttonSize"] = {
        name = "Main Bar Button Size",
        description = "Size of buttons on the main action bar",
        type = "range",
        min = 20,
        max = 64,
        step = 2,
        category = "Action Bars",
    },
    
    -- Resolution and display settings
    ["general.autoScale"] = {
        name = "Auto Scale UI",
        description = "Automatically adjust UI scale based on resolution and DPI",
        type = "boolean",
        category = "Display",
    },
    
    ["general.manualScaleOverride"] = {
        name = "Manual Scale Override",
        description = "Override automatic scaling with manual scale setting",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.autoDetect"] = {
        name = "Auto-Detect Resolution",
        description = "Automatically detect and adapt to screen resolution changes",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.forceAspectRatio"] = {
        name = "Force Aspect Ratio",
        description = "Force a specific aspect ratio instead of auto-detection",
        type = "select",
        values = {
            [nil] = "Auto-Detect",
            ["4:3"] = "4:3 (Legacy)",
            ["5:4"] = "5:4 (Legacy)",
            ["16:10"] = "16:10 (Widescreen)",
            ["16:9"] = "16:9 (Standard)",
            ["21:9"] = "21:9 (Ultrawide)",
            ["32:9"] = "32:9 (Super Ultrawide)"
        },
        category = "Display",
    },
    
    ["resolution.adaptLayoutForUltrawide"] = {
        name = "Adapt for Ultrawide",
        description = "Automatically adjust layout for ultrawide displays",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.dpiScaling"] = {
        name = "DPI Scaling",
        description = "Enable DPI-aware scaling for high-resolution displays",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.maintainCenteredLayout"] = {
        name = "Maintain Centered Layout",
        description = "Keep UI elements centered across all resolutions",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.safezoneRespect"] = {
        name = "Respect Safe Zones",
        description = "Keep UI elements within safe viewing areas",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.gridSnapping"] = {
        name = "Grid Snapping",
        description = "Snap UI elements to an invisible grid for alignment",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.gridSize"] = {
        name = "Grid Size",
        description = "Size of the alignment grid in pixels",
        type = "range",
        min = 5,
        max = 50,
        step = 5,
        category = "Display",
    },
    
    ["resolution.collisionDetection"] = {
        name = "Collision Detection",
        description = "Prevent UI elements from overlapping",
        type = "boolean",
        category = "Display",
    },
    
    ["resolution.layoutPreset"] = {
        name = "Layout Preset",
        description = "Base layout configuration for frame positioning",
        type = "select",
        values = {
            ["classic"] = "Classic Layout",
            ["compact"] = "Compact Layout",
            ["wide"] = "Wide Layout",
            ["ultrawide"] = "Ultrawide Layout"
        },
        category = "Display",
    },
    
    -- Additional setting info entries would be defined here
}