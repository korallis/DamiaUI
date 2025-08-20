local addonName, DamiaUI = ...

-- Interface Options Panel Management
DamiaUI.InterfacePanel = {}
local InterfacePanel = DamiaUI.InterfacePanel

local panelFrame
local subPanels = {}

-- Create the main interface panel
function InterfacePanel:Create()
    if panelFrame then
        return panelFrame
    end
    
    -- Create main frame
    panelFrame = CreateFrame("Frame", "DamiaUIOptionsPanel", UIParent)
    panelFrame.name = "DamiaUI"
    
    -- Register with Interface Options
    self:RegisterWithBlizzard()
    
    -- Create panel content
    self:CreateContent()
    
    return panelFrame
end

-- Register with Blizzard's Interface Options
function InterfacePanel:RegisterWithBlizzard()
    -- Handle different WoW versions
    if InterfaceOptions_AddCategory then
        -- Legacy Interface Options (pre-Dragonflight)
        panelFrame.okay = function(self) 
            DamiaUI.Settings:SaveSettings() 
        end
        panelFrame.cancel = function(self) 
            DamiaUI.Settings:CancelSettings() 
        end
        panelFrame.default = function(self) 
            DamiaUI.Settings:ResetSettings() 
        end
        
        InterfaceOptions_AddCategory(panelFrame)
        
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        -- Modern Settings system (Dragonflight+)
        local category = Settings.RegisterCanvasLayoutCategory(panelFrame, "DamiaUI", "DamiaUI")
        category.ID = "DamiaUI"
        Settings.RegisterAddOnCategory(category)
        
    else
        -- Fallback: Create our own settings access
        DamiaUI.Debug("Unable to register with Interface Options, creating standalone access")
        self:CreateStandaloneAccess()
    end
end

-- Create standalone settings access if Interface Options unavailable
function InterfacePanel:CreateStandaloneAccess()
    -- Create a minimap button or slash command access
    SLASH_DAMIAUI1 = "/damiaui"
    SLASH_DAMIAUI2 = "/dui"
    SlashCmdList["DAMIAUI"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "settings" or msg == "config" or msg == "" then
            self:Show()
        else
            print("|cffCC8010DamiaUI|r: Use /damiaui or /dui to open settings")
        end
    end
end

-- Create the panel content
function InterfacePanel:CreateContent()
    local panel = panelFrame
    
    -- Background
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Header section
    self:CreateHeader(panel)
    
    -- Module toggles section
    self:CreateModuleToggles(panel)
    
    -- Quick settings section
    self:CreateQuickSettings(panel)
    
    -- Action buttons
    self:CreateActionButtons(panel)
    
    -- Status information
    self:CreateStatusInfo(panel)
end

-- Create header section
function InterfacePanel:CreateHeader(parent)
    -- Main title
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", parent, "TOP", 0, -20)
    title:SetText("|cffCC8010DamiaUI|r")
    
    -- Subtitle
    local subtitle = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -10)
    subtitle:SetText("Modern UI Replacement for World of Warcraft")
    
    -- Version
    local version = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    version:SetPoint("TOP", subtitle, "BOTTOM", 0, -5)
    version:SetTextColor(0.7, 0.7, 0.7)
    version:SetText("Version: " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "Development"))
    
    -- Separator line
    local separator = parent:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOP", version, "BOTTOM", 0, -15)
    separator:SetSize(400, 1)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    
    return separator
end

-- Create module toggle section
function InterfacePanel:CreateModuleToggles(parent)
    local startY = -100
    
    -- Section title
    local sectionTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    sectionTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, startY)
    sectionTitle:SetText("Modules")
    
    -- Module definitions
    local modules = {
        {
            key = "actionbars",
            name = "Action Bars",
            desc = "Enhanced action bar system with improved styling and positioning",
            icon = "Interface\\Icons\\INV_Misc_Gear_02",
        },
        {
            key = "unitframes", 
            name = "Unit Frames",
            desc = "Redesigned player, target, and party frames with modern styling",
            icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze",
        },
        {
            key = "minimap",
            name = "Minimap",
            desc = "Enhanced minimap with additional features and cleaner appearance",
            icon = "Interface\\Icons\\INV_Misc_Map_01",
        },
        {
            key = "chat",
            name = "Chat System",
            desc = "Improved chat frame with modern features and styling",
            icon = "Interface\\Icons\\INV_Letter_18",
        },
        {
            key = "tooltips",
            name = "Tooltips",
            desc = "Enhanced tooltips with additional information and better formatting",
            icon = "Interface\\Icons\\INV_Misc_Note_01",
        },
        {
            key = "auras",
            name = "Auras",
            desc = "Buff and debuff display with improved positioning and styling",
            icon = "Interface\\Icons\\Spell_Holy_MindVision",
        },
    }
    
    local yOffset = startY - 30
    local checkboxes = {}
    
    for i, module in ipairs(modules) do
        -- Module container
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
        container:SetSize(450, 30)
        
        -- Module icon
        local icon = container:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", container, "LEFT", 0, 0)
        icon:SetSize(24, 24)
        icon:SetTexture(module.icon)
        
        -- Checkbox
        local checkbox = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        checkbox:SetSize(24, 24)
        
        -- Module name
        local nameText = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        nameText:SetText(module.name)
        
        -- Module description
        local descText = container:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
        descText:SetWidth(300)
        descText:SetJustifyH("LEFT")
        descText:SetTextColor(0.7, 0.7, 0.7)
        descText:SetText(module.desc)
        
        -- Checkbox functionality
        checkbox:SetScript("OnClick", function(self)
            local db, charDB, globalDB = DamiaUI.Settings:GetDB()
            local enabled = self:GetChecked()
            
            db.modules[module.key] = enabled
            DamiaUI.Settings:ToggleModule(module.key, enabled)
            
            -- Visual feedback
            if enabled then
                nameText:SetTextColor(1, 1, 1)
                descText:SetTextColor(0.8, 0.8, 0.8)
            else
                nameText:SetTextColor(0.5, 0.5, 0.5)
                descText:SetTextColor(0.4, 0.4, 0.4)
            end
        end)
        
        checkbox:SetScript("OnShow", function(self)
            local db, charDB, globalDB = DamiaUI.Settings:GetDB()
            local enabled = db.modules[module.key]
            self:SetChecked(enabled)
            
            if enabled then
                nameText:SetTextColor(1, 1, 1)
                descText:SetTextColor(0.8, 0.8, 0.8)
            else
                nameText:SetTextColor(0.5, 0.5, 0.5)
                descText:SetTextColor(0.4, 0.4, 0.4)
            end
        end)
        
        checkboxes[module.key] = checkbox
        yOffset = yOffset - 45
    end
    
    panelFrame.moduleCheckboxes = checkboxes
    return yOffset
end

-- Create quick settings section
function InterfacePanel:CreateQuickSettings(parent)
    local startY = -350
    
    -- Section title
    local sectionTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    sectionTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, startY)
    sectionTitle:SetText("Quick Settings")
    
    local yOffset = startY - 30
    
    -- Pixel Perfect
    local pixelPerfectCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    pixelPerfectCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    pixelPerfectCheck.Text:SetText("Pixel Perfect Scaling")
    pixelPerfectCheck.tooltipText = "Ensure UI elements align to pixel boundaries for crisp rendering"
    
    pixelPerfectCheck:SetScript("OnClick", function(self)
        local db, charDB, globalDB = DamiaUI.Settings:GetDB()
        db.general.pixelPerfect = self:GetChecked()
    end)
    
    pixelPerfectCheck:SetScript("OnShow", function(self)
        local db, charDB, globalDB = DamiaUI.Settings:GetDB()
        self:SetChecked(db.general.pixelPerfect)
    end)
    
    yOffset = yOffset - 25
    
    -- Class Colors
    local classColorsCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    classColorsCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    classColorsCheck.Text:SetText("Use Class Colors")
    classColorsCheck.tooltipText = "Color unit frames and player names by class"
    
    classColorsCheck:SetScript("OnClick", function(self)
        local db, charDB, globalDB = DamiaUI.Settings:GetDB()
        db.unitframes.classColors = self:GetChecked()
    end)
    
    classColorsCheck:SetScript("OnShow", function(self)
        local db, charDB, globalDB = DamiaUI.Settings:GetDB()
        self:SetChecked(db.unitframes.classColors)
    end)
    
    -- Store references
    panelFrame.pixelPerfectCheck = pixelPerfectCheck
    panelFrame.classColorsCheck = classColorsCheck
    
    return yOffset
end

-- Create action buttons
function InterfacePanel:CreateActionButtons(parent)
    local yPos = -450
    
    -- Reset All button
    local resetButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yPos)
    resetButton:SetSize(120, 24)
    resetButton:SetText("Reset All")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("DAMIAUI_RESET_SETTINGS")
    end)
    
    -- Reload UI button  
    local reloadButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    reloadButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    reloadButton:SetSize(120, 24)
    reloadButton:SetText("Reload UI")
    reloadButton:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    -- Advanced Settings button
    local advancedButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    advancedButton:SetPoint("LEFT", reloadButton, "RIGHT", 10, 0)
    advancedButton:SetSize(120, 24)
    advancedButton:SetText("Advanced...")
    advancedButton:SetScript("OnClick", function()
        print("|cffCC8010DamiaUI|r: Advanced settings coming in future update!")
    end)
end

-- Create status information
function InterfacePanel:CreateStatusInfo(parent)
    local yPos = -500
    
    -- Status section
    local statusTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statusTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yPos)
    statusTitle:SetText("Status:")
    statusTitle:SetTextColor(0.8, 0.8, 0.8)
    
    local statusText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", statusTitle, "RIGHT", 10, 0)
    statusText:SetText("All systems operational")
    statusText:SetTextColor(0, 1, 0)
    
    -- Profile information
    local profileTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileTitle:SetPoint("TOPLEFT", statusTitle, "BOTTOMLEFT", 0, -10)
    profileTitle:SetText("Current Profile:")
    profileTitle:SetTextColor(0.8, 0.8, 0.8)
    
    local profileText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    profileText:SetPoint("LEFT", profileTitle, "RIGHT", 10, 0)
    profileText:SetText("Default")
    profileText:SetTextColor(1, 1, 1)
    
    -- Update status on show
    panelFrame:SetScript("OnShow", function(self)
        local db, charDB, globalDB = DamiaUI.Settings:GetDB()
        if globalDB then
            profileText:SetText(globalDB.currentProfile or "Default")
        end
        
        -- Update all interactive elements
        if self.moduleCheckboxes then
            for _, checkbox in pairs(self.moduleCheckboxes) do
                if checkbox.GetScript and checkbox:GetScript("OnShow") then
                    checkbox:GetScript("OnShow")(checkbox)
                end
            end
        end
        
        if self.pixelPerfectCheck and self.pixelPerfectCheck:GetScript("OnShow") then
            self.pixelPerfectCheck:GetScript("OnShow")(self.pixelPerfectCheck)
        end
        
        if self.classColorsCheck and self.classColorsCheck:GetScript("OnShow") then
            self.classColorsCheck:GetScript("OnShow")(self.classColorsCheck)
        end
    end)
end

-- Show the panel
function InterfacePanel:Show()
    if panelFrame then
        if InterfaceOptionsFrame_OpenToCategory then
            -- Legacy method
            InterfaceOptionsFrame_OpenToCategory(panelFrame)
        elseif Settings and Settings.OpenToCategory then
            -- Modern method
            Settings.OpenToCategory("DamiaUI")
        else
            -- Fallback: show our frame directly
            panelFrame:Show()
        end
    end
end

-- Hide the panel
function InterfacePanel:Hide()
    if panelFrame then
        panelFrame:Hide()
    end
end

-- Initialize the interface panel
function InterfacePanel:Initialize()
    self:Create()
    DamiaUI.Debug("Interface panel initialized")
end