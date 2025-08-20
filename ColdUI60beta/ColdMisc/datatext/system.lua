--------------------------------------------------------------------
-- System Stats
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

local Stat = CreateFrame("Frame", "systemFrame", dataTextPanel)
Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:SetFrameStrata("MEDIUM")
Stat:SetFrameLevel(3)
Stat:EnableMouse(true)
Stat.tooltip = false
Stat:SetSize(60, 17)
Stat:SetPoint("RIGHT", dataTextPanel, "CENTER", 3, 0)

local Text  = Stat:CreateFontString(nil, "OVERLAY")
Text:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
Text:SetPoint("CENTER", 0, 1)
Text:SetTextColor(color[1],color[2],color[3])
Text:SetJustifyH"CENTER"

local bandwidthString = "%.2f Mbps"
local percentageString = "%.2f%%"

local kiloByteString = "|c00ffffff%d|rkb"
local megaByteString = "|c00ffffff%.2f|rmib"

local function formatMem(memory)
	local mult = 10^1
	if memory > 999 then
		local mem = ((memory/1024) * mult) / mult
		return string.format(megaByteString, mem)
	else
		local mem = (memory * mult) / mult
		return string.format(kiloByteString, mem)
	end
end

local memoryTable = {}

local function RebuildAddonList(self)
	local addOnCount = GetNumAddOns()
	if (addOnCount == #memoryTable) or self.tooltip == true then return end

	-- Number of loaded addons changed, create new memoryTable for all addons
	memoryTable = {}
	for i = 1, addOnCount do
		memoryTable[i] = { i, select(2, GetAddOnInfo(i)), 0, IsAddOnLoaded(i) }
	end
end

local function UpdateMemory()
	-- Update the memory usages of the addons
	UpdateAddOnMemoryUsage()
	-- Load memory usage in table
	local addOnMem = 0
	local totalMemory = 0
	for i = 1, #memoryTable do
		addOnMem = GetAddOnMemoryUsage(memoryTable[i][1])
		memoryTable[i][3] = addOnMem
		totalMemory = totalMemory + addOnMem
	end
	-- Sort the table to put the largest addon on top
	table.sort(memoryTable, function(a, b)
		if a and b then
			return a[3] > b[3]
		end
	end)
	
	return totalMemory
end

local int = 10

local function Update(self, t)
	int = int - t
	if int < 0 then
		collectgarbage("collect")
		RebuildAddonList(self)
		local total = UpdateMemory()
		Text:SetText(formatMem(total))
		Text:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
		int = 10
	end
end

Stat:SetScript("OnEnter", function(self)
	if not InCombatLockdown() then
		self.tooltip = true
		local bandwidth = GetAvailableBandwidth()
		GameTooltip:SetOwner(Stat, "ANCHOR_TOP", 0, 5)
		GameTooltip:ClearLines()
		if bandwidth ~= 0 then
			GetAvailableBandwidth()
			GameTooltip:AddDoubleLine("Bandwidth: " , string.format(bandwidthString, bandwidth),0.69, 0.31, 0.31,0.84, 0.75, 0.65)
			GameTooltip:AddDoubleLine("Download: ", string.format(percentageString, GetDownloadedPercentage() *100),0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
			GameTooltip:AddLine(" ")
		end
		local totalMemory = UpdateMemory()
		GameTooltip:AddDoubleLine("Total Memory Usage: ", formatMem(totalMemory), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
		GameTooltip:AddLine(" ")
		for i = 1, #memoryTable do
			if (memoryTable[i][4]) then
				local red = memoryTable[i][3] / totalMemory
				local green = 1 - red
				GameTooltip:AddDoubleLine(memoryTable[i][2], formatMem(memoryTable[i][3]), 1, 1, 1, red, green + .5, 0)
			end						
		end
		GameTooltip:Show()
	end
end)
Stat:SetScript("OnLeave", function(self) self.tooltip = false GameTooltip:Hide() end)
Stat:SetScript("OnUpdate", Update)
Update(Stat, 10)