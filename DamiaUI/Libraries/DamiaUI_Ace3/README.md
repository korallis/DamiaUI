# DamiaUI Ace3 Libraries

## Overview

This directory contains the complete Ace3 library collection embedded within DamiaUI using namespace isolation. All libraries have been adapted for **WoW 11.2 compatibility** and use the `DamiaUI_` prefix to prevent conflicts with other Ace3 implementations.

## Implemented Libraries

### Core Libraries

#### AceAddon-3.0 (`DamiaUI_AceAddon-3.0`)
- **Location**: `AceAddon-3.0/AceAddon-3.0.lua`
- **Purpose**: Foundation for modular addon architecture
- **Features**:
  - Addon registration and lifecycle management
  - Module system with inheritance
  - Mixin support for library embedding
  - Event-driven initialization and enabling

#### AceEvent-3.0 (`DamiaUI_AceEvent-3.0`)
- **Location**: `AceEvent-3.0/AceEvent-3.0.lua`
- **Purpose**: Secure event registration and dispatching
- **Features**:
  - Blizzard event registration/unregistration
  - Custom message system
  - Automatic cleanup on object release
  - Callback-based event handling

### Database Libraries

#### AceDB-3.0 (`DamiaUI_AceDB-3.0`)
- **Location**: `AceDB-3.0/AceDB-3.0.lua`
- **Purpose**: Comprehensive database and profile management
- **Features**:
  - Multi-scope data storage (global, character, class, race, faction, realm)
  - Profile system with copying, deletion, and reset
  - Default value handling with inheritance
  - Automatic cleanup on logout

#### AceDBOptions-3.0 (`DamiaUI_AceDBOptions-3.0`)
- **Location**: `AceDBOptions-3.0/AceDBOptions-3.0.lua`
- **Purpose**: Configuration interface for AceDB profiles
- **Features**:
  - Profile selection dropdown
  - New profile creation
  - Profile copying and deletion
  - Profile reset functionality

### Interface Libraries

#### AceConsole-3.0 (`DamiaUI_AceConsole-3.0`)
- **Location**: `AceConsole-3.0/AceConsole-3.0.lua`
- **Purpose**: Slash command registration and handling
- **Features**:
  - Slash command registration
  - Argument parsing utilities
  - Sub-command support
  - Enhanced command handlers

#### AceGUI-3.0 (`DamiaUI_AceGUI-3.0`)
- **Location**: `AceGUI-3.0/AceGUI-3.0.lua` + `widgets.lua`
- **Purpose**: Comprehensive GUI framework
- **Features**:
  - Widget system with recycling
  - Layout management (Flow, Fill, List)
  - Container and control widgets
  - Event system for user interaction

### Configuration Libraries

#### AceConfig-3.0 (`DamiaUI_AceConfig-3.0`)
- **Location**: `AceConfig-3.0/AceConfig-3.0.lua`
- **Purpose**: Centralized configuration management
- **Features**:
  - Option table registration and validation
  - Configuration change callbacks
  - Integration with AceConfigDialog

#### AceConfigDialog-3.0 (`DamiaUI_AceConfigDialog-3.0`)
- **Location**: `AceConfig-3.0/AceConfigDialog-3.0.lua`
- **Purpose**: Graphical configuration interface
- **Features**:
  - Automatic GUI generation from option tables
  - Blizzard Interface Options integration
  - Widget-based configuration forms
  - Real-time option updates

## Widget Collection

### AceGUI Widgets

The following widgets are implemented in `AceGUI-3.0/widgets.lua`:

#### Container Widgets
- **Frame**: Main window with title bar, status bar, and resize handles
- **InlineGroup**: Bordered group with optional title
- **ScrollFrame**: Scrollable content container

#### Control Widgets
- **CheckBox**: Boolean toggle with label
- **EditBox**: Text input field with label
- **Button**: Clickable button
- **Label**: Static text display
- **Heading**: Formatted heading text

#### Layout Managers
- **Flow**: Automatic wrapping layout
- **Fill**: Full container layout
- **List**: Vertical stacking layout

## Usage Examples

### Basic Addon Setup
```lua
local MyAddon = LibStub("DamiaUI_AceAddon-3.0"):NewAddon("MyAddon", "DamiaUI_AceEvent-3.0", "DamiaUI_AceConsole-3.0")
local AceDB = LibStub("DamiaUI_AceDB-3.0")

function MyAddon:OnInitialize()
    -- Initialize database
    self.db = AceDB:New("MyAddonDB", defaults)
    
    -- Register slash commands
    self:RegisterChatCommand("myaddon", "SlashCommand")
end

function MyAddon:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end
```

### Configuration Setup
```lua
local AceConfig = LibStub("DamiaUI_AceConfig-3.0")
local AceConfigDialog = LibStub("DamiaUI_AceConfigDialog-3.0")

local options = {
    type = "group",
    name = "My Addon",
    args = {
        enable = {
            type = "toggle",
            name = "Enable",
            get = function() return MyAddon.db.profile.enable end,
            set = function(info, value) MyAddon.db.profile.enable = value end,
        }
    }
}

AceConfig:RegisterOptionsTable("MyAddon", options)
AceConfigDialog:AddToBlizOptions("MyAddon")
```

### GUI Creation
```lua
local AceGUI = LibStub("DamiaUI_AceGUI-3.0")

local frame = AceGUI:Create("Frame")
frame:SetTitle("My Window")
frame:SetLayout("Flow")

local button = AceGUI:Create("Button")
button:SetText("Click Me")
button:SetCallback("OnClick", function()
    print("Button clicked!")
end)

frame:AddChild(button)
frame:Show()
```

## Loading Order

The libraries must be loaded in the correct dependency order:

1. **AceAddon-3.0** - Core framework
2. **AceEvent-3.0** - Event system
3. **AceDB-3.0** - Database system
4. **AceConsole-3.0** - Command system
5. **AceGUI-3.0** - GUI framework
6. **AceConfig-3.0** - Configuration system
7. **AceDBOptions-3.0** - Database options

This order is enforced in `DamiaUI_Ace3.xml`.

## Integration

To use these libraries in DamiaUI, include the master XML file:

```xml
<Include file="Libraries\DamiaUI_Ace3\DamiaUI_Ace3.xml"/>
```

All libraries will be available through LibStub using their namespaced names (e.g., `DamiaUI_AceAddon-3.0`).

## Compatibility

- **WoW Version**: 11.2+ (The War Within)
- **Namespace**: All libraries use `DamiaUI_` prefix
- **Dependencies**: LibStub, CallbackHandler-1.0
- **Conflicts**: None - isolated from other Ace3 implementations

## File Structure

```
DamiaUI_Ace3/
├── DamiaUI_Ace3.xml          # Master include file
├── README.md                  # This file
├── AceAddon-3.0/
│   ├── AceAddon-3.0.lua
│   └── AceAddon-3.0.xml
├── AceEvent-3.0/
│   ├── AceEvent-3.0.lua
│   └── AceEvent-3.0.xml
├── AceDB-3.0/
│   ├── AceDB-3.0.lua
│   └── AceDB-3.0.xml
├── AceDBOptions-3.0/
│   ├── AceDBOptions-3.0.lua
│   └── AceDBOptions-3.0.xml
├── AceConsole-3.0/
│   ├── AceConsole-3.0.lua
│   └── AceConsole-3.0.xml
├── AceConfig-3.0/
│   ├── AceConfig-3.0.lua
│   ├── AceConfigDialog-3.0.lua
│   └── AceConfig-3.0.xml
└── AceGUI-3.0/
    ├── AceGUI-3.0.lua
    ├── widgets.lua
    └── AceGUI-3.0.xml
```

## Testing

All libraries have been implemented with WoW 11.2 compatibility in mind and include:

- Proper error handling and validation
- Safe calling mechanisms to prevent addon breakage
- Memory management and cleanup
- Modern WoW API usage

## License

These implementations are based on the original Ace3 libraries and maintain the same BSD license. They are embedded within DamiaUI under the project's license terms.