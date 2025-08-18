--[[
    DamiaUI - Raid Unit Frames
    Scalable raid frame implementation with intelligent group organization
    
    Automatically adapts layout based on raid size (10, 25, 30, 40 players)
    and provides enhanced raid-specific functionality including dispel indicators,
    buff/debuff tracking, and role-based sorting.
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local floor, ceil, max = math.floor, math.ceil, math.max
local UnitName, UnitClass, UnitIsConnected = UnitName, UnitClass, UnitIsConnected
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local Compatibility = DamiaUI.Compatibility
local UnitBuff = Compatibility and Compatibility.UnitBuff or UnitBuff
local UnitDebuff = Compatibility and Compatibility.UnitDebuff or UnitDebuff
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid, IsInGroup = IsInRaid, IsInGroup
local GetRaidRosterInfo = GetRaidRosterInfo
local CreateFrame = CreateFrame

-- Module dependencies
local oUF = DamiaUI.Libraries.oUF
local Aurora = DamiaUI.Libraries.Aurora

-- Raid frame configuration
local RAID_CONFIG = {
    position = { x = -500, y = 200 },
    size = { width = 80, height = 32 },
    scale = 0.8,
    spacing = 2,
    groupSpacing = 10,
    growth = "RIGHT",
    groupsPerRow = 5,
    showGroupNumbers = true,
    showRoleIcon = true,
    showDispelIcon = true,
    showBuffs = false,
    showDebuffs = true,
    maxDebuffs = 3,
    sortByRole = true,
    compactMode = false
}

-- Layout configurations for different raid sizes
local RAID_LAYOUTS = {
    [10] = { groups = 2, maxFrames = 10, frameWidth = 90, frameHeight = 40 },
    [25] = { groups = 5, maxFrames = 25, frameWidth = 80, frameHeight = 32 },
    [30] = { groups = 6, maxFrames = 30, frameWidth = 75, frameHeight = 30 },
    [40] = { groups = 8, maxFrames = 40, frameWidth = 70, frameHeight = 28 }
}

-- Raid frames storage
local raidFrames = {}
local groupContainers = {}
local raidContainer = nil
local currentLayout = nil

-- Dispellable debuff types by class
local DISPEL_TYPES = {
    PRIEST = { ["Magic"] = true, ["Disease"] = true },
    PALADIN = { ["Magic"] = true, ["Poison"] = true, ["Disease"] = true },
    SHAMAN = { ["Magic"] = true, ["Curse"] = true },
    DRUID = { ["Magic"] = true, ["Curse"] = true, ["Poison"] = true },
    MAGE = { ["Curse"] = true },
    WARLOCK = { ["Magic"] = true }, -- Devour Magic via pet
    MONK = { ["Magic"] = true, ["Poison"] = true, ["Disease"] = true },
    DEMONHUNTER = {},
    WARRIOR = {},
    ROGUE = {},
    HUNTER = {},
    DEATHKNIGHT = {},
    EVOKER = { ["Magic"] = true, ["Poison"] = true, ["Curse"] = true, ["Disease"] = true }
}

-- Class colors for frames
local CLASS_COLORS = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER = { 0.67, 0.83, 0.45 },
    ROGUE = { 1.00, 0.96, 0.41 },
    PRIEST = { 1.00, 1.00, 1.00 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN = { 0.00, 0.44, 0.87 },
    MAGE = { 0.41, 0.80, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    MONK = { 0.00, 1.00, 0.59 },
    DRUID = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER = { 0.20, 0.58, 0.50 }
}

--[[
    Create raid-specific elements for each frame
]]
local function CreateRaidElements(self, unit)
    local scale = RAID_CONFIG.scale
    
    -- Role indicator (smaller for raid frames)
    if RAID_CONFIG.showRoleIcon then
        local roleIcon = self.Health:CreateTexture(nil, "OVERLAY")
        roleIcon:SetSize(10 * scale, 10 * scale)
        roleIcon:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
        roleIcon:Hide()
        self.GroupRoleIndicator = roleIcon
    end
    
    -- Dispel indicator
    if RAID_CONFIG.showDispelIcon then
        local dispelIcon = self.Health:CreateTexture(nil, "OVERLAY")
        dispelIcon:SetSize(12 * scale, 12 * scale)
        dispelIcon:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -1)
        dispelIcon:SetTexture("Interface\\RaidFrame\\Raid-Icon-Debuff")
        dispelIcon:Hide()
        self.DispelIndicator = dispelIcon
    end
    
    -- Debuff container
    if RAID_CONFIG.showDebuffs then
        local debuffs = CreateFrame("Frame", nil, self)
        debuffs:SetSize(self:GetWidth(), 12 * scale)
        debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
        debuffs.size = 12 * scale
        debuffs.spacing = 1
        debuffs.num = RAID_CONFIG.maxDebuffs
        debuffs:SetFrameLevel(self:GetFrameLevel() + 2)
        
        self.Debuffs = debuffs
    end
    
    -- Ready check indicator
    local readyCheck = self.Health:CreateTexture(nil, "OVERLAY")
    readyCheck:SetSize(16 * scale, 16 * scale)
    readyCheck:SetPoint("CENTER", self, "CENTER")
    readyCheck:Hide()
    self.ReadyCheckIndicator = readyCheck
    
    -- Offline/disconnect indicator
    local offline = self.Health:CreateTexture(nil, "OVERLAY")
    offline:SetAllPoints(self)
    offline:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
    offline:SetDesaturated(true)
    offline:SetVertexColor(0.5, 0.5, 0.5, 0.8)
    offline:Hide()
    self.OfflineIndicator = offline
    
    -- Range indicator
    self.Range = {
        insideAlpha = 1.0,
        outsideAlpha = 0.3
    }
    
    return self
end

--[[
    Update dispel indicator based on debuffs
]]
local function UpdateDispelIndicator(self)
    if not self.DispelIndicator then return end
    
    local playerClass = select(2, UnitClass("player"))
    local canDispel = DISPEL_TYPES[playerClass] or {}
    
    -- Check for dispellable debuffs
    local hasDispellable = false
    for i = 1, 10 do
        local name, icon, count, debuffType = UnitDebuff(self.unit, i)
        if not name then break end
        
        if debuffType and canDispel[debuffType] then
            hasDispellable = true
            self.DispelIndicator:SetTexture(icon)
            break
        end
    end
    
    if hasDispellable then
        self.DispelIndicator:Show()
    else
        self.DispelIndicator:Hide()
    end
end

--[[
    Update role indicator
]]
local function UpdateRoleIndicator(self)
    if not self.GroupRoleIndicator then return end
    
    local role = UnitGroupRolesAssigned(self.unit)
    local roleTextures = {
        TANK = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
        HEALER = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", 
        DAMAGER = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
    }
    
    local roleCoords = {
        TANK = { 0, 19/64, 22/64, 41/64 },
        HEALER = { 20/64, 39/64, 1/64, 20/64 },
        DAMAGER = { 20/64, 39/64, 22/64, 41/64 }
    }
    
    if role and role ~= "NONE" and roleTextures[role] then
        self.GroupRoleIndicator:SetTexture(roleTextures[role])
        self.GroupRoleIndicator:SetTexCoord(unpack(roleCoords[role]))
        self.GroupRoleIndicator:Show()
    else
        self.GroupRoleIndicator:Hide()
    end
end

--[[
    Raid frame layout function
]]
local function CreateRaidLayout(self, unit)
    if not unit:match("raid%d+") then return end
    
    local layout = currentLayout or RAID_LAYOUTS[25]
    local scale = RAID_CONFIG.scale
    
    -- Set frame dimensions
    self:SetSize(layout.frameWidth * scale, layout.frameHeight * scale)
    self:SetScale(scale)
    
    -- Create health bar (main bar for raid frames)
    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetStatusBarColor(0.2, 0.8, 0.2)
    
    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    
    -- Name text (centered for compact raid frames)
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 9 * scale, "OUTLINE")
    name:SetPoint("CENTER", health, "CENTER")
    name:SetTextColor(1, 1, 1)
    name:SetJustifyH("CENTER")
    
    -- Health deficit text (shows missing health)
    local healthDeficit = health:CreateFontString(nil, "OVERLAY")
    healthDeficit:SetFont("Fonts\\FRIZQT__.TTF", 8 * scale, "OUTLINE")
    healthDeficit:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -2, 1)
    healthDeficit:SetTextColor(1, 0.2, 0.2)
    healthDeficit:SetJustifyH("RIGHT")
    
    -- Register elements with oUF
    self.Health = health
    self.Health.bg = health.bg
    self.Name = name
    self.HealthDeficit = healthDeficit
    
    -- Add raid-specific elements
    CreateRaidElements(self, unit)
    
    -- Set class-based border color
    local _, class = UnitClass(unit)
    if class and CLASS_COLORS[class] then
        local color = CLASS_COLORS[class]
        self.Health.bg:SetVertexColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.8)
    end
    
    -- Apply Aurora styling
    if Aurora and Aurora.CreateBorder then
        Aurora.CreateBorder(self, 4)
    end
    
    return self
end

--[[
    Get optimal layout for current raid size
]]
local function GetOptimalLayout(numMembers)
    if numMembers <= 10 then
        return RAID_LAYOUTS[10]
    elseif numMembers <= 25 then
        return RAID_LAYOUTS[25] 
    elseif numMembers <= 30 then
        return RAID_LAYOUTS[30]
    else
        return RAID_LAYOUTS[40]
    end
end

--[[
    Create raid container and group containers
]]
local function CreateRaidContainer()
    if raidContainer then return raidContainer end
    
    raidContainer = CreateFrame("Frame", "DamiaUI_RaidContainer", UIParent)
    
    -- Position at raid-specific coordinates
    local x, y = DamiaUI.UnitFrames.GetCenterPosition(RAID_CONFIG.position.x, RAID_CONFIG.position.y)
    raidContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    
    return raidContainer
end

--[[
    Create group containers for organizing raid members
]]
local function CreateGroupContainers(numGroups)
    -- Clear existing group containers
    for i, container in pairs(groupContainers) do
        container:Hide()
    end
    
    -- Create new group containers
    for i = 1, numGroups do
        if not groupContainers[i] then
            groupContainers[i] = CreateFrame("Frame", "DamiaUI_RaidGroup" .. i, raidContainer)
        end
        
        local container = groupContainers[i]
        container:Show()
        
        -- Position group container
        local groupsPerRow = RAID_CONFIG.groupsPerRow
        local row = ceil(i / groupsPerRow) - 1
        local col = (i - 1) % groupsPerRow
        
        local groupWidth = (currentLayout.frameWidth + RAID_CONFIG.spacing) * 5 -- 5 members per group
        local groupHeight = currentLayout.frameHeight + RAID_CONFIG.spacing
        
        container:SetSize(groupWidth, groupHeight)
        container:SetPoint("TOPLEFT", raidContainer, "TOPLEFT", 
            col * (groupWidth + RAID_CONFIG.groupSpacing), 
            -row * (groupHeight + RAID_CONFIG.groupSpacing))
        
        -- Group number label
        if RAID_CONFIG.showGroupNumbers then
            if not container.groupLabel then
                container.groupLabel = container:CreateFontString(nil, "OVERLAY")
                container.groupLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                container.groupLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 12)
                container.groupLabel:SetTextColor(0.8, 0.8, 0.8)
            end
            container.groupLabel:SetText("Group " .. i)
        end
    end
end

--[[
    Position raid frames within their groups
]]
local function PositionRaidFrames()
    if not currentLayout then return end
    
    local frameWidth = currentLayout.frameWidth * RAID_CONFIG.scale
    local frameHeight = currentLayout.frameHeight * RAID_CONFIG.scale
    
    for i = 1, 40 do -- Max raid size
        local frame = raidFrames[i]
        if frame then
            -- Calculate group and position within group
            local groupNum = ceil(i / 5)
            local posInGroup = ((i - 1) % 5) + 1
            
            local container = groupContainers[groupNum]
            if container then
                frame:SetParent(container)
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", container, "TOPLEFT", 
                    (posInGroup - 1) * (frameWidth + RAID_CONFIG.spacing), 
                    0)
            end
        end
    end
end

--[[
    Update raid visibility and layout based on group status
]]
local function UpdateRaidVisibility()
    local inRaid = IsInRaid()
    local numMembers = GetNumGroupMembers()
    
    if not raidContainer then
        CreateRaidContainer()
    end
    
    if inRaid and numMembers > 5 then
        -- Determine optimal layout
        currentLayout = GetOptimalLayout(numMembers)
        local numGroups = ceil(numMembers / 5)
        
        -- Update container size
        local groupWidth = (currentLayout.frameWidth + RAID_CONFIG.spacing) * 5
        local groupHeight = currentLayout.frameHeight + RAID_CONFIG.spacing
        local groupsPerRow = RAID_CONFIG.groupsPerRow
        local rows = ceil(numGroups / groupsPerRow)
        local cols = math.min(numGroups, groupsPerRow)
        
        raidContainer:SetSize(
            cols * (groupWidth + RAID_CONFIG.groupSpacing) - RAID_CONFIG.groupSpacing,
            rows * (groupHeight + RAID_CONFIG.groupSpacing) - RAID_CONFIG.groupSpacing
        )
        
        -- Create and position group containers
        CreateGroupContainers(numGroups)
        
        -- Show frames for actual raid members
        for i = 1, numMembers do
            if raidFrames[i] then
                raidFrames[i]:Show()
                UpdateRoleIndicator(raidFrames[i])
                UpdateDispelIndicator(raidFrames[i])
            end
        end
        
        -- Hide unused frames
        for i = numMembers + 1, 40 do
            if raidFrames[i] then
                raidFrames[i]:Hide()
            end
        end
        
        -- Position all frames
        PositionRaidFrames()
        
        raidContainer:Show()
    else
        -- Hide raid frames when not in raid
        if raidContainer then
            raidContainer:Hide()
        end
        for i = 1, 40 do
            if raidFrames[i] then
                raidFrames[i]:Hide()
            end
        end
    end
end

--[[
    Initialize raid frames
]]
local function InitializeRaidFrames()
    -- Create container
    CreateRaidContainer()
    
    -- Register custom layout style
    oUF:RegisterStyle("DamiaRaid", CreateRaidLayout)
    
    -- Spawn raid frames
    for i = 1, 40 do -- Maximum raid size
        local unit = "raid" .. i
        local frameName = "DamiaUI_RaidFrame" .. i
        
        oUF:SetActiveStyle("DamiaRaid")
        local frame = oUF:Spawn(unit, frameName)
        
        if frame then
            raidFrames[i] = frame
            frame:Hide() -- Hidden by default
        end
    end
    
    -- Set up event handlers for dynamic visibility
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("GROUP_JOINED")  
    eventFrame:RegisterEvent("GROUP_LEFT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("UNIT_CONNECTION")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_AURA" then
            local unit = ...
            if unit and unit:match("raid%d+") then
                local frameIndex = tonumber(unit:match("raid(%d+)"))
                if raidFrames[frameIndex] then
                    UpdateDispelIndicator(raidFrames[frameIndex])
                end
            end
        else
            UpdateRaidVisibility()
        end
    end)
    
    -- Initial visibility update
    UpdateRaidVisibility()
end

--[[
    Get raid configuration
]]
local function GetRaidConfig()
    return RAID_CONFIG
end

--[[
    Update raid configuration
]]
local function SetRaidConfig(key, value)
    if RAID_CONFIG[key] ~= nil then
        RAID_CONFIG[key] = value
        
        -- Update layout if needed
        if key == "position" then
            if raidContainer then
                local x, y = DamiaUI.UnitFrames.GetCenterPosition(value.x, value.y)
                raidContainer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            end
        elseif key == "scale" or key == "size" or key == "spacing" then
            PositionRaidFrames()
        end
    end
end

--[[
    Public API
]]
local RaidFrames = {
    Initialize = InitializeRaidFrames,
    UpdateVisibility = UpdateRaidVisibility, 
    GetConfig = GetRaidConfig,
    SetConfig = SetRaidConfig,
    GetFrames = function() return raidFrames end,
    GetContainer = function() return raidContainer end
}

-- Export to DamiaUI namespace
if not DamiaUI.UnitFrames then
    DamiaUI.UnitFrames = {}
end

DamiaUI.UnitFrames.Raid = RaidFrames

-- Auto-initialize on load
InitializeRaidFrames()