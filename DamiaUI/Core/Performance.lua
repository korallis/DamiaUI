--[[
===============================================================================
Damia UI - Performance Optimization and Monitoring System
===============================================================================
Advanced performance monitoring system designed to maintain <2% FPS impact
and <25MB memory usage even in 40-person raids with heavy combat activity.

Features:
- Real-time FPS impact monitoring with automatic optimization
- Memory usage tracking and cleanup routines
- Performance degradation detection and response
- Frame pooling for temporary elements
- Automatic garbage collection optimization
- Performance metrics display and configuration options

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
local GetFramerate = GetFramerate
local GetTime = GetTime
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer
local collectgarbage = collectgarbage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

-- Create Performance module
local Performance = {}
DamiaUI.Performance = Performance

-- Performance constants and thresholds
local FPS_THRESHOLD_LOW = 30
local FPS_THRESHOLD_CRITICAL = 20
local FPS_IMPACT_LIMIT = 2.0 -- Maximum 2% FPS impact
local MEMORY_LIMIT_MB = 25 -- Maximum 25MB memory usage
local MEMORY_WARNING_MB = 20 -- Warning at 20MB
local DEGRADATION_THRESHOLD = 10 -- 10% performance degradation triggers optimization

-- Monitoring intervals
local PERFORMANCE_UPDATE_INTERVAL = 0.5 -- 500ms
local MEMORY_CHECK_INTERVAL = 2.0 -- 2 seconds
local GC_OPTIMIZATION_INTERVAL = 30.0 -- 30 seconds
local METRICS_HISTORY_SIZE = 300 -- Keep 5 minutes of data at 1s intervals

-- Performance tracking data
local performanceData = {
    baselineFPS = 0,
    currentFPS = 0,
    fpsHistory = {},
    fpsImpact = 0,
    memoryUsage = 0,
    memoryHistory = {},
    lastUpdateTime = 0,
    lastMemoryCheck = 0,
    lastGCOptimization = 0,
    optimizationLevel = 0, -- 0=off, 1=light, 2=moderate, 3=aggressive
    performanceDegraded = false,
    combatOptimizations = false,
}

-- Performance metrics for detailed monitoring
local metricsData = {
    frameTime = 0,
    eventProcessingTime = 0,
    updateCallbackCount = 0,
    memoryAllocations = 0,
    gcCollections = 0,
    addonLoadTime = 0,
}

-- Optimization settings by level
local optimizationLevels = {
    [0] = { -- None
        eventThrottling = false,
        framePooling = false,
        updateFrequencyReduction = false,
        combatOptimizations = false,
        memoryCleanupAggressive = false,
    },
    [1] = { -- Light
        eventThrottling = true,
        framePooling = true,
        updateFrequencyReduction = false,
        combatOptimizations = true,
        memoryCleanupAggressive = false,
    },
    [2] = { -- Moderate
        eventThrottling = true,
        framePooling = true,
        updateFrequencyReduction = true,
        combatOptimizations = true,
        memoryCleanupAggressive = true,
    },
    [3] = { -- Aggressive
        eventThrottling = true,
        framePooling = true,
        updateFrequencyReduction = true,
        combatOptimizations = true,
        memoryCleanupAggressive = true,
    }
}

-- Frame for performance monitoring
local performanceFrame = CreateFrame("Frame", "DamiaUIPerformanceFrame")
local gcOptimizationFrame = CreateFrame("Frame", "DamiaUIGCFrame")

--[[
===============================================================================
CORE PERFORMANCE MONITORING
===============================================================================
--]]

-- Initialize performance monitoring system
function Performance:Initialize()
    DamiaUI.Engine:LogInfo("Initializing Performance Monitoring System")
    
    -- Establish baseline FPS
    self:EstablishBaseline()
    
    -- Start monitoring loops
    self:StartPerformanceMonitoring()
    self:StartMemoryMonitoring()
    self:StartGCOptimization()
    
    -- Register for combat state changes
    DamiaUI.Events:RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", 
        function(event, inCombat)
            self:OnCombatStateChanged(inCombat)
        end, 2, "Performance_CombatState")
    
    -- Register for addon loaded to measure load time
    local loadStartTime = GetTime()
    DamiaUI.Events:RegisterEvent("ADDON_LOADED", function(event, loadedAddonName)
        if loadedAddonName == addonName then
            metricsData.addonLoadTime = (GetTime() - loadStartTime) * 1000
            DamiaUI.Engine:LogInfo("Addon load time: %.2fms", metricsData.addonLoadTime)
        end
    end, 1, "Performance_AddonLoaded")
    
    DamiaUI.Engine:LogInfo("Performance monitoring initialized")
end

-- Establish baseline FPS for impact calculation
function Performance:EstablishBaseline()
    local function measureBaseline()
        local measurements = {}
        local measurementCount = 20
        local measurementInterval = 0.1
        
        local function takeMeasurement(count)
            if count > measurementCount then
                -- Calculate average baseline
                local total = 0
                for _, fps in ipairs(measurements) do
                    total = total + fps
                end
                
                performanceData.baselineFPS = total / #measurements
                DamiaUI.Engine:LogInfo("Baseline FPS established: %.1f", performanceData.baselineFPS)
                return
            end
            
            table.insert(measurements, GetFramerate())
            C_Timer.After(measurementInterval, function()
                takeMeasurement(count + 1)
            end)
        end
        
        takeMeasurement(1)
    end
    
    -- Wait for initial UI load before measuring
    C_Timer.After(5.0, measureBaseline)
end

-- Start main performance monitoring loop
function Performance:StartPerformanceMonitoring()
    performanceFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - performanceData.lastUpdateTime >= PERFORMANCE_UPDATE_INTERVAL then
            self:UpdatePerformanceMetrics()
            performanceData.lastUpdateTime = currentTime
        end
    end)
end

-- Update performance metrics
function Performance:UpdatePerformanceMetrics()
    local startTime = GetTime()
    
    -- Update FPS data
    local currentFPS = GetFramerate()
    performanceData.currentFPS = currentFPS
    
    -- Track FPS history
    table.insert(performanceData.fpsHistory, {
        fps = currentFPS,
        time = GetTime(),
    })
    
    -- Maintain history size
    while #performanceData.fpsHistory > METRICS_HISTORY_SIZE do
        table.remove(performanceData.fpsHistory, 1)
    end
    
    -- Calculate FPS impact
    if performanceData.baselineFPS > 0 then
        local fpsLoss = performanceData.baselineFPS - currentFPS
        performanceData.fpsImpact = math.max(0, (fpsLoss / performanceData.baselineFPS) * 100)
    end
    
    -- Check for performance degradation
    self:CheckPerformanceDegradation()
    
    -- Auto-optimize if needed
    self:AutoOptimize()
    
    -- Update frame time metric
    metricsData.frameTime = (GetTime() - startTime) * 1000
    
    -- Fire performance update event
    DamiaUI.Events:Fire("DAMIA_PERFORMANCE_UPDATE", {
        fps = currentFPS,
        fpsImpact = performanceData.fpsImpact,
        memoryUsage = performanceData.memoryUsage,
        optimizationLevel = performanceData.optimizationLevel,
    })
end

-- Check for performance degradation
function Performance:CheckPerformanceDegradation()
    local currentFPS = performanceData.currentFPS
    local baselineFPS = performanceData.baselineFPS
    
    if baselineFPS == 0 then
        return
    end
    
    -- Calculate performance degradation
    local degradation = ((baselineFPS - currentFPS) / baselineFPS) * 100
    
    -- Check thresholds
    local wasDegraded = performanceData.performanceDegraded
    performanceData.performanceDegraded = degradation >= DEGRADATION_THRESHOLD or 
                                         currentFPS <= FPS_THRESHOLD_CRITICAL or
                                         performanceData.fpsImpact >= FPS_IMPACT_LIMIT
    
    -- Trigger optimization if degradation detected
    if performanceData.performanceDegraded and not wasDegraded then
        DamiaUI.Engine:LogWarning("Performance degradation detected: %.1f%% (FPS: %.1f)", 
                                 degradation, currentFPS)
        DamiaUI.Events:Fire("DAMIA_PERFORMANCE_DEGRADED", {
            degradation = degradation,
            currentFPS = currentFPS,
            fpsImpact = performanceData.fpsImpact,
        })
    elseif not performanceData.performanceDegraded and wasDegraded then
        DamiaUI.Engine:LogInfo("Performance recovered (FPS: %.1f)", currentFPS)
        DamiaUI.Events:Fire("DAMIA_PERFORMANCE_RECOVERED", {
            currentFPS = currentFPS,
            fpsImpact = performanceData.fpsImpact,
        })
    end
end

-- Auto-optimize performance based on current conditions
function Performance:AutoOptimize()
    local targetLevel = self:CalculateOptimalOptimizationLevel()
    
    if targetLevel ~= performanceData.optimizationLevel then
        self:SetOptimizationLevel(targetLevel)
    end
end

-- Calculate optimal optimization level
function Performance:CalculateOptimalOptimizationLevel()
    local currentFPS = performanceData.currentFPS
    local fpsImpact = performanceData.fpsImpact
    local memoryUsage = performanceData.memoryUsage
    local inCombat = InCombatLockdown()
    
    -- Determine optimization level based on conditions
    if currentFPS <= FPS_THRESHOLD_CRITICAL or fpsImpact >= FPS_IMPACT_LIMIT * 1.5 then
        return 3 -- Aggressive
    elseif currentFPS <= FPS_THRESHOLD_LOW or fpsImpact >= FPS_IMPACT_LIMIT or memoryUsage >= MEMORY_WARNING_MB then
        return inCombat and 3 or 2 -- Moderate or Aggressive in combat
    elseif performanceData.performanceDegraded or (inCombat and (currentFPS <= 45 or memoryUsage >= 15)) then
        return 1 -- Light
    else
        return 0 -- None
    end
end

-- Set optimization level
function Performance:SetOptimizationLevel(level)
    level = math.max(0, math.min(3, level))
    
    if level == performanceData.optimizationLevel then
        return
    end
    
    local oldLevel = performanceData.optimizationLevel
    performanceData.optimizationLevel = level
    
    local settings = optimizationLevels[level]
    
    -- Apply optimizations
    self:ApplyOptimizations(settings)
    
    DamiaUI.Engine:LogInfo("Optimization level changed: %d -> %d", oldLevel, level)
    DamiaUI.Events:Fire("DAMIA_OPTIMIZATION_CHANGED", level, oldLevel)
end

-- Apply optimization settings
function Performance:ApplyOptimizations(settings)
    -- Event throttling
    if settings.eventThrottling then
        self:EnableEventThrottling()
    else
        self:DisableEventThrottling()
    end
    
    -- Frame pooling
    if settings.framePooling then
        self:EnableFramePooling()
    else
        self:DisableFramePooling()
    end
    
    -- Update frequency reduction
    if settings.updateFrequencyReduction then
        self:ReduceUpdateFrequency()
    else
        self:RestoreUpdateFrequency()
    end
    
    -- Combat optimizations
    if settings.combatOptimizations then
        self:EnableCombatOptimizations()
    else
        self:DisableCombatOptimizations()
    end
    
    -- Aggressive memory cleanup
    if settings.memoryCleanupAggressive then
        self:EnableAggressiveMemoryCleanup()
    else
        self:DisableAggressiveMemoryCleanup()
    end
end

-- Handle combat state changes
function Performance:OnCombatStateChanged(inCombat)
    if inCombat then
        -- Enter combat optimizations
        self:EnableCombatOptimizations()
        performanceData.combatOptimizations = true
        
        -- Force garbage collection before combat
        if performanceData.optimizationLevel >= 1 then
            collectgarbage("collect")
        end
        
        DamiaUI.Engine:LogDebug("Combat optimizations enabled")
    else
        -- Exit combat - restore normal operation
        if not optimizationLevels[performanceData.optimizationLevel].combatOptimizations then
            self:DisableCombatOptimizations()
        end
        performanceData.combatOptimizations = false
        
        -- Post-combat cleanup
        C_Timer.After(2.0, function()
            self:PerformMemoryCleanup()
        end)
        
        DamiaUI.Engine:LogDebug("Combat optimizations disabled")
    end
end

--[[
===============================================================================
MEMORY MONITORING AND MANAGEMENT
===============================================================================
--]]

-- Start memory monitoring
function Performance:StartMemoryMonitoring()
    local memoryFrame = CreateFrame("Frame")
    memoryFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - performanceData.lastMemoryCheck >= MEMORY_CHECK_INTERVAL then
            self:UpdateMemoryMetrics()
            performanceData.lastMemoryCheck = currentTime
        end
    end)
end

-- Update memory usage metrics
function Performance:UpdateMemoryMetrics()
    UpdateAddOnMemoryUsage()
    local memoryKB = GetAddOnMemoryUsage(addonName)
    local memoryMB = memoryKB / 1024
    
    performanceData.memoryUsage = memoryMB
    
    -- Track memory history
    table.insert(performanceData.memoryHistory, {
        memory = memoryMB,
        time = GetTime(),
    })
    
    -- Maintain history size
    while #performanceData.memoryHistory > METRICS_HISTORY_SIZE do
        table.remove(performanceData.memoryHistory, 1)
    end
    
    -- Check memory limits
    if memoryMB >= MEMORY_LIMIT_MB then
        DamiaUI.Engine:LogWarning("Memory usage critical: %.2fMB (limit: %dMB)", 
                                 memoryMB, MEMORY_LIMIT_MB)
        self:PerformEmergencyMemoryCleanup()
        DamiaUI.Events:Fire("DAMIA_MEMORY_CRITICAL", memoryMB)
    elseif memoryMB >= MEMORY_WARNING_MB then
        DamiaUI.Engine:LogWarning("Memory usage high: %.2fMB (warning: %dMB)", 
                                 memoryMB, MEMORY_WARNING_MB)
        self:PerformMemoryCleanup()
        DamiaUI.Events:Fire("DAMIA_MEMORY_WARNING", memoryMB)
    end
end

-- Perform standard memory cleanup
function Performance:PerformMemoryCleanup()
    local startMemory = performanceData.memoryUsage
    
    -- Clean up frame pools
    if DamiaUI.Utils then
        DamiaUI.Utils:CleanupFramePools()
    end
    
    -- Clear old history data
    self:CleanupHistoryData()
    
    -- Clean up event statistics if too large
    if DamiaUI.Events then
        local stats = DamiaUI.Events:GetEventStatistics()
        if DamiaUI.Utils:GetTableSize(stats) > 100 then
            DamiaUI.Events:ResetEventStatistics()
        end
    end
    
    -- Trigger garbage collection
    collectgarbage("collect")
    
    -- Log cleanup results
    C_Timer.After(1.0, function()
        local endMemory = performanceData.memoryUsage
        local saved = startMemory - endMemory
        if saved > 0.1 then
            DamiaUI.Engine:LogInfo("Memory cleanup: %.2fMB -> %.2fMB (saved %.2fMB)", 
                                  startMemory, endMemory, saved)
        end
    end)
end

-- Perform emergency memory cleanup
function Performance:PerformEmergencyMemoryCleanup()
    DamiaUI.Engine:LogWarning("Performing emergency memory cleanup")
    
    -- Aggressive cleanup
    self:PerformMemoryCleanup()
    
    -- Clear all cached data
    if DamiaUI.Cache then
        DamiaUI.Cache:ClearAll()
    end
    
    -- Reset performance history
    performanceData.fpsHistory = {}
    performanceData.memoryHistory = {}
    
    -- Force immediate garbage collection
    collectgarbage("collect")
    collectgarbage("collect") -- Second pass for full cleanup
    
    -- Set aggressive optimization
    self:SetOptimizationLevel(3)
end

-- Clean up old history data
function Performance:CleanupHistoryData()
    local currentTime = GetTime()
    local maxAge = 300 -- 5 minutes
    
    -- Clean FPS history
    local fpsHistory = performanceData.fpsHistory
    for i = #fpsHistory, 1, -1 do
        if currentTime - fpsHistory[i].time > maxAge then
            table.remove(fpsHistory, i)
        else
            break -- History is ordered by time
        end
    end
    
    -- Clean memory history
    local memHistory = performanceData.memoryHistory
    for i = #memHistory, 1, -1 do
        if currentTime - memHistory[i].time > maxAge then
            table.remove(memHistory, i)
        else
            break
        end
    end
end

--[[
===============================================================================
GARBAGE COLLECTION OPTIMIZATION
===============================================================================
--]]

-- Start garbage collection optimization
function Performance:StartGCOptimization()
    gcOptimizationFrame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        
        if currentTime - performanceData.lastGCOptimization >= GC_OPTIMIZATION_INTERVAL then
            self:OptimizeGarbageCollection()
            performanceData.lastGCOptimization = currentTime
        end
    end)
end

-- Optimize garbage collection for combat situations
function Performance:OptimizeGarbageCollection()
    local inCombat = InCombatLockdown()
    local memoryUsage = performanceData.memoryUsage
    local optimizationLevel = performanceData.optimizationLevel
    
    if inCombat then
        -- During combat: minimal GC to avoid frame drops
        if memoryUsage > MEMORY_WARNING_MB then
            -- Quick incremental collection only
            collectgarbage("step", 100)
        end
        -- Skip full collection during combat unless critical
        if memoryUsage >= MEMORY_LIMIT_MB then
            collectgarbage("collect")
        end
    else
        -- Outside combat: normal or aggressive collection
        if optimizationLevel >= 2 or memoryUsage > 10 then
            collectgarbage("collect")
        elseif optimizationLevel >= 1 then
            collectgarbage("step", 1000)
        end
    end
    
    -- Track GC collections
    metricsData.gcCollections = metricsData.gcCollections + 1
end

--[[
===============================================================================
OPTIMIZATION IMPLEMENTATIONS
===============================================================================
--]]

-- Enable event throttling
function Performance:EnableEventThrottling()
    -- Throttle high-frequency events
    if DamiaUI.Events then
        DamiaUI.Events:ThrottleEvent("UNIT_HEALTH_FREQUENT", 0.1)
        DamiaUI.Events:ThrottleEvent("UNIT_POWER_FREQUENT", 0.1)
        DamiaUI.Events:ThrottleEvent("COMBAT_LOG_EVENT_UNFILTERED", 0.05)
    end
end

-- Disable event throttling
function Performance:DisableEventThrottling()
    -- Remove throttling (implementation would depend on Events module API)
    -- This is a placeholder for the actual implementation
end

-- Enable frame pooling optimizations
function Performance:EnableFramePooling()
    -- Frame pooling is already implemented in Utils module
    -- This ensures it's actively used for temporary frames
    if DamiaUI.Utils then
        DamiaUI.Utils.useFramePooling = true
    end
end

-- Disable frame pooling
function Performance:DisableFramePooling()
    if DamiaUI.Utils then
        DamiaUI.Utils.useFramePooling = false
    end
end

-- Reduce update frequency for non-critical elements
function Performance:ReduceUpdateFrequency()
    -- Fire event to reduce update frequencies across modules
    DamiaUI.Events:Fire("DAMIA_REDUCE_UPDATE_FREQUENCY", true)
end

-- Restore normal update frequency
function Performance:RestoreUpdateFrequency()
    DamiaUI.Events:Fire("DAMIA_REDUCE_UPDATE_FREQUENCY", false)
end

-- Enable combat-specific optimizations
function Performance:EnableCombatOptimizations()
    -- Reduce non-essential updates during combat
    DamiaUI.Events:Fire("DAMIA_COMBAT_OPTIMIZATIONS", true)
end

-- Disable combat optimizations
function Performance:DisableCombatOptimizations()
    DamiaUI.Events:Fire("DAMIA_COMBAT_OPTIMIZATIONS", false)
end

-- Enable aggressive memory cleanup
function Performance:EnableAggressiveMemoryCleanup()
    -- More frequent cleanup cycles
    MEMORY_CHECK_INTERVAL = 1.0
    GC_OPTIMIZATION_INTERVAL = 15.0
end

-- Disable aggressive memory cleanup
function Performance:DisableAggressiveMemoryCleanup()
    -- Normal cleanup intervals
    MEMORY_CHECK_INTERVAL = 2.0
    GC_OPTIMIZATION_INTERVAL = 30.0
end

--[[
===============================================================================
PERFORMANCE METRICS AND REPORTING
===============================================================================
--]]

-- Get current performance metrics
function Performance:GetMetrics()
    return {
        fps = {
            current = performanceData.currentFPS,
            baseline = performanceData.baselineFPS,
            impact = performanceData.fpsImpact,
            history = performanceData.fpsHistory,
        },
        memory = {
            current = performanceData.memoryUsage,
            limit = MEMORY_LIMIT_MB,
            warning = MEMORY_WARNING_MB,
            history = performanceData.memoryHistory,
        },
        optimization = {
            level = performanceData.optimizationLevel,
            degraded = performanceData.performanceDegraded,
            combatMode = performanceData.combatOptimizations,
        },
        detailed = metricsData,
    }
end

-- Get performance summary
function Performance:GetSummary()
    local metrics = self:GetMetrics()
    
    return {
        status = self:GetPerformanceStatus(),
        fpsImpact = metrics.fps.impact,
        memoryUsage = metrics.memory.current,
        optimizationLevel = metrics.optimization.level,
        recommendations = self:GetRecommendations(),
    }
end

-- Get performance status
function Performance:GetPerformanceStatus()
    local fps = performanceData.currentFPS
    local fpsImpact = performanceData.fpsImpact
    local memory = performanceData.memoryUsage
    
    if fps <= FPS_THRESHOLD_CRITICAL or fpsImpact >= FPS_IMPACT_LIMIT * 1.5 or memory >= MEMORY_LIMIT_MB then
        return "CRITICAL"
    elseif fps <= FPS_THRESHOLD_LOW or fpsImpact >= FPS_IMPACT_LIMIT or memory >= MEMORY_WARNING_MB then
        return "WARNING"
    elseif performanceData.performanceDegraded then
        return "DEGRADED"
    else
        return "GOOD"
    end
end

-- Get performance recommendations
function Performance:GetRecommendations()
    local recommendations = {}
    local fps = performanceData.currentFPS
    local memory = performanceData.memoryUsage
    local optimLevel = performanceData.optimizationLevel
    
    if fps <= FPS_THRESHOLD_CRITICAL then
        table.insert(recommendations, "FPS critically low - consider reducing addon settings")
    elseif fps <= FPS_THRESHOLD_LOW then
        table.insert(recommendations, "FPS low - automatic optimizations enabled")
    end
    
    if memory >= MEMORY_WARNING_MB then
        table.insert(recommendations, "High memory usage - consider reloading UI")
    end
    
    if optimLevel == 0 and performanceData.performanceDegraded then
        table.insert(recommendations, "Enable performance optimizations")
    elseif optimLevel == 3 then
        table.insert(recommendations, "Aggressive optimizations active - performance may be impacted")
    end
    
    if performanceData.fpsImpact >= FPS_IMPACT_LIMIT then
        table.insert(recommendations, "FPS impact exceeds target - review addon configuration")
    end
    
    return recommendations
end

-- Print performance report
function Performance:PrintReport()
    local metrics = self:GetMetrics()
    local summary = self:GetSummary()
    
    DamiaUI.Engine:LogInfo("Performance Report:")
    DamiaUI.Engine:LogInfo("  Status: %s", summary.status)
    DamiaUI.Engine:LogInfo("  FPS: %.1f (baseline: %.1f, impact: %.1f%%)", 
                          metrics.fps.current, metrics.fps.baseline, metrics.fps.impact)
    DamiaUI.Engine:LogInfo("  Memory: %.2fMB / %dMB limit", metrics.memory.current, MEMORY_LIMIT_MB)
    DamiaUI.Engine:LogInfo("  Optimization Level: %d", metrics.optimization.level)
    DamiaUI.Engine:LogInfo("  Load Time: %.2fms", metricsData.addonLoadTime)
    
    if #summary.recommendations > 0 then
        DamiaUI.Engine:LogInfo("  Recommendations:")
        for _, rec in ipairs(summary.recommendations) do
            DamiaUI.Engine:LogInfo("    - %s", rec)
        end
    end
end

--[[
===============================================================================
PUBLIC API FUNCTIONS
===============================================================================
--]]

-- Manual optimization control
function Performance:SetManualOptimization(level)
    if type(level) ~= "number" or level < 0 or level > 3 then
        DamiaUI.Engine:LogError("Invalid optimization level: must be 0-3")
        return false
    end
    
    self:SetOptimizationLevel(level)
    DamiaUI.Engine:LogInfo("Manual optimization level set to %d", level)
    return true
end

-- Force memory cleanup
function Performance:ForceMemoryCleanup()
    self:PerformMemoryCleanup()
end

-- Reset performance data
function Performance:Reset()
    performanceData.fpsHistory = {}
    performanceData.memoryHistory = {}
    performanceData.baselineFPS = 0
    performanceData.performanceDegraded = false
    metricsData.gcCollections = 0
    
    -- Re-establish baseline
    self:EstablishBaseline()
    
    DamiaUI.Engine:LogInfo("Performance data reset")
end

-- Check if performance targets are met
function Performance:IsPerformanceAcceptable()
    return performanceData.fpsImpact < FPS_IMPACT_LIMIT and 
           performanceData.memoryUsage < MEMORY_LIMIT_MB and
           not performanceData.performanceDegraded
end

-- Run performance stress test
function Performance:RunStressTest()
    DamiaUI.Engine:LogInfo("Running performance stress test...")
    
    local startMemory = performanceData.memoryUsage
    local startFPS = performanceData.currentFPS
    local startTime = GetTime()
    
    -- Create temporary frames to stress test frame pooling
    local testFrames = {}
    for i = 1, 50 do
        local frame = DamiaUI.Utils:GetPooledFrame("Frame", nil, UIParent)
        frame:SetSize(20, 20)
        frame:SetPoint("CENTER", UIParent, "CENTER", math.random(-200, 200), math.random(-200, 200))
        table.insert(testFrames, frame)
    end
    
    -- Stress test event system
    for i = 1, 100 do
        DamiaUI.Events:Fire("DAMIA_STRESS_TEST", i)
    end
    
    -- Clean up test frames
    C_Timer.After(2.0, function()
        for _, frame in ipairs(testFrames) do
            DamiaUI.Utils:ReturnPooledFrame(frame)
        end
        
        -- Force cleanup
        self:PerformMemoryCleanup()
        collectgarbage("collect")
        
        -- Report results
        local endTime = GetTime()
        local testDuration = (endTime - startTime) * 1000
        
        C_Timer.After(1.0, function()
            local endMemory = performanceData.memoryUsage
            local endFPS = performanceData.currentFPS
            
            DamiaUI.Engine:LogInfo("Stress Test Results:")
            DamiaUI.Engine:LogInfo("  Duration: %.2fms", testDuration)
            DamiaUI.Engine:LogInfo("  Memory: %.2fMB -> %.2fMB (change: %.2fMB)", 
                                  startMemory, endMemory, endMemory - startMemory)
            DamiaUI.Engine:LogInfo("  FPS: %.1f -> %.1f (change: %.1f)", 
                                  startFPS, endFPS, endFPS - startFPS)
            DamiaUI.Engine:LogInfo("  Frame Pooling: %d frames created and cleaned", #testFrames)
        end)
    end)
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Auto-initialize when engine is ready
DamiaUI.Events:RegisterCustomEvent("DAMIA_INITIALIZED", function()
    Performance:Initialize()
end, 1, "Performance_AutoInit")

-- Slash command for performance monitoring
SLASH_DAMIAPERFORMANCE1 = "/damiaperf"
SlashCmdList["DAMIAPERFORMANCE"] = function(msg)
    local command = (msg or ""):lower()
    
    if command == "report" or command == "" then
        Performance:PrintReport()
    elseif command == "reset" then
        Performance:Reset()
    elseif command == "cleanup" then
        Performance:ForceMemoryCleanup()
    elseif command == "panel" then
        -- Show performance panel if available
        if DamiaUI.PerformancePanel then
            DamiaUI.PerformancePanel:Toggle()
        else
            DamiaUI.Engine:LogInfo("Performance panel not available")
        end
    elseif command == "test" then
        -- Performance stress test
        Performance:RunStressTest()
    elseif command:match("^opt%s+(%d)$") then
        local level = tonumber(command:match("^opt%s+(%d)$"))
        Performance:SetManualOptimization(level)
    else
        DamiaUI.Engine:LogInfo("Performance Commands:")
        DamiaUI.Engine:LogInfo("  /damiaperf report - Show performance report")
        DamiaUI.Engine:LogInfo("  /damiaperf panel - Toggle performance panel")
        DamiaUI.Engine:LogInfo("  /damiaperf reset - Reset performance data")
        DamiaUI.Engine:LogInfo("  /damiaperf cleanup - Force memory cleanup")
        DamiaUI.Engine:LogInfo("  /damiaperf test - Run performance stress test")
        DamiaUI.Engine:LogInfo("  /damiaperf opt <0-3> - Set optimization level")
    end
end

DamiaUI.Engine:LogInfo("Performance optimization system loaded")