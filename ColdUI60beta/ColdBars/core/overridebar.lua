  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg.bars.override
  -- get the library
  local B = ns.B
  
  local num = NUM_ACTIONBAR_BUTTONS --there seems to be no MAX_OVERRIDE_NUM or the like
  local buttonList = {}

  --create the frame to hold the buttons
  local bar = CreateFrame("Frame","ColdOverride",UIParent, "SecureHandlerStateTemplate")
  bar:SetWidth(cfg.size*num+cfg.spacing*num +10)
  bar:SetHeight(cfg.size)
  bar:SetPoint("LEFT", ColdBar1, "LEFT")
  B.makedrag(bar)
  
   -- we don't want the overridebar hidden, so we disable the button
  --bar.btn:SetScale(.00001)
 --bar.btn:SetAlpha(0)

  --move the buttons into position and reparent them
  OverrideActionBar:SetParent(bar)
  OverrideActionBar:EnableMouse(false)
  OverrideActionBar:SetScript("OnShow", nil) --remove the onshow script
  local leaveButtonPlaced = false

  for i=1, num do
    local button =  _G["OverrideActionBarButton"..i]
    if not button and not leaveButtonPlaced then
      button = OverrideActionBar.LeaveButton --the magic 7th button
      leaveButtonPlaced = true
    end
    if not button then
      break
    end
    table.insert(buttonList, button) --add the button object to the list
    button:SetSize(cfg.size, cfg.size)
    button:ClearAllPoints()
    if i == 1 then
      button:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", cfg.spacing, cfg.spacing)
    else
      local previous = _G["OverrideActionBarButton"..i-1]
      button:SetPoint("LEFT", previous, "RIGHT", cfg.spacing, 0)
    end
  end

  --show/hide the frame on a given state driver
  RegisterStateDriver(OverrideActionBar, "visibility", "[petbattle] hide; [overridebar][vehicleui][possessbar,@vehicle,exists] show; hide")
 -- RegisterStateDriver(OverrideActionBar, "visibility", "[overridebar][vehicleui] show; hide")
