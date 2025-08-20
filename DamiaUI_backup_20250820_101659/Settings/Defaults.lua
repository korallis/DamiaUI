local addonName, DamiaUI = ...

-- Default position structure for frames
local DefaultPosition = {
    point = "CENTER",
    relativePoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    hasMoved = false,
}

-- Default settings structure
DamiaUI.Defaults = {
    profile = {
        -- Version control for migrations
        dbVersion = "1.0.0",
        
        -- General settings
        general = {
            enabled = true,
            minimapHidden = false,
            chatHidden = false,
            scale = 1.0,
            pixelPerfect = true,
        },
        
        -- ActionBars settings
        actionbars = {
            enabled = true,
            buttonSize = 36,
            spacing = 2,
            showEmptyButtons = true,
            showHotkeys = true,
            showMacroNames = false,
            fadeOutOfCombat = false,
            fadeOutOfRange = true,
            
            -- Individual bar settings
            mainActionBar = {
                enabled = true,
                position = {
                    point = "BOTTOM",
                    relativePoint = "BOTTOM",
                    xOffset = 0,
                    yOffset = 20,
                    hasMoved = false,
                },
                scale = 1.0,
                buttonSize = 36,
                spacing = 2,
                buttonsPerRow = 12,
                showBackground = true,
            },
            
            multiActionBarBottomLeft = {
                enabled = true,
                position = {
                    point = "BOTTOMLEFT",
                    relativePoint = "BOTTOM",
                    xOffset = -200,
                    yOffset = 60,
                    hasMoved = false,
                },
                scale = 1.0,
                buttonSize = 32,
                spacing = 2,
                buttonsPerRow = 12,
                showBackground = false,
            },
            
            multiActionBarBottomRight = {
                enabled = true,
                position = {
                    point = "BOTTOMRIGHT",
                    relativePoint = "BOTTOM",
                    xOffset = 200,
                    yOffset = 60,
                    hasMoved = false,
                },
                scale = 1.0,
                buttonSize = 32,
                spacing = 2,
                buttonsPerRow = 12,
                showBackground = false,
            },
            
            multiActionBarRight = {
                enabled = false,
                position = {
                    point = "RIGHT",
                    relativePoint = "RIGHT",
                    xOffset = -50,
                    yOffset = 0,
                    hasMoved = false,
                },
                scale = 1.0,
                buttonSize = 32,
                spacing = 2,
                buttonsPerRow = 1,
                showBackground = false,
            },
            
            multiActionBarLeft = {
                enabled = false,
                position = {
                    point = "LEFT",
                    relativePoint = "LEFT",
                    xOffset = 50,
                    yOffset = 0,
                    hasMoved = false,
                },
                scale = 1.0,
                buttonSize = 32,
                spacing = 2,
                buttonsPerRow = 1,
                showBackground = false,
            },
        },
        
        -- UnitFrames settings
        unitframes = {
            enabled = true,
            classColors = true,
            showHealthValues = "PERCENT",
            showAbsorbBars = true,
            smoothHealthUpdates = true,
            
            -- Player frame
            player = {
                enabled = true,
                position = {
                    point = "BOTTOM",
                    relativePoint = "CENTER",
                    xOffset = -100,
                    yOffset = -150,
                    hasMoved = false,
                },
                scale = 1.0,
                width = 200,
                height = 50,
                showPortrait = true,
                showHealthText = true,
                showPowerText = true,
                showAbsorbBar = true,
                showCastBar = true,
                castBarDetached = false,
                castBarPosition = {
                    point = "BOTTOM",
                    relativePoint = "TOP",
                    xOffset = 0,
                    yOffset = 5,
                    hasMoved = false,
                },
            },
            
            -- Target frame  
            target = {
                enabled = true,
                position = {
                    point = "BOTTOM",
                    relativePoint = "CENTER",
                    xOffset = 100,
                    yOffset = -150,
                    hasMoved = false,
                },
                scale = 1.0,
                width = 200,
                height = 50,
                showPortrait = true,
                showHealthText = true,
                showPowerText = true,
                showAbsorbBar = true,
                showCastBar = true,
                castBarDetached = false,
                castBarPosition = {
                    point = "BOTTOM",
                    relativePoint = "TOP",
                    xOffset = 0,
                    yOffset = 5,
                    hasMoved = false,
                },
                showBuffs = true,
                showDebuffs = true,
                maxBuffs = 8,
                maxDebuffs = 8,
                auraSize = 24,
            },
            
            -- Target of Target frame
            targettarget = {
                enabled = true,
                position = {
                    point = "BOTTOMLEFT",
                    relativePoint = "TOPRIGHT",
                    xOffset = 10,
                    yOffset = 0,
                    hasMoved = false,
                },
                scale = 0.8,
                width = 120,
                height = 30,
                showPortrait = false,
                showHealthText = false,
                showPowerText = false,
            },
            
            -- Focus frame
            focus = {
                enabled = true,
                position = {
                    point = "LEFT",
                    relativePoint = "CENTER",
                    xOffset = -300,
                    yOffset = 100,
                    hasMoved = false,
                },
                scale = 0.9,
                width = 180,
                height = 40,
                showPortrait = true,
                showHealthText = true,
                showPowerText = false,
                showCastBar = true,
                showBuffs = false,
                showDebuffs = true,
                maxDebuffs = 6,
                auraSize = 20,
            },
            
            -- Pet frame
            pet = {
                enabled = true,
                position = {
                    point = "BOTTOMRIGHT",
                    relativePoint = "TOPLEFT",
                    xOffset = -10,
                    yOffset = 0,
                    hasMoved = false,
                },
                scale = 0.7,
                width = 100,
                height = 25,
                showPortrait = false,
                showHealthText = false,
                showPowerText = false,
            },
        },
        
        -- Minimap settings
        minimap = {
            enabled = true,
            position = {
                point = "TOPRIGHT",
                relativePoint = "TOPRIGHT", 
                xOffset = -20,
                yOffset = -20,
                hasMoved = false,
            },
            scale = 1.0,
            size = 140,
            showBorder = true,
            showZoomButtons = false,
            showWorldMapButton = true,
            trackingMenu = true,
            fadeInCombat = false,
        },
        
        -- Chat settings
        chat = {
            enabled = true,
            fadeOutOfUse = true,
            fadeTimeout = 10,
            showTimestamps = true,
            timestampFormat = "[%H:%M:%S] ",
            classColorPlayerNames = true,
            shortenChannelNames = true,
            enableURL = true,
            enableEmojis = false,
            maxCopyLines = 100,
        },
        
        -- Tooltip settings
        tooltips = {
            enabled = true,
            anchorToCursor = false,
            showHealthBar = true,
            showItemLevel = true,
            showItemSource = false,
            showPlayerTitles = true,
            showGuildRanks = true,
            showTargetInfo = true,
            showSpellID = false,
            hideInCombat = false,
        },
        
        -- Fonts settings
        fonts = {
            enabled = true,
            normalFont = "Fonts\\FRIZQT__.TTF",
            headerFont = "Fonts\\MORPHEUS.TTF", 
            normalSize = 12,
            headerSize = 16,
            smallSize = 10,
            outline = "",
        },
        
        -- Aura settings
        auras = {
            enabled = true,
            
            playerBuffs = {
                enabled = true,
                position = {
                    point = "TOPRIGHT",
                    relativePoint = "TOPRIGHT",
                    xOffset = -20,
                    yOffset = -200,
                    hasMoved = false,
                },
                size = 32,
                spacing = 2,
                growDirection = "LEFT",
                wrapAfter = 8,
                maxRows = 3,
                showDuration = true,
                showCount = true,
            },
            
            playerDebuffs = {
                enabled = true,
                position = {
                    point = "TOPRIGHT", 
                    relativePoint = "TOPRIGHT",
                    xOffset = -20,
                    yOffset = -300,
                    hasMoved = false,
                },
                size = 40,
                spacing = 2,
                growDirection = "LEFT",
                wrapAfter = 8,
                maxRows = 2,
                showDuration = true,
                showCount = true,
            },
        },
        
        -- Module toggles for easy enable/disable
        modules = {
            actionbars = true,
            unitframes = true,
            minimap = true,
            chat = true,
            tooltips = true,
            auras = true,
            fonts = true,
        },
        
        -- Profile metadata
        profileCreatedCharacter = UnitName("player") or "Unknown",
        profileCreatedDate = date("%m/%d/%y %H:%M:%S"),
    },
    
    -- Character-specific settings (SavedVariablesPerCharacter)
    char = {
        -- Character-specific position overrides
        framePositions = {},
        
        -- Character-specific module states
        moduleStates = {},
        
        -- Character-specific keybindings
        keybindings = {},
    },
}

-- Global default settings (shared across all characters)
DamiaUI.GlobalDefaults = {
    -- Global settings that affect all characters
    global = {
        -- First time setup
        firstTimeSetup = true,
        
        -- Update notifications
        showUpdateNotifications = true,
        
        -- Debug settings
        debugMode = false,
        verboseLogging = false,
        
        -- Performance settings
        throttleUpdates = true,
        updateInterval = 0.1,
        
        -- Compatibility settings
        disableConflictingAddons = true,
        showCompatibilityWarnings = true,
    },
    
    -- Profiles system
    profiles = {},
    
    -- Current profile name
    currentProfile = "Default",
}

-- Function to get a deep copy of defaults
function DamiaUI:GetDefaults()
    return DamiaUI:DeepCopy(self.Defaults)
end

function DamiaUI:GetGlobalDefaults()
    return DamiaUI:DeepCopy(self.GlobalDefaults) 
end

-- Deep copy utility function
function DamiaUI:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DamiaUI:DeepCopy(orig_key)] = DamiaUI:DeepCopy(orig_value)
        end
        setmetatable(copy, DamiaUI:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end