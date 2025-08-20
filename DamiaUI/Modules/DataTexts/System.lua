--------------------------------------------------------------------
-- DamiaUI DataText - System Stats
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

local System = {}

-- Module registration
ns:RegisterModule("DataTextSystem", System)

function System:Initialize()
    -- Get config with defaults
    local config = ns:GetConfig("datatexts") or {}
    if not config.showSystem then
        return
    end
    
    self:CreateSystemFrame()
end

function System:CreateSystemFrame()
    local classcolors = {
        ["DEATHKNIGHT"] = { 196/255,  30/255,  60/255 },
        ["DRUID"]       = { 255/255, 125/255,  10/255 },
        ["HUNTER"]      = { 171/255, 214/255, 116/255 },
        ["MAGE"]        = { 104/255, 205/255, 255/255 },
        ["PALADIN"]     = { 245/255, 140/255, 186/255 },
        ["PRIEST"]      = { 212/255, 212/255, 212/255 },
        ["ROGUE"]       = { 255/255, 243/255,  82/255 },
        ["SHAMAN"]      = {  41/255,  79/255, 155/255 },
        ["WARLOCK"]     = { 148/255, 130/255, 201/255 },
        ["WARRIOR"]     = { 199/255, 156/255, 110/255 },
        ["MONK"]        = {   0/255, 156/255, 110/255 },
        ["DEMONHUNTER"] = { 163/255,  48/255, 201/255 },
        ["EVOKER"]      = {  51/255, 147/255, 127/255 },
    }

    local _, theClass = UnitClass("player")
    local color = classcolors[theClass] or {1, 1, 1}

    local Stat = CreateFrame("Frame", "DamiaUI_SystemFrame", UIParent)
    Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
    Stat:SetFrameStrata("MEDIUM")
    Stat:SetFrameLevel(3)
    Stat:EnableMouse(true)
    Stat.tooltip = false
    Stat:SetSize(60, 17)
    
    -- Position relative to minimap for now - this should be configurable
    Stat:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -70, -10)

    local Text = Stat:CreateFontString(nil, "OVERLAY")
    Text:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    Text:SetPoint("CENTER", 0, 1)
    Text:SetTextColor(color[1], color[2], color[3])
    Text:SetJustifyH("CENTER")

    local bandwidthString = "%.2f Mbps"
    local percentageString = "%.2f%%"

    local kiloByteString = "|c00ffffff%d|rkb"
    local megaByteString = "|c00ffffff%.2f|rmb"

    local function formatMem(memory)
        local mult = 10^1
        if memory > 999 then
            local mem = ((memory/1024) * mult) / mult
            return string.format(megaByteString, mem)
        else
            local mem = (memory * mult) / mult
            return string.format(kiloByteString, mem)
        end
    end

    local memoryTable = {}

    local function RebuildAddonList(self)
        -- Use C_AddOns API for WoW 11.2 compatibility
        local addOnCount
        if C_AddOns and C_AddOns.GetNumAddOns then
            addOnCount = C_AddOns.GetNumAddOns()
        else
            addOnCount = GetNumAddOns()
        end
        
        if (addOnCount == #memoryTable) or self.tooltip == true then 
            return 
        end

        -- Number of loaded addons changed, create new memoryTable for all addons
        memoryTable = {}
        for i = 1, addOnCount do
            local name
            if C_AddOns and C_AddOns.GetAddOnInfo then
                name = select(2, C_AddOns.GetAddOnInfo(i))
            else
                name = select(2, GetAddOnInfo(i))
            end
            
            local isLoaded
            if C_AddOns and C_AddOns.IsAddOnLoaded then
                isLoaded = C_AddOns.IsAddOnLoaded(i)
            else
                isLoaded = IsAddOnLoaded(i)
            end
            
            memoryTable[i] = { i, name, 0, isLoaded }
        end
    end

    local function UpdateMemory()
        -- Update the memory usages of the addons
        if UpdateAddOnMemoryUsage then
            UpdateAddOnMemoryUsage()
        end
        
        -- Load memory usage in table
        local addOnMem = 0
        local totalMemory = 0
        for i = 1, #memoryTable do
            local memUsage
            if C_AddOns and C_AddOns.GetAddOnMemoryUsage then
                memUsage = C_AddOns.GetAddOnMemoryUsage(memoryTable[i][1])
            else
                memUsage = GetAddOnMemoryUsage and GetAddOnMemoryUsage(memoryTable[i][1]) or 0
            end
            
            memoryTable[i][3] = memUsage
            totalMemory = totalMemory + memUsage
        end
        
        -- Sort the table to put the largest addon on top
        table.sort(memoryTable, function(a, b)
            if a and b then
                return a[3] > b[3]
            end
        end)
        
        return totalMemory
    end

    local int = 10

    local function Update(self, t)
        int = int - t
        if int < 0 then
            collectgarbage("collect")
            RebuildAddonList(self)
            local total = UpdateMemory()
            Text:SetText(formatMem(total))
            Text:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
            int = 10
        end
    end

    Stat:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then
            self.tooltip = true
            local bandwidth
            if GetAvailableBandwidth then
                bandwidth = GetAvailableBandwidth()
            else
                bandwidth = 0
            end
            
            GameTooltip:SetOwner(Stat, "ANCHOR_TOP", 0, 5)
            GameTooltip:ClearLines()
            
            if bandwidth ~= 0 then
                GameTooltip:AddDoubleLine("Bandwidth: ", string.format(bandwidthString, bandwidth), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
                local downloadPercent
                if GetDownloadedPercentage then
                    downloadPercent = GetDownloadedPercentage() * 100
                else
                    downloadPercent = 0
                end
                GameTooltip:AddDoubleLine("Download: ", string.format(percentageString, downloadPercent), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
                GameTooltip:AddLine(" ")
            end
            
            local totalMemory = UpdateMemory()
            GameTooltip:AddDoubleLine("Total Memory Usage: ", formatMem(totalMemory), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
            GameTooltip:AddLine(" ")
            
            for i = 1, #memoryTable do
                if (memoryTable[i][4]) then
                    local red = memoryTable[i][3] / totalMemory
                    local green = 1 - red
                    GameTooltip:AddDoubleLine(memoryTable[i][2], formatMem(memoryTable[i][3]), 1, 1, 1, red, green + .5, 0)
                end						
            end
            GameTooltip:Show()
        end
    end)
    
    Stat:SetScript("OnLeave", function(self) 
        self.tooltip = false 
        GameTooltip:Hide() 
    end)
    
    Stat:SetScript("OnUpdate", Update)
    Update(Stat, 10)
    
    self.frame = Stat
end

return System