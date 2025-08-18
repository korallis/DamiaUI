# WoW Global Functions API Documentation

This document provides comprehensive documentation of global functions available in the World of Warcraft API.

## Table of Contents
1. [Unit Functions](#unit-functions)
2. [Combat Functions](#combat-functions)
3. [Spell Functions](#spell-functions)
4. [Item Functions](#item-functions)
5. [UI Functions](#ui-functions)
6. [System Functions](#system-functions)

---

## Unit Functions

### UnitName
Returns the name of the specified unit.
```lua
name, realm = UnitName(unit)
```
- **Parameters:**
  - `unit` (string): Unit token (e.g., "player", "target", "party1")
- **Returns:**
  - `name` (string): Unit's name
  - `realm` (string|nil): Unit's realm (nil if same realm)

### UnitHealth
Returns the current health of a unit.
```lua
health = UnitHealth(unit [, usePredicted])
```
- **Parameters:**
  - `unit` (string): Unit token
  - `usePredicted` (boolean): Use predicted health value (default: true)
- **Returns:**
  - `health` (number): Current health value

### UnitHealthMax
Returns the maximum health of a unit.
```lua
maxHealth = UnitHealthMax(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `maxHealth` (number): Maximum health value

### UnitPower
Returns the current power (mana/rage/energy/etc) of a unit.
```lua
power = UnitPower(unit [, powerType] [, unmodified])
```
- **Parameters:**
  - `unit` (string): Unit token
  - `powerType` (number|Enum.PowerType): Power type to query (default: unit's current power type)
  - `unmodified` (boolean): Return unmodified value (default: false)
- **Returns:**
  - `power` (number): Current power value

### UnitPowerMax
Returns the maximum power of a unit.
```lua
maxPower = UnitPowerMax(unit [, powerType] [, unmodified])
```
- **Parameters:**
  - `unit` (string): Unit token
  - `powerType` (number|Enum.PowerType): Power type to query
  - `unmodified` (boolean): Return unmodified value
- **Returns:**
  - `maxPower` (number): Maximum power value

### UnitPowerType
Returns information about a unit's current power type.
```lua
powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `powerType` (number): Power type index
  - `powerToken` (string): Power type token (e.g., "MANA", "RAGE")
  - `altR` (number): Red color component for power color
  - `altG` (number): Green color component for power color
  - `altB` (number): Blue color component for power color

### UnitClass
Returns class information for a unit.
```lua
className, classFilename, classId = UnitClass(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `className` (string): Localized class name
  - `classFilename` (string): Non-localized class token (e.g., "WARRIOR")
  - `classId` (number): Numeric class ID

### UnitRace
Returns race information for a unit.
```lua
raceName, raceFile, raceID = UnitRace(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `raceName` (string): Localized race name
  - `raceFile` (string): Non-localized race token
  - `raceID` (number): Numeric race ID

### UnitLevel
Returns the level of a unit.
```lua
level = UnitLevel(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `level` (number): Unit's level (-1 if level is too high to determine)

### UnitExists
Checks if a unit exists.
```lua
exists = UnitExists(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `exists` (boolean): True if unit exists

### UnitIsPlayer
Checks if a unit is a player (not an NPC).
```lua
isPlayer = UnitIsPlayer(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isPlayer` (boolean): True if unit is a player

### UnitIsDead
Checks if a unit is dead.
```lua
isDead = UnitIsDead(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isDead` (boolean): True if unit is dead

### UnitIsGhost
Checks if a unit is a ghost.
```lua
isGhost = UnitIsGhost(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isGhost` (boolean): True if unit is a ghost

### UnitIsConnected
Checks if a unit (player) is connected.
```lua
isConnected = UnitIsConnected(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isConnected` (boolean): True if connected

### UnitIsAFK
Checks if a unit is AFK.
```lua
isAFK = UnitIsAFK(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isAFK` (boolean): True if AFK

### UnitIsDND
Checks if a unit is in Do Not Disturb mode.
```lua
isDND = UnitIsDND(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `isDND` (boolean): True if DND

### UnitGUID
Returns the GUID of a unit.
```lua
guid = UnitGUID(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `guid` (string): Unit's globally unique identifier

### UnitInRange
Checks if a unit is in range.
```lua
inRange = UnitInRange(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `inRange` (boolean|nil): True if in range, false if not, nil if unknown

### UnitInParty
Checks if a unit is in your party.
```lua
inParty = UnitInParty(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `inParty` (boolean): True if in party

### UnitInRaid
Checks if a unit is in your raid.
```lua
inRaid = UnitInRaid(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `inRaid` (boolean): True if in raid

---

## Combat Functions

### UnitAffectingCombat
Checks if a unit is affecting combat (in combat).
```lua
inCombat = UnitAffectingCombat(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `inCombat` (boolean): True if unit is in combat

### UnitAttackPower
Returns the unit's attack power.
```lua
base, posBuff, negBuff = UnitAttackPower(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `base` (number): Base attack power
  - `posBuff` (number): Positive buffs to attack power
  - `negBuff` (number): Negative buffs to attack power

### UnitAttackSpeed
Returns the unit's attack speed.
```lua
mainSpeed, offSpeed = UnitAttackSpeed(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `mainSpeed` (number): Main hand attack speed in seconds
  - `offSpeed` (number|nil): Off hand attack speed in seconds

### UnitDamage
Returns damage information for a unit.
```lua
minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `minDamage` (number): Minimum main hand damage
  - `maxDamage` (number): Maximum main hand damage
  - `minOffHandDamage` (number): Minimum off hand damage
  - `maxOffHandDamage` (number): Maximum off hand damage
  - `physicalBonusPos` (number): Positive physical bonus
  - `physicalBonusNeg` (number): Negative physical bonus
  - `percent` (number): Damage modifier percentage

### UnitRangedAttackPower
Returns the unit's ranged attack power.
```lua
base, posBuff, negBuff = UnitRangedAttackPower(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `base` (number): Base ranged attack power
  - `posBuff` (number): Positive buffs
  - `negBuff` (number): Negative buffs

### UnitSpellHaste
Returns the unit's spell haste percentage.
```lua
haste = UnitSpellHaste(unit)
```
- **Parameters:**
  - `unit` (string): Unit token
- **Returns:**
  - `haste` (number): Spell haste percentage

---

## Spell Functions

### GetSpellInfo (Classic/Pre-11.0)
Returns information about a spell.
```lua
name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spell)
```
- **Parameters:**
  - `spell` (number|string): Spell ID or name
- **Returns:**
  - `name` (string): Spell name
  - `rank` (string): Spell rank (removed in later versions)
  - `icon` (number): Icon texture ID
  - `castTime` (number): Cast time in milliseconds
  - `minRange` (number): Minimum range
  - `maxRange` (number): Maximum range
  - `spellID` (number): Spell ID

### GetSpellCooldown
Returns cooldown information for a spell.
```lua
start, duration, enabled, modRate = GetSpellCooldown(spell)
```
- **Parameters:**
  - `spell` (number|string): Spell ID or name
- **Returns:**
  - `start` (number): Cooldown start time (GetTime() based)
  - `duration` (number): Cooldown duration in seconds
  - `enabled` (number): 1 if cooldown is enabled
  - `modRate` (number): Cooldown rate modifier

### IsSpellKnown
Checks if a spell is known.
```lua
isKnown = IsSpellKnown(spellID [, isPet])
```
- **Parameters:**
  - `spellID` (number): Spell ID
  - `isPet` (boolean): Check pet spells (default: false)
- **Returns:**
  - `isKnown` (boolean): True if spell is known

### IsUsableSpell
Checks if a spell is currently usable.
```lua
usable, noMana = IsUsableSpell(spell)
```
- **Parameters:**
  - `spell` (number|string): Spell ID or name
- **Returns:**
  - `usable` (boolean): True if spell can be cast
  - `noMana` (boolean): True if only reason spell can't be cast is insufficient resources

### GetSpellCharges
Returns charge information for a spell.
```lua
currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)
```
- **Parameters:**
  - `spell` (number|string): Spell ID or name
- **Returns:**
  - `currentCharges` (number): Current charges available
  - `maxCharges` (number): Maximum charges
  - `cooldownStart` (number): When cooldown started
  - `cooldownDuration` (number): Cooldown duration
  - `chargeModRate` (number): Charge rate modifier

---

## Item Functions

### GetItemInfo
Returns information about an item.
```lua
name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(item)
```
- **Parameters:**
  - `item` (number|string): Item ID, name, or link
- **Returns:**
  - `name` (string): Item name
  - `link` (string): Item link
  - `quality` (number): Item quality (0-7)
  - `iLevel` (number): Item level
  - `reqLevel` (number): Required level
  - `class` (string): Item class
  - `subclass` (string): Item subclass
  - `maxStack` (number): Maximum stack size
  - `equipSlot` (string): Equipment slot
  - `texture` (number): Icon texture ID
  - `vendorPrice` (number): Vendor sell price in copper

### GetItemCount
Returns the number of an item in bags.
```lua
count = GetItemCount(item [, includeBank] [, includeCharges])
```
- **Parameters:**
  - `item` (number|string): Item ID or name
  - `includeBank` (boolean): Include bank items
  - `includeCharges` (boolean): Include charges
- **Returns:**
  - `count` (number): Item count

### GetInventoryItemID
Returns the item ID of an equipped item.
```lua
itemID = GetInventoryItemID(unit, slot)
```
- **Parameters:**
  - `unit` (string): Unit token (usually "player")
  - `slot` (number): Inventory slot ID
- **Returns:**
  - `itemID` (number): Item ID

### GetInventoryItemLink
Returns the item link of an equipped item.
```lua
itemLink = GetInventoryItemLink(unit, slot)
```
- **Parameters:**
  - `unit` (string): Unit token
  - `slot` (number): Inventory slot ID
- **Returns:**
  - `itemLink` (string): Item link

### UseInventoryItem
Uses an equipped item.
```lua
UseInventoryItem(slot)
```
- **Parameters:**
  - `slot` (number): Inventory slot ID

### UseItemByName
Uses an item by name.
```lua
UseItemByName(item [, target])
```
- **Parameters:**
  - `item` (string): Item name
  - `target` (string): Unit token to target

---

## UI Functions

### CreateFrame
Creates a new frame.
```lua
frame = CreateFrame(frameType [, name] [, parent] [, template] [, id])
```
- **Parameters:**
  - `frameType` (string): Type of frame (e.g., "Frame", "Button")
  - `name` (string): Global name for the frame
  - `parent` (Frame): Parent frame
  - `template` (string): Template to inherit from
  - `id` (number): ID number
- **Returns:**
  - `frame` (Frame): The created frame

### GetCursorPosition
Returns the cursor's position.
```lua
x, y = GetCursorPosition()
```
- **Returns:**
  - `x` (number): X coordinate
  - `y` (number): Y coordinate

### PlaySound
Plays a sound.
```lua
willPlay, soundHandle = PlaySound(soundKitID [, channel] [, forceNoDuplicates] [, runFinishCallback])
```
- **Parameters:**
  - `soundKitID` (number): Sound kit ID
  - `channel` (string): Audio channel
  - `forceNoDuplicates` (boolean): Prevent duplicate sounds
  - `runFinishCallback` (boolean): Run callback when finished
- **Returns:**
  - `willPlay` (boolean): True if sound will play
  - `soundHandle` (number): Handle to the sound

### print
Prints a message to the chat frame.
```lua
print(...)
```
- **Parameters:**
  - `...` (any): Values to print

### message
Displays a message dialog.
```lua
message(text)
```
- **Parameters:**
  - `text` (string): Message to display

---

## System Functions

### GetBuildInfo
Returns information about the game client.
```lua
version, build, date, tocversion = GetBuildInfo()
```
- **Returns:**
  - `version` (string): Version string (e.g., "10.2.5")
  - `build` (string): Build number
  - `date` (string): Build date
  - `tocversion` (number): TOC version number

### GetLocale
Returns the client's locale.
```lua
locale = GetLocale()
```
- **Returns:**
  - `locale` (string): Locale code (e.g., "enUS", "deDE")

### GetTime
Returns the system uptime in seconds.
```lua
time = GetTime()
```
- **Returns:**
  - `time` (number): Time in seconds since client started

### GetServerTime
Returns the server time.
```lua
serverTime = GetServerTime()
```
- **Returns:**
  - `serverTime` (number): Unix timestamp of server time

### GetFramerate
Returns the current framerate.
```lua
fps = GetFramerate()
```
- **Returns:**
  - `fps` (number): Current frames per second

### GetAddOnInfo
Returns information about an addon.
```lua
name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
```
- **Parameters:**
  - `index` (number|string): Addon index or name
- **Returns:**
  - `name` (string): Addon name
  - `title` (string): Addon title
  - `notes` (string): Addon notes
  - `loadable` (boolean): Can be loaded
  - `reason` (string): Reason if not loadable
  - `security` (string): Security status
  - `newVersion` (boolean): Has new version

### GetAddOnMetadata
Returns metadata for an addon.
```lua
value = GetAddOnMetadata(addon, field)
```
- **Parameters:**
  - `addon` (number|string): Addon index or name
  - `field` (string): Metadata field name
- **Returns:**
  - `value` (string): Metadata value

### IsAddOnLoaded
Checks if an addon is loaded.
```lua
loaded = IsAddOnLoaded(addon)
```
- **Parameters:**
  - `addon` (number|string): Addon index or name
- **Returns:**
  - `loaded` (boolean): True if loaded

### LoadAddOn
Loads an addon.
```lua
loaded, reason = LoadAddOn(addon)
```
- **Parameters:**
  - `addon` (number|string): Addon index or name
- **Returns:**
  - `loaded` (boolean): True if loaded successfully
  - `reason` (string): Reason if failed

### ReloadUI
Reloads the user interface.
```lua
ReloadUI()
```

### InCombatLockdown
Checks if in combat lockdown.
```lua
inCombat = InCombatLockdown()
```
- **Returns:**
  - `inCombat` (boolean): True if in combat lockdown

---

## Unit Tokens

Common unit tokens used throughout the API:

- `"player"` - The player
- `"target"` - Player's target
- `"focus"` - Player's focus target
- `"pet"` - Player's pet
- `"vehicle"` - Player's vehicle
- `"party1"` to `"party4"` - Party members
- `"raid1"` to `"raid40"` - Raid members
- `"boss1"` to `"boss8"` - Boss frames
- `"arena1"` to `"arena5"` - Arena opponents
- `"mouseover"` - Unit under mouse cursor
- `"none"` - No unit
- `"npc"` - NPC interact target

### Unit Token Modifiers

You can append modifiers to unit tokens:

- `"playertarget"` - Player's target
- `"playerpet"` - Player's pet
- `"party1target"` - Party member 1's target
- `"raid1target"` - Raid member 1's target
- `"focustarget"` - Focus's target
- `"targettarget"` - Target's target
- `"pettarget"` - Pet's target

---

## Power Types

Power type enumerations used in power-related functions:

- `0` or `Enum.PowerType.Mana` - Mana
- `1` or `Enum.PowerType.Rage` - Rage
- `2` or `Enum.PowerType.Focus` - Focus
- `3` or `Enum.PowerType.Energy` - Energy
- `4` or `Enum.PowerType.ComboPoints` - Combo Points
- `5` or `Enum.PowerType.Runes` - Runes (Death Knight)
- `6` or `Enum.PowerType.RunicPower` - Runic Power
- `7` or `Enum.PowerType.SoulShards` - Soul Shards
- `8` or `Enum.PowerType.LunarPower` - Lunar Power
- `9` or `Enum.PowerType.HolyPower` - Holy Power
- `11` or `Enum.PowerType.Maelstrom` - Maelstrom
- `12` or `Enum.PowerType.Chi` - Chi
- `13` or `Enum.PowerType.Insanity` - Insanity
- `16` or `Enum.PowerType.ArcaneCharges` - Arcane Charges
- `17` or `Enum.PowerType.Fury` - Fury (Demon Hunter)
- `18` or `Enum.PowerType.Pain` - Pain (Demon Hunter)

---

## Notes

1. Many functions may return `nil` if the information is not available
2. Protected functions can only be called from secure code (not during combat for some functions)
3. Some functions are deprecated in newer versions - always check the current API documentation
4. Function availability may vary between game versions (Retail, Classic, etc.)