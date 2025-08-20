
  --get the addon namespace
  local addon, ns = ...
  local cfg = ns.cfg

  -----------------------------
  -- CHARSPECIFIC PROFILES
  -----------------------------

  local playername, _ = UnitName("player")
  local _, playerclass = UnitClass("player")

  if playername == "Coldkil" then
	--do stuff (use config options here)
  end