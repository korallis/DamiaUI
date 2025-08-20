--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-- get the library
local lib = ns.lib

--getting the values
local curxp 
local maxxp
local perxp 
local restxp
local restper
local GetRestPer = function()
	local rested = GetXPExhaustion()
	if(rested and rested > 0) then
		return math.floor(rested / UnitXPMax("player") * 100 + 0.5)
	end
end

-- creating the xpbar frame
local xpback = CreateFrame("Frame", nil, ColdPlayer)
xpback:SetBackdrop(backdrop)
xpback:SetBackdropColor(.6,.6,.6)
xpback:SetBackdropBorderColor(0,0,0,0)
xpback:SetPoint("CENTER", ColdPlayer.Power, "CENTER")
xpback:SetSize(200, 8)
xpback:SetFrameLevel(4)
xpback:SetAlpha(0)

local xpbar = CreateFrame("StatusBar", nil, xpback)
xpbar:SetStatusBarTexture(cfg.tex)
xpbar:SetStatusBarColor(.9, .2, 1)
xpbar:SetSize(200,8)
xpbar:SetPoint("CENTER", xpback, "CENTER")
xpbar:SetFrameLevel(6)

local restbar = CreateFrame("StatusBar", nil, xpback)
restbar:SetStatusBarTexture(cfg.tex)
restbar:SetStatusBarColor(0, .4, 1)
restbar:SetSize(200,8)
restbar:SetPoint("CENTER", xpback, "CENTER")
restbar:SetFrameLevel(5)
restbar:Hide()


-- magic is here (updating the values so we have a working xp bar)
local function UpdateXP()
    curxp = UnitXP("player")
	maxxp = UnitXPMax("player")
	-- check needed because of new wow 5.0 engine
	if curxp == 0 then curxp = 1 end
	if maxxp == 0 or curxp > maxxp then maxxp = curxp end
	-- end checks
	perxp = math.floor(curxp/maxxp*100 + 0.5)
	restxp = GetXPExhaustion()
	restper = GetRestPer() or 1 -- again, the same check
	if UnitLevel("player") ~= MAX_PLAYER_LEVEL then
		xpbar:SetMinMaxValues(min(0, curxp), maxxp)
		xpbar:SetValue(curxp)
		if restxp then
			restbar:Show()
			restbar:SetMinMaxValues(min(0, curxp), maxxp)
			restbar:SetValue(curxp+restxp)
		else 
			restbar:Hide()	
		end
	else
		xpback:Hide()
	end
	
	local nextlvl = UnitLevel("player") + 1
	local line1 = "To level "..nextlvl..": "..lib.siValue(curxp).."/"..lib.siValue(maxxp).." ("..perxp.."%)"
	local line2
	if restxp then
		line2 = "|cff0066ffRested: "..lib.siValue(restxp).." ("..restper.."%)|r"
	end	
	
	xpback:SetScript("OnEnter", function()
		xpback:SetAlpha(1)
		-- creating the tooltip with the xp text
		GameTooltip:SetOwner(xpback, "ANCHOR_BOTTOM", 0, -10)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(line1)
		GameTooltip:AddLine(line2)
		GameTooltip:Show()
	end)
	xpback:SetScript("OnLeave", function()
		xpback:SetAlpha(0)
		GameTooltip:Hide()
	end)
end


-- xp display command (made for debugging, left in the end)
SLASH_EXP1 = "/xp"
SlashCmdList.EXP = function() 
	print("curxp: "..curxp.." maxxp: "..maxxp.." perxp: "..perxp)
	if restxp then print("restxp:"..restxp) end
 end
 
 -- register the events for updating the values
 local frame = CreateFrame("Frame",nil,UIParent)
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("UPDATE_EXHAUSTION")
frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
frame:RegisterEvent("UPDATE_FACTION")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", UpdateXP)