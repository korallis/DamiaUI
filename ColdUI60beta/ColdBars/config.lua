  --get the addon namespace
  local cfg = CreateFrame("Frame")
  local addon, ns = ...
  ns.cfg = cfg

  -----------------------------
  -- CONFIG
  -----------------------------
  cfg.bars = {
    --MAIN BAR
    bar1 = {
		num             = 8,       -- number of button to be displayed (between 1 and 12)
        size            = 28,      -- button size (28 is the size matching ColdUI)
        spacing         = 0,       -- spacing between buttons (0 equals a 2px space in game)
		vertical        = false,   -- button orientation (default: left to right, vertical: bottom to top)
		mouseover       = false,   -- set bar visible on mouseover
    },
    --OVERRIDE BAR (vehicle ui)
    override = { --the new vehicle and override bar
        size            = 28,     
        spacing         = 0,      
		--vertical        = false, thinking if it's a good idea
    },
    --BAR 2
    bar2 = {
		num             = 8,      
        size            = 28,     
        spacing         = 0,      
		vertical        = false,
		mouseover       = false,    
    },
    --BAR 3
    bar3 = {
		num             = 8,      
        size            = 28,     
        spacing         = 0,      
		vertical        = false,
		mouseover       = true, 
    },
    --BAR 4
    bar4 = {
		num             = 4,      
        size            = 28,     
        spacing         = 0,      
		vertical        = true,
		mouseover       = false, 
    },
    --BAR 5
    bar5 = {
		num             = 4,      
		size            = 28,     
		spacing         = 0,      
		vertical        = true,
		mouseover       = false, 
    },
    --PETBAR
    pet = {   
		size            = 28,     
		spacing         = 0,      
		vertical        = false,
		mouseover       = false, 
    },
    --STANCE + POSSESSBAR
    stance = {
		size            = 28,     
		spacing         = 0,      
		vertical        = true,
		mouseover       = false, 
    },
    --EXTRA ACTION BUTTON
    extra = { 
		size            = 36, -- it doesn't need much more than a defined size
    },
  }

  cfg.style = {
	font = "Interface\\AddOns\\ColdBars\\font.ttf",  -- font for hotkeys, item count
	fs = 10,                                         -- font size
	mono = true,                                     -- set to false if you don't use pixel fonts
	
	showhk = true,                                   -- show/hide hotkeys
	showic = true,                                   -- show/hide item count
	
	-- textures
	normal            = "Interface\\AddOns\\ColdBars\\tex\\gloss",
    flash             = "Interface\\AddOns\\ColdBars\\tex\\flash",
    hover             = "Interface\\AddOns\\ColdBars\\tex\\hover",
    pushed            = "Interface\\AddOns\\ColdBars\\tex\\pushed",
    checked           = "Interface\\AddOns\\ColdBars\\tex\\checked",
    equipped          = "Interface\\AddOns\\ColdBars\\tex\\gloss_grey",
    buttonback        = "Interface\\AddOns\\ColdBars\\tex\\button_background",
    buttonbackflat    = "Interface\\AddOns\\ColdBars\\tex\\button_background_flat",
    outer_shadow      = "Interface\\AddOns\\ColdBars\\tex\\outer_shadow",
  }