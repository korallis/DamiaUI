--[[
    DamiaUI - Target Unit Frame
    Symmetrical target frame implementation with casting bar and threat detection
    
    Positioned at (200, -80) from screen center for optimal right-side placement
    creating perfect symmetry with the player frame in the Damia UI layout.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local UnitName, UnitLevel, UnitClassification = UnitName, UnitLevel, UnitClassification
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType
local UnitCanAttack, UnitPlayerControlled = UnitCanAttack, UnitPlayerControlled
local UnitCreatureType, UnitCreatureFamily = UnitCreatureType, UnitCreatureFamily
local UnitThreatSituation = UnitThreatSituation
local CreateFrame = CreateFrame
local GetTime = GetTime

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora

-- Target frame specific configuration
local TARGET_CONFIG = {
    position = { x = 200, y = -80 },
    size = { width = 200, height = 50 },
    scale = 1.0,
    showCastbar = true,
    showThreat = true,
    showClassification = true,
    showTooltipOnMouseover = true,
    castbarHeight = 16,
    threatColors = {
        [0] = { r = 0.69, g = 0.69, b = 0.69 }, -- No threat (gray)
        [1] = { r = 1.00, g = 1.00, b = 0.47 }, -- Low threat (yellow)
        [2] = { r = 1.00, g = 0.60, b = 0.00 }, -- Medium threat (orange)  
        [3] = { r = 1.00, g = 0.00, b = 0.00 }, -- High threat (red)
    }
}

--[[
    Create target-specific elements
    Adds casting bar, threat indicator, classification, and level display
]]
local function CreateTargetElements(self)
    local scale = TARGET_CONFIG.scale
    
    -- Level text with classification
    local level = self.Health:CreateFontString(nil, "OVERLAY")
    level:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    level:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", -4, 12)
    level:SetTextColor(1, 1, 0)
    level:SetJustifyH("RIGHT")
    self.Level = level
    
    -- Classification text (Elite, Rare, Boss, etc.)
    local classification = self.Health:CreateFontString(nil, "OVERLAY") 
    classification:SetFont("Fonts\\FRIZQT__.TTF", 8 * scale, "OUTLINE")
    classification:SetPoint("RIGHT", level, "LEFT", -2, 0)
    classification:SetTextColor(1, 0.5, 0)
    classification:SetJustifyH("RIGHT")
    self.Classification = classification
    
    -- Threat indicator glow
    local threat = self:CreateTexture(nil, "BACKGROUND")
    threat:SetAllPoints(self)
    threat:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    threat:SetBlendMode("ADD")
    threat:SetAlpha(0)
    self.ThreatIndicator = threat
    
    -- Casting bar
    if TARGET_CONFIG.showCastbar then
        local castbar = CreateFrame("StatusBar", nil, self)
        castbar:SetHeight(TARGET_CONFIG.castbarHeight * scale)
        castbar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -4)
        castbar:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -4)
        castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar:SetStatusBarColor(1, 0.7, 0)
        castbar:Hide()
        
        -- Castbar background
        castbar.bg = castbar:CreateTexture(nil, "BORDER")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        
        -- Cast name text
        local castText = castbar:CreateFontString(nil, "OVERLAY")
        castText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
        castText:SetPoint("LEFT", castbar, "LEFT", 4, 0)
        castText:SetTextColor(1, 1, 1)
        castText:SetJustifyH("LEFT")
        castbar.Text = castText
        
        -- Cast time text
        local castTime = castbar:CreateFontString(nil, "OVERLAY")
        castTime:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
        castTime:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
        castTime:SetTextColor(1, 1, 1)
        castTime:SetJustifyH("RIGHT")
        castbar.Time = castTime
        
        -- Cast icon
        local castIcon = castbar:CreateTexture(nil, "ARTWORK")
        castIcon:SetSize(TARGET_CONFIG.castbarHeight * scale, TARGET_CONFIG.castbarHeight * scale)
        castIcon:SetPoint("RIGHT", castbar, "LEFT", -4, 0)
        castIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        castbar.Icon = castIcon
        
        -- Shield for uninterruptible casts
        local shield = castbar:CreateTexture(nil, "OVERLAY")
        shield:SetSize(16 * scale, 16 * scale)
        shield:SetPoint("CENTER", castIcon, "CENTER")
        shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Arena-Shield")
        shield:Hide()
        castbar.Shield = shield
        
        self.Castbar = castbar
        
        -- Apply Aurora styling to castbar
        if Aurora and Aurora.CreateBorder then
            Aurora.CreateBorder(castbar, 6)
            if Aurora.Skin and Aurora.Skin.StatusBarWidget then
                Aurora.Skin.StatusBarWidget(castbar)
            end
        end
    end
    
    return self
end

--[[
    Update target classification display
]]
local function UpdateClassification(self, unit)
    if unit ~= "target" or not self.Classification then return end
    
    local classification = UnitClassification(unit)
    local level = UnitLevel(unit)
    local text = ""
    
    if classification == "worldboss" then
        text = "Boss"
        self.Classification:SetTextColor(1, 0, 0) -- Red
    elseif classification == "rareelite" then
        text = "Rare Elite"
        self.Classification:SetTextColor(1, 0.5, 1) -- Pink
    elseif classification == "rare" then
        text = "Rare"
        self.Classification:SetTextColor(1, 0.5, 1) -- Pink
    elseif classification == "elite" then
        text = "Elite"
        self.Classification:SetTextColor(1, 1, 0) -- Yellow
    end
    
    self.Classification:SetText(text)
end

--[[
    Update threat indicator with smooth color transitions
]]
local function UpdateThreat(self, unit, status)
    if unit ~= "target" or not self.ThreatIndicator then return end
    
    local color = TARGET_CONFIG.threatColors[status or 0]
    if color then
        self.ThreatIndicator:SetVertexColor(color.r, color.g, color.b)
        
        -- Animate threat changes
        if status and status > 1 then
            self.ThreatIndicator:SetAlpha(0.3)
            -- Could add pulsing animation here
        else
            self.ThreatIndicator:SetAlpha(0)
        end
    end
end

--[[
    Enhanced castbar update with interrupt detection and spell priority
]]
local function UpdateCastbar(castbar, unit)
    if unit ~= "target" then return end
    
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    local isChanneling = false
    
    if not name then
        -- Check for channeling
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        isChanneling = true
    end
    
    if name then
        castbar:Show()
        castbar.Text:SetText(text or name)
        
        if texture and castbar.Icon then
            castbar.Icon:SetTexture(texture)
            castbar.Icon:Show()
        end
        
        -- Show shield for uninterruptible casts
        if castbar.Shield then
            if notInterruptible then
                castbar.Shield:Show()
            else
                castbar.Shield:Hide()
            end
        end
        
        -- Update cast time with better formatting
        if startTime and endTime and castbar.Time then
            local currentTime = GetTime() * 1000
            local timeLeft = (endTime - currentTime) / 1000
            local totalTime = (endTime - startTime) / 1000
            
            if timeLeft > 0 then
                if isChanneling then
                    castbar.Time:SetText(string.format("%.1f / %.1f", timeLeft, totalTime))
                else
                    castbar.Time:SetText(string.format("%.1f", timeLeft))
                end
                
                -- Update progress bar
                local progress = 1 - (timeLeft / totalTime)
                if isChanneling then
                    progress = timeLeft / totalTime
                end
                castbar:SetValue(progress)
            end
        end
        
        -- Enhanced color coding based on spell importance
        if notInterruptible then
            castbar:SetStatusBarColor(0.7, 0.7, 0.7) -- Gray for uninterruptible
        elseif IsImportantSpell(name) then
            castbar:SetStatusBarColor(1, 0.2, 0.2) -- Red for important/dangerous spells
        else
            castbar:SetStatusBarColor(1, 0.7, 0) -- Orange for normal interruptible
        end
        
        -- Add pulsing effect for important casts
        if IsImportantSpell(name) and not notInterruptible then
            if not castbar.pulseAnim then
                local animGroup = castbar:CreateAnimationGroup()
                local fadeOut = animGroup:CreateAnimation("Alpha")
                fadeOut:SetFromAlpha(1.0)
                fadeOut:SetToAlpha(0.6)
                fadeOut:SetDuration(0.5)
                fadeOut:SetOrder(1)
                
                local fadeIn = animGroup:CreateAnimation("Alpha")
                fadeIn:SetFromAlpha(0.6)
                fadeIn:SetToAlpha(1.0)
                fadeIn:SetDuration(0.5)
                fadeIn:SetOrder(2)
                
                animGroup:SetLooping("REPEAT")
                castbar.pulseAnim = animGroup
            end
            castbar.pulseAnim:Play()
        else
            if castbar.pulseAnim then
                castbar.pulseAnim:Stop()
            end
        end
    else
        castbar:Hide()
        if castbar.pulseAnim then
            castbar.pulseAnim:Stop()
        end
    end
end

--[[
    Check if a spell is considered important/dangerous
]]
local function IsImportantSpell(spellName)
    if not spellName then return false end
    
    local importantSpells = {
        -- Healing spells
        ["Heal"] = true,
        ["Greater Heal"] = true,
        ["Flash Heal"] = true,
        ["Healing Wave"] = true,
        ["Chain Heal"] = true,
        ["Holy Light"] = true,
        ["Flash of Light"] = true,
        ["Regrowth"] = true,
        ["Healing Touch"] = true,
        
        -- Crowd control
        ["Polymorph"] = true,
        ["Fear"] = true,
        ["Banish"] = true,
        ["Cyclone"] = true,
        ["Hibernate"] = true,
        ["Hex"] = true,
        
        -- High damage spells
        ["Pyroblast"] = true,
        ["Greater Fireball"] = true,
        ["Chain Lightning"] = true,
        ["Mind Blast"] = true,
        ["Shadow Bolt"] = true,
        ["Soul Burn"] = true
    }
    
    return importantSpells[spellName] or false
end

--[[
    Target frame health update with threat-aware coloring
]]
local function UpdateTargetHealth(health, unit, min, max)
    if unit ~= "target" then return end
    
    local frame = health.__owner
    if not frame or not frame.HealthValue then return end
    
    -- Format health values
    local healthText
    if max > 999999 then
        healthText = string.format("%.1fM", max / 1000000)
    elseif max > 999 then
        healthText = string.format("%.0fk", max / 1000)
    else
        healthText = tostring(max)
    end
    
    frame.HealthValue:SetText(healthText)
    
    -- Color health bar based on unit reaction
    local r, g, b = 0.2, 0.8, 0.2 -- Default green
    
    if UnitCanAttack("player", unit) then
        if UnitPlayerControlled(unit) then
            r, g, b = 1, 0, 0 -- Red for hostile players
        else
            r, g, b = 1, 0.5, 0 -- Orange for hostile NPCs
        end
    elseif UnitPlayerControlled(unit) then
        r, g, b = 0, 0.5, 1 -- Blue for friendly players
    end
    
    health:SetStatusBarColor(r, g, b)
end

--[[
    Target frame layout function
    Integrates with the main Damia layout while adding target-specific elements
]]
local function CreateTargetLayout(self, unit)
    if unit ~= "target" then return end
    
    -- Apply base Damia layout
    DamiaUI.UnitFrames.CreateDamiaLayout(self, unit)
    
    -- Add target-specific elements
    CreateTargetElements(self)
    
    -- Register target-specific update functions
    if self.Health then
        self.Health.Override = UpdateTargetHealth
    end
    
    -- Override threat update
    self.UpdateThreatStatus = UpdateThreat
    
    -- Position the frame at target-specific coordinates
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(TARGET_CONFIG.position.x, TARGET_CONFIG.position.y)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    self:SetSize(TARGET_CONFIG.size.width, TARGET_CONFIG.size.height)
    self:SetScale(TARGET_CONFIG.scale)
    
    -- Register events for target-specific updates
    self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateClassification)
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", function(self, event, unit)
        if unit == "target" then
            local status = UnitThreatSituation("player", unit)
            UpdateThreat(self, unit, status)
        end
    end)
    
    return self
end

--[[
    Target frame configuration access
]]
local function GetTargetConfig()
    return TARGET_CONFIG
end

local function SetTargetConfig(key, value)
    if TARGET_CONFIG[key] ~= nil then
        TARGET_CONFIG[key] = value
        -- Trigger frame update if needed
        local targetFrame = DamiaUI.UnitFrames:GetFrame("target")
        if targetFrame then
            DamiaUI.UnitFrames:RefreshFrame("target")
        end
    end
end

-- Export target-specific functions
DamiaUI.UnitFrames.Target = {
    CreateLayout = CreateTargetLayout,
    UpdateHealth = UpdateTargetHealth,
    UpdateCastbar = UpdateCastbar,
    UpdateThreat = UpdateThreat,
    UpdateClassification = UpdateClassification,
    GetConfig = GetTargetConfig,
    SetConfig = SetTargetConfig
}