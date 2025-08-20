# Project Structure & Organization

## Directory Layout

```
DamiaUI/
├── DamiaUI.toc                 # Addon metadata and load order
├── Core/
│   ├── Engine.lua              # Main initialization and library management
│   ├── Config.lua              # Configuration system and SavedVariables
│   ├── Events.lua              # Event handling and dispatcher
│   └── Utils.lua               # Utility functions and helpers
├── Modules/
│   ├── UnitFrames/
│   │   ├── UnitFrames.lua      # oUF layout and frame management
│   │   ├── Player.lua          # Player frame specific logic
│   │   ├── Target.lua          # Target frame specific logic
│   │   ├── Focus.lua           # Focus frame specific logic
│   │   ├── Party.lua           # Party frame management
│   │   └── Raid.lua            # Raid frame management
│   ├── ActionBars/
│   │   ├── ActionBars.lua      # Main action bar controller
│   │   ├── MainBar.lua         # Primary action bar
│   │   ├── SecondaryBars.lua   # Additional action bars
│   │   └── PetBar.lua          # Pet/stance bar
│   ├── Interface/
│   │   ├── Chat.lua            # Chat frame modifications
│   │   ├── Minimap.lua         # Minimap styling and positioning
│   │   ├── Buffs.lua           # Buff/debuff display
│   │   └── InfoPanels.lua      # Information display panels
│   ├── Skinning/
│   │   ├── Skinning.lua        # Aurora integration controller
│   │   ├── Blizzard.lua        # Blizzard frame skinning
│   │   ├── AddOns.lua          # Third-party addon skinning
│   │   └── Custom.lua          # Custom frame skinning
│   └── Configuration/
│       ├── Configuration.lua   # AceConfig interface
│       ├── Profiles.lua        # Profile management
│       └── Migration.lua       # Settings migration
├── Libraries/                  # Embedded dependencies (namespace isolated)
│   ├── LibStub/
│   ├── oUF/                    # Unit frame framework
│   ├── Aurora/                 # Skinning framework
│   ├── Ace3/                   # Configuration and utilities
│   │   ├── AceAddon-3.0/
│   │   ├── AceConfig-3.0/
│   │   ├── AceConfigDialog-3.0/
│   │   ├── AceDB-3.0/
│   │   └── AceGUI-3.0/
│   ├── LibActionButton-1.0/    # Action button handling
│   └── LibDataBroker-1.1/      # Information panel data
├── Media/
│   ├── Textures/
│   │   ├── Statusbar.tga       # Health/power bar texture
│   │   ├── Border.tga          # Frame border texture
│   │   └── Background.tga      # Panel background texture
│   ├── Fonts/
│   │   ├── Expressway.ttf      # Primary UI font
│   │   └── ExpressionPro.ttf   # Secondary font
│   └── Sounds/
│       └── notification.ogg    # UI feedback sounds
├── Locales/
│   ├── enUS.lua                # English (default)
│   ├── deDE.lua                # German
│   ├── frFR.lua                # French
│   ├── esES.lua                # Spanish
│   ├── ruRU.lua                # Russian
│   ├── koKR.lua                # Korean
│   └── zhCN.lua                # Chinese Simplified
└── Config/
    ├── Defaults.lua            # Default configuration values
    └── Constants.lua           # System constants and enums
```

## File Organization Principles

### Load Order (TOC File)
```ini
# Libraries first (dependency order critical)
Libraries\LibStub\LibStub.lua
Libraries\Aurora\Aurora.xml
Libraries\oUF\oUF.xml
Libraries\Ace3\AceAddon-3.0\AceAddon-3.0.xml
# ... other Ace3 components
Libraries\LibActionButton-1.0\LibActionButton-1.0.lua
Libraries\LibDataBroker-1.1\LibDataBroker-1.1.lua

# Core system (initialization order matters)
Config\Constants.lua
Config\Defaults.lua
Core\Utils.lua
Core\Events.lua
Core\Config.lua
Core\Engine.lua

# Modules (can be loaded in any order after core)
Modules\UnitFrames\UnitFrames.lua
Modules\ActionBars\ActionBars.lua
Modules\Interface\Interface.lua
Modules\Skinning\Skinning.lua
Modules\Configuration\Configuration.lua

# Localization last
Locales\enUS.lua
```

### Module Structure Pattern
Each module follows consistent internal organization:

```lua
-- Module header
local addonName, DamiaUI = ...
local ModuleName = DamiaUI:NewModule("ModuleName")

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame

-- Module constants
local MODULE_CONSTANTS = {}

-- Private functions
local function privateFunction() end

-- Public API
function ModuleName:PublicMethod() end

-- Event handlers
function ModuleName:OnEnable() end
function ModuleName:OnDisable() end

-- Module initialization
function ModuleName:Initialize() end
```

## Naming Conventions

### Files and Directories
- **Directories**: PascalCase (e.g., `UnitFrames/`, `ActionBars/`)
- **Lua Files**: PascalCase matching primary class/module (e.g., `Engine.lua`, `UnitFrames.lua`)
- **Media Files**: lowercase with descriptive names (e.g., `statusbar.tga`, `expressway.ttf`)
- **Locale Files**: Standard WoW locale codes (e.g., `enUS.lua`, `deDE.lua`)

### Code Elements
- **Global Variables**: PascalCase with DamiaUI prefix (e.g., `DamiaUI`, `DamiaUIDB`)
- **Module Names**: PascalCase (e.g., `UnitFrames`, `ActionBars`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `FRAME_WIDTH`, `UPDATE_INTERVAL`)
- **Functions**: PascalCase for public, camelCase for private
- **Frame Names**: PascalCase with DamiaUI prefix (e.g., `DamiaUIPlayerFrame`)

## Configuration Architecture

### SavedVariables Structure
```lua
-- Character-specific settings
DamiaUICharDB = {
    currentProfile = "Default",
    firstLogin = timestamp,
    lastLogin = timestamp
}

-- Account-wide settings
DamiaUIDB = {
    version = "1.0.0",
    profiles = {
        ["Default"] = ProfileData,
        ["Custom"] = ProfileData
    },
    global = {
        minimap = { hide = false },
        firstInstall = timestamp
    }
}
```

### Profile Data Organization
```lua
ProfileData = {
    unitframes = {
        player = { enabled = true, position = {x, y}, ... },
        target = { enabled = true, position = {x, y}, ... },
        focus = { enabled = true, position = {x, y}, ... }
    },
    actionbars = {
        mainbar = { enabled = true, buttonSize = 36, ... },
        secondarybar = { enabled = false, ... }
    },
    interface = {
        chat = { enabled = true, width = 350, ... },
        minimap = { enabled = true, scale = 1.0, ... }
    },
    skinning = {
        enabled = true,
        customColors = { background = {r, g, b, a}, ... }
    }
}
```

## Development Workflow

### Feature Development
1. Create feature branch from main
2. Implement in appropriate module directory
3. Add configuration options if needed
4. Update TOC file if new files added
5. Test with PTR client
6. Create pull request with documentation

### Module Dependencies
- **Core modules** depend only on embedded libraries
- **Feature modules** depend on Core and embedded libraries only
- **No cross-module dependencies** - use event system for communication
- **Configuration module** can access all other modules for settings

### Testing Structure
```
Tests/
├── Unit/
│   ├── CoreTests.lua
│   ├── UnitFrameTests.lua
│   └── ActionBarTests.lua
├── Integration/
│   ├── ModuleIntegrationTests.lua
│   └── ConfigurationTests.lua
└── Performance/
    ├── MemoryTests.lua
    └── FPSTests.lua
```

## Asset Management

### Media Guidelines
- **Textures**: 32x32 minimum, power-of-2 dimensions preferred
- **Fonts**: TTF format, include license information
- **Sounds**: OGG format, <100KB file size
- **File Naming**: Descriptive, lowercase with hyphens

### Localization Strategy
- **Default Language**: enUS (always present)
- **Fallback**: Missing translations fall back to enUS
- **String Keys**: Descriptive with module prefix (e.g., `UNITFRAMES_PLAYER_ENABLE`)
- **Pluralization**: Handle singular/plural forms appropriately

This structure ensures maintainable, scalable development while following WoW addon best practices and supporting the modular architecture required for Damia UI's comprehensive feature set.