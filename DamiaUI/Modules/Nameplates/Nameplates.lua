-- DamiaUI Nameplates Module
-- Based on ColdPlates, updated for WoW 11.2

local addonName, ns = ...

-- Create module
local Nameplates = {}
ns.Nameplates = Nameplates

-- Module registration
ns:RegisterModule("Nameplates", Nameplates)

-- Initialize module
function Nameplates:Initialize()
    -- Get config with defaults
    self.config = ns:GetConfig("nameplates") or {
        enabled = true,
        showSelf = false,
        showAll = true,
        showEnemies = true,
        showFriends = false,
        stacking = true,
        minScale = 0.8,
        maxScale = 1,
        minAlpha = 0.5,
        maxAlpha = 1,
        maxDistance = 40
    }
    
    if not self.config.enabled then
        return
    end
    
    -- Set CVars for nameplates
    self:SetupCVars()
    
    -- Register nameplate callbacks
    self:RegisterCallbacks()
    
    ns:Print("Nameplates module loaded")
end

-- Setup nameplate CVars (11.2 compatible)
function Nameplates:SetupCVars()
    -- Modern nameplate settings
    SetCVar("nameplateShowSelf", self.config.showSelf and 1 or 0)
    SetCVar("nameplateShowAll", self.config.showAll and 1 or 0)
    SetCVar("nameplateShowEnemies", self.config.showEnemies and 1 or 0)
    SetCVar("nameplateShowFriends", self.config.showFriends and 1 or 0)
    SetCVar("nameplateMotion", self.config.stacking and 1 or 0)  -- Stacking nameplates
    SetCVar("nameplateOverlapH", 0.8)
    SetCVar("nameplateOverlapV", 1.1)
    SetCVar("nameplateMinScale", self.config.minScale)
    SetCVar("nameplateMaxScale", self.config.maxScale)
    SetCVar("nameplateMinAlpha", self.config.minAlpha)
    SetCVar("nameplateMaxAlpha", self.config.maxAlpha)
    SetCVar("nameplateMaxDistance", self.config.maxDistance)
end

-- Style a nameplate (ColdUI style)
function Nameplates:StyleNameplate(nameplate)
    if not nameplate or nameplate.styled then return end
    
    local healthBar = nameplate.healthBar
    if not healthBar then return end
    
    -- Health bar texture
    healthBar:SetStatusBarTexture(ns.media.texture)
    
    -- Health bar backdrop
    if not healthBar.backdrop then
        healthBar.backdrop = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        healthBar.backdrop:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -1, 1)
        healthBar.backdrop:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 1, -1)
        healthBar.backdrop:SetBackdrop({
            edgeFile = ns.media.texture,
            edgeSize = 1,
        })
        healthBar.backdrop:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    -- Cast bar
    local castBar = nameplate.castBar
    if castBar then
        castBar:SetStatusBarTexture(ns.media.texture)
        castBar:SetHeight(10)
        
        if not castBar.backdrop then
            castBar.backdrop = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
            castBar.backdrop:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 1)
            castBar.backdrop:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, -1)
            castBar.backdrop:SetBackdrop({
                edgeFile = ns.media.texture,
                edgeSize = 1,
            })
            castBar.backdrop:SetBackdropBorderColor(0, 0, 0, 1)
        end
        
        -- Cast bar text
        if castBar.Text then
            castBar.Text:SetFont(ns.media.font, 9, "OUTLINE, MONOCHROME")
        end
    end
    
    -- Name text
    local name = nameplate.name
    if name then
        name:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    end
    
    -- Level text
    local level = nameplate.level
    if level then
        level:SetFont(ns.media.font, 9, "OUTLINE, MONOCHROME")
    end
    
    nameplate.styled = true
end

-- Register nameplate callbacks
function Nameplates:RegisterCallbacks()
    -- Hook nameplate added
    local function OnNamePlateAdded(self, event, unit)
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate then
            Nameplates:StyleNameplate(nameplate.UnitFrame)
        end
    end
    
    -- Hook nameplate removed
    local function OnNamePlateRemoved(self, event, unit)
        -- Cleanup if needed
    end
    
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "NAME_PLATE_UNIT_ADDED" then
            OnNamePlateAdded(self, event, ...)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            OnNamePlateRemoved(self, event, ...)
        end
    end)
end

-- Return module
return Nameplates