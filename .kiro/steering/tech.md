# Technical Stack & Development Guide

## Tech Stack

### Core Framework
- **Platform**: World of Warcraft 11.2+ (The War Within)
- **Language**: Lua 5.1 (WoW's embedded Lua environment)
- **Architecture**: Modular addon with embedded dependencies

### Embedded Libraries (Namespace Isolated)
- **DamiaUI_oUF**: Unit frame framework for player/target/focus frames
- **DamiaUI_Aurora**: Dark theme skinning library for consistent UI styling
- **DamiaUI_Ace3**: Configuration system and utility libraries
- **DamiaUI_LibActionButton**: Action bar button handling and management
- **DamiaUI_LibDataBroker**: Information panel data source integration

### Development Environment
- **IDE**: Any Lua-capable editor (VS Code with Lua extensions recommended)
- **Testing**: World of Warcraft PTR (Public Test Realm) for API compatibility
- **Version Control**: Git with semantic versioning (MAJOR.MINOR.PATCH)
- **Distribution**: CurseForge, WoWInterface, GitHub releases

## Common Commands

### Development Setup
```bash
# Clone repository
git clone <repository-url>
cd damia-ui

# Create symlink to WoW addons directory (macOS/Linux)
ln -s $(pwd) "~/Applications/World of Warcraft/_retail_/Interface/AddOns/DamiaUI"

# Windows equivalent
mklink /D "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\DamiaUI" "C:\path\to\project"
```

### Testing & Validation
```bash
# Run Lua syntax validation (if luac available)
find . -name "*.lua" -exec luac -p {} \;

# Check TOC file format
grep -E "^##" DamiaUI.toc

# Validate load order dependencies
grep -E "^[^#].*\.lua$" DamiaUI.toc
```

### Build & Release
```bash
# Create release package
zip -r DamiaUI-v1.0.0.zip DamiaUI/ -x "*.git*" "*.DS_Store" "*/.vscode/*"

# Generate changelog
git log --oneline --since="last release" > CHANGELOG.md

# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Performance Requirements

### Memory Management
- **Peak Usage**: <25MB during raids
- **Baseline**: <15MB during normal gameplay
- **Cleanup**: Aggressive garbage collection outside combat
- **Frame Pooling**: Reuse temporary frames to prevent memory leaks

### Frame Rate Impact
- **Target**: <2% FPS reduction in 20-person raids
- **Update Throttling**: 60Hz for UI elements, 10Hz for data panels
- **Event Optimization**: Minimal event registrations, immediate unregistration when unused
- **Combat Optimization**: Reduce non-essential updates during combat

### Load Time Optimization
- **Target**: Interface ready within 3 seconds of login
- **Lazy Loading**: Non-essential modules loaded on demand
- **Library Preloading**: Critical libraries loaded during ADDON_LOADED
- **Delayed Skinning**: Aurora skinning applied after initial load

## Code Standards

### Lua Conventions
```lua
-- File header template
local addonName, DamiaUI = ...

-- Local performance optimizations
local _G = _G
local pairs, ipairs = pairs, ipairs
local CreateFrame = CreateFrame

-- Constants in UPPER_SNAKE_CASE
local FRAME_WIDTH = 200
local UPDATE_INTERVAL = 0.1

-- Functions in PascalCase (public) or camelCase (private)
function DamiaUI:PublicMethod() end
local function privateFunction() end

-- Error handling pattern
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        DamiaUI:LogError("Function failed: " .. tostring(result))
        return nil
    end
    return result
end
```

### Performance Patterns
```lua
-- Event throttling
local lastUpdate = 0
local function ThrottledUpdate()
    local now = GetTime()
    if now - lastUpdate > UPDATE_INTERVAL then
        -- Perform update
        lastUpdate = now
    end
end

-- Combat lockdown handling
local function ExecuteProtectedAction(action, ...)
    if InCombatLockdown() then
        -- Queue for post-combat
        table.insert(pendingActions, {action, ...})
        return false
    end
    return action(...)
end
```

## Architecture Principles

### Module Independence
- Each module operates in isolation with defined APIs
- Communication through central event system only
- No direct cross-module dependencies
- Independent testing and development possible

### Namespace Isolation
- All embedded libraries use DamiaUI_ prefix
- Prevents conflicts with standalone library versions
- Graceful fallback to standalone versions when needed
- Version compatibility checking and warnings

### Error Recovery
- Safe mode activation for critical errors
- Configuration rollback capabilities
- Graceful degradation when features fail
- Comprehensive error logging with context