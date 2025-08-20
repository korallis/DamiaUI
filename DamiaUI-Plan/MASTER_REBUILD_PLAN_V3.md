# DamiaUI Master Rebuild Plan V3 - Based on VERIFIED API
**Date:** August 19, 2025  
**Interface:** 110200  
**Status:** Complete rewrite with actually tested patterns

---

## Core Principles (Updated)

1. **VERIFY EVERY FUNCTION EXISTS** - Use `/api` in-game or test directly
2. **BackdropTemplate is MANDATORY** - For any frame using SetBackdrop
3. **No Fantasy Functions** - ActionButton_UpdateAction doesn't exist
4. **Test Incrementally** - Every 10 lines of code
5. **Copy Working Addons** - Not theoretical documentation

---

## Pre-Development Checklist

### API Verification Commands
```lua
-- Test if a function exists BEFORE using it
/run print(ActionButton_UpdateAction and "EXISTS" or "DOESN'T EXIST")
/run print(GetActionTexture and "EXISTS" or "DOESN'T EXIST")
/run print(CreateFrame and "EXISTS" or "DOESN'T EXIST")

-- Open API browser
/api

-- Check frame inheritance
/run local f = CreateFrame("Frame", nil, nil, "BackdropTemplate"); print(f.SetBackdrop and "HAS SetBackdrop" or "NO SetBackdrop")
```

---

## Phase 1: Minimal VERIFIED Working Addon

### Goal
Single file that ACTUALLY works with zero errors

### Critical Templates Required
```lua
-- MANDATORY for backgrounds (since WoW 9.0):
"BackdropTemplate"

-- For secure actions:
"SecureActionButtonTemplate"  -- NOT ActionBarButtonTemplate alone

-- For cooldowns:
"CooldownFrameTemplate"
```

### Verified Frame Creation
```lua
-- ✅ WORKING Player Frame
local function CreatePlayerFrame()
    -- MUST have BackdropTemplate for SetBackdrop to work
    local frame = CreateFrame("Frame", "DamiaUIPlayerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 60)
    frame:SetPoint("CENTER", UIParent, "CENTER", -250, -150)
    
    -- NOW SetBackdrop works
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    
    -- StatusBar doesn't need special template
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    return frame
end
```

### Verified Action Button Creation
```lua
-- ✅ WORKING Action Button (NO FANTASY FUNCTIONS)
local function CreateActionButton(parent, id)
    -- Use SecureActionButtonTemplate ONLY
    local button = CreateFrame("Button", "DamiaUIButton"..id, parent, 
                              "SecureActionButtonTemplate")
    button:SetSize(36, 36)
    
    -- Configure for actions
    button:SetAttribute("type", "action")
    button:SetAttribute("action", id)
    
    -- Visual elements (MANUAL - no magic update functions)
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints()
    
    -- Cooldown with proper template
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    
    -- MANUAL update function - NOT built-in
    button.Update = function(self)
        local action = self:GetAttribute("action")
        local texture = GetActionTexture(action)  -- REAL function
        
        if texture then
            self.icon:SetTexture(texture)
            self.icon:Show()
        else
            self.icon:Hide()
        end
        
        -- Update cooldown with REAL functions
        local start, duration, enable = GetActionCooldown(action)
        if start and duration and start > 0 then
            self.cooldown:SetCooldown(start, duration)
        else
            self.cooldown:Clear()
        end
    end
    
    -- Initial update
    button:Update()
    
    return button
end
```

### Testing Protocol for Phase 1
```lua
-- After EVERY function addition:
/reload
/run print(GetAddOnMemoryUsage("DamiaUI").." KB")  -- Check memory
/run print(DamiaUIPlayerFrame and "✓" or "✗")      -- Check frame exists

-- Test specific functions:
/run DamiaUIPlayerFrame:SetBackdropColor(1,0,0,1)  -- Should turn red
/run DamiaUIButton1:Update()                        -- Should not error
```

---

## Phase 2: Modularization (ONLY after Phase 1 works)

### File Structure
```
DamiaUI/
├── DamiaUI.toc          # Verified loading order
├── Init.lua             # Namespace only
├── API.lua              # Verified API wrappers
├── Frames.lua           # Frame creation with BackdropTemplate
├── Buttons.lua          # Action buttons with REAL functions
└── SlashCommands.lua    # Simple command interface
```

### Init.lua - Namespace Setup
```lua
local addonName, addonTable = ...
_G.DamiaUI = addonTable

-- Store verified API functions
DamiaUI.API = {
    -- Only functions we've verified exist
    GetActionTexture = GetActionTexture,
    GetActionCooldown = GetActionCooldown,
    HasAction = HasAction,
    IsActionInRange = IsActionInRange,
    IsUsableAction = IsUsableAction,
    InCombatLockdown = InCombatLockdown,
}

-- Verify critical functions on load
local required = {
    "CreateFrame",
    "GetActionTexture",
    "GetActionCooldown",
}

for _, func in ipairs(required) do
    if not _G[func] then
        error("DamiaUI: Required function "..func.." doesn't exist!")
    end
end
```

---

## Phase 3: Event System (Verified Patterns)

### Real Events That Exist
```lua
-- ✅ VERIFIED Events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")    -- Combat ended
frame:RegisterEvent("PLAYER_REGEN_DISABLED")   -- Combat started
```

### Event Handler Pattern
```lua
local eventFrame = CreateFrame("Frame")
local events = {}

function events:ADDON_LOADED(addonName)
    if addonName ~= "DamiaUI" then return end
    -- Initialize
    eventFrame:UnregisterEvent("ADDON_LOADED")
end

function events:PLAYER_LOGIN()
    -- Create UI
end

function events:ACTIONBAR_SLOT_CHANGED(slot)
    -- Update specific button
    if DamiaUI.buttons[slot] then
        DamiaUI.buttons[slot]:Update()  -- Our function, not fantasy
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if events[event] then
        events[event](self, ...)
    end
end)

for event in pairs(events) do
    eventFrame:RegisterEvent(event)
end
```

---

## Phase 4: Combat Security (Critical)

### Secure Frame Rules
```lua
-- ✅ CORRECT: Check combat before modifying secure frames
local function ModifySecureFrame(frame)
    if InCombatLockdown() then
        print("Cannot modify during combat")
        return
    end
    
    frame:SetAttribute("action", 1)
end

-- ✅ CORRECT: Queue changes for after combat
local pendingChanges = {}

local function QueueSecureChange(frame, attribute, value)
    if InCombatLockdown() then
        pendingChanges[frame] = pendingChanges[frame] or {}
        pendingChanges[frame][attribute] = value
    else
        frame:SetAttribute(attribute, value)
    end
end

-- Apply after combat
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
    for frame, attributes in pairs(pendingChanges) do
        for attr, value in pairs(attributes) do
            frame:SetAttribute(attr, value)
        end
    end
    wipe(pendingChanges)
end)
```

---

## Phase 5: Libraries (Only If Needed)

### When to Use Libraries
- **LibActionButton-1.0** - ONLY if action buttons need advanced features
- **LibStub** - ONLY if using Ace3 or old libraries
- **oUF** - ONLY for complex unit frame layouts

### How to Verify Library Functions
```lua
-- Before using ANY library function
local LAB = LibStub and LibStub("LibActionButton-1.0", true)
if LAB then
    -- Library exists, verify methods
    if LAB.CreateButton then
        local button = LAB:CreateButton(...)
    else
        -- Fall back to manual implementation
    end
end
```

---

## Common Pitfalls (Updated)

### Fantasy Functions to Avoid
```lua
-- ❌ THESE DON'T EXIST:
ActionButton_UpdateAction()
ActionButton_Update()
ActionButton_ShowGrid()
ActionButton_HideGrid()
ActionBar_Update()
UnitFrame_Update()

-- ✅ USE THESE INSTEAD:
GetActionTexture()
GetActionCooldown()
HasAction()
-- And write your own update logic
```

### Template Requirements
```lua
-- ❌ WRONG - SetBackdrop will be nil
local frame = CreateFrame("Frame", name, parent)

-- ✅ RIGHT - SetBackdrop works
local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")

-- ❌ WRONG - No secure functionality
local button = CreateFrame("Button", name, parent, "ActionBarButtonTemplate")

-- ✅ RIGHT - Secure actions work
local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
```

---

## Validation Every Step

### After Adding Each Feature
```lua
-- 1. Check for errors
/console scriptErrors 1

-- 2. Verify the feature exists
/run print(FeatureName and "✓ Exists" or "✗ Missing")

-- 3. Test functionality
/run FeatureName:TestMethod()

-- 4. Check memory usage
/run print(GetAddOnMemoryUsage("DamiaUI").." KB")

-- 5. Check for taint
/console taintLog 1
-- Then check Logs\taint.log
```

---

## Resource Verification

### Before Using ANY Pattern
1. **Search GitHub** for actual usage in working addons
2. **Test in-game** with `/run` command
3. **Check `/api`** browser for function signature
4. **Verify with working addons** like Bartender4, ElvUI

### Trusted Sources (2025)
- GitHub repositories updated in 2024-2025
- In-game `/api` browser
- Working addons you can test
- **NOT**: Old tutorials, AI suggestions, theoretical docs

---

## Implementation Timeline

### Week 1: Foundation
- **Day 1:** Single working file with verified API
- **Day 2:** Test thoroughly, fix all errors
- **Day 3:** Modularize ONLY working code
- **Day 4:** Add SavedVariables
- **Day 5:** Polish and optimize

### Week 2: Features
- **Day 1-2:** Focus frame
- **Day 3-4:** Cast bars
- **Day 5:** Buffs/Debuffs

### Week 3: Advanced
- **Day 1-3:** Party/Raid frames
- **Day 4-5:** Configuration UI

---

## Success Metrics

### Phase 1 Complete
- [ ] Zero Lua errors
- [ ] All frames visible
- [ ] SetBackdrop works
- [ ] Action buttons clickable
- [ ] No fantasy function calls

### Phase 2 Complete
- [ ] Modular structure
- [ ] Each module loads
- [ ] No functionality lost
- [ ] Still zero errors

### Phase 3 Complete
- [ ] Events fire correctly
- [ ] Updates work
- [ ] Combat secure
- [ ] No taint

---

## Emergency Recovery

### If Functions Don't Exist
```lua
-- Create safe wrapper
local function SafeCall(func, ...)
    if _G[func] then
        return _G[func](...)
    else
        print("WARNING: "..func.." doesn't exist!")
        return nil
    end
end
```

### If Templates Missing
```lua
-- Check and add template
local frame = CreateFrame("Frame", name, parent)
if not frame.SetBackdrop and BackdropTemplateMixin then
    Mixin(frame, BackdropTemplateMixin)
end
```

---

## Final Checklist

Before ANY code commit:
- [ ] Tested in-game with `/reload`
- [ ] No Lua errors in chat or BugSack
- [ ] All functions verified to exist
- [ ] BackdropTemplate on all backdrop frames
- [ ] No fantasy update functions
- [ ] Manual update logic implemented
- [ ] Combat security checked
- [ ] Memory usage reasonable

---

## The Golden Rule

**If you haven't seen it work in-game, it doesn't work.**

No assumptions. No theoretical code. Only verified, tested, working patterns.