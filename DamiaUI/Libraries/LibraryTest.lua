--[[
DamiaUI Library Integration Test
Tests the core libraries to ensure they're functioning correctly
]]

local LibraryTest = {}

-- Test LibStub
function LibraryTest:TestLibStub()
    if not LibStub then
        return false, "LibStub not found"
    end
    
    -- Test basic functionality
    local testLib = LibStub:GetLibrary("LibStub", true)
    if not testLib then
        return false, "LibStub:GetLibrary failed"
    end
    
    return true, "LibStub working correctly"
end

-- Test CallbackHandler
function LibraryTest:TestCallbackHandler()
    local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0", true)
    if not CallbackHandler then
        return false, "CallbackHandler-1.0 not found"
    end
    
    -- Test creating a callback registry
    local testObj = {}
    CallbackHandler:New(testObj)
    
    if not testObj.RegisterCallback then
        return false, "CallbackHandler methods not added"
    end
    
    -- Test callback registration
    local callbackFired = false
    testObj:RegisterCallback("TestEvent", function() callbackFired = true end)
    testObj:Fire("TestEvent")
    
    if not callbackFired then
        return false, "Callback system not working"
    end
    
    return true, "CallbackHandler working correctly"
end

-- Test LibActionButton
function LibraryTest:TestLibActionButton()
    local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
    if not LibActionButton then
        return false, "LibActionButton-1.0 not found"
    end
    
    if not LibActionButton.CreateButton then
        return false, "LibActionButton:CreateButton method missing"
    end
    
    if not LibActionButton.RegisterCallback then
        return false, "LibActionButton:RegisterCallback method missing"
    end
    
    return true, "LibActionButton working correctly"
end

-- Test LibDataBroker
function LibraryTest:TestLibDataBroker()
    local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LibDataBroker then
        return false, "LibDataBroker-1.1 not found"
    end
    
    if not LibDataBroker.NewDataObject then
        return false, "LibDataBroker:NewDataObject method missing"
    end
    
    -- Test creating a data object
    local testDataObject = LibDataBroker:NewDataObject("TestObject", {
        type = "data_source",
        text = "Test",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    })
    
    if not testDataObject then
        return false, "Failed to create data object"
    end
    
    -- Test retrieving the data object
    local retrieved = LibDataBroker:GetDataObjectByName("TestObject")
    if retrieved ~= testDataObject then
        return false, "Failed to retrieve data object"
    end
    
    return true, "LibDataBroker working correctly"
end

-- Run all tests
function LibraryTest:RunAllTests()
    local tests = {
        {"LibStub", self.TestLibStub},
        {"CallbackHandler", self.TestCallbackHandler},
        {"LibActionButton", self.TestLibActionButton},
        {"LibDataBroker", self.TestLibDataBroker}
    }
    
    local results = {}
    local allPassed = true
    
    for _, test in ipairs(tests) do
        local name, testFunc = test[1], test[2]
        local success, message = testFunc(self)
        results[name] = {success = success, message = message}
        
        if not success then
            allPassed = false
        end
        
        print(string.format("DamiaUI Library Test [%s]: %s - %s", 
                          name, 
                          success and "PASS" or "FAIL", 
                          message))
    end
    
    return allPassed, results
end

-- Export for use by other modules
DamiaUI.LibraryTest = LibraryTest