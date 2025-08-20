-- DamiaUI Module System with Dependency Management
-- Provides proper module initialization order and dependency resolution

local addonName, ns = ...

-- Module registry with metadata
ns.moduleRegistry = {}
ns.moduleLoadOrder = {}
ns.moduleStatus = {}

-- Define module dependencies
local MODULE_DEPENDENCIES = {
    -- Core modules have no dependencies
    ["ActionBars"] = {},
    ["UnitFrames"] = {},
    ["Minimap"] = {},
    ["Chat"] = {},
    ["Nameplates"] = {},
    
    -- DataTexts depend on core modules being loaded
    ["DataTexts"] = {"ActionBars", "UnitFrames"},
    
    -- Misc modules depend on core UI
    ["Misc"] = {"ActionBars", "UnitFrames"},
    
    -- Skins depend on the modules they skin
    ["Skins"] = {"ActionBars", "UnitFrames", "Chat"},
}

-- Enhanced module registration with dependency tracking
function ns:RegisterModule(name, module, dependencies)
    if not name or not module then
        self:Debug("RegisterModule: Invalid module registration", name)
        return false
    end
    
    -- Validate module structure
    if not module.Initialize then
        self:Debug("RegisterModule:", name, "missing Initialize function")
        return false
    end
    
    -- Store module with metadata
    ns.moduleRegistry[name] = {
        module = module,
        dependencies = dependencies or MODULE_DEPENDENCIES[name] or {},
        status = "registered",
        initTime = 0,
    }
    
    -- Add to modules table for backward compatibility
    ns.modules[name] = module
    
    return true
end

-- Check if all dependencies are loaded
local function CheckDependencies(moduleName)
    local reg = ns.moduleRegistry[moduleName]
    if not reg then return false end
    
    for _, dep in ipairs(reg.dependencies) do
        local depReg = ns.moduleRegistry[dep]
        if not depReg or depReg.status ~= "initialized" then
            return false, dep
        end
    end
    
    return true
end

-- Topological sort for dependency resolution
local function BuildLoadOrder()
    local visited = {}
    local order = {}
    
    local function visit(name)
        if visited[name] then return end
        visited[name] = true
        
        local reg = ns.moduleRegistry[name]
        if reg then
            for _, dep in ipairs(reg.dependencies) do
                visit(dep)
            end
        end
        
        table.insert(order, name)
    end
    
    for name, _ in pairs(ns.moduleRegistry) do
        visit(name)
    end
    
    return order
end

-- Initialize a single module with error handling
local function InitializeModule(name)
    local reg = ns.moduleRegistry[name]
    if not reg then
        ns:Debug("InitializeModule: Module not found", name)
        return false
    end
    
    -- Check if already initialized
    if reg.status == "initialized" then
        return true
    end
    
    -- Check dependencies
    local depsOk, missingDep = CheckDependencies(name)
    if not depsOk then
        ns:Debug("InitializeModule:", name, "waiting for dependency", missingDep)
        reg.status = "pending"
        return false
    end
    
    -- Initialize with error protection
    local startTime = debugprofilestop()
    local success, result = xpcall(function()
        return reg.module:Initialize()
    end, function(err)
        ns:Debug("Module", name, "initialization error:", err)
        ns:Debug(debugstack())
    end)
    
    local initTime = debugprofilestop() - startTime
    reg.initTime = initTime
    
    if success then
        reg.status = "initialized"
        ns:Debug("Module", name, "initialized in", string.format("%.2fms", initTime))
        
        -- Enable module if it has an Enable method
        if reg.module.Enable then
            xpcall(function()
                reg.module:Enable()
            end, function(err)
                ns:Debug("Module", name, "enable error:", err)
            end)
        end
        
        return true
    else
        reg.status = "error"
        ns:Debug("Module", name, "failed to initialize")
        return false
    end
end

-- Initialize all modules in dependency order
function ns:InitializeModules()
    ns:Debug("Starting module initialization")
    
    -- Build dependency-resolved load order
    local loadOrder = BuildLoadOrder()
    
    -- Initialize modules in order
    local initialized = 0
    local failed = 0
    
    for _, name in ipairs(loadOrder) do
        if ns.moduleRegistry[name] then
            if InitializeModule(name) then
                initialized = initialized + 1
            else
                failed = failed + 1
            end
        end
    end
    
    -- Retry pending modules (in case of circular dependencies)
    local retryCount = 0
    local maxRetries = 3
    
    while retryCount < maxRetries do
        local pendingFound = false
        
        for name, reg in pairs(ns.moduleRegistry) do
            if reg.status == "pending" then
                pendingFound = true
                if InitializeModule(name) then
                    initialized = initialized + 1
                    failed = failed - 1
                end
            end
        end
        
        if not pendingFound then break end
        retryCount = retryCount + 1
    end
    
    ns:Debug("Module initialization complete:", initialized, "loaded,", failed, "failed")
    
    -- Report status
    return initialized, failed
end

-- Disable a module with cleanup
function ns:DisableModule(name)
    local reg = ns.moduleRegistry[name]
    if not reg then return false end
    
    local module = reg.module
    
    -- Call Disable method if it exists
    if module.Disable then
        local success = xpcall(function()
            module:Disable()
        end, function(err)
            ns:Debug("Module", name, "disable error:", err)
        end)
    end
    
    -- Unregister all events if module has an event frame
    if module.frame then
        module.frame:UnregisterAllEvents()
    end
    
    -- Clear any registered hooks
    if module.hooks then
        for k, v in pairs(module.hooks) do
            module.hooks[k] = nil
        end
    end
    
    -- Clean up timers if using AceTimer
    if module.CancelAllTimers then
        module:CancelAllTimers()
    end
    
    -- Mark as disabled
    reg.status = "disabled"
    
    return true
end

-- Enable a previously disabled module
function ns:EnableModule(name)
    local reg = ns.moduleRegistry[name]
    if not reg then return false end
    
    if reg.status == "disabled" then
        return InitializeModule(name)
    end
    
    return false
end

-- Get module status information
function ns:GetModuleStatus()
    local status = {}
    
    for name, reg in pairs(ns.moduleRegistry) do
        status[name] = {
            status = reg.status,
            initTime = reg.initTime,
            dependencies = reg.dependencies,
            hasMethods = {
                Initialize = reg.module.Initialize ~= nil,
                Enable = reg.module.Enable ~= nil,
                Disable = reg.module.Disable ~= nil,
            }
        }
    end
    
    return status
end

-- Debug command to show module status
function ns:ShowModuleStatus()
    self:Print("=== Module Status ===")
    
    local status = self:GetModuleStatus()
    for name, info in pairs(status) do
        local statusColor = info.status == "initialized" and "|cFF00FF00" or 
                          info.status == "error" and "|cFFFF0000" or 
                          "|cFFFFFF00"
        
        self:Print(string.format("%s%s|r: %s (%.2fms)", 
            statusColor, name, info.status, info.initTime))
            
        if #info.dependencies > 0 then
            self:Print("  Dependencies:", table.concat(info.dependencies, ", "))
        end
    end
end