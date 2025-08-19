--[[
    DamiaUI - Player Unit Frame
    Specialized player frame implementation with health, power, and text elements
    
    Positioned at (-200, -80) from screen center for optimal left-side placement
    in the classic Damia UI symmetrical layout design.
]]

local addonName = ...
local DamiaUI = _G.DamiaUI
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local UnitName, UnitLevel, UnitClassification = UnitName, UnitLevel, UnitClassification
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType
local GetPowerBarColor = GetPowerBarColor
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora
local CombatLockdown = DamiaUI.CombatLockdown

--[[
    Safe frame positioning with combat lockdown protection
--]]
local function SafePositionPlayerFrame(self)
    if not self then return end
    
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(PLAYER_CONFIG.position.x, PLAYER_CONFIG.position.y)
    
    if CombatLockdown then
        CombatLockdown:SafeSetPoint(self, "CENTER", UIParent, "BOTTOMLEFT", x, y)
        CombatLockdown:SafeSetSize(self, PLAYER_CONFIG.size.width, PLAYER_CONFIG.size.height)
        CombatLockdown:SafeSetScale(self, PLAYER_CONFIG.scale)
    else
        if not InCombatLockdown() then
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            self:SetSize(PLAYER_CONFIG.size.width, PLAYER_CONFIG.size.height)
            self:SetScale(PLAYER_CONFIG.scale)
        else
            DamiaUI.Engine:LogWarning("Player frame positioning deferred due to combat lockdown")
        end
    end
end

--[[
    Safe player element updates with combat lockdown protection
--]]
local function SafeUpdatePlayerElements(self)
    if not self then return end
    
    if CombatLockdown then
        CombatLockdown:SafeUpdateUnitFrames(function()
            -- Update player-specific elements that may require secure frame operations
            if self.Resting then
                self.Resting:SetShown(IsResting())
            end
            if self.Combat then
                self.Combat:SetShown(UnitAffectingCombat("player"))
            end
            if self.PvP then
                self.PvP:SetShown(UnitIsPVP("player"))
            end
        end)
    else
        if not InCombatLockdown() then
            if self.Resting then
                self.Resting:SetShown(IsResting())
            end
            if self.Combat then
                self.Combat:SetShown(UnitAffectingCombat("player"))
            end
            if self.PvP then
                self.PvP:SetShown(UnitIsPVP("player"))
            end
        end
    end
end

-- Player frame specific configuration
local PLAYER_CONFIG = {
    position = { x = -200, y = -80 },
    size = { width = 200, height = 50 },
    scale = 1.0,
    showResting = true,
    showCombat = true,
    showPvPIcon = true,
    showGroupLeader = true,
    showClassPower = true
}

--[[
    Create player-specific elements
    Adds resting state, combat indicator, PvP status, and class power
]]
local function CreatePlayerElements(self)
    local scale = PLAYER_CONFIG.scale
    
    -- Resting indicator
    local resting = self.Health:CreateTexture(nil, "OVERLAY")
    resting:SetSize(16 * scale, 16 * scale)
    resting:SetPoint("TOPLEFT", self, "TOPLEFT", -8, 8)
    resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    resting:SetTexCoord(0, 0.5, 0, 0.5)
    resting:Hide()
    self.Resting = resting
    
    -- Combat indicator
    local combat = self.Health:CreateTexture(nil, "OVERLAY")
    combat:SetSize(16 * scale, 16 * scale)
    combat:SetPoint("TOPRIGHT", self, "TOPRIGHT", 8, 8)
    combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    combat:SetTexCoord(0.5, 1, 0, 0.5)
    combat:Hide()
    self.Combat = combat
    
    -- PvP icon
    local pvp = self.Health:CreateTexture(nil, "OVERLAY")
    pvp:SetSize(14 * scale, 14 * scale)
    pvp:SetPoint("LEFT", self.Name, "RIGHT", 4, 0)
    self.PvP = pvp
    
    -- Group leader icon
    local leader = self.Health:CreateTexture(nil, "OVERLAY")
    leader:SetSize(12 * scale, 12 * scale)
    leader:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, -2)
    leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    self.Leader = leader
    
    -- Threat indicator glow (for player threat on current target)
    local threatGlow = self:CreateTexture(nil, "BACKGROUND")
    threatGlow:SetAllPoints(self)
    threatGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    threatGlow:SetBlendMode("ADD")
    threatGlow:SetAlpha(0)
    self.ThreatIndicator = threatGlow
    
    -- Enhanced casting bar for player
    local castbar = CreateFrame("StatusBar", nil, self)
    castbar:SetHeight(18 * scale)
    castbar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -6)
    castbar:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -6)
    castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castbar:SetStatusBarColor(0.2, 0.8, 0.2) -- Green for player casts
    
    castbar.bg = castbar:CreateTexture(nil, "BORDER")
    castbar.bg:SetAllPoints(castbar)
    castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Cast name text
    local castText = castbar:CreateFontString(nil, "OVERLAY")
    castText:SetFont("Fonts\\FRIZQT__.TTF", 11 * scale, "OUTLINE")
    castText:SetPoint("LEFT", castbar, "LEFT", 4, 0)
    castText:SetTextColor(1, 1, 1)
    castText:SetJustifyH("LEFT")
    
    -- Cast time text
    local castTime = castbar:CreateFontString(nil, "OVERLAY")
    castTime:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    castTime:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
    castTime:SetTextColor(1, 1, 1)
    castTime:SetJustifyH("RIGHT")
    
    -- Cast icon
    local castIcon = castbar:CreateTexture(nil, "ARTWORK")
    castIcon:SetSize(18 * scale, 18 * scale)
    castIcon:SetPoint("LEFT", castbar, "RIGHT", 4, 0)
    castIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    castbar.Text = castText
    castbar.Time = castTime
    castbar.Icon = castIcon
    self.Castbar = castbar
    
    -- Class power bar (for combo points, holy power, etc.)
    if PLAYER_CONFIG.showClassPower then
        local classPower = CreateFrame("Frame", nil, self)
        classPower:SetHeight(6 * scale)
        classPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
        classPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
        
        -- Create individual power segments
        classPower.segments = {}
        for i = 1, 11 do -- Max segments for any class power type
            local segment = CreateFrame("StatusBar", nil, classPower)
            segment:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            segment:SetHeight(6 * scale)
            segment.bg = segment:CreateTexture(nil, "BORDER")
            segment.bg:SetAllPoints(segment)
            segment.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            segment.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
            
            classPower.segments[i] = segment
        end
        
        self.ClassPower = classPower
    end
    
    return self
end

--[[
    Update player-specific power colors based on power type
]]
local function UpdatePlayerPower(power, unit, min, max, _, powerType)
    if unit ~= "player" then return end
    
    local r, g, b = GetPowerBarColor(powerType)
    power:SetStatusBarColor(r, g, b)
    
    -- Update power text
    if power.__owner and power.__owner.PowerValue then
        if max > 0 then
            power.__owner.PowerValue:SetText(string.format("%d/%d", min, max))
        else
            power.__owner.PowerValue:SetText("")
        end
    end
end

--[[
    Update class power display (combo points, holy power, etc.)
]]
local function UpdateClassPower(classPower, unit, powerType, current, max, modRate)
    if unit ~= "player" or not classPower or not classPower.segments then return end
    
    -- Hide all segments first
    for i = 1, #classPower.segments do
        classPower.segments[i]:Hide()
    end
    
    -- Show and position active segments
    if max > 0 and max <= #classPower.segments then
        local segmentWidth = (classPower:GetWidth() - (max - 1) * 2) / max
        
        for i = 1, max do
            local segment = classPower.segments[i]
            segment:SetWidth(segmentWidth)
            segment:ClearAllPoints()
            
            if i == 1 then
                segment:SetPoint("LEFT", classPower, "LEFT")
            else
                segment:SetPoint("LEFT", classPower.segments[i-1], "RIGHT", 2, 0)
            end
            
            -- Set color based on power type
            local r, g, b = 1, 1, 0 -- Default yellow
            if powerType == Enum.PowerType.ComboPoints then
                r, g, b = 1, 0.96, 0.41
            elseif powerType == Enum.PowerType.HolyPower then
                r, g, b = 0.95, 0.90, 0.60
            elseif powerType == Enum.PowerType.SoulShards then
                r, g, b = 0.50, 0.32, 0.85
            elseif powerType == Enum.PowerType.ArcaneCharges then
                r, g, b = 0.1, 0.4, 0.9
            end
            
            if i <= current then
                segment:SetStatusBarColor(r, g, b, 1)
                segment:SetValue(1)
            else
                segment:SetStatusBarColor(r * 0.3, g * 0.3, b * 0.3, 0.6)
                segment:SetValue(0)
            end
            
            segment:Show()
        end
    end
end

-- Forward declaration for UpdatePlayerThreat
local UpdatePlayerThreat

--[[
    Player frame layout function
    Integrates with the main Damia layout while adding player-specific elements
]]
local function CreatePlayerLayout(self, unit)
    if unit ~= "player" then return end
    
    -- Apply base Damia layout
    DamiaUI.UnitFrames.CreateDamiaLayout(self, unit)
    
    -- Add player-specific elements
    CreatePlayerElements(self)
    
    -- Register player-specific update functions
    if self.Power then
        self.Power.Override = UpdatePlayerPower
    end
    
    if self.ClassPower then
        self.ClassPower.Override = UpdateClassPower
    end
    
    -- Register threat events
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", function(self, event, unit)
        if unit == "player" or unit == "target" then
            UpdatePlayerThreat(self)
        end
    end)
    
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function(self, event)
        UpdatePlayerThreat(self)
    end)
    
    -- Position the frame at player-specific coordinates (with combat lockdown protection)
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(PLAYER_CONFIG.position.x, PLAYER_CONFIG.position.y)
    
    if CombatLockdown then
        CombatLockdown:SafeSetPoint(self, "CENTER", UIParent, "BOTTOMLEFT", x, y)
        CombatLockdown:SafeSetSize(self, PLAYER_CONFIG.size.width, PLAYER_CONFIG.size.height)
        CombatLockdown:SafeSetScale(self, PLAYER_CONFIG.scale)
    else
        -- Fallback for when CombatLockdown is not available
        if not InCombatLockdown() then
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            self:SetSize(PLAYER_CONFIG.size.width, PLAYER_CONFIG.size.height)
            self:SetScale(PLAYER_CONFIG.scale)
        else
            DamiaUI.Engine:LogWarning("Player frame positioning deferred due to combat lockdown")
        end
    end
    
    return self
end

--[[
    Update player threat indicator based on current target
]]
UpdatePlayerThreat = function(self)
    if not self.ThreatIndicator or not UnitExists("target") then 
        if self.ThreatIndicator then
            self.ThreatIndicator:SetAlpha(0)
        end
        return 
    end
    
    local threatSituation = UnitThreatSituation("player", "target")
    local colors = {
        [0] = { 0, 0, 0, 0 },           -- No threat
        [1] = { 1, 1, 0, 0.2 },         -- Low threat (yellow)
        [2] = { 1, 0.5, 0, 0.4 },       -- Medium threat (orange)
        [3] = { 1, 0, 0, 0.6 }          -- High threat (red)
    }
    
    local color = colors[threatSituation or 0]
    self.ThreatIndicator:SetVertexColor(color[1], color[2], color[3])
    self.ThreatIndicator:SetAlpha(color[4])
    
    -- Add pulsing effect for high threat
    if threatSituation and threatSituation >= 3 then
        if not self.ThreatIndicator.pulseAnim then
            local animGroup = self.ThreatIndicator:CreateAnimationGroup()
            local fadeOut = animGroup:CreateAnimation("Alpha")
            fadeOut:SetFromAlpha(0.6)
            fadeOut:SetToAlpha(0.2)
            fadeOut:SetDuration(0.5)
            fadeOut:SetOrder(1)
            
            local fadeIn = animGroup:CreateAnimation("Alpha")
            fadeIn:SetFromAlpha(0.2)
            fadeIn:SetToAlpha(0.6)
            fadeIn:SetDuration(0.5)
            fadeIn:SetOrder(2)
            
            animGroup:SetLooping("REPEAT")
            self.ThreatIndicator.pulseAnim = animGroup
        end
        self.ThreatIndicator.pulseAnim:Play()
    else
        if self.ThreatIndicator.pulseAnim then
            self.ThreatIndicator.pulseAnim:Stop()
        end
    end
end

--[[
    Enhanced health update for player frame
    Shows more detailed health information and status effects
]]
local function UpdatePlayerHealth(health, unit, min, max)
    if unit ~= "player" then return end
    
    local frame = health.__owner
    if not frame or not frame.HealthValue then return end
    
    -- Calculate health percentage
    local percent = (min / max) * 100
    
    -- Format health text with percentage
    local healthText
    if max > 999999 then
        healthText = string.format("%.1fM (%.0f%%)", max / 1000000, percent)
    elseif max > 999 then
        healthText = string.format("%.0fk (%.0f%%)", max / 1000, percent)
    else
        healthText = string.format("%d (%.0f%%)", max, percent)
    end
    
    frame.HealthValue:SetText(healthText)
    
    -- Update health bar color based on percentage
    if percent > 60 then
        health:SetStatusBarColor(0.2, 0.8, 0.2) -- Green
    elseif percent > 25 then
        health:SetStatusBarColor(0.8, 0.8, 0.2) -- Yellow
    else
        health:SetStatusBarColor(0.8, 0.2, 0.2) -- Red
    end
    
    -- Update threat indicator
    UpdatePlayerThreat(frame)
end

--[[
    Player frame configuration access
]]
local function GetPlayerConfig()
    return PLAYER_CONFIG
end

local function SetPlayerConfig(key, value)
    if PLAYER_CONFIG[key] ~= nil then
        PLAYER_CONFIG[key] = value
        -- Trigger frame update if needed (with combat lockdown protection)
        local playerFrame = DamiaUI.UnitFrames:GetFrame("player")
        if playerFrame then
            if CombatLockdown then
                CombatLockdown:SafeUpdateUnitFrames(function()
                    DamiaUI.UnitFrames:RefreshFrame("player")
                end)
            else
                -- Fallback for when CombatLockdown is not available
                if not InCombatLockdown() then
                    DamiaUI.UnitFrames:RefreshFrame("player")
                else
                    DamiaUI.Engine:LogWarning("Player frame refresh deferred due to combat lockdown")
                end
            end
        end
    end
end

-- Export player-specific functions (only if UnitFrames module exists)
if DamiaUI.UnitFrames and type(DamiaUI.UnitFrames) == "table" then
    DamiaUI.UnitFrames.Player = {
        CreateLayout = CreatePlayerLayout,
        UpdateHealth = UpdatePlayerHealth,
        UpdatePower = UpdatePlayerPower,
        UpdateClassPower = UpdateClassPower,
        UpdateThreat = UpdatePlayerThreat,
        GetConfig = GetPlayerConfig,
        SetConfig = SetPlayerConfig,
        SafePosition = SafePositionPlayerFrame,
        SafeUpdateElements = SafeUpdatePlayerElements
    }
end