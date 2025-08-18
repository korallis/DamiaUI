--[[
    DamiaUI Comprehensive Aurora Skinning Module
    
    Master skinning controller that coordinates Blizzard frame skinning,
    third-party addon integration, and custom styling with the Damia UI theme.
    Implements delayed application, frame monitoring, and accessibility features.
    
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

-- Initialize module
local Skinning = DamiaUI:NewModule("Skinning", "AceEvent-3.0")
DamiaUI.Skinning = Skinning

-- Module state
local Aurora
local isInitialized = false
local skinnedFrames = {}
local framesToSkin = {}
local monitorFrame
local subModules = {}
local highContrastMode = false

-- Skinning priorities and module initialization order
local SKINNING_PRIORITIES = {
    ["Custom"] = 1,    -- Initialize custom styling first
    ["Blizzard"] = 2,  -- Then Blizzard frames
    ["DamiaUI"] = 3,   -- DamiaUI specific frames
    ["ThirdParty"] = 4, -- Finally third-party addons
}

-- Damia UI signature color scheme
local DAMIA_COLORS = {
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
    border = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
    accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }, -- Signature orange
    highlight = { r = 1.0, g = 0.6, b = 0.2, a = 0.3 },
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textDisabled = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
    -- High contrast variants
    hcBackground = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
    hcBorder = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    hcAccent = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
    hcText = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
}

-- Known third-party addons that need skinning
local ADDON_SKINNING_MAP = {
    ["Recount"] = "RecountMainWindow",
    ["Details"] = "DetailsBaseFrame1",
    ["WeakAuras"] = function() return WeakAuras and WeakAuras.GetOptionsFrame() end,
    ["BigWigs"] = "BigWigsAnchor",
    ["DBM-Core"] = "DBMMainFrame",
    ["Auctionator"] = "AuctionatorFrame",
    ["TradeSkillMaster"] = "TSMMainFrame",
}

--[[
    Module Initialization
]]

function Skinning:OnInitialize()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGIN")
end

function Skinning:OnEnable()
    if not self:InitializeLibraries() then
        DamiaUI:LogError("Skinning: Aurora library not available - module disabled")
        return
    end
    
    -- Initialize submodules
    if not self:InitializeSubModules() then
        DamiaUI:LogError("Skinning: Failed to initialize submodules")
        return
    end
    
    -- Register for DamiaUI events
    DamiaUI.Events.RegisterCustomEvent("DAMIA_UI_READY", function()
        self:InitializeSkinning()
    end, 4)
    
    DamiaUI.Events.RegisterCustomEvent("DAMIA_CONFIG_CHANGED", function(event, key, oldValue, newValue)
        if key:match("^skinning%.") then
            self:OnConfigChanged(key, oldValue, newValue)
        end
    end, 3)
    
    -- Register for accessibility events
    DamiaUI.Events.RegisterCustomEvent("DAMIA_ACCESSIBILITY_CHANGED", function(event, setting, value)
        self:OnAccessibilityChanged(setting, value)
    end, 3)
    
    DamiaUI:LogDebug("Skinning module enabled with submodules")
end

function Skinning:InitializeLibraries()
    -- Get Aurora library reference
    Aurora = DamiaUI.Libraries.Aurora
    if not Aurora then
        DamiaUI:LogError("Aurora library not found")
        return false
    end
    
    -- Configure Aurora settings
    self:ConfigureAurora()
    
    return true
end

function Skinning:InitializeSubModules()
    -- Load submodules in priority order
    local subModuleFiles = {
        ["Custom"] = "Custom.lua",
        ["Blizzard"] = "Blizzard.lua",
        ["ThirdParty"] = "AddOns.lua"
    }
    
    for moduleName, fileName in pairs(subModuleFiles) do
        -- Submodules are loaded via TOC, just validate they're available
        if DamiaUI.Skinning[moduleName] then
            subModules[moduleName] = DamiaUI.Skinning[moduleName]
            if subModules[moduleName].Initialize then
                local success = subModules[moduleName]:Initialize()
                if success then
                    DamiaUI:LogDebug("Initialized skinning submodule: " .. moduleName)
                else
                    DamiaUI:LogWarning("Failed to initialize skinning submodule: " .. moduleName)
                end
            end
        else
            DamiaUI:LogWarning("Skinning submodule not found: " .. moduleName)
        end
    end
    
    return true
end

function Skinning:ConfigureAurora()
    if not Aurora or not Aurora.Settings then
        return
    end
    
    -- Get current color scheme (including high contrast)
    local customColors = self:GetActiveColorScheme()
    
    -- Apply custom colors to Aurora
    if Aurora.Settings.customColors then
        Aurora.Settings.customColors = customColors
        Aurora.Settings.useCustomColors = true
    end
    
    -- Configure Aurora-specific settings for Damia UI
    if Aurora.Settings then
        Aurora.Settings.useButtonGradientColour = true
        Aurora.Settings.useClassColours = false
        Aurora.Settings.useChatBubbleSkin = true
        Aurora.Settings.useNormalTexture = false
    end
    
    DamiaUI:LogDebug("Aurora configured with Damia color scheme")
end

--[[
    Core Skinning System
]]

function Skinning:InitializeSkinning()
    if isInitialized then
        return
    end
    
    -- Load configuration
    self:LoadConfiguration()
    
    -- Setup advanced frame monitoring
    self:SetupAdvancedFrameMonitoring()
    
    -- Initialize skinning in priority order with proper delays
    self:ScheduleSkinningPhases()
    
    isInitialized = true
    DamiaUI:LogDebug("Comprehensive skinning system initialized")
end

function Skinning:LoadConfiguration()
    -- Load accessibility settings
    highContrastMode = DamiaUI.Config.Get("skinning.highContrastMode", false)
    
    -- Apply high contrast to submodules
    if subModules.Custom and subModules.Custom.SetHighContrastMode then
        subModules.Custom:SetHighContrastMode(highContrastMode)
    end
end

function Skinning:ScheduleSkinningPhases()
    -- Phase 1: Custom styling system (immediate)
    if DamiaUI.Config.Get("skinning.enabled", true) then
        self:InitializeCustomStyling()
    end
    
    -- Phase 2: Blizzard frames (delayed to avoid taint)
    if DamiaUI.Config.Get("skinning.blizzardFrames", true) then
        C_Timer.After(0.5, function()
            self:InitializeBlizzardSkinning()
        end)
    end
    
    -- Phase 3: DamiaUI frames 
    if DamiaUI.Config.Get("skinning.enabled", true) then
        C_Timer.After(1.0, function()
            self:SkinDamiaUIFrames()
        end)
    end
    
    -- Phase 4: Third-party addons (delayed for loading)
    if DamiaUI.Config.Get("skinning.thirdPartyFrames", true) then
        C_Timer.After(2.0, function()
            self:InitializeThirdPartySkinning()
        end)
    end
    
    -- Phase 5: Generic frame monitoring
    C_Timer.After(3.0, function()
        self:StartGenericFrameMonitoring()
    end)
end

function Skinning:InitializeCustomStyling()
    if not subModules.Custom then
        DamiaUI:LogWarning("Custom styling module not available")
        return
    end
    
    -- Custom styling is handled by the Custom submodule
    DamiaUI:LogDebug("Custom styling system ready")
end

function Skinning:InitializeBlizzardSkinning()
    if not subModules.Blizzard then
        DamiaUI:LogWarning("Blizzard skinning module not available")
        return
    end
    
    -- Use comprehensive Blizzard skinning module
    DamiaUI:LogDebug("Blizzard skinning system activated")
end

function Skinning:SkinSpecificBlizzardFrames()
    -- Skin frames that Aurora might miss or need custom handling
    local framesToSkin = {
        -- Character frame
        { frame = CharacterFrame, skinFunc = "FrameTypeFrame" },
        { frame = PaperDollFrame, skinFunc = "FrameTypeFrame" },
        
        -- Spellbook
        { frame = SpellBookFrame, skinFunc = "FrameTypeFrame" },
        
        -- Talent frame
        { frame = PlayerTalentFrame, skinFunc = "FrameTypeFrame" },
        
        -- Collections
        { frame = CollectionsJournal, skinFunc = "FrameTypeFrame" },
        
        -- Adventure guide
        { frame = EncounterJournal, skinFunc = "FrameTypeFrame" },
        
        -- Social frames
        { frame = FriendsFrame, skinFunc = "FrameTypeFrame" },
        { frame = GuildFrame, skinFunc = "FrameTypeFrame" },
        
        -- PvP frame
        { frame = PVPUIFrame, skinFunc = "FrameTypeFrame" },
        
        -- Quest log
        { frame = QuestLogFrame, skinFunc = "FrameTypeFrame" },
    }
    
    for _, frameInfo in ipairs(framesToSkin) do
        if frameInfo.frame then
            self:ApplyAuroraSkin(frameInfo.frame, frameInfo.skinFunc)
        end
    end
end

function Skinning:SkinDamiaUIFrames()
    -- Skin all DamiaUI module frames
    local modules = {
        "UnitFrames",
        "ActionBars", 
        "Interface",
        "Configuration"
    }
    
    for _, moduleName in ipairs(modules) do
        local module = DamiaUI:GetModule(moduleName)
        if module and module.ApplyAuroraSkin then
            module:ApplyAuroraSkin()
        end
    end
    
    DamiaUI:LogDebug("DamiaUI frames skinned")
end

function Skinning:InitializeThirdPartySkinning()
    if not subModules.ThirdParty then
        DamiaUI:LogWarning("Third-party skinning module not available")
        return
    end
    
    -- Third-party skinning is handled by the AddOns submodule
    DamiaUI:LogDebug("Third-party addon skinning system activated")
end

function Skinning:SkinAddonFrames(addonName, frameReference)
    local frames = {}
    
    if type(frameReference) == "string" then
        -- Single frame reference
        local frame = _G[frameReference]
        if frame then
            table.insert(frames, frame)
        end
    elseif type(frameReference) == "function" then
        -- Function that returns frame
        local frame = frameReference()
        if frame then
            table.insert(frames, frame)
        end
    elseif type(frameReference) == "table" then
        -- Multiple frames
        frames = frameReference
    end
    
    -- Skin the frames
    for _, frame in ipairs(frames) do
        if frame and not skinnedFrames[frame] then
            self:ApplyAuroraSkin(frame, "FrameTypeFrame")
            skinnedFrames[frame] = true
        end
    end
    
    if #frames > 0 then
        DamiaUI:LogDebug("Skinned " .. #frames .. " frames for addon: " .. addonName)
    end
end

--[[
    Frame Monitoring System
]]

function Skinning:SetupAdvancedFrameMonitoring()
    -- Create main monitoring frame
    monitorFrame = CreateFrame("Frame", "DamiaUISkinningMonitor")
    monitorFrame:RegisterEvent("ADDON_LOADED")
    monitorFrame:RegisterEvent("PLAYER_LOGIN")
    monitorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Set monitoring event handlers
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        Skinning:OnMonitorEvent(event, ...)
    end)
    
    DamiaUI:LogDebug("Advanced frame monitoring initialized")
end

function Skinning:StartGenericFrameMonitoring()
    -- Hook CreateFrame for dynamic frame detection
    local originalCreateFrame = CreateFrame
    CreateFrame = function(frameType, name, parent, template, id)
        local frame = originalCreateFrame(frameType, name, parent, template, id)
        
        -- Route to appropriate submodule for processing
        if frame and name then
            self:ProcessNewFrame(frame, frameType, name, parent)
        end
        
        return frame
    end
    
    -- Set up periodic processing of queued frames
    C_Timer.NewTicker(2, function()
        self:ProcessFrameQueue()
    end)
    
    DamiaUI:LogDebug("Generic frame monitoring started")
end

function Skinning:ProcessNewFrame(frame, frameType, name, parent)
    if not frame or skinnedFrames[frame] then
        return
    end
    
    -- Determine which submodule should handle this frame
    local targetModule = self:DetermineFrameModule(name, frameType, parent)
    
    if targetModule and subModules[targetModule] then
        -- Queue frame for appropriate submodule
        table.insert(framesToSkin, {
            frame = frame,
            frameType = frameType,
            name = name,
            targetModule = targetModule,
            timestamp = GetTime()
        })
    end
end

function Skinning:DetermineFrameModule(name, frameType, parent)
    if not name then
        return nil
    end
    
    -- Skip DamiaUI frames
    if name:match("^DamiaUI") then
        return nil
    end
    
    -- Blizzard frames
    if name:match("^Blizzard_") or name:match("^Interface") or 
       name:match("Frame$") or name:match("Panel$") then
        return "Blizzard"
    end
    
    -- Known third-party patterns
    local thirdPartyPatterns = {
        "^Recount", "^Details", "^Skada", "^WeakAuras", "^BigWigs",
        "^DBM", "^VuhDo", "^Auctionator", "^TSM", "^AllTheThings",
        "^Bartender", "^Dominos", "^TidyPlates", "^Prat", "^WIM"
    }
    
    for _, pattern in ipairs(thirdPartyPatterns) do
        if name:match(pattern) then
            return "ThirdParty"
        end
    end
    
    -- Default to custom styling for unknown frames
    return "Custom"
end

function Skinning:ShouldSkinFrame(frame, frameType, name, parent)
    if not frame or skinnedFrames[frame] then
        return false
    end
    
    -- Skip frames that shouldn't be skinned
    local skipPatterns = {
        "DamiaUI", -- Our own frames
        "Aurora",  -- Aurora frames
        "Tooltip", -- Tooltip frames
        "Minimap", -- Minimap related
    }
    
    if name then
        for _, pattern in ipairs(skipPatterns) do
            if name:match(pattern) then
                return false
            end
        end
    end
    
    -- Only skin certain frame types
    local skinnableTypes = {
        "Frame",
        "Button", 
        "CheckButton",
        "ScrollFrame",
        "EditBox",
        "StatusBar",
    }
    
    for _, skinnableType in ipairs(skinnableTypes) do
        if frameType == skinnableType then
            return true
        end
    end
    
    return false
end

function Skinning:ProcessFrameQueue()
    if #framesToSkin == 0 then
        return
    end
    
    local currentTime = GetTime()
    local processedCount = 0
    
    -- Process frames that have been in queue for at least 1 second
    for i = #framesToSkin, 1, -1 do
        local frameInfo = framesToSkin[i]
        
        if currentTime - frameInfo.timestamp >= 1.0 then
            if frameInfo.frame and not skinnedFrames[frameInfo.frame] then
                -- Route to appropriate submodule
                local success = self:RouteFrameToModule(frameInfo)
                if success then
                    skinnedFrames[frameInfo.frame] = true
                    processedCount = processedCount + 1
                end
            end
            
            table.remove(framesToSkin, i)
        end
    end
    
    if processedCount > 0 then
        DamiaUI:LogDebug("Processed " .. processedCount .. " queued frames via submodules")
    end
end

function Skinning:RouteFrameToModule(frameInfo)
    local targetModule = frameInfo.targetModule or "Custom"
    local module = subModules[targetModule]
    
    if not module then
        return false
    end
    
    -- Try module-specific skinning method
    if module.SkinFrame then
        return module:SkinFrame(frameInfo.frame)
    elseif module.ApplyGenericFrameSkin then
        return module:ApplyGenericFrameSkin(frameInfo.frame)
    elseif targetModule == "Custom" and module.ApplyPresetStyle then
        -- Use generic panel style for unknown frames
        return module:ApplyPresetStyle(frameInfo.frame, "panel")
    end
    
    return false
end

--[[
    Aurora Integration
]]

function Skinning:ApplyAuroraSkin(frame, skinFunction)
    if not Aurora or not Aurora.Skin or not frame then
        return false
    end
    
    skinFunction = skinFunction or "FrameTypeFrame"
    
    if not Aurora.Skin[skinFunction] then
        DamiaUI:LogWarning("Aurora skin function not found: " .. skinFunction)
        return false
    end
    
    local success, error = pcall(Aurora.Skin[skinFunction], frame)
    if not success then
        DamiaUI:LogError("Failed to apply Aurora skin: " .. tostring(error))
        return false
    end
    
    -- Mark frame as skinned
    skinnedFrames[frame] = true
    
    return true
end

function Skinning:CreateCustomBorder(frame, borderSize, borderColor)
    if not frame then
        return
    end
    
    borderSize = borderSize or 1
    borderColor = borderColor or DamiaUI.Config.Get("skinning.customColors.border")
    
    -- Create border frame
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderSize,
    })
    
    if borderColor then
        border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    end
    
    frame.DamiaUIBorder = border
    return border
end

function Skinning:CreateCustomBackground(frame, backgroundColor)
    if not frame then
        return
    end
    
    backgroundColor = backgroundColor or DamiaUI.Config.Get("skinning.customColors.background")
    
    -- Create background texture
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    
    if backgroundColor then
        background:SetVertexColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
    end
    
    frame.DamiaUIBackground = background
    return background
end

--[[
    Configuration Handlers
]]

function Skinning:OnConfigChanged(key, oldValue, newValue)
    local parts = DamiaUI.Config.ParseKey(key)
    if #parts < 2 then
        return
    end
    
    local setting = parts[2]
    
    if setting == "enabled" then
        if newValue then
            self:InitializeSkinning()
        else
            self:DisableSkinning()
        end
    elseif setting == "customColors" then
        self:ConfigureAurora()
        self:RefreshAllSkins()
    elseif setting == "highContrastMode" then
        self:SetHighContrastMode(newValue)
    elseif setting == "blizzardFrames" then
        if newValue and subModules.Blizzard then
            self:InitializeBlizzardSkinning()
        end
    elseif setting == "thirdPartyFrames" then
        if newValue and subModules.ThirdParty then
            self:InitializeThirdPartySkinning()
        end
    end
end

function Skinning:OnAccessibilityChanged(setting, value)
    if setting == "highContrast" then
        self:SetHighContrastMode(value)
    elseif setting == "fontSize" then
        self:UpdateFontSizes(value)
    elseif setting == "colorBlindMode" then
        self:SetColorBlindMode(value)
    end
end

function Skinning:GetActiveColorScheme()
    local colors = {}
    
    if highContrastMode then
        -- Use high contrast colors
        colors.background = DAMIA_COLORS.hcBackground
        colors.border = DAMIA_COLORS.hcBorder
        colors.accent = DAMIA_COLORS.hcAccent
        colors.text = DAMIA_COLORS.hcText
    else
        -- Use standard Damia colors
        colors.background = DAMIA_COLORS.background
        colors.border = DAMIA_COLORS.border
        colors.accent = DAMIA_COLORS.accent
        colors.text = DAMIA_COLORS.text
    end
    
    -- Apply any custom color overrides from config
    local customColors = DamiaUI.Config.Get("skinning.customColors", {})
    for colorName, color in pairs(customColors) do
        colors[colorName] = color
    end
    
    return colors
end

function Skinning:SetHighContrastMode(enabled)
    if highContrastMode == enabled then
        return
    end
    
    highContrastMode = enabled
    DamiaUI.Config.Set("skinning.highContrastMode", enabled)
    
    -- Update submodules
    if subModules.Custom and subModules.Custom.SetHighContrastMode then
        subModules.Custom:SetHighContrastMode(enabled)
    end
    
    -- Reconfigure Aurora
    self:ConfigureAurora()
    
    -- Refresh all skins
    self:RefreshAllSkins()
    
    DamiaUI:LogDebug("High contrast mode " .. (enabled and "enabled" or "disabled"))
end

function Skinning:UpdateFontSizes(multiplier)
    multiplier = multiplier or 1.0
    
    -- Update font sizes across all submodules
    for moduleName, module in pairs(subModules) do
        if module.UpdateFontSizes then
            module:UpdateFontSizes(multiplier)
        end
    end
    
    DamiaUI:LogDebug("Font sizes updated with multiplier: " .. multiplier)
end

function Skinning:SetColorBlindMode(enabled)
    -- Implementation for color blind accessibility
    if enabled then
        -- Adjust colors for better accessibility
        DAMIA_COLORS.accent = { r = 0.0, g = 0.6, b = 1.0, a = 1.0 } -- Blue instead of orange
    else
        -- Restore original orange accent
        DAMIA_COLORS.accent = { r = 0.8, g = 0.5, b = 0.1, a = 1.0 }
    end
    
    -- Reconfigure and refresh
    self:ConfigureAurora()
    self:RefreshAllSkins()
    
    DamiaUI:LogDebug("Color blind mode " .. (enabled and "enabled" or "disabled"))
end

function Skinning:RefreshAllSkins()
    -- Clear skinned frames cache
    table.wipe(skinnedFrames)
    
    -- Refresh submodules
    for moduleName, module in pairs(subModules) do
        if module.RefreshAllSkins then
            module:RefreshAllSkins()
        elseif module.RefreshAllCustomStyles then
            module:RefreshAllCustomStyles()
        end
    end
    
    -- Re-initialize skinning after short delay
    C_Timer.After(0.5, function()
        if isInitialized then
            self:ScheduleSkinningPhases()
        end
    end)
    
    DamiaUI:LogDebug("All skins refreshed")
end

function Skinning:DisableSkinning()
    -- This would remove all custom skinning
    -- Implementation depends on whether Aurora supports unskinning
    DamiaUI:LogInfo("Skinning disabled - UI reload recommended")
end

--[[
    Event Handlers
]]

function Skinning:OnMonitorEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        
        -- Check if this is a known addon that needs skinning
        if ADDON_SKINNING_MAP[addonName] then
            C_Timer.After(1, function()
                self:SkinAddonFrames(addonName, ADDON_SKINNING_MAP[addonName])
            end)
        end
    end
end

function Skinning:ADDON_LOADED(event, loadedAddon)
    if loadedAddon == addonName then
        -- Main addon loaded
    end
end

function Skinning:PLAYER_LOGIN()
    -- Initialize skinning system after login
    C_Timer.After(2, function()
        if not isInitialized then
            self:InitializeSkinning()
        end
    end)
end

--[[
    Public API
]]

--[[
    Enhanced Public API
]]

-- Manually skin a frame using appropriate submodule
function Skinning:SkinFrame(frame, stylePreset, options)
    if not frame then
        return false
    end
    
    -- Determine best submodule for this frame
    local frameName = frame:GetName() or ""
    local targetModule = self:DetermineFrameModule(frameName, frame:GetObjectType())
    
    if targetModule and subModules[targetModule] then
        if targetModule == "Custom" and subModules.Custom.ApplyPresetStyle then
            return subModules.Custom:ApplyPresetStyle(frame, stylePreset or "panel", options)
        elseif subModules[targetModule].SkinFrame then
            return subModules[targetModule]:SkinFrame(frame)
        end
    end
    
    -- Fallback to legacy method
    return self:ApplyAuroraSkin(frame, "FrameTypeFrame")
end

-- Create custom styled frame using preset
function Skinning:CreateStyledFrame(frameType, name, parent, stylePreset, options)
    if not subModules.Custom then
        return CreateFrame(frameType, name, parent)
    end
    
    local frame = CreateFrame(frameType, name, parent)
    subModules.Custom:ApplyPresetStyle(frame, stylePreset or "panel", options)
    
    return frame
end

-- Check if frame is already skinned
function Skinning:IsFrameSkinned(frame)
    return skinnedFrames[frame] == true
end

-- Get comprehensive skinning statistics
function Skinning:GetSkinnedFrames()
    local stats = {
        total = 0,
        byModule = {}
    }
    
    for frame, _ in pairs(skinnedFrames) do
        stats.total = stats.total + 1
    end
    
    -- Get stats from submodules
    for moduleName, module in pairs(subModules) do
        if module.GetSkinnedFrameCount then
            stats.byModule[moduleName] = module:GetSkinnedFrameCount()
        elseif module.GetSkinnedAddonCount then
            stats.byModule[moduleName] = module:GetSkinnedAddonCount()
        elseif module.GetStyledFrameCount then
            stats.byModule[moduleName] = module:GetStyledFrameCount()
        end
    end
    
    return stats
end

-- Add frame to monitoring queue with target module
function Skinning:QueueFrameForSkinning(frame, targetModule)
    if frame and not skinnedFrames[frame] then
        table.insert(framesToSkin, {
            frame = frame,
            frameType = frame:GetObjectType(),
            name = frame:GetName(),
            targetModule = targetModule or self:DetermineFrameModule(frame:GetName() or "", frame:GetObjectType()),
            timestamp = GetTime()
        })
    end
end

-- High-level styling functions
function Skinning:StyleUnitFrame(frame, options)
    if subModules.Custom and subModules.Custom.CreateUnitFrameStyle then
        return subModules.Custom:CreateUnitFrameStyle(frame, options)
    end
    return false
end

function Skinning:StyleActionButton(frame, options)
    if subModules.Custom and subModules.Custom.CreateActionButtonStyle then
        return subModules.Custom:CreateActionButtonStyle(frame, options)
    end
    return false
end

function Skinning:StylePanel(frame, options)
    if subModules.Custom and subModules.Custom.CreatePanelStyle then
        return subModules.Custom:CreatePanelStyle(frame, options)
    end
    return false
end

function Skinning:StyleTooltip(frame, options)
    if subModules.Custom and subModules.Custom.CreateTooltipStyle then
        return subModules.Custom:CreateTooltipStyle(frame, options)
    end
    return false
end

-- Accessibility functions
function Skinning:IsHighContrastMode()
    return highContrastMode
end

function Skinning:GetAvailableColorSchemes()
    return {
        "standard",
        "highContrast",
        "colorBlindFriendly",
        "custom"
    }
end

-- Submodule access
function Skinning:GetSubModule(moduleName)
    return subModules[moduleName]
end

function Skinning:GetAvailableSubModules()
    local modules = {}
    for moduleName in pairs(subModules) do
        table.insert(modules, moduleName)
    end
    return modules
end

-- Register the main module
DamiaUI:RegisterModule("Skinning", Skinning)