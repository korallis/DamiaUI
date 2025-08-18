# World of Warcraft API Documentation

Comprehensive documentation for World of Warcraft APIs, including Game Data APIs, Profile APIs, and Classic APIs. All documentation is sourced from the official Battle.net Developer Portal.

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Authentication](#authentication)
- [API Documentation](#api-documentation)
  - [Game Data APIs](#game-data-apis)
  - [Profile APIs](#profile-apis)
  - [Classic APIs](#classic-apis)
- [Guides](#guides)
- [Resources](#resources)

## 🚀 Quick Start

### 1. Get API Credentials
```bash
# Your credentials (keep secret!)
CLIENT_ID=137bf455a6a94e368913f41ebcb226b0
CLIENT_SECRET=UHD15Gh7ichSzr2Ku5xoFBEWf78asPUI
```

### 2. Get Access Token
```bash
curl -u $CLIENT_ID:$CLIENT_SECRET \
  -d grant_type=client_credentials \
  https://oauth.battle.net/token
```

### 3. Make Your First API Call
```bash
curl -H "Authorization: Bearer {access_token}" \
  "https://us.api.blizzard.com/data/wow/realm/index?namespace=dynamic-us&locale=en_US"
```

## 🔐 Authentication

- [**Authentication Guide**](guides/authentication.md) - Complete OAuth 2.0 implementation guide
  - Client Credentials Flow
  - Authorization Code Flow
  - Token Management
  - Regional Endpoints
  - Security Best Practices

## 📖 API Documentation

### Game Data APIs

[**Full Game Data API Documentation**](game-data-apis/README.md)

Game Data APIs provide access to World of Warcraft's static and dynamic game data.

**Categories:**
- **Achievements** - Achievement categories and details
- **Auction House** - Real-time auction data
- **Connected Realms** - Realm connections and status
- **Covenants** - Shadowlands covenant data
- **Creatures** - NPC and creature information
- **Items** - Item data and media
- **Journal** - Dungeon and raid journal
- **Mounts** - Mount collection data
- **Mythic Keystone** - M+ dungeons, affixes, and leaderboards
- **Pets** - Battle pet information
- **Playable Classes** - Class and specialization data
- **PvP** - Seasons, leaderboards, and rewards
- **Quests** - Quest data and categories
- **Realms** - Realm status and information
- **Reputations** - Faction and reputation data
- **Spells** - Spell and ability information
- **Talents** - Talent and PvP talent data
- **WoW Token** - Token pricing data

### Profile APIs

[**Full Profile API Documentation**](profile-apis/README.md)

Profile APIs provide character-specific and account-specific data.

**Endpoints:**
- **Character Profile** - Basic character information
- **Character Achievements** - Achievement progress
- **Character Appearance** - Customization data
- **Character Collections** - Mounts, pets, toys, heirlooms
- **Character Equipment** - Gear and stats
- **Character Media** - Character renders and avatars
- **Character Mythic Keystone** - M+ profile and season data
- **Character Professions** - Profession skills and recipes
- **Character PvP** - PvP statistics and ratings
- **Character Reputations** - Faction standings
- **Character Specializations** - Talent builds
- **Guild Profile** - Guild information and roster

### Classic APIs

[**Full Classic API Documentation**](classic-apis/README.md)

APIs for World of Warcraft Classic, including Classic Era and Season of Discovery.

**Supported Versions:**
- **Classic Era** - Original Classic (Level 60)
- **Classic** - Classic with expansions
- **Season of Discovery** - Classic with seasonal content

## 📋 Guides

Essential guides for working with WoW APIs:

- [**Namespaces**](guides/namespaces.md) - Understanding and using API namespaces
  - Static vs Dynamic vs Profile
  - Regional namespaces
  - Classic namespaces
  
- [**Localization**](guides/localization.md) - Multi-language support
  - Supported locales
  - Fallback behavior
  - Implementation examples

- [**Authentication**](guides/authentication.md) - OAuth 2.0 implementation
  - Getting started
  - Token management
  - Security best practices

## 🛠️ Implementation Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

class WoWAPI {
  constructor(clientId, clientSecret) {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.accessToken = null;
  }

  async authenticate() {
    const auth = Buffer.from(`${this.clientId}:${this.clientSecret}`).toString('base64');
    const response = await axios.post(
      'https://oauth.battle.net/token',
      'grant_type=client_credentials',
      {
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );
    this.accessToken = response.data.access_token;
  }

  async getRealms() {
    const response = await axios.get(
      'https://us.api.blizzard.com/data/wow/realm/index',
      {
        params: {
          namespace: 'dynamic-us',
          locale: 'en_US'
        },
        headers: {
          'Authorization': `Bearer ${this.accessToken}`
        }
      }
    );
    return response.data;
  }
}
```

### Python
```python
import requests
import base64

class WoWAPI:
    def __init__(self, client_id, client_secret):
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
    
    def authenticate(self):
        auth = base64.b64encode(
            f"{self.client_id}:{self.client_secret}".encode()
        ).decode()
        
        response = requests.post(
            'https://oauth.battle.net/token',
            data={'grant_type': 'client_credentials'},
            headers={'Authorization': f'Basic {auth}'}
        )
        
        self.access_token = response.json()['access_token']
    
    def get_realms(self, region='us'):
        response = requests.get(
            f'https://{region}.api.blizzard.com/data/wow/realm/index',
            params={
                'namespace': f'dynamic-{region}',
                'locale': 'en_US'
            },
            headers={'Authorization': f'Bearer {self.access_token}'}
        )
        return response.json()
```

## 📊 API Limits

- **Rate Limits**: 36,000 requests per hour, 100 requests per second
- **Token Expiration**: 24 hours
- **Cache Recommendations**:
  - Static data: 1-7 days
  - Dynamic data: 5-60 minutes
  - Profile data: 1-24 hours

## 🌍 Regional Endpoints

| Region | OAuth Endpoint | API Endpoint |
|--------|---------------|--------------|
| US | `https://oauth.battle.net/` | `https://us.api.blizzard.com/` |
| EU | `https://eu.battle.net/oauth/` | `https://eu.api.blizzard.com/` |
| KR | `https://kr.battle.net/oauth/` | `https://kr.api.blizzard.com/` |
| TW | `https://tw.battle.net/oauth/` | `https://tw.api.blizzard.com/` |
| CN | `https://oauth.battlenet.com.cn/` | `https://gateway.battlenet.com.cn/` |

## 🎮 Game Versions

| Version | Description | Current Patch |
|---------|-------------|---------------|
| Retail | The War Within | 11.2 |
| Classic Era | Original Classic | 1.15.x |
| Classic | Cataclysm Classic | 4.4.x |

## 📦 Repository Structure

```
wow-documentation/
├── README.md                 # This file
├── game-data-apis/          # Game Data API documentation
│   ├── README.md            # Game Data API index
│   └── [endpoint].md        # Individual endpoint docs
├── profile-apis/            # Profile API documentation
│   └── README.md           # Profile API reference
├── classic-apis/           # Classic API documentation
│   └── README.md          # Classic API reference
├── guides/                 # Implementation guides
│   ├── authentication.md  # OAuth guide
│   ├── namespaces.md     # Namespace guide
│   └── localization.md   # Localization guide
└── fetch_wow_api_docs.sh  # Script to update documentation
```

## 🔧 Tools & Scripts

- **fetch_wow_api_docs.sh** - Fetches latest API responses
- **fetch_profile_apis.sh** - Updates profile API documentation

## 🐛 Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Token expired - Get new token
   - Invalid credentials - Check CLIENT_ID and CLIENT_SECRET

2. **404 Not Found**
   - Wrong namespace - Check static vs dynamic
   - Resource doesn't exist - Verify ID/name

3. **429 Too Many Requests**
   - Rate limit exceeded - Implement backoff
   - Cache responses to reduce calls

## 📚 Additional Resources

- [Official Battle.net Developer Portal](https://develop.battle.net/)
- [API Discussion Forums](https://us.forums.blizzard.com/en/blizzard/c/api-discussion)
- [BlizzardCS Twitter](https://twitter.com/BlizzardCS) - Service status
- [WoW API Community Discord](https://discord.gg/blizzapi)

## 📝 License & Terms

This documentation references the official Blizzard Entertainment APIs. Use of the APIs is subject to:
- [Blizzard Developer API Terms of Use](https://develop.battle.net/terms)
- [Blizzard End User License Agreement](https://www.blizzard.com/legal/)

## 🤝 Contributing

This documentation is maintained for the Damia UI addon project. For corrections or additions:
1. Check the official Battle.net documentation for accuracy
2. Update relevant files
3. Run update scripts if API responses have changed

## 📅 Last Updated

**August 18, 2025** - Documentation current for WoW Retail 11.2 (The War Within)

---

*This documentation was created using official Battle.net API endpoints with authorized credentials.*