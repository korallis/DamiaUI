# DamiaUI Final Implementation Guide
**Based on GW2 UI Architecture Analysis**  
**Date:** August 19, 2025  
**Goal:** Clean, minimalistic, pixel-perfect modern UI

---

## The Truth About WoW UI Replacement

After analyzing GW2 UI (a successful, mature UI replacement), here's what actually works:

### Key Insights
1. **Don't recreate, restyle** - Hook and modify existing elements
2. **Hide EVERYTHING Blizzard** - Not just 2 frames, but 30+
3. **Use templates for consistency** - XML or Lua templates
4. **Settings from day one** - Every feature toggleable
5. **Work WITH WoW's systems** - Not against them

---

## Phase 1: Foundation (Week 1)

### 1.1 Project Structure
```
DamiaUI/
├── Core/
│   ├── Init.lua           # Namespace, constants
│   ├── API.lua            # API wrappers
│   ├── DisableBlizzard.lua # Complete hiding
│   └── Templates.lua      # Reusable templates
├── Modules/
│   ├── ActionBars.lua     # Action bar styling
│   ├── UnitFrames.lua     # Unit frames
│   └── Auras.lua          # Buffs/debuffs
├── Settings/
│   ├── Defaults.lua       # Default settings
│   └── Config.lua         # Settings interface
├── Media/
│   ├── Textures/         # Minimal textures
│   └── Fonts/            # Clean fonts
└── DamiaUI.toc
```

### 1.2 Complete Blizzard UI Hiding
```lua
-- DisableBlizzard.lua
local BLIZZARD_FRAMES = {
    -- Main Action Bars
    MainMenuBar,
    MainMenuBar.Background,
    MainMenuBarOverlayFrame,
    MainMenuBar.EndCaps.LeftEndCap,
    MainMenuBar.EndCaps.RightEndCap,
    MainMenuBar.BorderArt,
    
    -- Multi Bars
    MultiBarBottomLeft,
    MultiBarBottomRight,
    MultiBarLeft,
    MultiBarRight,
    VerticalMultiBarsContainer,
    
    -- Status Bars
    StatusTrackingBarManager,
    MainMenuExpBar,
    ReputationWatchBar,
    HonorWatchBar,
    
    -- Micro Menu & Bags
    MicroMenuContainer,
    BagsBar,
    
    -- Unit Frames (if replacing)
    PlayerFrame,
    TargetFrame,
    FocusFrame,
    
    -- Other UI Elements
    ObjectiveTrackerFrame,
    MinimapCluster,
    ChatFrame1Tab,
}

local function HideBlizzardUI()
    for _, frame in pairs(BLIZZARD_FRAMES) do
        if frame then
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            if frame.UnregisterAllEvents then
                frame:UnregisterAllEvents()
            end
            -- Force hide on show
            hooksecurefunc(frame, "Show", function(self)
                self:Hide()
            end)
        end
    end
end
```

### 1.3 Core Initialization
```lua
-- Init.lua
local addonName, DamiaUI = ...
_G.DamiaUI = DamiaUI

-- Constants
DamiaUI.media = {
    borderColor = {0.2, 0.2, 0.2, 1},
    backgroundColor = {0.05, 0.05, 0.05, 0.9},
    font = "Fonts\\FRIZQT__.TTF",
    statusbar = "Interface\\BUTTONS\\WHITE8X8",
}

-- Settings
DamiaUI.defaults = {
    actionbars = {
        enabled = true,
        buttonSize = 36,
        spacing = 2,
    },
    unitframes = {
        enabled = true,
        style = "minimal",
    },
}

-- Module system
DamiaUI.modules = {}
function DamiaUI:RegisterModule(name, module)
    self.modules[name] = module
end

function DamiaUI:InitializeModules()
    for name, module in pairs(self.modules) do
        if module.Initialize then
            module:Initialize()
        end
    end
end
```

---

## Phase 2: Action Bars (Week 1-2)

### 2.1 Style Existing Buttons (Don't Recreate)
```lua
-- ActionBars.lua
local function StyleActionButton(button)
    if button.styled then return end
    
    -- Hide default textures
    local normal = button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    
    -- Icon setup
    local icon = button.icon
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    
    -- Create clean border
    if not button.border then
        button.border = CreateFrame("Frame", nil, button)
        button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
        button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
        button.border:SetBackdrop({
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        })
        button.border:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end
    
    -- Cooldown setup
    local cooldown = button.cooldown
    if cooldown then
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        cooldown:SetDrawBling(false)
        cooldown:SetHideCountdownNumbers(false)
    end
    
    -- Hotkey styling
    local hotkey = button.HotKey
    if hotkey then
        hotkey:SetFont(DamiaUI.media.font, 11, "OUTLINE")
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    end
    
    button.styled = true
end

-- Hook to style all action buttons
local function StyleAllActionButtons()
    -- Main action bar
    for i = 1, 12 do
        StyleActionButton(_G["ActionButton"..i])
    end
    
    -- Multi bars
    for i = 1, 12 do
        StyleActionButton(_G["MultiBarBottomLeftButton"..i])
        StyleActionButton(_G["MultiBarBottomRightButton"..i])
        StyleActionButton(_G["MultiBarLeftButton"..i])
        StyleActionButton(_G["MultiBarRightButton"..i])
    end
end

-- Create custom action bar container
local function CreateActionBarContainer()
    local bar = CreateFrame("Frame", "DamiaUIMainBar", UIParent)
    bar:SetSize(12 * 38 + 11 * 2, 38)
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 30)
    
    -- Position default buttons in our frame
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        button:ClearAllPoints()
        button:SetParent(bar)
        button:SetSize(36, 36)
        
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", _G["ActionButton"..(i-1)], "RIGHT", 2, 0)
        end
        
        StyleActionButton(button)
    end
    
    return bar
end
```

---

## Phase 3: Unit Frames (Week 2)

### 3.1 Minimal Unit Frame Template
```lua
-- UnitFrames.lua
local function CreateMinimalUnitFrame(unit, width, height)
    local frame = CreateFrame("Button", "DamiaUI"..unit.."Frame", UIParent, 
                             "SecureUnitButtonTemplate, BackdropTemplate")
    frame:SetSize(width or 200, height or 50)
    frame.unit = unit
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    -- Health bar
    frame.health = CreateFrame("StatusBar", nil, frame)
    frame.health:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
    frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.health:SetHeight(height - 15)
    
    -- Power bar
    frame.power = CreateFrame("StatusBar", nil, frame)
    frame.power:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
    frame.power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.power:SetHeight(10)
    
    -- Health text
    frame.healthText = frame.health:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetFont(DamiaUI.media.font, 12, "OUTLINE")
    frame.healthText:SetPoint("CENTER", frame.health, "CENTER", 0, 0)
    
    -- Name text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY")
    frame.nameText:SetFont(DamiaUI.media.font, 11, "OUTLINE")
    frame.nameText:SetPoint("LEFT", frame.health, "LEFT", 4, 0)
    
    -- Register unit
    frame:SetAttribute("unit", unit)
    frame:RegisterForClicks("AnyUp")
    RegisterUnitWatch(frame)
    
    -- Update function
    frame.Update = function(self)
        if not UnitExists(unit) then return end
        
        -- Update health
        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)
        self.health:SetMinMaxValues(0, maxHealth)
        self.health:SetValue(health)
        self.healthText:SetText(string.format("%d%%", (health/maxHealth) * 100))
        
        -- Update power
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        self.power:SetMinMaxValues(0, maxPower)
        self.power:SetValue(power)
        
        -- Power color
        local powerType = UnitPowerType(unit)
        local color = PowerBarColor[powerType]
        if color then
            self.power:SetStatusBarColor(color.r, color.g, color.b)
        end
        
        -- Name
        self.nameText:SetText(UnitName(unit))
    end
    
    -- Events
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(self, event, ...)
        if ... == unit then
            self:Update()
        end
    end)
    
    frame:Update()
    
    return frame
end
```

---

## Phase 4: Settings System (Week 3)

### 4.1 Settings Infrastructure
```lua
-- Settings/Config.lua
local function CreateSettingsPanel()
    local panel = CreateFrame("Frame", "DamiaUIConfig", UIParent)
    panel.name = "DamiaUI"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(DamiaUI.media.font, 18, "OUTLINE")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    title:SetText("DamiaUI Settings")
    
    -- Action Bars toggle
    local actionBarsToggle = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    actionBarsToggle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    actionBarsToggle.text:SetText("Enable Action Bars")
    actionBarsToggle:SetChecked(DamiaUI.settings.actionbars.enabled)
    
    -- Register with Interface Options
    InterfaceOptions_AddCategory(panel)
    
    return panel
end
```

---

## Critical Implementation Rules

### DO:
1. ✅ Hide ALL Blizzard frames completely
2. ✅ Style existing elements when possible
3. ✅ Use BackdropTemplate for frames with backgrounds
4. ✅ Use SecureActionButtonTemplate for clickable actions
5. ✅ Test every feature in-game before moving on
6. ✅ Use consistent spacing (2px) and sizes

### DON'T:
1. ❌ Use ActionButton_UpdateAction (doesn't exist)
2. ❌ Recreate what you can restyle
3. ❌ Create frames without templates
4. ❌ Assume old API patterns work
5. ❌ Skip testing

---

## Visual Design Guidelines

### Colors
- Background: `0.05, 0.05, 0.05, 0.9` (Near black)
- Borders: `0.2, 0.2, 0.2, 1` (Dark gray)
- Text: `1, 1, 1, 1` (White)
- Health: `0.1, 0.8, 0.1, 1` (Green)
- Power: Dynamic based on type

### Spacing
- Button spacing: 2px
- Frame padding: 1px
- Text offset: 4px

### Fonts
- Main: FRIZQT 12px
- Small: FRIZQT 10px
- Headers: FRIZQT 14px
- All with OUTLINE

---

## Testing Checklist

After each phase:
- [ ] `/reload` - No Lua errors
- [ ] All Blizzard frames hidden
- [ ] Action buttons clickable
- [ ] Cooldowns display correctly
- [ ] Unit frames update health/power
- [ ] Settings save and load
- [ ] Combat lockdown respected
- [ ] Memory usage reasonable

---

## Timeline

- **Week 1:** Foundation + Basic Action Bars
- **Week 2:** Unit Frames + Auras
- **Week 3:** Settings + Polish
- **Week 4:** Testing + Optimization

Total: 1 month to functional, clean UI replacement