local ColdTooltip = CreateFrame("Frame", "ColdTooltip", UIParent)

local font = "Interface\\AddOns\\ColdMisc\\media\\homespun.ttf"
local fs = 10
local _TEXTURE = "Interface\\AddOns\\ColdMisc\\media\\flat2"
local blankTex = "Interface\\AddOns\\ColdMisc\\media\\flat2"

local _G = getfenv(0)

local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]

local gsub, find, format = string.gsub, string.find, string.format

local Tooltips = {GameTooltip,ShoppingTooltip1,ShoppingTooltip2,ShoppingTooltip3,WorldMapTooltip}
local ItemRefTooltip = ItemRefTooltip

local linkTypes = {item = true, enchant = true, spell = true, quest = true, unit = true, talent = true, achievement = true, glyph = true}

local classification = {
	worldboss = "|cffAF5050Boss|r",
	rareelite = "|cffAF5050+ Rare|r",
	elite = "|cffAF5050+|r",
	rare = "|cffAF5050Rare|r",
}

local NeedBackdropBorderRefresh = true

local anchor = CreateFrame("Frame", "ColdTooltipAnchor", UIParent)
anchor:SetSize(200, 10)
anchor:SetFrameStrata("TOOLTIP")
anchor:SetFrameLevel(20)
anchor:SetClampedToScreen(true)
anchor:SetAlpha(0)
anchor:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 1, -6)

local SetTemplate = function(f)
	f:SetBackdrop({
	  bgFile = _TEXTURE, 
	  edgeFile = blankTex, 
	  tile = false, tileSize = 0, edgeSize = 1,})
	f:SetBackdropColor(.2,.2,.2,.6)
	f:SetBackdropBorderColor(0,0,0)
end

-- Update Tooltip Position on some specifics Tooltip
-- Also used because on Eyefinity, SetClampedToScreen doesn't work on left and right side of screen #1
local function UpdateTooltip(self)
	local owner = self:GetOwner()
	if not owner then return end	
	local name = owner:GetName()
	
	-- fix X-offset or Y-offset
	local x = 0
	
	-- mouseover
	if self:GetAnchorType() == "ANCHOR_CURSOR" then	
		if NeedBackdropBorderRefresh then
			NeedBackdropBorderRefresh = false			
			self:SetBackdropColor(.2,.2,.2,.6)
		end
	elseif self:GetAnchorType() == "ANCHOR_NONE" and InCombatLockdown() then
		self:Hide()
	end
	
		
	if self:GetAnchorType() == "ANCHOR_NONE" and ColdTooltipAnchor then
		local point = ColdTooltipAnchor:GetPoint()
		if point == "TOPLEFT" then
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", ColdTooltipAnchor, "BOTTOMLEFT", 0, -x)			
		elseif point == "TOP" then
			self:ClearAllPoints()
			self:SetPoint("TOP", ColdTooltipAnchor, "BOTTOM", 0, -x)			
		elseif point == "TOPRIGHT" then
			self:ClearAllPoints()
			self:SetPoint("TOPRIGHT", ColdTooltipAnchor, "BOTTOMRIGHT", 0, -x)			
		elseif point == "BOTTOMLEFT" or point == "LEFT" then
			self:ClearAllPoints()
			self:SetPoint("BOTTOMLEFT", ColdTooltipAnchor, "TOPLEFT", 0, x)		
		elseif point == "BOTTOMRIGHT" or point == "RIGHT" then
				self:ClearAllPoints()
				self:SetPoint("BOTTOMRIGHT", ColdTooltipAnchor, "TOPRIGHT", 0, x)
		else
			self:ClearAllPoints()
			self:SetPoint("BOTTOM", ColdTooltipAnchor, "TOP", 0, x)		
		end
	end
	
end

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self, parent)
		self:SetOwner(parent, "ANCHOR_NONE")
end)

GameTooltip:HookScript("OnUpdate", function(self, ...) UpdateTooltip(self) end)

local function Hex(color)
	return string.format('|cff%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

local function GetColor(unit)
	if(UnitIsPlayer(unit) and not UnitHasVehicleUI(unit)) then
		local _, class = UnitClass(unit)
		local color = RAID_CLASS_COLORS[class]
		if not color then return end -- sometime unit too far away return nil for color :(
		local r,g,b = color.r, color.g, color.b
		return Hex(color), r, g, b	
	else
		local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		if not color then return end -- sometime unit too far away return nil for color :(
		local r,g,b = color.r, color.g, color.b		
		return Hex(color), r, g, b		
	end
end

-- update HP value on status bar
GameTooltipStatusBar:SetScript("OnValueChanged", function(self, value)
	if not value then
		return
	end
	local min, max = self:GetMinMaxValues()
	
	if (value < min) or (value > max) then
		return
	end
	local _, unit = GameTooltip:GetUnit()
	
	-- fix target of target returning nil
	if (not unit) then
		local GMF = GetMouseFocus()
		unit = GMF and GMF:GetAttribute("unit")
	end
end)

local healthBar = GameTooltipStatusBar
healthBar:ClearAllPoints()
healthBar:SetHeight(6)
healthBar:SetPoint("BOTTOMLEFT", healthBar:GetParent(), "TOPLEFT", 1, 3)
healthBar:SetPoint("BOTTOMRIGHT", healthBar:GetParent(), "TOPRIGHT", -1, 3)
healthBar:SetStatusBarTexture(_TEXTURE)

local healthBarBG = CreateFrame("Frame", "StatusBarBG", healthBar)
healthBarBG:SetFrameLevel(healthBar:GetFrameLevel() - 1)
healthBarBG:SetPoint("TOPLEFT", -1, 1)
healthBarBG:SetPoint("BOTTOMRIGHT", 1, -1)
SetTemplate(healthBarBG)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local lines = self:NumLines()
	local GMF = GetMouseFocus()
	local unit = (select(2, self:GetUnit())) or (GMF and GMF:GetAttribute("unit"))
	
	-- A mage's mirror images sometimes doesn't return a unit, this would fix it
	if (not unit) and (UnitExists("mouseover")) then
		unit = "mouseover"
	end
	
	-- Sometimes when you move your mouse quicky over units in the worldframe, we can get here without a unit
	if not unit then self:Hide() return end
	
	-- A "mouseover" unit is better to have as we can then safely say the tip should no longer show when it becomes invalid.
	if (UnitIsUnit(unit,"mouseover")) then
		unit = "mouseover"
	end

	local race = UnitRace(unit)
	local class = UnitClass(unit)
	local level = UnitLevel(unit)
	local guild = GetGuildInfo(unit)
	local name, realm = UnitName(unit)
	local crtype = UnitCreatureType(unit)
	local classif = UnitClassification(unit)
	local title = UnitPVPName(unit)
	local r, g, b = GetQuestDifficultyColor(level).r, GetQuestDifficultyColor(level).g, GetQuestDifficultyColor(level).b

	local color = GetColor(unit)	
	if not color then color = "|CFFFFFFFF" end -- just safe mode for when GetColor(unit) return nil for unit too far away

	if UnitIsPlayer(unit) then _G["GameTooltipTextLeft1"]:SetFormattedText("%s%s%s", color, name, realm and realm ~= "" and " *|r" or "|r") end
	_G["GameTooltipTextLeft1"]:SetFont(font,fs,'OUTLINE, MONOCHROME')

	if(UnitIsPlayer(unit)) then
		if UnitIsAFK(unit) then
			self:AppendText((" %s"):format(CHAT_FLAG_AFK))
		elseif UnitIsDND(unit) then 
			self:AppendText((" %s"):format(CHAT_FLAG_DND))
		end

		local offset = 2
		if guild then
			_G["GameTooltipTextLeft2"]:SetFormattedText("%s", IsInGuild() and GetGuildInfo("player") == guild and "|cff0090ff"..guild.."|r" or "|cff00ff10"..guild.."|r")
			_G["GameTooltipTextLeft2"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
			offset = offset + 1
		end

		for i= offset, lines do
			if(_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) then
				_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r %s", r*255, g*255, b*255, level > 0 and level or "??", race.."|r")
				_G["GameTooltipTextLeft"..i]:SetFont(font,fs,'OUTLINE, MONOCHROME')
				break
			end
		end
	else
		for i = 2, lines do
			if((_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) or (crtype and _G["GameTooltipTextLeft"..i]:GetText():find("^"..crtype))) then
				if level == -1 and classif == "elite" then classif = "worldboss" end
				_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r%s %s", r*255, g*255, b*255, classif ~= "worldboss" and level ~= 0 and level or "", classification[classif] or "", crtype or "")
				_G["GameTooltipTextLeft"..i]:SetFont(font,fs,'OUTLINE, MONOCHROME')
				break
			end
		end
	end

	local pvpLine
	for i = 1, lines do
		local text = _G["GameTooltipTextLeft"..i]:GetText()
		if text and text == PVP_ENABLED then
			pvpLine = _G["GameTooltipTextLeft"..i]
			pvpLine:SetText()
			_G["GameTooltipTextLeft"..i]:SetFont(font,fs,'OUTLINE, MONOCHROME')
			break
		end
	end

	-- ToT line
	if UnitExists(unit.."target") and unit~="player" then
		local hex, r, g, b = GetColor(unit.."target")
		if not r and not g and not b then r, g, b = 1, 1, 1 end
		GameTooltip:AddLine(UnitName(unit.."target"), r, g, b)
	end
	
	-- forcefully setting fonts on other tooltip lines
	_G["GameTooltipTextLeft2"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipTextLeft3"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipTextLeft4"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipText"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	if _G["GameTooltipMoneyFrame1PrefixText"] then 
	  _G["GameTooltipMoneyFrame1PrefixText"]:SetFont(font,fs,'OUTLINE, MONOCHROME') 
	  _G["GameTooltipMoneyFrame1PrefixText"]:SetShadowOffset(0,0)
	end  

	-- Sometimes this wasn't getting reset, the fact a cleanup isn't performed at this point, now that it was moved to "OnTooltipCleared" is very bad, so this is a fix
	self.fadeOut = nil
end)

local BorderColor = function(self)
	local GMF = GetMouseFocus()
	local unit = (select(2, self:GetUnit())) or (GMF and GMF:GetAttribute("unit"))
		
	local reaction = unit and UnitReaction(unit, "player")
	local player = unit and UnitIsPlayer(unit)
	local tapped = unit and UnitIsTapped(unit)
	local tappedbyme = unit and UnitIsTappedByPlayer(unit)
	local connected = unit and UnitIsConnected(unit)
	local dead = unit and UnitIsDead(unit)

	if player then
		local class = select(2, UnitClass(unit))
		local c = RAID_CLASS_COLORS[class]
		r, g, b = c.r, c.g, c.b
		healthBar:SetStatusBarColor(r, g, b)
	elseif reaction then
		local c = colors.reaction[reaction]
		r, g, b = c[1], c[2], c[3]
		healthBar:SetStatusBarColor(r, g, b)
	else
		local _, link = self:GetItem()
		local quality = link and select(3, GetItemInfo(link))
		if quality and quality >= 2 then
			local r, g, b = GetItemQualityColor(quality)
			self:SetBackdropBorderColor(r, g, b)
		else
			healthBar:SetStatusBarColor(.6,.6,.6)
		end
	end
	self:SetBackdropBorderColor(0,0,0)
	healthBarBG:SetBackdropBorderColor(0,0,0)
	
	-- need this
	NeedBackdropBorderRefresh = true
end

local SetStyle = function(self)
	SetTemplate(self)
	BorderColor(self)
	if _G["GameTooltipMoneyFrame1PrefixText"] then 
	  _G["GameTooltipMoneyFrame1PrefixText"]:SetFont(font,fs,'OUTLINE, MONOCHROME') 
	  _G["GameTooltipMoneyFrame1PrefixText"]:SetShadowOffset(0,0)
	end  	
end

ColdTooltip:RegisterEvent("PLAYER_LOGIN")
ColdTooltip:RegisterEvent("PLAYER_ENTERING_WORLD")
ColdTooltip:SetScript("OnEvent", function(self)
	for _, ct in pairs(Tooltips) do
		ct:HookScript("OnShow", SetStyle)
	end
	
	ItemRefTooltip:HookScript("OnTooltipSetItem", SetStyle)
	ItemRefTooltip:HookScript("OnShow", SetStyle)	
	SetTemplate(FriendsTooltip)
	--forcefully setting font on load
	_G["GameTooltipTextLeft1"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipTextLeft2"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipTextLeft3"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipTextLeft4"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
	_G["GameTooltipText"]:SetFont(font,fs,'OUTLINE, MONOCHROME')
 	
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:SetScript("OnEvent", nil)
end)