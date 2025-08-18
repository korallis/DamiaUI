# World of Warcraft Profile APIs

Profile APIs provide character-specific information including equipment, achievements, collections, and more.

## Authentication
All Profile APIs require:
- OAuth 2.0 Bearer token
- Appropriate namespace (profile-{region})
- Character realm and name

## API Endpoints

### Account Profile API
- **Endpoint**: `/profile/user/wow`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns the WoW account profile for the authenticated user
- **Required Scope**: wow.profile

### Character Achievements API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/achievements`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character achievements

### Character Achievements Statistics API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/achievements/statistics`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character achievement statistics

### Character Appearance API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/appearance`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character appearance details

### Character Collections API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/collections`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character collections index

### Character Collections Mounts API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/collections/mounts`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character mount collection

### Character Collections Pets API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/collections/pets`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character pet collection

### Character Collections Toys API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/collections/toys`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character toy collection

### Character Collections Heirlooms API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/collections/heirlooms`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character heirloom collection

### Character Encounters API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/encounters`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character encounters index

### Character Encounters Raids API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/encounters/raids`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character raid encounters

### Character Encounters Dungeons API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/encounters/dungeons`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character dungeon encounters

### Character Equipment API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/equipment`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character equipment

### Character Hunter Pets API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/hunter-pets`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns hunter pet information

### Character Media API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/character-media`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character media assets

### Character Mythic Keystone Profile API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/mythic-keystone-profile`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character Mythic Keystone profile

### Character Mythic Keystone Profile Season API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/mythic-keystone-profile/season/{seasonId}`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character Mythic Keystone season details

### Character Professions API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/professions`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character professions

### Character Profile API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character profile summary

### Character Profile Status API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/status`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character profile status

### Character PvP Bracket Statistics API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/pvp-bracket/{pvpBracket}`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character PvP bracket statistics
- **PvP Brackets**: 1v1, 2v2, 3v3, rbg

### Character PvP Summary API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/pvp-summary`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character PvP summary

### Character Quests API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/quests`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character quests

### Character Quests Completed API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/quests/completed`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns completed quests

### Character Reputations API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/reputations`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character reputations

### Character Soulbinds API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/soulbinds`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character soulbinds

### Character Specializations API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/specializations`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character specializations

### Character Statistics API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/statistics`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character statistics

### Character Titles API
- **Endpoint**: `/profile/wow/character/{realmSlug}/{characterName}/titles`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns character titles

### Guild API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns guild profile

### Guild Activity API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}/activity`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns guild activity feed

### Guild Achievements API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}/achievements`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns guild achievements

### Guild Roster API
- **Endpoint**: `/data/wow/guild/{realmSlug}/{nameSlug}/roster`
- **Method**: GET
- **Namespace**: profile-{region}
- **Description**: Returns guild roster

## Response Format

All responses are in JSON format with the following general structure:

```json
{
  "_links": {
    "self": {
      "href": "https://us.api.blizzard.com/..."
    }
  },
  // API-specific data fields
}
```

## Error Responses

Standard HTTP status codes:
- 200: Success
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 429: Too Many Requests
- 500: Internal Server Error
- 503: Service Unavailable

## Rate Limiting

- 36,000 requests per hour
- 100 requests per second
- Headers include rate limit information

## Example Usage

### cURL Example
```bash
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/profile/wow/character/tichondrius/example?namespace=profile-us&locale=en_US"
```

### JavaScript Example
```javascript
const response = await fetch(
  'https://us.api.blizzard.com/profile/wow/character/tichondrius/example?namespace=profile-us&locale=en_US',
  {
    headers: {
      'Authorization': 'Bearer ' + accessToken
    }
  }
);
const data = await response.json();
```

## Important Notes

1. Character names are case-insensitive but should be lowercase in URLs
2. Realm slugs use hyphens instead of spaces (e.g., "Area 52" becomes "area-52")
3. Some endpoints require the character to be logged out to update
4. Profile data may be cached for up to 24 hours
5. Protected profiles return limited information

