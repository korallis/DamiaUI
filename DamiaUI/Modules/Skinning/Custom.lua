--[[
    DamiaUI Custom Frame Styling Module
    
    Provides custom styling utilities and preset themes for creating
    consistent visual elements across all DamiaUI components.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local math = math
local tinsert = table.insert

-- Initialize Custom styling module
local CustomStyling = {}
DamiaUI.Skinning = DamiaUI.Skinning or {}
DamiaUI.Skinning.Custom = CustomStyling

-- Module state
local Aurora
local customStyledFrames = {}
local stylePresets = {}
local animationGroups = {}
local highContrastMode = false

-- Damia UI color scheme with variations
local DAMIA_COLORS = {
    -- Core colors
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    backgroundLight = { r = 0.15, g = 0.15, b = 0.15, a = 0.95 },
    backgroundDark = { r = 0.05, g = 0.05, b = 0.05, a = 0.95 },
    
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    borderLight = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 },
    borderDark = { r = 0.2, g = 0.2, b = 0.2, a = 1.0 },
    
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Signature orange
    accentLight = { r = 1.0, g = 0.6, b = 0.2, a = 1.0 },
    accentDark = { r = 0.6, g = 0.4, b = 0.0, a = 1.0 },
    
    highlight = { r = 1.0, g = 0.6, b = 0.2, a = 0.3 },
    highlightStrong = { r = 1.0, g = 0.6, b = 0.2, a = 0.6 },
    
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textSecondary = { r = 0.8, g = 0.8, b = 0.8, a = 1.0 },
    textDisabled = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
    textSuccess = { r = 0.0, g = 1.0, b = 0.0, a = 1.0 },
    textWarning = { r = 1.0, g = 1.0, b = 0.0, a = 1.0 },
    textError = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
    
    -- High contrast variants
    hcBackground = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
    hcBorder = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    hcAccent = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
    hcHighlight = { r = 1.0, g = 1.0, b = 1.0, a = 0.8 },
    hcText = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
}

-- Style presets for common frame types
local STYLE_PRESETS = {
    ["unitFrame"] = {
        background = DAMIA_COLORS.backgroundDark,
        border = DAMIA_COLORS.borderLight,
        borderSize = 1,
        cornerRadius = 0,
        gradient = {
            orientation = "VERTICAL",
            startColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.9 },
            endColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 }
        },
        shadow = {
            enabled = true,
            color = { r = 0.0, g = 0.0, b = 0.0, a = 0.8 },
            offset = { x = 2, y = -2 },
            blur = 4
        }
    },
    
    ["actionButton"] = {
        background = DAMIA_COLORS.background,
        border = DAMIA_COLORS.border,
        borderSize = 1,
        cornerRadius = 2,
        hover = {
            background = DAMIA_COLORS.backgroundLight,
            border = DAMIA_COLORS.accent,
            glow = {
                enabled = true,
                color = DAMIA_COLORS.accent,
                strength = 0.5
            }
        },
        pressed = {
            background = DAMIA_COLORS.backgroundDark,
            border = DAMIA_COLORS.accentDark
        }
    },
    
    ["panel"] = {
        background = DAMIA_COLORS.background,
        border = DAMIA_COLORS.border,
        borderSize = 1,
        cornerRadius = 0,
        gradient = {
            orientation = "VERTICAL",
            startColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.95 },
            endColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 }
        },
        titleBar = {
            enabled = true,
            height = 24,
            background = DAMIA_COLORS.accent,
            textColor = DAMIA_COLORS.text,
            fontSize = 12,
            fontFlags = "OUTLINE"
        }
    },
    
    ["statusBar"] = {
        background = DAMIA_COLORS.backgroundDark,
        border = DAMIA_COLORS.border,
        borderSize = 1,
        texture = "Interface\\Buttons\\WHITE8X8",
        orientation = "HORIZONTAL",
        smoothFill = true,
        spark = {
            enabled = true,
            texture = "Interface\\CastingBar\\UI-CastingBar-Spark",
            width = 16,
            height = 24
        },
        gradient = {
            enabled = true,
            startColor = DAMIA_COLORS.accent,
            endColor = DAMIA_COLORS.accentDark
        }
    },
    
    ["tooltip"] = {
        background = DAMIA_COLORS.backgroundDark,
        border = DAMIA_COLORS.borderLight,
        borderSize = 1,
        cornerRadius = 0,
        fade = {
            enabled = true,
            fadeInTime = 0.15,
            fadeOutTime = 0.1
        },
        shadow = {
            enabled = true,
            color = { r = 0.0, g = 0.0, b = 0.0, a = 0.9 },
            offset = { x = 3, y = -3 },
            blur = 6
        }
    },
    
    ["editBox"] = {
        background = DAMIA_COLORS.backgroundDark,
        border = DAMIA_COLORS.border,
        borderSize = 1,
        cornerRadius = 2,
        padding = { left = 5, right = 5, top = 2, bottom = 2 },
        focus = {
            border = DAMIA_COLORS.accent,
            glow = {
                enabled = true,
                color = DAMIA_COLORS.accent,
                strength = 0.3
            }
        },
        disabled = {
            background = { r = 0.05, g = 0.05, b = 0.05, a = 0.5 },
            textColor = DAMIA_COLORS.textDisabled
        }
    },
    
    ["dropdown"] = {
        background = DAMIA_COLORS.background,
        border = DAMIA_COLORS.border,
        borderSize = 1,
        cornerRadius = 0,
        button = {
            background = DAMIA_COLORS.backgroundLight,
            border = DAMIA_COLORS.border,
            hover = {
                background = DAMIA_COLORS.accent,
                textColor = DAMIA_COLORS.text
            }
        },
        menu = {
            background = DAMIA_COLORS.backgroundDark,
            border = DAMIA_COLORS.borderLight,
            maxHeight = 200
        }
    }
}

--[[
    Initialization and Setup
]]

function CustomStyling:Initialize()
    if not self:ValidateAurora() then
        DamiaUI:LogWarning("Custom Styling: Aurora not available, using fallback methods")
    end
    
    -- Setup style presets
    self:InitializeStylePresets()
    
    -- Load configuration
    self:LoadConfiguration()
    
    DamiaUI:LogDebug("Custom styling system initialized")
    return true
end

function CustomStyling:ValidateAurora()
    Aurora = DamiaUI.Libraries.Aurora or _G.Aurora
    return Aurora ~= nil
end

function CustomStyling:InitializeStylePresets()
    for presetName, preset in pairs(STYLE_PRESETS) do
        stylePresets[presetName] = preset
    end
end

function CustomStyling:LoadConfiguration()
    -- Load high contrast mode setting
    highContrastMode = DamiaUI.Config.Get("skinning.highContrastMode", false)
    
    -- Load custom color overrides
    local customColors = DamiaUI.Config.Get("skinning.customColors", {})
    for colorName, color in pairs(customColors) do
        if DAMIA_COLORS[colorName] then
            DAMIA_COLORS[colorName] = color
        end
    end
end

--[[
    Core Styling Functions
]]

function CustomStyling:ApplyPresetStyle(frame, presetName, overrides)
    if not frame or not presetName then
        return false
    end
    
    local preset = stylePresets[presetName]
    if not preset then
        DamiaUI:LogWarning("Style preset not found: " .. presetName)
        return false
    end
    
    -- Apply overrides
    if overrides then
        preset = self:MergeStyleData(preset, overrides)
    end
    
    -- Apply high contrast adjustments if enabled
    if highContrastMode then
        preset = self:ApplyHighContrastMode(preset)
    end
    
    local success = pcall(function()
        self:ApplyStyleToFrame(frame, preset)
    end)
    
    if success then
        customStyledFrames[frame] = { preset = presetName, style = preset }
        DamiaUI:LogDebug("Applied preset style: " .. presetName)
    end
    
    return success
end

function CustomStyling:ApplyStyleToFrame(frame, style)
    if not frame or not style then
        return
    end
    
    -- Background
    if style.background then
        self:CreateStyledBackground(frame, style.background, style.gradient)
    end
    
    -- Border
    if style.border then
        self:CreateStyledBorder(frame, style.border, style.borderSize, style.cornerRadius)
    end
    
    -- Shadow
    if style.shadow and style.shadow.enabled then
        self:CreateFrameShadow(frame, style.shadow)
    end
    
    -- Title bar
    if style.titleBar and style.titleBar.enabled then
        self:CreateTitleBar(frame, style.titleBar)
    end
    
    -- Interactive states (for buttons)
    if style.hover or style.pressed then
        self:SetupInteractiveStates(frame, style)
    end
    
    -- Special elements
    if style.spark then
        self:CreateStatusBarSpark(frame, style.spark)
    end
end

function CustomStyling:CreateStyledBackground(frame, backgroundColor, gradient)
    if not frame then
        return
    end
    
    -- Remove existing background
    if frame.damiaBackground then
        frame.damiaBackground:Hide()
    end
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    
    if gradient and gradient.orientation then
        -- Create gradient background
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetGradientAlpha(
            gradient.orientation,
            gradient.startColor.r, gradient.startColor.g, gradient.startColor.b, gradient.startColor.a,
            gradient.endColor.r, gradient.endColor.g, gradient.endColor.b, gradient.endColor.a
        )
    else
        -- Solid color background
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
    end
    
    frame.damiaBackground = bg
end

function CustomStyling:CreateStyledBorder(frame, borderColor, borderSize, cornerRadius)
    if not frame then
        return
    end
    
    borderSize = borderSize or 1
    cornerRadius = cornerRadius or 0
    
    -- Remove existing border
    if frame.damiaBorder then
        frame.damiaBorder:Hide()
    end
    
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints(frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    local backdrop = {
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderSize,
    }
    
    -- Add corner radius if specified
    if cornerRadius > 0 then
        backdrop.bgFile = "Interface\\Buttons\\WHITE8X8"
        backdrop.tile = false
        backdrop.insets = { left = cornerRadius, right = cornerRadius, top = cornerRadius, bottom = cornerRadius }
    end
    
    border:SetBackdrop(backdrop)
    border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    
    frame.damiaBorder = border
end

function CustomStyling:CreateFrameShadow(frame, shadowStyle)
    if not frame or not shadowStyle then
        return
    end
    
    -- Remove existing shadow
    if frame.damiaShadow then
        frame.damiaShadow:Hide()
    end
    
    local shadow = CreateFrame("Frame", nil, frame)
    shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", shadowStyle.offset.x, shadowStyle.offset.y)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", shadowStyle.offset.x, shadowStyle.offset.y)
    
    shadow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    
    shadow:SetBackdropColor(
        shadowStyle.color.r,
        shadowStyle.color.g,
        shadowStyle.color.b,
        shadowStyle.color.a
    )
    
    frame.damiaShadow = shadow
end

function CustomStyling:CreateTitleBar(frame, titleStyle)
    if not frame or not titleStyle then
        return
    end
    
    -- Remove existing title bar
    if frame.damiaTitleBar then
        frame.damiaTitleBar:Hide()
    end
    
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(titleStyle.height or 24)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 2)
    
    -- Title bar background
    local bg = titleBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(titleBar)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(titleStyle.background.r, titleStyle.background.g, titleStyle.background.b, titleStyle.background.a)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetFont("Fonts\\FRIZQT__.TTF", titleStyle.fontSize or 12, titleStyle.fontFlags or "OUTLINE")
    titleText:SetTextColor(titleStyle.textColor.r, titleStyle.textColor.g, titleStyle.textColor.b, titleStyle.textColor.a)
    
    if frame.GetTitle and frame:GetTitle() then
        titleText:SetText(frame:GetTitle())
    elseif frame:GetName() then
        titleText:SetText(frame:GetName())
    else
        titleText:SetText("DamiaUI")
    end
    
    titleBar.text = titleText
    frame.damiaTitleBar = titleBar
end

function CustomStyling:SetupInteractiveStates(frame, style)
    if not frame or frame:GetObjectType() ~= "Button" then
        return
    end
    
    -- Store original colors
    local originalBg = frame.damiaBackground
    local originalBorder = frame.damiaBorder
    
    -- Hover state
    if style.hover then
        if frame.SetHighlightTexture then
            frame:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local highlight = frame:GetHighlightTexture()
            if highlight then
                if style.hover.background then
                    highlight:SetVertexColor(
                        style.hover.background.r,
                        style.hover.background.g,
                        style.hover.background.b,
                        style.hover.background.a or 0.3
                    )
                end
            end
        end
        
        -- Hover glow effect
        if style.hover.glow and style.hover.glow.enabled then
            self:CreateButtonGlow(frame, style.hover.glow)
        end
    end
    
    -- Pressed state
    if style.pressed then
        if frame.SetPushedTexture then
            frame:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
            local pushed = frame:GetPushedTexture()
            if pushed and style.pressed.background then
                pushed:SetVertexColor(
                    style.pressed.background.r,
                    style.pressed.background.g,
                    style.pressed.background.b,
                    style.pressed.background.a or 0.5
                )
            end
        end
    end
end

function CustomStyling:CreateButtonGlow(frame, glowStyle)
    if not frame or not glowStyle then
        return
    end
    
    -- Remove existing glow
    if frame.damiaGlow then
        frame.damiaGlow:Hide()
    end
    
    local glow = CreateFrame("Frame", nil, frame)
    glow:SetAllPoints(frame)
    glow:SetFrameLevel(frame:GetFrameLevel() + 3)
    
    local glowTexture = glow:CreateTexture(nil, "OVERLAY")
    glowTexture:SetAllPoints(glow)
    glowTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
    glowTexture:SetVertexColor(
        glowStyle.color.r,
        glowStyle.color.g,
        glowStyle.color.b,
        0 -- Start invisible
    )
    glowTexture:SetBlendMode("ADD")
    
    -- Animation
    local fadeIn = glow:CreateAnimationGroup()
    local fadeInAlpha = fadeIn:CreateAnimation("Alpha")
    fadeInAlpha:SetFromAlpha(0)
    fadeInAlpha:SetToAlpha(glowStyle.strength or 0.5)
    fadeInAlpha:SetDuration(0.2)
    fadeInAlpha:SetSmoothing("OUT")
    
    local fadeOut = glow:CreateAnimationGroup()
    local fadeOutAlpha = fadeOut:CreateAnimation("Alpha")
    fadeOutAlpha:SetFromAlpha(glowStyle.strength or 0.5)
    fadeOutAlpha:SetToAlpha(0)
    fadeOutAlpha:SetDuration(0.2)
    fadeOutAlpha:SetSmoothing("IN")
    
    -- Hook to button events
    frame:HookScript("OnEnter", function() fadeIn:Play() end)
    frame:HookScript("OnLeave", function() fadeOut:Play() end)
    
    glow:Hide() -- Start hidden
    frame.damiaGlow = glow
end

function CustomStyling:CreateStatusBarSpark(frame, sparkStyle)
    if not frame or frame:GetObjectType() ~= "StatusBar" then
        return
    end
    
    -- Remove existing spark
    if frame.damiaSpark then
        frame.damiaSpark:Hide()
    end
    
    local spark = frame:CreateTexture(nil, "OVERLAY")
    spark:SetTexture(sparkStyle.texture or "Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetSize(sparkStyle.width or 16, sparkStyle.height or 24)
    spark:SetBlendMode("ADD")
    
    -- Position spark based on status bar value
    local function UpdateSparkPosition()
        local value = frame:GetValue()
        local min, max = frame:GetMinMaxValues()
        
        if max > min then
            local percent = (value - min) / (max - min)
            local width = frame:GetWidth()
            spark:SetPoint("CENTER", frame, "LEFT", width * percent, 0)
            spark:SetShown(percent > 0 and percent < 1)
        else
            spark:Hide()
        end
    end
    
    -- Hook value changes
    frame:HookScript("OnValueChanged", UpdateSparkPosition)
    UpdateSparkPosition() -- Initial position
    
    frame.damiaSpark = spark
end

--[[
    High Contrast Mode
]]

function CustomStyling:ApplyHighContrastMode(style)
    if not style or not highContrastMode then
        return style
    end
    
    local hcStyle = {}
    for key, value in pairs(style) do
        hcStyle[key] = value
    end
    
    -- Override colors with high contrast variants
    hcStyle.background = DAMIA_COLORS.hcBackground
    hcStyle.border = DAMIA_COLORS.hcBorder
    
    if hcStyle.gradient then
        hcStyle.gradient.startColor = DAMIA_COLORS.hcBackground
        hcStyle.gradient.endColor = DAMIA_COLORS.hcBackground
    end
    
    if hcStyle.hover then
        hcStyle.hover.background = DAMIA_COLORS.hcHighlight
        hcStyle.hover.border = DAMIA_COLORS.hcAccent
    end
    
    if hcStyle.titleBar then
        hcStyle.titleBar.background = DAMIA_COLORS.hcAccent
        hcStyle.titleBar.textColor = DAMIA_COLORS.hcText
    end
    
    return hcStyle
end

function CustomStyling:SetHighContrastMode(enabled)
    if highContrastMode == enabled then
        return
    end
    
    highContrastMode = enabled
    DamiaUI.Config.Set("skinning.highContrastMode", enabled)
    
    -- Refresh all styled frames
    self:RefreshAllCustomStyles()
    
    DamiaUI:LogDebug("High contrast mode " .. (enabled and "enabled" or "disabled"))
end

function CustomStyling:IsHighContrastMode()
    return highContrastMode
end

--[[
    Animation System
]]

function CustomStyling:CreateFadeAnimation(frame, duration, fromAlpha, toAlpha, onComplete)
    if not frame then
        return
    end
    
    local animGroup = frame:CreateAnimationGroup()
    local fadeAnim = animGroup:CreateAnimation("Alpha")
    
    fadeAnim:SetFromAlpha(fromAlpha or 0)
    fadeAnim:SetToAlpha(toAlpha or 1)
    fadeAnim:SetDuration(duration or 0.3)
    fadeAnim:SetSmoothing("OUT")
    
    if onComplete then
        fadeAnim:SetScript("OnFinished", onComplete)
    end
    
    tinsert(animationGroups, animGroup)
    return animGroup
end

function CustomStyling:CreateSlideAnimation(frame, duration, startX, startY, endX, endY, onComplete)
    if not frame then
        return
    end
    
    local animGroup = frame:CreateAnimationGroup()
    local slideAnim = animGroup:CreateAnimation("Translation")
    
    slideAnim:SetOffset(endX - startX, endY - startY)
    slideAnim:SetDuration(duration or 0.3)
    slideAnim:SetSmoothing("OUT")
    
    if onComplete then
        slideAnim:SetScript("OnFinished", onComplete)
    end
    
    tinsert(animationGroups, animGroup)
    return animGroup
end

function CustomStyling:CreateScaleAnimation(frame, duration, fromScale, toScale, onComplete)
    if not frame then
        return
    end
    
    local animGroup = frame:CreateAnimationGroup()
    local scaleAnim = animGroup:CreateAnimation("Scale")
    
    scaleAnim:SetScale(fromScale or 0.1, fromScale or 0.1)
    scaleAnim:SetToScale(toScale or 1, toScale or 1)
    scaleAnim:SetDuration(duration or 0.3)
    scaleAnim:SetSmoothing("OUT")
    
    if onComplete then
        scaleAnim:SetScript("OnFinished", onComplete)
    end
    
    tinsert(animationGroups, animGroup)
    return animGroup
end

--[[
    Utility Functions
]]

function CustomStyling:MergeStyleData(base, overrides)
    local merged = {}
    
    -- Deep copy base
    for key, value in pairs(base) do
        if type(value) == "table" then
            merged[key] = {}
            for subKey, subValue in pairs(value) do
                merged[key][subKey] = subValue
            end
        else
            merged[key] = value
        end
    end
    
    -- Apply overrides
    for key, value in pairs(overrides) do
        if type(value) == "table" and merged[key] and type(merged[key]) == "table" then
            for subKey, subValue in pairs(value) do
                merged[key][subKey] = subValue
            end
        else
            merged[key] = value
        end
    end
    
    return merged
end

function CustomStyling:GetColorByName(colorName)
    return DAMIA_COLORS[colorName]
end

function CustomStyling:SetCustomColor(colorName, color)
    if DAMIA_COLORS[colorName] then
        DAMIA_COLORS[colorName] = color
        
        -- Save to configuration
        local customColors = DamiaUI.Config.Get("skinning.customColors", {})
        customColors[colorName] = color
        DamiaUI.Config.Set("skinning.customColors", customColors)
        
        -- Refresh affected frames
        self:RefreshColorDependentFrames(colorName)
    end
end

function CustomStyling:RefreshColorDependentFrames(colorName)
    -- Find frames using the changed color and refresh them
    for frame, frameData in pairs(customStyledFrames) do
        if self:StyleUsesColor(frameData.style, colorName) then
            self:ApplyStyleToFrame(frame, frameData.style)
        end
    end
end

function CustomStyling:StyleUsesColor(style, colorName)
    -- Recursively check if style uses the specified color
    if not style then
        return false
    end
    
    for key, value in pairs(style) do
        if type(value) == "table" then
            if value == DAMIA_COLORS[colorName] then
                return true
            elseif self:StyleUsesColor(value, colorName) then
                return true
            end
        end
    end
    
    return false
end

--[[
    Public API
]]

function CustomStyling:CreateUnitFrameStyle(frame, options)
    return self:ApplyPresetStyle(frame, "unitFrame", options)
end

function CustomStyling:CreateActionButtonStyle(frame, options)
    return self:ApplyPresetStyle(frame, "actionButton", options)
end

function CustomStyling:CreatePanelStyle(frame, options)
    return self:ApplyPresetStyle(frame, "panel", options)
end

function CustomStyling:CreateStatusBarStyle(frame, options)
    return self:ApplyPresetStyle(frame, "statusBar", options)
end

function CustomStyling:CreateTooltipStyle(frame, options)
    return self:ApplyPresetStyle(frame, "tooltip", options)
end

function CustomStyling:CreateEditBoxStyle(frame, options)
    return self:ApplyPresetStyle(frame, "editBox", options)
end

function CustomStyling:CreateDropdownStyle(frame, options)
    return self:ApplyPresetStyle(frame, "dropdown", options)
end

function CustomStyling:RemoveCustomStyle(frame)
    if not frame or not customStyledFrames[frame] then
        return false
    end
    
    -- Remove custom elements
    if frame.damiaBackground then
        frame.damiaBackground:Hide()
    end
    if frame.damiaBorder then
        frame.damiaBorder:Hide()
    end
    if frame.damiaShadow then
        frame.damiaShadow:Hide()
    end
    if frame.damiaTitleBar then
        frame.damiaTitleBar:Hide()
    end
    if frame.damiaGlow then
        frame.damiaGlow:Hide()
    end
    if frame.damiaSpark then
        frame.damiaSpark:Hide()
    end
    
    customStyledFrames[frame] = nil
    return true
end

function CustomStyling:RefreshAllCustomStyles()
    for frame, frameData in pairs(customStyledFrames) do
        if frame and frame:IsValid() then
            self:ApplyPresetStyle(frame, frameData.preset, frameData.overrides)
        else
            customStyledFrames[frame] = nil
        end
    end
end

function CustomStyling:GetStyledFrameCount()
    local count = 0
    for _ in pairs(customStyledFrames) do
        count = count + 1
    end
    return count
end

function CustomStyling:AddStylePreset(name, preset)
    stylePresets[name] = preset
end

function CustomStyling:GetStylePreset(name)
    return stylePresets[name]
end

function CustomStyling:GetAllColorNames()
    local colors = {}
    for colorName in pairs(DAMIA_COLORS) do
        tinsert(colors, colorName)
    end
    return colors
end

-- Initialize when called
if DamiaUI.Skinning then
    DamiaUI.Skinning.Custom = CustomStyling
end