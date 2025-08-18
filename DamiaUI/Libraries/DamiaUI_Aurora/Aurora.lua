--[[
    DamiaUI Custom Aurora Skinning Library
    
    A comprehensive skinning framework inspired by Aurora but built specifically 
    for DamiaUI with WoW 11.2 compatibility and the signature dark theme with 
    orange accents (r=0.8, g=0.5, b=0.1).
    
    This library provides:
    - Core skinning framework with backdrop API compatibility
    - DamiaUI color scheme integration
    - Button, frame, and statusbar styling
    - Shadow and glow effects
    - Skinning templates for common frame types
    
    Author: DamiaUI Development Team
    Version: 1.0.0
    WoW Compatibility: 11.2+
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI or {}

-- Create Aurora namespace
local Aurora = {}
DamiaUI.Libraries = DamiaUI.Libraries or {}
DamiaUI.Libraries.Aurora = Aurora

-- Local references for performance
local _G = _G
local type, pairs, ipairs = type, pairs, ipairs
local unpack, select = unpack, select
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

-- WoW 11.2 Backdrop API compatibility check
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

--[[
    Core Configuration and Constants
]]

-- DamiaUI signature color scheme
Aurora.Colors = {
    -- Primary theme colors
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    backgroundDark = { r = 0.05, g = 0.05, b = 0.05, a = 0.98 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    borderDark = { r = 0.15, g = 0.15, b = 0.15, a = 1.0 },
    
    -- DamiaUI signature orange accent
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 },
    accentBright = { r = 1.0, g = 0.6, b = 0.2, a = 1.0 },
    accentDark = { r = 0.6, g = 0.4, b = 0.08, a = 1.0 },
    
    -- UI interaction colors
    highlight = { r = 1.0, g = 0.6, b = 0.2, a = 0.3 },
    selected = { r = 0.8, g = 0.5, b = 0.1, a = 0.5 },
    pressed = { r = 0.6, g = 0.4, b = 0.08, a = 0.7 },
    
    -- Text colors
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textBright = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
    textDisabled = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
    
    -- Status colors
    health = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
    mana = { r = 0.0, g = 0.4, b = 0.8, a = 1.0 },
    rage = { r = 0.8, g = 0.0, b = 0.0, a = 1.0 },
    energy = { r = 1.0, g = 1.0, b = 0.0, a = 1.0 },
    
    -- Shadow and glow effects
    shadow = { r = 0.0, g = 0.0, b = 0.0, a = 0.8 },
    glow = { r = 0.8, g = 0.5, b = 0.1, a = 0.6 },
    glowBright = { r = 1.0, g = 0.7, b = 0.3, a = 0.8 },
}

-- Texture paths optimized for WoW 11.2
Aurora.Textures = {
    -- Background textures
    background = "Interface\\ChatFrame\\ChatFrameBackground",
    backgroundTile = "Interface\\Tooltips\\UI-Tooltip-Background",
    
    -- Border textures
    border = "Interface\\Buttons\\WHITE8X8",
    borderGlow = "Interface\\Buttons\\WHITE8X8",
    
    -- Button textures
    buttonNormal = "Interface\\Buttons\\UI-Panel-Button-Up",
    buttonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    buttonPressed = "Interface\\Buttons\\UI-Panel-Button-Down",
    buttonDisabled = "Interface\\Buttons\\UI-Panel-Button-Disabled",
    
    -- Statusbar textures
    statusbar = "Interface\\TargetingFrame\\UI-StatusBar",
    statusbarSmooth = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    
    -- Special effect textures
    shadow = "Interface\\Tooltips\\UI-Tooltip-Background",
    glow = "Interface\\Buttons\\WHITE8X8",
}

-- Backdrop configurations for WoW 11.2 compatibility
Aurora.Backdrops = {
    -- Standard panel backdrop
    panel = {
        bgFile = Aurora.Textures.background,
        edgeFile = Aurora.Textures.border,
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },
    
    -- Button backdrop
    button = {
        bgFile = Aurora.Textures.background,
        edgeFile = Aurora.Textures.border,
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },
    
    -- Tooltip backdrop
    tooltip = {
        bgFile = Aurora.Textures.backgroundTile,
        edgeFile = Aurora.Textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    },
    
    -- Shadow backdrop
    shadow = {
        bgFile = Aurora.Textures.shadow,
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    },
}

-- Animation settings
Aurora.Animations = {
    fadeIn = { duration = 0.15, alpha = { from = 0, to = 1 } },
    fadeOut = { duration = 0.15, alpha = { from = 1, to = 0 } },
    highlight = { duration = 0.1, alpha = { from = 0, to = 0.3 } },
    glow = { duration = 0.3, alpha = { from = 0.6, to = 1.0 } },
}

-- Settings and configuration
Aurora.Settings = {
    useCustomColors = true,
    customColors = Aurora.Colors,
    useButtonGradientColour = true,
    useClassColours = false,
    useChatBubbleSkin = true,
    useNormalTexture = false,
    shadowSize = 4,
    glowSize = 2,
    animationSpeed = 0.15,
}

--[[
    Utility Functions
]]

-- Safe color application with validation
local function SetColorSafe(object, method, color)
    if not object or not color or not object[method] then
        return false
    end
    
    local r, g, b, a = color.r or 1, color.g or 1, color.b or 1, color.a or 1
    object[method](object, r, g, b, a)
    return true
end

-- Create WoW 11.2 compatible backdrop frame
local function CreateBackdropFrame(parent, template)
    local frame
    if BACKDROP_TEMPLATE then
        -- WoW 11.2+ with BackdropTemplate
        frame = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    else
        -- Pre-11.2 compatibility
        frame = CreateFrame("Frame", nil, parent)
        if BackdropTemplateMixin then
            Mixin(frame, BackdropTemplateMixin)
        end
    end
    return frame
end

-- Apply backdrop with WoW 11.2 compatibility
local function ApplyBackdrop(frame, backdropInfo)
    if not frame then return false end
    
    if frame.SetBackdrop then
        frame:SetBackdrop(backdropInfo)
        return true
    elseif BACKDROP_TEMPLATE and frame.SetBackdropInfo then
        frame:SetBackdropInfo(backdropInfo)
        return true
    end
    
    return false
end

-- Create shadow effect
local function CreateShadow(frame, size, color, offset)
    if frame.DamiaUIShadow then
        return frame.DamiaUIShadow
    end
    
    size = size or Aurora.Settings.shadowSize
    color = color or Aurora.Colors.shadow
    offset = offset or { x = 2, y = -2 }
    
    local shadow = CreateBackdropFrame(frame:GetParent() or UIParent)
    shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", offset.x, offset.y)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset.x, offset.y)
    
    ApplyBackdrop(shadow, Aurora.Backdrops.shadow)
    SetColorSafe(shadow, "SetBackdropColor", color)
    
    frame.DamiaUIShadow = shadow
    return shadow
end

-- Create glow effect
local function CreateGlow(frame, size, color)
    if frame.DamiaUIGlow then
        return frame.DamiaUIGlow
    end
    
    size = size or Aurora.Settings.glowSize
    color = color or Aurora.Colors.glow
    
    local glow = CreateBackdropFrame(frame:GetParent() or UIParent)
    glow:SetFrameLevel(frame:GetFrameLevel() - 1)
    glow:SetPoint("TOPLEFT", frame, "TOPLEFT", -size, size)
    glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", size, -size)
    
    ApplyBackdrop(glow, {
        bgFile = nil,
        edgeFile = Aurora.Textures.glow,
        tile = false,
        tileSize = 0,
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size }
    })
    
    SetColorSafe(glow, "SetBackdropBorderColor", color)
    glow:SetAlpha(0) -- Start hidden
    
    frame.DamiaUIGlow = glow
    return glow
end

--[[
    Core Skinning Functions
]]

Aurora.Skin = {}

-- Generic frame skinning
function Aurora.Skin.FrameTypeFrame(frame, options)
    if not frame then return false end
    
    options = options or {}
    local backdropInfo = options.backdrop or Aurora.Backdrops.panel
    local backgroundColor = options.backgroundColor or Aurora.Colors.background
    local borderColor = options.borderColor or Aurora.Colors.border
    local createShadow = options.shadow ~= false
    local createGlow = options.glow == true
    
    -- Apply backdrop
    if not ApplyBackdrop(frame, backdropInfo) then
        return false
    end
    
    -- Set colors
    SetColorSafe(frame, "SetBackdropColor", backgroundColor)
    SetColorSafe(frame, "SetBackdropBorderColor", borderColor)
    
    -- Create shadow effect
    if createShadow then
        CreateShadow(frame, options.shadowSize, options.shadowColor, options.shadowOffset)
    end
    
    -- Create glow effect
    if createGlow then
        CreateGlow(frame, options.glowSize, options.glowColor)
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "frame",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

-- Button skinning with interactive states
function Aurora.Skin.FrameTypeButton(frame, options)
    if not frame then return false end
    
    options = options or {}
    local backgroundColor = options.backgroundColor or Aurora.Colors.background
    local borderColor = options.borderColor or Aurora.Colors.border
    local highlightColor = options.highlightColor or Aurora.Colors.highlight
    local pressedColor = options.pressedColor or Aurora.Colors.pressed
    
    -- Apply base frame styling
    Aurora.Skin.FrameTypeFrame(frame, options)
    
    -- Remove default button textures
    if frame.SetNormalTexture then frame:SetNormalTexture("") end
    if frame.SetHighlightTexture then frame:SetHighlightTexture("") end
    if frame.SetPushedTexture then frame:SetPushedTexture("") end
    if frame.SetDisabledTexture then frame:SetDisabledTexture("") end
    
    -- Create highlight texture
    if not frame.DamiaUIHighlight then
        local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(frame)
        highlight:SetTexture(Aurora.Textures.background)
        SetColorSafe(highlight, "SetVertexColor", highlightColor)
        highlight:SetAlpha(0)
        frame.DamiaUIHighlight = highlight
        frame:SetHighlightTexture(highlight)
    end
    
    -- Create pressed state handler
    if not frame.DamiaUIPressedHandler then
        frame:HookScript("OnMouseDown", function(self)
            if self:IsEnabled() then
                SetColorSafe(self, "SetBackdropColor", pressedColor)
            end
        end)
        
        frame:HookScript("OnMouseUp", function(self)
            SetColorSafe(self, "SetBackdropColor", backgroundColor)
        end)
        
        frame:HookScript("OnLeave", function(self)
            SetColorSafe(self, "SetBackdropColor", backgroundColor)
        end)
        
        frame.DamiaUIPressedHandler = true
    end
    
    -- Handle disabled state
    if not frame.DamiaUIDisabledHandler then
        hooksecurefunc(frame, "SetEnabled", function(self, enabled)
            if enabled then
                SetColorSafe(self, "SetBackdropColor", backgroundColor)
                SetColorSafe(self, "SetBackdropBorderColor", borderColor)
            else
                SetColorSafe(self, "SetBackdropColor", Aurora.Colors.backgroundDark)
                SetColorSafe(self, "SetBackdropBorderColor", Aurora.Colors.borderDark)
            end
        end)
        
        frame.DamiaUIDisabledHandler = true
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "button",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

-- StatusBar skinning
function Aurora.Skin.FrameTypeStatusBar(frame, options)
    if not frame then return false end
    
    options = options or {}
    local backgroundColor = options.backgroundColor or Aurora.Colors.backgroundDark
    local borderColor = options.borderColor or Aurora.Colors.border
    local barColor = options.barColor or Aurora.Colors.accent
    local texture = options.texture or Aurora.Textures.statusbar
    
    -- Apply base frame styling
    Aurora.Skin.FrameTypeFrame(frame, options)
    
    -- Set statusbar texture and color
    if frame.SetStatusBarTexture then
        frame:SetStatusBarTexture(texture)
        SetColorSafe(frame, "SetStatusBarColor", barColor)
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "statusbar",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

-- CheckButton skinning
function Aurora.Skin.FrameTypeCheckButton(frame, options)
    if not frame then return false end
    
    options = options or {}
    
    -- Apply button styling first
    Aurora.Skin.FrameTypeButton(frame, options)
    
    -- Style the check texture
    if frame.SetCheckedTexture then
        local checkedTexture = frame:CreateTexture(nil, "ARTWORK")
        checkedTexture:SetTexture(Aurora.Textures.border)
        checkedTexture:SetPoint("CENTER")
        checkedTexture:SetSize(12, 12)
        SetColorSafe(checkedTexture, "SetVertexColor", Aurora.Colors.accent)
        frame:SetCheckedTexture(checkedTexture)
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "checkbutton",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

-- EditBox skinning
function Aurora.Skin.FrameTypeEditBox(frame, options)
    if not frame then return false end
    
    options = options or {}
    local backgroundColor = options.backgroundColor or Aurora.Colors.backgroundDark
    local borderColor = options.borderColor or Aurora.Colors.border
    local focusColor = options.focusColor or Aurora.Colors.accent
    
    -- Apply base frame styling
    Aurora.Skin.FrameTypeFrame(frame, options)
    
    -- Handle focus states
    if not frame.DamiaUIFocusHandler then
        frame:HookScript("OnEditFocusGained", function(self)
            SetColorSafe(self, "SetBackdropBorderColor", focusColor)
            if self.DamiaUIGlow then
                self.DamiaUIGlow:SetAlpha(0.3)
            end
        end)
        
        frame:HookScript("OnEditFocusLost", function(self)
            SetColorSafe(self, "SetBackdropBorderColor", borderColor)
            if self.DamiaUIGlow then
                self.DamiaUIGlow:SetAlpha(0)
            end
        end)
        
        frame.DamiaUIFocusHandler = true
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "editbox",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

-- ScrollFrame skinning
function Aurora.Skin.FrameTypeScrollFrame(frame, options)
    if not frame then return false end
    
    options = options or {}
    
    -- Apply base frame styling
    Aurora.Skin.FrameTypeFrame(frame, options)
    
    -- Style scrollbar if present
    if frame.ScrollBar then
        Aurora.Skin.FrameTypeFrame(frame.ScrollBar, {
            backgroundColor = Aurora.Colors.backgroundDark,
            borderColor = Aurora.Colors.border,
            shadow = false
        })
        
        -- Style thumb button
        if frame.ScrollBar.thumbTexture then
            local thumb = frame.ScrollBar.thumbTexture
            if thumb.SetVertexColor then
                SetColorSafe(thumb, "SetVertexColor", Aurora.Colors.accent)
            end
        end
    end
    
    -- Store skinning info
    frame.DamiaUIStyled = {
        type = "scrollframe",
        options = options,
        timestamp = GetTime()
    }
    
    return true
end

--[[
    Skinning Templates and Presets
]]

Aurora.Templates = {}

-- Panel template with various styles
Aurora.Templates.Panel = {
    default = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.background,
        borderColor = Aurora.Colors.border,
        shadow = true,
        glow = false
    },
    
    dark = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.backgroundDark,
        borderColor = Aurora.Colors.borderDark,
        shadow = true,
        glow = false
    },
    
    accent = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.background,
        borderColor = Aurora.Colors.accent,
        shadow = true,
        glow = true
    },
    
    minimal = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.background,
        borderColor = Aurora.Colors.border,
        shadow = false,
        glow = false
    }
}

-- Button template with various styles
Aurora.Templates.Button = {
    default = {
        backdrop = Aurora.Backdrops.button,
        backgroundColor = Aurora.Colors.background,
        borderColor = Aurora.Colors.border,
        highlightColor = Aurora.Colors.highlight,
        pressedColor = Aurora.Colors.pressed,
        shadow = true,
        glow = false
    },
    
    primary = {
        backdrop = Aurora.Backdrops.button,
        backgroundColor = Aurora.Colors.accent,
        borderColor = Aurora.Colors.accentDark,
        highlightColor = Aurora.Colors.accentBright,
        pressedColor = Aurora.Colors.accentDark,
        shadow = true,
        glow = false
    },
    
    minimal = {
        backdrop = Aurora.Backdrops.button,
        backgroundColor = Aurora.Colors.backgroundDark,
        borderColor = Aurora.Colors.borderDark,
        highlightColor = Aurora.Colors.highlight,
        pressedColor = Aurora.Colors.pressed,
        shadow = false,
        glow = false
    }
}

-- StatusBar template
Aurora.Templates.StatusBar = {
    health = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.backgroundDark,
        borderColor = Aurora.Colors.border,
        barColor = Aurora.Colors.health,
        texture = Aurora.Textures.statusbarSmooth,
        shadow = false,
        glow = false
    },
    
    mana = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.backgroundDark,
        borderColor = Aurora.Colors.border,
        barColor = Aurora.Colors.mana,
        texture = Aurora.Textures.statusbarSmooth,
        shadow = false,
        glow = false
    },
    
    experience = {
        backdrop = Aurora.Backdrops.panel,
        backgroundColor = Aurora.Colors.backgroundDark,
        borderColor = Aurora.Colors.border,
        barColor = Aurora.Colors.accent,
        texture = Aurora.Textures.statusbarSmooth,
        shadow = false,
        glow = false
    }
}

--[[
    High-Level Skinning Functions
]]

-- Apply template to frame
function Aurora:ApplyTemplate(frame, templateType, templateName, customOptions)
    if not frame or not Aurora.Templates[templateType] then
        return false
    end
    
    local template = Aurora.Templates[templateType][templateName]
    if not template then
        return false
    end
    
    -- Merge custom options with template
    local options = {}
    for k, v in pairs(template) do
        options[k] = v
    end
    
    if customOptions then
        for k, v in pairs(customOptions) do
            options[k] = v
        end
    end
    
    -- Apply appropriate skinning function
    local frameType = frame:GetObjectType()
    local skinFunction = Aurora.Skin["FrameType" .. frameType]
    
    if skinFunction then
        return skinFunction(frame, options)
    else
        -- Fallback to generic frame styling
        return Aurora.Skin.FrameTypeFrame(frame, options)
    end
end

-- Quick styling functions
function Aurora:StylePanel(frame, style, options)
    return self:ApplyTemplate(frame, "Panel", style or "default", options)
end

function Aurora:StyleButton(frame, style, options)
    return self:ApplyTemplate(frame, "Button", style or "default", options)
end

function Aurora:StyleStatusBar(frame, style, options)
    return self:ApplyTemplate(frame, "StatusBar", style or "health", options)
end

-- Create styled frame
function Aurora:CreateFrame(frameType, name, parent, template, style, options)
    local frame = CreateFrame(frameType, name, parent, template)
    
    if style then
        self:ApplyTemplate(frame, frameType, style, options)
    else
        -- Apply default styling based on frame type
        local skinFunction = self.Skin["FrameType" .. frameType]
        if skinFunction then
            skinFunction(frame, options)
        end
    end
    
    return frame
end

--[[
    Animation and Effect Functions
]]

-- Fade in animation
function Aurora:FadeIn(frame, duration, callback)
    if not frame then return end
    
    duration = duration or Aurora.Animations.fadeIn.duration
    frame:SetAlpha(0)
    frame:Show()
    
    local fadeIn = frame:CreateAnimationGroup()
    local alpha = fadeIn:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(duration)
    alpha:SetSmoothing("OUT")
    
    if callback then
        fadeIn:SetScript("OnFinished", callback)
    end
    
    fadeIn:Play()
    return fadeIn
end

-- Fade out animation
function Aurora:FadeOut(frame, duration, callback)
    if not frame then return end
    
    duration = duration or Aurora.Animations.fadeOut.duration
    
    local fadeOut = frame:CreateAnimationGroup()
    local alpha = fadeOut:CreateAnimation("Alpha")
    alpha:SetFromAlpha(frame:GetAlpha())
    alpha:SetToAlpha(0)
    alpha:SetDuration(duration)
    alpha:SetSmoothing("IN")
    
    fadeOut:SetScript("OnFinished", function()
        frame:Hide()
        if callback then callback() end
    end)
    
    fadeOut:Play()
    return fadeOut
end

-- Glow animation
function Aurora:AnimateGlow(frame, duration, callback)
    if not frame or not frame.DamiaUIGlow then return end
    
    duration = duration or Aurora.Animations.glow.duration
    local glow = frame.DamiaUIGlow
    
    local glowAnim = glow:CreateAnimationGroup()
    glowAnim:SetLooping("BOUNCE")
    
    local alpha = glowAnim:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.3)
    alpha:SetToAlpha(0.8)
    alpha:SetDuration(duration)
    alpha:SetSmoothing("SMOOTH")
    
    if callback then
        glowAnim:SetScript("OnFinished", callback)
    end
    
    glowAnim:Play()
    return glowAnim
end

--[[
    Utility and Management Functions
]]

-- Check if frame is already styled
function Aurora:IsStyled(frame)
    return frame and frame.DamiaUIStyled ~= nil
end

-- Remove styling from frame
function Aurora:RemoveStyle(frame)
    if not frame or not frame.DamiaUIStyled then
        return false
    end
    
    -- Remove shadow
    if frame.DamiaUIShadow then
        frame.DamiaUIShadow:Hide()
        frame.DamiaUIShadow:SetParent(nil)
        frame.DamiaUIShadow = nil
    end
    
    -- Remove glow
    if frame.DamiaUIGlow then
        frame.DamiaUIGlow:Hide()
        frame.DamiaUIGlow:SetParent(nil)
        frame.DamiaUIGlow = nil
    end
    
    -- Remove highlight
    if frame.DamiaUIHighlight then
        frame.DamiaUIHighlight:Hide()
        frame.DamiaUIHighlight:SetParent(nil)
        frame.DamiaUIHighlight = nil
    end
    
    -- Reset backdrop
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    elseif frame.SetBackdropInfo then
        frame:SetBackdropInfo(nil)
    end
    
    -- Clear styling info
    frame.DamiaUIStyled = nil
    
    return true
end

-- Get styling information
function Aurora:GetStyleInfo(frame)
    return frame and frame.DamiaUIStyled
end

-- Update color scheme
function Aurora:UpdateColorScheme(newColors)
    if not newColors then return end
    
    for colorName, color in pairs(newColors) do
        if Aurora.Colors[colorName] then
            Aurora.Colors[colorName] = color
        end
    end
    
    -- Update settings
    Aurora.Settings.customColors = Aurora.Colors
end

--[[
    Initialization and Registration
]]

-- Initialize the Aurora library
function Aurora:Initialize()
    -- Register with DamiaUI
    if DamiaUI and DamiaUI.Libraries then
        DamiaUI.Libraries.Aurora = self
    end
    
    -- Set up configuration
    self.Settings.customColors = self.Colors
    
    -- Initialize backdrop compatibility
    if not BACKDROP_TEMPLATE then
        -- Pre-11.2 compatibility setup if needed
    end
    
    return true
end

-- Auto-initialize when loaded
Aurora:Initialize()

-- Export for global access
_G.DamiaUIAurora = Aurora

return Aurora