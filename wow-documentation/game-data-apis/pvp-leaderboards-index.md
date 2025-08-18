# PvP Leaderboards Index

## Endpoint
```
GET /data/wow/pvp-season/27/pvp-leaderboard/index?namespace=dynamic-us&locale=en_US
```

## Response
```json
{
    "_links": {
        "self": {
            "href": "https://us.api.blizzard.com/data/wow/pvp-season/27/pvp-leaderboard/?namespace=dynamic-us"
        }
    },
    "season": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/pvp-season/27?namespace=dynamic-us"
        },
        "id": 27
    },
    "leaderboards": [
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/pvp-season/27/pvp-leaderboard/2v2?namespace=dynamic-us"
            },
            "name": "2v2",
            "id": 0
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/pvp-season/27/pvp-leaderboard/3v3?namespace=dynamic-us"
            },
            "name": "3v3",
            "id": 1
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/pvp-season/27/pvp-leaderboard/rbg?namespace=dynamic-us"
            },
            "name": "rbg",
            "id": 3
        }
    ]
}
```

