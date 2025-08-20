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

-- MiniMapTrackingDropDown fix (after line 376)
if not MiniMapTrackingDropDown then
    -- Create dummy frame if it doesn't exist
    MiniMapTrackingDropDown = CreateFrame("Frame", "MiniMapTrackingDropDown", Minimap)
    MiniMapTrackingDropDown:Hide()
    
    -- Add toggle function if it doesn't exist
    MiniMapTrackingDropDown.Toggle = function()
        if C_Minimap and C_Minimap.GetTrackingInfo then
            -- Use new tracking API if available
            ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", 0, 0)
        end
    end
end

-- InCombatLockdown function (ensure it exists)
if not InCombatLockdown then
    InCombatLockdown = function()
        return UnitAffectingCombat("player") or false
    end
end

-- Combat Lockdown Protection Utilities
ns.CombatProtection = ns.CombatProtection or {}

-- Queue for functions to execute after combat
local postCombatQueue = {}
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Execute queued functions after combat
        for i = 1, #postCombatQueue do
            local func = postCombatQueue[i]
            if type(func) == "function" then
                pcall(func)
            end
        end
        wipe(postCombatQueue)
    end
end)

-- Safe execution wrapper
function ns.CombatProtection.SafeCall(func, ...)
    if not func or type(func) ~= "function" then
        return false
    end
    
    if InCombatLockdown() then
        -- Capture varargs before closure (cannot use ... inside closures)
        local args = {...}
        -- Queue for after combat
        table.insert(postCombatQueue, function()
            func(unpack(args))
        end)
        return false, "queued"
    else
        -- Execute immediately
        local success, result = pcall(func, ...)
        return success, result
    end
end

-- Safe frame modification wrapper
function ns.CombatProtection.SafeFrameCall(frame, method, ...)
    if not frame or not method then
        return false
    end
    
    if InCombatLockdown() then
        -- Capture varargs before closure (cannot use ... inside closures)
        local args = {...}
        table.insert(postCombatQueue, function()
            if frame and frame[method] then
                frame[method](frame, unpack(args))
            end
        end)
        return false, "queued"
    else
        if frame and frame[method] then
            local success, result = pcall(frame[method], frame, ...)
            return success, result
        end
    end
    return false
end

-- Safe attribute setting
function ns.CombatProtection.SafeSetAttribute(frame, attribute, value)
    if not frame or not attribute then
        return false
    end
    
    if InCombatLockdown() then
        table.insert(postCombatQueue, function()
            if frame and frame.SetAttribute then
                frame:SetAttribute(attribute, value)
            end
        end)
        return false, "queued"
    else
        if frame and frame.SetAttribute then
            local success = pcall(frame.SetAttribute, frame, attribute, value)
            return success
        end
    end
    return false
end

-- Secure Hook Utilities
ns.SecureHooks = ns.SecureHooks or {}
local hookedFunctions = {}

-- Safe secure hook wrapper
function ns.SecureHooks.SecureHook(target, method, handler)
    if not target or not method or not handler then
        return false
    end
    
    local hookKey = tostring(target) .. "." .. method
    if hookedFunctions[hookKey] then
        return false, "already hooked"
    end
    
    if type(target) == "string" then
        -- Global function hook
        if _G[target] then
            hooksecurefunc(target, handler)
            hookedFunctions[hookKey] = true
            return true
        end
    elseif type(target) == "table" and target[method] then
        -- Object method hook
        hooksecurefunc(target, method, handler)
        hookedFunctions[hookKey] = true
        return true
    end
    
    return false, "target not found"
end

-- Blizzard function hooks with error handling
function ns.SecureHooks.HookBlizzardFunction(funcName, handler)
    if not funcName or not handler then
        return false
    end
    
    if _G[funcName] then
        local success, err = pcall(hooksecurefunc, funcName, function(...)
            local ok, result = pcall(handler, ...)
            if not ok then
                ns:Debug("Error in hooked function " .. funcName .. ": " .. tostring(result))
            end
        end)
        
        if success then
            hookedFunctions[funcName] = true
            return true
        else
            ns:Debug("Failed to hook function " .. funcName .. ": " .. tostring(err))
        end
    end
    
    return false
end

-- Performance Optimization - Cached Function References
ns.CachedAPI = ns.CachedAPI or {}

-- Cache frequently used functions
local cachedFunctions = {
    -- Unit functions
    UnitHealth = UnitHealth,
    UnitHealthMax = UnitHealthMax,
    UnitPower = UnitPower,
    UnitPowerMax = UnitPowerMax,
    UnitPowerType = UnitPowerType,
    UnitClass = UnitClass,
    UnitLevel = UnitLevel,
    UnitName = UnitName,
    UnitExists = UnitExists,
    UnitIsDeadOrGhost = UnitIsDeadOrGhost,
    UnitIsConnected = UnitIsConnected,
    UnitReaction = UnitReaction,
    UnitPlayerControlled = UnitPlayerControlled,
    UnitCanAttack = UnitCanAttack,
    UnitIsFriend = UnitIsFriend,
    UnitIsUnit = UnitIsUnit,
    
    -- Combat functions
    InCombatLockdown = InCombatLockdown,
    UnitAffectingCombat = UnitAffectingCombat,
    
    -- Time functions
    GetTime = GetTime,
    
    -- Action functions (cached with nil checks)
    GetActionCooldown = GetActionCooldown,
    GetActionInfo = GetActionInfo,
    HasAction = HasAction,
    IsEquippedAction = IsEquippedAction,
    
    -- Spell functions
    GetSpellCooldown = GetSpellCooldown,
    GetSpellInfo = GetSpellInfo,
    
    -- Item functions
    GetItemInfo = GetItemInfo,
    GetItemQualityColor = GetItemQualityColor,
    
    -- System functions
    GetFramerate = GetFramerate,
    collectgarbage = collectgarbage,
}

-- Provide cached access
for funcName, func in pairs(cachedFunctions) do
    if func then
        ns.CachedAPI[funcName] = func
    end
end

-- Performance monitoring for cached calls
local callCounts = {}
local function trackAPICall(funcName)
    callCounts[funcName] = (callCounts[funcName] or 0) + 1
end

-- Wrapped cached functions with call tracking (only in debug mode)
if ns.config and ns.config.debug then
    for funcName, func in pairs(ns.CachedAPI) do
        ns.CachedAPI[funcName] = function(...)
            trackAPICall(funcName)
            return func(...)
        end
    end
    
    -- Debug function to print API usage stats
    function ns.CachedAPI.GetUsageStats()
        return callCounts
    end
end

-- Secure Frame Handling Utilities
ns.SecureFrames = ns.SecureFrames or {}

-- Create secure frame with protected attributes
function ns.SecureFrames.CreateSecureFrame(frameType, name, parent, template)
    if InCombatLockdown() then
        return nil, "combat lockdown"
    end
    
    local frame = CreateFrame(frameType, name, parent, template)
    if frame then
        -- Mark as DamiaUI frame
        frame._damiaUI = true
        frame._secureFrame = true
        
        -- Add protection methods
        frame.SafeSetAttribute = function(self, attr, value)
            return ns.CombatProtection.SafeSetAttribute(self, attr, value)
        end
        
        frame.SafeCall = function(self, method, ...)
            return ns.CombatProtection.SafeFrameCall(self, method, ...)
        end
    end
    
    return frame
end

-- Secure frame attribute batch setter
function ns.SecureFrames.SetSecureAttributes(frame, attributes)
    if not frame or not attributes or InCombatLockdown() then
        if InCombatLockdown() then
            table.insert(postCombatQueue, function()
                ns.SecureFrames.SetSecureAttributes(frame, attributes)
            end)
        end
        return false
    end
    
    for attr, value in pairs(attributes) do
        if frame.SetAttribute then
            pcall(frame.SetAttribute, frame, attr, value)
        end
    end
    
    return true
end

-- Frame cleanup utility
function ns.SecureFrames.CleanupSecureFrame(frame)
    if not frame then return end
    
    -- Queue cleanup if in combat
    if InCombatLockdown() then
        table.insert(postCombatQueue, function()
            ns.SecureFrames.CleanupSecureFrame(frame)
        end)
        return
    end
    
    -- Clear attributes
    if frame.SetAttribute then
        frame:SetAttribute("type", nil)
        frame:SetAttribute("action", nil)
        frame:SetAttribute("spell", nil)
        frame:SetAttribute("item", nil)
        frame:SetAttribute("macro", nil)
    end
    
    -- Hide and clear parent
    frame:Hide()
    frame:SetParent(nil)
    frame._damiaUI = nil
    frame._secureFrame = nil
end

-- Additional missing API functions based on validation report

-- Fix for GetInventorySlotInfo (might be deprecated)
if not GetInventorySlotInfo then
    GetInventorySlotInfo = function(slotName)
        local slotId = _G[slotName .. "SLOT"]
        if slotId then
            return slotId, nil, nil
        end
        return nil
    end
end

-- Fix for GetAverageItemLevel (moved to C_PaperDollInfo)
if not GetAverageItemLevel and C_PaperDollInfo then
    GetAverageItemLevel = function()
        return C_PaperDollInfo.GetItemLevel() or 0
    end
end

-- Fix for UnitGroupRolesAssigned (moved to C_LFGInfo or GetSpecialization)
if not UnitGroupRolesAssigned then
    UnitGroupRolesAssigned = function(unit)
        if unit == "player" then
            local spec = GetSpecialization()
            if spec then
                local role = GetSpecializationRole(spec)
                return role or "NONE"
            end
        end
        return "NONE"
    end
end

-- Fix for GetNumGroupMembers (ensure it exists)
if not GetNumGroupMembers then
    GetNumGroupMembers = function()
        return GetNumPartyMembers() or 0
    end
end

-- Fix for GetNumPartyMembers (might be deprecated)
if not GetNumPartyMembers then
    GetNumPartyMembers = function()
        return GetNumSubgroupMembers() or 0
    end
end

-- Fix for IsInGroup (ensure it exists)
if not IsInGroup then
    IsInGroup = function()
        return (GetNumGroupMembers() > 0) or (GetNumSubgroupMembers() > 0)
    end
end

-- Fix for IsInRaid (ensure it exists)  
if not IsInRaid then
    IsInRaid = function()
        return IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() > 5
    end
end

-- Additional secure utilities for addon modules
ns.SecureUtils = ns.SecureUtils or {}

-- Batch execute functions after combat
function ns.SecureUtils.ExecuteAfterCombat(funcTable)
    if not funcTable then return end
    
    for _, func in ipairs(funcTable) do
        if type(func) == "function" then
            table.insert(postCombatQueue, func)
        end
    end
end

-- Check if frame can be safely modified
function ns.SecureUtils.CanModifyFrame(frame)
    if not frame then return false end
    
    -- Check combat lockdown
    if InCombatLockdown() then return false end
    
    -- Check if frame is protected
    if frame:IsProtected() then return false end
    
    return true
end

-- Safe mass frame operation
function ns.SecureUtils.SafeMassFrameOperation(frames, operation, ...)
    if InCombatLockdown() then
        -- Capture varargs before closure (cannot use ... inside closures)
        local args = {...}
        table.insert(postCombatQueue, function()
            ns.SecureUtils.SafeMassFrameOperation(frames, operation, unpack(args))
        end)
        return false, "queued"
    end
    
    local args = {...}
    for _, frame in ipairs(frames) do
        if frame and frame[operation] then
            pcall(frame[operation], frame, unpack(args))
        end
    end
    
    return true
end

-- Error Capture System for DamiaUI
ns.ErrorCapture = ns.ErrorCapture or {}
print("[DEBUG] API.lua: ns.ErrorCapture initialized = " .. tostring(ns.ErrorCapture))
local errorLogs = {}
local maxErrors = 100 -- Limit stored errors to prevent memory issues

-- Enhanced error logging function
function ns.ErrorCapture.LogError(source, error, stack)
    local timestamp = date("%H:%M:%S")
    local errorEntry = {
        timestamp = timestamp,
        source = source or "Unknown",
        error = tostring(error or "Unknown error"),
        stack = stack or debugstack(2, 1, 0),
        count = 1
    }
    
    -- Check if this is a duplicate error
    for i = #errorLogs, math.max(1, #errorLogs - 10), -1 do
        local existingError = errorLogs[i]
        if existingError.source == errorEntry.source and existingError.error == errorEntry.error then
            existingError.count = existingError.count + 1
            existingError.timestamp = timestamp
            return -- Don't add duplicate
        end
    end
    
    -- Add new error
    table.insert(errorLogs, errorEntry)
    
    -- Trim old errors if we exceed the limit
    if #errorLogs > maxErrors then
        table.remove(errorLogs, 1)
    end
    
    -- Output to chat if debug mode is enabled
    if (ns.config and ns.config.debug) or ns.debugMode then
        print("|cffff0000DamiaUI Error:|r " .. errorEntry.source .. " - " .. errorEntry.error)
    end
end

-- Enhanced debug function that also logs errors
function ns:Debug(msg, isError)
    if (ns.config and ns.config.debug) or ns.debugMode then
        local prefix = isError and "|cffff0000DamiaUI Error:|r " or "|cff00ff00DamiaUI:|r "
        print(prefix .. tostring(msg))
    end
    
    if isError then
        ns.ErrorCapture.LogError("Debug", msg)
    end
end

-- Enhanced pcall wrapper that logs errors
function ns.ErrorCapture.SafeCall(func, source, ...)
    if not func or type(func) ~= "function" then
        ns.ErrorCapture.LogError(source or "SafeCall", "Invalid function provided")
        return false, "Invalid function"
    end
    
    local success, result = pcall(func, ...)
    if not success then
        ns.ErrorCapture.LogError(source or "SafeCall", result, debugstack(2, 1, 0))
        return false, result
    end
    
    return success, result
end
print("[DEBUG] API.lua: ns.ErrorCapture.SafeCall defined = " .. tostring(ns.ErrorCapture.SafeCall))

-- Get all captured errors
function ns.ErrorCapture.GetErrors()
    return errorLogs
end

-- Clear captured errors
function ns.ErrorCapture.ClearErrors()
    wipe(errorLogs)
    print("|cff00ff00DamiaUI:|r Error log cleared.")
end

-- Get error count
function ns.ErrorCapture.GetErrorCount()
    return #errorLogs
end

-- Get recent errors (last N)
function ns.ErrorCapture.GetRecentErrors(count)
    count = count or 10
    local recent = {}
    for i = math.max(1, #errorLogs - count + 1), #errorLogs do
        table.insert(recent, errorLogs[i])
    end
    return recent
end

-- Hook into Blizzard's error handler
local originalErrorHandler = geterrorhandler()
seterrorhandler(function(err)
    ns.ErrorCapture.LogError("Blizzard", err, debugstack(2, 1, 0))
    return originalErrorHandler(err)
end)

-- Print debug info
ns:Debug("Enhanced API Compatibility Layer loaded for WoW 11.2")
ns:Debug("Combat Protection: Enabled")
ns:Debug("Secure Hooks: Enabled") 
ns:Debug("Performance Caching: " .. (ns.CachedAPI and "Enabled" or "Disabled"))
ns:Debug("Secure Frame Utils: Enabled")
ns:Debug("Error Capture System: Enabled")