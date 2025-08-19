--[[
===============================================================================
DamiaUI - WoW API Compatibility Layer
===============================================================================
Provides compatibility wrappers for deprecated WoW API functions across
multiple game versions (Retail, Classic Era, Wrath Classic, Cata Classic).

This module ensures that the addon works correctly across all supported
WoW versions by providing modern API replacements while maintaining
backward compatibility with legacy APIs.

Features:
- Automatic API version detection and build number checking
- Modern C_* namespace API support (C_UnitAuras, C_Spell, etc.)
- Compatibility wrappers for deprecated functions
- Multi-version support (11.2.x+, 4.4.x, 3.4.x, 1.15.x)
- Runtime API availability checking with caching
- Performance optimized function references
- Proper nil checking and parameter validation
- Legacy return format preservation

Supported Modern APIs:
- C_UnitAuras.GetAuraDataByIndex, GetBuffDataByIndex, GetDebuffDataByIndex
- C_Spell.GetSpellInfo, GetSpellName, GetSpellCooldown, etc.
- Proper handling of UnitAuraInfo and SpellInfo structures

Author: DamiaUI Development Team
Version: 2.0.0 - Updated for WoW 11.2+ API compatibility
===============================================================================
--]]

local _, DamiaUI = ...

-- Early return if compatibility already loaded
if DamiaUI.Compatibility then
    return DamiaUI.Compatibility
end

-- Local references for performance
local _G = _G
local type = type
local pcall = pcall
local select = select
local strsplit = strsplit

-- Create Compatibility module
local Compatibility = {}
DamiaUI.Compatibility = Compatibility

-- Suppress WoW API global warnings for this file
---@diagnostic disable: undefined-global, undefined-field

-- Version detection and constants
local WOW_VERSION = select(1, GetBuildInfo())
local WOW_BUILD = select(2, GetBuildInfo())
local WOW_VERSION_MAJOR = tonumber(select(1, strsplit(".", WOW_VERSION)))
local TOC_VERSION = select(4, GetBuildInfo())

-- Version flags for easy checking
local IS_RETAIL = WOW_VERSION_MAJOR >= 10
local IS_CATA_CLASSIC = WOW_VERSION_MAJOR >= 4 and WOW_VERSION_MAJOR < 10
local IS_WRATH_CLASSIC = WOW_VERSION_MAJOR >= 3 and WOW_VERSION_MAJOR < 4
local IS_CLASSIC_ERA = WOW_VERSION_MAJOR >= 1 and WOW_VERSION_MAJOR < 3

-- Build number for more precise version checking
local BUILD_NUMBER = tonumber(WOW_BUILD) or 0

-- Modern API availability (11.0+ generally)
-- Note: These will be properly checked after APIExists is defined
local HAS_MODERN_AURA_API = false
local HAS_MODERN_SPELL_API = false

-- WoW Project ID compatibility (may not exist in all versions)
---@diagnostic disable-next-line: undefined-global
local WOW_PROJECT_ID = WOW_PROJECT_ID or (IS_RETAIL and 1 or IS_CLASSIC_ERA and 2 or IS_WRATH_CLASSIC and 3 or IS_CATA_CLASSIC and 4 or 0)
---@diagnostic disable-next-line: undefined-global
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE or 1

-- API availability cache for performance
local apiCache = {}

--[[
===============================================================================
UTILITY FUNCTIONS
===============================================================================
--]]

-- Check if an API exists and cache the result
local function APIExists(apiName)
    if apiCache[apiName] ~= nil then
        return apiCache[apiName]
    end
    
    local exists = false
    if apiName:find("%.") then
        -- Namespaced API (e.g., "C_Spell.GetSpellInfo")
        local namespace, funcName = strsplit(".", apiName)
        local namespaceTable = _G[namespace]
        exists = namespaceTable and type(namespaceTable[funcName]) == "function"
    else
        -- Global API
        exists = type(_G[apiName]) == "function"
    end
    
    apiCache[apiName] = exists
    return exists
end

-- Safe function call with fallback
local function SafeAPICall(func, ...)
    if type(func) == "function" then
        local success, result = pcall(func, ...)
        if success then
            return result
        end
    end
    return nil
end

-- Initialize modern API availability flags after APIExists is defined
HAS_MODERN_AURA_API = BUILD_NUMBER >= 110000 and APIExists("C_UnitAuras.GetAuraDataByIndex")
HAS_MODERN_SPELL_API = BUILD_NUMBER >= 110000 and APIExists("C_Spell.GetSpellInfo")

--[[
===============================================================================
AURA SYSTEM COMPATIBILITY
===============================================================================
--]]

-- UnitAura replacement with C_UnitAuras.GetAuraDataByIndex compatibility
local function CompatibleUnitAura(unit, index, filter)
    -- Validate parameters
    if not unit or not index then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_AURA_API and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if auraData then
            -- Convert modern structure to legacy return format
            -- Return values match original UnitAura signature:
            -- name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
            -- nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isFromPlayerOrPlayerPet,
            -- nameplateShowAll, timeMod, isDispellable
            
            return auraData.name or nil,
                   auraData.icon or nil,
                   auraData.applications or 0,
                   auraData.dispelName or nil,
                   auraData.duration or 0,
                   auraData.expirationTime or 0,
                   auraData.sourceUnit or nil,
                   auraData.isStealable or false,
                   auraData.nameplateShowPersonal or false,
                   auraData.spellId or nil,
                   auraData.canApplyAura or false,
                   auraData.isBossAura or false,
                   auraData.isFromPlayerOrPlayerPet or false,
                   auraData.nameplateShowAll or false,
                   auraData.timeMod or 1,
                   (auraData.isDispellable ~= nil) and auraData.isDispellable or false
        end
        return nil
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.UnitAura and type(_G.UnitAura) == "function" then
        return UnitAura(unit, index, filter)
    end
    
    return nil
end

-- UnitBuff compatibility wrapper  
local function CompatibleUnitBuff(unit, index, filter)
    -- Validate parameters
    if not unit or not index then
        return nil
    end
    
    -- Modern API (11.0+) - use specific buff function if available
    if HAS_MODERN_AURA_API and C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, index)
        if auraData then
            -- Convert to legacy format
            return auraData.name or nil,
                   auraData.icon or nil,
                   auraData.applications or 0,
                   auraData.dispelName or nil,
                   auraData.duration or 0,
                   auraData.expirationTime or 0,
                   auraData.sourceUnit or nil,
                   auraData.isStealable or false,
                   auraData.nameplateShowPersonal or false,
                   auraData.spellId or nil,
                   auraData.canApplyAura or false,
                   auraData.isBossAura or false,
                   auraData.isFromPlayerOrPlayerPet or false,
                   auraData.nameplateShowAll or false,
                   auraData.timeMod or 1,
                   (auraData.isDispellable ~= nil) and auraData.isDispellable or false
        end
        return nil
    end
    
    -- Fallback to general aura function
    return CompatibleUnitAura(unit, index, filter or "HELPFUL")
end

-- UnitDebuff compatibility wrapper
local function CompatibleUnitDebuff(unit, index, filter)
    -- Validate parameters
    if not unit or not index then
        return nil
    end
    
    -- Modern API (11.0+) - use specific debuff function if available
    if HAS_MODERN_AURA_API and C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, index)
        if auraData then
            -- Convert to legacy format
            return auraData.name or nil,
                   auraData.icon or nil,
                   auraData.applications or 0,
                   auraData.dispelName or nil,
                   auraData.duration or 0,
                   auraData.expirationTime or 0,
                   auraData.sourceUnit or nil,
                   auraData.isStealable or false,
                   auraData.nameplateShowPersonal or false,
                   auraData.spellId or nil,
                   auraData.canApplyAura or false,
                   auraData.isBossAura or false,
                   auraData.isFromPlayerOrPlayerPet or false,
                   auraData.nameplateShowAll or false,
                   auraData.timeMod or 1,
                   (auraData.isDispellable ~= nil) and auraData.isDispellable or false
        end
        return nil
    end
    
    -- Fallback to general aura function
    return CompatibleUnitAura(unit, index, filter or "HARMFUL")
end

--[[
===============================================================================
SPELL SYSTEM COMPATIBILITY
===============================================================================
--]]

-- GetSpellInfo replacement with C_Spell.GetSpellInfo compatibility
local function CompatibleGetSpellInfo(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
        if spellInfo then
            -- Convert modern structure to legacy return format:
            -- name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon
            return spellInfo.name or nil,
                   nil, -- rank (removed in modern API)
                   spellInfo.iconID or nil,
                   spellInfo.castTime or 0,
                   spellInfo.minRange or 0,
                   spellInfo.maxRange or 0,
                   spellInfo.spellID or nil,
                   spellInfo.originalIconID or spellInfo.iconID
        end
        return nil
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellInfo and type(_G.GetSpellInfo) == "function" then
        return GetSpellInfo(spellIdentifier)
    end
    
    return nil
end

-- GetSpellCooldown replacement
local function CompatibleGetSpellCooldown(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)  
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellCooldown then
        local cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
        if cooldownInfo then
            -- Convert to legacy format: startTime, duration, enabled, modRate
            return cooldownInfo.startTime or 0,
                   cooldownInfo.duration or 0,
                   (cooldownInfo.isEnabled ~= nil) and cooldownInfo.isEnabled or true,
                   cooldownInfo.modRate or 1
        end
        return 0, 0, true, 1
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellCooldown and type(_G.GetSpellCooldown) == "function" then
        return GetSpellCooldown(spellIdentifier)
    end
    
    return 0, 0, true, 1
end

-- GetSpellTexture replacement
local function CompatibleGetSpellTexture(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdentifier)
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellTexture and type(_G.GetSpellTexture) == "function" then
        return GetSpellTexture(spellIdentifier)
    end
    
    return nil
end

-- GetSpellCharges replacement
local function CompatibleGetSpellCharges(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellCharges then
        local chargeInfo = C_Spell.GetSpellCharges(spellIdentifier)
        if chargeInfo then
            -- Convert to legacy format: currentCharges, maxCharges, cooldownStartTime, cooldownDuration, chargeModRate
            return chargeInfo.currentCharges or 0,
                   chargeInfo.maxCharges or 0,
                   chargeInfo.cooldownStartTime or 0,
                   chargeInfo.cooldownDuration or 0,
                   chargeInfo.chargeModRate or 1
        end
        return nil
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellCharges and type(_G.GetSpellCharges) == "function" then
        return GetSpellCharges(spellIdentifier)
    end
    
    return nil
end

-- IsUsableSpell replacement
local function CompatibleIsUsableSpell(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return false, false
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.IsSpellUsable then
        local usableInfo = C_Spell.IsSpellUsable(spellIdentifier)
        if usableInfo then
            -- Convert to legacy format: isUsable, noMana
            -- Handle different field names across versions
            local isUsable = usableInfo.usable or usableInfo.isUsable or false
            local noMana = usableInfo.insufficientPower or usableInfo.noMana or false
            return isUsable, noMana
        end
        return false, false
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.IsUsableSpell and type(_G.IsUsableSpell) == "function" then
        return IsUsableSpell(spellIdentifier)
    end
    
    return false, false
end

-- GetSpellDescription replacement
local function CompatibleGetSpellDescription(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellDescription then
        return C_Spell.GetSpellDescription(spellIdentifier)
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellDescription and type(_G.GetSpellDescription) == "function" then
        return GetSpellDescription(spellIdentifier)
    end
    
    return nil
end

-- GetSpellCount replacement (now GetSpellCastCount)
local function CompatibleGetSpellCount(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellCastCount then
        return C_Spell.GetSpellCastCount(spellIdentifier)
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellCount and type(_G.GetSpellCount) == "function" then
        return GetSpellCount(spellIdentifier)
    end
    
    return nil
end

-- Additional modern API wrappers for WoW 11.2+

-- GetSpellName wrapper
local function CompatibleGetSpellName(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellIdentifier)
    end
    
    -- Fallback to GetSpellInfo for name only
    local name = CompatibleGetSpellInfo(spellIdentifier)
    return name
end

-- IsSpellKnown replacement
local function CompatibleIsSpellKnown(spellIdentifier, isPetSpell)
    -- Validate parameter
    if not spellIdentifier then
        return false
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellIdentifier, isPetSpell)
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.IsSpellKnown and type(_G.IsSpellKnown) == "function" then
        return IsSpellKnown(spellIdentifier, isPetSpell)
    end
    
    return false
end

-- GetSpellSubtext replacement
local function CompatibleGetSpellSubtext(spellIdentifier)
    -- Validate parameter
    if not spellIdentifier then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_SPELL_API and C_Spell and C_Spell.GetSpellSubtext then
        return C_Spell.GetSpellSubtext(spellIdentifier)
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellSubtext and type(_G.GetSpellSubtext) == "function" then
        return GetSpellSubtext(spellIdentifier)
    end
    
    return nil
end

-- Additional UnitAura helper functions

-- Get aura by spell ID (convenience wrapper)
local function CompatibleGetAuraBySpellID(unit, spellID, filter)
    -- Validate parameters
    if not unit or not spellID then
        return nil
    end
    
    -- Modern API (11.0+)
    if HAS_MODERN_AURA_API and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        -- Use specific player aura function if querying player
        if unit == "player" then
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if auraData then
                return auraData.name, auraData.icon, auraData.applications, auraData.dispelName,
                       auraData.duration, auraData.expirationTime, auraData.sourceUnit,
                       auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId,
                       auraData.canApplyAura, auraData.isBossAura, auraData.isFromPlayerOrPlayerPet,
                       auraData.nameplateShowAll, auraData.timeMod, auraData.isDispellable
            end
        end
    end
    
    -- Fallback: iterate through auras to find by spell ID
    local index = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable,
              nameplateShowPersonal, currentSpellID, canApplyAura, isBossDebuff,
              isFromPlayerOrPlayerPet, nameplateShowAll, timeMod, isDispellable = CompatibleUnitAura(unit, index, filter)
        
        if not name then
            break
        end
        
        if currentSpellID == spellID then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable,
                   nameplateShowPersonal, currentSpellID, canApplyAura, isBossDebuff,
                   isFromPlayerOrPlayerPet, nameplateShowAll, timeMod, isDispellable
        end
        
        index = index + 1
    end
    
    return nil
end

--[[
===============================================================================
GUILD SYSTEM COMPATIBILITY  
===============================================================================
--]]

-- IsInGuild replacement with C_Guild.IsGuildMember compatibility
local function CompatibleIsInGuild()
    -- Modern API (9.0+) with namespace check
    if C_Guild and C_Guild.IsGuildMember then
        return C_Guild.IsGuildMember()
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.IsInGuild and type(_G.IsInGuild) == "function" then
        return IsInGuild()
    end
    
    return false
end

--[[
===============================================================================
REALM/SERVER COMPATIBILITY
===============================================================================
--]]

-- GetRealmName replacement with GetNormalizedRealmName compatibility
local function CompatibleGetRealmName()
    -- Modern API (10.0+)
    if APIExists("GetNormalizedRealmName") then
        return GetNormalizedRealmName()
    end
    
    -- Legacy API fallback with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetRealmName and type(_G.GetRealmName) == "function" then
        return GetRealmName()
    end
    
    return "Unknown"
end

--[[
===============================================================================
SOUND SYSTEM COMPATIBILITY
===============================================================================
--]]

-- PlaySound replacement with PlaySoundFile compatibility
local function CompatiblePlaySound(soundID, channel)
    -- Modern API preference (PlaySoundFile for custom sounds)
    if type(soundID) == "string" and APIExists("PlaySoundFile") then
        return PlaySoundFile(soundID, channel or "Master")
    end
    
    -- Legacy PlaySound for sound IDs with existence check
    ---@diagnostic disable-next-line: undefined-global
    if _G.PlaySound and type(_G.PlaySound) == "function" then
        return PlaySound(soundID, channel)
    end
    
    return false
end

--[[
===============================================================================
TEXTURE SYSTEM COMPATIBILITY
===============================================================================
--]]

-- Enhanced SetTexture compatibility for solid colors
local function CompatibleSetTexture(textureObject, ...)
    if not textureObject or not textureObject.SetTexture then
        return false
    end
    
    local arg1, arg2, arg3, arg4 = ...
    
    -- Check if we're setting a solid color (4 numeric arguments)
    if type(arg1) == "number" and type(arg2) == "number" and 
       type(arg3) == "number" and (arg4 == nil or type(arg4) == "number") then
        
        -- Modern API (use SetColorTexture for solid colors)
        if textureObject.SetColorTexture then
            textureObject:SetColorTexture(arg1, arg2, arg3, arg4 or 1.0)
            return true
        end
    end
    
    -- Standard texture path or fallback
    return textureObject:SetTexture(arg1, arg2, arg3, arg4)
end

-- Helper function to set white solid texture (replaces WHITE8X8 usage)
local function CompatibleSetSolidTexture(textureObject, r, g, b, a)
    if not textureObject then
        return false
    end
    
    r = r or 1.0
    g = g or 1.0 
    b = b or 1.0
    a = a or 1.0
    
    -- Modern API preference
    if textureObject.SetColorTexture then
        textureObject:SetColorTexture(r, g, b, a)
        return true
    end
    
    -- Fallback to WHITE8X8 for older versions
    if textureObject.SetTexture then
        textureObject:SetTexture("Interface\\Buttons\\WHITE8X8")
        if textureObject.SetVertexColor then
            textureObject:SetVertexColor(r, g, b, a)
        end
        return true
    end
    
    return false
end

--[[
===============================================================================
SPELLBOOK COMPATIBILITY
===============================================================================
--]]

-- GetNumSpellTabs replacement
local function CompatibleGetNumSpellTabs()
    if APIExists("C_SpellBook.GetNumSpellBookSkillLines") then
        return C_SpellBook.GetNumSpellBookSkillLines()
    end
    
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetNumSpellTabs and type(_G.GetNumSpellTabs) == "function" then
        return GetNumSpellTabs()
    end
    
    return 0
end

-- GetSpellTabInfo replacement
local function CompatibleGetSpellTabInfo(index)
    if APIExists("C_SpellBook.GetSpellBookSkillLineInfo") then
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(index)
        if skillLineInfo then
            return skillLineInfo.name,
                   skillLineInfo.iconID,
                   skillLineInfo.itemIndexOffset,
                   skillLineInfo.numSpellBookItems,
                   skillLineInfo.isGuild,
                   skillLineInfo.offSpecID,
                   skillLineInfo.shouldHide,
                   skillLineInfo.specID
        end
        return nil
    end
    
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellTabInfo and type(_G.GetSpellTabInfo) == "function" then
        return GetSpellTabInfo(index)
    end
    
    return nil
end

-- GetSpellBookItemName replacement
local function CompatibleGetSpellBookItemName(index, bookType)
    if APIExists("C_SpellBook.GetSpellBookItemName") then
        return C_SpellBook.GetSpellBookItemName(index, bookType)
    end
    
    ---@diagnostic disable-next-line: undefined-global
    if _G.GetSpellBookItemName and type(_G.GetSpellBookItemName) == "function" then
        return GetSpellBookItemName(index, bookType)
    end
    
    return nil
end

--[[
===============================================================================
COMPATIBILITY API REGISTRATION
===============================================================================
--]]

-- Register all compatibility functions
function Compatibility:Initialize()
    if self.isInitialized then
        return
    end
    
    -- Aura System
    self.UnitAura = CompatibleUnitAura
    self.UnitBuff = CompatibleUnitBuff  
    self.UnitDebuff = CompatibleUnitDebuff
    self.GetAuraBySpellID = CompatibleGetAuraBySpellID
    
    -- Spell System
    self.GetSpellInfo = CompatibleGetSpellInfo
    self.GetSpellName = CompatibleGetSpellName
    self.GetSpellCooldown = CompatibleGetSpellCooldown
    self.GetSpellTexture = CompatibleGetSpellTexture
    self.GetSpellCharges = CompatibleGetSpellCharges
    self.IsUsableSpell = CompatibleIsUsableSpell
    self.IsSpellKnown = CompatibleIsSpellKnown
    self.GetSpellDescription = CompatibleGetSpellDescription
    self.GetSpellSubtext = CompatibleGetSpellSubtext
    self.GetSpellCount = CompatibleGetSpellCount
    
    -- Guild System
    self.IsInGuild = CompatibleIsInGuild
    
    -- Realm/Server
    self.GetRealmName = CompatibleGetRealmName
    
    -- Sound System  
    self.PlaySound = CompatiblePlaySound
    
    -- Texture System
    self.SetTexture = CompatibleSetTexture
    self.SetSolidTexture = CompatibleSetSolidTexture
    
    -- Spellbook System
    self.GetNumSpellTabs = CompatibleGetNumSpellTabs
    self.GetSpellTabInfo = CompatibleGetSpellTabInfo
    self.GetSpellBookItemName = CompatibleGetSpellBookItemName
    
    -- Version information
    self.WOW_VERSION = WOW_VERSION
    self.WOW_BUILD = WOW_BUILD
    self.WOW_VERSION_MAJOR = WOW_VERSION_MAJOR
    self.BUILD_NUMBER = BUILD_NUMBER
    self.IS_RETAIL = IS_RETAIL
    self.IS_CATA_CLASSIC = IS_CATA_CLASSIC
    self.IS_WRATH_CLASSIC = IS_WRATH_CLASSIC
    self.IS_CLASSIC_ERA = IS_CLASSIC_ERA
    self.HAS_MODERN_AURA_API = HAS_MODERN_AURA_API
    self.HAS_MODERN_SPELL_API = HAS_MODERN_SPELL_API
    
    -- Utility functions
    self.APIExists = APIExists
    self.SafeAPICall = SafeAPICall
    
    self.isInitialized = true
    
    if DamiaUI.Engine then
        DamiaUI.Engine:LogInfo("Compatibility layer initialized for WoW %s (Build %s)", WOW_VERSION, WOW_BUILD)
        DamiaUI.Engine:LogDebug("Modern Aura API: %s, Modern Spell API: %s", 
                                tostring(HAS_MODERN_AURA_API), tostring(HAS_MODERN_SPELL_API))
    end
end

-- Get version information
function Compatibility:GetVersionInfo()
    return {
        version = WOW_VERSION,
        build = WOW_BUILD,
        buildNumber = BUILD_NUMBER,
        majorVersion = WOW_VERSION_MAJOR,
        tocVersion = TOC_VERSION,
        isRetail = IS_RETAIL,
        isCataClassic = IS_CATA_CLASSIC,
        isWrathClassic = IS_WRATH_CLASSIC,
        isClassicEra = IS_CLASSIC_ERA,
        hasModernAuraAPI = HAS_MODERN_AURA_API,
        hasModernSpellAPI = HAS_MODERN_SPELL_API
    }
end

-- Check if specific API is available
function Compatibility:IsAPIAvailable(apiName)
    return APIExists(apiName)
end

-- Check if modern APIs should be preferred
function Compatibility:ShouldUseModernAPIs()
    return IS_RETAIL and BUILD_NUMBER >= 110000
end

-- Check if a specific modern API namespace is available
function Compatibility:IsModernNamespaceAvailable(namespace)
    if not namespace then
        return false
    end
    
    local namespaceTable = _G[namespace]
    return namespaceTable and type(namespaceTable) == "table"
end

-- Apply compatibility patches to existing global functions
function Compatibility:ApplyGlobalPatches()
    if not self.isInitialized then
        self:Initialize()
    end
    
    -- Only patch if we're providing better compatibility
    local globalPatches = {
        -- Only patch if modern API is available but old one isn't reliable
        ["UnitAura"] = self.UnitAura,
        ["GetRealmName"] = self.GetRealmName,
    }
    
    for globalName, compatFunc in pairs(globalPatches) do
        if _G[globalName] and APIExists("C_" .. globalName:match("Unit(.+)")) then
            -- Backup original if it exists
            if not _G["_Original" .. globalName] then
                _G["_Original" .. globalName] = _G[globalName]
            end
            
            -- Apply compatibility wrapper
            _G[globalName] = compatFunc
        end
    end
    
    if DamiaUI.Engine then
        DamiaUI.Engine:LogDebug("Applied global compatibility patches")
    end
end

-- Restore original global functions
function Compatibility:RestoreGlobalFunctions()
    local backedUpFunctions = {"UnitAura", "GetRealmName"}
    
    for _, funcName in ipairs(backedUpFunctions) do
        local originalName = "_Original" .. funcName
        if _G[originalName] then
            _G[funcName] = _G[originalName]
            _G[originalName] = nil
        end
    end
    
    if DamiaUI.Engine then
        DamiaUI.Engine:LogDebug("Restored original global functions")
    end
end

--[[
===============================================================================
MODULE INITIALIZATION
===============================================================================
--]]

-- Auto-initialize compatibility layer
Compatibility:Initialize()

-- Log version and compatibility information
if DamiaUI.Engine then
    DamiaUI.Engine:LogInfo("DamiaUI Compatibility Layer loaded")
    DamiaUI.Engine:LogInfo("Detected WoW Version: %s (Build %s)", WOW_VERSION, WOW_BUILD)
    DamiaUI.Engine:LogInfo("Client Type: %s", 
        IS_RETAIL and "Retail" or 
        IS_CATA_CLASSIC and "Cataclysm Classic" or
        IS_WRATH_CLASSIC and "Wrath Classic" or 
        IS_CLASSIC_ERA and "Classic Era" or "Unknown")
else
    -- Fallback logging removed - silent compatibility layer loading
end

return Compatibility