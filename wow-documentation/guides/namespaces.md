# World of Warcraft API Namespaces

## Overview

Namespaces are a required parameter for all World of Warcraft Game Data and Profile APIs. They help segregate data based on region, game version, and data type.

## Namespace Types

### Static Namespace
`static-{region}` or `static-{gameVersion}-{region}`

- Contains game data that rarely changes
- Includes: items, spells, talents, creatures, quests
- Updated with game patches
- Highly cacheable

**Examples**:
- `static-us` - US static data
- `static-eu` - EU static data
- `static-classic-us` - Classic static data

### Dynamic Namespace
`dynamic-{region}` or `dynamic-{gameVersion}-{region}`

- Contains frequently changing data
- Includes: auctions, leaderboards, realm status
- Updates regularly (hourly or more frequent)
- Limited caching recommended

**Examples**:
- `dynamic-us` - US dynamic data
- `dynamic-eu` - EU dynamic data
- `dynamic-classic-us` - Classic dynamic data

### Profile Namespace
`profile-{region}` or `profile-{gameVersion}-{region}`

- Contains character and guild profile data
- Requires character/guild to exist in that region
- Updates when character logs out or periodically
- May require authorization for protected profiles

**Examples**:
- `profile-us` - US character profiles
- `profile-eu` - EU character profiles
- `profile-classic-us` - Classic character profiles

## Region Codes

| Region | Code | API Endpoint |
|--------|------|--------------|
| United States | `us` | `https://us.api.blizzard.com` |
| Europe | `eu` | `https://eu.api.blizzard.com` |
| Korea | `kr` | `https://kr.api.blizzard.com` |
| Taiwan | `tw` | `https://tw.api.blizzard.com` |
| China | `cn` | `https://gateway.battlenet.com.cn` |

## Game Version Prefixes

| Game Version | Prefix | Description |
|--------------|--------|-------------|
| Retail | (none) | Current expansion (The War Within) |
| Classic Era | `classic1x` | Original Classic (Level 60) |
| Classic | `classic` | Classic with expansions |

## Namespace Usage Examples

### Retail Static Data
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-us&locale=en_US"
```

### Retail Dynamic Data
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/connected-realm/11/auctions?namespace=dynamic-us&locale=en_US"
```

### Retail Profile Data
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/profile/wow/character/tichondrius/example?namespace=profile-us&locale=en_US"
```

### Classic Static Data
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-classic-us&locale=en_US"
```

### Classic Era Static Data
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-classic1x-us&locale=en_US"
```

## Namespace Requirements by API

### Game Data APIs

| API Category | Required Namespace Type |
|--------------|------------------------|
| Achievement | static |
| Auction House | dynamic |
| Azerite Essence | static |
| Connected Realm | dynamic |
| Covenant | static |
| Creature | static |
| Guild Crest | static |
| Item | static |
| Journal | static |
| Media | static |
| Modified Crafting | static |
| Mount | static |
| Mythic Keystone Affix | static |
| Mythic Keystone Dungeon | dynamic |
| Mythic Keystone Leaderboard | dynamic |
| Mythic Keystone Season | dynamic |
| Mythic Raid Leaderboard | dynamic |
| Pet | static |
| Playable Class | static |
| Playable Race | static |
| Playable Specialization | static |
| Power Type | static |
| Profession | static |
| PvP Season | dynamic |
| PvP Leaderboard | dynamic |
| PvP Tier | static |
| Quest | static |
| Realm | dynamic |
| Region | dynamic |
| Reputation | static |
| Spell | static |
| Talent | static |
| Tech Talent | static |
| Title | static |
| WoW Token | dynamic |

### Profile APIs

All Profile APIs require the `profile-{region}` namespace.

## Cross-Region Considerations

### Data Isolation
- Each region's data is completely separate
- Characters don't exist across regions
- Auction houses are region-specific
- Leaderboards are region-specific

### API Access
- You can access any region's API from anywhere
- Use the appropriate regional endpoint
- Token obtained from any region works globally

### Time Zones
- US: Pacific Time (PST/PDT)
- EU: Central European Time (CET/CEST)
- KR/TW: Korea Standard Time (KST)
- CN: China Standard Time (CST)

## Best Practices

### 1. Choose the Correct Namespace
- Use static for reference data
- Use dynamic for real-time data
- Use profile for character data

### 2. Cache Appropriately
- Static data: Cache for hours/days
- Dynamic data: Cache for minutes
- Profile data: Cache based on update frequency

### 3. Handle Namespace Errors
```javascript
// Example error handling
try {
  const response = await fetch(url);
  if (response.status === 404) {
    // Check if namespace is correct
    console.error('Resource not found - verify namespace');
  }
} catch (error) {
  console.error('API request failed:', error);
}
```

### 4. Use Consistent Namespaces
When fetching related data, ensure namespace consistency:

```javascript
const namespace = 'static-us';
const locale = 'en_US';

// Fetch item
const itemUrl = `https://us.api.blizzard.com/data/wow/item/${itemId}?namespace=${namespace}&locale=${locale}`;

// Fetch item media (same namespace)
const mediaUrl = `https://us.api.blizzard.com/data/wow/media/item/${itemId}?namespace=${namespace}&locale=${locale}`;
```

## Common Namespace Errors

### Error: "Invalid namespace"
**Cause**: Namespace doesn't exist or is malformed
**Solution**: Verify namespace format matches `{type}-{region}`

### Error: "Resource not found"
**Cause**: Resource doesn't exist in specified namespace
**Solution**: 
- Verify the resource exists in that game version
- Check if using correct static vs dynamic
- Ensure region matches the data

### Error: "Forbidden"
**Cause**: Attempting to access profile data without proper authorization
**Solution**: Use OAuth Authorization Code flow for protected profiles

## Namespace Migration

When Blizzard updates namespace structures:

1. **Deprecation Notice**: Usually 6 months advance notice
2. **Parallel Support**: Both old and new namespaces work temporarily
3. **Migration Period**: Update your code to use new namespaces
4. **Sunset**: Old namespaces stop working

Monitor the [API forums](https://us.forums.blizzard.com/en/blizzard/c/api-discussion) for namespace changes.

## Testing Namespaces

### Verify Namespace Availability
```bash
# Test if namespace is valid
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/achievement/index?namespace=static-us&locale=en_US"

# Success: Returns data
# Failure: Returns error with details
```

### Compare Namespace Data
```bash
# Compare Retail vs Classic item
# Retail
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-us&locale=en_US"

# Classic
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-classic-us&locale=en_US"
```

## Summary

Namespaces are essential for:
- Accessing the correct data version
- Ensuring regional data accuracy
- Optimizing caching strategies
- Maintaining API compatibility

Always include the appropriate namespace parameter in your API requests to ensure you're accessing the correct data for your application's needs.