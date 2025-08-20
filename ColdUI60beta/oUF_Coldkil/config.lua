--get the addon namespace
local addon, ns = ...
  
--generate a holder for the config data
local cfg = CreateFrame("Frame")

-----------------------------
-- CONFIG
-----------------------------
cfg.plugins = {
	lootframe = true,      -- enable/disable lootframe reskin
}

cfg.layout = {
	portraits = true,      -- enable/disable portraits
	fadeout = false,       -- fading unitframes out of combat
}

cfg.player = {
	buffs = false,         -- player buffs on frame
	debuffs = false,       -- player debuffs on frame
	hpX = 1,               -- hp text horizontal offset (change it to adjust for different reso as needed)
	hpY = 2,               -- hp text vertical offset
	powX = 3,              -- power text horizontal offset
	powY = 2,              -- power text vertical offset
}

cfg.target = {
	buffs = true,          -- target buffs on frame
	debuffs = true,        -- target debuffs on frame
	hpX = 3,               -- hp horizontal offset
	hpY = 2,               -- hp vertical offset
	perX = 1,              -- hp% horizontal offset
	perY = 2,              -- hp% vertical offset
}

cfg.focus = {
	extended = false,      -- extended focus frame, with portrait and castbar (set it to false to have the minimal one)
}

cfg.party = {
	buffs = false,         -- party frame buffs
	debuffs = true,        -- party frame debuffs
}

cfg.raid = {
	showraid = true,       -- set to false if you want to use another addon for raid frames
	showraidhp = false,     -- enable/disable hp% on raid frames (healer layout only)
	timers = true,         -- enable/disable timers on raid frames (healer layout only)
}

cfg.datatext = {
	enable = true,	       -- oh yeah
}

cfg.worldmapsize = .65     -- set the scale of the small world map

-- fonts and textures
cfg.font              = "Interface\\AddOns\\oUF_Coldkil\\fonts\\homespun.ttf"
cfg.fontsize          = 10      
cfg.tex               = "Interface\\AddOns\\oUF_Coldkil\\textures\\flat2"
cfg.texflat           = "Interface\\AddOns\\oUF_Coldkil\\textures\\flat2"
cfg.texcast           = "Interface\\AddOns\\oUF_Coldkil\\textures\\flat2"
cfg.texblank          = "Interface\\Buttons\\WHITE8x8"

--hand the config to the namespace for usage in other lua files
ns.cfg = cfg