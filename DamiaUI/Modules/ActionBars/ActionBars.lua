--[[
===============================================================================
Damia UI - Action Bars Module
===============================================================================
LibActionButton-based action bar implementation with centered layout.
Manages main, secondary, pet, and stance bars with Aurora styling.

Features:
- Centered symmetrical layout philosophy
- LibActionButton-1.0 integration
- Combat lockdown handling
- Aurora styling integration
- Keybind and cooldown displays
- Dynamic bar visibility

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local CreateFrame = CreateFrame
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GetActionInfo = GetActionInfo
local HasAction = HasAction
local IsActionInRange = IsActionInRange
local GetActionCooldown = GetActionCooldown
local GetActionCount = GetActionCount
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown

-- LibActionButton reference
local LAB = LibStub and LibStub:GetLibrary("LibActionButton-1.0", true)

-- Combat lockdown protection
local CombatLockdown = DamiaUI.CombatLockdown

-- Create ActionBars module using DamiaUI's module system
local ActionBars = DamiaUI and DamiaUI:NewModule("ActionBars") or {
    bars = {},
    buttons = {},
    initialized = false,
    blizzardBarsHidden = false,
}

-- Add module properties
ActionBars.bars = {}
ActionBars.buttons = {}
ActionBars.initialized = false
ActionBars.blizzardBarsHidden = false

-- Module dependencies
local moduleDependencies = {
    "Config",
    "Events",
    "Utils"
}

-- Constants
local BUTTON_SPACING = 4
local BUTTON_SIZE_DEFAULT = 36
local FADE_DURATION = 0.2

-- Button state colors (Aurora theme)
local BUTTON_COLORS = {
    normal = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    pushed = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    highlight = { r = 0.8, g = 0.5, b = 0.1, a = 0.8 },
    checked = { r = 0.6, g = 0.4, b = 0.1, a = 1.0 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
}

--[[
===============================================================================
MODULE LIFECYCLE
===============================================================================
--]]

function ActionBars:OnEnable()
    DamiaUI.Engine:LogInfo("ActionBars module enabled")
    
    -- Verify LibActionButton is available
    if not LAB then
        DamiaUI.Engine:LogError("LibActionButton-1.0 not found! Action bars cannot function.")
        return
    end
    
    -- Register for configuration changes
    if DamiaUI.Config then
        DamiaUI.Config:RegisterCallback("actionbars", function(key, oldValue, newValue)
            self:OnConfigChanged(key, oldValue, newValue)
        end, "ActionBars_ConfigWatcher")
    end
    
    -- Register for game events
    if DamiaUI.Events then
        DamiaUI.Events:RegisterCustomEvent("DAMIA_PLAYER_ENTERING_WORLD", function()
            self:InitializeBars()
        end, 2, "ActionBars_PlayerEnteringWorld")
        
        DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", function(_, inCombat)
            self:HandleCombatStateChange(inCombat)
        end, 2, "ActionBars_CombatStateChanged")
    end
    
    -- Register for LibActionButton events
    if LAB then
        LAB.RegisterCallback(self, "OnButtonUpdate", "UpdateButton")
        LAB.RegisterCallback(self, "OnButtonState", "UpdateButtonState")
        LAB.RegisterCallback(self, "OnButtonUsable", "UpdateButtonUsable")
    end
end

function ActionBars:OnDisable()
    DamiaUI.Engine:LogInfo("ActionBars module disabled")
    
    -- Hide all bars
    self:HideAllBars()
    
    -- Restore Blizzard bars if they were hidden
    if self.blizzardBarsHidden then
        self:ShowBlizzardBars()
    end
    
    -- Cleanup configuration callbacks
    if DamiaUI.Config then
        DamiaUI.Config:UnregisterCallback("actionbars", "ActionBars_ConfigWatcher")
    end
    
    -- Cleanup event handlers
    if DamiaUI.Events then
        DamiaUI.Events:UnregisterCustomEvent("DAMIA_PLAYER_ENTERING_WORLD", "ActionBars_PlayerEnteringWorld")
        DamiaUI.Events:UnregisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", "ActionBars_CombatStateChanged")
    end
    
    -- Unregister LibActionButton callbacks
    if LAB then
        LAB.UnregisterCallback(self, "OnButtonUpdate")
        LAB.UnregisterCallback(self, "OnButtonState")
        LAB.UnregisterCallback(self, "OnButtonUsable")
    end
end

function ActionBars:OnConfigChanged(key, oldValue, newValue)
    DamiaUI.Engine:LogDebug("ActionBars config changed: %s", key)
    
    if not self.initialized then
        return
    end
    
    -- Handle specific configuration changes
    if key == "enabled" then
        if newValue then
            self:ShowAllBars()
        else
            self:HideAllBars()
        end
    elseif key == "hideBlizzardBars" then
        if newValue then
            self:HideBlizzardBars()
        else
            self:ShowBlizzardBars()
        end
    else
        -- For other config changes, update the specific bar
        local barName = key:match("^([^%.]+)")
        if barName and self.bars[barName] then
            self:UpdateBarLayout(barName)
        end
    end
end

--[[
===============================================================================
INITIALIZATION AND SETUP
===============================================================================
--]]

function ActionBars:InitializeBars()
    if self.initialized then
        return
    end
    
    DamiaUI.Engine:LogInfo("Initializing action bars...")
    
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars") or DamiaUI.Defaults.profile.actionbars
    
    if not config.enabled then
        DamiaUI.Engine:LogInfo("Action bars disabled in configuration")
        return
    end
    
    -- Hide Blizzard bars if configured
    if config.hideBlizzardBars then
        self:HideBlizzardBars()
    end
    
    -- Create main action bar
    if config.main.enabled then
        self:CreateMainBar()
    end
    
    -- Create secondary bars
    if config.secondary.enabled or config.right.enabled or config.right2.enabled then
        self:CreateSecondaryBars()
    end
    
    -- Create pet bar
    if config.pet.enabled then
        self:CreatePetBar()
    end
    
    -- Create stance bar
    if config.stance.enabled then
        self:CreateStanceBar()
    end
    
    -- Apply Aurora styling
    self:ApplyAuroraStyling()
    
    self.initialized = true
    DamiaUI.Engine:LogInfo("Action bars initialization complete")
end

--[[
===============================================================================
BAR CREATION AND MANAGEMENT
===============================================================================
--]]

function ActionBars:CreateMainBar()
    if DamiaUI.MainBar then
        if DamiaUI.MainBar:Initialize(self) then
            DamiaUI.Engine:LogDebug("Main action bar initialized successfully")
            -- Store reference to main bar
            local mainBar = DamiaUI.MainBar:GetBar()
            if mainBar then
                self.bars.main = mainBar
            end
        else
            DamiaUI.Engine:LogError("Failed to initialize main action bar")
        end
    else
        DamiaUI.Engine:LogError("MainBar module not found")
    end
end

function ActionBars:CreateSecondaryBars()
    if DamiaUI.SecondaryBars then
        if DamiaUI.SecondaryBars:Initialize(self) then
            DamiaUI.Engine:LogDebug("Secondary bars initialized successfully")
            -- Store references to secondary bars
            local secondaryBars = DamiaUI.SecondaryBars:GetAllBars()
            for barType, bar in pairs(secondaryBars) do
                self.bars[barType] = bar
            end
        else
            DamiaUI.Engine:LogError("Failed to initialize secondary bars")
        end
    else
        DamiaUI.Engine:LogError("SecondaryBars module not found")
    end
end

function ActionBars:CreatePetBar()
    if DamiaUI.PetBar then
        if DamiaUI.PetBar:Initialize(self) then
            DamiaUI.Engine:LogDebug("Pet and stance bars initialized successfully")
            -- Store references to pet and stance bars
            local petBar = DamiaUI.PetBar:GetPetBar()
            local stanceBar = DamiaUI.PetBar:GetStanceBar()
            if petBar then
                self.bars.pet = petBar
            end
            if stanceBar then
                self.bars.stance = stanceBar
            end
        else
            DamiaUI.Engine:LogError("Failed to initialize pet and stance bars")
        end
    else
        DamiaUI.Engine:LogError("PetBar module not found")
    end
end

function ActionBars:CreateStanceBar()
    -- Stance bar creation is handled by CreatePetBar() since they're in the same module
    -- This method is kept for API compatibility
    DamiaUI.Engine:LogDebug("Stance bar creation handled by PetBar module")
end

function ActionBars:CreateActionButton(barType, buttonIndex, parent)
    if not LAB then
        return nil
    end
    
    local buttonName = string.format("DamiaUI_%sButton%d", barType:gsub("^%l", string.upper), buttonIndex)
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barType) or DamiaUI.Defaults.profile.actionbars[barType]
    
    if not config then
        DamiaUI.Engine:LogError("No configuration found for bar type: %s", barType)
        return nil
    end
    
    -- Create button using LibActionButton
    local button = LAB:CreateButton(self:GetActionID(barType, buttonIndex), buttonName, parent)
    if not button then
        DamiaUI.Engine:LogError("Failed to create action button: %s", buttonName)
        return nil
    end
    
    -- Configure button
    button:SetSize(config.buttonSize, config.buttonSize)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    
    -- Store configuration reference
    button.damiaConfig = config
    button.damiaBarType = barType
    button.damiaIndex = buttonIndex
    
    -- Setup button visuals
    self:SetupButtonVisuals(button, config)
    
    -- Setup button overlays
    self:SetupButtonOverlays(button, config)
    
    -- Store button reference
    self.buttons[buttonName] = button
    
    return button
end

--[[
===============================================================================
BUTTON STYLING AND VISUALS
===============================================================================
--]]

function ActionBars:SetupButtonVisuals(button, config)
    if not button then return end
    
    -- Create backdrop for Aurora styling
    if not button.backdrop then
        button.backdrop = CreateFrame("Frame", nil, button)
        button.backdrop:SetAllPoints()
        button.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
    end
    
    -- Set button textures to Aurora theme
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetColorTexture(BUTTON_COLORS.normal.r, BUTTON_COLORS.normal.g, BUTTON_COLORS.normal.b, BUTTON_COLORS.normal.a)
    end
    
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetColorTexture(BUTTON_COLORS.pushed.r, BUTTON_COLORS.pushed.g, BUTTON_COLORS.pushed.b, BUTTON_COLORS.pushed.a)
    end
    
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetColorTexture(BUTTON_COLORS.highlight.r, BUTTON_COLORS.highlight.g, BUTTON_COLORS.highlight.b, BUTTON_COLORS.highlight.a)
        highlightTexture:SetBlendMode("ADD")
    end
    
    local checkedTexture = button:GetCheckedTexture()
    if checkedTexture then
        checkedTexture:SetColorTexture(BUTTON_COLORS.checked.r, BUTTON_COLORS.checked.g, BUTTON_COLORS.checked.b, BUTTON_COLORS.checked.a)
    end
    
    -- Create border (BackdropTemplate is required for SetBackdrop on Retail)
    if not button.border then
        button.border = CreateFrame("Frame", nil, button.backdrop, "BackdropTemplate")
        button.border:SetAllPoints()
        button.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button.border:SetBackdropBorderColor(BUTTON_COLORS.border.r, BUTTON_COLORS.border.g, BUTTON_COLORS.border.b, BUTTON_COLORS.border.a)
    end
end

function ActionBars:SetupButtonOverlays(button, config)
    if not button then return end
    
    -- Keybind text
    if config.showKeybinds then
        if not button.keybindText then
            button.keybindText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.keybindText:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            button.keybindText:SetTextColor(0.6, 0.6, 0.6, 1)
            button.keybindText:SetJustifyH("LEFT")
        end
        self:UpdateKeybindText(button)
    end
    
    -- Stack count text
    if not button.countText then
        button.countText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button.countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.countText:SetTextColor(1, 1, 1, 1)
        button.countText:SetJustifyH("RIGHT")
    end
    
    -- Cooldown display
    if config.showCooldowns then
        if not button.cooldown then
            button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            button.cooldown:SetAllPoints(button)
            button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        end
    end
    
    -- Macro name text
    if config.showMacroNames then
        if not button.macroText then
            button.macroText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.macroText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
            button.macroText:SetTextColor(1, 1, 1, 1)
            button.macroText:SetJustifyH("CENTER")
        end
    end
end

function ActionBars:ApplyAuroraStyling()
    -- Apply Aurora styling to all created bars
    for barName, bar in pairs(self.bars) do
        if bar and bar.buttons then
            for _, button in pairs(bar.buttons) do
                if button then
                    -- Additional Aurora styling can be applied here
                    -- This would integrate with the DamiaUI_Aurora library
                    self:SetupButtonVisuals(button, button.damiaConfig)
                end
            end
        end
    end
end

--[[
===============================================================================
BLIZZARD BAR MANAGEMENT
===============================================================================
--]]

function ActionBars:HideBlizzardBars()
    if InCombatLockdown() then
        DamiaUI.Engine:LogWarning("Cannot hide Blizzard bars during combat")
        return
    end
    
    local framesToHide = {
        "ActionBarController",
        "MainMenuBar",
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarLeft",
        "MultiBarRight",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7",
        "PetActionBar",
        "StanceBar",
        "PossessBar",
        "OverrideActionBar",
        "VehicleMenuBar",
    }
    
    for _, frameName in ipairs(framesToHide) do
        local frame = _G[frameName]
        if frame then
            frame:SetParent(DamiaUI.hiddenFrame or CreateFrame("Frame"))
            frame:Hide()
        end
    end
    
    self.blizzardBarsHidden = true
    DamiaUI.Engine:LogInfo("Blizzard action bars hidden")
end

function ActionBars:ShowBlizzardBars()
    if InCombatLockdown() then
        DamiaUI.Engine:LogWarning("Cannot show Blizzard bars during combat")
        return
    end
    
    local framesToShow = {
        "ActionBarController",
        "MainMenuBar",
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarLeft",
        "MultiBarRight",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7",
        "PetActionBar",
        "StanceBar",
        "PossessBar",
        "OverrideActionBar",
        "VehicleMenuBar",
    }
    
    for _, frameName in ipairs(framesToShow) do
        local frame = _G[frameName]
        if frame then
            frame:SetParent(UIParent)
            frame:Show()
        end
    end
    
    self.blizzardBarsHidden = false
    DamiaUI.Engine:LogInfo("Blizzard action bars restored")
end

--[[
===============================================================================
BUTTON UPDATE HANDLERS
===============================================================================
--]]

function ActionBars:UpdateButton(button)
    if not button or not button.damiaConfig then return end
    
    -- Update button count
    self:UpdateButtonCount(button)
    
    -- Update button cooldown
    if button.damiaConfig.showCooldowns then
        self:UpdateButtonCooldown(button)
    end
    
    -- Update button usability
    self:UpdateButtonUsable(button)
end

function ActionBars:UpdateButtonState(button)
    if not button then return end
    
    -- This is called when button state changes (pressed, released, etc.)
    -- Additional state-specific styling can be added here
end

function ActionBars:UpdateButtonUsable(button)
    if not button then return end
    
    -- Update button appearance based on usability
    local actionID = self:GetActionID(button.damiaBarType, button.damiaIndex)
    local isUsable, notEnoughMana = IsUsableAction(actionID)
    
    if button:GetNormalTexture() then
        if isUsable then
            button:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
        elseif notEnoughMana then
            button:GetNormalTexture():SetVertexColor(0.5, 0.5, 1, 1)
        else
            button:GetNormalTexture():SetVertexColor(0.4, 0.4, 0.4, 1)
        end
    end
end

function ActionBars:UpdateButtonCount(button)
    if not button or not button.countText then return end
    
    local actionID = self:GetActionID(button.damiaBarType, button.damiaIndex)
    local count = GetActionCount(actionID)
    
    if count and count > 1 then
        button.countText:SetText(count)
        button.countText:Show()
    else
        button.countText:Hide()
    end
end

function ActionBars:UpdateButtonCooldown(button)
    if not button or not button.cooldown then return end
    
    local actionID = self:GetActionID(button.damiaBarType, button.damiaIndex)
    local start, duration, enabled = GetActionCooldown(actionID)
    
    if start and duration and enabled then
        button.cooldown:SetCooldown(start, duration)
    end
end

function ActionBars:UpdateKeybindText(button)
    if not button or not button.keybindText then return end
    
    local actionID = self:GetActionID(button.damiaBarType, button.damiaIndex)
    local key = GetBindingKey(string.format("ACTIONBUTTON%d", actionID))
    
    if key then
        -- Abbreviate common key names
        key = key:gsub("SHIFT%-", "S")
        key = key:gsub("CTRL%-", "C")
        key = key:gsub("ALT%-", "A")
        button.keybindText:SetText(key)
        button.keybindText:Show()
    else
        button.keybindText:Hide()
    end
end

--[[
===============================================================================
COMBAT AND STATE HANDLING
===============================================================================
--]]

function ActionBars:HandleCombatStateChange(inCombat)
    DamiaUI.Engine:LogDebug("Combat state changed: %s", inCombat and "entering" or "leaving")
    
    -- Handle combat-specific bar behavior
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars") or DamiaUI.Defaults.profile.actionbars
    
    for barName, bar in pairs(self.bars) do
        if bar and config[barName] and config[barName].fadeOnCombat then
            if inCombat then
                -- Fade bar during combat
                UIFrameFadeOut(bar, FADE_DURATION, bar:GetAlpha(), config[barName].fadeAlpha or 0.5)
            else
                -- Restore bar after combat
                UIFrameFadeIn(bar, FADE_DURATION, bar:GetAlpha(), 1.0)
            end
        end
    end
end

--[[
===============================================================================
UTILITY FUNCTIONS
===============================================================================
--]]

function ActionBars:GetActionID(barType, buttonIndex)
    -- Convert bar type and button index to WoW action ID
    if barType == "main" then
        return buttonIndex
    elseif barType == "secondary" then
        return buttonIndex + 12
    elseif barType == "right" then
        return buttonIndex + 24
    elseif barType == "right2" then
        return buttonIndex + 36
    elseif barType == "pet" then
        return buttonIndex + 120  -- Pet action IDs
    elseif barType == "stance" then
        return buttonIndex + 132  -- Stance/shapeshift IDs
    end
    
    return buttonIndex
end

function ActionBars:ShowAllBars()
    for barName, bar in pairs(self.bars) do
        if bar then
            bar:Show()
        end
    end
end

function ActionBars:HideAllBars()
    for barName, bar in pairs(self.bars) do
        if bar then
            bar:Hide()
        end
    end
end

function ActionBars:UpdateBarLayout(barName)
    local bar = self.bars[barName]
    if not bar then
        return
    end
    
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars." .. barName) or DamiaUI.Defaults.profile.actionbars[barName]
    if not config then return end
    
    -- Safe layout update with combat lockdown protection
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            -- Reposition bar
            DamiaUI.Utils:PositionFrame(bar, config.position.x, config.position.y, "CENTER")
            
            -- Update bar scale
            bar:SetScale(config.scale)
            
            -- Update button sizes and positions
            if bar.buttons then
                for i, button in pairs(bar.buttons) do
                    if button then
                        button:SetSize(config.buttonSize, config.buttonSize)
                        
                        -- Reposition button within bar
                        local offsetX = (i - 1) * (config.buttonSize + config.buttonSpacing)
                        button:ClearAllPoints()
                        button:SetPoint("LEFT", bar, "LEFT", offsetX, 0)
                    end
                end
                
                -- Update bar size
                bar:SetSize(
                    config.buttonCount * (config.buttonSize + config.buttonSpacing) - config.buttonSpacing,
                    config.buttonSize
                )
            end
        end)
    else
        if InCombatLockdown() then
            DamiaUI.Engine:LogWarning("Action bar layout update deferred due to combat lockdown")
            return
        end
        
        -- Reposition bar
        DamiaUI.Utils:PositionFrame(bar, config.position.x, config.position.y, "CENTER")
        
        -- Update bar scale
        bar:SetScale(config.scale)
        
        -- Update button sizes and positions
        if bar.buttons then
            for i, button in pairs(bar.buttons) do
                if button then
                    button:SetSize(config.buttonSize, config.buttonSize)
                    
                    -- Reposition button within bar
                    local offsetX = (i - 1) * (config.buttonSize + config.buttonSpacing)
                    button:ClearAllPoints()
                    button:SetPoint("LEFT", bar, "LEFT", offsetX, 0)
                end
            end
            
            -- Update bar size
            bar:SetSize(
                config.buttonCount * (config.buttonSize + config.buttonSpacing) - config.buttonSpacing,
                config.buttonSize
            )
        end
    end
end

--[[
===============================================================================
PUBLIC API
===============================================================================
--]]

function ActionBars:GetActionBar(barId)
    return self.bars[barId]
end

function ActionBars:UpdateBarLayout()
    -- Safe layout update with combat lockdown protection
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            for barName in pairs(self.bars) do
                self:UpdateBarLayout(barName)
            end
        end)
    else
        if InCombatLockdown() then
            DamiaUI.Engine:LogWarning("Cannot update bar layout during combat")
            return
        end
        
        for barName in pairs(self.bars) do
            self:UpdateBarLayout(barName)
        end
    end
    
    DamiaUI.Engine:LogInfo("Action bar layout updated")
end

function ActionBars:UpdateAllButtons()
    DamiaUI.Engine:LogInfo("Updating all action buttons")
    
    for _, button in pairs(self.buttons) do
        if button then
            self:UpdateButton(button)
        end
    end
end

function ActionBars:IsInitialized()
    return self.initialized
end

-- Safe update methods with combat lockdown protection
function ActionBars:SafeUpdateLayout()
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            self:UpdateBarLayout()
        end)
    else
        if not InCombatLockdown() then
            self:UpdateBarLayout()
        else
            DamiaUI.Engine:LogWarning("Action bars layout update deferred due to combat lockdown")
        end
    end
end

-- Module already registered via NewModule
-- Export to DamiaUI namespace for external access
if DamiaUI then
    DamiaUI.ActionBars = ActionBars
end