--[[
===============================================================================
DamiaUI - Compatibility Test Suite
===============================================================================
Test suite to verify compatibility layer functionality across WoW versions.
This file can be loaded in-game to verify that all compatibility functions
work correctly.

Usage: /script LoadAddOn("DamiaUI"); DamiaUI.CompatibilityTest:RunTests()

Author: DamiaUI Development Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Create test module
local CompatibilityTest = {}
DamiaUI.CompatibilityTest = CompatibilityTest

-- Test results storage
local testResults = {}
local testCount = 0
local passedCount = 0

-- Test helper functions
local function StartTest(testName)
    testCount = testCount + 1
    print(string.format("|cff00ccff[Test %d]|r %s", testCount, testName))
end

local function AssertTrue(condition, message)
    if condition then
        passedCount = passedCount + 1
        print(string.format("  |cff00ff00✓|r %s", message or "Passed"))
        return true
    else
        print(string.format("  |cffff0000✗|r %s", message or "Failed"))
        return false
    end
end

local function AssertNotNil(value, message)
    return AssertTrue(value ~= nil, message or "Value should not be nil")
end

local function AssertFunction(func, message)
    return AssertTrue(type(func) == "function", message or "Should be a function")
end

-- Test compatibility layer initialization
function CompatibilityTest:TestInitialization()
    StartTest("Compatibility Layer Initialization")
    
    AssertNotNil(DamiaUI.Compatibility, "Compatibility module should exist")
    AssertTrue(DamiaUI.Compatibility.isInitialized, "Should be initialized")
    AssertNotNil(DamiaUI.Compatibility.WOW_VERSION, "Should have WoW version")
    AssertNotNil(DamiaUI.CompatibilityUtils, "CompatibilityUtils should exist")
end

-- Test version detection
function CompatibilityTest:TestVersionDetection()
    StartTest("Version Detection")
    
    local Compatibility = DamiaUI.Compatibility
    local versionInfo = Compatibility:GetVersionInfo()
    
    AssertNotNil(versionInfo, "Version info should exist")
    AssertNotNil(versionInfo.version, "Should have version string")
    AssertNotNil(versionInfo.build, "Should have build number")
    AssertTrue(type(versionInfo.majorVersion) == "number", "Major version should be number")
    
    -- Test version flags
    local hasVersionFlag = versionInfo.isRetail or versionInfo.isCataClassic or 
                          versionInfo.isWrathClassic or versionInfo.isClassicEra
    AssertTrue(hasVersionFlag, "Should have at least one version flag set")
    
    print(string.format("  Detected: %s (Build %s)", versionInfo.version, versionInfo.build))
    
    if versionInfo.isRetail then
        print("  |cff00ff00Retail version detected|r")
    elseif versionInfo.isCataClassic then
        print("  |cffFFD700Cataclysm Classic detected|r")
    elseif versionInfo.isWrathClassic then
        print("  |cff87CEEBWrath Classic detected|r")
    elseif versionInfo.isClassicEra then
        print("  |cffDDA0DDClassic Era detected|r")
    end
end

-- Test API availability checking
function CompatibilityTest:TestAPIAvailability()
    StartTest("API Availability Checking")
    
    local Compatibility = DamiaUI.Compatibility
    
    -- Test some known APIs
    local testAPIs = {
        "UnitExists",
        "CreateFrame", 
        "GetTime",
        "C_Timer.After"
    }
    
    for _, apiName in ipairs(testAPIs) do
        local available = Compatibility:IsAPIAvailable(apiName)
        print(string.format("  %s: %s", apiName, available and "|cff00ff00Available|r" or "|cffff0000Missing|r"))
    end
end

-- Test aura system compatibility
function CompatibilityTest:TestAuraCompatibility()
    StartTest("Aura System Compatibility")
    
    local Compatibility = DamiaUI.Compatibility
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(Compatibility.UnitAura, "UnitAura wrapper should exist")
    AssertFunction(Compatibility.UnitBuff, "UnitBuff wrapper should exist")
    AssertFunction(Compatibility.UnitDebuff, "UnitDebuff wrapper should exist")
    
    AssertFunction(CompatUtils.UnitAura, "CompatUtils UnitAura wrapper should exist")
    AssertFunction(CompatUtils.UnitBuff, "CompatUtils UnitBuff wrapper should exist")
    AssertFunction(CompatUtils.UnitDebuff, "CompatUtils UnitDebuff wrapper should exist")
    
    -- Test actual function calls (safe to call on player)
    if UnitExists("player") then
        local name, icon = CompatUtils:UnitBuff("player", 1, "HELPFUL")
        print(string.format("  UnitBuff test result: %s", name and "Success" or "No buffs found"))
    end
end

-- Test spell system compatibility
function CompatibilityTest:TestSpellCompatibility()
    StartTest("Spell System Compatibility")
    
    local Compatibility = DamiaUI.Compatibility
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(Compatibility.GetSpellInfo, "GetSpellInfo wrapper should exist")
    AssertFunction(Compatibility.GetSpellCooldown, "GetSpellCooldown wrapper should exist")
    AssertFunction(Compatibility.GetSpellTexture, "GetSpellTexture wrapper should exist")
    
    AssertFunction(CompatUtils.GetSpellInfo, "CompatUtils GetSpellInfo should exist")
    
    -- Test with a known spell (Auto Attack - spell ID 6603)
    local spellInfo = CompatUtils:GetSpellInfo(6603)
    if spellInfo then
        print("  |cff00ff00Spell info retrieval working|r")
    else
        print("  |cffFFD700Spell info test inconclusive|r")
    end
end

-- Test texture system compatibility
function CompatibilityTest:TestTextureCompatibility()
    StartTest("Texture System Compatibility")
    
    local Compatibility = DamiaUI.Compatibility
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(Compatibility.SetTexture, "SetTexture wrapper should exist")
    AssertFunction(Compatibility.SetSolidTexture, "SetSolidTexture wrapper should exist")
    AssertFunction(CompatUtils.SetSolidTexture, "CompatUtils SetSolidTexture should exist")
    
    -- Test with a dummy texture
    local testFrame = CreateFrame("Frame")
    local testTexture = testFrame:CreateTexture()
    
    if testTexture then
        local success = CompatUtils:SetSolidTexture(testTexture, 1.0, 0.5, 0.0, 1.0)
        AssertTrue(success, "Should successfully set solid texture")
        
        -- Clean up
        testFrame:Hide()
        testFrame = nil
    end
end

-- Test realm/server compatibility
function CompatibilityTest:TestServerCompatibility()
    StartTest("Server/Realm Compatibility")
    
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(CompatUtils.GetRealmName, "GetRealmName wrapper should exist")
    AssertFunction(CompatUtils.IsInGuild, "IsInGuild wrapper should exist")
    
    local realmName = CompatUtils:GetRealmName()
    AssertNotNil(realmName, "Should return a realm name")
    print(string.format("  Realm: %s", realmName))
    
    local inGuild = CompatUtils:IsInGuild()
    print(string.format("  In Guild: %s", inGuild and "Yes" or "No"))
end

-- Test sound system compatibility
function CompatibilityTest:TestSoundCompatibility()
    StartTest("Sound System Compatibility")
    
    local Compatibility = DamiaUI.Compatibility
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(Compatibility.PlaySound, "PlaySound wrapper should exist")
    AssertFunction(CompatUtils.PlaySound, "CompatUtils PlaySound should exist")
    
    print("  |cffFFD700Sound testing skipped (no audio in test)|r")
end

-- Test action button styling
function CompatibilityTest:TestActionButtonStyling()
    StartTest("Action Button Styling")
    
    local CompatUtils = DamiaUI.CompatibilityUtils
    
    AssertFunction(CompatUtils.StyleActionButton, "StyleActionButton should exist")
    
    -- Create a test button
    local testButton = CreateFrame("Button", nil, UIParent)
    testButton:SetSize(32, 32)
    
    -- Add required textures
    local normalTexture = testButton:CreateTexture(nil, "ARTWORK")
    local pushedTexture = testButton:CreateTexture(nil, "ARTWORK") 
    local highlightTexture = testButton:CreateTexture(nil, "HIGHLIGHT")
    local checkedTexture = testButton:CreateTexture(nil, "ARTWORK")
    
    testButton:SetNormalTexture(normalTexture)
    testButton:SetPushedTexture(pushedTexture)
    testButton:SetHighlightTexture(highlightTexture)
    testButton:SetCheckedTexture(checkedTexture)
    
    local success = CompatUtils:StyleActionButton(testButton)
    AssertTrue(success, "Should successfully style action button")
    
    -- Clean up
    testButton:Hide()
    testButton = nil
end

-- Run all tests
function CompatibilityTest:RunTests()
    print("|cff00ccff===============================================|r")
    print("|cff00ccffDamiaUI Compatibility Test Suite|r")
    print("|cff00ccff===============================================|r")
    
    testResults = {}
    testCount = 0
    passedCount = 0
    
    -- Run all test methods
    self:TestInitialization()
    self:TestVersionDetection()
    self:TestAPIAvailability()
    self:TestAuraCompatibility()
    self:TestSpellCompatibility()
    self:TestTextureCompatibility()
    self:TestServerCompatibility()
    self:TestSoundCompatibility()
    self:TestActionButtonStyling()
    
    -- Print results
    print("|cff00ccff===============================================|r")
    print(string.format("|cff00ccffTest Results: %d/%d passed|r", passedCount, testCount))
    
    if passedCount == testCount then
        print("|cff00ff00All tests passed! ✓|r")
    else
        print(string.format("|cffFFD700%d tests failed|r", testCount - passedCount))
    end
    
    print("|cff00ccff===============================================|r")
    
    return passedCount, testCount
end

-- Quick test function for slash command
function CompatibilityTest:QuickTest()
    print("|cffFFD700Running quick compatibility check...|r")
    
    if not DamiaUI.Compatibility then
        print("|cffff0000Compatibility layer not found!|r")
        return false
    end
    
    if not DamiaUI.Compatibility.isInitialized then
        print("|cffff0000Compatibility layer not initialized!|r")
        return false
    end
    
    local version = DamiaUI.Compatibility:GetVersionInfo()
    print(string.format("|cff00ff00Compatibility layer active for WoW %s|r", version.version))
    
    return true
end

return CompatibilityTest