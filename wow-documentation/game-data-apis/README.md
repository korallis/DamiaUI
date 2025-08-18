# World of Warcraft Game Data APIs

This directory contains documentation for all World of Warcraft Game Data APIs fetched from the official Battle.net API.

## API Categories

### Achievement APIs
- [Achievement Categories Index](achievement-categories-index.md)
- [Achievements Index](achievements-index.md)

### Auction House API
- [Auction House Data](auction-house.md)

### Connected Realm API
- [Connected Realms Index](connected-realms-index.md)

### Covenant API
- [Covenants Index](covenants-index.md)

### Creature API
- [Creature Families](creature-families.md)
- [Creature Types](creature-types.md)

### Guild Crest API
- [Guild Crests](guild-crests.md)

### Item API
- [Item Classes](item-classes.md)

### Journal API
- [Journal Expansions](journal-expansions.md)
- [Journal Encounters](journal-encounters.md)
- [Journal Instances](journal-instances.md)

### Media API
- [Creature Display Media](media-creature-display.md)
- [Item Media](media-item.md)

### Mount API
- [Mounts Index](mounts-index.md)

### Mythic Keystone API
- [Mythic Keystone Index](mythic-keystone-index.md)
- [Mythic Keystone Dungeons](mythic-keystone-dungeons.md)
- [Mythic Keystone Periods](mythic-keystone-periods.md)
- [Mythic Keystone Seasons](mythic-keystone-seasons.md)

### Mythic Keystone Leaderboard API
- [Mythic Keystone Leaderboard Index](mythic-leaderboard-index.md)

### Mythic Raid Leaderboard API
- [Mythic Raid Leaderboard](mythic-raid-leaderboard.md)

### Pet API
- [Pets Index](pets-index.md)

### Playable Class API
- [Playable Classes](playable-classes.md)
- [Playable Class - Shaman](playable-class-shaman.md)

### Playable Race API
- [Playable Races](playable-races.md)

### Playable Specialization API
- [Playable Specializations](playable-specializations.md)
- [Playable Specialization - Elemental](playable-spec-elemental.md)

### Power Type API
- [Power Types](power-types.md)

### Profession API
- [Professions Index](professions-index.md)

### PvP Season API
- [PvP Seasons Index](pvp-seasons-index.md)
- [PvP Season 27](pvp-season-27.md)

### PvP Leaderboards API
- [PvP Leaderboards Index](pvp-leaderboards-index.md)
- [PvP Leaderboard 3v3](pvp-leaderboard-3v3.md)

### PvP Rewards API
- [PvP Rewards Index](pvp-rewards.md)

### Quest API
- [Quests Index](quests-index.md)
- [Quest Areas](quest-areas.md)
- [Quest Categories](quest-categories.md)
- [Quest Types](quest-types.md)

### Realm API
- [Realms Index](realms-index.md)
- [Realm - Tichondrius](realm-tichondrius.md)

### Region API
- [Regions Index](regions-index.md)
- [Region - US](region-us.md)

### Reputations API
- [Reputation Factions](reputation-factions.md)
- [Reputation Tiers](reputation-tiers.md)

### Spell API
- [Spell Example](spell-example.md)

### Talent API
- [Talents Index](talents-index.md)
- [PvP Talents](pvp-talents.md)

### Tech Talent API
- [Tech Talent Trees](tech-talent-trees.md)
- [Tech Talents](tech-talents.md)

### Title API
- [Titles Index](titles-index.md)

### WoW Token API
- [WoW Token](wow-token.md)

## Authentication

All APIs require an OAuth 2.0 access token. See the main documentation for authentication details.

## Namespaces

WoW APIs use namespaces to separate different types of data:
- `static` - Game data that doesn't change frequently (items, spells, etc.)
- `dynamic` - Realm-specific data that updates regularly (auctions, leaderboards, etc.)
- `profile` - Character-specific data

## Localization

All endpoints support localization via the `locale` parameter. Common locales:
- en_US - English (US)
- en_GB - English (UK)
- de_DE - German
- es_ES - Spanish
- fr_FR - French
- it_IT - Italian
- pt_BR - Portuguese
- ru_RU - Russian
- ko_KR - Korean
- zh_TW - Traditional Chinese
- zh_CN - Simplified Chinese

