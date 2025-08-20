--------------------------------------------------------------------
-- GOLD
--------------------------------------------------------------------
	local Stat = CreateFrame("Frame", "goldFrame", dataTextPanel)
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("MEDIUM")
	Stat:SetFrameLevel(3)
	Stat:SetSize(60, 17)
	Stat:SetPoint("RIGHT", dataTextPanel, "RIGHT")
	
	local Text  = Stat:CreateFontString(nil, "OVERLAY")
	Text:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
	Text:SetPoint("RIGHT", -4, 1)
	Text:SetJustifyH"RIGHT"

	local Profit	= 0
	local Spent		= 0
	local OldMoney	= 0
	local myPlayerRealm = GetCVar("realmName");

	local function formatMoney(money)
		local gold = floor(math.abs(money) / 10000)
		local silver = mod(floor(math.abs(money) / 100), 100)
		local copper = mod(floor(math.abs(money)), 100)
		if gold ~= 0 then
			return format("%s.%s".."|cffffd700g|r", gold, silver)
		elseif silver ~= 0 then
			return format("%s.%s".."|cffc7c7cfs|r", silver, copper)
		else
			return format("%s".."|cffeda55fc|r", copper)
		end
	end

	local function FormatTooltipMoney(money)
		local gold, silver, copper = abs(money / 10000), abs(mod(money / 100, 100)), abs(mod(money, 100))
		local cash = ""
		cash = format("%.2d".."|cffffd700g|r".." %.2d".."|cffc7c7cfs|r".." %.2d".."|cffeda55fc|r", gold, silver, copper)		
		return cash
	end	

	local function OnEvent(self, event)
		if event == "PLAYER_ENTERING_WORLD" then
			OldMoney = GetMoney()
		end
		
		local NewMoney	= GetMoney()
		local Change = NewMoney-OldMoney -- Positive if we gain money
		
		if OldMoney>NewMoney then		-- Lost Money
			Spent = Spent - Change
		else							-- Gained Moeny
			Profit = Profit + Change
		end
		
		Text:SetText(formatMoney(NewMoney))

		local myPlayerName  = UnitName("player");				
				
		OldMoney = NewMoney
	end

	Stat:RegisterEvent("PLAYER_MONEY")
	Stat:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
	Stat:RegisterEvent("SEND_MAIL_COD_CHANGED")
	Stat:RegisterEvent("PLAYER_TRADE_MONEY")
	Stat:RegisterEvent("TRADE_MONEY_CHANGED")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:SetScript("OnMouseDown", function() OpenAllBags() end)
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
			elseif (Profit-Spent)>0 then
				GameTooltip:AddDoubleLine("Profit:", formatMoney(Profit-Spent), 0, 1, 0, 1, 1, 1)
			end				
			GameTooltip:AddLine' '								

			for i = 1, GetNumWatchedTokens() do
				local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)
				if name and i == 1 then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(CURRENCY)
				end
				local r, g, b = 1,1,1
				if itemID then r, g, b = GetItemQualityColor(select(3, GetItemInfo(itemID))) end
				if name and count then GameTooltip:AddDoubleLine(name, count, r, g, b, 1, 1, 1) end
			end
			GameTooltip:Show()
		end
	end)
	Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)	