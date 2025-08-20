# DamiaUI Master Rebuild Plan

## Executive Summary
This document consolidates all learnings, mistakes, and solutions into a master plan for rebuilding DamiaUI from scratch using **Option 1: Start with WORKING_EXAMPLE.lua**.

## Documents Created
1. **MISTAKES_ANALYSIS.md** - Comprehensive analysis of what went wrong
2. **PREVENTION_ROADMAP.md** - Strategies to prevent future failures  
3. **IMPLEMENTATION_GUIDE.md** - Working code patterns and examples
4. **VALIDATION_CHECKLIST.md** - Step-by-step testing procedures
5. **WoW_Addon_Development_Knowledge_Base.md** (Updated) - Corrected patterns
6. **WORKING_EXAMPLE.lua** - 350 lines of ACTUALLY WORKING code

## The Core Lesson
**131 files with zero functionality < 350 lines that actually work**

## Critical Mistakes We Made
1. ❌ Renamed all libraries with "DamiaUI_" prefix → Broke everything
2. ❌ Built complex abstractions → No actual functionality
3. ❌ Referenced non-existent systems → Code that calls nothing
4. ❌ Never tested in-game → Built in a vacuum
5. ❌ Copied without understanding → Cargo cult programming

## The New Approach

### Phase 1: Foundation (Week 1)
**Goal**: Get WORKING_EXAMPLE.lua running perfectly

#### Day 1-2: Setup & Basic Frames
```lua
-- Start with WORKING_EXAMPLE.lua
-- Test each function works
/run DamiaUI.playerFrame:Show() -- Must work
/run DamiaUI.targetFrame:Show() -- Must work
/run DamiaUI.actionBar:Show() -- Must work
```

#### Day 3-4: Polish & Saved Variables
- Add position saving
- Add profile support
- Test persistence across /reload

#### Day 5: Validation
- Run full VALIDATION_CHECKLIST.md
- Must pass ALL checks before proceeding

### Phase 2: Modularization (Week 2)
**Goal**: Split WORKING_EXAMPLE.lua into logical files

#### File Structure (ONLY these files):
```
DamiaUI/
├── DamiaUI.toc
├── Core.lua           -- Initialization
├── PlayerFrame.lua    -- Player unit frame
├── TargetFrame.lua    -- Target unit frame
├── ActionBar.lua      -- Action bars
├── SlashCommands.lua  -- Commands
└── Config.lua         -- Settings
```

#### Rules:
1. Each file must add VISIBLE functionality
2. Test after EVERY file
3. NO abstraction layers
4. NO library renaming

### Phase 3: Configuration (Week 3)
**Goal**: Add simple configuration

#### Priority Order:
1. Slash commands for all settings
2. Saved variables for persistence
3. Only then consider GUI config

### Phase 4: Extended Features (Week 4+)
**Goal**: Add features users actually want

#### Feature Priority:
1. Party frames (if requested)
2. Raid frames (if requested)
3. Cast bars (if requested)
4. Buffs/Debuffs (if requested)

**Rule**: NO feature without user request

## Validation Gates

### Gate 1: After WORKING_EXAMPLE.lua
- [ ] Player frame visible and updating
- [ ] Target frame working with colors
- [ ] Action bar buttons clickable
- [ ] Slash commands working
- [ ] Survives /reload

### Gate 2: After Modularization
- [ ] All files load without errors
- [ ] Same functionality as single file
- [ ] No performance degradation
- [ ] Clean /framestack output

### Gate 3: After Configuration
- [ ] Settings persist
- [ ] Commands change settings
- [ ] No combat lockdown issues
- [ ] Works with default UI hidden

## Development Rules

### ABSOLUTE RULES (NEVER BREAK):
1. **NO library renaming** - Use standard names ALWAYS
2. **Test in-game within 1 hour** - No long coding sessions
3. **Visible changes only** - If user can't see it, don't build it
4. **One feature at a time** - Complete before starting next
5. **Working > Perfect** - Functionality before elegance

### Red Flags (STOP if you see these):
- Writing more than 100 lines without testing
- Creating "systems" or "frameworks"
- Renaming ANY library
- Building for "future needs"
- Not seeing changes in-game

## Success Metrics

### Week 1 Success:
- ✅ WORKING_EXAMPLE.lua runs perfectly
- ✅ All frames visible and functional
- ✅ Slash commands work
- ✅ No errors in BugSack

### Week 2 Success:
- ✅ Code split into logical files
- ✅ Same functionality maintained
- ✅ Clean, readable code
- ✅ Each file under 500 lines

### Week 3 Success:
- ✅ Configuration system works
- ✅ Settings persist
- ✅ User can customize
- ✅ No performance impact

### Week 4+ Success:
- ✅ User-requested features added
- ✅ Stable and performant
- ✅ Works with other addons
- ✅ Positive user feedback

## Testing Protocol

### After EVERY code change:
1. `/reload` - Must load without errors
2. `/framestack` - Check frame visibility
3. `/damiaui test` - Run built-in tests
4. Check BugSack - Zero errors
5. Test in combat - No taints

### Daily Testing:
1. Fresh login test
2. Instance test
3. PvP test (if applicable)
4. Memory/performance check
5. Other addon compatibility

## File Structure (Final)

```
DamiaUI/
├── DamiaUI.toc              -- Manifest (10 lines max)
├── Core.lua                 -- Init & setup (100 lines max)
├── Frames/
│   ├── PlayerFrame.lua      -- Player unit frame (200 lines max)
│   ├── TargetFrame.lua      -- Target unit frame (200 lines max)
│   └── PartyFrames.lua      -- Party frames (if needed)
├── Bars/
│   ├── ActionBar.lua        -- Main action bar (300 lines max)
│   └── ExtraBars.lua        -- Additional bars (if needed)
├── Config/
│   ├── SlashCommands.lua    -- Commands (100 lines max)
│   └── SavedVariables.lua   -- Settings (100 lines max)
└── Libs/                    -- ONLY if absolutely needed
    └── LibStub.lua          -- STANDARD NAME, NO PREFIX
```

## The Mantra
**"Does it work in-game? Can the user see it? If not, nothing else matters."**

## Starting Point
1. Copy WORKING_EXAMPLE.lua to new DamiaUI folder
2. Create simple .toc file
3. Test it works
4. Begin Phase 1

## Remember
- The original DamiaUI failed with 131 files
- WORKING_EXAMPLE.lua succeeds with 350 lines
- **Simple and working beats complex and broken every time**

---

## Approval Checkpoint
Before proceeding with rebuild:
- [ ] Reviewed all mistake documents
- [ ] Understand what went wrong
- [ ] Committed to simple approach
- [ ] Will test frequently in-game
- [ ] Will NOT rename libraries
- [ ] Will NOT build abstractions
- [ ] Will follow validation checklist

**Ready to build something that ACTUALLY WORKS!**