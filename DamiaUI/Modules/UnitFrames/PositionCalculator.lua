--[[
    DamiaUI - Frame Position Calculator
    Advanced positioning system with UI scale awareness and multi-resolution support
    
    Provides precise frame positioning calculations for the centered, symmetrical 
    Damia UI layout across all supported resolutions and UI scale settings.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local UIParent = UIParent
local math_floor, math_ceil = math.floor, math.ceil
local pairs, ipairs = pairs, ipairs

-- Position calculator module
local PositionCalculator = {}

-- Cache for expensive calculations
local calculationCache = {}
local cacheExpiry = 2.0 -- seconds
local lastCacheCleanup = 0

-- Enhanced resolution profiles with DPI awareness
local RESOLUTION_PROFILES = {
    ["4:3"] = {
        safeZone = { left = 0.03, right = 0.03, top = 0.05, bottom = 0.08 },
        scaling = { min = 0.64, max = 0.85, optimal = 0.75, dpi_factor = 0.9 },
        layout = "compact",
        centerBias = { x = 0, y = 0 }
    },
    ["5:4"] = {
        safeZone = { left = 0.04, right = 0.04, top = 0.05, bottom = 0.08 },
        scaling = { min = 0.64, max = 0.9, optimal = 0.78, dpi_factor = 0.9 },
        layout = "compact",
        centerBias = { x = 0, y = 0 }
    },
    ["16:10"] = {
        safeZone = { left = 0.05, right = 0.05, top = 0.05, bottom = 0.08 },
        scaling = { min = 0.64, max = 1.0, optimal = 0.8, dpi_factor = 1.0 },
        layout = "standard",
        centerBias = { x = 0, y = 0 }
    },
    ["16:9"] = {
        safeZone = { left = 0.05, right = 0.05, top = 0.05, bottom = 0.1 },
        scaling = { min = 0.64, max = 1.0, optimal = 0.85, dpi_factor = 1.0 },
        layout = "standard",
        centerBias = { x = 0, y = 0 }
    },
    ["21:9"] = {
        safeZone = { left = 0.15, right = 0.15, top = 0.05, bottom = 0.1 },
        scaling = { min = 0.7, max = 1.0, optimal = 0.9, dpi_factor = 1.1 },
        layout = "ultrawide",
        centerBias = { x = 0, y = 0 }
    },
    ["32:9"] = {
        safeZone = { left = 0.25, right = 0.25, top = 0.05, bottom = 0.1 },
        scaling = { min = 0.8, max = 1.0, optimal = 1.0, dpi_factor = 1.2 },
        layout = "super_ultrawide",
        centerBias = { x = 0, y = 0 }
    }
}

-- Enhanced layout presets with DPI and aspect ratio variants
local LAYOUT_PRESETS = {
    ["classic"] = {
        player = { x = -200, y = -80, scale = 1.0 },
        target = { x = 200, y = -80, scale = 1.0 },
        focus = { x = 0, y = -40, scale = 0.8 },
        targettarget = { x = 350, y = -40, scale = 0.7 },
        party = { x = -400, y = 0, scale = 0.9 },
        raid = { x = -500, y = 200, scale = 0.75 }
    },
    ["compact"] = {
        player = { x = -150, y = -60, scale = 0.9 },
        target = { x = 150, y = -60, scale = 0.9 },
        focus = { x = 0, y = -30, scale = 0.7 },
        targettarget = { x = 250, y = -30, scale = 0.6 },
        party = { x = -300, y = 0, scale = 0.8 },
        raid = { x = -400, y = 150, scale = 0.7 }
    },
    ["wide"] = {
        player = { x = -300, y = -80, scale = 1.1 },
        target = { x = 300, y = -80, scale = 1.1 },
        focus = { x = 0, y = -40, scale = 0.9 },
        targettarget = { x = 450, y = -40, scale = 0.8 },
        party = { x = -500, y = 0, scale = 1.0 },
        raid = { x = -600, y = 200, scale = 0.8 }
    },
    ["ultrawide"] = {
        player = { x = -400, y = -80, scale = 1.0 },
        target = { x = 400, y = -80, scale = 1.0 },
        focus = { x = 0, y = -40, scale = 0.8 },
        targettarget = { x = 550, y = -40, scale = 0.7 },
        party = { x = -650, y = 0, scale = 0.9 },
        raid = { x = -750, y = 200, scale = 0.75 }
    }
}

-- Current environment cache
local currentEnvironment = {
    screenWidth = 0,
    screenHeight = 0,
    aspectRatio = "16:9",
    uiScale = 1.0,
    profile = nil,
    lastUpdate = 0
}

--[[
    Detect current aspect ratio based on screen dimensions
]]
local function DetectAspectRatio()
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    local ratio = width / height
    
    -- Round to common aspect ratios with tolerance
    if math.abs(ratio - 4/3) < 0.1 then
        return "4:3"
    elseif math.abs(ratio - 16/10) < 0.1 then
        return "16:10"
    elseif math.abs(ratio - 16/9) < 0.1 then
        return "16:9"
    elseif math.abs(ratio - 21/9) < 0.15 then
        return "21:9"
    elseif math.abs(ratio - 32/9) < 0.2 then
        return "32:9"
    else
        -- Default to 16:9 for unknown ratios
        return "16:9"
    end
end

--[[
    Update environment cache when screen properties change
]]
local function UpdateEnvironment()
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    -- Only update if something actually changed
    if currentEnvironment.screenWidth ~= width or 
       currentEnvironment.screenHeight ~= height or
       math.abs(currentEnvironment.uiScale - uiScale) > 0.01 then
        
        currentEnvironment.screenWidth = width
        currentEnvironment.screenHeight = height
        currentEnvironment.uiScale = uiScale
        currentEnvironment.aspectRatio = DetectAspectRatio()
        currentEnvironment.profile = RESOLUTION_PROFILES[currentEnvironment.aspectRatio]
        currentEnvironment.lastUpdate = GetTime()
        
        -- Fire update event for listeners
        if DamiaUI.EventSystem then
            DamiaUI.EventSystem:Fire("DISPLAY_ENVIRONMENT_CHANGED", currentEnvironment)
        end
    end
end

--[[
    Get center position with UI scale and safe zone awareness
    Returns absolute coordinates for frame positioning
]]
function PositionCalculator.GetCenterPosition(offsetX, offsetY, respectSafeZone)
    UpdateEnvironment()
    
    local width = currentEnvironment.screenWidth
    local height = currentEnvironment.screenHeight
    local uiScale = currentEnvironment.uiScale
    local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
    
    -- Calculate base center position
    local centerX = width / 2
    local centerY = height / 2
    
    -- Apply safe zone adjustments if requested
    if respectSafeZone then
        local safeLeft = width * profile.safeZone.left
        local safeRight = width * profile.safeZone.right
        local safeTop = height * profile.safeZone.top
        local safeBottom = height * profile.safeZone.bottom
        
        -- Adjust center to account for safe zones
        centerX = (safeLeft + (width - safeRight)) / 2
        centerY = (safeBottom + (height - safeTop)) / 2
    end
    
    -- Apply offsets and scale
    local finalX = (centerX + offsetX) / uiScale
    local finalY = (centerY + offsetY) / uiScale
    
    return math_floor(finalX + 0.5), math_floor(finalY + 0.5)
end

--[[
    Position a frame using the center-based coordinate system
]]
function PositionCalculator.PositionFrame(frame, offsetX, offsetY, anchor, respectSafeZone)
    if not frame then return end
    
    local x, y = PositionCalculator.GetCenterPosition(offsetX, offsetY, respectSafeZone)
    anchor = anchor or "CENTER"
    
    frame:ClearAllPoints()
    frame:SetPoint(anchor, UIParent, "BOTTOMLEFT", x, y)
end

--[[
    Get optimal frame scale with enhanced DPI and resolution awareness
]]
function PositionCalculator.GetOptimalScale(baseScale, frameType, useCache)
    useCache = useCache ~= false -- Default to true
    
    local cacheKey = string.format("scale_%s_%.2f_%s", frameType or "default", baseScale or 1.0, currentEnvironment.aspectRatio)
    
    if useCache and calculationCache[cacheKey] and 
       (GetTime() - calculationCache[cacheKey].timestamp) < cacheExpiry then
        return calculationCache[cacheKey].value
    end
    
    UpdateEnvironment()
    
    local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
    local uiScale = currentEnvironment.uiScale
    baseScale = baseScale or 1.0
    
    -- Base optimal scale from profile
    local optimalScale = profile.scaling.optimal
    
    -- Apply DPI factor
    if profile.scaling.dpi_factor then
        optimalScale = optimalScale * profile.scaling.dpi_factor
    end
    
    -- Frame type specific adjustments with enhanced scaling
    local frameAdjustments = {
        player = 1.0,
        target = 1.0,
        focus = 0.8,
        targettarget = 0.7,
        party = 0.9,
        raid = 0.75,
        actionbar = 1.0,
        chat = 0.95,
        minimap = 1.0,
        tooltip = 0.9
    }
    
    local frameAdjustment = frameAdjustments[frameType] or 1.0
    
    -- Apply layout-specific adjustments
    if profile.layout == "ultrawide" then
        if frameType == "party" or frameType == "raid" then
            frameAdjustment = frameAdjustment * 1.05 -- Slightly larger for visibility
        end
    elseif profile.layout == "super_ultrawide" then
        if frameType == "party" or frameType == "raid" then
            frameAdjustment = frameAdjustment * 1.1
        elseif frameType == "actionbar" then
            frameAdjustment = frameAdjustment * 1.05
        end
    elseif profile.layout == "compact" then
        frameAdjustment = frameAdjustment * 0.95 -- Slightly smaller for compact layouts
    end
    
    -- Calculate final scale
    local finalScale = baseScale * optimalScale * frameAdjustment
    
    -- Clamp to profile bounds
    finalScale = math.max(profile.scaling.min, math.min(profile.scaling.max, finalScale))
    
    -- Cache the result
    if useCache then
        calculationCache[cacheKey] = {
            value = finalScale,
            timestamp = GetTime()
        }
    end
    
    return finalScale
end

--[[
    Get layout positions with enhanced aspect ratio adaptation
]]
function PositionCalculator.GetLayoutPositions(layoutName, useCache)
    useCache = useCache ~= false -- Default to true
    layoutName = layoutName or "classic"
    
    local cacheKey = string.format("layout_%s_%s", layoutName, currentEnvironment.aspectRatio)
    
    if useCache and calculationCache[cacheKey] and 
       (GetTime() - calculationCache[cacheKey].timestamp) < cacheExpiry then
        return calculationCache[cacheKey].value
    end
    
    UpdateEnvironment()
    
    -- Select base layout
    local layout = LAYOUT_PRESETS[layoutName]
    
    -- Auto-select layout based on aspect ratio if not found
    if not layout then
        local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
        if profile.layout == "ultrawide" then
            layout = LAYOUT_PRESETS["ultrawide"] or LAYOUT_PRESETS["wide"]
        elseif profile.layout == "super_ultrawide" then
            layout = LAYOUT_PRESETS["ultrawide"] or LAYOUT_PRESETS["wide"]
        elseif profile.layout == "compact" then
            layout = LAYOUT_PRESETS["compact"]
        else
            layout = LAYOUT_PRESETS["classic"]
        end
    end
    
    local adjustedLayout = {}
    local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
    
    for frameType, position in pairs(layout) do
        adjustedLayout[frameType] = {
            x = position.x,
            y = position.y,
            scale = position.scale or 1.0
        }
        
        -- Apply aspect ratio specific adjustments
        local multiplier = 1.0
        if currentEnvironment.aspectRatio == "21:9" then
            multiplier = 1.3
        elseif currentEnvironment.aspectRatio == "32:9" then
            multiplier = 1.6
        elseif currentEnvironment.aspectRatio == "4:3" then
            multiplier = 0.8
        elseif currentEnvironment.aspectRatio == "5:4" then
            multiplier = 0.85
        end
        
        adjustedLayout[frameType].x = position.x * multiplier
        
        -- Apply center bias for ultra-wide displays
        if profile.centerBias and (multiplier > 1.2) then
            local bias = profile.centerBias.x or 0
            if math.abs(adjustedLayout[frameType].x) < 100 then
                -- Don't apply bias to center elements
            elseif adjustedLayout[frameType].x > 0 then
                adjustedLayout[frameType].x = adjustedLayout[frameType].x + bias
            else
                adjustedLayout[frameType].x = adjustedLayout[frameType].x - bias
            end
        end
    end
    
    -- Cache the result
    if useCache then
        calculationCache[cacheKey] = {
            value = adjustedLayout,
            timestamp = GetTime()
        }
    end
    
    return adjustedLayout
end

--[[
    Calculate safe positioning bounds for dynamic frame placement
]]
function PositionCalculator.GetSafeBounds()
    UpdateEnvironment()
    
    local width = currentEnvironment.screenWidth
    local height = currentEnvironment.screenHeight
    local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
    
    return {
        left = width * profile.safeZone.left,
        right = width * (1 - profile.safeZone.right),
        top = height * (1 - profile.safeZone.top),
        bottom = height * profile.safeZone.bottom,
        centerX = width / 2,
        centerY = height / 2
    }
end

--[[
    Check if a position is within safe viewing area
]]
function PositionCalculator.IsPositionSafe(x, y, frameWidth, frameHeight)
    local bounds = PositionCalculator.GetSafeBounds()
    frameWidth = frameWidth or 0
    frameHeight = frameHeight or 0
    
    local left = x - frameWidth / 2
    local right = x + frameWidth / 2
    local top = y + frameHeight / 2
    local bottom = y - frameHeight / 2
    
    return left >= bounds.left and 
           right <= bounds.right and 
           top <= bounds.top and 
           bottom >= bounds.bottom
end

--[[
    Get recommended frame sizes based on current resolution
]]
function PositionCalculator.GetRecommendedFrameSize(frameType)
    UpdateEnvironment()
    
    local baseWidth, baseHeight
    
    -- Base sizes for different frame types
    if frameType == "player" or frameType == "target" then
        baseWidth, baseHeight = 200, 50
    elseif frameType == "focus" then
        baseWidth, baseHeight = 160, 35
    elseif frameType == "party" then
        baseWidth, baseHeight = 180, 45
    elseif frameType == "raid" then
        baseWidth, baseHeight = 80, 30
    else
        baseWidth, baseHeight = 200, 50
    end
    
    -- Scale based on resolution
    local scale = PositionCalculator.GetOptimalScale(1.0, frameType)
    
    return math_floor(baseWidth * scale + 0.5), math_floor(baseHeight * scale + 0.5)
end

--[[
    Get current environment information
]]
function PositionCalculator.GetEnvironment()
    UpdateEnvironment()
    return currentEnvironment
end

--[[
    Advanced positioning with grid snapping and collision detection
]]
function PositionCalculator.GetAdvancedPosition(frameType, baseX, baseY, options)
    options = options or {}
    
    UpdateEnvironment()
    
    local profile = currentEnvironment.profile or RESOLUTION_PROFILES["16:9"]
    local bounds = PositionCalculator.GetSafeBounds()
    
    -- Start with base position
    local x, y = baseX or 0, baseY or 0
    
    -- Apply aspect ratio adaptation
    if options.adaptToAspectRatio ~= false then
        local multiplier = 1.0
        if currentEnvironment.aspectRatio == "21:9" then
            multiplier = 1.3
        elseif currentEnvironment.aspectRatio == "32:9" then
            multiplier = 1.6
        elseif currentEnvironment.aspectRatio == "4:3" then
            multiplier = 0.8
        end
        x = x * multiplier
    end
    
    -- Apply grid snapping if requested
    if options.snapToGrid then
        local gridSize = options.gridSize or 10
        x = math_floor(x / gridSize + 0.5) * gridSize
        y = math_floor(y / gridSize + 0.5) * gridSize
    end
    
    -- Ensure position is within safe bounds
    if options.respectSafeBounds ~= false then
        local frameWidth = options.frameWidth or 200
        local frameHeight = options.frameHeight or 50
        
        x, y = PositionCalculator.ConstrainToSafeBounds(x, y, frameWidth, frameHeight)
    end
    
    return x, y
end

--[[
    Batch position calculation for multiple frames
]]
function PositionCalculator.BatchCalculatePositions(frameList, layoutName)
    local positions = {}
    local layout = PositionCalculator.GetLayoutPositions(layoutName)
    
    for _, frameData in ipairs(frameList) do
        local frameType = frameData.type
        local basePosition = layout[frameType]
        
        if basePosition then
            local x, y = PositionCalculator.GetAdvancedPosition(
                frameType,
                basePosition.x,
                basePosition.y,
                frameData.options
            )
            
            positions[frameType] = {
                x = x,
                y = y,
                scale = PositionCalculator.GetOptimalScale(basePosition.scale, frameType)
            }
        end
    end
    
    return positions
end

--[[
    Cache management and cleanup
]]
function PositionCalculator.CleanupCache()
    local currentTime = GetTime()
    
    if currentTime - lastCacheCleanup < 30 then -- Cleanup every 30 seconds
        return
    end
    
    lastCacheCleanup = currentTime
    local itemsRemoved = 0
    
    for key, entry in pairs(calculationCache) do
        if currentTime - entry.timestamp > cacheExpiry then
            calculationCache[key] = nil
            itemsRemoved = itemsRemoved + 1
        end
    end
    
    if itemsRemoved > 0 and DamiaUI.Engine then
        DamiaUI.Engine:LogDebug("Position calculator cache cleanup: %d items removed", itemsRemoved)
    end
end

--[[
    Get cache statistics for debugging
]]
function PositionCalculator.GetCacheStats()
    local stats = {
        totalEntries = 0,
        expiredEntries = 0,
        cacheHitRate = 0
    }
    
    local currentTime = GetTime()
    
    for key, entry in pairs(calculationCache) do
        stats.totalEntries = stats.totalEntries + 1
        if currentTime - entry.timestamp > cacheExpiry then
            stats.expiredEntries = stats.expiredEntries + 1
        end
    end
    
    return stats
end

--[[
    Force cache invalidation
]]
function PositionCalculator.InvalidateCache(pattern)
    if pattern then
        local itemsRemoved = 0
        for key in pairs(calculationCache) do
            if string.find(key, pattern) then
                calculationCache[key] = nil
                itemsRemoved = itemsRemoved + 1
            end
        end
        
        if DamiaUI.Engine then
            DamiaUI.Engine:LogDebug("Cache invalidated: %d items matching '%s'", itemsRemoved, pattern)
        end
    else
        calculationCache = {}
        if DamiaUI.Engine then
            DamiaUI.Engine:LogDebug("Cache completely invalidated")
        end
    end
end

--[[
    Enhanced positioning with collision detection
]]
function PositionCalculator.PositionWithCollisionAvoidance(frameType, baseX, baseY, existingFrames)
    local x, y = PositionCalculator.GetAdvancedPosition(frameType, baseX, baseY)
    
    -- Simple collision avoidance (can be enhanced further)
    if existingFrames then
        local frameWidth = 200 -- Default frame width
        local frameHeight = 50 -- Default frame height
        local minDistance = 60 -- Minimum distance between frames
        
        for _, existingFrame in pairs(existingFrames) do
            local distance = math.sqrt((x - existingFrame.x)^2 + (y - existingFrame.y)^2)
            if distance < minDistance then
                -- Move frame away from collision
                local angle = math.atan2(y - existingFrame.y, x - existingFrame.x)
                x = existingFrame.x + math.cos(angle) * minDistance
                y = existingFrame.y + math.sin(angle) * minDistance
            end
        end
    end
    
    return x, y
end

--[[
    Register for display change events with enhanced monitoring
]]
function PositionCalculator.Initialize()
    -- Create event frame for monitoring display changes
    local eventFrame = CreateFrame("Frame", "DamiaUIPositionCalculatorMonitor")
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Invalidate cache on resolution changes
        PositionCalculator.InvalidateCache()
        UpdateEnvironment()
        
        if DamiaUI.UnitFrames and DamiaUI.UnitFrames.RefreshAllFrames then
            DamiaUI.UnitFrames:RefreshAllFrames()
        end
    end)
    
    -- Periodic cache cleanup
    local cleanupTimer = 0
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        cleanupTimer = cleanupTimer + elapsed
        if cleanupTimer >= 30 then -- Every 30 seconds
            cleanupTimer = 0
            PositionCalculator.CleanupCache()
        end
    end)
    
    -- Initial environment setup
    UpdateEnvironment()
    
    if DamiaUI.Engine then
        DamiaUI.Engine:LogInfo("Enhanced Position Calculator initialized")
    end
end

-- Export the module
DamiaUI.PositionCalculator = PositionCalculator