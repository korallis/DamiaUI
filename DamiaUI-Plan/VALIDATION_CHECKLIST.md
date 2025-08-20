# DamiaUI Validation Checklist

This document provides comprehensive step-by-step validation procedures for each component of the DamiaUI addon. Follow this checklist to ensure every feature works correctly before moving to the next development phase.

## 1. Pre-Development Checklist

Before writing any code, validate your approach:

### [ ] Can I see this feature in-game right now?
- **Check**: Identify the default UI element you're replacing
- **Expected**: You can interact with and observe the current behavior
- **Command**: None required - visual inspection
- **If it fails**: Research the feature online or ask other players

### [ ] Do I have a working example to reference?
- **Check**: Find existing addon code or Blizzard UI code
- **Expected**: You have reference implementation to study
- **Command**: `/dump FrameName` for existing frames
- **If it fails**: Check other addons or WoW API documentation

### [ ] Am I using standard library names?
- **Check**: Verify all API calls exist in current WoW version
- **Expected**: No "attempt to call nil value" errors
- **Command**: `/dump APIFunctionName` to test existence
- **If it fails**: Check WoW API changes or use alternatives

### [ ] Have I tested the simplest version first?
- **Check**: Create minimal working version before adding features
- **Expected**: Basic functionality works without errors
- **Command**: Load minimal version and test core function
- **If it fails**: Simplify further until it works

## 2. Frame Creation Validation

For every new frame created:

### [ ] Frame visible with /framestack
- **Check**: Frame appears in framestack tool
- **Expected**: Frame listed with correct parent hierarchy
- **Command**: `/framestack` then mouseover your frame
- **If it fails**: Check frame creation code and SetParent calls

### [ ] Frame responds to Show/Hide
- **Check**: Frame visibility can be controlled programmatically
- **Expected**: Frame disappears/reappears correctly
- **Command**: `/run YourFrame:Hide()` then `/run YourFrame:Show()`
- **If it fails**: Check frame anchoring and parent relationships

### [ ] Updates when relevant data changes
- **Check**: Frame content changes when underlying data changes
- **Expected**: Real-time updates without manual refresh
- **Command**: Trigger the data change event naturally in-game
- **If it fails**: Check event registration and update functions

### [ ] Survives /reload
- **Check**: Frame appears correctly after UI reload
- **Expected**: Frame in same position with correct data
- **Command**: `/reload` then check frame state
- **If it fails**: Check saved variables and initialization code

## 3. Event System Validation

For every event handler registered:

### [ ] Events fire when expected
- **Check**: Event handlers execute at the right time
- **Expected**: Handler code runs when event occurs
- **Command**: Add debug prints to handlers, trigger events
- **If it fails**: Check event name spelling and registration

### [ ] Updates happen in real-time
- **Check**: UI updates immediately when events fire
- **Expected**: No delay between event and UI update
- **Command**: Trigger event and observe immediate UI change
- **If it fails**: Check event handler logic and frame update code

### [ ] No errors in BugSack
- **Check**: Event handlers don't generate Lua errors
- **Expected**: BugSack remains empty during normal play
- **Command**: Install BugSack addon, play normally for 10 minutes
- **If it fails**: Fix the Lua errors before proceeding

### [ ] No combat lockdown taints
- **Check**: Secure frames remain untainted during combat
- **Expected**: No "Interface action failed because of an AddOn" messages
- **Command**: Enter combat, use abilities, check for taint messages
- **If it fails**: Review secure frame handling and combat restrictions

## 4. Slash Command Validation

For every slash command implemented:

### [ ] Command recognized immediately
- **Check**: Command works right after registration
- **Expected**: No "Unknown command" message
- **Command**: Type your slash command immediately after loading
- **If it fails**: Check SlashCmdList registration syntax

### [ ] No "unknown command" errors
- **Check**: All command variations work correctly
- **Expected**: Proper response for valid and invalid syntax
- **Command**: Test all subcommands and invalid inputs
- **If it fails**: Add proper error handling and help text

### [ ] Works after /reload
- **Check**: Commands persist through UI reloads
- **Expected**: All commands function normally after reload
- **Command**: `/reload` then test all slash commands
- **If it fails**: Check command registration in initialization code

### [ ] All subcommands function
- **Check**: Every documented subcommand works
- **Expected**: Each subcommand produces expected result
- **Command**: Test each subcommand individually
- **If it fails**: Debug specific subcommand logic

## 5. Action Bar Validation

For action bar implementations:

### [ ] Buttons clickable
- **Check**: Mouse clicks register on action buttons
- **Expected**: Click events fire correctly
- **Command**: Click each button and verify response
- **If it fails**: Check button frame setup and click handlers

### [ ] Keybindings work
- **Check**: Keyboard shortcuts trigger correct actions
- **Expected**: Key presses activate bound abilities
- **Command**: Test all bound keys while targeting different things
- **If it fails**: Check keybinding registration and secure templates

### [ ] Spells cast properly
- **Check**: Clicking buttons casts the intended spells
- **Expected**: Spell casting animation and effects occur
- **Command**: Click spell buttons with valid targets
- **If it fails**: Check spell ID accuracy and secure action handling

### [ ] Updates on spell changes
- **Check**: Buttons update when spells change (cooldowns, availability)
- **Expected**: Visual state matches actual spell state
- **Command**: Cast spells and watch cooldown animations
- **If it fails**: Check event registration for spell state changes

## 6. Performance Validation

Monitor performance impact:

### [ ] FPS remains stable
- **Check**: Frame rate doesn't drop with addon active
- **Expected**: Less than 5% FPS impact
- **Command**: `/run print(GetFramerate())` before and after loading
- **If it fails**: Profile code for expensive operations

### [ ] Memory usage reasonable
- **Check**: Addon doesn't consume excessive memory
- **Expected**: Less than 10MB for basic functionality
- **Command**: `/run print(GetAddOnMemoryUsage("DamiaUI"))` after 30min play
- **If it fails**: Look for memory leaks and unnecessary data storage

### [ ] No excessive garbage collection
- **Check**: Addon doesn't create excessive temporary objects
- **Expected**: Stable memory usage over time
- **Command**: Monitor memory usage over 1 hour of play
- **If it fails**: Reduce object creation in frequently called functions

### [ ] CPU usage under 1%
- **Check**: Addon doesn't consume significant processing power
- **Expected**: Minimal CPU impact during normal play
- **Command**: Use CPU profiling addons to measure impact
- **If it fails**: Optimize expensive calculations and reduce update frequency

## 7. Integration Testing

Test compatibility and robustness:

### [ ] Works with other addons
- **Check**: No conflicts with popular addons
- **Expected**: Normal functionality with common addon combinations
- **Command**: Test with DBM, WeakAuras, Details, ElvUI
- **If it fails**: Identify specific conflicts and implement workarounds

### [ ] Survives combat
- **Check**: Addon functions normally during combat
- **Expected**: No errors or taint issues during fights
- **Command**: Enter combat, use all addon features
- **If it fails**: Review secure frame usage and combat restrictions

### [ ] Handles loading screens
- **Check**: Addon state preserved across zone changes
- **Expected**: Frames and data intact after loading screens
- **Command**: Travel between zones and check addon state
- **If it fails**: Check event handling for ADDON_LOADED and similar

### [ ] Works in instances
- **Check**: Full functionality in dungeons and raids
- **Expected**: No errors in group content
- **Command**: Enter dungeon/raid and test all features
- **If it fails**: Check for instance-specific restrictions or events

## Validation Workflow

Follow this sequence for each new feature:

1. **Complete Pre-Development Checklist** - Don't code until all items pass
2. **Create minimal implementation** - Simplest possible working version
3. **Run Frame Creation Validation** - Ensure basic display works
4. **Add event handling** - Run Event System Validation
5. **Implement user interactions** - Run relevant validation sections
6. **Performance test** - Run Performance Validation
7. **Integration test** - Run Integration Testing
8. **Document** - Only after everything passes validation

## Debugging Tools

Essential tools for validation:

- **BugSack**: Catches Lua errors
- **FrameStack**: Identifies frame hierarchy
- **EventTrace**: Monitors event firing
- **cpuusage**: Profiles addon performance
- **WeakAuras**: Can be used to monitor custom events

## Common Failure Patterns

If validation fails, check these common issues:

1. **Typos in API function names** - Case sensitivity matters
2. **Incorrect event names** - Check spelling exactly
3. **Missing parent frames** - Frames need proper parents
4. **Combat taint** - Secure frames have strict rules
5. **Memory leaks** - Unregistered event handlers accumulate
6. **Race conditions** - Events may fire before initialization

## Success Criteria

A feature is ready for the next phase when:
- All relevant checklist items pass
- No errors in BugSack after 30 minutes of play
- Performance impact is minimal
- Works with other addons
- Survives combat and loading screens

**Remember**: It's better to have one perfectly working feature than ten broken ones. Complete validation before moving forward.