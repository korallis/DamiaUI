--[[
===============================================================================
Damia UI - Event System
===============================================================================
Three-tier event handling system for DamiaUI addon:
1. WoW Events - Game event registration and handling
2. Custom Events - Inter-module communication
3. Configuration Events - Settings change propagation

Features:
- Priority-based event handling
- Combat lockdown management
- Event throttling and batching
- Performance monitoring
- Memory efficient event management

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer
local table = table
local string = string

-- Create Events module
local Events = {}
DamiaUI.Events = Events

-- Event system constants
local PRIORITY_CRITICAL = 1
local PRIORITY_HIGH = 2
local PRIORITY_NORMAL = 3
local PRIORITY_LOW = 4
local MAX_EVENTS_PER_FRAME = 20
local EVENT_THROTTLE_INTERVAL = 0.016 -- ~60 FPS

-- Event storage and management
local eventFrame = CreateFrame("Frame", "DamiaUIEventFrame")
local eventHandlers = {}
local customEventHandlers = {}
local configEventHandlers = {}
local eventQueue = {}
local throttledEvents = {}
local lastEventProcessTime = 0
local eventStatistics = {}

-- Combat event queue
local combatEventQueue = {}
local combatSafeEvents = {
    ["PLAYER_LOGIN"] = true,
    ["ADDON_LOADED"] = true,
    ["PLAYER_LOGOUT"] = true,
    ["PLAYER_ENTERING_WORLD"] = true,
    ["PLAYER_LEAVING_WORLD"] = true,
    ["VARIABLES_LOADED"] = true,
}

-- Event batching for performance
local eventBatcher = {
    batches = {},
    timeout = 0.1, -- 100ms batch window
    maxBatchSize = 50,
}

--[[
===============================================================================
CORE EVENT SYSTEM INFRASTRUCTURE
===============================================================================
--]]

-- Initialize event statistics
local function InitEventStats(eventName)
    if not eventStatistics[eventName] then
        eventStatistics[eventName] = {
            callCount = 0,
            totalTime = 0,
            averageTime = 0,
            lastCalled = 0,
            errors = 0,
        }
    end
end

-- Update event statistics
local function UpdateEventStats(eventName, executionTime, hasError)
    local stats = eventStatistics[eventName]
    if not stats then
        InitEventStats(eventName)
        stats = eventStatistics[eventName]
    end
    
    stats.callCount = stats.callCount + 1
    stats.totalTime = stats.totalTime + executionTime
    stats.averageTime = stats.totalTime / stats.callCount
    stats.lastCalled = GetTime()
    
    if hasError then
        stats.errors = stats.errors + 1
    end
end

-- Get event statistics for monitoring
function Events:GetEventStatistics(eventName)
    if eventName then
        return eventStatistics[eventName]
    else
        return eventStatistics
    end
end

-- Reset event statistics
function Events:ResetEventStatistics()
    eventStatistics = {}
    DamiaUI.Engine:LogInfo("Event statistics reset")
end

--[[
===============================================================================
WOW EVENT HANDLING (TIER 1)
===============================================================================
--]]

-- Register WoW event handler with priority
function Events:RegisterEvent(event, callback, priority, identifier)
    if not event or not callback then
        DamiaUI.Engine:LogError("RegisterEvent: Invalid event or callback")
        return false
    end
    
    if type(callback) ~= "function" then
        DamiaUI.Engine:LogError("RegisterEvent: Callback must be a function")
        return false
    end
    
    priority = priority or PRIORITY_NORMAL
    identifier = identifier or ("Handler_" .. tostring(callback))
    
    -- Initialize event handler list
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
        InitEventStats(event)
    end
    
    -- Create handler entry
    local handler = {
        callback = callback,
        priority = priority,
        identifier = identifier,
        enabled = true,
        callCount = 0,
        totalTime = 0,
        lastError = nil,
    }
    
    -- Insert maintaining priority order (lower number = higher priority)
    local inserted = false
    for i, existingHandler in ipairs(eventHandlers[event]) do
        if priority < existingHandler.priority then
            table.insert(eventHandlers[event], i, handler)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(eventHandlers[event], handler)
    end
    
    DamiaUI.Engine:LogDebug("Registered event handler: %s for %s (priority %d)", 
                           identifier, event, priority)
    return true
end

-- Unregister WoW event handler
function Events:UnregisterEvent(event, identifier)
    if not event or not identifier then
        DamiaUI.Engine:LogError("UnregisterEvent: Invalid event or identifier")
        return false
    end
    
    if not eventHandlers[event] then
        DamiaUI.Engine:LogWarning("UnregisterEvent: Event %s not registered", event)
        return false
    end
    
    -- Find and remove handler
    for i, handler in ipairs(eventHandlers[event]) do
        if handler.identifier == identifier then
            table.remove(eventHandlers[event], i)
            
            -- Unregister event if no handlers remain
            if #eventHandlers[event] == 0 then
                eventFrame:UnregisterEvent(event)
                eventHandlers[event] = nil
            end
            
            DamiaUI.Engine:LogDebug("Unregistered event handler: %s for %s", identifier, event)
            return true
        end
    end
    
    DamiaUI.Engine:LogWarning("UnregisterEvent: Handler %s not found for %s", identifier, event)
    return false
end

-- Enable/disable event handler
function Events:SetEventHandlerEnabled(event, identifier, enabled)
    if not eventHandlers[event] then
        return false
    end
    
    for _, handler in ipairs(eventHandlers[event]) do
        if handler.identifier == identifier then
            handler.enabled = enabled
            DamiaUI.Engine:LogDebug("Event handler %s for %s %s", 
                                   identifier, event, enabled and "enabled" or "disabled")
            return true
        end
    end
    
    return false
end

-- Process WoW event through registered handlers
local function ProcessWoWEvent(event, ...)
    local handlers = eventHandlers[event]
    if not handlers then
        return
    end
    
    local startTime = GetTime()
    local processedCount = 0
    local errorCount = 0
    
    -- Check if event should be queued during combat
    if InCombatLockdown() and not combatSafeEvents[event] then
        table.insert(combatEventQueue, {event = event, args = {...}, time = startTime})
        return
    end
    
    -- Process handlers in priority order
    for _, handler in ipairs(handlers) do
        if handler.enabled then
            local handlerStartTime = GetTime()
            
            -- Use ErrorHandler SafeCall if available
            local success, result
            if DamiaUI.ErrorHandler and DamiaUI.ErrorHandler.SafeCall then
                success, result = DamiaUI.ErrorHandler:SafeCall(handler.callback, "Events",
                    { event = event, handler = handler.identifier }, event, ...)
            else
                success, result = pcall(handler.callback, event, ...)
            end
            
            local handlerTime = GetTime() - handlerStartTime
            
            handler.callCount = handler.callCount + 1
            handler.totalTime = handler.totalTime + handlerTime
            
            if success then
                processedCount = processedCount + 1
            else
                errorCount = errorCount + 1
                handler.lastError = result
                if not DamiaUI.ErrorHandler then
                    DamiaUI.Engine:LogError("Event handler error [%s]: %s", handler.identifier, result)
                end
            end
        end
    end
    
    local totalTime = GetTime() - startTime
    UpdateEventStats(event, totalTime, errorCount > 0)
    
    if totalTime > 0.01 then -- Log slow events (>10ms)
        DamiaUI.Engine:LogWarning("Slow event processing: %s took %.2fms", event, totalTime * 1000)
    end
end

--[[
===============================================================================
CUSTOM EVENT SYSTEM (TIER 2)
===============================================================================
--]]

-- Fire custom event for inter-module communication
function Events:Fire(eventName, ...)
    if not eventName then
        DamiaUI.Engine:LogError("Fire: Invalid event name")
        return false
    end
    
    local handlers = customEventHandlers[eventName]
    if not handlers then
        return true -- No handlers is not an error
    end
    
    local startTime = GetTime()
    local processedCount = 0
    local errorCount = 0
    
    DamiaUI.Engine:LogDebug("Firing custom event: %s", eventName)
    
    -- Process custom event handlers
    for _, handler in ipairs(handlers) do
        if handler.enabled then
            local handlerStartTime = GetTime()
            local success, result = pcall(handler.callback, eventName, ...)
            local handlerTime = GetTime() - handlerStartTime
            
            handler.callCount = handler.callCount + 1
            handler.totalTime = handler.totalTime + handlerTime
            
            if success then
                processedCount = processedCount + 1
            else
                errorCount = errorCount + 1
                handler.lastError = result
                DamiaUI.Engine:LogError("Custom event handler error [%s]: %s", 
                                       handler.identifier, result)
            end
        end
    end
    
    local totalTime = GetTime() - startTime
    UpdateEventStats("CUSTOM_" .. eventName, totalTime, errorCount > 0)
    
    return errorCount == 0
end

-- Register custom event handler
function Events:RegisterCustomEvent(eventName, callback, priority, identifier)
    if not eventName or not callback then
        DamiaUI.Engine:LogError("RegisterCustomEvent: Invalid event name or callback")
        return false
    end
    
    priority = priority or PRIORITY_NORMAL
    identifier = identifier or ("CustomHandler_" .. tostring(callback))
    
    if not customEventHandlers[eventName] then
        customEventHandlers[eventName] = {}
        InitEventStats("CUSTOM_" .. eventName)
    end
    
    local handler = {
        callback = callback,
        priority = priority,
        identifier = identifier,
        enabled = true,
        callCount = 0,
        totalTime = 0,
        lastError = nil,
    }
    
    -- Insert maintaining priority order
    local inserted = false
    for i, existingHandler in ipairs(customEventHandlers[eventName]) do
        if priority < existingHandler.priority then
            table.insert(customEventHandlers[eventName], i, handler)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(customEventHandlers[eventName], handler)
    end
    
    DamiaUI.Engine:LogDebug("Registered custom event handler: %s for %s", identifier, eventName)
    return true
end

-- Unregister custom event handler
function Events:UnregisterCustomEvent(eventName, identifier)
    if not customEventHandlers[eventName] then
        return false
    end
    
    for i, handler in ipairs(customEventHandlers[eventName]) do
        if handler.identifier == identifier then
            table.remove(customEventHandlers[eventName], i)
            
            if #customEventHandlers[eventName] == 0 then
                customEventHandlers[eventName] = nil
            end
            
            DamiaUI.Engine:LogDebug("Unregistered custom event handler: %s for %s", 
                                   identifier, eventName)
            return true
        end
    end
    
    return false
end

--[[
===============================================================================
CONFIGURATION EVENT SYSTEM (TIER 3)
===============================================================================
--]]

-- Fire configuration change event
function Events:FireConfigEvent(configKey, oldValue, newValue)
    if not configKey then
        return false
    end
    
    local handlers = configEventHandlers[configKey]
    if not handlers then
        return true
    end
    
    DamiaUI.Engine:LogDebug("Config changed: %s (%s -> %s)", 
                           configKey, tostring(oldValue), tostring(newValue))
    
    local startTime = GetTime()
    local processedCount = 0
    local errorCount = 0
    
    for _, handler in ipairs(handlers) do
        if handler.enabled then
            local success, result = pcall(handler.callback, configKey, oldValue, newValue)
            
            if success then
                processedCount = processedCount + 1
            else
                errorCount = errorCount + 1
                DamiaUI.Engine:LogError("Config event handler error [%s]: %s", 
                                       handler.identifier, result)
            end
        end
    end
    
    local totalTime = GetTime() - startTime
    UpdateEventStats("CONFIG_" .. configKey, totalTime, errorCount > 0)
    
    -- Also fire generic config change event
    self:Fire("DAMIA_CONFIG_CHANGED", configKey, oldValue, newValue)
    
    return errorCount == 0
end

-- Register configuration change handler
function Events:RegisterConfigEvent(configKey, callback, identifier)
    if not configKey or not callback then
        DamiaUI.Engine:LogError("RegisterConfigEvent: Invalid config key or callback")
        return false
    end
    
    identifier = identifier or ("ConfigHandler_" .. tostring(callback))
    
    if not configEventHandlers[configKey] then
        configEventHandlers[configKey] = {}
        InitEventStats("CONFIG_" .. configKey)
    end
    
    local handler = {
        callback = callback,
        identifier = identifier,
        enabled = true,
    }
    
    table.insert(configEventHandlers[configKey], handler)
    
    DamiaUI.Engine:LogDebug("Registered config event handler: %s for %s", identifier, configKey)
    return true
end

-- Unregister configuration change handler
function Events:UnregisterConfigEvent(configKey, identifier)
    if not configEventHandlers[configKey] then
        return false
    end
    
    for i, handler in ipairs(configEventHandlers[configKey]) do
        if handler.identifier == identifier then
            table.remove(configEventHandlers[configKey], i)
            
            if #configEventHandlers[configKey] == 0 then
                configEventHandlers[configKey] = nil
            end
            
            DamiaUI.Engine:LogDebug("Unregistered config event handler: %s for %s", 
                                   identifier, configKey)
            return true
        end
    end
    
    return false
end

--[[
===============================================================================
EVENT THROTTLING AND BATCHING
===============================================================================
--]]

-- Add event to throttling system
function Events:ThrottleEvent(eventName, interval, callback)
    if not eventName or not callback then
        return false
    end
    
    interval = interval or EVENT_THROTTLE_INTERVAL
    
    if not throttledEvents[eventName] then
        throttledEvents[eventName] = {
            interval = interval,
            callback = callback,
            lastCall = 0,
            pendingArgs = nil,
        }
    end
    
    return true
end

-- Process throttled event
local function ProcessThrottledEvent(eventName, ...)
    local throttled = throttledEvents[eventName]
    if not throttled then
        return false
    end
    
    local currentTime = GetTime()
    throttled.pendingArgs = {...}
    
    if currentTime - throttled.lastCall >= throttled.interval then
        throttled.lastCall = currentTime
        local success, result = pcall(throttled.callback, eventName, unpack(throttled.pendingArgs))
        
        if not success then
            DamiaUI.Engine:LogError("Throttled event error [%s]: %s", eventName, result)
        end
        
        throttled.pendingArgs = nil
        return true
    end
    
    return false
end

-- Batch similar events together
function Events:BatchEvent(eventName, ...)
    if not eventName then
        return false
    end
    
    if not eventBatcher.batches[eventName] then
        eventBatcher.batches[eventName] = {
            events = {},
            timer = nil,
        }
    end
    
    local batch = eventBatcher.batches[eventName]
    table.insert(batch.events, {...})
    
    -- Start batch timer if not already running
    if not batch.timer then
        batch.timer = C_Timer.NewTimer(eventBatcher.timeout, function()
            Events:ProcessEventBatch(eventName)
        end)
    end
    
    -- Process immediately if batch is full
    if #batch.events >= eventBatcher.maxBatchSize then
        Events:ProcessEventBatch(eventName)
    end
    
    return true
end

-- Process batched events
function Events:ProcessEventBatch(eventName)
    local batch = eventBatcher.batches[eventName]
    if not batch or #batch.events == 0 then
        return
    end
    
    local events = batch.events
    batch.events = {}
    batch.timer = nil
    
    -- Fire custom event with batched data
    self:Fire("DAMIA_BATCH_" .. eventName, events)
    
    DamiaUI.Engine:LogDebug("Processed batch: %s (%d events)", eventName, #events)
end

--[[
===============================================================================
COMBAT EVENT MANAGEMENT
===============================================================================
--]]

-- Process events queued during combat
local function ProcessCombatEventQueue()
    while #combatEventQueue > 0 do
        local queuedEvent = table.remove(combatEventQueue, 1)
        ProcessWoWEvent(queuedEvent.event, unpack(queuedEvent.args))
    end
    
    if #combatEventQueue > 0 then
        DamiaUI.Engine:LogInfo("Processed %d queued combat events", #combatEventQueue)
    end
end

-- Register combat state monitoring
Events:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    DamiaUI.Engine:LogDebug("Entering combat - queuing non-critical events")
    Events:Fire("DAMIA_COMBAT_STATE_CHANGED", true)
end, PRIORITY_CRITICAL, "DamiaUI_CombatEnter")

Events:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    DamiaUI.Engine:LogDebug("Leaving combat - processing queued events")
    ProcessCombatEventQueue()
    Events:Fire("DAMIA_COMBAT_STATE_CHANGED", false)
end, PRIORITY_CRITICAL, "DamiaUI_CombatLeave")

--[[
===============================================================================
EVENT FRAME SCRIPT HANDLERS
===============================================================================
--]]

-- Main event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    ProcessWoWEvent(event, ...)
end)

-- Throttled event processor
local throttleFrame = CreateFrame("Frame")
throttleFrame:SetScript("OnUpdate", function()
    local currentTime = GetTime()
    
    -- Process throttled events
    for eventName, throttled in pairs(throttledEvents) do
        if throttled.pendingArgs and currentTime - throttled.lastCall >= throttled.interval then
            ProcessThrottledEvent(eventName, unpack(throttled.pendingArgs))
        end
    end
end)

--[[
===============================================================================
PERFORMANCE MONITORING AND DEBUGGING
===============================================================================
--]]

-- Get event handler performance information
function Events:GetHandlerPerformance(event)
    if not eventHandlers[event] then
        return nil
    end
    
    local performance = {}
    for _, handler in ipairs(eventHandlers[event]) do
        performance[handler.identifier] = {
            callCount = handler.callCount,
            totalTime = handler.totalTime,
            averageTime = handler.callCount > 0 and (handler.totalTime / handler.callCount) or 0,
            lastError = handler.lastError,
            enabled = handler.enabled,
        }
    end
    
    return performance
end

-- Print event system status
function Events:PrintStatus()
    local wowEvents = 0
    local customEvents = 0
    local configEvents = 0
    
    for _ in pairs(eventHandlers) do wowEvents = wowEvents + 1 end
    for _ in pairs(customEventHandlers) do customEvents = customEvents + 1 end
    for _ in pairs(configEventHandlers) do configEvents = configEvents + 1 end
    
    DamiaUI.Engine:LogInfo("Event System Status:")
    DamiaUI.Engine:LogInfo("  WoW Events: %d", wowEvents)
    DamiaUI.Engine:LogInfo("  Custom Events: %d", customEvents)
    DamiaUI.Engine:LogInfo("  Config Events: %d", configEvents)
    DamiaUI.Engine:LogInfo("  Combat Queue: %d", #combatEventQueue)
    DamiaUI.Engine:LogInfo("  Throttled Events: %d", DamiaUI.Utils:GetTableSize(throttledEvents))
end

--[[
===============================================================================
PUBLIC API CONVENIENCE FUNCTIONS
===============================================================================
--]]

-- Convenience functions for common event operations
DamiaUI.RegisterEvent = function(event, callback, priority, identifier)
    return Events:RegisterEvent(event, callback, priority, identifier)
end

DamiaUI.UnregisterEvent = function(event, identifier)
    return Events:UnregisterEvent(event, identifier)
end

DamiaUI.FireEvent = function(eventName, ...)
    return Events:Fire(eventName, ...)
end

DamiaUI.RegisterCustomEvent = function(eventName, callback, priority, identifier)
    return Events:RegisterCustomEvent(eventName, callback, priority, identifier)
end

DamiaUI.IsInCombat = function()
    return InCombatLockdown()
end

-- Register core events for addon lifecycle
Events:RegisterEvent("ADDON_LOADED", function(event, loadedAddonName)
    if loadedAddonName == addonName then
        DamiaUI.Engine:LogInfo("Event system initialized")
        Events:Fire("DAMIA_ADDON_LOADED")
    end
end, PRIORITY_CRITICAL, "DamiaUI_AddonLoaded")

Events:RegisterEvent("PLAYER_LOGIN", function()
    Events:Fire("DAMIA_PLAYER_LOGIN")
end, PRIORITY_HIGH, "DamiaUI_PlayerLogin")

Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    Events:Fire("DAMIA_PLAYER_ENTERING_WORLD")
end, PRIORITY_HIGH, "DamiaUI_PlayerEnteringWorld")

-- UI scale change monitoring
Events:RegisterEvent("UI_SCALE_CHANGED", function()
    local newScale = UIParent:GetEffectiveScale()
    Events:Fire("DAMIA_SCALE_CHANGED", newScale)
end, PRIORITY_NORMAL, "DamiaUI_UIScaleChanged")