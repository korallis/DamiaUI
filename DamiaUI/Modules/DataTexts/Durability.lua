-- DamiaUI Durability DataText
-- Based on ColdMisc durability.lua, updated for WoW 11.2

local addonName, ns = ...

local Durability = {}
ns:RegisterModule("DataTextDurability", Durability)

function Durability:Initialize()
    -- Get config with defaults
    local config = ns:GetConfig("datatexts") or {}
    if not config.showDurability then
        return
    end
    
    self:CreateDurabilityFrame()
end

function Durability:CreateDurabilityFrame()
    -- Create data text
    local DurabilityDataText = CreateFrame("Frame", "DamiaUIDurabilityDataText", UIParent)
    DurabilityDataText:SetSize(60, 20)
    DurabilityDataText:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 5, 5)

    -- Create text
    DurabilityDataText.text = DurabilityDataText:CreateFontString(nil, "OVERLAY")
    DurabilityDataText.text:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
    DurabilityDataText.text:SetPoint("CENTER")

-- Slot IDs for equipment
local slots = {
    [1] = {1, "Head"},
    [2] = {3, "Shoulder"},
    [3] = {5, "Chest"},
    [4] = {6, "Waist"},
    [5] = {7, "Legs"},
    [6] = {8, "Feet"},
    [7] = {9, "Wrist"},
    [8] = {10, "Hands"},
    [9] = {16, "Main Hand"},
    [10] = {17, "Off Hand"},
}

-- Update function
local function UpdateDurability()
    local current, total = 0, 0
    
    for i = 1, 10 do
        if slots[i] then
            local slotId = slots[i][1]
            local cur, max = GetInventoryItemDurability(slotId)
            if cur and max and max > 0 then
                current = current + cur
                total = total + max
            end
        end
    end
    
    local percent = 100
    if total > 0 then
        percent = (current / total) * 100
    end
    
    -- Color based on durability
    local r, g, b = 0, 1, 0
    if percent < 20 then
        r, g, b = 1, 0, 0
    elseif percent < 40 then
        r, g, b = 1, 0.5, 0
    elseif percent < 60 then
        r, g, b = 1, 1, 0
    end
    
    DurabilityDataText.text:SetFormattedText("|cff%02x%02x%02x%d%%|r", r*255, g*255, b*255, percent)
end

-- Tooltip
DurabilityDataText:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Durability", 1, 1, 1)
    
    for i = 1, 10 do
        if slots[i] then
            local slotId, slotName = slots[i][1], slots[i][2]
            local cur, max = GetInventoryItemDurability(slotId)
            if cur and max and max > 0 then
                local percent = (cur / max) * 100
                local r, g, b = 0, 1, 0
                if percent < 20 then
                    r, g, b = 1, 0, 0
                elseif percent < 40 then
                    r, g, b = 1, 0.5, 0
                elseif percent < 60 then
                    r, g, b = 1, 1, 0
                end
                GameTooltip:AddDoubleLine(slotName, string.format("%d%%", percent), 1, 1, 1, r, g, b)
            end
        end
    end
    
    -- Repair cost
    local cost = GetRepairAllCost()
    if cost and cost > 0 then
        GameTooltip:AddLine(" ")
        local gold = floor(cost / 10000)
        local silver = floor((cost - gold * 10000) / 100)
        local copper = mod(cost, 100)
        GameTooltip:AddDoubleLine("Repair Cost:", string.format("%dg %ds %dc", gold, silver, copper), 1, 1, 1, 1, 1, 1)
    end
    
    GameTooltip:Show()
end)

DurabilityDataText:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Click to open character panel
DurabilityDataText:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        if not CharacterFrame:IsShown() then
            ShowUIPanel(CharacterFrame)
        else
            HideUIPanel(CharacterFrame)
        end
    end
end)

-- Register events
DurabilityDataText:RegisterEvent("PLAYER_ENTERING_WORLD")
DurabilityDataText:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
DurabilityDataText:RegisterEvent("MERCHANT_SHOW")
DurabilityDataText:RegisterEvent("PLAYER_DEAD")

DurabilityDataText:SetScript("OnEvent", function(self, event)
    UpdateDurability()
end)

    -- Initial update
    UpdateDurability()
    
    self.frame = DurabilityDataText
end

return Durability