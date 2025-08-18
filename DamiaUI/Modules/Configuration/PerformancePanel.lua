--[[
===============================================================================
Damia UI - Performance Configuration Panel
===============================================================================
Performance metrics display and configuration interface providing real-time
monitoring and control over the addon's performance optimization systems.

Features:
- Real-time performance metrics display
- Optimization level controls
- Memory usage monitoring
- FPS impact tracking
- Event throttling configuration
- Performance recommendations

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references
local CreateFrame = CreateFrame
local GetTime = GetTime
local C_Timer = C_Timer
local string = string
local math = math

-- Create Performance Panel module
local PerformancePanel = {}
DamiaUI.PerformancePanel = PerformancePanel

-- Panel configuration
local PANEL_WIDTH = 600
local PANEL_HEIGHT = 500
local UPDATE_INTERVAL = 0.5 -- Update display every 500ms
local HISTORY_DISPLAY_POINTS = 60 -- Show last 60 data points

-- UI elements
local performanceFrame = nil
local metricsDisplays = {}
local controlElements = {}
local chartFrames = {}

-- Display data
local displayData = {
    lastUpdate = 0,
    fpsHistory = {},
    memoryHistory = {},
    recommendations = {},
}

--[[
===============================================================================
PANEL CREATION AND INITIALIZATION
===============================================================================
--]]

-- Initialize performance panel
function PerformancePanel:Initialize()
    if performanceFrame then
        return -- Already initialized
    end
    
    DamiaUI.Engine:LogInfo("Initializing Performance Configuration Panel")
    
    self:CreatePanel()
    self:CreateMetricsDisplay()
    self:CreateControlsSection()
    self:CreateChartsSection()
    self:StartUpdateLoop()
    
    -- Register for events
    DamiaUI.Events:RegisterCustomEvent("DAMIA_PERFORMANCE_UPDATE", 
        function(event, data) self:OnPerformanceUpdate(data) end, 3, "PerformancePanel_Update")
    
    DamiaUI.Events:RegisterCustomEvent("DAMIA_MEMORY_WARNING", 
        function(event, memory) self:OnMemoryWarning(memory) end, 3, "PerformancePanel_MemoryWarning")
    
    DamiaUI.Engine:LogInfo("Performance panel initialized")
end

-- Create main panel frame
function PerformancePanel:CreatePanel()
    performanceFrame = CreateFrame("Frame", "DamiaUIPerformancePanel", UIParent)
    performanceFrame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    performanceFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    performanceFrame:SetFrameStrata("DIALOG")
    performanceFrame:SetFrameLevel(100)
    performanceFrame:Hide()
    
    -- Background
    local bg = performanceFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    
    -- Border
    local border = performanceFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.3, 0.3, 0.3, 1)
    border:SetPoint("TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Title
    local title = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", performanceFrame, "TOP", 0, -10)
    title:SetText("DamiaUI Performance Monitor")
    title:SetTextColor(1, 1, 1, 1)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, performanceFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", performanceFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    
    -- Make draggable
    performanceFrame:SetMovable(true)
    performanceFrame:EnableMouse(true)
    performanceFrame:RegisterForDrag("LeftButton")
    performanceFrame:SetScript("OnDragStart", performanceFrame.StartMoving)
    performanceFrame:SetScript("OnDragStop", performanceFrame.StopMovingOrSizing)
end

-- Create metrics display section
function PerformancePanel:CreateMetricsDisplay()
    local yOffset = -50
    
    -- Current Performance Section
    local perfHeader = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    perfHeader:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", 20, yOffset)
    perfHeader:SetText("Current Performance")
    perfHeader:SetTextColor(0.9, 0.9, 0.9, 1)
    
    yOffset = yOffset - 25
    
    -- FPS Display
    metricsDisplays.fps = self:CreateMetricDisplay("FPS", "0.0", 20, yOffset, "|cff00ff00")
    yOffset = yOffset - 20
    
    -- FPS Impact Display
    metricsDisplays.fpsImpact = self:CreateMetricDisplay("FPS Impact", "0.0%", 20, yOffset, "|cffFFD700")
    yOffset = yOffset - 20
    
    -- Memory Usage Display
    metricsDisplays.memory = self:CreateMetricDisplay("Memory Usage", "0.0 MB", 20, yOffset, "|cff00ccff")
    yOffset = yOffset - 20
    
    -- Optimization Level Display
    metricsDisplays.optLevel = self:CreateMetricDisplay("Optimization Level", "None", 20, yOffset, "|cffff9900")
    yOffset = yOffset - 30
    
    -- System Status Section
    local statusHeader = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusHeader:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", 20, yOffset)
    statusHeader:SetText("System Status")
    statusHeader:SetTextColor(0.9, 0.9, 0.9, 1)
    
    yOffset = yOffset - 25
    
    -- Performance Status
    metricsDisplays.perfStatus = self:CreateMetricDisplay("Performance", "Good", 20, yOffset, "|cff00ff00")
    yOffset = yOffset - 20
    
    -- Throttling Status
    metricsDisplays.throttling = self:CreateMetricDisplay("Event Throttling", "Normal", 20, yOffset, "|cff00ccff")
    yOffset = yOffset - 20
    
    -- Memory Status
    metricsDisplays.memStatus = self:CreateMetricDisplay("Memory Status", "Normal", 20, yOffset, "|cff00ff00")
end

-- Create individual metric display
function PerformancePanel:CreateMetricDisplay(label, value, x, y, color)
    local labelText = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", x, y)
    labelText:SetText(label .. ":")
    labelText:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local valueText = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("LEFT", labelText, "RIGHT", 10, 0)
    valueText:SetText(color .. value .. "|r")
    
    return {
        label = labelText,
        value = valueText,
        color = color,
    }
end

-- Create controls section
function PerformancePanel:CreateControlsSection()
    local xOffset = 320
    local yOffset = -50
    
    -- Controls Header
    local controlsHeader = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    controlsHeader:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", xOffset, yOffset)
    controlsHeader:SetText("Performance Controls")
    controlsHeader:SetTextColor(0.9, 0.9, 0.9, 1)
    
    yOffset = yOffset - 30
    
    -- Manual Optimization Level Control
    local optLabel = performanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optLabel:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", xOffset, yOffset)
    optLabel:SetText("Manual Optimization:")
    optLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    yOffset = yOffset - 25
    
    -- Optimization Level Buttons
    local optButtons = {}\n    for i = 0, 3 do\n        local optButton = CreateFrame(\"Button\", nil, performanceFrame, \"UIPanelButtonTemplate\")\n        optButton:SetSize(40, 25)\n        optButton:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset + (i * 45), yOffset)\n        optButton:SetText(tostring(i))\n        optButton:SetScript(\"OnClick\", function()\n            if DamiaUI.Performance then\n                DamiaUI.Performance:SetManualOptimization(i)\n                self:UpdateControlsDisplay()\n            end\n        end)\n        \n        optButtons[i] = optButton\n    end\n    \n    controlElements.optButtons = optButtons\n    \n    yOffset = yOffset - 40\n    \n    -- Memory Cleanup Button\n    local cleanupButton = CreateFrame(\"Button\", nil, performanceFrame, \"UIPanelButtonTemplate\")\n    cleanupButton:SetSize(120, 25)\n    cleanupButton:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset, yOffset)\n    cleanupButton:SetText(\"Force Cleanup\")\n    cleanupButton:SetScript(\"OnClick\", function()\n        if DamiaUI.Memory then\n            DamiaUI.Memory:ForceCleanup()\n            DamiaUI.Engine:LogInfo(\"Manual memory cleanup performed\")\n        end\n    end)\n    \n    controlElements.cleanupButton = cleanupButton\n    \n    yOffset = yOffset - 35\n    \n    -- Reset Statistics Button\n    local resetButton = CreateFrame(\"Button\", nil, performanceFrame, \"UIPanelButtonTemplate\")\n    resetButton:SetSize(120, 25)\n    resetButton:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset, yOffset)\n    resetButton:SetText(\"Reset Stats\")\n    resetButton:SetScript(\"OnClick\", function()\n        if DamiaUI.Performance then\n            DamiaUI.Performance:Reset()\n        end\n        if DamiaUI.Throttle then\n            DamiaUI.Throttle:ResetStatistics()\n        end\n        DamiaUI.Engine:LogInfo(\"Performance statistics reset\")\n    end)\n    \n    controlElements.resetButton = resetButton\n    \n    yOffset = yOffset - 35\n    \n    -- Throttling Controls\n    local throttleLabel = performanceFrame:CreateFontString(nil, \"OVERLAY\", \"GameFontNormal\")\n    throttleLabel:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset, yOffset)\n    throttleLabel:SetText(\"Event Throttling:\")\n    throttleLabel:SetTextColor(0.8, 0.8, 0.8, 1)\n    \n    yOffset = yOffset - 25\n    \n    -- Enable/Disable Throttling\n    local throttleToggle = CreateFrame(\"CheckButton\", nil, performanceFrame, \"InterfaceOptionsCheckButtonTemplate\")\n    throttleToggle:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset, yOffset)\n    throttleToggle:SetChecked(true)\n    throttleToggle:SetScript(\"OnClick\", function()\n        if DamiaUI.Throttle then\n            DamiaUI.Throttle:SetEnabled(throttleToggle:GetChecked())\n        end\n    end)\n    \n    local throttleToggleLabel = throttleToggle:CreateFontString(nil, \"OVERLAY\", \"GameFontNormalSmall\")\n    throttleToggleLabel:SetPoint(\"LEFT\", throttleToggle, \"RIGHT\", 5, 0)\n    throttleToggleLabel:SetText(\"Enabled\")\n    \n    controlElements.throttleToggle = throttleToggle\n    \n    yOffset = yOffset - 25\n    \n    -- Adaptive Throttling\n    local adaptiveToggle = CreateFrame(\"CheckButton\", nil, performanceFrame, \"InterfaceOptionsCheckButtonTemplate\")\n    adaptiveToggle:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", xOffset, yOffset)\n    adaptiveToggle:SetChecked(true)\n    adaptiveToggle:SetScript(\"OnClick\", function()\n        if DamiaUI.Throttle then\n            DamiaUI.Throttle:SetAdaptiveMode(adaptiveToggle:GetChecked())\n        end\n    end)\n    \n    local adaptiveToggleLabel = adaptiveToggle:CreateFontString(nil, \"OVERLAY\", \"GameFontNormalSmall\")\n    adaptiveToggleLabel:SetPoint(\"LEFT\", adaptiveToggle, \"RIGHT\", 5, 0)\n    adaptiveToggleLabel:SetText(\"Adaptive\")\n    \n    controlElements.adaptiveToggle = adaptiveToggle\nend\n\n-- Create charts section\nfunction PerformancePanel:CreateChartsSection()\n    local yOffset = -280\n    \n    -- Charts Header\n    local chartsHeader = performanceFrame:CreateFontString(nil, \"OVERLAY\", \"GameFontHighlight\")\n    chartsHeader:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", 20, yOffset)\n    chartsHeader:SetText(\"Performance Charts\")\n    chartsHeader:SetTextColor(0.9, 0.9, 0.9, 1)\n    \n    yOffset = yOffset - 25\n    \n    -- FPS Chart\n    chartFrames.fps = self:CreateChart(\"FPS\", 20, yOffset, 260, 80, \"|cff00ff00\")\n    \n    -- Memory Chart\n    chartFrames.memory = self:CreateChart(\"Memory (MB)\", 300, yOffset, 260, 80, \"|cff00ccff\")\n    \n    yOffset = yOffset - 100\n    \n    -- Recommendations Section\n    local recHeader = performanceFrame:CreateFontString(nil, \"OVERLAY\", \"GameFontHighlight\")\n    recHeader:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", 20, yOffset)\n    recHeader:SetText(\"Recommendations\")\n    recHeader:SetTextColor(0.9, 0.9, 0.9, 1)\n    \n    yOffset = yOffset - 20\n    \n    -- Recommendations display\n    metricsDisplays.recommendations = performanceFrame:CreateFontString(nil, \"OVERLAY\", \"GameFontNormalSmall\")\n    metricsDisplays.recommendations:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", 20, yOffset)\n    metricsDisplays.recommendations:SetWidth(PANEL_WIDTH - 40)\n    metricsDisplays.recommendations:SetJustifyH(\"LEFT\")\n    metricsDisplays.recommendations:SetText(\"No recommendations at this time.\")\n    metricsDisplays.recommendations:SetTextColor(0.9, 0.9, 0.6, 1)\nend\n\n-- Create individual chart\nfunction PerformancePanel:CreateChart(title, x, y, width, height, color)\n    local chartFrame = CreateFrame(\"Frame\", nil, performanceFrame)\n    chartFrame:SetPoint(\"TOPLEFT\", performanceFrame, \"TOPLEFT\", x, y)\n    chartFrame:SetSize(width, height)\n    \n    -- Chart background\n    local bg = chartFrame:CreateTexture(nil, \"BACKGROUND\")\n    bg:SetAllPoints()\n    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)\n    \n    -- Chart border\n    local border = chartFrame:CreateTexture(nil, \"BORDER\")\n    border:SetAllPoints()\n    border:SetColorTexture(0.4, 0.4, 0.4, 1)\n    \n    -- Chart title\n    local titleText = chartFrame:CreateFontString(nil, \"OVERLAY\", \"GameFontNormalSmall\")\n    titleText:SetPoint(\"TOP\", chartFrame, \"TOP\", 0, -5)\n    titleText:SetText(title)\n    titleText:SetTextColor(1, 1, 1, 1)\n    \n    -- Chart data lines (will be updated dynamically)\n    local dataLines = {}\n    \n    return {\n        frame = chartFrame,\n        title = titleText,\n        dataLines = dataLines,\n        color = color,\n        width = width,\n        height = height,\n        data = {},\n    }\nend\n\n--[[\n===============================================================================\nUPDATE AND DISPLAY FUNCTIONS\n===============================================================================\n--]]\n\n-- Start update loop\nfunction PerformancePanel:StartUpdateLoop()\n    local updateFrame = CreateFrame(\"Frame\")\n    updateFrame:SetScript(\"OnUpdate\", function()\n        local currentTime = GetTime()\n        \n        if currentTime - displayData.lastUpdate >= UPDATE_INTERVAL then\n            self:UpdateDisplay()\n            displayData.lastUpdate = currentTime\n        end\n    end)\nend\n\n-- Update all display elements\nfunction PerformancePanel:UpdateDisplay()\n    if not performanceFrame or not performanceFrame:IsVisible() then\n        return\n    end\n    \n    self:UpdateMetricsDisplay()\n    self:UpdateControlsDisplay()\n    self:UpdateChartsDisplay()\n    self:UpdateRecommendations()\nend\n\n-- Update metrics display\nfunction PerformancePanel:UpdateMetricsDisplay()\n    if not DamiaUI.Performance then\n        return\n    end\n    \n    local metrics = DamiaUI.Performance:GetMetrics()\n    local summary = DamiaUI.Performance:GetSummary()\n    \n    -- FPS\n    local fpsColor = \"|cff00ff00\" -- Green\n    if metrics.fps.current < 30 then\n        fpsColor = \"|cffff0000\" -- Red\n    elseif metrics.fps.current < 45 then\n        fpsColor = \"|cffFFD700\" -- Yellow\n    end\n    metricsDisplays.fps.value:SetText(fpsColor .. string.format(\"%.1f\", metrics.fps.current) .. \"|r\")\n    \n    -- FPS Impact\n    local impactColor = \"|cff00ff00\" -- Green\n    if metrics.fps.impact >= 2.0 then\n        impactColor = \"|cffff0000\" -- Red\n    elseif metrics.fps.impact >= 1.0 then\n        impactColor = \"|cffFFD700\" -- Yellow\n    end\n    metricsDisplays.fpsImpact.value:SetText(impactColor .. string.format(\"%.1f%%\", metrics.fps.impact) .. \"|r\")\n    \n    -- Memory\n    local memColor = \"|cff00ccff\" -- Blue\n    if metrics.memory.current >= 25 then\n        memColor = \"|cffff0000\" -- Red\n    elseif metrics.memory.current >= 20 then\n        memColor = \"|cffFFD700\" -- Yellow\n    end\n    metricsDisplays.memory.value:SetText(memColor .. string.format(\"%.1f MB\", metrics.memory.current) .. \"|r\")\n    \n    -- Optimization Level\n    local optLevels = {\"None\", \"Light\", \"Moderate\", \"Aggressive\"}\n    local optColor = \"|cffff9900\"\n    metricsDisplays.optLevel.value:SetText(optColor .. optLevels[metrics.optimization.level + 1] .. \"|r\")\n    \n    -- Performance Status\n    local statusColors = {\n        GOOD = \"|cff00ff00\",\n        DEGRADED = \"|cffFFD700\",\n        WARNING = \"|cffFF8C00\",\n        CRITICAL = \"|cffff0000\"\n    }\n    local statusColor = statusColors[summary.status] or \"|cff00ccff\"\n    metricsDisplays.perfStatus.value:SetText(statusColor .. summary.status .. \"|r\")\n    \n    -- Throttling Status\n    if DamiaUI.Throttle then\n        local throttleStats = DamiaUI.Throttle:GetStatistics()\n        local throttleLevel = throttleStats.performanceLevel or \"normal\"\n        local throttleColor = \"|cff00ccff\"\n        if throttleLevel == \"critical\" then\n            throttleColor = \"|cffff0000\"\n        elseif throttleLevel == \"low\" then\n            throttleColor = \"|cffFFD700\"\n        end\n        metricsDisplays.throttling.value:SetText(throttleColor .. throttleLevel .. \"|r\")\n    end\n    \n    -- Memory Status\n    local memStatusColor = \"|cff00ff00\" -- Normal\n    local memStatusText = \"Normal\"\n    if metrics.memory.current >= 25 then\n        memStatusColor = \"|cffff0000\"\n        memStatusText = \"Critical\"\n    elseif metrics.memory.current >= 20 then\n        memStatusColor = \"|cffFFD700\"\n        memStatusText = \"High\"\n    end\n    metricsDisplays.memStatus.value:SetText(memStatusColor .. memStatusText .. \"|r\")\nend\n\n-- Update controls display\nfunction PerformancePanel:UpdateControlsDisplay()\n    if not controlElements.optButtons or not DamiaUI.Performance then\n        return\n    end\n    \n    local metrics = DamiaUI.Performance:GetMetrics()\n    local currentLevel = metrics.optimization.level\n    \n    -- Update optimization level buttons\n    for level, button in pairs(controlElements.optButtons) do\n        if level == currentLevel then\n            button:SetText(\"|cffFFD700\" .. level .. \"|r\")\n        else\n            button:SetText(tostring(level))\n        end\n    end\n    \n    -- Update throttling toggles\n    if DamiaUI.Throttle and controlElements.throttleToggle then\n        local throttleStats = DamiaUI.Throttle:GetStatistics()\n        controlElements.throttleToggle:SetChecked(throttleStats.enabled)\n        controlElements.adaptiveToggle:SetChecked(throttleStats.adaptiveMode or false)\n    end\nend\n\n-- Update charts display\nfunction PerformancePanel:UpdateChartsDisplay()\n    if not DamiaUI.Performance then\n        return\n    end\n    \n    local metrics = DamiaUI.Performance:GetMetrics()\n    \n    -- Update FPS chart\n    if metrics.fps.history then\n        self:UpdateChart(chartFrames.fps, metrics.fps.history, \"fps\", 0, 120)\n    end\n    \n    -- Update Memory chart\n    if metrics.memory.history then\n        self:UpdateChart(chartFrames.memory, metrics.memory.history, \"memory\", 0, 30)\n    end\nend\n\n-- Update individual chart\nfunction PerformancePanel:UpdateChart(chart, historyData, dataKey, minValue, maxValue)\n    if not chart or not historyData or #historyData == 0 then\n        return\n    end\n    \n    -- Clear existing lines\n    for _, line in ipairs(chart.dataLines) do\n        line:Hide()\n    end\n    chart.dataLines = {}\n    \n    -- Get recent data points\n    local dataPoints = {}\n    local startIndex = math.max(1, #historyData - HISTORY_DISPLAY_POINTS + 1)\n    \n    for i = startIndex, #historyData do\n        local value = historyData[i][dataKey] or 0\n        table.insert(dataPoints, value)\n    end\n    \n    if #dataPoints < 2 then\n        return\n    end\n    \n    -- Calculate scale\n    local actualMin = math.huge\n    local actualMax = -math.huge\n    \n    for _, value in ipairs(dataPoints) do\n        actualMin = math.min(actualMin, value)\n        actualMax = math.max(actualMax, value)\n    end\n    \n    local rangeMin = math.min(minValue, actualMin)\n    local rangeMax = math.max(maxValue, actualMax)\n    local range = rangeMax - rangeMin\n    \n    if range == 0 then\n        range = 1\n    end\n    \n    -- Draw lines\n    for i = 2, #dataPoints do\n        local x1 = (i - 2) / (#dataPoints - 1) * (chart.width - 20) + 10\n        local y1 = (chart.height - 20) - ((dataPoints[i - 1] - rangeMin) / range) * (chart.height - 20) + 10\n        local x2 = (i - 1) / (#dataPoints - 1) * (chart.width - 20) + 10\n        local y2 = (chart.height - 20) - ((dataPoints[i] - rangeMin) / range) * (chart.height - 20) + 10\n        \n        local line = chart.frame:CreateTexture(nil, \"OVERLAY\")\n        line:SetColorTexture(0, 1, 0, 0.8) -- Green line\n        line:SetSize(math.max(1, math.sqrt((x2-x1)^2 + (y2-y1)^2)), 1)\n        line:SetPoint(\"BOTTOMLEFT\", chart.frame, \"BOTTOMLEFT\", x1, y1)\n        \n        -- Rotate line to connect points (simplified)\n        if math.abs(x2 - x1) > 0.1 then\n            line:SetWidth(math.abs(x2 - x1))\n            line:SetPoint(\"BOTTOMLEFT\", chart.frame, \"BOTTOMLEFT\", math.min(x1, x2), math.min(y1, y2))\n        end\n        \n        table.insert(chart.dataLines, line)\n    end\nend\n\n-- Update recommendations\nfunction PerformancePanel:UpdateRecommendations()\n    if not DamiaUI.Performance or not metricsDisplays.recommendations then\n        return\n    end\n    \n    local summary = DamiaUI.Performance:GetSummary()\n    local recommendations = summary.recommendations or {}\n    \n    if #recommendations == 0 then\n        metricsDisplays.recommendations:SetText(\"|cff00ff00No performance issues detected.|r\")\n    else\n        local recText = \"|cffFFD700Recommendations:\\n|r\"\n        for i, rec in ipairs(recommendations) do\n            recText = recText .. \"• \" .. rec\n            if i < #recommendations then\n                recText = recText .. \"\\n\"\n            end\n        end\n        metricsDisplays.recommendations:SetText(recText)\n    end\nend\n\n--[[\n===============================================================================\nEVENT HANDLERS\n===============================================================================\n--]]\n\n-- Handle performance updates\nfunction PerformancePanel:OnPerformanceUpdate(data)\n    -- Update display data if panel is visible\n    if performanceFrame and performanceFrame:IsVisible() then\n        -- Force immediate update for real-time feel\n        self:UpdateDisplay()\n    end\nend\n\n-- Handle memory warnings\nfunction PerformancePanel:OnMemoryWarning(memory)\n    if performanceFrame and performanceFrame:IsVisible() then\n        -- Flash the memory display or show warning\n        DamiaUI.Engine:LogWarning(\"Memory warning: %.2fMB\", memory)\n    end\nend\n\n--[[\n===============================================================================\nPUBLIC API FUNCTIONS\n===============================================================================\n--]]\n\n-- Show performance panel\nfunction PerformancePanel:Show()\n    if not performanceFrame then\n        self:Initialize()\n    end\n    \n    performanceFrame:Show()\n    self:UpdateDisplay()\n    \n    DamiaUI.Engine:LogDebug(\"Performance panel shown\")\nend\n\n-- Hide performance panel\nfunction PerformancePanel:Hide()\n    if performanceFrame then\n        performanceFrame:Hide()\n    end\nend\n\n-- Toggle performance panel\nfunction PerformancePanel:Toggle()\n    if not performanceFrame then\n        self:Show()\n        return\n    end\n    \n    if performanceFrame:IsVisible() then\n        self:Hide()\n    else\n        self:Show()\n    end\nend\n\n-- Check if panel is visible\nfunction PerformancePanel:IsVisible()\n    return performanceFrame and performanceFrame:IsVisible()\nend\n\n--[[\n===============================================================================\nINITIALIZATION\n===============================================================================\n--]]\n\n-- Auto-initialize when addon is ready\nDamiaUI.Events:RegisterCustomEvent(\"DAMIA_INITIALIZED\", function()\n    -- Panel will be initialized on first show\nend, 3, \"PerformancePanel_AutoInit\")\n\n-- Slash command for performance panel\nSLASH_DAMIAPERF1 = \"/damiaperf\"\nSLASH_DAMIAPERF2 = \"/damiaperformance\"\nSlashCmdList[\"DAMIAPERF\"] = function(msg)\n    PerformancePanel:Toggle()\nend\n\nDamiaUI.Engine:LogInfo(\"Performance configuration panel loaded\")"