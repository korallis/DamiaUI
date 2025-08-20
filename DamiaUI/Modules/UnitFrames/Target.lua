-- DamiaUI Target Unit Frame
-- Based on oUF_Coldkil layout, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF or _G.oUF
local UnitFrames = ns.UnitFrames

-- Target frame layout (ColdUI style)
function UnitFrames:CreateTargetFrame(self)
    self:SetSize(200, 30)
    
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
    power.colorPower = true
    
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
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    self:Tag(name, "[difficulty][level][shortclassification] [name]")
    
    -- Buffs
    local buffs = CreateFrame("Frame", nil, self)
    buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
    buffs:SetSize(200, 20)
    buffs.size = 20
    buffs.spacing = 2
    buffs.num = 8
    buffs["growth-x"] = "RIGHT"
    buffs["growth-y"] = "UP"
    buffs.initialAnchor = "BOTTOMLEFT"
    buffs.PostCreateIcon = function(buffs, button)
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        ns:CreateBackdrop(button)
    end
    
    -- Debuffs
    local debuffs = CreateFrame("Frame", nil, self)
    debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
    debuffs:SetSize(200, 20)
    debuffs.size = 20
    debuffs.spacing = 2
    debuffs.num = 8
    debuffs["growth-x"] = "RIGHT"
    debuffs["growth-y"] = "DOWN"
    debuffs.initialAnchor = "TOPLEFT"
    debuffs.onlyShowPlayer = true
    debuffs.PostCreateIcon = function(debuffs, button)
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        ns:CreateBackdrop(button)
    end
    
    -- Castbar
    local castbar = CreateFrame("StatusBar", nil, self)
    castbar:SetSize(200, 20)
    castbar:SetPoint("TOP", self, "BOTTOM", 0, -25)
    castbar:SetStatusBarTexture(ns.media.texture)
    castbar:SetStatusBarColor(0.7, 0.3, 0.3)
    
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
    self.Buffs = buffs
    self.Debuffs = debuffs
    self.Castbar = castbar
end