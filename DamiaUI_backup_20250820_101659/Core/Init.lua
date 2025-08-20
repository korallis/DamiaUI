local addonName, DamiaUI = ...

-- Ensure addon table exists and is globally reachable early
DamiaUI.VERSION_STRING = "DamiaUI @project-version@"
_G.DamiaUI = DamiaUI
_G.DamiaUI_ADDON = DamiaUI

-- Create a callback registry for the addon using CallbackHandler-1.0 if available
do
    local ok, CallbackHandler = pcall(function()
        return LibStub and LibStub("CallbackHandler-1.0")
    end)
    if ok and CallbackHandler and not DamiaUI.callbacks then
        DamiaUI.callbacks = CallbackHandler:New(DamiaUI)
    else
        -- Minimal fallback to avoid nil errors if library fails to load
        DamiaUI.callbacks = {
            handlers = {},
            Fire = function() end,
            RegisterCallback = function() end,
            UnregisterCallback = function() end,
            UnregisterAllCallbacks = function() end,
        }
    end
end

-- Expansion detection (copied from GW2_UI patterns)
do -- Expansions
    DamiaUI.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
    DamiaUI.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
    DamiaUI.Wrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
    DamiaUI.Cata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
    DamiaUI.Mists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
    DamiaUI.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

    local season = C_Seasons and C_Seasons.GetActiveSeason()
    DamiaUI.ClassicHC = season == 3 -- Hardcore
    DamiaUI.ClassicSOD = season == 2 -- Season of Discovery
    DamiaUI.ClassicAnniv = season == 11 -- Anniversary
    DamiaUI.ClassicAnnivHC = season == 12 -- Anniversary Hardcore

    local IsHardcoreActive = C_GameRules and C_GameRules.IsHardcoreActive
    DamiaUI.IsHardcoreActive = IsHardcoreActive and IsHardcoreActive()

    local IsEngravingEnabled = C_Engraving and C_Engraving.IsEngravingEnabled
    DamiaUI.IsEngravingEnabled = IsEngravingEnabled and IsEngravingEnabled()
end

-- Constants
local gameLocale = GetLocale()
DamiaUI.myguid = UnitGUID("player")
DamiaUI.addonName = addonName:gsub("_", " ")
DamiaUI.mylocal = gameLocale == "enGB" and "enUS" or gameLocale
DamiaUI.NoOp = function() end
DamiaUI.myfaction, DamiaUI.myLocalizedFaction = UnitFactionGroup("player")
DamiaUI.myLocalizedClass, DamiaUI.myclass, DamiaUI.myClassID = UnitClass("player")
DamiaUI.myLocalizedRace, DamiaUI.myrace = UnitRace("player")
DamiaUI.myname = UnitName("player")
DamiaUI.myrealm = GetRealmName()
DamiaUI.mysex = UnitSex("player")
DamiaUI.mylevel = UnitLevel("player")
DamiaUI.screenwidth, DamiaUI.screenHeight = GetPhysicalScreenSize()
DamiaUI.resolution = format("%dx%d", DamiaUI.screenwidth, DamiaUI.screenHeight)
DamiaUI.wowpatch, DamiaUI.wowbuild, _ , DamiaUI.wowToc = GetBuildInfo()

DamiaUI.wowbuild = tonumber(DamiaUI.wowbuild)
DamiaUI.DamiaColor = "|cffCC8010" -- DamiaUI brand color
DamiaUI.NewSign = [[|TInterface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon:14:14|t]]

-- Hidden frame for parenting frames we want to hide
DamiaUI.HiddenFrame = CreateFrame("Frame")
DamiaUI.HiddenFrame.HiddenString = DamiaUI.HiddenFrame:CreateFontString(nil, "OVERLAY")
DamiaUI.HiddenFrame:Hide()

-- Scan tooltip for item info
DamiaUI.ScanTooltip = CreateFrame("GameTooltip", "DamiaUIScanTooltip", UIParent, "GameTooltipTemplate")

-- Layout constants
DamiaUI.BorderSize = 1
DamiaUI.SpacingSize = 2

-- State tracking
DamiaUI.ShowRlPopup = false
DamiaUI.InMoveHudMode = false

-- Tables for module system
DamiaUI.modules = {}
DamiaUI.MOVABLE_FRAMES = {}
DamiaUI.scaleableFrames = {}
DamiaUI.animations = {}
DamiaUI.BackdropTemplates = {}
DamiaUI.texts = {}

-- Settings will be initialized later
DamiaUI.settings = {}
DamiaUI.db = {}

-- Utility functions
local function copyTable(newTable, tableToCopy)
    if type(newTable) ~= "table" then newTable = {} end

    if type(tableToCopy) == "table" then
        for option, value in pairs(tableToCopy) do
            if type(value) == "table" then
                value = copyTable(newTable[option], value)
            end
            newTable[option] = value
        end
    end

    return newTable
end
DamiaUI.copyTable = copyTable

-- Role detection helper
local function GetPlayerRole()
    local assignedRole = UnitGroupRolesAssigned("player")
    if assignedRole and assignedRole ~= "NONE" then
        return assignedRole
    end
    -- Fallback to spec role if available
    local spec = GetSpecialization()
    if spec then
        local _, _, _, _, role = GetSpecializationInfo(spec)
        return role or "NONE"
    end
    return "NONE"
end
DamiaUI.GetPlayerRole = GetPlayerRole

local function CheckRole()
    local spec = GetSpecialization()
    if spec then
        DamiaUI.myspec = spec
        DamiaUI.myspecID, DamiaUI.myspecName, DamiaUI.myspecDesc, DamiaUI.myspecIcon, DamiaUI.myspecRole = GetSpecializationInfo(spec)
    end
    DamiaUI.myrole = GetPlayerRole()
end
DamiaUI.CheckRole = CheckRole

-- Debug printing
function DamiaUI:Print(...)
    print(DamiaUI.DamiaColor .. "DamiaUI|r:", ...)
end

-- Support both DamiaUI.Debug("msg") and DamiaUI:Debug("msg") styles
function DamiaUI.Debug(_, ...)
    if DamiaUI.settings and DamiaUI.settings.DEBUG_MODE then
        print(DamiaUI.DamiaColor .. "DamiaUI Debug|r:", ...)
    end
end

-- Module registration system
function DamiaUI:CreateModule(name)
    local module = {}
    self.modules[name] = module
    self:Debug("Created module:", name)
    return module
end

function DamiaUI:RegisterModule(name, moduleTable)
    if type(moduleTable) == "table" then
        self.modules[name] = moduleTable
        if moduleTable.Initialize and type(moduleTable.Initialize) == "function" then
            -- Call initialization if available
            moduleTable:Initialize()
        end
        self:Debug("Registered module:", name)
    end
end

function DamiaUI:GetModule(name)
    return self.modules[name]
end

-- Load order: This file is loaded first, then API, then DisableBlizzard
DamiaUI:Print("Core initialized -", DamiaUI.VERSION_STRING)