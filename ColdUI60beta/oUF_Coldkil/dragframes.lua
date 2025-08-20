--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-- get the library
local lib = ns.lib

local layout = ns.cfg.layout
local frames ={
	"ColdPlayer",
	"ColdPet",
	"ColdTarget",
	"ColdToT",
	"ColdFocus",
	"ColdPartyAnchor",
	"ColdRaidAnchor",
	"ColdLoot",
}

function moveframes()
	for _, v in pairs(frames) do
		f = _G[v]
		fn = f:GetName()
		f.draggable:SetAlpha(1)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
	end
	LootFrame:Show()
end	

function lockframes()
	for _, v in pairs(frames) do
		f = _G[v]
		f.draggable:SetAlpha(0)
		f:RegisterForDrag(nil)
	end	
	LootFrame:Hide()
end

function setupframes()
	print("ColdUI: layout |c004477FFrestored|r")
	_G["ColdPlayer"]:SetPoint("BOTTOM", UIParent, "BOTTOM", -180, 240)
	_G["ColdPet"]:SetPoint('TOPLEFT', _G["ColdPlayer"], 'TOPRIGHT', 7, 0)
	_G["ColdTarget"]:SetPoint("BOTTOM", UIParent, "BOTTOM", 180, 240)
	_G["ColdToT"]:SetPoint("TOPRIGHT", _G["ColdTarget"], "TOPLEFT", -7, 0)
	_G["ColdFocus"]:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 232)
	_G["ColdPartyAnchor"]:SetPoint("TOPLEFT", UIParent, "LEFT", 10, 10)
	_G["ColdRaidAnchor"]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 172)
	_G["ColdLoot"]:SetPoint("LEFT", UIParent, "CENTER", 20, 0)
end

function resetframes()
	for _, v in pairs(frames) do
		f = _G[v]
		f:ClearAllPoints()
	end
	setupframes()
end

SLASH_MOVEUI1 = "/fm"
SlashCmdList.MOVEUI = function() print("ColdUI: frames |c0000FF00unlocked|r") moveframes() end

SLASH_LOCKUI1 = "/fl"
SlashCmdList.LOCKUI = function() print("ColdUI: frames |c00FF0000locked|r") lockframes() end

SLASH_LAYOUT1 = "/fr"
SlashCmdList.LAYOUT = function() resetframes() end

