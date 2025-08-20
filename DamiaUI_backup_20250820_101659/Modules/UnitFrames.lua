local _, DamiaUI = ...

-- =============================================================================
-- UNIT FRAMES MODULE - Phase 3 Implementation
-- =============================================================================
-- Based on GW2_UI patterns:
-- 1. Use SecureUnitButtonTemplate for clickable frames
-- 2. Use BackdropTemplate for proper backdrop support
-- 3. Implement health prediction and smooth animations
-- 4. Handle power bar colors dynamically based on power type
-- 5. Register proper unit events for real-time updates
-- 6. Support class colors for players, reaction colors for NPCs
-- 7. Use RegisterUnitWatch for automatic show/hide

local UnitFrames = DamiaUI:CreateModule("UnitFrames")

-- Constants
local PLAYER_FRAME_SIZE = {210, 26}
local TARGET_FRAME_SIZE = {210, 26}
local FOCUS_FRAME_SIZE = {160, 40}

local BACKDROP_CONFIG = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Create animated status bar (simplified version of GW2_UI pattern)
local function CreateAnimatedStatusBar(name, parent, texture)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture(texture or "Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)
    
    -- Add smooth animation support
    bar.animationSpeed = 0.3
    bar.targetValue = 100
    bar.currentValue = 100
    
    return bar
end

-- Add a right-side indicator box with 1px borders (matches screenshot detail)
local function AddRightIndicator(frame)
    if frame.indicator then return end
    local box = DamiaUI:CreateBorderedPanel(nil, frame)
    box:SetSize(26, 16)
    box:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    box.bg:SetColorTexture(0, 0, 0, 0.9)
    -- subtle vertical ticks
    for i = 1, 3 do
        local tick = box:CreateTexture(nil, "BORDER")
        tick:SetWidth(1)
        tick:SetColorTexture(unpack(DamiaUI.Theme.border))
        tick:SetPoint("TOPLEFT", box, "TOPLEFT", i * 6, 0)
        tick:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", i * 6, 0)
    end
    frame.indicator = box
end

-- Get unit color based on class/reaction
local function GetUnitHealthColor(unit)
    if not UnitExists(unit) then
        return 0.5, 0.5, 0.5
    end
    
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        -- Safe check for RAID_CLASS_COLORS
        local classColors = _G.RAID_CLASS_COLORS or {}
        local color = classColors[class]
        if color then
            return color.r, color.g, color.b
        end
    else
        local reaction = UnitReaction(unit, "player")
        if reaction then
            if reaction <= 3 then
                return 1, 0.2, 0.2  -- Hostile (red)
            elseif reaction == 4 then
                return 1, 1, 0      -- Neutral (yellow)
            else
                return 0.2, 1, 0.2  -- Friendly (green)
            end
        end
    end
    
    return 0.5, 0.5, 0.5  -- Default gray
end

-- Get power color based on power type
local function GetPowerColor(powerType)
    local colors = DamiaUI.PowerColors
    return colors[powerType] or {0.5, 0.5, 0.5}
end

-- Update health bar with smooth animation
local function UpdateHealthBar(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local healthPercent = (health / maxHealth) * 100
    
    -- Update health bar
    frame.healthBar:SetMinMaxValues(0, maxHealth)
    frame.healthBar:SetValue(health)
    
    -- Update health text
    if frame.healthText then
        frame.healthText:SetText(string.format("%.0f%%", healthPercent))
    end
    
    -- Update health bar color
    local r, g, b = GetUnitHealthColor(unit)
    frame.healthBar:SetStatusBarColor(r, g, b)
end

-- Update power bar
local function UpdatePowerBar(frame)
    local unit = frame.unit
    if not UnitExists(unit) or not frame.powerBar then return end
    
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local powerType = UnitPowerType(unit)
    
    -- Update power bar
    frame.powerBar:SetMinMaxValues(0, maxPower)
    frame.powerBar:SetValue(power)
    
    -- Update power bar color
    local color = GetPowerColor(powerType)
    frame.powerBar:SetStatusBarColor(unpack(color))
end

-- Update unit frame data
local function UpdateUnitFrameData(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    -- Update name
    if frame.nameText then
        frame.nameText:SetText(UnitName(unit))
        
        -- Color name by class/reaction
        local r, g, b = GetUnitHealthColor(unit)
        frame.nameText:SetTextColor(r, g, b)
    end
    
    -- Update level (for target/focus)
    if frame.levelText then
        local level = UnitLevel(unit)
        frame.levelText:SetText(level > 0 and level or "??")
        
        -- Color level by difficulty
        if UnitCanAttack("player", unit) and _G.GetQuestDifficultyColor then
            local color = _G.GetQuestDifficultyColor(level)
            if color then
                frame.levelText:SetTextColor(color.r, color.g, color.b)
            else
                frame.levelText:SetTextColor(1, 1, 1)
            end
        else
            frame.levelText:SetTextColor(1, 1, 1)
        end
    end
end

-- =============================================================================
-- FRAME CREATION FUNCTIONS
-- =============================================================================

-- Create base unit frame
local function CreateBaseUnitFrame(name, unit, width, height)
    -- Create secure unit button template for proper clicking
    local frame = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    frame:SetSize(width, height)
    frame.unit = unit
    
    -- Set unit attributes for secure clicking
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:EnableMouse(true)
    frame:RegisterForClicks("AnyUp")
    
    -- Set backdrop
    frame:SetBackdrop(BACKDROP_CONFIG)
    frame:SetBackdropColor(unpack(DamiaUI.Theme.panelBg))
    frame:SetBackdropBorderColor(unpack(DamiaUI.Theme.border))
    
    -- Create health bar
    frame.healthBar = CreateAnimatedStatusBar(name .. "HealthBar", frame)
    -- Single compact health bar like screenshots
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    
    -- Create health text
    frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
    DamiaUI:SetFont(frame.healthText, DamiaUI.DefaultFonts.number, 12, "OUTLINE")
    frame.healthText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
    frame.healthText:SetJustifyH("CENTER")
    frame.healthText:SetTextColor(unpack(DamiaUI.Theme.text))
    
    -- Create name text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY")
    DamiaUI:SetFont(frame.nameText, DamiaUI.DefaultFonts.normal, 10, "OUTLINE")
    frame.nameText:SetPoint("LEFT", frame, "LEFT", 6, 0)
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:SetTextColor(unpack(DamiaUI.Theme.text))
    
    AddRightIndicator(frame)

    return frame
end

-- Create compact label boxes used in the screenshots (focus/targettarget/pet)
local function CreateLabelBox(name, text, anchor, x, y, color)
    local frame = DamiaUI:CreateBorderedPanel(name, UIParent)
    frame:SetSize(120, 22)
    frame:SetPoint(anchor, UIParent, anchor, x, y)
    local fs = frame:CreateFontString(nil, "OVERLAY")
    DamiaUI:SetFont(fs, DamiaUI.DefaultFonts.normal, 12, "OUTLINE")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    if color then fs:SetTextColor(unpack(color)) end
    frame.text = fs
    return frame
end

-- Create player frame
local function CreatePlayerFrame()
    local frame = CreateBaseUnitFrame("DamiaUIPlayerFrame", "player", PLAYER_FRAME_SIZE[1], PLAYER_FRAME_SIZE[2])
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", -220, 150)
    
    -- No separate power bar in the compact layout; color health bar gold
    frame.healthBar:SetStatusBarColor(unpack(DamiaUI.Theme.gold))

    -- Cast bar directly above player frame
    frame.cast = CreateFrame("StatusBar", "DamiaUIPlayerCast", frame)
    frame.cast:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.cast:SetSize(PLAYER_FRAME_SIZE[1], 6)
    frame.cast:SetPoint("BOTTOM", frame, "TOP", 0, 6)
    frame.cast:SetStatusBarColor(1, 0.7, 0.2)
    local castBg = frame.cast:CreateTexture(nil, "BACKGROUND")
    castBg:SetAllPoints()
    castBg:SetColorTexture(0, 0, 0, 0.7)
    local castBorder = DamiaUI:CreateBorderedPanel(nil, frame.cast)
    castBorder:SetPoint("TOPLEFT", frame.cast, -1, 1)
    castBorder:SetPoint("BOTTOMRIGHT", frame.cast, 1, -1)
    
    -- Update functions
    function frame:UpdateFrame()
        UpdateUnitFrameData(self)
        UpdateHealthBar(self)
        UpdatePowerBar(self)
    end
    
    -- Event handling
    frame:SetScript("OnEvent", function(self, event, unit)
        if not unit or unit == "player" then
            self:UpdateFrame()
        end
    end)
    
    -- Register events
    DamiaUI:RegisterFrameEvents(frame, {
        "PLAYER_ENTERING_WORLD",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_POWER_UPDATE",
        "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER",
        "PLAYER_LEVEL_UP",
    })
    
    -- Handle visibility through events instead of RegisterUnitWatch
    frame:Show() -- Player frame is always shown
    
    return frame
end

-- Create target frame
local function CreateTargetFrame()
    local frame = CreateBaseUnitFrame("DamiaUITargetFrame", "target", TARGET_FRAME_SIZE[1], TARGET_FRAME_SIZE[2])
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 220, 150)
    
    -- Create level text for target
    frame.levelText = frame:CreateFontString(nil, "OVERLAY")
    DamiaUI:SetFont(frame.levelText, DamiaUI.DefaultFonts.number, 10, "OUTLINE")
    frame.levelText:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    frame.levelText:SetJustifyH("RIGHT")
    frame.levelText:SetTextColor(1, 1, 1)
    
    -- Update functions
    function frame:UpdateFrame()
        if UnitExists("target") then
            self:Show()
            UpdateUnitFrameData(self)
            UpdateHealthBar(self)
            -- Update auras below target
            if not self.auras then
                self.auras = CreateFrame("Frame", nil, self)
                self.auras:SetPoint("TOP", self, "BOTTOM", 0, -4)
                self.auras.icons = {}
                self.auras.size = 22
                self.auras.perRow = 8
            end
            local index = 1
            for i = 1, 16 do
                local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId = UnitAura("target", i, "HELPFUL")
                if not name then break end
                local row = math.floor((index - 1) / self.auras.perRow)
                local col = (index - 1) % self.auras.perRow
                local b = self.auras.icons[index] or CreateFrame("Frame", nil, self.auras)
                b:SetSize(self.auras.size, self.auras.size)
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", self.auras, "TOPLEFT", col * (self.auras.size + 2), -row * (self.auras.size + 2))
                if not b.tex then
                    b.tex = b:CreateTexture(nil, "ARTWORK")
                    b.tex:SetAllPoints()
                    b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    b.border = DamiaUI:CreateBorderedPanel(nil, b)
                    b.border:SetPoint("TOPLEFT", b, -1, 1)
                    b.border:SetPoint("BOTTOMRIGHT", b, 1, -1)
                end
                b.tex:SetTexture(icon)
                b:Show()
                self.auras.icons[index] = b
                index = index + 1
            end
            for i = index, #self.auras.icons do
                self.auras.icons[i]:Hide()
            end
        else
            self:Hide()
        end
    end
    
    -- Event handling
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or (unit and unit == "target") then
            self:UpdateFrame()
        end
    end)
    
    -- Register events
    DamiaUI:RegisterFrameEvents(frame, {
        "PLAYER_TARGET_CHANGED",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_FACTION",
    })
    
    -- Handle visibility based on target existence
    if UnitExists("target") then
        frame:Show()
    else
        frame:Hide()
    end
    
    return frame
end

-- Create focus frame
local function CreateFocusFrame()
    local frame = CreateBaseUnitFrame("DamiaUIFocusFrame", "focus", FOCUS_FRAME_SIZE[1], FOCUS_FRAME_SIZE[2])
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 50, 260)
    
    -- Create level text for focus
    frame.levelText = frame:CreateFontString(nil, "OVERLAY")
    DamiaUI:SetFont(frame.levelText, DamiaUI.DefaultFonts.normal, 10, "OUTLINE")
    frame.levelText:SetPoint("RIGHT", frame, "TOPRIGHT", -4, -2)
    frame.levelText:SetJustifyH("RIGHT")
    frame.levelText:SetTextColor(1, 1, 1)
    
    -- Smaller font sizes for focus frame
    DamiaUI:SetFont(frame.nameText, DamiaUI.DefaultFonts.normal, 10, "OUTLINE")
    DamiaUI:SetFont(frame.healthText, DamiaUI.DefaultFonts.normal, 11, "OUTLINE")
    
    -- Update functions
    function frame:UpdateFrame()
        if UnitExists("focus") then
            self:Show()
            UpdateUnitFrameData(self)
            UpdateHealthBar(self)
        else
            self:Hide()
        end
    end
    
    -- Event handling
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_FOCUS_CHANGED" or (unit and unit == "focus") then
            self:UpdateFrame()
        end
    end)
    
    -- Register events
    DamiaUI:RegisterFrameEvents(frame, {
        "PLAYER_FOCUS_CHANGED",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_FACTION",
    })
    
    -- Handle visibility based on focus existence
    if UnitExists("focus") then
        frame:Show()
    else
        frame:Hide()
    end
    
    return frame
end

-- =============================================================================
-- BLIZZARD FRAME HIDING
-- =============================================================================

local function HideBlizzardUnitFrames()
    -- Hide Blizzard player frame
    if PlayerFrame then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:Hide()
        PlayerFrame:SetAlpha(0)
    end
    
    -- Hide Blizzard target frame
    if TargetFrame then
        TargetFrame:UnregisterAllEvents()
        TargetFrame:Hide()
        TargetFrame:SetAlpha(0)
    end
    
    -- Hide Blizzard focus frame
    if FocusFrame then
        FocusFrame:UnregisterAllEvents()
        FocusFrame:Hide()
        FocusFrame:SetAlpha(0)
    end
    
    -- Hide combo point frame if it exists
    local comboFrame = _G.ComboFrame or _G.ComboPointPlayerFrame
    if comboFrame then
        if comboFrame.UnregisterAllEvents then
            comboFrame:UnregisterAllEvents()
        end
        if comboFrame.Hide then
            comboFrame:Hide()
        end
        if comboFrame.SetAlpha then
            comboFrame:SetAlpha(0)
        end
    end
    
    DamiaUI:Debug("Blizzard unit frames hidden")
end

-- =============================================================================
-- MODULE METHODS
-- =============================================================================

-- Initialize the unit frames module
function UnitFrames:Initialize()
    DamiaUI:Print("Initializing Unit Frames...")
    
    -- Hide Blizzard frames first
    HideBlizzardUnitFrames()
    
    -- Create our unit frames
    self.playerFrame = CreatePlayerFrame()
    self.targetFrame = CreateTargetFrame()
    self.focusFrame = CreateFocusFrame()

    -- Center label boxes (visual placeholders like in the screenshots)
    self.centerBoxes = self.centerBoxes or {}
    self.centerBoxes.focus = CreateLabelBox("DamiaUICenterFocus", "focus", "BOTTOM", 0, 182, {0.6,1,0.6,1})
    self.centerBoxes.targettarget = CreateLabelBox("DamiaUICenterToT", "targettarget", "BOTTOM", 0, 158, {0.6,1,0.6,1})
    self.centerBoxes.pet = CreateLabelBox("DamiaUICenterPet", "pet", "BOTTOM", 0, 134, {0.6,1,0.6,1})
    
    -- Store references
    DamiaUI.playerFrame = self.playerFrame
    DamiaUI.targetFrame = self.targetFrame  
    DamiaUI.focusFrame = self.focusFrame
    
    DamiaUI:Print("Unit Frames initialized")
    DamiaUI:Debug("Player frame:", self.playerFrame:GetName())
    DamiaUI:Debug("Target frame:", self.targetFrame:GetName())
    DamiaUI:Debug("Focus frame:", self.focusFrame:GetName())
end

-- Enable or disable unit frames
function UnitFrames:SetEnabled(enabled)
    if self.playerFrame then
        self.playerFrame:SetShown(enabled)
    end
    if self.targetFrame then
        self.targetFrame:SetShown(enabled)
    end
    if self.focusFrame then
        self.focusFrame:SetShown(enabled)
    end
end

-- Update all unit frames
function UnitFrames:UpdateAllFrames()
    if self.playerFrame and self.playerFrame.UpdateFrame then
        self.playerFrame:UpdateFrame()
    end
    if self.targetFrame and self.targetFrame.UpdateFrame then
        self.targetFrame:UpdateFrame()
    end
    if self.focusFrame and self.focusFrame.UpdateFrame then
        self.focusFrame:UpdateFrame()
    end
end

-- Reset positions
function UnitFrames:ResetPositions()
    if self.playerFrame then
        self.playerFrame:ClearAllPoints()
        self.playerFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 50, 200)
    end
    if self.targetFrame then
        self.targetFrame:ClearAllPoints()
        self.targetFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 200)
    end
    if self.focusFrame then
        self.focusFrame:ClearAllPoints()
        self.focusFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 50, 260)
    end
    DamiaUI:Print("Unit frame positions reset")
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Handle module events
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "DamiaUI" then
            self:UnregisterEvent("ADDON_LOADED")
            UnitFrames:Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Update all frames after entering world
        C_Timer.After(1, function()
            if UnitFrames.UpdateAllFrames then
                UnitFrames:UpdateAllFrames()
            end
        end)
    end
end

-- =============================================================================
-- MODULE REGISTRATION
-- =============================================================================

-- Register event for initialization  
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", OnEvent)

-- Register the module with DamiaUI
DamiaUI.modules.UnitFrames = UnitFrames

DamiaUI:Print("UnitFrames module loaded")