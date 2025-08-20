  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg.bars.bar4
    -- get the library
  local B = ns.B

  local num = NUM_ACTIONBAR_BUTTONS
  local buttonList = {}

  --create the frame to hold the buttons
  local bar = CreateFrame("Frame","ColdBar4",UIParent, "SecureHandlerStateTemplate")
  if cfg.vertical then
  	bar:SetWidth(cfg.size)
    bar:SetHeight(cfg.size*cfg.num+cfg.spacing*cfg.num +10)
  else
	bar:SetWidth(cfg.size*cfg.num+cfg.spacing*cfg.num +10)
    bar:SetHeight(cfg.size)
  end
  bar:SetPoint("RIGHT", UIParent, "RIGHT", -10, 0)
  B.makedrag(bar)
  
  --move the buttons into position and reparent them
  MultiBarRight:SetParent(bar)
  MultiBarRight:EnableMouse(false)

  for i=1, num do
    local button = _G["MultiBarRightButton"..i]
    table.insert(buttonList, button) --add the button object to the list
    button:SetSize(cfg.size, cfg.size)
    button:ClearAllPoints()
	if i == 1 then
	  if cfg.vertical then
       button:SetPoint("BOTTOM", bar, cfg.spacing, cfg.spacing)
	  else
	   button:SetPoint("LEFT", bar, cfg.spacing, cfg.spacing)
	  end
    else
      local previous = _G["MultiBarRightButton"..i-1]
	   if cfg.vertical then
        button:SetPoint("BOTTOM", previous, "TOP", 0, cfg.spacing)
	   else
		button:SetPoint("LEFT", previous, "RIGHT", cfg.spacing, 0)
	   end
    end
	if cfg.mouseover then	
	  bar:SetAlpha(0)
	  button:SetScript("OnEnter",function()
		bar:SetAlpha(1)
	  end)
	  button:SetScript("Onleave",function()
		bar:SetAlpha(0)
	  end)
	end
  end

  -- hide the unnecessary buttons
  if cfg.num < 12 then
    for y=cfg.num+1, 12 do
	  local button = _G["MultiBarRightButton"..y]
	  button:SetScale(.00001)
      button:SetAlpha(0)
    end
  end	

  --show/hide the frame on a given state driver
  RegisterStateDriver(MultiBarRight, "visibility", "[petbattle][overridebar][vehicleui] hide; show")