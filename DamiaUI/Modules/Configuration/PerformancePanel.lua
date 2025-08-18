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
    local optButtons = {}
    for i = 0, 3 do
        local optButton = CreateFrame("Button", nil, performanceFrame, "UIPanelButtonTemplate")
        optButton:SetSize(40, 25)
        optButton:SetPoint("TOPLEFT", performanceFrame, "TOPLEFT", xOffset + (i * 45), yOffset)
        optButton:SetText(tostring(i))
        optButton:SetScript("OnClick", function()
            if DamiaUI.Performance then
                DamiaUI.Performance:SetManualOptimization(i)
                self:UpdateControlsDisplay()
            end
        end)
        
        optButtons[i] = optButton
    end
    
    controlElements.optButtons = optButtons
end"