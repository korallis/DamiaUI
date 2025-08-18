--[[
    DamiaUI Blizzard Frame Skinning Module
    
    Handles comprehensive skinning of all Blizzard UI frames with Aurora integration.
    Implements delayed application and taint prevention strategies.
    
    Author: DamiaUI Development Team
    Version: 1.0.0
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

-- Initialize Blizzard skinning module
local BlizzardSkinning = {}
DamiaUI.Skinning = DamiaUI.Skinning or {}
DamiaUI.Skinning.Blizzard = BlizzardSkinning

-- Module state
local Aurora
local skinnedBlizzardFrames = {}
local queuedFrames = {}
local skinningComplete = false

-- Damia UI color scheme
local DAMIA_COLORS = {
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Signature orange
    highlight = { r = 1.0, g = 0.6, b = 0.2, a = 0.3 },
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textDisabled = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 }
}

-- Blizzard frames to skin (categorized by priority)
local BLIZZARD_FRAMES = {
    -- Priority 1: Core UI frames
    core = {
        "CharacterFrame",
        "SpellBookFrame", 
        "PlayerTalentFrame",
        "FriendsFrame",
        "MailFrame",
        "MerchantFrame",
        "TradeFrame",
        "BankFrame",
        "GuildBankFrame",
        "AuctionHouseFrame",
        "GameMenuFrame"
    },
    
    -- Priority 2: Secondary frames  
    secondary = {
        "CollectionsJournal",
        "EncounterJournal",
        "AchievementFrame",
        "PVPUIFrame",
        "LookingForGuildFrame", 
        "CraftFrame",
        "TradeSkillFrame",
        "QuestMapFrame",
        "WorldMapFrame"
    },
    
    -- Priority 3: Specialized frames
    specialized = {
        "GossipFrame",
        "QuestFrame", 
        "TabardFrame",
        "PetitionFrame",
        "ReputationFrame",
        "RaidInfoFrame",
        "HelpFrame",
        "VideoOptionsFrame",
        "InterfaceOptionsFrame"
    },
    
    -- Priority 4: Combat-sensitive frames (skin after combat only)
    combat = {
        "LootFrame",
        "StackSplitFrame", 
        "StaticPopup1",
        "StaticPopup2",
        "StaticPopup3",
        "StaticPopup4"
    }
}

-- Frames that need special handling
local SPECIAL_HANDLING_FRAMES = {
    -- Frames that require custom skinning functions
    ["CharacterFrame"] = "SkinCharacterFrame",
    ["SpellBookFrame"] = "SkinSpellBookFrame",
    ["PlayerTalentFrame"] = "SkinTalentFrame",
    ["WorldMapFrame"] = "SkinWorldMapFrame",
    ["QuestMapFrame"] = "SkinQuestMapFrame",
    ["CollectionsJournal"] = "SkinCollectionsFrame",
    ["EncounterJournal"] = "SkinEncounterJournal"
}

-- Frame creation monitoring
local MONITORED_FRAME_PATTERNS = {
    "^Blizzard",
    "^Interface",
    "^UI",
    "Frame$",
    "Panel$",
    "Dialog$"
}

--[[
    Initialization and Setup
]]

function BlizzardSkinning:Initialize()
    if not self:ValidateAurora() then
        DamiaUI:LogError("Blizzard Skinning: Aurora not available")
        return false
    end
    
    -- Configure Aurora with Damia colors
    self:ConfigureAurora()
    
    -- Setup frame monitoring
    self:SetupFrameMonitoring()
    
    -- Start delayed skinning process
    self:StartDelayedSkinning()
    
    DamiaUI:LogDebug("Blizzard skinning system initialized")
    return true
end

function BlizzardSkinning:ValidateAurora()
    Aurora = DamiaUI.Libraries.Aurora or _G.Aurora
    if not Aurora then
        return false
    end
    
    -- Verify Aurora has required methods
    local requiredMethods = {
        "CreateBD", "CreateBG", "CreateGradient", "ReskinButton", "ReskinTab"
    }
    
    for _, method in ipairs(requiredMethods) do
        if not Aurora[method] then
            DamiaUI:LogWarning("Aurora missing method: " .. method)
        end
    end
    
    return true
end

function BlizzardSkinning:ConfigureAurora()
    if not Aurora.db then
        return
    end
    
    -- Apply Damia color scheme to Aurora
    if Aurora.db.profile then
        Aurora.db.profile.customColors = DAMIA_COLORS
        Aurora.db.profile.useCustomColors = true
    end
    
    -- Override Aurora color functions to use Damia colors
    if Aurora.Color then
        Aurora.Color.background = DAMIA_COLORS.background
        Aurora.Color.border = DAMIA_COLORS.border
        Aurora.Color.accent = DAMIA_COLORS.accent
        Aurora.Color.highlight = DAMIA_COLORS.highlight
    end
end

--[[
    Core Skinning System
]]

function BlizzardSkinning:StartDelayedSkinning()
    -- Skin in phases to avoid taint and performance issues
    
    -- Phase 1: Core frames after short delay
    C_Timer.After(0.5, function()
        self:SkinFrameCategory("core")
    end)
    
    -- Phase 2: Secondary frames
    C_Timer.After(1.5, function()
        self:SkinFrameCategory("secondary")
    end)
    
    -- Phase 3: Specialized frames
    C_Timer.After(3.0, function()
        self:SkinFrameCategory("specialized")
    end)
    
    -- Phase 4: Combat frames (only when out of combat)
    C_Timer.After(5.0, function()
        if not InCombatLockdown() then
            self:SkinFrameCategory("combat")
        else
            self:QueueCombatFrames()
        end
    end)
end

function BlizzardSkinning:SkinFrameCategory(category)
    local frames = BLIZZARD_FRAMES[category]
    if not frames then
        return
    end
    
    local skinnedCount = 0
    
    for _, frameName in ipairs(frames) do
        if self:SkinBlizzardFrame(frameName) then
            skinnedCount = skinnedCount + 1
        end
    end
    
    if skinnedCount > 0 then
        DamiaUI:LogDebug(string.format("Skinned %d %s frames", skinnedCount, category))
    end
end

function BlizzardSkinning:SkinBlizzardFrame(frameName)
    local frame = _G[frameName]
    if not frame or skinnedBlizzardFrames[frameName] then
        return false
    end
    
    -- Check if frame needs special handling
    local specialHandler = SPECIAL_HANDLING_FRAMES[frameName]
    if specialHandler and self[specialHandler] then
        return self[specialHandler](self, frame)
    end
    
    -- Apply standard Aurora skinning
    return self:ApplyStandardSkin(frame, frameName)
end

function BlizzardSkinning:ApplyStandardSkin(frame, frameName)
    if not frame or not Aurora then
        return false
    end
    
    local success = pcall(function()
        -- Apply Aurora background
        if Aurora.CreateBD then
            Aurora.CreateBD(frame, 0.25)
        end
        
        -- Apply custom border with Damia colors
        self:CreateDamiaBorder(frame)
        
        -- Skin common elements
        self:SkinFrameElements(frame)
        
        -- Mark as skinned
        skinnedBlizzardFrames[frameName] = true
        
        -- Apply fade-in animation
        self:AnimateFrameEntry(frame)
    end)
    
    if success then
        DamiaUI:LogDebug("Successfully skinned: " .. frameName)
        return true
    else
        DamiaUI:LogError("Failed to skin: " .. frameName)
        return false
    end
end

function BlizzardSkinning:SkinFrameElements(frame)
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
end

function BlizzardSkinning:SkinChildButtons(frame)
    local function SkinButton(button)
        if not button or button:GetObjectType() ~= "Button" then
            return
        end
        
        if Aurora.ReskinButton then
            Aurora.ReskinButton(button)
        end
        
        -- Apply Damia accent color to button highlights
        if button.SetHighlightTexture then
            button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local highlight = button:GetHighlightTexture()
            if highlight then
                highlight:SetVertexColor(DAMIA_COLORS.highlight.r, DAMIA_COLORS.highlight.g, DAMIA_COLORS.highlight.b, DAMIA_COLORS.highlight.a)
            end
        end
    end
    
    -- Recursively find and skin buttons
    self:ProcessChildFrames(frame, function(child)
        if child:GetObjectType() == "Button" then
            SkinButton(child)
        end
    end)
end

function BlizzardSkinning:SkinChildTabs(frame)
    local function SkinTab(tab)
        if not tab then
            return
        end
        
        if Aurora.ReskinTab then
            Aurora.ReskinTab(tab)
        end
        
        -- Apply Damia colors to tab selection
        if tab.SetSelectedTexture then
            tab:SetSelectedTexture("Interface\\Buttons\\WHITE8X8")
            local selected = tab:GetSelectedTexture()
            if selected then
                selected:SetVertexColor(DAMIA_COLORS.accent.r, DAMIA_COLORS.accent.g, DAMIA_COLORS.accent.b, 0.3)
            end
        end
    end
    
    -- Look for tab patterns
    self:ProcessChildFrames(frame, function(child)
        local name = child:GetName() or ""
        if name:match("Tab%d*$") or child:GetObjectType() == "TabButton" then
            SkinTab(child)
        end
    end)
end

function BlizzardSkinning:SkinChildScrollbars(frame)
    local function SkinScrollbar(scrollbar)
        if not scrollbar or not scrollbar.ScrollUpButton then
            return
        end
        
        if Aurora.ReskinScroll then
            Aurora.ReskinScroll(scrollbar)
        end
        
        -- Apply Damia colors to scroll thumb
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

function BlizzardSkinning:SkinChildEditBoxes(frame)
    local function SkinEditBox(editbox)
        if not editbox or editbox:GetObjectType() ~= "EditBox" then
            return
        end
        
        if Aurora.ReskinEditBox then
            Aurora.ReskinEditBox(editbox)
        end
        
        -- Apply focus highlight
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

function BlizzardSkinning:SkinChildStatusBars(frame)
    local function SkinStatusBar(statusbar)
        if not statusbar or statusbar:GetObjectType() ~= "StatusBar" then
            return
        end
        
        -- Create background
        if not statusbar.bg then
            statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
            statusbar.bg:SetAllPoints()
            statusbar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            statusbar.bg:SetVertexColor(DAMIA_COLORS.background.r, DAMIA_COLORS.background.g, DAMIA_COLORS.background.b, 0.8)
        end
        
        -- Create border
        self:CreateDamiaBorder(statusbar)
    end
    
    self:ProcessChildFrames(frame, function(child)
        if child:GetObjectType() == "StatusBar" then
            SkinStatusBar(child)
        end
    end)
end

--[[
    Special Frame Handlers
]]

function BlizzardSkinning:SkinCharacterFrame(frame)
    if not frame or skinnedBlizzardFrames["CharacterFrame"] then
        return false
    end
    
    local success = pcall(function()
        -- Main frame
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Character model frame
        if CharacterModelFrame then
            Aurora.CreateBD(CharacterModelFrame, 0.1)
            self:CreateDamiaBorder(CharacterModelFrame)
        end
        
        -- Paperdoll frame
        if PaperDollFrame then
            self:SkinFrameElements(PaperDollFrame)
        end
        
        -- Reputation frame
        if ReputationFrame then
            self:SkinFrameElements(ReputationFrame)
        end
        
        skinnedBlizzardFrames["CharacterFrame"] = true
    end)
    
    return success
end

function BlizzardSkinning:SkinSpellBookFrame(frame)
    if not frame or skinnedBlizzardFrames["SpellBookFrame"] then
        return false
    end
    
    local success = pcall(function()
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Spellbook tabs
        for i = 1, 8 do
            local tab = _G["SpellBookSkillLineTab" .. i]
            if tab then
                Aurora.ReskinTab(tab)
            end
        end
        
        -- Spell buttons
        for i = 1, 12 do
            local button = _G["SpellButton" .. i]
            if button then
                Aurora.ReskinButton(button)
            end
        end
        
        skinnedBlizzardFrames["SpellBookFrame"] = true
    end)
    
    return success
end

function BlizzardSkinning:SkinTalentFrame(frame)
    if not frame or skinnedBlizzardFrames["PlayerTalentFrame"] then
        return false
    end
    
    local success = pcall(function()
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Talent tabs
        for i = 1, 5 do
            local tab = _G["PlayerTalentFrameTab" .. i]
            if tab then
                Aurora.ReskinTab(tab)
            end
        end
        
        skinnedBlizzardFrames["PlayerTalentFrame"] = true
    end)
    
    return success
end

function BlizzardSkinning:SkinWorldMapFrame(frame)
    if not frame or skinnedBlizzardFrames["WorldMapFrame"] then
        return false
    end
    
    local success = pcall(function()
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Hide default border textures
        if frame.BorderFrame then
            for _, texture in pairs({
                frame.BorderFrame.TopEdge,
                frame.BorderFrame.BottomEdge,
                frame.BorderFrame.LeftEdge,
                frame.BorderFrame.RightEdge,
                frame.BorderFrame.TopLeftCorner,
                frame.BorderFrame.TopRightCorner,
                frame.BorderFrame.BottomLeftCorner,
                frame.BorderFrame.BottomRightCorner
            }) do
                if texture then
                    texture:Hide()
                end
            end
        end
        
        skinnedBlizzardFrames["WorldMapFrame"] = true
    end)
    
    return success
end

function BlizzardSkinning:SkinCollectionsFrame(frame)
    if not frame or skinnedBlizzardFrames["CollectionsJournal"] then
        return false
    end
    
    local success = pcall(function()
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Collections tabs
        for i = 1, 5 do
            local tab = _G["CollectionsJournalTab" .. i]
            if tab then
                Aurora.ReskinTab(tab)
            end
        end
        
        skinnedBlizzardFrames["CollectionsJournal"] = true
    end)
    
    return success
end

function BlizzardSkinning:SkinEncounterJournal(frame)
    if not frame or skinnedBlizzardFrames["EncounterJournal"] then
        return false
    end
    
    local success = pcall(function()
        Aurora.CreateBD(frame, 0.25)
        self:CreateDamiaBorder(frame)
        
        -- Instance selection
        if EncounterJournalInstanceSelect then
            Aurora.CreateBD(EncounterJournalInstanceSelect, 0.1)
        end
        
        -- Encounter info
        if EncounterJournalEncounterFrame then
            Aurora.CreateBD(EncounterJournalEncounterFrame, 0.1)
        end
        
        skinnedBlizzardFrames["EncounterJournal"] = true
    end)
    
    return success
end

--[[
    Frame Monitoring System
]]

function BlizzardSkinning:SetupFrameMonitoring()
    -- Create monitoring frame
    local monitorFrame = CreateFrame("Frame", "DamiaUIBlizzardSkinMonitor")
    
    -- Monitor addon loading
    monitorFrame:RegisterEvent("ADDON_LOADED")
    monitorFrame:RegisterEvent("PLAYER_LOGIN")
    monitorFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            self:OnAddonLoaded(addonName)
        elseif event == "PLAYER_LOGIN" then
            -- Final skinning pass after login
            C_Timer.After(2, function()
                BlizzardSkinning:SkinMissedFrames()
            end)
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Skin combat frames after combat ends
            BlizzardSkinning:ProcessCombatQueue()
        end
    end)
    
    -- Monitor frame creation
    self:HookFrameCreation()
end

function BlizzardSkinning:OnAddonLoaded(addonName)
    -- Skin frames from newly loaded Blizzard addons
    if addonName:match("^Blizzard_") then
        C_Timer.After(0.2, function()
            self:SkinAddonFrames(addonName)
        end)
    end
end

function BlizzardSkinning:HookFrameCreation()
    -- Hook CreateFrame to catch dynamically created Blizzard frames
    local originalCreateFrame = CreateFrame
    CreateFrame = function(frameType, name, parent, template, id)
        local frame = originalCreateFrame(frameType, name, parent, template, id)
        
        if frame and name and self:ShouldMonitorFrame(name) then
            -- Queue for delayed skinning
            table.insert(queuedFrames, {
                frame = frame,
                name = name,
                timestamp = GetTime()
            })
        end
        
        return frame
    end
    
    -- Process queued frames periodically
    C_Timer.NewTicker(2, function()
        self:ProcessFrameQueue()
    end)
end

function BlizzardSkinning:ShouldMonitorFrame(frameName)
    if not frameName or skinnedBlizzardFrames[frameName] then
        return false
    end
    
    -- Check against monitored patterns
    for _, pattern in ipairs(MONITORED_FRAME_PATTERNS) do
        if frameName:match(pattern) then
            return true
        end
    end
    
    return false
end

function BlizzardSkinning:ProcessFrameQueue()
    local currentTime = GetTime()
    local processedCount = 0
    
    for i = #queuedFrames, 1, -1 do
        local frameInfo = queuedFrames[i]
        
        -- Process frames that have been queued for at least 1 second
        if currentTime - frameInfo.timestamp >= 1 then
            if frameInfo.frame and not skinnedBlizzardFrames[frameInfo.name] then
                self:SkinBlizzardFrame(frameInfo.name)
                processedCount = processedCount + 1
            end
            
            table.remove(queuedFrames, i)
        end
    end
    
    if processedCount > 0 then
        DamiaUI:LogDebug("Processed " .. processedCount .. " queued Blizzard frames")
    end
end

--[[
    Combat Frame Handling
]]

function BlizzardSkinning:QueueCombatFrames()
    -- Register for combat end to skin combat-sensitive frames
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function()
        BlizzardSkinning:ProcessCombatQueue()
        combatFrame:UnregisterAllEvents()
    end)
end

function BlizzardSkinning:ProcessCombatQueue()
    if InCombatLockdown() then
        return
    end
    
    -- Skin combat-sensitive frames
    self:SkinFrameCategory("combat")
    
    DamiaUI:LogDebug("Combat frames skinned")
end

--[[
    Utility Functions
]]

function BlizzardSkinning:CreateDamiaBorder(frame)
    if not frame or frame.damiaBorder then
        return
    end
    
    local border = CreateFrame("Frame", nil, frame)
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

function BlizzardSkinning:ProcessChildFrames(frame, callback)
    if not frame or not callback then
        return
    end
    
    local function ProcessFrame(f)
        callback(f)
        
        -- Process children recursively
        local children = { f:GetChildren() }
        for _, child in ipairs(children) do
            ProcessFrame(child)
        end
    end
    
    ProcessFrame(frame)
end

function BlizzardSkinning:AnimateFrameEntry(frame)
    if not frame or not frame.SetAlpha then
        return
    end
    
    -- Fade in animation for newly skinned frames
    frame:SetAlpha(0)
    
    local fadeIn = frame:CreateAnimationGroup()
    local fade = fadeIn:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.3)
    fade:SetSmoothing("OUT")
    
    fadeIn:Play()
end

function BlizzardSkinning:SkinMissedFrames()
    -- Final pass to catch any missed frames
    for category, frames in pairs(BLIZZARD_FRAMES) do
        for _, frameName in ipairs(frames) do
            if not skinnedBlizzardFrames[frameName] then
                self:SkinBlizzardFrame(frameName)
            end
        end
    end
end

function BlizzardSkinning:SkinAddonFrames(addonName)
    -- Skin frames from specific Blizzard addon
    local addon = _G[addonName]
    if not addon then
        return
    end
    
    -- Look for frames created by this addon
    for _, frameName in pairs(BLIZZARD_FRAMES.core) do
        local frame = _G[frameName]
        if frame and not skinnedBlizzardFrames[frameName] then
            self:SkinBlizzardFrame(frameName)
        end
    end
end

--[[
    Public API
]]

function BlizzardSkinning:RefreshAllSkins()
    -- Clear skinned frames cache and re-skin all
    table.wipe(skinnedBlizzardFrames)
    
    C_Timer.After(0.1, function()
        self:StartDelayedSkinning()
    end)
end

function BlizzardSkinning:IsFrameSkinned(frameName)
    return skinnedBlizzardFrames[frameName] == true
end

function BlizzardSkinning:GetSkinnedFrameCount()
    local count = 0
    for _ in pairs(skinnedBlizzardFrames) do
        count = count + 1
    end
    return count
end

-- Initialize when called
if DamiaUI.Skinning then
    DamiaUI.Skinning.Blizzard = BlizzardSkinning
end