--[[
    DamiaUI English (US) Localization
    
    Primary localization file for DamiaUI addon. This serves as the base
    language and fallback for all other localizations.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI or {}

-- Initialize localization system
local L = {}
DamiaUI.L = L

-- Set locale
L.LOCALE = "enUS"

--[[
    Core Addon Strings
]]
L.ADDON_NAME = "Damia UI"
L.ADDON_DESCRIPTION = "Complete interface replacement with centered layout inspired by classic Damia design"
L.VERSION = "Version"
L.AUTHOR = "Author"
L.ENABLED = "Enabled"
L.DISABLED = "Disabled"
L.LOADING = "Loading..."
L.ERROR = "Error"
L.WARNING = "Warning"
L.SUCCESS = "Success"

--[[
    General Interface Strings
]]
L.GENERAL = "General"
L.OPTIONS = "Options"
L.SETTINGS = "Settings"
L.CONFIGURATION = "Configuration"
L.PROFILES = "Profiles"
L.RESET = "Reset"
L.CANCEL = "Cancel"
L.ACCEPT = "Accept"
L.OK = "OK"
L.YES = "Yes"
L.NO = "No"
L.DEFAULT = "Default"
L.CUSTOM = "Custom"
L.NONE = "None"
L.AUTO = "Auto"

--[[
    Configuration Interface
]]
L.CONFIG_GENERAL_HEADER = "General Settings"
L.CONFIG_ENABLE_ADDON = "Enable DamiaUI"
L.CONFIG_ENABLE_ADDON_DESC = "Enable or disable the entire DamiaUI addon"
L.CONFIG_UI_SCALE = "UI Scale"
L.CONFIG_UI_SCALE_DESC = "Adjust the overall scale of DamiaUI elements"
L.CONFIG_DEBUG_MODE = "Debug Mode"
L.CONFIG_DEBUG_MODE_DESC = "Enable debug logging for troubleshooting"
L.CONFIG_RESET_SETTINGS = "Reset All Settings"
L.CONFIG_RESET_SETTINGS_DESC = "Reset all DamiaUI settings to defaults"
L.CONFIG_RESET_CONFIRM = "Are you sure you want to reset all settings? This cannot be undone."

--[[
    Unit Frame Strings
]]
L.UNIT_FRAMES = "Unit Frames"
L.UNIT_FRAMES_DESC = "Configure player, target, and party unit frames"
L.PLAYER_FRAME = "Player Frame"
L.TARGET_FRAME = "Target Frame"
L.FOCUS_FRAME = "Focus Frame"
L.PARTY_FRAMES = "Party Frames"
L.RAID_FRAMES = "Raid Frames"
L.TARGET_TARGET = "Target's Target"

-- Unit frame options
L.UF_SHOW_NAME = "Show Name"
L.UF_SHOW_NAME_DESC = "Display unit name on the frame"
L.UF_SHOW_LEVEL = "Show Level"
L.UF_SHOW_LEVEL_DESC = "Display unit level on the frame"
L.UF_SHOW_PORTRAIT = "Show Portrait"
L.UF_SHOW_PORTRAIT_DESC = "Display unit portrait"
L.UF_SHOW_PVP_ICON = "Show PvP Icon"
L.UF_SHOW_PVP_ICON_DESC = "Display PvP status icon"
L.UF_SHOW_HEALTH_TEXT = "Show Health Text"
L.UF_SHOW_HEALTH_TEXT_DESC = "Display health values as text"
L.UF_SHOW_POWER_TEXT = "Show Power Text"
L.UF_SHOW_POWER_TEXT_DESC = "Display power values as text"
L.UF_COLOR_BY_CLASS = "Color by Class"
L.UF_COLOR_BY_CLASS_DESC = "Color unit frames based on class"
L.UF_COLOR_BY_HEALTH = "Color by Health"
L.UF_COLOR_BY_HEALTH_DESC = "Color health bars based on health percentage"

--[[
    Action Bar Strings
]]
L.ACTION_BARS = "Action Bars"
L.ACTION_BARS_DESC = "Configure action button bars and layout"
L.MAIN_ACTION_BAR = "Main Action Bar"
L.SECONDARY_ACTION_BAR = "Secondary Action Bar"
L.RIGHT_ACTION_BAR = "Right Action Bar"
L.PET_ACTION_BAR = "Pet Action Bar"
L.STANCE_BAR = "Stance Bar"

-- Action bar options
L.AB_BUTTON_SIZE = "Button Size"
L.AB_BUTTON_SIZE_DESC = "Adjust the size of action buttons"
L.AB_BUTTON_SPACING = "Button Spacing"
L.AB_BUTTON_SPACING_DESC = "Adjust spacing between buttons"
L.AB_SHOW_KEYBINDS = "Show Keybinds"
L.AB_SHOW_KEYBINDS_DESC = "Display keybind text on buttons"
L.AB_SHOW_MACRO_NAMES = "Show Macro Names"
L.AB_SHOW_MACRO_NAMES_DESC = "Display macro names on buttons"
L.AB_SHOW_COOLDOWNS = "Show Cooldowns"
L.AB_SHOW_COOLDOWNS_DESC = "Display cooldown spirals and text"
L.AB_HIDE_BLIZZARD_BARS = "Hide Blizzard Bars"
L.AB_HIDE_BLIZZARD_BARS_DESC = "Hide the default Blizzard action bars"

--[[
    Interface Strings
]]
L.INTERFACE = "Interface"
L.INTERFACE_DESC = "Configure chat, minimap, and other interface elements"
L.CHAT = "Chat"
L.MINIMAP = "Minimap"
L.TOOLTIP = "Tooltip"
L.BAGS = "Bags"
L.MICRO_MENU = "Micro Menu"

-- Chat options
L.CHAT_FONT_SIZE = "Font Size"
L.CHAT_FONT_SIZE_DESC = "Adjust chat font size"
L.CHAT_FADE_TIME = "Fade Time"
L.CHAT_FADE_TIME_DESC = "Time in seconds before chat messages fade"
L.CHAT_ENABLE_POSITIONING = "Enable Chat Positioning"
L.CHAT_ENABLE_POSITIONING_DESC = "Allow DamiaUI to manage chat frame positioning"

-- Minimap options
L.MINIMAP_SCALE = "Scale"
L.MINIMAP_SCALE_DESC = "Adjust minimap scale"
L.MINIMAP_ENABLE_POSITIONING = "Enable Minimap Positioning"
L.MINIMAP_ENABLE_POSITIONING_DESC = "Allow DamiaUI to manage minimap positioning"
L.MINIMAP_SHOW_ZONE = "Show Zone Text"
L.MINIMAP_SHOW_ZONE_DESC = "Display current zone name"
L.MINIMAP_SHOW_CLOCK = "Show Clock"
L.MINIMAP_SHOW_CLOCK_DESC = "Display clock on minimap"

--[[
    Skinning Strings
]]
L.SKINNING = "Skinning"
L.SKINNING_DESC = "Configure Aurora-based interface skinning"
L.SKIN_BLIZZARD_FRAMES = "Skin Blizzard Frames"
L.SKIN_BLIZZARD_FRAMES_DESC = "Apply skinning to Blizzard interface elements"
L.SKIN_THIRD_PARTY = "Skin Third-Party Addons"
L.SKIN_THIRD_PARTY_DESC = "Apply skinning to known third-party addon frames"
L.CUSTOM_COLORS = "Custom Colors"
L.BACKGROUND_COLOR = "Background Color"
L.BACKGROUND_COLOR_DESC = "Set custom background color"
L.BORDER_COLOR = "Border Color"
L.BORDER_COLOR_DESC = "Set custom border color"
L.ACCENT_COLOR = "Accent Color"
L.ACCENT_COLOR_DESC = "Set custom accent color"

--[[
    Status and Information Messages
]]
L.ADDON_LOADED = "DamiaUI loaded successfully"
L.ADDON_ENABLED = "DamiaUI enabled"
L.ADDON_DISABLED = "DamiaUI disabled - reload UI to take effect"
L.CONFIG_SAVED = "Configuration saved"
L.PROFILE_CREATED = "Profile created: %s"
L.PROFILE_DELETED = "Profile deleted: %s"
L.PROFILE_COPIED = "Profile copied from '%s' to '%s'"
L.PROFILE_RESET = "Profile reset: %s"
L.SETTINGS_RESET = "All settings reset to defaults"

-- Error messages
L.ERROR_LIBRARY_MISSING = "Required library missing: %s"
L.ERROR_MODULE_FAILED = "Module failed to load: %s"
L.ERROR_CONFIG_INVALID = "Invalid configuration value: %s"
L.ERROR_PROFILE_NOT_FOUND = "Profile not found: %s"
L.ERROR_COMBAT_RESTRICTION = "Cannot perform this action while in combat"

-- Warning messages  
L.WARNING_RELOAD_REQUIRED = "A UI reload is required for this change to take effect"
L.WARNING_EXPERIMENTAL = "This feature is experimental and may cause issues"
L.WARNING_PERFORMANCE = "This setting may impact performance"

--[[
    Command Help Text
]]
L.COMMAND_HELP = "Available DamiaUI commands:"
L.COMMAND_CONFIG = "/damia config - Open configuration"
L.COMMAND_RESET = "/damia reset - Reset all settings"
L.COMMAND_RELOAD = "/damia reload - Reload UI"
L.COMMAND_DEBUG = "/damia debug - Toggle debug mode"
L.COMMAND_VERSION = "/damia version - Show version information"

--[[
    Profile Management
]]
L.PROFILE_DEFAULT = "Default"
L.PROFILE_NEW = "New Profile"
L.PROFILE_COPY = "Copy Profile"
L.PROFILE_DELETE = "Delete Profile"
L.PROFILE_CURRENT = "Current Profile"
L.PROFILE_NAME = "Profile Name"
L.PROFILE_NAME_DESC = "Enter a name for the new profile"
L.PROFILE_COPY_FROM = "Copy From"
L.PROFILE_COPY_FROM_DESC = "Select profile to copy settings from"
L.PROFILE_DELETE_CONFIRM = "Are you sure you want to delete the profile '%s'? This cannot be undone."

--[[
    Color Names
]]
L.COLOR_RED = "Red"
L.COLOR_GREEN = "Green"
L.COLOR_BLUE = "Blue"
L.COLOR_YELLOW = "Yellow"
L.COLOR_ORANGE = "Orange"
L.COLOR_PURPLE = "Purple"
L.COLOR_WHITE = "White"
L.COLOR_BLACK = "Black"
L.COLOR_GRAY = "Gray"

--[[
    Unit Types and Classifications
]]
L.PLAYER = "Player"
L.TARGET = "Target"
L.FOCUS = "Focus"
L.PET = "Pet"
L.PARTY = "Party"
L.RAID = "Raid"
L.BOSS = "Boss"
L.ELITE = "Elite"
L.RARE = "Rare"
L.RARE_ELITE = "Rare Elite"
L.TRIVIAL = "Trivial"

--[[
    Class Names
]]
L.CLASS_WARRIOR = "Warrior"
L.CLASS_PALADIN = "Paladin"
L.CLASS_HUNTER = "Hunter"
L.CLASS_ROGUE = "Rogue"
L.CLASS_PRIEST = "Priest"
L.CLASS_DEATH_KNIGHT = "Death Knight"
L.CLASS_SHAMAN = "Shaman"
L.CLASS_MAGE = "Mage"
L.CLASS_WARLOCK = "Warlock"
L.CLASS_MONK = "Monk"
L.CLASS_DRUID = "Druid"
L.CLASS_DEMON_HUNTER = "Demon Hunter"
L.CLASS_EVOKER = "Evoker"

--[[
    Power Types
]]
L.POWER_MANA = "Mana"
L.POWER_RAGE = "Rage"
L.POWER_FOCUS = "Focus"
L.POWER_ENERGY = "Energy"
L.POWER_COMBO_POINTS = "Combo Points"
L.POWER_RUNES = "Runes"
L.POWER_RUNIC_POWER = "Runic Power"
L.POWER_SOUL_SHARDS = "Soul Shards"
L.POWER_LUNAR_POWER = "Astral Power"
L.POWER_HOLY_POWER = "Holy Power"
L.POWER_ALTERNATE = "Alternate Resource"
L.POWER_MAELSTROM = "Maelstrom"
L.POWER_CHI = "Chi"
L.POWER_INSANITY = "Insanity"
L.POWER_BURNING_EMBERS = "Burning Embers"
L.POWER_DEMONIC_FURY = "Demonic Fury"
L.POWER_ARCANE_CHARGES = "Arcane Charges"
L.POWER_FURY = "Fury"
L.POWER_PAIN = "Pain"

--[[
    Format Strings
]]
L.FORMAT_CURRENT = "%s"
L.FORMAT_MAX = "%s"
L.FORMAT_BOTH = "%s / %s"
L.FORMAT_PERCENT = "%d%%"
L.FORMAT_DEFICIT = "-%s"
L.FORMAT_TIME = "%02d:%02d"
L.FORMAT_LARGE_NUMBER = "%.1f%s"

--[[
    Keybind Text
]]
L.KEY_BUTTON1 = "LMB"
L.KEY_BUTTON2 = "RMB"
L.KEY_BUTTON3 = "MMB"
L.KEY_BUTTON4 = "MB4"
L.KEY_BUTTON5 = "MB5"
L.KEY_SHIFT = "S-"
L.KEY_CTRL = "C-"
L.KEY_ALT = "A-"
L.KEY_META = "M-"

-- Make localization globally available
_G.DamiaUI_L = L