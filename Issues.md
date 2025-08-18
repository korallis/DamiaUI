DamiaUI issues and targeted fixes (tracking)

Open items identified

1) TOC load order: Compatibility layer not loaded in per-client TOCs
- Affected: DamiaUI_Mainline.toc, DamiaUI_Classic.toc, DamiaUI_WOTLKC.toc, DamiaUI_Cata.toc
- Impact: Modules may call deprecated APIs before wrappers exist; inconsistent cross-version behavior
- Fix: Add `Core/Compatibility.lua` and `Core/CompatibilityUtils.lua` to Core section before other core files

2) SetBackdrop used without BackdropTemplate mixin
- Affected: ActionBars/MainBar.lua, ActionBars/SecondaryBars.lua, ActionBars/PetBar.lua, ActionBars/ActionBars.lua
- Impact: Retail (9.0+) throws errors when calling SetBackdrop on frames not created with BackdropTemplate; buttons shouldn’t call SetBackdrop directly
- Fix: 
	- For frames needing borders, create child frames with "BackdropTemplate" and call SetBackdrop on those children
	- Remove redundant transparent SetBackdrop on bar frames (use no-op or textures)
	- Ensure any frame that calls SetBackdrop is created with BackdropTemplate

3) Module registration call uses dot instead of colon
- Affected: Modules/ActionBars/ActionBars.lua
- Impact: `RegisterModule` receives wrong parameters and fails type checks at runtime
- Fix: Change `DamiaUI.RegisterModule(...)` to `DamiaUI:RegisterModule(...)`

4) Direct UnitDebuff/UnitBuff usage in Raid frames
- Affected: Modules/UnitFrames/Raid.lua
- Impact: Potential API incompatibility across versions; bypasses internal compatibility
- Fix: Use `DamiaUI.Compatibility` wrappers for UnitDebuff/UnitBuff when available

5) Engine uses string:trim() which is not a standard Lua method
- Affected: Core/Engine.lua
- Impact: Runtime error when calling `input:trim()`; breaks slash commands
- Fix: Replace with Blizzard’s global `strtrim(input)` and similar where needed

Notes
- SecondaryBars already maps keybinds per-bar; ActionBars generic keybind mapping may not be used by side bars and is left as-is for now.
- Further audit for Backdrop usage in Skinning modules can follow after core fixes land.

Changes applied in this pass (commit)

- Added Compatibility modules to all per-client TOCs (before Engine)
- Fixed Backdrop issues by:
	- Creating border frames with "BackdropTemplate" for button styling in MainBar, SecondaryBars, PetBar
	- Removing transparent SetBackdrop calls on bar frames
	- Ensuring ActionBars button.border is created with BackdropTemplate
- Fixed module registration call in ActionBars.lua to use colon
- Switched Raid.lua to use compatibility wrapper for UnitDebuff (and UnitBuff if needed)
- Replaced Engine’s string:trim() usages with strtrim()

Second pass: Integration and Skinning Backdrop compliance
- Integration/Templates/DetailsTemplates.lua: Stopped calling SetBackdrop on Details base frames; now uses a background texture plus a BackdropTemplate child border frame.
- Integration/DetailsIntegration.lua: Ensure CreateDamiaDetailsBorder creates its frame with BackdropTemplate before calling SetBackdrop.
- Integration/Templates/DBMTemplates.lua: Avoid SetBackdrop on DBM bar frames; add a background texture and a BackdropTemplate child border with SetBackdrop for the edge.
- Skinning/Skinning.lua: Use BackdropTemplate for the created border frame(s) before SetBackdrop.
- Skinning/Custom.lua: Use BackdropTemplate for custom styled borders and frame shadows before SetBackdrop.
- Skinning/AddOns.lua and Skinning/Blizzard.lua: Use BackdropTemplate for helper border frames before SetBackdrop.

Post-change audit
- Grep confirms remaining SetBackdrop calls target frames created with BackdropTemplate or use library-managed wrappers (Aurora). Direct SetBackdrop on non-BackdropTemplate frames has been removed from Integration/Skinning and Interface modules.

Verification to-do
- Load each client (Retail, Classic Era, WOTLKC, Cata) to confirm no SetBackdrop assertions
- Sanity-check action bar buttons and borders render; slash commands work without errors
