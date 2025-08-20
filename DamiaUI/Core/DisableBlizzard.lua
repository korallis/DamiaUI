-- DamiaUI Disable Blizzard UI Elements
-- Based on ColdUI hide.lua

local addonName, ns = ...

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
    -- Hide listed frames
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", function(self) self:Hide() end)
        end
    end
    
    -- Hide MultiBar frames
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide MultiBarBottomLeft
    for i = 1, 12 do
        local button = _G["MultiBarBottomLeftButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide MultiBarBottomRight
    for i = 1, 12 do
        local button = _G["MultiBarBottomRightButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide MultiBarLeft
    for i = 1, 12 do
        local button = _G["MultiBarLeftButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide MultiBarRight
    for i = 1, 12 do
        local button = _G["MultiBarRightButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide Pet Action Bar
    for i = 1, 10 do
        local button = _G["PetActionButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide Stance Bar buttons
    for i = 1, 10 do
        local button = _G["StanceButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide Possess Bar buttons
    for i = 1, 10 do
        local button = _G["PossessButton"..i]
        if button then
            button:UnregisterAllEvents()
            button:Hide()
            button:SetAttribute("statehidden", true)
        end
    end
    
    -- Hide Extra Action Button
    if ExtraActionBarFrame then
        ExtraActionBarFrame:UnregisterAllEvents()
        ExtraActionBarFrame:Hide()
    end
    
    -- Hide Zone Ability Frame
    if ZoneAbilityFrame then
        ZoneAbilityFrame:UnregisterAllEvents()
        ZoneAbilityFrame:Hide()
    end
end

-- Disable Blizzard Unit Frames
local function DisableBlizzardUnitFrames()
    if ns.config and ns.config.unitframes and ns.config.unitframes.enabled then
        -- Player Frame
        if PlayerFrame then
            PlayerFrame:UnregisterAllEvents()
            PlayerFrame:Hide()
            PlayerFrame:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Target Frame
        if TargetFrame then
            TargetFrame:UnregisterAllEvents()
            TargetFrame:Hide()
            TargetFrame:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Focus Frame
        if FocusFrame then
            FocusFrame:UnregisterAllEvents()
            FocusFrame:Hide()
            FocusFrame:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Party Frames
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame"..i]
            if frame then
                frame:UnregisterAllEvents()
                frame:Hide()
                frame:SetScript("OnShow", function(self) self:Hide() end)
            end
        end
        
        -- Boss Frames
        for i = 1, 5 do
            local frame = _G["Boss"..i.."TargetFrame"]
            if frame then
                frame:UnregisterAllEvents()
                frame:Hide()
                frame:SetScript("OnShow", function(self) self:Hide() end)
            end
        end
        
        -- Arena Frames
        if ArenaEnemyFrames then
            ArenaEnemyFrames:UnregisterAllEvents()
            ArenaEnemyFrames:Hide()
            ArenaEnemyFrames:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Compact Raid Frames
        if CompactRaidFrameManager then
            CompactRaidFrameManager:UnregisterAllEvents()
            CompactRaidFrameManager:Hide()
            CompactRaidFrameManager:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:Hide()
            CompactRaidFrameContainer:SetScript("OnShow", function(self) self:Hide() end)
        end
    end
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

-- Main disable function
function ns:DisableBlizzardUI()
    -- Ensure config exists
    if not ns.config then
        ns.config = {}
    end
    
    -- Wait for player login to ensure everything is loaded
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        -- Re-check config after login
        if not ns.config then
            ns.config = {}
        end
        
        -- Action bars
        if ns.config.actionbar and ns.config.actionbar.enabled then
            HideBlizzardFrames()
        end
        
        -- Unit frames
        if ns.config.unitframes and ns.config.unitframes.enabled then
            DisableBlizzardUnitFrames()
        end
        
        -- Buffs (if using custom buff frames)
        -- DisableBlizzardBuffs()
        
        -- Hide Talking Head Frame
        if TalkingHeadFrame then
            TalkingHeadFrame:UnregisterAllEvents()
            TalkingHeadFrame:Hide()
            TalkingHeadFrame:SetScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Hide Boss Banner
        if BossBanner then
            BossBanner:UnregisterAllEvents()
            BossBanner:Hide()
        end
        
        -- Hide Alert Frames (optional)
        if AlertFrame then
            AlertFrame:UnregisterAllEvents()
            AlertFrame:Hide()
        end
        
        f:UnregisterEvent("PLAYER_LOGIN")
    end)
end

-- Initialize
ns:DisableBlizzardUI()