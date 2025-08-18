--[[
===============================================================================
Damia UI - Event Throttling and Update Frequency Management
===============================================================================
Advanced throttling system to manage event processing and update frequencies
for optimal performance during high-load situations like 40-person raids.

Features:
- Intelligent event throttling with priority levels
- Dynamic update frequency adjustment
- Combat-aware throttling strategies
- Frame rate responsive throttling
- Batch processing for similar events
- Smart debouncing for UI updates

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local math = math
local table = table
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local GetTime = GetTime
local GetFramerate = GetFramerate
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer

-- Create Throttle module
local Throttle = {}
DamiaUI.Throttle = Throttle

-- Throttling constants and settings
local DEFAULT_THROTTLE_INTERVAL = 0.033 -- ~30 FPS default
local MIN_THROTTLE_INTERVAL = 0.016 -- ~60 FPS maximum
local MAX_THROTTLE_INTERVAL = 0.1 -- ~10 FPS minimum
local BATCH_WINDOW = 0.05 -- 50ms batch window
local MAX_BATCH_SIZE = 20 -- Maximum events per batch

-- Performance thresholds for dynamic adjustment
local FPS_THRESHOLD_HIGH = 60
local FPS_THRESHOLD_NORMAL = 45
local FPS_THRESHOLD_LOW = 30
local FPS_THRESHOLD_CRITICAL = 20

-- Throttling priority levels
local PRIORITY_CRITICAL = 1 -- Never throttle
local PRIORITY_HIGH = 2 -- Light throttling only
local PRIORITY_NORMAL = 3 -- Normal throttling
local PRIORITY_LOW = 4 -- Aggressive throttling
local PRIORITY_BACKGROUND = 5 -- Very aggressive throttling

-- Throttled event storage
local throttledEvents = {}
local eventBatches = {}
local updateCallbacks = {}
local debouncedCallbacks = {}

-- Dynamic throttling state
local throttlingState = {
    enabled = true,
    globalMultiplier = 1.0,
    combatMultiplier = 1.5,
    adaptiveMode = true,
    currentFPS = 60,
    performanceLevel = "normal",
}

-- Throttling statistics
local throttlingStats = {
    eventsThrottled = 0,
    eventsBatched = 0,
    callbacksDeferred = 0,
    averageThrottleTime = 0,
    totalSavedCalls = 0,
}

-- Main throttling frame
local throttleFrame = CreateFrame("Frame", "DamiaUIThrottleFrame")
local batchFrame = CreateFrame("Frame", "DamiaUIBatchFrame")
local updateFrame = CreateFrame("Frame", "DamiaUIUpdateFrame")

--[[
===============================================================================
CORE THROTTLING SYSTEM
===============================================================================
--]]

-- Initialize throttling system
function Throttle:Initialize()
    DamiaUI.Engine:LogInfo("Initializing Event Throttling System")
    
    -- Set up main throttling loop
    self:StartThrottlingLoop()
    self:StartBatchProcessing()
    self:StartUpdateManagement()
    
    -- Register for performance monitoring
    DamiaUI.Events:RegisterCustomEvent("DAMIA_PERFORMANCE_UPDATE", 
        function(event, data) self:OnPerformanceUpdate(data) end, 2, "Throttle_Performance")
    
    DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", 
        function(event, inCombat) self:OnCombatStateChanged(inCombat) end, 2, "Throttle_Combat")
    
    -- Register for optimization level changes
    DamiaUI.Events:RegisterCustomEvent("DAMIA_OPTIMIZATION_CHANGED", 
        function(event, level) self:OnOptimizationChanged(level) end, 2, "Throttle_Optimization")
    
    DamiaUI.Engine:LogInfo("Event throttling system initialized")
end

-- Start main throttling loop
function Throttle:StartThrottlingLoop()
    throttleFrame:SetScript("OnUpdate", function(self, elapsed)
        Throttle:ProcessThrottledEvents()
        Throttle:ProcessDebouncedCallbacks()
    end)
end

-- Start batch processing
function Throttle:StartBatchProcessing()
    batchFrame:SetScript("OnUpdate", function(self, elapsed)
        Throttle:ProcessEventBatches()
    end)
end

-- Start update callback management
function Throttle:StartUpdateManagement()
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        Throttle:ProcessUpdateCallbacks(elapsed)
    end)
end

--[[
===============================================================================
EVENT THROTTLING
===============================================================================
--]]

-- Register event for throttling
function Throttle:RegisterEvent(eventName, callback, interval, priority, identifier)
    if not eventName or not callback then
        DamiaUI.Engine:LogError("RegisterEvent: Invalid event name or callback")
        return false
    end
    
    if type(callback) ~= "function" then
        DamiaUI.Engine:LogError("RegisterEvent: Callback must be a function")
        return false
    end
    
    interval = interval or DEFAULT_THROTTLE_INTERVAL
    priority = priority or PRIORITY_NORMAL
    identifier = identifier or ("ThrottledEvent_" .. tostring(callback))
    
    -- Apply global multiplier
    local adjustedInterval = self:CalculateAdjustedInterval(interval, priority)
    
    throttledEvents[eventName] = throttledEvents[eventName] or {}
    
    local throttleData = {
        callback = callback,
        interval = adjustedInterval,
        baseInterval = interval,
        priority = priority,
        identifier = identifier,
        lastCall = 0,
        pendingArgs = nil,
        callCount = 0,
        totalTime = 0,
        enabled = true,
    }
    
    table.insert(throttledEvents[eventName], throttleData)
    
    DamiaUI.Engine:LogDebug("Registered throttled event: %s for %s (interval: %.3fs, priority: %d)", 
                           identifier, eventName, adjustedInterval, priority)
    return true
end

-- Fire throttled event
function Throttle:FireEvent(eventName, ...)
    if not throttledEvents[eventName] then
        return false
    end
    
    local currentTime = GetTime()
    
    for _, throttleData in ipairs(throttledEvents[eventName]) do
        if throttleData.enabled then
            -- Store pending arguments
            throttleData.pendingArgs = {...}
            
            -- Check if we should process immediately (high priority or first call)
            if throttleData.priority <= PRIORITY_HIGH and throttleData.lastCall == 0 then
                self:ExecuteThrottledCallback(throttleData, eventName, ...)
            end
        end
    end
    
    return true
end

-- Process all throttled events
function Throttle:ProcessThrottledEvents()
    if not throttlingState.enabled then
        return
    end
    
    local currentTime = GetTime()
    local eventsProcessed = 0
    
    for eventName, eventList in pairs(throttledEvents) do
        for _, throttleData in ipairs(eventList) do
            if throttleData.enabled and throttleData.pendingArgs then
                -- Check if enough time has passed
                if currentTime - throttleData.lastCall >= throttleData.interval then
                    self:ExecuteThrottledCallback(throttleData, eventName, unpack(throttleData.pendingArgs))
                    throttleData.pendingArgs = nil
                    eventsProcessed = eventsProcessed + 1
                    
                    -- Limit processing per frame for performance
                    if eventsProcessed >= 50 then
                        break
                    end
                end
            end
        end
        
        if eventsProcessed >= 50 then
            break
        end
    end
    
    if eventsProcessed > 0 then
        throttlingStats.eventsThrottled = throttlingStats.eventsThrottled + eventsProcessed
    end
end

-- Execute throttled callback
function Throttle:ExecuteThrottledCallback(throttleData, eventName, ...)
    local startTime = GetTime()
    throttleData.lastCall = startTime
    
    local success, result = pcall(throttleData.callback, eventName, ...)
    
    local executionTime = GetTime() - startTime
    throttleData.callCount = throttleData.callCount + 1
    throttleData.totalTime = throttleData.totalTime + executionTime
    
    if not success then
        DamiaUI.Engine:LogError("Throttled event callback error [%s]: %s", 
                               throttleData.identifier, result)
    end
end

--[[
===============================================================================
EVENT BATCHING
===============================================================================
--]]

-- Register event for batching
function Throttle:RegisterBatchEvent(eventName, batchCallback, batchWindow, maxBatchSize)
    if not eventName or not batchCallback then
        return false
    end
    
    batchWindow = batchWindow or BATCH_WINDOW
    maxBatchSize = maxBatchSize or MAX_BATCH_SIZE
    
    eventBatches[eventName] = {
        callback = batchCallback,
        batchWindow = batchWindow,
        maxBatchSize = maxBatchSize,
        events = {},
        lastProcessed = 0,
        timer = nil,
    }
    
    DamiaUI.Engine:LogDebug("Registered batch event: %s (window: %.3fs, size: %d)", 
                           eventName, batchWindow, maxBatchSize)
    return true
end

-- Add event to batch
function Throttle:BatchEvent(eventName, ...)
    local batch = eventBatches[eventName]
    if not batch then
        return false
    end
    
    table.insert(batch.events, {...})
    
    -- Process immediately if batch is full
    if #batch.events >= batch.maxBatchSize then
        self:ProcessBatch(eventName)
        return true
    end
    
    -- Set timer if not already running
    if not batch.timer then
        batch.timer = C_Timer.NewTimer(batch.batchWindow, function()
            Throttle:ProcessBatch(eventName)
        end)
    end
    
    return true
end

-- Process event batches
function Throttle:ProcessEventBatches()
    local currentTime = GetTime()
    
    for eventName, batch in pairs(eventBatches) do
        if #batch.events > 0 and currentTime - batch.lastProcessed >= batch.batchWindow then
            self:ProcessBatch(eventName)
        end
    end
end

-- Process individual batch
function Throttle:ProcessBatch(eventName)
    local batch = eventBatches[eventName]
    if not batch or #batch.events == 0 then
        return
    end
    
    local events = batch.events
    batch.events = {}
    batch.lastProcessed = GetTime()
    batch.timer = nil
    
    local startTime = GetTime()
    local success, result = pcall(batch.callback, eventName, events)
    
    if success then
        throttlingStats.eventsBatched = throttlingStats.eventsBatched + #events
        DamiaUI.Engine:LogDebug("Processed batch: %s (%d events in %.2fms)", 
                               eventName, #events, (GetTime() - startTime) * 1000)
    else
        DamiaUI.Engine:LogError("Batch callback error [%s]: %s", eventName, result)
    end
end

--[[
===============================================================================
UPDATE FREQUENCY MANAGEMENT
===============================================================================
--]]

-- Register update callback with frequency control
function Throttle:RegisterUpdateCallback(identifier, callback, frequency, priority)
    if not identifier or not callback then
        return false
    end
    
    frequency = frequency or 30 -- Default 30 FPS
    priority = priority or PRIORITY_NORMAL
    
    local interval = 1 / frequency
    local adjustedInterval = self:CalculateAdjustedInterval(interval, priority)
    
    updateCallbacks[identifier] = {
        callback = callback,
        frequency = frequency,
        interval = adjustedInterval,
        baseInterval = interval,
        priority = priority,
        lastCall = 0,
        elapsedTime = 0,
        enabled = true,
        callCount = 0,
        totalTime = 0,
    }
    
    DamiaUI.Engine:LogDebug("Registered update callback: %s (frequency: %dFPS, priority: %d)", 
                           identifier, frequency, priority)
    return true
end

-- Unregister update callback
function Throttle:UnregisterUpdateCallback(identifier)
    if updateCallbacks[identifier] then
        updateCallbacks[identifier] = nil
        DamiaUI.Engine:LogDebug("Unregistered update callback: %s", identifier)
        return true
    end
    return false
end

-- Process update callbacks
function Throttle:ProcessUpdateCallbacks(elapsed)
    if not throttlingState.enabled then
        return
    end
    
    for identifier, updateData in pairs(updateCallbacks) do
        if updateData.enabled then
            updateData.elapsedTime = updateData.elapsedTime + elapsed
            
            if updateData.elapsedTime >= updateData.interval then
                local startTime = GetTime()
                local success, result = pcall(updateData.callback, updateData.elapsedTime)
                local executionTime = GetTime() - startTime
                
                updateData.lastCall = GetTime()
                updateData.elapsedTime = 0
                updateData.callCount = updateData.callCount + 1
                updateData.totalTime = updateData.totalTime + executionTime
                
                if not success then
                    DamiaUI.Engine:LogError("Update callback error [%s]: %s", identifier, result)
                end
            end
        end
    end
end

-- Adjust update frequency for all callbacks
function Throttle:AdjustUpdateFrequencies(multiplier)
    multiplier = multiplier or throttlingState.globalMultiplier
    
    for identifier, updateData in pairs(updateCallbacks) do
        updateData.interval = self:CalculateAdjustedInterval(updateData.baseInterval, updateData.priority, multiplier)
    end
    
    DamiaUI.Engine:LogDebug("Update frequencies adjusted by multiplier: %.2f", multiplier)
end

--[[
===============================================================================
DEBOUNCING
===============================================================================
--]]

-- Register debounced callback
function Throttle:RegisterDebouncedCallback(identifier, callback, delay, priority)
    if not identifier or not callback then
        return false
    end
    
    delay = delay or 0.25 -- Default 250ms delay
    priority = priority or PRIORITY_NORMAL
    
    debouncedCallbacks[identifier] = {
        callback = callback,
        delay = delay,
        priority = priority,
        timer = nil,
        pendingArgs = nil,
        lastTrigger = 0,
        enabled = true,
    }
    
    DamiaUI.Engine:LogDebug("Registered debounced callback: %s (delay: %.3fs)", identifier, delay)
    return true
end

-- Trigger debounced callback
function Throttle:TriggerDebounced(identifier, ...)
    local debounceData = debouncedCallbacks[identifier]
    if not debounceData or not debounceData.enabled then
        return false
    end
    
    debounceData.pendingArgs = {...}
    debounceData.lastTrigger = GetTime()
    
    -- Cancel existing timer
    if debounceData.timer then
        debounceData.timer:Cancel()
    end
    
    -- Set new timer
    debounceData.timer = C_Timer.NewTimer(debounceData.delay, function()
        if debounceData.pendingArgs then
            local success, result = pcall(debounceData.callback, unpack(debounceData.pendingArgs))
            if not success then
                DamiaUI.Engine:LogError("Debounced callback error [%s]: %s", identifier, result)
            end
            debounceData.pendingArgs = nil
            debounceData.timer = nil
        end
    end)
    
    return true
end

-- Process debounced callbacks (for immediate execution when needed)
function Throttle:ProcessDebouncedCallbacks()
    if not throttlingState.enabled then
        return
    end
    
    -- This function handles immediate execution for high-priority debounced callbacks
    for identifier, debounceData in pairs(debouncedCallbacks) do
        if debounceData.enabled and debounceData.priority <= PRIORITY_HIGH and debounceData.pendingArgs then
            local currentTime = GetTime()
            -- Execute immediately for high priority items that have been waiting
            if currentTime - debounceData.lastTrigger >= debounceData.delay / 2 then
                if debounceData.timer then
                    debounceData.timer:Cancel()
                    debounceData.timer = nil
                end
                
                local success, result = pcall(debounceData.callback, unpack(debounceData.pendingArgs))
                if not success then
                    DamiaUI.Engine:LogError("Debounced callback error [%s]: %s", identifier, result)
                end
                
                debounceData.pendingArgs = nil
            end
        end
    end
end

--[[
===============================================================================
DYNAMIC THROTTLING ADJUSTMENT
===============================================================================
--]]

-- Calculate adjusted interval based on priority and current conditions
function Throttle:CalculateAdjustedInterval(baseInterval, priority, customMultiplier)
    priority = priority or PRIORITY_NORMAL
    local multiplier = customMultiplier or throttlingState.globalMultiplier
    
    -- Apply combat multiplier if in combat
    if InCombatLockdown() then
        multiplier = multiplier * throttlingState.combatMultiplier
    end
    
    -- Priority-based adjustments
    local priorityMultiplier = 1.0
    if priority == PRIORITY_CRITICAL then
        priorityMultiplier = 0.5 -- Reduce throttling for critical events
    elseif priority == PRIORITY_HIGH then
        priorityMultiplier = 0.75
    elseif priority == PRIORITY_LOW then
        priorityMultiplier = 1.5
    elseif priority == PRIORITY_BACKGROUND then
        priorityMultiplier = 2.0
    end
    
    local adjustedInterval = baseInterval * multiplier * priorityMultiplier
    
    -- Enforce limits
    return math.max(MIN_THROTTLE_INTERVAL, math.min(MAX_THROTTLE_INTERVAL, adjustedInterval))
end

-- Update throttling based on performance data
function Throttle:UpdateDynamicThrottling()
    if not throttlingState.adaptiveMode then
        return
    end
    
    local currentFPS = throttlingState.currentFPS
    local newMultiplier = 1.0
    local newPerformanceLevel = "normal"
    
    if currentFPS >= FPS_THRESHOLD_HIGH then
        newMultiplier = 0.8 -- Reduce throttling for good performance
        newPerformanceLevel = "high"
    elseif currentFPS >= FPS_THRESHOLD_NORMAL then
        newMultiplier = 1.0 -- Normal throttling
        newPerformanceLevel = "normal"
    elseif currentFPS >= FPS_THRESHOLD_LOW then
        newMultiplier = 1.3 -- Increase throttling for low performance
        newPerformanceLevel = "low"
    else
        newMultiplier = 1.8 -- Aggressive throttling for very low performance
        newPerformanceLevel = "critical"
    end
    
    -- Only update if there's a significant change
    if math.abs(newMultiplier - throttlingState.globalMultiplier) > 0.1 or
       newPerformanceLevel ~= throttlingState.performanceLevel then
        
        local oldMultiplier = throttlingState.globalMultiplier
        throttlingState.globalMultiplier = newMultiplier
        throttlingState.performanceLevel = newPerformanceLevel
        
        -- Update all throttled events
        self:UpdateAllThrottling()
        
        DamiaUI.Engine:LogInfo("Dynamic throttling updated: %.1f -> %.1f (%s performance)", 
                              oldMultiplier, newMultiplier, newPerformanceLevel)
    end
end

-- Update all throttling intervals
function Throttle:UpdateAllThrottling()
    -- Update throttled events
    for eventName, eventList in pairs(throttledEvents) do
        for _, throttleData in ipairs(eventList) do
            throttleData.interval = self:CalculateAdjustedInterval(throttleData.baseInterval, throttleData.priority)
        end
    end
    
    -- Update update callbacks
    self:AdjustUpdateFrequencies()
end

--[[
===============================================================================
EVENT HANDLERS
===============================================================================
--]]

-- Handle performance updates
function Throttle:OnPerformanceUpdate(data)
    if data and data.fps then
        throttlingState.currentFPS = data.fps
        self:UpdateDynamicThrottling()
    end
end

-- Handle combat state changes
function Throttle:OnCombatStateChanged(inCombat)
    if inCombat then
        -- Increase throttling during combat
        local oldMultiplier = throttlingState.combatMultiplier
        throttlingState.combatMultiplier = math.min(2.0, throttlingState.combatMultiplier * 1.2)
        
        DamiaUI.Engine:LogDebug("Combat throttling enabled: multiplier %.1f -> %.1f", 
                               oldMultiplier, throttlingState.combatMultiplier)
    else
        -- Reset combat multiplier
        throttlingState.combatMultiplier = 1.5
        DamiaUI.Engine:LogDebug("Combat throttling disabled")
    end
    
    self:UpdateAllThrottling()
end

-- Handle optimization level changes
function Throttle:OnOptimizationChanged(level)
    local multipliers = {
        [0] = 0.8, -- No optimization - less throttling
        [1] = 1.0, -- Light optimization - normal throttling
        [2] = 1.3, -- Moderate optimization - more throttling
        [3] = 1.8, -- Aggressive optimization - heavy throttling
    }
    
    local newMultiplier = multipliers[level] or 1.0
    
    if newMultiplier ~= throttlingState.globalMultiplier then
        local oldMultiplier = throttlingState.globalMultiplier
        throttlingState.globalMultiplier = newMultiplier
        
        self:UpdateAllThrottling()
        
        DamiaUI.Engine:LogInfo("Throttling optimization level %d: multiplier %.1f -> %.1f", 
                              level, oldMultiplier, newMultiplier)
    end
end

--[[
===============================================================================
CONTROL FUNCTIONS
===============================================================================
--]]

-- Enable/disable throttling system
function Throttle:SetEnabled(enabled)
    throttlingState.enabled = enabled
    DamiaUI.Engine:LogInfo("Throttling system %s", enabled and "enabled" or "disabled")
end

-- Enable/disable adaptive throttling
function Throttle:SetAdaptiveMode(enabled)
    throttlingState.adaptiveMode = enabled
    DamiaUI.Engine:LogInfo("Adaptive throttling %s", enabled and "enabled" or "disabled")
end

-- Set global throttling multiplier
function Throttle:SetGlobalMultiplier(multiplier)
    multiplier = math.max(0.1, math.min(5.0, multiplier))
    
    local oldMultiplier = throttlingState.globalMultiplier
    throttlingState.globalMultiplier = multiplier
    
    self:UpdateAllThrottling()
    
    DamiaUI.Engine:LogInfo("Global throttling multiplier: %.1f -> %.1f", oldMultiplier, multiplier)
end

-- Enable/disable specific throttled event
function Throttle:SetEventEnabled(eventName, identifier, enabled)
    if not throttledEvents[eventName] then
        return false
    end
    
    for _, throttleData in ipairs(throttledEvents[eventName]) do
        if throttleData.identifier == identifier then
            throttleData.enabled = enabled
            DamiaUI.Engine:LogDebug("Throttled event %s:%s %s", eventName, identifier, enabled and "enabled" or "disabled")
            return true
        end
    end
    
    return false
end

-- Enable/disable update callback
function Throttle:SetUpdateCallbackEnabled(identifier, enabled)
    if updateCallbacks[identifier] then
        updateCallbacks[identifier].enabled = enabled
        DamiaUI.Engine:LogDebug("Update callback %s %s", identifier, enabled and "enabled" or "disabled")
        return true
    end
    return false
end

--[[
===============================================================================
STATISTICS AND REPORTING
===============================================================================
--]]

-- Get throttling statistics
function Throttle:GetStatistics()
    local totalEvents = 0
    local totalCallbacks = 0
    local avgThrottleTime = 0
    
    -- Calculate averages from throttled events
    for eventName, eventList in pairs(throttledEvents) do
        for _, throttleData in ipairs(eventList) do
            totalEvents = totalEvents + 1
            if throttleData.callCount > 0 then
                avgThrottleTime = avgThrottleTime + (throttleData.totalTime / throttleData.callCount)
            end
        end
    end
    
    -- Count update callbacks
    for _ in pairs(updateCallbacks) do
        totalCallbacks = totalCallbacks + 1
    end
    
    return {
        enabled = throttlingState.enabled,
        globalMultiplier = throttlingState.globalMultiplier,
        combatMultiplier = throttlingState.combatMultiplier,
        performanceLevel = throttlingState.performanceLevel,
        currentFPS = throttlingState.currentFPS,
        totalThrottledEvents = totalEvents,
        totalUpdateCallbacks = totalCallbacks,
        eventsThrottled = throttlingStats.eventsThrottled,
        eventsBatched = throttlingStats.eventsBatched,
        callbacksDeferred = throttlingStats.callbacksDeferred,
        averageExecutionTime = totalEvents > 0 and (avgThrottleTime / totalEvents) or 0,
    }
end

-- Print throttling report
function Throttle:PrintReport()
    local stats = self:GetStatistics()
    
    DamiaUI.Engine:LogInfo("Throttling System Report:")
    DamiaUI.Engine:LogInfo("  Status: %s (adaptive: %s)", 
                          stats.enabled and "Enabled" or "Disabled",
                          throttlingState.adaptiveMode and "On" or "Off")
    DamiaUI.Engine:LogInfo("  Performance: %s (%.1f FPS)", stats.performanceLevel, stats.currentFPS)
    DamiaUI.Engine:LogInfo("  Multipliers: Global %.1f, Combat %.1f", 
                          stats.globalMultiplier, stats.combatMultiplier)
    DamiaUI.Engine:LogInfo("  Registered: %d throttled events, %d update callbacks", 
                          stats.totalThrottledEvents, stats.totalUpdateCallbacks)
    DamiaUI.Engine:LogInfo("  Processed: %d throttled, %d batched events", 
                          stats.eventsThrottled, stats.eventsBatched)
    DamiaUI.Engine:LogInfo("  Average execution time: %.2fms", stats.averageExecutionTime * 1000)
end

-- Reset statistics
function Throttle:ResetStatistics()
    throttlingStats.eventsThrottled = 0
    throttlingStats.eventsBatched = 0
    throttlingStats.callbacksDeferred = 0
    throttlingStats.totalSavedCalls = 0
    
    -- Reset individual callback stats
    for eventName, eventList in pairs(throttledEvents) do
        for _, throttleData in ipairs(eventList) do
            throttleData.callCount = 0
            throttleData.totalTime = 0
        end
    end
    
    for identifier, updateData in pairs(updateCallbacks) do
        updateData.callCount = 0
        updateData.totalTime = 0
    end
    
    DamiaUI.Engine:LogInfo("Throttling statistics reset")
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Auto-initialize when engine is ready
DamiaUI.Events:RegisterCustomEvent("DAMIA_INITIALIZED", function()
    Throttle:Initialize()
end, 1, "Throttle_AutoInit")

-- Register for specific events that should be throttled by default
DamiaUI.Events:RegisterCustomEvent("DAMIA_ADDON_LOADED", function()
    -- Register common throttled events
    Throttle:RegisterEvent("UNIT_HEALTH_FREQUENT", function() end, 0.1, PRIORITY_LOW, "Default_Health")
    Throttle:RegisterEvent("UNIT_POWER_FREQUENT", function() end, 0.1, PRIORITY_LOW, "Default_Power")
    Throttle:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function() end, 0.05, PRIORITY_NORMAL, "Default_Combat")
    
    -- Register batch events
    Throttle:RegisterBatchEvent("UI_UPDATE_BATCH", function(eventName, events)
        -- Process batched UI updates
        DamiaUI.Events:Fire("DAMIA_BATCH_UI_UPDATE", events)
    end, BATCH_WINDOW, MAX_BATCH_SIZE)
    
    DamiaUI.Engine:LogDebug("Default throttled events registered")
end, 3, "Throttle_DefaultEvents")

-- Slash command for throttling control
SLASH_DAMIATHROTTLE1 = "/damiathrottle"
SlashCmdList["DAMIATHROTTLE"] = function(msg)
    local command = (msg or ""):lower()
    
    if command == "report" or command == "" then
        Throttle:PrintReport()
    elseif command == "reset" then
        Throttle:ResetStatistics()
    elseif command == "enable" then
        Throttle:SetEnabled(true)
    elseif command == "disable" then
        Throttle:SetEnabled(false)
    elseif command == "adaptive on" then
        Throttle:SetAdaptiveMode(true)
    elseif command == "adaptive off" then
        Throttle:SetAdaptiveMode(false)
    elseif command:match("^mult%s+([%d%.]+)$") then
        local multiplier = tonumber(command:match("^mult%s+([%d%.]+)$"))
        if multiplier then
            Throttle:SetGlobalMultiplier(multiplier)
        end
    else
        DamiaUI.Engine:LogInfo("Throttling Commands:")
        DamiaUI.Engine:LogInfo("  /damiathrottle report - Show throttling report")
        DamiaUI.Engine:LogInfo("  /damiathrottle reset - Reset statistics")
        DamiaUI.Engine:LogInfo("  /damiathrottle enable/disable - Control throttling")
        DamiaUI.Engine:LogInfo("  /damiathrottle adaptive on/off - Control adaptive mode")
        DamiaUI.Engine:LogInfo("  /damiathrottle mult <number> - Set global multiplier")
    end
end

DamiaUI.Engine:LogInfo("Event throttling and update frequency management system loaded")