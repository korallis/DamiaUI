-- Minimap reskin (pretty stolen from minimalist addons) 
-- has standard functions, scrolling zoom, tracking, other stuff

-- stuff you don't want to change
local _TEXTURE = "Interface\\AddOns\\ColdMisc\\media\\flat2"
local blankTex = "Interface\\AddOns\\ColdMisc\\media\\flat2"
local font = "Interface\\AddOns\\ColdMisc\\media\\homespun.ttf"
local fs = 10
local _, playerClass = UnitClass('player')
local backdrop = {
	edgeFile = blankTex,
	edgeSize = 1,
}
local backdropfull = {
	bgFile = _TEXTURE,
	edgeFile = blankTex,
	edgeSize = 1,
}

-- start the magic!
local ColdMinimap = CreateFrame("Frame", "ColdMinimap", UIParent)
ColdMinimap:RegisterEvent("ADDON_LOADED")
ColdMinimap:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 10)
ColdMinimap:SetSize(140, 140)
ColdMinimap:SetBackdrop(backdrop)
ColdMinimap:SetBackdropColor(0, 0, 0, 0)
ColdMinimap:SetBackdropBorderColor(0, 0, 0, 1)

-- kill the minimap cluster
MinimapCluster:Hide()

-- Parent Minimap into our Map frame.
Minimap:SetParent(ColdMinimap)
Minimap:ClearAllPoints()
Minimap:SetPoint("TOPLEFT", 1, -1)
Minimap:SetPoint("BOTTOMRIGHT", -1, 1)

-- Hide Border
MinimapBorder:Hide()
MinimapBorderTop:Hide()

-- Hide Zoom Buttons
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()

-- Hide Voice Chat Frame
MiniMapVoiceChatFrame:Hide()

-- Hide North texture at top
MinimapNorthTag:SetTexture(nil)

-- Hide Zone Frame
MinimapZoneTextButton:Hide()

-- Hide Tracking Button
MiniMapTracking:Hide()

-- Hide Calendar Button
GameTimeFrame:Hide()

-- Hide Mail Button
MiniMapMailFrame:ClearAllPoints()
MiniMapMailFrame:SetPoint("TOPRIGHT", Minimap, 3, 3)
MiniMapMailBorder:Hide()

-- Hide world map button
MiniMapWorldMapButton:Hide()

-- shitty 3.3 flag to move
MiniMapInstanceDifficulty:ClearAllPoints()
MiniMapInstanceDifficulty:SetParent(Minimap)
MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

-- 4.0.6 Guild instance difficulty
GuildInstanceDifficulty:ClearAllPoints()
GuildInstanceDifficulty:SetParent(Minimap)
GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

-- Reposition lfg icon at bottom-left and its tooltip
QueueStatusMinimapButton:ClearAllPoints()
QueueStatusMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, 1)
QueueStatusMinimapButtonBorder:Hide()

-- new objectives tracker that needs to get moved 
ObjectiveTrackerFrame:ClearAllPoints()
ObjectiveTrackerFrame:SetParent(UIParent)
ObjectiveTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, -2)

-- Enable mouse scrolling
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, d)
	if d > 0 then
		_G.MinimapZoomIn:Click()
	elseif d < 0 then
		_G.MinimapZoomOut:Click()
	end
end)

-- Set Square Map Mask
Minimap:SetMaskTexture(blankTex)

-- For others mods with a minimap button, set minimap buttons position in square mode.
function GetMinimapShape() return "SQUARE" end

-- do some stuff on addon loaded or player login event
ColdMinimap:SetScript("OnEvent", function(self, event, addon)
	if addon == "Blizzard_TimeManager" then
		-- Hide Game Time
		TimeManagerClockButton:Hide()
	end
end)

----------------------------------------------------------------------------------------
-- Right click tracking menu
----------------------------------------------------------------------------------------

Minimap:SetScript("OnMouseUp", function(self, btn)
	if btn == "RightButton" then
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, ColdMinimap)
	else
		Minimap_OnClick(self)
	end
end)

--------------------------------------------------------------------------------------------------
-- Mouseover map, displaying zone and coords (taken from TukUI who made with the help of others)
--------------------------------------------------------------------------------------------------

local m_zone = CreateFrame("Frame",nil,UIParent)
m_zone:SetPoint("TOP",Minimap, "TOP",0,-2)
m_zone:SetSize(134, 20)
m_zone:SetBackdrop(backdropfull)
m_zone:SetBackdropColor(.2, .2, .2, .6)
m_zone:SetBackdropBorderColor(0, 0, 0, 1)
m_zone:SetFrameLevel(5)
m_zone:SetAlpha(0)

local m_zone_text = m_zone:CreateFontString(nil,"Overlay")
m_zone_text:SetFont(font,fs,"OUTLINE, MONOCHROME")
m_zone_text:SetPoint("TOP", 0, -1)
m_zone_text:SetPoint("BOTTOM")
m_zone_text:SetHeight(12)
m_zone_text:SetWidth(m_zone:GetWidth()-6)
m_zone_text:SetAlpha(0)

local m_coord = CreateFrame("Frame",nil,UIParent)
m_coord:SetPoint("BOTTOMLEFT",Minimap,2,2)
m_coord:SetSize(40,20)
m_coord:SetBackdrop(backdropfull)
m_coord:SetBackdropColor(.2, .2, .2, .6)
m_coord:SetBackdropBorderColor(0, 0, 0, 1)
m_coord:SetFrameLevel(5)
m_coord:SetAlpha(0)

local m_coord_text = m_coord:CreateFontString(nil,"Overlay")
m_coord_text:SetFont(font,fs,"OUTLINE, MONOCHROME")
m_coord_text:SetPoint("Center",1,0)
m_coord_text:SetAlpha(0)
m_coord_text:SetText("00,00")

Minimap:SetScript("OnEnter",function()
	m_zone:SetAlpha(1)
	m_zone_text:SetAlpha(1)
	m_coord:SetAlpha(1)
	m_coord_text:SetAlpha(1)
end)

Minimap:SetScript("OnLeave",function()
	m_zone:SetAlpha(0)
	m_zone_text:SetAlpha(0)
	m_coord:SetAlpha(0)
	m_coord_text:SetAlpha(0)
end)
 
local ela = 0
local coord_Update = function(self,t)
	ela = ela - t
	if ela > 0 then return end
	local x,y = GetPlayerMapPosition("player")
	local xt,yt
	x = math.floor(100 * x)
	y = math.floor(100 * y)
	if x == 0 and y == 0 then
		m_coord_text:SetText("X _ X")
	else
		if x < 10 then
			xt = "0"..x
		else
			xt = x
		end
		if y < 10 then
			yt = "0"..y
		else
			yt = y
		end
		m_coord_text:SetText(xt..","..yt)
	end
	ela = .2
end
m_coord:SetScript("OnUpdate",coord_Update)
 
local zone_Update = function()
	local pvp = GetZonePVPInfo()
	m_zone_text:SetText(GetMinimapZoneText())
	if pvp == "friendly" then
		m_zone_text:SetTextColor(0.1, 1.0, 0.1)
	elseif pvp == "sanctuary" then
		m_zone_text:SetTextColor(0.41, 0.8, 0.94)
	elseif pvp == "arena" or pvp == "hostile" then
		m_zone_text:SetTextColor(1.0, 0.1, 0.1)
	elseif pvp == "contested" then
		m_zone_text:SetTextColor(1.0, 0.7, 0.0)
	else
		m_zone_text:SetTextColor(1.0, 1.0, 1.0)
	end
end
 
m_zone:RegisterEvent("PLAYER_ENTERING_WORLD")
m_zone:RegisterEvent("ZONE_CHANGED_NEW_AREA")
m_zone:RegisterEvent("ZONE_CHANGED")
m_zone:RegisterEvent("ZONE_CHANGED_INDOORS")
m_zone:SetScript("OnEvent",zone_Update) 