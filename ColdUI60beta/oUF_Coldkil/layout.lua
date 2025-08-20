--[[-------------------------------------------------------------------------
Coldkil unitframes layout - now with 138% more awesomeness
---------------------------------------------------------------------------]]

--get the addon namespace
local addon, ns = ...

--get the config values
local cfg = ns.cfg
local L = ns.cfg.layout
local P = ns.cfg.player
local T = ns.cfg.target
local Pa = ns.cfg.party
local R = ns.cfg.raid

-- get the library
local lib = ns.lib

-------------------------------------------------------------
--      Local variables
-------------------------------------------------------------
local tex = cfg.tex
local font = cfg.font
local smalls = cfg.fontsize
local myClass = lib.getClass('player')
local mySpec = GetSpecialization()
local dummy = function() return end

-------------------------------------------------------------
--      Unit Frames Layout
-------------------------------------------------------------
local Shared = function(self, unit, isSingle)
	self.menu = lib.menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	-- XXX: Change to AnyUp when RegisterAttributeDriver doesn't cause clicks
	-- to get incorrectly eaten.
	self:RegisterForClicks("AnyDown")
	
	-- enable our colors
	self.colors = colors
	
	if unit == "player" or unit == "target" then
		self:SetSize(200, 30)
	elseif unit == "focus" or unit == "pet" or unit == "targettarget" then
		self:SetSize(60, 16)
	elseif unit == "party" then
		self:SetSize(150, 20)
	else
		self:SetSize(35, 32)
	end

	------------------------------------------------------------
	--  Shared things we want on different unitframes
	------------------------------------------------------------	
	local panelhp = CreateFrame("Frame",nil,self)
	panelhp:SetFrameLevel(7)
	local over = CreateFrame("Frame",nil,self)
	self.Panelhp = panelhp
	self.over = over
	
	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetFrameLevel(3)
	Health:SetStatusBarTexture(tex)
	local HealthBackground = Health:CreateTexture(nil, "BORDER")
	HealthBackground:SetTexture(tex)
	Health.bg = HealthBackground
	local shadowH = CreateFrame("Frame", nil, Health)
	shadowH:SetFrameLevel(3)
	shadowH:SetPoint("TOPLEFT", Health, "TOPLEFT", -1, 1)
	shadowH:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 1, -1)
	shadowH:SetBackdrop(backdrop)
	shadowH:SetBackdropColor(0, 0, 0, 0)
	shadowH:SetBackdropBorderColor(0, 0, 0, 1)
	Health.frequentUpdates = true
	Health.Smooth = true
	Health.PostUpdate = lib.PostUpdateHealth
	self.Health = Health
	-- HP text/tag
	local HealthPoints = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	local HPper = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	self:Tag(HealthPoints, '[dead][offline][coldhp]')
	Health.value = HealthPoints
	Health.valueper = HPper
	
	-- Power Bar
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetFrameLevel(3)
	Power:SetStatusBarTexture(tex)
	local PowerBackground = Power:CreateTexture(nil, "BORDER")
	PowerBackground:SetTexture(tex)
	local shadowP = CreateFrame("Frame", nil, Power)
	shadowP:SetFrameLevel(3)
	shadowP:SetPoint("TOPLEFT", Power, "TOPLEFT", -1, 1)
	shadowP:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT", 1, -1)
	shadowP:SetBackdrop(backdrop)
	shadowP:SetBackdropColor(.6, .6, .6, .25)
	shadowP:SetBackdropBorderColor(0, 0, 0, 1)
	Power.bg = PowerBackground
	Power.frequentUpdates = true
	Power.Smooth = true
	self.Power = Power
	-- Power text/tag
	local PowerPoints = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	local powtag = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	Power.value = PowerPoints
	Power.tag = powtag
	Power.PostUpdate = lib.PostUpdatePower
	
	--Portrait
	local portrait = CreateFrame("PlayerModel", nil, self)
	portrait:SetFrameLevel(4)
	self.Portrait = portrait
	
	-- Castbar
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(tex)		
	Castbar:SetFrameLevel(2)
	Castbar.PostCastStart = lib.CheckCast
	Castbar.PostChannelStart = lib.CheckChannel
	local CBshadow = CreateFrame("Frame", nil, Castbar)
	CBshadow:SetFrameLevel(2)
	CBshadow:SetPoint("TOPLEFT", Castbar, "TOPLEFT", -1, 1)
	CBshadow:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMRIGHT", 1, -1)
	CBshadow:SetBackdrop(backdrop)
	CBshadow:SetBackdropColor(.1,.1,.1,.9)
	CBshadow:SetBackdropBorderColor(0, 0, 0, 1)
	-- Castbar Text
	Castbar.time = lib.SetFontString(Castbar, font, smalls, "OUTLINE, MONOCHROME")
	Castbar.Text = lib.SetFontString(Castbar, font, smalls, "OUTLINE, MONOCHROME")
	self.Castbar = Castbar
	self.Castbar.Time = Castbar.time
	
	-- Name, Level, Classiication
	Name = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	Level = lib.SetFontString(panelhp, font, smalls, "OUTLINE, MONOCHROME")
	self:Tag(Name, '[name]')
	self:Tag(Level, '[level][shortclassification][difficulty]')
	self.Level = Level
	self.Name = Name
	
	-------------------------------------------------------------
	--      Player Layout
	-------------------------------------------------------------
	if unit == "player" then	
		local classcolor = colors.class[lib.getClass(unit)]
		
		Health:SetPoint("TOPLEFT", self, "TOPLEFT")
		Health:SetPoint("TOPRIGHT", self, "TOPRIGHT")
		Health:SetHeight(16)
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("TOPRIGHT", Health, "TOPRIGHT")
		HealthBackground:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT")

		if L.portraits then
		  portrait:SetPoint("TOPLEFT", Health, "TOPLEFT")
		  portrait:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -1, 1)
		  portrait:SetAlpha(.25)	
		end
		
		Power:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
		Power:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
		Power:SetHeight(8)
		PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		PowerBackground:SetPoint("TOPRIGHT", Power, "TOPRIGHT")
		PowerBackground:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT")
		
		panelhp:SetPoint("LEFT", Power, "LEFT", 3, -6)
		panelhp:SetSize(75,13)
		panelhp:SetBackdrop(backdrop)
		panelhp:SetBackdropColor(.6,.6,.6)
		panelhp:SetBackdropBorderColor(0,0,0)
		
		HealthPoints:SetPoint("RIGHT", panelhp, "RIGHT", P.hpX, P.hpY)
		HealthPoints:SetJustifyH"RIGHT"
		
		PowerPoints:SetPoint("LEFT", panelhp, "LEFT", P.powX, P.powY)
		PowerPoints:SetTextColor(classcolor[1],classcolor[2],classcolor[3])
				
		panelhp:RegisterEvent("PLAYER_REGEN_ENABLED")
		panelhp:RegisterEvent("PLAYER_REGEN_DISABLED")
		panelhp:RegisterEvent("PLAYER_UPDATE_RESTING")
		panelhp:RegisterEvent("PLAYER_ENTERING_WORLD")
		panelhp:SetScript("OnEvent", function(self, event)
			if event == "PLAYER_ENTERING_WORLD" then
				if IsResting() and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
					PowerPoints:SetTextColor(0,.4,1)
				end	
		    elseif event == "PLAYER_REGEN_DISABLED" then
			  PowerPoints:SetTextColor(1,0,0)
		    elseif event == "PLAYER_UPDATE_RESTING" and IsResting() and UnitLevel("player") ~= MAX_PLAYER_LEVEL or event == "PLAYER_REGEN_ENABLED" and IsResting() and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
			  PowerPoints:SetTextColor(0,.4,1)
		    else
			  PowerPoints:SetTextColor(classcolor[1],classcolor[2],classcolor[3])
		    end
	    end)

		Castbar:SetPoint("LEFT", self, "LEFT",-3,-4)
		Castbar:SetPoint("RIGHT", self, "RIGHT",3,-4)
		Castbar:SetHeight(13)
		Castbar.time:SetPoint("TOPRIGHT", Power, "BOTTOMRIGHT",3,-2)
		Castbar.time:SetJustifyH"RIGHT"
		Castbar.Text:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 82,-2)
		Castbar.Text:SetPoint("TOPRIGHT", Power, "BOTTOMRIGHT",-30,-2)
		Castbar.safezone = Castbar:CreateTexture(nil, "ARTWORK")
		Castbar.safezone:SetTexture(tex)
		Castbar.safezone:SetVertexColor(0.89, 0.31, 0.31, 0.6)
		Castbar.SafeZone = Castbar.safezone
		
		-- new 5.0.4 classes "combo points" (holy power, chi, shadow orbs)
		-- warlock bars are managed through my script due to the immense complications to make my code compatible with oUF.
		local classIconCont = CreateFrame("Frame",nil,self)
		classIconCont:SetSize(10,10)
		classIconCont:SetPoint('LEFT', Health, 'LEFT', 3, 0)
		classIconCont:SetFrameLevel(6)
		
		if myClass == "MONK" or myClass == "PRIEST" or myClass == "PALADIN" then
		  local ClassIcons = {}
		  for index = 1, 5 do
			local Icon = CreateFrame("Frame", nil, classIconCont)
			Icon.UpdateTexture = dummy
			Icon:SetSize(10, 10)
			Icon:SetBackdrop(backdrop)
			Icon:SetBackdropBorderColor(0,0,0)
			ClassIcons[index] = Icon
			if index == 1 then
              ClassIcons[index]:SetPoint"CENTER"
			else  
			  ClassIcons[index]:SetPoint('LEFT', ClassIcons[index-1], 'RIGHT', 2, 0)
			end  
		  end
		  self.ClassIcons = ClassIcons
			
		  -- check monk chi glyph	
		  if myClass == "MONK" then
		  
		  end
		  
		  -- display shadow orbs only if shadow spec'd
		  if myClass == "PRIEST" then
			
		  end
		end
		
		-- eclipse bar
		if myClass == "DRUID" then			
			local eclipseBar = CreateFrame('Frame', nil, self)
			eclipseBar:SetPoint("BOTTOM", Health, "TOP", 0, 5)
			eclipseBar:SetSize(self:GetWidth()+2, 11)
			eclipseBar:SetFrameLevel(5)
			eclipseBar:SetFrameStrata"MEDIUM"
			eclipseBar:SetBackdrop(backdrop)
			eclipseBar:SetBackdropColor(.6,.6,.6,0)
			eclipseBar:SetBackdropBorderColor(0,0,0)
					
			local lunarBar = CreateFrame('StatusBar', nil, eclipseBar)
			lunarBar:SetPoint('LEFT', eclipseBar, 'LEFT', 1, 0)
			lunarBar:SetSize(eclipseBar:GetWidth()-2, eclipseBar:GetHeight()-2)
			lunarBar:SetStatusBarTexture(tex)
			lunarBar:SetStatusBarColor(.30, .52, .90)
			eclipseBar.LunarBar = lunarBar

			local solarBar = CreateFrame('StatusBar', nil, eclipseBar)
			solarBar:SetPoint('LEFT', lunarBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
			solarBar:SetSize(eclipseBar:GetWidth()-2, eclipseBar:GetHeight()-2)
			solarBar:SetStatusBarTexture(tex)
			solarBar:SetStatusBarColor(.80, .82,  .30)
			eclipseBar.SolarBar = solarBar
			
			self.EclipseBar = eclipseBar
		end
		
		if P.buffs then
			local Buffs = CreateFrame("Frame", nil, self)
			Buffs:SetWidth(250)
			Buffs:SetHeight(20)
			Buffs:SetPoint("RIGHT", self, "LEFT",-3, 0)
			Buffs.initialAnchor = "RIGHT"
			Buffs["growth-x"] = "LEFT"
			Buffs["growth-y"] = "DOWN"
			Buffs.size = 26
			Buffs.num = 6 
			Buffs.spacing = 3
			Buffs.onlyShowPlayer = true
			Buffs.PostCreateIcon = lib.PostCreateAura
			Buffs.PostUpdateIcon = lib.PostUpdateAura
			self.Buffs = Buffs
		end	
		
		if P.debuffs then
			local Debuffs = CreateFrame("Frame", nil, self)
			Debuffs:SetWidth(250)
			Debuffs:SetHeight(20)
			Debuffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, 20)
			Debuffs.initialAnchor = "RIGHT"
			Debuffs["growth-x"] = "RIGHT"
			Debuffs["growth-y"] = "UP"
			Debuffs.size = 22
			Debuffs.num = 25
			Debuffs.spacing = 3
			Debuffs.PostCreateIcon = lib.PostCreateAura
			Debuffs.PostUpdateIcon = lib.PostUpdateAura
			self.Debuffs = Debuffs
		end
		
		local ricon = panelhp:CreateTexture(nil, "OVERLAY")
		ricon:SetSize(22,22)
		ricon:SetPoint("CENTER", panelhp, "TOP", 0, 3)
		self.RaidIcon = ricon
		
		-- AltPowerBar, the one that appears for ryolith and other mundane things like DMF
		PlayerPowerBarAlt:SetParent(UIParent)
		PlayerPowerBarAlt:SetFrameStrata("MEDIUM")
		PlayerPowerBarAlt:SetFrameLevel(3)
		PlayerPowerBarAlt:SetClampedToScreen(false)
		PlayerPowerBarAlt:ClearAllPoints()
		PlayerPowerBarAlt.ClearAllPoints = function() end
		PlayerPowerBarAlt:SetPoint("TOP", UIParent, "TOP", 0, -170)
		PlayerPowerBarAlt.SetPoint = function() end
		
		-- Ghost Button Fix
		GhostFrame:SetParent(UIParent)
		GhostFrame:SetFrameStrata("MEDIUM")
		GhostFrame:SetFrameLevel(3)
		GhostFrame:SetClampedToScreen(false)
		GhostFrame:ClearAllPoints()
		GhostFrame.ClearAllPoints = function() end
		GhostFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -5, 0)
		GhostFrame.SetPoint = function() end		
	end
	
	-------------------------------------------------------------
	--      Target Layout
	-------------------------------------------------------------
	if unit == "target" then
		Health:SetPoint("TOPLEFT", self, "TOPLEFT")
		Health:SetPoint("TOPRIGHT", self, "TOPRIGHT")
		Health:SetHeight(16)
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("TOPRIGHT", Health, "TOPRIGHT")
		HealthBackground:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT")

		if L.portraits then
		  portrait:SetPoint("TOPLEFT", Health, "TOPLEFT")
		  portrait:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT",-1,1)
		  portrait:SetAlpha(.25)	
		end
		
		panelhp:SetPoint("RIGHT", Power, "RIGHT", -3, -6)
		panelhp:SetSize(75,13)
		panelhp:SetBackdrop(backdrop)
		panelhp:SetBackdropColor(.6,.6,.6)
		panelhp:SetBackdropBorderColor(0,0,0)
		
		HealthPoints:SetPoint("LEFT", panelhp, "LEFT", T.hpX, T.hpY)
		HPper:SetPoint("RIGHT", panelhp, "RIGHT", T.perX, T.perY)
		HPper:SetJustifyH"RIGHT"
		
		Power:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
		Power:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
		Power:SetHeight(8)
		PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		PowerBackground:SetPoint("TOPRIGHT", Power, "TOPRIGHT")
		PowerBackground:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT")
		
		Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2.5, 2.5)
		Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2.5)
		Name:SetJustifyH"RIGHT"

		Castbar:SetPoint("LEFT", self, "LEFT", -3, -4)
		Castbar:SetPoint("RIGHT", self, "RIGHT", 3, -4)
		Castbar:SetHeight(13)
		Castbar.time:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 0, -3)
		Castbar.Text:SetPoint("TOPRIGHT", Power, "BOTTOMRIGHT", -80, -3)
		Castbar.Text:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 25, -3)
		Castbar.Text:SetJustifyH"RIGHT"
		
		if T.buffs then
			local Buffs = CreateFrame("Frame", nil, self)
			Buffs:SetPoint("TOPLEFT", Health, "TOPRIGHT", 3, 1)
			Buffs:SetSize(180, 26)
			Buffs.initialAnchor = "LEFT"
			Buffs.size = 26
			Buffs.num = 6
			Buffs.spacing = 2
			Buffs.PostCreateIcon = lib.PostCreateAura
			Buffs.PostUpdateIcon = lib.PostUpdateAura
			self.Buffs = Buffs
		end
		
		if T.debuffs then
			local Debuffs = CreateFrame("Frame", nil, self)	
			Debuffs:SetFrameLevel(6)
			Debuffs:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 4, 0)
			Debuffs:SetSize(180, 20)
			Debuffs.initialAnchor = "LEFT"
			Debuffs["growth-y"] = "UP"
			Debuffs.size = 26
			Debuffs.num = 15
			Debuffs.spacing = 2
			Debuffs.onlyShowPlayer = true
			Debuffs.PostCreateIcon = lib.PostCreateAura
			Debuffs.PostUpdateIcon = lib.PostUpdateAura
			self.Debuffs = Debuffs
		end	
		
		-- rogue combo points (now with more druid love!) 
		if (myClass == "ROGUE" or myClass == "DRUID") and unit == "target" then
			local CPoints = {}
			CPoints.unit = PlayerFrame.unit
	
			local combobar = CreateFrame("Frame", nil, self)
			combobar:SetSize(58, 10)
			combobar:SetPoint("LEFT", ColdPlayer.Health, "LEFT", 2, 0)
			combobar:Hide()
			combobar:SetFrameLevel(6)
		
			if myClass == "DRUID" then
				combobar:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
				combobar:SetScript("OnEvent", function()
					local currentform = GetShapeshiftForm()
					if currentform == 3 then
						combobar:Show()
					else
						combobar:Hide()
					end
				end)
			else
				combobar:Show()
			end	
	
			for i = 1, 5 do
			CPoints[i] = CreateFrame("Frame", "coldCP"..i, combobar)
			CPoints[i]:SetSize(10, 10)
			CPoints[i]:SetBackdrop(backdrop)
			CPoints[i]:SetBackdropBorderColor(0,0,0)
			
				if i == 1 then
					CPoints[i]:SetPoint("LEFT", combobar)
					CPoints[i]:SetBackdropColor(1, 0, 0)
				else
					CPoints[i]:SetPoint("LEFT", CPoints[i-1], "RIGHT", 2, 0)
				end
			end
			CPoints[2]:SetBackdropColor(1, .5, 0)
			CPoints[3]:SetBackdropColor(1, 1, 0)
			CPoints[4]:SetBackdropColor(.5, 1, 0)
			CPoints[5]:SetBackdropColor(0, 1, 0)
		
			self.CPoints = CPoints
		end
		
		local ricon = panelhp:CreateTexture(nil, "OVERLAY")
		ricon:SetSize(22,22)
		ricon:SetPoint("CENTER", panelhp, "TOP", 0, 3)
		self.RaidIcon = ricon
	end
	
	-------------------------------------------------------------
	--      Pet, ToT, Focus layout
	-------------------------------------------------------------
	if unit == "focus" or unit == "pet" or unit == "targettarget" then
		if cfg.focus.extended and unit == "focus" then
		  self:SetSize(130, 30)
		
		  panelhp:SetSize(55, 13)
		  panelhp:SetPoint("RIGHT", Health, "RIGHT", 4, 5)
		  panelhp:SetBackdrop(backdrop)
		  panelhp:SetBackdropColor(.6,.6,.6)
		  panelhp:SetBackdropBorderColor(0,0,0)
		  
		  if L.portraits then
		    portrait:SetPoint("TOPLEFT", Health, "TOPLEFT", 0, -1)
		    portrait:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 1)
		    portrait:SetAlpha(.25)
		  end
		  
		  Health:SetPoint("TOPLEFT", self, "TOPLEFT")
		  Health:SetPoint("TOPRIGHT", self, "TOPRIGHT")
		  Health:SetHeight(16)
		  HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		  HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		  HealthBackground:SetHeight(Health:GetHeight())
		  HealthPoints:SetPoint("TOPRIGHT", panelhp, "TOPRIGHT", 0, 2)
		  HealthPoints:SetJustifyH"RIGHT"
		  HPper:SetPoint("LEFT", panelhp, "LEFT", 0, 1)
		 		
		  Power:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
		  Power:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
		  Power:SetHeight(8)
		  PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		  PowerBackground:SetPoint("RIGHT", Power, "RIGHT")
		  PowerBackground:SetHeight(Power:GetHeight())
		 
		  Castbar:SetPoint("LEFT", self, "LEFT", -4, -4)
		  Castbar:SetPoint("RIGHT", self, "RIGHT", 4, -4)
		  Castbar:SetHeight(13)
		  Castbar.time:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 0, -4)
		  Castbar.Text:SetPoint("TOPRIGHT", Power, "BOTTOMRIGHT", -2, -4)
		  Castbar.Text:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 30, -4)
		  Castbar.Text:SetJustifyH"RIGHT"
		
		  Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 3, 2)
		  Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -55, 2)
		
		else
		Health:SetPoint("TOPLEFT", self, "TOPLEFT")
		Health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		HealthBackground:SetAlpha(1)
		HealthBackground:SetPoint("TOPRIGHT", self, "TOPRIGHT")
		HealthBackground:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
		
		  if unit == "pet" then
			Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2, 2)
		    Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2)
		    Name:SetJustifyH"RIGHT"
		  elseif unit == "targettarget" then
			Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2, 2)
			Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 2)
		  else
		  	Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2, 2)
		    Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2)
		    Name:SetJustifyH"CENTER"
		  end
		end
	end
	
	-------------------------------------------------------------
	--      Party frames layout
	-------------------------------------------------------------
	if unit == "party" then
		Health:SetSize(150, 16)
		Health:SetPoint("TOP", self, "TOP")
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		HealthBackground:SetAlpha(1)
		HealthBackground:SetHeight(Health:GetHeight())
		
		if L.portraits then
		    portrait:SetPoint("TOPLEFT", Health, "TOPLEFT", 0, .5)
		    portrait:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 1)
		    portrait:SetAlpha(.25)
		end
		
		panelhp:SetPoint("LEFT", Power, "LEFT", 2, -6)
		panelhp:SetSize(34,13)
		panelhp:SetBackdrop(backdrop)
		panelhp:SetBackdropColor(.6,.6,.6)
		panelhp:SetBackdropBorderColor(0,0,0)
		
		HealthPoints:SetPoint("CENTER", panelhp, "CENTER", 1.5, 1.5)
		
		Power:SetSize(150, 6)
		Power:SetPoint("TOP", Health, "BOTTOM", 0, -4)
		PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		PowerBackground:SetPoint("TOPRIGHT", Power, "TOPRIGHT")
		PowerBackground:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT")
		
		Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2, 2)
		
		if Pa.debuffs then
			local Debuffs = CreateFrame("Frame", nil, self)
			Debuffs:SetWidth(250)
			Debuffs:SetHeight(20)
			Debuffs:SetPoint("LEFT", self, "RIGHT", 5, -1)
			Debuffs.initialAnchor = "LEFT"
			Debuffs.size = 25
			Debuffs.num = 6
			Debuffs.spacing = 3
			Debuffs.PostCreateIcon = lib.PostCreateAura
			Debuffs.PostUpdateIcon = lib.PostUpdateAura
			self.Debuffs = Debuffs
		end
		
		Health.PostUpdate = lib.PostUpdateHealthPartyRaid
		
		local ricon = Health:CreateTexture(nil, "OVERLAY")
		ricon:SetSize(18,18)
		ricon:SetPoint("CENTER", panelhp, "TOP")
		self.RaidIcon = ricon
		
		local role = lib.SetFontString(Health, font, smalls, "OUTLINE, MONOCHROME")
		role:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2)
		role:SetJustifyH"RIGHT"
		self:Tag(role, '[ColdLFD]')
		
		local range = {
			insideAlpha = 1,
			outsideAlpha = .5,
		}
		self.Range = range
	end
	
	-------------------------------------------------------------
	--      Raid frames layout
	-------------------------------------------------------------
	if unit == "raid" then
		self:SetSize(95,14)
			
		Health:SetSize(95, 14)
		Health:SetPoint("TOP", self, "TOP")
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		HealthBackground:SetAlpha(1)
		HealthBackground:SetHeight(Health:GetHeight())
	
		Name:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 2, 2)
		Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2)
		self:Tag(Name, '[name]')

		local ricon = Health:CreateTexture(nil, "OVERLAY")
		ricon:SetTexture([[Interface\AddOns\oUF_Coldkil\textures\raidicons.blp]])
		ricon:SetSize(13,13)
		ricon:SetPoint("CENTER", self, "RIGHT", 3, 0)
		self.RaidIcon = ricon	
			
		local role = lib.SetFontString(Health, font, smalls, "OUTLINE, MONOCHROME")
		role:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -2, 2)
		role:SetJustifyH"RIGHT"
		self:Tag(role, '[ColdLFD]')

		Health.PostUpdate = lib.PostUpdateHealthPartyRaid
			
		local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
		}
		self.Range = range	
	end
	
	----------------------------------------------------------------
	--       Boss frames layout
	----------------------------------------------------------------
	if (unit and unit:find("boss%d")) then
		self:SetSize(180,25)
		
		Health:SetSize(180, 16)
		Health:SetPoint("TOP", self, "TOP")
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		HealthBackground:SetAlpha(1)
		HealthBackground:SetHeight(Health:GetHeight())
		
		panelhp:SetPoint("RIGHT", Power, "RIGHT", -3, -6)
		panelhp:SetSize(30,13)
		panelhp:SetBackdrop(backdrop)
		panelhp:SetBackdropColor(.6,.6,.6)
		panelhp:SetBackdropBorderColor(0,0,0)
		
		HPper:SetFont(font,smalls,"OUTLINE, MONOCHROME")
		HPper:SetPoint("CENTER", panelhp, "CENTER", 0, 1)
		HPper:SetJustifyH"CENTER"
		
		Name:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -1, 3)
		Name:SetJustifyH"RIGHT"
		
		Power:SetSize(180, 6)
		Power:SetPoint("TOP", Health, "BOTTOM", 0, -5)
		PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		PowerBackground:SetPoint("RIGHT", Power, "RIGHT")
		PowerBackground:SetHeight(Power:GetHeight())
		
		Castbar:SetPoint("LEFT", self, "LEFT", -3, -4)
		Castbar:SetPoint("RIGHT", self, "RIGHT", 3, -4)
		Castbar:SetHeight(13)
		Castbar.time:SetPoint("TOPRIGHT", Power, "TOPRIGHT", -33, -6)
		Castbar.time:SetJustifyH"RIGHT"
		Castbar.Text:SetPoint("TOPLEFT", Power, "TOPLEFT", 0, -6)
		Castbar.Text:SetPoint("TOPRIGHT", Castbar, "TOPRIGHT", -35, -6)
	end
	----------------------------------------------------------------
	--       Arena frames layout
	----------------------------------------------------------------
	if (unit and unit:find("arena%d")) and (not unit:find("arena%dtarget")) and (not unit:find("arena%dpet")) then
		self:SetSize(180,25)
		
		Health:SetSize(180, 22)
		Health:SetPoint("TOP", self, "TOP")
		HealthBackground:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
		HealthBackground:SetPoint("RIGHT", Health, "RIGHT")
		HealthBackground:SetAlpha(1)
		HealthBackground:SetHeight(Health:GetHeight())
		HPper:SetFont(font,smalls,"OUTLINE, MONOCHROME")
		HPper:SetPoint("RIGHT", Health, "RIGHT", -2, 0)
		HPper:SetJustifyH"RIGHT"
		-- class colored healthbars and specific updates
		Health.PostUpdate = lib.PostUpdateHealthArena
		
		Name:SetPoint("LEFT", Health, "LEFT", 2, 0)
		
		Power:SetSize(180, 3)
		Power:SetPoint("BOTTOM", Health, "TOP", 0, 1)
		PowerBackground:SetPoint("LEFT", Power:GetStatusBarTexture(), "RIGHT")
		PowerBackground:SetPoint("RIGHT", Power, "RIGHT")
		PowerBackground:SetAlpha(.2)
		PowerBackground:SetHeight(Power:GetHeight())
		Power.colorPower = true
		
		Castbar:SetPoint("TOP", Health, "BOTTOM", 0, -3)
		Castbar:SetSize(180, 13)
		Castbar.time:SetPoint("RIGHT", Castbar, "RIGHT", -2, 0)
		Castbar.time:SetJustifyH"RIGHT"
		Castbar.Text:SetPoint("LEFT", Castbar, "LEFT", 2, 0)
		Castbar.Text:SetPoint("RIGHT", Castbar, "RIGHT", -30, 0)
		
		-- adding trinket icon on the left
		self.Trinket = CreateFrame("Frame", nil, self)
		self.Trinket:SetSize(24, 24)
		self.Trinket:SetPoint("RIGHT", Health, "LEFT", -4, 0)
		self.Trinket.trinketUseAnnounce = true
		self.Trinket.trinketUpAnnounce = true
	    -- adding spec icon on the right
		Spec = CreateFrame("Frame", nil, self)
		Spec:SetSize(24, 24)
		Spec:SetPoint("LEFT", Health, "RIGHT", 4, 0)
		Spec:SetBackdrop(backdrop)
		Spec:SetBackdropColor(.2,.2,.2,.6)
		Spec:SetBackdropBorderColor(0,0,0)
		Spec.texture = Spec:CreateTexture(nil, "BACKGROUND")
		Spec.texture:SetPoint("TOPLEFT", Spec, "TOPLEFT")
		Spec.texture:SetPoint("BOTTOMRIGHT", Spec, "BOTTOMRIGHT")
		self.Spec = Spec -- adding handle for future usage
	end
end

oUF:RegisterStyle("Coldkil", Shared)
----------------------------------------------------------------------------------
-- spawning various units
----------------------------------------------------------------------------------

	local player = oUF:Spawn('player', "ColdPlayer")
	local pet = oUF:Spawn('pet', "ColdPet")
	local target = oUF:Spawn('target', "ColdTarget")
	local tot = oUF:Spawn('targettarget', "ColdToT") 
	local focus = oUF:Spawn('focus', "ColdFocus")
	
	local arena = {}
	for i = 1, 5 do
		arena[i] = oUF:Spawn("arena"..i, "ColdArena"..i)
		if i == 1 then
			arena[i]:SetPoint("LEFT", UIParent, "CENTER", 300, 100)
		else
			arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -30)
		end
		arena[i].Spec:RegisterEvent("PLAYER_LOGIN")
		arena[i].Spec:RegisterEvent("PLAYER_ENTERING_WORLD")
		arena[i].Spec:RegisterEvent("ARENA_OPPONENT_UPDATE")
		arena[i].Spec:SetScript("OnEvent", function(self, event)
		  local s = GetArenaOpponentSpec(i)
		  if s and s > 0 then
			local _, _, _, icon, _, _, _ = GetSpecializationInfoByID(s)
		  end
		  if icon then
			arena[i].Spec.texture = icon
		  end
		end)
	end
	
	for i = 1,MAX_BOSS_FRAMES do
		local c_boss = _G["Boss"..i.."TargetFrame"]
		c_boss:UnregisterAllEvents()
		c_boss.Show = function() return end
		c_boss:Hide()
		_G["Boss"..i.."TargetFrame".."HealthBar"]:UnregisterAllEvents()
		_G["Boss"..i.."TargetFrame".."ManaBar"]:UnregisterAllEvents()
	end

	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = oUF:Spawn("boss"..i, "ColdBoss"..i)
		if i == 1 then
			boss[i]:SetPoint("LEFT", UIParent, "CENTER", 400, 150)
		else
			boss[i]:SetPoint('TOP', boss[i-1], 'BOTTOM', 0, -25)             
		end
	end
	
	local party = oUF:SpawnHeader("ColdParty", nil, "custom [@raid6,exists] hide;show",
		--"showSolo", true,
		'showParty', true,
		'yOffset', -20,
		'columnAnchorPoint', 'LEFT',
		'columnSpacing', 15,
		'oUF-initialConfigFunction', [[
			self:SetWidth(150)
			self:SetHeight(20)
		]]
	)
	local partyanchor = CreateFrame("Frame", "ColdPartyAnchor", UIParent)
	partyanchor:SetSize(160, 200)
	party:SetParent(partyanchor)
	party:SetPoint("TOPLEFT", partyanchor, "TOPLEFT", 2, -2)
	
  if R.showraid then
	local raid
	local raidanchor = CreateFrame("Frame", "ColdRaidAnchor", UIParent)
	raid = oUF:SpawnHeader("ColdRaid", nil, "custom [@raid6,exists] show;hide", 
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetWidth(95)
			self:SetHeight(14)
		]],
		"yOffset", -5,
		"showParty", true, 
		"showPlayer", true, 
		"showRaid", true, 
		"groupFilter", "1,2,3,4,5,6,7,8", 
		"groupingOrder", "1,2,3,4,5,6,7,8", 
		"groupBy", "GROUP"
	  )
	raidanchor:SetSize(100,600)
	raidanchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 172)

	raid:SetParent(raidanchor)
	raid:SetPoint("BOTTOMLEFT", raidanchor, "BOTTOMLEFT", 2, 2)
	lib.dragalize(raidanchor)
  end
  
  -- setting up draggable frames 
  lib.dragalize(player)
  lib.dragalize(pet)
  lib.dragalize(target)
  lib.dragalize(tot)
  lib.dragalize(focus)
  lib.dragalize(partyanchor)
  
  player:SetPoint("BOTTOM", UIParent, "BOTTOM", -180, 240)
  pet:SetPoint('TOPLEFT', player, 'TOPRIGHT', 7, 0)
  target:SetPoint("BOTTOM", UIParent, "BOTTOM", 180, 240)
  tot:SetPoint("TOPRIGHT", target, "TOPLEFT", -7, 0)
  if cfg.focus.extended then
	focus:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 200)
  else
	focus:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 232)
  end
  partyanchor:SetPoint("TOPLEFT", UIParent, "LEFT", 10, 10)

  ------------------- DEBUG

SlashCmdList["SHOW_ARENA"] = function()
local str = "ColdArena"
  for i = 1, 5 do
	_G[str..i]:Show(); _G[str..i].Hide = function() end; _G[str..i].unit = "player"
  end
end
SLASH_SHOW_ARENA1 = "/tarena"

SlashCmdList["SHOW_BOSS"] = function()
  local str = "ColdBoss"
  for i = 1, 4 do
	_G[str..i]:Show(); _G[str..i].Hide = function() end; _G[str..i].unit = "player"
  end
end
SLASH_SHOW_BOSS1 = "/tboss"
