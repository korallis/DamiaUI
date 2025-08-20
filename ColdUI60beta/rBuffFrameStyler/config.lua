
  -- // rBuffFrameStyler
  -- // zork - 2010

  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local cfg = CreateFrame("Frame")
  ns.cfg = cfg

  -----------------------------
  -- CONFIG
  -----------------------------

  cfg.buffframe = {
    scale           = 1,
    pos             = { a1 = "TOPRIGHT", af = "UIParent", a2 = "TOPRIGHT", x = -35, y = -35 },
    userplaced      = false, --want to place the bar somewhere else?
    rowSpacing      = 0,
    colSpacing      = 0,
    buffsPerRow     = 10,
    gap             = 10, --gap in pixel between buff and debuff
  }

  cfg.tempenchant = {
    scale           = 1,
    pos             = { a1 = "TOP", af = "Minimap", a2 = "BOTTOM", x = 40, y = -70 },
    userplaced      = false, --want to place the bar somewhere else?
    colSpacing      = 0,
  }

  cfg.textures = {
    normal            = "Interface\\AddOns\\rBuffFrameStyler\\media\\gloss",
    outer_shadow      = "Interface\\AddOns\\rBuffFrameStyler\\media\\outer_shadow",
  }

  cfg.background = {
    showshadow        = false,   --show an outer shadow?
    shadowcolor       = { r = 0, g = 0, b = 0, a = 0.9},
    inset             = 6,
  }

  cfg.color = {
    normal            = { r = 0.4, g = 0.35, b = 0.35, },
    classcolored      = false,
  }

  cfg.duration = {
    fontsize        = 10,
    pos             = { a1 = "BOTTOM", x = 1.5, y = 1 },
  }

  cfg.count = {
    fontsize        = 10,
    pos             = { a1 = "TOPRIGHT", x = 0, y = 0 },
  }

  cfg.font = "Interface\\AddOns\\rBuffFrameStyler\\media\\homespun.ttf"
