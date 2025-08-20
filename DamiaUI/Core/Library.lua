-- DamiaUI Library Functions
-- Based on ColdUI lib.lua

local addonName, ns = ...

-- Create ColdUI-style backdrop with 11.2 compatibility
function ns:CreateBackdrop(frame, alpha)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    
    -- ColdUI backdrop configuration
    frame:SetBackdrop({
        bgFile = ns.media.buttonBackgroundFlat,
        tile = false,
        tileSize = 32,
        edgeSize = 5,
        insets = {left = 5, right = 5, top = 5.5, bottom = 5}
    })
    
    -- ColdUI colors
    frame:SetBackdropColor(0.2, 0.2, 0.2, alpha or 0.6)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

-- Style action button
function ns:StyleActionButton(button)
    if not button then return end
    
    local name = button:GetName()
    
    -- Remove default textures
    local normal = button:GetNormalTexture()
    if normal then normal:SetTexture(nil) end
    
    -- Style the button
    button:SetNormalTexture(ns.media.buttonBackground)
    button:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
    button:GetNormalTexture():SetVertexColor(0.3, 0.3, 0.3)
    
    -- Icon
    local icon = _G[name.."Icon"] or button.icon
    if icon then
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Cooldown
    local cooldown = _G[name.."Cooldown"] or button.cooldown
    if cooldown then
        cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Count
    local count = _G[name.."Count"] or button.Count
    if count then
        count:SetFont(ns.media.font, 12, "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Hotkey
    local hotkey = _G[name.."HotKey"] or button.HotKey
    if hotkey then
        hotkey:SetFont(ns.media.font, 11, "OUTLINE")
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    end
    
    -- Create backdrop
    if not button.backdrop then
        button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.backdrop:SetAllPoints()
        button.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
        ns:CreateBackdrop(button.backdrop)
    end
end

-- Create health bar
function ns:CreateHealthBar(parent, width, height)
    local health = CreateFrame("StatusBar", nil, parent)
    health:SetSize(width, height)
    health:SetStatusBarTexture(ns.media.texture)
    health:SetStatusBarColor(0.1, 0.8, 0.1)
    
    -- Background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.media.texture)
    health.bg:SetVertexColor(0.1, 0.1, 0.1)
    
    -- Text
    health.text = health:CreateFontString(nil, "OVERLAY")
    health.text:SetFont(ns.media.font, 11, "OUTLINE")
    health.text:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    
    return health
end

-- Create power bar
function ns:CreatePowerBar(parent, width, height)
    local power = CreateFrame("StatusBar", nil, parent)
    power:SetSize(width, height)
    power:SetStatusBarTexture(ns.media.texture)
    
    -- Background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints()
    power.bg:SetTexture(ns.media.texture)
    power.bg:SetVertexColor(0.1, 0.1, 0.1)
    
    -- Text
    power.text = power:CreateFontString(nil, "OVERLAY")
    power.text:SetFont(ns.media.font, 10, "OUTLINE")
    power.text:SetPoint("RIGHT", power, "RIGHT", -2, 0)
    
    -- Color by power type
    power.colorPower = true
    
    return power
end

-- Create cast bar
function ns:CreateCastBar(parent, width, height)
    local castbar = CreateFrame("StatusBar", nil, parent)
    castbar:SetSize(width, height)
    castbar:SetStatusBarTexture(ns.media.texture)
    castbar:SetStatusBarColor(0.7, 0.7, 0.3)
    
    -- Background
    castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
    castbar.bg:SetAllPoints()
    castbar.bg:SetTexture(ns.media.texture)
    castbar.bg:SetVertexColor(0.1, 0.1, 0.1)
    
    -- Border
    ns:CreateBackdrop(castbar)
    
    -- Text
    castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
    castbar.Text:SetFont(ns.media.font, 11, "OUTLINE")
    castbar.Text:SetPoint("LEFT", castbar, "LEFT", 2, 0)
    
    -- Time
    castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
    castbar.Time:SetFont(ns.media.font, 11, "OUTLINE")
    castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -2, 0)
    
    -- Icon
    castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
    castbar.Icon:SetSize(height, height)
    castbar.Icon:SetPoint("RIGHT", castbar, "LEFT", -4, 0)
    castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Icon border
    castbar.IconBorder = CreateFrame("Frame", nil, castbar, "BackdropTemplate")
    castbar.IconBorder:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -1, 1)
    castbar.IconBorder:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 1, -1)
    ns:CreateBackdrop(castbar.IconBorder)
    
    -- Spark
    castbar.Spark = castbar:CreateTexture(nil, "OVERLAY")
    castbar.Spark:SetSize(10, height * 1.5)
    castbar.Spark:SetBlendMode("ADD")
    castbar.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    
    return castbar
end

-- Abbreviate numbers
function ns:ShortValue(value)
    if not value then return "" end
    
    if value >= 1e9 then
        return format("%.1fb", value / 1e9)
    elseif value >= 1e6 then
        return format("%.1fm", value / 1e6)
    elseif value >= 1e3 then
        return format("%.1fk", value / 1e3)
    else
        return format("%d", value)
    end
end

-- RGB to Hex
function ns:RGBToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

-- Get class color
function ns:GetClassColor(class)
    local color = RAID_CLASS_COLORS[class]
    if color then
        return color.r, color.g, color.b
    else
        return 0.5, 0.5, 0.5
    end
end

-- Update health color
function ns:UpdateHealthColor(health, unit)
    if not unit then return end
    
    local r, g, b
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        r, g, b = ns:GetClassColor(class)
    else
        r, g, b = 0.1, 0.8, 0.1
    end
    
    health:SetStatusBarColor(r, g, b)
    if health.bg then
        health.bg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3)
    end
end

-- Update power color
function ns:UpdatePowerColor(power, unit)
    if not unit then return end
    
    local powerType = UnitPowerType(unit)
    local color = PowerBarColor[powerType]
    
    if color then
        power:SetStatusBarColor(color.r, color.g, color.b)
        if power.bg then
            power.bg:SetVertexColor(color.r * 0.3, color.g * 0.3, color.b * 0.3)
        end
    else
        power:SetStatusBarColor(0.5, 0.5, 0.5)
        if power.bg then
            power.bg:SetVertexColor(0.15, 0.15, 0.15)
        end
    end
end

-- Make frame movable
function ns:MakeMovable(frame, savePosition)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        if savePosition then
            local point, _, relativePoint, x, y = self:GetPoint()
            if not DamiaUICharDB.positions then
                DamiaUICharDB.positions = {}
            end
            DamiaUICharDB.positions[self:GetName()] = {point, relativePoint, x, y}
        end
    end)
end

-- Restore frame position
function ns:RestorePosition(frame)
    if DamiaUICharDB.positions and DamiaUICharDB.positions[frame:GetName()] then
        local pos = DamiaUICharDB.positions[frame:GetName()]
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
end

-- Skin button
function ns:SkinButton(button)
    if not button then return end
    
    -- Remove default textures
    if button.Left then button.Left:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.LeftDisabled then button.LeftDisabled:SetAlpha(0) end
    if button.MiddleDisabled then button.MiddleDisabled:SetAlpha(0) end
    if button.RightDisabled then button.RightDisabled:SetAlpha(0) end
    
    -- Add backdrop
    ns:CreateBackdrop(button)
    
    -- Adjust text
    if button.Text then
        button.Text:SetFont(ns.media.font, 11, "OUTLINE")
    end
    
    -- Highlight
    if button:GetHighlightTexture() then
        button:GetHighlightTexture():SetTexture(ns.media.texture)
        button:GetHighlightTexture():SetVertexColor(0.3, 0.3, 0.3, 0.3)
    end
end