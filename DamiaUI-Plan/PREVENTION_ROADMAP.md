# PREVENTION ROADMAP - DamiaUI Development Discipline

This document provides strict guidelines to prevent the catastrophic failures identified in the DamiaUI project analysis. **Follow these rules exactly** to build working functionality first, then add complexity incrementally.

---

## CORE DEVELOPMENT PRINCIPLES

### 1. WORKING CODE FIRST PRINCIPLE
**RULE:** No new systems, modules, or complexity until current functionality works in-game
**VALIDATION:** Must demonstrate working UI before proceeding to next step
**RED FLAGS:** 
- Building frameworks before creating frames
- Writing abstraction layers before concrete implementation
- Planning complex architectures before proving basic functionality

### 2. NO ABSTRACTION WITHOUT IMPLEMENTATION
**RULE:** Must have 3+ working concrete examples before creating abstraction
**VALIDATION:** Show multiple working implementations that share common patterns
**RED FLAGS:**
- Building "future-proof" architectures 
- Creating generic systems for single use cases
- Designing for "enterprise scalability" in simple addons

### 3. STANDARD LIBRARY NAMES ALWAYS
**RULE:** NEVER rename WoW addon libraries - use standard names exactly
**VALIDATION:** All LibStub calls use official library names
**RED FLAGS:**
- Any custom prefixing of library names
- "Namespacing" libraries for isolation
- Modifying library identification strings

### 4. TEST IN-GAME FREQUENTLY
**RULE:** Test in-game after every major change - within 1 hour of coding
**VALIDATION:** Screenshot/video proof of functionality working in WoW
**RED FLAGS:**
- Days of coding without in-game testing
- Relying only on syntax checking
- Building multiple systems before testing any

---

## PREVENTION STRATEGIES BY MISTAKE TYPE

### MISTAKE #1: LIBRARY RENAMING PREVENTION

**PREVENTION RULES:**
1. **NEVER modify library names** - use exactly as distributed
2. **Use LibStub standard patterns** - no custom namespacing
3. **Test library loading immediately** after including

**VALIDATION CHECKPOINTS:**
- [ ] All LibStub calls use official names (e.g., "AceAddon-3.0", not "DamiaUI_AceAddon-3.0")
- [ ] Libraries load without errors in /console lua
- [ ] Can create basic addon object with standard patterns

**RED FLAGS TO WATCH FOR:**
- Any mention of "custom" or "prefixed" libraries
- References to "DamiaUI_*" library names  
- Complex library loading logic instead of simple LibStub calls

**CORRECT PATTERN:**
```lua
-- ALWAYS use this pattern
local DamiaUI = LibStub("AceAddon-3.0"):NewAddon("DamiaUI", "AceEvent-3.0", "AceDB-3.0")

-- NEVER do this
local AceAddon = LibStub("DamiaUI_AceAddon-3.0")
```

### MISTAKE #2: NON-EXISTENT SYSTEM REFERENCES PREVENTION

**PREVENTION RULES:**
1. **Only reference systems that exist** - no forward declarations
2. **Create systems before using them** - implementation before reference
3. **Validate system existence** before calling methods

**VALIDATION CHECKPOINTS:**
- [ ] Every system referenced actually has implementation file
- [ ] All method calls have corresponding method definitions
- [ ] No nil checks that always fail due to unimplemented systems

**RED FLAGS TO WATCH FOR:**
- Setting systems to nil then checking if they exist
- Complex fallback logic for unimplemented systems
- References to "ModuleLoader", "EventDispatcher" etc. without implementation

**CORRECT PATTERN:**
```lua
-- Create system first
local PlayerFrame = DamiaUI:NewModule("PlayerFrame", "AceEvent-3.0")

-- Then use it
function PlayerFrame:OnEnable()
    -- Implementation here
end

-- NEVER do this
DamiaUI.ModuleLoader = nil  -- Set to nil
if DamiaUI.ModuleLoader then  -- Will always be false
```

### MISTAKE #3: ACE ADDON MISUSE PREVENTION

**PREVENTION RULES:**
1. **AceAddon IS your addon object** - don't merge or modify
2. **Use AceAddon standard patterns** - no custom object composition
3. **Let AceAddon handle module creation** - use NewModule()

**VALIDATION CHECKPOINTS:**
- [ ] Addon created with single LibStub("AceAddon-3.0"):NewAddon() call
- [ ] No merging AceAddon into other objects
- [ ] Modules created with addon:NewModule() pattern

**RED FLAGS TO WATCH FOR:**
- Complex object merging or copying
- Manual method copying between objects
- Multiple addon object creation attempts

**CORRECT PATTERN:**
```lua
-- Simple and correct
local DamiaUI = LibStub("AceAddon-3.0"):NewAddon("DamiaUI", "AceEvent-3.0")

-- Create modules through AceAddon
local PlayerFrame = DamiaUI:NewModule("PlayerFrame", "AceEvent-3.0")
```

### MISTAKE #4: ZERO FRAME CREATION PREVENTION

**PREVENTION RULES:**
1. **CreateFrame() is MANDATORY** - no UI exists without it
2. **Test frame visibility immediately** - must see frames in-game
3. **Build one working frame** before adding complexity

**VALIDATION CHECKPOINTS:**
- [ ] At least one CreateFrame() call in working code
- [ ] Frame visible in-game (screenshot required)
- [ ] Frame updates with game data (health, mana, etc.)

**RED FLAGS TO WATCH FOR:**
- oUF configuration without CreateFrame() calls
- "Elements" and "layouts" without actual frames
- Complex frame management systems with no frames

**MANDATORY FIRST IMPLEMENTATION:**
```lua
-- EVERY UI addon must start with this
local frame = CreateFrame("Frame", "DamiaUIPlayerFrame", UIParent)
frame:SetSize(200, 60)
frame:SetPoint("CENTER", UIParent, "CENTER", -250, -150)
frame:Show()

-- Then add complexity
local healthBar = CreateFrame("StatusBar", nil, frame)
-- ...
```

### MISTAKE #5: OVERCOMPLICATED COMMANDS PREVENTION

**PREVENTION RULES:**
1. **Start with simple slash commands** - no complex parsers
2. **Commands should do actual things** - not just print messages
3. **Build complexity incrementally** - add commands as features exist

**VALIDATION CHECKPOINTS:**
- [ ] Slash commands perform visible actions (toggle frames, etc.)
- [ ] Commands work with actual implemented features
- [ ] Simple command parsing (no enterprise-level argument handling)

**RED FLAGS TO WATCH FOR:**
- 200+ line command parsers for simple addons
- Commands that reference unimplemented features
- Complex argument parsing before basic functionality

**CORRECT PATTERN:**
```lua
-- Simple and functional
SLASH_DAMIAUI1 = "/damiaui"
SlashCmdList["DAMIAUI"] = function(msg)
    if msg == "toggle" then
        DamiaUI.playerFrame:SetShown(not DamiaUI.playerFrame:IsShown())
    else
        print("DamiaUI: Use 'toggle' to show/hide frames")
    end
end
```

### MISTAKE #6: STRUCTURE COPYING PREVENTION

**PREVENTION RULES:**
1. **Don't copy ElvUI structure** unless you have ElvUI's features
2. **Start with single file** - split only when >500 lines
3. **Understand WHY complex structures exist** before copying them

**VALIDATION CHECKPOINTS:**
- [ ] File count under 5 until core functionality works
- [ ] Each file has clear, single responsibility
- [ ] Can justify every file's existence with working functionality

**RED FLAGS TO WATCH FOR:**
- Creating 20+ files for basic addon
- Empty or near-empty module files
- Complex directory structures without features to justify them

**CORRECT PROGRESSION:**
```
Phase 1: DamiaUI.lua (all functionality, <500 lines)
Phase 2: Split when justified by size
Phase 3: Add structure only when maintaining >2000 lines
```

### MISTAKE #7: TESTING FAILURES PREVENTION

**PREVENTION RULES:**
1. **Test user-visible functionality** - not implementation details
2. **Can player see and interact with UI?** - primary test
3. **Test real game integration** - does it work in combat, with addons, etc.

**VALIDATION CHECKPOINTS:**
- [ ] Every test validates something user can see/interact with
- [ ] Tests verify frames exist and are visible
- [ ] Tests check data updates correctly (health bars, etc.)

**RED FLAGS TO WATCH FOR:**
- Testing library loading instead of UI functionality
- Complex test frameworks for simple functionality
- All tests passing while addon shows nothing in-game

**MANDATORY TEST PATTERN:**
```lua
-- Primary test - does it work for users?
function TestBasicFunctionality()
    -- Can user see the frame?
    assert(DamiaUI.playerFrame:IsVisible(), "Player frame should be visible")
    
    -- Does it show correct data?
    local health = UnitHealth("player")
    assert(DamiaUI.playerFrame.healthBar:GetValue() == health, "Health should match")
    
    -- Can user interact with it?
    DamiaUI.playerFrame:SetShown(false)
    assert(not DamiaUI.playerFrame:IsVisible(), "Frame should hide when commanded")
end
```

---

## STEP-BY-STEP BUILD PROCESS

### PHASE 1: SINGLE WORKING FRAME (WEEK 1)

**Goal:** One visible, functional UI element that replaces Blizzard functionality

**Day 1: Basic Player Frame**
- [ ] Create single .lua file with CreateFrame() call
- [ ] Frame visible at specific position
- [ ] Frame has background/border
- [ ] Test in-game: Can you see the frame?

**Day 2: Health Bar**
- [ ] Add StatusBar to frame
- [ ] StatusBar shows current player health
- [ ] Updates automatically when health changes
- [ ] Test in-game: Does health bar update correctly?

**Day 3: Power Bar and Text**
- [ ] Add power bar (mana/energy/rage)
- [ ] Add health text (current/max)
- [ ] Power updates with class resource
- [ ] Test in-game: Do all elements update correctly?

**Day 4: Target Frame**
- [ ] Create second frame for target
- [ ] Target frame shows target health/power
- [ ] Appears/disappears when target changes
- [ ] Test in-game: Does target frame work correctly?

**Day 5: Basic Positioning and Polish**
- [ ] Frames positioned like standard UI
- [ ] Basic drag functionality
- [ ] Simple saved variables for position
- [ ] Test in-game: Everything works and looks good?

**PHASE 1 SUCCESS CRITERIA:**
- Player can see custom health/power bars
- Bars update in real-time during gameplay
- Target frame works correctly
- Basic positioning is functional
- Can replace Blizzard player/target frames

### PHASE 2: ACTION BARS (WEEK 2)

**Prerequisites:** Phase 1 must be 100% functional

**Day 1: Single Action Button**
- [ ] Create one working action button
- [ ] Shows correct spell/item icon
- [ ] Button responds to clicks
- [ ] Test in-game: Can cast spells through button?

**Day 2: Full 12-Button Bar**
- [ ] Create array of 12 buttons
- [ ] All buttons functional and positioned correctly
- [ ] Buttons show current action bar spells
- [ ] Test in-game: Full action bar works?

**Day 3: Keybinding Support**
- [ ] Buttons respond to keybinds (1-9, 0, -, =)
- [ ] Visual feedback for keybinding
- [ ] Keybinds work in combat
- [ ] Test in-game: All keybinds functional?

**Day 4: Multiple Bars**
- [ ] Add second action bar
- [ ] Bar switching functionality
- [ ] Additional keybinding support
- [ ] Test in-game: Multiple bars work correctly?

**Day 5: Polish and Integration**
- [ ] Action bars integrate with unit frames
- [ ] Visual consistency
- [ ] Performance testing
- [ ] Test in-game: Everything works smoothly?

**PHASE 2 SUCCESS CRITERIA:**
- Complete action bar replacement
- All keybinds functional
- Multiple bars work correctly
- Performance acceptable in combat

### PHASE 3: CONFIGURATION (WEEK 3)

**Prerequisites:** Phases 1-2 must be 100% functional

**Day 1: Simple Slash Commands**
- [ ] /damiaui toggle - show/hide frames
- [ ] /damiaui reset - reset positions
- [ ] /damiaui scale [value] - scale UI elements
- [ ] Test in-game: All commands work?

**Day 2: Basic Saved Variables**
- [ ] Save frame positions between sessions
- [ ] Save scale settings
- [ ] Save enabled/disabled state
- [ ] Test in-game: Settings persist after reload?

**Day 3: Simple Configuration Panel**
- [ ] Basic GUI for common settings
- [ ] Position adjustment sliders
- [ ] Scale adjustment
- [ ] Test in-game: GUI works and saves settings?

**Day 4: Profile System (Optional)**
- [ ] Only add if needed for multi-character support
- [ ] Simple profile switching
- [ ] Copy/delete profiles
- [ ] Test in-game: Profiles work correctly?

**Day 5: Advanced Configuration**
- [ ] Only add features that users actually requested
- [ ] Color customization if needed
- [ ] Additional positioning options
- [ ] Test in-game: Advanced features work?

**PHASE 3 SUCCESS CRITERIA:**
- Users can customize core settings
- Settings save/load correctly
- Configuration is intuitive
- No configuration breaks existing functionality

---

## VALIDATION CHECKPOINTS

### AFTER EVERY FILE CREATION
**MANDATORY CHECKS:**
1. **File loads without errors** - Check for syntax errors
2. **File serves clear purpose** - Can explain why file exists
3. **File adds visible functionality** - User can see/interact with changes
4. **File integrates correctly** - Doesn't break existing features

**VALIDATION QUESTIONS:**
- What user-visible feature does this file enable?
- How would I demo this file's functionality to someone?
- What happens if I remove this file - does anything break that matters?

### AFTER EVERY MAJOR FEATURE
**MANDATORY TESTS:**
1. **Full addon reload** - Does everything still work?
2. **Combat testing** - Does UI work during combat?
3. **Performance check** - No frame rate drops?
4. **Integration testing** - Works with other addons?

**USER ACCEPTANCE CRITERIA:**
- Can a new user install and immediately see improvements?
- Are there any broken features or error messages?
- Does the addon do what it claims to do?

### WEEKLY VALIDATION GATES
**WEEK 1 GATE:** 
- Must have visible, functional unit frames before proceeding
- Health/power bars must update correctly
- No progression without working UI

**WEEK 2 GATE:**
- Must have working action buttons before adding configuration
- All keybinds must be functional
- No configuration work until actions work

**WEEK 3 GATE:**
- Must have core functionality complete before polish
- All user-requested features must work
- No new features until existing ones are solid

---

## LIBRARY USAGE RULES

### ACE3 LIBRARIES
**RULES:**
1. **Use standard names:** "AceAddon-3.0", "AceEvent-3.0", "AceDB-3.0"
2. **Simple patterns:** LibStub("AceAddon-3.0"):NewAddon("AddonName")
3. **Don't customize:** Use libraries as designed, don't modify

**CORRECT USAGE:**
```lua
local DamiaUI = LibStub("AceAddon-3.0"):NewAddon("DamiaUI", "AceEvent-3.0", "AceDB-3.0")

function DamiaUI:OnInitialize()
    -- Initialize saved variables
    self.db = LibStub("AceDB-3.0"):New("DamiaUIDB", defaults, true)
end

function DamiaUI:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_LOGIN")
end
```

### oUF FRAMEWORK
**RULES:**
1. **Must call CreateFrame()** - oUF doesn't create frames automatically
2. **Understand oUF is styling framework** - not frame creation framework  
3. **Start simple:** One frame type, basic styling, then expand

**CORRECT USAGE:**
```lua
local oUF = LibStub("oUF")

-- Style function - defines how frames look
local function Style(self, unit)
    -- Basic frame setup
    self:SetSize(200, 60)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints()
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.Health = health
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetSize(200, 20)
    power:SetPoint("TOP", health, "BOTTOM", 0, -2)
    power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.Power = power
end

-- Register the style
oUF:RegisterStyle("DamiaUI", Style)
oUF:SetActiveStyle("DamiaUI")

-- ACTUALLY CREATE FRAMES
local player = oUF:Spawn("player", "DamiaUIPlayer")
local target = oUF:Spawn("target", "DamiaUITarget")
```

### THIRD-PARTY LIBRARIES
**RULES:**
1. **Understand before using** - Create simple example first
2. **Use standard versions** - Don't modify library code
3. **Validate necessity** - Can you accomplish goal without library?

**EVALUATION CHECKLIST:**
- [ ] Can demonstrate library working in isolation
- [ ] Library solves specific problem you actually have
- [ ] Library is actively maintained and compatible with current WoW
- [ ] Library doesn't add more complexity than value

---

## RED FLAGS CHECKLIST

### IMMEDIATE STOP SIGNALS
**If you see these, STOP and reassess:**

**ARCHITECTURAL RED FLAGS:**
- [ ] Building "future-proof" architecture before current functionality works
- [ ] Creating more than 5 files before having working UI
- [ ] Renaming or customizing standard libraries
- [ ] Complex dependency injection systems for simple functionality
- [ ] Module loaders, event dispatchers, or framework code before UI

**DEVELOPMENT RED FLAGS:**
- [ ] Writing code for hours without testing in-game
- [ ] Building abstractions without concrete implementations
- [ ] Copying complex patterns from other addons without understanding
- [ ] Focus on code organization over functionality
- [ ] Testing implementation details instead of user features

**FEATURE RED FLAGS:**
- [ ] Complex configuration systems before basic functionality
- [ ] Enterprise-level command parsing for simple addons  
- [ ] Advanced features before core features work
- [ ] Building for theoretical users instead of actual needs
- [ ] Adding features that don't improve user experience

### RECOVERY ACTIONS
**When red flags detected:**

1. **IMMEDIATE STOP:** Stop all development
2. **ASSESS DAMAGE:** What actually works in-game?
3. **SIMPLIFY:** Remove all non-working complexity  
4. **RESTART:** Begin with single working frame
5. **VALIDATE:** Prove each step works before proceeding

---

## SUCCESS METRICS

### DAILY SUCCESS CRITERIA
**Each day must produce:**
- Visible change in-game UI
- Functional improvement user can interact with
- No regression in existing functionality
- Clear progress toward weekly goal

### WEEKLY SUCCESS CRITERIA
**Week 1:** Complete unit frames replacement
**Week 2:** Complete action bars replacement  
**Week 3:** Complete basic configuration

### PROJECT SUCCESS CRITERIA
**Must achieve ALL of these:**
- [ ] Replaces Blizzard UI with functional equivalent
- [ ] No errors in-game during normal use
- [ ] Performance acceptable (no frame rate impact)
- [ ] Users can install and use immediately
- [ ] Core functionality works in all game situations

### FAILURE RECOVERY
**If success criteria not met:**
1. **Immediate rollback** to last working state
2. **Identify root cause** of failure
3. **Simplify approach** - remove complexity
4. **Focus on basics** - get core working first
5. **Document lessons** - avoid repeating mistakes

---

## CONCLUSION

This roadmap represents the lessons learned from a complete project failure. The DamiaUI project created 131 files with zero working functionality because it violated every principle in this document.

**CORE PRINCIPLES SUMMARY:**
1. **Working code first** - no abstraction without implementation
2. **Standard libraries** - never rename or customize  
3. **User-visible features** - test what users see, not what code does
4. **Incremental complexity** - add features one at a time
5. **In-game validation** - test frequently in actual WoW environment

**REMEMBER:** 
- One working feature beats a hundred perfect abstractions
- Simple code that works beats complex code that doesn't
- User experience is the only thing that matters
- Build for today's needs, not theoretical future requirements

Follow this roadmap exactly to avoid repeating the failures that led to 131 files of non-functional code. Build working functionality first, then add complexity only when justified by actual needs.

**SUCCESS MANTRA:** 
*"Does it work in-game? Can the user see it and interact with it? If not, nothing else matters."*