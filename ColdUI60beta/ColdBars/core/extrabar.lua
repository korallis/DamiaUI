  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg.bars.extra
  -- get the library
  local B = ns.B

  local num = 1
  local buttonList = {}

  --create the frame to hold the buttons
  local bar = CreateFrame("Frame","ColdExtra",UIParent, "SecureHandlerStateTemplate")
  bar:SetWidth(cfg.size+10)
  bar:SetHeight(cfg.size)
  bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
  B.makedrag(bar)
  
  -- we don't want that for some unfortunate case extraaction button is missing, so hiding the button is the best way to not mess with it
  bar.btn:SetScale(.00001)
  bar.btn:SetAlpha(0)
  
  ExtraActionBarFrame:Show()
  
  --move the buttons into position and reparent them
  ExtraActionBarFrame:SetParent(bar)
  ExtraActionBarFrame:EnableMouse(false)
  ExtraActionBarFrame:ClearAllPoints()
  ExtraActionBarFrame.ignoreFramePositionManager = true

  --the extra button
  local button = ExtraActionButton1
  table.insert(buttonList, button) --add the button object to the list
  button:SetSize(cfg.size,cfg.size)
  button:SetPoint("LEFT", bar, "LEFT")

  --show/hide the frame on a given state driver
  RegisterStateDriver(ExtraActionBarFrame, "visibility", "[petbattle][overridebar][vehicleui] hide; show")

