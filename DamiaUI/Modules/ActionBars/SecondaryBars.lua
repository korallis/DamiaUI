--[[
===============================================================================
Damia UI - Secondary Action Bars Implementation
===============================================================================
Specialized module for secondary, right, and right2 action bars.
Implements symmetrical layout philosophy with proper spacing from center.

Features:
- Secondary bar above main bar (centered)
- Right bars positioned symmetrically from center
- Aurora styling integration
- Configurable visibility and auto-hide
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
local UIFrameFadeOut = UIFrameFadeOut

-- LibActionButton reference
local LAB = LibStub and LibStub:GetLibrary("LibActionButton-1.0", true)

-- Create SecondaryBars module
local SecondaryBars = {
    bars = {},
    buttons = {},
    initialized = false,
}

-- Bar configurations and defaults
local BAR_CONFIGS = {
    secondary = {
        defaultPosition = { x = 0, y = 140 }, -- Above main bar, centered
        defaultButtonCount = 12,
        defaultOrientation = "horizontal",
        actionIDOffset = 12, -- Actions 13-24
    },
    right = {
        defaultPosition = { x = 300, y = -150 }, -- Right side, symmetrical
        defaultButtonCount = 12,
        defaultOrientation = "vertical",
        actionIDOffset = 24, -- Actions 25-36
    },
    right2 = {
        defaultPosition = { x = 340, y = -150 }, -- Further right, symmetrical
        defaultButtonCount = 12,
        defaultOrientation = "vertical",
        actionIDOffset = 36, -- Actions 37-48
    },
}

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
INITIALIZATION AND SETUP
===============================================================================
--]]

function SecondaryBars:Initialize(parentModule)
    if self.initialized then
        return true
    end
    
    self.parentModule = parentModule
    
    if not LAB then
        DamiaUI.Engine:LogError("LibActionButton-1.0 not available for secondary bars")
        return false
    end
    
    -- Initialize each secondary bar type
    local success = true
    
    -- Create secondary bar (horizontal above main)
    if self:ShouldCreateBar("secondary") then
        success = success and self:CreateSecondaryBar("secondary")
    end
    
    -- Create right bars (vertical on right side)
    if self:ShouldCreateBar("right") then
        success = success and self:CreateSecondaryBar("right")
    end
    
    if self:ShouldCreateBar("right2") then
        success = success and self:CreateSecondaryBar("right2")
    end
    
    if success then
        self:ApplyAuroraStyling()
        self.initialized = true
        DamiaUI.Engine:LogInfo("Secondary action bars initialized")
    end
    
    return success
end

function SecondaryBars:ShouldCreateBar(barType)
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barType) or DamiaUI.Defaults.profile.actionbars[barType]
    return config and config.enabled
end

function SecondaryBars:CreateSecondaryBar(barType)
    local barConfig = BAR_CONFIGS[barType]
    if not barConfig then
        DamiaUI.Engine:LogError("Unknown bar type: %s", barType)
        return false
    end
    
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barType) or DamiaUI.Defaults.profile.actionbars[barType]
    
    -- Create bar frame
    local bar = self:CreateBarFrame(barType, config, barConfig)
    if not bar then
        return false
    end
    
    -- Create buttons for this bar
    if not self:CreateBarButtons(barType, bar, config, barConfig) then
        return false
    end
    
    -- Position and scale the bar
    self:PositionBar(barType, bar, config, barConfig)
    
    -- Store bar reference
    self.bars[barType] = bar
    
    DamiaUI.Engine:LogDebug("Secondary action bar '%s' created successfully", barType)
    return true
end

function SecondaryBars:CreateBarFrame(barType, config, barConfig)
    local buttonSize = config.buttonSize or 32
    local spacing = config.buttonSpacing or 4
    local buttonCount = config.buttonCount or barConfig.defaultButtonCount
    local orientation = barConfig.defaultOrientation
    
    local barWidth, barHeight
    if orientation == "horizontal" then
        barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
        barHeight = buttonSize
    else -- vertical
        barWidth = buttonSize
        barHeight = buttonCount * buttonSize + (buttonCount - 1) * spacing
    end
    
    -- Create bar frame
    local frameName = string.format("DamiaUI_%sActionBar", barType:gsub("^%l", string.upper))
    local bar = CreateFrame("Frame", frameName, UIParent)
    bar:SetSize(barWidth, barHeight)
    bar:SetFrameStrata("LOW")
    bar:SetFrameLevel(10)
    
    -- Create transparent backdrop
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    bar:SetBackdropColor(0, 0, 0, 0) -- Transparent
    
    -- Store metadata
    bar.damiaConfig = config
    bar.damiaBarType = barType
    bar.damiaOrientation = orientation
    
    return bar
end

function SecondaryBars:CreateBarButtons(barType, bar, config, barConfig)
    local buttonSize = config.buttonSize or 32
    local spacing = config.buttonSpacing or 4
    local buttonCount = config.buttonCount or barConfig.defaultButtonCount
    local orientation = barConfig.defaultOrientation
    local actionIDOffset = barConfig.actionIDOffset
    
    bar.buttons = {}
    
    for i = 1, buttonCount do
        local button = self:CreateSingleButton(barType, i, bar, actionIDOffset + i)
        if button then
            bar.buttons[i] = button
            
            -- Position button within bar
            if orientation == "horizontal" then
                local offsetX = (i - 1) * (buttonSize + spacing)
                button:SetPoint("LEFT", bar, "LEFT", offsetX, 0)
            else -- vertical
                local offsetY = -((i - 1) * (buttonSize + spacing))
                button:SetPoint("TOP", bar, "TOP", 0, offsetY)
            end
            
            -- Store reference in parent module
            if self.parentModule and self.parentModule.buttons then
                local buttonName = string.format("DamiaUI_%sButton%d", barType:gsub("^%l", string.upper), i)
                self.parentModule.buttons[buttonName] = button
            end
            
            -- Store in local buttons table
            self.buttons[string.format("%s_%d", barType, i)] = button
        else
            DamiaUI.Engine:LogError("Failed to create %s action button %d", barType, i)
            return false
        end
    end
    
    DamiaUI.Engine:LogDebug("Created %d buttons for %s bar", #bar.buttons, barType)
    return true
end

function SecondaryBars:CreateSingleButton(barType, buttonIndex, parent, actionID)
    if not LAB then
        return nil
    end
    
    local buttonName = string.format("DamiaUI_%sButton%d", barType:gsub("^%l", string.upper), buttonIndex)
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barType) or DamiaUI.Defaults.profile.actionbars[barType]
    local buttonSize = config.buttonSize or 32
    
    -- Create button using LibActionButton
    local button = LAB:CreateButton(actionID, buttonName, parent)
    
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
    button.damiaConfig = config
    button.damiaBarType = barType
    button.damiaIndex = buttonIndex
    button.damiaActionID = actionID
    
    -- Setup button styling and overlays
    self:SetupButtonStyling(button, config)
    self:SetupButtonOverlays(button, config)
    
    return button
end

--[[
===============================================================================
BUTTON STYLING AND POSITIONING
===============================================================================
--]]

function SecondaryBars:SetupButtonStyling(button, config)
    if not button then return end
    
    -- Apply Aurora styling
    button:SetBackdrop(BUTTON_STYLE.backdrop)
    button:SetBackdropColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
    button:SetBackdropBorderColor(BUTTON_STYLE.borderColor.r, BUTTON_STYLE.borderColor.g, BUTTON_STYLE.borderColor.b, BUTTON_STYLE.borderColor.a)
    
    -- Configure state textures
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        normalTexture:SetVertexColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
    end
    
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        pushedTexture:SetVertexColor(BUTTON_STYLE.pushedColor.r, BUTTON_STYLE.pushedColor.g, BUTTON_STYLE.pushedColor.b, BUTTON_STYLE.pushedColor.a)
    end
    
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlightTexture:SetVertexColor(BUTTON_STYLE.highlightColor.r, BUTTON_STYLE.highlightColor.g, BUTTON_STYLE.highlightColor.b, BUTTON_STYLE.highlightColor.a)
        highlightTexture:SetBlendMode("ADD")
    end
    
    local checkedTexture = button:GetCheckedTexture()
    if checkedTexture then
        checkedTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        checkedTexture:SetVertexColor(BUTTON_STYLE.checkedColor.r, BUTTON_STYLE.checkedColor.g, BUTTON_STYLE.checkedColor.b, BUTTON_STYLE.checkedColor.a)
    end
end

function SecondaryBars:SetupButtonOverlays(button, config)
    if not button then return end
    
    -- Keybind text overlay
    if config.showKeybinds then
        button.keybindText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.keybindText:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.keybindText:SetTextColor(0.6, 0.6, 0.6, 1)
        button.keybindText:SetJustifyH("LEFT")
        button.keybindText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        self:UpdateKeybindText(button)
    end
    
    -- Stack count text
    button.countText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.countText:SetTextColor(1, 1, 1, 1)
    button.countText:SetJustifyH("RIGHT")
    button.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    -- Cooldown frame
    if config.showCooldowns then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
        button.cooldown:SetDrawBling(false)
        button.cooldown:SetDrawEdge(true)
    end
    
    -- Macro name text (only for secondary bar, not side bars)
    if config.showMacroNames and button.damiaBarType == "secondary" then
        button.macroText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.macroText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        button.macroText:SetTextColor(1, 1, 1, 1)
        button.macroText:SetJustifyH("CENTER")
        button.macroText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    end
    
    -- Range indicator
    button.rangeIndicator = button:CreateTexture(nil, "OVERLAY")
    button.rangeIndicator:SetAllPoints(button)
    button.rangeIndicator:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0)
    button.rangeIndicator:SetBlendMode("MULTIPLY")
end

function SecondaryBars:PositionBar(barType, bar, config, barConfig)
    if not bar then return end
    
    -- Use configured position or default
    local posX = config.position.x or barConfig.defaultPosition.x
    local posY = config.position.y or barConfig.defaultPosition.y
    
    -- Position relative to screen center
    if DamiaUI.Utils then
        DamiaUI.Utils:PositionFrame(bar, posX, posY, "CENTER")
    else
        -- Fallback positioning
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    end
    
    -- Apply scale
    local scale = config.scale or 1.0
    bar:SetScale(scale)
    
    DamiaUI.Engine:LogDebug("%s bar positioned at (%d, %d) with scale %.2f", barType, posX, posY, scale)
end

function SecondaryBars:ApplyAuroraStyling()
    for barType, bar in pairs(self.bars) do
        if bar and bar.buttons then
            for _, button in pairs(bar.buttons) do
                if button and button.damiaConfig then
                    self:SetupButtonStyling(button, button.damiaConfig)
                end
            end
        end
    end
    
    DamiaUI.Engine:LogDebug("Aurora styling applied to secondary bars")
end

--[[
===============================================================================
BUTTON STATE MANAGEMENT
===============================================================================
--]]

function SecondaryBars:UpdateButton(button)
    if not button or not HasAction(button.damiaActionID) then
        return
    end
    
    -- Update button count
    self:UpdateButtonCount(button)
    
    -- Update cooldown
    if button.damiaConfig.showCooldowns and button.cooldown then
        self:UpdateButtonCooldown(button)
    end
    
    -- Update usability and range
    self:UpdateButtonUsability(button)
    
    -- Update keybind display
    if button.damiaConfig.showKeybinds and button.keybindText then
        self:UpdateKeybindText(button)
    end
end

function SecondaryBars:UpdateButtonCount(button)
    if not button or not button.countText then return end
    
    local count = GetActionCount(button.damiaActionID)
    
    if count and count > 1 then
        button.countText:SetText(count)
        button.countText:Show()
    else
        button.countText:Hide()
    end
end

function SecondaryBars:UpdateButtonCooldown(button)
    if not button or not button.cooldown then return end
    
    local start, duration, enabled = GetActionCooldown(button.damiaActionID)
    
    if start and duration and duration > 0 and enabled == 1 then
        button.cooldown:SetCooldown(start, duration)
        button.cooldown:Show()
    else
        button.cooldown:Hide()
    end
end

function SecondaryBars:UpdateButtonUsability(button)
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
            button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0.3)
        else
            button.rangeIndicator:SetVertexColor(1, 0.1, 0.1, 0)
        end
    end
end

function SecondaryBars:UpdateKeybindText(button)
    if not button or not button.keybindText then return end
    
    -- Get keybind based on action ID
    local actionType = button.damiaBarType
    local key = nil
    
    if actionType == "secondary" then
        key = GetBindingKey(string.format("MULTIACTIONBAR1BUTTON%d", button.damiaIndex))
    elseif actionType == "right" then
        key = GetBindingKey(string.format("MULTIACTIONBAR2BUTTON%d", button.damiaIndex))
    elseif actionType == "right2" then
        key = GetBindingKey(string.format("MULTIACTIONBAR3BUTTON%d", button.damiaIndex))
    end
    
    if key then
        -- Abbreviate modifier keys
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

function SecondaryBars:UpdateAllButtons()
    for buttonKey, button in pairs(self.buttons) do
        if button then
            self:UpdateButton(button)
        end
    end
end

--[[
===============================================================================
LAYOUT AND VISIBILITY MANAGEMENT
===============================================================================
--]]

function SecondaryBars:UpdateLayout()
    if InCombatLockdown() then
        return false
    end
    
    for barType, bar in pairs(self.bars) do
        if bar then
            local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barType) or DamiaUI.Defaults.profile.actionbars[barType]
            local barConfig = BAR_CONFIGS[barType]
            
            if config and barConfig then
                self:PositionBar(barType, bar, config, barConfig)
                self:UpdateBarButtons(barType, bar, config, barConfig)
            end
        end
    end
    
    return true
end

function SecondaryBars:UpdateBarButtons(barType, bar, config, barConfig)
    if not bar or not bar.buttons then return end
    
    local buttonSize = config.buttonSize or 32
    local spacing = config.buttonSpacing or 4
    local orientation = barConfig.defaultOrientation
    
    -- Update bar size
    local buttonCount = #bar.buttons
    local barWidth, barHeight
    if orientation == "horizontal" then
        barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
        barHeight = buttonSize
    else -- vertical
        barWidth = buttonSize
        barHeight = buttonCount * buttonSize + (buttonCount - 1) * spacing
    end
    bar:SetSize(barWidth, barHeight)
    
    -- Update button positions and sizes
    for i, button in pairs(bar.buttons) do
        if button then
            button:SetSize(buttonSize, buttonSize)
            button:ClearAllPoints()
            
            if orientation == "horizontal" then
                local offsetX = (i - 1) * (buttonSize + spacing)
                button:SetPoint("LEFT", bar, "LEFT", offsetX, 0)
            else -- vertical
                local offsetY = -((i - 1) * (buttonSize + spacing))
                button:SetPoint("TOP", bar, "TOP", 0, offsetY)
            end
        end
    end
end

function SecondaryBars:ShowBar(barType)
    local bar = self.bars[barType]
    if bar then
        bar:Show()
        return true
    end
    return false
end

function SecondaryBars:HideBar(barType)
    local bar = self.bars[barType]
    if bar then
        bar:Hide()
        return true
    end
    return false
end

function SecondaryBars:ShowAllBars()
    for barType, bar in pairs(self.bars) do
        if bar then
            bar:Show()
        end
    end
end

function SecondaryBars:HideAllBars()
    for barType, bar in pairs(self.bars) do
        if bar then
            bar:Hide()
        end
    end
end

function SecondaryBars:HandleCombatStateChange(inCombat)
    for barType, bar in pairs(self.bars) do
        if bar and bar.damiaConfig and bar.damiaConfig.fadeOnCombat then
            if inCombat then
                UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), bar.damiaConfig.fadeAlpha or 0.5)
            else
                UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), 1.0)
            end
        end
    end
end

--[[
===============================================================================
PUBLIC API
===============================================================================
--]]

function SecondaryBars:IsInitialized()
    return self.initialized
end

function SecondaryBars:GetBar(barType)
    return self.bars[barType]
end

function SecondaryBars:GetButton(barType, index)
    return self.buttons[string.format("%s_%d", barType, index)]
end

function SecondaryBars:GetAllBars()
    return self.bars
end

function SecondaryBars:Cleanup()
    -- Hide and cleanup all bars
    for barType, bar in pairs(self.bars) do
        if bar then
            bar:Hide()
            bar:SetParent(nil)
        end
    end
    
    -- Cleanup button references
    for buttonKey, button in pairs(self.buttons) do
        if button then
            button:Hide()
            button:SetParent(nil)
        end
    end
    
    self.bars = {}
    self.buttons = {}
    self.initialized = false
    
    DamiaUI.Engine:LogDebug("Secondary action bars cleaned up")
end

-- Export SecondaryBars module
DamiaUI.SecondaryBars = SecondaryBars