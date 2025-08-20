-----------------------------------------------------------------
-- CAN'T TOUCH THIS!!!
-----------------------------------------------------------------

--get the addon namespace
local addon, ns = ...

--get the config values
local cfg = ns.cfg

-- get the library
local lib = ns.lib

local _, playerClass = UnitClass('player')

-----------------------------------------------------------------
-- popup frame
-----------------------------------------------------------------

local f = CreateFrame("Frame", "ColdUIHelp", UIParent)
f:SetPoint("BOTTOM", UIParent, "CENTER", 0, 35)
f:SetSize(335, 260)
f:SetBackdrop(backdrop)
f:SetBackdropColor(.25, .25, .25, .6)
f:SetBackdropBorderColor(0,0,0,1)
f:Hide()

local fh = lib.SetFontString(f, cfg.font, cfg.fontsize, "OUTLINE, MONOCHROME")
fh:SetPoint("TOP", f, "TOP", 0, -10)
fh:SetText("ColdUI help")
fh:SetJustifyH"CENTER"
fh:SetTextColor(.9, .9, .1)

local ft = lib.SetFontString(f, cfg.font, cfg.fontsize, "OUTLINE, MONOCHROME")
ft:SetText("Thanks for using ColdUI! You can display this help by using the |c00FF5500/ch|r command.\n\nOther slash commands:\n- |c00FF5500/fm|r will let you move the unitframes around\n- |c00FF5500/fl|r will lock the unitframes in place\n- |c00FF5500/fr|r will restore the unitframes position depending on what layout you activate in the config file.\n\nIf you use also the |c00009999ColdBars|r addon, you can use in addition:\n- |c00FF5500/bm|r will let you move the actionbars, and clicking the red buttons will show/hide the related bar\n- |c00FF5500/bl|r will lock the actionbars\n- |c00FF5500/br|r will restore the actionbars in the default position.\nAdditional options are in the addon config file, which lets you change the number of buttons or the orientation for every single actionbar.\n\nHave Fun!")
ft:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -25)
ft:SetWidth(f:GetWidth()-12)

local b = CreateFrame("Button", "ColdButton", f)
b:SetSize(120, 20)
b:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
b:SetBackdrop(backdrop)
b:SetBackdropColor(.25, .25, .25, .6)
b:SetBackdropBorderColor(0,0,0,1)
b:Hide()

local bt = lib.SetFontString(b, cfg.font, cfg.fontsize, "OUTLINE, MONOCHROME")
bt:SetPoint("CENTER", b, "CENTER", 0, 1)
bt:SetJustifyH"CENTER"
bt:SetText("Close")
bt:SetTextColor(.3, .9, .1)

b:SetScript("OnClick", function()
    f:Hide()
	b:Hide()
 end)
 
-------------------------------------------------------------------
-- from here, shenaningans
-------------------------------------------------------------------

local function start() 
	f:Show()
	b:Show()
	ColdCharVar.notfirstlogin = true
end

local uistart = CreateFrame("Frame")
uistart:RegisterEvent("PLAYER_ENTERING_WORLD")
uistart:SetScript("OnEvent", function(self, event)
	if not ColdCharVar then ColdCharVar = {} end
	local db = ColdCharVar
	
	if not db.notfirstlogin then
		start()
	end	
end)

SLASH_HELPUI1 = "/ch"
SlashCmdList.HELPUI = function() _G["ColdUIHelp"]:Show() _G["ColdButton"]:Show() end