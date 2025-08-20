
# DamiaUI ➜ Full 11.2 Upgrade Playbook (Interface 110200)

**Purpose:** Transform `DamiaUI` into a 1:1 replica of `ColdUI60beta`, fully updated for **Retail 11.2** with correct APIs, libraries, and file structure. This guide is written so that an AI (or a human) can execute it step-by-step inside Cursor.

**Authoritative targets (validated):**
- Patch **11.2.0** “Ghosts of K’aresh”; addon **TOC interface = 110200**. citeturn1search12turn1search0
- **Settings API** replaced most old Interface Options functions in 10.0+. citeturn0search3
- **Bags API** moved to `C_Container` and returns a **structured table**. citeturn0search9turn0search17
- **Backdrop** usage requires `"BackdropTemplate"` since 9.0. citeturn0search10
- **Aura iteration**: prefer `AuraUtil.ForEachAura`. citeturn0search4turn0search20
- **Tooltip data**: `C_TooltipInfo.*` namespace (if you need structured tooltip reads). citeturn0search5turn0search13

> ⚠️ Scope: This playbook assumes **Retail-only** target. If you later support Classic flavors, add additional TOCs and compatibility shims.

---

## 0) Repo Layout & Preconditions

- Repo contains **both** folders at root:
  - `ColdUI60beta/` (source-of-truth legacy)
  - `DamiaUI/` (live addon to be replaced)
- You have a POSIX shell (bash) available for one-liners. Windows users can use Git Bash or PowerShell equivalents included below.
- You will **commit** after every phase.

---

## 1) Phase A — Make DamiaUI a byte-for-byte mirror of ColdUI60beta

**Goal:** Reset `DamiaUI/` to a clean copy of `ColdUI60beta/` so functionality matches exactly before modernization.

### Commands (bash)
```bash
cd <repo-root>

# Safety commit of current work
git add -A && git commit -m "backup: before 11.2 migration (pre-mirror)" || true

# Replace DamiaUI with ColdUI60beta
rm -rf DamiaUI
cp -a ColdUI60beta DamiaUI

git add -A && git commit -m "feat: mirror DamiaUI from ColdUI60beta (pre-modernization)"
```

### Commands (PowerShell)
```powershell
Set-Location <repo-root>
git add -A; git commit -m "backup: before 11.2 migration (pre-mirror)"
Remove-Item -Recurse -Force DamiaUI
Copy-Item -Recurse ColdUI60beta DamiaUI
git add -A; git commit -m "feat: mirror DamiaUI from ColdUI60beta (pre-modernization)"
```

---

## 2) Phase B — Namespace / SavedVariables rename to “DamiaUI”

**Goal:** Ensure global table, SavedVariables, and literal strings match `DamiaUI`.

### Automated replacements (bash)
```bash
# Exact-token rename (case-sensitive) with .bak backups
grep -RIl --exclude-dir=.git -e '\bColdUI\b' DamiaUI | xargs -I{} sed -i.bak 's/\bColdUI\b/DamiaUI/g' {}
grep -RIl --exclude-dir=.git -e '\bCOLDUI\b' DamiaUI | xargs -I{} sed -i.bak 's/\bCOLDUI\b/DAMIAUI/g' {}
```

### Manual review check
- Search the repo for `ColdUI` to catch edge cases (textures, strings you *don’t* want renamed). Fix any false positives.
- Ensure the TOC’s `## SavedVariables:` uses `DamiaUI_DB` (below).

```bash
git add -A && git commit -m "chore: rename ColdUI -> DamiaUI (namespace & savedvars)"
```

---

## 3) Phase C — Update TOC to **Interface: 110200**

Create/overwrite `DamiaUI/DamiaUI.toc` **exactly** as follows:

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

- **Why 110200?** This is the interface number for patch 11.2.0. citeturn1search12turn1search0

```bash
git add DamiaUI/DamiaUI.toc && git commit -m "chore(toc): set Interface 110200 and module list"
```

---

## 4) Phase D — Library Update Matrix (install or embed)

> You can **vendor** libs under `DamiaUI/Libs` and include via `embeds.xml`, or configure `.pkgmeta` for externals. The sources below are current for Retail 11.2.

| Library | Purpose | Where to fetch (primary) | Notes |
|---|---|---|---|
| **LibActionButton-1.0** | Secure action button framework | CurseForge / WowAce files (Retail builds updated **Aug 2, 2025**) | Compatible with **Retail 11.2**; use for bars/buttons. citeturn0search6turn0search22 |
| **LibSharedMedia-3.0** | Shared fonts/sounds/textures | CurseForge files (**May 21, 2025** latest) | Safe for 11.x; register your assets cleanly. citeturn0search7turn0search15turn0search23 |
| **oUF** (optional) | Unit-frame framework | GitHub (oUF-wow) | Modern versions target Retail; ensure your layout is compatible. citeturn0search1 |
| **LibDataBroker-1.1** | Data provider interface | GitHub mirrors / packager | Stable; only if you expose an LDB feed. *(General reference)* |

### embeds.xml (create/overwrite at `DamiaUI/embeds.xml`)
```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <!-- If you vendor libraries under DamiaUI/Libs/, uncomment the lines you need. -->

  <!-- Ace3 (optional, if you use it) -->
  <!-- <Include file="Libs\Ace3\AceAddon-3.0\AceAddon-3.0.xml"/> -->
  <!-- <Include file="Libs\Ace3\AceEvent-3.0\AceEvent-3.0.xml"/> -->
  <!-- <Include file="Libs\Ace3\AceConsole-3.0\AceConsole-3.0.xml"/> -->
  <!-- <Include file="Libs\Ace3\AceDB-3.0\AceDB-3.0.xml"/> -->
  <!-- <Include file="Libs\Ace3\AceConfig-3.0\AceConfig-3.0.xml"/> -->

  <!-- LibSharedMedia -->
  <!-- <Script file="Libs\LibSharedMedia-3.0\LibSharedMedia-3.0.lua"/> -->

  <!-- LibDataBroker -->
  <!-- <Script file="Libs\LibDataBroker-1.1\LibDataBroker-1.1.lua"/> -->

  <!-- oUF -->
  <!-- <Include file="Libs\oUF\ouf.xml"/> -->

  <!-- LibActionButton -->
  <!-- <Include file="Libs\LibActionButton-1.0\LibActionButton-1.0.xml"/> -->
</Ui>
```

```bash
git add DamiaUI/embeds.xml && git commit -m "chore(embeds): library includes for 11.2"
```

---

## 5) Phase E — API Modernization (mechanical, regex-safe)

### E1. Bags API → `C_Container`

**Replace calls and update callsites for new return type.**

#### Mechanical replacements (bash)
```bash
# Replace legacy function names with namespaced versions
grep -RIl 'GetContainerItemInfo\|GetContainerNumSlots\|GetContainerItemLink' DamiaUI | while read -r f; do
  sed -i.bak 's/\bGetContainerItemInfo\b/C_Container.GetContainerItemInfo/g' "$f"
  sed -i.bak 's/\bGetContainerNumSlots\b/C_Container.GetContainerNumSlots/g' "$f"
  sed -i.bak 's/\bGetContainerItemLink\b/C_Container.GetContainerItemLink/g' "$f"
done
```

#### Correct usage (edit callsites)
```lua
-- OLD (multiple returns):
-- local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)

-- NEW (single table return in DF+):
local info = C_Container.GetContainerItemInfo(bag, slot)  -- returns a table
if info then
  local icon   = info.iconFileID
  local count  = info.stackCount or 1
  local link   = C_Container.GetContainerItemLink(bag, slot)
  local quality = info.quality
end
```
*(DF 10.0.2 namespaced and table-return confirmed.)* citeturn0search9turn0search17

Commit:
```bash
git add -A && git commit -m "refactor(bags): migrate to C_Container (table returns)"
```

---

### E2. Backdrops → `"BackdropTemplate"`

**All frames using `:SetBackdrop`, `:ApplyBackdrop`, etc., must be created with the Backdrop template.**

#### Mechanical helper (bash; heuristic)
```bash
# Add "BackdropTemplate" to CreateFrame("Frame", ...) that probably use backdrops later.
# Review every diff; this is a heuristic.
perl -0777 -pi -e 's/(CreateFrame\(\s*"Frame"\s*,\s*[^,]+,\s*[^,\)]+\))\s*\)/$1, "BackdropTemplate")/g' DamiaUI/**/*.lua 2>/dev/null || true
```

#### Correct pattern (edit frames that set backdrops)
```lua
local f = CreateFrame("Frame", "DamiaBox", UIParent, "BackdropTemplate")
f.backdropInfo = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left=8, right=8, top=8, bottom=8 },
}
f:ApplyBackdrop()
-- f:ClearBackdrop()
```
*(Backdrop change originated in 9.0; templates required.)* citeturn0search10

Commit:
```bash
git add -A && git commit -m "refactor(ui): enforce BackdropTemplate on backdrop frames"
```

---

### E3. Options Panel → **Settings API**

**Replace** `InterfaceOptionsFrame_OpenToCategory` & `InterfaceOptions_AddCategory` **with** the Settings API.

#### Create `DamiaUI/Core/Init.lua` (or merge into your core file)
```lua
local ADDON, NS = ...
NS.DAMIA_NAME = "DamiaUI"

-- SavedVariables bootstrap (AceDB optional)
local function initDB()
  if LibStub and LibStub("AceDB-3.0", true) then
    NS.db = LibStub("AceDB-3.0"):New("DamiaUI_DB", { profile = {} }, true)
  else
    DamiaUI_DB = DamiaUI_DB or { profile = {} }
    NS.db = DamiaUI_DB
  end
end

local function createOptionsPanel()
  local cfg = CreateFrame("Frame", "DamiaUIOptions", UIParent, "BackdropTemplate")
  cfg.name = NS.DAMIA_NAME
  local title = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(NS.DAMIA_NAME .. " Configuration")

  local sub = cfg:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetText("Retail 11.2 • /damia to open")

  local category, layout = Settings.RegisterCanvasLayoutCategory(cfg, NS.DAMIA_NAME)
  Settings.RegisterAddOnCategory(category)
  NS.CATEGORY_ID = category:GetID()
end

local function openOptions()
  if NS.CATEGORY_ID then
    Settings.OpenToCategory(NS.CATEGORY_ID)
  end
end

SLASH_DAMIA1 = "/damia"
SLASH_DAMIA2 = "/damiaui"
SlashCmdList.DAMIA = function(msg)
  msg = strtrim(msg or "")
  if msg == "" or msg == "config" then
    openOptions()
  elseif msg == "reset" then
    if NS.db and NS.db.profile then wipe(NS.db.profile) print("|cffff7f00DamiaUI:|r Profile reset.") end
  else
    print("|cffff7f00DamiaUI commands:|r /damia, /damia config, /damia reset")
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    initDB()
    createOptionsPanel()
  end
end)
```

*(Settings API introduced 10.0; use `RegisterCanvasLayoutCategory` and `OpenToCategory`.)* citeturn0search3

Commit:
```bash
git add DamiaUI/Core/Init.lua && git commit -m "feat(settings): migrate options to Settings API"
```

---

### E4. Auras → `AuraUtil.ForEachAura`

**Replace manual `UnitAura` loops** with `AuraUtil.ForEachAura` for correctness and future-proofing.

Create/merge `DamiaUI/Modules/Auras.lua`:
```lua
local function EachAura(unit, filter, fn)
  AuraUtil.ForEachAura(unit, filter, nil, function(aura)
    fn(aura)     -- aura.name, aura.spellId, aura.duration, aura.expirationTime, etc.
    return false -- continue
  end)
end

-- Example: count target debuffs on target change
local function CountTargetDebuffs()
  local n = 0
  EachAura("target", "HARMFUL", function() n = n + 1 end)
  return n
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:SetScript("OnEvent", function() CountTargetDebuffs() end)
```
*(Recommended in modern docs.)* citeturn0search4turn0search20

Commit:
```bash
git add DamiaUI/Modules/Auras.lua && git commit -m "refactor(auras): use AuraUtil.ForEachAura"
```

---

### E5. Tooltip reads (only if you parse tooltips)

If your code scrapes tooltips for info, switch to `C_TooltipInfo.*` where possible.

```lua
local tip = C_TooltipInfo.GetInboxItem(1)  -- example
-- Or: C_TooltipInfo.GetUnitAura("target", index, "HARMFUL")
```
*(Namespace reference.)* citeturn0search5turn0search13

Commit (if applicable):
```bash
git add -A && git commit -m "refactor(tooltip): migrate to C_TooltipInfo namespace"
```

---

## 6) Phase F — Minimal Bag module using modern API

Create/merge `DamiaUI/Modules/Bags.lua`:
```lua
local function ForEachSlot(fn)
  for bag = 0, NUM_BAG_SLOTS do
    local slots = C_Container.GetContainerNumSlots(bag)
    if slots and slots > 0 then
      for slot = 1, slots do fn(bag, slot) end
    end
  end
end

local function DebugBags()
  ForEachSlot(function(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then
      local link = C_Container.GetContainerItemLink(bag, slot)
      local count = info.stackCount or 1
      -- print(("Bag %d Slot %d: %s x%d"):format(bag, slot, link or "nil", count))
    end
  end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:SetScript("OnEvent", function() DebugBags() end)
```

Commit:
```bash
git add DamiaUI/Modules/Bags.lua && git commit -m "feat(bags): add modern C_Container example module"
```

---

## 7) Phase G — Backdrop helper (optional)

Create/merge `DamiaUI/Core/Compat.lua`:
```lua
local _G = _G
DamiaUI_Compat = {}

function DamiaUI_Compat:CreateBackdropFrame(parent, name)
  local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
  return f
end
```

Commit:
```bash
git add DamiaUI/Core/Compat.lua && git commit -m "chore: Backdrop helper"
```

---

## 8) Phase H — Library embedding (optional vendoring)

Create folder structure if you vendor:
```
DamiaUI/
  Libs/
    Ace3/...
    LibSharedMedia-3.0/...
    LibDataBroker-1.1/...
    oUF/...
    LibActionButton-1.0/...
```
Then **uncomment** corresponding lines in `embeds.xml` and commit.

---

## 9) Phase I — Validation: Static search & lint

### I1. Grep sweep (no further hits expected)
```bash
grep -RIn "GetContainer" DamiaUI && echo "❌ Legacy bag calls remain"; true
grep -RIn "InterfaceOptionsFrame_OpenToCategory" DamiaUI && echo "❌ Legacy options open call remains"; true
grep -RIn "SetBackdrop(" DamiaUI && echo "ℹ️ Ensure these frames inherit BackdropTemplate"; true
grep -RIn "UnitAura(" DamiaUI && echo "ℹ️ Consider AuraUtil.ForEachAura"; true
```

### I2. Syntax check (Lua 5.1 style)
- Skim for trailing commas in tables and typos (`:trim()` ➜ `strtrim` in WoW).

Commit any fixes as needed.

---

## 10) Phase J — In‑game QA

1. **Enable Lua errors** (Interface → Help).
2. Launch **Retail 11.2** with only **DamiaUI** enabled.
3. Type `/damia` ➜ Settings panel opens. citeturn0search3
4. Open **bags** ➜ no errors; items resolve via `C_Container` and `stackCount`. citeturn0search9
5. Inspect any framed panels using backdrops ➜ render without errors (BackdropTemplate in place). citeturn0search10
6. Target a dummy ➜ aura logic works with `AuraUtil.ForEachAura`. citeturn0search4

If errors occur, capture **exact** file/line and adjust the relevant section above.

---

## 11) Phase K — Optional: Action Bars & Unit Frames

- If you manage bars:
  - Prefer **LibActionButton-1.0** (Retail builds current as of **Aug 2, 2025**). citeturn0search6
- If you use unit frames:
  - Update **oUF** to a current Retail-ready version. *(Project maintained)*. citeturn0search1

---

## 12) Appendix — Rationale & References

- **11.2.0 interface 110200** and patch notes/API deltas. citeturn1search12turn1search0
- **Settings API** (10.0) overview and migration. citeturn0search3
- **C_Container** table return & namespacing. citeturn0search9turn0search17
- **Backdrop** template requirement since 9.0. citeturn0search10
- **AuraUtil.ForEachAura** usage recommendation. citeturn0search4turn0search20
- **C_TooltipInfo** namespace (structured tooltip data). citeturn0search5turn0search13

---

## 13) Final Commit

```bash
git add -A
git commit -m "DamiaUI: fully updated to Retail 11.2 (Interface 110200) — bags->C_Container, Settings API, BackdropTemplate, AuraUtil; libs ready"
```

> ✅ After following **all** phases, `DamiaUI` should load cleanly on **Retail 11.2** with modern APIs and library hooks.
