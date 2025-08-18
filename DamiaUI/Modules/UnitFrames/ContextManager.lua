--[[
    DamiaUI - Context Manager for Unit Frames
    Intelligent frame visibility management based on group size and context
    
    Automatically manages visibility and layout of party, raid, and arena frames
    based on current group composition, instance type, and PvP status.
    Provides smooth transitions and contextual information filtering.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local IsInInstance = IsInInstance
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local GetNumArenaOpponents = GetNumArenaOpponents
local UnitInBattleground = UnitInBattleground
local CreateFrame = CreateFrame
local C_Timer = C_Timer

-- Context states
local CONTEXT_TYPES = {
    SOLO = 1,
    PARTY = 2,
    RAID = 3,
    ARENA = 4,
    BATTLEGROUND = 5
}

-- Current context state
local currentContext = {
    type = CONTEXT_TYPES.SOLO,
    memberCount = 0,
    instanceType = nil,
    lastUpdate = 0,
    transitioning = false
}

-- Frame visibility states
local frameVisibility = {
    party = false,
    raid = false,
    arena = false,
    player = true,
    target = true,
    focus = true
}

-- Configuration for context-based visibility
local CONTEXT_CONFIG = {
    updateInterval = 0.5, -- Check context every 500ms
    transitionDuration = 0.3, -- Fade transition duration
    enableSmoothtransitions = true,
    autoHideFrames = true,
    prioritizeByContext = true,
    
    -- Frame priorities by context
    contextPriority = {
        [CONTEXT_TYPES.SOLO] = { "player", "target", "focus" },
        [CONTEXT_TYPES.PARTY] = { "player", "target", "party", "focus" },
        [CONTEXT_TYPES.RAID] = { "player", "target", "raid", "focus" },
        [CONTEXT_TYPES.ARENA] = { "player", "target", "arena", "focus" },
        [CONTEXT_TYPES.BATTLEGROUND] = { "player", "target", "raid", "arena", "focus" }
    }
}

-- Context detection
local function DetectCurrentContext()
    local inInstance, instanceType = IsInInstance()
    local numMembers = GetNumGroupMembers()
    local isInGroup = IsInGroup()
    local isInRaid = IsInRaid()
    local isInArena = IsActiveBattlefieldArena()
    local numArenaOpponents = GetNumArenaOpponents()
    local inBattleground = UnitInBattleground("player")
    
    local newContext = { type = CONTEXT_TYPES.SOLO, memberCount = 1, instanceType = instanceType }
    
    -- Determine context type based on priority
    if isInArena and numArenaOpponents > 0 then
        newContext.type = CONTEXT_TYPES.ARENA
        newContext.memberCount = numArenaOpponents
    elseif inBattleground then
        newContext.type = CONTEXT_TYPES.BATTLEGROUND
        newContext.memberCount = numMembers
    elseif isInRaid and numMembers > 5 then
        newContext.type = CONTEXT_TYPES.RAID
        newContext.memberCount = numMembers
    elseif isInGroup and numMembers > 1 and numMembers <= 5 then
        newContext.type = CONTEXT_TYPES.PARTY
        newContext.memberCount = numMembers
    else
        newContext.type = CONTEXT_TYPES.SOLO
        newContext.memberCount = 1
    end
    
    return newContext
end

-- Check if context has changed significantly
local function HasContextChanged(newContext)
    return currentContext.type ~= newContext.type or 
           math.abs(currentContext.memberCount - newContext.memberCount) > 0 or
           currentContext.instanceType ~= newContext.instanceType
end

-- Update frame visibility based on context
local function UpdateFrameVisibility(contextType, memberCount)
    local newVisibility = {
        party = false,
        raid = false,
        arena = false,
        player = true,
        target = true,
        focus = true
    }
    
    -- Determine which frames should be visible
    if contextType == CONTEXT_TYPES.PARTY then
        newVisibility.party = memberCount > 1
    elseif contextType == CONTEXT_TYPES.RAID then
        newVisibility.raid = memberCount > 5
    elseif contextType == CONTEXT_TYPES.ARENA then
        newVisibility.arena = memberCount > 0
    elseif contextType == CONTEXT_TYPES.BATTLEGROUND then
        -- In battlegrounds, show raid frames for groups, arena for enemies
        newVisibility.raid = memberCount > 5
        newVisibility.arena = GetNumArenaOpponents() > 0
    end
    
    -- Apply visibility changes
    for frameType, shouldShow in pairs(newVisibility) do
        if frameVisibility[frameType] ~= shouldShow then
            frameVisibility[frameType] = shouldShow
            ApplyFrameVisibility(frameType, shouldShow)
        end
    end
end

-- Apply visibility changes to actual frames
local function ApplyFrameVisibility(frameType, shouldShow)
    local frameMod = nil
    local frames = {}
    
    -- Get the appropriate frame module and frames
    if frameType == "party" and DamiaUI.UnitFrames and DamiaUI.UnitFrames.Party then
        frameMod = DamiaUI.UnitFrames.Party
        frames = frameMod.GetFrames()
        local container = frameMod.GetContainer()
        
        if container then
            if shouldShow then
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    container:SetAlpha(0)
                    container:Show()
                    
                    local fadeIn = container:CreateAnimationGroup()
                    local alpha = fadeIn:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(0)
                    alpha:SetToAlpha(1)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeIn:Play()
                else
                    container:Show()
                end
                frameMod.UpdateVisibility()
            else
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    local fadeOut = container:CreateAnimationGroup()
                    local alpha = fadeOut:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(container:GetAlpha())
                    alpha:SetToAlpha(0)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeOut:SetScript("OnFinished", function()
                        container:Hide()
                    end)
                    fadeOut:Play()
                else
                    container:Hide()
                end
            end
        end
    elseif frameType == "raid" and DamiaUI.UnitFrames and DamiaUI.UnitFrames.Raid then
        frameMod = DamiaUI.UnitFrames.Raid
        frames = frameMod.GetFrames()
        local container = frameMod.GetContainer()
        
        if container then
            if shouldShow then
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    container:SetAlpha(0)
                    container:Show()
                    
                    local fadeIn = container:CreateAnimationGroup()
                    local alpha = fadeIn:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(0)
                    alpha:SetToAlpha(1)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeIn:Play()
                else
                    container:Show()
                end
                frameMod.UpdateVisibility()
            else
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    local fadeOut = container:CreateAnimationGroup()
                    local alpha = fadeOut:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(container:GetAlpha())
                    alpha:SetToAlpha(0)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeOut:SetScript("OnFinished", function()
                        container:Hide()
                    end)
                    fadeOut:Play()
                else
                    container:Hide()
                end
            end
        end
    elseif frameType == "arena" and DamiaUI.UnitFrames and DamiaUI.UnitFrames.Arena then
        frameMod = DamiaUI.UnitFrames.Arena
        frames = frameMod.GetFrames()
        local container = frameMod.GetContainer()
        
        if container then
            if shouldShow then
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    container:SetAlpha(0)
                    container:Show()
                    
                    local fadeIn = container:CreateAnimationGroup()
                    local alpha = fadeIn:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(0)
                    alpha:SetToAlpha(1)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeIn:Play()
                else
                    container:Show()
                end
                frameMod.UpdateVisibility()
            else
                if CONTEXT_CONFIG.enableSmoothtransitions then
                    local fadeOut = container:CreateAnimationGroup()
                    local alpha = fadeOut:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(container:GetAlpha())
                    alpha:SetToAlpha(0)
                    alpha:SetDuration(CONTEXT_CONFIG.transitionDuration)
                    fadeOut:SetScript("OnFinished", function()
                        container:Hide()
                    end)
                    fadeOut:Play()
                else
                    container:Hide()
                end
            end
        end
    end
    
    DamiaUI.Engine:LogDebug("Frame visibility changed: %s = %s", frameType, tostring(shouldShow))
end

-- Context update function called by timer
local function UpdateContext()
    local newContext = DetectCurrentContext()
    
    if HasContextChanged(newContext) then
        DamiaUI.Engine:LogInfo("Context changed: %s -> %s (members: %d -> %d)", 
            GetContextName(currentContext.type), GetContextName(newContext.type),
            currentContext.memberCount, newContext.memberCount)
        
        currentContext.transitioning = true
        
        -- Update frame visibility
        UpdateFrameVisibility(newContext.type, newContext.memberCount)
        
        -- Fire custom event for context change
        if DamiaUI.Events then
            DamiaUI.Events:TriggerCustomEvent("DAMIA_CONTEXT_CHANGED", currentContext, newContext)
        end
        
        currentContext = newContext
        currentContext.lastUpdate = GetTime()
        
        -- Clear transitioning flag after transition duration
        C_Timer.After(CONTEXT_CONFIG.transitionDuration, function()
            currentContext.transitioning = false
        end)
    else
        currentContext.lastUpdate = GetTime()
    end
end

-- Get human-readable context name
local function GetContextName(contextType)
    local contextNames = {
        [CONTEXT_TYPES.SOLO] = "Solo",
        [CONTEXT_TYPES.PARTY] = "Party", 
        [CONTEXT_TYPES.RAID] = "Raid",
        [CONTEXT_TYPES.ARENA] = "Arena",
        [CONTEXT_TYPES.BATTLEGROUND] = "Battleground"
    }
    return contextNames[contextType] or "Unknown"
end

-- Information filtering based on context
local function GetPriorityElements(contextType)
    return CONTEXT_CONFIG.contextPriority[contextType] or CONTEXT_CONFIG.contextPriority[CONTEXT_TYPES.SOLO]
end

-- Filter and prioritize information based on current context
local function FilterContextualInformation(infoType, data)
    if not CONTEXT_CONFIG.prioritizeByContext then return data end
    
    local priorities = GetPriorityElements(currentContext.type)
    local filteredData = {}
    
    -- Sort data based on context priority
    for _, priority in ipairs(priorities) do
        if data[priority] then
            filteredData[priority] = data[priority]
        end
    end
    
    -- Add any remaining data not in priority list
    for key, value in pairs(data) do
        if not filteredData[key] then
            filteredData[key] = value
        end
    end
    
    return filteredData
end

-- Context Manager main object
local ContextManager = {
    -- Public API
    GetCurrentContext = function()
        return {
            type = currentContext.type,
            typeName = GetContextName(currentContext.type),
            memberCount = currentContext.memberCount,
            instanceType = currentContext.instanceType,
            isTransitioning = currentContext.transitioning,
            lastUpdate = currentContext.lastUpdate
        }
    end,
    
    GetFrameVisibility = function()
        return frameVisibility
    end,
    
    IsFrameVisible = function(frameType)
        return frameVisibility[frameType] or false
    end,
    
    ForceUpdate = function()
        UpdateContext()
    end,
    
    SetConfig = function(key, value)
        if CONTEXT_CONFIG[key] ~= nil then
            CONTEXT_CONFIG[key] = value
        end
    end,
    
    GetConfig = function()
        return CONTEXT_CONFIG
    end,
    
    FilterInformation = FilterContextualInformation,
    
    GetContextPriorities = function()
        return GetPriorityElements(currentContext.type)
    end
}

-- Initialize context manager
local function InitializeContextManager()
    -- Initial context detection
    currentContext = DetectCurrentContext()
    currentContext.lastUpdate = GetTime()
    
    -- Set initial frame visibility
    UpdateFrameVisibility(currentContext.type, currentContext.memberCount)
    
    -- Start context monitoring timer
    local updateTicker = C_Timer.NewTicker(CONTEXT_CONFIG.updateInterval, function()
        UpdateContext()
    end)
    
    -- Register events for immediate context changes
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("GROUP_JOINED")
    eventFrame:RegisterEvent("GROUP_LEFT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Immediate context update for important events
        if event == "PLAYER_ENTERING_WORLD" or 
           event == "GROUP_ROSTER_UPDATE" or
           event == "GROUP_JOINED" or 
           event == "GROUP_LEFT" or
           event == "ZONE_CHANGED_NEW_AREA" then
            C_Timer.After(0.1, function() -- Small delay to let other systems update
                UpdateContext()
            end)
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or
               event == "ARENA_OPPONENT_UPDATE" then
            C_Timer.After(0.1, function()
                UpdateContext()
            end)
        end
    end)
    
    DamiaUI.Engine:LogInfo("Context Manager initialized - Current context: %s (%d members)", 
        GetContextName(currentContext.type), currentContext.memberCount)
    
    return updateTicker
end

-- Export to DamiaUI namespace
if not DamiaUI.UnitFrames then
    DamiaUI.UnitFrames = {}
end

DamiaUI.UnitFrames.ContextManager = ContextManager

-- Auto-initialize
InitializeContextManager()