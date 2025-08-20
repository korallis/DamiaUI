--get the addon namespace
local addon, ns = ...

--get the config values
local cfg = ns.cfg

-- frame holder for the functions
local lib = CreateFrame("Frame")

local font = cfg.font
local fs = cfg.fontsize

--------------------------------------------
-- colors metatables
--------------------------------------------
colors = setmetatable({
	tapped = {0.55, 0.57, 0.61},
	disconnected = {0.84, 0.75, 0.65},
	power = setmetatable({
		["MANA"] = {0.31, 0.45, 0.63},
		["RAGE"] = {0.69, 0.31, 0.31},
		["FOCUS"] = {1, .5, 0},
		["ENERGY"] = {0.70, 0.73, 0.15},
		["RUNES"] = {0.55, 0.57, 0.61},
		["RUNIC_POWER"] = {0, 0.82, 1},
		["AMMOSLOT"] = {0.8, 0.6, 0},
		["FUEL"] = {0, 0.55, 0.5},
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {__index = oUF.colors.power}),
	happiness = setmetatable({
		[1] = {1, 0, 0}, 
		[2] = {1, 1, 0}, 
		[3] = {0, 1, 0},
	}, {__index = oUF.colors.happiness}),
	runes = setmetatable({
			[1] = {.69,.31,.31},
			[2] = {.33,.59,.33},
			[3] = {.31,.45,.63},
			[4] = {.7, .7, .7},
	}, {__index = oUF.colors.runes}),
	reaction = setmetatable({
		[1] = { 222/255, 95/255,  95/255 }, -- Hated
		[2] = { 222/255, 95/255,  95/255 }, -- Hostile
		[3] = { 222/255, 95/255,  95/255 }, -- Unfriendly
		[4] = { 218/255, 197/255, 92/255 }, -- Neutral
		[5] = { 75/255,  175/255, 76/255 }, -- Friendly
		[6] = { 75/255,  175/255, 76/255 }, -- Honored
		[7] = { 75/255,  175/255, 76/255 }, -- Revered
		[8] = { 75/255,  175/255, 76/255 }, -- Exalted	
	}, {__index = oUF.colors.reaction}),
	class = setmetatable({
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
	}, {__index = oUF.colors.class}),
},{__index = oUF.colors})


-----------------------------------------------------------
-- additional oUF text tags
-----------------------------------------------------------
oUF.Tags.Methods['coldhp'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
	return lib.siValue(UnitHealth(unit))
end
oUF.Tags.Events['coldhp'] = "UNIT_HEALTH UNIT_MAXHEALTH"


oUF.Tags.Methods['nameshort'] = function(unit)
	local name = UnitName(unit)
	return lib.utf8sub(name, 4, false)
end
oUF.Tags.Events['nameshort'] = "UNIT_NAME_UPDATE"


oUF.Tags.Methods['ColdLFD'] = function(u)
  local role = UnitGroupRolesAssigned(u)
  if role == "HEALER" then
	return "|cff8AFF30 H|r"
  elseif role == "TANK" then
	return "|cffFFF130 T|r"
  elseif role == "DAMAGER" then
	return "|cffFF6161 D|r"
  end
end
oUF.Tags.Events['ColdLFD'] = 'PLAYER_ROLES_ASSIGNED PARTY_MEMBERS_CHANGED'


-------------------------------------------------------------
--      Ugly stuff you don't want to touch :)
-------------------------------------------------------------
lib.ColorGradient = function(perc, ...)
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...) 

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

lib.menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", string.upper)

	if(cunit == 'Vehicle') then
		cunit = 'Pet'
	end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

lib.getClass = function(unit) 
	local _, playerClass = UnitClass(unit)
	return playerClass
end	

local function round(num, idp)
  if idp and idp > 0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

lib.siValue = function(val)
	if(val >= 1e9) then
		return ('%.1f'):format(val / 1e9):gsub('%.', 'b')
	elseif(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

lib.utf8sub = function(string, i, dots)
	if not string then return end
	local bytes = string:len()
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and '...' or '')
		else
			return string
		end
	end
end

lib.PostUpdateHealth = function(health, unit, min, max)
	local self = health:GetParent()
	local d
	if min and max then d =(round(min/max, 2)*100) else d = 1 end
	local r, g, b
	if min and max then
		r, g, b = lib.ColorGradient(min/max, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	else
		r = 1
		g = 1
		b = 1
	end	
	local theClass = lib.getClass(unit)
	local color = colors.class[theClass]
	local less, more = lib.siValue(min), lib.siValue(max)
	
	-- health background colors and panel border colors
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		health:SetStatusBarColor(.9, .9, .9)
		health.bg:SetVertexColor(.2, .2, .2)
	else
		health:SetStatusBarColor(.25, .25, .25)
		health.bg:SetVertexColor(r, g, b)
	end

	
	-- hp text format (% displayed if not max)
	if min ~= max then
		if unit == "player" then
			health.value:SetText(less)
		elseif (unit and unit:find("boss%d")) then
			health.valueper:SetText(d.."%")
		else
			health.valueper:SetText(d.."%")
		end	
	else
		if unit == "player" then
			health.value:SetText(more)
			health.valueper:SetText(d.."%")
		elseif (unit and unit:find("boss%d")) then
			health.valueper:SetText(lib.siValue(max))
		else
			health.value:SetText(more)
			health.valueper:SetText(d.."%")
		end	
	end	

	-- hp text color
	if(unit) then
		health.value:SetTextColor(r, g, b)
		if unit == "target" and color then
			health.valueper:SetTextColor(color[1],color[2],color[3])
		else
			health.valueper:SetTextColor(r, g, b)
		end	
	end
end

lib.PostUpdateHealthArena = function(health, unit, min, max)
	local self = health:GetParent()
	local d
	if min and max then d = math.floor(min*100/max) else d = 1 end
	local r, g, b
	if min and max then
		r, g, b = lib.ColorGradient(min/max, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	else
		r = 1
		g = 1
		b = 1
	end	
	local theClass = lib.getClass(unit)
	local color = colors.class[theClass]
	
    -- health background colors and panel border colors
	if color then
		health:SetStatusBarColor(color[1], color[2], color[3])
	end	
	health.bg:SetVertexColor(.2, .2, .2)
	
	if UnitIsDead(unit) or UnitIsGhost(unit) then
		health.value:SetText("dead")
	  else	
		if min ~= max then
			health.value:SetText(d.."%")
		else
			health.value:SetText(lib.siValue(max))
		end
	end

	health.value:SetTextColor(r, g, b)
end

lib.PostUpdateHealthPartyRaid = function(health, unit, min, max)
	local self = health:GetParent()
	local d
	if min and max then d = math.floor(min*100/max) else d = 1 end
	local r, g, b
	if min and max then
		r, g, b = lib.ColorGradient(min/max, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	else
		r = 1
		g = 1
		b = 1
	end	
	local theClass = lib.getClass(unit)
	local color = colors.class[theClass]
	
	if color then
		self.Name:SetTextColor(color[1], color[2], color[3])
	else
		self.Name:SetTextColor(1,1,1)
	end	
	
    -- health background colors and panel border colors
	health:SetStatusBarColor(.25, .25, .25)
	health.bg:SetVertexColor(r, g, b)
	
	if cfg.layout.healer then
	  if UnitIsDead(unit) or UnitIsGhost(unit) then
		health.value:SetText("dead")
	  else	
		if min ~= max then
			health.value:Show()
			health.value:SetText(d.."%")
		else
			health.value:Hide()
		end
	  end
	end
	health.value:SetTextColor(r, g, b)
end

lib.PostUpdatePower = function(power, unit, min, max)
	if not power then return end
	local _, pType = UnitPowerType(unit)
	local theClass = lib.getClass(unit)
	local color = colors.class[theClass]
	local colort = colors.power[pType]
	-- checks needed due to new 5.0 WoW engine
	if min == 0 then min = 1 end
	if max == 0 or max < min then max = min end
	-- end of checks
	local d = (round(min/max, 2)*100)
	local less, more = lib.siValue(min), lib.siValue(max)
	
	--power bar colors
	if unit == "player" or unit == "target" or (unit == "focus" and cfg.focus.extended) then
		if color and colort then
			power:SetStatusBarColor(color[1], color[2], color[3])
			power.bg:SetVertexColor(.2,.2,.2)
		elseif colort then
			power:SetStatusBarColor(.7, .3, .3)
			power.bg:SetVertexColor(.2,.2,.2)
		else
			power:SetStatusBarColor(.7, .3, .3)
			power.bg:SetVertexColor(.2,.2,.2)
		end
	else
		if colort then
			power:SetStatusBarColor(colort[1], colort[2], colort[3])
			power.bg:SetVertexColor(.2,.2,.2)
		else
			power:SetStatusBarColor(.7, .3, .3)
			power.bg:SetVertexColor(.2,.2,.2)
		end
	end

	power.value:SetText(less)
end

backdrop = {
	bgFile = cfg.tex,
	edgeFile = cfg.texblank,
	edgeSize = 1,
}

backdropfull = {
	bgFile = cfg.tex,
	edgeFile = cfg.tex,
	edgeSize = 2,
}

lib.SetFontString = function(parent, fontName, fontHeight, fontStyle)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetJustifyH("LEFT")
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(0, 0)
	return fs
end

local bd = {
	bgFile = cfg.tex,
}

lib.panelize = function (frame)
    local p = CreateFrame("Frame", frame:GetName().." - panel", frame)
	p:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
	p:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
	p:SetFrameLevel(frame:GetFrameLevel()-1)
	p:SetBackdrop(backdrop)
	p:SetBackdropColor(.2,.2,.2)
	p:SetBackdropBorderColor(1,1,1)
end

lib.dragalize = function (frame)
	local fn = frame:GetName()
	frame:SetScript("OnDragStart", function(s) s:StartMoving() end)
    frame:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	
	local d = CreateFrame("Frame", fn, UIParent)
	d:SetBackdrop(backdrop)
	d:SetBackdropColor(0,1,0,.5)
	d:SetAllPoints(frame)
	d:SetFrameLevel(frame:GetFrameLevel()+5)
	d:SetFrameStrata"HIGH"
	d:SetAlpha(0)  -- should be always 0, put 1 if you need to display frame names for edit
	frame.draggable = d
	
	local name = lib.SetFontString(d, cfg.font, 10, "OUTLINE, MONOCHROME")
	name:SetText(fn)
	name:SetPoint("CENTER", d, "CENTER")
	name:SetJustifyH"CENTER"
end

local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", ceil(s / day))
	elseif s >= hour then
		return format("%dh", ceil(s / hour))
	elseif s >= minute then
		return format("%dm", ceil(s / minute))
	elseif s >= minute / 12 then
		return floor(s)
	end
	return format("%.1f", s)
end

local CreateAuraTimer = function(self, elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				local time = FormatTime(self.timeLeft)
				self.remaining:SetText(time)
				if self.timeLeft <= 5 then
					self.remaining:SetTextColor(0.99, 0.31, 0.31)
				else
					self.remaining:SetTextColor(1, 1, 1)
				end
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

lib.PostCreateAura = function(element, button)
	button:SetBackdrop(backdrop)
	button:SetBackdropBorderColor(0,0,0)
	button.remaining = lib.SetFontString(button, font, fs, "OUTLINE, MONOCHROME")
	button.remaining:SetPoint("CENTER", 1, 0)
	
	button.cd.noOCC = true		 	-- hide OmniCC CDs
	button.cd.noCooldownCount = true	-- hide CDC CDs
	
	button.cd:SetReverse()
	button.icon:SetPoint("TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	
	button.count:SetPoint("BOTTOMRIGHT", 2, 0)
	button.count:SetJustifyH("RIGHT")
	button.count:SetFont(font, fs, "OUTLINE, MONOCHROME")
	button.count:SetTextColor(0, .8, 0)
	
	button.overlayFrame = CreateFrame("frame", nil, button, nil)
	button.cd:SetFrameLevel(button:GetFrameLevel() + 1)
	button.cd:ClearAllPoints()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
	button.cd:SetAlpha(0)
	button.overlayFrame:SetFrameLevel(button.cd:GetFrameLevel() + 1)	   
	button.overlay:SetParent(button.overlayFrame)
	button.count:SetParent(button.overlayFrame)
	button.remaining:SetParent(button.overlayFrame)
end

lib.PostUpdateAura = function(icons, unit, icon, index, offset, filter, isDebuff, duration, timeLeft)
	local _, _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)

	if(icon.debuff) then
		if(not UnitIsFriend("player", unit) and icon.owner ~= "player" and icon.owner ~= "vehicle") then
			icon:SetBackdropBorderColor(.7, .7, .7)
			icon.icon:SetDesaturated(true)
		else
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			icon:SetBackdropBorderColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			icon.icon:SetDesaturated(false)
		end
	end
	
	if duration and duration > 0 then
		icon.remaining:Show()
	else
		icon.remaining:Hide()
	end
 
	icon.duration = duration
	icon.timeLeft = expirationTime
	icon.first = true
	icon:SetScript("OnUpdate", CreateAuraTimer)
end

local CheckInterrupt = function(self, unit)
	if unit == "vehicle" then unit = "player" end

	if self.interrupt and UnitCanAttack("player", unit) then
		self:SetStatusBarColor(1, 0, 0)	
	else
		self:SetStatusBarColor(.9, .9, 0)	
	end
end

lib.CheckCast = function(self, unit, name, rank, castid)
	CheckInterrupt(self, unit)
end

lib.CheckChannel = function(self, unit, name, rank)
	CheckInterrupt(self, unit)
end

-- handover to use the functions in other files
ns.lib = lib