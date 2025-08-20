local backdrop = {
	bgFile = "Interface\\AddOns\\ColdMisc\\media\\flat2",
	edgeFile = "Interface\\AddOns\\ColdMisc\\media\\flat2",
	edgeSize = 1,
}

local function SetButton (frame)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(.2,.2,.2,.6)
	frame:SetBackdropBorderColor(0,0,0)
	frame:SetSize(140, 13)
end

local function Textize (frame, str)
	local s = frame:CreateFontString(nil, "OVERLAY")
	s:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
	s:SetText(str)
	s:SetJustifyH"CENTER"
	s:SetPoint("CENTER", frame, "CENTER", 0, 1)
end
----------------------------------------------------------------------------------------
-- Blizzard micro menu
----------------------------------------------------------------------------------------

local MenuOut = CreateFrame("Frame", "ColdMenuOut", Minimap)
SetButton(MenuOut)
Textize(MenuOut, "+ Menu +")
MenuOut:SetPoint("BOTTOM", Minimap, "TOP", 0, 4)
MenuOut:SetAlpha(0)

local MenuIn = CreateFrame("Frame", "ColdMenuIn", Minimap)
SetButton(MenuIn)
Textize(MenuIn, "- Menu -")
MenuIn:SetPoint("BOTTOM", Minimap, "TOP", 0, 4)
MenuIn:Hide()

local helpBut = CreateFrame("Frame", "ColdHelpButton", MenuIn)
SetButton(helpBut)
Textize(helpBut, "Help")
helpBut:SetPoint("BOTTOM", MenuIn, "TOP", 0, 3)
helpBut:SetScript("OnMouseUp", function() ToggleHelpFrame() end)

local ijBut = CreateFrame("Frame", "ColdIJButton", MenuIn)
SetButton(ijBut)
Textize(ijBut, "Encounter Journal")
ijBut:SetPoint("BOTTOM", helpBut, "TOP", 0, 3)
ijBut:SetScript("OnMouseUp", function() ToggleEncounterJournal() end)

local mountBut = CreateFrame("Frame", "ColdMountButton", MenuIn)
SetButton(mountBut)
Textize(mountBut, "Mounts & Pets")
mountBut:SetPoint("BOTTOM", ijBut, "TOP", 0, 3)
mountBut:SetScript("OnMouseUp", function() TogglePetJournal() end)

local lfgBut = CreateFrame("Frame", "ColdLFGButton", MenuIn)
SetButton(lfgBut)
Textize(lfgBut, "LFDungeon")
lfgBut:SetPoint("BOTTOM", mountBut, "TOP", 0, 3)
lfgBut:SetScript("OnMouseUp", function() ToggleLFDParentFrame() end)

local guildBut = CreateFrame("Frame", "ColdGuildButton", MenuIn)
SetButton(guildBut)
Textize(guildBut, "Guild / LFGuild")
guildBut:SetPoint("BOTTOM", lfgBut, "TOP", 0, 3)
guildBut:SetScript("OnMouseUp", function() 
	if IsInGuild() then 
		ToggleGuildFinder()
	else
		ToggleGuildFrame() 
	end
end)

local pvpBut = CreateFrame("Frame", "ColdPVPButton", MenuIn)
SetButton(pvpBut)
Textize(pvpBut, "PvP")
pvpBut:SetPoint("BOTTOM", guildBut, "TOP", 0, 3)
pvpBut:SetScript("OnMouseUp", function() TogglePVPFrame() end)

local socBut = CreateFrame("Frame", "ColdSocialButton", MenuIn)
SetButton(socBut)
Textize(socBut, "Friends & Ignore")
socBut:SetPoint("BOTTOM", pvpBut, "TOP", 0, 3)
socBut:SetScript("OnMouseUp", function() ToggleFriendsFrame(1) end)

local qlogBut = CreateFrame("Frame", "ColdQuestButton", MenuIn)
SetButton(qlogBut)
Textize(qlogBut, "Quest Log")
qlogBut:SetPoint("BOTTOM", socBut, "TOP", 0, 3)
qlogBut:SetScript("OnMouseUp", function() ToggleFrame(QuestLogFrame) end)

local achvBut = CreateFrame("Frame", "ColdAchvButton", MenuIn)
SetButton(achvBut)
Textize(achvBut, "Achievements")
achvBut:SetPoint("BOTTOM", qlogBut, "TOP", 0, 3)
achvBut:SetScript("OnMouseUp", function() ToggleAchievementFrame() end)

local talBut = CreateFrame("Frame", "ColdTalentButton", MenuIn)
SetButton(talBut)
Textize(talBut, "Talents & Glyphs")
talBut:SetPoint("BOTTOM", achvBut, "TOP", 0, 3)
talBut:SetScript("OnMouseUp", function() ToggleTalentFrame() end)

-- fixing the alert for non-spent talents
TalentMicroButtonAlert:ClearAllPoints()
TalentMicroButtonAlert:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
TalentMicroButtonAlert:SetBackdrop(backdrop)
TalentMicroButtonAlert:SetBackdropColor(.2,.2,.2,.6)
TalentMicroButtonAlert:SetBackdropBorderColor(0,0,0)

local spellBut = CreateFrame("Frame", "ColdSpellbookButton", MenuIn)
SetButton(spellBut)
Textize(spellBut, "Spellbook")
spellBut:SetPoint("BOTTOM", talBut, "TOP", 0, 3)
spellBut:SetScript("OnMouseUp", function() ToggleFrame(SpellBookFrame) end)

local charBut = CreateFrame("Frame", "ColdCharButton", MenuIn)
SetButton(charBut)
Textize(charBut, CHARACTER_BUTTON)
charBut:SetPoint("BOTTOM", spellBut, "TOP", 0, 3)
charBut:SetScript("OnMouseUp", function() ToggleCharacter("PaperDollFrame") end)

local storeBut = CreateFrame("Frame", "ColdStoreButton", MenuIn)
SetButton(storeBut)
Textize(storeBut, "InGame Store")
storeBut:SetPoint("BOTTOM", charBut, "TOP", 0, 3)
storeBut:SetScript("OnMouseUp", function() ToggleStoreUI() end)

MenuOut:SetScript("OnEnter", function() MenuOut:SetAlpha(1) end)
MenuOut:SetScript("OnLeave", function() MenuOut:SetAlpha(0) end)
MenuOut:SetScript("OnMouseUp", function() MenuIn:Show()  MenuOut:Hide()  end)

MenuIn:SetScript("OnMouseUp", function() MenuOut:Show()  MenuIn:Hide()   end)