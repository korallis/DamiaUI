--[[
    DamiaUI Details! Integration Templates
    
    Pre-configured Details! templates with window configurations optimized for DamiaUI.
    Provides DPS/HPS meter positioning and Aurora theme integration.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Initialize Details Templates module
local DetailsTemplates = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.DetailsTemplates = DetailsTemplates

-- Local references for performance
local _G = _G
local _detalhes = _G._detalhes
local pairs, ipairs = pairs, ipairs
local type = type
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsAddOnLoaded = IsAddOnLoaded

-- DamiaUI positioning for Details windows
local DETAILS_POSITIONS = {
    -- Solo play positioning
    solo = {
        damage = { 
            x = 400, y = -200, 
            width = 220, height = 200,
            anchor = "BOTTOMRIGHT"
        },
        healing = { 
            x = 400, y = -20,
            width = 220, height = 140,
            anchor = "BOTTOMRIGHT"
        }
    },
    
    -- Party positioning  
    party = {
        damage = { 
            x = 450, y = -150,
            width = 250, height = 180,
            anchor = "BOTTOMRIGHT"
        },
        healing = { 
            x = 450, y = 50,
            width = 250, height = 140,
            anchor = "BOTTOMRIGHT"
        }
    },
    
    -- Raid positioning
    raid = {
        damage = { 
            x = 500, y = -100,
            width = 280, height = 200,
            anchor = "BOTTOMRIGHT"
        },
        healing = { 
            x = 500, y = 120,
            width = 280, height = 160,
            anchor = "BOTTOMRIGHT"
        },
        utility = {
            x = 500, y = 300,
            width = 280, height = 120,
            anchor = "BOTTOMRIGHT"
        }
    }
}

-- Details configuration templates
local DETAILS_CONFIGURATIONS = {
    -- DamiaUI optimized skin settings
    appearance = {
        skin = "DamiaUI", -- Will be registered with Details
        font_face = "Fonts\\FRIZQT__.TTF",
        font_size = 11,
        
        -- Colors matching DamiaUI theme
        color = {
            background = { 0.1, 0.1, 0.1, 0.95 },
            border = { 0.3, 0.3, 0.3, 1.0 },
            header = { 0.8, 0.5, 0.1, 1.0 }, -- Damia orange
            text = { 1.0, 1.0, 1.0, 1.0 },
            bar_background = { 0.15, 0.15, 0.15, 0.8 },
            bar_color = { 0.8, 0.5, 0.1, 0.8 }
        },
        
        -- Window settings
        hide_in_combat_alpha = 0,
        hide_in_combat_type = 1,
        window_scale = 1.0,
        clickthrough_window = false,
        clickthrough_rows = false,
        clickthrough_incombatonly = false,
        
        -- Bar settings
        bars_sort_direction = 1,
        bars_inverted = false,
        bar_height = 18,
        row_height = 18,
        
        -- Border and background
        bg_r = 0.1, bg_g = 0.1, bg_b = 0.1, bg_alpha = 0.95,
        border_color = { 0.3, 0.3, 0.3, 1 },
        border_size = 1,
        
        -- Header
        show_statusbar = true,
        statusbar_info = { "DPS", "Details" },
        
        -- Icons and textures
        use_multi_iconfile = true,
        icon_file = "Interface\\Icons\\",
        icon_grayscale = false,
        
        -- Animation
        animate_scroll = false,
        
        -- Misc
        switch_all_roles_in_combat = false,
        switch_tank = false,
        switch_healer = false,
        switch_damager = true
    },
    
    -- Window templates
    windows = {
        damage = {
            name = "DamiaUI Damage",
            mode = 1, -- Damage done
            segment = 0, -- Current fight
            display = "bar",
            
            -- Positioning will be set dynamically
            pos = {},
            
            -- Display settings
            row_info = {
                textR_outline = true,
                textR_outline_small = false,
                textL_outline = true,
                textL_outline_small = false,
                fixed_text_color = { 1, 1, 1 },
                space = { ["right"] = 0, ["left"] = 0, ["between"] = 0 },
                texture = "BantoBar",
                texture_background = "Blizzard Tooltip",
                texture_background_class_color = false,
                texture_class_colors = true,
                texture_custom_file = "Interface\\Buttons\\WHITE8X8",
                
                models = {
                    upper_model = "Spells\\AcidBreath_SuperGreen.M2",
                    lower_model = "World\\EXPANSION02\\DOODADS\\Coldarra\\COLDARRALOCUS.m2",
                    upper_alpha = 0.5,
                    lower_alpha = 0.1,
                    lower_enabled = false,
                    upper_enabled = false,
                }
            },
            
            -- Bars configuration
            bars = {
                alpha = 1,
                icon = true,
                icon_file = "",
                grow_direction = 3,
                height = 18,
                spark_width = 30,
                spark_height = 100,
                spark_alpha = 0.3,
                spark_color = { 1, 1, 1 },
                spark_texture = "Interface\\CastingBar\\UI-CastingBar-Spark"
            },
            
            -- Plugins
            plugins = {
                ["Details:Vanguard"] = true,
                ["Details:Encounter Breakdown"] = true
            }
        },
        
        healing = {
            name = "DamiaUI Healing",
            mode = 2, -- Healing done
            segment = 0, -- Current fight
            display = "bar",
            
            -- Similar configuration to damage but for healing
            row_info = {
                textR_outline = true,
                textL_outline = true,
                fixed_text_color = { 1, 1, 1 },
                texture = "BantoBar",
                texture_background = "Blizzard Tooltip",
                texture_class_colors = true
            },
            
            bars = {
                alpha = 1,
                icon = true,
                grow_direction = 3,
                height = 16
            }
        }
    }
}

--[[
    Core Functions
]]

function DetailsTemplates:Initialize()
    self.initialized = false
    
    -- Check if Details is available
    if not self:IsDetailsAvailable() then
        DamiaUI:LogDebug("Details! not available, templates disabled")
        return false
    end
    
    -- Setup Details integration
    self:SetupDetailsIntegration()
    
    self.initialized = true
    DamiaUI:LogDebug("Details templates initialized")
    return true
end

function DetailsTemplates:IsDetailsAvailable()
    return IsAddOnLoaded("Details") and _detalhes ~= nil
end

function DetailsTemplates:SetupDetailsIntegration()
    -- Wait for Details to be fully loaded
    if not _detalhes or not _detalhes.GetCurrentInstance then
        C_Timer.After(2, function()
            self:SetupDetailsIntegration()
        end)
        return
    end
    
    -- Register DamiaUI skin with Details
    self:RegisterDamiaUISkin()
    
    -- Hook into Details events if needed
    if _detalhes.RegisterCallback then
        _detalhes:RegisterCallback("DETAILS_INSTANCE_OPEN", self, "OnDetailsInstanceOpen")
        _detalhes:RegisterCallback("DETAILS_INSTANCE_CLOSE", self, "OnDetailsInstanceClose")
    end
    
    DamiaUI:LogDebug("Details integration setup complete")
end

function DetailsTemplates:RegisterDamiaUISkin()
    if not _detalhes or not _detalhes.RegisterSkin then
        return false
    end
    
    local skinData = {
        name = "DamiaUI",
        version = "1.0",
        author = "DamiaUI Team",
        
        -- Skin template
        template = {
            -- Background
            ["color_bg"] = DETAILS_CONFIGURATIONS.appearance.color.background,
            ["bg_alpha"] = DETAILS_CONFIGURATIONS.appearance.bg_alpha,
            
            -- Border  
            ["color_border"] = DETAILS_CONFIGURATIONS.appearance.color.border,
            ["border_size"] = DETAILS_CONFIGURATIONS.appearance.border_size,
            
            -- Header
            ["statusbar_color"] = DETAILS_CONFIGURATIONS.appearance.color.header,
            
            -- Bars
            ["bar_texture"] = "Interface\\Buttons\\WHITE8X8",
            ["bar_height"] = DETAILS_CONFIGURATIONS.appearance.bar_height,
            
            -- Font
            ["font_face"] = DETAILS_CONFIGURATIONS.appearance.font_face,
            ["font_size"] = DETAILS_CONFIGURATIONS.appearance.font_size,
            
            -- Colors
            ["text_color"] = DETAILS_CONFIGURATIONS.appearance.color.text
        }
    }
    
    local success = pcall(function()
        _detalhes:RegisterSkin("DamiaUI", skinData)
    end)
    
    if success then
        DamiaUI:LogDebug("DamiaUI skin registered with Details")
        return true
    else
        DamiaUI:LogWarning("Failed to register DamiaUI skin with Details")
        return false
    end
end

--[[
    Template Application
]]

function DetailsTemplates:ApplyTemplate(templateType)
    if not self:IsDetailsAvailable() then
        return false, "Details not available"
    end
    
    templateType = templateType or "solo"
    
    local positions = DETAILS_POSITIONS[templateType]
    if not positions then
        return false, "Unknown template type: " .. tostring(templateType)
    end
    
    -- Check if user already has configured Details windows (non-invasive)
    if self:HasExistingConfiguration() then
        DamiaUI:LogDebug("Details already configured by user, skipping template application")
        return true, "User configuration detected, template not applied"
    end
    
    -- Apply damage meter configuration
    local success = self:ConfigureDetailsWindow(1, "damage", positions.damage)
    if not success then
        return false, "Failed to configure damage window"
    end
    
    -- Apply healing meter configuration if applicable
    if positions.healing then
        success = self:ConfigureDetailsWindow(2, "healing", positions.healing)
        if not success then
            DamiaUI:LogWarning("Failed to configure healing window")
        end
    end
    
    -- Apply utility window for raids
    if positions.utility and templateType == "raid" then
        success = self:ConfigureDetailsWindow(3, "utility", positions.utility)
        if not success then
            DamiaUI:LogWarning("Failed to configure utility window")
        end
    end
    
    -- Apply DamiaUI skin
    self:ApplyDamiaUISkin()
    
    DamiaUI:LogDebug("Applied Details template: " .. templateType)
    return true, "Template applied successfully"
end

function DetailsTemplates:HasExistingConfiguration()
    if not _detalhes or not _detalhes.tabela_instancias then
        return false
    end
    
    -- Check if any instances have been manually positioned or configured
    for i = 1, #_detalhes.tabela_instancias do
        local instance = _detalhes.tabela_instancias[i]
        if instance and instance.damiaui_template ~= true then
            -- If instance exists and wasn't created by DamiaUI, user has configuration
            if instance.pos_x and instance.pos_y then
                return true
            end
        end
    end
    
    return false
end

function DetailsTemplates:ConfigureDetailsWindow(instanceId, windowType, position)
    if not _detalhes then
        return false
    end
    
    local instance = _detalhes:GetInstance(instanceId)
    if not instance then
        -- Create new instance
        instance = _detalhes:CreateInstance()
        if not instance then
            return false
        end
    end
    
    -- Apply window configuration
    local config = DETAILS_CONFIGURATIONS.windows[windowType] or DETAILS_CONFIGURATIONS.windows.damage
    
    -- Position settings
    instance.pos_x = position.x
    instance.pos_y = position.y
    instance.pos_w = position.width
    instance.pos_h = position.height
    
    -- Window settings
    instance.segment = config.segment or 0
    instance.mode = config.mode or 1
    
    -- Mark as DamiaUI template
    instance.damiaui_template = true
    instance.damiaui_version = DamiaUI.version
    instance.damiaui_window_type = windowType
    
    -- Apply appearance settings
    if instance.baseFrame then
        self:ApplyWindowAppearance(instance, windowType)
    end
    
    -- Show the window
    if instance.Show then
        instance:Show()
    end
    
    return true
end

function DetailsTemplates:ApplyWindowAppearance(instance, windowType)
    if not instance or not instance.baseFrame then
        return false
    end
    
    local appearance = DETAILS_CONFIGURATIONS.appearance
    
    -- Background + border using safe child frames
    if instance.baseFrame then
        -- Background texture
        if not instance.baseFrame.damiaBackground then
            local bg = instance.baseFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(instance.baseFrame)
            instance.baseFrame.damiaBackground = bg
        end
        instance.baseFrame.damiaBackground:SetTexture("Interface\\Buttons\\WHITE8X8")
        instance.baseFrame.damiaBackground:SetVertexColor(
            appearance.color.background[1],
            appearance.color.background[2],
            appearance.color.background[3],
            appearance.color.background[4]
        )

        -- Border frame with BackdropTemplate
        if not instance.baseFrame.damiaBorder then
            local border = CreateFrame("Frame", nil, instance.baseFrame, "BackdropTemplate")
            border:SetAllPoints(instance.baseFrame)
            border:SetFrameLevel(instance.baseFrame:GetFrameLevel() + 1)
            instance.baseFrame.damiaBorder = border
        end
        instance.baseFrame.damiaBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = appearance.border_size,
        })
        instance.baseFrame.damiaBorder:SetBackdropBorderColor(
            appearance.color.border[1],
            appearance.color.border[2],
            appearance.color.border[3],
            appearance.color.border[4]
        )
    end
    
    -- Apply DamiaUI styling to bars
    if instance.bars then
        for _, bar in ipairs(instance.bars) do
            if bar and bar.texture then
                bar.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
            end
        end
    end
    
    return true
end

function DetailsTemplates:ApplyDamiaUISkin()
    if not _detalhes then
        return false
    end
    
    -- Apply DamiaUI skin to all instances
    for i = 1, #_detalhes.tabela_instancias do
        local instance = _detalhes.tabela_instancias[i]
        if instance and instance.damiaui_template then
            -- Set skin
            if instance.SetSkin then
                instance:SetSkin("DamiaUI")
            end
            
            -- Force refresh
            if instance.RefreshBars then
                instance:RefreshBars()
            end
        end
    end
    
    return true
end

--[[
    Group Type Detection and Auto-Configuration
]]

function DetailsTemplates:DetectGroupType()
    local numGroupMembers = GetNumGroupMembers()
    local isInRaid = IsInRaid()
    
    if isInRaid and numGroupMembers > 10 then
        return "raid"
    elseif numGroupMembers > 1 then
        return "party"
    else
        return "solo"
    end
end

function DetailsTemplates:AutoConfigureForGroup()
    if not self:IsDetailsAvailable() then
        return false
    end
    
    local groupType = self:DetectGroupType()
    local success, message = self:ApplyTemplate(groupType)
    
    if success then
        DamiaUI:LogDebug("Auto-configured Details for group type: " .. groupType)
    else
        DamiaUI:LogWarning("Failed to auto-configure Details: " .. tostring(message))
    end
    
    return success
end

--[[
    Event Handlers
]]

function DetailsTemplates:OnDetailsInstanceOpen(instanceId)
    local instance = _detalhes:GetInstance(instanceId)
    if instance and instance.damiaui_template then
        -- Ensure DamiaUI styling is maintained
        self:ApplyWindowAppearance(instance, instance.damiaui_window_type or "damage")
    end
end

function DetailsTemplates:OnDetailsInstanceClose(instanceId)
    -- Handle instance closing if needed
    DamiaUI:LogDebug("Details instance closed: " .. tostring(instanceId))
end

--[[
    Configuration Functions
]]

function DetailsTemplates:CreateConfigurationPanel()
    if not self:IsDetailsAvailable() then
        return nil
    end
    
    local panel = CreateFrame("Frame", "DamiaUIDetailsTemplatesPanel")
    panel.name = "Details Templates"
    panel.parent = "DamiaUI"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Details! Templates")
    
    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Pre-configured Details! meter positions and styling for DamiaUI")
    desc:SetWidth(600)
    desc:SetWordWrap(true)
    
    -- Template buttons
    local yOffset = -80
    local templates = { "solo", "party", "raid" }
    
    for _, templateType in ipairs(templates) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", 16, yOffset)
        button:SetSize(150, 24)
        button:SetText("Apply " .. templateType:gsub("^%l", string.upper) .. " Template")
        
        button:SetScript("OnClick", function()
            local success, message = self:ApplyTemplate(templateType)
            if success then
                DamiaUI:Print("Details template applied: " .. templateType)
            else
                DamiaUI:Print("Failed to apply template: " .. message)
            end
        end)
        
        yOffset = yOffset - 32
    end
    
    -- Auto-configure button
    local autoButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    autoButton:SetPoint("TOPLEFT", 16, yOffset)
    autoButton:SetSize(200, 24)
    autoButton:SetText("Auto-Configure for Current Group")
    
    autoButton:SetScript("OnClick", function()
        local success = self:AutoConfigureForGroup()
        if success then
            DamiaUI:Print("Details auto-configured for current group")
        else
            DamiaUI:Print("Failed to auto-configure Details")
        end
    end)
    
    return panel
end

--[[
    Public API
]]

function DetailsTemplates:GetAvailableTemplates()
    local templates = {}
    
    for templateType, positions in pairs(DETAILS_POSITIONS) do
        templates[templateType] = {
            name = templateType:gsub("^%l", string.upper) .. " Template",
            description = "Details configuration optimized for " .. templateType .. " play",
            positions = positions
        }
    end
    
    return templates
end

function DetailsTemplates:ResetToDefaults()
    if not self:IsDetailsAvailable() then
        return false
    end
    
    -- Remove DamiaUI templates
    for i = #_detalhes.tabela_instancias, 1, -1 do
        local instance = _detalhes.tabela_instancias[i]
        if instance and instance.damiaui_template then
            instance:Hide()
            _detalhes:DeleteInstance(i)
        end
    end
    
    DamiaUI:LogDebug("Details templates reset to defaults")
    return true
end

function DetailsTemplates:RefreshAllWindows()
    if not self:IsDetailsAvailable() then
        return false
    end
    
    -- Refresh all DamiaUI-managed instances
    for i = 1, #_detalhes.tabela_instancias do
        local instance = _detalhes.tabela_instancias[i]
        if instance and instance.damiaui_template then
            if instance.RefreshBars then
                instance:RefreshBars()
            end
            if instance.RefreshWindow then
                instance:RefreshWindow()
            end
        end
    end
    
    return true
end

-- Initialize when called
if DamiaUI.Integration then
    DamiaUI.Integration.DetailsTemplates = DetailsTemplates
end