-- DamiaUI Party Unit Frames
-- Based on oUF_Coldkil layout, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF or _G.oUF
local UnitFrames = ns.UnitFrames

-- Party frame layout (ColdUI style)
function UnitFrames:CreatePartyFrame(self)
    self:SetSize(150, 20)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture(ns.media.texture)
    health.frequentUpdates = true
    health.Smooth = true
    health.colorClass = true
    health.colorReaction = true
    
    -- Health background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.media.texture)
    health.bg.multiplier = 0.3
    
    -- Health border
    ns:CreateBackdrop(health)
    
    -- Health text
    health.value = health:CreateFontString(nil, "OVERLAY")
    health.value:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    health.value:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    self:Tag(health.value, "[perhp]%")
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
    power:SetHeight(3)
    power:SetStatusBarTexture(ns.media.texture)
    power.colorPower = true
    
    -- Power background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints()
    power.bg:SetTexture(ns.media.texture)
    power.bg.multiplier = 0.3
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    self:Tag(name, "[name:short]")
    
    -- Range indicator
    local range = self:CreateTexture(nil, "OVERLAY")
    range:SetAllPoints()
    
    -- Assign to self
    self.Health = health
    self.Power = power
    self.Name = name
    self.Range = {
        insideAlpha = 1,
        outsideAlpha = 0.5,
    }
end