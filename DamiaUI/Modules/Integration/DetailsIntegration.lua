--[[
    DamiaUI - Details! Damage Meter Integration
    
    Specialized integration for Details! damage meter addon, providing intelligent
    window positioning, consistent Aurora styling, and performance-optimized
    display management.
    
    Features:
    - Automatic window positioning to complement DamiaUI layout
    - Consistent Aurora styling with DamiaUI theme
    - Intelligent transparency and border management
    - Combat state awareness for display optimization
    - Multi-window management and conflict resolution
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs, type = pairs, ipairs, type
local math = math
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local InCombatLockdown = InCombatLockdown

-- Module initialization
local DetailsIntegration = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.DetailsIntegration = DetailsIntegration

-- Details! references
local Details
local _detalhes

-- Module state
local integrationState = {
    initialized = false,
    managedWindows = {},
    originalSettings = {},
    appliedSettings = {},
    combatState = false,
    lastUpdate = 0
}

-- DamiaUI color scheme for Details! integration
local DAMIA_DETAILS_COLORS = {
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.85 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 0.9 },
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Signature orange
    bars = {
        damage = { r = 0.8, g = 0.2, b = 0.2, a = 0.8 },
        healing = { r = 0.2, g = 0.8, b = 0.2, a = 0.8 },
        tanking = { r = 0.2, g = 0.4, b = 0.8, a = 0.8 },
        utility = { r = 0.8, g = 0.6, b = 0.2, a = 0.8 }
    },
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textHighlight = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }
}

-- Positioning configurations for Details! windows
local DETAILS_WINDOW_CONFIGS = {
    -- Primary damage window - bottom right
    [1] = {
        name = "Primary DPS",
        position = {
            anchor = { point = "BOTTOMRIGHT", x = -20, y = 150 },
            size = { width = 320, height = 200 },
            scale = 1.0
        },
        display = {
            mode = "DAMAGE_DONE",
            showTitle = true,
            showBackground = true,
            transparency = 0.85
        },
        combat = {
            showInCombat = true,
            hideOutOfCombat = false,
            combatAlpha = 1.0,
            nonCombatAlpha = 0.7
        },
        priority = 1
    },
    
    -- Secondary healing window - bottom right, above primary
    [2] = {
        name = "Healing",
        position = {
            anchor = { point = "BOTTOMRIGHT", x = -20, y = 370 },
            size = { width = 300, height = 180 },
            scale = 0.9
        },
        display = {
            mode = "HEALING_DONE", 
            showTitle = true,
            showBackground = true,
            transparency = 0.8
        },
        combat = {
            showInCombat = true,
            hideOutOfCombat = true,
            combatAlpha = 1.0,
            nonCombatAlpha = 0.3
        },
        priority = 2
    },
    
    -- Tertiary utility window - bottom left
    [3] = {
        name = "Utility",
        position = {
            anchor = { point = "BOTTOMLEFT", x = 20, y = 150 },
            size = { width = 280, height = 160 },
            scale = 0.85
        },
        display = {
            mode = "DAMAGE_TAKEN",
            showTitle = true,
            showBackground = true,
            transparency = 0.75
        },
        combat = {
            showInCombat = false,
            hideOutOfCombat = true,
            combatAlpha = 0.8,
            nonCombatAlpha = 0.5
        },
        priority = 3
    },
    
    -- Optional fourth window - left side for specific encounters
    [4] = {
        name = "Encounter Specific",
        position = {
            anchor = { point = "LEFT", x = 20, y = 0 },
            size = { width = 260, height = 140 },
            scale = 0.8
        },
        display = {
            mode = "DISPELL_DONE",
            showTitle = true,
            showBackground = true,
            transparency = 0.7
        },
        combat = {
            showInCombat = false,
            hideOutOfCombat = true,
            combatAlpha = 0.9,
            nonCombatAlpha = 0.2
        },
        priority = 4,
        situational = true
    },
    
    -- Optional fifth window - right side for detailed breakdowns
    [5] = {
        name = "Detailed Breakdown",
        position = {
            anchor = { point = "RIGHT", x = -20, y = 0 },
            size = { width = 260, height = 140 },
            scale = 0.8
        },
        display = {
            mode = "SPELL_DAMAGE_DONE",
            showTitle = true,
            showBackground = true,
            transparency = 0.7
        },
        combat = {
            showInCombat = false,
            hideOutOfCombat = true,
            combatAlpha = 0.8,
            nonCombatAlpha = 0.2
        },
        priority = 5,
        situational = true
    }
}

-- Details! specific display modes and configurations
local DISPLAY_MODES = {
    ["DAMAGE_DONE"] = {
        attribute = 1,
        subAttribute = 1,
        name = "Damage Done",
        colors = DAMIA_DETAILS_COLORS.bars.damage
    },
    ["HEALING_DONE"] = {
        attribute = 2,
        subAttribute = 1,
        name = "Healing Done", 
        colors = DAMIA_DETAILS_COLORS.bars.healing
    },
    ["DAMAGE_TAKEN"] = {
        attribute = 1,
        subAttribute = 2,
        name = "Damage Taken",
        colors = DAMIA_DETAILS_COLORS.bars.tanking
    },
    ["DISPELL_DONE"] = {
        attribute = 4,
        subAttribute = 1,
        name = "Dispells",
        colors = DAMIA_DETAILS_COLORS.bars.utility
    },
    ["SPELL_DAMAGE_DONE"] = {
        attribute = 1,
        subAttribute = 3,
        name = "Spell Damage",
        colors = DAMIA_DETAILS_COLORS.bars.damage
    }
}

--[[
    Core Integration Functions
]]

function DetailsIntegration:Initialize()
    -- Check if Details! is loaded and ready
    if not self:ValidateDetails() then
        DamiaUI:LogDebug("DetailsIntegration: Details! not available")
        return false
    end
    
    -- Setup Details! hooks and callbacks
    self:SetupDetailsHooks()
    
    -- Setup event monitoring
    self:SetupEventHandling()
    
    -- Initialize window management
    self:InitializeWindowManagement()
    
    integrationState.initialized = true
    DamiaUI:LogInfo("DetailsIntegration: Successfully initialized")
    return true
end

function DetailsIntegration:ValidateDetails()
    _detalhes = _G._detalhes
    Details = _detalhes
    
    if not Details then
        return false
    end
    
    -- Check for required Details! API functions
    if not Details.GetCurrentInstance or not Details.GetInstance then
        DamiaUI:LogWarning("DetailsIntegration: Details! API incomplete")
        return false
    end
    
    -- Ensure Details! is properly loaded
    if not Details.opened_windows or Details.opened_windows == 0 then
        -- Details might not be fully loaded yet
        return false
    end
    
    return true
end

function DetailsIntegration:SetupDetailsHooks()
    -- Hook window creation/modification
    if Details and Details.CreateInstance then
        local originalCreateInstance = Details.CreateInstance
        Details.CreateInstance = function(...)
            local result = originalCreateInstance(...)
            
            C_Timer.After(0.1, function()
                self:OnDetailsWindowCreated(result)
            end)
            
            return result
        end
    end
    
    -- Hook window switching/mode changes
    if Details and Details.SwitchWindow then
        local originalSwitchWindow = Details.SwitchWindow
        Details.SwitchWindow = function(instance, segment, ...)
            local result = originalSwitchWindow(instance, segment, ...)
            
            C_Timer.After(0.1, function()
                self:OnDetailsWindowSwitched(instance)
            end)
            
            return result
        end
    end
end

function DetailsIntegration:SetupEventHandling()
    -- Create event frame
    local eventFrame = CreateFrame("Frame", "DamiaUIDetailsIntegration")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leave combat
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- Zone changes
    eventFrame:RegisterEvent("ENCOUNTER_START")       -- Boss encounters
    eventFrame:RegisterEvent("ENCOUNTER_END")         -- Boss encounter end
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            DetailsIntegration:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            DetailsIntegration:OnLeaveCombat()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            DetailsIntegration:OnZoneChanged()
        elseif event == "ENCOUNTER_START" then
            DetailsIntegration:OnEncounterStart(...)
        elseif event == "ENCOUNTER_END" then
            DetailsIntegration:OnEncounterEnd(...)
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            DetailsIntegration:OnDisplayChanged()
        end
    end)
    
    self.eventFrame = eventFrame
end

function DetailsIntegration:InitializeWindowManagement()
    -- Configure existing Details! windows
    C_Timer.After(1, function()
        self:ConfigureExistingWindows()
    end)
    
    -- Setup periodic maintenance
    self.maintenanceTicker = C_Timer.NewTicker(10, function()
        self:PerformMaintenance()
    end)
end

--[[
    Event Handlers
]]

function DetailsIntegration:OnDetailsWindowCreated(instance)
    if not instance then
        return
    end
    
    local instanceId = instance:GetId()
    DamiaUI:LogDebug("DetailsIntegration: Details! window created - " .. instanceId)
    
    -- Apply our configuration to the new window
    self:ConfigureWindow(instance, instanceId)
end

function DetailsIntegration:OnDetailsWindowSwitched(instance)
    if not instance then
        return
    end
    
    local instanceId = instance:GetId()
    
    -- Re-apply styling after mode switch
    C_Timer.After(0.2, function()
        self:ApplyWindowStyling(instance, instanceId)
    end)
end

function DetailsIntegration:OnEnterCombat()
    DamiaUI:LogDebug("DetailsIntegration: Entering combat - adjusting window visibility")
    integrationState.combatState = true
    
    for instanceId, config in pairs(integrationState.managedWindows) do
        local instance = Details:GetInstance(instanceId)
        if instance and config.combat then
            self:ApplyCombatState(instance, instanceId, true)
        end
    end
end

function DetailsIntegration:OnLeaveCombat()
    DamiaUI:LogDebug("DetailsIntegration: Leaving combat - restoring window visibility")
    integrationState.combatState = false
    
    C_Timer.After(2, function() -- Brief delay to avoid immediate repositioning
        for instanceId, config in pairs(integrationState.managedWindows) do
            local instance = Details:GetInstance(instanceId)
            if instance and config.combat then
                self:ApplyCombatState(instance, instanceId, false)
            end
        end
    end)
end

function DetailsIntegration:OnZoneChanged()
    DamiaUI:LogDebug("DetailsIntegration: Zone changed - checking window relevance")
    
    -- Adjust window visibility based on zone type
    C_Timer.After(1, function()
        self:UpdateWindowsForZone()
    end)
end

function DetailsIntegration:OnEncounterStart(encounterId, encounterName)
    DamiaUI:LogDebug("DetailsIntegration: Encounter started - " .. (encounterName or "Unknown"))
    
    -- Show encounter-specific windows
    self:ShowSituationalWindows(true)
end

function DetailsIntegration:OnEncounterEnd(encounterId, encounterName, success)
    DamiaUI:LogDebug("DetailsIntegration: Encounter ended")
    
    -- Hide situational windows after brief delay
    C_Timer.After(5, function()
        self:ShowSituationalWindows(false)
    end)
end

function DetailsIntegration:OnDisplayChanged()
    DamiaUI:LogDebug("DetailsIntegration: Display changed - recalculating positions")
    
    C_Timer.After(0.5, function()
        self:RecalculateAllPositions()
    end)
end

--[[
    Window Configuration and Management
]]

function DetailsIntegration:ConfigureExistingWindows()
    if not Details then
        return
    end
    
    DamiaUI:LogDebug("DetailsIntegration: Configuring existing Details! windows")
    
    local configuredCount = 0
    
    -- Configure up to 5 windows based on our profiles
    for i = 1, 5 do
        local instance = Details:GetInstance(i)
        if instance then
            self:ConfigureWindow(instance, i)
            configuredCount = configuredCount + 1
        elseif i <= 2 then
            -- Create essential windows if they don't exist
            self:CreateWindow(i)
            configuredCount = configuredCount + 1
        end
    end
    
    DamiaUI:LogInfo(string.format("DetailsIntegration: Configured %d Details! windows", configuredCount))
end

function DetailsIntegration:ConfigureWindow(instance, instanceId)
    if not instance or not DETAILS_WINDOW_CONFIGS[instanceId] then
        return false
    end
    
    local config = DETAILS_WINDOW_CONFIGS[instanceId]
    
    -- Store original settings before making changes
    self:StoreOriginalSettings(instance, instanceId)
    
    -- Apply positioning
    self:ApplyWindowPositioning(instance, instanceId, config.position)
    
    -- Apply display settings
    self:ApplyWindowDisplay(instance, instanceId, config.display)
    
    -- Apply styling
    self:ApplyWindowStyling(instance, instanceId)
    
    -- Apply combat state settings
    if config.combat then
        self:ApplyCombatState(instance, instanceId, integrationState.combatState)
    end
    
    -- Store managed window configuration
    integrationState.managedWindows[instanceId] = config
    
    DamiaUI:LogDebug("DetailsIntegration: Configured window " .. instanceId)
    return true
end

function DetailsIntegration:CreateWindow(instanceId)
    if not Details or not DETAILS_WINDOW_CONFIGS[instanceId] then
        return nil
    end
    
    local config = DETAILS_WINDOW_CONFIGS[instanceId]
    
    -- Create new Details! instance
    local instance = Details:CreateInstance()
    if not instance then
        return nil
    end
    
    -- Configure the new window
    self:ConfigureWindow(instance, instanceId)
    
    DamiaUI:LogDebug("DetailsIntegration: Created new Details! window " .. instanceId)
    return instance
end

function DetailsIntegration:ApplyWindowPositioning(instance, instanceId, positionConfig)
    if not instance or not instance.baseFrame or not positionConfig then
        return false
    end
    
    local frame = instance.baseFrame
    local anchor = positionConfig.anchor
    local size = positionConfig.size
    
    local success = pcall(function()
        -- Clear existing points
        frame:ClearAllPoints()
        
        -- Apply new position
        frame:SetPoint(anchor.point, UIParent, anchor.point, anchor.x, anchor.y)
        
        -- Apply size
        if size then
            frame:SetSize(size.width, size.height)
            
            -- Update Details! internal size tracking
            if instance.SetSize then
                instance:SetSize(size.width, size.height)
            end
        end
        
        -- Apply scale
        if positionConfig.scale then
            frame:SetScale(positionConfig.scale)
        end
    end)
    
    return success
end

function DetailsIntegration:ApplyWindowDisplay(instance, instanceId, displayConfig)
    if not instance or not displayConfig then
        return false
    end
    
    local success = pcall(function()
        -- Set display mode
        if displayConfig.mode and DISPLAY_MODES[displayConfig.mode] then
            local modeConfig = DISPLAY_MODES[displayConfig.mode]
            instance:SetDisplay(modeConfig.attribute, modeConfig.subAttribute)
        end
        
        -- Configure title display
        if displayConfig.showTitle ~= nil then
            instance:ShowTitleBar(displayConfig.showTitle)
        end
        
        -- Configure background
        if displayConfig.showBackground ~= nil then
            instance:ShowBackground(displayConfig.showBackground)
        end
        
        -- Set transparency
        if displayConfig.transparency then
            instance:SetAlpha(displayConfig.transparency)
        end
    end)
    
    return success
end

function DetailsIntegration:ApplyWindowStyling(instance, instanceId)
    if not instance or not instance.baseFrame then
        return false
    end
    
    local frame = instance.baseFrame
    
    -- Apply Aurora-style background
    if DamiaUI.Libraries.Aurora then
        local Aurora = DamiaUI.Libraries.Aurora
        if Aurora.CreateBD and not frame.damiaBD then
            Aurora.CreateBD(frame, 0.25)
            frame.damiaBD = true
        end
    end
    
    -- Apply DamiaUI border styling
    self:CreateDamiaDetailsBorder(frame)
    
    -- Style internal elements
    self:StyleDetailsElements(instance, instanceId)
    
    return true
end

function DetailsIntegration:StyleDetailsElements(instance, instanceId)
    if not instance then
        return
    end
    
    -- Get window configuration for color scheme
    local config = DETAILS_WINDOW_CONFIGS[instanceId]
    local displayMode = config and config.display and config.display.mode
    local colors = displayMode and DISPLAY_MODES[displayMode] and DISPLAY_MODES[displayMode].colors
    
    if not colors then
        colors = DAMIA_DETAILS_COLORS.bars.damage -- Default
    end
    
    -- Apply bar colors
    if instance.GetBarTexture then
        local barTexture = instance:GetBarTexture()
        if barTexture then
            -- Details! uses its own color system, we hook into it
            self:ApplyDetailsBarColors(instance, colors)
        end
    end
    
    -- Style title bar
    self:StyleDetailsTitleBar(instance)
    
    -- Style scrollbar if present
    self:StyleDetailsScrollbar(instance)
end

function DetailsIntegration:ApplyDetailsBarColors(instance, colors)
    if not instance or not colors then
        return
    end
    
    -- Hook into Details! color system
    if instance.rowdata and instance.rowdata.texture then
        instance.rowdata.texture_background_color = {
            colors.r * 0.3, colors.g * 0.3, colors.b * 0.3, colors.a * 0.5
        }
        instance.rowdata.texture_custom_color = {
            colors.r, colors.g, colors.b, colors.a
        }
    end
end

function DetailsIntegration:StyleDetailsTitleBar(instance)
    if not instance.titleBar then
        return
    end
    
    local titleBar = instance.titleBar
    
    -- Apply DamiaUI accent color to title text
    if titleBar.text then
        titleBar.text:SetTextColor(
            DAMIA_DETAILS_COLORS.accent.r,
            DAMIA_DETAILS_COLORS.accent.g,
            DAMIA_DETAILS_COLORS.accent.b,
            DAMIA_DETAILS_COLORS.accent.a
        )
    end
    
    -- Style title bar background
    if titleBar.background then
        titleBar.background:SetVertexColor(
            DAMIA_DETAILS_COLORS.background.r,
            DAMIA_DETAILS_COLORS.background.g,
            DAMIA_DETAILS_COLORS.background.b,
            DAMIA_DETAILS_COLORS.background.a
        )
    end
end

function DetailsIntegration:StyleDetailsScrollbar(instance)
    if not instance.baseFrame then
        return
    end
    
    -- Find and style scrollbar elements
    local children = { instance.baseFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName() or ""
        if name:match("ScrollBar") and DamiaUI.Libraries.Aurora then
            local Aurora = DamiaUI.Libraries.Aurora
            if Aurora.ReskinScroll then
                Aurora.ReskinScroll(child)
            end
        end
    end
end

function DetailsIntegration:ApplyCombatState(instance, instanceId, inCombat)
    local config = integrationState.managedWindows[instanceId]
    if not config or not config.combat then
        return
    end
    
    local combatConfig = config.combat
    
    -- Handle visibility
    if inCombat then
        if combatConfig.showInCombat then
            instance:Show()
            if combatConfig.combatAlpha then
                instance:SetAlpha(combatConfig.combatAlpha)
            end
        end
    else
        if combatConfig.hideOutOfCombat then
            instance:Hide()
        else
            if combatConfig.nonCombatAlpha then
                instance:SetAlpha(combatConfig.nonCombatAlpha)
            end
        end
    end
end

--[[
    Utility Functions
]]

function DetailsIntegration:CreateDamiaDetailsBorder(frame)
    if not frame or frame.damiaBorder then
        return
    end
    
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints(frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    
    border:SetBackdropBorderColor(
        DAMIA_DETAILS_COLORS.border.r,
        DAMIA_DETAILS_COLORS.border.g, 
        DAMIA_DETAILS_COLORS.border.b,
        DAMIA_DETAILS_COLORS.border.a
    )
    
    frame.damiaBorder = border
    return border
end

function DetailsIntegration:StoreOriginalSettings(instance, instanceId)
    if not instance or integrationState.originalSettings[instanceId] then
        return -- Already stored
    end
    
    local settings = {
        position = {},
        display = {},
        style = {}
    }
    
    -- Store position settings
    if instance.baseFrame then
        local frame = instance.baseFrame
        settings.position.points = { frame:GetPoint() }
        settings.position.size = { frame:GetSize() }
        settings.position.scale = frame:GetScale()
        settings.position.alpha = frame:GetAlpha()
    end
    
    -- Store display settings
    if instance.GetDisplay then
        settings.display.attribute, settings.display.subAttribute = instance:GetDisplay()
    end
    
    integrationState.originalSettings[instanceId] = settings
end

function DetailsIntegration:ShowSituationalWindows(show)
    for instanceId, config in pairs(integrationState.managedWindows) do
        if config.situational then
            local instance = Details:GetInstance(instanceId)
            if instance then
                if show then
                    instance:Show()
                else
                    instance:Hide()
                end
            end
        end
    end
end

function DetailsIntegration:UpdateWindowsForZone()
    local inDungeon = IsInInstance()
    local inRaid = select(2, IsInInstance()) == "raid"
    local inArena = select(2, IsInInstance()) == "arena"
    
    -- Adjust window visibility based on content type
    for instanceId, config in pairs(integrationState.managedWindows) do
        local instance = Details:GetInstance(instanceId)
        if instance then
            local shouldShow = true
            
            -- Hide certain windows in arenas
            if inArena and instanceId > 2 then
                shouldShow = false
            end
            
            -- Show additional windows in raids
            if inRaid and config.situational then
                shouldShow = true
            end
            
            if shouldShow then
                instance:Show()
            else
                instance:Hide()
            end
        end
    end
end

--[[
    Maintenance Functions
]]

function DetailsIntegration:PerformMaintenance()
    if not Details then
        return
    end
    
    local currentTime = GetTime()
    
    -- Skip if we performed maintenance recently
    if currentTime - integrationState.lastUpdate < 5 then
        return
    end
    
    -- Verify all managed windows still exist
    local cleanedCount = 0
    for instanceId in pairs(integrationState.managedWindows) do
        local instance = Details:GetInstance(instanceId)
        if not instance then
            integrationState.managedWindows[instanceId] = nil
            integrationState.originalSettings[instanceId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        DamiaUI:LogDebug(string.format("DetailsIntegration: Cleaned %d orphaned windows", cleanedCount))
    end
    
    integrationState.lastUpdate = currentTime
end

function DetailsIntegration:RecalculateAllPositions()
    DamiaUI:LogDebug("DetailsIntegration: Recalculating all window positions")
    
    for instanceId, config in pairs(integrationState.managedWindows) do
        local instance = Details:GetInstance(instanceId)
        if instance and config.position then
            self:ApplyWindowPositioning(instance, instanceId, config.position)
        end
    end
end

--[[
    Public API
]]

function DetailsIntegration:ApplyIntegration(profile)
    -- This is called by the main Integration controller
    if not integrationState.initialized then
        return self:Initialize()
    end
    
    -- Trigger a configuration refresh
    C_Timer.After(1, function()
        self:ConfigureExistingWindows()
    end)
    
    return true
end

function DetailsIntegration:RestoreOriginalSettings()
    DamiaUI:LogInfo("DetailsIntegration: Restoring original Details! settings")
    
    for instanceId, settings in pairs(integrationState.originalSettings) do
        local instance = Details:GetInstance(instanceId)
        if instance and instance.baseFrame then
            pcall(function()
                local frame = instance.baseFrame
                
                -- Restore position
                if settings.position.points then
                    frame:ClearAllPoints()
                    frame:SetPoint(unpack(settings.position.points))
                end
                
                -- Restore size and scale
                if settings.position.size then
                    frame:SetSize(unpack(settings.position.size))
                end
                
                if settings.position.scale then
                    frame:SetScale(settings.position.scale)
                end
                
                if settings.position.alpha then
                    frame:SetAlpha(settings.position.alpha)
                end
                
                -- Restore display settings
                if settings.display.attribute and settings.display.subAttribute then
                    instance:SetDisplay(settings.display.attribute, settings.display.subAttribute)
                end
            end)
        end
    end
    
    -- Clear managed windows
    table.wipe(integrationState.managedWindows)
    table.wipe(integrationState.appliedSettings)
end

function DetailsIntegration:GetIntegrationStatus()
    return {
        initialized = integrationState.initialized,
        managedWindows = 0, -- Count managed windows
        inCombat = integrationState.combatState,
        windowConfigs = DETAILS_WINDOW_CONFIGS
    }
end

function DetailsIntegration:GetWindowConfigurations()
    return DETAILS_WINDOW_CONFIGS
end

function DetailsIntegration:GetColorScheme()
    return DAMIA_DETAILS_COLORS
end

-- Initialize if Details! is available
if _G._detalhes then
    C_Timer.After(2, function()
        DetailsIntegration:Initialize()
    end)
end

return DetailsIntegration