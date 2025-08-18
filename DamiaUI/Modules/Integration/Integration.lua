--[[
    DamiaUI Integration Module
    
    Main integration system that manages all third-party addon templates and
    auto-configuration. Provides unified API for addon integration management.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Initialize Integration module
local Integration = {}
DamiaUI.Integration = Integration

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type = type
local CreateFrame = CreateFrame
local C_Timer = C_Timer

-- Module state
local moduleInitialized = false
local templateModules = {}
local integrationFrame = nil

-- Integration configuration
local INTEGRATION_CONFIG = {
    enabled = true,
    autoConfiguration = true,
    verboseLogging = false,
    loadDelay = 2, -- Delay before starting integration system
    
    -- Template priorities
    templatePriority = {
        "WeakAurasTemplates",
        "DetailsTemplates", 
        "DBMTemplates"
    }
}

--[[
    Core Module Functions
]]

function Integration:Initialize()
    if moduleInitialized then
        return true
    end
    
    -- Check if integration is enabled
    if not INTEGRATION_CONFIG.enabled then
        DamiaUI:LogDebug("Integration system disabled")
        return false
    end
    
    -- Delay initialization to allow other systems to load
    C_Timer.After(INTEGRATION_CONFIG.loadDelay, function()
        self:DelayedInitialization()
    end)
    
    return true
end

function Integration:DelayedInitialization()
    -- Initialize template modules
    self:InitializeTemplateModules()
    
    -- Initialize auto-configuration system
    self:InitializeAutoConfiguration()
    
    -- Setup integration frame for events
    self:SetupIntegrationFrame()
    
    -- Create configuration interface
    self:CreateConfigurationInterface()
    
    moduleInitialized = true
    DamiaUI:LogDebug("Integration system fully initialized")
    
    -- Announce successful initialization
    if INTEGRATION_CONFIG.verboseLogging then
        DamiaUI:Print("DamiaUI Integration System ready")
    end
end

function Integration:InitializeTemplateModules()
    local initialized = 0
    
    -- Initialize template modules in priority order
    for _, moduleName in ipairs(INTEGRATION_CONFIG.templatePriority) do
        local module = self[moduleName]
        if module and type(module.Initialize) == "function" then
            local success = module:Initialize()
            if success then
                templateModules[moduleName] = module
                initialized = initialized + 1
                DamiaUI:LogDebug("Initialized template module: " .. moduleName)
            else
                DamiaUI:LogWarning("Failed to initialize template module: " .. moduleName)
            end
        else
            DamiaUI:LogWarning("Template module not found or invalid: " .. moduleName)
        end
    end
    
    DamiaUI:LogDebug(string.format("Initialized %d template modules", initialized))
end

function Integration:InitializeAutoConfiguration()
    if self.AutoConfig and type(self.AutoConfig.Initialize) == "function" then
        local success = self.AutoConfig:Initialize()
        if success then
            DamiaUI:LogDebug("Auto-configuration system initialized")
        else
            DamiaUI:LogWarning("Failed to initialize auto-configuration system")
        end
    else
        DamiaUI:LogWarning("Auto-configuration module not available")
    end
end

function Integration:SetupIntegrationFrame()
    -- Create frame for integration events
    integrationFrame = CreateFrame("Frame", "DamiaUIIntegrationFrame")
    
    -- Register for events that affect integrations
    integrationFrame:RegisterEvent("ADDON_LOADED")
    integrationFrame:RegisterEvent("PLAYER_LOGIN")
    integrationFrame:RegisterEvent("PLAYER_LOGOUT")
    integrationFrame:RegisterEvent("UI_SCALE_CHANGED")
    integrationFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    
    integrationFrame:SetScript("OnEvent", function(self, event, ...)
        Integration:OnIntegrationEvent(event, ...)
    end)
end

--[[
    Event Handlers
]]

function Integration:OnIntegrationEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        self:OnAddonLoaded(loadedAddon)
    elseif event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "PLAYER_LOGOUT" then
        self:OnPlayerLogout()
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        self:OnDisplayChanged()
    end
end

function Integration:OnAddonLoaded(addonName)
    -- Handle addon loading for template modules
    for moduleName, module in pairs(templateModules) do
        if module.OnAddonLoaded then
            module:OnAddonLoaded(addonName)
        end
    end
    
    -- Handle auto-configuration
    if self.AutoConfig and self.AutoConfig.OnAddonLoaded then
        self.AutoConfig:OnAddonLoaded(addonName)
    end
end

function Integration:OnPlayerLogin()
    -- Final integration setup after login
    C_Timer.After(3, function()
        self:PerformFinalSetup()
    end)
end

function Integration:OnPlayerLogout()
    -- Save any integration state before logout
    self:SaveIntegrationState()
end

function Integration:OnDisplayChanged()
    -- Update template positions for display changes
    self:UpdateTemplatePositions()
end

function Integration:PerformFinalSetup()
    -- Apply any pending configurations
    if self.AutoConfig and self.AutoConfig.ProcessDelayedConfigurations then
        self.AutoConfig:ProcessDelayedConfigurations()
    end
    
    -- Validate template applications
    self:ValidateTemplateApplications()
    
    DamiaUI:LogDebug("Integration final setup completed")
end

function Integration:SaveIntegrationState()
    -- Save state to be restored on next login
    local state = {
        appliedTemplates = {},
        configurationData = {},
        timestamp = time()
    }
    
    -- Collect state from template modules
    for moduleName, module in pairs(templateModules) do
        if module.GetState then
            state.appliedTemplates[moduleName] = module:GetState()
        end
    end
    
    -- Store in DamiaUI database
    if DamiaUI.db and DamiaUI.db.char then
        DamiaUI.db.char.integrationState = state
    end
    
    DamiaUI:LogDebug("Integration state saved")
end

function Integration:UpdateTemplatePositions()
    -- Update positions for all template modules
    for moduleName, module in pairs(templateModules) do
        if module.UpdatePositions then
            module:UpdatePositions()
        end
    end
    
    DamiaUI:LogDebug("Template positions updated for display change")
end

function Integration:ValidateTemplateApplications()
    -- Validate that templates were applied correctly
    local validationResults = {}
    
    for moduleName, module in pairs(templateModules) do
        if module.ValidateTemplates then
            validationResults[moduleName] = module:ValidateTemplates()
        end
    end
    
    -- Log validation results
    for moduleName, result in pairs(validationResults) do
        if result then
            DamiaUI:LogDebug("Template validation passed: " .. moduleName)
        else
            DamiaUI:LogWarning("Template validation failed: " .. moduleName)
        end
    end
end

--[[
    Template Management API
]]

function Integration:GetAvailableTemplates(addonName)
    local templates = {}
    
    for moduleName, module in pairs(templateModules) do
        if module.GetAvailableTemplates then
            local moduleTemplates = module:GetAvailableTemplates()
            if moduleTemplates then
                templates[moduleName] = moduleTemplates
            end
        end
    end
    
    return templates
end

function Integration:ApplyTemplate(moduleName, templateName, options)
    local module = templateModules[moduleName]
    if not module then
        return false, "Template module not found: " .. tostring(moduleName)
    end
    
    if module.ApplyTemplate then
        return module:ApplyTemplate(templateName, options)
    elseif module.InstallTemplate then
        return module:InstallTemplate(templateName, options)
    else
        return false, "Module does not support template application"
    end
end

function Integration:RemoveTemplate(moduleName, templateName)
    local module = templateModules[moduleName]
    if not module then
        return false, "Template module not found: " .. tostring(moduleName)
    end
    
    if module.RemoveTemplate then
        return module:RemoveTemplate(templateName)
    elseif module.UninstallTemplate then
        return module:UninstallTemplate(templateName)
    else
        return false, "Module does not support template removal"
    end
end

function Integration:RefreshAllTemplates()
    local results = {}
    
    for moduleName, module in pairs(templateModules) do
        if module.RefreshAllTemplates then
            results[moduleName] = module:RefreshAllTemplates()
        elseif module.RefreshConfiguration then
            results[moduleName] = module:RefreshConfiguration()
        end
    end
    
    return results
end

function Integration:ResetAllTemplates()
    local results = {}
    
    for moduleName, module in pairs(templateModules) do
        if module.ResetToDefaults then
            results[moduleName] = module:ResetToDefaults()
        end
    end
    
    -- Also reset auto-configuration
    if self.AutoConfig and self.AutoConfig.ResetAllConfigurations then
        results["AutoConfig"] = self.AutoConfig:ResetAllConfigurations()
    end
    
    return results
end

--[[
    Configuration Interface
]]

function Integration:CreateConfigurationInterface()
    -- Create main integration options panel
    local panel = CreateFrame("Frame", "DamiaUIIntegrationPanel")
    panel.name = "Integration"
    panel.parent = "DamiaUI"
    
    -- Panel title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Addon Integration")
    
    -- Panel description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Manage templates and auto-configuration for popular addons")
    desc:SetWidth(600)
    desc:SetWordWrap(true)
    
    -- Auto-configuration toggle
    local autoConfigCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoConfigCheck:SetPoint("TOPLEFT", 16, -70)
    autoConfigCheck.Text:SetText("Enable Auto-Configuration")
    autoConfigCheck:SetChecked(INTEGRATION_CONFIG.autoConfiguration)
    
    autoConfigCheck:SetScript("OnClick", function(self)
        INTEGRATION_CONFIG.autoConfiguration = self:GetChecked()
        
        if self:GetChecked() then
            DamiaUI:Print("Auto-configuration enabled")
        else
            DamiaUI:Print("Auto-configuration disabled")
        end
    end)
    
    -- Verbose logging toggle
    local verboseCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    verboseCheck:SetPoint("TOPLEFT", autoConfigCheck, "BOTTOMLEFT", 0, -8)
    verboseCheck.Text:SetText("Verbose Logging")
    verboseCheck:SetChecked(INTEGRATION_CONFIG.verboseLogging)
    
    verboseCheck:SetScript("OnClick", function(self)
        INTEGRATION_CONFIG.verboseLogging = self:GetChecked()
        
        if self:GetChecked() then
            DamiaUI:Print("Verbose integration logging enabled")
        else
            DamiaUI:Print("Verbose integration logging disabled")
        end
    end)
    
    -- Template module status
    local statusLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    statusLabel:SetPoint("TOPLEFT", 16, -140)
    statusLabel:SetText("Template Modules:")
    
    local yOffset = -160
    for moduleName, module in pairs(templateModules) do
        local status = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        status:SetPoint("TOPLEFT", 20, yOffset)
        
        local statusText = moduleName .. ": "
        if module.initialized then
            statusText = statusText .. "|cff00ff00Active|r"
        else
            statusText = statusText .. "|cffff0000Inactive|r"
        end
        
        status:SetText(statusText)
        yOffset = yOffset - 20
    end
    
    -- Action buttons
    local refreshButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    refreshButton:SetPoint("TOPLEFT", 16, yOffset - 20)
    refreshButton:SetSize(120, 24)
    refreshButton:SetText("Refresh All")
    
    refreshButton:SetScript("OnClick", function()
        local results = self:RefreshAllTemplates()
        DamiaUI:Print("Refreshed all templates")
    end)
    
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", refreshButton, "RIGHT", 8, 0)
    resetButton:SetSize(120, 24)
    resetButton:SetText("Reset All")
    
    resetButton:SetScript("OnClick", function()
        local results = self:ResetAllTemplates()
        DamiaUI:Print("Reset all templates to defaults")
    end)
    
    self.configPanel = panel
    
    -- Register child panels for template modules
    self:RegisterChildPanels()
end

function Integration:RegisterChildPanels()
    -- Register configuration panels for each template module
    for moduleName, module in pairs(templateModules) do
        if module.CreateConfigurationPanel then
            local childPanel = module:CreateConfigurationPanel()
            if childPanel then
                childPanel.parent = "DamiaUI Integration"
                DamiaUI:LogDebug("Registered config panel for: " .. moduleName)
            end
        end
    end
    
    -- Register auto-config panel
    if self.AutoConfig and self.AutoConfig.CreateConfigurationPanel then
        local autoConfigPanel = self.AutoConfig:CreateConfigurationPanel()
        if autoConfigPanel then
            autoConfigPanel.parent = "DamiaUI Integration"
            DamiaUI:LogDebug("Registered auto-config panel")
        end
    end
end

--[[
    Public API
]]

function Integration:IsInitialized()
    return moduleInitialized
end

function Integration:GetTemplateModules()
    return templateModules
end

function Integration:GetTemplateModule(moduleName)
    return templateModules[moduleName]
end

function Integration:IsModuleActive(moduleName)
    local module = templateModules[moduleName]
    return module and module.initialized
end

function Integration:GetIntegrationStats()
    local stats = {
        modulesActive = 0,
        templatesApplied = 0,
        addonsConfigured = 0
    }
    
    -- Count active modules
    for moduleName, module in pairs(templateModules) do
        if module.initialized then
            stats.modulesActive = stats.modulesActive + 1
        end
    end
    
    -- Get template statistics from modules
    for moduleName, module in pairs(templateModules) do
        if module.GetTemplateCount then
            stats.templatesApplied = stats.templatesApplied + module:GetTemplateCount()
        end
    end
    
    -- Get auto-configuration statistics
    if self.AutoConfig and self.AutoConfig.GetAppliedConfigurations then
        local configured = self.AutoConfig:GetAppliedConfigurations()
        for _ in pairs(configured) do
            stats.addonsConfigured = stats.addonsConfigured + 1
        end
    end
    
    return stats
end

function Integration:EnableModule(moduleName)
    if moduleName == "Integration" then
        INTEGRATION_CONFIG.enabled = true
        return self:Initialize()
    end
    
    local module = self[moduleName]
    if module and type(module.Initialize) == "function" then
        local success = module:Initialize()
        if success then
            templateModules[moduleName] = module
        end
        return success
    end
    
    return false
end

function Integration:DisableModule(moduleName)
    if moduleName == "Integration" then
        INTEGRATION_CONFIG.enabled = false
        moduleInitialized = false
        return true
    end
    
    local module = templateModules[moduleName]
    if module then
        if module.Shutdown then
            module:Shutdown()
        end
        templateModules[moduleName] = nil
        return true
    end
    
    return false
end

-- Utility function for other modules
function Integration:RegisterTemplateModule(moduleName, module)
    if type(module.Initialize) == "function" then
        self[moduleName] = module
        DamiaUI:LogDebug("Registered template module: " .. moduleName)
        
        -- Initialize if integration system is already running
        if moduleInitialized then
            local success = module:Initialize()
            if success then
                templateModules[moduleName] = module
            end
        end
        
        return true
    end
    
    return false
end

-- Initialize the integration system
DamiaUI.Integration = Integration