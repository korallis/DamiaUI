--[[
    DamiaUI Integration Auto-Configuration System
    
    Automatically detects popular addons when they're loaded and applies
    DamiaUI-compatible configurations. Handles import/export of configurations
    for sharing DamiaUI-compatible addon setups.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Initialize Auto Configuration module
local AutoConfig = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.AutoConfig = AutoConfig

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsAddOnLoaded = IsAddOnLoaded
local GetTime = GetTime

-- Supported addon templates
local SUPPORTED_ADDONS = {
    ["WeakAuras"] = {
        templateModule = "WeakAurasTemplates",
        priority = 1,
        configDelay = 3, -- Wait 3 seconds after addon loads
        autoApply = true,
        checkFunction = function()
            return WeakAuras and WeakAuras.Import
        end
    },
    
    ["Details"] = {
        templateModule = "DetailsTemplates",
        priority = 1,
        configDelay = 2,
        autoApply = true,
        checkFunction = function()
            return _detalhes and _detalhes.GetCurrentInstance
        end
    },
    
    ["DBM-Core"] = {
        templateModule = "DBMTemplates",
        priority = 2,
        configDelay = 1,
        autoApply = true,
        checkFunction = function()
            return DBM and DBM.Options
        end
    },
    
    -- Additional supported addons
    ["Plater"] = {
        templateModule = "PlaterTemplates", -- Future implementation
        priority = 3,
        configDelay = 2,
        autoApply = false, -- Manual only for now
        checkFunction = function()
            return Plater and Plater.db
        end
    },
    
    ["ElvUI"] = {
        templateModule = "ElvUICompatibility", -- Future implementation
        priority = 4,
        configDelay = 5,
        autoApply = false, -- Manual only - potential conflicts
        checkFunction = function()
            return ElvUI and ElvUI[1]
        end
    }
}

-- Configuration queue for delayed processing
local configQueue = {}
local monitoredAddons = {}
local appliedConfigurations = {}

-- Export/import system
local exportData = {
    version = "1.0.0",
    configurations = {},
    metadata = {
        createdBy = "DamiaUI",
        createdAt = nil,
        playerClass = nil,
        playerRealm = nil,
        gameVersion = nil
    }
}

--[[
    Core Functions
]]

function AutoConfig:Initialize()
    self.initialized = false
    
    -- Setup addon monitoring
    self:SetupAddonMonitoring()
    
    -- Scan for already loaded addons
    self:ScanLoadedAddons()
    
    -- Setup configuration queue processor
    self:StartConfigurationProcessor()
    
    -- Initialize export/import system
    self:InitializeExportSystem()
    
    self.initialized = true
    DamiaUI:LogDebug("Auto-configuration system initialized")
    return true
end

function AutoConfig:SetupAddonMonitoring()
    -- Create monitoring frame
    local monitorFrame = CreateFrame("Frame", "DamiaUIAutoConfigMonitor")
    
    -- Monitor addon loading
    monitorFrame:RegisterEvent("ADDON_LOADED")
    monitorFrame:RegisterEvent("PLAYER_LOGIN")
    monitorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    monitorFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddonName = ...
            AutoConfig:OnAddonLoaded(loadedAddonName)
        elseif event == "PLAYER_LOGIN" then
            -- Final configuration scan
            C_Timer.After(5, function()
                AutoConfig:ProcessDelayedConfigurations()
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- World-specific configurations
            C_Timer.After(3, function()
                AutoConfig:ApplyWorldSpecificConfigurations()
            end)
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- Group change configurations (Details templates)
            AutoConfig:OnGroupChange()
        end
    end)
    
    self.monitorFrame = monitorFrame
end

function AutoConfig:ScanLoadedAddons()
    -- Scan currently loaded addons
    for addonName, addonInfo in pairs(SUPPORTED_ADDONS) do
        if IsAddOnLoaded(addonName) and addonInfo.checkFunction() then
            self:QueueAddonConfiguration(addonName, addonInfo)
        end
    end
    
    DamiaUI:LogDebug("Scanned loaded addons for auto-configuration")
end

function AutoConfig:StartConfigurationProcessor()
    -- Process configuration queue every second
    C_Timer.NewTicker(1, function()
        self:ProcessConfigurationQueue()
    end)
end

--[[
    Addon Detection and Queueing
]]

function AutoConfig:OnAddonLoaded(addonName)
    local addonInfo = SUPPORTED_ADDONS[addonName]
    if not addonInfo then
        return -- Not a supported addon
    end
    
    if monitoredAddons[addonName] then
        return -- Already monitoring
    end
    
    -- Queue for configuration
    self:QueueAddonConfiguration(addonName, addonInfo)
    monitoredAddons[addonName] = true
    
    DamiaUI:LogDebug("Queued addon for auto-configuration: " .. addonName)
end

function AutoConfig:QueueAddonConfiguration(addonName, addonInfo)
    if appliedConfigurations[addonName] then
        return -- Already configured
    end
    
    table.insert(configQueue, {
        addonName = addonName,
        addonInfo = addonInfo,
        queueTime = GetTime(),
        processed = false
    })
end

function AutoConfig:ProcessConfigurationQueue()
    local currentTime = GetTime()
    
    for i = #configQueue, 1, -1 do
        local item = configQueue[i]
        
        if not item.processed and currentTime - item.queueTime >= item.addonInfo.configDelay then
            if self:IsAddonReadyForConfiguration(item.addonName, item.addonInfo) then
                local success = self:ConfigureAddon(item.addonName, item.addonInfo)
                
                if success then
                    item.processed = true
                    appliedConfigurations[item.addonName] = true
                    table.remove(configQueue, i)
                    DamiaUI:LogDebug("Auto-configured addon: " .. item.addonName)
                end
            elseif currentTime - item.queueTime > 30 then
                -- Remove from queue after 30 seconds to avoid infinite waiting
                DamiaUI:LogWarning("Auto-configuration timeout: " .. item.addonName)
                table.remove(configQueue, i)
            end
        end
    end
end

function AutoConfig:IsAddonReadyForConfiguration(addonName, addonInfo)
    -- Check if addon is still loaded
    if not IsAddOnLoaded(addonName) then
        return false
    end
    
    -- Use addon-specific check function
    if addonInfo.checkFunction then
        return addonInfo.checkFunction()
    end
    
    return true
end

--[[
    Configuration Application
]]

function AutoConfig:ConfigureAddon(addonName, addonInfo)
    if not addonInfo.autoApply then
        DamiaUI:LogDebug("Auto-apply disabled for addon: " .. addonName)
        return false
    end
    
    -- Get the template module
    local templateModule = self:GetTemplateModule(addonInfo.templateModule)
    if not templateModule then
        DamiaUI:LogWarning("Template module not found: " .. addonInfo.templateModule)
        return false
    end
    
    -- Check if module is initialized
    if not templateModule.initialized then
        local success = templateModule:Initialize()
        if not success then
            DamiaUI:LogWarning("Failed to initialize template module: " .. addonInfo.templateModule)
            return false
        end
    end
    
    -- Apply configuration based on addon type
    return self:ApplyAddonConfiguration(addonName, templateModule, addonInfo)
end

function AutoConfig:GetTemplateModule(moduleName)
    if not DamiaUI.Integration then
        return nil
    end
    
    return DamiaUI.Integration[moduleName]
end

function AutoConfig:ApplyAddonConfiguration(addonName, templateModule, addonInfo)
    local success = false
    
    if addonName == "WeakAuras" then
        success = self:ConfigureWeakAuras(templateModule)
    elseif addonName == "Details" then
        success = self:ConfigureDetails(templateModule)
    elseif addonName == "DBM-Core" then
        success = self:ConfigureDBM(templateModule)
    else
        DamiaUI:LogWarning("No configuration handler for addon: " .. addonName)
        return false
    end
    
    if success then
        -- Store configuration metadata
        self:StoreConfigurationMetadata(addonName, templateModule)
    end
    
    return success
end

function AutoConfig:ConfigureWeakAuras(templateModule)
    local playerClass = select(2, UnitClass("player"))
    
    -- Install recommended templates
    local success, results = templateModule:InstallRecommendedTemplates(playerClass)
    
    if success and results then
        local installedCount = 0
        for templateKey, result in pairs(results) do
            if result.success then
                installedCount = installedCount + 1
            end
        end
        
        if installedCount > 0 then
            DamiaUI:Print(string.format("Auto-configured WeakAuras: %d templates installed", installedCount))
            return true
        end
    end
    
    return false
end

function AutoConfig:ConfigureDetails(templateModule)
    -- Auto-configure based on current group type
    local success = templateModule:AutoConfigureForGroup()
    
    if success then
        DamiaUI:Print("Auto-configured Details! meter positioning")
        return true
    end
    
    return false
end

function AutoConfig:ConfigureDBM(templateModule)
    -- Apply default DBM template
    local success, message = templateModule:ApplyTemplate("default")
    
    if success then
        DamiaUI:Print("Auto-configured DBM positioning and styling")
        return true
    end
    
    DamiaUI:LogDebug("DBM auto-configuration failed: " .. tostring(message))
    return false
end

--[[
    Event Handlers
]]

function AutoConfig:ProcessDelayedConfigurations()
    -- Process any remaining configurations after login
    for addonName, addonInfo in pairs(SUPPORTED_ADDONS) do
        if IsAddOnLoaded(addonName) and not appliedConfigurations[addonName] then
            if self:IsAddonReadyForConfiguration(addonName, addonInfo) then
                self:ConfigureAddon(addonName, addonInfo)
            end
        end
    end
end

function AutoConfig:ApplyWorldSpecificConfigurations()
    -- Apply configurations that require world data
    local inInstance = IsInInstance()
    local instanceType = select(2, IsInInstance())
    
    -- Adjust configurations based on instance type
    if inInstance then
        self:ApplyInstanceConfigurations(instanceType)
    end
end

function AutoConfig:ApplyInstanceConfigurations(instanceType)
    -- Apply instance-specific configurations
    if instanceType == "raid" then
        self:ConfigureForRaid()
    elseif instanceType == "party" then
        self:ConfigureForDungeon()
    elseif instanceType == "pvp" then
        self:ConfigureForPvP()
    end
end

function AutoConfig:ConfigureForRaid()
    -- Apply raid-specific configurations
    if appliedConfigurations["Details"] then
        local detailsModule = self:GetTemplateModule("DetailsTemplates")
        if detailsModule then
            detailsModule:ApplyTemplate("raid")
        end
    end
    
    DamiaUI:LogDebug("Applied raid configurations")
end

function AutoConfig:ConfigureForDungeon()
    -- Apply dungeon-specific configurations
    if appliedConfigurations["Details"] then
        local detailsModule = self:GetTemplateModule("DetailsTemplates")
        if detailsModule then
            detailsModule:ApplyTemplate("party")
        end
    end
    
    DamiaUI:LogDebug("Applied dungeon configurations")
end

function AutoConfig:ConfigureForPvP()
    -- Apply PvP-specific configurations
    DamiaUI:LogDebug("Applied PvP configurations")
end

function AutoConfig:OnGroupChange()
    -- Handle group composition changes
    if appliedConfigurations["Details"] then
        local detailsModule = self:GetTemplateModule("DetailsTemplates")
        if detailsModule then
            -- Auto-configure for new group type
            C_Timer.After(1, function()
                detailsModule:AutoConfigureForGroup()
            end)
        end
    end
end

--[[
    Configuration Storage and Metadata
]]

function AutoConfig:StoreConfigurationMetadata(addonName, templateModule)
    if not exportData.configurations[addonName] then
        exportData.configurations[addonName] = {}
    end
    
    exportData.configurations[addonName] = {
        applied = true,
        appliedAt = time(),
        templateModule = templateModule.name or "Unknown",
        version = templateModule.version or "Unknown",
        damiaUIVersion = DamiaUI.version
    }
end

--[[
    Export/Import System
]]

function AutoConfig:InitializeExportSystem()
    exportData.metadata.createdAt = time()
    exportData.metadata.playerClass = select(2, UnitClass("player"))
    exportData.metadata.playerRealm = GetRealmName()
    exportData.metadata.gameVersion = DamiaUI.gameVersion.gameType
end

function AutoConfig:ExportConfiguration()
    -- Generate export string for sharing
    local exportString = self:SerializeConfiguration(exportData)
    
    if exportString then
        -- Create export frame for displaying the string
        self:ShowExportFrame(exportString)
        return exportString
    end
    
    return nil
end

function AutoConfig:SerializeConfiguration(data)
    local success, serialized = pcall(function()
        return DamiaUI:Serialize(data)
    end)
    
    if success then
        -- Encode for sharing (base64 or similar)
        return "!DAMIAUI:CONFIG:1!" .. serialized .. "!END!"
    end
    
    return nil
end

function AutoConfig:ImportConfiguration(importString)
    if not importString or type(importString) ~= "string" then
        return false, "Invalid import string"
    end
    
    -- Validate import string format
    if not importString:match("^!DAMIAUI:CONFIG:1!") then
        return false, "Invalid format"
    end
    
    -- Extract data
    local dataString = importString:match("^!DAMIAUI:CONFIG:1!(.+)!END!$")
    if not dataString then
        return false, "Malformed import string"
    end
    
    -- Deserialize
    local success, data = pcall(function()
        return DamiaUI:Deserialize(dataString)
    end)
    
    if not success then
        return false, "Failed to deserialize data"
    end
    
    -- Apply imported configuration
    return self:ApplyImportedConfiguration(data)
end

function AutoConfig:ApplyImportedConfiguration(importedData)
    if not importedData or not importedData.configurations then
        return false, "No configuration data found"
    end
    
    local appliedCount = 0
    
    for addonName, configData in pairs(importedData.configurations) do
        if SUPPORTED_ADDONS[addonName] and IsAddOnLoaded(addonName) then
            local templateModule = self:GetTemplateModule(SUPPORTED_ADDONS[addonName].templateModule)
            if templateModule then
                local success = self:ApplyAddonConfiguration(addonName, templateModule, SUPPORTED_ADDONS[addonName])
                if success then
                    appliedCount = appliedCount + 1
                end
            end
        end
    end
    
    if appliedCount > 0 then
        DamiaUI:Print(string.format("Imported configurations for %d addons", appliedCount))
        return true, string.format("Applied %d configurations", appliedCount)
    end
    
    return false, "No configurations could be applied"
end

function AutoConfig:ShowExportFrame(exportString)
    -- Create export display frame
    local frame = CreateFrame("Frame", "DamiaUIConfigExportFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText("DamiaUI Configuration Export")
    
    -- Scrollable text area
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -23, 4)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetText(exportString)
    editBox:SetCursorPosition(0)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    frame:Show()
end

--[[
    Configuration Panel
]]

function AutoConfig:CreateConfigurationPanel()
    local panel = CreateFrame("Frame", "DamiaUIAutoConfigPanel")
    panel.name = "Auto Configuration"
    panel.parent = "DamiaUI"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Auto Configuration")
    
    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Automatic configuration system for popular addons")
    desc:SetWidth(600)
    desc:SetWordWrap(true)
    
    -- Status display
    local statusLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    statusLabel:SetPoint("TOPLEFT", 16, -80)
    statusLabel:SetText("Configured Addons:")
    
    local yOffset = -100
    for addonName, addonInfo in pairs(SUPPORTED_ADDONS) do
        local status = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        status:SetPoint("TOPLEFT", 20, yOffset)
        
        local statusText = addonName .. ": "
        if IsAddOnLoaded(addonName) then
            if appliedConfigurations[addonName] then
                statusText = statusText .. "|cff00ff00Configured|r"
            else
                statusText = statusText .. "|cffffff00Loaded, not configured|r"
            end
        else
            statusText = statusText .. "|cff666666Not loaded|r"
        end
        
        status:SetText(statusText)
        yOffset = yOffset - 20
    end
    
    -- Export button
    local exportButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportButton:SetPoint("TOPLEFT", 16, yOffset - 20)
    exportButton:SetSize(150, 24)
    exportButton:SetText("Export Configuration")
    
    exportButton:SetScript("OnClick", function()
        local exportString = self:ExportConfiguration()
        if exportString then
            DamiaUI:Print("Configuration exported successfully")
        else
            DamiaUI:Print("Failed to export configuration")
        end
    end)
    
    -- Import button
    local importButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importButton:SetPoint("LEFT", exportButton, "RIGHT", 8, 0)
    importButton:SetSize(150, 24)
    importButton:SetText("Import Configuration")
    
    importButton:SetScript("OnClick", function()
        self:ShowImportFrame()
    end)
    
    return panel
end

function AutoConfig:ShowImportFrame()
    -- Create import frame (similar to export frame)
    local frame = CreateFrame("Frame", "DamiaUIConfigImportFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText("DamiaUI Configuration Import")
    
    -- Import instructions
    local instructions = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 8, -8)
    instructions:SetText("Paste the configuration string below:")
    instructions:SetWidth(480)
    instructions:SetWordWrap(true)
    
    -- Text input area
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", -4, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -23, 30)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(true)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Import button
    local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    importButton:SetSize(100, 22)
    importButton:SetText("Import")
    
    importButton:SetScript("OnClick", function()
        local importString = editBox:GetText()
        local success, message = self:ImportConfiguration(importString)
        
        if success then
            DamiaUI:Print("Configuration imported successfully")
        else
            DamiaUI:Print("Failed to import configuration: " .. tostring(message))
        end
        
        frame:Hide()
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    frame:Show()
end

--[[
    Public API
]]

function AutoConfig:GetSupportedAddons()
    return SUPPORTED_ADDONS
end

function AutoConfig:GetAppliedConfigurations()
    return appliedConfigurations
end

function AutoConfig:IsAddonConfigured(addonName)
    return appliedConfigurations[addonName] == true
end

function AutoConfig:ManuallyConfigureAddon(addonName)
    local addonInfo = SUPPORTED_ADDONS[addonName]
    if not addonInfo then
        return false, "Addon not supported"
    end
    
    if not IsAddOnLoaded(addonName) then
        return false, "Addon not loaded"
    end
    
    local success = self:ConfigureAddon(addonName, addonInfo)
    
    if success then
        return true, "Configuration applied"
    else
        return false, "Configuration failed"
    end
end

function AutoConfig:ResetAddonConfiguration(addonName)
    local addonInfo = SUPPORTED_ADDONS[addonName]
    if not addonInfo then
        return false
    end
    
    local templateModule = self:GetTemplateModule(addonInfo.templateModule)
    if templateModule and templateModule.ResetToDefaults then
        local success = templateModule:ResetToDefaults()
        
        if success then
            appliedConfigurations[addonName] = nil
            if exportData.configurations[addonName] then
                exportData.configurations[addonName] = nil
            end
        end
        
        return success
    end
    
    return false
end

-- Initialize when called
if DamiaUI.Integration then
    DamiaUI.Integration.AutoConfig = AutoConfig
end