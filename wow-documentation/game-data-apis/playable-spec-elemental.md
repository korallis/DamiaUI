# Playable Specialization - Elemental

## Endpoint
```
GET /data/wow/playable-specialization/262?namespace=static-us&locale=en_US
```

## Response
```json
{
    "_links": {
        "self": {
            "href": "https://us.api.blizzard.com/data/wow/playable-specialization/262?namespace=static-11.2.0_62213-us"
        }
    },
    "id": 262,
    "playable_class": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/playable-class/7?namespace=static-11.2.0_62213-us"
        },
        "name": "Shaman",
        "id": 7
    },
    "name": "Elemental",
    "gender_description": {
        "male": "A spellcaster who harnesses the destructive forces of nature and the elements.\r\n\r\nPreferred Weapon: Mace, Dagger, and Shield",
        "female": "A spellcaster who harnesses the destructive forces of nature and the elements.\r\n\r\nPreferred Weapon: Mace, Dagger, and Shield"
    },
    "media": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/media/playable-specialization/262?namespace=static-11.2.0_62213-us"
        },
        "id": 262
    },
    "role": {
        "type": "DAMAGE",
        "name": "Damage"
    },
    "pvp_talents": [
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/727?namespace=static-11.2.0_62213-us"
                },
                "name": "Static Field Totem",
                "id": 727
            },
            "spell_tooltip": {
                "description": "Summons a totem with 4% of your health at the target location for 6 sec that forms a circuit of electricity that enemies cannot pass through.",
                "cast_time": "Instant",
                "power_cost": "2,500 Mana",
                "range": "30 yd range",
                "cooldown": "1.5 min cooldown"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/3488?namespace=static-11.2.0_62213-us"
                },
                "name": "Totem of Wrath",
                "id": 3488
            },
            "spell_tooltip": {
                "description": "Primordial Wave summons a totem at your feet for 15 sec that increases the critical effect of damage and healing spells of all nearby allies within 40 yards by 15% for 15 sec.\r\n",
                "cast_time": "Passive"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/3490?namespace=static-11.2.0_62213-us"
                },
                "name": "Counterstrike Totem",
                "id": 3490
            },
            "spell_tooltip": {
                "description": "Summons a totem at your feet for 15 sec.\r\n\r\nWhenever enemies within 20 yards of the totem deal direct damage, the totem will deal 100% of the damage dealt back to attacker. ",
                "cast_time": "Instant",
                "power_cost": "1,500 Mana",
                "range": "40 yd range",
                "cooldown": "45 sec cooldown"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/3491?namespace=static-11.2.0_62213-us"
                },
                "name": "Unleash Shield",
                "id": 3491
            },
            "spell_tooltip": {
                "description": "Unleash your Elemental Shield's energy on an enemy target:\r\n\r\nLightning Shield: Knocks them away.\r\n\r\nEarth Shield: Roots them in place for 2 sec.\r\n\r\nWater Shield: Summons a whirlpool for 6 sec, reducing damage and healing by 50% while they stand within it.",
                "cast_time": "Instant",
                "range": "20 yd range",
                "cooldown": "30 sec cooldown"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/3620?namespace=static-11.2.0_62213-us"
                },
                "name": "Grounding Totem",
                "id": 3620
            },
            "spell_tooltip": {
                "description": "Summons a totem at your feet that will redirect all harmful spells cast within 30 yards on a nearby party or raid member to itself. Will not redirect area of effect spells. Lasts 3 sec.",
                "cast_time": "Instant",
                "power_cost": "2,950 Mana",
                "cooldown": "30 sec cooldown"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/5574?namespace=static-11.2.0_62213-us"
                },
                "name": "Burrow",
                "id": 5574
            },
            "spell_tooltip": {
                "description": "Burrow beneath the ground, becoming unattackable, removing movement impairing effects, and increasing your movement speed by 50% for 5 sec.\r\n\r\nWhen the effect ends, enemies within 6 yards are knocked in the air and take 36,498 Physical damage.",
                "cast_time": "Instant",
                "cooldown": "2 min cooldown"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/5659?namespace=static-11.2.0_62213-us"
                },
                "name": "Electrocute",
                "id": 5659
            },
            "spell_tooltip": {
                "description": "When you successfully Purge a beneficial effect, the enemy suffers 23,226 Nature damage over 3 sec.",
                "cast_time": "Passive"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/5660?namespace=static-11.2.0_62213-us"
                },
                "name": "Shamanism",
                "id": 5660
            },
            "spell_tooltip": {
                "description": "Your Bloodlust spell now has a 60 sec. cooldown, but increases Haste by 20%, and only affects you and your friendly target when cast for 10 sec.\r\n\r\nIn addition, Bloodlust is no longer affected by Sated.",
                "cast_time": "Passive"
            }
        },
        {
            "talent": {
                "key": {
                    "href": "https://us.api.blizzard.com/data/wow/pvp-talent/5681?namespace=static-11.2.0_62213-us"
                },
                "name": "Storm Conduit",
                "id": 5681
            },
            "spell_tooltip": {
                "description": "Casting Lightning Bolt or Chain Lightning reduces the cooldown of Astral Shift, Gust of Wind, Wind Shear, and Nature Totems by 1.0 sec.\r\n\r\nInterrupt duration reduced by 30% on Lightning Bolt and Chain Lightning casts.",
                "cast_time": "Passive"
            }
        }
    ],
    "spec_talent_tree": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/talent-tree/786/playable-specialization/262?namespace=static-11.2.0_62213-us"
        },
        "name": "Elemental"
    },
    "power_type": {
        "key": {
            "href": "https://us.api.blizzard.com/data/wow/power-type/11?namespace=static-11.2.0_62213-us"
        },
        "name": "Maelstrom",
        "id": 11
    },
    "primary_stat_type": {
        "type": "INTELLECT",
        "name": "Intellect"
    },
    "hero_talent_trees": [
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/1033/hero-talent/70?namespace=static-11.2.0_62213-us"
            },
            "name": "Stormbringer",
            "id": 70
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/786/hero-talent/55?namespace=static-11.2.0_62213-us"
            },
            "name": "Stormbringer",
            "id": 55
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/1034/hero-talent/73?namespace=static-11.2.0_62213-us"
            },
            "name": "Stormbringer",
            "id": 73
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/786/hero-talent/56?namespace=static-11.2.0_62213-us"
            },
            "name": "Farseer",
            "id": 56
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/1034/hero-talent/75?namespace=static-11.2.0_62213-us"
            },
            "name": "Farseer",
            "id": 75
        },
        {
            "key": {
                "href": "https://us.api.blizzard.com/data/wow/talent-tree/1033/hero-talent/72?namespace=static-11.2.0_62213-us"
            },
            "name": "Farseer",
            "id": 72
        }
    ]
}
```

