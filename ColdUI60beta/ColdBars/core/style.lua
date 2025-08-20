  --get the addon namespace
  local addon, ns = ...

  --get the config values
  local cfg = ns.cfg.style
  
  local outline = ""
  if mono then outline = "OUTLINE, MONOCHROME" else outline = "THINOUTLINE" end
  local _G = _G
  local i
  
  -- creating button background
  local backdrop = {
    bgFile = cfg.buttonbackflat,
    tile = false,
    tileSize = 32,
    edgeSize = 5,
    insets = {left = 5, right = 5, top = 5.5, bottom = 5,},
  }
  
  local function applyBackground(bu)
    if not bu or (bu and bu.bg) then return end
    if bu:GetFrameLevel() < 1 then bu:SetFrameLevel(1) end
    bu.bg = CreateFrame("Frame", nil, bu)
    bu.bg:SetAllPoints(bu)
    bu.bg:SetPoint("TOPLEFT", bu, "TOPLEFT", -4, 4)
    bu.bg:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", 4, -4)
    bu.bg:SetFrameLevel(bu:GetFrameLevel()-1)
    bu.bg:SetBackdrop(backdrop)
    bu.bg:SetBackdropColor(.2, .2, .2, .6)
	bu.bg:SetBackdropBorderColor(0,0,0)
  end
  
  -- style extra action button
  local function styleExtra(bu)
    if not bu or (bu and bu.styled) then return end -- run the script only once
    local name = bu:GetName()
    local ho = _G[name.."HotKey"]
    --remove the style background theme
    bu.style:SetTexture(nil)
    hooksecurefunc(bu.style, "SetTexture", function(self, texture)
      if texture then
        self:SetTexture(nil)
      end
    end)
    --icon
    bu.icon:SetTexCoord(0.1,0.9,0.1,0.9)
    bu.icon:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
    bu.icon:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)
    --cooldown
    bu.cooldown:SetAllPoints(bu.icon)
    --hotkey
    ho:Hide()
    --add button normaltexture
    bu:SetNormalTexture(cfg.normal)
    local nt = bu:GetNormalTexture()
    nt:SetVertexColor(.37, .3, .3)
    nt:SetAllPoints(bu)
    --apply background
    if not bu.bg then applyBackground(bu) end
    bu.styled = true
  end
  
  
  --style action bar buttons
  local function styleButton(bu)
    if not bu or (bu and bu.styled) then
      return
    end
    local action = bu.action
    local name = bu:GetName()
    local ic  = _G[name.."Icon"]
    local co  = _G[name.."Count"]
    local bo  = _G[name.."Border"]
    local ho  = _G[name.."HotKey"]
    local cd  = _G[name.."Cooldown"]
    local na  = _G[name.."Name"]
    local fl  = _G[name.."Flash"]
    local nt  = _G[name.."NormalTexture"]
    local fbg  = _G[name.."FloatingBG"]
    if fbg then fbg:Hide() end  --floating background
    bo:SetTexture(nil)          --hide the border
    --hotkey
    if cfg.showhk then
      ho:SetFont(cfg.font, cfg.fs, "OUTLINE, MONOCHROME")
      ho:ClearAllPoints()
      ho:SetPoint("BOTTOMLEFT", 1, 1.5)
      ho:SetPoint("BOTTOMRIGHT", 1, 1.5)
    else
      ho:Hide()
    end
	--item count
	if cfg.showic then
      co:SetFont(cfg.font, cfg.fs, "OUTLINE, MONOCHROME")
      co:ClearAllPoints()
      co:SetPoint("TOPRIGHT", 1, .5)
	  co:SetTextColor(0,1,0)
    else
      co:Hide()
    end
    na:Hide() -- hide macro names
    --applying the textures
    fl:SetTexture(cfg.flash)
    bu:SetHighlightTexture(cfg.hover)
    bu:SetPushedTexture(cfg.pushed)
    bu:SetCheckedTexture(cfg.checked)
    bu:SetNormalTexture(cfg.normal)
    --cut default border
    ic:SetTexCoord(0.1,0.9,0.1,0.9)
    ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
    ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)
    --adjust cooldown frame
    cd:SetPoint("TOPLEFT", bu, "TOPLEFT", 1, -1)
    cd:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -1, 1)
    --apply the normaltexture
    if ( IsEquippedAction(action) ) then
      bu:SetNormalTexture(cfg.equipped)
      nt:SetVertexColor(.1,.5,.1)
    else
      bu:SetNormalTexture(cfg.normal)
      nt:SetVertexColor(.37,.3,.3)
    end
    --make the normaltexture match the buttonsize
    nt:SetAllPoints(bu)
    --hook to prevent Blizzard from reseting our colors
    hooksecurefunc(nt, "SetVertexColor", function(nt, r, g, b, a)
      local bu = nt:GetParent()
      local action = bu.action
      if r==1 and g==1 and b==1 and action and (IsEquippedAction(action)) then
          nt:SetVertexColor(0.999,0.999,0.999,1)
      elseif r==0.5 and g==0.5 and b==1 then
        --blizzard oom color
          nt:SetVertexColor(0.499,0.499,0.999,1)
      elseif r==1 and g==1 and b==1 then
          nt:SetVertexColor(0.999,0.999,0.999,1)
      end
    end)
    --background
    if not bu.bg then applyBackground(bu) end
    bu.styled = true
  end
  
  --style pet bar
  local function stylePet(bu)
    if not bu or (bu and bu.styled) then return end
    local name = bu:GetName()
    local ic  = _G[name.."Icon"]
    local fl  = _G[name.."Flash"]
    local nt  = _G[name.."NormalTexture2"]
    nt:SetAllPoints(bu)
    --applying color
    nt:SetVertexColor(.37, .3, .3, 1)
    --setting the textures
    fl:SetTexture(cfg.flash)
    bu:SetHighlightTexture(cfg.hover)
    bu:SetPushedTexture(cfg.pushed)
    bu:SetCheckedTexture(cfg.checked)
    bu:SetNormalTexture(cfg.normal)
    hooksecurefunc(bu, "SetNormalTexture", function(self, texture)
      --make sure the normaltexture stays the way we want it
      if texture and texture ~= cfg.normal then
        self:SetNormalTexture(cfg.normal)
      end
    end)
    --cut the default border of the icons and make them shiny
    ic:SetTexCoord(0.1,0.9,0.1,0.9)
    ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
    ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)
    --shadows+background
    if not bu.bg then applyBackground(bu) end
    bu.styled = true
  end
  
  --style stance bar
  local function styleStance(bu)
    if not bu or (bu and bu.styled) then return end
    local name = bu:GetName()
    local ic  = _G[name.."Icon"]
    local fl  = _G[name.."Flash"]
    local nt  = _G[name.."NormalTexture2"]
    nt:SetAllPoints(bu)
    --applying color
    nt:SetVertexColor(.37, .3, .3,1)
    --setting the textures
    fl:SetTexture(cfg.flash)
    bu:SetHighlightTexture(cfg.hover)
    bu:SetPushedTexture(cfg.pushed)
    bu:SetCheckedTexture(cfg.checked)
    bu:SetNormalTexture(cfg.normal)
    --cut the default border of the icons and make them shiny
    ic:SetTexCoord(0.1,0.9,0.1,0.9)
    ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
    ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)
    --shadows+background
    if not bu.bg then applyBackground(bu) end
    bu.styled = true
  end
  
  --style possess bar
  local function stylePossess(bu)
    if not bu or (bu and bu.styled) then return end
    local name = bu:GetName()
    local ic  = _G[name.."Icon"]
    local fl  = _G[name.."Flash"]
    local nt  = _G[name.."NormalTexture"]
    nt:SetAllPoints(bu)
    --applying color
    nt:SetVertexColor(.37, .3, .3, 1)
    --setting the textures
    fl:SetTexture(cfg.flash)
    bu:SetHighlightTexture(cfg.hover)
    bu:SetPushedTexture(cfg.pushed)
    bu:SetCheckedTexture(cfg.checked)
    bu:SetNormalTexture(cfg.normal)
    --cut the default border of the icons and make them shiny
    ic:SetTexCoord(0.1,0.9,0.1,0.9)
    ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
    ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)
    --shadows+background
    if not bu.bg then applyBackground(bu) end
    bu.styled = true
  end
  
  -- shorten some hotkey names
  local replace = string.gsub
  local function updatehotkey(self, actionButtonType)
	local hotkey = _G[self:GetName() .. 'HotKey']
	local text = hotkey:GetText()
	
	text = replace(text, '(s%-)', 's')
	text = replace(text, '(a%-)', 'a')
	text = replace(text, '(c%-)', 'c')
	text = replace(text, '(Mouse Button )', 'm')
	text = replace(text, '(Middle Mouse)', 'm3')
	text = replace(text, '(Mouse Wheel Up)', 'mU')
	text = replace(text, '(Mouse Wheel Down)', 'mD')
	text = replace(text, '(Num Pad )', 'n')
	text = replace(text, '(Page Up)', 'pu')
	text = replace(text, '(Page Down)', 'pd')
	text = replace(text, '(Spacebar)', 'spb')
	text = replace(text, '(Insert)', 'ins')
	text = replace(text, '(Home)', 'hm')
	text = replace(text, '(Delete)', 'del')
	
	if hotkey:GetText() == _G['RANGE_INDICATOR'] then
		hotkey:SetText('')
	else
		hotkey:SetText(text)
	end
  end
  
  -- initialize function
  local function init()
    --style the actionbar buttons
    for i = 1, NUM_ACTIONBAR_BUTTONS do
      styleButton(_G["ActionButton"..i])
      styleButton(_G["MultiBarBottomLeftButton"..i])
      styleButton(_G["MultiBarBottomRightButton"..i])
      styleButton(_G["MultiBarRightButton"..i])
      styleButton(_G["MultiBarLeftButton"..i])
    end
    for i = 1, 6 do
      styleButton(_G["OverrideActionBarButton"..i])
    end
    --petbar buttons
    for i=1, NUM_PET_ACTION_SLOTS do
      stylePet(_G["PetActionButton"..i])
    end
    --stancebar buttons
    for i=1, NUM_STANCE_SLOTS do
      styleStance(_G["StanceButton"..i])
    end
    --possess buttons
    for i=1, NUM_POSSESS_SLOTS do
      stylePossess(_G["PossessButton"..i])
    end
    --extraactionbutton1
    styleExtra(_G["ExtraActionButton1"])	
  end
  
  -- launch the styling!
  local a = CreateFrame("Frame")
  a:RegisterEvent("PLAYER_LOGIN")
  a:RegisterEvent("PLAYER_ENTERING_WORLD")
  a:SetScript("OnEvent", init)
  hooksecurefunc("ActionButton_UpdateHotkeys", updatehotkey)