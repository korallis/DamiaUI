# Verified World of Warcraft API Documentation
## Based on Production Addons Working in 11.2.0
**Date:** August 19, 2025  
**Interface:** 110200  
**Status:** VERIFIED with working addons

---

## Critical Requirements Since WoW 9.0

### BackdropTemplate is MANDATORY
```lua
-- ❌ BROKEN - Will fail with "SetBackdrop is nil"
local frame = CreateFrame("Frame", "MyFrame", UIParent)

-- ✅ WORKING - Required since 9.0 (2020)
local frame = CreateFrame("Frame", "MyFrame", UIParent, "BackdropTemplate")
```

### Fixing Older Frames
```lua
-- For frames created without BackdropTemplate
if not frame.SetBackdrop then
    Mixin(frame, BackdropTemplateMixin)
end
```

---

## Working Frame Creation Patterns

### Basic Frame with Background
```lua
local frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(200, 100)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
```

### StatusBar (Health/Power)
```lua
local healthBar = CreateFrame("StatusBar", nil, frame)
healthBar:SetSize(180, 20)
healthBar:SetPoint("CENTER", frame, "CENTER", 0, 0)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetStatusBarColor(0.1, 0.8, 0.1)
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(75)
```

### Secure Unit Frame
```lua
-- For clickable unit frames that work in combat
local unitFrame = CreateFrame("Button", "MyUnitFrame", UIParent, 
    "SecureUnitButtonTemplate, PingableUnitFrameTemplate")
unitFrame:SetSize(200, 50)
unitFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
unitFrame:SetAttribute("unit", "player")
unitFrame:RegisterForClicks("AnyUp")
```

---

## Action Bar Implementation

### Secure Action Button
```lua
-- ⚠️ CRITICAL: ActionButton_UpdateAction() DOES NOT EXIST!
-- Create action button with ONLY SecureActionButtonTemplate
local button = CreateFrame("Button", "MyActionButton1", UIParent, 
    "SecureActionButtonTemplate")
button:SetSize(40, 40)
button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

-- Configure as action button
button:SetAttribute("type", "action")
button:SetAttribute("action", 1)

-- Visual setup
button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")

-- Create icon texture
button.icon = button:CreateTexture(nil, "BACKGROUND")
button.icon:SetAllPoints()

-- Manual update using REAL API functions
local texture = GetActionTexture(1)
if texture then
    button.icon:SetTexture(texture)
end
```

### Action Bar Container
```lua
local bar = CreateFrame("Frame", "MyActionBar", UIParent)
bar:SetSize(480, 40)
bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)

-- Create 12 buttons
for i = 1, 12 do
    local button = CreateFrame("Button", "MyActionButton"..i, bar, 
        "SecureActionButtonTemplate")
    button:SetSize(38, 38)
    
    if i == 1 then
        button:SetPoint("LEFT", bar, "LEFT", 2, 0)
    else
        button:SetPoint("LEFT", _G["MyActionButton"..(i-1)], "RIGHT", 2, 0)
    end
    
    -- Configure for actions
    button:SetAttribute("type", "action")
    button:SetAttribute("action", i)
    
    -- Create visuals
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints()
    
    -- Manual update with REAL functions
    local texture = GetActionTexture(i)
    if texture then
        button.icon:SetTexture(texture)
    end
end
```

---

## Event System

### Basic Event Handling
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MyAddon" then
            -- Initialize addon
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Player has logged in
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        -- Handle world entry
    end
end)
```

### Unit Events
```lua
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_MAXHEALTH")

frame:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" or unit == "target" then
        -- Update relevant frames
    end
end)
```

---

## Combat Lockdown Handling

### Safe Secure Frame Updates
```lua
local function UpdateSecureFrame(frame)
    if InCombatLockdown() then
        -- Queue for after combat
        frame.needsUpdate = true
        return
    end
    
    -- Safe to modify
    frame:SetAttribute("action", newAction)
    frame.needsUpdate = false
end

-- Process after combat ends
local combatWatcher = CreateFrame("Frame")
combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
combatWatcher:SetScript("OnEvent", function()
    for _, frame in pairs(mySecureFrames) do
        if frame.needsUpdate then
            UpdateSecureFrame(frame)
        end
    end
end)
```

---

## Slash Commands

### Working Registration Pattern
```lua
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
SlashCmdList["MYADDON"] = function(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "show" then
        MyAddonFrame:Show()
    elseif cmd == "hide" then
        MyAddonFrame:Hide()
    elseif cmd == "reset" then
        MyAddonFrame:ClearAllPoints()
        MyAddonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        print("|cffCC8010MyAddon|r Commands:")
        print("  /myaddon show - Show the frame")
        print("  /myaddon hide - Hide the frame")
        print("  /myaddon reset - Reset position")
    end
end
```

---

## SavedVariables

### Initialization Pattern
```lua
local defaults = {
    version = 1,
    position = { x = 0, y = 0 },
    scale = 1,
    enabled = true
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyAddon" then
        -- Initialize or load saved variables
        MyAddonDB = MyAddonDB or {}
        
        -- Apply defaults for missing values
        for k, v in pairs(defaults) do
            if MyAddonDB[k] == nil then
                MyAddonDB[k] = v
            end
        end
        
        -- Apply saved settings
        MyAddonFrame:SetScale(MyAddonDB.scale)
        MyAddonFrame:SetPoint("CENTER", UIParent, "CENTER", 
            MyAddonDB.position.x, MyAddonDB.position.y)
            
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "PLAYER_LOGOUT" then
        -- Save current state
        local point, _, _, x, y = MyAddonFrame:GetPoint()
        MyAddonDB.position = { x = x, y = y }
        MyAddonDB.scale = MyAddonFrame:GetScale()
    end
end)
```

---

## TOC File Requirements

```toc
## Interface: 110200
## Title: |cffCC8010MyAddon|r
## Notes: A working addon for WoW 11.2
## Author: YourName
## Version: 1.0.0
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB

# Core files
Core.lua
Frames.lua
Events.lua
SlashCommands.lua
```

---

## Common Libraries and Dependencies

### Using Ace3
```toc
## OptionalDeps: Ace3
## X-Embeds: Ace3

embeds.xml
```

### Using LibStub (if needed)
```lua
local LibStub = _G.LibStub
if LibStub then
    local AceAddon = LibStub("AceAddon-3.0")
    local addon = AceAddon:NewAddon("MyAddon")
end
```

---

## Hiding Default UI Elements

### Hide Blizzard Frames
```lua
-- Player Frame
if PlayerFrame then
    PlayerFrame:UnregisterAllEvents()
    PlayerFrame:Hide()
end

-- Target Frame
if TargetFrame then
    TargetFrame:UnregisterAllEvents()
    TargetFrame:Hide()
end

-- Main Action Bar
if MainMenuBar then
    MainMenuBar:Hide()
end

-- Hide during pet battles
local frame = CreateFrame("Frame", nil, PetBattleFrameHider)
```

---

## Font Strings

### Creating Text
```lua
local text = frame:CreateFontString(nil, "OVERLAY")
text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
text:SetText("Hello World")
text:SetTextColor(1, 1, 1, 1)
```

---

## Textures

### Adding Icons/Images
```lua
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(32, 32)
icon:SetPoint("LEFT", frame, "LEFT", 5, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
```

---

## Timer and Animation

### Using C_Timer
```lua
-- One-time delay
C_Timer.After(2, function()
    print("2 seconds have passed")
end)

-- Repeating timer
local ticker = C_Timer.NewTicker(1, function()
    -- This runs every second
    UpdateSomething()
end)

-- Cancel ticker
ticker:Cancel()
```

---

## Validation Commands

### In-Game Testing
```lua
/run print((_G["MyAddonFrame"] and "Addon loaded") or "Addon not found")
/run MyAddonFrame:SetBackdropColor(1, 0, 0, 1) -- Test backdrop
/fstack -- Frame stack tool to inspect frames
/etrace -- Event trace tool
/api -- Access in-game API documentation
```

---

## Critical Patterns Summary

1. **ALWAYS** use `BackdropTemplate` for frames with backgrounds
2. **ALWAYS** check `InCombatLockdown()` before modifying secure frames
3. **ALWAYS** use `SecureActionButtonTemplate` for action buttons (NOT ActionBarButtonTemplate)
4. **ALWAYS** unregister `ADDON_LOADED` after initialization
5. **NEVER** use ActionButton_UpdateAction() or ActionButton_Update() - THEY DON'T EXIST
6. **NEVER** modify global variables without checking existence first
7. **NEVER** hook secure functions directly (use `hooksecurefunc`)
8. **NEVER** assume old API patterns still work - verify everything
9. **NEVER** trust documentation without testing - even "verified" docs can be wrong

---

## References

- In-game API browser: `/api`
- Frame Stack: `/fstack`
- Event Trace: `/etrace`
- Taint Log: `/console taintLog 1`
- WoWUIDevs Discord Community
- GitHub: Popular addon repositories for reference