local _, DamiaUI = ...

local isArenaHooked = false
local lockedFrames = {}

local MAX_PARTY = MEMBERS_PER_RAID_GROUP or MAX_PARTY_MEMBERS or 5
local MAX_BOSS_FRAMES = 10

-- Lock frame parent to prevent re-showing
local function LockParent(frame, parent)
    if parent ~= DamiaUI.HiddenFrame then
        frame:SetParent(DamiaUI.HiddenFrame)
    end
end

-- Handle frame hiding and event cleanup
local function HandleFrame(frame, doNotReparent)
    if type(frame) == "string" then
        frame = _G[frame]
    end

    if not frame then return end

    local lockParent = doNotReparent == 1

    if lockParent or not doNotReparent then
        frame:SetParent(DamiaUI.HiddenFrame)
        if lockParent and not lockedFrames[frame] then
            hooksecurefunc(frame, "SetParent", LockParent)
            lockedFrames[frame] = true
        end
    end

    frame:UnregisterAllEvents()
    frame:Hide()

    -- Clean up child frames
    for _, child in next, {
        frame.petFrame or frame.PetFrame,
        frame.healthBar or frame.healthbar or frame.HealthBar,
        frame.manabar or frame.ManaBar,
        frame.castBar or frame.spellbar,
        frame.powerBarAlt or frame.PowerBarAlt,
        frame.totFrame,
        frame.BuffFrame
    } do
        if child then
            child:UnregisterAllEvents()
        end
    end
end

local function DisableBlizzardFrames()
    DamiaUI:Debug("Starting Blizzard frame disabling...")
    
    -- Based on our settings, we'll disable frames
    -- For Phase 1, we'll disable the most common frames
    local ourPartyFrames = true -- DamiaUI.settings.PARTY_FRAMES
    local ourRaidFrames = true -- DamiaUI.settings.RAID_FRAMES
    local ourBossFrames = true -- DamiaUI.settings.BOSS_FRAMES
    local ourArenaFrames = true -- DamiaUI.settings.ARENA_FRAMES
    local ourPetFrame = true -- DamiaUI.settings.PET_FRAME
    local ourTargetFrame = true -- DamiaUI.settings.TARGET_FRAME
    local ourTargetTargetFrame = true -- DamiaUI.settings.TARGET_TARGET_FRAME
    local ourFocusFrame = true -- DamiaUI.settings.FOCUS_FRAME
    local ourFocusTargetFrame = true -- DamiaUI.settings.FOCUS_TARGET_FRAME
    local ourPlayerFrame = true -- DamiaUI.settings.PLAYER_FRAME
    local ourCastBar = true -- DamiaUI.settings.CAST_BAR
    local ourActionbars = true -- DamiaUI.settings.ACTION_BARS
    local ourInventory = true -- DamiaUI.settings.BAGS

    -- Party and Raid Frame Cleanup
    if ourPartyFrames or ourRaidFrames then
        UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end

    -- Party Frames
    if ourPartyFrames then
        if CompactPartyFrame then
            CompactPartyFrame:UnregisterAllEvents()
        end

        if PartyFrame then
            HandleFrame(PartyFrame, 1)
            PartyFrame:UnregisterAllEvents()
            PartyFrame:SetScript("OnShow", nil)

            -- Handle party member frames if they exist
            if PartyFrame.PartyMemberFramePool then
                for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                    HandleFrame(frame, true)
                end
            end
        end

        for i = 1, MAX_PARTY do
            HandleFrame("PartyMemberFrame" .. i)
            HandleFrame("CompactPartyFrameMember" .. i)
        end
    end

    -- Raid Frames
    if ourRaidFrames then
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:HookScript("OnShow", function() 
                CompactRaidFrameContainer:Hide() 
            end)
        end

        -- Disable raid frame manager
        if CompactRaidFrameManager then
            CompactRaidFrameManager:UnregisterAllEvents()
            CompactRaidFrameManager:SetParent(DamiaUI.HiddenFrame)
            
            -- Disable compact raid frame setting
            if CompactRaidFrameManager_SetSetting then
                CompactRaidFrameManager_SetSetting("IsShown", "0")
            end
        end

        -- Modern edit mode support
        if DamiaUI.Retail and CompactRaidFrameContainer.GwKillEditMode then
            CompactRaidFrameContainer:GwKillEditMode()
        end
    end

    -- Arena Frames
    if ourArenaFrames then
        -- Arena taint fix
        hooksecurefunc("UnitFrameThreatIndicator_Initialize", function(_, unitFrame)
            if unitFrame then
                unitFrame:UnregisterAllEvents()
            end
        end)

        Arena_LoadUI = DamiaUI.NoOp

        if not isArenaHooked and CompactArenaFrame then
            isArenaHooked = true
            HandleFrame(CompactArenaFrame, 1)

            if CompactArenaFrame.memberUnitFrames then
                for _, frame in next, CompactArenaFrame.memberUnitFrames do
                    HandleFrame(frame, true)
                end
            end
        end
    end

    -- Boss Frames
    if ourBossFrames then
        HandleFrame(BossTargetFrameContainer, 1)

        for i = 1, MAX_BOSS_FRAMES do
            HandleFrame("Boss" .. i .. "TargetFrame", true)
        end
    end

    -- Pet Frame
    if ourPetFrame then
        HandleFrame(PetFrame)
    end

    -- Target Frame
    if ourTargetFrame then
        HandleFrame(TargetFrame)
        HandleFrame(ComboFrame)
    end

    -- Target of Target Frame
    if ourTargetFrame and ourTargetTargetFrame then
        HandleFrame(TargetFrameToT)
    end

    -- Focus Frame
    if ourFocusFrame then
        HandleFrame(FocusFrame)
    end

    -- Focus Target Frame
    if ourFocusFrame and ourFocusTargetFrame then
        HandleFrame(TargetofFocusFrame)
    end

    -- Player Frame
    if ourPlayerFrame then
        HandleFrame(PlayerFrame)

        -- Keep some vehicle events for vehicle support
        if PlayerFrame then
            PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
            PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
            PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
            PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")

            PlayerFrame:SetMovable(true)
            PlayerFrame:SetUserPlaced(true)
            PlayerFrame:SetDontSavePosition(true)
        end
    end

    -- Cast Bars
    if ourCastBar then
        HandleFrame(PlayerCastingBarFrame)
        HandleFrame(CastingBarFrame)
        HandleFrame(PetCastingBarFrame)

        -- Prevent cast bar from showing
        if DamiaUI.Retail and PlayerCastingBarFrame then
            PlayerCastingBarFrame:HookScript("OnShow", function() 
                PlayerCastingBarFrame:Hide() 
            end)
            
            if PlayerCastingBarFrame.GwKillEditMode then
                PlayerCastingBarFrame:GwKillEditMode()
            end
        end
    end

    -- Inventory/Bags
    if ourInventory then
        if MicroButtonAndBagsBar then
            MicroButtonAndBagsBar:SetParent(DamiaUI.HiddenFrame)
            MicroButtonAndBagsBar:UnregisterAllEvents()
        end
    end

    -- Action Bars
    if ourActionbars then
        local actionBarFrames = {
            MultiBar5 = true,
            MultiBar6 = true,
            MultiBar7 = true,
            MultiBarLeft = true,
            MultiBarRight = true,
            MultiBarBottomLeft = true,
            MultiBarBottomRight = true,
            StanceBar = true
        }

        for name in next, actionBarFrames do
            local frame = _G[name]
            if frame then
                frame:SetParent(DamiaUI.HiddenFrame)
                frame:UnregisterAllEvents()
            end
        end

        -- Main Menu Bar - special handling
        if MainMenuBar then
            MainMenuBar:SetParent(DamiaUI.HiddenFrame)
            MainMenuBar:UnregisterAllEvents()
            
            -- Hide art frame
            if MainMenuBarArtFrame then
                MainMenuBarArtFrame:SetParent(DamiaUI.HiddenFrame)
                MainMenuBarArtFrame:UnregisterAllEvents()
            end
        end

        -- Retail status tracking bars (XP/Rep) – hide to match custom bottom layout
        if StatusTrackingBarManager then
            StatusTrackingBarManager:SetParent(DamiaUI.HiddenFrame)
            StatusTrackingBarManager:UnregisterAllEvents()
            if StatusTrackingBarManager.Hide then
                StatusTrackingBarManager:Hide()
            end
        end

        if MainStatusTrackingBarContainer then
            MainStatusTrackingBarContainer:SetParent(DamiaUI.HiddenFrame)
            if MainStatusTrackingBarContainer.Hide then
                MainStatusTrackingBarContainer:Hide()
            end
        end
    end

    DamiaUI:Debug("Blizzard frame disabling completed")
end

-- Store the function in DamiaUI namespace
DamiaUI.DisableBlizzardFrames = DisableBlizzardFrames

-- Auto-execute on load if needed
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "DamiaUI" then
        -- Wait a bit to ensure all frames are loaded
        C_Timer.After(0.5, function()
            DisableBlizzardFrames()
            DamiaUI:Print("Blizzard UI disabled")
        end)
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)