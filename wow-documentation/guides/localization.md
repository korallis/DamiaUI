# World of Warcraft API Localization

## Overview

The World of Warcraft APIs support multiple languages through the `locale` parameter. This allows you to retrieve game data in the language appropriate for your users.

## Supported Locales

| Locale Code | Language | Region Support |
|-------------|----------|----------------|
| `en_US` | English (US) | All regions |
| `es_MX` | Spanish (Mexico) | US |
| `pt_BR` | Portuguese (Brazil) | US |
| `en_GB` | English (UK) | EU |
| `es_ES` | Spanish (Spain) | EU |
| `fr_FR` | French | EU |
| `ru_RU` | Russian | EU |
| `de_DE` | German | EU |
| `pt_PT` | Portuguese (Portugal) | EU |
| `it_IT` | Italian | EU |
| `ko_KR` | Korean | KR |
| `zh_TW` | Traditional Chinese | TW |
| `zh_CN` | Simplified Chinese | CN |

## Using Locales

### Basic Usage
Include the `locale` parameter in your API request:

```bash
# English (US)
curl -H "Authorization: Bearer {token}" \
  "https://us.api.blizzard.com/data/wow/item/19019?namespace=static-us&locale=en_US"

# Spanish (Spain)
curl -H "Authorization: Bearer {token}" \
  "https://eu.api.blizzard.com/data/wow/item/19019?namespace=static-eu&locale=es_ES"

# Korean
curl -H "Authorization: Bearer {token}" \
  "https://kr.api.blizzard.com/data/wow/item/19019?namespace=static-kr&locale=ko_KR"
```

## Localized Fields

### Commonly Localized Data
- **Names**: Item names, spell names, NPC names
- **Descriptions**: Item descriptions, quest text, ability descriptions
- **Flavor Text**: Lore text, quotes
- **Categories**: Achievement categories, item types

### Example Response - Item API
```json
{
  "id": 19019,
  "name": {
    "en_US": "Thunderfury, Blessed Blade of the Windseeker",
    "es_ES": "Trueno Furioso, Espada Bendita del Hijo del Viento",
    "de_DE": "Donnerzorn, die gesegnete Klinge des Windsuchers",
    "fr_FR": "Tonnefury, lame bénie du Chercheur-de-vent"
  },
  "quality": {
    "type": "LEGENDARY",
    "name": {
      "en_US": "Legendary",
      "es_ES": "Legendario",
      "de_DE": "Legendär",
      "fr_FR": "Légendaire"
    }
  }
}
```

## Locale Fallback Behavior

### Default Fallback Chain
1. Requested locale
2. Base language (e.g., `es_MX` → `es_ES`)
3. English (`en_US`)
4. First available translation

### Missing Translations
When a translation is missing:
- Returns English text
- May return empty string for non-critical text
- Structure remains consistent

## Region-Locale Compatibility

### Best Practices
- Use region-appropriate locales
- Match namespace region with locale region
- Consider player base demographics

### Region-Locale Matrix

| Region | Primary Locales | Secondary Locales |
|--------|----------------|-------------------|
| US | en_US | es_MX, pt_BR |
| EU | en_GB, de_DE, fr_FR | es_ES, it_IT, ru_RU, pt_PT |
| KR | ko_KR | - |
| TW | zh_TW | - |
| CN | zh_CN | - |

## Implementation Examples

### JavaScript - Multi-locale Support
```javascript
class WoWAPIClient {
  constructor(accessToken, defaultLocale = 'en_US') {
    this.accessToken = accessToken;
    this.defaultLocale = defaultLocale;
  }

  async getItem(itemId, locale = this.defaultLocale) {
    const response = await fetch(
      `https://us.api.blizzard.com/data/wow/item/${itemId}?namespace=static-us&locale=${locale}`,
      {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`
        }
      }
    );
    return response.json();
  }

  async getItemMultiLocale(itemId, locales = ['en_US', 'es_ES', 'de_DE']) {
    const promises = locales.map(locale => this.getItem(itemId, locale));
    const results = await Promise.all(promises);
    
    return locales.reduce((acc, locale, index) => {
      acc[locale] = results[index];
      return acc;
    }, {});
  }
}
```

### Python - Locale Detection
```python
import requests
from typing import Dict, Optional

class WoWAPI:
    LOCALE_MAPPING = {
        'en': 'en_US',
        'es': 'es_ES',
        'de': 'de_DE',
        'fr': 'fr_FR',
        'it': 'it_IT',
        'pt': 'pt_BR',
        'ru': 'ru_RU',
        'ko': 'ko_KR',
        'zh-Hans': 'zh_CN',
        'zh-Hant': 'zh_TW'
    }
    
    def __init__(self, access_token: str):
        self.access_token = access_token
        self.headers = {'Authorization': f'Bearer {access_token}'}
    
    def detect_locale(self, browser_locale: str) -> str:
        """Convert browser locale to WoW API locale"""
        # Extract language code
        lang = browser_locale.split('-')[0].lower()
        return self.LOCALE_MAPPING.get(lang, 'en_US')
    
    def get_localized_data(self, endpoint: str, locale: str = 'en_US') -> Dict:
        url = f"https://us.api.blizzard.com{endpoint}"
        params = {
            'namespace': 'static-us',
            'locale': locale
        }
        response = requests.get(url, headers=self.headers, params=params)
        return response.json()
```

### PHP - Locale Caching
```php
class WoWAPILocalization {
    private $cache = [];
    private $accessToken;
    private $defaultLocale = 'en_US';
    
    public function __construct($accessToken, $defaultLocale = 'en_US') {
        $this->accessToken = $accessToken;
        $this->defaultLocale = $defaultLocale;
    }
    
    public function getLocalizedItem($itemId, $locale = null) {
        $locale = $locale ?: $this->defaultLocale;
        $cacheKey = "item_{$itemId}_{$locale}";
        
        // Check cache
        if (isset($this->cache[$cacheKey])) {
            return $this->cache[$cacheKey];
        }
        
        // Fetch from API
        $url = "https://us.api.blizzard.com/data/wow/item/{$itemId}";
        $url .= "?namespace=static-us&locale={$locale}";
        
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $this->accessToken
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        curl_close($ch);
        
        $data = json_decode($response, true);
        
        // Cache result
        $this->cache[$cacheKey] = $data;
        
        return $data;
    }
}
```

## Handling Missing Translations

### Graceful Degradation
```javascript
function getLocalizedText(data, field, locale, fallbackLocale = 'en_US') {
  // Try requested locale
  if (data[field] && data[field][locale]) {
    return data[field][locale];
  }
  
  // Try fallback locale
  if (data[field] && data[field][fallbackLocale]) {
    return data[field][fallbackLocale];
  }
  
  // Try any available locale
  if (data[field] && typeof data[field] === 'object') {
    const available = Object.keys(data[field]);
    if (available.length > 0) {
      return data[field][available[0]];
    }
  }
  
  // Return placeholder
  return `[Missing translation: ${field}]`;
}
```

## Locale-Specific Considerations

### Character Encoding
- All API responses use UTF-8 encoding
- Ensure proper character handling for Asian languages
- Consider font support for special characters

### Text Direction
- All WoW locales use left-to-right (LTR) text
- No right-to-left (RTL) language support currently

### Date and Time Formats
```javascript
const formatDate = (timestamp, locale) => {
  const date = new Date(timestamp * 1000);
  
  const formats = {
    'en_US': { month: 'short', day: 'numeric', year: 'numeric' },
    'en_GB': { day: 'numeric', month: 'short', year: 'numeric' },
    'de_DE': { day: 'numeric', month: 'numeric', year: 'numeric' },
    'fr_FR': { day: 'numeric', month: 'long', year: 'numeric' }
  };
  
  return date.toLocaleDateString(locale.replace('_', '-'), formats[locale] || formats['en_US']);
};
```

### Number Formatting
```javascript
const formatNumber = (number, locale) => {
  const localeMap = {
    'en_US': 'en-US',
    'de_DE': 'de-DE',
    'fr_FR': 'fr-FR',
    'es_ES': 'es-ES'
  };
  
  return new Intl.NumberFormat(localeMap[locale] || 'en-US').format(number);
};

// Examples:
// en_US: 1,234,567
// de_DE: 1.234.567
// fr_FR: 1 234 567
// es_ES: 1.234.567
```

## Performance Optimization

### Locale Caching Strategy
1. **Cache by locale**: Store responses per locale
2. **Shared cache**: Cache locale-independent data separately
3. **TTL by type**: Different cache duration for static vs dynamic

```javascript
class LocaleCache {
  constructor() {
    this.cache = new Map();
  }
  
  getCacheKey(endpoint, locale) {
    return `${endpoint}:${locale}`;
  }
  
  get(endpoint, locale) {
    const key = this.getCacheKey(endpoint, locale);
    const cached = this.cache.get(key);
    
    if (cached && cached.expires > Date.now()) {
      return cached.data;
    }
    
    return null;
  }
  
  set(endpoint, locale, data, ttl = 3600000) {
    const key = this.getCacheKey(endpoint, locale);
    this.cache.set(key, {
      data: data,
      expires: Date.now() + ttl
    });
  }
}
```

### Batch Locale Requests
```javascript
async function batchLocaleRequests(endpoints, locales, accessToken) {
  const requests = [];
  
  for (const endpoint of endpoints) {
    for (const locale of locales) {
      requests.push({
        endpoint,
        locale,
        promise: fetch(`${endpoint}?locale=${locale}`, {
          headers: { 'Authorization': `Bearer ${accessToken}` }
        })
      });
    }
  }
  
  const responses = await Promise.all(requests.map(r => r.promise));
  
  return requests.map((req, index) => ({
    endpoint: req.endpoint,
    locale: req.locale,
    data: responses[index].json()
  }));
}
```

## Testing Localization

### Test Coverage Checklist
- [ ] All supported locales return data
- [ ] Fallback behavior works correctly
- [ ] Special characters display properly
- [ ] Number formatting is locale-appropriate
- [ ] Date formatting follows locale conventions
- [ ] Missing translations handled gracefully

### Automated Testing
```javascript
const testLocalization = async (itemId, accessToken) => {
  const locales = ['en_US', 'es_ES', 'de_DE', 'fr_FR', 'ko_KR', 'zh_TW'];
  const results = {};
  
  for (const locale of locales) {
    try {
      const response = await fetch(
        `https://us.api.blizzard.com/data/wow/item/${itemId}?namespace=static-us&locale=${locale}`,
        { headers: { 'Authorization': `Bearer ${accessToken}` } }
      );
      
      const data = await response.json();
      results[locale] = {
        success: true,
        hasName: !!data.name,
        hasDescription: !!data.description
      };
    } catch (error) {
      results[locale] = {
        success: false,
        error: error.message
      };
    }
  }
  
  return results;
};
```

## Best Practices

1. **Always specify locale**: Don't rely on defaults
2. **Cache by locale**: Separate cache entries per language
3. **Handle fallbacks**: Implement graceful degradation
4. **Test all locales**: Ensure coverage for target markets
5. **Monitor usage**: Track which locales are most used
6. **Optimize requests**: Batch when fetching multiple locales
7. **Consider user preference**: Store and respect user's locale choice