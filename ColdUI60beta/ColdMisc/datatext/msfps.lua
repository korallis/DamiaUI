--------------------------------------------------------------------
-- FPS & LATENCY
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

local Stat = CreateFrame("Frame", "fpsFrame", dataTextPanel)
Stat:SetFrameStrata("MEDIUM")	
Stat:SetFrameLevel(3)
Stat:EnableMouse(true)
Stat:SetSize(90, 17)
Stat:SetPoint("LEFT", dataTextPanel, "LEFT")

local Text  = Stat:CreateFontString(nil, "OVERLAY")
Text:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
Text:SetPoint("LEFT", 6, 1)
Text:SetJustifyH"LEFT"


-- colorize the tags with class colors
local fpstag = "fps "
local mlstag = "mls"
Text:SetTextColor(color[1],color[2],color[3])

local int = 1
local function Update(self, t)
	int = int - t
	if int < 0 then
		Text:SetText("|c00ffffff"..floor(GetFramerate()).."|r"..fpstag.."|c00ffffff"..select(3, GetNetStats()).."|r"..mlstag)
		int = 1			
	end	
end
	
Stat:SetScript("OnUpdate", Update) 
Stat:SetScript("OnEnter", function(self)
    if not InCombatLockdown() then
		local _, _, latencyHome, latencyWorld = GetNetStats()
		local latency = format(MAINMENUBAR_LATENCY_LABEL, latencyHome, latencyWorld)
		GameTooltip:SetOwner(Stat, "ANCHOR_TOP", 11, 5)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(latency)
		GameTooltip:Show()
	end
end)	
Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)	
Update(Stat, 10)
