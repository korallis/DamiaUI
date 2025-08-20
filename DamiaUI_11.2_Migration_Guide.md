
# DamiaUI → 11.2 Migration Guide (Retail 11.2 / Interface 110200)

> Goal: make `DamiaUI` an exact replica of `ColdUI60beta`, fully modernized for **Retail 11.2** (TOC **110200**) with libraries and APIs updated.

## 0) Prereqs

- You have `ColdUI60beta/` and `DamiaUI/` at the repo root.
- You’re targeting **Retail 11.2** (Interface **110200**).

---

## 1) What the old script would do (now written as exact, manual steps)

### A. Mirror the folder (ColdUI60beta → DamiaUI)
1. Remove the current DamiaUI folder:
   ```bash
   git rm -r DamiaUI || rm -rf DamiaUI
   ```
2. Copy the ColdUI tree:
   ```bash
   cp -a ColdUI60beta DamiaUI
   ```

### B. Rename the namespace & SavedVariables
```bash
grep -RIl --exclude-dir=.git -e '\bColdUI\b' DamiaUI | xargs -I{} sed -i.bak 's/\bColdUI\b/DamiaUI/g' {}
grep -RIl --exclude-dir=.git -e '\bCOLDUI\b' DamiaUI | xargs -I{} sed -i.bak 's/\bCOLDUI\b/DAMIAUI/g' {}
```

### C. Update common APIs

1) **Bags** → `C_Container`
```bash
grep -RIl 'GetContainerItemInfo\|GetContainerNumSlots\|GetContainerItemLink' DamiaUI | while read f; do
  sed -i.bak 's/\bGetContainerItemInfo\b/C_Container.GetContainerItemInfo/g' "$f"
  sed -i.bak 's/\bGetContainerNumSlots\b/C_Container.GetContainerNumSlots/g' "$f"
  sed -i.bak 's/\bGetContainerItemLink\b/C_Container.GetContainerItemLink/g' "$f"
done
```

Lua:
```lua
local info = C_Container.GetContainerItemInfo(bag, slot)
if info then
  local icon = info.iconFileID
  local count = info.stackCount or 1
  local link = C_Container.GetContainerItemLink(bag, slot)
end
```

2) **Backdrops** → `BackdropTemplate`
```lua
local f = CreateFrame("Frame", "DamiaBox", UIParent, "BackdropTemplate")
f.backdropInfo = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left=8, right=8, top=8, bottom=8 }
}
f:ApplyBackdrop()
```

3) **Options** → Settings API
```lua
local cfg = CreateFrame("Frame", "DamiaUIOptions", UIParent, "BackdropTemplate")
cfg.name = "DamiaUI"
local category = Settings.RegisterCanvasLayoutCategory(cfg, cfg.name)
Settings.RegisterAddOnCategory(category)
local id = category:GetID()
SLASH_DAMIA1="/damia"
SlashCmdList.DAMIA = function() Settings.OpenToCategory(id) end
```

4) **Auras** → AuraUtil
```lua
AuraUtil.ForEachAura("target", "HARMFUL", nil, function(aura)
  return false
end)
```

5) **Tooltips** → C_TooltipInfo
```lua
local data = C_TooltipInfo.GetUnitAura("target", index, "HARMFUL")
```

### D. TOC & scaffolding

`DamiaUI/DamiaUI.toc`:
```toc
## Interface: 110200
## Title: DamiaUI
## Notes: Complete interface replacement (Retail 11.2)
## Version: 11.2.0
## Author: DamiaUI Team
## SavedVariables: DamiaUI_DB
## OptionalDeps: Ace3, LibSharedMedia-3.0, LibDataBroker-1.1, oUF, LibActionButton-1.0
## X-Embeds: Ace3, LibSharedMedia-3.0, LibDataBroker-1.1, oUF, LibActionButton-1.0

embeds.xml

Core/Init.lua
Core/Compat.lua

Modules/Bags.lua
Modules/Auras.lua
```

### E. Libraries
- LibActionButton-1.0 — current for 11.2.0
- LibSharedMedia-3.0 — maintained
- oUF — maintained

---

## 2) Test Plan

1) Enable Lua errors.
2) Login with only DamiaUI enabled.
3) `/damia` opens panel.
4) Open bags — no errors.
5) Backdrop frames render.
6) Target mob — AuraUtil logic runs.

---

## 3) Grep for stragglers

```bash
grep -RIn "GetContainer" DamiaUI
grep -RIn "SetBackdrop" DamiaUI
grep -RIn "InterfaceOptionsFrame_OpenToCategory" DamiaUI
grep -RIn "UnitAura(" DamiaUI
```

---

## 4) Best Practices

- Use Settings API.
- Use C_Container and C_TooltipInfo.
- Always use BackdropTemplate for :SetBackdrop.
- Prefer AuraUtil.ForEachAura.
- Avoid taint by respecting secure templates.
- Keep TOC fields accurate.
