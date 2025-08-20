---------------------------------------------------------------------------------------------------
-- new runebar plugin, based on the nibRunes addon
-- code is completely rewritten, i kept the base idea on how to manage the runes
-- and the awesome gcd tracker.
----------------------------------------------------------------------------------------------------

--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-- get the library
local lib = ns.lib

local myClass = lib.getClass('player')
if myClass ~= "DEATHKNIGHT" then return end

-- create the container
local ColdRunes = CreateFrame("Frame")
ColdRunes:SetParent(ColdPlayer)
ColdRunes:SetPoint("LEFT", ColdPlayer, "TOPLEFT", 3, 0)
ColdRunes:SetFrameLevel(6)
ColdRunes:SetSize(206, 14)

-- local variables
local RUNETYPE_BLOOD = 1
local RUNETYPE_UNHOLY = 2
local RUNETYPE_FROST = 3
local RUNETYPE_DEATH = 4

local gcdNextDuration = 0
local gcdEnd = 0
local order = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6,}

local runecolors = {
	[1] = {r = 0.9, g = 0.15, b = 0.15},	-- Blood
	[2] = {r = 0.40, g = 0.9, b = 0.30},	-- Unholy
	[3] = {r = 0, g = 0.7, b = 0.9},		-- Frost
	[4] = {r = 0.60, g = 0.37, b = 0.78},	-- Death
}

-- onupdate function (with the double gcd bar tracker)
local function TimeUpdater()
	local time = GetTime()
	
	if time > ColdRunes.LastTime + 0.04 then	-- Update 25 times a second
		-- Update Rune Bars
		local RuneBar
		local start, duration, runeReady
		for rune = 1, 6 do
			RuneBar = ColdRunes.RuneBars[rune]
			start, duration, runeReady = GetRuneCooldown(rune)

			if RuneBar ~= nil then
				if runeReady or UnitIsDead("player") or UnitIsGhost("player") then
					RuneBar.BottomStatusBar:SetValue(1)
					RuneBar.TopStatusBar:SetValue(1)
				else
					RuneBar.BottomStatusBar:SetValue((time - start) / duration)
					RuneBar.TopStatusBar:SetValue(math.max((time - (start + duration - gcdNextDuration)) / gcdNextDuration, 0.0))
				end
			end
		end

		ColdRunes.LastTime = time
	end
end

-- update rune colors
local function ColorUpdater()
	  for rune = 1, 6 do
		RuneBar = ColdRunes.RuneBars[rune]
		if not RuneBar then return end
	
		local RuneType = GetRuneType(rune)
		if RuneType then
		RuneBar.BottomStatusBar.bg:SetTexture(runecolors[RuneType].r * .6, runecolors[RuneType].g * .6, runecolors[RuneType].b * .6)
		RuneBar.TopStatusBar.bg:SetTexture(runecolors[RuneType].r, runecolors[RuneType].g, runecolors[RuneType].b)
	  end
	end
end

local function Rune_TypeUpdate(event, rune)
	if not rune or tonumber(rune) ~= rune or rune < 1 or rune > 6 then
		return
	end
	ColorUpdater()
end

-- getting track of reduced gcd for unholy presence
local function Rune_UpdateForm()
	if GetShapeshiftForm() == 3 then
		gcdNextDuration = 1.0
	else
		gcdNextDuration = 1.5
	end
end

local function Rune_UpdateCooldown()
	local gcdStart, gcdDuration, gcdIsEnabled 
	gcdEnd = gcdIsEnabled and gcdDuration > 0 and gcdStart + gcdDuration or gcdEnd
end

local function Rune_PlayerEnteringWorld()
	ColorUpdater()

	Rune_UpdateForm()
	Rune_UpdateCooldown()
end

local function RuneEvents(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		Rune_PlayerEnteringWorld()
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		Rune_UpdateCooldown()
	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		Rune_UpdateForm()
	elseif event == "RUNE_TYPE_UPDATE" then
		Rune_TypeUpdate(event, ...)
	end
end



-- Settings Update
local function Updater()
	local RuneBar
	for i = 1, 6 do
		local CurRune = order[i]
		RuneBar = ColdRunes.RuneBars[i]

		RuneBar.frame:SetSize(20, 8)
		RuneBar.frame:SetPoint("LEFT", ColdRunes, "LEFT", 2 + (CurRune - 1)*24, 0)
		RuneBar.StatusBarBG:SetPoint("TOPLEFT", RuneBar.frame, "TOPLEFT", -1, 1)
		RuneBar.StatusBarBG:SetPoint("BOTTOMRIGHT", RuneBar.frame, "BOTTOMRIGHT", 1, -1)	
		RuneBar.StatusBarBG:SetFrameLevel(5)
		RuneBar.BottomStatusBar:SetFrameLevel(6)
		RuneBar.TopStatusBar:SetFrameLevel(7)
	end
	
	ColorUpdater()
end

-- Frame Creation
local function CreateFrames()
	if ColdRunes.RuneBars then return end
	
	ColdRunes.RuneBars = {}
	
	local RuneBar
	for i = 1, 6 do
		ColdRunes.RuneBars[i] = {}
		RuneBar = ColdRunes.RuneBars[i]

		-- Create Rune Bar
		RuneBar.frame = CreateFrame("Frame", nil, ColdRunes)
		
		-- Status Bar Background
		RuneBar.StatusBarBG = CreateFrame("Frame", ColdPlayer)
		RuneBar.StatusBarBG:SetBackdrop(backdrop)
		RuneBar.StatusBarBG:SetBackdropColor(.6,.6,.6)
		RuneBar.StatusBarBG:SetBackdropBorderColor(0, 0, 0, 1)	

		-- Bottom Status Bar
		RuneBar.BottomStatusBar = CreateFrame("StatusBar", nil, RuneBar.frame)
		RuneBar.BottomStatusBar:SetOrientation("HORIZONTAL")
		RuneBar.BottomStatusBar:SetMinMaxValues(0, 1)
		RuneBar.BottomStatusBar:SetValue(1)
		RuneBar.BottomStatusBar:SetAllPoints(RuneBar.frame)

		RuneBar.BottomStatusBar.bg = RuneBar.BottomStatusBar:CreateTexture()
		RuneBar.BottomStatusBar.bg:SetAllPoints()
		RuneBar.BottomStatusBar:SetStatusBarTexture(RuneBar.BottomStatusBar.bg)

		-- Top Status Bar
		RuneBar.TopStatusBar = CreateFrame("StatusBar", nil, RuneBar.frame)
		RuneBar.TopStatusBar:SetOrientation("HORIZONTAL")
		RuneBar.TopStatusBar:SetMinMaxValues(0, 1)
		RuneBar.TopStatusBar:SetValue(1)
		RuneBar.TopStatusBar:SetAllPoints(RuneBar.frame)

		RuneBar.TopStatusBar.bg = RuneBar.TopStatusBar:CreateTexture()
		RuneBar.TopStatusBar.bg:SetAllPoints()
		RuneBar.TopStatusBar:SetStatusBarTexture(RuneBar.TopStatusBar.bg)
	end
	Updater()
	
	-- Disable default rune frame
	RuneFrame:UnregisterAllEvents()
	RuneFrame:Hide()
	RuneFrame.Show = function() end
end

local function initialize()
	CreateFrames()
	
	ColdRunes:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	ColdRunes:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	ColdRunes:RegisterEvent("RUNE_TYPE_UPDATE")
	ColdRunes:RegisterEvent("PLAYER_ENTERING_WORLD")
	ColdRunes:SetScript("OnEvent", RuneEvents)
	
	-- Enable OnUpdate handler
	ColdRunes.LastTime = 0
	ColdRunes:SetScript("OnUpdate", TimeUpdater)
end

ColdRunes:RegisterEvent("PLAYER_LOGIN")
ColdRunes:SetScript("OnEvent", initialize)