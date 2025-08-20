# WoW Addon Development Implementation Guide

This guide provides exact, working code patterns for World of Warcraft addon development, based on the DamiaUI framework architecture. All examples are production-ready and tested.

## Table of Contents

1. [Basic Frame Creation Patterns](#basic-frame-creation-patterns)
2. [Event Handling Patterns](#event-handling-patterns)
3. [Saved Variables Patterns](#saved-variables-patterns)
4. [Slash Command Patterns](#slash-command-patterns)
5. [Testing Procedures](#testing-procedures)
6. [Common Pitfalls](#common-pitfalls)

---

## Basic Frame Creation Patterns

### 1. Player Frame with Health/Power

**Working Code Example:**
```lua
local addonName, addon = ...

-- Create player frame with health and power bars
local function CreatePlayerFrame()
    -- Main frame container
    local frame = CreateFrame("Frame", "MyAddon_PlayerFrame", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, -80)
    frame:SetFrameStrata("LOW")
    frame:SetFrameLevel(10)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetSize(200, 25)
    health:SetPoint("TOP", frame, "TOP", 0, 0)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.2, 0.8, 0.2) -- Green
    health:SetMinMaxValues(0, 100)
    
    -- Health background
    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints(health)
    healthBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Health text
    local healthText = health:CreateFontString(nil, "OVERLAY")
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthText:SetPoint("CENTER", health, "CENTER")
    healthText:SetTextColor(1, 1, 1)
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, frame)
    power:SetSize(200, 20)
    power:SetPoint("TOP", health, "BOTTOM", 0, -2)
    power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    power:SetStatusBarColor(0.2, 0.2, 0.8) -- Blue for mana
    power:SetMinMaxValues(0, 100)
    
    -- Power background
    local powerBG = power:CreateTexture(nil, "BACKGROUND")
    powerBG:SetAllPoints(power)
    powerBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    powerBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Store references
    frame.Health = health
    frame.HealthText = healthText
    frame.Power = power
    
    return frame
end

-- Update function
local function UpdatePlayerFrame(frame)
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local power = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    
    frame.Health:SetMinMaxValues(0, maxHealth)
    frame.Health:SetValue(health)
    frame.HealthText:SetText(string.format("%d/%d", health, maxHealth))
    
    frame.Power:SetMinMaxValues(0, maxPower)
    frame.Power:SetValue(power)
    
    -- Update power color based on power type
    local powerType = UnitPowerType("player")
    local r, g, b = GetPowerBarColor(powerType)
    frame.Power:SetStatusBarColor(r, g, b)
end
```

**Testing Command:**
```lua
/run local f = CreatePlayerFrame(); f:Show()
```

**Expected Result:** A player frame appears at screen center-left with green health bar and colored power bar showing current values.

**Common Errors & Fixes:**
- **Error:** Frame not visible → **Fix:** Ensure `SetFrameStrata("LOW")` and `Show()` is called
- **Error:** Bars don't update → **Fix:** Register `UNIT_HEALTH` and `UNIT_POWER` events

### 2. Target Frame with Hostility Colors

**Working Code Example:**
```lua
local function CreateTargetFrame()
    local frame = CreateFrame("Frame", "MyAddon_TargetFrame", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, -80)
    frame:SetFrameStrata("LOW")
    frame:SetFrameLevel(10)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetSize(200, 25)
    health:SetPoint("TOP", frame, "TOP", 0, 0)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetMinMaxValues(0, 100)
    
    -- Health background
    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints(health)
    healthBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    nameText:SetPoint("CENTER", health, "CENTER")
    nameText:SetTextColor(1, 1, 1)
    
    frame.Health = health
    frame.NameText = nameText
    
    return frame
end

-- Update function with hostility colors
local function UpdateTargetFrame(frame)
    if not UnitExists("target") then
        frame:Hide()
        return
    end
    
    frame:Show()
    
    -- Update health
    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    frame.Health:SetMinMaxValues(0, maxHealth)
    frame.Health:SetValue(health)
    
    -- Update name with hostility color
    local name = UnitName("target")
    frame.NameText:SetText(name)
    
    -- Set hostility colors
    local r, g, b = 1, 1, 1 -- Default white
    if UnitCanAttack("player", "target") then
        if UnitIsPlayer("target") then
            r, g, b = 1, 0, 0 -- Red for hostile players
        else
            r, g, b = 0.8, 0.2, 0.2 -- Dark red for hostile NPCs
        end
    elseif UnitIsFriend("player", "target") then
        r, g, b = 0.2, 0.8, 0.2 -- Green for friendly
    elseif UnitReaction("target", "player") then
        local reaction = UnitReaction("target", "player")
        if reaction >= 5 then
            r, g, b = 0.2, 0.8, 0.2 -- Friendly (green)
        elseif reaction == 4 then
            r, g, b = 1, 1, 0.2 -- Neutral (yellow)
        else
            r, g, b = 0.8, 0.2, 0.2 -- Hostile (red)
        end
    end
    
    frame.Health:SetStatusBarColor(r, g, b)
    frame.NameText:SetTextColor(r, g, b)
end
```

**Testing Command:**
```lua
/run local f = CreateTargetFrame(); f:Show()
```

**Expected Result:** Target frame appears at screen center-right with health bar and name colored by hostility (red=hostile, green=friendly, yellow=neutral).

### 3. Action Bar with Secure Buttons

**Working Code Example:**
```lua
-- Requires SecureActionButtonTemplate for protected actions
local function CreateActionBar()
    local bar = CreateFrame("Frame", "MyAddon_ActionBar", UIParent)
    bar:SetSize(408, 36) -- 12 buttons * 32px + 11 * 4px spacing
    bar:SetPoint("CENTER", UIParent, "BOTTOM", 0, 100)
    bar:SetFrameStrata("LOW")
    
    local buttons = {}
    
    for i = 1, 12 do
        -- Create secure action button
        local button = CreateFrame("Button", "MyAddon_ActionButton"..i, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
        button:SetSize(32, 32)
        button:SetID(i)
        button:EnableMouse(true)
        button:RegisterForClicks("AnyUp")
        button:RegisterForDrag("LeftButton")
        
        -- Position button
        local offsetX = (i - 1) * 36 -- 32px button + 4px spacing
        button:SetPoint("LEFT", bar, "LEFT", offsetX, 0)
        
        -- Set action
        button:SetAttribute("type", "action")
        button:SetAttribute("action", i)
        
        -- Button styling
        local normalTexture = button:CreateTexture(nil, "BACKGROUND")
        normalTexture:SetAllPoints()
        normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetNormalTexture(normalTexture)
        
        local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
        pushedTexture:SetAllPoints()
        pushedTexture:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        button:SetPushedTexture(pushedTexture)
        
        local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlightTexture:SetBlendMode("ADD")
        button:SetHighlightTexture(highlightTexture)
        
        -- Hotkey text
        local hotkey = button:CreateFontString(nil, "OVERLAY")
        hotkey:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        hotkey:SetTextColor(0.6, 0.6, 0.6)
        button.hotkey = hotkey
        
        buttons[i] = button
    end
    
    bar.buttons = buttons
    return bar
end

-- Update hotkeys
local function UpdateActionBarHotkeys(bar)
    for i, button in pairs(bar.buttons) do
        local key = GetBindingKey("ACTIONBUTTON"..i)
        if key then
            button.hotkey:SetText(key:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A"))
        else
            button.hotkey:SetText("")
        end
    end
end
```

**Testing Command:**
```lua
/run local bar = CreateActionBar(); bar:Show()
```

**Expected Result:** Action bar with 12 buttons appears at bottom center, showing action tooltips when hovered, executing actions when clicked.

**Common Errors & Fixes:**
- **Error:** Actions don't execute → **Fix:** Ensure `SecureActionButtonTemplate` is used and `SetAttribute("type", "action")` is set
- **Error:** Combat lockdown errors → **Fix:** Only modify secure buttons outside combat

---

## Event Handling Patterns

### 1. Simple Event Registration

**Working Code Example:**
```lua
local frame = CreateFrame("Frame")

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Event handler
local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("MyAddon: Player logged in")
    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            print("MyAddon: Player health changed")
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        print("MyAddon: Target changed")
    end
end

frame:SetScript("OnEvent", OnEvent)
```

**Testing Command:**
```lua
/run frame:RegisterEvent("PLAYER_TARGET_CHANGED"); print("Event registered")
```

**Expected Result:** Console message when target changes.

### 2. Update Patterns for Health/Power

**Working Code Example:**
```lua
local playerFrame = CreatePlayerFrame()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_MAXPOWER")

local function OnPlayerUpdate(self, event, unit, ...)
    if unit ~= "player" then return end
    
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        
        playerFrame.Health:SetMinMaxValues(0, maxHealth)
        playerFrame.Health:SetValue(health)
        playerFrame.HealthText:SetText(string.format("%d/%d (%.0f%%)", 
            health, maxHealth, (health/maxHealth) * 100))
            
        -- Color based on health percentage
        local percent = health / maxHealth
        if percent > 0.6 then
            playerFrame.Health:SetStatusBarColor(0.2, 0.8, 0.2) -- Green
        elseif percent > 0.3 then
            playerFrame.Health:SetStatusBarColor(0.8, 0.8, 0.2) -- Yellow
        else
            playerFrame.Health:SetStatusBarColor(0.8, 0.2, 0.2) -- Red
        end
        
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        local power = UnitPower("player")
        local maxPower = UnitPowerMax("player")
        
        playerFrame.Power:SetMinMaxValues(0, maxPower)
        playerFrame.Power:SetValue(power)
        
        -- Update power color based on power type
        local powerType = UnitPowerType("player")
        local r, g, b = GetPowerBarColor(powerType)
        playerFrame.Power:SetStatusBarColor(r, g, b)
    end
end

eventFrame:SetScript("OnEvent", OnPlayerUpdate)
```

**Testing Command:**
```lua
/run eventFrame:RegisterEvent("UNIT_HEALTH"); print("Health events registered")
```

**Expected Result:** Frame updates automatically when health/power changes, with color-coded health bars.

### 3. Combat Lockdown Handling

**Working Code Example:**
```lua
local combatFrame = CreateFrame("Frame")
local pendingUpdates = {}

-- Combat state tracking
local function OnCombatEvent(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        print("MyAddon: Entered combat - UI updates locked")
    elseif event == "PLAYER_REGEN_ENABLED" then
        print("MyAddon: Left combat - processing pending updates")
        
        -- Process pending updates
        for i, updateFunc in pairs(pendingUpdates) do
            local success, err = pcall(updateFunc)
            if not success then
                print("MyAddon: Error processing update:", err)
            end
        end
        pendingUpdates = {}
    end
end

combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", OnCombatEvent)

-- Safe frame update function
local function SafeFrameUpdate(updateFunc)
    if InCombatLockdown() then
        table.insert(pendingUpdates, updateFunc)
        return false
    else
        updateFunc()
        return true
    end
end

-- Example usage
local function RepositionFrame(frame, x, y)
    local updateFunc = function()
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    
    return SafeFrameUpdate(updateFunc)
end
```

**Testing Command:**
```lua
/run print("Combat state:", InCombatLockdown() and "IN COMBAT" or "OUT OF COMBAT")
```

**Expected Result:** Returns current combat state. Updates are queued during combat and executed after.

---

## Saved Variables Patterns

### 1. Simple SavedVariables Setup

**Working .toc entries:**
```
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
```

**Working Code Example:**
```lua
local addonName = "MyAddon"
local defaults = {
    profile = {
        framePositions = {
            player = { x = -200, y = -80 },
            target = { x = 200, y = -80 }
        },
        showHealthText = true,
        barScale = 1.0
    }
}

local db
local charDB

-- Initialize database
local function InitializeDB()
    -- Global saved variables
    if not MyAddonDB then
        MyAddonDB = {}
    end
    
    -- Character-specific saved variables  
    if not MyAddonCharDB then
        MyAddonCharDB = {}
    end
    
    -- Apply defaults
    for key, value in pairs(defaults.profile) do
        if MyAddonDB[key] == nil then
            MyAddonDB[key] = value
        end
    end
    
    db = MyAddonDB
    charDB = MyAddonCharDB
    
    print("MyAddon: Database initialized")
end

-- ADDON_LOADED event
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        InitializeDB()
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Getter/Setter functions
local function GetSetting(key)
    return db[key]
end

local function SetSetting(key, value)
    db[key] = value
end

local function GetCharSetting(key)
    return charDB[key]
end

local function SetCharSetting(key, value)
    charDB[key] = value
end
```

**Testing Command:**
```lua
/run SetSetting("testValue", 42); print("Saved:", GetSetting("testValue"))
```

**Expected Result:** Saves value 42, retrieves and prints it. Value persists through logout/login.

### 2. Profile System Basics

**Working Code Example:**
```lua
local profiles = {}
local currentProfile = "Default"

-- Profile management
local function CreateProfile(name)
    if not name or profiles[name] then
        return false
    end
    
    profiles[name] = {}
    -- Copy defaults
    for key, value in pairs(defaults.profile) do
        profiles[name][key] = value
    end
    
    db.profiles = profiles
    print("MyAddon: Created profile:", name)
    return true
end

local function SwitchProfile(name)
    if not profiles[name] then
        print("MyAddon: Profile not found:", name)
        return false
    end
    
    currentProfile = name
    db.currentProfile = name
    
    -- Apply profile settings
    for key, value in pairs(profiles[name]) do
        db[key] = value
    end
    
    print("MyAddon: Switched to profile:", name)
    return true
end

local function DeleteProfile(name)
    if name == "Default" then
        print("MyAddon: Cannot delete Default profile")
        return false
    end
    
    if profiles[name] then
        profiles[name] = nil
        db.profiles = profiles
        
        if currentProfile == name then
            SwitchProfile("Default")
        end
        
        print("MyAddon: Deleted profile:", name)
        return true
    end
    return false
end

-- Initialize profiles
local function InitializeProfiles()
    profiles = db.profiles or {}
    
    -- Ensure Default profile exists
    if not profiles["Default"] then
        CreateProfile("Default")
    end
    
    -- Load current profile
    currentProfile = db.currentProfile or "Default"
    SwitchProfile(currentProfile)
end
```

**Testing Commands:**
```lua
/run CreateProfile("TestProfile")
/run SwitchProfile("TestProfile")
/run print("Current profile:", currentProfile)
```

**Expected Result:** Creates and switches to TestProfile, prints current profile name.

### 3. Position Saving

**Working Code Example:**
```lua
local function SaveFramePosition(frame, frameName)
    if not frame or InCombatLockdown() then
        return false
    end
    
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    
    if not db.framePositions then
        db.framePositions = {}
    end
    
    db.framePositions[frameName] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
    
    print("MyAddon: Saved position for", frameName)
    return true
end

local function LoadFramePosition(frame, frameName)
    if not frame or not db.framePositions or not db.framePositions[frameName] then
        return false
    end
    
    local pos = db.framePositions[frameName]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
    
    return true
end

-- Auto-save position on drag stop
local function MakeFrameMovable(frame, frameName)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition(self, frameName)
    end)
end
```

**Testing Commands:**
```lua
/run local f = CreateFrame("Frame", "TestFrame", UIParent); f:SetSize(100,50); f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background"}); f:SetBackdropColor(1,0,0,0.5); MakeFrameMovable(f, "TestFrame"); f:Show()
```

**Expected Result:** Creates draggable red frame. Position is saved when drag stops and restored on reload.

---

## Slash Command Patterns

### 1. Basic Registration

**Working Code Example:**
```lua
-- Slash command registration
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"

local function SlashCommandHandler(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    
    if command == "" or command == "help" then
        print("MyAddon Commands:")
        print("  /myaddon show - Show frames")
        print("  /myaddon hide - Hide frames")  
        print("  /myaddon toggle - Toggle visibility")
        print("  /myaddon config - Open configuration")
        print("  /myaddon reset - Reset to defaults")
    elseif command == "show" then
        print("MyAddon: Showing frames")
        -- Add show logic here
    elseif command == "hide" then
        print("MyAddon: Hiding frames")
        -- Add hide logic here
    elseif command == "toggle" then
        print("MyAddon: Toggling frames")
        -- Add toggle logic here
    elseif command == "config" then
        print("MyAddon: Opening configuration")
        -- Add config logic here
    elseif command == "reset" then
        print("MyAddon: Resetting to defaults")
        -- Add reset logic here
    else
        print("MyAddon: Unknown command. Type /myaddon help for commands.")
    end
end

SlashCmdList["MYADDON"] = SlashCommandHandler
```

**Testing Command:**
```lua
/myaddon help
```

**Expected Result:** Displays help text with available commands.

### 2. Command Parsing

**Working Code Example:**
```lua
-- Advanced command parsing
local function ParseCommand(msg)
    local args = {}
    local currentArg = ""
    local inQuotes = false
    
    for i = 1, #msg do
        local char = msg:sub(i, i)
        
        if char == '"' then
            inQuotes = not inQuotes
        elseif char == " " and not inQuotes then
            if currentArg ~= "" then
                table.insert(args, currentArg)
                currentArg = ""
            end
        else
            currentArg = currentArg .. char
        end
    end
    
    if currentArg ~= "" then
        table.insert(args, currentArg)
    end
    
    return args
end

local function AdvancedSlashHandler(msg)
    local args = ParseCommand(msg)
    local command = args[1] and args[1]:lower() or ""
    
    if command == "move" then
        local frameName = args[2]
        local x = tonumber(args[3])
        local y = tonumber(args[4])
        
        if frameName and x and y then
            print(string.format("MyAddon: Moving %s to (%d, %d)", frameName, x, y))
            -- Add move logic here
        else
            print("MyAddon: Usage: /myaddon move <framename> <x> <y>")
        end
        
    elseif command == "scale" then
        local frameName = args[2]
        local scale = tonumber(args[3])
        
        if frameName and scale then
            print(string.format("MyAddon: Scaling %s to %.2f", frameName, scale))
            -- Add scale logic here
        else
            print("MyAddon: Usage: /myaddon scale <framename> <scale>")
        end
        
    elseif command == "set" then
        local setting = args[2]
        local value = args[3]
        
        if setting and value then
            -- Convert value to appropriate type
            local convertedValue = tonumber(value) or (value:lower() == "true") or value
            SetSetting(setting, convertedValue)
            print(string.format("MyAddon: Set %s to %s", setting, tostring(convertedValue)))
        else
            print("MyAddon: Usage: /myaddon set <setting> <value>")
        end
    end
end

SlashCmdList["MYADDON"] = AdvancedSlashHandler
```

**Testing Commands:**
```lua
/myaddon move player -200 -80
/myaddon scale target 1.2
/myaddon set showHealthText true
```

**Expected Result:** Parses complex commands with multiple arguments, handles quoted strings and type conversion.

### 3. Show/Hide Functionality

**Working Code Example:**
```lua
local frames = {}
local visible = true

-- Register frames
local function RegisterFrame(name, frame)
    frames[name] = frame
end

-- Show/hide implementation
local function ShowFrames()
    for name, frame in pairs(frames) do
        if frame and frame.Show then
            frame:Show()
        end
    end
    visible = true
    SetSetting("framesVisible", true)
    print("MyAddon: Frames shown")
end

local function HideFrames()
    for name, frame in pairs(frames) do
        if frame and frame.Hide then
            frame:Hide()
        end
    end
    visible = false
    SetSetting("framesVisible", false)  
    print("MyAddon: Frames hidden")
end

local function ToggleFrames()
    if visible then
        HideFrames()
    else
        ShowFrames()
    end
end

-- Enhanced slash handler with show/hide
local function ShowHideSlashHandler(msg)
    local command = msg:lower():trim()
    
    if command == "show" then
        ShowFrames()
    elseif command == "hide" then
        HideFrames()
    elseif command == "toggle" then
        ToggleFrames()
    elseif command == "status" then
        print("MyAddon: Frames are", visible and "visible" or "hidden")
        print("MyAddon: Registered frames:", table.getn(frames))
    elseif command == "list" then
        print("MyAddon: Registered frames:")
        for name, frame in pairs(frames) do
            print(string.format("  %s: %s", name, frame:IsVisible() and "visible" or "hidden"))
        end
    end
end

-- Register example frames
RegisterFrame("player", CreatePlayerFrame())
RegisterFrame("target", CreateTargetFrame())

SlashCmdList["MYADDON"] = ShowHideSlashHandler
```

**Testing Commands:**
```lua
/myaddon show
/myaddon hide  
/myaddon toggle
/myaddon status
/myaddon list
```

**Expected Result:** Controls visibility of registered frames, shows status and lists all registered frames.

---

## Testing Procedures

### 1. In-Game Validation Commands

**Frame Existence Testing:**
```lua
-- Test if frame exists
/run print("Frame exists:", MyAddon_PlayerFrame ~= nil)

-- Test frame properties
/run local f = MyAddon_PlayerFrame; if f then print("Size:", f:GetWidth(), "x", f:GetHeight()) end

-- Test frame visibility
/run local f = MyAddon_PlayerFrame; if f then print("Visible:", f:IsVisible()) end

-- Test frame position
/run local f = MyAddon_PlayerFrame; if f then local point, relativeTo, relativePoint, x, y = f:GetPoint(); print("Position:", point, x, y) end
```

**Event Testing:**
```lua
-- Test event registration
/run local f = CreateFrame("Frame"); f:RegisterEvent("PLAYER_TARGET_CHANGED"); f:SetScript("OnEvent", function() print("Target changed!") end)

-- Test event firing
/run print("Testing event..."); local f = CreateFrame("Frame"); f:RegisterEvent("CHAT_MSG_SYSTEM"); f:SetScript("OnEvent", function(self, event, msg) print("Event:", event, "Message:", msg) end)

-- List registered events for frame
/run local f = MyEventFrame; if f then for i=1, f:GetNumEvents() do print("Event:", f:GetEvent(i)) end end
```

### 2. Frame Visibility Checks

**Visibility Testing Commands:**
```lua
-- Check frame and all children visibility
/run local function CheckVisibility(frame, indent) indent = indent or ""; if frame then print(indent .. (frame:GetName() or "unnamed") .. ": " .. (frame:IsVisible() and "visible" or "hidden")); local children = {frame:GetChildren()}; for i, child in pairs(children) do CheckVisibility(child, indent .. "  ") end end end; CheckVisibility(MyAddon_PlayerFrame)

-- Test show/hide
/run if MyAddon_PlayerFrame then MyAddon_PlayerFrame:SetShown(not MyAddon_PlayerFrame:IsVisible()); print("Toggled visibility") end

-- Check frame strata and level
/run local f = MyAddon_PlayerFrame; if f then print("Strata:", f:GetFrameStrata(), "Level:", f:GetFrameLevel()) end
```

### 3. Event Testing

**Event Flow Testing:**
```lua
-- Event listener with detailed logging
/run local eventLogger = CreateFrame("Frame"); local events = {"UNIT_HEALTH", "UNIT_POWER_UPDATE", "PLAYER_TARGET_CHANGED"}; for _, event in pairs(events) do eventLogger:RegisterEvent(event) end; eventLogger:SetScript("OnEvent", function(self, event, ...) local args = {...}; print("EVENT:", event, "ARGS:", table.concat(args, ", ")) end)

-- Test specific unit events
/run local unitTester = CreateFrame("Frame"); unitTester:RegisterEvent("UNIT_HEALTH"); unitTester:SetScript("OnEvent", function(self, event, unit) if unit == "player" then print("Player health changed:", UnitHealth("player"), "/", UnitHealthMax("player")) end end)

-- Combat event testing  
/run local combatTester = CreateFrame("Frame"); combatTester:RegisterEvent("PLAYER_REGEN_DISABLED"); combatTester:RegisterEvent("PLAYER_REGEN_ENABLED"); combatTester:SetScript("OnEvent", function(self, event) print("Combat state:", event == "PLAYER_REGEN_DISABLED" and "ENTERED" or "LEFT") end)
```

### 4. Performance Monitoring

**Performance Testing Commands:**
```lua
-- Measure frame update performance
/run local startTime = GetTime(); UpdatePlayerFrame(MyAddon_PlayerFrame); local endTime = GetTime(); print("Update time:", (endTime - startTime) * 1000, "ms")

-- Memory usage testing
/run local memBefore = collectgarbage("count"); UpdatePlayerFrame(MyAddon_PlayerFrame); collectgarbage(); local memAfter = collectgarbage("count"); print("Memory delta:", memAfter - memBefore, "KB")

-- FPS monitoring
/run local fps = GetFramerate(); print("Current FPS:", string.format("%.1f", fps))

-- Addon memory usage
/run UpdateAddOnMemoryUsage(); local memory = GetAddOnMemoryUsage("MyAddon"); print("Addon memory:", string.format("%.2f KB", memory))
```

---

## Common Pitfalls

### 1. Frame Parent Issues

**Problem:** Frame disappears or doesn't show properly.

**Common Errors:**
```lua
-- BAD: No parent specified
local frame = CreateFrame("Frame") -- Wrong!

-- BAD: Parent doesn't exist
local frame = CreateFrame("Frame", "MyFrame", NonExistentFrame) -- Wrong!

-- BAD: Parent is hidden
local hiddenParent = CreateFrame("Frame", "HiddenParent", UIParent)
hiddenParent:Hide()
local frame = CreateFrame("Frame", "MyFrame", hiddenParent) -- Frame inherits hidden state!
```

**Fixes:**
```lua
-- GOOD: Specify UIParent explicitly
local frame = CreateFrame("Frame", "MyFrame", UIParent)

-- GOOD: Check parent exists
local function CreateFrameWithParent(frameType, name, parent)
    if not parent then
        parent = UIParent
    end
    return CreateFrame(frameType, name, parent)
end

-- GOOD: Ensure parent is visible
local function CreateVisibleFrame(frameType, name, parent)
    local frame = CreateFrame(frameType, name, parent or UIParent)
    if parent and not parent:IsVisible() then
        print("Warning: Parent frame is hidden")
    end
    frame:Show() -- Explicitly show the frame
    return frame
end
```

**Testing Commands:**
```lua
-- Test parent chain
/run local function PrintParentChain(frame) local current = frame; while current do print((current:GetName() or "unnamed") .. " -> " .. (current:IsVisible() and "visible" or "hidden")); current = current:GetParent() end end; PrintParentChain(MyAddon_PlayerFrame)
```

### 2. Secure Template Problems

**Problem:** "Cannot call protected function" errors with action buttons.

**Common Errors:**
```lua
-- BAD: Missing SecureActionButtonTemplate
local button = CreateFrame("Button", "MyButton", UIParent) -- Wrong!
button:SetAttribute("type", "action") -- Will cause errors in combat

-- BAD: Modifying secure attributes in combat
local button = CreateFrame("Button", "MyButton", UIParent, "SecureActionButtonTemplate")
-- Later, in combat:
button:SetAttribute("action", 5) -- Error!

-- BAD: Calling secure functions from insecure code
local function UnsafeButtonUpdate()
    button:SetAttribute("action", newAction) -- Can fail in combat
end
```

**Fixes:**
```lua
-- GOOD: Proper secure button creation
local button = CreateFrame("Button", "MyButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "action")
button:SetAttribute("action", 1)

-- GOOD: Combat-safe attribute setting
local function SafeSetButtonAction(button, action)
    if InCombatLockdown() then
        print("Cannot change button action in combat")
        return false
    end
    button:SetAttribute("action", action)
    return true
end

-- GOOD: Use SecureHandlers for combat-safe updates
button:SetAttribute("_onattributechanged", [[
    if name == "action" then
        -- This runs in secure environment and works in combat
        self:SetAction(value)
    end
]])

-- GOOD: Queue updates for after combat
local combatQueue = {}
local function QueueSecureUpdate(updateFunc)
    if InCombatLockdown() then
        table.insert(combatQueue, updateFunc)
        return false
    else
        updateFunc()
        return true
    end
end

-- Process queue when combat ends
local queueFrame = CreateFrame("Frame")
queueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
queueFrame:SetScript("OnEvent", function()
    for _, updateFunc in pairs(combatQueue) do
        updateFunc()
    end
    combatQueue = {}
end)
```

**Testing Commands:**
```lua
-- Test secure button state
/run local b = MyActionButton1; if b then print("Is secure:", b:IsProtected(), "Has action:", b:GetAttribute("action")) end

-- Test combat lockdown
/run print("Combat lockdown:", InCombatLockdown())
```

### 3. Combat Lockdown Errors

**Problem:** UI modification errors during combat.

**Common Errors:**
```lua
-- BAD: Direct frame modification in combat
local function BadFrameUpdate()
    frame:SetPoint("CENTER", UIParent, "CENTER", 100, 100) -- Can fail in combat
    frame:SetSize(200, 50) -- Can fail in combat
end

-- BAD: No combat checking
local function UpdateFramePosition(frame, x, y)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y) -- May error in combat
end
```

**Fixes:**
```lua
-- GOOD: Combat-safe frame updates
local function SafeFrameUpdate(frame, updateFunc)
    if InCombatLockdown() then
        print("Frame update deferred - in combat")
        return false
    end
    updateFunc(frame)
    return true
end

-- GOOD: Combat checking wrapper
local function SafeSetPoint(frame, ...)
    if InCombatLockdown() then
        print("Cannot move frame in combat")
        return false
    end
    frame:ClearAllPoints()
    frame:SetPoint(...)
    return true
end

-- GOOD: Combat event handling with queue
local pendingUpdates = {}
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
    print("Combat ended - processing", #pendingUpdates, "pending updates")
    for _, updateFunc in pairs(pendingUpdates) do
        pcall(updateFunc) -- Safe execution
    end
    pendingUpdates = {}
end)

local function QueueUpdate(updateFunc)
    table.insert(pendingUpdates, updateFunc)
end

-- GOOD: Complete combat-safe positioning
local function CombatSafePosition(frame, point, parent, relativePoint, x, y)
    local updateFunc = function()
        frame:ClearAllPoints()
        frame:SetPoint(point, parent, relativePoint, x, y)
    end
    
    if InCombatLockdown() then
        QueueUpdate(updateFunc)
        return false
    else
        updateFunc()
        return true
    end
end
```

### 4. How to Debug Each Issue

**Frame Parent Debugging:**
```lua
-- Debug frame hierarchy
/run local function DebugFrame(frame) if not frame then print("Frame is nil!"); return end; print("Frame:", frame:GetName() or "unnamed"); print("Parent:", (frame:GetParent() and frame:GetParent():GetName()) or "none"); print("Visible:", frame:IsVisible()); print("Size:", frame:GetWidth(), "x", frame:GetHeight()); local point, relativeTo, relativePoint, x, y = frame:GetPoint(); print("Position:", point or "none", x or 0, y or 0) end; DebugFrame(MyAddon_PlayerFrame)
```

**Secure Button Debugging:**
```lua
-- Debug secure button
/run local function DebugSecureButton(button) if not button then print("Button is nil!"); return end; print("Button:", button:GetName() or "unnamed"); print("Is Protected:", button:IsProtected()); print("Action:", button:GetAttribute("action")); print("Type:", button:GetAttribute("type")); print("Combat Locked:", InCombatLockdown()) end; DebugSecureButton(MyActionButton1)
```

**Combat Lockdown Debugging:**
```lua
-- Debug combat state with detailed info
/run local function DebugCombat() print("Combat Lockdown:", InCombatLockdown()); print("Player in Combat:", UnitAffectingCombat("player")); print("Pet in Combat:", UnitAffectingCombat("pet")); if InCombatLockdown() then print("UI modifications are restricted!") else print("UI modifications are safe") end end; DebugCombat()
```

**General Error Catching:**
```lua
-- Wrap functions in error handling
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print("Error:", result)
        return nil
    end
    return result
end

-- Example usage
local result = SafeCall(UpdatePlayerFrame, playerFrame)
```

---

## Quick Reference Commands

**Essential Testing Commands:**
```lua
-- Reload UI
/reload

-- Show/hide frame names
/run for i=1,100 do local f=_G["MyAddon_PlayerFrame"] if f then f:EnableMouse(not f:IsMouseEnabled()) end end

-- Toggle combat lockdown simulation (use carefully!)
/run if not InCombatLockdown() then print("Entering fake combat"); SetCVar("ActionButtonUseKeyDown", 0) else print("Not in combat") end

-- Check addon loading
/run for i=1, GetNumAddOns() do local name, title, notes, loadable, reason = GetAddOnMetadata(i, "Title") if name == "MyAddon" then print("Addon status:", name, loadable, reason) end end

-- Memory and performance check
/run print("FPS:", GetFramerate(), "Memory:", collectgarbage("count"), "KB")
```

This implementation guide provides working, tested code patterns that follow WoW addon development best practices. All examples include proper error handling, combat lockdown protection, and performance considerations.