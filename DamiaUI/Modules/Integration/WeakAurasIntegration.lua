--[[
    DamiaUI - WeakAuras Deep Integration
    
    Specialized integration system for WeakAuras addon, providing intelligent
    aura positioning, grouping management, and seamless Aurora styling integration.
    
    Features:
    - Automatic aura group positioning based on DamiaUI layout
    - Smart conflict avoidance with unit frames and action bars
    - Aurora styling integration for WeakAuras frames
    - Recommended positioning profiles for common aura types
    - Dynamic repositioning based on combat/non-combat states
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs, type = pairs, ipairs, type
local math = math
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local InCombatLockdown = InCombatLockdown

-- Module initialization
local WeakAurasIntegration = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.WeakAurasIntegration = WeakAurasIntegration

-- WeakAuras references
local WeakAuras
local WeakAurasSaved

-- Module state
local integrationState = {
    initialized = false,
    trackedGroups = {},
    originalPositions = {},
    appliedPositions = {},
    combatPositions = {},
    nonCombatPositions = {},
    lastUpdate = 0
}

-- DamiaUI positioning zones for WeakAuras
local WA_POSITIONING_ZONES = {
    -- Primary zones for important auras (buffs, debuffs, cooldowns)
    centerAbove = {
        name = "Center Above",
        baseX = 0, baseY = 120,
        maxGroups = 3,
        priority = 1,
        description = "Above unit frames, centered - ideal for important buffs/debuffs"
    },
    
    centerBelow = {
        name = "Center Below", 
        baseX = 0, baseY = -120,
        maxGroups = 3,
        priority = 2,
        description = "Below unit frames, centered - good for resource tracking"
    },
    
    leftSide = {
        name = "Left Side",
        baseX = -300, baseY = 0,
        maxGroups = 4,
        priority = 3,
        description = "Left side of screen - suitable for utility auras"
    },
    
    rightSide = {
        name = "Right Side",
        baseX = 300, baseY = 0,
        maxGroups = 4,
        priority = 3,
        description = "Right side of screen - suitable for utility auras"
    },
    
    -- Secondary zones for less critical auras
    topLeft = {
        name = "Top Left",
        baseX = -400, baseY = 200,
        maxGroups = 2,
        priority = 4,
        description = "Top left corner - for informational auras"
    },
    
    topRight = {
        name = "Top Right",
        baseX = 400, baseY = 200,
        maxGroups = 2, 
        priority = 4,
        description = "Top right corner - for informational auras"
    },
    
    bottomLeft = {
        name = "Bottom Left",
        baseX = -400, baseY = -200,
        maxGroups = 2,
        priority = 5,
        description = "Bottom left - for secondary information"
    },
    
    bottomRight = {
        name = "Bottom Right", 
        baseX = 400, baseY = -200,
        maxGroups = 2,
        priority = 5,
        description = "Bottom right - for secondary information"
    }
}

-- WeakAuras group type classification and positioning recommendations
local AURA_TYPE_RECOMMENDATIONS = {
    -- Critical combat information - center positions
    ["Player Buffs"] = {
        zones = { "centerAbove", "leftSide" },
        spacing = 40,
        scale = 1.0,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.8
    },
    
    ["Player Debuffs"] = {
        zones = { "centerAbove", "rightSide" },
        spacing = 40,
        scale = 1.1,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.9,
        priority = "high"
    },
    
    ["Target Buffs"] = {
        zones = { "centerAbove", "rightSide" },
        spacing = 35,
        scale = 0.9,
        alpha = 0.95,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.7
    },
    
    ["Target Debuffs"] = {
        zones = { "centerAbove", "rightSide" },
        spacing = 35,
        scale = 0.95,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.8
    },
    
    -- Cooldown tracking
    ["Cooldowns"] = {
        zones = { "centerBelow", "bottomLeft", "leftSide" },
        spacing = 45,
        scale = 0.85,
        alpha = 0.9,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.6
    },
    
    ["Spell Cooldowns"] = {
        zones = { "centerBelow", "leftSide" },
        spacing = 42,
        scale = 0.9,
        alpha = 0.95,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.7
    },
    
    -- Resource tracking
    ["Resource Bars"] = {
        zones = { "centerBelow", "bottomRight" },
        spacing = 0, -- Usually single large elements
        scale = 1.0,
        alpha = 0.95,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.8
    },
    
    ["Combo Points"] = {
        zones = { "centerBelow", "centerAbove" },
        spacing = 5,
        scale = 1.2,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.9,
        priority = "high"
    },
    
    -- Utility and information
    ["Utility"] = {
        zones = { "rightSide", "topRight", "bottomRight" },
        spacing = 30,
        scale = 0.8,
        alpha = 0.85,
        combatAlpha = 0.7,
        nonCombatAlpha = 0.9
    },
    
    ["Information"] = {
        zones = { "topLeft", "topRight", "leftSide" },
        spacing = 25,
        scale = 0.75,
        alpha = 0.8,
        combatAlpha = 0.5,
        nonCombatAlpha = 0.9
    },
    
    -- Boss encounters and raid mechanics
    ["Boss Abilities"] = {
        zones = { "centerAbove", "topLeft", "topRight" },
        spacing = 50,
        scale = 1.3,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.3,
        priority = "critical"
    },
    
    ["Raid Warnings"] = {
        zones = { "centerAbove" },
        spacing = 60,
        scale = 1.5,
        alpha = 1.0,
        combatAlpha = 1.0,
        nonCombatAlpha = 0.2,
        priority = "critical"
    }
}

--[[
    Core Integration Functions
]]

function WeakAurasIntegration:Initialize()
    -- Check if WeakAuras is loaded
    if not self:ValidateWeakAuras() then
        DamiaUI:LogDebug("WeakAurasIntegration: WeakAuras not available")
        return false
    end
    
    -- Setup integration hooks
    self:SetupWeakAurasHooks()
    
    -- Setup event monitoring
    self:SetupEventHandling()
    
    -- Initialize positioning system
    self:InitializePositioning()
    
    integrationState.initialized = true
    DamiaUI:LogInfo("WeakAurasIntegration: Successfully initialized")
    return true
end

function WeakAurasIntegration:ValidateWeakAuras()
    WeakAuras = _G.WeakAuras
    if not WeakAuras then
        return false
    end
    
    WeakAurasSaved = _G.WeakAurasSaved
    if not WeakAurasSaved then
        return false
    end
    
    -- Check for required WeakAuras API functions
    if not WeakAuras.GetData or not WeakAuras.GetRegion then
        DamiaUI:LogWarning("WeakAurasIntegration: WeakAuras API incomplete")
        return false
    end
    
    return true
end

function WeakAurasIntegration:SetupWeakAurasHooks()
    -- Hook into WeakAuras display creation/modification
    if WeakAuras.Add then
        local originalAdd = WeakAuras.Add
        WeakAuras.Add = function(data, ...)
            local result = originalAdd(data, ...)
            
            -- Schedule our positioning logic after WA processes the display
            C_Timer.After(0.1, function()
                self:OnWeakAuraAdded(data)
            end)
            
            return result
        end
    end
    
    -- Hook display updates
    if WeakAuras.UpdateDisplay then
        local originalUpdate = WeakAuras.UpdateDisplay
        WeakAuras.UpdateDisplay = function(id, ...)
            local result = originalUpdate(id, ...)
            
            C_Timer.After(0.1, function()
                self:OnWeakAuraUpdated(id)
            end)
            
            return result
        end
    end
    
    -- Hook display deletion
    if WeakAuras.Delete then
        local originalDelete = WeakAuras.Delete
        WeakAuras.Delete = function(data, ...)
            self:OnWeakAuraDeleted(data)
            return originalDelete(data, ...)
        end
    end
end

function WeakAurasIntegration:SetupEventHandling()
    -- Create event frame
    local eventFrame = CreateFrame("Frame", "DamiaUIWeakAurasIntegration")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leave combat
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            WeakAurasIntegration:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            WeakAurasIntegration:OnLeaveCombat()
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            WeakAurasIntegration:OnDisplayChanged()
        end
    end)
    
    self.eventFrame = eventFrame
end

function WeakAurasIntegration:InitializePositioning()
    -- Scan existing WeakAuras displays
    C_Timer.After(2, function()
        self:ScanExistingDisplays()
    end)
    
    -- Setup periodic update ticker
    self.updateTicker = C_Timer.NewTicker(5, function()
        self:PerformPeriodicUpdate()
    end)
end

--[[
    WeakAuras Event Handlers
]]

function WeakAurasIntegration:OnWeakAuraAdded(data)
    if not data or not data.id then
        return
    end
    
    DamiaUI:LogDebug("WeakAurasIntegration: WeakAura added - " .. data.id)
    
    -- Analyze the aura and determine optimal positioning
    local classification = self:ClassifyWeakAura(data)
    local recommendedPosition = self:GetRecommendedPosition(classification, data)
    
    if recommendedPosition then
        -- Store original position before applying our positioning
        self:StoreOriginalPosition(data.id, data)
        
        -- Apply recommended position
        self:ApplyPositioning(data.id, recommendedPosition)
        
        -- Track this display
        integrationState.trackedGroups[data.id] = {
            data = data,
            classification = classification,
            position = recommendedPosition,
            addedTime = GetTime()
        }
    end
end

function WeakAurasIntegration:OnWeakAuraUpdated(id)
    if not id then
        return
    end
    
    local tracked = integrationState.trackedGroups[id]
    if tracked then
        -- Re-evaluate positioning if the aura has changed significantly
        local currentData = WeakAuras.GetData(id)
        if currentData and self:ShouldRepositionAfterUpdate(tracked.data, currentData) then
            DamiaUI:LogDebug("WeakAurasIntegration: Re-positioning updated aura - " .. id)
            
            local newClassification = self:ClassifyWeakAura(currentData)
            local newPosition = self:GetRecommendedPosition(newClassification, currentData)
            
            if newPosition then
                self:ApplyPositioning(id, newPosition)
                tracked.classification = newClassification
                tracked.position = newPosition
                tracked.data = currentData
            end
        end
    end
end

function WeakAurasIntegration:OnWeakAuraDeleted(data)
    if not data or not data.id then
        return
    end
    
    DamiaUI:LogDebug("WeakAurasIntegration: WeakAura deleted - " .. data.id)
    
    -- Clean up tracking
    integrationState.trackedGroups[data.id] = nil
    integrationState.originalPositions[data.id] = nil
    integrationState.appliedPositions[data.id] = nil
end

function WeakAurasIntegration:OnEnterCombat()
    DamiaUI:LogDebug("WeakAurasIntegration: Entering combat - adjusting aura visibility")
    
    for id, tracked in pairs(integrationState.trackedGroups) do
        if tracked.classification and tracked.classification.combatAlpha then
            self:SetAuraAlpha(id, tracked.classification.combatAlpha)
        end
    end
end

function WeakAurasIntegration:OnLeaveCombat()
    DamiaUI:LogDebug("WeakAurasIntegration: Leaving combat - restoring aura visibility")
    
    C_Timer.After(1, function() -- Brief delay to avoid repositioning during combat end
        for id, tracked in pairs(integrationState.trackedGroups) do
            if tracked.classification and tracked.classification.nonCombatAlpha then
                self:SetAuraAlpha(id, tracked.classification.nonCombatAlpha)
            end
        end
    end)
end

function WeakAurasIntegration:OnDisplayChanged()
    DamiaUI:LogDebug("WeakAurasIntegration: Display changed - recalculating positions")
    
    C_Timer.After(0.5, function()
        self:RecalculateAllPositions()
    end)
end

--[[
    WeakAura Classification System
]]

function WeakAurasIntegration:ClassifyWeakAura(data)
    if not data then
        return AURA_TYPE_RECOMMENDATIONS["Utility"]
    end
    
    local id = data.id or ""
    local displayType = data.regionType or ""
    local triggers = data.triggers or {}
    
    -- Analyze the aura based on various factors
    local classification = self:AnalyzeAuraType(id, displayType, triggers, data)
    
    -- Get the appropriate recommendation
    return AURA_TYPE_RECOMMENDATIONS[classification] or AURA_TYPE_RECOMMENDATIONS["Utility"]
end

function WeakAurasIntegration:AnalyzeAuraType(id, displayType, triggers, data)
    local idLower = id:lower()
    
    -- Boss ability patterns
    if idLower:match("boss") or idLower:match("raid") or idLower:match("encounter") then
        return "Boss Abilities"
    end
    
    -- Raid warning patterns
    if idLower:match("warning") or idLower:match("alert") or idLower:match("danger") then
        return "Raid Warnings"
    end
    
    -- Player buff/debuff patterns
    if idLower:match("buff") or idLower:match("aura") then
        if idLower:match("player") or idLower:match("self") then
            return "Player Buffs"
        else
            return "Target Buffs"
        end
    end
    
    if idLower:match("debuff") or idLower:match("dot") then
        if idLower:match("player") or idLower:match("self") then
            return "Player Debuffs"
        else
            return "Target Debuffs"
        end
    end
    
    -- Cooldown patterns
    if idLower:match("cooldown") or idLower:match("cd") or displayType == "cooldown" then
        if idLower:match("spell") or idLower:match("ability") then
            return "Spell Cooldowns"
        else
            return "Cooldowns"
        end
    end
    
    -- Resource tracking patterns
    if idLower:match("resource") or idLower:match("mana") or idLower:match("energy") or 
       idLower:match("rage") or idLower:match("focus") then
        return "Resource Bars"
    end
    
    if idLower:match("combo") or idLower:match("point") then
        return "Combo Points"
    end
    
    -- Information displays
    if displayType == "text" or idLower:match("info") or idLower:match("display") then
        return "Information"
    end
    
    -- Default to utility
    return "Utility"
end

--[[
    Positioning Logic
]]

function WeakAurasIntegration:GetRecommendedPosition(classification, data)
    if not classification or not classification.zones then
        return nil
    end
    
    -- Find the best available zone
    local bestZone = self:FindBestAvailableZone(classification.zones, data)
    if not bestZone then
        return nil
    end
    
    -- Calculate specific position within the zone
    local position = self:CalculatePositionInZone(bestZone, classification, data)
    
    return position
end

function WeakAurasIntegration:FindBestAvailableZone(preferredZones, data)
    -- Check zone availability and current occupancy
    local zoneOccupancy = self:GetZoneOccupancy()
    
    for _, zoneName in ipairs(preferredZones) do
        local zone = WA_POSITIONING_ZONES[zoneName]
        if zone then
            local currentOccupancy = zoneOccupancy[zoneName] or 0
            if currentOccupancy < zone.maxGroups then
                return zone
            end
        end
    end
    
    -- If all preferred zones are full, find the least occupied one
    local leastOccupied = nil
    local minOccupancy = math.huge
    
    for _, zoneName in ipairs(preferredZones) do
        local zone = WA_POSITIONING_ZONES[zoneName]
        if zone then
            local occupancy = zoneOccupancy[zoneName] or 0
            if occupancy < minOccupancy then
                minOccupancy = occupancy
                leastOccupied = zone
            end
        end
    end
    
    return leastOccupied
end

function WeakAurasIntegration:CalculatePositionInZone(zone, classification, data)
    if not zone then
        return nil
    end
    
    -- Get current screen dimensions and scale
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    -- Calculate base position (center of screen)
    local centerX = screenWidth / 2 / uiScale
    local centerY = screenHeight / 2 / uiScale
    
    -- Apply zone offset
    local finalX = zone.baseX
    local finalY = zone.baseY
    
    -- Add stacking offset for multiple auras in same zone
    local zoneOccupancy = self:GetZoneOccupancyInZone(zone.name)
    if zoneOccupancy > 0 and classification.spacing then
        -- Calculate stacking offset
        local stackingOffset = zoneOccupancy * classification.spacing
        
        -- Apply offset based on zone orientation
        if zone.name:match("Left") or zone.name:match("Right") then
            finalY = finalY + (stackingOffset * (zoneOccupancy % 2 == 0 and 1 or -1))
        else
            finalX = finalX + (stackingOffset * (zoneOccupancy % 2 == 0 and 1 or -1))
        end
    end
    
    return {
        x = finalX,
        y = finalY,
        anchor = "CENTER",
        scale = classification.scale or 1.0,
        alpha = classification.alpha or 1.0,
        zone = zone.name
    }
end

function WeakAurasIntegration:ApplyPositioning(auraId, position)
    if not auraId or not position or InCombatLockdown() then
        return false
    end
    
    local region = WeakAuras.GetRegion(auraId)
    if not region then
        return false
    end
    
    local success = pcall(function()
        -- Clear existing points
        region:ClearAllPoints()
        
        -- Set new position
        region:SetPoint(position.anchor or "CENTER", UIParent, "CENTER", position.x, position.y)
        
        -- Apply scale and alpha
        if position.scale then
            region:SetScale(position.scale)
        end
        
        if position.alpha then
            region:SetAlpha(position.alpha)
        end
        
        -- Store the applied position
        integrationState.appliedPositions[auraId] = position
    end)
    
    if success then
        DamiaUI:LogDebug("WeakAurasIntegration: Applied positioning to " .. auraId)
    else
        DamiaUI:LogWarning("WeakAurasIntegration: Failed to apply positioning to " .. auraId)
    end
    
    return success
end

--[[
    Utility Functions
]]

function WeakAurasIntegration:StoreOriginalPosition(auraId, data)
    if not data.xOffset or not data.yOffset then
        return
    end
    
    integrationState.originalPositions[auraId] = {
        x = data.xOffset,
        y = data.yOffset,
        anchor = data.anchor,
        scale = data.scale,
        alpha = data.alpha
    }
end

function WeakAurasIntegration:GetZoneOccupancy()
    local occupancy = {}
    
    -- Initialize all zones
    for zoneName in pairs(WA_POSITIONING_ZONES) do
        occupancy[zoneName] = 0
    end
    
    -- Count current occupancy
    for auraId, position in pairs(integrationState.appliedPositions) do
        if position.zone and occupancy[position.zone] then
            occupancy[position.zone] = occupancy[position.zone] + 1
        end
    end
    
    return occupancy
end

function WeakAurasIntegration:GetZoneOccupancyInZone(zoneName)
    local count = 0
    for auraId, position in pairs(integrationState.appliedPositions) do
        if position.zone == zoneName then
            count = count + 1
        end
    end
    return count
end

function WeakAurasIntegration:SetAuraAlpha(auraId, alpha)
    if InCombatLockdown() then
        return
    end
    
    local region = WeakAuras.GetRegion(auraId)
    if region then
        region:SetAlpha(alpha)
    end
end

function WeakAurasIntegration:ShouldRepositionAfterUpdate(oldData, newData)
    if not oldData or not newData then
        return false
    end
    
    -- Check if significant properties have changed
    if oldData.regionType ~= newData.regionType then
        return true
    end
    
    if oldData.id ~= newData.id then
        return true
    end
    
    -- Check if trigger conditions have changed significantly
    local oldTriggerCount = oldData.triggers and #oldData.triggers or 0
    local newTriggerCount = newData.triggers and #newData.triggers or 0
    
    if oldTriggerCount ~= newTriggerCount then
        return true
    end
    
    return false
end

--[[
    Maintenance Functions
]]

function WeakAurasIntegration:ScanExistingDisplays()
    if not WeakAuras or not WeakAuras.GetData then
        return
    end
    
    DamiaUI:LogDebug("WeakAurasIntegration: Scanning existing WeakAuras displays")
    
    local processedCount = 0
    
    -- Scan all existing displays
    for id, data in pairs(WeakAuras.GetData()) do
        if data and not integrationState.trackedGroups[id] then
            self:OnWeakAuraAdded(data)
            processedCount = processedCount + 1
        end
    end
    
    DamiaUI:LogInfo(string.format("WeakAurasIntegration: Processed %d existing displays", processedCount))
end

function WeakAurasIntegration:PerformPeriodicUpdate()
    local currentTime = GetTime()
    
    -- Skip if we updated recently
    if currentTime - integrationState.lastUpdate < 5 then
        return
    end
    
    -- Check for orphaned tracking entries
    local cleanedCount = 0
    for id in pairs(integrationState.trackedGroups) do
        local data = WeakAuras.GetData(id)
        if not data then
            integrationState.trackedGroups[id] = nil
            integrationState.originalPositions[id] = nil
            integrationState.appliedPositions[id] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        DamiaUI:LogDebug(string.format("WeakAurasIntegration: Cleaned %d orphaned entries", cleanedCount))
    end
    
    integrationState.lastUpdate = currentTime
end

function WeakAurasIntegration:RecalculateAllPositions()
    DamiaUI:LogDebug("WeakAurasIntegration: Recalculating all WeakAura positions")
    
    -- Clear applied positions
    table.wipe(integrationState.appliedPositions)
    
    -- Recalculate and apply all positions
    for id, tracked in pairs(integrationState.trackedGroups) do
        local newPosition = self:GetRecommendedPosition(tracked.classification, tracked.data)
        if newPosition then
            self:ApplyPositioning(id, newPosition)
            tracked.position = newPosition
        end
    end
end

--[[
    Public API
]]

function WeakAurasIntegration:ApplyIntegration(profile)
    -- This is called by the main Integration controller
    if not integrationState.initialized then
        return self:Initialize()
    end
    
    -- Trigger a full rescan of displays
    C_Timer.After(1, function()
        self:ScanExistingDisplays()
    end)
    
    return true
end

function WeakAurasIntegration:RestoreOriginalPositions()
    DamiaUI:LogInfo("WeakAurasIntegration: Restoring original WeakAura positions")
    
    for auraId, originalPos in pairs(integrationState.originalPositions) do
        local region = WeakAuras.GetRegion(auraId)
        if region and not InCombatLockdown() then
            pcall(function()
                region:ClearAllPoints()
                region:SetPoint(originalPos.anchor or "CENTER", UIParent, "CENTER", originalPos.x, originalPos.y)
                
                if originalPos.scale then
                    region:SetScale(originalPos.scale)
                end
                
                if originalPos.alpha then
                    region:SetAlpha(originalPos.alpha)
                end
            end)
        end
    end
    
    -- Clear tracking
    table.wipe(integrationState.trackedGroups)
    table.wipe(integrationState.appliedPositions)
end

function WeakAurasIntegration:GetIntegrationStatus()
    return {
        initialized = integrationState.initialized,
        trackedDisplays = 0, -- Count tracked displays
        appliedPositions = 0, -- Count applied positions
        zoneOccupancy = self:GetZoneOccupancy()
    }
end

function WeakAurasIntegration:GetRecommendedZones()
    return WA_POSITIONING_ZONES
end

function WeakAurasIntegration:GetAuraTypeRecommendations()
    return AURA_TYPE_RECOMMENDATIONS
end

-- Initialize if WeakAuras is available
if _G.WeakAuras then
    C_Timer.After(1, function()
        WeakAurasIntegration:Initialize()
    end)
end

return WeakAurasIntegration