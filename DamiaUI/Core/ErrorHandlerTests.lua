--[[
===============================================================================
Damia UI - Error Handler Testing Module
===============================================================================
Test suite for the comprehensive error handling system. This module provides
various test scenarios to verify error classification, recovery mechanisms,
safe mode activation, and configuration repair functionality.

This file is for development/testing purposes only and should be removed or
disabled in production builds.

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Only load tests in debug mode
if not DamiaUI or not DamiaUI.ErrorHandler then
    return
end

-- Create test module
local ErrorTests = {}
DamiaUI.ErrorTests = ErrorTests

-- Test configuration
local testConfig = {
    enableTests = false, -- Set to true to enable testing
    runOnStartup = false,
    testResults = {},
    currentTest = nil
}

-- Test scenarios
local testScenarios = {
    {
        name = "Configuration Error Test",
        category = "config_error",
        description = "Tests configuration validation and recovery",
        testFunction = function()
            -- Attempt to set invalid configuration
            local success = DamiaUI.Config:Set("unitframes.player.scale", "invalid_string")
            return not success, "Should reject invalid scale value"
        end
    },
    {
        name = "Nil Reference Error Test", 
        category = "nil_error",
        description = "Tests handling of nil reference errors",
        testFunction = function()
            local success, result = DamiaUI.ErrorHandler:SafeCall(function()
                local nilValue = nil
                return nilValue.nonExistentProperty -- This should cause an error
            end, "ErrorTests", { operation = "nil_test" })
            return not success, "Should catch nil reference error"
        end
    },
    {
        name = "Event Handler Error Test",
        category = "event_error", 
        description = "Tests event handler error recovery",
        testFunction = function()
            -- Register a failing event handler
            local errorOccurred = false
            DamiaUI.Events:RegisterCustomEvent("TEST_EVENT", function()
                error("Intentional test error")
            end, 5, "FailingTestHandler")
            
            -- Fire the event and see if it's handled
            DamiaUI.Events:Fire("TEST_EVENT")
            
            -- Check if error was logged
            local recentErrors = DamiaUI.ErrorHandler:GetRecentErrors(1)
            local hasError = #recentErrors > 0 and 
                            recentErrors[1].message:find("Intentional test error")
            
            -- Clean up
            DamiaUI.Events:UnregisterCustomEvent("TEST_EVENT", "FailingTestHandler")
            
            return hasError, "Should log event handler error"
        end
    },
    {
        name = "Performance Monitoring Test",
        category = "performance",
        description = "Tests performance monitoring and slow operation detection",
        testFunction = function()
            local success, result = DamiaUI.ErrorHandler:SafeCall(function()
                -- Simulate slow operation
                local startTime = GetTime()
                while GetTime() - startTime < 0.1 do
                    -- Busy wait for 100ms
                end
                return true
            end, "ErrorTests", { operation = "slow_test" })
            
            -- Check if performance issue was logged
            local recentErrors = DamiaUI.ErrorHandler:GetRecentErrors(5, DamiaUI.ErrorHandler.SEVERITY.LOW)
            local hasPerformanceWarning = false
            
            for _, error in ipairs(recentErrors) do
                if error.category == DamiaUI.ErrorHandler.CATEGORY.PERFORMANCE then
                    hasPerformanceWarning = true
                    break
                end
            end
            
            return hasPerformanceWarning, "Should detect slow operation"
        end
    },
    {
        name = "Configuration Corruption Recovery Test",
        category = "config_corruption",
        description = "Tests configuration corruption detection and repair",
        testFunction = function()
            -- Simulate configuration corruption
            local database = DamiaUI.Config:GetDatabase()
            if not database then
                return false, "Database not available"
            end
            
            -- Backup original profiles
            local originalProfiles = DamiaUI.Utils:CopyTable(database.profiles)
            
            -- Corrupt the profiles
            database.profiles = nil
            
            -- Test repair functionality
            local repaired, issues, repairs = DamiaUI.ErrorHandler:ValidateAndRepairConfiguration()
            
            -- Restore original profiles
            database.profiles = originalProfiles
            
            return repaired and #issues > 0, "Should detect and repair configuration corruption"
        end
    },
    {
        name = "Safe Mode Activation Test",
        category = "safe_mode",
        description = "Tests safe mode activation and deactivation",
        testFunction = function()
            -- Test safe mode activation
            local activated = DamiaUI.SafeMode:Activate("Test activation")
            local isActive = DamiaUI.SafeMode:IsActive()
            
            -- Test deactivation
            local deactivated = false
            if isActive then
                deactivated = DamiaUI.SafeMode:Deactivate()
            end
            
            return activated and isActive and deactivated, "Should activate and deactivate safe mode"
        end
    }
}

--[[
===============================================================================
TEST EXECUTION FUNCTIONS
===============================================================================
--]]

-- Run a single test scenario
function ErrorTests:RunTest(scenario)
    if not scenario or not scenario.testFunction then
        return false, "Invalid test scenario"
    end
    
    testConfig.currentTest = scenario.name
    
    print(string.format("|cff00ccff[%s] Running test: %s|r", addonName, scenario.name))
    print(string.format("|cff888888%s|r", scenario.description))
    
    local testStartTime = GetTime()
    local success, passed, message = pcall(scenario.testFunction)
    local testDuration = GetTime() - testStartTime
    
    local result = {
        name = scenario.name,
        category = scenario.category,
        success = success,
        passed = success and passed,
        message = message or (success and "Test completed" or "Test execution failed"),
        duration = testDuration,
        timestamp = GetTime()
    }
    
    table.insert(testConfig.testResults, result)
    
    -- Print result
    if result.passed then
        print(string.format("|cff00ff00✓ PASS|r %s (%.1fms)", result.message, testDuration * 1000))
    else
        print(string.format("|cffff0000✗ FAIL|r %s (%.1fms)", result.message, testDuration * 1000))
    end
    
    testConfig.currentTest = nil
    return result.passed, result.message
end

-- Run all test scenarios
function ErrorTests:RunAllTests()
    if not testConfig.enableTests then
        print(string.format("|cffff8800[%s] Error handler testing is disabled|r", addonName))
        return false
    end
    
    print(string.format("|cff00ccff[%s] Running Error Handler Test Suite|r", addonName))
    print(string.format("|cff888888Total tests: %d|r", #testScenarios))
    
    -- Clear previous results
    testConfig.testResults = {}
    
    local passedCount = 0
    local totalTime = GetTime()
    
    for i, scenario in ipairs(testScenarios) do
        local passed, message = self:RunTest(scenario)
        if passed then
            passedCount = passedCount + 1
        end
        
        -- Brief pause between tests
        if i < #testScenarios then
            C_Timer.After(0.1, function() end)
        end
    end
    
    totalTime = GetTime() - totalTime
    
    -- Print summary
    print(string.format("|cff00ccff[%s] Test Suite Complete|r", addonName))
    print(string.format("|cffffffff  Passed: %d/%d tests|r", passedCount, #testScenarios))
    print(string.format("|cffffffff  Duration: %.1fms|r", totalTime * 1000))
    
    if passedCount == #testScenarios then
        print("|cff00ff00  All tests passed! ✓|r")
    else
        print(string.format("|cffff8800  %d test(s) failed ⚠|r", #testScenarios - passedCount))
    end
    
    return passedCount == #testScenarios
end

-- Run specific test by name
function ErrorTests:RunTestByName(testName)
    if not testConfig.enableTests then
        print(string.format("|cffff8800[%s] Error handler testing is disabled|r", addonName))
        return false
    end
    
    for _, scenario in ipairs(testScenarios) do
        if scenario.name == testName or scenario.category == testName then
            return self:RunTest(scenario)
        end
    end
    
    print(string.format("|cffff0000[%s] Test not found: %s|r", addonName, testName))
    return false
end

-- Get test results
function ErrorTests:GetTestResults()
    return testConfig.testResults
end

-- Get test summary
function ErrorTests:GetTestSummary()
    local summary = {
        totalTests = #testConfig.testResults,
        passedTests = 0,
        failedTests = 0,
        categories = {},
        averageDuration = 0,
        totalDuration = 0
    }
    
    for _, result in ipairs(testConfig.testResults) do
        if result.passed then
            summary.passedTests = summary.passedTests + 1
        else
            summary.failedTests = summary.failedTests + 1
        end
        
        summary.totalDuration = summary.totalDuration + result.duration
        
        if not summary.categories[result.category] then
            summary.categories[result.category] = { passed = 0, failed = 0 }
        end
        
        if result.passed then
            summary.categories[result.category].passed = summary.categories[result.category].passed + 1
        else
            summary.categories[result.category].failed = summary.categories[result.category].failed + 1
        end
    end
    
    if summary.totalTests > 0 then
        summary.averageDuration = summary.totalDuration / summary.totalTests
    end
    
    return summary
end

--[[
===============================================================================
INTERACTIVE TEST COMMANDS
===============================================================================
--]]

-- Enable/disable testing
function ErrorTests:EnableTesting(enabled)
    testConfig.enableTests = enabled
    print(string.format("|cff00ccff[%s] Error handler testing %s|r", 
                       addonName, enabled and "enabled" or "disabled"))
end

-- Print available tests
function ErrorTests:ListTests()
    print(string.format("|cff00ccff[%s] Available Error Handler Tests:|r", addonName))
    for i, scenario in ipairs(testScenarios) do
        print(string.format("|cffffffff  %d. %s|r", i, scenario.name))
        print(string.format("|cff888888     %s|r", scenario.description))
    end
end

-- Simulate an error for testing recovery
function ErrorTests:SimulateError(errorType, severity)
    if not testConfig.enableTests then
        print("|cffff8800Testing is disabled|r")
        return
    end
    
    errorType = errorType or "test"
    severity = severity or DamiaUI.ErrorHandler.SEVERITY.MEDIUM
    
    local errorMessages = {
        config = "Test configuration error - invalid setting detected",
        combat = "Test combat error - protected function called during combat",
        event = "Test event error - event handler callback failed",
        frame = "Test frame error - attempt to index nil frame",
        memory = "Test memory error - allocation failed",
        performance = "Test performance error - operation exceeded time limit"
    }
    
    local message = errorMessages[errorType] or ("Test " .. errorType .. " error")
    
    DamiaUI.ErrorHandler:ReportError(
        message,
        DamiaUI.ErrorHandler.CATEGORY.UNKNOWN,
        severity,
        "ErrorTests"
    )
    
    print(string.format("|cff00ccff[%s] Simulated %s error with severity %d|r", 
                       addonName, errorType, severity))
end

--[[
===============================================================================
SLASH COMMAND INTEGRATION
===============================================================================
--]]

-- Register test commands
if DamiaUI.Engine and DamiaUI.Engine.RegisterChatCommand then
    DamiaUI.Engine:RegisterChatCommand("damiatest", function(input)
        if not input or input:trim() == "" then
            ErrorTests:ListTests()
            return
        end
        
        local command, args = input:match("^(%w+)%s*(.*)")
        command = (command or ""):lower()
        args = args or ""
        
        if command == "enable" then
            ErrorTests:EnableTesting(true)
        elseif command == "disable" then
            ErrorTests:EnableTesting(false)
        elseif command == "run" then
            if args:trim() == "" then
                ErrorTests:RunAllTests()
            else
                ErrorTests:RunTestByName(args:trim())
            end
        elseif command == "simulate" then
            local errorType, severity = args:match("^(%w+)%s*(%d*)")
            severity = tonumber(severity) or DamiaUI.ErrorHandler.SEVERITY.MEDIUM
            ErrorTests:SimulateError(errorType, severity)
        elseif command == "summary" then
            local summary = ErrorTests:GetTestSummary()
            print(string.format("|cff00ccff[%s] Test Summary:|r", addonName))
            print(string.format("  Total: %d, Passed: %d, Failed: %d", 
                               summary.totalTests, summary.passedTests, summary.failedTests))
        elseif command == "list" then
            ErrorTests:ListTests()
        else
            print("|cff00ccffError Handler Test Commands:|r")
            print("  /damiatest enable - Enable testing")
            print("  /damiatest disable - Disable testing")  
            print("  /damiatest run [test_name] - Run tests")
            print("  /damiatest simulate [error_type] [severity] - Simulate error")
            print("  /damiatest summary - Show test results summary")
            print("  /damiatest list - List available tests")
        end
    end)
end

--[[
===============================================================================
INITIALIZATION
===============================================================================
--]]

-- Initialize test module
function ErrorTests:Initialize()
    -- Only initialize if error handler is available
    if not DamiaUI.ErrorHandler then
        return false
    end
    
    print(string.format("|cff00ccff[%s] Error Handler Test Suite loaded|r", addonName))
    print("|cff888888Use /damiatest to run error handling tests|r")
    
    -- Auto-run tests if configured
    if testConfig.runOnStartup and testConfig.enableTests then
        C_Timer.After(2, function()
            ErrorTests:RunAllTests()
        end)
    end
    
    return true
end

-- Auto-initialize when loaded
C_Timer.After(0.5, function()
    ErrorTests:Initialize()
end)