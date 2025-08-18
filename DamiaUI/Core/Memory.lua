--[[
===============================================================================
Damia UI - Memory Management System
===============================================================================
Advanced memory management with usage tracking, cleanup routines, and 
optimization strategies to maintain <25MB memory usage in all scenarios.

Features:
- Real-time memory usage monitoring
- Automatic cleanup routines and garbage collection
- Memory leak detection and prevention
- Smart caching with automatic eviction
- Memory profiling and usage analysis
- Frame and object pooling management

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
local type, tostring, tonumber = type, tostring, tonumber
local CreateFrame = CreateFrame
local GetTime = GetTime
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local collectgarbage = collectgarbage
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown

-- Create Memory module
local Memory = {}
DamiaUI.Memory = Memory

-- Memory management constants
local MEMORY_CHECK_INTERVAL = 1.0 -- Check memory every second
local MEMORY_HISTORY_SIZE = 300 -- Keep 5 minutes of memory data
local CACHE_CLEANUP_INTERVAL = 60.0 -- Clean cache every minute
local GC_OPTIMIZATION_INTERVAL = 30.0 -- GC optimization every 30 seconds
local LEAK_DETECTION_INTERVAL = 120.0 -- Check for leaks every 2 minutes

-- Memory thresholds (MB)
local MEMORY_TARGET = 15 -- Target usage
local MEMORY_WARNING = 20 -- Warning threshold
local MEMORY_CRITICAL = 25 -- Critical threshold
local MEMORY_EMERGENCY = 30 -- Emergency cleanup

-- Memory tracking data
local memoryData = {
    current = 0,
    peak = 0,
    baseline = 0,
    history = {},
    allocations = 0,
    deallocations = 0,
    gcCollections = 0,
    lastCleanup = 0,
    lastGCOptimization = 0,
    lastLeakCheck = 0,
    leakDetected = false,
}

-- Cache management
local cacheData = {
    maxSize = 1024 * 1024, -- 1MB cache limit
    currentSize = 0,
    entries = {},
    accessTimes = {},
    hitCount = 0,
    missCount = 0,
}

-- Memory pools for object reuse
local memoryPools = {
    tables = {},
    strings = {},
    functions = {},
    textures = {},
    frames = {},
}

-- Memory profiling data
local profilingData = {
    enabled = false,
    snapshots = {},
    allocations = {},
    categories = {
        frames = 0,
        textures = 0,
        strings = 0,
        tables = 0,
        functions = 0,
        other = 0,
    },
}

-- Cleanup registry for automatic resource management
local cleanupRegistry = {}

-- Memory monitoring frame
local memoryFrame = CreateFrame("Frame", "DamiaUIMemoryFrame")

--[[
===============================================================================
CORE MEMORY MONITORING
===============================================================================
--]]

-- Initialize memory management system
function Memory:Initialize()
    DamiaUI.Engine:LogInfo("Initializing Memory Management System")
    
    -- Establish memory baseline
    self:EstablishBaseline()
    
    -- Start monitoring loops
    self:StartMemoryMonitoring()
    self:StartCacheCleanup()
    self:StartGCOptimization()
    self:StartLeakDetection()
    
    -- Register for performance events
    DamiaUI.Events:RegisterCustomEvent("DAMIA_PERFORMANCE_DEGRADED", 
        function() self:OnPerformanceDegraded() end, 2, "Memory_PerformanceDegraded")
    
    DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", 
        function(event, inCombat) self:OnCombatStateChanged(inCombat) end, 2, "Memory_CombatState")
    
    -- Initialize object pools
    self:InitializeObjectPools()
    
    DamiaUI.Engine:LogInfo("Memory management initialized")
end

-- Establish memory baseline
function Memory:EstablishBaseline()
    C_Timer.After(2.0, function() -- Wait for initial loading
        UpdateAddOnMemoryUsage()
        local baseline = GetAddOnMemoryUsage(addonName) / 1024 -- Convert to MB
        memoryData.baseline = baseline
        memoryData.current = baseline
        memoryData.peak = baseline
        
        DamiaUI.Engine:LogInfo("Memory baseline established: %.2fMB", baseline)
    end)
end

-- Start memory monitoring loop
function Memory:StartMemoryMonitoring()
    memoryFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - memoryData.lastCleanup >= MEMORY_CHECK_INTERVAL then
            self:UpdateMemoryStats()
            memoryData.lastCleanup = currentTime
        end
    end)
end

-- Update memory statistics
function Memory:UpdateMemoryStats()
    UpdateAddOnMemoryUsage()
    local memoryKB = GetAddOnMemoryUsage(addonName)
    local memoryMB = memoryKB / 1024
    
    -- Update current stats
    memoryData.current = memoryMB
    if memoryMB > memoryData.peak then
        memoryData.peak = memoryMB
    end
    
    -- Track history
    table.insert(memoryData.history, {
        memory = memoryMB,
        time = GetTime(),
    })
    
    -- Maintain history size
    while #memoryData.history > MEMORY_HISTORY_SIZE do
        table.remove(memoryData.history, 1)
    end
    
    -- Check thresholds and trigger appropriate actions
    self:CheckMemoryThresholds(memoryMB)
    
    -- Update profiling data if enabled
    if profilingData.enabled then
        self:UpdateProfilingData()
    end
end

-- Check memory thresholds and trigger actions
function Memory:CheckMemoryThresholds(memoryMB)
    if memoryMB >= MEMORY_EMERGENCY then
        DamiaUI.Engine:LogError("Emergency memory usage: %.2fMB", memoryMB)
        self:PerformEmergencyCleanup()
        DamiaUI.Events:Fire("DAMIA_MEMORY_EMERGENCY", memoryMB)
    elseif memoryMB >= MEMORY_CRITICAL then
        DamiaUI.Engine:LogWarning("Critical memory usage: %.2fMB", memoryMB)
        self:PerformCriticalCleanup()
        DamiaUI.Events:Fire("DAMIA_MEMORY_CRITICAL", memoryMB)
    elseif memoryMB >= MEMORY_WARNING then
        DamiaUI.Engine:LogWarning("High memory usage: %.2fMB", memoryMB)
        self:PerformStandardCleanup()
        DamiaUI.Events:Fire("DAMIA_MEMORY_WARNING", memoryMB)
    end
end

--[[
===============================================================================
MEMORY CLEANUP ROUTINES
===============================================================================
--]]

-- Perform standard memory cleanup
function Memory:PerformStandardCleanup()
    local startMemory = memoryData.current
    local startTime = GetTime()
    
    DamiaUI.Engine:LogDebug("Performing standard memory cleanup")
    
    -- Clean up frame pools
    self:CleanupFramePools()
    
    -- Clean up cache
    self:CleanupCache(0.3) -- Remove 30% of cached data
    
    -- Clean up old history data
    self:CleanupHistoryData()
    
    -- Run registered cleanup functions
    self:RunCleanupRegistry()
    
    -- Incremental garbage collection
    collectgarbage("step", 1000)
    
    local cleanupTime = (GetTime() - startTime) * 1000
    
    C_Timer.After(1.0, function()
        local endMemory = memoryData.current
        local savedMemory = startMemory - endMemory
        if savedMemory > 0.1 then
            DamiaUI.Engine:LogInfo("Standard cleanup: %.2fMB -> %.2fMB (saved %.2fMB) in %.1fms", 
                                  startMemory, endMemory, savedMemory, cleanupTime)
        end
    end)
end

-- Perform critical memory cleanup
function Memory:PerformCriticalCleanup()
    local startMemory = memoryData.current
    local startTime = GetTime()
    
    DamiaUI.Engine:LogWarning("Performing critical memory cleanup")
    
    -- Standard cleanup first
    self:CleanupFramePools()
    self:CleanupCache(0.6) -- Remove 60% of cached data
    self:CleanupHistoryData()
    self:RunCleanupRegistry()
    
    -- More aggressive cleanup
    self:CleanupObjectPools()
    self:ClearProfilingData()
    
    -- Force full garbage collection
    collectgarbage("collect")
    
    local cleanupTime = (GetTime() - startTime) * 1000
    
    C_Timer.After(1.0, function()
        local endMemory = memoryData.current
        local savedMemory = startMemory - endMemory
        DamiaUI.Engine:LogInfo("Critical cleanup: %.2fMB -> %.2fMB (saved %.2fMB) in %.1fms", 
                              startMemory, endMemory, savedMemory, cleanupTime)
    end)
end

-- Perform emergency memory cleanup
function Memory:PerformEmergencyCleanup()
    local startMemory = memoryData.current
    local startTime = GetTime()
    
    DamiaUI.Engine:LogError("Performing emergency memory cleanup")
    
    -- Critical cleanup first
    self:PerformCriticalCleanup()
    
    -- Emergency measures
    self:ClearAllCaches()
    self:ResetObjectPools()
    self:ClearAllHistory()
    
    -- Notify all modules to reduce memory usage
    DamiaUI.Events:Fire("DAMIA_MEMORY_EMERGENCY_CLEANUP")
    
    -- Multiple garbage collection passes
    for i = 1, 3 do
        collectgarbage("collect")
    end
    
    local cleanupTime = (GetTime() - startTime) * 1000
    
    C_Timer.After(1.0, function()
        local endMemory = memoryData.current
        local savedMemory = startMemory - endMemory
        DamiaUI.Engine:LogError("Emergency cleanup: %.2fMB -> %.2fMB (saved %.2fMB) in %.1fms", 
                               startMemory, endMemory, savedMemory, cleanupTime)
        
        if endMemory >= MEMORY_CRITICAL then
            DamiaUI.Engine:LogError("Emergency cleanup failed to resolve memory issue - consider UI reload")
        end
    end)
end

-- Clean up frame pools
function Memory:CleanupFramePools()
    if DamiaUI.Utils and DamiaUI.Utils.CleanupFramePools then
        DamiaUI.Utils:CleanupFramePools()
    end
    
    -- Additional frame pool cleanup
    for poolName, pool in pairs(memoryPools.frames) do
        while #pool > 5 do -- Keep maximum 5 frames per type
            local frame = table.remove(pool)
            if frame and frame.Hide then
                frame:Hide()
                frame:SetParent(nil)
            end
            frame = nil
        end
    end
end

-- Clean up object pools
function Memory:CleanupObjectPools()
    for poolType, pool in pairs(memoryPools) do
        if poolType ~= "frames" then -- Frames handled separately
            -- Keep only essential pooled objects
            while #pool > 10 do
                table.remove(pool)
            end
        end
    end
end

-- Reset object pools completely
function Memory:ResetObjectPools()
    for poolType, pool in pairs(memoryPools) do
        if poolType == "frames" then
            -- Properly dispose of frames
            for _, frame in ipairs(pool) do
                if frame and frame.Hide then
                    frame:Hide()
                    frame:SetParent(nil)
                end
            end
        end
        -- Clear the pool
        memoryPools[poolType] = {}
    end
    
    DamiaUI.Engine:LogInfo("Object pools reset")
end

-- Clean up history data
function Memory:CleanupHistoryData()
    local currentTime = GetTime()
    local maxAge = 180 -- Keep only 3 minutes of history during cleanup
    
    -- Clean memory history
    for i = #memoryData.history, 1, -1 do
        if currentTime - memoryData.history[i].time > maxAge then
            table.remove(memoryData.history, i)
        else
            break -- History is ordered by time
        end
    end
end

-- Clear all history data
function Memory:ClearAllHistory()
    memoryData.history = {}
    
    -- Also clear performance history if available
    if DamiaUI.Performance then
        local perfData = DamiaUI.Performance:GetMetrics()
        if perfData and perfData.fps and perfData.fps.history then
            perfData.fps.history = {}
        end
        if perfData and perfData.memory and perfData.memory.history then
            perfData.memory.history = {}
        end
    end
    
    DamiaUI.Engine:LogDebug("All history data cleared")
end

--[[
===============================================================================
CACHE MANAGEMENT
===============================================================================
--]]

-- Start cache cleanup routine
function Memory:StartCacheCleanup()
    local cacheFrame = CreateFrame("Frame")
    cacheFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - cacheData.lastCleanup >= CACHE_CLEANUP_INTERVAL then
            self:CleanupCache(0.2) -- Regular cleanup of 20%
            cacheData.lastCleanup = currentTime
        end
    end)
end

-- Clean up cache entries
function Memory:CleanupCache(percentage)
    if cacheData.currentSize == 0 then
        return
    end
    
    percentage = percentage or 0.3
    local targetRemovals = math.floor(#cacheData.entries * percentage)
    local removed = 0
    local savedSize = 0
    
    -- Sort entries by access time (least recently used first)
    local sortedEntries = {}
    for key, value in pairs(cacheData.entries) do
        table.insert(sortedEntries, {
            key = key,
            value = value,
            accessTime = cacheData.accessTimes[key] or 0,
        })
    end
    
    table.sort(sortedEntries, function(a, b)
        return a.accessTime < b.accessTime
    end)
    
    -- Remove least recently used entries
    for i = 1, math.min(targetRemovals, #sortedEntries) do
        local entry = sortedEntries[i]
        local size = self:CalculateObjectSize(entry.value)
        
        cacheData.entries[entry.key] = nil
        cacheData.accessTimes[entry.key] = nil
        savedSize = savedSize + size
        removed = removed + 1
    end
    
    cacheData.currentSize = cacheData.currentSize - savedSize
    
    if removed > 0 then
        DamiaUI.Engine:LogDebug("Cache cleanup: removed %d entries, saved %d bytes", removed, savedSize)
    end
end

-- Clear all cached data
function Memory:ClearAllCaches()
    local savedSize = cacheData.currentSize
    
    cacheData.entries = {}
    cacheData.accessTimes = {}
    cacheData.currentSize = 0
    
    DamiaUI.Engine:LogInfo("All caches cleared: saved %d bytes", savedSize)
end

-- Add item to cache
function Memory:CacheSet(key, value, ttl)
    if not key or value == nil then
        return false
    end
    
    local size = self:CalculateObjectSize(value)
    
    -- Check cache limits
    if size > cacheData.maxSize / 4 then -- Don't cache items larger than 25% of max cache
        return false
    end
    
    -- Make room if needed
    while cacheData.currentSize + size > cacheData.maxSize do
        self:CleanupCache(0.2)
        if cacheData.currentSize + size > cacheData.maxSize then
            -- Still not enough room, clear more aggressively
            self:CleanupCache(0.5)
            break
        end
    end
    
    cacheData.entries[key] = value
    cacheData.accessTimes[key] = GetTime()
    cacheData.currentSize = cacheData.currentSize + size
    
    -- Set TTL if specified
    if ttl then
        C_Timer.After(ttl, function()
            if cacheData.entries[key] then
                local itemSize = self:CalculateObjectSize(cacheData.entries[key])
                cacheData.entries[key] = nil
                cacheData.accessTimes[key] = nil
                cacheData.currentSize = cacheData.currentSize - itemSize
            end
        end)
    end
    
    return true
end

-- Get item from cache
function Memory:CacheGet(key)
    local value = cacheData.entries[key]
    if value ~= nil then
        cacheData.accessTimes[key] = GetTime()
        cacheData.hitCount = cacheData.hitCount + 1
        return value
    else
        cacheData.missCount = cacheData.missCount + 1
        return nil
    end
end

-- Remove item from cache
function Memory:CacheRemove(key)
    local value = cacheData.entries[key]
    if value ~= nil then
        local size = self:CalculateObjectSize(value)
        cacheData.entries[key] = nil
        cacheData.accessTimes[key] = nil
        cacheData.currentSize = cacheData.currentSize - size
        return true
    end
    return false
end

--[[
===============================================================================
OBJECT POOLING MANAGEMENT
===============================================================================
--]]

-- Initialize object pools
function Memory:InitializeObjectPools()
    for poolType in pairs(memoryPools) do
        memoryPools[poolType] = {}
    end
    DamiaUI.Engine:LogDebug("Object pools initialized")
end

-- Get object from pool
function Memory:GetPooledObject(objectType, createFunc, ...)
    local pool = memoryPools[objectType]
    if not pool then
        pool = {}
        memoryPools[objectType] = pool
    end
    
    if #pool > 0 then
        return table.remove(pool)
    else
        -- Create new object if pool is empty
        if createFunc and type(createFunc) == "function" then
            return createFunc(...)
        end
        return nil
    end
end

-- Return object to pool
function Memory:ReturnPooledObject(objectType, object)
    if not object then
        return false
    end
    
    local pool = memoryPools[objectType]
    if not pool then
        pool = {}
        memoryPools[objectType] = pool
    end
    
    -- Limit pool size to prevent memory bloat
    if #pool < 20 then
        table.insert(pool, object)
        return true
    else
        -- Pool is full, let object be garbage collected
        return false
    end
end

--[[
===============================================================================
MEMORY PROFILING
===============================================================================
--]]

-- Enable memory profiling
function Memory:EnableProfiling()
    profilingData.enabled = true
    profilingData.startTime = GetTime()
    DamiaUI.Engine:LogInfo("Memory profiling enabled")
end

-- Disable memory profiling
function Memory:DisableProfiling()
    profilingData.enabled = false
    DamiaUI.Engine:LogInfo("Memory profiling disabled")
end

-- Take memory snapshot
function Memory:TakeSnapshot(label)
    if not profilingData.enabled then
        return nil
    end
    
    UpdateAddOnMemoryUsage()
    local snapshot = {
        label = label or "Snapshot_" .. #profilingData.snapshots + 1,
        time = GetTime(),
        memory = GetAddOnMemoryUsage(addonName) / 1024, -- MB
        categories = self:AnalyzeMemoryCategories(),
    }
    
    table.insert(profilingData.snapshots, snapshot)
    
    DamiaUI.Engine:LogDebug("Memory snapshot taken: %s (%.2fMB)", snapshot.label, snapshot.memory)
    return snapshot
end

-- Analyze memory usage by categories
function Memory:AnalyzeMemoryCategories()
    -- This is a simplified analysis - in a real implementation,
    -- you would need more sophisticated memory tracking
    local categories = {}
    
    -- Estimate based on object pools and known data structures
    categories.frames = #memoryPools.frames * 0.005 -- ~5KB per frame estimate
    categories.textures = #memoryPools.textures * 0.01 -- ~10KB per texture estimate
    categories.strings = cacheData.currentSize * 0.3 -- Assume 30% of cache is strings
    categories.tables = cacheData.currentSize * 0.5 -- Assume 50% of cache is tables
    categories.other = memoryData.current - (categories.frames + categories.textures + categories.strings + categories.tables)
    
    return categories
end

-- Update profiling data
function Memory:UpdateProfilingData()
    profilingData.categories = self:AnalyzeMemoryCategories()
end

-- Clear profiling data
function Memory:ClearProfilingData()
    profilingData.snapshots = {}
    profilingData.allocations = {}
    DamiaUI.Engine:LogDebug("Profiling data cleared")
end

--[[
===============================================================================
LEAK DETECTION
===============================================================================
--]]

-- Start leak detection
function Memory:StartLeakDetection()
    local leakFrame = CreateFrame("Frame")
    leakFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - memoryData.lastLeakCheck >= LEAK_DETECTION_INTERVAL then
            self:CheckForMemoryLeaks()
            memoryData.lastLeakCheck = currentTime
        end
    end)
end

-- Check for potential memory leaks
function Memory:CheckForMemoryLeaks()
    if #memoryData.history < 10 then
        return -- Not enough data
    end
    
    -- Check for consistent memory growth
    local recentHistory = {}
    for i = #memoryData.history - 9, #memoryData.history do
        table.insert(recentHistory, memoryData.history[i].memory)
    end
    
    -- Calculate trend
    local growth = 0
    for i = 2, #recentHistory do
        growth = growth + (recentHistory[i] - recentHistory[i-1])
    end
    
    local averageGrowth = growth / (#recentHistory - 1)
    
    -- Detect potential leak
    if averageGrowth > 0.1 then -- Growing by more than 0.1MB per check interval
        if not memoryData.leakDetected then
            memoryData.leakDetected = true
            DamiaUI.Engine:LogWarning("Potential memory leak detected (growth: %.3fMB/check)", averageGrowth)
            DamiaUI.Events:Fire("DAMIA_MEMORY_LEAK_DETECTED", averageGrowth)
            
            -- Take snapshot for analysis
            if profilingData.enabled then
                self:TakeSnapshot("Leak_Detection")
            end
            
            -- Trigger cleanup
            self:PerformStandardCleanup()
        end
    else
        if memoryData.leakDetected and averageGrowth < 0.05 then
            memoryData.leakDetected = false
            DamiaUI.Engine:LogInfo("Memory leak resolved")
            DamiaUI.Events:Fire("DAMIA_MEMORY_LEAK_RESOLVED")
        end
    end
end

--[[
===============================================================================
GARBAGE COLLECTION OPTIMIZATION
===============================================================================
--]]

-- Start GC optimization
function Memory:StartGCOptimization()
    local gcFrame = CreateFrame("Frame")
    gcFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - memoryData.lastGCOptimization >= GC_OPTIMIZATION_INTERVAL then
            self:OptimizeGarbageCollection()
            memoryData.lastGCOptimization = currentTime
        end
    end)
end

-- Optimize garbage collection based on current conditions
function Memory:OptimizeGarbageCollection()
    local inCombat = InCombatLockdown()
    local memoryUsage = memoryData.current
    
    if inCombat then
        -- Minimal GC during combat to avoid frame drops
        if memoryUsage >= MEMORY_CRITICAL then
            collectgarbage("collect")
            memoryData.gcCollections = memoryData.gcCollections + 1
        elseif memoryUsage >= MEMORY_WARNING then
            collectgarbage("step", 500)
        end
    else
        -- More aggressive GC outside combat
        if memoryUsage >= MEMORY_WARNING then
            collectgarbage("collect")
            memoryData.gcCollections = memoryData.gcCollections + 1
        else
            collectgarbage("step", 1000)
        end
    end
end

--[[
===============================================================================
CLEANUP REGISTRY
===============================================================================
--]]

-- Register cleanup function
function Memory:RegisterCleanupFunction(identifier, func, priority)
    if not identifier or not func then
        return false
    end
    
    priority = priority or 5
    
    cleanupRegistry[identifier] = {
        func = func,
        priority = priority,
    }
    
    return true
end

-- Unregister cleanup function
function Memory:UnregisterCleanupFunction(identifier)
    cleanupRegistry[identifier] = nil
end

-- Run all registered cleanup functions
function Memory:RunCleanupRegistry()
    local sortedCleanup = {}
    
    -- Sort by priority (lower number = higher priority)
    for identifier, data in pairs(cleanupRegistry) do
        table.insert(sortedCleanup, {
            identifier = identifier,
            func = data.func,
            priority = data.priority,
        })
    end
    
    table.sort(sortedCleanup, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Execute cleanup functions
    for _, cleanup in ipairs(sortedCleanup) do
        local success, error = pcall(cleanup.func)
        if not success then
            DamiaUI.Engine:LogError("Cleanup function error [%s]: %s", cleanup.identifier, error)
        end
    end
end

--[[
===============================================================================
UTILITY FUNCTIONS
===============================================================================
--]]

-- Calculate approximate size of an object in memory
function Memory:CalculateObjectSize(obj)
    local objType = type(obj)
    
    if objType == "string" then
        return #obj + 24 -- String overhead
    elseif objType == "table" then
        local size = 40 -- Table overhead
        for k, v in pairs(obj) do
            size = size + self:CalculateObjectSize(k) + self:CalculateObjectSize(v)
        end
        return size
    elseif objType == "number" then
        return 8
    elseif objType == "boolean" then
        return 1
    elseif objType == "function" then
        return 32 -- Approximation
    else
        return 8 -- Pointer size
    end
end

--[[
===============================================================================
EVENT HANDLERS
===============================================================================
--]]

-- Handle performance degradation
function Memory:OnPerformanceDegraded()
    DamiaUI.Engine:LogDebug("Performance degradation detected - triggering memory cleanup")
    self:PerformStandardCleanup()
end

-- Handle combat state changes
function Memory:OnCombatStateChanged(inCombat)
    if inCombat then
        -- Pre-combat cleanup
        if memoryData.current >= MEMORY_WARNING then
            self:PerformStandardCleanup()
        end
        
        -- Force GC before combat
        collectgarbage("collect")
    else
        -- Post-combat cleanup
        C_Timer.After(2.0, function()
            self:PerformStandardCleanup()
        end)
    end
end

--[[
===============================================================================
PUBLIC API FUNCTIONS
===============================================================================
--]]

-- Get current memory usage
function Memory:GetUsage()
    return memoryData.current
end

-- Get memory statistics
function Memory:GetStats()
    local hitRate = 0
    if cacheData.hitCount + cacheData.missCount > 0 then
        hitRate = cacheData.hitCount / (cacheData.hitCount + cacheData.missCount) * 100
    end
    
    return {
        current = memoryData.current,
        peak = memoryData.peak,
        baseline = memoryData.baseline,
        target = MEMORY_TARGET,
        warning = MEMORY_WARNING,
        critical = MEMORY_CRITICAL,
        gcCollections = memoryData.gcCollections,
        leakDetected = memoryData.leakDetected,
        cache = {
            size = cacheData.currentSize,
            maxSize = cacheData.maxSize,
            hitRate = hitRate,
            entries = #cacheData.entries,
        },
        pools = {
            frames = #memoryPools.frames,
            tables = #memoryPools.tables,
            strings = #memoryPools.strings,
        },
    }
end

-- Force immediate cleanup
function Memory:ForceCleanup(level)
    level = level or "standard"
    
    if level == "emergency" then
        self:PerformEmergencyCleanup()
    elseif level == "critical" then
        self:PerformCriticalCleanup()
    else
        self:PerformStandardCleanup()
    end
end

-- Print memory report
function Memory:PrintReport()
    local stats = self:GetStats()
    
    DamiaUI.Engine:LogInfo("Memory Report:")
    DamiaUI.Engine:LogInfo("  Current: %.2fMB / %.2fMB (peak: %.2fMB)", 
                          stats.current, stats.critical, stats.peak)
    DamiaUI.Engine:LogInfo("  Baseline: %.2fMB, Target: %.2fMB", stats.baseline, stats.target)
    DamiaUI.Engine:LogInfo("  GC Collections: %d", stats.gcCollections)
    DamiaUI.Engine:LogInfo("  Leak Detected: %s", stats.leakDetected and "Yes" or "No")
    DamiaUI.Engine:LogInfo("  Cache: %d entries, %.1f%% hit rate", stats.cache.entries, stats.cache.hitRate)
    DamiaUI.Engine:LogInfo("  Pools: %d frames, %d tables, %d strings", 
                          stats.pools.frames, stats.pools.tables, stats.pools.strings)
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Auto-initialize when engine is ready
DamiaUI.Events:RegisterCustomEvent("DAMIA_INITIALIZED", function()
    Memory:Initialize()
end, 1, "Memory_AutoInit")

DamiaUI.Engine:LogInfo("Memory management system loaded")