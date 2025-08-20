-- DamiaUI Rune Bar for Death Knights
-- Based on oUF_Coldkil runebar, updated for WoW 11.2

local addonName, ns = ...
local oUF = ns.oUF or _G.oUF
local UnitFrames = ns.UnitFrames

-- Death Knight Rune Bar (ColdUI style)
function UnitFrames:CreateRuneBar(self)
    local _, class = UnitClass("player")
    if class ~= "DEATHKNIGHT" then return end
    
    -- Create rune frame
    local runes = CreateFrame("Frame", nil, self)
    runes:SetSize(200, 8)
    runes:SetPoint("TOP", self, "BOTTOM", 0, -2)
    
    -- Create individual runes
    for i = 1, 6 do
        local rune = CreateFrame("StatusBar", nil, runes)
        rune:SetSize(31, 8)
        rune:SetStatusBarTexture(ns.media.texture)
        
        -- Position runes
        if i == 1 then
            rune:SetPoint("LEFT", runes, "LEFT", 0, 0)
        else
            rune:SetPoint("LEFT", runes[i-1], "RIGHT", 2, 0)
        end
        
        -- Rune background
        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetAllPoints()
        rune.bg:SetTexture(ns.media.texture)
        rune.bg:SetVertexColor(0.1, 0.1, 0.1)
        
        -- Rune border
        local border = CreateFrame("Frame", nil, rune, "BackdropTemplate")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({
            edgeFile = ns.media.texture,
            edgeSize = 1,
        })
        border:SetBackdropBorderColor(0, 0, 0, 1)
        
        runes[i] = rune
    end
    
    -- Update rune colors
    runes.UpdateColor = function(self, event, rid)
        local rune = self[rid]
        if not rune then return end
        
        local _, _, ready = GetRuneCooldown(rid)
        if ready then
            rune:SetStatusBarColor(0.7, 0.7, 0.7)  -- Ready color
        else
            rune:SetStatusBarColor(0.3, 0.3, 0.3)  -- On cooldown
        end
    end
    
    -- oUF element assignment
    self.Runes = runes
    
    return runes
end

-- Combo Points for Rogues/Druids (ColdUI style)
function UnitFrames:CreateComboPoints(self)
    local _, class = UnitClass("player")
    if class ~= "ROGUE" and class ~= "DRUID" then return end
    
    -- Create combo point frame
    local combo = CreateFrame("Frame", nil, self)
    combo:SetSize(200, 8)
    combo:SetPoint("TOP", self, "BOTTOM", 0, -2)
    
    -- Create individual combo points
    local maxCombo = 5
    if class == "ROGUE" then
        maxCombo = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
    end
    
    for i = 1, maxCombo do
        local point = combo:CreateTexture(nil, "ARTWORK")
        point:SetSize(35, 8)
        point:SetTexture(ns.media.texture)
        point:SetVertexColor(1, 0.9, 0)
        
        -- Position points
        if i == 1 then
            point:SetPoint("LEFT", combo, "LEFT", 0, 0)
        else
            point:SetPoint("LEFT", combo[i-1], "RIGHT", 2, 0)
        end
        
        combo[i] = point
    end
    
    -- oUF element assignment
    self.CPoints = combo
    
    return combo
end