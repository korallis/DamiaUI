-- raid frames helepr/timers for healer layout. Hope i didn't miss anything.

--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-- get the library
local lib = ns.lib

-- get the library
local lib = ns.lib

-- locales
local FV = function(val)
    if (val >= 1e6) then
        return ("%.1fm"):format(val / 1e6)
    elseif (val >= 1e3) then
        return ("%.1fk"):format(val / 1e3)
    else
        return ("%d"):format(val)
    end
end

-----------------------------------------------------------------------------------
--          PRIEST
-----------------------------------------------------------------------------------

-- PW:Shield -- white timer
oUF.Tags.Methods['ColdPWS'] = function(u)
local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(17))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cffFAFAD2"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdPWS'] = "UNIT_AURA"

-- Weakened Soul -- red symbol
oUF.Tags.Methods['ColdWS'] = function(u) if UnitDebuff(u, GetSpellInfo(6788)) then return "|cffFF0000#|r" end end
oUF.Tags.Events['ColdWS'] = "UNIT_AURA"

-- Renew -- green timer
oUF.Tags.Methods['ColdRNW'] = function(u) 
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(139))
    if(fromwho == "player") then
        local spellTimer = expirationTime - GetTime()
		if spellTimer > 0 then
			return "|cff32CD32"..FV(spellTimer).."|r"
		end
    end
end
oUF.Tags.Events['ColdRNW'] = "UNIT_AURA"

-- Prayer of Mending -- gold turning to red as stacks drop
local pomStack = {1,2,3,4,5}
oUF.Tags.Methods['ColdPOM'] = function(u)
    local name, _,_, c, _,_,_, fromwho = UnitAura(u, GetSpellInfo(41635)) 
    if fromwho == "player" then
        if c > 3 and c ~= 0 then
            return "|cffFFD700"..pomStack[c].."|r"
        elseif c > 1 and c ~= 0 then
            return "|cffFF7F50"..pomStack[c].."|r"
        elseif c > 0 and c ~= 0 then
            return "|cffFF0000"..pomStack[c].."|r"
		else return "|cffFF00000|r"	
        end
	end	
end
oUF.Tags.Events['ColdPOM'] = "UNIT_AURA"

-----------------------------------------------------------------------------------
--          DRUID
-----------------------------------------------------------------------------------
-- Lifebloom -- timer red at 1 stack, yellow at 2 stacks, green at three stacks
oUF.Tags.Methods['ColdLB'] = function(u)
    local name, _,_, c,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(33763))
    if(fromwho == "player") then
		local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
		if c > 2 then
			return "|cffFF9900"..TimeLeft.."|r"
		elseif c > 1 then
            return "|cffFF9900"..TimeLeft.."|r"
        else
            return "|cffFF0000"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdLB'] = "UNIT_AURA"

-- Rejuvenation -- green timer
oUF.Tags.Methods['ColdRej'] = function(u)
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(774))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff57FF9A"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdRej'] = "UNIT_AURA"

-- Regrowth -- azure timer
oUF.Tags.Methods['ColdRG'] = function(u)
	local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(8936))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff33FF33"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdRG'] = "UNIT_AURA"

-- Swiftmend -- purple symbol
oUF.Tags.Methods['ColdSM'] = function(u) if (UnitAura(u, GetSpellInfo(8936)) or UnitAura(u, GetSpellInfo(774))) then 
	return "|cffFF00BB#|r" 
	end 
end 
oUF.Tags.Events['ColdSM'] = "UNIT_AURA"
-----------------------------------------------------------------------------------
--          SHAMAN
-----------------------------------------------------------------------------------
-- Earth Shield -- brown stack counter, turns red  at less than 3 stacks
local esStack = {1,2,3,4,5,6,7,8,9}
oUF.Tags.Methods['ColdES'] = function(u)
    local name, _,_, c, _,_,_, fromwho = UnitAura(u, GetSpellInfo(974)) 
    if fromwho == "player" then
	local esStack  = esStack [c]
		if esStack  > 3 then
            return "|cffCD853F"..esStack.."|r"
        else
            return "|cffFF0000"..esStack.."|r"
        end
	end	
end
oUF.Tags.Events['ColdES'] = 'UNIT_AURA'

-- Riptide -- blue timer
oUF.Tags.Methods['ColdRip'] = function(u) --¼¤Á÷
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(61295))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff00BFFF"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdRip'] = 'UNIT_AURA'


-----------------------------------------------------------------------------------
--          PALADIN
-----------------------------------------------------------------------------------
-- Beacon of Light -- pink symbol
oUF.Tags.Methods['ColdBea'] = function(u) if UnitAura(u, GetSpellInfo(53563)) then return "|cffFFB90F#|r" end end
oUF.Tags.Events['ColdBea'] = "UNIT_AURA"

-- Sacred Shield -- light yellow timer
oUF.Tags.Methods['ColdSS'] = function(u)
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(20925))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cffFF00BB"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdSS'] = 'UNIT_AURA'

-- Eternal Flame -- light orange timer
oUF.Tags.Methods['ColdEF'] = function(u)
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(114163))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff00FFDD"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdEF'] = 'UNIT_AURA'

-- Forbearance -- red symbol
oUF.Tags.Methods['ColdFor'] = function(u) if UnitDebuff(u, GetSpellInfo(25771)) then return "|cffFF9900#|r" end end
oUF.Tags.Events['ColdFor'] = "UNIT_AURA"

-- Hand of Sacrifice

-----------------------------------------------------------------------------------
--          MONK
-----------------------------------------------------------------------------------

-- Zen Sphere -- dark green timer
oUF.Tags.Methods['ColdZS'] = function(u)
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(124081))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff20B2AA"..TimeLeft.."|r"
        end
    end
end
oUF.Tags.Events['ColdZS'] = 'UNIT_AURA'

-- Soothing Mist -- white symbol
oUF.Tags.Methods['ColdSoo'] = function(u) if UnitAura(u, GetSpellInfo(115175)) then return "|cffF5F5F5#|r" end end
oUF.Tags.Events['ColdSoo'] = "UNIT_AURA"

-- Renewing Mist -- light green timer
oUF.Tags.Methods['ColdRM'] = function(u)
    local name, _,_,_,_,_, expirationTime, fromwho = UnitAura(u, GetSpellInfo(115151))
    if(fromwho == "player") then
        local spellTimer = (expirationTime-GetTime())
		local TimeLeft = FV(spellTimer)
        if spellTimer > 0 then
            return "|cff7FFFD4"..TimeLeft.."|r"
        end
    end
end 
oUF.Tags.Events['ColdRM'] = 'UNIT_AURA'



-----------------------------------------------------------------------------------
--          SHENANINGANS - DON'T TOUCH!!
-----------------------------------------------------------------------------------
healTimers={
    ["DRUID"] = {
        ["TL"] = "[ColdRej]", 
        ["TR"] = "[ColdLB]",
        ["BL"] = "[ColdSM]", 
        ["BR"] = "[ColdRG]",
    },
    ["PRIEST"] = {
		["TL"] = "[ColdRNW]",
        ["TR"] = "[ColdPOM]",
        ["BL"] = "[ColdWS]",
        ["BR"] = "[ColdPWS]",
    },
    ["PALADIN"] = {
        ["TL"] = "[ColdFor]",
        ["TR"] = "[ColdEF]",
        ["BL"] = "[ColdBea]",
        ["BR"] = "[ColdSS]",
    },
    ["SHAMAN"] = {
        ["TL"] = "[ColdRip]",
        ["TR"] = "[ColdES]",
        ["BL"] = "",
        ["BR"] = "",
    },
	["MONK"] = {
		["TL"] = "[ColdZS]",
		["TR"] = "[ColdRM]",
        ["BR"] = "[ColdSoo]",
        ["BL"] = "",
    },
}

local _, class = UnitClass("player")
local f = cfg.font
local s = cfg.fontsize
local update = .25

local Enable = function(self)
    if(self.ColdHealTimers) then
		if not healTimers[class] then return end
	
        self.AuraStatusBL = self.Health:CreateFontString(nil, "OVERLAY")
        self.AuraStatusBL:ClearAllPoints()
        self.AuraStatusBL:SetPoint("BOTTOMLEFT", self.Health, 1, 1.5)
		self.AuraStatusBL:SetJustifyH("LEFT")
        self.AuraStatusBL:SetFont(f, s, "OUTLINE, MONOCHROME")
        self.AuraStatusBL.frequentUpdates = update
        self:Tag(self.AuraStatusBL, healTimers[class]["BL"])	

		self.AuraStatusTR = self.Health:CreateFontString(nil, "OVERLAY")
        self.AuraStatusTR:ClearAllPoints()
        self.AuraStatusTR:SetPoint("TOPRIGHT", self.Health, 1, .5)
		self.AuraStatusTR:SetJustifyH("RIGHT")
        self.AuraStatusTR:SetFont(f, s, "OUTLINE, MONOCHROME")
        self.AuraStatusTR.frequentUpdates = update
        self:Tag(self.AuraStatusTR, healTimers[class]["TR"])
		
		self.AuraStatusTL = self.Health:CreateFontString(nil, "OVERLAY")
        self.AuraStatusTL:ClearAllPoints()
        self.AuraStatusTL:SetPoint("TOPLEFT", self.Health, 1, .5)
		self.AuraStatusTL:SetJustifyH("LEFT")
        self.AuraStatusTL:SetFont(f, s, "OUTLINE, MONOCHROME")
        self.AuraStatusTL.frequentUpdates = update
        self:Tag(self.AuraStatusTL, healTimers[class]["TL"])
		
        self.AuraStatusBR = self.Health:CreateFontString(nil, "OVERLAY")
        self.AuraStatusBR:ClearAllPoints()
        self.AuraStatusBR:SetPoint("BOTTOMRIGHT", self.Health, 1, 1.5)
        self.AuraStatusBR:SetFont(f, s, "OUTLINE, MONOCHROME")
        self.AuraStatusBR.frequentUpdates = update
        self:Tag(self.AuraStatusBR, healTimers[class]["BR"])
    end
end

oUF:AddElement('ColdHealTimers', nil, Enable, nil)