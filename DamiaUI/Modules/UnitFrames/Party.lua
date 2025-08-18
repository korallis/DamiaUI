--[[
    DamiaUI - Party Unit Frames
    Dynamic party frame implementation with role indicators and contextual adaptation
    
    Automatically shows/hides based on group composition and provides enhanced
    party-specific functionality including role indicators, health/mana bars,
    and threat detection.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local UnitName, UnitLevel, UnitClass = UnitName, UnitLevel, UnitClass
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup = IsInGroup
local CreateFrame = CreateFrame

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora

-- Party frame configuration
local PARTY_CONFIG = {
    position = { x = -400, y = 0 },
    size = { width = 180, height = 45 },
    scale = 0.9,
    spacing = 8,
    growth = "DOWN",
    showRoleIcon = true,
    showThreatIndicator = true,
    showRange = true,
    maxFrames = 4
}

-- Party frames storage
local partyFrames = {}
local partyContainer = nil

-- Threat status colors
local THREAT_COLORS = {
    [0] = { 0.69, 0.69, 0.69 }, -- No threat
    [1] = { 1, 1, 0 }, -- Low threat (yellow)
    [2] = { 1, 0.5, 0 }, -- Medium threat (orange)  
    [3] = { 1, 0, 0 } -- High threat (red)
}

-- Role icon textures
local ROLE_TEXTURES = {
    TANK = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    HEALER = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    DAMAGER = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    NONE = nil
}

local ROLE_COORDS = {
    TANK = { 0, 19/64, 22/64, 41/64 },
    HEALER = { 20/64, 39/64, 1/64, 20/64 },
    DAMAGER = { 20/64, 39/64, 22/64, 41/64 },
    NONE = { 0, 0, 0, 0 }
}

--[[
    Create party-specific elements for each frame
]]
local function CreatePartyElements(self, unit)
    local scale = PARTY_CONFIG.scale
    local unitNumber = unit:match("party(%d)")
    if not unitNumber then return end
    
    -- Role indicator
    if PARTY_CONFIG.showRoleIcon then
        local roleIcon = self.Health:CreateTexture(nil, "OVERLAY")
        roleIcon:SetSize(16 * scale, 16 * scale)
        roleIcon:SetPoint("LEFT", self, "LEFT", -20, 0)
        roleIcon:Hide()
        self.GroupRoleIndicator = roleIcon
    end
    
    -- Threat indicator border
    if PARTY_CONFIG.showThreatIndicator then
        local threatBorder = CreateFrame("Frame", nil, self)
        threatBorder:SetAllPoints(self)
        threatBorder:SetFrameLevel(self:GetFrameLevel() + 10)
        
        local border = threatBorder:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(threatBorder)
        border:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
        border:SetBlendMode("ADD")
        border:Hide()
        
        self.ThreatIndicator = {
            Border = border,
            Override = UpdateThreatIndicator
        }
    end
    
    -- Range indicator (fade out when out of range)
    if PARTY_CONFIG.showRange then
        self.Range = {
            insideAlpha = 1.0,
            outsideAlpha = 0.4
        }
    end
    
    -- Ready check indicator
    local readyCheck = self.Health:CreateTexture(nil, "OVERLAY")
    readyCheck:SetSize(20 * scale, 20 * scale)
    readyCheck:SetPoint("CENTER", self, "CENTER")
    readyCheck:Hide()
    self.ReadyCheckIndicator = readyCheck
    
    -- Resurrection indicator
    local resurrect = self.Health:CreateTexture(nil, "OVERLAY")  
    resurrect:SetSize(16 * scale, 16 * scale)
    resurrect:SetPoint("CENTER", self, "CENTER")
    resurrect:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
    resurrect:Hide()
    self.ResurrectIndicator = resurrect
    
    -- Phase indicator
    local phaseIcon = self.Health:CreateTexture(nil, "OVERLAY")
    phaseIcon:SetSize(12 * scale, 12 * scale)
    phaseIcon:SetPoint("TOPRIGHT", self, "TOPRIGHT", 2, 2)
    phaseIcon:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon")
    self.PhaseIndicator = phaseIcon
    
    return self
end

--[[
    Update threat indicator based on unit's threat situation
]]
function UpdateThreatIndicator(threat, unit, status, scaledPercent, rawPercent, threatValue)
    if not threat or not threat.Border then return end
    
    local threatSituation = UnitThreatSituation(unit)
    
    if threatSituation and threatSituation > 0 then
        local color = THREAT_COLORS[threatSituation] or THREAT_COLORS[0]
        threat.Border:SetVertexColor(color[1], color[2], color[3], 0.8)
        threat.Border:Show()
    else
        threat.Border:Hide()
    end
end

--[[
    Update role indicator based on assigned group role
]]
local function UpdateRoleIndicator(self)
    if not self.GroupRoleIndicator then return end
    
    local role = UnitGroupRolesAssigned(self.unit)
    
    if role and role ~= "NONE" and ROLE_TEXTURES[role] then
        self.GroupRoleIndicator:SetTexture(ROLE_TEXTURES[role])
        self.GroupRoleIndicator:SetTexCoord(unpack(ROLE_COORDS[role]))
        self.GroupRoleIndicator:Show()
    else
        self.GroupRoleIndicator:Hide()
    end
end

--[[
    Party frame layout function
]]
local function CreatePartyLayout(self, unit)
    if not unit:match("party%d") then return end
    
    local scale = PARTY_CONFIG.scale
    
    -- Set frame dimensions and scale
    self:SetSize(PARTY_CONFIG.size.width * scale, PARTY_CONFIG.size.height * scale)
    self:SetScale(scale)
    
    -- Create health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetHeight(22 * scale)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.2, 0.8, 0.2)
    
    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Create power bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(8 * scale)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -2)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -2)
    power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    power.bg = power:CreateTexture(nil, "BORDER")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    power.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Name text
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11 * scale, "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 4, 0)
    name:SetTextColor(1, 1, 1)
    name:SetJustifyH("LEFT")
    
    -- Health value text
    local healthValue = health:CreateFontString(nil, "OVERLAY")
    healthValue:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    healthValue:SetPoint("RIGHT", health, "RIGHT", -4, 0)
    healthValue:SetTextColor(1, 1, 1)
    healthValue:SetJustifyH("RIGHT")
    
    -- Register elements with oUF
    self.Health = health
    self.Health.bg = health.bg
    self.Power = power
    self.Power.bg = power.bg
    self.Name = name
    self.HealthValue = healthValue
    
    -- Add party-specific elements
    CreatePartyElements(self, unit)
    
    -- Apply Aurora styling if available
    if Aurora and Aurora.CreateBorder then
        Aurora.CreateBorder(self, 6)
        if Aurora.Skin and Aurora.Skin.StatusBarWidget then
            Aurora.Skin.StatusBarWidget(health)
            Aurora.Skin.StatusBarWidget(power)
        end
    end
    
    return self
end

--[[
    Create party container and position frames
]]
local function CreatePartyContainer()
    if partyContainer then return partyContainer end
    
    partyContainer = CreateFrame("Frame", "DamiaUI_PartyContainer", UIParent)
    partyContainer:SetSize(PARTY_CONFIG.size.width, PARTY_CONFIG.size.height * PARTY_CONFIG.maxFrames)
    
    -- Position at party-specific coordinates
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(PARTY_CONFIG.position.x, PARTY_CONFIG.position.y)
    partyContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    
    return partyContainer
end

--[[
    Position party frames in vertical layout
]]
local function PositionPartyFrames()
    if not partyContainer then return end
    
    local yOffset = 0
    for i = 1, PARTY_CONFIG.maxFrames do
        local frame = partyFrames[i]
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", partyContainer, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - (PARTY_CONFIG.size.height + PARTY_CONFIG.spacing) * PARTY_CONFIG.scale
        end
    end
end

--[[
    Show/hide party frames based on group status
]]
local function UpdatePartyVisibility()
    local inGroup = IsInGroup() and not IsInRaid()
    local numMembers = GetNumGroupMembers()
    
    if not partyContainer then
        CreatePartyContainer()
    end
    
    if inGroup and numMembers > 1 then
        partyContainer:Show()
        
        -- Show frames for actual party members
        for i = 1, numMembers - 1 do -- -1 because player is not in party units
            if partyFrames[i] then
                partyFrames[i]:Show()
                UpdateRoleIndicator(partyFrames[i])
            end
        end
        
        -- Hide unused frames
        for i = numMembers, PARTY_CONFIG.maxFrames do
            if partyFrames[i] then
                partyFrames[i]:Hide()
            end
        end
    else
        -- Hide all party frames when not in group
        if partyContainer then
            partyContainer:Hide()
        end
        for i = 1, PARTY_CONFIG.maxFrames do
            if partyFrames[i] then
                partyFrames[i]:Hide()
            end
        end
    end
end

--[[
    Initialize party frames
]]
local function InitializePartyFrames()
    -- Create container
    CreatePartyContainer()
    
    -- Register custom layout style
    oUF:RegisterStyle("DamiaParty", CreatePartyLayout)
    
    -- Spawn party frames
    for i = 1, PARTY_CONFIG.maxFrames do
        local unit = "party" .. i
        local frameName = "DamiaUI_PartyFrame" .. i
        
        oUF:SetActiveStyle("DamiaParty")
        local frame = oUF:Spawn(unit, frameName)
        
        if frame then
            frame:SetParent(partyContainer)
            partyFrames[i] = frame
        end
    end
    
    -- Position frames
    PositionPartyFrames()
    
    -- Set up event handlers for dynamic visibility
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("GROUP_JOINED")
    eventFrame:RegisterEvent("GROUP_LEFT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        UpdatePartyVisibility()
    end)
    
    -- Initial visibility update
    UpdatePartyVisibility()
end

--[[
    Get party configuration
]]
local function GetPartyConfig()
    return PARTY_CONFIG
end

--[[
    Update party configuration
]]
local function SetPartyConfig(key, value)
    if PARTY_CONFIG[key] ~= nil then
        PARTY_CONFIG[key] = value
        
        -- Update frames if needed
        if key == "position" then
            if partyContainer then
                local x, y = DamiaUI.UnitFrames.GetCenterPosition(value.x, value.y)
                partyContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            end
        elseif key == "scale" or key == "size" or key == "spacing" then
            PositionPartyFrames()
        end
    end
end

--[[
    Public API
]]
local PartyFrames = {
    Initialize = InitializePartyFrames,
    UpdateVisibility = UpdatePartyVisibility,
    GetConfig = GetPartyConfig,
    SetConfig = SetPartyConfig,
    GetFrames = function() return partyFrames end,
    GetContainer = function() return partyContainer end
}

-- Export to DamiaUI namespace
if not DamiaUI.UnitFrames then
    DamiaUI.UnitFrames = {}
end

DamiaUI.UnitFrames.Party = PartyFrames

-- Auto-initialize on load
InitializePartyFrames()