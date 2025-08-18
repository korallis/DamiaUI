--[[
    DamiaUI oUF Health Element
    
    Handles health display and updates for unit frames.
    Supports health bars, text values, and color coding.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitIsDeadOrGhost, UnitIsConnected = UnitIsDeadOrGhost, UnitIsConnected
local UnitClass, UnitReaction = UnitClass, UnitReaction
local UnitIsPlayer, UnitIsTapDenied = UnitIsPlayer, UnitIsTapDenied

-- Constants
local HEALTH_UPDATE_THROTTLE = 0.1
local DEAD_TEXT = "Dead"
local GHOST_TEXT = "Ghost"
local OFFLINE_TEXT = "Offline"

--[[
    Health Update Function
    
    Updates health bars, background, and text elements
]]
local function UpdateHealth(frame, unit)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Health
    if not element then
        return
    end
    
    local currentHealth = UnitHealth(unit) or 0
    local maxHealth = UnitHealthMax(unit) or 1
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    local isConnected = UnitIsConnected(unit)
    
    -- Update status bar values
    element:SetMinMaxValues(0, maxHealth)
    element:SetValue(currentHealth)
    
    -- Update background if it exists
    if element.bg then
        element.bg:SetMinMaxValues(0, maxHealth)
        element.bg:SetValue(maxHealth)
    end
    
    -- Color the health bar
    local r, g, b = 0.25, 0.78, 0.25  -- Default green
    
    if not isConnected then
        -- Offline - gray color
        r, g, b = 0.5, 0.5, 0.5
    elseif isDeadOrGhost then
        -- Dead/ghost - red color
        r, g, b = 0.5, 0.5, 0.5
    elseif UnitIsPlayer(unit) then
        -- Player - use class colors
        local _, class = UnitClass(unit)
        if class then
            local classColors = oUF:GetClassColor(class)
            if classColors then
                r, g, b = classColors[1], classColors[2], classColors[3]
            end
        end
    elseif UnitIsTapDenied(unit) then
        -- Tapped by others - gray
        r, g, b = 0.5, 0.5, 0.5
    else
        -- NPC - use reaction colors
        local reaction = UnitReaction(unit, "player")
        if reaction then
            local reactionColors = oUF:GetReactionColor(reaction)
            if reactionColors then
                r, g, b = reactionColors[1], reactionColors[2], reactionColors[3]
            end
        end
    end
    
    -- Apply colors
    element:SetStatusBarColor(r, g, b)
    
    -- Update background color (darker version)
    if element.bg then
        element.bg:SetVertexColor(r * 0.25, g * 0.25, b * 0.25, 0.5)
    end
    
    -- Update health text if it exists
    if element.value then
        local healthText = ""
        
        if not isConnected then
            healthText = OFFLINE_TEXT
        elseif isDeadOrGhost then
            healthText = UnitIsGhost(unit) and GHOST_TEXT or DEAD_TEXT
        elseif maxHealth > 0 then
            -- Format health values based on size
            if frame.HealthValueFormat then
                if frame.HealthValueFormat == "percent" then
                    local percent = (currentHealth / maxHealth) * 100
                    healthText = string.format("%.0f%%", percent)
                elseif frame.HealthValueFormat == "current" then
                    healthText = oUF:FormatNumber(currentHealth)
                elseif frame.HealthValueFormat == "deficit" then
                    local deficit = maxHealth - currentHealth
                    if deficit > 0 then
                        healthText = "-" .. oUF:FormatNumber(deficit)
                    end
                elseif frame.HealthValueFormat == "both" then
                    healthText = oUF:FormatNumber(currentHealth) .. " / " .. oUF:FormatNumber(maxHealth)
                else
                    -- Default to max health
                    healthText = oUF:FormatNumber(maxHealth)
                end
            else
                -- Default format
                healthText = oUF:FormatNumber(maxHealth)
            end
        end
        
        element.value:SetText(healthText)
    end
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, currentHealth, maxHealth, isDeadOrGhost, isConnected)
    end
end

--[[
    Element Enable Function
    
    Called when the health element is enabled on a frame
]]
local function EnableHealth(frame, unit)
    local element = frame.Health
    if not element then
        return false
    end
    
    -- Store reference to the frame for updates
    element.__owner = frame
    element.__unit = unit
    
    -- Set up default properties if not already configured
    if not element:GetStatusBarTexture() then
        element:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    -- Create background if it doesn't exist
    if not element.bg and not element.background then
        element.bg = element:CreateTexture(nil, "BORDER")
        element.bg:SetAllPoints(element)
        element.bg:SetTexture(element:GetStatusBarTexture():GetTexture())
        element.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    end
    
    -- Register for events
    frame:RegisterEvent("UNIT_HEALTH", UpdateHealth)
    frame:RegisterEvent("UNIT_MAXHEALTH", UpdateHealth)
    frame:RegisterEvent("UNIT_CONNECTION", UpdateHealth)
    frame:RegisterEvent("UNIT_FACTION", UpdateHealth)
    
    -- Initial update
    UpdateHealth(frame, unit)
    
    return true
end

--[[
    Element Disable Function
    
    Called when the health element is disabled on a frame
]]
local function DisableHealth(frame, unit)
    local element = frame.Health
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_HEALTH")
    frame:UnregisterEvent("UNIT_MAXHEALTH")
    frame:UnregisterEvent("UNIT_CONNECTION")
    frame:UnregisterEvent("UNIT_FACTION")
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
end

--[[
    Element Registration
]]
oUF:RegisterElement("Health", UpdateHealth, EnableHealth, DisableHealth)