# Battle.net API Authentication Guide

## Overview

The Battle.net APIs use OAuth 2.0 for authentication. There are two main authentication flows:
1. **Client Credentials Flow** - For server-to-server requests (most common for game data)
2. **Authorization Code Flow** - For accessing user-specific data (profiles, protected data)

## Client Credentials Flow

This is the most common authentication method for accessing game data APIs.

### Step 1: Create a Client

1. Go to https://develop.battle.net/access/clients
2. Click "Create Client"
3. Fill in the required information:
   - Client Name
   - Redirect URIs (for Authorization Code flow)
   - Service URL
   - Intended Use
4. Save your Client ID and Client Secret

### Step 2: Get an Access Token

**Endpoint**: `https://oauth.battle.net/token`

**Request**:
```bash
curl -u {client_id}:{client_secret} \
  -d grant_type=client_credentials \
  https://oauth.battle.net/token
```

**Response**:
```json
{
  "access_token": "EUxBpylb209mrN1iibdnAZicDbHRIcQR2b",
  "token_type": "bearer",
  "expires_in": 86399,
  "sub": "137bf455a6a94e368913f41ebcb226b0"
}
```

### Step 3: Use the Access Token

Include the access token in the Authorization header:

```bash
curl -H "Authorization: Bearer {access_token}" \
  "https://us.api.blizzard.com/data/wow/achievement/index?namespace=static-us&locale=en_US"
```

## Authorization Code Flow

Used for accessing user-specific protected data.

### Step 1: Redirect User to Authorization

```
https://oauth.battle.net/authorize
  ?response_type=code
  &client_id={client_id}
  &redirect_uri={redirect_uri}
  &scope=wow.profile
  &state={state}
```

### Step 2: Exchange Code for Token

After user authorizes, exchange the code for an access token:

```bash
curl -X POST https://oauth.battle.net/token \
  -u {client_id}:{client_secret} \
  -d redirect_uri={redirect_uri} \
  -d scope=wow.profile \
  -d grant_type=authorization_code \
  -d code={authorization_code}
```

### Step 3: Use the Access Token

Same as Client Credentials flow.

## Regional Endpoints

Different regions have different OAuth and API endpoints:

### OAuth Endpoints
- **US**: `https://oauth.battle.net/`
- **EU**: `https://eu.battle.net/oauth/`
- **KR**: `https://kr.battle.net/oauth/`
- **TW**: `https://tw.battle.net/oauth/`
- **CN**: `https://oauth.battlenet.com.cn/`

### API Endpoints
- **US**: `https://us.api.blizzard.com/`
- **EU**: `https://eu.api.blizzard.com/`
- **KR**: `https://kr.api.blizzard.com/`
- **TW**: `https://tw.api.blizzard.com/`
- **CN**: `https://gateway.battlenet.com.cn/`

## Scopes

Available scopes for Authorization Code flow:

- `wow.profile` - Access to WoW character profile data
- `sc2.profile` - Access to StarCraft II profile data
- `d3.profile` - Access to Diablo III profile data
- `openid` - OpenID Connect authentication

## Token Management

### Token Expiration
- Access tokens typically expire after 24 hours (86400 seconds)
- Check the `expires_in` field in the token response
- Implement token refresh logic before expiration

### Token Validation
Validate tokens using the token validation endpoint:

```bash
curl -H "Authorization: Bearer {access_token}" \
  https://oauth.battle.net/oauth/check_token
```

Response:
```json
{
  "exp": 1234567890,
  "user_name": "user@example.com",
  "authorities": ["wow.profile"],
  "scope": ["wow.profile"],
  "client_id": "your_client_id"
}
```

## Rate Limiting

### Limits
- **Per Hour**: 36,000 requests
- **Per Second**: 100 requests

### Rate Limit Headers
Response headers include rate limit information:
- `X-RateLimit-Limit` - Requests allowed per hour
- `X-RateLimit-Remaining` - Requests remaining
- `X-RateLimit-Reset` - Unix timestamp when limit resets

### Best Practices
1. Cache responses when possible
2. Implement exponential backoff for retries
3. Monitor rate limit headers
4. Use conditional requests with ETags

## Error Handling

### Common HTTP Status Codes
- `200 OK` - Success
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Invalid or expired token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

### Error Response Format
```json
{
  "code": 401,
  "type": "UNAUTHORIZED",
  "detail": "Invalid access token"
}
```

## Security Best Practices

1. **Never expose Client Secret**
   - Keep it server-side only
   - Never include in client-side code
   - Rotate regularly

2. **Use HTTPS**
   - All API calls must use HTTPS
   - Verify SSL certificates

3. **Validate Tokens**
   - Check expiration before use
   - Validate token format
   - Handle refresh properly

4. **Secure Storage**
   - Store tokens securely
   - Use environment variables
   - Encrypt sensitive data

5. **Implement Proper CORS**
   - Configure allowed origins
   - Restrict methods and headers

## Implementation Examples

### Node.js Example
```javascript
const axios = require('axios');

// Get access token
async function getAccessToken(clientId, clientSecret) {
  const auth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  
  const response = await axios.post('https://oauth.battle.net/token', 
    'grant_type=client_credentials',
    {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );
  
  return response.data.access_token;
}

// Use access token
async function getAchievements(accessToken) {
  const response = await axios.get(
    'https://us.api.blizzard.com/data/wow/achievement/index',
    {
      params: {
        namespace: 'static-us',
        locale: 'en_US'
      },
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    }
  );
  
  return response.data;
}
```

### Python Example
```python
import requests
import base64

# Get access token
def get_access_token(client_id, client_secret):
    auth = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
    
    response = requests.post(
        'https://oauth.battle.net/token',
        data={'grant_type': 'client_credentials'},
        headers={'Authorization': f'Basic {auth}'}
    )
    
    return response.json()['access_token']

# Use access token
def get_achievements(access_token):
    response = requests.get(
        'https://us.api.blizzard.com/data/wow/achievement/index',
        params={
            'namespace': 'static-us',
            'locale': 'en_US'
        },
        headers={'Authorization': f'Bearer {access_token}'}
    )
    
    return response.json()
```

### PHP Example
```php
<?php
// Get access token
function getAccessToken($clientId, $clientSecret) {
    $ch = curl_init('https://oauth.battle.net/token');
    curl_setopt($ch, CURLOPT_USERPWD, $clientId . ':' . $clientSecret);
    curl_setopt($ch, CURLOPT_POSTFIELDS, 'grant_type=client_credentials');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    $data = json_decode($response, true);
    return $data['access_token'];
}

// Use access token
function getAchievements($accessToken) {
    $url = 'https://us.api.blizzard.com/data/wow/achievement/index';
    $url .= '?namespace=static-us&locale=en_US';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    return json_decode($response, true);
}
?>
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Token expired - Get a new token
   - Invalid token format - Check Bearer prefix
   - Wrong region - Ensure token matches API region

2. **403 Forbidden**
   - Missing scope - Request appropriate scope
   - Protected endpoint - Use Authorization Code flow

3. **429 Too Many Requests**
   - Rate limit exceeded - Implement backoff
   - Cache responses - Reduce API calls

4. **503 Service Unavailable**
   - Maintenance - Check BlizzardCS Twitter
   - Temporary issue - Retry with backoff

## Additional Resources

- [Official Battle.net API Documentation](https://develop.battle.net/documentation)
- [API Forums](https://us.forums.blizzard.com/en/blizzard/c/api-discussion)
- [BlizzardCS Twitter](https://twitter.com/BlizzardCS) - Service status
- [API Status Page](https://develop.battle.net/support)