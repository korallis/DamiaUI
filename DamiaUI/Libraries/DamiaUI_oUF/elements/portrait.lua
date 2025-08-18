--[[
    DamiaUI oUF Portrait Element
    
    Handles 2D and 3D portrait display for unit frames.
    Supports both texture-based and model-based portraits.
]]

local addonName = ...
local oUF = LibStub("oUF")
if not oUF then return end

local _G = _G
local UnitExists, UnitIsVisible = UnitExists, UnitIsVisible
local UnitIsConnected, UnitIsDeadOrGhost = UnitIsConnected, UnitIsDeadOrGhost
local SetPortraitTexture, SetPortraitToTexture = SetPortraitTexture, SetPortraitToTexture

-- Constants
local PORTRAIT_UPDATE_THROTTLE = 0.2

--[[
    Update 2D Portrait
]]
local function Update2DPortrait(element, unit)
    if not element.SetTexture then
        return
    end
    
    local isConnected = UnitIsConnected(unit)
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    
    if not isConnected then
        -- Offline - set to gray/disconnected texture
        element:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
        element:SetDesaturated(false)
    elseif isDeadOrGhost then
        -- Dead/Ghost - set portrait but desaturate it
        SetPortraitTexture(element, unit)
        element:SetDesaturated(true)
    else
        -- Alive and connected - normal portrait
        SetPortraitTexture(element, unit)
        element:SetDesaturated(false)
    end
end

--[[
    Update 3D Portrait Model
]]
local function Update3DPortrait(element, unit)
    if not element.SetUnit then
        return
    end
    
    local isConnected = UnitIsConnected(unit)
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    
    if not isConnected then
        -- Offline - clear the model
        element:ClearModel()
        element:SetModelScale(1)
        return
    end
    
    -- Set the unit for the model
    element:SetUnit(unit)
    element:SetCamera(0)
    
    -- Adjust appearance for dead/ghost units
    if isDeadOrGhost then
        element:SetDesaturation(0.5)
        element:SetModelAlpha(0.6)
    else
        element:SetDesaturation(0)
        element:SetModelAlpha(1.0)
    end
    
    -- Position and scale the model
    element:SetPortraitZoom(1)
    element:SetPosition(0, 0, 0)
end

--[[
    Portrait Update Function
    
    Updates portrait based on type (2D texture or 3D model)
]]
local function UpdatePortrait(frame, unit)
    if not unit or not UnitExists(unit) then
        return
    end
    
    local element = frame.Portrait
    if not element then
        return
    end
    
    -- Check if this is a 3D model or 2D texture
    if element.SetUnit then
        -- 3D Model Portrait
        Update3DPortrait(element, unit)
    elseif element.SetTexture then
        -- 2D Texture Portrait 
        Update2DPortrait(element, unit)
    end
    
    -- Custom post-update callback
    if element.PostUpdate then
        element.PostUpdate(element, unit)
    end
end

--[[
    Element Enable Function
    
    Called when the portrait element is enabled on a frame
]]
local function EnablePortrait(frame, unit)
    local element = frame.Portrait
    if not element then
        return false
    end
    
    -- Store reference to the frame
    element.__owner = frame
    element.__unit = unit
    
    -- Set up 3D model properties if this is a model frame
    if element.SetUnit then
        element:SetFrameLevel(frame:GetFrameLevel() + 1)
        
        -- Default model settings
        if not element.hasCustomCamera then
            element:SetCamera(0)
        end
    end
    
    -- Set up 2D texture properties if this is a texture
    if element.SetTexture then
        element:SetDrawLayer("ARTWORK")
        
        -- Set default texture coordinates for clean portrait display
        element:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    
    -- Register for events
    frame:RegisterEvent("UNIT_PORTRAIT_UPDATE", UpdatePortrait)
    frame:RegisterEvent("UNIT_MODEL_CHANGED", UpdatePortrait)
    frame:RegisterEvent("UNIT_CONNECTION", UpdatePortrait)
    frame:RegisterEvent("UNIT_LEVEL", UpdatePortrait) -- Level changes can affect model
    
    -- Additional events for 3D models
    if element.SetUnit then
        frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdatePortrait)
        frame:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdatePortrait)
        frame:RegisterEvent("UNIT_EXITED_VEHICLE", UpdatePortrait)
    end
    
    -- Initial update
    UpdatePortrait(frame, unit)
    
    return true
end

--[[
    Element Disable Function
    
    Called when the portrait element is disabled on a frame
]]
local function DisablePortrait(frame, unit)
    local element = frame.Portrait
    if not element then
        return
    end
    
    -- Unregister events
    frame:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
    frame:UnregisterEvent("UNIT_MODEL_CHANGED")
    frame:UnregisterEvent("UNIT_CONNECTION")
    frame:UnregisterEvent("UNIT_LEVEL")
    
    -- Additional cleanup for 3D models
    if element.SetUnit then
        frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        frame:UnregisterEvent("UNIT_ENTERED_VEHICLE") 
        frame:UnregisterEvent("UNIT_EXITED_VEHICLE")
        
        element:ClearModel()
    end
    
    -- Clear 2D texture
    if element.SetTexture then
        element:SetTexture(nil)
    end
    
    -- Clear references
    element.__owner = nil
    element.__unit = nil
end

--[[
    Utility function to create a 2D portrait texture
]]
function oUF:CreatePortraitTexture(parent, layer, sublayer)
    local portrait = parent:CreateTexture(nil, layer or "ARTWORK", nil, sublayer)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    return portrait
end

--[[
    Utility function to create a 3D portrait model
]]
function oUF:CreatePortraitModel(parent, template)
    local portrait = CreateFrame("PlayerModel", nil, parent, template)
    portrait:SetFrameLevel(parent:GetFrameLevel() + 1)
    return portrait
end

--[[
    Element Registration
]]
oUF:RegisterElement("Portrait", UpdatePortrait, EnablePortrait, DisablePortrait)