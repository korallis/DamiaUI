--[[
    DamiaUI oUF Auras Element
    
    Handles buff and debuff display for unit frames.
    Supports filtering, sorting, and customizable layouts.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitAura, UnitExists = UnitAura, UnitExists
local CreateFrame = CreateFrame
local floor, ceil = math.floor, math.ceil
local tinsert, tremove, tsort = table.insert, table.remove, table.sort

-- Constants
local AURA_SIZE = 20
local AURA_SPACING = 2
local AURAS_PER_ROW = 8
local MAX_AURAS = 32

--[[
    Aura Button Creation and Setup
]]
local function CreateAuraButton(parent, index)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(AURA_SIZE, AURA_SIZE)
    
    -- Icon texture
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints(button)
    button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Count text
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetTextColor(1, 1, 1)
    button.Count:SetJustifyH("RIGHT")
    
    -- Duration text
    button.Duration = button:CreateFontString(nil, "OVERLAY")
    button.Duration:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    button.Duration:SetPoint("TOP", button, "BOTTOM", 0, -2)
    button.Duration:SetTextColor(1, 1, 1)
    button.Duration:SetJustifyH("CENTER")
    
    -- Border (for debuff types)
    button.Border = button:CreateTexture(nil, "BORDER")
    button.Border:SetAllPoints(button)
    button.Border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    button.Border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    button.Border:Hide()
    
    -- Overlay for buff/debuff distinction
    button.Overlay = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.Overlay:SetAllPoints(button.Icon)
    button.Overlay:SetTexture("Interface\\Buttons\\UI-TempEnchant-Border")
    button.Overlay:SetTexCoord(0, 1, 0, 1)
    button.Overlay:Hide()
    
    return button
end

--[[
    Position Aura Buttons
]]
local function PositionAuraButtons(element)
    local buttonsPerRow = element.buttonsPerRow or AURAS_PER_ROW
    local spacing = element.spacing or AURA_SPACING
    local size = element.size or AURA_SIZE
    local growthDirection = element.growth or "RIGHT"
    local anchor = element.anchor or "TOPLEFT"
    
    for index, button in ipairs(element) do
        button:SetSize(size, size)
        button:ClearAllPoints()
        
        if index == 1 then
            button:SetPoint(anchor, element, anchor)
        else
            local row = ceil(index / buttonsPerRow) - 1
            local col = (index - 1) % buttonsPerRow
            
            if growthDirection == "RIGHT" then
                button:SetPoint("TOPLEFT", element, "TOPLEFT", col * (size + spacing), -row * (size + spacing))
            elseif growthDirection == "LEFT" then
                button:SetPoint("TOPRIGHT", element, "TOPRIGHT", -col * (size + spacing), -row * (size + spacing))
            elseif growthDirection == "UP" then
                button:SetPoint("BOTTOMLEFT", element, "BOTTOMLEFT", col * (size + spacing), row * (size + spacing))
            elseif growthDirection == "DOWN" then
                button:SetPoint("TOPLEFT", element, "TOPLEFT", col * (size + spacing), -row * (size + spacing))
            end
        end
    end
end

--[[
    Update Aura Duration Text
]]
local function UpdateAuraDuration(button, timeLeft)
    if not button.Duration then
        return
    end
    
    if not timeLeft or timeLeft == 0 then
        button.Duration:SetText("")
        return
    end
    
    local duration
    if timeLeft >= 86400 then -- 24 hours
        duration = string.format("%dd", floor(timeLeft / 86400))
    elseif timeLeft >= 3600 then -- 1 hour
        duration = string.format("%dh", floor(timeLeft / 3600))
    elseif timeLeft >= 60 then -- 1 minute
        duration = string.format("%dm", floor(timeLeft / 60))
    else
        duration = string.format("%d", floor(timeLeft))
    end
    
    button.Duration:SetText(duration)
    
    -- Color code based on time left
    if timeLeft <= 5 then
        button.Duration:SetTextColor(1, 0, 0) -- Red
    elseif timeLeft <= 30 then
        button.Duration:SetTextColor(1, 1, 0) -- Yellow
    else
        button.Duration:SetTextColor(1, 1, 1) -- White
    end
end

--[[
    Auras Update Function
    
    Updates all auras for the given unit
]]
local function UpdateAuras(frame, unit, filter)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Auras or frame.Buffs or frame.Debuffs
    if not element then
        return
    end
    
    -- Determine filter type
    local auraFilter = filter or element.filter or "HELPFUL"
    local isDebuff = auraFilter:find("HARMFUL")
    
    -- Get max auras to display
    local maxAuras = element.maxAuras or MAX_AURAS
    
    -- Collect aura data
    local auras = {}
    local index = 1
    
    while index <= maxAuras do
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellID, canApplyAura, isBossAura, isFromPlayerOrPlayerPet,
              nameplateShowAll, timeMod, effect1, effect2, effect3 = UnitAura(unit, index, auraFilter)
        
        if not name then
            break
        end
        
        -- Apply custom filtering if provided
        local shouldShow = true
        if element.CustomFilter then
            shouldShow = element.CustomFilter(element, unit, {
                name = name,
                icon = icon,
                count = count,
                dispelType = dispelType,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                isStealable = isStealable,
                spellID = spellID,
                isBossAura = isBossAura,
                isFromPlayerOrPlayerPet = isFromPlayerOrPlayerPet
            })
        end
        
        if shouldShow then
            tinsert(auras, {
                index = index,
                name = name,
                icon = icon,
                count = count,
                dispelType = dispelType,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                isStealable = isStealable,
                spellID = spellID,
                isBossAura = isBossAura,
                isFromPlayerOrPlayerPet = isFromPlayerOrPlayerPet,
                timeLeft = expirationTime > 0 and (expirationTime - GetTime()) or 0
            })
        end
        
        index = index + 1
    end
    
    -- Sort auras if custom sort function provided
    if element.CustomSort then
        tsort(auras, element.CustomSort)
    else
        -- Default sort: player auras first, then by time left
        tsort(auras, function(a, b)
            if a.isFromPlayerOrPlayerPet and not b.isFromPlayerOrPlayerPet then
                return true
            elseif not a.isFromPlayerOrPlayerPet and b.isFromPlayerOrPlayerPet then
                return false
            else
                return a.timeLeft > b.timeLeft
            end
        end)
    end
    
    -- Update or create buttons
    local numAuras = #auras
    for i = 1, math.max(numAuras, #element) do
        local button = element[i]
        local aura = auras[i]
        
        if aura then
            -- Create button if it doesn't exist
            if not button then
                button = CreateAuraButton(element, i)
                element[i] = button
            end
            
            -- Update button data
            button.Icon:SetTexture(aura.icon)
            
            -- Update count
            if aura.count and aura.count > 1 then
                button.Count:SetText(aura.count)
                button.Count:Show()
            else
                button.Count:Hide()
            end
            
            -- Update duration
            UpdateAuraDuration(button, aura.timeLeft)
            
            -- Update border for debuffs
            if isDebuff and aura.dispelType then
                local color = DebuffTypeColor[aura.dispelType] or DebuffTypeColor["none"]
                button.Border:SetVertexColor(color.r, color.g, color.b)
                button.Border:Show()
            else
                button.Border:Hide()
            end
            
            -- Store aura data on button
            button.auraData = aura
            
            button:Show()
        else
            -- Hide unused buttons
            if button then
                button:Hide()
                button.auraData = nil
            end
        end
    end
    
    -- Position buttons
    PositionAuraButtons(element)
    
    -- Show/hide the element container
    if numAuras > 0 then
        element:Show()
    else
        element:Hide()
    end
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, auras, numAuras)
    end
end

--[[
    Element Enable Function
]]
local function EnableAuras(frame, unit)
    local element = frame.Auras or frame.Buffs or frame.Debuffs
    if not element then
        return false
    end
    
    -- Store references
    element.__owner = frame
    element.__unit = unit
    
    -- Set default properties
    element.size = element.size or AURA_SIZE
    element.spacing = element.spacing or AURA_SPACING
    element.buttonsPerRow = element.buttonsPerRow or AURAS_PER_ROW
    element.maxAuras = element.maxAuras or MAX_AURAS
    
    -- Register for events
    frame:RegisterEvent("UNIT_AURA", UpdateAuras)
    
    -- Initial update
    UpdateAuras(frame, unit)
    
    return true
end

--[[
    Element Disable Function
]]
local function DisableAuras(frame, unit)
    local element = frame.Auras or frame.Buffs or frame.Debuffs
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_AURA")
    
    -- Hide all buttons
    for i = 1, #element do
        if element[i] then
            element[i]:Hide()
        end
    end
    
    element:Hide()
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
end

--[[
    Element Registration
]]
oUF:RegisterElement("Auras", UpdateAuras, EnableAuras, DisableAuras)
oUF:RegisterElement("Buffs", UpdateAuras, EnableAuras, DisableAuras) 
oUF:RegisterElement("Debuffs", UpdateAuras, EnableAuras, DisableAuras)