--[[
    DamiaUI Third-Party AddOn Skinning Module
    
    Enhanced addon skinning system with deep integration support.
    Works in conjunction with the Integration system for comprehensive
    addon positioning, styling, and management.
    
    Features:
    - Automatic detection and Aurora skinning of popular addons
    - Integration with DamiaUI positioning system
    - Enhanced conflict detection and resolution
    - Performance-optimized processing with viewport awareness
    
    Author: DamiaUI Development Team
    Version: 2.0.0
]]

local addonName, addon = ...
local DamiaUI = _G.DamiaUI

if not DamiaUI then
    return
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded

-- Initialize AddOns skinning module
local AddOnsSkinning = {}
DamiaUI.Skinning = DamiaUI.Skinning or {}
DamiaUI.Skinning.AddOns = AddOnsSkinning

-- Integration system reference
local Integration

-- Module state
local Aurora
local skinnedAddOnFrames = {}
local monitoredAddOns = {}
local skinningQueue = {}
local integrationEnabled = false

-- Damia UI color scheme
local DAMIA_COLORS = {
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Signature orange
    highlight = { r = 1.0, g = 0.6, b = 0.2, a = 0.3 },
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textDisabled = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 }
}

-- Known third-party addons and their skinning information
local ADDON_SKINNING_DATA = {
    -- Combat/DPS Addons
    ["Recount"] = {
        priority = 1,
        frames = { "RecountMainWindow", "RecountConfigWindow" },
        skinFunction = "SkinRecountFrames",
        loadDelay = 1,
        checkFunction = function() return Recount and Recount.MainWindow end
    },
    
    ["Details"] = {
        priority = 1,
        frames = function() 
            local frames = {}
            for i = 1, 5 do
                local frame = _G["DetailsBaseFrame" .. i]
                if frame then
                    table.insert(frames, frame)
                end
            end
            return frames
        end,
        skinFunction = "SkinDetailsFrames",
        loadDelay = 2,
        checkFunction = function() return _detalhes and _detalhes:GetCurrentInstance() end
    },
    
    ["Skada"] = {
        priority = 1,
        frames = function()
            local frames = {}
            if Skada then
                for _, window in ipairs(Skada:GetWindows()) do
                    if window.bargroup and window.bargroup.frame then
                        table.insert(frames, window.bargroup.frame)
                    end
                end
            end
            return frames
        end,
        skinFunction = "SkinSkadaFrames",
        loadDelay = 2,
        checkFunction = function() return Skada end
    },
    
    -- WeakAuras
    ["WeakAuras"] = {
        priority = 2,
        frames = function() 
            local frames = {}
            if WeakAuras and WeakAuras.GetOptionsFrame then
                local optionsFrame = WeakAuras.GetOptionsFrame()
                if optionsFrame then
                    table.insert(frames, optionsFrame)
                end
            end
            return frames
        end,
        skinFunction = "SkinWeakAurasFrames",
        loadDelay = 3,
        checkFunction = function() return WeakAuras end
    },
    
    -- Raid/Dungeon Tools
    ["BigWigs"] = {
        priority = 2,
        frames = { "BigWigsAnchor", "BigWigsEmphasizeAnchor" },
        skinFunction = "SkinBigWigsFrames", 
        loadDelay = 1,
        checkFunction = function() return BigWigs end
    },
    
    ["DBM-Core"] = {
        priority = 2,
        frames = function()
            local frames = {}
            if DBM and DBM.Bars then
                for _, bar in pairs(DBM.Bars:GetActiveBars()) do
                    if bar.frame then
                        table.insert(frames, bar.frame)
                    end
                end
            end
            return frames
        end,
        skinFunction = "SkinDBMFrames",
        loadDelay = 2,
        checkFunction = function() return DBM end
    },
    
    ["VuhDo"] = {
        priority = 2,
        frames = function()
            local frames = {}
            for i = 1, 10 do
                local panel = _G["VuhDoPanel" .. i]
                if panel then
                    table.insert(frames, panel)
                end
            end
            return frames
        end,
        skinFunction = "SkinVuhDoFrames",
        loadDelay = 2,
        checkFunction = function() return VuhDo end
    },
    
    -- Trading/Economic
    ["Auctionator"] = {
        priority = 3,
        frames = { "AuctionatorFrame", "AuctionatorConfigFrame" },
        skinFunction = "SkinAuctionatorFrames",
        loadDelay = 1,
        checkFunction = function() return Auctionator end
    },
    
    ["TradeSkillMaster"] = {
        priority = 3,
        frames = function()
            local frames = {}
            if TSM_API and TSM_API.GetMainFrame then
                local mainFrame = TSM_API.GetMainFrame()
                if mainFrame then
                    table.insert(frames, mainFrame)
                end
            end
            return frames
        end,
        skinFunction = "SkinTSMFrames",
        loadDelay = 2,
        checkFunction = function() return TSM_API end
    },
    
    ["AllTheThings"] = {
        priority = 3,
        frames = { "AllTheThingsMainFrame", "AllTheThingsSettingsFrame" },
        skinFunction = "SkinAllTheThingsFrames",
        loadDelay = 1,
        checkFunction = function() return AllTheThings end
    },
    
    -- UI Enhancement
    ["Bartender4"] = {
        priority = 4,
        frames = function()
            local frames = {}
            if Bartender4 then
                for i = 1, 10 do
                    local bar = _G["BT4Bar" .. i]
                    if bar then
                        table.insert(frames, bar)
                    end
                end
            end
            return frames
        end,
        skinFunction = "SkinBartender4Frames",
        loadDelay = 1,
        checkFunction = function() return Bartender4 end
    },
    
    ["Dominos"] = {
        priority = 4,
        frames = function()
            local frames = {}
            if Dominos then
                for i = 1, 14 do
                    local bar = _G["DominosActionBar" .. i]
                    if bar then
                        table.insert(frames, bar)
                    end
                end
            end
            return frames
        end,
        skinFunction = "SkinDominosFrames",
        loadDelay = 1,
        checkFunction = function() return Dominos end
    },
    
    ["TidyPlates"] = {
        priority = 4,
        frames = { "TidyPlatesConfigPanel" },
        skinFunction = "SkinTidyPlatesFrames",
        loadDelay = 1,
        checkFunction = function() return TidyPlates end
    },
    
    -- Chat/Social
    ["Prat"] = {
        priority = 4,
        frames = function()
            local frames = {}
            for i = 1, NUM_CHAT_WINDOWS do
                local frame = _G["ChatFrame" .. i]
                if frame and frame.PratHistory then
                    table.insert(frames, frame)
                end
            end
            return frames
        end,
        skinFunction = "SkinPratFrames",
        loadDelay = 1,
        checkFunction = function() return Prat end
    },
    
    ["WIM"] = {
        priority = 4,
        frames = function()
            local frames = {}
            if WIM_Windows then
                for _, window in pairs(WIM_Windows) do
                    if window.frame then
                        table.insert(frames, window.frame)
                    end
                end
            end
            return frames
        end,
        skinFunction = "SkinWIMFrames",
        loadDelay = 1,
        checkFunction = function() return WIM end
    }
}

-- Generic frame patterns to monitor for unknown addons
local GENERIC_FRAME_PATTERNS = {
    "%w+Frame$",
    "%w+MainFrame$",
    "%w+ConfigFrame$", 
    "%w+OptionsFrame$",
    "%w+Window$",
    "%w+Panel$",
    "%w+Dialog$"
}

--[[
    Initialization and Setup
]]

function AddOnsSkinning:Initialize()
    if not self:ValidateAurora() then
        DamiaUI:LogError("AddOns Skinning: Aurora not available")
        return false
    end
    
    -- Initialize integration with positioning system
    self:InitializeIntegration()
    
    -- Setup addon monitoring
    self:SetupAddOnMonitoring()
    
    -- Start scanning for loaded addons
    self:StartAddOnScanning()
    
    DamiaUI:LogDebug("AddOns skinning system initialized")
    return true
end

function AddOnsSkinning:ValidateAurora()
    Aurora = DamiaUI.Libraries.Aurora or _G.Aurora
    return Aurora ~= nil
end

function AddOnsSkinning:InitializeIntegration()
    -- Check if Integration system is available
    Integration = DamiaUI.Integration
    
    if Integration then
        integrationEnabled = true
        DamiaUI:LogDebug("AddOns Skinning: Integration system connected")
        
        -- Register skinning callbacks with Integration system
        if Integration.RegisterSkinningCallback then
            Integration:RegisterSkinningCallback(function(addonName, profile)
                return self:SkinAddonWithProfile(addonName, profile)
            end)
        end
    else
        DamiaUI:LogDebug("AddOns Skinning: Running in standalone mode (Integration not available)")
        integrationEnabled = false
    end
end

function AddOnsSkinning:SetupAddOnMonitoring()
    -- Create monitoring frame
    local monitorFrame = CreateFrame("Frame", "DamiaUIAddOnSkinMonitor")
    
    -- Monitor addon loading
    monitorFrame:RegisterEvent("ADDON_LOADED")
    monitorFrame:RegisterEvent("PLAYER_LOGIN")
    monitorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddonName = ...
            AddOnsSkinning:OnAddonLoaded(loadedAddonName)
        elseif event == "PLAYER_LOGIN" then
            -- Final scan after login
            C_Timer.After(3, function()
                AddOnsSkinning:ScanAllLoadedAddOns()
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Secondary scan after entering world
            C_Timer.After(5, function()
                AddOnsSkinning:ScanGenericFrames()
            end)
        end
    end)
end

function AddOnsSkinning:StartAddOnScanning()
    -- Scan currently loaded addons
    for addonName, skinData in pairs(ADDON_SKINNING_DATA) do
        if IsAddOnLoaded(addonName) then
            self:QueueAddonForSkinning(addonName, skinData)
        end
    end
    
    -- Process queue
    C_Timer.NewTicker(1, function()
        self:ProcessSkinningQueue()
    end)
end

--[[
    Core Skinning System
]]

function AddOnsSkinning:OnAddonLoaded(addonName)
    local skinData = ADDON_SKINNING_DATA[addonName]
    if skinData then
        self:QueueAddonForSkinning(addonName, skinData)
        DamiaUI:LogDebug("Queued addon for skinning: " .. addonName)
    end
end

function AddOnsSkinning:QueueAddonForSkinning(addonName, skinData)
    if monitoredAddOns[addonName] then
        return -- Already queued
    end
    
    table.insert(skinningQueue, {
        addonName = addonName,
        skinData = skinData,
        queueTime = GetTime(),
        processed = false
    })
    
    monitoredAddOns[addonName] = true
end

function AddOnsSkinning:ProcessSkinningQueue()
    local currentTime = GetTime()
    
    for i = #skinningQueue, 1, -1 do
        local item = skinningQueue[i]
        
        -- Check if enough time has passed and addon is ready
        if not item.processed and currentTime - item.queueTime >= item.skinData.loadDelay then
            if self:IsAddonReadyForSkinning(item.addonName, item.skinData) then
                self:SkinAddon(item.addonName, item.skinData)
                item.processed = true
                table.remove(skinningQueue, i)
            elseif currentTime - item.queueTime > 30 then
                -- Remove from queue after 30 seconds to avoid infinite waiting
                DamiaUI:LogWarning("Addon skinning timeout: " .. item.addonName)
                table.remove(skinningQueue, i)
            end
        end
    end
end

function AddOnsSkinning:IsAddonReadyForSkinning(addonName, skinData)
    -- Check if addon is loaded
    if not IsAddOnLoaded(addonName) then
        return false
    end
    
    -- Use addon-specific check function if available
    if skinData.checkFunction then
        return skinData.checkFunction()
    end
    
    return true
end

function AddOnsSkinning:SkinAddon(addonName, skinData)
    if skinnedAddOnFrames[addonName] then
        return false -- Already skinned
    end
    
    -- Get frames to skin
    local frames = self:GetAddonFrames(skinData.frames)
    if not frames or #frames == 0 then
        return false
    end
    
    -- Apply skinning
    local success = false
    if skinData.skinFunction and self[skinData.skinFunction] then
        success = self[skinData.skinFunction](self, frames, addonName)
    else
        success = self:ApplyGenericSkinning(frames, addonName)
    end
    
    if success then
        skinnedAddOnFrames[addonName] = true
        DamiaUI:LogDebug("Successfully skinned addon: " .. addonName)
        
        -- Notify Integration system if enabled
        if integrationEnabled and Integration and Integration.OnAddonSkinned then
            Integration:OnAddonSkinned(addonName, frames)
        end
    else
        DamiaUI:LogWarning("Failed to skin addon: " .. addonName)
    end
    
    return success
end

function AddOnsSkinning:SkinAddonWithProfile(addonName, profile)
    -- Enhanced skinning function that works with Integration profiles
    if skinnedAddOnFrames[addonName] then
        return true -- Already skinned
    end
    
    local skinData = profile.skinningData or ADDON_SKINNING_DATA[addonName]
    if not skinData then
        DamiaUI:LogWarning("AddOns Skinning: No skinning data for " .. addonName)
        return false
    end
    
    -- Use the existing SkinAddon logic but with profile awareness
    local success = self:SkinAddon(addonName, skinData)
    
    if success and profile.configuration then
        -- Apply additional configuration from the profile
        self:ApplyProfileConfiguration(addonName, profile.configuration)
    end
    
    return success
end

function AddOnsSkinning:ApplyProfileConfiguration(addonName, configuration)
    -- Apply additional styling configuration from Integration profiles
    if not configuration then
        return
    end
    
    DamiaUI:LogDebug("AddOns Skinning: Applying profile configuration for " .. addonName)
    
    -- Handle background alpha configuration
    if configuration.backgroundAlpha then
        self:SetAddonBackgroundAlpha(addonName, configuration.backgroundAlpha)
    end
    
    -- Handle auto-hide configuration
    if configuration.autoHide then
        self:SetupAddonAutoHide(addonName, configuration.autoHide)
    end
    
    -- Handle combat-only visibility
    if configuration.combatOnly then
        self:SetupAddonCombatVisibility(addonName, configuration.combatOnly)
    end
end

function AddOnsSkinning:GetAddonFrames(frameSpec)
    local frames = {}
    
    if type(frameSpec) == "table" then
        -- Static frame list
        for _, frameName in ipairs(frameSpec) do
            local frame = _G[frameName]
            if frame then
                table.insert(frames, frame)
            end
        end
    elseif type(frameSpec) == "function" then
        -- Dynamic frame getter
        local dynamicFrames = frameSpec()
        if dynamicFrames then
            for _, frame in ipairs(dynamicFrames) do
                table.insert(frames, frame)
            end
        end
    elseif type(frameSpec) == "string" then
        -- Single frame
        local frame = _G[frameSpec]
        if frame then
            table.insert(frames, frame)
        end
    end
    
    return frames
end

--[[
    Generic Skinning Functions
]]

function AddOnsSkinning:ApplyGenericSkinning(frames, addonName)
    local success = true
    
    for _, frame in ipairs(frames) do
        if not self:ApplyGenericFrameSkin(frame) then
            success = false
        end
    end
    
    return success
end

function AddOnsSkinning:ApplyGenericFrameSkin(frame)
    if not frame or not Aurora then
        return false
    end
    
    local success = pcall(function()
        -- Apply Aurora background
        if Aurora.CreateBD then
            Aurora.CreateBD(frame, 0.25)
        end
        
        -- Create Damia border
        self:CreateDamiaBorder(frame)
        
        -- Skin common elements
        self:SkinFrameElements(frame)
        
        -- Apply Damia accent colors
        self:ApplyDamiaAccents(frame)
    end)
    
    return success
end

function AddOnsSkinning:SkinFrameElements(frame)
    if not frame then
        return
    end
    
    -- Skin buttons
    self:SkinChildButtons(frame)
    
    -- Skin tabs
    self:SkinChildTabs(frame)
    
    -- Skin scrollbars
    self:SkinChildScrollbars(frame)
    
    -- Skin editboxes
    self:SkinChildEditBoxes(frame)
    
    -- Skin status bars
    self:SkinChildStatusBars(frame)
    
    -- Skin dropdown menus
    self:SkinChildDropdowns(frame)
end

function AddOnsSkinning:SkinChildButtons(frame)
    local function SkinButton(button)
        if not button or button:GetObjectType() ~= "Button" then
            return
        end
        
        if Aurora.ReskinButton then
            Aurora.ReskinButton(button)
        end
        
        -- Apply Damia highlight
        if button.SetHighlightTexture then
            button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local highlight = button:GetHighlightTexture()
            if highlight then
                highlight:SetVertexColor(DAMIA_COLORS.highlight.r, DAMIA_COLORS.highlight.g, DAMIA_COLORS.highlight.b, DAMIA_COLORS.highlight.a)
            end
        end
    end
    
    self:ProcessChildFrames(frame, function(child)
        if child:GetObjectType() == "Button" then
            SkinButton(child)
        end
    end)
end

function AddOnsSkinning:SkinChildTabs(frame)
    local function SkinTab(tab)
        if not tab then
            return
        end
        
        if Aurora.ReskinTab then
            Aurora.ReskinTab(tab)
        end
        
        -- Apply Damia accent to selected state
        if tab.SetSelectedTexture then
            tab:SetSelectedTexture("Interface\\Buttons\\WHITE8X8")
            local selected = tab:GetSelectedTexture()
            if selected then
                selected:SetVertexColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b, 0.3)
            end
        end
    end
    
    self:ProcessChildFrames(frame, function(child)
        local name = child:GetName() or ""
        if name:match("Tab%d*$") or child:GetObjectType() == "TabButton" then
            SkinTab(child)
        end
    end)
end

function AddOnsSkinning:SkinChildScrollbars(frame)
    local function SkinScrollbar(scrollbar)
        if not scrollbar then
            return
        end
        
        if Aurora.ReskinScroll then
            Aurora.ReskinScroll(scrollbar)
        end
        
        -- Apply Damia colors to scroll elements
        if scrollbar.thumbTexture then
            scrollbar.thumbTexture:SetVertexColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b, 0.8)
        end
    end
    
    self:ProcessChildFrames(frame, function(child)
        local name = child:GetName() or ""
        if name:match("ScrollBar$") or name:match("Slider$") then
            SkinScrollbar(child)
        end
    end)
end

function AddOnsSkinning:SkinChildEditBoxes(frame)
    local function SkinEditBox(editbox)
        if not editbox or editbox:GetObjectType() ~= "EditBox" then
            return
        end
        
        if Aurora.ReskinEditBox then
            Aurora.ReskinEditBox(editbox)
        end
        
        -- Focus highlighting
        if editbox:HasScript("OnEditFocusGained") then
            editbox:HookScript("OnEditFocusGained", function(self)
                if self.bg then
                    self.bg:SetBackdropBorderColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b, 1)
                end
            end)
        end
        
        if editbox:HasScript("OnEditFocusLost") then
            editbox:HookScript("OnEditFocusLost", function(self)
                if self.bg then
                    self.bg:SetBackdropBorderColor(DAMIA_COLORS.border.r, DAMIA_COLORS.border.g, DAMIA_COLORS.border.b, 1)
                end
            end)
        end
    end
    
    self:ProcessChildFrames(frame, function(child)
        if child:GetObjectType() == "EditBox" then
            SkinEditBox(child)
        end
    end)
end

function AddOnsSkinning:SkinChildStatusBars(frame)
    local function SkinStatusBar(statusbar)
        if not statusbar or statusbar:GetObjectType() ~= "StatusBar" then
            return
        end
        
        -- Background
        if not statusbar.bg then
            statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
            statusbar.bg:SetAllPoints()
            statusbar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            statusbar.bg:SetVertexColor(DAMIA_COLORS.background.r, DAMIA_COLORS.background.g, DAMIA_COLORS.background.b, 0.8)
        end
        
        -- Border
        self:CreateDamiaBorder(statusbar)
    end
    
    self:ProcessChildFrames(frame, function(child)
        if child:GetObjectType() == "StatusBar" then
            SkinStatusBar(child)
        end
    end)
end

function AddOnsSkinning:SkinChildDropdowns(frame)
    local function SkinDropdown(dropdown)
        if not dropdown then
            return
        end
        
        if Aurora.ReskinDropDown then
            Aurora.ReskinDropDown(dropdown)
        end
    end
    
    self:ProcessChildFrames(frame, function(child)
        local name = child:GetName() or ""
        if name:match("DropDown$") or name:match("Menu$") then
            SkinDropdown(child)
        end
    end)
end

--[[
    Specific AddOn Skinning Functions
]]

function AddOnsSkinning:SkinRecountFrames(frames, addonName)
    local success = true
    
    for _, frame in ipairs(frames) do
        if not self:ApplyGenericFrameSkin(frame) then
            success = false
        end
        
        -- Recount specific styling
        if frame == Recount.MainWindow then
            -- Style the title bar
            if frame.TitleText then
                frame.TitleText:SetTextColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b)
            end
            
            -- Style scrolling combat text
            if frame.Rows then
                for i, row in ipairs(frame.Rows) do
                    if row.LeftText then
                        row.LeftText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                    end
                end
            end
        end
    end
    
    return success
end

function AddOnsSkinning:SkinDetailsFrames(frames, addonName)
    local success = true
    
    for _, frame in ipairs(frames) do
        if not self:ApplyGenericFrameSkin(frame) then
            success = false
        end
        
        -- Details specific styling
        if frame.baseFrame then
            -- Apply Damia colors to bars
            if frame.barGroup and frame.barGroup.bars then
                for _, bar in ipairs(frame.barGroup.bars) do
                    if bar.texture then
                        bar.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                    end
                end
            end
        end
    end
    
    return success
end

function AddOnsSkinning:SkinWeakAurasFrames(frames, addonName)
    local success = true
    
    for _, frame in ipairs(frames) do
        if not self:ApplyGenericFrameSkin(frame) then
            success = false
        end
        
        -- WeakAuras options frame specific styling
        if frame.frame and frame.frame.container then
            self:SkinFrameElements(frame.frame.container)
        end
    end
    
    return success
end

function AddOnsSkinning:SkinBigWigsFrames(frames, addonName)
    return self:ApplyGenericSkinning(frames, addonName)
end

function AddOnsSkinning:SkinDBMFrames(frames, addonName)
    local success = true
    
    for _, frame in ipairs(frames) do
        if not self:ApplyGenericFrameSkin(frame) then
            success = false
        end
        
        -- DBM bar styling
        if frame.bar then
            frame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            if frame.bar.bg then
                frame.bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                frame.bar.bg:SetVertexColor(DAMIA_COLORS.background.r, DAMIA_COLORS.background.g, DAMIA_COLORS.background.b, 0.3)
            end
        end
    end
    
    return success
end

--[[
    Generic Frame Scanning
]]

function AddOnsSkinning:ScanGenericFrames()
    -- Scan for frames matching generic patterns
    for frameName, frame in pairs(_G) do
        if type(frame) == "table" and frame.GetObjectType and pcall(frame.GetObjectType, frame) then
            if self:ShouldSkinGenericFrame(frameName, frame) then
                self:ApplyGenericFrameSkin(frame)
            end
        end
    end
end

function AddOnsSkinning:ScanAllLoadedAddOns()
    -- Final scan for any missed addons
    for addonName, skinData in pairs(ADDON_SKINNING_DATA) do
        if IsAddOnLoaded(addonName) and not skinnedAddOnFrames[addonName] then
            if self:IsAddonReadyForSkinning(addonName, skinData) then
                self:SkinAddon(addonName, skinData)
            end
        end
    end
end

function AddOnsSkinning:ShouldSkinGenericFrame(frameName, frame)
    -- Skip if already skinned or shouldn't be skinned
    if not frameName or skinnedAddOnFrames[frameName] then
        return false
    end
    
    -- Skip DamiaUI frames
    if frameName:match("^DamiaUI") then
        return false
    end
    
    -- Skip Blizzard frames (handled by Blizzard module)
    if frameName:match("^Blizzard_") or frameName:match("^Interface") then
        return false
    end
    
    -- Check if frame matches patterns
    for _, pattern in ipairs(GENERIC_FRAME_PATTERNS) do
        if frameName:match(pattern) then
            -- Additional checks
            if frame:GetObjectType() == "Frame" and frame:IsVisible() then
                return true
            end
        end
    end
    
    return false
end

--[[
    Utility Functions
]]

function AddOnsSkinning:CreateDamiaBorder(frame)
    if not frame or frame.damiaBorder then
        return
    end
    
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    
    border:SetBackdropBorderColor(DAMIA_COLORS.border.r, DAMIA_COLORS.border.g, DAMIA_COLORS.border.b, DAMIA_COLORS.border.a)
    
    frame.damiaBorder = border
    return border
end

function AddOnsSkinning:ApplyDamiaAccents(frame)
    if not frame then
        return
    end
    
    -- Apply accent colors to specific elements
    local function ApplyAccentColor(element)
        if element and element.SetTextColor then
            element:SetTextColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b)
        end
    end
    
    -- Common title elements
    ApplyAccentColor(frame.title)
    ApplyAccentColor(frame.Title)
    ApplyAccentColor(frame.TitleText)
    ApplyAccentColor(frame.titleText)
end

function AddOnsSkinning:ProcessChildFrames(frame, callback)
    if not frame or not callback then
        return
    end
    
    local function ProcessFrame(f)
        callback(f)
        
        local children = { f:GetChildren() }
        for _, child in ipairs(children) do
            ProcessFrame(child)
        end
    end
    
    ProcessFrame(frame)
end

--[[
    Public API
]]

function AddOnsSkinning:RefreshAllSkins()
    table.wipe(skinnedAddOnFrames)
    table.wipe(monitoredAddOns)
    table.wipe(skinningQueue)
    
    C_Timer.After(0.1, function()
        self:StartAddOnScanning()
    end)
end

function AddOnsSkinning:IsAddonSkinned(addonName)
    return skinnedAddOnFrames[addonName] == true
end

function AddOnsSkinning:GetSkinnedAddonCount()
    local count = 0
    for _ in pairs(skinnedAddOnFrames) do
        count = count + 1
    end
    return count
end

function AddOnsSkinning:GetSupportedAddOns()
    local addons = {}
    for addonName in pairs(ADDON_SKINNING_DATA) do
        table.insert(addons, addonName)
    end
    return addons
end

function AddOnsSkinning:AddCustomAddon(addonName, skinData)
    ADDON_SKINNING_DATA[addonName] = skinData
    
    if IsAddOnLoaded(addonName) then
        self:QueueAddonForSkinning(addonName, skinData)
    end
end

--[[
    Integration Support Functions
]]

function AddOnsSkinning:SetAddonBackgroundAlpha(addonName, alpha)
    -- Find and modify background alpha for addon frames
    local skinData = ADDON_SKINNING_DATA[addonName]
    if not skinData then
        return
    end
    
    local frames = self:GetAddonFrames(skinData.frames)
    for _, frame in ipairs(frames) do
        if frame and frame.bg then
            frame.bg:SetAlpha(alpha)
        elseif frame and frame.SetBackdropColor then
            local r, g, b = frame:GetBackdropColor()
            frame:SetBackdropColor(r, g, b, alpha)
        end
    end
end

function AddOnsSkinning:SetupAddonAutoHide(addonName, autoHideConfig)
    -- Setup automatic hiding behavior for addons
    if not autoHideConfig then
        return
    end
    
    local skinData = ADDON_SKINNING_DATA[addonName]
    if not skinData then
        return
    end
    
    local frames = self:GetAddonFrames(skinData.frames)
    for _, frame in ipairs(frames) do
        if frame then
            -- Store original alpha for restoration
            if not frame.originalAlpha then
                frame.originalAlpha = frame:GetAlpha()
            end
            
            -- Setup mouse enter/leave behavior
            frame:EnableMouse(true)
            frame:SetScript("OnEnter", function(self)
                if autoHideConfig.fadeOnHover then
                    self:SetAlpha(self.originalAlpha or 1.0)
                end
            end)
            
            frame:SetScript("OnLeave", function(self)
                if autoHideConfig.fadeOnHover then
                    self:SetAlpha(autoHideConfig.hiddenAlpha or 0.3)
                end
            end)
            
            -- Set initial hidden state if configured
            if autoHideConfig.startHidden then
                frame:SetAlpha(autoHideConfig.hiddenAlpha or 0.3)
            end
        end
    end
end

function AddOnsSkinning:SetupAddonCombatVisibility(addonName, combatConfig)
    -- Setup combat-based visibility behavior
    if not combatConfig then
        return
    end
    
    local skinData = ADDON_SKINNING_DATA[addonName]
    if not skinData then
        return
    end
    
    -- Create combat monitoring frame if not exists
    if not self.combatMonitorFrame then
        self.combatMonitorFrame = CreateFrame("Frame", "DamiaUIAddonsCombatMonitor")
        self.combatMonitorFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.combatMonitorFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.combatMonitorFrame.addons = {}
        
        self.combatMonitorFrame:SetScript("OnEvent", function(self, event)
            local inCombat = event == "PLAYER_REGEN_DISABLED"
            
            for trackedAddonName, config in pairs(self.addons) do
                local addonSkinData = ADDON_SKINNING_DATA[trackedAddonName]
                if addonSkinData then
                    local frames = AddOnsSkinning:GetAddonFrames(addonSkinData.frames)
                    for _, frame in ipairs(frames) do
                        if frame then
                            if inCombat then
                                if config.showInCombat then
                                    frame:Show()
                                    if config.combatAlpha then
                                        frame:SetAlpha(config.combatAlpha)
                                    end
                                end
                            else
                                if config.hideOutOfCombat then
                                    frame:Hide()
                                else
                                    if config.nonCombatAlpha then
                                        frame:SetAlpha(config.nonCombatAlpha)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    
    -- Register this addon for combat monitoring
    self.combatMonitorFrame.addons[addonName] = combatConfig
end

function AddOnsSkinning:GetIntegrationStatus()
    return {
        integrationEnabled = integrationEnabled,
        hasIntegrationSystem = Integration ~= nil,
        skinnedAddons = self:GetSkinnedAddonCount(),
        supportedAddons = #self:GetSupportedAddOns()
    }
end

-- Initialize when called
if DamiaUI.Skinning then
    DamiaUI.Skinning.AddOns = AddOnsSkinning
end