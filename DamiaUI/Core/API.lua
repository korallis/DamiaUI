-- DamiaUI API Compatibility Layer for WoW 11.2
-- Provides compatibility shims for deprecated or changed APIs

local addonName, ns = ...

-- API Compatibility fixes for 11.2
-- Many functions moved to C_* namespaces in 11.x

-- Action Bar APIs
if not GetActionCooldown and C_ActionBar then
    GetActionCooldown = function(slot)
        local info = C_ActionBar.GetActionCooldown(slot)
        if info then
            return info.startTime, info.duration, info.modRate
        end
        return 0, 0, 0
    end
end

-- Spell APIs (many moved to C_Spell in 11.x)
if not GetSpellCooldown and C_Spell then
    GetSpellCooldown = function(spell)
        local info = C_Spell.GetSpellCooldown(spell)
        if info then
            return info.startTime, info.duration, info.isEnabled, info.modRate
        end
        return 0, 0, 0, 0
    end
end

if not GetSpellInfo and C_Spell then
    GetSpellInfo = function(spell)
        local info = C_Spell.GetSpellInfo(spell)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
        return nil
    end
end

-- Container/Bag APIs (moved to C_Container in 10.x)
if not GetContainerNumSlots and C_Container then
    GetContainerNumSlots = C_Container.GetContainerNumSlots
end

if not GetContainerItemInfo and C_Container then
    GetContainerItemInfo = function(bag, slot)
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.iconFileID, info.stackCount, info.isLocked, info.quality, info.isReadable, info.hasLoot, info.hyperlink, info.isFiltered, info.hasNoValue, info.itemID
        end
        return nil
    end
end

-- Minimap APIs
if not GetMinimapZoneText and C_Map then
    GetMinimapZoneText = function()
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local info = C_Map.GetMapInfo(mapID)
            if info then
                return info.name
            end
        end
        return ""
    end
end

-- Item APIs
if not GetItemInfo and C_Item then
    GetItemInfo = function(item)
        local info = C_Item.GetItemInfo(item)
        if info then
            return info.itemName, info.itemLink, info.itemQuality, info.itemLevel, info.itemMinLevel, info.itemType, info.itemSubType, info.itemStackCount, info.itemEquipLoc, info.itemTexture, info.sellPrice, info.classID, info.subclassID, info.bindType, info.expansionID, info.setID, info.isCraftingReagent
        end
        return nil
    end
end

-- Currency APIs
if not GetCurrencyInfo and C_CurrencyInfo then
    GetCurrencyInfo = function(currencyType)
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyType)
        if info then
            return info.name, info.quantity, info.iconFileID, info.quantityEarnedThisWeek, info.maxWeeklyQuantity, info.maxQuantity, info.discovered, info.quality
        end
        return nil
    end
end

-- Timer APIs
if not After and C_Timer then
    After = C_Timer.After
end

-- Fix for ActionButton functions that don't exist
if not ActionButton_UpdateAction then
    ActionButton_UpdateAction = function(button)
        local action = button.action or button:GetAttribute("action")
        if action and button.Update then
            button:Update()
        end
    end
end

-- Fix for removed grid functions
if not ActionButton_ShowGrid then
    ActionButton_ShowGrid = function(button)
        if button then
            button:SetAttribute("showgrid", 1)
            if button.SetAlpha then
                button:SetAlpha(1)
            end
        end
    end
end

if not ActionButton_HideGrid then
    ActionButton_HideGrid = function(button)
        if button then
            button:SetAttribute("showgrid", 0)
            local action = button:GetAttribute("action")
            if not (action and HasAction(action)) and button.SetAlpha then
                button:SetAlpha(0)
            end
        end
    end
end

-- Fix for IsEquippedAction (ensure it exists)
if not IsEquippedAction then
    IsEquippedAction = function(slot)
        if not slot then return false end
        local actionType, id = GetActionInfo(slot)
        if actionType == "item" then
            return IsEquippedItem(id)
        end
        return false
    end
end

-- Fix for HasAction (ensure it exists)
if not HasAction then
    HasAction = function(slot)
        if not slot then return false end
        local actionType = GetActionInfo(slot)
        return actionType ~= nil
    end
end

-- Fix for GetActionInfo (ensure it exists)
if not GetActionInfo then
    GetActionInfo = function(slot)
        if not slot then return nil end
        -- This is a core API that should exist, if it doesn't we can't fully replicate it
        -- Return nil to indicate no action
        return nil
    end
end

-- Backdrop template mixin for frames that don't have it
if not BackdropTemplateMixin then
    BackdropTemplateMixin = {}
end

-- Ensure PowerBarColor exists
if not PowerBarColor then
    PowerBarColor = {
        ["MANA"] = {r = 0.31, g = 0.45, b = 0.63},
        ["RAGE"] = {r = 0.69, g = 0.31, b = 0.31},
        ["FOCUS"] = {r = 0.71, g = 0.43, b = 0.27},
        ["ENERGY"] = {r = 0.65, g = 0.63, b = 0.35},
        ["RUNIC_POWER"] = {r = 0, g = 0.82, b = 1},
        ["FURY"] = {r = 0.788, g = 0.259, b = 0.992},
        ["PAIN"] = {r = 1, g = 0.61, b = 0},
        ["MAELSTROM"] = {r = 0, g = 0.5, b = 1},
        ["INSANITY"] = {r = 0.4, g = 0, b = 0.8},
        ["LUNAR_POWER"] = {r = 0.93, g = 0.51, b = 0.93},
    }
end

-- Fix for GetZonePVPInfo
if not GetZonePVPInfo then
    GetZonePVPInfo = function()
        local pvpType = C_PvP and C_PvP.GetZonePVPInfo and C_PvP.GetZonePVPInfo()
        return pvpType or "contested"
    end
end

-- Fix for GetNumShapeshiftForms
if not GetNumShapeshiftForms then
    GetNumShapeshiftForms = function()
        return C_StanceBar and C_StanceBar.GetNumStances and C_StanceBar.GetNumStances() or 0
    end
end

-- Fix for TimeManagerClockButton (might not exist in 11.2)
if not TimeManagerClockButton then
    -- Create a dummy frame if it doesn't exist
    TimeManagerClockButton = CreateFrame("Frame", "TimeManagerClockButton", UIParent)
    TimeManagerClockButton:Hide()
end

-- Fix for Calendar and Time Manager functions
if not Calendar_Toggle then
    Calendar_Toggle = function()
        if C_Calendar and C_Calendar.OpenCalendar then
            C_Calendar.OpenCalendar()
        elseif ToggleCalendar then
            ToggleCalendar()
        end
    end
end

if not TimeManager_Toggle then
    TimeManager_Toggle = function()
        if _G.TimeManagerFrame then
            _G.TimeManagerFrame:SetShown(not _G.TimeManagerFrame:IsShown())
        end
    end
end

-- Fix for ToggleCalendar (ensure it exists)
if not ToggleCalendar then
    ToggleCalendar = function()
        if C_Calendar and C_Calendar.OpenCalendar then
            C_Calendar.OpenCalendar()
        elseif GameTimeFrame then
            GameTimeFrame:Click()
        end
    end
end

-- Fix for ToggleTimeManager (ensure it exists)
if not ToggleTimeManager then
    ToggleTimeManager = function()
        if _G.TimeManagerFrame then
            _G.TimeManagerFrame:SetShown(not _G.TimeManagerFrame:IsShown())
        end
    end
end

-- Fix for GetRuneCooldown (Death Knight)
if not GetRuneCooldown then
    GetRuneCooldown = function(runeIndex)
        if _G.C_RuneBar and _G.C_RuneBar.GetRuneCooldown then
            return _G.C_RuneBar.GetRuneCooldown(runeIndex)
        end
        return 0, 0, false
    end
end

-- Fix for GetGuildInfo (moved to C_GuildInfo in 11.x)
if not GetGuildInfo then
    GetGuildInfo = function(unit)
        if C_GuildInfo and C_GuildInfo.GetGuildInfo then
            local info = C_GuildInfo.GetGuildInfo(unit)
            if info then
                return info.guildName, info.guildRankName, info.guildRankIndex, info.realm
            end
        end
        return nil
    end
end

-- Fix for UnitAura/UnitBuff/UnitDebuff (deprecated in 10.2.6, removed in 11.x)
if not UnitAura and C_UnitAuras then
    UnitAura = function(unit, index, filter)
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name, auraData.icon, auraData.applications, auraData.dispelType,
                   auraData.duration, auraData.expirationTime, auraData.sourceUnit,
                   auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId,
                   auraData.canApplyAura, auraData.isBossDebuff, auraData.castByPlayer,
                   auraData.nameplateShowAll, auraData.timeMod
        end
        return nil
    end
end

if not UnitBuff and C_UnitAuras then
    UnitBuff = function(unit, index, filter)
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name, auraData.icon, auraData.applications, auraData.dispelType,
                   auraData.duration, auraData.expirationTime, auraData.sourceUnit,
                   auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId,
                   auraData.canApplyAura, auraData.isBossDebuff, auraData.castByPlayer,
                   auraData.nameplateShowAll, auraData.timeMod
        end
        return nil
    end
end

if not UnitDebuff and C_UnitAuras then
    UnitDebuff = function(unit, index, filter)
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name, auraData.icon, auraData.applications, auraData.dispelType,
                   auraData.duration, auraData.expirationTime, auraData.sourceUnit,
                   auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId,
                   auraData.canApplyAura, auraData.isBossDebuff, auraData.castByPlayer,
                   auraData.nameplateShowAll, auraData.timeMod
        end
        return nil
    end
end

-- Fix for GetRealmName (might be deprecated in 11.x)
if not GetRealmName then
    GetRealmName = function()
        local realmName = GetNormalizedRealmName and GetNormalizedRealmName() or ""
        if realmName == "" and C_RealmInfo then
            local info = C_RealmInfo.GetCurrentRealmInfo()
            if info then
                realmName = info.realmName
            end
        end
        return realmName
    end
end

-- Fix for GetInventoryItemDurability (moved to C_Item in 11.x) 
if not GetInventoryItemDurability and C_Item then
    GetInventoryItemDurability = function(slot)
        local current, maximum = C_Item.GetItemInventoryDurability(slot)
        return current, maximum
    end
end

-- Fix for GetItemQualityColor (moved to C_Item in 11.x)
if not GetItemQualityColor and C_Item then
    GetItemQualityColor = function(quality)
        local color = C_Item.GetItemQualityColor(quality) or ITEM_QUALITY_COLORS[quality]
        if color then
            return color.r, color.g, color.b, color.hex
        end
        return 1, 1, 1, "|cffffffff"
    end
end

-- Fix for deprecated dropdown functions (use LibUIDropDownMenu or new Menu API)
if not EasyMenu then
    EasyMenu = function(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
        -- Fallback to using the new Menu API if available
        if Menu then
            Menu.ModifyMenu(menuFrame:GetName(), function(dropdown, rootDescription)
                for _, item in ipairs(menuList) do
                    if item.text then
                        local button = rootDescription:CreateButton(item.text)
                        if item.func then
                            button:SetAction(item.func)
                        end
                    end
                end
            end)
        else
            -- Basic fallback - create a simple context menu
            print("EasyMenu is deprecated. Please update to use the new Menu API.")
        end
    end
end

-- Fix for ToggleDropDownMenu (deprecated, use new Menu API)
if not ToggleDropDownMenu then
    ToggleDropDownMenu = function(level, value, dropDownFrame, anchorName, xOffset, yOffset)
        -- Basic fallback
        if dropDownFrame and dropDownFrame.Toggle then
            dropDownFrame:Toggle()
        else
            print("ToggleDropDownMenu is deprecated. Please update to use the new Menu API.")
        end
    end
end

-- Print debug info
ns:Debug("API Compatibility Layer loaded for WoW 11.2")