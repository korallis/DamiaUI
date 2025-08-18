--[[
Name: CallbackHandler-1.0
Revision: $Rev: 45 $
Developed by: The World of Warcraft AddOn community

Description:
A Lua library for managing callback functions within addons.
CallbackHandler provides a simple framework for registering, firing, and managing callbacks
used by many Ace3 libraries and WoW addons for event handling.

This implementation is compatible with WoW 11.2 (110200) and maintains backwards compatibility.

License: MIT License
]]

local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)

if not CallbackHandler then return end

local assert, error, loadstring = assert, error, loadstring
local setmetatable, rawset, rawget = setmetatable, rawset, rawget
local next, select, pairs, type, tostring = next, select, pairs, type, tostring
local wipe = table.wipe or wipe

-- Recycled objects
local events = {}
local registry = {}

-- Function to clear a table (for reusing)
local function safecall(func, ...)
    if func then
        return xpcall(func, geterrorhandler(), ...)
    end
end

-- Create a new callback registry
local function createRegistry(target, meta)
    meta = meta or {}
    meta.__index = meta
    
    registry.handlers = {}  -- [event] = {[handler] = priority or true}
    registry.insertQueue = {}  -- temp queue for insertions during iteration
    registry.isIterating = false
    
    -- Register a callback
    function registry:RegisterCallback(event, method, ...)
        if type(event) ~= "string" then
            error("Usage: object:RegisterCallback(event, method [, ...]): 'event' must be a string.", 2)
        end
        
        method = method or event
        
        local callback, context, priority
        if type(method) == "string" then
            local handler = self
            if select('#', ...) > 0 then
                handler = ...
                local arg1 = select(2, ...)
                if type(arg1) == "number" then
                    priority = arg1
                else
                    context = arg1
                    priority = select(3, ...)
                end
            end
            
            if type(handler) == "table" and handler[method] then
                callback = handler[method]
                context = context or handler
            else
                error(("Usage: object:RegisterCallback(event, method [, context] [, priority]): 'method' - method '%s' not found on provided handler."):format(tostring(method)), 2)
            end
        elseif type(method) == "function" then
            callback = method
            context = ...
            priority = select(2, ...)
        else
            error("Usage: object:RegisterCallback(event, method [, ...]): 'method' must be a string or function.", 2)
        end
        
        if not callback then
            error("Usage: object:RegisterCallback(event, method [, ...]): unable to derive callback from arguments.", 2)
        end
        
        priority = priority or 0
        
        -- Create handler entry
        local handlers = self.handlers[event]
        if not handlers then
            handlers = {}
            self.handlers[event] = handlers
        end
        
        if not handlers[callback] then
            -- New registration
            handlers[callback] = {
                context = context,
                priority = priority,
                callback = callback
            }
        else
            -- Update existing
            handlers[callback].context = context
            handlers[callback].priority = priority
        end
    end
    
    -- Unregister a callback
    function registry:UnregisterCallback(event, method, ...)
        if type(event) ~= "string" then
            error("Usage: object:UnregisterCallback(event, method): 'event' must be a string.", 2)
        end
        
        method = method or event
        
        local callback, context
        if type(method) == "string" then
            local handler = self
            if select('#', ...) > 0 then
                handler = ...
                context = select(2, ...)
            end
            
            if type(handler) == "table" and handler[method] then
                callback = handler[method]
                context = context or handler
            end
        elseif type(method) == "function" then
            callback = method
            context = ...
        end
        
        if not callback then
            error("Usage: object:UnregisterCallback(event, method [, ...]): unable to derive callback from arguments.", 2)
        end
        
        local handlers = self.handlers[event]
        if handlers and handlers[callback] then
            handlers[callback] = nil
            -- Clean up empty handler table
            if not next(handlers) then
                self.handlers[event] = nil
            end
        end
    end
    
    -- Unregister all callbacks for an object
    function registry:UnregisterAllCallbacks(event)
        if event then
            if type(event) ~= "string" then
                error("Usage: object:UnregisterAllCallbacks([event]): 'event' must be a string or nil.", 2)
            end
            self.handlers[event] = nil
        else
            wipe(self.handlers)
        end
    end
    
    -- Fire a callback event
    function registry:Fire(event, ...)
        if type(event) ~= "string" then
            error("Usage: object:Fire(event, ...): 'event' must be a string.", 2)
        end
        
        local handlers = self.handlers[event]
        if not handlers then return end
        
        -- Create sorted list of handlers by priority
        local sortedHandlers = {}
        for callback, data in pairs(handlers) do
            sortedHandlers[#sortedHandlers + 1] = data
        end
        
        if #sortedHandlers > 1 then
            table.sort(sortedHandlers, function(a, b)
                return a.priority > b.priority
            end)
        end
        
        -- Mark as iterating to handle concurrent modifications
        self.isIterating = true
        
        -- Call handlers in priority order
        for i = 1, #sortedHandlers do
            local data = sortedHandlers[i]
            if data.context then
                safecall(data.callback, data.context, event, ...)
            else
                safecall(data.callback, event, ...)
            end
        end
        
        self.isIterating = false
        
        -- Process any pending insertions
        if next(self.insertQueue) then
            for event, handlers in pairs(self.insertQueue) do
                local eventHandlers = self.handlers[event] or {}
                for callback, data in pairs(handlers) do
                    eventHandlers[callback] = data
                end
                self.handlers[event] = eventHandlers
            end
            wipe(self.insertQueue)
        end
    end
    
    return setmetatable(registry, meta)
end

-- Public API for creating new callback registries
function CallbackHandler:New(target, registerName, unregisterName, unregisterAllName)
    registerName = registerName or "RegisterCallback"
    unregisterName = unregisterName or "UnregisterCallback"
    unregisterAllName = unregisterAllName or "UnregisterAllCallbacks"
    
    if target then
        if target[registerName] or target[unregisterName] or target[unregisterAllName] then
            error("Usage: CallbackHandler:New(target): target already has a method named '" .. (target[registerName] and registerName or target[unregisterName] and unregisterName or unregisterAllName) .. "'.", 2)
        end
    else
        target = {}
    end
    
    local registry = createRegistry(target)
    
    target[registerName] = function(self, ...)
        return registry:RegisterCallback(...)
    end
    target[unregisterName] = function(self, ...)
        return registry:UnregisterCallback(...)
    end
    target[unregisterAllName] = function(self, ...)
        return registry:UnregisterAllCallbacks(...)
    end
    target.Fire = function(self, ...)
        return registry:Fire(...)
    end
    
    -- Store reference to registry for debugging
    target.callbacks = registry
    
    return target
end

-- Legacy method (same as New)
CallbackHandler.New = CallbackHandler.New

-- Set up the CallbackHandler as its own callback registry for libraries that need it
CallbackHandler:New(CallbackHandler, "RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks")