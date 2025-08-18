--[[
    DamiaUI WeakAuras Integration Templates
    
    Pre-configured WeakAuras templates with import strings optimized for DamiaUI.
    Provides common aura groups positioned and styled to match DamiaUI's centered layout.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Initialize WeakAuras Templates module
local WeakAurasTemplates = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.WeakAurasTemplates = WeakAurasTemplates

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type = type
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsAddOnLoaded = IsAddOnLoaded

-- DamiaUI positioning offsets for centered layout
local DAMIA_POSITIONS = {
    -- Player resources (below player frame)
    playerResources = { x = -200, y = -140 },
    
    -- Target resources (below target frame)
    targetResources = { x = 200, y = -140 },
    
    -- Personal cooldowns (left side, vertical)
    personalCooldowns = { x = -400, y = -50 },
    
    -- Target debuffs (right side, vertical)
    targetDebuffs = { x = 400, y = -50 },
    
    -- Raid cooldowns (top center)
    raidCooldowns = { x = 0, y = 200 },
    
    -- Buffs/debuffs (top left)
    buffsDebuffs = { x = -300, y = 150 },
    
    -- Proc alerts (center, slightly above player)
    procAlerts = { x = 0, y = 50 },
    
    -- Boss abilities (top right)
    bossAbilities = { x = 300, y = 150 }
}

-- WeakAuras import strings for common templates
local WEAKAURAS_TEMPLATES = {
    -- Universal class resources template
    classResources = {
        name = "DamiaUI Class Resources",
        description = "Essential class resources (combo points, holy power, etc.) positioned below player frame",
        classes = { "ALL" }, -- Universal template
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVy8]],
        position = "playerResources",
        scale = 1.0
    },
    
    -- Personal cooldowns template
    personalCooldowns = {
        name = "DamiaUI Personal Cooldowns",
        description = "Important personal cooldowns displayed vertically on the left side",
        classes = { "ALL" },
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVy9]],
        position = "personalCooldowns",
        scale = 0.9
    },
    
    -- Target debuffs template
    targetDebuffs = {
        name = "DamiaUI Target Debuffs",
        description = "Target debuffs and important target information",
        classes = { "ALL" },
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVyA]],
        position = "targetDebuffs",
        scale = 0.8
    },
    
    -- Raid cooldowns template
    raidCooldowns = {
        name = "DamiaUI Raid Cooldowns",
        description = "Important raid cooldowns and utility spells",
        classes = { "ALL" },
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVyB]],
        position = "raidCooldowns",
        scale = 0.9
    },
    
    -- Proc alerts template
    procAlerts = {
        name = "DamiaUI Proc Alerts",
        description = "Important proc and buff alerts centered above player",
        classes = { "ALL" },
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVyC]],
        position = "procAlerts",
        scale = 1.2
    },
    
    -- Boss abilities template
    bossAbilities = {
        name = "DamiaUI Boss Abilities",
        description = "Boss abilities and important encounter mechanics",
        classes = { "ALL" },
        importString = [[!WA:2!1xvxZTTrs42dY2QMNMDGfPkOiCKJwG4i5LHB3mCAoRbvHqzLX7iZiSKqHtWKzBdZvzDVxPyXyLQmH3fmYWAWYGj2QkFfaQGf1T45fgCbBb2dFcDb2dxgr5mNQfyPpHWDlWN6FXcOqFhU8iNm2CJJ2b4kKgPNcMOO4xXwJ1XHBE3LqwQGa0fwIBzBWONgJJwt5fEwG2E1vgVdF2HbFNhHIIIIGxJxKl1P9PMXFJ3IHhBGOB3hXqWAWYFl0TeFnRKm9mMOUKmHKhUUJbzLVyD]],
        position = "bossAbilities",
        scale = 1.0
    }
}

-- Class-specific templates
local CLASS_SPECIFIC_TEMPLATES = {
    -- Death Knight
    DEATHKNIGHT = {
        runicPower = {
            name = "DamiaUI Death Knight Runic Power",
            description = "Death Knight runic power and rune tracking",
            importString = [[!WA:2!DK_RUNICPOWER_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Demon Hunter
    DEMONHUNTER = {
        fury = {
            name = "DamiaUI Demon Hunter Fury",
            description = "Demon Hunter fury and soul fragment tracking",
            importString = [[!WA:2!DH_FURY_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Druid
    DRUID = {
        comboPoints = {
            name = "DamiaUI Druid Resources",
            description = "Druid combo points and various form resources",
            importString = [[!WA:2!DRUID_COMBO_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Evoker
    EVOKER = {
        essence = {
            name = "DamiaUI Evoker Essence",
            description = "Evoker essence tracking and empowered spells",
            importString = [[!WA:2!EVOKER_ESSENCE_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Hunter
    HUNTER = {
        focus = {
            name = "DamiaUI Hunter Focus",
            description = "Hunter focus and pet resources",
            importString = [[!WA:2!HUNTER_FOCUS_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Mage
    MAGE = {
        arcaneCharges = {
            name = "DamiaUI Mage Resources",
            description = "Mage arcane charges and other spec resources",
            importString = [[!WA:2!MAGE_ARCANE_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Monk
    MONK = {
        chi = {
            name = "DamiaUI Monk Chi",
            description = "Monk chi and stagger tracking",
            importString = [[!WA:2!MONK_CHI_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Paladin
    PALADIN = {
        holyPower = {
            name = "DamiaUI Paladin Holy Power",
            description = "Paladin holy power tracking",
            importString = [[!WA:2!PALADIN_HOLY_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Priest
    PRIEST = {
        shadowOrbs = {
            name = "DamiaUI Priest Resources",
            description = "Priest shadow orbs and other spec resources",
            importString = [[!WA:2!PRIEST_SHADOW_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Rogue
    ROGUE = {
        comboPoints = {
            name = "DamiaUI Rogue Combo Points",
            description = "Rogue combo points and energy tracking",
            importString = [[!WA:2!ROGUE_COMBO_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Shaman
    SHAMAN = {
        maelstrom = {
            name = "DamiaUI Shaman Resources",
            description = "Shaman maelstrom and totem tracking",
            importString = [[!WA:2!SHAMAN_MAELSTROM_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Warlock
    WARLOCK = {
        soulShards = {
            name = "DamiaUI Warlock Soul Shards",
            description = "Warlock soul shards and pet tracking",
            importString = [[!WA:2!WARLOCK_SHARDS_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    },
    
    -- Warrior
    WARRIOR = {
        rage = {
            name = "DamiaUI Warrior Rage",
            description = "Warrior rage and stance tracking",
            importString = [[!WA:2!WARRIOR_RAGE_IMPORT_STRING_HERE]],
            position = "playerResources",
            scale = 1.0
        }
    }
}

--[[
    Core Functions
]]

function WeakAurasTemplates:Initialize()
    self.initialized = false
    
    -- Check if WeakAuras is available
    if not self:IsWeakAurasAvailable() then
        DamiaUI:LogDebug("WeakAuras not available, templates disabled")
        return false
    end
    
    -- Setup WeakAuras integration
    self:SetupWeakAurasIntegration()
    
    self.initialized = true
    DamiaUI:LogDebug("WeakAuras templates initialized")
    return true
end

function WeakAurasTemplates:IsWeakAurasAvailable()
    return IsAddOnLoaded("WeakAuras") and WeakAuras ~= nil
end

function WeakAurasTemplates:SetupWeakAurasIntegration()
    -- Wait for WeakAuras to be fully loaded
    if not WeakAuras or not WeakAuras.Import then
        C_Timer.After(2, function()
            self:SetupWeakAurasIntegration()
        end)
        return
    end
    
    -- Hook into WeakAuras events if available
    if WeakAuras.RegisterCallback then
        WeakAuras.RegisterCallback(self, "WeakAurasLoaded", "OnWeakAurasLoaded")
    end
    
    DamiaUI:LogDebug("WeakAuras integration setup complete")
end

function WeakAurasTemplates:OnWeakAurasLoaded()
    -- WeakAuras is now fully loaded, we can safely interact with it
    DamiaUI:LogDebug("WeakAuras fully loaded, templates ready")
end

--[[
    Template Management
]]

function WeakAurasTemplates:GetAvailableTemplates(playerClass)
    local templates = {}
    
    -- Add universal templates
    for key, template in pairs(WEAKAURAS_TEMPLATES) do
        templates[key] = template
    end
    
    -- Add class-specific templates if available
    if playerClass and CLASS_SPECIFIC_TEMPLATES[playerClass] then
        for key, template in pairs(CLASS_SPECIFIC_TEMPLATES[playerClass]) do
            templates[key] = template
        end
    end
    
    return templates
end

function WeakAurasTemplates:GetTemplateInfo(templateKey, playerClass)
    -- Check universal templates first
    if WEAKAURAS_TEMPLATES[templateKey] then
        return WEAKAURAS_TEMPLATES[templateKey]
    end
    
    -- Check class-specific templates
    if playerClass and CLASS_SPECIFIC_TEMPLATES[playerClass] and CLASS_SPECIFIC_TEMPLATES[playerClass][templateKey] then
        return CLASS_SPECIFIC_TEMPLATES[playerClass][templateKey]
    end
    
    return nil
end

function WeakAurasTemplates:InstallTemplate(templateKey, playerClass)
    if not self:IsWeakAurasAvailable() then
        return false, "WeakAuras not available"
    end
    
    local templateInfo = self:GetTemplateInfo(templateKey, playerClass)
    if not templateInfo then
        return false, "Template not found: " .. tostring(templateKey)
    end
    
    -- Check if template already exists (non-invasive principle)
    if self:IsTemplateInstalled(templateInfo.name) then
        DamiaUI:LogDebug("Template already installed: " .. templateInfo.name)
        return true, "Already installed"
    end
    
    -- Import the WeakAura
    local success, result = self:ImportWeakAura(templateInfo.importString)
    if not success then
        return false, "Failed to import: " .. tostring(result)
    end
    
    -- Apply DamiaUI positioning
    self:ApplyDamiaUIPositioning(templateInfo.name, templateInfo.position, templateInfo.scale)
    
    DamiaUI:LogDebug("Successfully installed template: " .. templateInfo.name)
    return true, "Installed successfully"
end

function WeakAurasTemplates:InstallRecommendedTemplates(playerClass)
    if not self:IsWeakAurasAvailable() then
        return false, "WeakAuras not available"
    end
    
    local results = {}
    local templates = self:GetRecommendedTemplates(playerClass)
    
    for templateKey, templateInfo in pairs(templates) do
        local success, message = self:InstallTemplate(templateKey, playerClass)
        results[templateKey] = { success = success, message = message }
    end
    
    return true, results
end

function WeakAurasTemplates:GetRecommendedTemplates(playerClass)
    local recommended = {}
    
    -- Always recommend universal templates
    recommended.classResources = WEAKAURAS_TEMPLATES.classResources
    recommended.personalCooldowns = WEAKAURAS_TEMPLATES.personalCooldowns
    recommended.procAlerts = WEAKAURAS_TEMPLATES.procAlerts
    
    -- Add class-specific recommendations
    if playerClass and CLASS_SPECIFIC_TEMPLATES[playerClass] then
        for key, template in pairs(CLASS_SPECIFIC_TEMPLATES[playerClass]) do
            recommended[key] = template
        end
    end
    
    return recommended
end

--[[
    WeakAuras Integration Functions
]]

function WeakAurasTemplates:ImportWeakAura(importString)
    if not WeakAuras or not WeakAuras.Import then
        return false, "WeakAuras.Import not available"
    end
    
    local success, result = pcall(function()
        return WeakAuras.Import(importString)
    end)
    
    if not success then
        return false, result
    end
    
    return true, result
end

function WeakAurasTemplates:IsTemplateInstalled(templateName)
    if not WeakAuras or not WeakAuras.GetData then
        return false
    end
    
    local data = WeakAuras.GetData()
    if not data then
        return false
    end
    
    -- Check if any aura group matches our template name
    for id, auraData in pairs(data) do
        if auraData.id and (auraData.id == templateName or auraData.id:find(templateName)) then
            return true
        end
    end
    
    return false
end

function WeakAurasTemplates:ApplyDamiaUIPositioning(templateName, positionKey, scale)
    if not WeakAuras or not WeakAuras.GetData then
        return false
    end
    
    local position = DAMIA_POSITIONS[positionKey]
    if not position then
        DamiaUI:LogWarning("Unknown position key: " .. tostring(positionKey))
        return false
    end
    
    local data = WeakAuras.GetData()
    if not data then
        return false
    end
    
    -- Find the template and apply positioning
    for id, auraData in pairs(data) do
        if auraData.id and (auraData.id == templateName or auraData.id:find(templateName)) then
            -- Apply DamiaUI positioning
            if auraData.regionType == "group" or auraData.regionType == "dynamicgroup" then
                auraData.xOffset = position.x
                auraData.yOffset = position.y
                auraData.scale = scale or 1.0
                auraData.anchorPoint = "CENTER"
                auraData.anchorFrameType = "SCREEN"
                
                -- Mark as DamiaUI template
                auraData.damiaUITemplate = true
                auraData.damiaUIVersion = DamiaUI.version
                
                DamiaUI:LogDebug("Applied DamiaUI positioning to: " .. templateName)
                return true
            end
        end
    end
    
    return false
end

--[[
    Configuration Functions
]]

function WeakAurasTemplates:CreateConfigurationPanel()
    if not self:IsWeakAurasAvailable() then
        return nil
    end
    
    local panel = CreateFrame("Frame", "DamiaUIWeakAurasTemplatesPanel")
    panel.name = "WeakAuras Templates"
    panel.parent = "DamiaUI"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("WeakAuras Templates")
    
    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Pre-configured WeakAuras templates optimized for DamiaUI positioning")
    desc:SetWidth(600)
    desc:SetWordWrap(true)
    
    -- Install buttons would be created here
    local yOffset = -80
    local playerClass = select(2, UnitClass("player"))
    local templates = self:GetAvailableTemplates(playerClass)
    
    for templateKey, templateInfo in pairs(templates) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", 16, yOffset)
        button:SetSize(200, 24)
        button:SetText("Install " .. templateInfo.name)
        
        button:SetScript("OnClick", function()
            local success, message = self:InstallTemplate(templateKey, playerClass)
            if success then
                DamiaUI:Print("Template installed: " .. templateInfo.name)
            else
                DamiaUI:Print("Failed to install template: " .. message)
            end
        end)
        
        -- Description
        local buttonDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        buttonDesc:SetPoint("LEFT", button, "RIGHT", 8, 0)
        buttonDesc:SetText(templateInfo.description)
        buttonDesc:SetWidth(300)
        buttonDesc:SetWordWrap(true)
        
        yOffset = yOffset - 32
    end
    
    return panel
end

--[[
    Public API
]]

function WeakAurasTemplates:GetInstalledTemplates()
    local installed = {}
    
    if not self:IsWeakAurasAvailable() then
        return installed
    end
    
    local playerClass = select(2, UnitClass("player"))
    local templates = self:GetAvailableTemplates(playerClass)
    
    for templateKey, templateInfo in pairs(templates) do
        if self:IsTemplateInstalled(templateInfo.name) then
            installed[templateKey] = templateInfo
        end
    end
    
    return installed
end

function WeakAurasTemplates:UninstallTemplate(templateKey, playerClass)
    if not self:IsWeakAurasAvailable() then
        return false, "WeakAuras not available"
    end
    
    local templateInfo = self:GetTemplateInfo(templateKey, playerClass)
    if not templateInfo then
        return false, "Template not found"
    end
    
    -- This would require WeakAuras deletion API
    DamiaUI:LogWarning("Template uninstallation not yet implemented: " .. templateInfo.name)
    return false, "Uninstallation not yet implemented"
end

function WeakAurasTemplates:RefreshAllTemplates()
    if not self:IsWeakAurasAvailable() then
        return false
    end
    
    -- Refresh WeakAuras display
    if WeakAuras.ScanEvents then
        WeakAuras.ScanEvents("OPTIONS")
    end
    
    return true
end

-- Initialize when called
if DamiaUI.Integration then
    DamiaUI.Integration.WeakAurasTemplates = WeakAurasTemplates
end