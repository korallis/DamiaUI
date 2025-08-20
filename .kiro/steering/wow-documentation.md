# WoW API Documentation Steering

This steering file provides access to comprehensive World of Warcraft API documentation for developing the Damia UI addon.

## Overview

The WoW documentation includes complete API references for:
- Game Data APIs (static and dynamic game data)
- Profile APIs (character and guild data)  
- Classic APIs (Classic Era and Season of Discovery)
- Implementation guides and best practices

## Main Documentation
#[[file:wow-documentation/README.md]]

## Game Data APIs

### Core Documentation
#[[file:wow-documentation/game-data-apis/README.md]]

### Achievement System
#[[file:wow-documentation/game-data-apis/achievement-categories-index.md]]
#[[file:wow-documentation/game-data-apis/achievements-index.md]]

### Auction House
#[[file:wow-documentation/game-data-apis/auction-house.md]]

### Realms & Connectivity
#[[file:wow-documentation/game-data-apis/connected-realms-index.md]]
#[[file:wow-documentation/game-data-apis/realms-index.md]]
#[[file:wow-documentation/game-data-apis/realm-tichondrius.md]]
#[[file:wow-documentation/game-data-apis/regions-index.md]]
#[[file:wow-documentation/game-data-apis/region-us.md]]

### Covenants & Shadowlands
#[[file:wow-documentation/game-data-apis/covenants-index.md]]

### Creatures & NPCs
#[[file:wow-documentation/game-data-apis/creature-families.md]]
#[[file:wow-documentation/game-data-apis/creature-types.md]]

### Guild System
#[[file:wow-documentation/game-data-apis/guild-crests.md]]

### Items & Equipment
#[[file:wow-documentation/game-data-apis/item-classes.md]]
#[[file:wow-documentation/game-data-apis/media-item.md]]

### Dungeons & Raids
#[[file:wow-documentation/game-data-apis/journal-encounters.md]]
#[[file:wow-documentation/game-data-apis/journal-expansions.md]]
#[[file:wow-documentation/game-data-apis/journal-instances.md]]

### Media & Display
#[[file:wow-documentation/game-data-apis/media-creature-display.md]]

### Mounts & Collections
#[[file:wow-documentation/game-data-apis/mounts-index.md]]

### Mythic+ System
#[[file:wow-documentation/game-data-apis/mythic-keystone-dungeons.md]]
#[[file:wow-documentation/game-data-apis/mythic-keystone-index.md]]
#[[file:wow-documentation/game-data-apis/mythic-keystone-periods.md]]
#[[file:wow-documentation/game-data-apis/mythic-keystone-seasons.md]]
#[[file:wow-documentation/game-data-apis/mythic-leaderboard-index.md]]
#[[file:wow-documentation/game-data-apis/mythic-raid-leaderboard.md]]

### Battle Pets
#[[file:wow-documentation/game-data-apis/pets-index.md]]

### Classes & Specializations
#[[file:wow-documentation/game-data-apis/playable-classes.md]]
#[[file:wow-documentation/game-data-apis/playable-class-shaman.md]]
#[[file:wow-documentation/game-data-apis/playable-races.md]]
#[[file:wow-documentation/game-data-apis/playable-specializations.md]]
#[[file:wow-documentation/game-data-apis/playable-spec-elemental.md]]

### Character Systems
#[[file:wow-documentation/game-data-apis/power-types.md]]

### Professions
#[[file:wow-documentation/game-data-apis/professions-index.md]]

### PvP System
#[[file:wow-documentation/game-data-apis/pvp-leaderboards-index.md]]
#[[file:wow-documentation/game-data-apis/pvp-leaderboard-3v3.md]]
#[[file:wow-documentation/game-data-apis/pvp-rewards.md]]
#[[file:wow-documentation/game-data-apis/pvp-seasons-index.md]]
#[[file:wow-documentation/game-data-apis/pvp-season-27.md]]
#[[file:wow-documentation/game-data-apis/pvp-talents.md]]

### Questing System
#[[file:wow-documentation/game-data-apis/quest-areas.md]]
#[[file:wow-documentation/game-data-apis/quest-categories.md]]
#[[file:wow-documentation/game-data-apis/quest-types.md]]
#[[file:wow-documentation/game-data-apis/quests-index.md]]

### Reputation System
#[[file:wow-documentation/game-data-apis/reputation-factions.md]]
#[[file:wow-documentation/game-data-apis/reputation-tiers.md]]

### Spells & Abilities
#[[file:wow-documentation/game-data-apis/spell-example.md]]

### Talent System
#[[file:wow-documentation/game-data-apis/talents-index.md]]
#[[file:wow-documentation/game-data-apis/tech-talent-trees.md]]
#[[file:wow-documentation/game-data-apis/tech-talents.md]]

### Titles & Achievements
#[[file:wow-documentation/game-data-apis/titles-index.md]]

### Economy
#[[file:wow-documentation/game-data-apis/wow-token.md]]

## Profile APIs
#[[file:wow-documentation/profile-apis/README.md]]

## Classic APIs
#[[file:wow-documentation/classic-apis/README.md]]

## Usage Guidelines

When developing Damia UI features that interact with WoW data:

1. **Reference appropriate API endpoints** for the data you need
2. **Follow authentication patterns** outlined in the guides
3. **Use proper namespaces** (static vs dynamic vs profile)
4. **Implement caching** to respect rate limits
5. **Handle regional differences** appropriately

## Integration Notes

- APIs are primarily for external tools, not in-game addons
- Use this documentation for understanding data structures
- Addon development uses WoW's internal Lua APIs instead
- This documentation helps understand the broader WoW data ecosystem