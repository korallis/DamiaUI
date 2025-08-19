--[[
    DamiaUI - Arena Unit Frames
    PvP-focused arena frame implementation with enemy tracking
    
    Automatically shows/hides based on PvP context and provides enhanced
    arena-specific functionality including trinket tracking, diminishing returns,
    cooldown monitoring, and spec detection.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local GetTime = GetTime
local UnitName, UnitClass, UnitLevel = UnitName, UnitClass, UnitLevel
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local GetNumArenaOpponents = GetNumArenaOpponents
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Module dependencies with safe checks
local oUF = DamiaUI.Libraries and DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora
local Compatibility = DamiaUI.Compatibility
local CombatLockdown = DamiaUI.CombatLockdown

--[[
    Safe arena frame operations with combat lockdown protection
--]]
local function SafeUpdateArenaFrames()
    if CombatLockdown then
        CombatLockdown:SafeUpdateUnitFrames(function()
            UpdateArenaVisibility()
        end)
    else
        if not InCombatLockdown() then
            UpdateArenaVisibility()
        else
            DamiaUI.Engine:LogWarning("Arena frame update deferred due to combat lockdown")
        end
    end
end

-- Compatibility API references with nil checks
local UnitBuff = Compatibility and Compatibility.UnitBuff or UnitBuff
local UnitDebuff = Compatibility and Compatibility.UnitDebuff or UnitDebuff

-- Arena frame configuration
local ARENA_CONFIG = {
    position = { x = 400, y = 100 },
    size = { width = 220, height = 60 },
    scale = 0.95,
    spacing = 10,
    growth = "DOWN",
    showTrinket = true,
    showDiminishingReturns = true,
    showSpecIcon = true,
    showCastingBar = true,
    showInterruptCooldown = true,
    maxFrames = 5,
    trinketCooldown = 90, -- PvP trinket cooldown
    drCooldown = 18 -- Diminishing returns duration
}

-- Arena frames storage
local arenaFrames = {}
local arenaContainer = nil
local trinketData = {}
local drData = {}

-- PvP trinket item IDs and icons
local TRINKET_ITEMS = {
    [42292] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02", -- Gladiator's Medallion (Alliance)
    [40895] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01", -- Medallion of the Horde
    [195710] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02" -- Gladiator's Medallion (Current)
}

-- Diminishing return categories and spells
local DR_CATEGORIES = {
    -- Stuns
    stun = {
        color = { 1, 0.5, 0 },
        spells = {
            [5211] = true,   -- Bash
            [853] = true,    -- Hammer of Justice  
            [408] = true,    -- Kidney Shot
            [47481] = true,  -- Gnaw
            [30283] = true,  -- Shadowfury
        }
    },
    -- Incapacitates
    incap = {
        color = { 1, 1, 0 },
        spells = {
            [2637] = true,   -- Hibernate
            [118] = true,    -- Polymorph
            [6770] = true,   -- Sap
            [20066] = true,  -- Repentance
            [51514] = true,  -- Hex
        }
    },
    -- Silences
    silence = {
        color = { 0.5, 0, 1 },
        spells = {
            [15487] = true,  -- Silence
            [1330] = true,   -- Garrote
            [47476] = true,  -- Strangulate
        }
    },
    -- Fears
    fear = {
        color = { 0.5, 0, 0.5 },
        spells = {
            [5782] = true,   -- Fear
            [8122] = true,   -- Psychic Scream
            [5484] = true,   -- Howl of Terror
        }
    }
}

-- Interrupt spell cooldowns (in seconds)
local INTERRUPT_COOLDOWNS = {
    [1766] = 15,   -- Kick (Rogue)
    [6552] = 10,   -- Pummel (Warrior)
    [47528] = 10,  -- Mind Freeze (Death Knight) 
    [57994] = 8,   -- Wind Shear (Shaman)
    [183752] = 15, -- Disrupt (Demon Hunter)
    [147362] = 24, -- Counter Shot (Hunter)
    [2139] = 24,   -- Counterspell (Mage)
    [19647] = 24,  -- Spell Lock (Warlock)
    [116705] = 15, -- Spear Hand Strike (Monk)
    [96231] = 15,  -- Rebuke (Paladin)
    [78675] = 60,  -- Solar Beam (Druid)
    [15487] = 45,  -- Silence (Priest)
}

--[[
    Create arena-specific elements for each frame
]]
local function CreateArenaElements(self, unit)
    local scale = ARENA_CONFIG.scale
    local arenaNumber = unit:match("arena(%d)")
    if not arenaNumber then return end
    
    arenaNumber = tonumber(arenaNumber)
    
    -- Spec icon
    if ARENA_CONFIG.showSpecIcon then
        local specIcon = self.Health:CreateTexture(nil, "OVERLAY")
        specIcon:SetSize(20 * scale, 20 * scale)
        specIcon:SetPoint("LEFT", self, "LEFT", -25, 0)
        self.SpecIcon = specIcon
    end
    
    -- Trinket cooldown indicator
    if ARENA_CONFIG.showTrinket then
        local trinket = CreateFrame("Frame", nil, self)
        trinket:SetSize(24 * scale, 24 * scale)
        trinket:SetPoint("RIGHT", self, "RIGHT", 25, 12)
        
        local trinketIcon = trinket:CreateTexture(nil, "ARTWORK")
        trinketIcon:SetAllPoints(trinket)
        trinketIcon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_02")
        
        local trinketCooldown = CreateFrame("Cooldown", nil, trinket, "CooldownFrameTemplate")
        trinketCooldown:SetAllPoints(trinket)
        trinketCooldown:SetDrawEdge(false)
        trinketCooldown:SetDrawSwipe(true)
        trinketCooldown:SetSwipeColor(0, 0, 0, 0.8)
        
        local trinketText = trinket:CreateFontString(nil, "OVERLAY")
        trinketText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
        trinketText:SetPoint("CENTER", trinket, "BOTTOM", 0, -3)
        trinketText:SetTextColor(1, 1, 1)
        
        trinket.icon = trinketIcon
        trinket.cooldown = trinketCooldown  
        trinket.text = trinketText
        self.Trinket = trinket
        
        -- Initialize trinket data
        trinketData[arenaNumber] = {
            available = true,
            lastUsed = 0,
            cooldownDuration = ARENA_CONFIG.trinketCooldown
        }
    end
    
    -- Diminishing returns indicator
    if ARENA_CONFIG.showDiminishingReturns then
        local dr = CreateFrame("Frame", nil, self)
        dr:SetSize(16 * scale, 16 * scale)
        dr:SetPoint("RIGHT", self, "RIGHT", 25, -12)
        
        local drIcon = dr:CreateTexture(nil, "ARTWORK")
        drIcon:SetAllPoints(dr)
        drIcon:SetTexture("Interface\\Icons\\Spell_Nature_Slow")
        drIcon:Hide()
        
        local drCooldown = CreateFrame("Cooldown", nil, dr, "CooldownFrameTemplate")
        drCooldown:SetAllPoints(dr)
        drCooldown:SetDrawEdge(false)
        drCooldown:SetReverse(true)
        
        dr.icon = drIcon
        dr.cooldown = drCooldown
        dr:Hide()
        self.DiminishingReturns = dr
        
        -- Initialize DR data
        drData[arenaNumber] = {}
    end
    
    -- Enhanced casting bar for arena
    if ARENA_CONFIG.showCastingBar then
        local castbar = CreateFrame("StatusBar", nil, self)
        castbar:SetHeight(18 * scale)
        castbar:SetPoint("TOPLEFT", self.Power or self.Health, "BOTTOMLEFT", 0, -4)
        castbar:SetPoint("TOPRIGHT", self.Power or self.Health, "BOTTOMRIGHT", 0, -4)
        castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar:SetStatusBarColor(1, 0.7, 0)
        
        castbar.bg = castbar:CreateTexture(nil, "BORDER")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        
        -- Cast name
        local castText = castbar:CreateFontString(nil, "OVERLAY")
        castText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
        castText:SetPoint("LEFT", castbar, "LEFT", 4, 0)
        castText:SetTextColor(1, 1, 1)
        castText:SetJustifyH("LEFT")
        
        -- Cast time
        local castTime = castbar:CreateFontString(nil, "OVERLAY")
        castTime:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
        castTime:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
        castTime:SetTextColor(1, 1, 1)
        castTime:SetJustifyH("RIGHT")
        
        -- Shield indicator (for uninterruptible casts)
        local shield = castbar:CreateTexture(nil, "OVERLAY")
        shield:SetSize(16 * scale, 16 * scale)
        shield:SetPoint("RIGHT", castbar, "RIGHT", 20, 0)
        shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Arena-Shield")
        shield:Hide()
        
        castbar.Text = castText
        castbar.Time = castTime
        castbar.Shield = shield
        self.Castbar = castbar
    end
    
    -- Interrupt cooldown tracker
    if ARENA_CONFIG.showInterruptCooldown then
        local interrupt = CreateFrame("Frame", nil, self)
        interrupt:SetSize(20 * scale, 20 * scale)
        interrupt:SetPoint("LEFT", self, "LEFT", -25, -20)
        interrupt:Hide()
        
        local interruptIcon = interrupt:CreateTexture(nil, "ARTWORK")
        interruptIcon:SetAllPoints(interrupt)
        interruptIcon:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph")
        
        local interruptCooldown = CreateFrame("Cooldown", nil, interrupt, "CooldownFrameTemplate")
        interruptCooldown:SetAllPoints(interrupt)
        interruptCooldown:SetDrawEdge(false)
        
        interrupt.icon = interruptIcon
        interrupt.cooldown = interruptCooldown
        self.InterruptCooldown = interrupt
    end
    
    return self
end

--[[
    Update trinket cooldown display
]]
local function UpdateTrinketCooldown(arenaNumber)
    local frame = arenaFrames[arenaNumber]
    if not frame or not frame.Trinket then return end
    
    local data = trinketData[arenaNumber]
    if not data then return end
    
    local remaining = (data.lastUsed + data.cooldownDuration) - GetTime()
    
    if remaining > 0 then
        data.available = false
        frame.Trinket.cooldown:SetCooldown(data.lastUsed, data.cooldownDuration)
        frame.Trinket.text:SetText(math.ceil(remaining))
        frame.Trinket.icon:SetDesaturated(true)
        frame.Trinket.icon:SetVertexColor(0.5, 0.5, 0.5)
    else
        data.available = true
        frame.Trinket.cooldown:Clear()
        frame.Trinket.text:SetText("")
        frame.Trinket.icon:SetDesaturated(false)
        frame.Trinket.icon:SetVertexColor(1, 1, 1)
    end
end

--[[
    Update diminishing returns display
]]
local function UpdateDiminishingReturns(arenaNumber, category)
    local frame = arenaFrames[arenaNumber]
    if not frame or not frame.DiminishingReturns then return end
    
    if not drData[arenaNumber] then
        drData[arenaNumber] = {}
    end
    
    local dr = frame.DiminishingReturns
    local now = GetTime()
    
    if category and DR_CATEGORIES[category] then
        drData[arenaNumber][category] = now + ARENA_CONFIG.drCooldown
        
        local color = DR_CATEGORIES[category].color
        dr.icon:SetVertexColor(color[1], color[2], color[3])
        dr.cooldown:SetCooldown(now, ARENA_CONFIG.drCooldown)
        dr:Show()
        
        -- Hide after cooldown
        C_Timer.After(ARENA_CONFIG.drCooldown, function()
            if drData[arenaNumber] and drData[arenaNumber][category] then
                drData[arenaNumber][category] = nil
                dr:Hide()
            end
        end)
    end
end

--[[
    Arena frame layout function
]]
local function CreateArenaLayout(self, unit)
    if not unit:match("arena%d") then return end
    
    local scale = ARENA_CONFIG.scale
    
    -- Set frame dimensions
    self:SetSize(ARENA_CONFIG.size.width * scale, ARENA_CONFIG.size.height * scale)
    self:SetScale(scale)
    
    -- Create health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetHeight(28 * scale)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.8, 0.2, 0.2) -- Red for enemies
    
    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Create power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(10 * scale)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -2)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -2)
    power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    power.bg = power:CreateTexture(nil, "BORDER")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    power.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Name text with level
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 12 * scale, "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 4, 0)
    name:SetTextColor(1, 1, 1)
    name:SetJustifyH("LEFT")
    
    -- Health percentage
    local healthPercent = health:CreateFontString(nil, "OVERLAY")
    healthPercent:SetFont("Fonts\\FRIZQT__.TTF", 11 * scale, "OUTLINE")
    healthPercent:SetPoint("RIGHT", health, "RIGHT", -4, 0)
    healthPercent:SetTextColor(1, 1, 1)
    healthPercent:SetJustifyH("RIGHT")
    
    -- Class text
    local classText = power:CreateFontString(nil, "OVERLAY")
    classText:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
    classText:SetPoint("LEFT", power, "LEFT", 4, 0)
    classText:SetTextColor(0.8, 0.8, 0.8)
    classText:SetJustifyH("LEFT")
    
    -- Register elements with oUF
    self.Health = health
    self.Health.bg = health.bg
    self.Power = power
    self.Power.bg = power.bg
    self.Name = name
    self.HealthPercent = healthPercent
    self.ClassText = classText
    
    -- Add arena-specific elements
    CreateArenaElements(self, unit)
    
    -- Apply Aurora styling
    if Aurora and Aurora.CreateBorder then
        Aurora.CreateBorder(self, 8)
        if Aurora.Skin and Aurora.Skin.StatusBarWidget then
            Aurora.Skin.StatusBarWidget(health)
            Aurora.Skin.StatusBarWidget(power)
            if self.Castbar then
                Aurora.Skin.StatusBarWidget(self.Castbar)
            end
        end
    end
    
    return self
end

--[[
    Create arena container and position frames
]]
local function CreateArenaContainer()
    if arenaContainer then return arenaContainer end
    
    arenaContainer = CreateFrame("Frame", "DamiaUI_ArenaContainer", UIParent)
    arenaContainer:SetSize(ARENA_CONFIG.size.width, 
        ARENA_CONFIG.size.height * ARENA_CONFIG.maxFrames + 
        ARENA_CONFIG.spacing * (ARENA_CONFIG.maxFrames - 1))
    
    -- Position at arena-specific coordinates
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(ARENA_CONFIG.position.x, ARENA_CONFIG.position.y)
    arenaContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    
    return arenaContainer
end

--[[
    Position arena frames in vertical layout
]]
local function PositionArenaFrames()
    if not arenaContainer then return end
    
    local yOffset = 0
    for i = 1, ARENA_CONFIG.maxFrames do
        local frame = arenaFrames[i]
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", arenaContainer, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - (ARENA_CONFIG.size.height + ARENA_CONFIG.spacing) * ARENA_CONFIG.scale
        end
    end
end

--[[
    Update arena visibility based on PvP context
]]
local function UpdateArenaVisibility()
    local inArena = IsActiveBattlefieldArena()
    local numOpponents = GetNumArenaOpponents()
    
    if not arenaContainer then
        CreateArenaContainer()
    end
    
    if inArena and numOpponents > 0 then
        arenaContainer:Show()
        
        -- Show frames for opponents
        for i = 1, numOpponents do
            if arenaFrames[i] then
                arenaFrames[i]:Show()
            end
        end
        
        -- Hide unused frames
        for i = numOpponents + 1, ARENA_CONFIG.maxFrames do
            if arenaFrames[i] then
                arenaFrames[i]:Hide()
            end
        end
    else
        -- Hide all arena frames when not in arena
        if arenaContainer then
            arenaContainer:Hide()
        end
        for i = 1, ARENA_CONFIG.maxFrames do
            if arenaFrames[i] then
                arenaFrames[i]:Hide()
            end
        end
    end
end

--[[
    Initialize arena frames
]]
local function InitializeArenaFrames()
    -- Validate oUF is available
    if not oUF then
        return -- oUF not available, can't create arena frames
    end
    
    -- Create container
    CreateArenaContainer()
    
    -- Register custom layout style
    oUF:RegisterStyle("DamiaArena", CreateArenaLayout)
    
    -- Spawn arena frames
    for i = 1, ARENA_CONFIG.maxFrames do
        local unit = "arena" .. i
        local frameName = "DamiaUI_ArenaFrame" .. i
        
        oUF:SetActiveStyle("DamiaArena")
        local frame = oUF:Spawn(unit, frameName)
        
        if frame then
            frame:SetParent(arenaContainer)
            arenaFrames[i] = frame
        end
    end
    
    -- Position frames
    PositionArenaFrames()
    
    -- Set up event handlers
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE") 
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or 
           event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or 
           event == "ARENA_OPPONENT_UPDATE" then
            UpdateArenaVisibility()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit and unit:match("arena%d") then
                local arenaNumber = tonumber(unit:match("arena(%d)"))
                if arenaNumber and trinketData[arenaNumber] then
                    -- Check if it's a trinket use
                    for itemID, icon in pairs(TRINKET_ITEMS) do
                        if spellID == itemID then
                            trinketData[arenaNumber].lastUsed = GetTime()
                            UpdateTrinketCooldown(arenaNumber)
                            break
                        end
                    end
                    
                    -- Check for interrupt usage
                    if INTERRUPT_COOLDOWNS[spellID] then
                        local frame = arenaFrames[arenaNumber]
                        if frame and frame.InterruptCooldown then
                            frame.InterruptCooldown.cooldown:SetCooldown(GetTime(), INTERRUPT_COOLDOWNS[spellID])
                            frame.InterruptCooldown:Show()
                        end
                    end
                end
            end
        end
    end)
    
    -- Update trinket cooldowns every second
    C_Timer.NewTicker(1, function()
        for i = 1, ARENA_CONFIG.maxFrames do
            if trinketData[i] then
                UpdateTrinketCooldown(i)
            end
        end
    end)
    
    -- Initial visibility update
    UpdateArenaVisibility()
end

--[[
    Get arena configuration
]]
local function GetArenaConfig()
    return ARENA_CONFIG
end

--[[
    Update arena configuration
]]
local function SetArenaConfig(key, value)
    if ARENA_CONFIG[key] ~= nil then
        ARENA_CONFIG[key] = value
        
        if key == "position" then
            if arenaContainer then
                local x, y = DamiaUI.UnitFrames.GetCenterPosition(value.x, value.y)
                arenaContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            end
        elseif key == "scale" or key == "size" or key == "spacing" then
            PositionArenaFrames()
        end
    end
end

--[[
    Public API
]]
local ArenaFrames = {
    Initialize = InitializeArenaFrames,
    UpdateVisibility = UpdateArenaVisibility,
    GetConfig = GetArenaConfig,
    SetConfig = SetArenaConfig,
    GetFrames = function() return arenaFrames end,
    GetContainer = function() return arenaContainer end,
    UpdateTrinketCooldown = UpdateTrinketCooldown,
    UpdateDiminishingReturns = UpdateDiminishingReturns,
    SafeUpdate = SafeUpdateArenaFrames
}

-- Export to DamiaUI namespace (UnitFrames should already exist from UnitFrames.lua)
if DamiaUI.UnitFrames then
    DamiaUI.UnitFrames.Arena = ArenaFrames
end

-- Initialize later when addon is ready
C_Timer.After(0, function()
    InitializeArenaFrames()
end)