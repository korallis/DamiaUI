--[[
    DamiaUI oUF Castbar Element
    
    Handles castbar display and updates for unit frames.
    Supports spell casting, channeling, and interrupt tracking.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local UnitExists, UnitIsUnit = UnitExists, UnitIsUnit
local GetTime = GetTime

-- Constants
local CASTBAR_UPDATE_INTERVAL = 0.01

--[[
    Castbar Update Function
    
    Updates castbar progress, text, and colors
]]
local function UpdateCastbar(frame, unit, event)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Castbar
    if not element then
        return
    end
    
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    local channeling = false
    
    -- Check for casting
    name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
    
    if not name then
        -- Check for channeling
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
        channeling = true
    end
    
    if not name then
        -- No casting or channeling
        element:Hide()
        if element.Text then
            element.Text:SetText("")
        end
        if element.Time then
            element.Time:SetText("")
        end
        return
    end
    
    -- Convert times to seconds
    startTime = startTime / 1000
    endTime = endTime / 1000
    local duration = endTime - startTime
    local currentTime = GetTime()
    
    -- Calculate progress
    local progress
    if channeling then
        progress = (endTime - currentTime) / duration
        progress = math.max(0, math.min(1, progress))
    else
        progress = (currentTime - startTime) / duration
        progress = math.max(0, math.min(1, progress))
    end
    
    -- Update castbar
    element:SetMinMaxValues(0, 1)
    element:SetValue(progress)
    element:Show()
    
    -- Update cast name
    if element.Text then
        element.Text:SetText(text or name or "")
    end
    
    -- Update time remaining
    if element.Time then
        local timeLeft = channeling and (endTime - currentTime) or (endTime - currentTime)
        timeLeft = math.max(0, timeLeft)
        element.Time:SetText(string.format("%.1f", timeLeft))
    end
    
    -- Update icon
    if element.Icon then
        element.Icon:SetTexture(texture)
    end
    
    -- Color based on interrupt status
    local r, g, b = 1, 0.7, 0  -- Default cast color (orange)
    
    if notInterruptible then
        -- Non-interruptible - red
        r, g, b = 0.8, 0.1, 0.1
    elseif channeling then
        -- Channeling - blue
        r, g, b = 0.2, 0.6, 1
    end
    
    element:SetStatusBarColor(r, g, b)
    
    -- Update background color (darker version)
    if element.bg then
        element.bg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3, 0.6)
    end
    
    -- Store cast information
    element.casting = not channeling
    element.channeling = channeling
    element.notInterruptible = notInterruptible
    element.spellID = spellID
    element.startTime = startTime
    element.endTime = endTime
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID)
    end
end

--[[
    Castbar animation update
]]
local function OnUpdate(self, elapsed)
    if not self.unit or not UnitExists(self.unit) then
        self:Hide()
        return
    end
    
    UpdateCastbar(self.__owner, self.unit)
end

--[[
    Element Enable Function
    
    Called when the castbar element is enabled on a frame
]]
local function EnableCastbar(frame, unit)
    local element = frame.Castbar
    if not element then
        return false
    end
    
    -- Store reference to the frame
    element.__owner = frame
    element.__unit = unit
    element.unit = unit
    
    -- Set up default properties if not already configured
    if not element:GetStatusBarTexture() then
        element:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    
    -- Create background if it doesn't exist
    if not element.bg then
        element.bg = element:CreateTexture(nil, "BORDER")
        element.bg:SetAllPoints(element)
        element.bg:SetTexture(element:GetStatusBarTexture():GetTexture())
        element.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    end
    
    -- Set up update script
    element:SetScript("OnUpdate", OnUpdate)
    
    -- Register for events
    frame:RegisterEvent("UNIT_SPELLCAST_START", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_FAILED", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_STOP", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_DELAYED", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", UpdateCastbar)
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", UpdateCastbar)
    
    -- Initial update
    UpdateCastbar(frame, unit)
    
    return true
end

--[[
    Element Disable Function
    
    Called when the castbar element is disabled on a frame
]]
local function DisableCastbar(frame, unit)
    local element = frame.Castbar
    if not element then
        return
    end
    
    -- Stop update script
    element:SetScript("OnUpdate", nil)
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_SPELLCAST_START")
    frame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
    frame:UnregisterEvent("UNIT_SPELLCAST_STOP")
    frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    frame:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
    frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    
    -- Hide the element
    element:Hide()
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
    element.unit = nil
    element.casting = nil
    element.channeling = nil
    element.notInterruptible = nil
    element.spellID = nil
    element.startTime = nil
    element.endTime = nil
end

--[[
    Element Registration
]]
oUF:RegisterElement("Castbar", UpdateCastbar, EnableCastbar, DisableCastbar)