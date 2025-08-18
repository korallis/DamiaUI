--[[
    DamiaUI Constants
    
    Global constants and configuration values used throughout the DamiaUI addon.
    These values define core behavior, limits, and default settings.
    
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

-- Initialize constants table
DamiaUI.Constants = {}
local Constants = DamiaUI.Constants

--[[
    Core Addon Information
]]
Constants.ADDON_NAME = "DamiaUI"
Constants.VERSION = "1.0.0"
Constants.BUILD_DATE = "@project-date-iso@"
Constants.AUTHOR = "DamiaUI Development Team"

-- Supported WoW versions
Constants.SUPPORTED_VERSIONS = {
    ["11.2"] = 110200, -- The War Within (Current)
    ["11.0.5"] = 110005,
    ["11.0.0"] = 110000, -- The War Within Launch
}

--[[
    Performance Constants
]]
Constants.PERFORMANCE = {
    -- Memory usage limits (in MB)
    MEMORY_WARNING_THRESHOLD = 20,
    MEMORY_CRITICAL_THRESHOLD = 25,
    MEMORY_TARGET = 15,
    
    -- FPS impact limits
    FPS_IMPACT_TARGET = 2, -- Target: <2% FPS impact
    
    -- Update frequencies (in Hz)
    HEALTH_UPDATE_RATE = 60,
    POWER_UPDATE_RATE = 60,
    SECONDARY_UPDATE_RATE = 10,
    
    -- Throttling intervals (in seconds)
    GARBAGE_COLLECTION_INTERVAL = 120,
    PERFORMANCE_CHECK_INTERVAL = 30,
    CONFIG_SAVE_THROTTLE = 2,
}

--[[
    UI Layout Constants
]]
Constants.LAYOUT = {
    -- Screen positioning
    CENTER_ANCHOR = "CENTER",
    SCREEN_REFERENCE = "UIParent",
    
    -- Default frame positions (relative to center)
    FRAME_POSITIONS = {
        PLAYER = { x = -200, y = -80 },
        TARGET = { x = 200, y = -80 },
        FOCUS = { x = 0, y = -40 },
        TARGET_TARGET = { x = 350, y = -40 },
        PARTY_BASE = { x = -400, y = 0 },
        RAID_BASE = { x = -500, y = 200 },
    },
    
    -- Action bar positions
    ACTION_BAR_POSITIONS = {
        MAIN = { x = 0, y = -250 },
        SECONDARY = { x = 0, y = -210 },
        RIGHT = { x = 40, y = -250 },
        RIGHT2 = { x = 80, y = -250 },
        PET = { x = -200, y = -250 },
        STANCE = { x = -240, y = -250 },
    },
    
    -- Interface element positions
    INTERFACE_POSITIONS = {
        CHAT = { x = -400, y = -200 },
        MINIMAP = { x = 200, y = 200 },
        TOOLTIP = { x = 0, y = 0 },
    },
}

--[[
    Color Constants
]]
Constants.COLORS = {
    -- Default theme colors
    BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    ACCENT = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 },
    
    -- Status colors
    HEALTH = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
    MANA = { r = 0.0, g = 0.4, b = 0.8, a = 1.0 },
    RAGE = { r = 0.8, g = 0.0, b = 0.0, a = 1.0 },
    ENERGY = { r = 1.0, g = 1.0, b = 0.0, a = 1.0 },
    
    -- Quality colors (item rarity)
    QUALITY = {
        [0] = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 }, -- Poor (Gray)
        [1] = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, -- Common (White)
        [2] = { r = 0.1, g = 1.0, b = 0.1, a = 1.0 }, -- Uncommon (Green)
        [3] = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 }, -- Rare (Blue)
        [4] = { r = 0.6, g = 0.2, b = 1.0, a = 1.0 }, -- Epic (Purple)
        [5] = { r = 1.0, g = 0.5, b = 0.0, a = 1.0 }, -- Legendary (Orange)
    },
}

--[[
    Font Constants
]]
Constants.FONTS = {
    -- Default WoW fonts
    UI_FONT = "Fonts\\FRIZQT__.TTF",
    DAMAGE_FONT = "Fonts\\skurri.TTF",
    CHAT_FONT = "Fonts\\ARIALN.TTF",
    
    -- Font sizes
    SIZE = {
        TINY = 8,
        SMALL = 10,
        NORMAL = 12,
        MEDIUM = 14,
        LARGE = 16,
        HUGE = 20,
    },
    
    -- Font flags
    FLAGS = {
        NORMAL = "",
        OUTLINE = "OUTLINE",
        THICK_OUTLINE = "THICKOUTLINE",
        MONOCHROME = "MONOCHROME",
    },
}

--[[
    Animation Constants
]]
Constants.ANIMATION = {
    -- Duration constants (in seconds)
    INSTANT = 0,
    FAST = 0.15,
    NORMAL = 0.3,
    SLOW = 0.5,
    VERY_SLOW = 1.0,
    
    -- Easing types
    EASING = {
        LINEAR = "LINEAR",
        SMOOTH = "SMOOTH",
        BOUNCE = "BOUNCE",
        ELASTIC = "ELASTIC",
    },
    
    -- Common alpha values
    ALPHA = {
        HIDDEN = 0,
        FADED = 0.3,
        SEMI_TRANSPARENT = 0.6,
        MOSTLY_VISIBLE = 0.8,
        VISIBLE = 1.0,
    },
}

--[[
    Event Constants
]]
Constants.EVENTS = {
    -- Custom DamiaUI events
    DAMIA_INITIALIZED = "DAMIA_INITIALIZED",
    DAMIA_UI_READY = "DAMIA_UI_READY",
    DAMIA_CONFIG_CHANGED = "DAMIA_CONFIG_CHANGED",
    DAMIA_PROFILE_CHANGED = "DAMIA_PROFILE_CHANGED",
    DAMIA_COMBAT_STATE_CHANGED = "DAMIA_COMBAT_STATE_CHANGED",
    DAMIA_SCALE_CHANGED = "DAMIA_SCALE_CHANGED",
    
    -- Priority levels
    PRIORITY = {
        CRITICAL = 1,
        HIGH = 2,
        NORMAL = 5,
        LOW = 8,
        LOWEST = 10,
    },
}

--[[
    Size and Scale Constants
]]
Constants.SIZES = {
    -- Unit frame sizes
    UNIT_FRAMES = {
        PLAYER = { width = 200, height = 50 },
        TARGET = { width = 200, height = 50 },
        FOCUS = { width = 160, height = 40 },
        TARGET_TARGET = { width = 120, height = 30 },
        PARTY = { width = 120, height = 40 },
        RAID = { width = 80, height = 30 },
    },
    
    -- Action button sizes
    ACTION_BUTTONS = {
        TINY = 20,
        SMALL = 28,
        NORMAL = 36,
        LARGE = 44,
        HUGE = 52,
    },
    
    -- Border and spacing
    BORDER_SIZE = 1,
    BUTTON_SPACING = 4,
    FRAME_PADDING = 2,
}

--[[
    Limits and Validation Constants
]]
Constants.LIMITS = {
    -- Scale limits
    MIN_SCALE = 0.5,
    MAX_SCALE = 2.0,
    SCALE_STEP = 0.05,
    
    -- Size limits
    MIN_BUTTON_SIZE = 20,
    MAX_BUTTON_SIZE = 64,
    MIN_FRAME_SIZE = 50,
    MAX_FRAME_SIZE = 500,
    
    -- Position limits (screen percentage)
    MIN_POSITION = -0.4,
    MAX_POSITION = 0.4,
    
    -- String limits
    MAX_STRING_LENGTH = 255,
    MAX_NAME_LENGTH = 50,
    
    -- Performance limits
    MAX_EVENT_HANDLERS = 100,
    MAX_MODULES = 20,
    MAX_CALLBACKS = 50,
}

--[[
    Texture Paths
]]
Constants.TEXTURES = {
    -- Status bar textures
    STATUSBAR = "Interface\\TargetingFrame\\UI-StatusBar",
    STATUSBAR_FILL = "Interface\\TargetingFrame\\UI-StatusBar",
    
    -- Border textures
    BORDER = "Interface\\Buttons\\WHITE8X8",
    TOOLTIP_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border",
    
    -- Background textures
    BACKGROUND = "Interface\\ChatFrame\\ChatFrameBackground",
    DIALOG_BACKGROUND = "Interface\\DialogFrame\\UI-DialogBox-Background",
    
    -- Button textures
    BUTTON_NORMAL = "Interface\\Buttons\\UI-Panel-Button-Up",
    BUTTON_HIGHLIGHT = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    BUTTON_PUSHED = "Interface\\Buttons\\UI-Panel-Button-Down",
}

--[[
    Sound Paths
]]
Constants.SOUNDS = {
    -- UI sounds
    BUTTON_CLICK = "Interface\\Sounds\\UI\\igMainMenuOptionCheckBoxOn.ogg",
    BUTTON_HOVER = "Interface\\Sounds\\UI\\igMainMenuOptionCheckBoxOff.ogg",
    
    -- Alert sounds
    WARNING = "Interface\\Sounds\\UI\\igPlayerInviteDecline.ogg",
    ERROR = "Interface\\Sounds\\UI\\igPlayerInviteDecline.ogg",
    SUCCESS = "Interface\\Sounds\\UI\\igPlayerInviteAccept.ogg",
    
    -- Custom DamiaUI sounds (placeholders)
    DAMIA_NOTIFICATION = "Interface\\AddOns\\DamiaUI\\Media\\Sounds\\Notification.ogg",
    DAMIA_ALERT = "Interface\\AddOns\\DamiaUI\\Media\\Sounds\\Alert.ogg",
}

--[[
    Debug Constants
]]
Constants.DEBUG = {
    -- Debug levels
    LEVEL = {
        OFF = 0,
        ERROR = 1,
        WARNING = 2,
        INFO = 3,
        DEBUG = 4,
        TRACE = 5,
    },
    
    -- Debug categories
    CATEGORY = {
        CORE = "CORE",
        CONFIG = "CONFIG",
        EVENTS = "EVENTS",
        UNITFRAMES = "UNITFRAMES",
        ACTIONBARS = "ACTIONBARS",
        INTERFACE = "INTERFACE",
        SKINNING = "SKINNING",
        PERFORMANCE = "PERFORMANCE",
    },
}