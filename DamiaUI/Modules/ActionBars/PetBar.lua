--[[
===============================================================================
Damia UI - Pet and Stance Bar Implementation
===============================================================================
Specialized module for pet action bars and stance/shapeshift bars.
Handles auto-hide functionality and class-specific behavior.

Features:
- Pet action bar with auto-hide when no pet is active
- Stance/shapeshift bar with class-specific handling
- Positioned symmetrically from main bar
- Aurora styling integration
- Dynamic button count based on available actions
- Combat state handling

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
local UnitExists = UnitExists
local HasPetAction = HasPetAction
local GetPetActionInfo = GetPetActionInfo
local GetPetActionCooldown = GetPetActionCooldown
local GetPetActionSlotUsable = GetPetActionSlotUsable
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetNumShapeshiftForms = GetNumShapeshiftForms

-- Compatibility layer for modern API support
local Compatibility = DamiaUI.Compatibility
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut
local C_Timer = C_Timer

-- LibActionButton reference
local LAB = LibStub and LibStub:GetLibrary("LibActionButton-1.0", true)

-- Combat lockdown protection
local CombatLockdown = DamiaUI.CombatLockdown

-- Create PetBar module
local PetBar = {
    petBar = nil,
    stanceBar = nil,
    petButtons = {},
    stanceButtons = {},
    initialized = false,
    petBarVisible = false,
    stanceBarVisible = false,
}

-- Bar configurations
local PET_BAR_CONFIG = {
    maxButtons = 10,
    defaultPosition = { x = -200, y = 100 }, -- Left of main bar
    buttonSize = 30,
    spacing = 2,
    fadeDelay = 1.0, -- Delay before auto-hide
}

local STANCE_BAR_CONFIG = {
    maxButtons = 10,
    defaultPosition = { x = -280, y = 100 }, -- Further left of pet bar
    buttonSize = 30,
    spacing = 2,
    fadeDelay = 1.0,
}

-- Button styling (Aurora theme, smaller size)
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

-- Class-specific stance configurations
local CLASS_STANCE_CONFIG = {
    WARRIOR = { maxStances = 3, stanceName = "Stance" },
    PALADIN = { maxStances = 1, stanceName = "Aura" },
    DRUID = { maxStances = 4, stanceName = "Form" },
    ROGUE = { maxStances = 1, stanceName = "Stealth" },
    PRIEST = { maxStances = 1, stanceName = "Shadowform" },
    SHAMAN = { maxStances = 1, stanceName = "Ghost Wolf" },
    DEATHKNIGHT = { maxStances = 1, stanceName = "Presence" },
}

--[[
===============================================================================
INITIALIZATION AND SETUP
===============================================================================
--]]

function PetBar:Initialize(parentModule)
    if self.initialized then
        return true
    end
    
    self.parentModule = parentModule
    
    if not LAB then
        DamiaUI.Engine:LogError("LibActionButton-1.0 not available for pet/stance bars")
        return false
    end
    
    local success = true
    
    -- Create pet bar if enabled
    if self:ShouldCreatePetBar() then
        success = success and self:CreatePetBar()
    end
    
    -- Create stance bar if enabled
    if self:ShouldCreateStanceBar() then
        success = success and self:CreateStanceBar()
    end
    
    if success then
        self:ApplyAuroraStyling()
        self:RegisterEvents()
        self:UpdateVisibility()
        self.initialized = true
        DamiaUI.Engine:LogInfo("Pet and stance bars initialized")
    end
    
    return success
end

function PetBar:ShouldCreatePetBar()
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.pet") or DamiaUI.Defaults.profile.actionbars.pet
    return config and config.enabled
end

function PetBar:ShouldCreateStanceBar()
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.stance") or DamiaUI.Defaults.profile.actionbars.stance
    return config and config.enabled
end

--[[
===============================================================================
PET BAR CREATION
===============================================================================
--]]

function PetBar:CreatePetBar()
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.pet") or DamiaUI.Defaults.profile.actionbars.pet
    local buttonCount = config.buttonCount or PET_BAR_CONFIG.maxButtons
    local buttonSize = config.buttonSize or PET_BAR_CONFIG.buttonSize
    local spacing = config.buttonSpacing or PET_BAR_CONFIG.spacing
    
    -- Calculate bar dimensions
    local barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
    local barHeight = buttonSize
    
    -- Create pet bar frame
    self.petBar = CreateFrame("Frame", "DamiaUI_PetActionBar", UIParent)
    self.petBar:SetSize(barWidth, barHeight)
    self.petBar:SetFrameStrata("LOW")
    self.petBar:SetFrameLevel(10)
    
    -- Avoid SetBackdrop on bar; leave transparent
    
    -- Position pet bar
    self:PositionPetBar()
    
    -- Create pet buttons
    self.petButtons = {}
    for i = 1, buttonCount do
        local button = self:CreatePetButton(i)
        if button then
            self.petButtons[i] = button
            
            -- Position button
            local offsetX = (i - 1) * (buttonSize + spacing)
            button:SetPoint("LEFT", self.petBar, "LEFT", offsetX, 0)
            
            -- Store reference in parent module
            if self.parentModule and self.parentModule.buttons then
                self.parentModule.buttons[string.format("DamiaUI_PetButton%d", i)] = button
            end
        end
    end
    
    -- Initially hide if auto-hide is enabled
    if config.autoHide then
        self.petBar:SetAlpha(0)
    end
    
    self.petBar.damiaConfig = config
    
    DamiaUI.Engine:LogDebug("Pet action bar created with %d buttons", #self.petButtons)
    return true
end

function PetBar:CreatePetButton(buttonIndex)
    if not LAB then
        return nil
    end
    
    local buttonName = string.format("DamiaUI_PetButton%d", buttonIndex)
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.pet") or DamiaUI.Defaults.profile.actionbars.pet
    local buttonSize = config.buttonSize or PET_BAR_CONFIG.buttonSize
    
    -- Create button using LibActionButton for pet actions
    -- Pet actions use IDs 120+
    local actionID = 120 + buttonIndex - 1
    local button = LAB:CreateButton(actionID, buttonName, self.petBar, "pet")
    
    if not button then
        DamiaUI.Engine:LogError("Failed to create pet button: %s", buttonName)
        return nil
    end
    
    -- Configure button
    button:SetSize(buttonSize, buttonSize)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    
    -- Store metadata
    button.damiaConfig = config
    button.damiaBarType = "pet"
    button.damiaIndex = buttonIndex
    button.damiaPetSlot = buttonIndex
    
    -- Setup styling and overlays
    self:SetupButtonStyling(button, config)
    self:SetupPetButtonOverlays(button, config)
    
    return button
end

function PetBar:PositionPetBar()
    if not self.petBar then return end
    
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.pet") or DamiaUI.Defaults.profile.actionbars.pet
    local posX = config.position.x or PET_BAR_CONFIG.defaultPosition.x
    local posY = config.position.y or PET_BAR_CONFIG.defaultPosition.y
    local scale = config.scale or 0.9
    
    -- Position relative to screen center (with combat lockdown protection)
    if CombatLockdown then
        if DamiaUI.Utils then
            CombatLockdown:SafeUpdateActionBars(function()
                DamiaUI.Utils:PositionFrame(self.petBar, posX, posY, "CENTER")
            end)
        else
            CombatLockdown:SafeSetPoint(self.petBar, "CENTER", UIParent, "CENTER", posX, posY)
        end
        CombatLockdown:SafeSetScale(self.petBar, scale)
    else
        if not InCombatLockdown() then
            if DamiaUI.Utils then
                DamiaUI.Utils:PositionFrame(self.petBar, posX, posY, "CENTER")
            else
                self.petBar:ClearAllPoints()
                self.petBar:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
            end
            self.petBar:SetScale(scale)
        else
            DamiaUI.Engine:LogWarning("Pet bar positioning deferred due to combat lockdown")
        end
    end
end

--[[
===============================================================================
STANCE BAR CREATION
===============================================================================
--]]

function PetBar:CreateStanceBar()
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.stance") or DamiaUI.Defaults.profile.actionbars.stance
    local buttonCount = config.buttonCount or STANCE_BAR_CONFIG.maxButtons
    local buttonSize = config.buttonSize or STANCE_BAR_CONFIG.buttonSize
    local spacing = config.buttonSpacing or STANCE_BAR_CONFIG.spacing
    
    -- Get player class for stance configuration
    local _, playerClass = UnitClass("player")
    local classConfig = CLASS_STANCE_CONFIG[playerClass]
    
    if not classConfig then
        DamiaUI.Engine:LogDebug("No stance configuration for class: %s", playerClass or "Unknown")
        return true -- Not an error, just no stances for this class
    end
    
    -- Adjust button count based on class
    buttonCount = math.min(buttonCount, classConfig.maxStances)
    
    -- Calculate bar dimensions
    local barWidth = buttonCount * buttonSize + (buttonCount - 1) * spacing
    local barHeight = buttonSize
    
    -- Create stance bar frame
    self.stanceBar = CreateFrame("Frame", "DamiaUI_StanceActionBar", UIParent)
    self.stanceBar:SetSize(barWidth, barHeight)
    self.stanceBar:SetFrameStrata("LOW")
    self.stanceBar:SetFrameLevel(10)
    
    -- Avoid SetBackdrop on bar; leave transparent
    
    -- Position stance bar
    self:PositionStanceBar()
    
    -- Create stance buttons
    self.stanceButtons = {}
    for i = 1, buttonCount do
        local button = self:CreateStanceButton(i)
        if button then
            self.stanceButtons[i] = button
            
            -- Position button
            local offsetX = (i - 1) * (buttonSize + spacing)
            button:SetPoint("LEFT", self.stanceBar, "LEFT", offsetX, 0)
            
            -- Store reference in parent module
            if self.parentModule and self.parentModule.buttons then
                self.parentModule.buttons[string.format("DamiaUI_StanceButton%d", i)] = button
            end
        end
    end
    
    -- Initially hide if auto-hide is enabled
    if config.autoHide then
        self.stanceBar:SetAlpha(0)
    end
    
    self.stanceBar.damiaConfig = config
    self.stanceBar.damiaClassConfig = classConfig
    
    DamiaUI.Engine:LogDebug("Stance action bar created with %d buttons for %s", #self.stanceButtons, playerClass)
    return true
end

function PetBar:CreateStanceButton(buttonIndex)
    if not LAB then
        return nil
    end
    
    local buttonName = string.format("DamiaUI_StanceButton%d", buttonIndex)
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.stance") or DamiaUI.Defaults.profile.actionbars.stance
    local buttonSize = config.buttonSize or STANCE_BAR_CONFIG.buttonSize
    
    -- Create button using LibActionButton for stance actions
    -- Stance actions use IDs 132+
    local actionID = 132 + buttonIndex - 1
    local button = LAB:CreateButton(actionID, buttonName, self.stanceBar, "shapeshift")
    
    if not button then
        DamiaUI.Engine:LogError("Failed to create stance button: %s", buttonName)
        return nil
    end
    
    -- Configure button
    button:SetSize(buttonSize, buttonSize)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    
    -- Store metadata
    button.damiaConfig = config
    button.damiaBarType = "stance"
    button.damiaIndex = buttonIndex
    button.damiaStanceSlot = buttonIndex
    
    -- Setup styling and overlays
    self:SetupButtonStyling(button, config)
    self:SetupStanceButtonOverlays(button, config)
    
    return button
end

function PetBar:PositionStanceBar()
    if not self.stanceBar then return end
    
    local config = DamiaUI.Config and DamiaUI.Config:GetValue("actionbars.stance") or DamiaUI.Defaults.profile.actionbars.stance
    local posX = config.position.x or STANCE_BAR_CONFIG.defaultPosition.x
    local posY = config.position.y or STANCE_BAR_CONFIG.defaultPosition.y
    
    -- Position relative to screen center
    if DamiaUI.Utils then
        DamiaUI.Utils:PositionFrame(self.stanceBar, posX, posY, "CENTER")
    else
        self.stanceBar:ClearAllPoints()
        self.stanceBar:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    end
    
    -- Apply scale
    self.stanceBar:SetScale(config.scale or 0.9)
end

--[[
===============================================================================
BUTTON STYLING AND OVERLAYS
===============================================================================
--]]

function PetBar:SetupButtonStyling(button, config)
    if not button then return end
    
    -- Apply Aurora styling via BackdropTemplate border frame
    if not button.damiaBorder then
        local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
        border:SetAllPoints(button)
        border:SetBackdrop(BUTTON_STYLE.backdrop)
        border:SetBackdropColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
        border:SetBackdropBorderColor(BUTTON_STYLE.borderColor.r, BUTTON_STYLE.borderColor.g, BUTTON_STYLE.borderColor.b, BUTTON_STYLE.borderColor.a)
        button.damiaBorder = border
    end
    
    -- Configure state textures using compatibility layer
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        if Compatibility and Compatibility.SetSolidTexture then
            Compatibility.SetSolidTexture(normalTexture, BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
        else
            normalTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            normalTexture:SetVertexColor(BUTTON_STYLE.normalColor.r, BUTTON_STYLE.normalColor.g, BUTTON_STYLE.normalColor.b, BUTTON_STYLE.normalColor.a)
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

function PetBar:SetupPetButtonOverlays(button, config)
    if not button then return end
    
    -- Cooldown frame (pet actions have cooldowns)
    if config.showCooldowns then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
        button.cooldown:SetDrawBling(false)
        button.cooldown:SetDrawEdge(true)
    end
    
    -- Auto-cast indicator for pet abilities
    button.autoCast = button:CreateTexture(nil, "OVERLAY")
    button.autoCast:SetAllPoints(button)
    button.autoCast:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
    button.autoCast:SetBlendMode("ADD")
    button.autoCast:Hide()
    
    -- Auto-cast shine effect
    button.autoCastShine = CreateFrame("Frame", nil, button)
    button.autoCastShine:SetAllPoints(button)
    button.autoCastShine:SetFrameLevel(button:GetFrameLevel() + 2)
end

function PetBar:SetupStanceButtonOverlays(button, config)
    if not button then return end
    
    -- Cooldown frame (stance changes can have cooldowns)
    if config.showCooldowns then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
        button.cooldown:SetDrawBling(false)
        button.cooldown:SetDrawEdge(true)
    end
end

function PetBar:ApplyAuroraStyling()
    -- Apply styling to pet buttons
    for _, button in pairs(self.petButtons) do
        if button and button.damiaConfig then
            self:SetupButtonStyling(button, button.damiaConfig)
        end
    end
    
    -- Apply styling to stance buttons
    for _, button in pairs(self.stanceButtons) do
        if button and button.damiaConfig then
            self:SetupButtonStyling(button, button.damiaConfig)
        end
    end
    
    DamiaUI.Engine:LogDebug("Aurora styling applied to pet and stance bars")
end

--[[
===============================================================================
EVENT HANDLING AND UPDATES
===============================================================================
--]]

function PetBar:RegisterEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            self:OnEvent(event, ...)
        end)
    end
    
    -- Pet-related events
    if self.petBar then
        self.eventFrame:RegisterEvent("UNIT_PET")
        self.eventFrame:RegisterEvent("PET_BAR_UPDATE")
        self.eventFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
        self.eventFrame:RegisterEvent("UNIT_PET_EXPERIENCE")
    end
    
    -- Stance-related events
    if self.stanceBar then
        self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
        self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        self.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    end
    
    -- General events
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function PetBar:OnEvent(event, ...)
    if event == "UNIT_PET" then
        local unitID = ...
        if unitID == "player" then
            self:UpdatePetBarVisibility()
            self:UpdatePetButtons()
        end
    elseif event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_COOLDOWN" then
        self:UpdatePetButtons()
    elseif event == "UPDATE_SHAPESHIFT_FORMS" or event == "UPDATE_SHAPESHIFT_COOLDOWN" then
        self:UpdateStanceBarVisibility()
        self:UpdateStanceButtons()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Initial update
        C_Timer.After(1, function()
            self:UpdateVisibility()
            self:UpdateAllButtons()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:HandleCombatStateChange(false)
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:HandleCombatStateChange(true)
    end
end

--[[
===============================================================================
VISIBILITY MANAGEMENT
===============================================================================
--]]

function PetBar:UpdateVisibility()
    self:UpdatePetBarVisibility()
    self:UpdateStanceBarVisibility()
end

function PetBar:UpdatePetBarVisibility()
    if not self.petBar then return end
    
    local config = self.petBar.damiaConfig
    if not config then return end
    
    local shouldShow = UnitExists("pet")
    
    if config.autoHide then
        if shouldShow and not self.petBarVisible then
            -- Show pet bar
            UIFrameFadeIn(self.petBar, 0.3, self.petBar:GetAlpha(), 1.0)
            self.petBarVisible = true
        elseif not shouldShow and self.petBarVisible then
            -- Hide pet bar with delay
            C_Timer.After(PET_BAR_CONFIG.fadeDelay, function()
                if not UnitExists("pet") then
                    UIFrameFadeOut(self.petBar, 0.3, self.petBar:GetAlpha(), 0.0)
                    self.petBarVisible = false
                end
            end)
        end
    else
        -- Always show if auto-hide is disabled
        if not self.petBarVisible then
            self.petBar:SetAlpha(1.0)
            self.petBar:Show()
            self.petBarVisible = true
        end
    end
end

function PetBar:UpdateStanceBarVisibility()
    if not self.stanceBar then return end
    
    local config = self.stanceBar.damiaConfig
    if not config then return end
    
    local numForms = GetNumShapeshiftForms()
    local shouldShow = numForms > 0
    
    if config.autoHide then
        if shouldShow and not self.stanceBarVisible then
            -- Show stance bar
            UIFrameFadeIn(self.stanceBar, 0.3, self.stanceBar:GetAlpha(), 1.0)
            self.stanceBarVisible = true
        elseif not shouldShow and self.stanceBarVisible then
            -- Hide stance bar
            UIFrameFadeOut(self.stanceBar, 0.3, self.stanceBar:GetAlpha(), 0.0)
            self.stanceBarVisible = false
        end
    else
        -- Always show if auto-hide is disabled
        if not self.stanceBarVisible then
            self.stanceBar:SetAlpha(1.0)
            self.stanceBar:Show()
            self.stanceBarVisible = true
        end
    end
end

--[[
===============================================================================
BUTTON STATE UPDATES
===============================================================================
--]]

function PetBar:UpdateAllButtons()
    self:UpdatePetButtons()
    self:UpdateStanceButtons()
end

function PetBar:UpdatePetButtons()
    if not self.petButtons then return end
    
    for i, button in pairs(self.petButtons) do
        if button then
            self:UpdatePetButton(button, i)
        end
    end
end

function PetBar:UpdatePetButton(button, petSlot)
    if not button then return end
    
    local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(petSlot)
    
    -- Update cooldown
    if button.cooldown then
        local start, duration, enabled = GetPetActionCooldown(petSlot)
        if start and duration and duration > 0 and enabled == 1 then
            button.cooldown:SetCooldown(start, duration)
            button.cooldown:Show()
        else
            button.cooldown:Hide()
        end
    end
    
    -- Update auto-cast indicators
    if button.autoCast then
        if autoCastEnabled then
            button.autoCast:Show()
        else
            button.autoCast:Hide()
        end
    end
    
    -- Update usability
    local isUsable = GetPetActionSlotUsable(petSlot)
    local icon = button.icon or button:GetNormalTexture()
    if icon then
        if isUsable then
            icon:SetVertexColor(1, 1, 1, 1)
        else
            icon:SetVertexColor(0.4, 0.4, 0.4, 1)
        end
    end
end

function PetBar:UpdateStanceButtons()
    if not self.stanceButtons then return end
    
    for i, button in pairs(self.stanceButtons) do
        if button then
            self:UpdateStanceButton(button, i)
        end
    end
end

function PetBar:UpdateStanceButton(button, stanceSlot)
    if not button then return end
    
    local texture, isActive, isCastable = GetShapeshiftFormInfo(stanceSlot)
    
    -- Update cooldown
    if button.cooldown then
        local start, duration, enabled = GetShapeshiftFormCooldown(stanceSlot)
        if start and duration and duration > 0 and enabled == 1 then
            button.cooldown:SetCooldown(start, duration)
            button.cooldown:Show()
        else
            button.cooldown:Hide()
        end
    end
    
    -- Update checked state for active stance
    if button.GetCheckedTexture then
        local checkedTexture = button:GetCheckedTexture()
        if checkedTexture then
            if isActive then
                checkedTexture:Show()
            else
                checkedTexture:Hide()
            end
        end
    end
    
    -- Update usability
    local icon = button.icon or button:GetNormalTexture()
    if icon then
        if isCastable then
            icon:SetVertexColor(1, 1, 1, 1)
        else
            icon:SetVertexColor(0.4, 0.4, 0.4, 1)
        end
    end
end

--[[
===============================================================================
LAYOUT AND STATE MANAGEMENT
===============================================================================
--]]

function PetBar:UpdateLayout()
    -- Safe layout update with combat lockdown protection
    if CombatLockdown then
        CombatLockdown:SafeUpdateActionBars(function()
            if self.petBar then
                self:PositionPetBar()
                -- Update pet button layout if needed
            end
            
            if self.stanceBar then
                self:PositionStanceBar()
            end
        end)
    else
        if InCombatLockdown() then
            DamiaUI.Engine:LogWarning("Pet/Stance bar layout update deferred due to combat lockdown")
            return false
        end
        
        if self.petBar then
            self:PositionPetBar()
            -- Update pet button layout if needed
        end
        
        if self.stanceBar then
            self:PositionStanceBar()
            -- Update stance button layout if needed
        end
    end
    
    return true
end

function PetBar:HandleCombatStateChange(inCombat)
    -- Handle combat-specific behavior for pet and stance bars
    if self.petBar and self.petBar.damiaConfig and self.petBar.damiaConfig.fadeOnCombat then
        if inCombat then
            UIFrameFadeOut(self.petBar, 0.2, self.petBar:GetAlpha(), self.petBar.damiaConfig.fadeAlpha or 0.5)
        else
            UIFrameFadeIn(self.petBar, 0.2, self.petBar:GetAlpha(), 1.0)
        end
    end
    
    if self.stanceBar and self.stanceBar.damiaConfig and self.stanceBar.damiaConfig.fadeOnCombat then
        if inCombat then
            UIFrameFadeOut(self.stanceBar, 0.2, self.stanceBar:GetAlpha(), self.stanceBar.damiaConfig.fadeAlpha or 0.5)
        else
            UIFrameFadeIn(self.stanceBar, 0.2, self.stanceBar:GetAlpha(), 1.0)
        end
    end
end

--[[
===============================================================================
PUBLIC API
===============================================================================
--]]

function PetBar:IsInitialized()
    return self.initialized
end

function PetBar:GetPetBar()
    return self.petBar
end

function PetBar:GetStanceBar()
    return self.stanceBar
end

function PetBar:GetPetButton(index)
    return self.petButtons[index]
end

function PetBar:GetStanceButton(index)
    return self.stanceButtons[index]
end

function PetBar:ShowPetBar()
    if self.petBar then
        self.petBar:Show()
        self.petBarVisible = true
        return true
    end
    return false
end

function PetBar:HidePetBar()
    if self.petBar then
        self.petBar:Hide()
        self.petBarVisible = false
        return true
    end
    return false
end

function PetBar:ShowStanceBar()
    if self.stanceBar then
        self.stanceBar:Show()
        self.stanceBarVisible = true
        return true
    end
    return false
end

function PetBar:HideStanceBar()
    if self.stanceBar then
        self.stanceBar:Hide()
        self.stanceBarVisible = false
        return true
    end
    return false
end

function PetBar:Cleanup()
    -- Unregister events
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame = nil
    end
    
    -- Cleanup pet bar
    if self.petBar then
        self.petBar:Hide()
        self.petBar:SetParent(nil)
        self.petBar = nil
    end
    
    -- Cleanup stance bar
    if self.stanceBar then
        self.stanceBar:Hide()
        self.stanceBar:SetParent(nil)
        self.stanceBar = nil
    end
    
    -- Cleanup button references
    for _, button in pairs(self.petButtons) do
        if button then
            button:Hide()
            button:SetParent(nil)
        end
    end
    
    for _, button in pairs(self.stanceButtons) do
        if button then
            button:Hide()
            button:SetParent(nil)
        end
    end
    
    self.petButtons = {}
    self.stanceButtons = {}
    self.initialized = false
    self.petBarVisible = false
    self.stanceBarVisible = false
    
    DamiaUI.Engine:LogDebug("Pet and stance bars cleaned up")
end

-- Export PetBar module
DamiaUI.PetBar = PetBar