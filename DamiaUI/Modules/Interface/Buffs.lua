--[[
    DamiaUI - Buffs/Debuffs Interface Module
    
    Manages buff and debuff display above unit frames.
    Positions buffs strategically to complement the centered unit frame layout.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tonumber, tostring = type, tonumber, tostring
local math_floor, math_ceil = math.floor, math.ceil
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
-- Use compatibility layer for deprecated API functions
local Compatibility = DamiaUI.Compatibility
local UnitAura = Compatibility and Compatibility.UnitAura or UnitAura
local UnitBuff = Compatibility and Compatibility.UnitBuff or UnitBuff
local UnitDebuff = Compatibility and Compatibility.UnitDebuff or UnitDebuff

-- Initialize buffs module
local Buffs = {}
DamiaUI.Interface = DamiaUI.Interface or {}
DamiaUI.Interface.Buffs = Buffs

-- Module state
local Aurora
local isInitialized = false
local buffFrames = {}
local updateTimer

-- Buff display configuration based on viewport-first design
local BUFF_CONFIG = {
    -- Positions above unit frames (complementing center-focused layout)
    positions = {
        player = { x = -200, y = 20, anchor = "BOTTOM", relativeTo = "TOP" },
        target = { x = 200, y = 20, anchor = "BOTTOM", relativeTo = "TOP" },
        focus = { x = 0, y = 60, anchor = "BOTTOM", relativeTo = "TOP" },
        party = { x = -400, y = 50, anchor = "RIGHT", relativeTo = "LEFT" },
        raid = { x = -500, y = 240, anchor = "BOTTOM", relativeTo = "TOP" }
    },
    
    dimensions = {
        iconSize = 20,
        spacing = 2,
        maxBuffsPerRow = 8,
        maxDebuffsPerRow = 6,
        maxRows = 2,
        stackFontSize = 10,
        durationFontSize = 9
    },
    
    appearance = {
        showBuffs = true,
        showDebuffs = true,
        showDuration = true,
        showStacks = true,
        highlightDispellable = true,
        fadeOutOfRange = true,
        borderSize = 1,
        cooldownSwipe = true
    },
    
    filtering = {
        showOnlyMine = false,
        hideBlizzardBuffs = true,
        blacklist = {
            -- Common useless buffs
            [1] = "Well Fed", -- Example blacklist entries
            [2] = "Food", 
        },
        priorityList = {
            -- Priority debuffs that should always show
            [1] = "Magic",
            [2] = "Disease", 
            [3] = "Poison",
            [4] = "Curse"
        }
    },
    
    combat = {
        hideInCombat = false,
        fadeAlpha = 0.7,
        showOnlyImportant = false
    }
}

-- Aura importance classification
local AURA_IMPORTANCE = {
    CRITICAL = 1,
    HIGH = 2,
    MEDIUM = 3,
    LOW = 4,
    IGNORED = 5
}

--[[
    Positioning System
    Following the centered viewport-first design
]]
local function GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    return (centerX + offsetX) / uiScale, (centerY + offsetY) / uiScale
end

local function GetUnitFramePosition(unit)
    -- Get position relative to the unit frame (assuming oUF frame exists)
    local unitFrame = _G["DamiaUI_" .. unit:gsub("^%l", string.upper)]
    if unitFrame then
        return unitFrame:GetRect()
    end
    
    -- Fallback to configured positions
    local config = BUFF_CONFIG.positions[unit]
    if config then
        return GetCenterPosition(config.x, config.y)
    end
    
    return GetCenterPosition(0, 0)
end

--[[
    Aura Classification and Filtering
]]
local function ClassifyAura(name, spellId, debuffType, isHarmful, canDispel, isMine)
    -- Priority debuffs
    if isHarmful then
        if canDispel then
            return AURA_IMPORTANCE.CRITICAL
        end
        
        if debuffType and BUFF_CONFIG.filtering.priorityList then
            for _, priorityType in ipairs(BUFF_CONFIG.filtering.priorityList) do
                if debuffType == priorityType then
                    return AURA_IMPORTANCE.HIGH
                end
            end
        end
        
        if isMine then
            return AURA_IMPORTANCE.HIGH
        end
        
        return AURA_IMPORTANCE.MEDIUM
    else
        -- Buffs
        if isMine then
            return AURA_IMPORTANCE.MEDIUM
        end
        
        return AURA_IMPORTANCE.LOW
    end
end

local function ShouldShowAura(name, spellId, debuffType, isHarmful, canDispel, isMine, duration)
    local config = BUFF_CONFIG.filtering
    
    -- Check blacklist
    if config.blacklist then
        for _, blacklistedName in ipairs(config.blacklist) do
            if name == blacklistedName then
                return false
            end
        end
    end
    
    -- Show only mine filter
    if config.showOnlyMine and not isMine then
        return false
    end
    
    -- Always show dispellable debuffs
    if isHarmful and canDispel then
        return true
    end
    
    -- Classification-based filtering
    local importance = ClassifyAura(name, spellId, debuffType, isHarmful, canDispel, isMine)
    
    if importance == AURA_IMPORTANCE.IGNORED then
        return false
    end
    
    -- Combat filtering
    if InCombatLockdown() and BUFF_CONFIG.combat.showOnlyImportant then
        return importance <= AURA_IMPORTANCE.MEDIUM
    end
    
    return true
end

--[[
    Buff Frame Creation and Management
]]
local function CreateAuraIcon(parent, index)
    local config = BUFF_CONFIG.dimensions
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(config.iconSize, config.iconSize)
    
    -- Icon texture
    icon.texture = icon:CreateTexture(nil, "BACKGROUND")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Border
    icon.border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    icon.border:SetAllPoints(icon)
    icon.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = BUFF_CONFIG.appearance.borderSize
    })
    
    -- Stack count
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetFont("Fonts\\FRIZQT__.TTF", config.stackFontSize, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    icon.count:SetTextColor(1, 1, 1, 1)
    
    -- Duration text
    icon.duration = icon:CreateFontString(nil, "OVERLAY")
    icon.duration:SetFont("Fonts\\FRIZQT__.TTF", config.durationFontSize, "OUTLINE")
    icon.duration:SetPoint("BOTTOM", icon, "BOTTOM", 0, -12)
    icon.duration:SetTextColor(1, 1, 0.8, 1)
    
    -- Cooldown spiral (if enabled)
    if BUFF_CONFIG.appearance.cooldownSwipe then
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints(icon)
        icon.cooldown:SetReverse(false)
    end
    
    -- Tooltip
    icon:SetScript("OnEnter", function(self)
        if self.spellId then
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetSpellByID(self.spellId)
            GameTooltip:Show()
        end
    end)
    
    icon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Apply Aurora styling
    if Aurora and Aurora.Skin and Aurora.Skin.ButtonWidget then
        Aurora.Skin.ButtonWidget(icon)
    end
    
    return icon
end

local function CreateBuffFrame(unit)
    local frame = CreateFrame("Frame", "DamiaUI_BuffFrame_" .. unit, UIParent)
    local config = BUFF_CONFIG.dimensions
    
    -- Set frame size (will be adjusted based on visible auras)
    frame:SetSize(config.iconSize * config.maxBuffsPerRow + config.spacing * (config.maxBuffsPerRow - 1), 
                  config.iconSize * config.maxRows + config.spacing * (config.maxRows - 1))
    
    -- Position frame
    local position = BUFF_CONFIG.positions[unit]
    if position then
        local x, y = GetCenterPosition(position.x, position.y)
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
    
    -- Create icon pools
    frame.buffIcons = {}
    frame.debuffIcons = {}
    frame.unit = unit
    
    -- Create initial icons
    for i = 1, config.maxBuffsPerRow * config.maxRows do
        frame.buffIcons[i] = CreateAuraIcon(frame, i)
        frame.buffIcons[i]:Hide()
    end
    
    for i = 1, config.maxDebuffsPerRow * config.maxRows do
        frame.debuffIcons[i] = CreateAuraIcon(frame, i)
        frame.debuffIcons[i]:Hide()
    end
    
    buffFrames[unit] = frame
    return frame
end

--[[
    Aura Update Logic
]]
local function UpdateAuraIcon(icon, name, texture, count, debuffType, duration, expirationTime, spellId, isHarmful, canDispel, isMine)
    if not icon then return end
    
    -- Set texture
    icon.texture:SetTexture(texture)
    
    -- Set border color based on type
    local r, g, b = 0.5, 0.5, 0.5 -- Default gray
    if isHarmful then
        if canDispel then
            -- Dispellable debuff - bright red
            r, g, b = 1, 0.2, 0.2
        elseif debuffType then
            -- Color by debuff type
            local colors = {
                Magic = {0.2, 0.6, 1},
                Disease = {0.6, 0.4, 0},
                Poison = {0.2, 0.8, 0.2},
                Curse = {0.6, 0, 1}
            }
            local color = colors[debuffType]
            if color then
                r, g, b = color[1], color[2], color[3]
            end
        else
            r, g, b = 0.8, 0.1, 0.1 -- Generic debuff
        end
    else
        r, g, b = 0.2, 0.8, 0.2 -- Buff
    end
    
    icon.border:SetBackdropBorderColor(r, g, b, 1)
    
    -- Set stack count
    if count and count > 1 and BUFF_CONFIG.appearance.showStacks then
        icon.count:SetText(count)
        icon.count:Show()
    else
        icon.count:Hide()
    end
    
    -- Set duration
    if duration and duration > 0 and BUFF_CONFIG.appearance.showDuration then
        icon.duration:Show()
        if expirationTime and expirationTime > 0 then
            local remaining = expirationTime - GetTime()
            if remaining > 60 then
                icon.duration:SetText(math_floor(remaining / 60) .. "m")
            elseif remaining > 0 then
                icon.duration:SetText(math_floor(remaining) .. "s")
            else
                icon.duration:SetText("0")
            end
        else
            icon.duration:SetText("∞")
        end
    else
        icon.duration:Hide()
    end
    
    -- Set cooldown spiral
    if icon.cooldown and duration and expirationTime and expirationTime > GetTime() then
        icon.cooldown:SetCooldown(expirationTime - duration, duration)
        icon.cooldown:Show()
    elseif icon.cooldown then
        icon.cooldown:Hide()
    end
    
    -- Store spell info for tooltip
    icon.spellId = spellId
    icon.name = name
    icon.isHarmful = isHarmful
    
    icon:Show()
end

local function UpdateBuffFrame(unit)
    local frame = buffFrames[unit]
    if not frame or not UnitExists(unit) then
        return
    end
    
    local config = BUFF_CONFIG
    local buffIndex = 1
    local debuffIndex = 1
    
    -- Hide all icons first
    for _, icon in ipairs(frame.buffIcons) do
        icon:Hide()
    end
    for _, icon in ipairs(frame.debuffIcons) do
        icon:Hide()
    end
    
    -- Process buffs
    if config.appearance.showBuffs then
        for i = 1, 40 do -- Max 40 buffs
            local name, texture, count, debuffType, duration, expirationTime, caster, _, _, spellId = UnitBuff(unit, i)
            if not name then break end
            
            local isMine = caster == "player"
            local canDispel = false -- Buffs generally aren't dispellable by the player
            
            if ShouldShowAura(name, spellId, debuffType, false, canDispel, isMine, duration) and buffIndex <= #frame.buffIcons then
                UpdateAuraIcon(frame.buffIcons[buffIndex], name, texture, count, debuffType, duration, expirationTime, spellId, false, canDispel, isMine)
                buffIndex = buffIndex + 1
            end
        end
    end
    
    -- Process debuffs
    if config.appearance.showDebuffs then
        for i = 1, 40 do -- Max 40 debuffs
            local name, texture, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, _, _, _, _, canDispel = UnitDebuff(unit, i)
            if not name then break end
            
            local isMine = caster == "player"
            
            if ShouldShowAura(name, spellId, debuffType, true, canDispel, isMine, duration) and debuffIndex <= #frame.debuffIcons then
                UpdateAuraIcon(frame.debuffIcons[debuffIndex], name, texture, count, debuffType, duration, expirationTime, spellId, true, canDispel, isMine)
                debuffIndex = debuffIndex + 1
            end
        end
    end
    
    -- Position visible icons
    local function PositionIcons(icons, startY)
        local config = BUFF_CONFIG.dimensions
        local iconsPerRow = config.maxBuffsPerRow
        local currentRow = 0
        local currentCol = 0
        
        for i, icon in ipairs(icons) do
            if icon:IsShown() then
                local x = currentCol * (config.iconSize + config.spacing)
                local y = startY - (currentRow * (config.iconSize + config.spacing))
                
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                
                currentCol = currentCol + 1
                if currentCol >= iconsPerRow then
                    currentCol = 0
                    currentRow = currentRow + 1
                    if currentRow >= config.maxRows then
                        break
                    end
                end
            end
        end
        
        return currentRow
    end
    
    -- Position buffs at the top, debuffs below
    local buffRows = PositionIcons(frame.buffIcons, 0)
    local debuffStartY = -(buffRows + 1) * (config.dimensions.iconSize + config.dimensions.spacing)
    PositionIcons(frame.debuffIcons, debuffStartY)
end

--[[
    Combat State Management
]]
local function UpdateCombatVisibility(inCombat)
    local config = BUFF_CONFIG.combat
    
    for _, frame in pairs(buffFrames) do
        if inCombat and config.hideInCombat then
            frame:Hide()
        elseif inCombat and config.fadeAlpha then
            frame:SetAlpha(config.fadeAlpha)
        else
            frame:Show()
            frame:SetAlpha(1.0)
        end
    end
end

--[[
    Configuration Management
]]
function Buffs:UpdateConfiguration(newConfig)
    if type(newConfig) ~= "table" then
        return
    end
    
    -- Merge configuration
    for key, value in pairs(newConfig) do
        if BUFF_CONFIG[key] then
            if type(value) == "table" and type(BUFF_CONFIG[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    BUFF_CONFIG[key][subKey] = subValue
                end
            else
                BUFF_CONFIG[key] = value
            end
        end
    end
    
    -- Refresh all frames
    self:Refresh()
end

function Buffs:GetConfiguration()
    return BUFF_CONFIG
end

--[[
    Public API
]]
function Buffs:Initialize()
    if isInitialized then
        return true
    end
    
    -- Get Aurora library
    Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora
    
    -- Create buff frames for main units
    local units = {"player", "target", "focus"}
    for _, unit in ipairs(units) do
        CreateBuffFrame(unit)
    end
    
    -- Hide Blizzard buff frames if configured
    if BUFF_CONFIG.filtering.hideBlizzardBuffs then
        BuffFrame:Hide()
        BuffFrame:SetParent(CreateFrame("Frame"))
        DebuffFrame:Hide() 
        DebuffFrame:SetParent(CreateFrame("Frame"))
        TemporaryEnchantFrame:Hide()
        TemporaryEnchantFrame:SetParent(CreateFrame("Frame"))
    end
    
    -- Start update timer
    updateTimer = C_Timer.NewTicker(0.5, function()
        for unit, frame in pairs(buffFrames) do
            UpdateBuffFrame(unit)
        end
    end)
    
    isInitialized = true
    DamiaUI:LogDebug("Buffs module initialized")
    return true
end

function Buffs:Refresh()
    -- Update all frames
    for unit, frame in pairs(buffFrames) do
        UpdateBuffFrame(unit)
    end
end

function Buffs:UpdatePositions()
    for unit, frame in pairs(buffFrames) do
        local position = BUFF_CONFIG.positions[unit]
        if position then
            local x, y = GetCenterPosition(position.x, position.y)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
    end
end

function Buffs:SetCombatState(inCombat)
    UpdateCombatVisibility(inCombat)
end

function Buffs:GetBuffFrame(unit)
    return buffFrames[unit]
end

function Buffs:ForceUpdate()
    for unit in pairs(buffFrames) do
        UpdateBuffFrame(unit)
    end
end

--[[
    Event Handlers
]]
local function OnBuffEvent(event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        if buffFrames[unit] then
            UpdateBuffFrame(unit)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        Buffs:SetCombatState(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Buffs:SetCombatState(false)
    elseif event == "UI_SCALE_CHANGED" then
        C_Timer.After(0.1, function()
            Buffs:UpdatePositions()
        end)
    end
end

-- Register events if DamiaUI event system is available
if DamiaUI and DamiaUI.Events then
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        Buffs:Initialize()
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^interface%.buffs%.") then
            local configPart = key:match("interface%.buffs%.(.+)")
            if configPart then
                Buffs:UpdateConfiguration({[configPart] = newValue})
            end
        end
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", function(event, inCombat)
        Buffs:SetCombatState(inCombat)
    end, 2)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_SCALE_CHANGED", function()
        Buffs:UpdatePositions()
    end, 2)
end

-- Fallback event registration
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", OnBuffEvent)

-- Initialize on load if DamiaUI is ready
if DamiaUI and DamiaUI.IsReady then
    C_Timer.After(2, function()
        Buffs:Initialize()
    end)
end

return Buffs