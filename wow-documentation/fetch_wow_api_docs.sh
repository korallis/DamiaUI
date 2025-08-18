#!/bin/bash

# Battle.net API Documentation Fetcher
# Access token obtained from OAuth
ACCESS_TOKEN="EU8Bpylb209mrN1iibdnAZicDbHRIcQR2b"
BASE_URL="https://us.api.blizzard.com"
EU_BASE_URL="https://eu.api.blizzard.com"
DOC_DIR="/Users/lee/Library/Mobile Documents/com~apple~CloudDocs/Dev/Damia/wow-documentation"

# Create directories
mkdir -p "$DOC_DIR/game-data-apis"
mkdir -p "$DOC_DIR/profile-apis"
mkdir -p "$DOC_DIR/classic-apis"
mkdir -p "$DOC_DIR/guides"

# Function to fetch and save API response
fetch_api() {
    local endpoint=$1
    local output_file=$2
    local description=$3
    
    echo "Fetching: $description"
    echo "# $description" > "$output_file"
    echo "" >> "$output_file"
    echo "## Endpoint" >> "$output_file"
    echo "\`\`\`" >> "$output_file"
    echo "GET $endpoint" >> "$output_file"
    echo "\`\`\`" >> "$output_file"
    echo "" >> "$output_file"
    echo "## Response" >> "$output_file"
    echo "\`\`\`json" >> "$output_file"
    curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$BASE_URL$endpoint" | python3 -m json.tool >> "$output_file" 2>/dev/null || echo "Error fetching data" >> "$output_file"
    echo "\`\`\`" >> "$output_file"
    echo "" >> "$output_file"
}

# Game Data API Endpoints
echo "Fetching Game Data API Documentation..."

# Achievement APIs
fetch_api "/data/wow/achievement-category/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/achievement-categories-index.md" "Achievement Categories Index"
fetch_api "/data/wow/achievement/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/achievements-index.md" "Achievements Index"

# Auction House API
fetch_api "/data/wow/connected-realm/11/auctions?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/auction-house.md" "Auction House Data"

# Connected Realm API
fetch_api "/data/wow/connected-realm/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/connected-realms-index.md" "Connected Realms Index"

# Covenant API
fetch_api "/data/wow/covenant/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/covenants-index.md" "Covenants Index"

# Creature API
fetch_api "/data/wow/creature-family/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/creature-families.md" "Creature Families"
fetch_api "/data/wow/creature-type/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/creature-types.md" "Creature Types"

# Guild Crest API
fetch_api "/data/wow/guild-crest/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/guild-crests.md" "Guild Crests"

# Item API
fetch_api "/data/wow/item-class/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/item-classes.md" "Item Classes"

# Journal API
fetch_api "/data/wow/journal-expansion/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/journal-expansions.md" "Journal Expansions"
fetch_api "/data/wow/journal-encounter/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/journal-encounters.md" "Journal Encounters"
fetch_api "/data/wow/journal-instance/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/journal-instances.md" "Journal Instances"

# Media API
fetch_api "/data/wow/media/creature-display/30221?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/media-creature-display.md" "Creature Display Media"
fetch_api "/data/wow/media/item/19019?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/media-item.md" "Item Media"

# Mount API
fetch_api "/data/wow/mount/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/mounts-index.md" "Mounts Index"

# Mythic Keystone API
fetch_api "/data/wow/mythic-keystone/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-keystone-index.md" "Mythic Keystone Index"
fetch_api "/data/wow/mythic-keystone/dungeon/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-keystone-dungeons.md" "Mythic Keystone Dungeons"
fetch_api "/data/wow/mythic-keystone/period/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-keystone-periods.md" "Mythic Keystone Periods"
fetch_api "/data/wow/mythic-keystone/season/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-keystone-seasons.md" "Mythic Keystone Seasons"

# Mythic Keystone Leaderboard API
fetch_api "/data/wow/connected-realm/11/mythic-leaderboard/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-leaderboard-index.md" "Mythic Keystone Leaderboard Index"

# Mythic Raid Leaderboard API
fetch_api "/data/wow/leaderboard/hall-of-fame/ny-alotha-the-waking-city/alliance?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/mythic-raid-leaderboard.md" "Mythic Raid Leaderboard"

# Pet API
fetch_api "/data/wow/pet/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/pets-index.md" "Pets Index"

# Playable Class API
fetch_api "/data/wow/playable-class/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/playable-classes.md" "Playable Classes"
fetch_api "/data/wow/playable-class/7?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/playable-class-shaman.md" "Playable Class - Shaman"

# Playable Race API
fetch_api "/data/wow/playable-race/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/playable-races.md" "Playable Races"

# Playable Specialization API
fetch_api "/data/wow/playable-specialization/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/playable-specializations.md" "Playable Specializations"
fetch_api "/data/wow/playable-specialization/262?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/playable-spec-elemental.md" "Playable Specialization - Elemental"

# Power Type API
fetch_api "/data/wow/power-type/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/power-types.md" "Power Types"

# Profession API
fetch_api "/data/wow/profession/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/professions-index.md" "Professions Index"

# PvP Season API
fetch_api "/data/wow/pvp-season/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-seasons-index.md" "PvP Seasons Index"
fetch_api "/data/wow/pvp-season/27?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-season-27.md" "PvP Season 27"

# PvP Leaderboards API
fetch_api "/data/wow/pvp-season/27/pvp-leaderboard/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-leaderboards-index.md" "PvP Leaderboards Index"
fetch_api "/data/wow/pvp-season/27/pvp-leaderboard/3v3?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-leaderboard-3v3.md" "PvP Leaderboard 3v3"

# PvP Rewards API
fetch_api "/data/wow/pvp-season/27/pvp-reward/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-rewards.md" "PvP Rewards Index"

# Quest API
fetch_api "/data/wow/quest/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/quests-index.md" "Quests Index"
fetch_api "/data/wow/quest/area/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/quest-areas.md" "Quest Areas"
fetch_api "/data/wow/quest/category/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/quest-categories.md" "Quest Categories"
fetch_api "/data/wow/quest/type/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/quest-types.md" "Quest Types"

# Realm API
fetch_api "/data/wow/realm/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/realms-index.md" "Realms Index"
fetch_api "/data/wow/realm/tichondrius?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/realm-tichondrius.md" "Realm - Tichondrius"

# Region API
fetch_api "/data/wow/region/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/regions-index.md" "Regions Index"
fetch_api "/data/wow/region/1?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/region-us.md" "Region - US"

# Reputations API
fetch_api "/data/wow/reputation-faction/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/reputation-factions.md" "Reputation Factions"
fetch_api "/data/wow/reputation-tiers/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/reputation-tiers.md" "Reputation Tiers"

# Spell API
fetch_api "/data/wow/spell/196607?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/spell-example.md" "Spell Example"

# Talent API
fetch_api "/data/wow/talent/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/talents-index.md" "Talents Index"
fetch_api "/data/wow/pvp-talent/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/pvp-talents.md" "PvP Talents"

# Tech Talent API
fetch_api "/data/wow/tech-talent-tree/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/tech-talent-trees.md" "Tech Talent Trees"
fetch_api "/data/wow/tech-talent/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/tech-talents.md" "Tech Talents"

# Title API
fetch_api "/data/wow/title/index?namespace=static-us&locale=en_US" "$DOC_DIR/game-data-apis/titles-index.md" "Titles Index"

# WoW Token API
fetch_api "/data/wow/token/index?namespace=dynamic-us&locale=en_US" "$DOC_DIR/game-data-apis/wow-token.md" "WoW Token"

echo "Game Data API documentation fetched successfully!"

# Create main index file
cat > "$DOC_DIR/game-data-apis/README.md" << 'EOF'
# World of Warcraft Game Data APIs

This directory contains documentation for all World of Warcraft Game Data APIs fetched from the official Battle.net API.

## API Categories

### Achievement APIs
- [Achievement Categories Index](achievement-categories-index.md)
- [Achievements Index](achievements-index.md)

### Auction House API
- [Auction House Data](auction-house.md)

### Connected Realm API
- [Connected Realms Index](connected-realms-index.md)

### Covenant API
- [Covenants Index](covenants-index.md)

### Creature API
- [Creature Families](creature-families.md)
- [Creature Types](creature-types.md)

### Guild Crest API
- [Guild Crests](guild-crests.md)

### Item API
- [Item Classes](item-classes.md)

### Journal API
- [Journal Expansions](journal-expansions.md)
- [Journal Encounters](journal-encounters.md)
- [Journal Instances](journal-instances.md)

### Media API
- [Creature Display Media](media-creature-display.md)
- [Item Media](media-item.md)

### Mount API
- [Mounts Index](mounts-index.md)

### Mythic Keystone API
- [Mythic Keystone Index](mythic-keystone-index.md)
- [Mythic Keystone Dungeons](mythic-keystone-dungeons.md)
- [Mythic Keystone Periods](mythic-keystone-periods.md)
- [Mythic Keystone Seasons](mythic-keystone-seasons.md)

### Mythic Keystone Leaderboard API
- [Mythic Keystone Leaderboard Index](mythic-leaderboard-index.md)

### Mythic Raid Leaderboard API
- [Mythic Raid Leaderboard](mythic-raid-leaderboard.md)

### Pet API
- [Pets Index](pets-index.md)

### Playable Class API
- [Playable Classes](playable-classes.md)
- [Playable Class - Shaman](playable-class-shaman.md)

### Playable Race API
- [Playable Races](playable-races.md)

### Playable Specialization API
- [Playable Specializations](playable-specializations.md)
- [Playable Specialization - Elemental](playable-spec-elemental.md)

### Power Type API
- [Power Types](power-types.md)

### Profession API
- [Professions Index](professions-index.md)

### PvP Season API
- [PvP Seasons Index](pvp-seasons-index.md)
- [PvP Season 27](pvp-season-27.md)

### PvP Leaderboards API
- [PvP Leaderboards Index](pvp-leaderboards-index.md)
- [PvP Leaderboard 3v3](pvp-leaderboard-3v3.md)

### PvP Rewards API
- [PvP Rewards Index](pvp-rewards.md)

### Quest API
- [Quests Index](quests-index.md)
- [Quest Areas](quest-areas.md)
- [Quest Categories](quest-categories.md)
- [Quest Types](quest-types.md)

### Realm API
- [Realms Index](realms-index.md)
- [Realm - Tichondrius](realm-tichondrius.md)

### Region API
- [Regions Index](regions-index.md)
- [Region - US](region-us.md)

### Reputations API
- [Reputation Factions](reputation-factions.md)
- [Reputation Tiers](reputation-tiers.md)

### Spell API
- [Spell Example](spell-example.md)

### Talent API
- [Talents Index](talents-index.md)
- [PvP Talents](pvp-talents.md)

### Tech Talent API
- [Tech Talent Trees](tech-talent-trees.md)
- [Tech Talents](tech-talents.md)

### Title API
- [Titles Index](titles-index.md)

### WoW Token API
- [WoW Token](wow-token.md)

## Authentication

All APIs require an OAuth 2.0 access token. See the main documentation for authentication details.

## Namespaces

WoW APIs use namespaces to separate different types of data:
- `static` - Game data that doesn't change frequently (items, spells, etc.)
- `dynamic` - Realm-specific data that updates regularly (auctions, leaderboards, etc.)
- `profile` - Character-specific data

## Localization

All endpoints support localization via the `locale` parameter. Common locales:
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
- zh_CN - Simplified Chinese

EOF

echo "Documentation fetch script created!"