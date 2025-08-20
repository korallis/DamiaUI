# ColdUI60Beta to DamiaUI Migration Plan
## WoW 6.0 (WoD) to WoW 11.2 (The War Within)

---

## Module Structure Analysis

### ColdUI60Beta Components
1. **CError** - Error handling
2. **ColdBars** - Action bars system
3. **ColdMisc** - Miscellaneous features (minimap, chat, datatexts)
4. **ColdPlates** - Nameplates
5. **oUF** - Unit frame framework (embedded)
6. **oUF_Coldkil** - Unit frames layout
7. **oUF_Smooth** - Smooth bar animations
8. **rBuffFrameStyler** - Buff frame styling
9. **rLib** - Library functions (drag, fade, slash commands)

---

## Critical API Changes (6.0 → 11.2)

### 1. BackdropTemplate (MANDATORY since 9.0)
```lua
-- OLD (6.0):
local frame = CreateFrame("Frame", name, parent)

-- NEW (11.2):
local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
```

### 2. Action Bar API
```lua
-- REMOVED/FAKE:
ActionButton_UpdateAction()
ActionButton_Update()
ActionButton_ShowGrid()
ActionButton_HideGrid()

-- REPLACED WITH:
Manual updates using GetActionTexture(), GetActionCooldown(), etc.
```

### 3. Settings API
- UIDropDownMenu → New menu system
- Settings API completely overhauled

### 4. Minimap API
```lua
-- OLD:
MinimapCluster references

-- NEW:
MinimapCluster → Minimap
```

### 5. Combat Lockdown
- More strict InCombatLockdown() checks required
- Secure frame modifications must be queued

### 6. TOC File Changes
```toc
-- OLD:
## Interface: 60000

-- NEW:
## Interface: 110200
## IconTexture: Interface\Icons\INV_Misc_QuestionMark
## Category: DamiaUI
```

---

## Migration Steps

### Phase 1: Setup and Backup
1. Backup current DamiaUI files
2. Create migration documentation
3. Remove all existing DamiaUI files
4. Copy ColdUI60Beta structure

### Phase 2: Core Framework
1. Update all TOC files to Interface: 110200
2. Add BackdropTemplate to all frame creations
3. Update oUF framework to latest version
4. Fix LibStub and CallbackHandler references

### Phase 3: Action Bars (ColdBars)
- Remove ActionButton_UpdateAction references
- Implement manual update functions
- Use SecureActionButtonTemplate
- Add proper event handlers

### Phase 4: Unit Frames (oUF_Coldkil)
- Update oUF elements for 11.2
- Fix backdrop issues
- Update secure unit button templates
- Add PingableUnitFrameTemplate where needed

### Phase 5: Minimap (ColdMisc)
- Update MinimapCluster references
- Fix coordinate display
- Update zone text handling

### Phase 6: Chat (ColdMisc)
- Update chat frame modifications
- Fix tab handling
- Update editbox modifications

### Phase 7: Nameplates (ColdPlates)
- Complete rewrite needed (nameplate API changed)
- Use new C_NamePlate API

### Phase 8: Datatexts (ColdMisc)
- Update stat APIs
- Fix memory/fps calculations
- Update gold display

---

## File Structure Plan

```
DamiaUI/
├── DamiaUI.toc (main TOC)
├── Core/
│   ├── Init.lua
│   ├── Config.lua
│   ├── Profiles.lua
│   └── Libraries.xml
├── Modules/
│   ├── ActionBars/
│   │   ├── ActionBars.lua
│   │   ├── Bar1.lua
│   │   ├── Bar2.lua
│   │   ├── Bar3.lua
│   │   ├── Bar4.lua
│   │   ├── Bar5.lua
│   │   ├── PetBar.lua
│   │   ├── StanceBar.lua
│   │   └── ExtraBar.lua
│   ├── UnitFrames/
│   │   ├── Core.lua
│   │   ├── Player.lua
│   │   ├── Target.lua
│   │   ├── Party.lua
│   │   ├── Raid.lua
│   │   └── Arena.lua
│   ├── Minimap/
│   │   └── Minimap.lua
│   ├── Chat/
│   │   └── Chat.lua
│   ├── Nameplates/
│   │   └── Nameplates.lua
│   ├── DataTexts/
│   │   ├── Time.lua
│   │   ├── Durability.lua
│   │   ├── Gold.lua
│   │   └── System.lua
│   └── Misc/
│       ├── ErrorHandler.lua
│       ├── Tooltip.lua
│       └── MicroMenu.lua
├── Media/
│   ├── Fonts/
│   │   └── homespun.ttf
│   └── Textures/
│       ├── flat2.tga
│       └── [other textures]
└── Libraries/
    ├── oUF/
    ├── LibStub/
    └── CallbackHandler/
```

---

## API Function Replacements

### Action Bars
```lua
-- OLD:
ActionButton_UpdateAction(button)

-- NEW:
local function UpdateActionButton(button)
    local action = button:GetAttribute("action")
    local texture = GetActionTexture(action)
    if texture then
        button.icon:SetTexture(texture)
    end
    -- Update cooldown, count, etc.
end
```

### Unit Frames
```lua
-- OLD:
local frame = CreateFrame("Button", name, parent)

-- NEW:
local frame = CreateFrame("Button", name, parent, 
    "SecureUnitButtonTemplate, PingableUnitFrameTemplate")
```

### Backdrops
```lua
-- OLD:
frame:SetBackdrop(backdrop)

-- NEW:
if not frame.SetBackdrop then
    Mixin(frame, BackdropTemplateMixin)
end
frame:SetBackdrop(backdrop)
```

---

## Testing Checklist

- [ ] Addon loads without errors
- [ ] Action bars display and function
- [ ] Unit frames show and update
- [ ] Minimap displays correctly
- [ ] Chat modifications work
- [ ] Nameplates appear
- [ ] Data texts update
- [ ] Combat lockdown respected
- [ ] Settings save/load
- [ ] No taint errors

---

## Known Issues to Address

1. **ActionButton_UpdateAction** - Doesn't exist, needs complete rewrite
2. **MinimapCluster** - Changed structure
3. **Nameplate API** - Complete overhaul needed
4. **Settings API** - New system required
5. **UIDropDownMenu** - Replaced with new menu system
6. **Backdrop issues** - All frames need BackdropTemplate

---

## Resources

- In-game API: `/api`
- Frame Stack: `/fstack`
- Event Trace: `/etrace`
- Taint Log: `/console taintLog 1`
- Documentation: DamiaUI-Plan/VERIFIED_API_DOCUMENTATION.md