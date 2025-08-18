# World of Warcraft Classic APIs

World of Warcraft Classic APIs provide access to Classic Era, Season of Discovery, and Hardcore game data.

## Namespace System

WoW Classic uses different namespaces from Retail:
- `static-classic-{region}` - Static Classic game data
- `static-classic1x-{region}` - Classic Era static data
- `dynamic-classic-{region}` - Dynamic Classic data
- `dynamic-classic1x-{region}` - Classic Era dynamic data
- `profile-classic-{region}` - Classic character profiles

## Available Classic API Endpoints

### Classic Game Data APIs

#### Auction House API
- **Endpoint**: `/data/wow/connected-realm/{connectedRealmId}/auctions`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns auction house data for Classic realms

#### Connected Realm API
- **Endpoint**: `/data/wow/connected-realm/index`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns Classic connected realms

#### Creature API
- **Endpoint**: `/data/wow/creature/{creatureId}`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic creature data

#### Item API
- **Endpoint**: `/data/wow/item/{itemId}`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic item information

#### Item Class API
- **Endpoint**: `/data/wow/item-class/index`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic item classes

#### Media API
- **Endpoint**: `/data/wow/media/item/{itemId}`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic item media

#### Playable Class API
- **Endpoint**: `/data/wow/playable-class/index`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic playable classes

#### Playable Race API
- **Endpoint**: `/data/wow/playable-race/index`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic playable races

#### Power Type API
- **Endpoint**: `/data/wow/power-type/index`
- **Namespace**: static-classic-{region}
- **Description**: Returns Classic power types

#### PvP Season API
- **Endpoint**: `/data/wow/pvp-season/index`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns Classic PvP seasons

#### PvP Leaderboard API
- **Endpoint**: `/data/wow/pvp-region/{pvpRegionId}/pvp-season/{pvpSeasonId}/pvp-leaderboard/index`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns Classic PvP leaderboards

#### Realm API
- **Endpoint**: `/data/wow/realm/index`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns Classic realms

#### Region API
- **Endpoint**: `/data/wow/region/index`
- **Namespace**: dynamic-classic-{region}
- **Description**: Returns Classic regions

### Classic Profile APIs

#### Character Profile API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character profile

#### Character Appearance API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/appearance`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character appearance

#### Character Equipment API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/equipment`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character equipment

#### Character Media API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/character-media`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character media

#### Character PvP Summary API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/pvp-summary`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character PvP summary

#### Character Statistics API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/statistics`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic character statistics

#### Guild API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic guild profile

#### Guild Roster API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}/roster`
- **Namespace**: profile-classic-{region}
- **Description**: Returns Classic guild roster

## Classic Era vs Season of Discovery

### Classic Era (Vanilla)
- Uses `classic1x` namespaces
- Level cap: 60
- No expansions
- Original vanilla content only

### Season of Discovery
- Uses standard `classic` namespaces
- Progressive content releases
- New abilities and runes system
- Modified raid difficulties

### Hardcore
- Permanent death mechanics
- Special realm types
- Limited auction house
- No mailbox between characters

## Key Differences from Retail APIs

1. **Limited Endpoints**: Classic has fewer available endpoints than Retail
2. **No Achievement API**: Achievements don't exist in Classic
3. **No Mythic+ API**: Mythic+ doesn't exist in Classic
4. **Limited Collections**: No mount/pet collections in Classic Era
5. **Different Item IDs**: Classic items have different IDs from Retail
6. **No Covenant/Soulbind APIs**: These systems don't exist in Classic

## Example Requests

### Get Classic Realm List
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/realm/index?namespace=dynamic-classic-us&locale=en_US"
```

### Get Classic Character Profile
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/profile/wow/character/whitemane/example?namespace=profile-classic-us&locale=en_US"
```

### Get Classic Item
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-classic-us&locale=en_US"
```

## Response Format

Classic API responses follow the same format as Retail:

```json
{
  "_links": {
    "self": {
      "href": "https://us.api.blizzard.com/..."
    }
  },
  // Classic-specific data fields
}
```

## Important Notes

1. **Namespace Required**: Always specify the correct Classic namespace
2. **Limited Data**: Classic has less data available than Retail
3. **Different IDs**: Item, spell, and creature IDs differ between Classic and Retail
4. **Realm Names**: Classic realm names may differ from Retail
5. **API Availability**: Not all Retail endpoints have Classic equivalents

## Rate Limiting

Same as Retail APIs:
- 36,000 requests per hour
- 100 requests per second

## Supported Locales

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