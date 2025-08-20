# How to Fix DamiaUI's Library Problems

## The Core Problem
DamiaUI renamed all libraries with "DamiaUI_" prefix, breaking EVERYTHING.

## Why This Breaks Everything

### Example: oUF Library Chain
When oUF loads, it does this internally:
```lua
-- Inside oUF's code:
local oUF = LibStub("oUF")  -- It looks for "oUF", not "DamiaUI_oUF"
```

When you rename it to "DamiaUI_oUF", oUF can't find itself!

### Example: Ace3 Dependencies
AceConfig depends on AceGUI:
```lua
-- Inside AceConfig:
local AceGUI = LibStub("AceGUI-3.0")  -- Fails! Can't find "DamiaUI_AceGUI-3.0"
```

## THE FIX: Use Standard Library Names

### Step 1: Fix the .toc Files
Change all library .toc files back to standard names:

**WRONG:**
```
Libraries/DamiaUI_oUF/oUF.xml
Libraries/DamiaUI_Ace3/AceAddon-3.0/AceAddon-3.0.xml
```

**CORRECT:**
```
Libraries/oUF/oUF.xml
Libraries/Ace3/AceAddon-3.0/AceAddon-3.0.xml
```

### Step 2: Fix LibStub Registration
In each library's main file:

**WRONG:**
```lua
local lib = LibStub:NewLibrary("DamiaUI_oUF", version)
```

**CORRECT:**
```lua
local lib = LibStub:NewLibrary("oUF", version)
```

### Step 3: Fix Your Code's LibStub Calls

**WRONG:**
```lua
local oUF = LibStub("DamiaUI_oUF")
local AceAddon = LibStub("DamiaUI_AceAddon-3.0")
```

**CORRECT:**
```lua
local oUF = LibStub("oUF")
local AceAddon = LibStub("AceAddon-3.0")
```

## Alternative: Embedded Libraries (How ElvUI Does It)

Instead of renaming, ElvUI embeds libraries in their namespace:

```lua
-- ElvUI's approach
local E, L, V, P, G = unpack(select(2, ...))
E.Libs = {}
E.LibsMinor = {}

-- Load libraries but store references
E.Libs["AceAddon"] = LibStub("AceAddon-3.0")
E.Libs["AceDB"] = LibStub("AceDB-3.0")

-- They still use STANDARD names with LibStub!
```

## Why Standard Names Matter

1. **Libraries reference each other** - They expect standard names
2. **Version checking** - LibStub manages versions by name
3. **Other addons** - May share the same libraries
4. **Documentation** - All docs use standard names

## Quick Fix Script

Run this to fix all library references:

```bash
# In your addon directory
find . -name "*.lua" -o -name "*.xml" -o -name "*.toc" | xargs sed -i '' 's/DamiaUI_oUF/oUF/g'
find . -name "*.lua" -o -name "*.xml" -o -name "*.toc" | xargs sed -i '' 's/DamiaUI_AceAddon-3.0/AceAddon-3.0/g'
find . -name "*.lua" -o -name "*.xml" -o -name "*.toc" | xargs sed -i '' 's/DamiaUI_AceConfig-3.0/AceConfig-3.0/g'
# ... repeat for all libraries
```

## The Nuclear Option: Remove All Libraries

If fixing is too complex, just start simple:

```lua
-- No libraries needed for basic functionality!
local frame = CreateFrame("Frame", "MyFrame", UIParent)
frame:SetSize(200, 100)
frame:SetPoint("CENTER")
-- This works without ANY libraries!
```

## Testing Your Fix

1. Check if libraries load:
```lua
/run print(LibStub("oUF") and "oUF loaded" or "oUF FAILED")
/run print(LibStub("AceAddon-3.0") and "Ace loaded" or "Ace FAILED")
```

2. Check dependencies:
```lua
/run for name,lib in pairs(LibStub.libs) do print(name) end
```

## Common Library Names (NEVER CHANGE THESE)

- `LibStub`
- `CallbackHandler-1.0`
- `AceAddon-3.0`
- `AceConfig-3.0`
- `AceConsole-3.0`
- `AceDB-3.0`
- `AceDBOptions-3.0`
- `AceEvent-3.0`
- `AceGUI-3.0`
- `AceLocale-3.0`
- `AceTimer-3.0`
- `oUF`
- `LibActionButton-1.0`
- `LibDataBroker-1.1`

## Remember

**NEVER rename libraries. EVER.**

If you need namespace isolation, use Lua tables:
```lua
local MyAddon = {}
MyAddon.Libs = {
    AceAddon = LibStub("AceAddon-3.0"),  -- Standard name!
    oUF = LibStub("oUF"),                -- Standard name!
}
```

The libraries keep their standard names, you just store references in your namespace.