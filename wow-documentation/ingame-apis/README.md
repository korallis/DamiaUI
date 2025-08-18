# World of Warcraft In-Game API Documentation

This directory contains comprehensive documentation of the World of Warcraft API, compiled from official sources including the Blizzard API Documentation and the WoW Wiki.

## Version Information
- **Current as of:** Patch 11.2.0 (Build 62253)
- **Last Updated:** December 2024
- **Source:** Official Blizzard API Documentation & WoW Wiki

## Documentation Structure

### Core API Categories

1. **[Global Functions](./GlobalFunctions.md)** - Core WoW API functions available globally
2. **[Widget API](./WidgetAPI.md)** - UI element methods and properties
3. **[Events](./Events.md)** - Game events that addons can listen to
4. **[CVars](./CVars.md)** - Console variables for game configuration
5. **[Enumerations](./Enumerations.md)** - Constants and enums used throughout the API
6. **[Structures](./Structures.md)** - Data structures returned by API functions

### Namespaced APIs (C_*)

The modern WoW API uses namespaced functions under the C_* prefix. These are organized by functionality:

#### Account & Character
- **[C_AccountInfo](./namespaces/C_AccountInfo.md)** - Account-level information
- **[C_CharacterServices](./namespaces/C_CharacterServices.md)** - Character services
- **[C_PlayerInfo](./namespaces/C_PlayerInfo.md)** - Player character information
- **[C_SpecializationInfo](./namespaces/C_SpecializationInfo.md)** - Specialization data

#### Combat & Gameplay
- **[C_AzeriteItem](./namespaces/C_AzeriteItem.md)** - Azerite item system
- **[C_ClassTalents](./namespaces/C_ClassTalents.md)** - Talent system
- **[C_Spell](./namespaces/C_Spell.md)** - Spell information and casting
- **[C_UnitAuras](./namespaces/C_UnitAuras.md)** - Buff/debuff management

#### Economy & Items
- **[C_AuctionHouse](./namespaces/C_AuctionHouse.md)** - Auction house interface
- **[C_Bank](./namespaces/C_Bank.md)** - Bank operations
- **[C_Item](./namespaces/C_Item.md)** - Item information
- **[C_TradeSkillUI](./namespaces/C_TradeSkillUI.md)** - Professions interface

#### Social & Community
- **[C_BattleNet](./namespaces/C_BattleNet.md)** - Battle.net integration
- **[C_Calendar](./namespaces/C_Calendar.md)** - In-game calendar
- **[C_GuildInfo](./namespaces/C_GuildInfo.md)** - Guild management
- **[C_PartyInfo](./namespaces/C_PartyInfo.md)** - Party and raid management

#### UI & Interface
- **[C_ActionBar](./namespaces/C_ActionBar.md)** - Action bar customization
- **[C_AddOns](./namespaces/C_AddOns.md)** - Addon management
- **[C_EditMode](./namespaces/C_EditMode.md)** - Edit mode interface
- **[C_UI](./namespaces/C_UI.md)** - General UI functions

#### World & Environment
- **[C_Map](./namespaces/C_Map.md)** - Map interface
- **[C_QuestLog](./namespaces/C_QuestLog.md)** - Quest tracking
- **[C_Scenario](./namespaces/C_Scenario.md)** - Scenario information
- **[C_WorldMap](./namespaces/C_WorldMap.md)** - World map interface

## Version Compatibility

### Retail (Mainline)
- Full API support including latest features
- All C_* namespaced functions available
- Modern UI systems (Edit Mode, etc.)

### Classic Era
- Limited API subset
- No C_* namespaced functions in early versions
- Traditional UI systems only

### Wrath Classic
- Partial C_* namespace support
- Most Wrath-era features available
- Limited modern UI features

### Cataclysm Classic
- Extended C_* namespace support
- Most Cata-era features available
- Some modern UI backports

## Common API Patterns

### Event Registration
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Handle login
    end
end)
```

### Secure Actions
```lua
local button = CreateFrame("Button", "MyButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "action")
button:SetAttribute("action", 1)
```

### Unit Information
```lua
local name = UnitName("player")
local health = UnitHealth("player")
local maxHealth = UnitHealthMax("player")
```

## Important Notes

1. **Protected Functions**: Many combat-related functions are protected and can only be called from secure code
2. **Taint System**: Be careful not to taint the global namespace or Blizzard UI
3. **Version Checking**: Always check API availability when supporting multiple WoW versions
4. **Deprecation**: APIs may be deprecated between patches, always check patch notes

## Resources

- [Official WoW API Documentation](https://github.com/Gethe/wow-ui-source)
- [WoW Wiki API Reference](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [WoWPedia API Reference](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)

## Contributing

This documentation is maintained for the DamiaUI project. Updates should be made when new patches introduce API changes or when errors are discovered.