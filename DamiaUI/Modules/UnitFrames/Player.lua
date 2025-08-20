-- DamiaUI Player Unit Frame
-- Based on oUF_Coldkil layout, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF or _G.oUF
local UnitFrames = ns.UnitFrames

-- Player frame layout (ColdUI style)
function UnitFrames:CreatePlayerFrame(self)
    self:SetSize(200, 30)
    
    local _, myClass = UnitClass("player")
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture(ns.media.texture)
    health:SetStatusBarColor(0.1, 0.8, 0.1)
    health.frequentUpdates = true
    health.Smooth = true
    
    -- Health background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.media.texture)
    health.bg:SetVertexColor(0.1, 0.1, 0.1)
    
    -- Health border
    local healthBorder = CreateFrame("Frame", nil, health, "BackdropTemplate")
    healthBorder:SetPoint("TOPLEFT", -1, 1)
    healthBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    healthBorder:SetBackdrop({
        edgeFile = ns.media.texture,
        edgeSize = 1,
    })
    healthBorder:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Health text
    health.value = health:CreateFontString(nil, "OVERLAY")
    health.value:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    health.value:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    self:Tag(health.value, "[dead][offline][coldhp]")
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
    power:SetHeight(5)
    power:SetStatusBarTexture(ns.media.texture)
    power.frequentUpdates = true
    power.Smooth = true
    
    -- Power background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints()
    power.bg:SetTexture(ns.media.texture)
    power.bg.multiplier = 0.3
    
    -- Power border
    local powerBorder = CreateFrame("Frame", nil, power, "BackdropTemplate")
    powerBorder:SetPoint("TOPLEFT", -1, 1)
    powerBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    powerBorder:SetBackdrop({
        edgeFile = ns.media.texture,
        edgeSize = 1,
    })
    powerBorder:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Power text
    power.value = power:CreateFontString(nil, "OVERLAY")
    power.value:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    power.value:SetPoint("RIGHT", power, "RIGHT", -2, 0)
    self:Tag(power.value, "[powercolor][curpp]")
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    self:Tag(name, "[name]")
    
    -- Class-specific resources (combo points, runes, etc.)
    if myClass == "DEATHKNIGHT" then
        -- Add rune bar
    elseif myClass == "ROGUE" or myClass == "DRUID" then
        -- Add combo points
    end
    
    -- Castbar
    local castbar = CreateFrame("StatusBar", nil, self)
    castbar:SetSize(200, 20)
    castbar:SetPoint("TOP", self, "BOTTOM", 0, -5)
    castbar:SetStatusBarTexture(ns.media.texture)
    castbar:SetStatusBarColor(0.7, 0.7, 0.3)
    
    -- Castbar background
    castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
    castbar.bg:SetAllPoints()
    castbar.bg:SetTexture(ns.media.texture)
    castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)
    
    -- Castbar border
    ns:CreateBackdrop(castbar)
    
    -- Castbar text
    castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
    castbar.Text:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    castbar.Text:SetPoint("LEFT", castbar, "LEFT", 2, 0)
    
    -- Castbar time
    castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
    castbar.Time:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -2, 0)
    
    -- Assign to self
    self.Health = health
    self.Power = power
    self.Name = name
    self.Castbar = castbar
end