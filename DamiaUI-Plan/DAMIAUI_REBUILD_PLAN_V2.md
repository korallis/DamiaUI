# DamiaUI Rebuild Plan V2 - Based on Verified Patterns
**Date:** August 19, 2025  
**Interface:** 110200  
**Status:** Complete redesign based on working production patterns

---

## Core Principles

1. **Test Everything** - No code is assumed to work without testing
2. **Start Simple** - Single file first, then expand
3. **Use Proven Patterns** - Copy from working addons, not theoretical docs
4. **BackdropTemplate Always** - Never create frames with backdrops without it
5. **Verify Each Step** - Test in-game after every change

---

## Phase 1: Minimal Working Addon (1 File)

### Goal
Create a single DamiaUI.lua that:
- Shows player frame with health/power
- Shows target frame 
- Creates action bar with 12 buttons
- Has working slash commands
- All in ~350 lines

### Implementation
```lua
-- DamiaUI.lua
local addonName, addonTable = ...
_G.DamiaUI = addonTable

-- Player Frame
local function CreatePlayerFrame()
    local frame = CreateFrame("Frame", "DamiaUIPlayerFrame", UIParent, "BackdropTemplate")
    -- Implementation from VERIFIED_API_DOCUMENTATION.md
    return frame
end

-- Target Frame  
local function CreateTargetFrame()
    local frame = CreateFrame("Frame", "DamiaUITargetFrame", UIParent, "BackdropTemplate")
    -- Implementation from VERIFIED_API_DOCUMENTATION.md
    return frame
end

-- Action Bar
local function CreateActionBar()
    local bar = CreateFrame("Frame", "DamiaUIActionBar", UIParent)
    -- Implementation from VERIFIED_API_DOCUMENTATION.md
    return bar
end

-- Initialize on PLAYER_LOGIN
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    DamiaUI.playerFrame = CreatePlayerFrame()
    DamiaUI.targetFrame = CreateTargetFrame()
    DamiaUI.actionBar = CreateActionBar()
    print("|cffCC8010DamiaUI|r: Loaded successfully!")
end)

-- Slash Commands
SLASH_DAMIAUI1 = "/damiaui"
SLASH_DAMIAUI2 = "/dui"
SlashCmdList["DAMIAUI"] = function(msg)
    -- Command handling
end
```

### Validation
```bash
# Test commands
/damiaui test
/run print(DamiaUIPlayerFrame and "Player frame exists" or "FAILED")
/run print(DamiaUITargetFrame and "Target frame exists" or "FAILED")
/run print(DamiaUIActionBar and "Action bar exists" or "FAILED")
```

---

## Phase 2: Modular Structure (5 Files)

### File Structure
```
DamiaUI/
├── DamiaUI.toc
├── Core.lua         # Initialization and namespace
├── UnitFrames.lua   # Player, target, focus frames
├── ActionBars.lua   # All action bar functionality
├── Config.lua       # SavedVariables and settings
└── SlashCommands.lua # Command interface
```

### Core.lua
```lua
local addonName, addonTable = ...
_G.DamiaUI = addonTable

DamiaUI.frames = {}
DamiaUI.bars = {}
DamiaUI.config = {}

-- Event frame for initialization
DamiaUI.eventFrame = CreateFrame("Frame")
DamiaUI.eventFrame:RegisterEvent("ADDON_LOADED")
DamiaUI.eventFrame:RegisterEvent("PLAYER_LOGIN")
```

### Implementation Order
1. Get Core.lua working with proper namespace
2. Move unit frames to UnitFrames.lua
3. Move action bars to ActionBars.lua
4. Implement SavedVariables in Config.lua
5. Set up slash commands in SlashCommands.lua

---

## Phase 3: Configuration System

### Goals
- SavedVariables for positions/settings
- In-game configuration via slash commands
- Profile system (optional)

### Config Structure
```lua
DamiaUIDB = {
    version = 2,
    frames = {
        player = { point = "CENTER", x = -200, y = -100, scale = 1 },
        target = { point = "CENTER", x = 200, y = -100, scale = 1 },
    },
    bars = {
        main = { point = "BOTTOM", x = 0, y = 40, scale = 1 },
    },
    settings = {
        hideBlizzard = true,
        lockFrames = false,
    }
}
```

---

## Phase 4: Additional Features

### Priority Order
1. **Focus Frame** - Simple extension of target frame
2. **Cast Bars** - Player and target casting
3. **Buffs/Debuffs** - Basic aura display
4. **Party Frames** - Group member display
5. **Raid Frames** - Raid member display (later)

### Each Feature Process
1. Research working examples from oUF or similar
2. Create minimal implementation
3. Test in-game
4. Integrate with existing system
5. Add configuration options

---

## Phase 5: Libraries (If Needed)

### When to Add Libraries
- **ONLY** when core functionality is complete
- **ONLY** if they solve a specific problem
- **NEVER** rename library namespaces

### Potential Libraries
```lua
-- LibStub (if using Ace3)
local LibStub = _G.LibStub

-- oUF (if switching to framework)
local oUF = _G.oUF or ns.oUF

-- LibActionButton (for advanced action bars)
local LAB = LibStub("LibActionButton-1.0")
```

---

## Testing Protocol

### After Every Change
1. `/reload` to reload UI
2. Check for Lua errors
3. Verify frames exist: `/run print(FrameName)`
4. Test functionality
5. Check combat behavior

### Daily Testing
1. Run through dungeon/raid
2. Test in PvP
3. Check memory usage: `/run print(GetAddOnMemoryUsage("DamiaUI"))`
4. Verify saved variables persist

---

## Common Pitfalls to Avoid

### From Our Mistakes
1. ❌ **Don't rename libraries** - Use standard names
2. ❌ **Don't create non-existent systems** - No ModuleLoader, EventDispatcher
3. ❌ **Don't over-engineer** - Start simple, expand later
4. ❌ **Don't skip BackdropTemplate** - Required since 9.0
5. ❌ **Don't trust old documentation** - Verify everything

### From Research
1. ❌ **Don't modify secure frames in combat** - Check InCombatLockdown()
2. ❌ **Don't use global variables carelessly** - Namespace everything
3. ❌ **Don't hook secure functions directly** - Use hooksecurefunc
4. ❌ **Don't forget to unregister one-time events** - Memory leaks
5. ❌ **Don't assume API compatibility** - Test each pattern

---

## Success Metrics

### Phase 1 Complete When
- [ ] Player frame shows and updates
- [ ] Target frame shows and updates
- [ ] Action bar works with spells
- [ ] Slash commands respond
- [ ] No Lua errors

### Phase 2 Complete When
- [ ] Code is modular
- [ ] Each module loads correctly
- [ ] No functionality lost from Phase 1
- [ ] File structure is clean

### Phase 3 Complete When
- [ ] Settings persist across sessions
- [ ] Frames remember positions
- [ ] Configuration commands work
- [ ] Reset functionality works

### Phase 4 Complete When
- [ ] Each new feature works independently
- [ ] No conflicts with existing features
- [ ] Performance remains good
- [ ] No taint issues

---

## Recovery From Failures

### If Something Breaks
1. **Immediate:** `/reload` and check errors
2. **Debug:** `/etrace` to see events
3. **Inspect:** `/fstack` to examine frames
4. **Rollback:** Git revert to last working
5. **Isolate:** Comment out sections to find issue

### If Taint Occurs
1. Enable taint log: `/console taintLog 1`
2. Check `Logs\taint.log`
3. Look for "blocked" entries
4. Find the source of taint
5. Fix secure frame handling

---

## Timeline Estimate

- **Phase 1:** 1 day (mostly complete)
- **Phase 2:** 1 day (modularization)
- **Phase 3:** 1 day (configuration)
- **Phase 4:** 3-5 days (features)
- **Phase 5:** Optional (as needed)

**Total:** 1 week for fully functional replacement UI

---

## Current Status

✅ **Phase 1:** Working example created (with BackdropTemplate fix)  
⏳ **Phase 2:** Ready to begin modularization  
⏳ **Phase 3:** Config system design complete  
⏳ **Phase 4:** Feature list prioritized  
⏳ **Phase 5:** Libraries identified if needed

---

## Next Immediate Steps

1. Test the fixed DamiaUI.lua in-game
2. Verify all frames appear correctly
3. Begin Phase 2 modularization
4. Create proper file structure
5. Test each module independently