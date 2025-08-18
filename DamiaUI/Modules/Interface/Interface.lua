--[[
    DamiaUI Interface Module
    
    Manages chat frames, minimap, and other interface elements with
    centered positioning and Aurora skinning integration.
    
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
local InCombatLockdown = InCombatLockdown

-- Initialize module
local Interface = DamiaUI:NewModule("Interface", "AceEvent-3.0")
DamiaUI.Interface = Interface

-- Module state
local Aurora
local elements = {}
local isInitialized = false

-- Interface element positions (relative to screen center)
local ELEMENT_POSITIONS = {
    chat = { x = -400, y = -200 },
    minimap = { x = 200, y = 200 },
    tooltip = { x = 0, y = 0 }, -- Tooltip follows cursor
    bags = { x = 300, y = -100 },
    menu = { x = -300, y = 300 },
}

-- Element configurations
local ELEMENT_CONFIGS = {
    chat = {
        width = 350,
        height = 120,
        fontSize = 12,
        fadeTime = 10,
        maxLines = 200,
    },
    minimap = {
        size = 140,
        showZone = true,
        showClock = true,
        showDifficulty = true,
    },
    tooltip = {
        anchor = "CURSOR",
        fontSize = 11,
        showHealthbar = true,
    },
}

--[[
    Module Initialization
]]

function Interface:OnInitialize()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function Interface:OnEnable()
    if not self:InitializeLibraries() then
        DamiaUI:LogWarning("Interface: Aurora library not available - limited skinning")
    end
    
    -- Register for DamiaUI events
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        self:SetupAllElements()
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^interface%.") then
            self:OnConfigChanged(key, oldValue, newValue)
        end
    end, 3)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_SCALE_CHANGED", function(event, newScale)
        self:UpdateAllPositions()
    end, 2)
    
    DamiaUI:LogDebug("Interface module enabled")
end

function Interface:InitializeLibraries()
    -- Get Aurora library reference
    Aurora = DamiaUI.Libraries.Aurora
    return Aurora ~= nil
end

--[[
    Element Setup - Enhanced with new modules
]]

function Interface:SetupAllElements()
    if isInitialized then
        return
    end
    
    -- Initialize individual interface modules
    self:InitializeSubModules()
    
    -- Setup legacy elements (keeping for compatibility)
    if DamiaUI.Config.Get("interface.chat.enabled", true) then
        self:SetupChat()
    end
    
    if DamiaUI.Config.Get("interface.minimap.enabled", true) then
        self:SetupMinimap()
    end
    
    if DamiaUI.Config.Get("interface.tooltip.enabled", true) then
        self:SetupTooltip()
    end
    
    isInitialized = true
    DamiaUI:LogDebug("Interface elements setup complete")
end

function Interface:InitializeSubModules()
    -- The specialized interface modules are loaded separately
    -- This function ensures they are initialized properly
    
    local initOrder = {
        { name = "Chat", module = DamiaUI.Interface.Chat },
        { name = "Minimap", module = DamiaUI.Interface.Minimap },
        { name = "InfoPanels", module = DamiaUI.Interface.InfoPanels },
        { name = "Buffs", module = DamiaUI.Interface.Buffs }
    }
    
    -- Initialize modules in order with delay between each
    for i, moduleInfo in ipairs(initOrder) do
        C_Timer.After(i * 0.2, function()
            if moduleInfo.module and moduleInfo.module.Initialize then
                DamiaUI:LogDebug("Initializing " .. moduleInfo.name .. " module")
                local success = pcall(moduleInfo.module.Initialize, moduleInfo.module)
                if not success then
                    DamiaUI:LogWarning("Failed to initialize " .. moduleInfo.name .. " module")
                end
            else
                DamiaUI:LogDebug("Module " .. moduleInfo.name .. " not available for initialization")
            end
        end)
    end
end

--[[
    Chat System
]]

function Interface:SetupChat()
    -- Position and style chat frames
    self:SetupChatFrame(ChatFrame1)
    
    -- Setup additional chat frames if needed
    for i = 2, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            self:SetupChatFrame(chatFrame)
        end
    end
    
    -- Apply Aurora skinning to chat frames
    if Aurora then
        self:ApplyChatSkinning()
    end
    
    elements.chat = true
    DamiaUI:LogDebug("Chat setup complete")
end

function Interface:SetupChatFrame(chatFrame)
    if not chatFrame then
        return
    end
    
    local config = ELEMENT_CONFIGS.chat
    local pos = ELEMENT_POSITIONS.chat
    
    -- Set size
    chatFrame:SetSize(config.width, config.height)
    
    -- Position chat frame
    local x, y = DamiaUI:GetCenterPosition(pos.x, pos.y)
    chatFrame:ClearAllPoints()
    chatFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    
    -- Configure chat frame properties
    chatFrame:SetMaxLines(config.maxLines)
    chatFrame:SetFading(config.fadeTime > 0)
    chatFrame:SetTimeVisible(config.fadeTime)
    
    -- Set font
    local chatFont = chatFrame:GetFont()
    if chatFont then
        chatFrame:SetFont(chatFont, config.fontSize, "OUTLINE")
    end
    
    -- Make draggable (if not in combat)
    if not InCombatLockdown() then
        chatFrame:SetMovable(true)
        chatFrame:SetUserPlaced(true)
        chatFrame:SetClampedToScreen(true)
    end
end

function Interface:ApplyChatSkinning()
    if not Aurora then
        return
    end
    
    -- Apply Aurora skin to chat frames
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and Aurora.Skin then
            if Aurora.Skin.ChatFrameWidget then
                Aurora.Skin.ChatFrameWidget(chatFrame)
            end
        end
        
        -- Skin chat tabs
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and Aurora.Skin and Aurora.Skin.ChatTabWidget then
            Aurora.Skin.ChatTabWidget(chatTab)
        end
    end
end

--[[
    Minimap System
]]

function Interface:SetupMinimap()
    if not Minimap then
        return
    end
    
    local config = ELEMENT_CONFIGS.minimap
    local pos = ELEMENT_POSITIONS.minimap
    
    -- Position minimap
    local x, y = DamiaUI:GetCenterPosition(pos.x, pos.y)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    
    -- Set size
    Minimap:SetSize(config.size, config.size)
    
    -- Configure minimap shape
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    
    -- Setup minimap elements
    self:SetupMinimapElements(config)
    
    -- Apply Aurora skinning
    if Aurora and Aurora.Skin and Aurora.Skin.MinimapWidget then
        Aurora.Skin.MinimapWidget(Minimap)
    end
    
    elements.minimap = Minimap
    DamiaUI:LogDebug("Minimap setup complete")
end

function Interface:SetupMinimapElements(config)
    -- Zone text
    if config.showZone and MinimapZoneText then
        MinimapZoneText:ClearAllPoints()
        MinimapZoneText:SetPoint("TOP", Minimap, "TOP", 0, 15)
        MinimapZoneText:Show()
    elseif MinimapZoneText then
        MinimapZoneText:Hide()
    end
    
    -- Clock
    if config.showClock and TimeManagerClockButton then
        TimeManagerClockButton:ClearAllPoints()
        TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -15)
        TimeManagerClockButton:Show()
    elseif TimeManagerClockButton then
        TimeManagerClockButton:Hide()
    end
    
    -- Difficulty indicator
    if config.showDifficulty and MiniMapInstanceDifficulty then
        MiniMapInstanceDifficulty:ClearAllPoints()
        MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        MiniMapInstanceDifficulty:Show()
    elseif MiniMapInstanceDifficulty then
        MiniMapInstanceDifficulty:Hide()
    end
    
    -- Hide unwanted elements
    local elementsToHide = {
        MinimapBorderTop,
        MinimapBorder,
        MiniMapWorldMapButton,
        MiniMapMailFrame,
        MinimapBackdrop,
    }
    
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
        end
    end
end

--[[
    Tooltip System  
]]

function Interface:SetupTooltip()
    -- Configure GameTooltip
    if not GameTooltip then
        return
    end
    
    local config = ELEMENT_CONFIGS.tooltip
    
    -- Set tooltip font
    local font = GameTooltipText:GetFont()
    if font then
        GameTooltipText:SetFont(font, config.fontSize, "OUTLINE")
    end
    
    -- Configure tooltip behavior
    if config.anchor == "CURSOR" then
        GameTooltip:SetScript("OnShow", function(self)
            self:SetOwner(UIParent, "ANCHOR_CURSOR")
        end)
    end
    
    -- Health bar configuration
    if config.showHealthbar and GameTooltipStatusBar then
        GameTooltipStatusBar:SetHeight(8)
        GameTooltipStatusBar:ClearAllPoints()
        GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", 2, 2)
        GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Apply Aurora skinning
    if Aurora and Aurora.Skin and Aurora.Skin.TooltipWidget then
        Aurora.Skin.TooltipWidget(GameTooltip)
    end
    
    elements.tooltip = GameTooltip
    DamiaUI:LogDebug("Tooltip setup complete")
end

--[[
    Position Management
]]

function Interface:UpdateElementPosition(elementName)
    local element = elements[elementName]
    if not element then
        return
    end
    
    local pos = ELEMENT_POSITIONS[elementName]
    if not pos then
        return
    end
    
    -- Get position from config or use default
    local configPos = DamiaUI.Config.Get("interface." .. elementName .. ".position")
    local x = configPos and configPos.x or pos.x
    local y = configPos and configPos.y or pos.y
    
    local finalX, finalY = DamiaUI:GetCenterPosition(x, y)
    element:ClearAllPoints()
    element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", finalX, finalY)
end

function Interface:UpdateAllPositions()
    for elementName, element in pairs(elements) do
        if element and element.SetPoint then
            self:UpdateElementPosition(elementName)
        end
    end
end

--[[
    Bag Management
]]

function Interface:SetupBags()
    -- This would handle bag frame positioning and skinning
    -- Implementation would depend on specific bag addon integration
    DamiaUI:LogDebug("Bag setup placeholder")
end

--[[
    Menu Systems
]]

function Interface:SetupMenus()
    -- Position micro menu if enabled
    if MicroButtonAndBagsBar and DamiaUI.Config.Get("interface.micromenu.enabled", false) then
        local pos = ELEMENT_POSITIONS.menu
        local x, y = DamiaUI:GetCenterPosition(pos.x, pos.y)
        MicroButtonAndBagsBar:ClearAllPoints()
        MicroButtonAndBagsBar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        MicroButtonAndBagsBar:Show()
    end
end

--[[
    Combat State Management
]]

function Interface:OnCombatStateChanged(inCombat)
    -- Notify all sub-modules about combat state change
    if DamiaUI.Interface.Chat and DamiaUI.Interface.Chat.SetCombatState then
        DamiaUI.Interface.Chat:SetCombatState(inCombat)
    end
    
    if DamiaUI.Interface.Minimap and DamiaUI.Interface.Minimap.SetCombatState then
        DamiaUI.Interface.Minimap:SetCombatState(inCombat)
    end
    
    if DamiaUI.Interface.InfoPanels and DamiaUI.Interface.InfoPanels.SetCombatState then
        DamiaUI.Interface.InfoPanels:SetCombatState(inCombat)
    end
    
    if DamiaUI.Interface.Buffs and DamiaUI.Interface.Buffs.SetCombatState then
        DamiaUI.Interface.Buffs:SetCombatState(inCombat)
    end
    
    DamiaUI:LogDebug("Interface combat state changed: " .. (inCombat and "Entering" or "Leaving") .. " combat")
end

function Interface:UpdateVisibilityForState(state)
    -- State-based visibility management
    -- States: "combat", "normal", "party", "raid", "solo"
    
    local visibility = {
        combat = {
            chat = { show = true, alpha = 0.3 },
            minimap = { show = true, alpha = 0.8 },
            infopanels = { show = true, alpha = 0.6 },
            buffs = { show = true, alpha = 0.7 }
        },
        normal = {
            chat = { show = true, alpha = 1.0 },
            minimap = { show = true, alpha = 1.0 },
            infopanels = { show = true, alpha = 1.0 },
            buffs = { show = true, alpha = 1.0 }
        },
        party = {
            chat = { show = true, alpha = 0.8 },
            minimap = { show = true, alpha = 1.0 },
            infopanels = { show = true, alpha = 0.9 },
            buffs = { show = true, alpha = 1.0 }
        }
    }
    
    local stateConfig = visibility[state] or visibility.normal
    
    for elementType, config in pairs(stateConfig) do
        local element = elements[elementType]
        if element then
            if config.show then
                element:Show()
                element:SetAlpha(config.alpha or 1.0)
            else
                element:Hide()
            end
        end
    end
end

--[[
    Configuration Handlers
]]

function Interface:OnConfigChanged(key, oldValue, newValue)
    local parts = DamiaUI.Config.ParseKey(key)
    if #parts < 2 then
        return
    end
    
    local elementName = parts[2]
    local setting = parts[3]
    
    if setting == "enabled" then
        self:SetElementVisibility(elementName, newValue)
    elseif setting == "position" then
        self:UpdateElementPosition(elementName)
    elseif setting == "scale" then
        self:UpdateElementScale(elementName, newValue)
    elseif elementName == "chat" and setting == "fontSize" then
        self:UpdateChatFontSize(newValue)
    end
    
    -- Forward config changes to sub-modules
    self:ForwardConfigToSubModules(key, oldValue, newValue)
end

function Interface:ForwardConfigToSubModules(key, oldValue, newValue)
    -- Forward configuration changes to specialized modules
    local modules = {
        ["interface.chat"] = DamiaUI.Interface.Chat,
        ["interface.minimap"] = DamiaUI.Interface.Minimap,
        ["interface.infopanels"] = DamiaUI.Interface.InfoPanels,
        ["interface.buffs"] = DamiaUI.Interface.Buffs
    }
    
    for configPrefix, module in pairs(modules) do
        if key:match("^" .. configPrefix) and module and module.UpdateConfiguration then
            local configPart = key:match(configPrefix .. "%.(.+)")
            if configPart then
                module:UpdateConfiguration({[configPart] = newValue})
            end
        end
    end
end

function Interface:SetElementVisibility(elementName, visible)
    local element = elements[elementName]
    if not element then
        return
    end
    
    if visible then
        element:Show()
    else
        element:Hide()
    end
end

function Interface:UpdateElementScale(elementName, scale)
    local element = elements[elementName]
    if not element then
        return
    end
    
    element:SetScale(scale or 1.0)
end

function Interface:UpdateChatFontSize(fontSize)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            local font = chatFrame:GetFont()
            if font then
                chatFrame:SetFont(font, fontSize or 12, "OUTLINE")
            end
        end
    end
end

--[[
    Public API
]]

-- Get interface element
function Interface:GetElement(elementName)
    return elements[elementName]
end

-- Refresh all elements
function Interface:RefreshAllElements()
    self:UpdateAllPositions()
    
    -- Refresh specific elements
    if elements.chat then
        for i = 1, NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame" .. i]
            if chatFrame and chatFrame.isDocked then
                FCF_DockFrame(chatFrame)
            end
        end
    end
    
    -- Refresh sub-modules
    self:RefreshSubModules()
end

function Interface:RefreshSubModules()
    -- Refresh all specialized interface modules
    local modules = {
        DamiaUI.Interface.Chat,
        DamiaUI.Interface.Minimap,
        DamiaUI.Interface.InfoPanels,
        DamiaUI.Interface.Buffs
    }
    
    for _, module in ipairs(modules) do
        if module and module.Refresh then
            local success = pcall(module.Refresh, module)
            if not success then
                DamiaUI:LogWarning("Failed to refresh interface module")
            end
        end
    end
end

function Interface:UpdateAllModulePositions()
    -- Update positions for all specialized modules
    local modules = {
        DamiaUI.Interface.Chat,
        DamiaUI.Interface.Minimap,
        DamiaUI.Interface.InfoPanels,
        DamiaUI.Interface.Buffs
    }
    
    for _, module in ipairs(modules) do
        if module and module.UpdatePositions then
            local success = pcall(module.UpdatePositions, module)
            if not success then
                DamiaUI:LogWarning("Failed to update module positions")
            end
        end
    end
end

-- Force update all interface elements
function Interface:ForceUpdateAll()
    -- Force update legacy elements
    self:RefreshAllElements()
    
    -- Force update specialized modules
    local modules = {
        DamiaUI.Interface.InfoPanels,
        DamiaUI.Interface.Buffs
    }
    
    for _, module in ipairs(modules) do
        if module and module.ForceUpdate then
            pcall(module.ForceUpdate, module)
        end
    end
end

--[[
    Aurora Integration Helpers
]]

function Interface:ApplyAuroraToElement(element, skinFunction)
    if not Aurora or not Aurora.Skin or not element then
        return
    end
    
    if skinFunction and Aurora.Skin[skinFunction] then
        Aurora.Skin[skinFunction](element)
    end
end

--[[
    Event Handlers
]]

function Interface:ADDON_LOADED(event, loadedAddon)
    if loadedAddon == addonName then
        -- Setup interface elements that don't need delay
    end
end

function Interface:PLAYER_LOGIN()
    -- Initialize interface elements after login
    C_Timer.After(1, function()
        if not isInitialized then
            self:SetupAllElements()
        end
    end)
end

function Interface:PLAYER_ENTERING_WORLD()
    -- Final setup after entering world
    C_Timer.After(0.5, function()
        self:RefreshAllElements()
    end)
end

function Interface:PLAYER_REGEN_DISABLED()
    -- Entering combat
    self:OnCombatStateChanged(true)
    self:UpdateVisibilityForState("combat")
end

function Interface:PLAYER_REGEN_ENABLED()
    -- Leaving combat
    self:OnCombatStateChanged(false)
    self:UpdateVisibilityForState("normal")
end

function Interface:GROUP_ROSTER_UPDATE()
    -- Party/raid status changed
    local inParty = IsInGroup()
    local inRaid = IsInRaid()
    
    if inRaid then
        self:UpdateVisibilityForState("raid")
    elseif inParty then
        self:UpdateVisibilityForState("party")
    else
        self:UpdateVisibilityForState("solo")
    end
end

-- Register the module
DamiaUI:RegisterModule("Interface", Interface)