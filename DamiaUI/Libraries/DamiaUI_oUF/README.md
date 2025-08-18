# DamiaUI oUF Framework

A lightweight, self-contained unit frame framework embedded within DamiaUI to avoid conflicts with standalone oUF installations. Compatible with World of Warcraft 11.2+.

## Overview

This oUF implementation provides all core functionality needed for player, target, focus, party, and raid frames. It features proper namespace isolation using `DamiaUI_oUF` and integrates seamlessly with the DamiaUI addon ecosystem.

## Architecture

### Core Components

- **oUF.lua** - Main framework with style system, element management, and event handling
- **tags.lua** - Flexible text formatting system for dynamic content display
- **elements/** - Individual frame elements (health, power, castbar, auras, portraits, names)

### Key Features

- LibStub integration with "oUF" namespace registration
- Element-based architecture for modular frame construction
- Event-driven updates with throttling for performance
- Comprehensive color system for classes, power types, and reactions
- Tag system for flexible text formatting
- Full WoW 11.2 API compatibility

## API Reference

### Basic Usage

```lua
-- Get oUF reference (automatically loaded by DamiaUI)
local oUF = DamiaUI.Libraries.oUF

-- Register a custom style
oUF:RegisterStyle("MyStyle", function(self, unit)
    -- Frame setup code
    self:SetSize(200, 50)
    
    -- Create health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    self.Health = health
    
    -- oUF will automatically handle the rest
end)

-- Set active style and spawn frames
oUF:SetActiveStyle("MyStyle")
local playerFrame = oUF:Spawn("player", "MyPlayerFrame")
```

### Elements

#### Health Element
```lua
-- Basic setup
local health = CreateFrame("StatusBar", nil, frame)
health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
frame.Health = health

-- Optional configurations
frame.HealthValueFormat = "current" -- "current", "max", "percent", "deficit", "both"
```

#### Power Element
```lua
local power = CreateFrame("StatusBar", nil, frame)
power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
frame.Power = power

-- Optional configurations  
frame.PowerValueFormat = "current" -- Same options as health
```

#### Castbar Element
```lua
local castbar = CreateFrame("StatusBar", nil, frame)
castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

-- Optional text elements
castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")

frame.Castbar = castbar
```

#### Auras Element
```lua
local buffs = CreateFrame("Frame", nil, frame)
buffs.size = 20              -- Icon size
buffs.spacing = 2            -- Space between icons
buffs.buttonsPerRow = 8      -- Icons per row
buffs.maxAuras = 32          -- Maximum auras to show
buffs.filter = "HELPFUL"     -- "HELPFUL" for buffs, "HARMFUL" for debuffs
buffs.growth = "RIGHT"       -- Growth direction: "RIGHT", "LEFT", "UP", "DOWN"

-- Optional custom filtering
buffs.CustomFilter = function(element, unit, aura)
    return aura.isFromPlayerOrPlayerPet -- Only show player auras
end

frame.Buffs = buffs

-- Separate debuffs frame
local debuffs = CreateFrame("Frame", nil, frame) 
debuffs.filter = "HARMFUL"
frame.Debuffs = debuffs
```

#### Portrait Element
```lua
-- 2D Portrait (texture)
local portrait = frame:CreateTexture(nil, "ARTWORK")
portrait:SetSize(40, 40)
frame.Portrait = portrait

-- 3D Portrait (model)
local portrait = CreateFrame("PlayerModel", nil, frame)
portrait:SetSize(40, 40)
frame.Portrait = portrait
```

#### Name Element
```lua
local name = frame:CreateFontString(nil, "OVERLAY")
name:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
name.showLevel = true           -- Include level in name text
name.showClassification = true  -- Include elite/rare indicators
name.colorClass = true          -- Color by class/reaction
name.colorLevel = true          -- Color level by difficulty
frame.Name = name

-- Separate level element
local level = frame:CreateFontString(nil, "OVERLAY")
level:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
level.colorLevel = true
frame.Level = level
```

### Tags System

The tags system provides flexible text formatting for dynamic content:

```lua
-- Create a tag string
local text = oUF:CreateTagString(frame, "[name] - [hp:short]/[hp:max-short]")

-- Available tags:
-- [name] [name:short]                    -- Unit name
-- [level] [level:short]                  -- Level with classification
-- [hp] [hp:short] [hp:max] [hp:max-short] [hp:percent] [hp:deficit] -- Health
-- [pp] [pp:short] [pp:max] [pp:max-short] [pp:percent]              -- Power  
-- [class] [race]                         -- Class and race
-- [status] [status:short]                -- Connection/death status
-- [classification]                       -- Elite/rare indicator

-- Register custom tags
oUF.Tags:Register("myhp", function(unit)
    local current = UnitHealth(unit)
    local max = UnitHealthMax(unit)
    return string.format("%d/%d", current, max)
end, {"UNIT_HEALTH", "UNIT_MAXHEALTH"})
```

### Color System

```lua
-- Get class color
local r, g, b = unpack(oUF:GetClassColor("WARRIOR"))

-- Get power color  
local r, g, b = unpack(oUF:GetPowerColor("MANA"))

-- Get reaction color
local r, g, b = unpack(oUF:GetReactionColor(5)) -- 5 = friendly

-- Utility functions
local formattedNumber = oUF:FormatNumber(1500000) -- "1.5M"
local timeString = oUF:FormatTime(125) -- "2:05"
local classification = oUF:GetUnitClassification(unit) -- "Elite", "Rare", etc.
```

### Events and Updates

The framework automatically handles event registration and updates, but you can customize behavior:

```lua
-- Custom post-update callbacks
health.PostUpdate = function(element, unit, current, max, isDeadOrGhost, isConnected)
    -- Custom logic after health update
end

power.PostUpdate = function(element, unit, current, max, powerType, powerTypeName)
    -- Custom logic after power update  
end

castbar.PostUpdate = function(element, unit, name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID)
    -- Custom logic after castbar update
end
```

## Integration with DamiaUI

The oUF framework is automatically loaded by DamiaUI and made available through:

```lua
local oUF = DamiaUI.Libraries.oUF
```

The existing UnitFrames module in `DamiaUI/Modules/UnitFrames/UnitFrames.lua` provides a complete example of how to use this framework to create the centered layout unit frames.

## Performance Considerations

- Element updates are throttled to prevent excessive CPU usage
- Event registration is optimized to only listen for relevant events
- Large numbers are automatically formatted to prevent UI clutter
- Unused elements can be disabled to save resources

## Compatibility

- World of Warcraft 11.2+
- Compatible with all game versions (Mainline, Classic, etc.)
- Works with the DamiaUI error handling and performance systems
- Namespace isolated to prevent conflicts with other oUF installations

## License

This implementation is based on the original oUF framework by Haste and is embedded within DamiaUI under the same permissive license terms.