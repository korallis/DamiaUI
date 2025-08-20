-- DamiaUI Arena Unit Frames
-- Based on oUF_Coldkil layout, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF
if not oUF then return end
local UnitFrames = ns.UnitFrames

-- Arena frame layout (ColdUI style)
function UnitFrames:CreateArenaFrame(self)
    self:SetSize(180, 30)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture(ns.media.texture)
    health.frequentUpdates = true
    health.Smooth = true
    health.colorClass = true
    
    -- Health background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.media.texture)
    health.bg.multiplier = 0.3
    
    -- Health border
    ns:CreateBackdrop(health)
    
    -- Health text
    health.value = health:CreateFontString(nil, "OVERLAY")
    health.value:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    health.value:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    self:Tag(health.value, "[coldhp]")
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
    power:SetHeight(5)
    power:SetStatusBarTexture(ns.media.texture)
    power.colorPower = true
    
    -- Power background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints()
    power.bg:SetTexture(ns.media.texture)
    power.bg.multiplier = 0.3
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    self:Tag(name, "[name]")
    
    -- Trinket tracker
    local trinket = CreateFrame("Frame", nil, self)
    trinket:SetSize(25, 25)
    trinket:SetPoint("RIGHT", self, "LEFT", -5, 0)
    ns:CreateBackdrop(trinket)
    
    trinket.icon = trinket:CreateTexture(nil, "ARTWORK")
    trinket.icon:SetAllPoints()
    trinket.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    trinket.cooldown = CreateFrame("Cooldown", nil, trinket, "CooldownFrameTemplate")
    trinket.cooldown:SetAllPoints()
    
    -- Castbar
    local castbar = CreateFrame("StatusBar", nil, self)
    castbar:SetSize(180, 18)
    castbar:SetPoint("TOP", self, "BOTTOM", 0, -2)
    castbar:SetStatusBarTexture(ns.media.texture)
    castbar:SetStatusBarColor(0.7, 0.3, 0.3)
    
    castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
    castbar.bg:SetAllPoints()
    castbar.bg:SetTexture(ns.media.texture)
    castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)
    
    ns:CreateBackdrop(castbar)
    
    castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
    castbar.Text:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    castbar.Text:SetPoint("LEFT", castbar, "LEFT", 2, 0)
    
    -- Assign to self
    self.Health = health
    self.Power = power
    self.Name = name
    self.Trinket = trinket
    self.Castbar = castbar
end