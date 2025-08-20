--------------------------------------------------------------------
-- DamiaUI Misc - Micro Menu
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

local MicroMenu = {}

-- Module registration
ns:RegisterModule("MicroMenu", MicroMenu)

function MicroMenu:Initialize()
    self:CreateMicroMenu()
end

function MicroMenu:CreateMicroMenu()
    local backdrop = {
        bgFile = ns.media.texture,
        edgeFile = ns.media.texture,
        edgeSize = 1,
    }

    local function SetButton(frame)
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(.2, .2, .2, .6)
        frame:SetBackdropBorderColor(0, 0, 0)
        frame:SetSize(140, 13)
    end

    local function Textize(frame, str)
        local s = frame:CreateFontString(nil, "OVERLAY")
        s:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
        s:SetText(str)
        s:SetJustifyH("CENTER")
        s:SetPoint("CENTER", frame, "CENTER", 0, 1)
    end

    ----------------------------------------------------------------------------------------
    -- Blizzard micro menu
    ----------------------------------------------------------------------------------------

    local MenuOut = CreateFrame("Frame", "DamiaUI_MenuOut", Minimap)
    SetButton(MenuOut)
    Textize(MenuOut, "+ Menu +")
    MenuOut:SetPoint("BOTTOM", Minimap, "TOP", 0, 4)
    MenuOut:SetAlpha(0)
    MenuOut:EnableMouse(true)

    local MenuIn = CreateFrame("Frame", "DamiaUI_MenuIn", Minimap)
    SetButton(MenuIn)
    Textize(MenuIn, "- Menu -")
    MenuIn:SetPoint("BOTTOM", Minimap, "TOP", 0, 4)
    MenuIn:Hide()
    MenuIn:EnableMouse(true)

    -- Help Button
    local helpBut = CreateFrame("Frame", "DamiaUI_HelpButton", MenuIn)
    SetButton(helpBut)
    Textize(helpBut, "Help")
    helpBut:SetPoint("BOTTOM", MenuIn, "TOP", 0, 3)
    helpBut:EnableMouse(true)
    helpBut:SetScript("OnMouseUp", function() 
        if ToggleHelpFrame then
            ToggleHelpFrame() 
        end
    end)

    -- Adventure Guide Button (replaces Encounter Journal for 11.2)
    local advBut = CreateFrame("Frame", "DamiaUI_AdventureButton", MenuIn)
    SetButton(advBut)
    Textize(advBut, "Adventure Guide")
    advBut:SetPoint("BOTTOM", helpBut, "TOP", 0, 3)
    advBut:EnableMouse(true)
    advBut:SetScript("OnMouseUp", function() 
        if ToggleEncounterJournal then
            ToggleEncounterJournal()
        elseif ToggleAdventureGuide then
            ToggleAdventureGuide()
        end
    end)

    -- Collections Button (Mounts & Pets)
    local mountBut = CreateFrame("Frame", "DamiaUI_MountButton", MenuIn)
    SetButton(mountBut)
    Textize(mountBut, "Collections")
    mountBut:SetPoint("BOTTOM", advBut, "TOP", 0, 3)
    mountBut:EnableMouse(true)
    mountBut:SetScript("OnMouseUp", function() 
        if ToggleCollectionsJournal then
            ToggleCollectionsJournal()
        elseif TogglePetJournal then
            TogglePetJournal() 
        end
    end)

    -- Group Finder Button
    local lfgBut = CreateFrame("Frame", "DamiaUI_LFGButton", MenuIn)
    SetButton(lfgBut)
    Textize(lfgBut, "Group Finder")
    lfgBut:SetPoint("BOTTOM", mountBut, "TOP", 0, 3)
    lfgBut:EnableMouse(true)
    lfgBut:SetScript("OnMouseUp", function() 
        if PVEFrame_ToggleFrame then
            PVEFrame_ToggleFrame()
        elseif ToggleLFDParentFrame then
            ToggleLFDParentFrame() 
        end
    end)

    -- Guild Button
    local guildBut = CreateFrame("Frame", "DamiaUI_GuildButton", MenuIn)
    SetButton(guildBut)
    Textize(guildBut, "Guild")
    guildBut:SetPoint("BOTTOM", lfgBut, "TOP", 0, 3)
    guildBut:EnableMouse(true)
    guildBut:SetScript("OnMouseUp", function() 
        if IsInGuild() then 
            if ToggleGuildFrame then
                ToggleGuildFrame()
            end
        else
            if ToggleGuildFinder then
                ToggleGuildFinder()
            end
        end
    end)

    -- PvP Button
    local pvpBut = CreateFrame("Frame", "DamiaUI_PVPButton", MenuIn)
    SetButton(pvpBut)
    Textize(pvpBut, "PvP")
    pvpBut:SetPoint("BOTTOM", guildBut, "TOP", 0, 3)
    pvpBut:EnableMouse(true)
    pvpBut:SetScript("OnMouseUp", function() 
        if TogglePVPFrame then
            TogglePVPFrame() 
        end
    end)

    -- Social Button
    local socBut = CreateFrame("Frame", "DamiaUI_SocialButton", MenuIn)
    SetButton(socBut)
    Textize(socBut, "Social")
    socBut:SetPoint("BOTTOM", pvpBut, "TOP", 0, 3)
    socBut:EnableMouse(true)
    socBut:SetScript("OnMouseUp", function() 
        if ToggleFriendsFrame then
            ToggleFriendsFrame(1) 
        end
    end)

    -- Quest Log Button
    local qlogBut = CreateFrame("Frame", "DamiaUI_QuestButton", MenuIn)
    SetButton(qlogBut)
    Textize(qlogBut, "Quest Log")
    qlogBut:SetPoint("BOTTOM", socBut, "TOP", 0, 3)
    qlogBut:EnableMouse(true)
    qlogBut:SetScript("OnMouseUp", function() 
        if ToggleQuestLog then
            ToggleQuestLog()
        elseif QuestLogFrame then
            ToggleFrame(QuestLogFrame) 
        end
    end)

    -- Achievements Button
    local achvBut = CreateFrame("Frame", "DamiaUI_AchvButton", MenuIn)
    SetButton(achvBut)
    Textize(achvBut, "Achievements")
    achvBut:SetPoint("BOTTOM", qlogBut, "TOP", 0, 3)
    achvBut:EnableMouse(true)
    achvBut:SetScript("OnMouseUp", function() 
        if ToggleAchievementFrame then
            ToggleAchievementFrame() 
        end
    end)

    -- Talents Button
    local talBut = CreateFrame("Frame", "DamiaUI_TalentButton", MenuIn)
    SetButton(talBut)
    Textize(talBut, "Talents")
    talBut:SetPoint("BOTTOM", achvBut, "TOP", 0, 3)
    talBut:EnableMouse(true)
    talBut:SetScript("OnMouseUp", function() 
        if ToggleTalentFrame then
            ToggleTalentFrame()
        elseif PlayerTalentFrame then
            ToggleFrame(PlayerTalentFrame)
        end
    end)

    -- Spellbook Button
    local spellBut = CreateFrame("Frame", "DamiaUI_SpellbookButton", MenuIn)
    SetButton(spellBut)
    Textize(spellBut, "Spellbook")
    spellBut:SetPoint("BOTTOM", talBut, "TOP", 0, 3)
    spellBut:EnableMouse(true)
    spellBut:SetScript("OnMouseUp", function() 
        if ToggleSpellBook then
            ToggleSpellBook("spell")
        elseif SpellBookFrame then
            ToggleFrame(SpellBookFrame) 
        end
    end)

    -- Character Button
    local charBut = CreateFrame("Frame", "DamiaUI_CharButton", MenuIn)
    SetButton(charBut)
    Textize(charBut, CHARACTER_BUTTON or "Character")
    charBut:SetPoint("BOTTOM", spellBut, "TOP", 0, 3)
    charBut:EnableMouse(true)
    charBut:SetScript("OnMouseUp", function() 
        if ToggleCharacter then
            ToggleCharacter("PaperDollFrame") 
        end
    end)

    -- Store Button (if available)
    local storeBut = CreateFrame("Frame", "DamiaUI_StoreButton", MenuIn)
    SetButton(storeBut)
    Textize(storeBut, "Store")
    storeBut:SetPoint("BOTTOM", charBut, "TOP", 0, 3)
    storeBut:EnableMouse(true)
    storeBut:SetScript("OnMouseUp", function() 
        if ToggleStoreUI then
            ToggleStoreUI() 
        end
    end)

    -- Menu toggle functionality
    MenuOut:SetScript("OnEnter", function() 
        MenuOut:SetAlpha(1) 
    end)
    MenuOut:SetScript("OnLeave", function() 
        MenuOut:SetAlpha(0) 
    end)
    MenuOut:SetScript("OnMouseUp", function() 
        MenuIn:Show()  
        MenuOut:Hide()  
    end)

    MenuIn:SetScript("OnMouseUp", function() 
        MenuOut:Show()  
        MenuIn:Hide()   
    end)

    -- Handle talent frame alert positioning
    if TalentMicroButtonAlert then
        TalentMicroButtonAlert:ClearAllPoints()
        TalentMicroButtonAlert:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        TalentMicroButtonAlert:SetBackdrop(backdrop)
        TalentMicroButtonAlert:SetBackdropColor(.2, .2, .2, .6)
        TalentMicroButtonAlert:SetBackdropBorderColor(0, 0, 0)
    end
    
    self.MenuOut = MenuOut
    self.MenuIn = MenuIn
end

return MicroMenu