  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg.bars.stance
  -- get the library
  local B = ns.B

  local num = NUM_STANCE_SLOTS
  local num2 = NUM_POSSESS_SLOTS
  local buttonList = {}

  --container frame
  local bar = CreateFrame("Frame","ColdStance",UIParent, "SecureHandlerStateTemplate")
  if cfg.vertical then
  	bar:SetWidth(cfg.size)
    bar:SetHeight(cfg.size*num+cfg.spacing*num +10)
  else
	bar:SetWidth(cfg.size*num+cfg.spacing*num +10)
    bar:SetHeight(cfg.size)
  end
  bar:SetPoint("BOTTOMRIGHT", ColdBar1, "BOTTOMLEFT", 0, 0)
  B.makedrag(bar)

  --stancebar
  StanceBarFrame:SetParent(bar)
  StanceBarFrame:EnableMouse(false)

  for i=1, num do
    local button = _G["StanceButton"..i]
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
      local previous = _G["StanceButton"..i-1]
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

  --possess bar
  PossessBarFrame:SetParent(bar)
  PossessBarFrame:EnableMouse(false)

  for i=1, num2 do
    local button = _G["PossessButton"..i]
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
      local previous = _G["PossessButton"..i-1]
	   if cfg.vertical then
        button:SetPoint("BOTTOM", previous, "TOP", 0, cfg.spacing)
	   else
		button:SetPoint("LEFT", previous, "RIGHT", cfg.spacing, 0)
	   end
    end
  end

  --show/hide the frame on a given state driver
  RegisterStateDriver(StanceBarFrame, "visibility", "[petbattle][overridebar][vehicleui] hide; show")
  RegisterStateDriver(PossessBarFrame, "visibility", "[petbattle][overridebar][vehicleui] hide; show")