--[[
    DamiaUI - Chat Interface Module
    
    Manages chat frame repositioning, styling, and Aurora integration.
    Positions chat frames at bottom-left following the viewport-first design philosophy.
    
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
local type, tonumber = type, tonumber
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight

-- Initialize chat module
local Chat = {}
DamiaUI.Interface = DamiaUI.Interface or {}
DamiaUI.Interface.Chat = Chat

-- Module state
local Aurora
local chatFrames = {}
local isInitialized = false

-- Chat configuration based on viewport-first design
local CHAT_CONFIG = {
    -- Position at bottom-left relative to screen center
    position = { x = -400, y = -200 },
    size = { width = 350, height = 120 },
    font = {
        size = 12,
        flags = "OUTLINE",
        file = "Fonts\\FRIZQT__.TTF"
    },
    behavior = {
        fadeTime = 10,
        maxLines = 200,
        enableCopyURL = true,
        enableStickyChannels = true,
        showTimestamps = false
    },
    combat = {
        fadeAlpha = 0.3,
        hideOnCombat = false
    }
}

--[[
    Positioning System
    Following the centered viewport-first design
]]
local function GetCenterPosition(offsetX, offsetY)
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()
    
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    return (centerX + offsetX) / uiScale, (centerY + offsetY) / uiScale
end

local function PositionChatFrame(chatFrame, config)
    if not chatFrame or InCombatLockdown() then
        return
    end
    
    config = config or CHAT_CONFIG
    local x, y = GetCenterPosition(config.position.x, config.position.y)
    
    chatFrame:ClearAllPoints()
    chatFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    chatFrame:SetSize(config.size.width, config.size.height)
    chatFrame:SetUserPlaced(true)
    chatFrame:SetMovable(true)
    chatFrame:SetClampedToScreen(true)
end

--[[
    Chat Frame Setup and Styling
]]
local function StyleChatFrame(chatFrame)
    if not chatFrame then
        return
    end
    
    local config = CHAT_CONFIG
    
    -- Set font
    local fontFile, fontSize, fontFlags = chatFrame:GetFont()
    fontSize = config.font.size
    fontFlags = config.font.flags
    
    if config.font.file and fontFile ~= config.font.file then
        fontFile = config.font.file
    end
    
    chatFrame:SetFont(fontFile, fontSize, fontFlags)
    
    -- Configure behavior
    chatFrame:SetMaxLines(config.behavior.maxLines)
    chatFrame:SetFading(config.behavior.fadeTime > 0)
    if config.behavior.fadeTime > 0 then
        chatFrame:SetTimeVisible(config.behavior.fadeTime)
    end
    
    -- Enable editing box improvements
    local editBox = _G[chatFrame:GetName() .. "EditBox"]
    if editBox then
        editBox:SetAltArrowKeyMode(false)
        
        -- Style edit box
        if Aurora and Aurora.Skin and Aurora.Skin.EditBoxWidget then
            Aurora.Skin.EditBoxWidget(editBox)
        end
    end
end

local function ApplyAuroraStyling(chatFrame)
    if not Aurora or not Aurora.Skin then
        return
    end
    
    -- Apply Aurora skin to chat frame
    if Aurora.Skin.ChatFrameWidget then
        Aurora.Skin.ChatFrameWidget(chatFrame)
    end
    
    -- Style chat tab
    local chatTab = _G[chatFrame:GetName() .. "Tab"]
    if chatTab and Aurora.Skin.ChatTabWidget then
        Aurora.Skin.ChatTabWidget(chatTab)
    end
    
    -- Style scrolling button
    local scrollButton = _G[chatFrame:GetName() .. "ButtonFrameUpButton"]
    if scrollButton and Aurora.Skin.ButtonWidget then
        Aurora.Skin.ButtonWidget(scrollButton)
    end
    
    local scrollDownButton = _G[chatFrame:GetName() .. "ButtonFrameDownButton"]
    if scrollDownButton and Aurora.Skin.ButtonWidget then
        Aurora.Skin.ButtonWidget(scrollDownButton)
    end
end

local function SetupChatFrame(chatFrame, frameIndex)
    if not chatFrame then
        return
    end
    
    -- Store reference
    chatFrames[frameIndex] = chatFrame
    
    -- Position and size
    PositionChatFrame(chatFrame)
    
    -- Apply styling
    StyleChatFrame(chatFrame)
    
    -- Apply Aurora skin
    ApplyAuroraStyling(chatFrame)
    
    -- Configure visibility based on combat state
    chatFrame.DamiaUI_OriginalAlpha = chatFrame:GetAlpha()
    
    DamiaUI:LogDebug("Chat frame " .. frameIndex .. " setup complete")
end

--[[
    Combat State Management
]]
local function UpdateCombatVisibility(inCombat)
    local config = CHAT_CONFIG.combat
    
    for _, chatFrame in pairs(chatFrames) do
        if chatFrame and chatFrame:IsVisible() then
            if inCombat and config.hideOnCombat then
                chatFrame:Hide()
            elseif inCombat and config.fadeAlpha then
                chatFrame:SetAlpha(config.fadeAlpha)
            else
                chatFrame:Show()
                chatFrame:SetAlpha(chatFrame.DamiaUI_OriginalAlpha or 1.0)
            end
        end
    end
end

--[[
    URL Copy Enhancement
]]
local function EnableURLCopying()
    if not CHAT_CONFIG.behavior.enableCopyURL then
        return
    end
    
    -- Create URL copy frame
    local urlCopyFrame = CreateFrame("Frame", "DamiaUI_URLCopyFrame", UIParent, "DialogBoxFrame")
    urlCopyFrame:SetSize(350, 100)
    urlCopyFrame:SetPoint("CENTER")
    urlCopyFrame:Hide()
    
    local editBox = CreateFrame("EditBox", "DamiaUI_URLCopyEditBox", urlCopyFrame, "InputBoxTemplate")
    editBox:SetSize(300, 20)
    editBox:SetPoint("CENTER", urlCopyFrame, "CENTER", 0, 10)
    editBox:SetAutoFocus(true)
    
    local closeButton = CreateFrame("Button", nil, urlCopyFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOM", urlCopyFrame, "BOTTOM", 0, 20)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        urlCopyFrame:Hide()
    end)
    
    -- Apply Aurora styling
    if Aurora and Aurora.Skin then
        if Aurora.Skin.FrameWidget then
            Aurora.Skin.FrameWidget(urlCopyFrame)
        end
        if Aurora.Skin.EditBoxWidget then
            Aurora.Skin.EditBoxWidget(editBox)
        end
        if Aurora.Skin.ButtonWidget then
            Aurora.Skin.ButtonWidget(closeButton)
        end
    end
    
    -- Store reference for external use
    Chat.urlCopyFrame = urlCopyFrame
    Chat.urlEditBox = editBox
end

--[[
    Sticky Channels Enhancement
]]
local function SetupStickyChannels()
    if not CHAT_CONFIG.behavior.enableStickyChannels then
        return
    end
    
    -- Override default sticky behavior
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        
        if chatFrame and editBox then
            ChatTypeInfo["SAY"].sticky = 1
            ChatTypeInfo["YELL"].sticky = 1
            ChatTypeInfo["PARTY"].sticky = 1
            ChatTypeInfo["GUILD"].sticky = 1
            ChatTypeInfo["OFFICER"].sticky = 1
            ChatTypeInfo["RAID"].sticky = 1
            ChatTypeInfo["BATTLEGROUND"].sticky = 1
            ChatTypeInfo["WHISPER"].sticky = 1
        end
    end
end

--[[
    Configuration Management
]]
function Chat:UpdateConfiguration(newConfig)
    if type(newConfig) ~= "table" then
        return
    end
    
    -- Merge configuration
    for key, value in pairs(newConfig) do
        if CHAT_CONFIG[key] then
            if type(value) == "table" and type(CHAT_CONFIG[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    CHAT_CONFIG[key][subKey] = subValue
                end
            else
                CHAT_CONFIG[key] = value
            end
        end
    end
    
    -- Reapply configuration to all chat frames
    for i, chatFrame in pairs(chatFrames) do
        if chatFrame then
            SetupChatFrame(chatFrame, i)
        end
    end
end

function Chat:GetConfiguration()
    return CHAT_CONFIG
end

--[[
    Public API
]]
function Chat:Initialize()
    if isInitialized then
        return true
    end
    
    -- Get Aurora library
    Aurora = DamiaUI.Libraries and DamiaUI.Libraries.Aurora
    
    -- Setup primary chat frame
    if ChatFrame1 then
        SetupChatFrame(ChatFrame1, 1)
    end
    
    -- Setup additional chat frames
    for i = 2, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            SetupChatFrame(chatFrame, i)
        end
    end
    
    -- Setup enhancements
    EnableURLCopying()
    SetupStickyChannels()
    
    isInitialized = true
    return true
end

function Chat:Refresh()
    for i, chatFrame in pairs(chatFrames) do
        if chatFrame then
            SetupChatFrame(chatFrame, i)
        end
    end
end

function Chat:UpdatePositions()
    for _, chatFrame in pairs(chatFrames) do
        if chatFrame then
            PositionChatFrame(chatFrame)
        end
    end
end

function Chat:SetCombatState(inCombat)
    UpdateCombatVisibility(inCombat)
end

function Chat:GetChatFrame(index)
    return chatFrames[index]
end

function Chat:ShowURLCopy(url)
    if self.urlCopyFrame and self.urlEditBox then
        self.urlEditBox:SetText(url or "")
        self.urlEditBox:HighlightText()
        self.urlCopyFrame:Show()
    end
end

--[[
    Event Handlers
]]
local function OnChatEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        Chat:SetCombatState(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Chat:SetCombatState(false)
    elseif event == "UI_SCALE_CHANGED" then
        C_Timer.After(0.1, function()
            Chat:UpdatePositions()
        end)
    end
end

-- Register events if DamiaUI event system is available
if DamiaUI and DamiaUI.Events then
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        Chat:Initialize()
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^interface%.chat%.") then
            local configPart = key:match("interface%.chat%.(.+)")
            if configPart then
                Chat:UpdateConfiguration({[configPart] = newValue})
            end
        end
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_COMBAT_STATE_CHANGED", function(event, inCombat)
        Chat:SetCombatState(inCombat)
    end, 2)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_SCALE_CHANGED", function()
        Chat:UpdatePositions()
    end, 2)
end

-- Fallback event registration
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", OnChatEvent)

-- Initialize on load if DamiaUI is ready
if DamiaUI and DamiaUI.IsReady then
    C_Timer.After(1, function()
        Chat:Initialize()
    end)
end

return Chat