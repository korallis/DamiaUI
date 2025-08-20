
  --local variables
  local RAID_CLASS_COLORS = RAID_CLASS_COLORS
  local FACTION_BAR_COLORS = FACTION_BAR_COLORS
  local txt = "Interface\\AddOns\\ColdPlates\\flat2"
  local font = "Interface\\AddOns\\ColdPlates\\homespun.ttf"
  local imTank
  local _, class = UnitClass('player')

  -----------------------------
  -- FUNCTIONS
  -----------------------------
  
   -- role check for aggro colors
  local function RoleCheck()
    local spec = GetSpecialization()
	if (class == 'DEATHKNIGHT' and spec == 1) or(class == 'DRUID' and spec == 3) or(class == 'MONK' and spec == 1) or(class == 'PALADIN' and spec == 2) or(class == 'WARRIOR' and spec == 3) then
	  imTank = true
	else
	  imTank = false
	end
  end
  
    --update threat
  local function UpdateThreat(f)
	local r,g,b = f.new_healthbar:GetStatusBarColor()
	if f.hasClass == true then return end
	if not f.threat:IsShown() then
			if InCombatLockdown() and f.isFriendly ~= true then
				--No Threat
				if imTank then
					f.new_healthbar:SetStatusBarColor(1, 0, 0)		
				else
					f.new_healthbar:SetStatusBarColor(0, 1, 0)
					
				end		
			else
				--Set colors to their original, not in combat
				f.new_healthbar:SetStatusBarColor(r, g, b)
			end
		else
			--Ok we either have threat or we're losing/gaining it
			local r, g, b = f.threat:GetVertexColor()
			if g + b == 0 then
				--Have Threat
				if imTank then
					f.new_healthbar:SetStatusBarColor(0, 1, 0)			
				else
					f.new_healthbar:SetStatusBarColor(1, 0, 0)
				end
			else
				--Losing/Gaining Threat
				f.new_healthbar:SetStatusBarColor(1, 1, 0)	
			end
		end
  end

  --calc hex color from rgb
  local function RGBPercToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return string.format("%02x%02x%02x", r*255, g*255, b*255)
  end

  --i dont like that
  local hideStuff = function(f)
    f.name:Hide()
    f.level:Hide()
    f.dragon:SetTexture("")
    f.border:SetTexture("")
    f.boss:SetTexture("")
    f.highlight:SetTexture("")
    f.castbar.border:SetTexture("")
    f.castbar.shield:SetTexture("")
	f.castbar.shadow:SetTexture("")
  end
  
  --set txt func
  local updateText = function(f)
    local cs = getDifficultyColorString(f)
    local color = getHealthbarColor(f)
    f.ns:SetTextColor(1,1,1)
    local name = f.name:GetText() or "Nobody"
    local level = f.level:GetText() or ""
    if f.boss:IsShown() == 1 then
      level = "??"
      cs = "ff6600"
    elseif f.dragon:IsShown() == 1 then
      level = level.."+"
    end
    f.ns:SetText("|c00"..cs..""..level.."|r "..name)
  end

  --update castbar
  local updateCastbar = function(cb)
    if cb.shield:IsShown() then
	  cb.spell:SetTextColor(1,0,0)
    else
	  cb.spell:SetTextColor(0,1,0)
    end
	cb:SetStatusBarColor(.9,.9,0)
  end

  --update health
  local updateHealth = function(hb)
    if not hb then return end
    local nhb = hb:GetParent():GetParent().new_healthbar
    local min, max = hb:GetMinMaxValues()
    nhb:SetMinMaxValues(min,max)
    local val = hb:GetValue()
    nhb:SetValue(val)
  end

  --fix some more stuff
  local fixStuff = function(f)
    f.threat:ClearAllPoints()
    f.threat:SetAllPoints(f.threat_holder)
    f.threat:SetParent(f.threat_holder)
	UpdateThreat(f)
  end

  --fix the damn castbar hopping
  local fixCastbar = function(cb)
    --print("fix castbar")
    cb:ClearAllPoints()
    cb:SetAllPoints(cb.parent)
    cb:SetParent(cb.parent)
	updateCastbar(cb)
  end

  --get the actual color
  local fixColor = function(color)
    color.r,color.g,color.b = floor(color.r*100+.5)/100, floor(color.g*100+.5)/100, floor(color.b*100+.5)/100
  end

  --get colorstring for level color
  local getDifficultyColorString = function(f)
    local color = {}
    color.r,color.g,color.b = f.level:GetTextColor()
    fixColor(color)
    return RGBPercToHex(color.r,color.g,color.b)
  end

  --adjust faction color
  local fixFactionColor = function(color)
    for class, _ in pairs(RAID_CLASS_COLORS) do
      if RAID_CLASS_COLORS[class].r == color.r and RAID_CLASS_COLORS[class].g == color.g and RAID_CLASS_COLORS[class].b == color.b then
	  	f.hasClass = true
		--f.isFriendly = false
        return --no color change needed, bar is in class color
      end
    end
    if color.g+color.b == 0 then -- hostile
      color.r,color.g,color.b = FACTION_BAR_COLORS[2].r, FACTION_BAR_COLORS[2].g, FACTION_BAR_COLORS[2].b
	  --f.isFriendly = false
      return
    elseif color.r+color.b == 0 then -- friendly npc
      color.r,color.g,color.b = FACTION_BAR_COLORS[6].r, FACTION_BAR_COLORS[6].g, FACTION_BAR_COLORS[6].b
	  --f.isFriendly = true
      return
    elseif color.r+color.g > 1.95 then -- neutral
      color.r,color.g,color.b = FACTION_BAR_COLORS[4].r, FACTION_BAR_COLORS[4].g, FACTION_BAR_COLORS[4].b
	 -- f.isFriendly = false
      return
    elseif color.r+color.g == 0 then -- friendly player, we don't like 0,0,1 so we change it to a more likable color
      color.r,color.g,color.b = 0/255, 100/255, 255/255
	  --f.isFriendly = true
      return
    else -- enemy player
      --f.isFriendly = false
      return
    end
  end

  --get healthbar color func
  local getHealthbarColor = function(f)
    local color = {}
    color.r,color.g,color.b = f.healthbar:GetStatusBarColor()
    fixColor(color)
    --now that we have the color make sure we match it to the new faction/class colors
    fixFactionColor(color)
    --f.healthbar:SetStatusBarColor(color.r,color.g,color.b, 1)
    f.new_healthbar:SetStatusBarColor(color.r,color.g,color.b, 1)
    f.healthbar.defaultColor = color
    f.healthbar.colorApplied = "default"
    return color
  end

  --set txt func
  local updateText = function(f)
    local cs = getDifficultyColorString(f)
    local color = getHealthbarColor(f)
    f.ns:SetTextColor(1,1,1)
    local name = f.name:GetText() or "Nobody"
    local level = f.level:GetText() or ""
    if f.boss:IsShown() == 1 then
      level = "??"
      cs = "ff6600"
    elseif f.dragon:IsShown() == 1 then
      level = level.."+"
    end
    f.ns:SetText("|c00"..cs..""..level.."|r "..name)
  end

  --update castbar
  local updateCastbar = function(cb)
    if cb.shield:IsShown() then
	  cb.spell:SetTextColor(1,0,0)
    else
	  cb.spell:SetTextColor(0,1,0)
    end
  end

  --update health
  local updateHealth = function(hb)
    if not hb then return end
    local nhb = hb:GetParent():GetParent().new_healthbar
    local min, max = hb:GetMinMaxValues()
    nhb:SetMinMaxValues(min,max)
    local val = hb:GetValue()
    nhb:SetValue(val)
  end

  --new fontstrings for name and lvl func
  local createNameString = function(f)
	local offset = UIParent:GetScale() / f:GetEffectiveScale()
    local n = f.new_healthbar:CreateFontString(nil, "OVERLAY")
    n:SetFont(font, 10*offset, "OUTLINE, MONOCHROME")
    n:SetPoint("TOPLEFT", f.new_healthbar, "LEFT", 2*offset, 3*offset)
	n:SetPoint("TOPRIGHT", f.new_healthbar, "RIGHT", 0, 3*offset)
    n:SetJustifyH("LEFT")
    f.ns = n
  end

  --create art
  local createArt = function(f)
	local offset = UIParent:GetScale() / f:GetEffectiveScale()
    local w,h = 100, 4
    --threat holder
    local th = CreateFrame("Frame",nil,f)
    --th:SetSize(w,h)
    --th:SetPoint("CENTER")
    --threat glow
    --f.threat:SetTexCoord(0,1,0,1)
    --f.threat:SetTexture(txt)
    --f.threat:ClearAllPoints()
    --f.threat:SetAllPoints(th)
    f.threat:SetParent(th)
	th:Hide() -- hide the blizz threat glow (keeping the code just in case)
    --the default healthbar is bugged, the alpha can bug out...so we create our own healthbar
    f.healthbar:SetStatusBarTexture("")
    --background frame
    local nhb = CreateFrame("Statusbar",nil,f)
    nhb:SetStatusBarTexture(txt)
    nhb:SetSize(w,h)
    nhb:SetPoint("CENTER",0,0)
	nhb:SetFrameLevel(4)
    --bg
    local bf = CreateFrame("Frame",nil,f)
    bf:SetSize(w+2*offset, h+2*offset)
    bf:SetPoint"CENTER"
	bf:SetBackdrop({
	bgFile = txt,
	edgeFile = txt,
	edgeSize = offset,
	})
	bf:SetBackdropColor(.2,.2,.2,.6)
	bf:SetBackdropBorderColor(0,0,0)
	bf:SetFrameLevel(2)
    --raid icon
    f.raid:ClearAllPoints()
    f.raid:SetSize(25,25)
    f.raid:SetPoint("CENTER", 0, 35*offset)
	f.raid:SetTexture([[Interface\AddOns\oUF_Coldkil\textures\raidicons.blp]])
    f.raid:SetParent(f)
    --parent frames
    f.threat_holder = th
    f.new_healthbar = nhb
    --f.gloss_holder = hl
  end

  --create castbar art
  local createCastbarArt = function(f)
    local offset = UIParent:GetScale() / f:GetEffectiveScale()
    local w,h = 100, 4
    --background frame
    local bf = CreateFrame("Frame",nil,f)
    bf:SetSize(w,h)
    bf:SetPoint("CENTER",0, -15*offset)
	bf:SetFrameLevel(4)
	--position castbar
    f.castbar:SetStatusBarTexture(txt)
    f.castbar:ClearAllPoints()
    f.castbar:SetAllPoints(bf)
    f.castbar:SetParent(bf)
    --bg
	local bg = CreateFrame("Frame",nil,f.castbar)
	bg:SetSize(w+2*offset, h+2*offset)
    bg:SetPoint"CENTER"
	bg:SetBackdrop({
	bgFile = txt,
	edgeFile = txt,
	edgeSize = offset,
	})
	bg:SetBackdropColor(.2,.2,.2,.6)
	bg:SetBackdropBorderColor(0,0,0)
	bg:SetFrameLevel(2)
	--fix the new 5.3 castbar text
	f.castbar.spell:SetFont(font, 10*offset, "OUTLINE, MONOCHROME")
	f.castbar.spell:SetPoint("TOPLEFT", 2*offset, 0)
	f.castbar.spell:SetJustifyH"LEFT"
    --move icon to gloss frame
    local ic = CreateFrame("Frame",nil,f.castbar)
    ic:SetSize(20*offset,20*offset)
    ic:SetPoint("BOTTOMRIGHT", f.castbar, "BOTTOMLEFT", -4, 0)
	ic:SetFrameLevel(2)
    --castbar icon adjust
    f.castbar.icon:SetTexCoord(0.1,0.9,0.1,0.9)
    f.castbar.icon:ClearAllPoints()
    f.castbar.icon:SetAllPoints(ic)
    f.castbar.icon:SetParent(ic)
    f.castbar.icon:SetDrawLayer("BACKGROUND",3)
    local ib = CreateFrame("Frame",nil,ic)
	ib:SetSize(22*offset, 22*offset)
    ib:SetPoint"CENTER"
	ib:SetBackdrop({
	bgFile = txt,
	edgeFile = txt,
	edgeSize = offset,
	})
	ib:SetBackdropColor(.2,.2,.2,.6)
	ib:SetBackdropBorderColor(0,0,0)
	ib:SetFrameLevel(1)
    f.castbar.parent = bf --keep reference to parent element for later
    f.castbar_holder = bf
  end

  --update style func
  local updateStyle = function(f)
    hideStuff(f)
    fixStuff(f)
    updateText(f)
    updateHealth(f.healthbar)
  end

  --init style func
  local styleNameplate = function(f)
    if not f then return end
    if f and f.rDB_styled then return end
    --make objects available for later
    f.barFrame, f.nameFrame = f:GetChildren()
    f.healthbar, f.castbar = f.barFrame:GetChildren()
    f.threat, f.border, f.highlight, f.level, f.boss, f.raid, f.dragon = f.barFrame:GetRegions()
    f.name = f.nameFrame:GetRegions()
    f.healthbar.texture = f.healthbar:GetRegions()
    f.castbar.texture, f.castbar.border, f.castbar.shield, f.castbar.icon, f.castbar.spell, f.castbar.shadow = f.castbar:GetRegions()
    f.unit = {}
    --create stuff
    createArt(f)
    createCastbarArt(f)
    createNameString(f)
    updateText(f)
    --hide stuff
    hideStuff(f)
    --hook stuff
    f:HookScript("OnShow", updateStyle)
    f.castbar:HookScript("OnShow", updateCastbar)
    --fix castbar
    f.castbar:SetScript("OnValueChanged", fixCastbar)
    --update health
    f.healthbar:SetScript("OnValueChanged", updateHealth)
    updateHealth(f.healthbar)
    --set var
    f.rDP_styled = true
  end

  --check
  local IsNamePlateFrame = function(f)
    local name = f:GetName()
    if name and name:find("NamePlate") then
      return true
    end
    f.rDP_styled = true --don't touch this frame again
    return false
  end

  local startSearch = function(self)
    --timer
    local ag = self:CreateAnimationGroup()
    ag.anim = ag:CreateAnimation()
    ag.anim:SetDuration(0.33)
    ag:SetLooping("REPEAT")
    ag:SetScript("OnLoop", function(self, event, ...)
      local num = select("#", WorldFrame:GetChildren())
      for i = 1, num do
        local f = select(i, WorldFrame:GetChildren())
        if not f.rDP_styled and IsNamePlateFrame(f) then
          styleNameplate(f)
		elseif IsNamePlateFrame(f) then
		  UpdateThreat(f)
        end
      end
    end)
    ag:Play()
  end

  --init
  local a = CreateFrame("Frame")
  a:RegisterEvent("PLAYER_LOGIN")
  a:RegisterEvent("PLAYER_ENTERING_WORLD")
  a:RegisterEvent("PLAYER_REGEN_ENABLED")
  a:RegisterEvent("PLAYER_REGEN_DISABLED")
  a:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
  a:RegisterEvent("PLAYER_TALENT_UPDATE")
  a:SetScript("OnEvent", function(self,event,...)
    if event == "PLAYER_LOGIN" then
      SetCVar("bloattest",0)--0.0
      SetCVar("bloatnameplates",0)--0.0
      SetCVar("bloatthreat",0)--1
      startSearch(self)
	  RoleCheck()
	elseif(event=="PLAYER_ENTERING_WORLD") then
	  if InCombatLockdown() then
		SetCVar("nameplateShowEnemies", 1)
	  else
		SetCVar("nameplateShowEnemies", 0)
	  end
	elseif(event=="PLAYER_REGEN_ENABLED") then
		SetCVar("nameplateShowEnemies", 0)
	elseif(event=="PLAYER_REGEN_DISABLED") then
		SetCVar("nameplateShowEnemies", 1)
	else
	  RoleCheck()
    end
  end)