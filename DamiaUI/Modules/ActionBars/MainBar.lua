--[[
===============================================================================
Damia UI - Main Action Bar Implementation
===============================================================================
Specialized module for the main action bar with centered bottom positioning.
Handles 12 buttons with precise Damia UI centered layout philosophy.

Features:
- Centered at bottom of screen (0, 100) from bottom center
- 12 action buttons with proper spacing
- Aurora styling integration
- Keybind and cooldown displays
- Combat state handling
- Dynamic scaling and positioning

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local string = string
local strformat = string.format
local CreateFrame = CreateFrame
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GetActionInfo = GetActionInfo
local HasAction = HasAction
local IsUsableAction = IsUsableAction
local GetActionCooldown = GetActionCooldown
local GetActionCount = GetActionCount
local GetBindingKey = GetBindingKey
local UIFrameFadeIn = UIFrameFadeIn

-- Compatibility layer for modern API support
local Compatibility = DamiaUI.Compatibility
local UIFrameFadeOut = UIFrameFadeOut

-- LibActionButton reference
local LAB = LibStub and LibStub:GetLibrary("LibActionButton-1.0", true)

-- Compatibility layer
local Compatibility = DamiaUI.Compatibility
local CombatLockdown = DamiaUI.CombatLockdown

-- Create MainBar module
local MainBar = {
    bar = nil,
    buttons = {},
    initialized = false,
    config = nil,
}

-- Constants for main bar
local MAIN_BAR_BUTTON_COUNT = 12
local MAIN_BAR_DEFAULT_SIZE = 36
local MAIN_BAR_SPACING = 4
local MAIN_BAR_POSITION = { x = 0, y = 100 } -- Centered at bottom with 100px offset

-- Button styling constants (Aurora theme)
local BUTTON_STYLE = {
    backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    },
    normalColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    pushedColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    highlightColor = { r = 0.8, g = 0.5, b = 0.1, a = 0.4 },
    checkedColor = { r = 0.6, g = 0.4, b = 0.1, a = 1.0 },
    borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
}

--[[
===============================================================================
MAIN BAR CREATION AND SETUP
===============================================================================
--]]

function MainBar:Initialize(parentModule)
    if self.initialized then
        return true
    end
    
    self.parentModule = parentModule
    self.config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.main") or DamiaUI.Defaults.profile.actionbars.main
    
    if not self.config or not self.config.enabled then
        DamiaUI.Engine:LogInfo("Main action bar disabled in configuration")
        return false
    end
    
    if not LAB then
        DamiaUI.Engine:LogError("LibActionButton-1.0 not available for main bar")
        return false
    end
    
    -- Create the main bar
    if not self:CreateMainBar() then
        return false
    end
    
    -- Create action buttons
    if not self:CreateActionButtons() then
        return false
    end
    
    -- Apply styling
    self:ApplyAuroraStyling()
    
    -- Position bar according to centered layout
    self:PositionBar()
    
    self.initialized = true
    DamiaUI.Engine:LogInfo("Main action bar initialized with %d buttons", MAIN_BAR_BUTTON_COUNT)
    
    return true
end

function MainBar:CreateMainBar()
    -- Calculate bar dimensions
    local buttonSize = self.config.buttonSize or MAIN_BAR_DEFAULT_SIZE
    local spacing = self.config.buttonSpacing or MAIN_BAR_SPACING
    local buttonCount = self.config.buttonCount or MAIN_BAR_BUTTON_COUNT
    
    local barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
    local barHeight = buttonSize
    
    -- Create main bar frame
    self.bar = CreateFrame("Frame", "DamiaUI_MainActionBar", UIParent)
    self.bar:SetSize(barWidth, barHeight)
    self.bar:SetFrameStrata("LOW")
    self.bar:SetFrameLevel(10)
    
    -- Transparent background; avoid SetBackdrop to prevent BackdropTemplate issues on Retail
    -- If a background is needed later, use a texture layer
    
    -- Store configuration reference
    self.bar.damiaConfig = self.config
    
    DamiaUI.Engine:LogDebug("Main action bar frame created (%dx%d)", barWidth, barHeight)
    return true
end

function MainBar:CreateActionButtons()
    local buttonSize = self.config.buttonSize or MAIN_BAR_DEFAULT_SIZE
    local spacing = self.config.buttonSpacing or MAIN_BAR_SPACING
    local buttonCount = self.config.buttonCount or MAIN_BAR_BUTTON_COUNT
    
    self.buttons = {}
    
    for i = 1, buttonCount do
        local button = self:CreateSingleButton(i)
        if button then
            self.buttons[i] = button
            
            -- Position button within bar
            local offsetX = (i - 1) * (buttonSize + spacing)
            button:SetPoint("LEFT", self.bar, "LEFT", offsetX, 0)
            
            -- Store reference in parent module
            if self.parentModule and self.parentModule.buttons then
                self.parentModule.buttons[strformat("DamiaUI_MainButton%d", i)] = button
            end
        else
            DamiaUI.Engine:LogError("Failed to create main action button %d", i)
            return false
        end
    end
    
    DamiaUI.Engine:LogDebug("Created %d main action buttons", #self.buttons)
    return true
end

function MainBar:CreateSingleButton(buttonIndex)
    if not LAB then
        return nil
    end
    
    local buttonName = strformat("DamiaUI_MainButton%d", buttonIndex)
    local buttonSize = self.config.buttonSize or MAIN_BAR_DEFAULT_SIZE
    
    -- Create button using LibActionButton with correct action ID
    local actionID = buttonIndex -- Main bar uses action IDs 1-12
    local button = LAB:CreateButton(actionID, buttonName, self.bar)
    
    if not button then
        DamiaUI.Engine:LogError("LibActionButton failed to create button: %s", buttonName)
        return nil
    end
    
    -- Configure button properties
    button:SetSize(buttonSize, buttonSize)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    
    -- Store configuration and metadata
    button.damiaConfig = self.config
    button.damiaBarType = "main"
    button.damiaIndex = buttonIndex
    button.damiaActionID = actionID
    
    -- Setup button styling
    self:SetupButtonStyling(button)
    
    -- Setup button overlays (keybinds, counts, etc.)
    self:SetupButtonOverlays(button)
    
    return button
end

--[[
===============================================================================
BUTTON STYLING AND VISUALS
===============================================================================
--]]

function MainBar:SetupButtonStyling(button)
    if not button then return end
    
    -- Optional border frame for Aurora styling (uses BackdropTemplate)
    if not button.damiaBorder then
        local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
        border:SetAllPoints(button)
        border:SetBackdrop(BUTTON_STYLE.backdrop)
        border:SetBackdropColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
        border:SetBackdropBorderColor(BUTTON_STYLE.borderColor.r, BUTTON_STYLE.borderColor.g, BUTTON_STYLE.borderColor.b, BUTTON_STYLE.borderColor.a)
        button.damiaBorder = border
    end
    
    -- Configure textures for different states using compatibility layer
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        if Compatibility and Compatibility.SetSolidTexture then
            Compatibility.SetSolidTexture(normalTexture, BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
        else
            normalTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            normalTexture:SetVertexColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
        end
    end
    
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        if Compatibility and Compatibility.SetSolidTexture then
            Compatibility.SetSolidTexture(pushedTexture, BUTTON_STYLE.pushedColor.r, BUTTON_STYLE.pushedColor.g, BUTTON_STYLE.pushedColor.b, BUTTON_STYLE.pushedColor.a)
        else
            pushedTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            pushedTexture:SetVertexColor(BUTTON_STYLE.pushedColor.r, BUTTON_STYLE.pushedColor.g, BUTTON_STYLE.pushedColor.b, BUTTON_STYLE.pushedColor.a)
        end
    end
    
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        if Compatibility and Compatibility.SetSolidTexture then
            Compatibility.SetSolidTexture(highlightTexture, BUTTON_STYLE.highlightColor.r, BUTTON_STYLE.highlightColor.g, BUTTON_STYLE.highlightColor.b, BUTTON_STYLE.highlightColor.a)
        else
            highlightTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlightTexture:SetVertexColor(BUTTON_STYLE.highlightColor.r, BUTTON_STYLE.highlightColor.g, BUTTON_STYLE.highlightColor.b, BUTTON_STYLE.highlightColor.a)
        end
        highlightTexture:SetBlendMode("ADD")
    end
    
    local checkedTexture = button:GetCheckedTexture()
    if checkedTexture then
        if Compatibility and Compatibility.SetSolidTexture then
            Compatibility.SetSolidTexture(checkedTexture, BUTTON_STYLE.checkedColor.r, BUTTON_STYLE.checkedColor.g, BUTTON_STYLE.checkedColor.b, BUTTON_STYLE.checkedColor.a)
        else
            checkedTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            checkedTexture:SetVertexColor(BUTTON_STYLE.checkedColor.r, BUTTON_STYLE.checkedColor.g, BUTTON_STYLE.checkedColor.b, BUTTON_STYLE.checkedColor.a)
        end
    end
end

function MainBar:SetupButtonOverlays(button)
    if not button then return end
    
    -- Keybind text overlay
    if self.config.showKeybinds then
        button.keybindText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.keybindText:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.keybindText:SetTextColor(0.6, 0.6, 0.6, 1)
        button.keybindText:SetJustifyH("LEFT")
        button.keybindText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        self:UpdateKeybindText(button)
    end
    
    -- Stack count text overlay
    button.countText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.countText:SetTextColor(1, 1, 1, 1)
    button.countText:SetJustifyH("RIGHT")
    button.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    -- Cooldown frame
    if self.config.showCooldowns then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
        button.cooldown:SetDrawBling(true)
        button.cooldown:SetDrawEdge(true)
    end
    
    -- Macro name text overlay
    if self.config.showMacroNames then
        button.macroText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.macroText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        button.macroText:SetTextColor(1, 1, 1, 1)
        button.macroText:SetJustifyH("CENTER")
        button.macroText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    end
    
    -- Range indicator (red tint when out of range)
    button.rangeIndicator = button:CreateTexture(nil, "OVERLAY")
    button.rangeIndicator:SetAllPoints(button)
    if Compatibility and Compatibility.SetSolidTexture then
        Compatibility.SetSolidTexture(button.rangeIndicator, 1, 0.1, 0.1, 0)
    else
        button.rangeIndicator:SetTexture("Interface\\Buttons\\WHITE8X8")
        button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0)
    end
    button.rangeIndicator:SetBlendMode("MULTIPLY")
end

function MainBar:ApplyAuroraStyling()
    if not self.bar or not self.buttons then return end
    
    -- Ensure bar remains visually transparent; no SetBackdrop is used
    
    -- Apply styling to all buttons
    for i, button in pairs(self.buttons) do
        if button then
            self:SetupButtonStyling(button)
            self:UpdateButton(button)
        end
    end
    
    DamiaUI.Engine:LogDebug("Aurora styling applied to main action bar")
end

--[[
===============================================================================
POSITIONING AND LAYOUT
===============================================================================
--]]

function MainBar:UpdateBarLayout()
    -- Update button sizes and spacing
    local buttonSize = self.config.buttonSize or MAIN_BAR_DEFAULT_SIZE
    local spacing = self.config.buttonSpacing or MAIN_BAR_SPACING
    local buttonCount = self.config.buttonCount or MAIN_BAR_BUTTON_COUNT
    
    -- Resize bar
    local barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
    self.bar:SetSize(barWidth, buttonSize)
    
    -- Update button positions and sizes
    for i, button in pairs(self.buttons) do
        if button then
            button:SetSize(buttonSize, buttonSize)
            local offsetX = (i - 1) * (buttonSize + spacing)
            button:ClearAllPoints()
            button:SetPoint("LEFT", self.bar, "LEFT", offsetX, 0)
        end
    end
end

function MainBar:PositionBar()
    if not self.bar then return end
    
    -- Use configured position or default centered bottom position
    local posX = self.config.position.x or MAIN_BAR_POSITION.x
    local posY = self.config.position.y or MAIN_BAR_POSITION.y
    local scale = self.config.scale or 1.0
    
    -- Position relative to screen center using Utils (with combat lockdown protection)
    if CombatLockdown then
        if DamiaUI.Utils then
            CombatLockdown:SafeUpdateActionBars(function()
                DamiaUI.Utils:PositionFrame(self.bar, posX, posY, "CENTER")
            end)
        else
            CombatLockdown:SafeSetPoint(self.bar, "CENTER", UIParent, "CENTER", posX, posY)
        end
        CombatLockdown:SafeSetScale(self.bar, scale)
    else
        if not InCombatLockdown() then
            if DamiaUI.Utils then
                DamiaUI.Utils:PositionFrame(self.bar, posX, posY, "CENTER")
            else
                -- Fallback positioning
                self.bar:ClearAllPoints()
                self.bar:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
            end
            self.bar:SetScale(scale)
        else
            DamiaUI.Engine:LogWarning("Main action bar positioning deferred due to combat lockdown")
        end
    end
    
    DamiaUI.Engine:LogDebug("Main action bar positioned at (%d, %d) with scale %.2f", posX, posY, scale)
end

function MainBar:UpdateLayout()
    if not self.bar then
        return false
    end
    
    -- Update configuration
    self.config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.main") or DamiaUI.Defaults.profile.actionbars.main
    
    -- Safe layout update with combat lockdown protection
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            self:PositionBar()
            self:UpdateBarLayout()
        end)
    else
        if not InCombatLockdown() then
            -- Reposition bar
            self:PositionBar()
            
            -- Update button sizes and spacing
            local buttonSize = self.config.buttonSize or MAIN_BAR_DEFAULT_SIZE
            local spacing = self.config.buttonSpacing or MAIN_BAR_SPACING
            local buttonCount = self.config.buttonCount or MAIN_BAR_BUTTON_COUNT
            
            -- Resize bar
            local barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
            self.bar:SetSize(barWidth, buttonSize)
            
            -- Update button positions and sizes
            for i, button in pairs(self.buttons) do
                if button then
                    button:SetSize(buttonSize, buttonSize)
                    local offsetX = (i - 1) * (buttonSize + spacing)
                    button:ClearAllPoints()
                    button:SetPoint("LEFT", self.bar, "LEFT", offsetX, 0)
                end
            end
        else
            DamiaUI.Engine:LogWarning("Main action bar layout update deferred due to combat lockdown")
            return false
        end
    end
    
    DamiaUI.Engine:LogDebug("Main action bar layout updated")
    return true
end

--[[
===============================================================================
BUTTON STATE MANAGEMENT
===============================================================================
--]]

function MainBar:UpdateButton(button)
    if not button or not HasAction(button.damiaActionID) then
        return
    end
    
    -- Update button count
    self:UpdateButtonCount(button)
    
    -- Update button cooldown
    if self.config.showCooldowns and button.cooldown then
        self:UpdateButtonCooldown(button)
    end
    
    -- Update button usability and range
    self:UpdateButtonUsability(button)
    
    -- Update keybind display
    if self.config.showKeybinds and button.keybindText then
        self:UpdateKeybindText(button)
    end
end

function MainBar:UpdateButtonCount(button)
    if not button or not button.countText then return end
    
    local count = GetActionCount(button.damiaActionID)
    
    if count and count > 1 then
        button.countText:SetText(count)
        button.countText:Show()
    else
        button.countText:Hide()
    end
end

function MainBar:UpdateButtonCooldown(button)
    if not button or not button.cooldown then return end
    
    local start, duration, enabled = GetActionCooldown(button.damiaActionID)
    
    if start and duration and duration > 0 and enabled == 1 then
        button.cooldown:SetCooldown(start, duration)
        button.cooldown:Show()
    else
        button.cooldown:Hide()
    end
end

function MainBar:UpdateButtonUsability(button)
    if not button then return end
    
    local isUsable, notEnoughMana = IsUsableAction(button.damiaActionID)
    local inRange = IsActionInRange(button.damiaActionID)
    
    -- Update button color based on usability
    local icon = button.icon or button:GetNormalTexture()
    if icon then
        if not isUsable then
            if notEnoughMana then
                icon:SetVertexColor(0.5, 0.5, 1.0, 1) -- Blue tint for mana issues
            else
                icon:SetVertexColor(0.4, 0.4, 0.4, 1) -- Gray for unusable
            end
        else
            icon:SetVertexColor(1, 1, 1, 1) -- Normal color
        end
    end
    
    -- Update range indicator
    if button.rangeIndicator then
        if inRange == false then
            button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0.3) -- Red overlay for out of range
        else
            button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0) -- Hide range indicator
        end
    end
end

function MainBar:UpdateKeybindText(button)
    if not button or not button.keybindText then return end
    
    local key = GetBindingKey(strformat("ACTIONBUTTON%d", button.damiaIndex))
    
    if key then
        -- Abbreviate common modifier keys
        key = key:gsub("SHIFT%-", "S")
        key = key:gsub("CTRL%-", "C")
        key = key:gsub("ALT%-", "A")
        key = key:gsub("NUMPAD", "N")
        
        button.keybindText:SetText(key)
        button.keybindText:Show()
    else
        button.keybindText:Hide()
    end
end

function MainBar:UpdateAllButtons()
    for i, button in pairs(self.buttons) do
        if button then
            self:UpdateButton(button)
        end
    end
end

--[[
===============================================================================
VISIBILITY AND STATE MANAGEMENT
===============================================================================
--]]

function MainBar:Show()
    if self.bar then
        self.bar:Show()
        return true
    end
    return false
end

function MainBar:Hide()
    if self.bar then
        self.bar:Hide()
        return true
    end
    return false
end

function MainBar:SetAlpha(alpha)
    if self.bar then
        self.bar:SetAlpha(alpha)
        return true
    end
    return false
end

function MainBar:FadeIn(duration)
    if self.bar then
        UIFrameFadeIn(self.bar, duration or 0.2, self.bar:GetAlpha(), 1.0)
        return true
    end
    return false
end

function MainBar:FadeOut(duration, targetAlpha)
    if self.bar then
        UIFrameFadeOut(self.bar, duration or 0.2, self.bar:GetAlpha(), targetAlpha or 0.3)
        return true
    end
    return false
end

function MainBar:HandleCombatStateChange(inCombat)
    if not self.config or not self.config.fadeOnCombat then
        return
    end
    
    if inCombat then
        self:FadeOut(0.2, self.config.fadeAlpha or 0.5)
    else
        self:FadeIn(0.2)
    end
end

--[[
===============================================================================
PUBLIC API
===============================================================================
--]]

function MainBar:IsInitialized()
    return self.initialized
end

function MainBar:GetBar()
    return self.bar
end

function MainBar:GetButton(index)
    return self.buttons[index]
end

function MainBar:GetButtonCount()
    return #self.buttons
end

function MainBar:GetConfig()
    return self.config
end

function MainBar:Cleanup()
    if self.bar then
        self.bar:Hide()
        self.bar:SetParent(nil)
        self.bar = nil
    end
    
    for i, button in pairs(self.buttons) do
        if button then
            button:Hide()
            button:SetParent(nil)
        end
    end
    
    self.buttons = {}
    self.initialized = false
    
    DamiaUI.Engine:LogDebug("Main action bar cleaned up")
end

-- Safe update methods with combat lockdown protection
function MainBar:SafeUpdateLayout()
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            self:UpdateLayout()
        end)
    else
        if not InCombatLockdown() then
            self:UpdateLayout()
        else
            DamiaUI.Engine:LogWarning("Main bar layout update deferred due to combat lockdown")
        end
    end
end

-- Export MainBar module
DamiaUI.MainBar = MainBar