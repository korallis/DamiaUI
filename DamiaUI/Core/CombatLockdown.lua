--[[
===============================================================================
Damia UI - Combat Lockdown Management System
===============================================================================
Centralized combat lockdown protection system that queues protected operations
for execution after combat ends, following Blizzard's taint prevention model.

Features:
- Automatic InCombatLockdown() checking
- Queue system for deferred operations
- PLAYER_REGEN_ENABLED event handling
- Safe frame manipulation methods
- Comprehensive logging and error handling

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Create CombatLockdown module
local CombatLockdown = {}

-- Safe logging function that works before Engine is loaded
local function SafeLog(level, message, ...)
    if DamiaUI and DamiaUI.Engine and DamiaUI.Engine.LogInfo then
        if level == "ERROR" then
            DamiaUI.Engine:LogError(message, ...)
        elseif level == "WARNING" then
            DamiaUI.Engine:LogWarning(message, ...)
        elseif level == "DEBUG" then
            DamiaUI.Engine:LogDebug(message, ...)
        else
            DamiaUI.Engine:LogInfo(message, ...)
        end
    else
        -- Fallback to print with addon prefix
        print("|cffCC8010DamiaUI|r [" .. level .. "] " .. string.format(message, ...))
    end
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime

-- Operation queue for deferred execution
local operationQueue = {}
local queueProcessing = false
local eventFrame = nil

-- Protected operation types
local OPERATION_TYPES = {
    FRAME_POSITION = "frame_position",
    FRAME_SIZE = "frame_size",
    FRAME_SCALE = "frame_scale",
    FRAME_SHOW_HIDE = "frame_show_hide",
    FRAME_PARENT = "frame_parent",
    FRAME_STRATA = "frame_strata",
    FRAME_LEVEL = "frame_level",
    FRAME_ATTRIBUTE = "frame_attribute",
    FRAME_CREATION = "frame_creation",
    ACTION_BAR_UPDATE = "action_bar_update",
    UNIT_FRAME_UPDATE = "unit_frame_update"
}

-- Statistics tracking
local stats = {
    operationsQueued = 0,
    operationsExecuted = 0,
    operationsFailed = 0,
    queueProcessingTime = 0,
    lastQueueClear = 0
}

--[[
===============================================================================
CORE LOCKDOWN CHECKING
===============================================================================
--]]

--[[
    Check if currently in combat lockdown
    @return boolean inCombat
--]]
function CombatLockdown:IsInCombat()
    return InCombatLockdown()
end

--[[
    Execute operation immediately if not in combat, otherwise queue it
    @param operationType string The type of operation (from OPERATION_TYPES)
    @param func function The function to execute
    @param ... any Additional arguments to pass to the function
    @return boolean success Whether the operation was executed immediately
--]]
function CombatLockdown:ExecuteOrQueue(operationType, func, ...)
    if not func or type(func) ~= "function" then
        SafeLog("ERROR", "CombatLockdown:ExecuteOrQueue - Invalid function provided")
        return false
    end
    
    if not self:IsInCombat() then
        -- Execute immediately
        local success, result = pcall(func, ...)
        if success then
            SafeLog("DEBUG", "CombatLockdown: Executed %s operation immediately", operationType)
            return true
        else
            SafeLog("ERROR", "CombatLockdown: Failed to execute %s operation: %s", operationType, tostring(result))
            stats.operationsFailed = stats.operationsFailed + 1
            return false
        end
    else
        -- Queue for later execution
        self:QueueOperation(operationType, func, ...)
        SafeLog("DEBUG", "CombatLockdown: Queued %s operation for after combat", operationType)
        return false
    end
end

--[[
    Queue an operation for execution after combat
    @param operationType string The type of operation
    @param func function The function to execute
    @param ... any Additional arguments to pass to the function
--]]
function CombatLockdown:QueueOperation(operationType, func, ...)
    local operation = {
        type = operationType,
        func = func,
        args = {...},
        timestamp = GetTime(),
        id = #operationQueue + 1
    }
    
    table.insert(operationQueue, operation)
    stats.operationsQueued = stats.operationsQueued + 1
    
    -- Ensure event frame is set up
    self:EnsureEventFrame()
    
    SafeLog("DEBUG", "CombatLockdown: Queued operation %d (%s)", operation.id, operationType)
end

--[[
    Clear all queued operations (use with caution)
--]]
function CombatLockdown:ClearQueue()
    local count = #operationQueue
    operationQueue = {}
    stats.lastQueueClear = GetTime()
    
    SafeLog("INFO", "CombatLockdown: Cleared %d queued operations", count)
end

--[[
    Get current queue statistics
    @return table stats Current statistics
--]]
function CombatLockdown:GetStats()
    return {
        operationsQueued = stats.operationsQueued,
        operationsExecuted = stats.operationsExecuted,
        operationsFailed = stats.operationsFailed,
        queueProcessingTime = stats.queueProcessingTime,
        lastQueueClear = stats.lastQueueClear,
        currentQueueSize = #operationQueue,
        inCombat = self:IsInCombat()
    }
end

--[[
===============================================================================
SAFE FRAME OPERATIONS
===============================================================================
--]]

--[[
    Safely position a frame
    @param frame table The frame to position
    @param point string Anchor point
    @param relativeTo table|nil Relative frame
    @param relativePoint string|nil Relative anchor point
    @param x number X offset
    @param y number Y offset
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetPoint(frame, point, relativeTo, relativePoint, x, y)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetPoint - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_POSITION, function()
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end)
end

--[[
    Safely resize a frame
    @param frame table The frame to resize
    @param width number New width
    @param height number New height
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetSize(frame, width, height)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetSize - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_SIZE, function()
        frame:SetSize(width, height)
    end)
end

--[[
    Safely scale a frame
    @param frame table The frame to scale
    @param scale number New scale value
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetScale(frame, scale)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetScale - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_SCALE, function()
        frame:SetScale(scale)
    end)
end

--[[
    Safely show or hide a frame
    @param frame table The frame to show/hide
    @param show boolean Whether to show (true) or hide (false)
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetShown(frame, show)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetShown - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_SHOW_HIDE, function()
        if show then
            frame:Show()
        else
            frame:Hide()
        end
    end)
end

--[[
    Safely change frame parent
    @param frame table The frame to reparent
    @param parent table New parent frame
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetParent(frame, parent)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetParent - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_PARENT, function()
        frame:SetParent(parent)
    end)
end

--[[
    Safely change frame strata
    @param frame table The frame to modify
    @param strata string New frame strata
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetFrameStrata(frame, strata)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetFrameStrata - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_STRATA, function()
        frame:SetFrameStrata(strata)
    end)
end

--[[
    Safely change frame level
    @param frame table The frame to modify
    @param level number New frame level
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetFrameLevel(frame, level)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetFrameLevel - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_LEVEL, function()
        frame:SetFrameLevel(level)
    end)
end

--[[
    Safely set frame attribute (for secure frames)
    @param frame table The secure frame to modify
    @param name string Attribute name
    @param value any Attribute value
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeSetAttribute(frame, name, value)
    if not frame then
        SafeLog("ERROR", "CombatLockdown:SafeSetAttribute - No frame provided")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_ATTRIBUTE, function()
        if frame.SetAttribute then
            frame:SetAttribute(name, value)
        else
            SafeLog("WARNING", "CombatLockdown:SafeSetAttribute - Frame does not support attributes")
        end
    end)
end

--[[
===============================================================================
SPECIALIZED OPERATIONS
===============================================================================
--]]

--[[
    Safely update action bar layout
    @param updateFunc function Function that performs the action bar update
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeUpdateActionBars(updateFunc)
    if not updateFunc or type(updateFunc) ~= "function" then
        SafeLog("ERROR", "CombatLockdown:SafeUpdateActionBars - Invalid update function")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.ACTION_BAR_UPDATE, updateFunc)
end

--[[
    Safely update unit frame layout
    @param updateFunc function Function that performs the unit frame update
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeUpdateUnitFrames(updateFunc)
    if not updateFunc or type(updateFunc) ~= "function" then
        SafeLog("ERROR", "CombatLockdown:SafeUpdateUnitFrames - Invalid update function")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.UNIT_FRAME_UPDATE, updateFunc)
end

--[[
    Safely create a new frame with deferred execution if needed
    @param frameType string Type of frame to create
    @param name string|nil Frame name
    @param parent table Parent frame
    @param template string|nil Frame template
    @param callback function Function to call with the created frame
    @return boolean success Whether operation was executed immediately
--]]
function CombatLockdown:SafeCreateFrame(frameType, name, parent, template, callback)
    if not frameType or not callback then
        SafeLog("ERROR", "CombatLockdown:SafeCreateFrame - Missing required parameters")
        return false
    end
    
    return self:ExecuteOrQueue(OPERATION_TYPES.FRAME_CREATION, function()
        local frame = CreateFrame(frameType, name, parent, template)
        callback(frame)
    end)
end

--[[
===============================================================================
EVENT HANDLING AND QUEUE PROCESSING
===============================================================================
--]]

--[[
    Ensure event frame is created and registered
--]]
function CombatLockdown:EnsureEventFrame()
    if eventFrame then
        return
    end
    
    eventFrame = CreateFrame("Frame", "DamiaUI_CombatLockdownFrame")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            CombatLockdown:ProcessQueue()
        end
    end)
    
    SafeLog("DEBUG", "CombatLockdown: Event frame created and registered")
end

--[[
    Process all queued operations after combat ends
--]]
function CombatLockdown:ProcessQueue()
    if queueProcessing or #operationQueue == 0 then
        return
    end
    
    queueProcessing = true
    local startTime = GetTime()
    local successCount = 0
    local failureCount = 0
    
    SafeLog("INFO", "CombatLockdown: Processing %d queued operations", #operationQueue)
    
    -- Process operations in order
    for i, operation in ipairs(operationQueue) do
        local success, result = pcall(operation.func, unpack(operation.args))
        
        if success then
            successCount = successCount + 1
            SafeLog("DEBUG", "CombatLockdown: Executed queued operation %d (%s)", operation.id, operation.type)
        else
            failureCount = failureCount + 1
            SafeLog("ERROR", "CombatLockdown: Failed queued operation %d (%s): %s", operation.id, operation.type, tostring(result))
        end
    end
    
    -- Update statistics
    stats.operationsExecuted = stats.operationsExecuted + successCount
    stats.operationsFailed = stats.operationsFailed + failureCount
    stats.queueProcessingTime = GetTime() - startTime
    
    -- Clear the queue
    operationQueue = {}
    queueProcessing = false
    
    SafeLog("INFO", "CombatLockdown: Queue processing complete - %d succeeded, %d failed (%.3fs)", 
                          successCount, failureCount, stats.queueProcessingTime)
    
    -- Fire event for other modules
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_COMBAT_QUEUE_PROCESSED", successCount, failureCount)
    end
end

--[[
===============================================================================
UTILITY METHODS
===============================================================================
--]]

--[[
    Check if a frame is considered "protected" and subject to combat lockdown
    @param frame table The frame to check
    @return boolean isProtected Whether the frame is protected
--]]
function CombatLockdown:IsFrameProtected(frame)
    if not frame then
        return false
    end
    
    -- Check if frame is a secure frame
    if frame.IsProtected and frame:IsProtected() then
        return true
    end
    
    -- Check if frame has secure attributes
    if frame.GetAttribute then
        return true
    end
    
    -- Check if frame is an action button
    if frame.GetAction or frame.SetAction then
        return true
    end
    
    return false
end

--[[
    Create a wrapper function that automatically handles combat lockdown
    @param operationType string The type of operation
    @param func function The function to wrap
    @return function wrappedFunction The wrapped function
--]]
function CombatLockdown:WrapFunction(operationType, func)
    if not func or type(func) ~= "function" then
        SafeLog("ERROR", "CombatLockdown:WrapFunction - Invalid function provided")
        return function() end
    end
    
    return function(...)
        return self:ExecuteOrQueue(operationType, func, ...)
    end
end

--[[
    Register a callback to be executed when the queue is processed
    @param callback function Function to call after queue processing
    @param identifier string Unique identifier for the callback
--]]
function CombatLockdown:RegisterQueueCallback(callback, identifier)
    if not callback or type(callback) ~= "function" then
        SafeLog("ERROR", "CombatLockdown:RegisterQueueCallback - Invalid callback function")
        return
    end
    
    if DamiaUI.Events then
        DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_QUEUE_PROCESSED", callback, 1, identifier)
        SafeLog("DEBUG", "CombatLockdown: Registered queue callback: %s", identifier)
    end
end

--[[
    Unregister a queue callback
    @param identifier string Unique identifier for the callback
--]]
function CombatLockdown:UnregisterQueueCallback(identifier)
    if DamiaUI.Events then
        DamiaUI.Events:UnregisterCustomEvent("DAMIA_COMBAT_QUEUE_PROCESSED", identifier)
        SafeLog("DEBUG", "CombatLockdown: Unregistered queue callback: %s", identifier)
    end
end

--[[
===============================================================================
MODULE INITIALIZATION
===============================================================================
--]]

--[[
    Initialize the CombatLockdown module
--]]
function CombatLockdown:OnEnable()
    SafeLog("INFO", "CombatLockdown module enabled")
    
    -- Set up event frame
    self:EnsureEventFrame()
    
    -- Register for configuration changes
    if DamiaUI.Config then
        DamiaUI.Config:RegisterCallback("combat.lockdown", function(key, oldValue, newValue)
            self:OnConfigChanged(key, oldValue, newValue)
        end, "CombatLockdown_ConfigWatcher")
    end
end

--[[
    Cleanup when module is disabled
--]]
function CombatLockdown:OnDisable()
    SafeLog("INFO", "CombatLockdown module disabled")
    
    -- Clear any pending operations
    self:ClearQueue()
    
    -- Cleanup event frame
    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnEvent", nil)
        eventFrame = nil
    end
    
    -- Cleanup configuration callbacks
    if DamiaUI.Config then
        DamiaUI.Config:UnregisterCallback("combat.lockdown", "CombatLockdown_ConfigWatcher")
    end
end

--[[
    Handle configuration changes
--]]
function CombatLockdown:OnConfigChanged(key, oldValue, newValue)
    SafeLog("DEBUG", "CombatLockdown config changed: %s", key)
    -- Configuration changes can be handled here if needed
end

-- Export operation types for external use
CombatLockdown.OPERATION_TYPES = OPERATION_TYPES

-- Register module with engine
if DamiaUI and DamiaUI.RegisterModule then
    DamiaUI:RegisterModule("CombatLockdown", CombatLockdown)
elseif DamiaUI then
    -- Fallback registration
    DamiaUI.CombatLockdown = CombatLockdown
    if DamiaUI.Engine then
        SafeLog("DEBUG", "CombatLockdown module registered directly")
    end
end