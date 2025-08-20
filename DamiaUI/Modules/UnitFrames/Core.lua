-- DamiaUI Unit Frames Core
-- Based on oUF_Coldkil, updated for WoW 11.2 with latest oUF

local addonName, ns = ...
local oUF = ns.oUF

local UnitFrames = {}
ns.UnitFrames = UnitFrames

-- Check for oUF availability with fallback
if not oUF then
    if ns.LogDebug then
        ns:LogDebug("WARNING: oUF not found! Unit frames will be disabled")
    end
    
    -- Create stub module that doesn't break the system
    function UnitFrames:Initialize()
        if ns.LogDebug then
            ns:LogDebug("UnitFrames: oUF not available, skipping initialization")
        end
        return false
    end
    
    -- Register the stub module and return early
    ns:RegisterModule("UnitFrames", UnitFrames)
    return
else
    if ns.LogDebug then
        ns:LogDebug("oUF found and available for UnitFrames")
    end
end

-- Configuration
UnitFrames.config = {}
UnitFrames.units = {}

-- Initialize module
function UnitFrames:Initialize()
    if ns.LogDebug then
        ns:LogDebug("UnitFrames:Initialize() called")
    end
    
    -- Get config
    self.config = ns.config.unitframes
    if ns.LogDebug then
        ns:LogDebug("UnitFrames config: " .. tostring(self.config ~= nil))
    end
    
    if not self.config or not self.config.enabled then
        if ns.LogDebug then
            ns:LogDebug("UnitFrames disabled or no config, returning")
        end
        return
    end
    
    if ns.LogDebug then
        ns:LogDebug("UnitFrames enabled, proceeding...")
    end
    
    -- Register custom tags FIRST
    self:RegisterTags()
    if ns.LogDebug then
        ns:LogDebug("Custom tags registered")
    end
    
    -- Register oUF style
    self:RegisterStyle()
    if ns.LogDebug then
        ns:LogDebug("oUF style registered")
    end
    
    -- Set active style
    oUF:SetActiveStyle("DamiaUI")
    if ns.LogDebug then
        ns:LogDebug("Active style set to DamiaUI")
    end
    
    -- Spawn units
    self:SpawnUnits()
    if ns.LogDebug then
        ns:LogDebug("Units spawned")
    end
    
    if ns.LogDebug then
        ns:LogDebug("UnitFrames initialization completed")
        ns:LogDebug("Unit Frames module loaded")
    end
end

-- Register oUF style
function UnitFrames:RegisterStyle()
    oUF:RegisterStyle("DamiaUI", function(frame, unit)
        self:SetupFrame(frame, unit)
    end)
end

-- Spawn all unit frames
function UnitFrames:SpawnUnits()
    if ns.LogDebug then
        ns:LogDebug("SpawnUnits called")
    end
    
    oUF:SetActiveStyle("DamiaUI")
    
    -- Player frame
    if self.config.player then
        local player = oUF:Spawn("player", "DamiaUI_PlayerFrame")
        if player then
            player:SetPoint(unpack(self.config.player.pos or {"BOTTOMRIGHT", UIParent, "BOTTOM", -150, 260}))
            self.units.player = player
            if ns.LogDebug then
                ns:LogDebug("Player frame spawned")
            end
        end
    end
    
    -- Target frame
    if self.config.target then
        local target = oUF:Spawn("target", "DamiaUI_TargetFrame")
        if target then
            target:SetPoint(unpack(self.config.target.pos or {"BOTTOMLEFT", UIParent, "BOTTOM", 150, 260}))
            self.units.target = target
            if ns.LogDebug then
                ns:LogDebug("Target frame spawned")
            end
        end
    end
    
    -- Focus frame
    if self.config.focus then
        local focus = oUF:Spawn("focus", "DamiaUI_FocusFrame")
        if focus then
            focus:SetPoint(unpack(self.config.focus.pos or {"BOTTOMRIGHT", UIParent, "BOTTOM", -150, 320}))
            self.units.focus = focus
            if ns.LogDebug then
                ns:LogDebug("Focus frame spawned")
            end
        end
    end
    
    -- Target of Target
    local targettarget = oUF:Spawn("targettarget", "DamiaUI_TargetTargetFrame")
    if targettarget then
        targettarget:SetPoint("BOTTOMRIGHT", self.units.target or UIParent, "BOTTOMLEFT", -10, 0)
        self.units.targettarget = targettarget
        if ns.LogDebug then
            ns:LogDebug("TargetTarget frame spawned")
        end
    end
    
    -- Pet frame
    local pet = oUF:Spawn("pet", "DamiaUI_PetFrame")
    if pet then
        pet:SetPoint("BOTTOMLEFT", self.units.player or UIParent, "BOTTOMRIGHT", 10, 0)
        self.units.pet = pet
        if ns.LogDebug then
            ns:LogDebug("Pet frame spawned")
        end
    end
    
    -- Party frames
    if self.config.showParty then
        local party = oUF:SpawnHeader(
            "DamiaUI_PartyHeader", nil, "party",
            "showParty", true,
            "showPlayer", false,
            "showRaid", false,
            "showSolo", false,
            "xOffset", 0,
            "yOffset", -40,
            "point", "TOP",
            "oUF-initialConfigFunction", [[
                self:SetHeight(25)
                self:SetWidth(150)
            ]]
        )
        if party then
            party:SetPoint(unpack(self.config.party.pos or {"TOPLEFT", UIParent, "TOPLEFT", 20, -100}))
            self.units.party = party
            if ns.LogDebug then
                ns:LogDebug("Party frames spawned")
            end
        end
    end
    
    -- Raid frames
    if self.config.showRaid then
        local raid = oUF:SpawnHeader(
            "DamiaUI_RaidHeader", nil, "raid",
            "showRaid", true,
            "showParty", false,
            "showPlayer", false,
            "showSolo", false,
            "xOffset", 5,
            "yOffset", -5,
            "point", "LEFT",
            "groupFilter", "1,2,3,4,5,6,7,8",
            "groupingOrder", "1,2,3,4,5,6,7,8",
            "groupBy", "GROUP",
            "maxColumns", 8,
            "unitsPerColumn", 5,
            "columnSpacing", 5,
            "columnAnchorPoint", "TOP",
            "oUF-initialConfigFunction", [[
                self:SetHeight(25)
                self:SetWidth(80)
            ]]
        )
        if raid then
            raid:SetPoint(unpack(self.config.raid.pos or {"TOPLEFT", UIParent, "TOPLEFT", 20, -200}))
            self.units.raid = raid
            if ns.LogDebug then
                ns:LogDebug("Raid frames spawned")
            end
        end
    end
    
    -- Arena frames
    if self.config.showArena then
        local arena = {}
        for i = 1, 5 do
            arena[i] = oUF:Spawn("arena"..i, "DamiaUI_ArenaFrame"..i)
            if arena[i] then
                if i == 1 then
                    arena[i]:SetPoint(unpack(self.config.arena.pos or {"TOPRIGHT", UIParent, "TOPRIGHT", -100, -200}))
                else
                    arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -40)
                end
            end
        end
        self.units.arena = arena
        if ns.LogDebug then
            ns:LogDebug("Arena frames spawned")
        end
    end
    
    if ns.LogDebug then
        ns:LogDebug("All unit frames spawned successfully")
    end
end

-- Setup frame based on unit
function UnitFrames:SetupFrame(frame, unit)
    -- Frame settings
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(1)
    
    -- Register clicks
    frame:RegisterForClicks("AnyUp")
    
    -- Create backdrop
    if not frame.backdrop then
        frame.backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
        frame.backdrop:SetPoint("TOPLEFT", -3, 3)
        frame.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
        ns:CreateBackdrop(frame.backdrop)
    end
    
    -- Get unit configuration
    local unitType = unit:gsub("%d+", "")
    local unitConfig = self.config[unitType] or {}
    
    -- Set size
    local width = unitConfig.width or 200
    local height = unitConfig.height or 30
    frame:SetSize(width, height)
    
    -- Health bar
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetStatusBarTexture(ns.media.texture)
    health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    health:SetHeight(height * 0.85)
    health:SetWidth(width)
    
    -- Health colors
    health.colorClass = true
    health.colorReaction = true
    health.colorHealth = true
    health.frequentUpdates = true
    health.Smooth = true
    
    -- Health background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture(ns.media.texture)
    health.bg.multiplier = 0.3
    
    -- Health text
    health.value = health:CreateFontString(nil, "OVERLAY")
    health.value:SetFont(ns.media.font, 11, "OUTLINE")
    health.value:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    health.value:SetJustifyH("RIGHT")
    
    -- Power bar
    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture(ns.media.texture)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
    power:SetHeight(height * 0.15)
    
    -- Power colors
    power.colorPower = true
    power.frequentUpdates = true
    power.Smooth = true
    
    -- Power background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture(ns.media.texture)
    power.bg.multiplier = 0.3
    
    -- Power text
    power.value = power:CreateFontString(nil, "OVERLAY")
    power.value:SetFont(ns.media.font, 10, "OUTLINE")
    power.value:SetPoint("RIGHT", power, "RIGHT", -2, 0)
    power.value:SetJustifyH("RIGHT")
    
    -- Name
    local name = health:CreateFontString(nil, "OVERLAY")
    name:SetFont(ns.media.font, 12, "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 2, 0)
    name:SetJustifyH("LEFT")
    
    -- Level
    local level = health:CreateFontString(nil, "OVERLAY")
    level:SetFont(ns.media.font, 11, "OUTLINE")
    level:SetPoint("RIGHT", health.value, "LEFT", -2, 0)
    level:SetJustifyH("RIGHT")
    
    -- Portrait (optional for player/target)
    if unit == "player" or unit == "target" then
        local portrait = CreateFrame("PlayerModel", nil, frame)
        portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        portrait:SetWidth(height)
        portrait:SetHeight(height)
        portrait:SetAlpha(0.2)
        frame.Portrait = portrait
        
        -- Adjust health bar for portrait
        health:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 1, 0)
        health:SetWidth(width - height - 1)
    end
    
    -- Castbar for player, target, focus
    if unit == "player" or unit == "target" or unit == "focus" then
        local castbar = CreateFrame("StatusBar", nil, frame)
        castbar:SetStatusBarTexture(ns.media.texture)
        castbar:SetStatusBarColor(0.7, 0.7, 0.3)
        castbar:SetHeight(20)
        castbar:SetWidth(width)
        
        if unit == "player" then
            castbar:SetPoint("TOP", frame, "BOTTOM", 0, -5)
        else
            castbar:SetPoint("BOTTOM", frame, "TOP", 0, 5)
        end
        
        -- Castbar background
        castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture(ns.media.texture)
        castbar.bg:SetVertexColor(0.1, 0.1, 0.1)
        
        -- Castbar border
        if not castbar.backdrop then
            castbar.backdrop = CreateFrame("Frame", nil, castbar, "BackdropTemplate")
            castbar.backdrop:SetFrameLevel(castbar:GetFrameLevel() - 1)
            castbar.backdrop:SetPoint("TOPLEFT", -3, 3)
            castbar.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
            ns:CreateBackdrop(castbar.backdrop)
        end
        
        -- Cast time
        castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Time:SetFont(ns.media.font, 11, "OUTLINE")
        castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -2, 0)
        
        -- Spell name
        castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Text:SetFont(ns.media.font, 11, "OUTLINE")
        castbar.Text:SetPoint("LEFT", castbar, "LEFT", 2, 0)
        castbar.Text:SetPoint("RIGHT", castbar.Time, "LEFT", -2, 0)
        castbar.Text:SetJustifyH("LEFT")
        
        -- Spell icon
        castbar.Icon = castbar:CreateTexture(nil, "OVERLAY")
        castbar.Icon:SetHeight(20)
        castbar.Icon:SetWidth(20)
        castbar.Icon:SetPoint("RIGHT", castbar, "LEFT", -5, 0)
        castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- Icon border
        if not castbar.IconBorder then
            castbar.IconBorder = CreateFrame("Frame", nil, castbar, "BackdropTemplate")
            castbar.IconBorder:SetPoint("TOPLEFT", castbar.Icon, -2, 2)
            castbar.IconBorder:SetPoint("BOTTOMRIGHT", castbar.Icon, 2, -2)
            ns:CreateBackdrop(castbar.IconBorder)
        end
        
        -- Safe zone (for player)
        if unit == "player" then
            castbar.SafeZone = castbar:CreateTexture(nil, "OVERLAY")
            castbar.SafeZone:SetTexture(ns.media.texture)
            castbar.SafeZone:SetVertexColor(0.8, 0.2, 0.2, 0.3)
        end
        
        -- Shield for non-interruptible casts
        castbar.Shield = castbar:CreateTexture(nil, "OVERLAY")
        castbar.Shield:SetSize(20, 20)
        castbar.Shield:SetPoint("CENTER", castbar.Icon)
        castbar.Shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Shield")
        castbar.Shield:Hide()
        
        -- Custom castbar functions
        castbar.PostCastStart = self.PostCastStart
        castbar.PostChannelStart = self.PostChannelStart
        castbar.PostCastStop = self.PostCastStop
        castbar.PostChannelStop = self.PostChannelStop
        castbar.PostCastFailed = self.PostCastFailed
        castbar.PostCastInterrupted = self.PostCastInterrupted
        
        frame.Castbar = castbar
    end
    
    -- Auras (Buffs/Debuffs) for player/target
    if unit == "player" or unit == "target" then
        -- Buffs
        local buffs = CreateFrame("Frame", nil, frame)
        buffs:SetHeight(24)
        buffs:SetWidth(width)
        buffs.size = 24
        buffs.spacing = 2
        buffs.num = 8
        
        if unit == "player" then
            buffs:SetPoint("BOTTOM", frame, "TOP", 0, 30)
            buffs.initialAnchor = "BOTTOMLEFT"
            buffs["growth-x"] = "RIGHT"
            buffs["growth-y"] = "UP"
        else
            buffs:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
            buffs.initialAnchor = "TOPLEFT"
            buffs["growth-x"] = "RIGHT"
            buffs["growth-y"] = "DOWN"
        end
        
        buffs.PostCreateIcon = function(self, button)
            button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            button.count:SetFont(ns.media.font, 10, "OUTLINE")
            button.count:SetPoint("BOTTOMRIGHT", -1, 1)
            
            if not button.backdrop then
                button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
                button.backdrop:SetPoint("TOPLEFT", -2, 2)
                button.backdrop:SetPoint("BOTTOMRIGHT", 2, -2)
                ns:CreateBackdrop(button.backdrop)
            end
        end
        
        frame.Buffs = buffs
        
        -- Debuffs
        local debuffs = CreateFrame("Frame", nil, frame)
        debuffs:SetHeight(24)
        debuffs:SetWidth(width)
        debuffs.size = 24
        debuffs.spacing = 2
        debuffs.num = 8
        
        if unit == "player" then
            debuffs:SetPoint("TOP", buffs, "BOTTOM", 0, -5)
        else
            debuffs:SetPoint("BOTTOM", frame, "TOP", 0, 5)
        end
        
        debuffs.initialAnchor = "BOTTOMLEFT"
        debuffs["growth-x"] = "RIGHT"
        debuffs["growth-y"] = "UP"
        debuffs.onlyShowPlayer = (unit == "target")
        
        debuffs.PostCreateIcon = buffs.PostCreateIcon
        
        frame.Debuffs = debuffs
    end
    
    -- Raid Target Icon
    local raidIcon = frame:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(16, 16)
    raidIcon:SetPoint("CENTER", frame, "TOP", 0, 0)
    
    -- Combat Icon (player only)
    if unit == "player" then
        local combat = frame:CreateTexture(nil, "OVERLAY")
        combat:SetSize(16, 16)
        combat:SetPoint("CENTER", frame, "BOTTOMLEFT", 0, 0)
        frame.CombatIndicator = combat
    end
    
    -- Leader Icon
    local leader = frame:CreateTexture(nil, "OVERLAY")
    leader:SetSize(12, 12)
    leader:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    
    -- Role Icon
    local role = frame:CreateTexture(nil, "OVERLAY")
    role:SetSize(12, 12)
    role:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    
    -- Range checking for party/raid
    if unit:match("party") or unit:match("raid") then
        frame.Range = {
            insideAlpha = 1,
            outsideAlpha = 0.5
        }
    end
    
    -- Assign elements to frame
    frame.Health = health
    frame.Power = power
    frame.Name = name
    frame.Level = level
    frame.RaidTargetIndicator = raidIcon
    frame.LeaderIndicator = leader
    frame.GroupRoleIndicator = role
    
    -- Update functions
    self:SetupTags(frame, unit)
    self:SetupEvents(frame, unit)
end

-- Castbar post functions
function UnitFrames.PostCastStart(castbar, unit)
    if castbar.notInterruptible then
        castbar:SetStatusBarColor(0.7, 0.3, 0.3)
        if castbar.Shield then
            castbar.Shield:Show()
        end
    else
        castbar:SetStatusBarColor(0.7, 0.7, 0.3)
        if castbar.Shield then
            castbar.Shield:Hide()
        end
    end
end

UnitFrames.PostChannelStart = UnitFrames.PostCastStart

function UnitFrames.PostCastStop(castbar, unit)
    if castbar.Shield then
        castbar.Shield:Hide()
    end
end

UnitFrames.PostChannelStop = UnitFrames.PostCastStop

function UnitFrames.PostCastFailed(castbar, unit)
    castbar:SetStatusBarColor(0.8, 0.2, 0.2)
end

function UnitFrames.PostCastInterrupted(castbar, unit)
    castbar:SetStatusBarColor(0.8, 0.2, 0.2)
end

-- Setup oUF tags
function UnitFrames:SetupTags(frame, unit)
    -- Health value
    frame:Tag(frame.Health.value, "[damiaui:health]")
    
    -- Power value
    frame:Tag(frame.Power.value, "[damiaui:power]")
    
    -- Name
    frame:Tag(frame.Name, "[damiaui:name]")
    
    -- Level
    frame:Tag(frame.Level, "[damiaui:level]")
end

-- Register custom tags
function UnitFrames:RegisterTags()
    if ns.LogDebug then
        ns:LogDebug("Registering custom oUF tags")
    end
    
    -- Custom health tag
    oUF.Tags.Methods["damiaui:health"] = function(unit)
        local cur = UnitHealth(unit)
        local max = UnitHealthMax(unit)
        
        if UnitIsDead(unit) then
            return "Dead"
        elseif UnitIsGhost(unit) then
            return "Ghost"
        elseif not UnitIsConnected(unit) then
            return "Offline"
        else
            return ns:ShortValue(cur) .. " / " .. ns:ShortValue(max)
        end
    end
    oUF.Tags.Events["damiaui:health"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_DEAD PLAYER_ALIVE"
    
    -- Custom power tag
    oUF.Tags.Methods["damiaui:power"] = function(unit)
        local cur = UnitPower(unit)
        local max = UnitPowerMax(unit)
        
        if max == 0 then
            return ""
        else
            return ns:ShortValue(cur)
        end
    end
    oUF.Tags.Events["damiaui:power"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
    
    -- Custom name tag
    oUF.Tags.Methods["damiaui:name"] = function(unit)
        local name = UnitName(unit)
        return name and string.sub(name, 1, 20) or ""
    end
    oUF.Tags.Events["damiaui:name"] = "UNIT_NAME_UPDATE UNIT_CONNECTION"
    
    -- Custom level tag  
    oUF.Tags.Methods["damiaui:level"] = function(unit)
        local level = UnitLevel(unit)
        local classification = UnitClassification(unit)
        local color = GetQuestDifficultyColor(level) or {r = 1, g = 1, b = 1}
        
        if level == -1 then
            level = "??"
            color = {r = 1, g = 0, b = 0}
        end
        
        local elite = ""
        if classification == "elite" then
            elite = "+"
        elseif classification == "rare" then
            elite = "R"
        elseif classification == "rareelite" then
            elite = "R+"
        elseif classification == "worldboss" then
            elite = "B"
        end
        
        return format("|cff%02x%02x%02x%s%s|r", color.r*255, color.g*255, color.b*255, level, elite)
    end
    oUF.Tags.Events["damiaui:level"] = "UNIT_LEVEL UNIT_CLASSIFICATION_CHANGED"
    
    if ns.LogDebug then
        ns:LogDebug("Custom tags registered successfully")
    end
end

-- Setup events for unit-specific updates
function UnitFrames:SetupEvents(frame, unit)
    -- Additional unit-specific setup can go here
end

-- Utility function for shortening values
function ns:ShortValue(value)
    if not value then return "" end
    
    if value >= 1e6 then
        return format("%.1fm", value / 1e6)
    elseif value >= 1e3 then
        return format("%.1fk", value / 1e3)
    else
        return format("%d", value)
    end
end

-- Create backdrop helper
function ns:CreateBackdrop(frame)
    if not frame then return end
    
    frame:SetBackdrop({
        bgFile = ns.media.texture,
        edgeFile = ns.media.texture,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame:SetBackdropColor(unpack(ns.colors.backdrop))
    frame:SetBackdropBorderColor(unpack(ns.colors.border))
end

-- Register module
ns:RegisterModule("UnitFrames", UnitFrames)