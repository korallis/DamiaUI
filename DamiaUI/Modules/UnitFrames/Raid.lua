-- DamiaUI Raid Unit Frames
-- Based on oUF_Coldkil layout, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF or _G.oUF
local UnitFrames = ns.UnitFrames

-- Raid frame layout (ColdUI style)
function UnitFrames:CreateRaidFrame(self)
    self:SetSize(80, 25)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture(ns.media.texture)
    health.frequentUpdates = true
    health.colorClass = true
    health.colorReaction = true
    health.colorDisconnected = true
    
    -- Health background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.media.texture)
    health.bg.multiplier = 0.3
    
    -- Health border
    ns:CreateBackdrop(health)
    
    -- Health deficit
    health.value = health:CreateFontString(nil, "OVERLAY")
    health.value:SetFont(ns.media.font, 9, "OUTLINE, MONOCHROME")
    health.value:SetPoint("CENTER", health, "CENTER", 0, 0)
    self:Tag(health.value, "[raidhp]")
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 9, "OUTLINE, MONOCHROME")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    self:Tag(name, "[name:short]")
    
    -- Role icon
    local role = health:CreateTexture(nil, "OVERLAY")
    role:SetSize(12, 12)
    role:SetPoint("TOPRIGHT", health, "TOPRIGHT", -2, -2)
    
    -- Raid icon
    local raidicon = health:CreateTexture(nil, "OVERLAY")
    raidicon:SetSize(12, 12)
    raidicon:SetPoint("TOP", health, "TOP", 0, 2)
    
    -- Range indicator
    local range = self:CreateTexture(nil, "OVERLAY")
    range:SetAllPoints()
    
    -- Assign to self
    self.Health = health
    self.Name = name
    self.GroupRoleIndicator = role
    self.RaidTargetIndicator = raidicon
    self.Range = {
        insideAlpha = 1,
        outsideAlpha = 0.3,
    }
end