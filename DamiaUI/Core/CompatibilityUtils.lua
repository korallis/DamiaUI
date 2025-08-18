--[[
===============================================================================
DamiaUI - Compatibility Utilities
===============================================================================
Utility functions to help modules integrate with the compatibility layer.
Provides easy-to-use helpers that automatically handle API version differences.

Author: DamiaUI Development Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Early return if already loaded
if DamiaUI.CompatibilityUtils then
    return DamiaUI.CompatibilityUtils
end

-- Local references
local Compatibility = DamiaUI.Compatibility

-- Create CompatibilityUtils module
local CompatibilityUtils = {}
DamiaUI.CompatibilityUtils = CompatibilityUtils

--[[
===============================================================================
TEXTURE UTILITIES
===============================================================================
--]]

-- Set a texture to a solid color (replaces WHITE8X8 usage)
function CompatibilityUtils:SetSolidTexture(textureObject, r, g, b, a)
    if not textureObject then
        return false
    end
    
    if Compatibility and Compatibility.SetSolidTexture then
        return Compatibility.SetSolidTexture(textureObject, r, g, b, a)
    end
    
    -- Fallback if compatibility layer not available
    if textureObject.SetColorTexture then
        textureObject:SetColorTexture(r or 1.0, g or 1.0, b or 1.0, a or 1.0)
        return true
    end
    
    if textureObject.SetTexture then
        textureObject:SetTexture("Interface\\Buttons\\WHITE8X8")
        if textureObject.SetVertexColor then
            textureObject:SetVertexColor(r or 1.0, g or 1.0, b or 1.0, a or 1.0)
        end
        return true
    end
    
    return false
end

-- Apply button texture styling with compatibility
function CompatibilityUtils:StyleActionButton(button, colors)
    if not button then
        return false
    end
    
    colors = colors or {
        normal = {r = 0.3, g = 0.3, b = 0.3, a = 0.8},
        pushed = {r = 0.5, g = 0.5, b = 0.5, a = 0.9},
        highlight = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
        checked = {r = 0.8, g = 0.5, b = 0.1, a = 0.6}
    }
    
    -- Normal texture
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        self:SetSolidTexture(normalTexture, colors.normal.r, colors.normal.g, colors.normal.b, colors.normal.a)
    end
    
    -- Pushed texture
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        self:SetSolidTexture(pushedTexture, colors.pushed.r, colors.pushed.g, colors.pushed.b, colors.pushed.a)
    end
    
    -- Highlight texture
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        self:SetSolidTexture(highlightTexture, colors.highlight.r, colors.highlight.g, colors.highlight.b, colors.highlight.a)
        highlightTexture:SetBlendMode("ADD")
    end
    
    -- Checked texture
    local checkedTexture = button:GetCheckedTexture()
    if checkedTexture then
        self:SetSolidTexture(checkedTexture, colors.checked.r, colors.checked.g, colors.checked.b, colors.checked.a)
    end
    
    return true
end

--[[
===============================================================================
API WRAPPERS
===============================================================================
--]]

-- Wrapper for UnitAura with compatibility
function CompatibilityUtils:UnitAura(unit, index, filter)
    if Compatibility and Compatibility.UnitAura then
        return Compatibility.UnitAura(unit, index, filter)
    end
    
    -- Fallback to global function
    if _G.UnitAura then
        return UnitAura(unit, index, filter)
    end
    
    return nil
end

-- Wrapper for UnitBuff with compatibility
function CompatibilityUtils:UnitBuff(unit, index, filter)
    if Compatibility and Compatibility.UnitBuff then
        return Compatibility.UnitBuff(unit, index, filter)
    end
    
    if _G.UnitBuff then
        return UnitBuff(unit, index, filter)
    end
    
    return nil
end

-- Wrapper for UnitDebuff with compatibility
function CompatibilityUtils:UnitDebuff(unit, index, filter)
    if Compatibility and Compatibility.UnitDebuff then
        return Compatibility.UnitDebuff(unit, index, filter)
    end
    
    if _G.UnitDebuff then
        return UnitDebuff(unit, index, filter)
    end
    
    return nil
end

-- Wrapper for GetSpellInfo with compatibility
function CompatibilityUtils:GetSpellInfo(spellID)
    if Compatibility and Compatibility.GetSpellInfo then
        return Compatibility.GetSpellInfo(spellID)
    end
    
    if _G.GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    
    return nil
end

-- Wrapper for GetRealmName with compatibility
function CompatibilityUtils:GetRealmName()
    if Compatibility and Compatibility.GetRealmName then
        return Compatibility.GetRealmName()
    end
    
    if _G.GetNormalizedRealmName then
        return GetNormalizedRealmName()
    end
    
    if _G.GetRealmName then
        return GetRealmName()
    end
    
    return "Unknown"
end

-- Wrapper for IsInGuild with compatibility
function CompatibilityUtils:IsInGuild()
    if Compatibility and Compatibility.IsInGuild then
        return Compatibility.IsInGuild()
    end
    
    if _G.IsInGuild then
        return IsInGuild()
    end
    
    return false
end

-- Wrapper for PlaySound with compatibility
function CompatibilityUtils:PlaySound(soundID, channel)
    if Compatibility and Compatibility.PlaySound then
        return Compatibility.PlaySound(soundID, channel)
    end
    
    if _G.PlaySound then
        return PlaySound(soundID, channel)
    end
    
    return false
end

--[[
===============================================================================
VERSION CHECKING UTILITIES
===============================================================================
--]]

-- Check if we're running on Retail
function CompatibilityUtils:IsRetail()
    if Compatibility then
        return Compatibility.IS_RETAIL
    end
    
    local version = select(1, GetBuildInfo())
    local majorVersion = tonumber(select(1, strsplit(".", version)))
    return majorVersion and majorVersion >= 10
end

-- Check if we're running on Classic Era
function CompatibilityUtils:IsClassicEra()
    if Compatibility then
        return Compatibility.IS_CLASSIC_ERA
    end
    
    local version = select(1, GetBuildInfo())
    local majorVersion = tonumber(select(1, strsplit(".", version)))
    return majorVersion and majorVersion >= 1 and majorVersion < 3
end

-- Check if we're running on Wrath Classic
function CompatibilityUtils:IsWrathClassic()
    if Compatibility then
        return Compatibility.IS_WRATH_CLASSIC
    end
    
    local version = select(1, GetBuildInfo())
    local majorVersion = tonumber(select(1, strsplit(".", version)))
    return majorVersion and majorVersion >= 3 and majorVersion < 4
end

-- Check if we're running on Cata Classic
function CompatibilityUtils:IsCataClassic()
    if Compatibility then
        return Compatibility.IS_CATA_CLASSIC
    end
    
    local version = select(1, GetBuildInfo())
    local majorVersion = tonumber(select(1, strsplit(".", version)))
    return majorVersion and majorVersion >= 4 and majorVersion < 10
end

-- Get version information
function CompatibilityUtils:GetVersionInfo()
    if Compatibility and Compatibility.GetVersionInfo then
        return Compatibility.GetVersionInfo()
    end
    
    -- Fallback version info
    local version = select(1, GetBuildInfo())
    local build = select(2, GetBuildInfo())
    local majorVersion = tonumber(select(1, strsplit(".", version)))
    
    return {
        version = version,
        build = build,
        majorVersion = majorVersion or 0,
        isRetail = majorVersion and majorVersion >= 10,
        isCataClassic = majorVersion and majorVersion >= 4 and majorVersion < 10,
        isWrathClassic = majorVersion and majorVersion >= 3 and majorVersion < 4,
        isClassicEra = majorVersion and majorVersion >= 1 and majorVersion < 3
    }
end

--[[
===============================================================================
MODULE REGISTRATION HELPERS
===============================================================================
--]]

-- Helper to register compatibility-aware module initialization
function CompatibilityUtils:RegisterModuleInit(module, initFunc)
    if not module or not initFunc then
        return false
    end
    
    -- Wait for compatibility layer to be ready
    local function delayedInit()
        if DamiaUI.Compatibility and DamiaUI.Compatibility.isInitialized then
            initFunc()
        else
            -- Try again in a short while
            C_Timer.After(0.1, delayedInit)
        end
    end
    
    -- Start the delayed init process
    C_Timer.After(0.05, delayedInit)
    
    return true
end

-- Check if a specific API exists
function CompatibilityUtils:IsAPIAvailable(apiName)
    if Compatibility and Compatibility.IsAPIAvailable then
        return Compatibility.IsAPIAvailable(apiName)
    end
    
    -- Fallback API checking
    if apiName:find("%.") then
        local namespace, funcName = strsplit(".", apiName)
        local namespaceTable = _G[namespace]
        return namespaceTable and type(namespaceTable[funcName]) == "function"
    else
        return type(_G[apiName]) == "function"
    end
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Log initialization
if DamiaUI.Engine then
    DamiaUI.Engine:LogDebug("CompatibilityUtils initialized")
end

return CompatibilityUtils