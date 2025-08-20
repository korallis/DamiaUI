--get the addon namespace
local addon, ns = ...
-- get the library
local B = ns.B

local bars = {
"ColdBar1",
"ColdBar2",
"ColdBar3",
"ColdBar4",
"ColdBar5",
"ColdStance",
"ColdExtra",
"ColdOverride",
"ColdPetBar",
}

local function movebars()
	for _, v in pairs(bars) do
		f = _G[v]
		fn = f:GetName()
		f.handle:SetAlpha(1)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f.btn:Show()
	end
end	

local function lockbars()
	for _, v in pairs(bars) do
		f = _G[v]
		f.handle:SetAlpha(0)
		f:RegisterForDrag(nil)
		f.btn:Hide()
	end	
end

local function resetbars()
	for _, v in pairs(bars) do
		f = _G[v]
		f:ClearAllPoints()
		if v == "ColdBar1" then f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50) end
		if v == "ColdBar2" then f:SetPoint("BOTTOM", _G["ColdBar1"], "TOP", 0, 0) end
		if v == "ColdBar3" then f:SetPoint("BOTTOM", _G["ColdBar2"], "TOP", 0, 0) end
		if v == "ColdBar4" then f:SetPoint("RIGHT", UIParent, "RIGHT", -10, 0) end
		if v == "ColdBar5" then f:SetPoint("RIGHT", _G["ColdBar4"], "LEFT", 0, 0) end
		if v == "ColdStance" then f:SetPoint("BOTTOMRIGHT", _G["ColdBar1"], "BOTTOMLEFT", 0, 0) end
		if v == "ColdExtra" then f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150) end
		if v == "ColdOverride" then f:SetPoint("LEFT", _G["ColdBar1"], "LEFT") end
		if v == "ColdPet" then f:SetPoint("TOP", _G["ColdBar1"], "BOTTOM", 0, 0) end
	end	
	_G["ColdExtra"]:Show() --just to be sure we don't mess with it.
	_G["ColdOverride"]:Show() -- again, override bar should be always visible.
end

-- initialize dragframes and visibility
local initdrag = CreateFrame("Frame")
initdrag:RegisterEvent("PLAYER_LOGIN")
initdrag:SetScript("OnEvent", function(self, event)
    -- setup the visbility DB
	if not ColdBars then ColdBars = {} end

	for _, v in pairs(bars) do
		f = _G[v]
		fn = f:GetName()
		
		if B.checkstate(fn) or v == "ColdExtra" then f:Show()  -- again, EAB is always wanted
		else f:Hide()
		end
	end
end)

-- slash commands
SLASH_MOVEAB1 = "/bm"
SlashCmdList.MOVEAB = function() print("ColdBars: actionbars |c0000FF00unlocked|r") movebars() end

SLASH_LOCKAB1 = "/bl"
SlashCmdList.LOCKAB = function() print("ColdBars: actionbars |c00FF0000locked|r") lockbars() end

SLASH_RESETAB1 = "/br"
SlashCmdList.RESETAB = function() print("ColdBars: actionbars |c004477FFrestored|r") resetbars() end
