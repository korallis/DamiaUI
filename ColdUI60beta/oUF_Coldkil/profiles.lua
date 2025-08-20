--get the addon namespace
local addon, ns = ...
--get the config values
local cfg = ns.cfg
-----------------------------------------------------------------------------
-- PROFILES FILE
-- Here you can define custom sets of config options for your characters.
-- Just follow the template below
-----------------------------------------------------------------------------
local charname = select(1, UnitName("player"))
local spec = GetSpecialization()

if charname == "Vrargh" then                -- check characters name
	cfg.layout.healer = false			    -- set character-only options
end


