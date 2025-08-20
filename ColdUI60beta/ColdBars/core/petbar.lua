  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg.bars.pet
  -- get the library
  local B = ns.B


  local num = NUM_PET_ACTION_SLOTS
  local buttonList = {}

  --create the frame to hold the buttons
  local bar = CreateFrame("Frame","ColdPetBar",UIParent, "SecureHandlerStateTemplate")
  if cfg.vertical then
  	bar:SetWidth(cfg.size)
    bar:SetHeight(cfg.size*num+cfg.spacing*num +10)
  else
	bar:SetWidth(cfg.size*num+cfg.spacing*num +10)
    bar:SetHeight(cfg.size)
  end
  bar:ClearAllPoints()
  bar:SetPoint("TOP", ColdBar1, "BOTTOM", 0, 0)
  B.makedrag(bar)

  --move the buttons into position and reparent them
  PetActionBarFrame:SetParent(bar)
  PetActionBarFrame:EnableMouse(false)

  for i=1, num do
    local button = _G["PetActionButton"..i]
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
      local previous = _G["PetActionButton"..i-1]
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
    --cooldown fix
    local cd = _G["PetActionButton"..i.."Cooldown"]
    cd:SetAllPoints(button)
  end

  --show/hide the frame on a given state driver
  RegisterStateDriver(PetActionBarFrame, "visibility", "[petbattle][overridebar][vehicleui] hide; [@pet,exists,nodead] show; hide")