--[[
    DamiaUI - Aurora Styling Integration for Unit Frames
    Comprehensive dark theme styling using embedded Aurora framework
    
    Applies consistent Aurora dark styling to all unit frame elements including
    health bars, power bars, casting bars, and custom frame borders.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

-- Module dependencies (will be properly loaded via addon initialization)
local Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora

-- Aurora styling module
local AuroraStyling = {}

-- Damia UI specific color theme extending Aurora
local DAMIA_COLORS = {
    -- Background colors
    backdrop = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    backdropSecondary = { r = 0.15, g = 0.15, b = 0.15, a = 0.90 },
    
    -- Border colors
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    borderHighlight = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Damia orange accent
    borderActive = { r = 1.0, g = 0.7, b = 0.2, a = 1.0 },
    
    -- Text colors
    textPrimary = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textSecondary = { r = 0.8, g = 0.8, b = 0.8, a = 1.0 },
    textMuted = { r = 0.6, g = 0.6, b = 0.6, a = 0.8 },
    textAccent = { r = 1.0, g = 0.82, b = 0.0, a = 1.0 },
    
    -- Status bar colors
    health = { r = 0.2, g = 0.8, b = 0.2, a = 1.0 },
    healthLow = { r = 0.8, g = 0.2, b = 0.2, a = 1.0 },
    mana = { r = 0.2, g = 0.4, b = 0.8, a = 1.0 },
    energy = { r = 1.0, g = 1.0, b = 0.2, a = 1.0 },
    rage = { r = 0.8, g = 0.2, b = 0.2, a = 1.0 },
    focus = { r = 1.0, g = 0.5, b = 0.25, a = 1.0 },
    
    -- Casting bar colors
    casting = { r = 1.0, g = 0.7, b = 0.0, a = 1.0 },
    castingUninterruptible = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
    channeling = { r = 0.2, g = 0.8, b = 0.2, a = 1.0 }
}

-- Texture paths for consistent styling
local DAMIA_TEXTURES = {
    statusbar = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\Statusbar",
    statusbarSmooth = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\StatusbarSmooth",
    backdrop = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\Backdrop",
    border = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\Border",
    highlight = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\Highlight"
}

--[[
    Apply Aurora dark styling to a status bar
]]
function AuroraStyling.StyleStatusBar(statusbar, barType, useGlow)
    if not statusbar or not Aurora then return end
    
    barType = barType or "default"
    
    -- Set texture
    local texture = DAMIA_TEXTURES.statusbarSmooth or "Interface\\TargetingFrame\\UI-StatusBar"
    statusbar:SetStatusBarTexture(texture)
    
    -- Apply border if Aurora CreateBorder is available
    if Aurora.CreateBorder then
        Aurora.CreateBorder(statusbar, 8)
    else
        -- Fallback border creation
        AuroraStyling.CreateSimpleBorder(statusbar)
    end
    
    -- Create background
    if not statusbar.bg then
        statusbar.bg = statusbar:CreateTexture(nil, "BORDER")
        statusbar.bg:SetAllPoints(statusbar)
        statusbar.bg:SetTexture(texture)
        
        local backdrop = DAMIA_COLORS.backdrop
        statusbar.bg:SetVertexColor(backdrop.r, backdrop.g, backdrop.b, backdrop.a * 0.3)
    end
    
    -- Add subtle glow effect for active elements
    if useGlow and not statusbar.glow then
        statusbar.glow = statusbar:CreateTexture(nil, "ARTWORK", nil, 7)
        statusbar.glow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        statusbar.glow:SetAllPoints(statusbar)
        statusbar.glow:SetBlendMode("ADD")
        statusbar.glow:SetAlpha(0)
        
        -- Animate glow on updates
        statusbar:HookScript("OnValueChanged", function(self, value)
            if value and value > 0 then
                self.glow:SetAlpha(0.1)
            else
                self.glow:SetAlpha(0)
            end
        end)
    end
end

--[[
    Create a simple border when Aurora is not available
]]
function AuroraStyling.CreateSimpleBorder(frame, borderSize)
    borderSize = borderSize or 1
    
    if frame.damiaBorder then return end
    
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints(frame)
    border:SetFrameStrata(frame:GetFrameStrata())
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    -- Create border textures
    local borderColor = DAMIA_COLORS.border
    
    -- Top
    local top = border:CreateTexture(nil, "BORDER")
    top:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    top:SetPoint("TOPLEFT", border, "TOPLEFT")
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    top:SetHeight(borderSize)
    
    -- Bottom
    local bottom = border:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    bottom:SetHeight(borderSize)
    
    -- Left
    local left = border:CreateTexture(nil, "BORDER")
    left:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    left:SetPoint("TOPLEFT", border, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    left:SetWidth(borderSize)
    
    -- Right
    local right = border:CreateTexture(nil, "BORDER")
    right:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    right:SetWidth(borderSize)
    
    frame.damiaBorder = border
    return border
end

--[[
    Apply comprehensive styling to a unit frame
]]
function AuroraStyling.StyleUnitFrame(frame, frameType)
    if not frame then return end
    
    frameType = frameType or "default"
    
    -- Style the main frame
    AuroraStyling.StyleFrame(frame)
    
    -- Style health bar
    if frame.Health then
        AuroraStyling.StyleStatusBar(frame.Health, "health", true)
        AuroraStyling.StyleHealthBar(frame.Health, frameType)
    end
    
    -- Style power bar
    if frame.Power then
        AuroraStyling.StyleStatusBar(frame.Power, "power", false)
        AuroraStyling.StylePowerBar(frame.Power, frameType)
    end
    
    -- Style casting bar
    if frame.Castbar then
        AuroraStyling.StyleStatusBar(frame.Castbar, "casting", true)
        AuroraStyling.StyleCastingBar(frame.Castbar, frameType)
    end
    
    -- Style text elements
    AuroraStyling.StyleTextElements(frame, frameType)
    
    -- Apply frame-specific styling
    if frameType == "player" then
        AuroraStyling.StylePlayerFrame(frame)
    elseif frameType == "target" then
        AuroraStyling.StyleTargetFrame(frame)
    elseif frameType == "focus" then
        AuroraStyling.StyleFocusFrame(frame)
    end
end

--[[
    Apply basic frame styling
]]
function AuroraStyling.StyleFrame(frame)
    if not frame then return end
    
    -- Apply backdrop
    local backdrop = DAMIA_COLORS.backdrop
    if Aurora and Aurora.SetBackdrop then
        Aurora.SetBackdrop(frame, {
            bgFile = DAMIA_TEXTURES.backdrop,
            edgeFile = DAMIA_TEXTURES.border,
            tile = false,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        Aurora.SetBackdropColor(frame, backdrop.r, backdrop.g, backdrop.b, backdrop.a)
    else
        -- Create simple background
        if not frame.damiaBackground then
            frame.damiaBackground = frame:CreateTexture(nil, "BACKGROUND")
            frame.damiaBackground:SetAllPoints(frame)
            frame.damiaBackground:SetColorTexture(backdrop.r, backdrop.g, backdrop.b, backdrop.a)
        end
        
        -- Create border
        AuroraStyling.CreateSimpleBorder(frame, 2)
    end
end

--[[
    Style health bar with dynamic coloring
]]
function AuroraStyling.StyleHealthBar(healthBar, frameType)
    if not healthBar then return end
    
    -- Hook value changes for dynamic coloring
    healthBar:HookScript("OnValueChanged", function(self, value)
        local min, max = self:GetMinMaxValues()
        if max > 0 then
            local percent = (value / max) * 100
            local color = DAMIA_COLORS.health
            
            -- Color based on health percentage
            if percent < 25 then
                color = DAMIA_COLORS.healthLow
            elseif percent < 50 then
                -- Blend between low and normal
                local blend = (percent - 25) / 25
                color = {
                    r = DAMIA_COLORS.healthLow.r * (1 - blend) + DAMIA_COLORS.health.r * blend,
                    g = DAMIA_COLORS.healthLow.g * (1 - blend) + DAMIA_COLORS.health.g * blend,
                    b = DAMIA_COLORS.healthLow.b * (1 - blend) + DAMIA_COLORS.health.b * blend,
                    a = 1.0
                }
            end
            
            self:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
    end)
end

--[[
    Style power bar with power type detection
]]
function AuroraStyling.StylePowerBar(powerBar, frameType)
    if not powerBar then return end
    
    -- Hook power updates for dynamic coloring
    powerBar:HookScript("OnValueChanged", function(self, value)
        local frame = self:GetParent()
        if frame and frame.unit then
            local powerType = UnitPowerType(frame.unit)
            local color = DAMIA_COLORS.mana -- default
            
            if powerType == Enum.PowerType.Mana then
                color = DAMIA_COLORS.mana
            elseif powerType == Enum.PowerType.Rage then
                color = DAMIA_COLORS.rage
            elseif powerType == Enum.PowerType.Energy then
                color = DAMIA_COLORS.energy
            elseif powerType == Enum.PowerType.Focus then
                color = DAMIA_COLORS.focus
            end
            
            self:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
    end)
end

--[[
    Style casting bar with interrupt detection
]]
function AuroraStyling.StyleCastingBar(castbar, frameType)
    if not castbar then return end
    
    -- Default casting color
    local color = DAMIA_COLORS.casting
    castbar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

--[[
    Style all text elements consistently
]]
function AuroraStyling.StyleTextElements(frame, frameType)
    if not frame then return end
    
    local scale = frame:GetScale() or 1.0
    
    -- Style name text
    if frame.Name then
        local color = DAMIA_COLORS.textPrimary
        frame.Name:SetTextColor(color.r, color.g, color.b, color.a)
        frame.Name:SetFont("Fonts\\FRIZQT__.TTF", 12 * scale, "OUTLINE")
    end
    
    -- Style health value text
    if frame.HealthValue then
        local color = DAMIA_COLORS.textPrimary
        frame.HealthValue:SetTextColor(color.r, color.g, color.b, color.a)
        frame.HealthValue:SetFont("Fonts\\FRIZQT__.TTF", 11 * scale, "OUTLINE")
    end
    
    -- Style power value text
    if frame.PowerValue then
        local color = DAMIA_COLORS.textSecondary
        frame.PowerValue:SetTextColor(color.r, color.g, color.b, color.a)
        frame.PowerValue:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    end
    
    -- Style level text
    if frame.Level then
        local color = DAMIA_COLORS.textAccent
        frame.Level:SetTextColor(color.r, color.g, color.b, color.a)
        frame.Level:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    end
    
    -- Style classification text
    if frame.Classification then
        local color = DAMIA_COLORS.borderHighlight
        frame.Classification:SetTextColor(color.r, color.g, color.b, color.a)
        frame.Classification:SetFont("Fonts\\FRIZQT__.TTF", 8 * scale, "OUTLINE")
    end
end

--[[
    Player frame specific styling
]]
function AuroraStyling.StylePlayerFrame(frame)
    -- Add subtle player frame glow
    if not frame.playerGlow then
        frame.playerGlow = frame:CreateTexture(nil, "BACKGROUND")
        frame.playerGlow:SetAllPoints(frame)
        frame.playerGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        frame.playerGlow:SetBlendMode("ADD")
        frame.playerGlow:SetVertexColor(0.2, 0.4, 0.8, 0.1) -- Subtle blue
        frame.playerGlow:SetAlpha(0.1)
    end
end

--[[
    Target frame specific styling
]]
function AuroraStyling.StyleTargetFrame(frame)
    -- Target frames get threat-aware styling handled in Target.lua
    -- This provides the base styling foundation
end

--[[
    Focus frame specific styling
]]
function AuroraStyling.StyleFocusFrame(frame)
    -- Add subtle focus glow
    if not frame.focusGlow then
        frame.focusGlow = frame:CreateTexture(nil, "BACKGROUND")
        frame.focusGlow:SetAllPoints(frame)
        frame.focusGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        frame.focusGlow:SetBlendMode("ADD")
        frame.focusGlow:SetVertexColor(0.8, 0.4, 0.0, 0.1) -- Subtle orange
        frame.focusGlow:SetAlpha(0.1)
    end
end

--[[
    Initialize Aurora styling system
]]
function AuroraStyling.Initialize()
    -- Check if Aurora is available
    if not Aurora then
        DamiaUI:Print("Aurora library not found, using fallback styling")
        return false
    end
    
    -- Initialize Aurora with Damia UI settings
    if Aurora.InitializeSettings then
        Aurora.InitializeSettings({
            customColors = DAMIA_COLORS,
            textures = DAMIA_TEXTURES
        })
    end
    
    return true
end

--[[
    Get Damia UI color theme
]]
function AuroraStyling.GetColors()
    return DAMIA_COLORS
end

--[[
    Get Damia UI texture paths
]]
function AuroraStyling.GetTextures()
    return DAMIA_TEXTURES
end

-- Export the module
DamiaUI.AuroraStyling = AuroraStyling