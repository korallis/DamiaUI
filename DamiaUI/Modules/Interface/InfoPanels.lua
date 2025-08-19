--[[
    DamiaUI - Information Panels Module
    
    Manages information display panels with LibDataBroker integration.
    Creates cockpit-style information display following the viewport-first design philosophy.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tonumber, tostring = type, tonumber, tostring
local string = string
local strformat = string.format
local math = math
local mathfloor = mathfloor
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local GetAddOnMetadata = GetAddOnMetadata
local IsAddOnLoaded = IsAddOnLoaded

-- Initialize info panels module
local InfoPanels = {}
DamiaUI.Interface = DamiaUI.Interface or {}
DamiaUI.Interface.InfoPanels = InfoPanels

-- Module state
local Aurora
local LibDataBroker
local isInitialized = false
local panels = {}
local dataObjects = {}

-- Info panel configuration based on viewport-first design
local PANEL_CONFIG = {
    -- Bottom panel positions (complementing chat and action bars)
    positions = {
        bottomLeft = { x = -200, y = -300 },
        bottomCenter = { x = 0, y = -300 },
        bottomRight = { x = 200, y = -300 },
        topLeft = { x = -400, y = 250 },
        topRight = { x = 400, y = 250 }
    },
    
    dimensions = {
        width = 180,
        height = 20,
        spacing = 4,
        padding = 8
    },
    
    appearance = {
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
        textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
    },
    
    behavior = {
        updateInterval = 2.0,
        hideInCombat = false,
        fadeAlpha = 0.6,
        clickToConfig = true
    },
    
    -- Default panel layout
    layout = {
        bottomLeft = { "currency", "durability" },
        bottomCenter = { "coordinates", "framerate" },
        bottomRight = { "memory", "latency" },
        topLeft = {},
        topRight = {}
    }
}

-- Built-in data providers
local BUILTIN_DATA_OBJECTS = {
    framerate = {
        name = "FPS",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        type = "data source",
        text = "0 fps",
        value = 0,
        OnClick = function() end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Frame Rate")
            tooltip:AddLine("Current: " .. GetFramerate() .. " fps")
            tooltip:Show()
        end
    },
    
    memory = {
        name = "Memory",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        type = "data source", 
        text = "0 MB",
        value = 0,
        OnClick = function()
            collectgarbage("collect")
        end,
        OnTooltipShow = function(tooltip)
            local memory = GetAddOnMemoryUsage(addonName)
            tooltip:AddLine("Memory Usage")
            tooltip:AddLine(strformat("DamiaUI: %.2f MB", memory / 1024))
            tooltip:AddLine("Click to run garbage collection")
            tooltip:Show()
        end
    },
    
    latency = {
        name = "Latency",
        icon = "Interface\\Icons\\INV_Misc_Net_01", 
        type = "data source",
        text = "0ms",
        value = 0,
        OnTooltipShow = function(tooltip)
            local _, _, lagHome, lagWorld = GetNetStats()
            tooltip:AddLine("Network Latency")
            tooltip:AddLine("Home: " .. lagHome .. "ms")
            tooltip:AddLine("World: " .. lagWorld .. "ms")
            tooltip:Show()
        end
    },
    
    coordinates = {
        name = "Coordinates",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        type = "data source",
        text = "0, 0",
        value = 0,
        OnTooltipShow = function(tooltip)
            local mapID = C_Map.GetBestMapForUnit("player")
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if position then
                local x, y = position:GetXY()
                tooltip:AddLine("Player Coordinates")
                tooltip:AddLine(strformat("X: %.1f, Y: %.1f", x * 100, y * 100))
            else
                tooltip:AddLine("Coordinates unavailable")
            end
            tooltip:Show()
        end
    },
    
    durability = {
        name = "Durability",
        icon = "Interface\\Icons\\INV_Hammer_20",
        type = "data source",
        text = "100%",
        value = 100,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Equipment Durability")
            local lowest = 100
            for slot = 1, 18 do
                local current, maximum = GetInventoryItemDurability(slot)
                if current and maximum and maximum > 0 then
                    local percent = (current / maximum) * 100
                    if percent < lowest then
                        lowest = percent
                    end
                end
            end
            tooltip:AddLine(strformat("Lowest: %.0f%%", lowest))
            tooltip:Show()
        end
    },
    
    currency = {
        name = "Currency",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        type = "data source",
        text = "0g",
        value = 0,
        OnTooltipShow = function(tooltip)
            local money = GetMoney()
            local gold = mathfloor(money / 10000)
            local silver = mathfloor((money % 10000) / 100)
            local copper = money % 100
            
            tooltip:AddLine("Currency")
            tooltip:AddLine(strformat("%dg %ds %dc", gold, silver, copper))
            tooltip:Show()
        end
    }
}

--[[
    Positioning System
    Following the centered viewport-first design
]]
local function GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    return (centerX + offsetX) / uiScale, (centerY + offsetY) / uiScale
end

--[[
    Panel Creation and Management
]]
local function CreateInfoPanel(panelName, position, dataObjects)
    local panel = CreateFrame("Frame", "DamiaUI_InfoPanel_" .. panelName, UIParent)
    local config = PANEL_CONFIG
    
    -- Set panel dimensions and position
    panel:SetSize(config.dimensions.width, config.dimensions.height)
    local x, y = GetCenterPosition(position.x, position.y)
    panel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    
    -- Create background
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(
        config.appearance.backgroundColor.r,
        config.appearance.backgroundColor.g,
        config.appearance.backgroundColor.b,
        config.appearance.backgroundColor.a
    )
    panel.background = bg
    
    -- Create border
    local border = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    border:SetAllPoints(panel)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    border:SetBackdropBorderColor(
        config.appearance.borderColor.r,
        config.appearance.borderColor.g,
        config.appearance.borderColor.b,
        config.appearance.borderColor.a
    )
    panel.border = border
    
    -- Create text display
    local text = panel:CreateFontString(nil, "OVERLAY")
    text:SetFont(config.appearance.font, config.appearance.fontSize, config.appearance.fontFlags)
    text:SetTextColor(
        config.appearance.textColor.r,
        config.appearance.textColor.g,
        config.appearance.textColor.b,
        config.appearance.textColor.a
    )
    text:SetPoint("CENTER", panel, "CENTER")
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    panel.text = text
    
    -- Store data objects for this panel
    panel.dataObjects = dataObjects or {}
    panel.currentIndex = 1
    panel.panelName = panelName
    
    -- Set up click handling
    panel:EnableMouse(true)
    panel:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            -- Cycle through data objects
            if #self.dataObjects > 1 then
                self.currentIndex = (self.currentIndex % #self.dataObjects) + 1
                InfoPanels:UpdatePanel(panelName)
            end
        elseif button == "RightButton" then
            -- Show context menu or config
            if config.behavior.clickToConfig then
                InfoPanels:ShowConfigMenu(panelName, self)
            end
        end
    end)
    
    -- Set up tooltip
    panel:SetScript("OnEnter", function(self)
        local currentObject = self.dataObjects[self.currentIndex]
        if currentObject and currentObject.OnTooltipShow then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            currentObject.OnTooltipShow(GameTooltip)
        end
    end)
    
    panel:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Apply Aurora styling if available
    if Aurora and Aurora.Skin and Aurora.Skin.FrameWidget then
        Aurora.Skin.FrameWidget(panel)
    end
    
    panels[panelName] = panel
    return panel
end

--[[
    Data Management
]]
local function InitializeBuiltinDataObjects()
    -- Register built-in data objects with LibDataBroker if available
    if LibDataBroker then
        for name, obj in pairs(BUILTIN_DATA_OBJECTS) do
            if not LibDataBroker:GetDataObjectByName(name) then
                dataObjects[name] = LibDataBroker:NewDataObject(name, obj)
            end
        end
    else
        -- Use built-in objects directly
        dataObjects = BUILTIN_DATA_OBJECTS
    end
end

local function UpdateBuiltinData()
    -- Update framerate
    if dataObjects.framerate then
        local fps = GetFramerate()
        dataObjects.framerate.value = fps
        dataObjects.framerate.text = strformat("%.0f fps", fps)
    end
    
    -- Update memory
    if dataObjects.memory then
        UpdateAddOnMemoryUsage()
        local memory = GetAddOnMemoryUsage(addonName) / 1024
        dataObjects.memory.value = memory
        dataObjects.memory.text = strformat("%.1f MB", memory)
    end
    
    -- Update latency
    if dataObjects.latency then
        local _, _, lagHome, lagWorld = GetNetStats()
        local avgLag = (lagHome + lagWorld) / 2
        dataObjects.latency.value = avgLag
        dataObjects.latency.text = strformat("%dms", avgLag)
    end
    
    -- Update coordinates
    if dataObjects.coordinates then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if position then
                local x, y = position:GetXY()
                dataObjects.coordinates.text = strformat("%.1f, %.1f", x * 100, y * 100)
            end
        end
    end
    
    -- Update durability
    if dataObjects.durability then
        local lowest = 100
        for slot = 1, 18 do
            local current, maximum = GetInventoryItemDurability(slot)
            if current and maximum and maximum > 0 then
                local percent = (current / maximum) * 100
                if percent < lowest then
                    lowest = percent
                end
            end
        end
        dataObjects.durability.value = lowest
        dataObjects.durability.text = strformat("%.0f%%", lowest)
    end
    
    -- Update currency
    if dataObjects.currency then
        local money = GetMoney()
        local gold = mathfloor(money / 10000)
        dataObjects.currency.value = gold
        if gold >= 10000 then
            dataObjects.currency.text = strformat("%.0fk", gold / 1000)
        else
            dataObjects.currency.text = strformat("%dg", gold)
        end
    end
end

--[[
    Panel Updates
]]
function InfoPanels:UpdatePanel(panelName)
    local panel = panels[panelName]
    if not panel or not panel.dataObjects or #panel.dataObjects == 0 then
        return
    end
    
    local currentObject = panel.dataObjects[panel.currentIndex]
    if currentObject then
        if currentObject.text then
            panel.text:SetText(currentObject.text)
        elseif currentObject.value then
            panel.text:SetText(tostring(currentObject.value))
        else
            panel.text:SetText(currentObject.name or "N/A")
        end
        
        -- Update color based on value if needed
        local color = PANEL_CONFIG.appearance.textColor
        if currentObject.name == "durability" and currentObject.value < 25 then
            color = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 } -- Red for low durability
        elseif currentObject.name == "latency" and currentObject.value > 200 then
            color = { r = 1.0, g = 0.5, b = 0.0, a = 1.0 } -- Orange for high latency
        end
        
        panel.text:SetTextColor(color.r, color.g, color.b, color.a)
    end
end

function InfoPanels:UpdateAllPanels()
    UpdateBuiltinData()
    
    for panelName, panel in pairs(panels) do
        self:UpdatePanel(panelName)
    end
end

--[[
    Combat State Management
]]
local function UpdateCombatVisibility(inCombat)
    local config = PANEL_CONFIG.behavior
    
    for _, panel in pairs(panels) do
        if inCombat and config.hideInCombat then
            panel:Hide()
        elseif inCombat and config.fadeAlpha then
            panel:SetAlpha(config.fadeAlpha)
        else
            panel:Show()
            panel:SetAlpha(1.0)
        end
    end
end

--[[
    Configuration Management
]]
function InfoPanels:ShowConfigMenu(panelName, panel)
    -- Simple configuration menu (expandable)
    -- Configuration menu logging removed
end

function InfoPanels:UpdateConfiguration(newConfig)
    if type(newConfig) ~= "table" then
        return
    end
    
    -- Merge configuration
    for key, value in pairs(newConfig) do
        if PANEL_CONFIG[key] then
            if type(value) == "table" and type(PANEL_CONFIG[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    PANEL_CONFIG[key][subKey] = subValue
                end
            else
                PANEL_CONFIG[key] = value
            end
        end
    end
    
    -- Recreate panels with new configuration
    self:Refresh()
end

function InfoPanels:GetConfiguration()
    return PANEL_CONFIG
end

--[[
    Public API
]]
function InfoPanels:Initialize()
    if isInitialized then
        return true
    end
    
    -- Get library references
    Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora
    LibDataBroker = DamiaUI.Libraries and DamiaUI.Libraries.LibDataBroker
    
    -- Initialize data objects
    InitializeBuiltinDataObjects()
    
    -- Create panels based on configuration
    for panelName, position in pairs(PANEL_CONFIG.positions) do
        local panelObjects = PANEL_CONFIG.layout[panelName]
        if panelObjects and #panelObjects > 0 then
            local objects = {}
            for _, objName in ipairs(panelObjects) do
                if dataObjects[objName] then
                    table.insert(objects, dataObjects[objName])
                end
            end
            
            if #objects > 0 then
                CreateInfoPanel(panelName, position, objects)
            end
        end
    end
    
    -- Start update timer
    self.updateTimer = C_Timer.NewTicker(PANEL_CONFIG.behavior.updateInterval, function()
        self:UpdateAllPanels()
    end)
    
    isInitialized = true
    DamiaUI:LogDebug("InfoPanels module initialized")
    return true
end

function InfoPanels:Refresh()
    -- Clear existing panels
    for panelName, panel in pairs(panels) do
        panel:Hide()
        panel:SetParent(nil)
    end
    panels = {}
    
    -- Cancel update timer
    if self.updateTimer then
        self.updateTimer:Cancel()
    end
    
    -- Reinitialize
    isInitialized = false
    self:Initialize()
end

function InfoPanels:UpdatePositions()
    for panelName, panel in pairs(panels) do
        local position = PANEL_CONFIG.positions[panelName]
        if position then
            local x, y = GetCenterPosition(position.x, position.y)
            panel:ClearAllPoints()
            panel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
    end
end

function InfoPanels:SetCombatState(inCombat)
    UpdateCombatVisibility(inCombat)
end

function InfoPanels:GetPanel(panelName)
    return panels[panelName]
end

function InfoPanels:RegisterDataObject(name, dataObject)
    if LibDataBroker then
        dataObjects[name] = LibDataBroker:NewDataObject(name, dataObject)
    else
        dataObjects[name] = dataObject
    end
end

--[[
    Event Handlers
]]
local function OnInfoPanelEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        InfoPanels:SetCombatState(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        InfoPanels:SetCombatState(false)
    elseif event == "UI_SCALE_CHANGED" then
        C_Timer.After(0.1, function()
            InfoPanels:UpdatePositions()
        end)
    elseif event == "PLAYER_MONEY" then
        -- Update currency immediately
        if dataObjects.currency then
            local money = GetMoney()
            local gold = mathfloor(money / 10000)
            dataObjects.currency.value = gold
            if gold >= 10000 then
                dataObjects.currency.text = strformat("%.0fk", gold / 1000)
            else
                dataObjects.currency.text = strformat("%dg", gold)
            end
            InfoPanels:UpdatePanel("bottomLeft")
        end
    end
end

-- Register events if DamiaUI event system is available
if DamiaUI and DamiaUI.Events then
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        InfoPanels:Initialize()
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^interface%.infopanels%.") then
            local configPart = key:match("interface%.infopanels%.(.+)")
            if configPart then
                InfoPanels:UpdateConfiguration({[configPart] = newValue})
            end
        end
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", function(event, inCombat)
        InfoPanels:SetCombatState(inCombat)
    end, 2)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_SCALE_CHANGED", function()
        InfoPanels:UpdatePositions()
    end, 2)
end

-- Fallback event registration
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:SetScript("OnEvent", OnInfoPanelEvent)

-- Initialize on load if DamiaUI is ready
if DamiaUI and DamiaUI.IsReady then
    C_Timer.After(1.5, function()
        InfoPanels:Initialize()
    end)
end

return InfoPanels