--[[
    DamiaUI oUF Power Element
    
    Handles power display and updates for unit frames.
    Supports mana, rage, energy, runic power, and all other power types.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitPowerType, UnitIsConnected = UnitPowerType, UnitIsConnected
local UnitIsDeadOrGhost, UnitExists = UnitIsDeadOrGhost, UnitExists

-- Power type constants (for WoW 11.2 compatibility)
local POWER_TYPES = {
    [0] = "MANA",
    [1] = "RAGE", 
    [2] = "FOCUS",
    [3] = "ENERGY",
    [4] = "CHI",
    [5] = "RUNES",
    [6] = "RUNIC_POWER",
    [7] = "SOUL_SHARDS",
    [8] = "LUNAR_POWER",
    [9] = "HOLY_POWER",
    [10] = "ALTERNATE_POWER",
    [11] = "MAELSTROM",
    [12] = "INSANITY",
    [13] = "OBSOLETE",
    [14] = "OBSOLETE2",
    [15] = "ARCANE_CHARGES",
    [16] = "FURY",
    [17] = "PAIN",
    [18] = "ESSENCE",
}

-- Constants
local POWER_UPDATE_THROTTLE = 0.05

--[[
    Power Update Function
    
    Updates power bars, background, and text elements
]]
local function UpdatePower(frame, unit, powerType)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Power
    if not element then
        return
    end
    
    local currentPower = UnitPower(unit, powerType) or 0
    local maxPower = UnitPowerMax(unit, powerType) or 0
    local powerTypeIndex = UnitPowerType(unit)
    local powerTypeName = POWER_TYPES[powerTypeIndex] or "MANA"
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    local isConnected = UnitIsConnected(unit)
    
    -- Update status bar values
    element:SetMinMaxValues(0, maxPower)
    element:SetValue(currentPower)
    
    -- Update background if it exists
    if element.bg then
        element.bg:SetMinMaxValues(0, maxPower)
        element.bg:SetValue(maxPower)
    end
    
    -- Hide power bar if unit has no power or is dead/offline
    if maxPower == 0 or isDeadOrGhost or not isConnected then
        element:Hide()
        if element.value then
            element.value:SetText("")
        end
        return
    else
        element:Show()
    end
    
    -- Color the power bar based on power type
    local r, g, b = 0.31, 0.45, 0.63  -- Default mana blue
    local powerColors = oUF:GetPowerColor(powerTypeName)
    if powerColors then
        r, g, b = powerColors[1], powerColors[2], powerColors[3]
    end
    
    -- Apply colors
    element:SetStatusBarColor(r, g, b)
    
    -- Update background color (darker version)
    if element.bg then
        element.bg:SetVertexColor(r * 0.25, g * 0.25, b * 0.25, 0.5)
    end
    
    -- Update power text if it exists
    if element.value then
        local powerText = ""
        
        if maxPower > 0 then
            -- Format power values based on configuration
            if frame.PowerValueFormat then
                if frame.PowerValueFormat == "percent" then
                    local percent = (currentPower / maxPower) * 100
                    powerText = string.format("%.0f%%", percent)
                elseif frame.PowerValueFormat == "current" then
                    powerText = tostring(currentPower)
                elseif frame.PowerValueFormat == "deficit" then
                    local deficit = maxPower - currentPower
                    if deficit > 0 then
                        powerText = "-" .. tostring(deficit)
                    end
                elseif frame.PowerValueFormat == "both" then
                    powerText = currentPower .. " / " .. maxPower
                else
                    -- Default to current power
                    powerText = tostring(currentPower)
                end
            else
                -- Default format - show current for most types, max for some special types
                if powerTypeName == "HOLY_POWER" or powerTypeName == "CHI" or powerTypeName == "ARCANE_CHARGES" or powerTypeName == "SOUL_SHARDS" then
                    powerText = currentPower .. "/" .. maxPower
                else
                    powerText = tostring(maxPower)
                end
            end
        end
        
        element.value:SetText(powerText)
    end
    
    -- Store power type info for other elements
    element.powerType = powerTypeIndex
    element.powerTypeName = powerTypeName
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, currentPower, maxPower, powerTypeIndex, powerTypeName)
    end
end

--[[
    Element Enable Function
    
    Called when the power element is enabled on a frame
]]
local function EnablePower(frame, unit)
    local element = frame.Power
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
    frame:RegisterEvent("UNIT_POWER_UPDATE", UpdatePower)
    frame:RegisterEvent("UNIT_MAXPOWER", UpdatePower)
    frame:RegisterEvent("UNIT_DISPLAYPOWER", UpdatePower)
    frame:RegisterEvent("UNIT_CONNECTION", UpdatePower)
    
    -- Initial update
    UpdatePower(frame, unit)
    
    return true
end

--[[
    Element Disable Function
    
    Called when the power element is disabled on a frame
]]
local function DisablePower(frame, unit)
    local element = frame.Power
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_POWER_UPDATE")
    frame:UnregisterEvent("UNIT_MAXPOWER")
    frame:UnregisterEvent("UNIT_DISPLAYPOWER")
    frame:UnregisterEvent("UNIT_CONNECTION")
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
    element.powerType = nil
    element.powerTypeName = nil
end

--[[
    Element Registration
]]
oUF:RegisterElement("Power", UpdatePower, EnablePower, DisablePower)