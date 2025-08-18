--[[
===============================================================================
Damia UI - Combat State Detection System
===============================================================================
Advanced combat state detection and UI highlighting system that provides
contextual visual feedback based on combat status, threat levels, and
encounter phases.

Features:
- Global combat state tracking
- Threat level detection and warnings
- Combat role awareness
- UI highlighting and visual feedback
- Performance optimized updates

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Create Combat module
local Combat = {}

-- Module dependencies
local moduleDependencies = {
    "Config",
    "Events",
    "Utils",
    "Performance",
    "Memory",
    "Throttle"
}

-- Local references for performance
local _G = _G
local UnitAffectingCombat = UnitAffectingCombat
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetThreatStatusColor = GetThreatStatusColor
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local UnitExists = UnitExists
local GetTime = GetTime

-- Combat state tracking
local combatState = {
    inCombat = false,
    combatStart = 0,
    combatDuration = 0,
    threatLevel = 0,
    threatTarget = nil,
    playerRole = "NONE",
    instanceType = nil,
    lastUpdate = 0
}

-- Threat level constants
local THREAT_LEVELS = {
    NONE = 0,
    LOW = 1,
    MEDIUM = 2, 
    HIGH = 3
}

-- Threat colors for UI feedback
local THREAT_COLORS = {
    [THREAT_LEVELS.NONE] = { 0, 0, 0, 0 },           -- Transparent
    [THREAT_LEVELS.LOW] = { 1, 1, 0, 0.3 },          -- Yellow
    [THREAT_LEVELS.MEDIUM] = { 1, 0.5, 0, 0.5 },     -- Orange  
    [THREAT_LEVELS.HIGH] = { 1, 0, 0, 0.7 }          -- Red
}

-- Combat highlighting configuration
local COMBAT_CONFIG = {
    enabled = true,
    highlightFrames = true,
    highlightActionBars = true,
    highlightMinimap = true,
    pulseAnimation = true,
    threatWarnings = true,
    updateInterval = 0.1, -- 100ms update interval
    fadeInTime = 0.2,
    fadeOutTime = 0.5,
    performanceOptimizations = true, -- Enable performance optimizations during combat
    reduceAnimations = false, -- Reduce animations during low FPS
    throttleUpdates = false, -- Throttle updates during heavy combat
}

-- Registered UI elements for combat highlighting
local highlightElements = {}

-- Animation frame pool
local animationFrames = {}

--[[
    Update combat state information
]]
local function UpdateCombatState()
    local now = GetTime()
    local inCombat = UnitAffectingCombat("player")
    local instanceType, _ = IsInInstance()
    
    -- Update basic combat state
    if inCombat and not combatState.inCombat then
        -- Entering combat
        combatState.inCombat = true
        combatState.combatStart = now
        DamiaUI.Engine:LogDebug("Player entered combat")
        Combat:OnCombatStart()
    elseif not inCombat and combatState.inCombat then
        -- Leaving combat
        combatState.inCombat = false
        combatState.combatDuration = now - combatState.combatStart
        DamiaUI.Engine:LogDebug("Player left combat (duration: %.1fs)", combatState.combatDuration)
        Combat:OnCombatEnd()
    end
    
    -- Update combat duration
    if combatState.inCombat then
        combatState.combatDuration = now - combatState.combatStart
    end
    
    -- Update threat information
    local threatSituation = UnitThreatSituation("player")
    local newThreatLevel = threatSituation or THREAT_LEVELS.NONE
    
    if newThreatLevel ~= combatState.threatLevel then
        local oldLevel = combatState.threatLevel
        combatState.threatLevel = newThreatLevel
        Combat:OnThreatChanged(oldLevel, newThreatLevel)
    end
    
    -- Update player role
    local currentRole = UnitGroupRolesAssigned("player")
    if currentRole ~= combatState.playerRole then
        combatState.playerRole = currentRole
        Combat:OnRoleChanged(currentRole)
    end
    
    -- Update instance type
    combatState.instanceType = instanceType
    combatState.lastUpdate = now
end

--[[
    Handle combat start
]]
function Combat:OnCombatStart()
    if not COMBAT_CONFIG.enabled then return end
    
    -- Performance optimizations for combat
    if COMBAT_CONFIG.performanceOptimizations then
        self:EnableCombatOptimizations()
    end
    
    -- Trigger combat highlighting
    self:EnableCombatHighlighting()
    
    -- Fire custom event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_COMBAT_START", combatState.combatStart)
    end
    
    DamiaUI.Engine:LogInfo("Combat highlighting activated")
end

--[[
    Handle combat end
]]
function Combat:OnCombatEnd()
    if not COMBAT_CONFIG.enabled then return end
    
    -- Disable performance optimizations
    if COMBAT_CONFIG.performanceOptimizations then
        self:DisableCombatOptimizations()
    end
    
    -- Remove combat highlighting
    self:DisableCombatHighlighting()
    
    -- Reset threat state
    combatState.threatLevel = THREAT_LEVELS.NONE
    combatState.threatTarget = nil
    
    -- Fire custom event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_COMBAT_END", combatState.combatDuration)
    end
    
    DamiaUI.Engine:LogInfo("Combat highlighting deactivated")
end

--[[
    Handle threat level changes
]]
function Combat:OnThreatChanged(oldLevel, newLevel)
    if not COMBAT_CONFIG.threatWarnings then return end
    
    -- Update threat warnings
    self:UpdateThreatWarnings(newLevel)
    
    -- Fire custom event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_THREAT_CHANGED", oldLevel, newLevel)
    end
    
    DamiaUI.Engine:LogDebug("Threat level changed: %d -> %d", oldLevel, newLevel)
end

--[[
    Handle role changes
]]
function Combat:OnRoleChanged(newRole)
    -- Fire custom event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_ROLE_CHANGED", newRole)
    end
    
    DamiaUI.Engine:LogDebug("Player role changed to: %s", newRole or "NONE")
end

--[[
    Enable combat highlighting on registered elements
]]
function Combat:EnableCombatHighlighting()
    if not COMBAT_CONFIG.highlightFrames then return end
    
    for element, config in pairs(highlightElements) do
        if element and element:IsShown() then
            self:ApplyHighlighting(element, config)
        end
    end
end

--[[
    Disable combat highlighting on registered elements
]]
function Combat:DisableCombatHighlighting()
    for element, config in pairs(highlightElements) do
        if element then
            self:RemoveHighlighting(element)
        end
    end
end

--[[
    Apply combat highlighting to a UI element
]]
function Combat:ApplyHighlighting(element, config)
    if not element or not config then return end
    
    -- Create or get existing highlight overlay
    local highlight = element.DamiaUI_CombatHighlight
    if not highlight then
        highlight = CreateFrame("Frame", nil, element)
        highlight:SetAllPoints(element)
        highlight:SetFrameLevel(element:GetFrameLevel() + 10)
        
        local texture = highlight:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints(highlight)
        texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
        texture:SetBlendMode("ADD")
        texture:SetVertexColor(1, 0, 0, 0.3)
        
        highlight.texture = texture
        element.DamiaUI_CombatHighlight = highlight
    end
    
    -- Apply threat-based coloring
    local color = THREAT_COLORS[combatState.threatLevel] or THREAT_COLORS[THREAT_LEVELS.NONE]
    highlight.texture:SetVertexColor(color[1], color[2], color[3], color[4])
    
    -- Show highlight
    highlight:Show()
    
    -- Apply pulsing animation if enabled
    if COMBAT_CONFIG.pulseAnimation then
        self:StartPulseAnimation(highlight)
    end
end

--[[
    Remove combat highlighting from a UI element
]]
function Combat:RemoveHighlighting(element)
    if not element then return end
    
    local highlight = element.DamiaUI_CombatHighlight
    if highlight then
        self:StopPulseAnimation(highlight)
        
        -- Fade out animation
        if highlight.fadeOut then
            highlight.fadeOut:Stop()
        end
        
        highlight.fadeOut = C_Timer.NewTimer(COMBAT_CONFIG.fadeOutTime, function()
            highlight:Hide()
        end)
    end
end

--[[
    Start pulse animation on highlight element
]]
function Combat:StartPulseAnimation(highlight)
    if not highlight or not highlight.texture then return end
    
    -- Stop existing animation
    self:StopPulseAnimation(highlight)
    
    -- Create animation group
    local animGroup = highlight:CreateAnimationGroup()
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.8)
    fadeOut:SetToAlpha(0.2)
    fadeOut:SetDuration(0.6)
    fadeOut:SetOrder(1)
    
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.2)
    fadeIn:SetToAlpha(0.8)
    fadeIn:SetDuration(0.6)
    fadeIn:SetOrder(2)
    
    animGroup:SetLooping("REPEAT")
    animGroup:Play()
    
    highlight.pulseAnimation = animGroup
end

--[[
    Stop pulse animation on highlight element
]]
function Combat:StopPulseAnimation(highlight)
    if highlight and highlight.pulseAnimation then
        highlight.pulseAnimation:Stop()
        highlight.pulseAnimation = nil
    end
end

--[[
    Update threat warnings based on current threat level
]]
function Combat:UpdateThreatWarnings(threatLevel)
    if threatLevel >= THREAT_LEVELS.HIGH then
        -- High threat - show warning
        self:ShowThreatWarning("HIGH THREAT!", { 1, 0, 0 })
    elseif threatLevel >= THREAT_LEVELS.MEDIUM then
        -- Medium threat - show caution
        self:ShowThreatWarning("Threat Warning", { 1, 0.5, 0 })
    else
        -- Low or no threat - hide warning
        self:HideThreatWarning()
    end
end

--[[
    Show threat warning message
]]
function Combat:ShowThreatWarning(message, color)
    -- This could be expanded to show actual UI warnings
    DamiaUI.Engine:LogWarning("Threat Warning: %s", message)
    
    -- Fire threat warning event
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_THREAT_WARNING", message, color)
    end
end

--[[
    Hide threat warning message
]]
function Combat:HideThreatWarning()
    -- Hide any active threat warnings
    if DamiaUI.Events then
        DamiaUI.Events:Fire("DAMIA_THREAT_WARNING_CLEAR")
    end
end

--[[
    Register UI element for combat highlighting
]]
function Combat:RegisterForHighlighting(element, config)
    if not element then return end
    
    config = config or {
        enabled = true,
        pulseAnimation = COMBAT_CONFIG.pulseAnimation,
        threatColors = true
    }
    
    highlightElements[element] = config
    
    -- Apply highlighting if already in combat
    if combatState.inCombat and COMBAT_CONFIG.highlightFrames then
        self:ApplyHighlighting(element, config)
    end
end

--[[
    Unregister UI element from combat highlighting
]]
function Combat:UnregisterFromHighlighting(element)
    if not element then return end
    
    -- Remove highlighting
    self:RemoveHighlighting(element)
    
    -- Remove from registry
    highlightElements[element] = nil
end

--[[
    Get current combat state
]]
function Combat:GetCombatState()
    return {
        inCombat = combatState.inCombat,
        duration = combatState.combatDuration,
        threatLevel = combatState.threatLevel,
        playerRole = combatState.playerRole,
        instanceType = combatState.instanceType
    }
end

--[[
    Get combat configuration
]]
function Combat:GetConfig()
    return COMBAT_CONFIG
end

--[[
    Update combat configuration
]]
function Combat:SetConfig(key, value)
    if COMBAT_CONFIG[key] ~= nil then
        COMBAT_CONFIG[key] = value
        
        -- Apply changes immediately if needed
        if key == "enabled" and not value then
            self:DisableCombatHighlighting()
        elseif key == "highlightFrames" and combatState.inCombat then
            if value then
                self:EnableCombatHighlighting()
            else
                self:DisableCombatHighlighting()
            end
        end
    end
end

-- Module initialization
function Combat:OnEnable()
    DamiaUI.Engine:LogInfo("Combat detection system enabled")
    
    -- Register for configuration changes
    if DamiaUI.Config then
        DamiaUI.Config:RegisterCallback("combat", function(key, oldValue, newValue)
            self:OnConfigChanged(key, oldValue, newValue)
        end, "Combat_ConfigWatcher")
    end
    
    -- Start combat state monitoring
    self:StartMonitoring()
end

function Combat:OnDisable()
    DamiaUI.Engine:LogInfo("Combat detection system disabled")
    
    -- Stop monitoring
    self:StopMonitoring()
    
    -- Clear all highlighting
    self:DisableCombatHighlighting()
    
    -- Cleanup configuration callbacks
    if DamiaUI.Config then
        DamiaUI.Config:UnregisterCallback("combat", "Combat_ConfigWatcher")
    end
end

function Combat:OnConfigChanged(key, oldValue, newValue)
    DamiaUI.Engine:LogDebug("Combat config changed: %s", key)
    self:SetConfig(key, newValue)
end

--[[
    Start combat monitoring
]]
function Combat:StartMonitoring()
    if self.monitoringActive then return end
    
    -- Create update ticker
    self.updateTicker = C_Timer.NewTicker(COMBAT_CONFIG.updateInterval, function()
        UpdateCombatState()
        -- Monitor performance during combat
        self:MonitorCombatPerformance()
    end)
    
    self.monitoringActive = true
    DamiaUI.Engine:LogDebug("Combat monitoring started")
end

--[[
    Stop combat monitoring  
]]
function Combat:StopMonitoring()
    if not self.monitoringActive then return end
    
    if self.updateTicker then
        self.updateTicker:Cancel()
        self.updateTicker = nil
    end
    
    self.monitoringActive = false
    DamiaUI.Engine:LogDebug("Combat monitoring stopped")
end

-- Public API methods
function Combat:IsInCombat()
    return combatState.inCombat
end

function Combat:GetThreatLevel()
    return combatState.threatLevel
end

function Combat:GetCombatDuration()
    return combatState.combatDuration
end

function Combat:GetPlayerRole()
    return combatState.playerRole
end

--[[
    Enable performance optimizations during combat
]]
function Combat:EnableCombatOptimizations()
    -- Notify performance system that we're entering combat
    if DamiaUI.Performance then
        -- Force memory cleanup before combat
        if DamiaUI.Memory then
            DamiaUI.Memory:PerformStandardCleanup()
        end
        
        -- Enable combat-specific throttling
        if DamiaUI.Throttle then
            -- Increase throttling during combat
            DamiaUI.Throttle:SetGlobalMultiplier(1.5)
            
            -- Reduce update frequencies for non-critical elements
            DamiaUI.Events:Fire("DAMIA_COMBAT_OPTIMIZATIONS", true)
        end
    end
    
    -- Reduce animations if performance is poor
    if COMBAT_CONFIG.reduceAnimations then
        self:ReduceAnimationComplexity()
    end
    
    DamiaUI.Engine:LogDebug("Combat performance optimizations enabled")
end

--[[
    Disable performance optimizations after combat
]]
function Combat:DisableCombatOptimizations()
    -- Restore normal performance settings
    if DamiaUI.Throttle then
        -- Restore normal throttling
        DamiaUI.Throttle:SetGlobalMultiplier(1.0)
        
        -- Restore normal update frequencies
        DamiaUI.Events:Fire("DAMIA_COMBAT_OPTIMIZATIONS", false)
    end
    
    -- Restore normal animations
    if COMBAT_CONFIG.reduceAnimations then
        self:RestoreAnimationComplexity()
    end
    
    -- Schedule post-combat cleanup
    if DamiaUI.Memory then
        C_Timer.After(2.0, function()
            DamiaUI.Memory:PerformStandardCleanup()
        end)
    end
    
    DamiaUI.Engine:LogDebug("Combat performance optimizations disabled")
end

--[[
    Reduce animation complexity during performance issues
]]
function Combat:ReduceAnimationComplexity()
    -- Disable pulse animations if FPS is low
    if DamiaUI.Performance then
        local metrics = DamiaUI.Performance:GetMetrics()
        if metrics.fps.current < 30 then
            COMBAT_CONFIG.pulseAnimation = false
            
            -- Stop existing animations
            for element, _ in pairs(highlightElements) do
                if element.DamiaUI_CombatHighlight then
                    self:StopPulseAnimation(element.DamiaUI_CombatHighlight)
                end
            end
            
            DamiaUI.Engine:LogDebug("Combat animations reduced due to low FPS")
        end
    end
end

--[[
    Restore normal animation complexity
]]
function Combat:RestoreAnimationComplexity()
    -- Restore pulse animations
    COMBAT_CONFIG.pulseAnimation = true
    DamiaUI.Engine:LogDebug("Combat animations restored")
end

--[[
    Monitor performance during combat and adjust accordingly
]]
function Combat:MonitorCombatPerformance()
    if not combatState.inCombat then
        return
    end
    
    if DamiaUI.Performance then
        local metrics = DamiaUI.Performance:GetMetrics()
        
        -- Adjust based on FPS
        if metrics.fps.current < 20 then
            -- Critical FPS - disable all combat animations
            if COMBAT_CONFIG.pulseAnimation then
                COMBAT_CONFIG.pulseAnimation = false
                self:DisableCombatHighlighting()
                DamiaUI.Engine:LogWarning("Combat highlighting disabled due to critical FPS")
            end
        elseif metrics.fps.current < 30 and not COMBAT_CONFIG.reduceAnimations then
            -- Low FPS - reduce animations
            COMBAT_CONFIG.reduceAnimations = true
            self:ReduceAnimationComplexity()
        elseif metrics.fps.current >= 45 and COMBAT_CONFIG.reduceAnimations then
            -- Good FPS - restore animations
            COMBAT_CONFIG.reduceAnimations = false
            self:RestoreAnimationComplexity()
        end
        
        -- Adjust update interval based on performance
        if metrics.fps.current < 30 then
            COMBAT_CONFIG.updateInterval = 0.2 -- Reduce to 5 FPS updates
        elseif metrics.fps.current < 45 then
            COMBAT_CONFIG.updateInterval = 0.15 -- Reduce to ~7 FPS updates
        else
            COMBAT_CONFIG.updateInterval = 0.1 -- Normal 10 FPS updates
        end
    end
end

-- Register module with engine
DamiaUI.RegisterModule("Combat", Combat, moduleDependencies)