--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-- get the library
local lib = ns.lib

if lib.getClass("player") ~= "WARLOCK" then return end

local MAX_POWER_PER_EMBER = 10
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS
local destro = SPEC_WARLOCK_DESTRUCTION
local affli = SPEC_WARLOCK_AFFLICTION
local demo = SPEC_WARLOCK_DEMONOLOGY

local shardc = {139/255, 51/255, 188/255}
local emberc = {189/255, 91/255, 58/255}
local furyc  = {119/255, 238/255, 28/255}


local shards = {}
local embers = {}
local demofury
local shardnum, embernum

-- container for the magic
local lockbar = CreateFrame("Frame", nil, ColdPlayer)

-- containers for the widgets
local shardbar = CreateFrame("Frame", "ColdShardbar", lockbar)
shardbar:SetSize(50,10)
shardbar:SetFrameLevel(6)
shardbar:SetPoint('LEFT', ColdPlayer.Health, 'LEFT', 3, 0)

local emberbar = CreateFrame("Frame", "ColdEmberbar", lockbar)
emberbar:SetSize(150, 8)
emberbar:SetFrameLevel(6)
emberbar:SetPoint("LEFT", ColdPlayer, "TOPLEFT", 4, 0)

local furybar = CreateFrame("Frame", "ColdFurybar", lockbar)
furybar:SetSize(150, 8)
furybar:SetFrameLevel(6)
furybar:SetPoint("LEFT", ColdPlayer, "TOPLEFT", 4, 0)


local function juggleBars(spec)
  if spec then
	if spec ~= affli then
		if spec == destro then
			emberbar:Show()
			shardbar:Hide()
			furybar:Hide()
		else
			emberbar:Hide()
			shardbar:Hide()
			furybar:Show()
		end
	else
		emberbar:Hide()
		shardbar:Show()
		furybar:Hide()
	end
  else
    emberbar:Hide()
	shardbar:Hide()
	furybar:Hide()
  end	
end

local function glyphcheck()
	local spec = GetSpecialization()
	
	-- glyph of burning embers
	if spec == destro then
		local maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
		local numBars = floor(maxPower / MAX_POWER_PER_EMBER)
		if numBars ~= embernum then
			embers[4]:Hide()
		else	
			embers[4]:Show()
		end
	end
	
	-- glyph of soul shards
	if spec == affli then
		local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
		if maxShards ~= shardnum then
			shards[4]:Hide()
		else
			shards[4]:Show()
		end
	end
end

local function updateBars()
	local spec = GetSpecialization()
	-- show the correct bar, hide the unnecessary ones
	juggleBars(spec)
	
	if spec then
		if spec == affli then
			local numShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
			local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
			
			for i = 1, maxShards do
				if i <= numShards then
					shards[i]:SetBackdropColor(unpack(shardc))
				else
					shards[i]:SetBackdropColor(.9,.7,.9)
				end
			end

		elseif spec == destro then
			local power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
			local maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
			local numEmbers = power / MAX_POWER_PER_EMBER
			local numBars = floor(maxPower / MAX_POWER_PER_EMBER)
			
			for i = 1, numBars do
				embers[i]:SetMinMaxValues((MAX_POWER_PER_EMBER * i) - MAX_POWER_PER_EMBER, MAX_POWER_PER_EMBER * i)
				embers[i]:SetValue(power)
			end
			
		elseif spec == demo then
			local power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
			local maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)
			
			demofury:SetMinMaxValues(0, maxPower)
			demofury:SetValue(power)
		end
	end
end

local function createBars()	
	for i = 1,4 do
		embers[i] = CreateFrame("StatusBar", "ColdEmber"..i, emberbar)
		embers[i]:SetStatusBarTexture(cfg.tex)
		embers[i]:SetStatusBarColor(unpack(emberc))
		embers[i]:SetSize(25,8)
		if i == 1 then
			embers[i]:SetPoint("LEFT", emberbar)
		else
			embers[i]:SetPoint("LEFT", embers[i-1], "RIGHT", 4, 0)
		end
		
		local shadow = CreateFrame("Frame", nil, embers[i])
		shadow:SetBackdrop(backdrop)
		shadow:SetBackdropColor(.6,.6,.6)
		shadow:SetBackdropBorderColor(0,0,0)
		shadow:SetPoint('TOPLEFT', -1, 1)
		shadow:SetPoint('BOTTOMRIGHT', 1, -1)
		shadow:SetFrameLevel(5)
		embers[i].sh = shadow
	end
	embernum = 4
	
	for i = 1, 4 do
		shards[i] = CreateFrame("Frame", "coldShard"..i, shardbar)
		shards[i]:SetSize(10, 10)
		shards[i]:SetBackdrop(backdrop)
		shards[i]:SetBackdropBorderColor(0,0,0)
		shards[i]:SetFrameLevel(6)
		if i == 1 then
			shards[i]:SetPoint("LEFT", shardbar, "LEFT")
		else
			shards[i]:SetPoint("LEFT", shards[i-1], "RIGHT", 2, 0)
		end
	end
	shardnum = 4
	
	demofury = CreateFrame("StatusBar", "ColdDemoFury", furybar)
	demofury:SetSize(150,8)
	demofury:SetPoint"CENTER"
	demofury:SetStatusBarTexture(cfg.tex)
	demofury:SetStatusBarColor(unpack(furyc))
	local shadowf = CreateFrame("Frame", nil, demofury)
	shadowf:SetBackdrop(backdrop)
	shadowf:SetBackdropColor(.2,.2,.2)
	shadowf:SetBackdropBorderColor(0,0,0)
	shadowf:SetPoint('TOPLEFT', -1, 1)
	shadowf:SetPoint('BOTTOMRIGHT', 1, -1)
	shadowf:SetFrameLevel(5)
	demofury.sh = shadowf
	
	-- force updating after creating the widgets
	updateBars()
end

lockbar:RegisterEvent("PLAYER_ENTERING_WORLD")
lockbar:RegisterEvent('UNIT_DISPLAYPOWER')
lockbar:RegisterEvent('UNIT_POWER')
lockbar:RegisterEvent('UNIT_POWER_FREQUENT')
lockbar:RegisterEvent('GLYPH_UPDATED')
lockbar:RegisterEvent('GLYPH_ADDED')
lockbar:SetScript("OnEvent",function(self,event)
	if event == "PLAYER_ENTERING_WORLD" then
		createBars()
		glyphcheck() -- forcing a glyph check as soon as we login
	elseif event == 'GLYPH_UPDATED' or event == 'GLYPH_ADDED' then
		glyphcheck()
	else
		updateBars()
	end
end)

