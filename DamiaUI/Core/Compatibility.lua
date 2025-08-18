--[[
===============================================================================
DamiaUI - WoW API Compatibility Layer
===============================================================================
Provides compatibility wrappers for deprecated WoW API functions across
multiple game versions (Retail, Classic Era, Wrath Classic, Cata Classic).

This module ensures that the addon works correctly across all supported
WoW versions by providing modern API replacements while maintaining
backward compatibility.

Features:
- Automatic API version detection
- Compatibility wrappers for deprecated functions
- Multi-version support (11.2.x, 4.4.x, 3.4.x, 1.15.x)
- Runtime API availability checking
- Performance optimized function references

Author: DamiaUI Development Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Early return if compatibility already loaded
if DamiaUI.Compatibility then
    return DamiaUI.Compatibility
end

-- Local references for performance
local _G = _G
local type = type
local pcall = pcall
local select = select
local tinsert = table.insert

-- Create Compatibility module
local Compatibility = {}
DamiaUI.Compatibility = Compatibility

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

--[[
===============================================================================
AURA SYSTEM COMPATIBILITY
===============================================================================
--]]

-- UnitAura replacement with C_UnitAuras.GetAuraDataByIndex compatibility
local function CompatibleUnitAura(unit, index, filter)
    -- Modern API (11.0+)
    if APIExists("C_UnitAuras.GetAuraDataByIndex") then
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name,
                   auraData.icon,
                   auraData.applications,
                   auraData.dispelName,
                   auraData.duration,
                   auraData.expirationTime,
                   auraData.sourceUnit,
                   auraData.isStealable,
                   auraData.nameplateShowPersonal,
                   auraData.spellId,
                   auraData.canApplyAura,
                   auraData.isBossAura,
                   auraData.isFromPlayerOrPlayerPet,
                   auraData.nameplateShowAll,
                   auraData.timeMod,
                   auraData.canDispel or auraData.isDispellable
        end
        return nil
    end
    
    -- Legacy API fallback
    if _G.UnitAura then
        return UnitAura(unit, index, filter)
    end
    
    return nil
end

-- UnitBuff compatibility wrapper
local function CompatibleUnitBuff(unit, index, filter)
    return CompatibleUnitAura(unit, index, filter or "HELPFUL")
end

-- UnitDebuff compatibility wrapper
local function CompatibleUnitDebuff(unit, index, filter)
    return CompatibleUnitAura(unit, index, filter or "HARMFUL")
end

--[[
===============================================================================
SPELL SYSTEM COMPATIBILITY
===============================================================================
--]]

-- GetSpellInfo replacement with C_Spell.GetSpellInfo compatibility
local function CompatibleGetSpellInfo(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.GetSpellInfo") then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name,
                   nil, -- rank (removed in modern API)
                   spellInfo.iconID,
                   spellInfo.castTime,
                   spellInfo.minRange,
                   spellInfo.maxRange,
                   spellInfo.spellID,
                   spellInfo.originalIconID
        end
        return nil
    end
    
    -- Legacy API fallback
    if _G.GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    
    return nil
end

-- GetSpellCooldown replacement
local function CompatibleGetSpellCooldown(spellID)
    -- Modern API (11.0+)  
    if APIExists("C_Spell.GetSpellCooldown") then
        local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if cooldownInfo then
            return cooldownInfo.startTime,
                   cooldownInfo.duration,
                   cooldownInfo.isEnabled,
                   cooldownInfo.modRate
        end
        return nil
    end
    
    -- Legacy API fallback
    if _G.GetSpellCooldown then
        return GetSpellCooldown(spellID)
    end
    
    return nil
end

-- GetSpellTexture replacement
local function CompatibleGetSpellTexture(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.GetSpellTexture") then
        return C_Spell.GetSpellTexture(spellID)
    end
    
    -- Legacy API fallback
    if _G.GetSpellTexture then
        return GetSpellTexture(spellID)
    end
    
    return nil
end

-- GetSpellCharges replacement
local function CompatibleGetSpellCharges(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.GetSpellCharges") then
        local chargeInfo = C_Spell.GetSpellCharges(spellID)
        if chargeInfo then
            return chargeInfo.currentCharges,
                   chargeInfo.maxCharges,
                   chargeInfo.cooldownStartTime,
                   chargeInfo.cooldownDuration,
                   chargeInfo.chargeModRate
        end
        return nil
    end
    
    -- Legacy API fallback
    if _G.GetSpellCharges then
        return GetSpellCharges(spellID)
    end
    
    return nil
end

-- IsUsableSpell replacement
local function CompatibleIsUsableSpell(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.IsSpellUsable") then
        local usableInfo = C_Spell.IsSpellUsable(spellID)
        if usableInfo then
            return usableInfo.isUsable, usableInfo.noMana
        end
        return false, false
    end
    
    -- Legacy API fallback
    if _G.IsUsableSpell then
        return IsUsableSpell(spellID)
    end
    
    return false, false
end

-- GetSpellDescription replacement
local function CompatibleGetSpellDescription(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.GetSpellDescription") then
        return C_Spell.GetSpellDescription(spellID)
    end
    
    -- Legacy API fallback
    if _G.GetSpellDescription then
        return GetSpellDescription(spellID)
    end
    
    return nil
end

-- GetSpellCount replacement (now GetSpellCastCount)
local function CompatibleGetSpellCount(spellID)
    -- Modern API (11.0+)
    if APIExists("C_Spell.GetSpellCastCount") then
        return C_Spell.GetSpellCastCount(spellID)
    end
    
    -- Legacy API fallback
    if _G.GetSpellCount then
        return GetSpellCount(spellID)
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
    -- Modern API (9.0+)
    if APIExists("C_Guild.IsGuildMember") then
        return C_Guild.IsGuildMember()
    end
    
    -- Legacy API fallback
    if _G.IsInGuild then
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
    
    -- Legacy API fallback
    if _G.GetRealmName then
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
    
    -- Legacy PlaySound for sound IDs
    if _G.PlaySound then
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
    
    if _G.GetNumSpellTabs then
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
    
    if _G.GetSpellTabInfo then
        return GetSpellTabInfo(index)
    end
    
    return nil
end

-- GetSpellBookItemName replacement
local function CompatibleGetSpellBookItemName(index, bookType)
    if APIExists("C_SpellBook.GetSpellBookItemName") then
        return C_SpellBook.GetSpellBookItemName(index, bookType)
    end
    
    if _G.GetSpellBookItemName then
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
    
    -- Spell System
    self.GetSpellInfo = CompatibleGetSpellInfo
    self.GetSpellCooldown = CompatibleGetSpellCooldown
    self.GetSpellTexture = CompatibleGetSpellTexture
    self.GetSpellCharges = CompatibleGetSpellCharges
    self.IsUsableSpell = CompatibleIsUsableSpell
    self.GetSpellDescription = CompatibleGetSpellDescription
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
    self.IS_RETAIL = IS_RETAIL
    self.IS_CATA_CLASSIC = IS_CATA_CLASSIC
    self.IS_WRATH_CLASSIC = IS_WRATH_CLASSIC
    self.IS_CLASSIC_ERA = IS_CLASSIC_ERA
    
    -- Utility functions
    self.APIExists = APIExists
    self.SafeAPICall = SafeAPICall
    
    self.isInitialized = true
    
    if DamiaUI.Engine then
        DamiaUI.Engine:LogInfo("Compatibility layer initialized for WoW %s (Build %s)", WOW_VERSION, WOW_BUILD)
    end
end

-- Get version information
function Compatibility:GetVersionInfo()
    return {
        version = WOW_VERSION,
        build = WOW_BUILD,
        majorVersion = WOW_VERSION_MAJOR,
        tocVersion = TOC_VERSION,
        isRetail = IS_RETAIL,
        isCataClassic = IS_CATA_CLASSIC,
        isWrathClassic = IS_WRATH_CLASSIC,
        isClassicEra = IS_CLASSIC_ERA
    }
end

-- Check if specific API is available
function Compatibility:IsAPIAvailable(apiName)
    return APIExists(apiName)
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
    -- Fallback logging if Engine not available
    print(string.format("[DamiaUI] Compatibility layer loaded for WoW %s", WOW_VERSION))
end

return Compatibility