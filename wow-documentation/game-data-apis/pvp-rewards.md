# PvP Rewards Index

## Endpoint
```
GET /data/wow/pvp-season/27/pvp-reward/index?namespace=dynamic-us&locale=en_US
```

## Response
```json
{
    "_links": {
        "self": {
            "href": "https://us.api.blizzard.com/data/wow/pvp-season/27/pvp-reward/?namespace=dynamic-us"
        }
    },
    "season": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/pvp-season/27?namespace=dynamic-us"
        },
        "id": 27
    },
    "rewards": [
        {
            "bracket": {
                "id": 3,
                "type": "BATTLEGROUNDS"
            },
            "achievement": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/achievement/13211?namespace=static-8.2.0_30827-us"
                },
                "name": "Hero of the Horde: Sinister",
                "id": 13211
            },
            "rating_cutoff": 2397,
            "faction": {
                "type": "HORDE",
                "name": "Horde"
            }
        },
        {
            "bracket": {
                "id": 3,
                "type": "BATTLEGROUNDS"
            },
            "achievement": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/achievement/13210?namespace=static-8.2.0_30827-us"
                },
                "name": "Hero of the Alliance: Sinister",
                "id": 13210
            },
            "rating_cutoff": 2322,
            "faction": {
                "type": "ALLIANCE",
                "name": "Alliance"
            }
        },
        {
            "bracket": {
                "id": 1,
                "type": "ARENA_3v3"
            },
            "achievement": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/achievement/13200?namespace=static-8.2.0_30827-us"
                },
                "name": "Sinister Gladiator: Battle for Azeroth Season 2",
                "id": 13200
            },
            "rating_cutoff": 2952,
            "faction": {
                "type": "HORDE",
                "name": "Horde"
            }
        },
        {
            "bracket": {
                "id": 1,
                "type": "ARENA_3v3"
            },
            "achievement": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/achievement/13200?namespace=static-8.2.0_30827-us"
                },
                "name": "Sinister Gladiator: Battle for Azeroth Season 2",
                "id": 13200
            },
            "rating_cutoff": 3002,
            "faction": {
                "type": "ALLIANCE",
                "name": "Alliance"
            }
        }
    ]
}
```

