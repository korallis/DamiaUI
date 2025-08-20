# DamiaUI 11.2 Lua Example Pack

Drop the `DamiaUI` folder into your `_retail_/Interface/AddOns/` folder or replace your repo's `DamiaUI/` with this one.

Contents:
- `DamiaUI.toc` (Interface 110200)
- `embeds.xml` (commented includes for vendored libs)
- `Core/Init.lua` (Settings API panel, slash commands, SavedVariables bootstrap)
- `Core/Compat.lua` (Backdrop & bag helper)
- `Modules/Bags.lua` (C_Container usage)
- `Modules/Auras.lua` (AuraUtil.ForEachAura usage)

Notes:
- If you use Ace3/AceDB, add the includes in `embeds.xml` and vendor the libs under `DamiaUI/Libs/` or configure `.pkgmeta`.
- Use `/damia` or `/damiaui` in-game to open the Settings panel.
