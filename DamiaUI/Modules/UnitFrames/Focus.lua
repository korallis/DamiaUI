--[[
    DamiaUI - Focus Unit Frame
    Compact focus frame implementation with scaled-down design
    
    Positioned at (0, -40) from screen center for optimal visibility above
    the player/target frames in the classic Damia UI symmetrical layout.
]]

local addonName = ...
local DamiaUI = _G.DamiaUI
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local UnitName, UnitLevel, UnitClassification = UnitName, UnitLevel, UnitClassification
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType
local UnitCanAttack, UnitPlayerControlled = UnitCanAttack, UnitPlayerControlled
local UnitExists = UnitExists
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora
local CombatLockdown = DamiaUI.CombatLockdown

--[[
    Safe focus frame positioning with combat lockdown protection
--]]
local function SafePositionFocusFrame(self)
    if not self then return end
    
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(FOCUS_CONFIG.position.x, FOCUS_CONFIG.position.y)
    
    if CombatLockdown then
        CombatLockdown:SafeSetPoint(self, "CENTER", UIParent, "BOTTOMLEFT", x, y)
        CombatLockdown:SafeSetSize(self, FOCUS_CONFIG.size.width, FOCUS_CONFIG.size.height)
        CombatLockdown:SafeSetScale(self, FOCUS_CONFIG.scale)
    else
        if not InCombatLockdown() then
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            self:SetSize(FOCUS_CONFIG.size.width, FOCUS_CONFIG.size.height)
            self:SetScale(FOCUS_CONFIG.scale)
        else
            DamiaUI.Engine:LogWarning("Focus frame positioning deferred due to combat lockdown")
        end
    end
end

--[[
    Safe focus element updates with combat lockdown protection
--]]
local function SafeUpdateFocusElements(self)
    if not self then return end
    
    if CombatLockdown then
        CombatLockdown:SafeUpdateUnitFrames(function()
            -- Update focus-specific elements
            if self.Castbar and UnitExists("focus") then
                UpdateFocusCastbar(self.Castbar, "focus")
            end
            if self.Level and UnitExists("focus") then
                local level = UnitLevel("focus")
                if level > 0 then
                    self.Level:SetText(level)
                else
                    self.Level:SetText("??")
                end
            end
        end)
    else
        if not InCombatLockdown() then
            if self.Castbar and UnitExists("focus") then
                UpdateFocusCastbar(self.Castbar, "focus")
            end
            if self.Level and UnitExists("focus") then
                local level = UnitLevel("focus")
                if level > 0 then
                    self.Level:SetText(level)
                else
                    self.Level:SetText("??")
                end
            end
        end
    end
end

-- Focus frame specific configuration
local FOCUS_CONFIG = {
    position = { x = 0, y = -40 },
    size = { width = 160, height = 35 },
    scale = 0.8,
    showCastbar = true,
    showPowerBar = false, -- Compact design without power bar
    showLevel = true,
    showClassification = false, -- Too cluttered for small frame
    compactLayout = true,
    castbarHeight = 12
}

--[[
    Create focus-specific elements optimized for compact display
]]
local function CreateFocusElements(self)
    local scale = FOCUS_CONFIG.scale
    
    -- Compact level display
    if FOCUS_CONFIG.showLevel then
        local level = self.Health:CreateFontString(nil, "OVERLAY")
        level:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
        level:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", -2, 10)
        level:SetTextColor(1, 1, 0)
        level:SetJustifyH("RIGHT")
        self.Level = level
    end
    
    -- Compact casting bar positioned below health
    if FOCUS_CONFIG.showCastbar then
        local castbar = CreateFrame("StatusBar", nil, self)
        castbar:SetHeight(FOCUS_CONFIG.castbarHeight * scale)
        castbar:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -2)
        castbar:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -2)
        castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar:SetStatusBarColor(0.8, 0.8, 0.2) -- Slightly different color for focus
        castbar:Hide()
        
        -- Castbar background
        castbar.bg = castbar:CreateTexture(nil, "BORDER")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        castbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        
        -- Compact cast name text (no separate time display due to size)
        local castText = castbar:CreateFontString(nil, "OVERLAY")
        castText:SetFont("Fonts\\FRIZQT__.TTF", 8 * scale, "OUTLINE")
        castText:SetPoint("CENTER", castbar, "CENTER")
        castText:SetTextColor(1, 1, 1)
        castText:SetJustifyH("CENTER")
        castbar.Text = castText
        
        -- Small cast icon
        local castIcon = castbar:CreateTexture(nil, "ARTWORK")
        castIcon:SetSize(FOCUS_CONFIG.castbarHeight * scale, FOCUS_CONFIG.castbarHeight * scale)
        castIcon:SetPoint("RIGHT", castbar, "LEFT", -2, 0)
        castIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        castbar.Icon = castIcon
        
        self.Castbar = castbar
        
        -- Apply Aurora styling to castbar
        if Aurora and Aurora.CreateBorder then
            Aurora.CreateBorder(castbar, 4) -- Smaller border for compact design
            if Aurora.Skin and Aurora.Skin.StatusBarWidget then
                Aurora.Skin.StatusBarWidget(castbar)
            end
        end
    end
    
    -- Focus indicator glow (subtle)
    local focusGlow = self:CreateTexture(nil, "BACKGROUND")
    focusGlow:SetAllPoints(self)
    focusGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    focusGlow:SetBlendMode("ADD")
    focusGlow:SetVertexColor(0, 0.5, 1, 0.2) -- Subtle blue glow
    focusGlow:SetAlpha(0.2)
    self.FocusGlow = focusGlow
    
    return self
end

--[[
    Compact health update for focus frame
]]
local function UpdateFocusHealth(health, unit, min, max)
    if unit ~= "focus" then return end
    
    local frame = health.__owner
    if not frame or not frame.HealthValue then return end
    
    -- Simplified health display for compact frame
    local healthText
    if max > 999999 then
        healthText = string.format("%.1fM", max / 1000000)
    elseif max > 9999 then
        healthText = string.format("%.0fk", max / 1000)
    else
        healthText = tostring(max)
    end
    
    frame.HealthValue:SetText(healthText)
    
    -- Color health bar based on unit reaction (simplified)
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
    Compact castbar update for focus frame
]]
local function UpdateFocusCastbar(castbar, unit)
    if unit ~= "focus" then return end
    
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    
    if not name then
        -- Check for channeling
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
    end
    
    if name then
        castbar:Show()
        
        -- Truncate long spell names for compact display
        local displayText = text or name
        if string.len(displayText) > 18 then
            displayText = string.sub(displayText, 1, 15) .. "..."
        end
        castbar.Text:SetText(displayText)
        
        if texture and castbar.Icon then
            castbar.Icon:SetTexture(texture)
            castbar.Icon:Show()
        end
        
        -- Simplified color coding
        if notInterruptible then
            castbar:SetStatusBarColor(0.6, 0.6, 0.6) -- Gray for uninterruptible
        else
            castbar:SetStatusBarColor(0.8, 0.8, 0.2) -- Yellow for interruptible
        end
    else
        castbar:Hide()
    end
end

--[[
    Focus visibility handler - hide when no focus target
]]
local function UpdateFocusVisibility(self, unit)
    if unit ~= "focus" then return end
    
    if UnitExists(unit) then
        self:Show()
        if self.FocusGlow then
            self.FocusGlow:SetAlpha(0.2)
        end
    else
        self:Hide()
    end
end

--[[
    Focus frame layout function
    Creates a compact version of the Damia layout optimized for focus target
]]
local function CreateFocusLayout(self, unit)
    if unit ~= "focus" then return end
    
    local scale = FOCUS_CONFIG.scale
    
    -- Set frame dimensions and scale
    self:SetSize(FOCUS_CONFIG.size.width * scale, FOCUS_CONFIG.size.height * scale)
    self:SetScale(scale)
    
    -- Position frame using centered coordinate system (with combat lockdown protection)
    SafePositionFocusFrame(self)
    
    -- Create compact health bar (no power bar for focus)
    local health = CreateFrame("StatusBar", nil, self)
    health:SetHeight(18 * scale)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.2, 0.8, 0.2)
    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Compact name text
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 3, 0)
    name:SetTextColor(1, 1, 1)
    name:SetJustifyH("LEFT")
    
    -- Compact health value text
    local healthValue = health:CreateFontString(nil, "OVERLAY")
    healthValue:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
    healthValue:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    healthValue:SetTextColor(1, 1, 1)
    healthValue:SetJustifyH("RIGHT")
    
    -- Register elements with oUF
    self.Health = health
    self.Health.bg = health.bg
    self.Name = name
    self.HealthValue = healthValue
    
    -- Add focus-specific elements
    CreateFocusElements(self)
    
    -- Register focus-specific update functions
    if self.Health then
        self.Health.Override = UpdateFocusHealth
    end
    
    -- Apply Aurora styling with compact borders
    if Aurora and Aurora.CreateBorder then
        Aurora.CreateBorder(self, 6) -- Smaller border for compact design
        if Aurora.Skin and Aurora.Skin.StatusBarWidget then
            Aurora.Skin.StatusBarWidget(health)
        end
    end
    
    -- Register visibility updates
    self:RegisterEvent("PLAYER_FOCUS_CHANGED", UpdateFocusVisibility)
    
    -- Initial visibility check
    UpdateFocusVisibility(self, unit)
    
    return self
end

--[[
    Focus frame configuration access
]]
local function GetFocusConfig()
    return FOCUS_CONFIG
end

local function SetFocusConfig(key, value)
    if FOCUS_CONFIG[key] ~= nil then
        FOCUS_CONFIG[key] = value
        -- Trigger frame update if needed (with combat lockdown protection)
        local focusFrame = DamiaUI.UnitFrames:GetFrame("focus")
        if focusFrame then
            if CombatLockdown then
                CombatLockdown:SafeUpdateUnitFrames(function()
                    DamiaUI.UnitFrames:RefreshFrame("focus")
                end)
            else
                if not InCombatLockdown() then
                    DamiaUI.UnitFrames:RefreshFrame("focus")
                else
                    DamiaUI.Engine:LogWarning("Focus frame refresh deferred due to combat lockdown")
                end
            end
        end
    end
end

-- Export focus-specific functions (only if UnitFrames module exists)
if DamiaUI.UnitFrames and type(DamiaUI.UnitFrames) == "table" then
    DamiaUI.UnitFrames.Focus = {
        CreateLayout = CreateFocusLayout,
        UpdateHealth = UpdateFocusHealth,
        UpdateCastbar = UpdateFocusCastbar,
        UpdateVisibility = UpdateFocusVisibility,
        GetConfig = GetFocusConfig,
        SetConfig = SetFocusConfig,
        SafePosition = SafePositionFocusFrame,
        SafeUpdateElements = SafeUpdateFocusElements
    }
end

--[[
    Focus frame utility functions
]]
local function IsFocusFrameCompact()
    return FOCUS_CONFIG.compactLayout
end

local function ToggleFocusCastbar(enabled)
    FOCUS_CONFIG.showCastbar = enabled
    local focusFrame = DamiaUI.UnitFrames:GetFrame("focus")
    if focusFrame and focusFrame.Castbar then
        if enabled then
            focusFrame.Castbar:Show()
        else
            focusFrame.Castbar:Hide()
        end
    end
end

-- Export focus-specific functions
DamiaUI.UnitFrames.Focus = {
    CreateLayout = CreateFocusLayout,
    UpdateHealth = UpdateFocusHealth,
    UpdateCastbar = UpdateFocusCastbar,
    UpdateVisibility = UpdateFocusVisibility,
    GetConfig = GetFocusConfig,
    SetConfig = SetFocusConfig,
    IsCompact = IsFocusFrameCompact,
    ToggleCastbar = ToggleFocusCastbar
}