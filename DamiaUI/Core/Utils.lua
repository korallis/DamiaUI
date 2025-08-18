--[[
===============================================================================
Damia UI - Core Utilities
===============================================================================
Utility functions for center positioning, scaling, frame management, and 
common operations used throughout the addon.

Features:
- Viewport-centered coordinate system
- UI scale-aware positioning
- Frame pooling for performance
- Common mathematical operations
- String and table utilities

Author: Damia UI Team
Version: 1.0.0
===============================================================================
--]]

local addonName, DamiaUI = ...

-- Local references for performance
local _G = _G
local math = math
local string = string
local table = table
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime

-- Create Utils module
local Utils = {}
DamiaUI.Utils = Utils

-- Constants for positioning and scaling
local DEFAULT_UI_SCALE = 1.0
local MIN_UI_SCALE = 0.5
local MAX_UI_SCALE = 2.0
local SCALE_PRECISION = 0.01

-- Multi-resolution constants
local RESOLUTION_UPDATE_THRESHOLD = 1.0 -- seconds
local DPI_DETECTION_ENABLED = true

-- Enhanced frame pool for memory optimization
local framePool = {}
local poolCleanupTime = 300 -- Clean pool every 5 minutes
local lastPoolCleanup = 0
local poolStats = {
    created = 0,
    reused = 0,
    cleaned = 0,
    maxPoolSize = 10, -- Maximum frames per type
}
local useFramePooling = true

--[[
===============================================================================
POSITIONING AND COORDINATE SYSTEM
===============================================================================
--]]

-- Get screen center position with multi-resolution awareness
function Utils:GetScreenCenter(respectSafeZone)
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:GetCenterPosition(0, 0, respectSafeZone)
    end
    
    -- Fallback to basic calculation
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    return (screenWidth / 2) / uiScale, (screenHeight / 2) / uiScale
end

-- Convert offset coordinates to absolute screen positions
-- Uses screen center (0,0) as origin point with multi-resolution support
function Utils:GetCenterPosition(offsetX, offsetY, respectSafeZone)
    if not offsetX then offsetX = 0 end
    if not offsetY then offsetY = 0 end
    
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:GetCenterPosition(offsetX, offsetY, respectSafeZone)
    end
    
    -- Fallback calculation
    local centerX, centerY = self:GetScreenCenter()
    return centerX + offsetX, centerY + offsetY
end

-- Position frame relative to screen center with multi-resolution support
function Utils:PositionFrame(frame, offsetX, offsetY, point, respectSafeZone)
    if not frame then
        DamiaUI.Engine:LogError("PositionFrame: Invalid frame provided")
        return false
    end
    
    if InCombatLockdown() and frame:IsProtected() then
        DamiaUI.Engine:LogWarning("Cannot position protected frame during combat")
        return false
    end
    
    point = point or "CENTER"
    
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:PositionFrame(frame, offsetX or 0, offsetY or 0, point, respectSafeZone)
    end
    
    -- Fallback positioning
    local x, y = self:GetCenterPosition(offsetX or 0, offsetY or 0)
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, "BOTTOMLEFT", x, y)
    
    return true
end

-- Calculate position for frame arrays (party, raid frames)
function Utils:CalculateGridPosition(index, columns, spacing, startX, startY)
    if not index or index < 1 then
        return startX or 0, startY or 0
    end
    
    columns = columns or 5
    spacing = spacing or 5
    startX = startX or 0
    startY = startY or 0
    
    local row = math.floor((index - 1) / columns)
    local col = (index - 1) % columns
    
    local x = startX + (col * spacing)
    local y = startY - (row * spacing)
    
    return x, y
end

-- Get distance between two points
function Utils:GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--[[
===============================================================================
SCALING AND SIZE CALCULATIONS
===============================================================================
--]]

-- Get current effective UI scale with resolution awareness
function Utils:GetUIScale()
    if DamiaUI.Resolution then
        local resInfo = DamiaUI.Resolution:GetCurrentResolution()
        return resInfo.effectiveScale
    end
    
    return UIParent:GetEffectiveScale()
end

-- Calculate scaled size with multi-resolution awareness
function Utils:GetScaledSize(baseSize, frameType, userScale)
    if not baseSize then
        DamiaUI.Engine:LogError("GetScaledSize: Invalid base size")
        return 0
    end
    
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:ScaleSize(baseSize, frameType)
    end
    
    -- Fallback scaling
    userScale = userScale or DEFAULT_UI_SCALE
    userScale = math.max(MIN_UI_SCALE, math.min(MAX_UI_SCALE, userScale))
    
    local scaledSize = baseSize * userScale
    return math.floor(scaledSize / SCALE_PRECISION + 0.5) * SCALE_PRECISION
end

-- Calculate frame size maintaining aspect ratio
function Utils:GetProportionalSize(baseWidth, baseHeight, targetWidth, targetHeight)
    if not baseWidth or not baseHeight then
        return targetWidth or baseWidth, targetHeight or baseHeight
    end
    
    if targetWidth and not targetHeight then
        local ratio = targetWidth / baseWidth
        return targetWidth, baseHeight * ratio
    elseif targetHeight and not targetWidth then
        local ratio = targetHeight / baseHeight
        return baseWidth * ratio, targetHeight
    else
        return targetWidth or baseWidth, targetHeight or baseHeight
    end
end

-- Scale point coordinates
function Utils:ScalePoint(x, y, scale)
    scale = scale or 1.0
    return (x or 0) * scale, (y or 0) * scale
end

--[[
===============================================================================
FRAME MANAGEMENT AND POOLING
===============================================================================
--]]

-- Get frame from pool or create new one
function Utils:GetPooledFrame(frameType, name, parent, template)
    frameType = frameType or "Frame"
    
    -- Check if pooling is enabled
    if not useFramePooling then
        poolStats.created = poolStats.created + 1
        return CreateFrame(frameType, name, parent, template)
    end
    
    local pool = framePool[frameType]
    if not pool then
        pool = {}
        framePool[frameType] = pool
    end
    
    local frame = table.remove(pool)
    if frame then
        -- Reset frame state
        frame:SetParent(parent or UIParent)
        frame:Show()
        frame:SetAlpha(1)
        frame:ClearAllPoints()
        
        -- Clear any textures or text
        if frame.SetTexture then frame:SetTexture(nil) end
        if frame.SetText then frame:SetText("") end
        
        poolStats.reused = poolStats.reused + 1
        return frame
    else
        -- Create new frame
        poolStats.created = poolStats.created + 1
        return CreateFrame(frameType, name, parent, template)
    end
end

-- Return frame to pool
function Utils:ReturnPooledFrame(frame, frameType)
    if not frame or not useFramePooling then
        return false
    end
    
    frameType = frameType or frame:GetObjectType()
    
    local pool = framePool[frameType]
    if not pool then
        pool = {}
        framePool[frameType] = pool
    end
    
    -- Don't pool if we already have too many
    if #pool >= poolStats.maxPoolSize then
        frame:Hide()
        frame:SetParent(nil)
        return false
    end
    
    -- Clean frame state thoroughly
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(nil)
    frame:SetAlpha(1)
    frame:SetScale(1)
    
    -- Reset common properties
    if frame.SetText then frame:SetText("") end
    if frame.SetTexture then frame:SetTexture(nil) end
    if frame.SetVertexColor then frame:SetVertexColor(1, 1, 1, 1) end
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    
    -- Clear any scripts
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    
    -- Add to pool
    table.insert(pool, frame)
    return true
end

-- Clean up frame pools periodically
function Utils:CleanupFramePools(aggressive)
    local currentTime = GetTime()
    if not aggressive and currentTime - lastPoolCleanup < poolCleanupTime then
        return
    end
    
    lastPoolCleanup = currentTime
    local totalFrames = 0
    local poolCount = 0
    local cleanedFrames = 0
    
    local maxFrames = aggressive and 3 or poolStats.maxPoolSize
    
    for frameType, pool in pairs(framePool) do
        -- Keep fewer frames during aggressive cleanup
        while #pool > maxFrames do
            local frame = table.remove(pool)
            if frame then
                frame:Hide()
                frame:SetParent(nil)
                cleanedFrames = cleanedFrames + 1
                frame = nil
            end
        end
        
        totalFrames = totalFrames + #pool
        poolCount = poolCount + 1
    end
    
    poolStats.cleaned = poolStats.cleaned + cleanedFrames
    
    if cleanedFrames > 0 then
        DamiaUI.Engine:LogDebug("Frame pool cleanup: removed %d frames, %d remaining in %d pools", 
                               cleanedFrames, totalFrames, poolCount)
    end
end

-- Safe frame modification with enhanced error handling
function Utils:SafeSetFrameProperty(frame, property, value)
    if not frame or not property then
        return false
    end
    
    if frame:IsProtected() and InCombatLockdown() then
        if DamiaUI.ErrorHandler then
            DamiaUI.ErrorHandler:LogWarning("Cannot modify protected frame during combat: " .. property, "Utils")
        else
            DamiaUI.Engine:LogWarning("Cannot modify protected frame during combat: %s", property)
        end
        return false
    end
    
    if frame[property] then
        local success, result
        if DamiaUI.ErrorHandler then
            success, result = DamiaUI.ErrorHandler:SafeCall(frame[property], "Utils",
                { frame = tostring(frame), property = property }, frame, value)
        else
            success, result = pcall(frame[property], frame, value)
        end
        
        if not success then
            if not DamiaUI.ErrorHandler then
                DamiaUI.Engine:LogError("Failed to set frame property %s: %s", property, result)
            end
            return false
        end
        return true
    else
        local errorMsg = "Frame property does not exist: " .. property
        if DamiaUI.ErrorHandler then
            DamiaUI.ErrorHandler:LogError(errorMsg, "Utils")
        else
            DamiaUI.Engine:LogError(errorMsg)
        end
        return false
    end
end

--[[
===============================================================================
COMBAT AND STATE UTILITIES
===============================================================================
--]]

-- Check if we're in combat
function Utils:IsInCombat()
    return InCombatLockdown()
end

-- Queue action for after combat
local combatQueue = {}
function Utils:QueueAfterCombat(func, ...)
    if not InCombatLockdown() then
        func(...)
        return true
    end
    
    table.insert(combatQueue, {func = func, args = {...}})
    return false
end

-- Process combat queue when leaving combat with enhanced error handling
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
    while #combatQueue > 0 do
        local action = table.remove(combatQueue, 1)
        if action.func then
            if DamiaUI.ErrorHandler then
                DamiaUI.ErrorHandler:SafeCall(action.func, "Utils",
                    { operation = "combat_queue_action" }, unpack(action.args))
            else
                local success, error = pcall(action.func, unpack(action.args))
                if not success then
                    DamiaUI.Engine:LogError("Combat queue action failed: %s", error)
                end
            end
        end
    end
end)

--[[
===============================================================================
STRING UTILITIES
===============================================================================
--]]

-- Trim whitespace from string
function Utils:Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end

-- Split string by delimiter
function Utils:Split(str, delimiter)
    if not str then return {} end
    delimiter = delimiter or ","
    
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, self:Trim(match))
    end
    return result
end

-- Format time duration
function Utils:FormatTime(seconds)
    if not seconds then return "0:00" end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%d:%02d", minutes, secs)
    end
end

-- Format number with appropriate suffix (K, M, etc.)
function Utils:FormatNumber(number)
    if not number then return "0" end
    
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(math.floor(number))
    end
end

-- Generate unique frame name
function Utils:GenerateFrameName(prefix)
    prefix = prefix or "DamiaUIFrame"
    local timestamp = GetTime()
    local random = math.random(1000, 9999)
    return string.format("%s_%d_%d", prefix, timestamp * 1000, random)
end

--[[
===============================================================================
TABLE UTILITIES
===============================================================================
--]]

-- Deep copy table
function Utils:CopyTable(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:CopyTable(value)
    end
    
    return copy
end

-- Merge tables (source into target)
function Utils:MergeTables(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end
    
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            self:MergeTables(target[key], value)
        else
            target[key] = value
        end
    end
    
    return target
end

-- Check if table is empty
function Utils:IsTableEmpty(tbl)
    if type(tbl) ~= "table" then
        return true
    end
    return next(tbl) == nil
end

-- Get table size (for non-array tables)
function Utils:GetTableSize(tbl)
    if type(tbl) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

--[[
===============================================================================
MATHEMATICAL UTILITIES
===============================================================================
--]]

-- Clamp value between min and max
function Utils:Clamp(value, min, max)
    if not value then return min or 0 end
    return math.max(min or value, math.min(max or value, value))
end

-- Round number to specified decimal places
function Utils:Round(number, decimals)
    if not number then return 0 end
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(number * mult + 0.5) / mult
end

-- Linear interpolation
function Utils:Lerp(a, b, t)
    if not a or not b or not t then return a or 0 end
    return a + (b - a) * math.max(0, math.min(1, t))
end

-- Convert degrees to radians
function Utils:ToRadians(degrees)
    return (degrees or 0) * math.pi / 180
end

-- Convert radians to degrees
function Utils:ToDegrees(radians)
    return (radians or 0) * 180 / math.pi
end

--[[
===============================================================================
COLOR UTILITIES
===============================================================================
--]]

-- Convert RGB to hex color
function Utils:RGBToHex(r, g, b)
    r = math.floor((r or 0) * 255)
    g = math.floor((g or 0) * 255)
    b = math.floor((b or 0) * 255)
    return string.format("%02x%02x%02x", r, g, b)
end

-- Convert hex to RGB
function Utils:HexToRGB(hex)
    if not hex then return 0, 0, 0 end
    hex = hex:gsub("#", "")
    
    if hex:len() == 6 then
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        return r, g, b
    end
    
    return 0, 0, 0
end

-- Create color string for UI text
function Utils:CreateColorString(text, r, g, b)
    if not text then return "" end
    r = r or 1
    g = g or 1
    b = b or 1
    
    local hex = self:RGBToHex(r, g, b)
    return string.format("|cff%s%s|r", hex, text)
end

--[[
===============================================================================
MULTI-RESOLUTION UTILITIES
===============================================================================
--]]

-- Detect display DPI and resolution characteristics
function Utils:DetectDisplayCharacteristics()
    if not DamiaUI.Resolution then
        return {
            dpi = "standard",
            isHighDPI = false,
            isUltrawide = false,
            aspectRatio = "16:9"
        }
    end
    
    local resolution = DamiaUI.Resolution:GetCurrentResolution()
    return {
        dpi = resolution.dpiCategory,
        isHighDPI = DamiaUI.Resolution:IsHighDPI(),
        isUltrawide = DamiaUI.Resolution:IsUltrawide(),
        aspectRatio = resolution.aspectRatio,
        detected = resolution.detected,
        effectiveScale = resolution.effectiveScale
    }
end

-- Get safe positioning bounds for current resolution
function Utils:GetSafeAreaBounds()
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:GetSafeBounds()
    end
    
    -- Fallback safe area calculation
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    
    return {
        left = width * 0.05,
        right = width * 0.95,
        top = height * 0.95,
        bottom = height * 0.1,
        centerX = width / 2,
        centerY = height / 2,
        safeWidth = width * 0.9,
        safeHeight = height * 0.85
    }
end

-- Check if position is within safe viewing area
function Utils:IsPositionSafe(x, y, frameWidth, frameHeight)
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:IsPositionSafe(x, y, frameWidth, frameHeight)
    end
    
    -- Fallback safety check
    local bounds = self:GetSafeAreaBounds()
    frameWidth = frameWidth or 0
    frameHeight = frameHeight or 0
    
    local halfWidth = frameWidth / 2
    local halfHeight = frameHeight / 2
    
    return (x - halfWidth) >= bounds.left and
           (x + halfWidth) <= bounds.right and
           (y - halfHeight) >= bounds.bottom and
           (y + halfHeight) <= bounds.top
end

-- Constrain position to safe area
function Utils:ConstrainToSafeArea(x, y, frameWidth, frameHeight)
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:ConstrainToSafeBounds(x, y, frameWidth, frameHeight)
    end
    
    -- Fallback constraint
    local bounds = self:GetSafeAreaBounds()
    frameWidth = frameWidth or 0
    frameHeight = frameHeight or 0
    
    local halfWidth = frameWidth / 2
    local halfHeight = frameHeight / 2
    
    if (x - halfWidth) < bounds.left then
        x = bounds.left + halfWidth
    elseif (x + halfWidth) > bounds.right then
        x = bounds.right - halfWidth
    end
    
    if (y - halfHeight) < bounds.bottom then
        y = bounds.bottom + halfHeight
    elseif (y + halfHeight) > bounds.top then
        y = bounds.top - halfHeight
    end
    
    return x, y
end

-- Get optimal scale for specific frame type
function Utils:GetOptimalFrameScale(frameType, baseScale)
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:GetRecommendedScale(frameType, baseScale)
    end
    
    -- Fallback scale calculation
    baseScale = baseScale or 1.0
    local uiScale = self:GetUIScale()
    
    local frameScales = {
        player = 1.0,
        target = 1.0,
        focus = 0.8,
        party = 0.9,
        raid = 0.75,
        actionbar = 1.0
    }
    
    local adjustment = frameScales[frameType] or 1.0
    return baseScale * uiScale * adjustment
end

-- Adapt position for current aspect ratio
function Utils:AdaptPositionForDisplay(x, y, frameType)
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:AdaptPositionForAspectRatio(x, y, frameType)
    end
    
    -- Fallback: no adaptation
    return x, y
end

-- Get layout adjustments for current display
function Utils:GetDisplayLayoutAdjustments()
    if DamiaUI.Resolution then
        return DamiaUI.Resolution:GetLayoutAdjustments()
    end
    
    -- Fallback: standard adjustments
    return {
        horizontalSpread = 1.0,
        verticalSpacing = 1.0,
        elementScale = 1.0,
        safeZoneMargin = 0
    }
end

-- Position frame with automatic aspect ratio adaptation
function Utils:PositionFrameAdaptive(frame, offsetX, offsetY, frameType, point, respectSafeZone)
    if not frame then
        return false
    end
    
    -- Adapt position for current display
    local adaptedX, adaptedY = self:AdaptPositionForDisplay(offsetX or 0, offsetY or 0, frameType)
    
    -- Position the frame
    return self:PositionFrame(frame, adaptedX, adaptedY, point, respectSafeZone)
end

-- Scale frame with optimal settings for current resolution
function Utils:ScaleFrameOptimal(frame, frameType, baseScale)
    if not frame or not frame.SetScale then
        return false
    end
    
    local optimalScale = self:GetOptimalFrameScale(frameType, baseScale)
    frame:SetScale(optimalScale)
    
    return true
end

-- Get recommended frame size for current resolution
function Utils:GetRecommendedFrameSize(frameType, baseWidth, baseHeight)
    if DamiaUI.Resolution then
        -- Use Resolution module's calculation if available
        local width, height = DamiaUI.Resolution:GetRecommendedFrameSize(frameType)
        if width and height then
            return width, height
        end
    end
    
    -- Fallback calculation
    baseWidth = baseWidth or 200
    baseHeight = baseHeight or 50
    
    local scale = self:GetOptimalFrameScale(frameType, 1.0)
    return math.floor(baseWidth * scale + 0.5), math.floor(baseHeight * scale + 0.5)
end

--[[
===============================================================================
INITIALIZATION AND CLEANUP
===============================================================================
--]]

-- Enhanced frame pooling controls
function Utils:SetFramePoolingEnabled(enabled)
    useFramePooling = enabled
    DamiaUI.Engine:LogInfo("Frame pooling %s", enabled and "enabled" or "disabled")
end

function Utils:GetFramePoolingStats()
    local totalPooled = 0
    for _, pool in pairs(framePool) do
        totalPooled = totalPooled + #pool
    end
    
    return {
        created = poolStats.created,
        reused = poolStats.reused,
        cleaned = poolStats.cleaned,
        currentlyPooled = totalPooled,
        poolTypes = DamiaUI.Utils:GetTableSize(framePool),
        reuseRate = poolStats.reused > 0 and (poolStats.reused / (poolStats.created + poolStats.reused) * 100) or 0,
        enabled = useFramePooling,
    }
end

function Utils:ResetFramePoolStats()
    poolStats.created = 0
    poolStats.reused = 0
    poolStats.cleaned = 0
end

-- Set up periodic cleanup
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:SetScript("OnUpdate", function()
    Utils:CleanupFramePools()
end)

-- Register for performance events
if DamiaUI.Events then
    DamiaUI.Events:RegisterCustomEvent("DAMIA_MEMORY_WARNING", function()
        Utils:CleanupFramePools(true) -- Aggressive cleanup
    end, 3, "Utils_MemoryWarning")
    
    DamiaUI.Events:RegisterCustomEvent("DAMIA_PERFORMANCE_DEGRADED", function()
        Utils:CleanupFramePools(true)
    end, 3, "Utils_PerformanceDegraded")
end

-- Register with engine
if DamiaUI.Engine then
    DamiaUI.Engine:LogInfo("Core utilities initialized with multi-resolution support")
end