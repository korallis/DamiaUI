--[[
===============================================================================
Damia UI - Resolution Management System
===============================================================================
Advanced multi-resolution support and adaptive scaling system for different
display configurations and DPI settings.

Features:
- Support for resolutions from 1080p to 4K and beyond
- Aspect ratio handling from 4:3 to 32:9 (super ultrawide)
- DPI scaling compatibility and detection
- Manual scale override options
- Automatic UI repositioning on resolution changes
- Centered layout preservation across all display types

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local math = math
local table = table
local pairs, ipairs = pairs, ipairs
local type, tonumber = type, tonumber
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local UIParent = UIParent
local GetTime = GetTime
local CreateFrame = CreateFrame

-- Create Resolution module
local Resolution = {}
DamiaUI.Resolution = Resolution

-- Constants for resolution detection and scaling
local RESOLUTION_THRESHOLDS = {
    -- Standard resolutions with DPI categories
    {width = 1024, height = 768, name = "XGA", dpi = "low"},
    {width = 1280, height = 720, name = "HD", dpi = "low"},
    {width = 1280, height = 800, name = "WXGA", dpi = "low"},
    {width = 1280, height = 1024, name = "SXGA", dpi = "low"},
    {width = 1366, height = 768, name = "FWXGA", dpi = "low"},
    {width = 1440, height = 900, name = "WXGA+", dpi = "low"},
    {width = 1600, height = 900, name = "HD+", dpi = "low"},
    {width = 1600, height = 1200, name = "UXGA", dpi = "low"},
    {width = 1680, height = 1050, name = "WSXGA+", dpi = "low"},
    {width = 1920, height = 1080, name = "FHD", dpi = "standard"},
    {width = 1920, height = 1200, name = "WUXGA", dpi = "standard"},
    {width = 2560, height = 1080, name = "UWFHD", dpi = "standard"},
    {width = 2560, height = 1440, name = "QHD", dpi = "high"},
    {width = 2560, height = 1600, name = "WQXGA", dpi = "high"},
    {width = 3440, height = 1440, name = "UWQHD", dpi = "high"},
    {width = 3840, height = 1080, name = "SUUWFHD", dpi = "high"},
    {width = 3840, height = 2160, name = "4K", dpi = "high"},
    {width = 5120, height = 1440, name = "SUWQHD", dpi = "high"},
    {width = 5120, height = 2880, name = "5K", dpi = "very_high"},
    {width = 7680, height = 4320, name = "8K", dpi = "very_high"}
}

-- Aspect ratio definitions with safe zones and scaling recommendations
local ASPECT_RATIO_CONFIGS = {
    ["4:3"] = {
        ratio = 4/3,
        tolerance = 0.05,
        safeZone = {left = 0.03, right = 0.03, top = 0.05, bottom = 0.08},
        scaling = {min = 0.64, max = 0.85, optimal = 0.75, dpi_multiplier = 0.9},
        layout = "standard",
        description = "Legacy 4:3 displays"
    },
    ["5:4"] = {
        ratio = 5/4,
        tolerance = 0.05,
        safeZone = {left = 0.04, right = 0.04, top = 0.05, bottom = 0.08},
        scaling = {min = 0.64, max = 0.9, optimal = 0.78, dpi_multiplier = 0.9},
        layout = "standard",
        description = "Legacy 5:4 displays"
    },
    ["16:10"] = {
        ratio = 16/10,
        tolerance = 0.05,
        safeZone = {left = 0.05, right = 0.05, top = 0.05, bottom = 0.08},
        scaling = {min = 0.64, max = 1.0, optimal = 0.8, dpi_multiplier = 1.0},
        layout = "standard",
        description = "Widescreen 16:10 displays"
    },
    ["16:9"] = {
        ratio = 16/9,
        tolerance = 0.05,
        safeZone = {left = 0.05, right = 0.05, top = 0.05, bottom = 0.1},
        scaling = {min = 0.64, max = 1.0, optimal = 0.85, dpi_multiplier = 1.0},
        layout = "standard",
        description = "Standard widescreen displays"
    },
    ["21:9"] = {
        ratio = 21/9,
        tolerance = 0.15,
        safeZone = {left = 0.15, right = 0.15, top = 0.05, bottom = 0.1},
        scaling = {min = 0.7, max = 1.0, optimal = 0.9, dpi_multiplier = 1.1},
        layout = "ultrawide",
        description = "Ultrawide displays"
    },
    ["32:9"] = {
        ratio = 32/9,
        tolerance = 0.2,
        safeZone = {left = 0.25, right = 0.25, top = 0.05, bottom = 0.1},
        scaling = {min = 0.8, max = 1.0, optimal = 1.0, dpi_multiplier = 1.2},
        layout = "super_ultrawide",
        description = "Super ultrawide displays"
    }
}

-- DPI scaling configurations
local DPI_CONFIGURATIONS = {
    ["low"] = {
        threshold = 96,
        scale_factor = 0.85,
        ui_density = "comfortable",
        font_adjustment = 0.9
    },
    ["standard"] = {
        threshold = 120,
        scale_factor = 1.0,
        ui_density = "normal",
        font_adjustment = 1.0
    },
    ["high"] = {
        threshold = 144,
        scale_factor = 1.15,
        ui_density = "compact",
        font_adjustment = 1.1
    },
    ["very_high"] = {
        threshold = 192,
        scale_factor = 1.3,
        ui_density = "very_compact",
        font_adjustment = 1.2
    }
}

-- Current resolution state
local currentResolution = {
    width = 0,
    height = 0,
    aspectRatio = "16:9",
    aspectConfig = nil,
    dpiCategory = "standard",
    dpiConfig = nil,
    detected = nil,
    uiScale = 1.0,
    effectiveScale = 1.0,
    manualOverride = false,
    lastUpdate = 0
}

-- Configuration cache for performance
local configCache = {}
local cacheExpiry = 5 -- Cache for 5 seconds

--[[
===============================================================================
RESOLUTION DETECTION AND CLASSIFICATION
===============================================================================
--]]

-- Detect current screen resolution and classify it
function Resolution:DetectResolution()
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    -- Calculate actual pixel dimensions
    local actualWidth = width * uiScale
    local actualHeight = height * uiScale
    
    -- Find closest resolution match
    local closestMatch = nil
    local minDistance = math.huge
    
    for _, res in ipairs(RESOLUTION_THRESHOLDS) do
        local distance = math.sqrt(
            (actualWidth - res.width)^2 + (actualHeight - res.height)^2
        )
        if distance < minDistance then
            minDistance = distance
            closestMatch = res
        end
    end
    
    -- Update current resolution state
    currentResolution.width = width
    currentResolution.height = height
    currentResolution.uiScale = uiScale
    currentResolution.detected = closestMatch
    currentResolution.lastUpdate = GetTime()
    
    -- Detect aspect ratio
    local aspectRatio = self:DetectAspectRatio(width, height)
    currentResolution.aspectRatio = aspectRatio
    currentResolution.aspectConfig = ASPECT_RATIO_CONFIGS[aspectRatio]
    
    -- Determine DPI category
    local dpiCategory = closestMatch and closestMatch.dpi or "standard"
    currentResolution.dpiCategory = dpiCategory
    currentResolution.dpiConfig = DPI_CONFIGURATIONS[dpiCategory]
    
    -- Calculate effective scale
    self:CalculateEffectiveScale()
    
    -- Clear cache to force recalculation
    configCache = {}
    
    DamiaUI.Engine:LogInfo("Resolution detected: %dx%d (%s, %s, %s DPI)", 
        actualWidth, actualHeight, 
        closestMatch and closestMatch.name or "Unknown",
        aspectRatio, dpiCategory)
    
    return currentResolution
end

-- Detect aspect ratio from dimensions
function Resolution:DetectAspectRatio(width, height)
    local ratio = width / height
    
    for aspectName, config in pairs(ASPECT_RATIO_CONFIGS) do
        if math.abs(ratio - config.ratio) <= config.tolerance then
            return aspectName
        end
    end
    
    -- Default to 16:9 for unknown ratios
    return "16:9"
end

-- Get current resolution information
function Resolution:GetCurrentResolution()
    -- Update if data is stale
    if GetTime() - currentResolution.lastUpdate > 1.0 then
        self:DetectResolution()
    end
    
    return currentResolution
end

-- Check if current resolution supports high DPI
function Resolution:IsHighDPI()
    local res = self:GetCurrentResolution()
    return res.dpiCategory == "high" or res.dpiCategory == "very_high"
end

-- Check if current display is ultrawide
function Resolution:IsUltrawide()
    local res = self:GetCurrentResolution()
    return res.aspectRatio == "21:9" or res.aspectRatio == "32:9"
end

--[[
===============================================================================
SCALING CALCULATIONS
===============================================================================
--]]

-- Calculate effective UI scale based on resolution and settings
function Resolution:CalculateEffectiveScale()
    local config = DamiaUI.Config and DamiaUI.Config:Get("general") or {}
    local userScale = config.scale or 1.0
    local autoScale = config.autoScale or false
    local manualOverride = config.manualScaleOverride or false
    
    currentResolution.manualOverride = manualOverride
    
    if manualOverride then
        -- Use manual override scale
        currentResolution.effectiveScale = userScale
        return currentResolution.effectiveScale
    end
    
    local baseScale = userScale
    
    if autoScale then
        -- Calculate automatic scale based on resolution and DPI
        local aspectConfig = currentResolution.aspectConfig or ASPECT_RATIO_CONFIGS["16:9"]
        local dpiConfig = currentResolution.dpiConfig or DPI_CONFIGURATIONS["standard"]
        
        -- Base scale from aspect ratio configuration
        local optimalScale = aspectConfig.scaling.optimal
        
        -- Apply DPI scaling
        local dpiMultiplier = aspectConfig.scaling.dpi_multiplier * dpiConfig.scale_factor
        
        -- Combine user preference with automatic scaling
        baseScale = userScale * optimalScale * dpiMultiplier
        
        -- Clamp to reasonable bounds
        baseScale = math.max(aspectConfig.scaling.min, 
                            math.min(aspectConfig.scaling.max, baseScale))
    end
    
    currentResolution.effectiveScale = baseScale
    return currentResolution.effectiveScale
end

-- Get recommended scale for a specific frame type
function Resolution:GetRecommendedScale(frameType, baseScale)
    baseScale = baseScale or 1.0
    local effectiveScale = self:CalculateEffectiveScale()
    
    -- Frame type specific adjustments
    local frameAdjustments = {
        player = 1.0,
        target = 1.0,
        focus = 0.8,
        targettarget = 0.7,
        party = 0.9,
        raid = 0.75,
        actionbar = 1.0,
        chat = 1.0,
        minimap = 1.0,
        tooltip = 0.95
    }
    
    local adjustment = frameAdjustments[frameType] or 1.0
    local finalScale = baseScale * effectiveScale * adjustment
    
    -- Apply aspect ratio specific adjustments
    local aspectConfig = currentResolution.aspectConfig
    if aspectConfig then
        if frameType == "actionbar" and aspectConfig.layout == "ultrawide" then
            finalScale = finalScale * 1.1 -- Slightly larger action bars on ultrawide
        elseif frameType == "raid" and aspectConfig.layout == "super_ultrawide" then
            finalScale = finalScale * 0.9 -- Smaller raid frames on super ultrawide
        end
    end
    
    return math.max(0.5, math.min(2.0, finalScale))
end

-- Scale a size value with current resolution settings
function Resolution:ScaleSize(baseSize, frameType)
    if not baseSize then return 0 end
    
    local scale = self:GetRecommendedScale(frameType or "default")
    return math.floor(baseSize * scale + 0.5)
end

--[[
===============================================================================
POSITIONING AND SAFE ZONES
===============================================================================
--]]

-- Get safe positioning bounds for current resolution
function Resolution:GetSafeBounds()
    local cacheKey = "safeBounds_" .. currentResolution.width .. "_" .. currentResolution.height
    
    if configCache[cacheKey] and GetTime() - configCache[cacheKey].timestamp < cacheExpiry then
        return configCache[cacheKey].data
    end
    
    local res = self:GetCurrentResolution()
    local aspectConfig = res.aspectConfig or ASPECT_RATIO_CONFIGS["16:9"]
    
    local width = res.width
    local height = res.height
    local safeZone = aspectConfig.safeZone
    
    local bounds = {
        left = width * safeZone.left,
        right = width * (1 - safeZone.right),
        top = height * (1 - safeZone.top),
        bottom = height * safeZone.bottom,
        centerX = width / 2,
        centerY = height / 2,
        safeWidth = width * (1 - safeZone.left - safeZone.right),
        safeHeight = height * (1 - safeZone.top - safeZone.bottom)
    }
    
    -- Cache the result
    configCache[cacheKey] = {
        data = bounds,
        timestamp = GetTime()
    }
    
    return bounds
end

-- Check if a position is within safe viewing area
function Resolution:IsPositionSafe(x, y, frameWidth, frameHeight)
    local bounds = self:GetSafeBounds()
    frameWidth = frameWidth or 0
    frameHeight = frameHeight or 0
    
    local halfWidth = frameWidth / 2
    local halfHeight = frameHeight / 2
    
    return (x - halfWidth) >= bounds.left and
           (x + halfWidth) <= bounds.right and
           (y - halfHeight) >= bounds.bottom and
           (y + halfHeight) <= bounds.top
end

-- Adjust position to fit within safe bounds
function Resolution:ConstrainToSafeBounds(x, y, frameWidth, frameHeight)
    local bounds = self:GetSafeBounds()
    frameWidth = frameWidth or 0
    frameHeight = frameHeight or 0
    
    local halfWidth = frameWidth / 2
    local halfHeight = frameHeight / 2
    
    -- Constrain X coordinate
    if (x - halfWidth) < bounds.left then
        x = bounds.left + halfWidth
    elseif (x + halfWidth) > bounds.right then
        x = bounds.right - halfWidth
    end
    
    -- Constrain Y coordinate
    if (y - halfHeight) < bounds.bottom then
        y = bounds.bottom + halfHeight
    elseif (y + halfHeight) > bounds.top then
        y = bounds.top - halfHeight
    end
    
    return x, y
end

--[[
===============================================================================
CENTER-BASED POSITIONING SYSTEM
===============================================================================
--]]

-- Get center position with resolution awareness
function Resolution:GetCenterPosition(offsetX, offsetY, respectSafeZone)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    
    local bounds = self:GetSafeBounds()
    local centerX, centerY
    
    if respectSafeZone then
        -- Use safe zone center
        centerX = bounds.left + bounds.safeWidth / 2
        centerY = bounds.bottom + bounds.safeHeight / 2
    else
        -- Use screen center
        centerX = bounds.centerX
        centerY = bounds.centerY
    end
    
    -- Apply UI scale
    local uiScale = currentResolution.uiScale
    local finalX = (centerX + offsetX) / uiScale
    local finalY = (centerY + offsetY) / uiScale
    
    return math.floor(finalX + 0.5), math.floor(finalY + 0.5)
end

-- Position frame using center-based coordinates
function Resolution:PositionFrame(frame, offsetX, offsetY, anchor, respectSafeZone)
    if not frame then
        DamiaUI.Engine:LogError("PositionFrame: Invalid frame")
        return false
    end
    
    local x, y = self:GetCenterPosition(offsetX or 0, offsetY or 0, respectSafeZone)
    anchor = anchor or "CENTER"
    
    frame:ClearAllPoints()
    frame:SetPoint(anchor, UIParent, "BOTTOMLEFT", x, y)
    
    return true
end

--[[
===============================================================================
LAYOUT ADAPTATION
===============================================================================
--]]

-- Get layout adjustments for current aspect ratio
function Resolution:GetLayoutAdjustments()
    local res = self:GetCurrentResolution()
    local aspectConfig = res.aspectConfig or ASPECT_RATIO_CONFIGS["16:9"]
    
    local adjustments = {
        horizontalSpread = 1.0,
        verticalSpacing = 1.0,
        elementScale = 1.0,
        safeZoneMargin = 0
    }
    
    -- Apply aspect ratio specific adjustments
    if aspectConfig.layout == "ultrawide" then
        adjustments.horizontalSpread = 1.3
        adjustments.safeZoneMargin = 50
    elseif aspectConfig.layout == "super_ultrawide" then
        adjustments.horizontalSpread = 1.6
        adjustments.safeZoneMargin = 100
    elseif res.aspectRatio == "4:3" then
        adjustments.horizontalSpread = 0.8
        adjustments.verticalSpacing = 1.1
    end
    
    -- Apply DPI adjustments
    local dpiConfig = res.dpiConfig or DPI_CONFIGURATIONS["standard"]
    adjustments.elementScale = adjustments.elementScale * dpiConfig.scale_factor
    
    return adjustments
end

-- Adapt position for ultrawide displays
function Resolution:AdaptPositionForAspectRatio(x, y, frameType)
    local adjustments = self:GetLayoutAdjustments()
    
    -- Apply horizontal spread for ultrawide displays
    local adjustedX = x * adjustments.horizontalSpread
    local adjustedY = y * adjustments.verticalSpacing
    
    -- Apply safe zone margin for very wide displays
    if math.abs(adjustedX) < adjustments.safeZoneMargin then
        if adjustedX > 0 then
            adjustedX = adjustedX + adjustments.safeZoneMargin
        elseif adjustedX < 0 then
            adjustedX = adjustedX - adjustments.safeZoneMargin
        end
    end
    
    return adjustedX, adjustedY
end

--[[
===============================================================================
CONFIGURATION AND OVERRIDES
===============================================================================
--]]

-- Set manual scale override
function Resolution:SetManualScale(scale, persist)
    if type(scale) ~= "number" or scale < 0.5 or scale > 2.0 then
        DamiaUI.Engine:LogError("Invalid manual scale: %s", tostring(scale))
        return false
    end
    
    currentResolution.effectiveScale = scale
    currentResolution.manualOverride = true
    
    if persist and DamiaUI.Config then
        DamiaUI.Config:Set("general.scale", scale)
        DamiaUI.Config:Set("general.manualScaleOverride", true)
    end
    
    -- Fire scaling update event
    if DamiaUI.EventSystem then
        DamiaUI.EventSystem:Fire("RESOLUTION_SCALE_CHANGED", {
            scale = scale,
            manual = true
        })
    end
    
    DamiaUI.Engine:LogInfo("Manual scale set to %.2f", scale)
    return true
end

-- Enable/disable automatic scaling
function Resolution:SetAutoScale(enabled, persist)
    if persist and DamiaUI.Config then
        DamiaUI.Config:Set("general.autoScale", enabled)
    end
    
    -- Recalculate effective scale
    self:CalculateEffectiveScale()
    
    -- Fire scaling update event
    if DamiaUI.EventSystem then
        DamiaUI.EventSystem:Fire("RESOLUTION_SCALE_CHANGED", {
            scale = currentResolution.effectiveScale,
            automatic = enabled
        })
    end
    
    DamiaUI.Engine:LogInfo("Auto scaling %s", enabled and "enabled" or "disabled")
    return true
end

-- Get available resolution profiles
function Resolution:GetAvailableProfiles()
    local profiles = {}
    
    for aspectRatio, config in pairs(ASPECT_RATIO_CONFIGS) do
        table.insert(profiles, {
            aspectRatio = aspectRatio,
            description = config.description,
            layout = config.layout,
            optimal_scale = config.scaling.optimal,
            safe_zone = config.safeZone
        })
    end
    
    -- Sort by aspect ratio
    table.sort(profiles, function(a, b)
        return a.aspectRatio < b.aspectRatio
    end)
    
    return profiles
end

--[[
===============================================================================
EVENT HANDLING AND MONITORING
===============================================================================
--]]

-- Handle resolution change events
function Resolution:OnResolutionChanged()
    DamiaUI.Engine:LogInfo("Resolution change detected, updating configuration")
    
    -- Re-detect resolution
    self:DetectResolution()
    
    -- Fire resolution change event
    if DamiaUI.EventSystem then
        DamiaUI.EventSystem:Fire("RESOLUTION_CHANGED", currentResolution)
    end
    
    -- Queue frame repositioning after combat if needed
    if DamiaUI.Utils and DamiaUI.Utils.IsInCombat() then
        DamiaUI.Utils:QueueAfterCombat(function()
            self:RefreshAllFramePositions()
        end)
    else
        self:RefreshAllFramePositions()
    end
end

-- Refresh all frame positions for new resolution
function Resolution:RefreshAllFramePositions()
    if DamiaUI.UnitFrames and DamiaUI.UnitFrames.RefreshAllFrames then
        DamiaUI.UnitFrames:RefreshAllFrames()
    end
    
    if DamiaUI.ActionBars and DamiaUI.ActionBars.RefreshAllBars then
        DamiaUI.ActionBars:RefreshAllBars()
    end
    
    if DamiaUI.Interface and DamiaUI.Interface.RefreshAllFrames then
        DamiaUI.Interface:RefreshAllFrames()
    end
    
    DamiaUI.Engine:LogInfo("All frame positions refreshed for new resolution")
end

--[[
===============================================================================
INITIALIZATION AND MONITORING
===============================================================================
--]]

-- Initialize resolution monitoring
function Resolution:Initialize()
    -- Initial resolution detection
    self:DetectResolution()
    
    -- Create event monitoring frame
    local monitorFrame = CreateFrame("Frame", "DamiaUIResolutionMonitor")
    monitorFrame:RegisterEvent("UI_SCALE_CHANGED")
    monitorFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        Resolution:OnResolutionChanged()
    end)
    
    -- Periodic validation (every 5 seconds)
    local validationTimer = 0
    monitorFrame:SetScript("OnUpdate", function(self, elapsed)
        validationTimer = validationTimer + elapsed
        if validationTimer >= 5.0 then
            validationTimer = 0
            
            -- Check if resolution has changed without events
            local currentWidth = GetScreenWidth()
            local currentHeight = GetScreenHeight()
            local currentUIScale = UIParent:GetEffectiveScale()
            
            if currentWidth ~= currentResolution.width or 
               currentHeight ~= currentResolution.height or
               math.abs(currentUIScale - currentResolution.uiScale) > 0.01 then
                Resolution:OnResolutionChanged()
            end
        end
    end)
    
    DamiaUI.Engine:LogInfo("Resolution monitoring system initialized")
    DamiaUI.Engine:LogInfo("Current resolution: %dx%d (%s, %s)", 
        currentResolution.width, currentResolution.height,
        currentResolution.aspectRatio, currentResolution.dpiCategory)
end

-- Get debug information
function Resolution:GetDebugInfo()
    return {
        current = currentResolution,
        aspectConfigs = ASPECT_RATIO_CONFIGS,
        dpiConfigs = DPI_CONFIGURATIONS,
        safeBounds = self:GetSafeBounds(),
        layoutAdjustments = self:GetLayoutAdjustments(),
        cacheSize = DamiaUI.Utils and DamiaUI.Utils:GetTableSize(configCache) or 0
    }
end

-- Register with engine for initialization
if DamiaUI.Engine then
    DamiaUI.Engine:LogInfo("Resolution management system loaded")
end