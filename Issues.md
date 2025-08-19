2x DamiaUI/Core/Engine.lua:406: Usage: New(tbl, defaults, defaultProfile)
[FIXED] Issue: AceDB:New was being called with incorrect parameters
- Cause: I was passing a string "DamiaUIDB" instead of the actual saved variables table
- Why Missed: I didn't understand that this modified version of AceDB expects the actual table reference, not the string name like standard AceDB
- Root Problem: Failed to understand the difference between standard AceDB (expects string) and this modified version (expects table)
- Fix: Changed from passing "DamiaUIDB" string to passing _G.DamiaUIDB table reference, with initialization check
[DamiaUI/Libraries/DamiaUI_Ace3/AceAddon-3.0/AceAddon-3.0.lua]:98: in function <...Libraries/DamiaUI_Ace3/AceAddon-3.0/AceAddon-3.0.lua:96>

Locals:
frame = DamiaUI_AceAddon30Frame {
}
event = "ADDON_LOADED"
events = <table> {
}
AceAddon = <table> {
 embeds = <table> {
 }
 addons = <table> {
 }
 mixins = <table> {
 }
 initializequeue = <table> {
 }
 mixinTargets = <table> {
 }
 enablequeue = <table> {
 }
 frame = DamiaUI_AceAddon30Frame {
 }
 statuses = <table> {
 }
}

## SUMMARY

### Root Cause:
I was passing parameters to AceDB:New incorrectly. The standard AceDB library expects the saved variable NAME as a string, but this modified/namespaced version expects the actual TABLE reference.

### Why This Happened:
1. I assumed all AceDB implementations work the same way
2. I didn't check the actual code to see what parameters were expected
3. I passed a string "DamiaUIDB" when it needed the global table _G.DamiaUIDB

### Key Lesson:
Always verify the actual implementation when using modified or namespaced libraries. Don't assume they work exactly like the standard versions. The error message clearly stated it expected a table, not a string - I should have paid attention to that.

### The Fix:
```lua
-- WRONG: Passing string name
self.db = AceDB:New("DamiaUIDB", defaults, true)

-- CORRECT: Passing actual table reference
if not _G.DamiaUIDB then
    _G.DamiaUIDB = {}
end
self.db = AceDB:New(_G.DamiaUIDB, defaults, true)
```

This ensures the saved variables table exists and passes the correct reference to AceDB.
