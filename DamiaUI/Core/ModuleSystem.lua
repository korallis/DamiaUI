-- DamiaUI Module System with Dependency Management
-- Provides proper module initialization order and dependency resolution

local addonName, ns = ...

-- CRITICAL: Ensure ns.modules exists before anything else
if not ns.modules then
    ns.modules = {}
end

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

-- Enhanced module registration with dependency tracking and error handling
function ns:RegisterModule(name, module, dependencies)
    if not name or not module then
        if ns.LogDebug then
            ns:LogDebug("RegisterModule: Invalid module registration - name: " .. tostring(name) .. ", module: " .. tostring(module))
        end
        return false
    end
    
    -- Enhanced module structure validation
    if type(module) ~= "table" then
        if ns.LogDebug then
            ns:LogDebug("RegisterModule: " .. name .. " is not a table")
        end
        return false
    end
    
    if not module.Initialize then
        if ns.LogDebug then
            ns:LogDebug("RegisterModule: " .. name .. " missing Initialize function")
        end
        return false
    end
    
    -- Ensure registry exists
    if not ns.moduleRegistry then
        ns.moduleRegistry = {}
    end
    
    -- Store module with metadata
    ns.moduleRegistry[name] = {
        module = module,
        dependencies = dependencies or MODULE_DEPENDENCIES[name] or {},
        status = "registered",
        initTime = 0,
        registered = GetTime(),
    }
    
    -- Ensure modules table exists for backward compatibility
    if not ns.modules then
        ns.modules = {}
    end
    
    -- Add to modules table for backward compatibility
    ns.modules[name] = module
    
    if ns.LogDebug then
        ns:LogDebug("Module registered: " .. name .. " with " .. #(dependencies or MODULE_DEPENDENCIES[name] or {}) .. " dependencies")
    end
    
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

-- Initialize all modules in dependency order with enhanced error handling
function ns:InitializeModules()
    if ns.LogDebug then
        ns:LogDebug("Starting module initialization")
        ns:LogDebug("Available modules: " .. table.concat(ns:GetModuleNames(), ", "))
    end
    
    -- Ensure we have modules to initialize
    if not ns.moduleRegistry or next(ns.moduleRegistry) == nil then
        if ns.LogDebug then
            ns:LogDebug("ERROR: No modules registered in moduleRegistry")
        end
        return 0, 0
    end
    
    -- Build dependency-resolved load order
    local loadOrder = BuildLoadOrder()
    if ns.LogDebug then
        ns:LogDebug("Module load order: " .. table.concat(loadOrder, ", "))
    end
    
    -- Initialize modules in order
    local initialized = 0
    local failed = 0
    
    for _, name in ipairs(loadOrder) do
        if ns.moduleRegistry[name] then
            if ns.LogDebug then
                ns:LogDebug("Attempting to initialize module: " .. name)
            end
            if InitializeModule(name) then
                initialized = initialized + 1
                if ns.LogDebug then
                    ns:LogDebug("Module " .. name .. " initialized successfully")
                end
            else
                failed = failed + 1
                if ns.LogDebug then
                    ns:LogDebug("Module " .. name .. " failed to initialize")
                end
            end
        else
            if ns.LogDebug then
                ns:LogDebug("WARNING: Module " .. name .. " not found in registry")
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
                if ns.LogDebug then
                    ns:LogDebug("Retrying pending module: " .. name .. " (attempt " .. (retryCount + 1) .. ")")
                end
                if InitializeModule(name) then
                    initialized = initialized + 1
                    failed = failed - 1
                    if ns.LogDebug then
                        ns:LogDebug("Module " .. name .. " initialized on retry")
                    end
                end
            end
        end
        
        if not pendingFound then break end
        retryCount = retryCount + 1
    end
    
    if ns.LogDebug then
        ns:LogDebug("Module initialization complete: " .. initialized .. " loaded, " .. failed .. " failed")
    end
    
    -- Report any remaining failed modules
    if failed > 0 then
        if ns.LogDebug then
            ns:LogDebug("Failed modules:")
            for name, reg in pairs(ns.moduleRegistry) do
                if reg.status == "error" or reg.status == "pending" then
                    ns:LogDebug("  " .. name .. ": " .. reg.status)
                end
            end
        end
    end
    
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