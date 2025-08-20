-- DamiaUI Disable Blizzard UI Elements
-- Based on ColdUI hide.lua

local addonName, ns = ...

-- Create hidden frame for parenting
ns.HiddenFrame = CreateFrame("Frame")
ns.HiddenFrame:Hide()

-- Comprehensive frame hiding function
local function HideBlizzardFrame(frame)
    if not frame then return end
    
    frame:UnregisterAllEvents()
    frame:Hide()
    frame:SetParent(ns.HiddenFrame)
    frame.ignoreFramePositionManager = true
    
    -- Prevent re-showing
    frame:SetScript("OnShow", function(self)
        self:Hide()
    end)
    
    -- For secure frames
    if frame.SetAttribute then
        frame:SetAttribute("statehidden", true)
    end
    
    -- Unregister state drivers
    if frame.UnregisterStateDriver then
        UnregisterStateDriver(frame, "visibility")
        UnregisterStateDriver(frame, "display")
    end
end

-- List of frames to hide
local framesToHide = {
    -- Action Bars
    MainMenuBar,
    MainMenuBarArtFrame,
    MainMenuBarArtFrameBackground,
    ActionBarUpButton,
    ActionBarDownButton,
    MainMenuBarPageNumber,
    MainMenuBarPerformanceBar,
    MainMenuExpBar,
    MainMenuBarMaxLevelBar,
    MainMenuBarVehicleLeaveButton,
    ReputationWatchBar,
    ArtifactWatchBar,
    HonorWatchBar,
    
    -- Micro Menu
    MicroButtonAndBagsBar,
    CharacterMicroButton,
    SpellbookMicroButton,
    TalentMicroButton,
    AchievementMicroButton,
    QuestLogMicroButton,
    GuildMicroButton,
    LFDMicroButton,
    EJMicroButton,
    CollectionsMicroButton,
    MainMenuMicroButton,
    HelpMicroButton,
    StoreMicroButton,
    
    -- Bags
    MainMenuBarBackpackButton,
    CharacterBag0Slot,
    CharacterBag1Slot,
    CharacterBag2Slot,
    CharacterBag3Slot,
    CharacterReagentBag0Slot,
    
    -- Status Tracking
    StatusTrackingBarManager,
    
    -- Override Action Bar
    OverrideActionBar,
    
    -- Possess Bar
    PossessBarFrame,
    
    -- Pet Battle
    PetBattleFrame,
    
    -- Stance Bar (optional)
    -- StanceBarFrame,
    
    -- MultiCast (Shaman totems)
    MultiCastActionBarFrame,
}

-- Hide frames function
local function HideBlizzardFrames()
    -- Hide listed frames using comprehensive hiding
    for _, frame in pairs(framesToHide) do
        HideBlizzardFrame(frame)
    end
    
    -- Hide MultiBar frames
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide MultiBarBottomLeft
    for i = 1, 12 do
        local button = _G["MultiBarBottomLeftButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide MultiBarBottomRight
    for i = 1, 12 do
        local button = _G["MultiBarBottomRightButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide MultiBarLeft
    for i = 1, 12 do
        local button = _G["MultiBarLeftButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide MultiBarRight
    for i = 1, 12 do
        local button = _G["MultiBarRightButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide Pet Action Bar
    for i = 1, 10 do
        local button = _G["PetActionButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide Stance Bar buttons
    for i = 1, 10 do
        local button = _G["StanceButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide Possess Bar buttons
    for i = 1, 10 do
        local button = _G["PossessButton"..i]
        HideBlizzardFrame(button)
    end
    
    -- Hide Extra Action Button
    HideBlizzardFrame(ExtraActionBarFrame)
    
    -- Hide Zone Ability Frame
    HideBlizzardFrame(ZoneAbilityFrame)
end

-- Disable Blizzard Unit Frames
local function DisableBlizzardUnitFrames()
    -- Remove config check - always hide for now
    -- Player Frame
    HideBlizzardFrame(PlayerFrame)
    
    -- Target Frame
    HideBlizzardFrame(TargetFrame)
    
    -- Focus Frame
    HideBlizzardFrame(FocusFrame)
    
    -- Party Frames
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame"..i]
        HideBlizzardFrame(frame)
    end
    
    -- Boss Frames
    for i = 1, 5 do
        local frame = _G["Boss"..i.."TargetFrame"]
        HideBlizzardFrame(frame)
    end
    
    -- Arena Frames
    HideBlizzardFrame(ArenaEnemyFrames)
    
    -- Compact Raid Frames
    HideBlizzardFrame(CompactRaidFrameManager)
    HideBlizzardFrame(CompactRaidFrameContainer)
end

-- Disable Blizzard Buffs
local function DisableBlizzardBuffs()
    if BuffFrame then
        BuffFrame:Hide()
        TemporaryEnchantFrame:Hide()
        ConsolidatedBuffs:Hide()
    end
    
    if DebuffFrame then
        DebuffFrame:Hide()
    end
end

-- Main disable function - called from Init.lua after config is loaded
function ns:DisableBlizzardUI()
    print("[DEBUG] DisableBlizzardUI called")
    
    -- Ensure config exists
    if not ns.config then
        print("[DEBUG] No config found, creating empty config")
        ns.config = {}
    end
    
    print("[DEBUG] Config available: " .. tostring(ns.config ~= nil))
    if ns.config.actionbar then
        print("[DEBUG] Actionbar config enabled: " .. tostring(ns.config.actionbar.enabled))
    end
    if ns.config.unitframes then
        print("[DEBUG] Unitframes config enabled: " .. tostring(ns.config.unitframes.enabled))
    end
    
    -- Action bars - ALWAYS hide them for now to ensure they're gone
    print("[DEBUG] Hiding Blizzard action bars")
    HideBlizzardFrames()
    
    -- Unit frames - ALWAYS hide them for now to ensure they're gone  
    print("[DEBUG] Hiding Blizzard unit frames")
    DisableBlizzardUnitFrames()
    
    -- Hide Talking Head Frame
    HideBlizzardFrame(TalkingHeadFrame)
    
    -- Hide Boss Banner
    HideBlizzardFrame(BossBanner)
    
    -- Hide Alert Frames (optional)
    HideBlizzardFrame(AlertFrame)
    
    print("[DEBUG] DisableBlizzardUI completed")
end

-- DO NOT call this here - it will be called from Init.lua after config is loaded