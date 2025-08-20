--------------------------------------------------------------------
-- DURABILITY
--------------------------------------------------------------------
local classcolors = {
		["DEATHKNIGHT"] = { 196/255,  30/255,  60/255 },
		["DRUID"]       = { 255/255, 125/255,  10/255 },
		["HUNTER"]      = { 171/255, 214/255, 116/255 },
		["MAGE"]        = { 104/255, 205/255, 255/255 },
		["PALADIN"]     = { 245/255, 140/255, 186/255 },
		["PRIEST"]      = { 212/255, 212/255, 212/255 },
		["ROGUE"]       = { 255/255, 243/255,  82/255 },
		["SHAMAN"]      = {  41/255,  79/255, 155/255 },
		["WARLOCK"]     = { 148/255, 130/255, 201/255 },
		["WARRIOR"]     = { 199/255, 156/255, 110/255 },
		["MONK"]        = {   0/255, 156/255, 110/255 },
}

local _, theClass = UnitClass("player")
local color = classcolors[theClass]

local Panel = CreateFrame("Frame", "dataTextPanel", UIParent)
Panel:SetSize(316, 17)
Panel:SetFrameLevel(1)
Panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 10)
Panel:SetBackdrop({
	bgFile = "Interface\\AddOns\\ColdMisc\\media\\flat2",
	edgeFile = "Interface\\AddOns\\ColdMisc\\media\\flat2",
	edgeSize = 1,
})
Panel:SetBackdropBorderColor(0, 0, 0)
Panel:SetBackdropColor(.2, .2, .2, .6)

local Stat = CreateFrame("Frame", "durFrame", Panel)
Stat:EnableMouse(true)
Stat:SetFrameStrata("MEDIUM")
Stat:SetFrameLevel(3)
Stat:SetSize(60, 17)
Stat:SetPoint("LEFT", Panel, "CENTER", 18, 0)

local Text  = Stat:CreateFontString(nil, "OVERLAY")
Text:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
Text:SetPoint("CENTER", 0, 1)
Text:SetTextColor(color[1],color[2],color[3])
Text:SetJustifyH"CENTER"


local Total = 0
local current, max
	
local Slots = {
	[1] = {1, "Head", 1000},
	[2] = {3, "Shoulder", 1000},
	[3] = {5, "Chest", 1000},
	[4] = {6, "Waist", 1000},
	[5] = {9, "Wrist", 1000},
	[6] = {10, "Hands", 1000},
	[7] = {7, "Legs", 1000},
	[8] = {8, "Feet", 1000},
	[9] = {16, "Main Hand", 1000},
	[10] = {17, "Off Hand", 1000},
	[11] = {18, "Ranged", 1000}
}

	local function OnEvent(self)
		for i = 1, 11 do
			if GetInventoryItemLink("player", Slots[i][1]) ~= nil then
				current, max = GetInventoryItemDurability(Slots[i][1])
				if current then 
					Slots[i][3] = current/max
					Total = Total + 1
				end
			end
		end
		table.sort(Slots, function(a, b) return a[3] < b[3] end)
		
		if Total > 0 then
			Text:SetText("|c00ffffff"..floor(Slots[1][3]*100).."%|rdur")
		else
			Text:SetText("100% ".."dur")
		end
		-- Setup Durability Tooltip
		Total = 0
	end

	Stat:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	Stat:RegisterEvent("MERCHANT_SHOW")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:SetScript("OnMouseDown", function() ToggleCharacter("PaperDollFrame") end)
	Stat:SetScript("OnEvent", OnEvent)
	Stat:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(Stat, "ANCHOR_TOP", 0, 5)
			GameTooltip:ClearLines()
			for i = 1, 11 do
				if Slots[i][3] ~= 1000 then
					green = Slots[i][3]*2
					red = 1 - green
					GameTooltip:AddDoubleLine(Slots[i][2], floor(Slots[i][3]*100).."%",1 ,1 , 1, red + 1, green, 0)
				end
			end
			GameTooltip:Show()
		end
	end)
	Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)