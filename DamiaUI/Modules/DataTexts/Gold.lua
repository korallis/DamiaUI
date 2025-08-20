--------------------------------------------------------------------
-- DamiaUI DataText - Gold
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

local Gold = {}

-- Module registration
ns:RegisterModule("DataTextGold", Gold)

function Gold:Initialize()
    if not ns:GetConfig("datatexts", "showGold") then
        return
    end
    
    self:CreateGoldFrame()
end

function Gold:CreateGoldFrame()
    -- Create the gold frame (assuming we have a data text panel)
    local Stat = CreateFrame("Frame", "DamiaUI_GoldFrame", UIParent)
    Stat:EnableMouse(true)
    Stat:SetFrameStrata("MEDIUM")
    Stat:SetFrameLevel(3)
    Stat:SetSize(60, 17)
    
    -- Position relative to minimap for now - this should be configurable
    Stat:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -10)
    
    local Text = Stat:CreateFontString(nil, "OVERLAY")
    Text:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
    Text:SetPoint("RIGHT", -4, 1)
    Text:SetJustifyH("RIGHT")

    local Profit = 0
    local Spent = 0
    local OldMoney = 0
    local myPlayerRealm = GetCVar("realmName")

    local function formatMoney(money)
        local gold = math.floor(math.abs(money) / 10000)
        local silver = math.fmod(math.floor(math.abs(money) / 100), 100)
        local copper = math.fmod(math.floor(math.abs(money)), 100)
        if gold ~= 0 then
            return format("%s.%s".."|cffffd700g|r", gold, silver)
        elseif silver ~= 0 then
            return format("%s.%s".."|cffc7c7cfs|r", silver, copper)
        else
            return format("%s".."|cffeda55fc|r", copper)
        end
    end

    local function FormatTooltipMoney(money)
        local gold, silver, copper = math.abs(money / 10000), math.abs(math.fmod(money / 100, 100)), math.abs(math.fmod(money, 100))
        local cash = ""
        cash = format("%.2d".."|cffffd700g|r".." %.2d".."|cffc7c7cfs|r".." %.2d".."|cffeda55fc|r", gold, silver, copper)		
        return cash
    end	

    local function OnEvent(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            OldMoney = GetMoney()
        end
        
        local NewMoney = GetMoney()
        local Change = NewMoney - OldMoney -- Positive if we gain money
        
        if OldMoney > NewMoney then		-- Lost Money
            Spent = Spent - Change
        else							-- Gained Money
            Profit = Profit + Change
        end
        
        Text:SetText(formatMoney(NewMoney))

        local myPlayerName = UnitName("player")				
                
        OldMoney = NewMoney
    end

    Stat:RegisterEvent("PLAYER_MONEY")
    Stat:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
    Stat:RegisterEvent("SEND_MAIL_COD_CHANGED")
    Stat:RegisterEvent("PLAYER_TRADE_MONEY")
    Stat:RegisterEvent("TRADE_MONEY_CHANGED")
    Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
    Stat:SetScript("OnMouseDown", function() 
        if not InCombatLockdown() then
            OpenAllBags() 
        end
    end)
    Stat:SetScript("OnEvent", OnEvent)
    Stat:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then
            GameTooltip:SetOwner(Stat, "ANCHOR_TOP", -26, 5)
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Session: ")
            GameTooltip:AddDoubleLine("Earned:", formatMoney(Profit), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Spent:", formatMoney(Spent), 1, 1, 1, 1, 1, 1)
            if Profit < Spent then
                GameTooltip:AddDoubleLine("Deficit:", formatMoney(Profit-Spent), 1, 0, 0, 1, 1, 1)
            elseif (Profit-Spent) > 0 then
                GameTooltip:AddDoubleLine("Profit:", formatMoney(Profit-Spent), 0, 1, 0, 1, 1, 1)
            end				
            GameTooltip:AddLine(' ')								

            -- Use WoW 11.2 compatible API for currency info
            -- In 11.2, backpack can track up to 3 currencies
            local maxBackpackCurrencies = 3
            for i = 1, maxBackpackCurrencies do
                local name, count, icon, currencyID
                if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
                    local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
                    if info then
                        name, count, icon, currencyID = info.name, info.quantity, info.iconFileID, info.currencyTypesID
                    end
                elseif GetBackpackCurrencyInfo then
                    name, count, _, icon, currencyID = GetBackpackCurrencyInfo(i)
                end
                
                if name and i == 1 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(CURRENCY)
                end
                local r, g, b = 1, 1, 1
                if currencyID then 
                    -- Currency items use currency ID, not item ID for quality
                    -- Most currencies are white quality
                    r, g, b = 1, 1, 1
                end
                if name and count then 
                    GameTooltip:AddDoubleLine(name, count, r, g, b, 1, 1, 1) 
                end
            end
            GameTooltip:Show()
        end
    end)
    Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    self.frame = Stat
end

return Gold