--[[
Name: LibDataBroker-1.1
Revision: $Rev: 109 $
Developed by: The World of Warcraft AddOn community

Description:
LibDataBroker provides a framework for addon communication and data sharing.
It's commonly used for minimap buttons, information display systems, and 
inter-addon communication.

This implementation is compatible with WoW 11.2 (110200) and maintains backwards compatibility.

License: MIT License
]]

local MAJOR, MINOR = "LibDataBroker-1.1", 109
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

-- Import CallbackHandler for event management
local CallbackHandler = LibStub("CallbackHandler-1.0")

-- Initialize or preserve existing data
lib.callbacks = lib.callbacks or CallbackHandler:New(lib)
lib.objects = lib.objects or {}
lib.namespaces = lib.namespaces or {}

-- Supported data object types
local supportedTypes = {
    data_source = true,
    launcher = true
}

-- Attribute validation patterns
local attributeValidators = {
    type = function(obj, value)
        return supportedTypes[value]
    end,
    text = function(obj, value)
        return type(value) == "string" or type(value) == "function"
    end,
    label = function(obj, value)
        return type(value) == "string"
    end,
    suffix = function(obj, value)
        return type(value) == "string"
    end,
    value = function(obj, value)
        return type(value) ~= "table"
    end,
    icon = function(obj, value)
        return type(value) == "string" or type(value) == "function"
    end,
    iconCoords = function(obj, value)
        return type(value) == "table" and #value == 4
    end,
    iconR = function(obj, value)
        return type(value) == "number" and value >= 0 and value <= 1
    end,
    iconG = function(obj, value)
        return type(value) == "number" and value >= 0 and value <= 1
    end,
    iconB = function(obj, value)
        return type(value) == "number" and value >= 0 and value <= 1
    end,
    iconA = function(obj, value)
        return type(value) == "number" and value >= 0 and value <= 1
    end,
    tocname = function(obj, value)
        return type(value) == "string"
    end,
    OnClick = function(obj, value)
        return type(value) == "function"
    end,
    OnDoubleClick = function(obj, value)
        return type(value) == "function"
    end,
    OnTooltipShow = function(obj, value)
        return type(value) == "function"
    end,
    OnEnter = function(obj, value)
        return type(value) == "function"
    end,
    OnLeave = function(obj, value)
        return type(value) == "function"
    end
}

-- Create metatable for data objects
local dataObjectMT = {
    __newindex = function(self, key, value)
        local validator = attributeValidators[key]
        if validator and not validator(self, value) then
            error(("Invalid value for attribute '%s'"):format(key), 2)
        end
        
        -- Store the old value for the callback
        local oldValue = rawget(self, key)
        rawset(self, key, value)
        
        -- Fire callback for attribute changes
        if oldValue ~= value then
            lib.callbacks:Fire("LibDataBroker_AttributeChanged", rawget(self, "__name"), key, value, oldValue, self)
            lib.callbacks:Fire("LibDataBroker_AttributeChanged_" .. rawget(self, "__name"), key, value, oldValue, self)
            lib.callbacks:Fire("LibDataBroker_AttributeChanged_" .. rawget(self, "__name") .. "_" .. key, value, oldValue, self)
        end
    end,
    
    __index = function(self, key)
        -- Allow access to private attributes for internal use
        if key == "__name" or key == "__type" then
            return rawget(self, key)
        end
        
        local value = rawget(self, key)
        if type(value) == "function" then
            return value
        end
        
        return value
    end
}

-- Core library functions
function lib:NewDataObject(name, dataobject)
    if type(name) ~= "string" then
        error("Usage: NewDataObject(name, dataobject): 'name' must be a string.", 2)
    end
    
    if lib.objects[name] then
        error("Usage: NewDataObject(name, dataobject): 'name' '" .. name .. "' is already in use.", 2)
    end
    
    dataobject = dataobject or {}
    
    if type(dataobject) ~= "table" then
        error("Usage: NewDataObject(name, dataobject): 'dataobject' must be a table or nil.", 2)
    end
    
    -- Validate required type attribute
    local objType = dataobject.type
    if not objType then
        error("Usage: NewDataObject(name, dataobject): 'dataobject.type' is required.", 2)
    end
    
    if not supportedTypes[objType] then
        error("Usage: NewDataObject(name, dataobject): 'dataobject.type' '" .. tostring(objType) .. "' is not supported.", 2)
    end
    
    -- Create a copy of the data object
    local obj = {}
    for k, v in pairs(dataobject) do
        obj[k] = v
    end
    
    -- Store internal attributes
    rawset(obj, "__name", name)
    rawset(obj, "__type", objType)
    
    -- Apply metatable
    setmetatable(obj, dataObjectMT)
    
    -- Register the object
    lib.objects[name] = obj
    
    -- Fire callbacks
    lib.callbacks:Fire("LibDataBroker_DataObjectCreated", name, obj)
    
    return obj
end

function lib:GetDataObjectByName(name)
    if type(name) ~= "string" then
        error("Usage: GetDataObjectByName(name): 'name' must be a string.", 2)
    end
    
    return lib.objects[name]
end

function lib:GetObjectNames()
    local names = {}
    for name in pairs(lib.objects) do
        names[#names + 1] = name
    end
    return names
end

function lib:DataObjectIterator()
    return pairs(lib.objects)
end

function lib:GetNameAndObjectByIndex(index)
    local i = 0
    for name, obj in pairs(lib.objects) do
        i = i + 1
        if i == index then
            return name, obj
        end
    end
    return nil, nil
end

function lib:IsDataObject(obj, name)
    return (type(obj) == "table" and rawget(obj, "__name") == name and lib.objects[name] == obj) or false
end

-- Namespace support for addon isolation
function lib:NewNamespace(namespace, parent)
    if type(namespace) ~= "string" then
        error("Usage: NewNamespace(namespace, parent): 'namespace' must be a string.", 2)
    end
    
    if lib.namespaces[namespace] then
        error("Usage: NewNamespace(namespace, parent): namespace '" .. namespace .. "' already exists.", 2)
    end
    
    local ns = {}
    ns.namespace = namespace
    ns.parent = parent or lib
    ns.objects = {}
    
    -- Create namespace-specific methods
    function ns:NewDataObject(name, dataobject)
        -- Prefix name with namespace to avoid conflicts
        local fullName = namespace .. "_" .. name
        local obj = lib:NewDataObject(fullName, dataobject)
        self.objects[name] = obj
        return obj
    end
    
    function ns:GetDataObjectByName(name)
        local obj = self.objects[name]
        if obj then
            return obj
        end
        -- Fallback to full name lookup
        return lib:GetDataObjectByName(namespace .. "_" .. name)
    end
    
    function ns:GetObjectNames()
        local names = {}
        for name in pairs(self.objects) do
            names[#names + 1] = name
        end
        return names
    end
    
    lib.namespaces[namespace] = ns
    return ns
end

function lib:GetNamespace(namespace)
    return lib.namespaces[namespace]
end

-- Utility functions for display management
function lib:GetIconTexture(obj)
    if not obj then return nil end
    
    local icon = obj.icon
    if type(icon) == "function" then
        return icon(obj)
    end
    return icon
end

function lib:GetText(obj)
    if not obj then return nil end
    
    local text = obj.text
    if type(text) == "function" then
        return text(obj)
    end
    return text
end

function lib:GetIconCoords(obj)
    if not obj or not obj.iconCoords then return 0, 1, 0, 1 end
    
    local coords = obj.iconCoords
    if type(coords) == "table" and #coords >= 4 then
        return coords[1], coords[2], coords[3], coords[4]
    end
    return 0, 1, 0, 1
end

function lib:GetIconColor(obj)
    if not obj then return 1, 1, 1, 1 end
    
    local r = obj.iconR or 1
    local g = obj.iconG or 1
    local b = obj.iconB or 1
    local a = obj.iconA or 1
    
    return r, g, b, a
end

-- Type checking utilities
function lib:IsDataSource(obj)
    return obj and rawget(obj, "__type") == "data_source"
end

function lib:IsLauncher(obj)
    return obj and rawget(obj, "__type") == "launcher"
end

-- Event system integration
function lib:RegisterCallback(...)
    return self.callbacks:RegisterCallback(...)
end

function lib:UnregisterCallback(...)
    return self.callbacks:UnregisterCallback(...)
end

function lib:UnregisterAllCallbacks(...)
    return self.callbacks:UnregisterAllCallbacks(...)
end

-- Version compatibility functions
lib.GetLibraryVersion = function()
    return MAJOR, MINOR
end

lib.GetDataObjects = lib.DataObjectIterator  -- Legacy support

-- Backwards compatibility for older versions
if not lib.pairs then
    lib.pairs = lib.DataObjectIterator
end

-- Fire initial callback for existing addons
if oldminor then
    lib.callbacks:Fire("LibDataBroker_LibraryUpgraded", MAJOR, oldminor, MINOR)
end