--[[
    DamiaUI oUF Name Element
    
    Handles unit name display with support for custom formatting,
    level display, and classification indicators.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitName, UnitLevel = UnitName, UnitLevel
local UnitClassification, UnitExists = UnitClassification, UnitExists
local UnitClass, UnitCreatureType = UnitClass, UnitCreatureType
local UnitIsPlayer, UnitRace = UnitIsPlayer, UnitRace
local format = string.format

--[[
    Name Update Function
    
    Updates name text, level, and classification display
]]
local function UpdateName(frame, unit)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Name
    if not element then
        return
    end
    
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    local classification = UnitClassification(unit)
    local isPlayer = UnitIsPlayer(unit)
    
    if not name then
        element:SetText("")
        return
    end
    
    -- Build display text
    local displayText = name
    
    -- Add level if configured and available
    if element.showLevel and level and level > 0 then
        local levelText = tostring(level)
        
        -- Add level color based on difficulty
        if element.colorLevel then
            local playerLevel = UnitLevel("player")
            if playerLevel and level then
                local levelDiff = level - playerLevel
                local r, g, b = 1, 1, 1  -- Default white
                
                if levelDiff >= 5 then
                    r, g, b = 1, 0, 0  -- Red (much higher)
                elseif levelDiff >= 3 then
                    r, g, b = 1, 0.5, 0  -- Orange (higher)
                elseif levelDiff >= -2 then
                    r, g, b = 1, 1, 0  -- Yellow (similar)
                else
                    r, g, b = 0.5, 0.5, 0.5  -- Gray (much lower)
                end
                
                levelText = format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, levelText)
            end
        end
        
        displayText = levelText .. " " .. displayText
    end
    
    -- Add classification indicator
    if element.showClassification and classification then
        local classText = oUF:GetUnitClassification(unit)
        if classText ~= "" then
            displayText = displayText .. classText
        end
    end
    
    -- Set the text
    element:SetText(displayText)
    
    -- Color the name based on class/reaction
    if element.colorClass then
        local r, g, b = 1, 1, 1  -- Default white
        
        if isPlayer then
            -- Player - use class color
            local _, class = UnitClass(unit)
            if class then
                local classColors = oUF:GetClassColor(class)
                if classColors then
                    r, g, b = classColors[1], classColors[2], classColors[3]
                end
            end
        else
            -- NPC - use reaction color  
            local reaction = UnitReaction(unit, "player")
            if reaction then
                local reactionColors = oUF:GetReactionColor(reaction)
                if reactionColors then
                    r, g, b = reactionColors[1], reactionColors[2], reactionColors[3]
                end
            end
        end
        
        element:SetTextColor(r, g, b)
    end
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, name, level, classification, isPlayer)
    end
end

--[[
    Level Update Function (separate element support)
]]
local function UpdateLevel(frame, unit)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Level
    if not element then
        return
    end
    
    local level = UnitLevel(unit)
    local classification = UnitClassification(unit)
    
    if not level or level <= 0 then
        if UnitLevel("player") == GetMaxPlayerLevel() then
            -- Max level player, show ?? for higher level units
            element:SetText("??")
            element:SetTextColor(1, 0, 0)  -- Red
        else
            element:SetText("")
        end
        return
    end
    
    local levelText = tostring(level)
    
    -- Add classification symbol
    if classification then
        local classSymbol = ""
        if classification == "worldboss" then
            classSymbol = "B"  -- Boss
        elseif classification == "rareelite" then
            classSymbol = "R+"  -- Rare Elite
        elseif classification == "elite" then
            classSymbol = "+"  -- Elite
        elseif classification == "rare" then
            classSymbol = "R"  -- Rare
        end
        
        if classSymbol ~= "" then
            levelText = levelText .. classSymbol
        end
    end
    
    element:SetText(levelText)
    
    -- Color level based on difficulty
    if element.colorLevel ~= false then  -- Default to true
        local playerLevel = UnitLevel("player")
        if playerLevel then
            local levelDiff = level - playerLevel
            local r, g, b = 1, 1, 1  -- Default white
            
            if levelDiff >= 5 then
                r, g, b = 1, 0, 0  -- Red (much higher)
            elseif levelDiff >= 3 then
                r, g, b = 1, 0.5, 0  -- Orange (higher) 
            elseif levelDiff >= -2 then
                r, g, b = 1, 1, 0  -- Yellow (similar)
            else
                r, g, b = 0.5, 0.5, 0.5  -- Gray (much lower)
            end
            
            element:SetTextColor(r, g, b)
        else
            element:SetTextColor(1, 1, 1)  -- White fallback
        end
    end
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit, level, classification)
    end
end

--[[
    Name Element Enable Function
]]
local function EnableName(frame, unit)
    local element = frame.Name
    if not element then
        return false
    end
    
    -- Store references
    element.__owner = frame
    element.__unit = unit
    
    -- Set default properties
    if element.showLevel == nil then element.showLevel = false end
    if element.showClassification == nil then element.showClassification = true end
    if element.colorClass == nil then element.colorClass = true end
    if element.colorLevel == nil then element.colorLevel = true end
    
    -- Register for events
    frame:RegisterEvent("UNIT_NAME_UPDATE", UpdateName)
    frame:RegisterEvent("UNIT_LEVEL", UpdateName)
    frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateName)
    
    -- Initial update
    UpdateName(frame, unit)
    
    return true
end

--[[
    Name Element Disable Function
]]
local function DisableName(frame, unit)
    local element = frame.Name
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_NAME_UPDATE")
    frame:UnregisterEvent("UNIT_LEVEL") 
    frame:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED")
    
    -- Clear text
    element:SetText("")
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
end

--[[
    Level Element Enable Function
]]
local function EnableLevel(frame, unit)
    local element = frame.Level
    if not element then
        return false
    end
    
    -- Store references
    element.__owner = frame
    element.__unit = unit
    
    -- Register for events
    frame:RegisterEvent("UNIT_LEVEL", UpdateLevel)
    frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateLevel)
    
    -- Initial update
    UpdateLevel(frame, unit)
    
    return true
end

--[[
    Level Element Disable Function  
]]
local function DisableLevel(frame, unit)
    local element = frame.Level
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_LEVEL")
    frame:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED")
    
    -- Clear text
    element:SetText("")
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
end

--[[
    Element Registration
]]
oUF:RegisterElement("Name", UpdateName, EnableName, DisableName)
oUF:RegisterElement("Level", UpdateLevel, EnableLevel, DisableLevel)