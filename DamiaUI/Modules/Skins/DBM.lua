-- DamiaUI DBM Skin Module
-- Based on ColdDBM, modernized for WoW 11.2 and integrated with DamiaUI
-- Auto-detects DBM and applies consistent DamiaUI theming

local addonName, ns = ...
local DBMSkin = {}
ns.DBMSkin = DBMSkin

-- Configuration with enhanced options
DBMSkin.config = {
    enabled = true,
    leftIcon = true,        -- Show left icon with backdrop
    rightIcon = false,      -- Show right icon with backdrop
    barHeight = 8,         -- Height of timer bars
    iconSize = 22,         -- Size of icons
    iconSpacing = 4,       -- Space between icons and bar
    fontOutline = "OUTLINEMONOCHROME",
    fontSize = 10,
    timerFontSize = 10,
    nameJustifyH = "LEFT", -- Name text alignment
    timerJustifyH = "RIGHT", -- Timer text alignment
    barTexture = ns.media.texture,
    backdropTexture = ns.media.texture,
    font = ns.media.font,
    colors = {
        backdrop = {0.2, 0.2, 0.2, 0.6},
        border = {0, 0, 0, 1},
        iconBackdrop = {0.2, 0.2, 0.2, 0.6},
        iconBorder = {0, 0, 0, 1},
    }
}

-- DBM detection flags
DBMSkin.dbmDetected = false
DBMSkin.dbmLoaded = false
DBMSkin.skinApplied = false

-- Hooked functions table to prevent multiple hooks
DBMSkin.hookedFunctions = {}

-- Initialize module
function DBMSkin:Initialize()
    -- Get config from DamiaUI
    if ns.config and ns.config.dbmSkin then
        for k, v in pairs(ns.config.dbmSkin) do
            if DBMSkin.config[k] ~= nil then
                DBMSkin.config[k] = v
            end
        end
    end
    
    if not self.config.enabled then
        ns:Debug("DBM Skin module disabled in config")
        return
    end
    
    -- Check if DBM is already loaded
    self:CheckDBM()
    
    -- Set up event monitoring for addon loading
    self:RegisterEvents()
    
    ns:Print("DBM Skin module initialized")
end

-- Register events for DBM detection
function DBMSkin:RegisterEvents()
    -- Create event frame if it doesn't exist
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame", "DamiaUIDBMSkinEvents")
    end
    
    -- Register for addon loaded events
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            
            -- Check for various DBM addons
            if loadedAddon:find("^DBM") then
                ns:Debug("DBM addon detected:", loadedAddon)
                self:CheckDBM()
            end
        elseif event == "PLAYER_LOGIN" then
            -- Final check after all addons are loaded
            C_Timer.After(2, function()
                self:CheckDBM()
            end)
        end
    end)
end

-- Check if DBM is available and apply skin
function DBMSkin:CheckDBM()
    -- Check for DBM-Core
    if not IsAddOnLoaded("DBM-Core") then
        ns:Debug("DBM-Core not loaded")
        return
    end
    
    -- Check for DBM global
    if not DBM then
        ns:Debug("DBM global not available")
        return
    end
    
    -- Check for DBM-StatusBarTimers (needed for bar templates)
    if not IsAddOnLoaded("DBM-StatusBarTimers") then
        ns:Debug("DBM-StatusBarTimers not loaded")
        return
    end
    
    self.dbmDetected = true
    self.dbmLoaded = true
    
    ns:Print("DBM detected, applying DamiaUI skin...")
    
    -- Apply skin immediately if not already applied
    if not self.skinApplied then
        self:ApplySkin()
    end
end

-- Main skin application function
function DBMSkin:ApplySkin()
    if self.skinApplied then
        ns:Debug("DBM skin already applied")
        return
    end
    
    -- Hook CreateFrame to catch DBM bar creation
    self:HookCreateFrame()
    
    -- Hook existing bars if any
    self:SkinExistingBars()
    
    -- Hook DBM bar creation functions if available
    self:HookDBMFunctions()
    
    self.skinApplied = true
    ns:Print("DBM skin applied successfully")
end

-- Hook CreateFrame to catch new DBM bars
function DBMSkin:HookCreateFrame()
    if self.hookedFunctions.CreateFrame then
        return -- Already hooked
    end
    
    -- Store original CreateFrame
    local originalCreateFrame = CreateFrame
    
    -- Hook CreateFrame securely
    hooksecurefunc('CreateFrame', function(frameType, frameName, parent, template)
        -- Only process frames with DBT template
        if template == 'DBTBarTemplate' and frameName then
            -- Use a timer to allow the frame to be fully created
            C_Timer.After(0.1, function()
                self:SkinDBMBar(frameName)
            end)
        end
    end)
    
    self.hookedFunctions.CreateFrame = true
    ns:Debug("CreateFrame hooked for DBM bar detection")
end

-- Skin existing DBM bars
function DBMSkin:SkinExistingBars()
    -- Look for existing DBM bars (they usually start with "DBT")
    for i = 1, 100 do -- Check first 100 possible bars
        local barName = "DBTBar" .. i
        local bar = _G[barName]
        if bar then
            self:SkinDBMBar(barName)
        end
    end
    
    -- Also check for alternate naming patterns
    for i = 1, 50 do
        local patterns = {
            "DBT_Bar" .. i,
            "DBMBar" .. i,
            "DBM_Bar" .. i
        }
        
        for _, pattern in ipairs(patterns) do
            local bar = _G[pattern]
            if bar then
                self:SkinDBMBar(pattern)
            end
        end
    end
end

-- Hook DBM-specific functions if available
function DBMSkin:HookDBMFunctions()
    -- Try to hook DBM's bar creation functions
    if DBT and DBT.CreateBar and not self.hookedFunctions.DBTCreateBar then
        hooksecurefunc(DBT, "CreateBar", function(...)
            C_Timer.After(0.1, function()
                -- Re-scan for new bars
                self:SkinExistingBars()
            end)
        end)
        self.hookedFunctions.DBTCreateBar = true
        ns:Debug("DBT.CreateBar hooked")
    end
    
    -- Hook DBM bar template functions
    if DBM and DBM.Bars and DBM.Bars.CreateBar and not self.hookedFunctions.DBMCreateBar then
        hooksecurefunc(DBM.Bars, "CreateBar", function(...)
            C_Timer.After(0.1, function()
                self:SkinExistingBars()
            end)
        end)
        self.hookedFunctions.DBMCreateBar = true
        ns:Debug("DBM.Bars.CreateBar hooked")
    end
end

-- Main function to skin a specific DBM bar
function DBMSkin:SkinDBMBar(frameName)
    local frame = _G[frameName]
    if not frame then
        ns:Debug("Frame not found:", frameName)
        return
    end
    
    -- Skip if already skinned
    if frame.DamiaUISkinned then
        return
    end
    
    ns:Debug("Skinning DBM bar:", frameName)
    
    -- Get child elements
    local bar = _G[frameName .. "Bar"]
    local spark = _G[frameName .. "BarSpark"] 
    local texture = _G[frameName .. "BarTexture"]
    local icon1 = _G[frameName .. "BarIcon1"] 
    local icon2 = _G[frameName .. "BarIcon2"]
    local nameText = _G[frameName .. "BarName"]
    local timerText = _G[frameName .. "BarTimer"]
    
    if not bar then
        ns:Debug("Bar child not found for:", frameName)
        return
    end
    
    -- Style the main bar
    self:StyleBar(bar, texture, spark)
    
    -- Style text elements
    self:StyleBarText(nameText, timerText, bar)
    
    -- Style icons
    self:StyleIcons(icon1, icon2, frame, bar)
    
    -- Create backdrop
    self:CreateBarBackdrop(bar)
    
    -- Mark as skinned to prevent re-skinning
    frame.DamiaUISkinned = true
    
    ns:Debug("Successfully skinned DBM bar:", frameName)
end

-- Style the main bar
function DBMSkin:StyleBar(bar, texture, spark)
    if not bar then return end
    
    -- Set bar height
    bar:SetHeight(self.config.barHeight)
    bar:SetFrameLevel(1)
    
    -- Style bar texture
    if texture then
        texture:SetTexture(self.config.barTexture)
        
        -- Prevent DBM from overriding our texture
        texture.SetTexture = function() end
    end
    
    -- Hide/disable spark
    if spark then
        spark:SetAlpha(0)
        spark.SetAlpha = function() end
    end
end

-- Style bar text elements
function DBMSkin:StyleBarText(nameText, timerText, bar)
    if nameText then
        -- Position name text
        nameText:ClearAllPoints()
        nameText:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 3)
        
        -- Style name text
        nameText:SetFont(self.config.font, self.config.fontSize, self.config.fontOutline)
        nameText:SetShadowColor(0, 0, 0, 0)
        nameText:SetJustifyH(self.config.nameJustifyH)
        
        -- Prevent DBM from overriding our font
        nameText.SetFont = function() end
    end
    
    if timerText then
        -- Position timer text
        timerText:ClearAllPoints()
        timerText:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 3)
        
        -- Style timer text
        timerText:SetFont(self.config.font, self.config.timerFontSize, self.config.fontOutline)
        timerText:SetShadowColor(0, 0, 0, 0)
        timerText:SetJustifyH(self.config.timerJustifyH)
        
        -- Prevent DBM from overriding our font
        timerText.SetFont = function() end
    end
end

-- Style icons with backdrops
function DBMSkin:StyleIcons(icon1, icon2, frame, bar)
    -- Style left icon
    if icon1 and self.config.leftIcon then
        self:StyleSingleIcon(icon1, frame, bar, "left")
    end
    
    -- Style right icon  
    if icon2 and self.config.rightIcon then
        self:StyleSingleIcon(icon2, frame, bar, "right")
    end
end

-- Style a single icon
function DBMSkin:StyleSingleIcon(icon, frame, bar, side)
    if not icon then return end
    
    -- Set icon texture coordinates
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:ClearAllPoints()
    
    -- Position based on side
    if side == "left" then
        icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -self.config.iconSpacing, 6)
    else -- right
        icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", self.config.iconSpacing, 6)
    end
    
    -- Create backdrop for icon
    self:CreateIconBackdrop(icon, bar)
end

-- Create backdrop for the main bar
function DBMSkin:CreateBarBackdrop(bar)
    if not bar or bar.DamiaUIBackdrop then
        return -- Already has backdrop
    end
    
    -- Create backdrop frame using WoW 11.2 BackdropTemplate
    local backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    backdrop:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    backdrop:SetFrameLevel(0)
    
    -- Set backdrop
    backdrop:SetBackdrop({
        bgFile = self.config.backdropTexture,
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    
    -- Apply colors
    local colors = self.config.colors
    backdrop:SetBackdropBorderColor(unpack(colors.border))
    backdrop:SetBackdropColor(unpack(colors.backdrop))
    
    bar.DamiaUIBackdrop = backdrop
end

-- Create backdrop for icons
function DBMSkin:CreateIconBackdrop(icon, bar)
    if not icon or icon.DamiaUIBackdrop then
        return -- Already has backdrop
    end
    
    -- Create backdrop frame
    local backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    backdrop:SetPoint("TOPRIGHT", icon, 1, 1)
    backdrop:SetPoint("BOTTOMLEFT", icon, -1, -1)
    backdrop:SetFrameLevel(0)
    
    -- Set backdrop
    backdrop:SetBackdrop({
        bgFile = self.config.backdropTexture,
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1,
    })
    
    -- Apply colors
    local colors = self.config.colors
    backdrop:SetBackdropBorderColor(unpack(colors.iconBorder))
    backdrop:SetBackdropColor(unpack(colors.iconBackdrop))
    
    icon.DamiaUIBackdrop = backdrop
end

-- Enable the module
function DBMSkin:Enable()
    if not self.config.enabled then
        self.config.enabled = true
        
        -- Save to config
        if ns.config then
            if not ns.config.dbmSkin then
                ns.config.dbmSkin = {}
            end
            ns.config.dbmSkin.enabled = true
        end
        
        -- Re-initialize
        self:Initialize()
    end
end

-- Disable the module
function DBMSkin:Disable()
    if self.config.enabled then
        self.config.enabled = false
        
        -- Save to config
        if ns.config then
            if not ns.config.dbmSkin then
                ns.config.dbmSkin = {}
            end
            ns.config.dbmSkin.enabled = false
        end
        
        -- Unregister events
        if self.eventFrame then
            self.eventFrame:UnregisterAllEvents()
        end
        
        -- Note: We can't easily remove the skins from existing bars
        -- A UI reload would be needed for complete removal
        ns:Print("DBM Skin disabled (UI reload recommended)")
    end
end

-- Update configuration
function DBMSkin:UpdateConfig(newConfig)
    if not newConfig then return end
    
    for key, value in pairs(newConfig) do
        if self.config[key] ~= nil then
            self.config[key] = value
        end
    end
    
    -- Save to DamiaUI config
    if ns.config then
        if not ns.config.dbmSkin then
            ns.config.dbmSkin = {}
        end
        for key, value in pairs(self.config) do
            ns.config.dbmSkin[key] = value
        end
    end
    
    -- Re-apply skin to existing bars if DBM is loaded
    if self.dbmLoaded and self.skinApplied then
        -- Clear skinned flags to allow re-skinning
        for i = 1, 100 do
            local barName = "DBTBar" .. i
            local frame = _G[barName]
            if frame then
                frame.DamiaUISkinned = nil
            end
        end
        
        -- Re-skin
        self:SkinExistingBars()
    end
    
    ns:Print("DBM Skin configuration updated")
end

-- Get current status
function DBMSkin:GetStatus()
    return {
        enabled = self.config.enabled,
        dbmDetected = self.dbmDetected,
        dbmLoaded = self.dbmLoaded,
        skinApplied = self.skinApplied,
        hookedFunctions = self.hookedFunctions
    }
end

-- Debug function to manually trigger skin application
function DBMSkin:ForceSkin()
    ns:Print("Forcing DBM skin application...")
    
    -- Reset flags
    self.skinApplied = false
    
    -- Clear existing skinned markers
    for i = 1, 100 do
        local patterns = {"DBTBar", "DBT_Bar", "DBMBar", "DBM_Bar"}
        for _, pattern in ipairs(patterns) do
            local frame = _G[pattern .. i]
            if frame then
                frame.DamiaUISkinned = nil
            end
        end
    end
    
    -- Re-apply
    self:ApplySkin()
end

-- Slash command integration
function DBMSkin:HandleSlashCommand(args)
    local cmd = args:lower():trim()
    
    if cmd == "status" then
        local status = self:GetStatus()
        ns:Print("DBM Skin Status:")
        print("  Enabled:", status.enabled and "Yes" or "No")
        print("  DBM Detected:", status.dbmDetected and "Yes" or "No") 
        print("  DBM Loaded:", status.dbmLoaded and "Yes" or "No")
        print("  Skin Applied:", status.skinApplied and "Yes" or "No")
        print("  Hooked Functions:", #status.hookedFunctions)
    elseif cmd == "enable" then
        self:Enable()
        ns:Print("DBM Skin enabled")
    elseif cmd == "disable" then
        self:Disable()
    elseif cmd == "force" or cmd == "reload" then
        self:ForceSkin()
    elseif cmd == "config" then
        ns:Print("DBM Skin Configuration:")
        print("  Left Icon:", self.config.leftIcon and "Yes" or "No")
        print("  Right Icon:", self.config.rightIcon and "Yes" or "No")
        print("  Bar Height:", self.config.barHeight)
        print("  Font Size:", self.config.fontSize)
        print("  Timer Font Size:", self.config.timerFontSize)
    else
        ns:Print("DBM Skin Commands:")
        print("  /dui dbm status - Show status")
        print("  /dui dbm enable - Enable skin")
        print("  /dui dbm disable - Disable skin") 
        print("  /dui dbm force - Force re-skin")
        print("  /dui dbm config - Show configuration")
    end
end

-- Register module with DamiaUI
ns:RegisterModule("DBMSkin", DBMSkin)