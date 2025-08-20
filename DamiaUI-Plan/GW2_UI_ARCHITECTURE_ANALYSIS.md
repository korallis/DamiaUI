# GW2 UI Architecture Analysis - Complete Breakdown
**Date:** August 19, 2025  
**Source:** https://github.com/Mortalknight/GW2_UI  
**Purpose:** Learn from a successful complete UI replacement addon

---

## Executive Summary

GW2 UI is a mature, professional complete UI replacement addon that does EXACTLY what DamiaUI aims to do - replace the entire WoW interface. The difference is visual style: GW2 UI uses Guild Wars 2 aesthetics while we want clean, minimalistic, pixel-perfect modern design.

---

## Core Architecture

### 1. File Organization
```
GW2_UI/
├── core/                    # Core functionality (shared across versions)
│   ├── API/                 # API wrappers
│   ├── Aura/                # Buff/debuff handling
│   ├── Mainbar/             # Main action bar layout
│   ├── Units/               # Unit frames
│   ├── GW2_ui.lua          # Main addon logic
│   ├── init.lua            # Initial setup
│   ├── disableBlizzard.lua # Blizzard UI hiding
│   └── backdropTemplates.lua
├── Mainline/               # Retail-specific code
│   ├── Actionbar/          # Action bar implementation
│   ├── Character/          # Character panel
│   └── Units/              # Retail-specific unit frames
├── settings/               # Settings system
├── Textures/              # All textures
├── fonts/                 # Custom fonts
└── Libs/                  # External libraries
```

### 2. Initialization Flow
1. **init.lua** - Sets up namespace, constants, libraries
2. **defaults2.lua** - Default settings
3. **migration.lua** - Settings migration
4. **disableBlizzard.lua** - Hide Blizzard frames
5. **GW2_ui.lua** - Main addon logic and module loading

---

## Key Implementation Patterns

### 1. Hiding Blizzard UI (Complete)

```lua
-- From Actionbars.lua - They hide EVERYTHING
local GW_BLIZZARD_HIDE_FRAMES = {
    MainMenuBar,
    MainMenuBar.Background,
    MainMenuBarOverlayFrame,
    MainMenuBarTexture0,
    MainMenuBarTexture1,
    MainMenuBarTexture2,
    MainMenuBarTexture3,
    MainMenuBar.EndCaps.LeftEndCap,
    MainMenuBar.EndCaps.RightEndCap,
    MainMenuBar.ActionBarPageNumber,
    MainMenuBar.BorderArt,
    ReputationWatchBar,
    HonorWatchBar,
    ArtifactWatchBar,
    MainMenuExpBar,
    VerticalMultiBarsContainer  -- The War Within specific
}

local function hideBlizzardsActionbars()
    for _, v in pairs(GW_BLIZZARD_HIDE_FRAMES) do
        if v then
            v:SetAlpha(0)
            v:EnableMouse(false)
            if v.UnregisterAllEvents then
                v:UnregisterAllEvents()
            end
        end
    end
    -- Force hide with hooksecurefunc
    for _, object in pairs(GW_BLIZZARD_FORCE_HIDE) do
        hooksecurefunc(object, "Show", Self_Hide)
        object:Hide()
    end
end
```

### 2. Action Button Implementation

```lua
-- They DON'T use ActionButton_UpdateAction (doesn't exist!)
-- Instead, they style existing buttons and hook updates
local function setActionButtonStyle(btn, noBackDrop, isStanceButton, isPet)
    local btnName = btn:GetName()
    local btnWidth = btn:GetWidth()
    
    -- Icon texture
    btn.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Custom backdrop system
    if btn.gwBackdrop == nil then
        local backDrop = CreateFrame("Frame", nil, btn, "GwActionButtonBackdropTmpl")
        btn.gwBackdrop = backDrop
    end
    
    -- Pushed/highlight textures
    btn:SetPushedTexture("Interface/AddOns/GW2_UI/textures/uistuff/actionbutton-pressed")
    btn:SetHighlightTexture("Interface/AddOns/GW2_UI/textures/uistuff/UI-Quickslot-Depress")
    
    -- Cooldown handling
    btn.cooldown:SetSwipeColor(0, 0, 0, 0.7)
    btn.cooldown:SetHideCountdownNumbers(false)
end
```

### 3. Unit Frame Creation

```lua
-- They use custom XML templates with Lua initialization
local function CreateUnitFrame(name, revert, animatedPowerbar)
    local template = "GwNormalUnitFramePingable"  -- Custom XML template
    local f = CreateFrame("Button", name, UIParent, template)
    
    -- Health bar setup with prediction
    f.health = f.healthContainer.healPrediction.absorbbg.health
    f.healPrediction = f.healthContainer.healPrediction
    
    -- Animated status bars
    GW.AddStatusbarAnimation(f.health, true)
    
    -- Power bar (optional animation)
    if animatedPowerbar then
        f.powerbar = GW.CreateAnimatedStatusBar(name .. "Powerbar", f, "GwStatusPowerBar", true)
    end
    
    return f
end
```

### 4. Module System

They don't use a traditional module system. Instead:
- Each feature is in its own file/directory
- Settings control what loads
- Everything is in the GW namespace
- Heavy use of hooks and callbacks

```lua
-- Example of their settings-based loading
if GW.settings.ACTIONBARS_ENABLED then
    GW.LoadActionbars()
end
if GW.settings.UNITFRAMES_ENABLED then
    GW.LoadUnitframes()
end
```

### 5. Visual Polish Techniques

#### Custom Borders
```lua
-- They create custom border frames
local backDrop = CreateFrame("Frame", nil, btn, "GwActionButtonBackdropTmpl")
backDrop.border1:SetAlpha(tonumber(GW.settings.ACTIONBAR_BACKGROUND_ALPHA))
```

#### Animations
```lua
-- Smooth animations for everything
local function AddToAnimation(name, from, to, start, duration, method)
    animations[name] = {
        start = start,
        duration = duration,
        from = from,
        to = to,
        method = method
    }
end
```

#### Texture Management
```lua
-- Consistent texture coords for clean edges
btn.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
```

---

## Critical Differences from Our Approach

### What They Do Better

1. **Complete Blizzard UI Hiding**
   - They hide 30+ frames vs our 2
   - Use hooksecurefunc to prevent re-showing
   - Handle The War Within specific frames

2. **Action Button Styling**
   - Style existing buttons instead of recreating
   - Custom backdrop system with XML templates
   - Proper cooldown visual handling

3. **Settings System**
   - Comprehensive settings with profiles
   - Every feature can be toggled
   - Settings migration system

4. **Visual Consistency**
   - Custom XML templates for consistent look
   - Shared backdrop templates
   - Consistent font handling

### What We Can Learn

1. **Hide ALL Blizzard frames, not just some**
2. **Use XML templates for complex layouts**
3. **Hook existing functionality instead of recreating**
4. **Implement proper settings system from start**
5. **Use animation system for smooth transitions**

---

## Implementation Strategy for DamiaUI

### Phase 1: Core Infrastructure
```lua
-- Proper namespace and initialization
local addonName, DamiaUI = ...
DamiaUI.modules = {}
DamiaUI.settings = {}

-- Complete Blizzard hiding
DamiaUI.HideBlizzardUI = function()
    -- Hide ALL frames like GW2 does
end
```

### Phase 2: Action Bars
```lua
-- Style existing buttons instead of recreating
local function StyleActionButton(button)
    -- Clean, minimal styling
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Minimal border
    button.border = CreateBorder(button, 1)
    
    -- Clean cooldown
    button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
end
```

### Phase 3: Unit Frames
```lua
-- Use templates for consistency
local function CreateMinimalUnitFrame(unit)
    local frame = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    
    -- Clean health bar
    frame.health = CreateFrame("StatusBar", nil, frame)
    frame.health:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
    
    -- Minimal text
    frame.healthText = frame.health:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    
    return frame
end
```

---

## Key Takeaways

1. **GW2 UI is professionally architected** - Not hacky, uses proper patterns
2. **They hook and style, not recreate** - Work WITH WoW's systems
3. **Complete replacement means COMPLETE** - Hide everything Blizzard
4. **Settings from the start** - Every feature toggleable
5. **Visual consistency through templates** - Not ad-hoc styling

---

## Action Items for DamiaUI

1. ✅ Copy their complete Blizzard frame hiding list
2. ✅ Implement proper action button styling (not recreation)
3. ⏳ Create XML templates for our minimal style
4. ⏳ Build settings system from start
5. ⏳ Use their animation system for polish

---

## Code We Should Directly Adapt

### 1. Complete Hide List
```lua
-- Adapt their GW_BLIZZARD_HIDE_FRAMES list
-- Add hooksecurefunc pattern for force hiding
```

### 2. Action Button Range Indicator
```lua
-- Their helper_RangeUpdate function
-- Shows out-of-range with red overlay
```

### 3. Animation System
```lua
-- Their AddToAnimation/lerp system
-- Provides smooth transitions
```

### 4. Settings Architecture
```lua
-- Profile system
-- Migration system
-- Per-module settings
```

---

## Conclusion

GW2 UI shows that a complete UI replacement requires:
- **Comprehensive** Blizzard UI hiding
- **Working with** WoW's systems, not against them
- **Professional** architecture and organization
- **Settings-driven** modularity
- **Visual consistency** through templates

We can achieve our minimal, clean aesthetic using their proven architectural patterns.