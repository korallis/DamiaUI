-- DamiaUI Unit Frames Layout
-- Spawns all unit frames using oUF

local addonName, ns = ...
local oUF = ns.oUF or oUF
local UnitFrames = ns.UnitFrames

-- Spawn all unit frames
function UnitFrames:SpawnUnits()
    -- Player
    local player = oUF:Spawn("player", "DamiaUIPlayerFrame")
    if self.config.player and self.config.player.pos then
        player:SetPoint(unpack(self.config.player.pos))
    else
        player:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -150, 260)
    end
    ns:MakeMovable(player, true)
    self.units.player = player
    
    -- Target
    local target = oUF:Spawn("target", "DamiaUITargetFrame")
    if self.config.target and self.config.target.pos then
        target:SetPoint(unpack(self.config.target.pos))
    else
        target:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 150, 260)
    end
    ns:MakeMovable(target, true)
    self.units.target = target
    
    -- Target of Target
    local targettarget = oUF:Spawn("targettarget", "DamiaUITargetTargetFrame")
    targettarget:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -5)
    self.units.targettarget = targettarget
    
    -- Focus
    local focus = oUF:Spawn("focus", "DamiaUIFocusFrame")
    if self.config.focus and self.config.focus.pos then
        focus:SetPoint(unpack(self.config.focus.pos))
    else
        focus:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -150, 320)
    end
    ns:MakeMovable(focus, true)
    self.units.focus = focus
    
    -- Focus Target
    local focustarget = oUF:Spawn("focustarget", "DamiaUIFocusTargetFrame")
    focustarget:SetPoint("TOPRIGHT", focus, "BOTTOMRIGHT", 0, -5)
    self.units.focustarget = focustarget
    
    -- Pet
    local pet = oUF:Spawn("pet", "DamiaUIPetFrame")
    pet:SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -5)
    self.units.pet = pet
    
    -- Party
    if self.config.showParty then
        local party = oUF:SpawnHeader("DamiaUIPartyHeader", nil, "party",
            "showParty", true,
            "showPlayer", false,
            "showSolo", false,
            "xOffset", 0,
            "yOffset", -40,
            "maxColumns", 1,
            "unitsPerColumn", 4,
            "columnAnchorPoint", "TOP",
            "initial-anchor", "TOPLEFT",
            "initial-width", self.config.party and self.config.party.width or 150,
            "initial-height", self.config.party and self.config.party.height or 25,
            "oUF-initialConfigFunction", [[
                self:SetWidth(150)
                self:SetHeight(25)
            ]]
        )
        
        if self.config.party and self.config.party.pos then
            party:SetPoint(unpack(self.config.party.pos))
        else
            party:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -100)
        end
        ns:MakeMovable(party, true)
        self.units.party = party
    end
    
    -- Raid
    if self.config.showRaid then
        local raid = {}
        for i = 1, 8 do
            local header = oUF:SpawnHeader("DamiaUIRaidGroup"..i, nil, "raid",
                "showRaid", true,
                "showParty", false,
                "showPlayer", true,
                "xOffset", 5,
                "yOffset", -5,
                "maxColumns", 5,
                "unitsPerColumn", 5,
                "columnAnchorPoint", "LEFT",
                "initial-anchor", "TOPLEFT",
                "initial-width", self.config.raid and self.config.raid.width or 80,
                "initial-height", self.config.raid and self.config.raid.height or 25,
                "groupFilter", tostring(i),
                "oUF-initialConfigFunction", [[
                    self:SetWidth(80)
                    self:SetHeight(25)
                ]]
            )
            
            if i == 1 then
                if self.config.raid and self.config.raid.pos then
                    header:SetPoint(unpack(self.config.raid.pos))
                else
                    header:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
                end
                ns:MakeMovable(header, true)
            else
                header:SetPoint("TOPLEFT", raid[i-1], "BOTTOMLEFT", 0, -10)
            end
            
            raid[i] = header
        end
        self.units.raid = raid
    end
    
    -- Boss frames
    local boss = {}
    for i = 1, 5 do
        boss[i] = oUF:Spawn("boss"..i, "DamiaUIBoss"..i.."Frame")
        if i == 1 then
            boss[i]:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -100, -200)
        else
            boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -30)
        end
        self.units["boss"..i] = boss[i]
    end
    
    -- Arena frames
    if self.config.showArena then
        local arena = {}
        for i = 1, 5 do
            arena[i] = oUF:Spawn("arena"..i, "DamiaUIArena"..i.."Frame")
            if i == 1 then
                if self.config.arena and self.config.arena.pos then
                    arena[i]:SetPoint(unpack(self.config.arena.pos))
                else
                    arena[i]:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -100, -200)
                end
                ns:MakeMovable(arena[i], true)
            else
                arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -30)
            end
            self.units["arena"..i] = arena[i]
        end
        
        -- Arena prep frames
        local arenaprep = {}
        for i = 1, 5 do
            arenaprep[i] = oUF:Spawn("arenapet"..i, "DamiaUIArenaPet"..i.."Frame")
            arenaprep[i]:SetPoint("TOPRIGHT", arena[i], "TOPLEFT", -5, 0)
            self.units["arenapet"..i] = arenaprep[i]
        end
    end
end