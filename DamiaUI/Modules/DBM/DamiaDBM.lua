-- DamiaDBM - Standalone DBM Skin for DamiaUI-V2 
-- Updated from ColdDBM for WoW 11.2 compatibility
-- Credits to Wildbreath and Haleth for original ColdDBM

-- Configuration
local config = {
    leftIcon = true,        -- Show left icon with backdrop
    rightIcon = false,      -- Show right icon with backdrop  
    barHeight = 8,         -- Height of timer bars
    iconSize = 22,         -- Size of icons (not used in positioning but available)
    iconSpacing = 4,       -- Space between icons and bar
    fontOutline = "OUTLINEMONOCHROME",
    fontSize = 10,
    timerFontSize = 10,
    nameJustifyH = "LEFT",
    timerJustifyH = "RIGHT",
    
    -- Media paths using DamiaUI-V2 structure
    barTexture = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\flat2.tga",
    backdropTexture = "Interface\\AddOns\\DamiaUI\\Media\\Textures\\flat2.tga", 
    font = "Interface\\AddOns\\DamiaUI\\Media\\Fonts\\homespun.ttf",
    
    -- Colors
    backdropColor = {0.2, 0.2, 0.2, 0.6},
    borderColor = {0, 0, 0, 1},
    iconBackdropColor = {0.2, 0.2, 0.2, 0.6},
    iconBorderColor = {0, 0, 0, 1},
}

-- Track processed frames to avoid double-processing
local processedFrames = {}

-- Main hook function for CreateFrame - WoW 11.2 compatible
hooksecurefunc('CreateFrame', function(frameType, frameName, parent, template, ...)
    -- Only process DBM bar template frames
    if template ~= 'DBTBarTemplate' or not frameName then
        return
    end
    
    -- Avoid double processing
    if processedFrames[frameName] then
        return
    end
    
    -- Use C_Timer for delayed processing to ensure frame is fully created
    C_Timer.After(0.1, function()
        ProcessDBMBar(frameName)
    end)
    
    processedFrames[frameName] = true
end)

-- Main function to process and style a DBM bar
function ProcessDBMBar(frameName)
    local frame = _G[frameName]
    if not frame then
        return
    end
    
    -- Get child elements with proper error checking
    local bar = _G[frameName .. "Bar"]
    local spark = _G[frameName .. "BarSpark"] 
    local texture = _G[frameName .. "BarTexture"]
    local icon1 = _G[frameName .. "BarIcon1"] 
    local icon2 = _G[frameName .. "BarIcon2"]
    local nameText = _G[frameName .. "BarName"]
    local timerText = _G[frameName .. "BarTimer"]
    
    if not bar then
        return
    end
    
    -- Apply bar styling
    ApplyBarStyle(bar, texture, spark)
    
    -- Apply text styling  
    ApplyTextStyle(nameText, timerText, bar)
    
    -- Apply icon styling
    ApplyIconStyle(icon1, icon2, frame, bar)
    
    -- Create backdrops using WoW 11.2 BackdropTemplate
    CreateBarBackdrop(bar)
end

-- Apply styling to the main bar
function ApplyBarStyle(bar, texture, spark)
    if not bar then return end
    
    -- Set bar dimensions
    bar:SetHeight(config.barHeight)
    bar:SetFrameLevel(1)
    
    -- Style bar texture
    if texture then
        texture:SetTexture(config.barTexture)
        -- Prevent DBM from overriding our texture
        texture.SetTexture = function() end
    end
    
    -- Hide spark effect
    if spark then
        spark:SetAlpha(0)
        spark.SetAlpha = function() end
    end
end

-- Apply styling to text elements
function ApplyTextStyle(nameText, timerText, bar)
    if nameText then
        -- Position and style name text
        nameText:ClearAllPoints()
        nameText:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 3)
        nameText:SetFont(config.font, config.fontSize, config.fontOutline)
        nameText:SetShadowColor(0, 0, 0, 0)
        nameText:SetJustifyH(config.nameJustifyH)
        
        -- Prevent DBM from overriding our font
        nameText.SetFont = function() end
    end
    
    if timerText then
        -- Position and style timer text
        timerText:ClearAllPoints()
        timerText:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 3)
        timerText:SetFont(config.font, config.timerFontSize, config.fontOutline)
        timerText:SetShadowColor(0, 0, 0, 0)
        timerText:SetJustifyH(config.timerJustifyH)
        
        -- Prevent DBM from overriding our font
        timerText.SetFont = function() end
    end
end

-- Apply styling to icons
function ApplyIconStyle(icon1, icon2, frame, bar)
    -- Style left icon
    if icon1 and config.leftIcon then
        StyleSingleIcon(icon1, frame, bar, "left")
    end
    
    -- Style right icon  
    if icon2 and config.rightIcon then
        StyleSingleIcon(icon2, frame, bar, "right")
    end
end

-- Style a single icon
function StyleSingleIcon(icon, frame, bar, side)
    if not icon then return end
    
    -- Set icon texture coordinates (crop edges)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:ClearAllPoints()
    
    -- Position based on side
    if side == "left" then
        icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -config.iconSpacing, 6)
    else -- right
        icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", config.iconSpacing, 6)
    end
    
    -- Create backdrop for icon
    CreateIconBackdrop(icon, bar)
end

-- Create backdrop for the main bar using WoW 11.2 BackdropTemplate
function CreateBarBackdrop(bar)
    if not bar or bar.DamiaDBMBackdrop then
        return -- Already has backdrop
    end
    
    -- Create backdrop frame using BackdropTemplate for WoW 11.2 compatibility
    local backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    backdrop:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    backdrop:SetFrameLevel(0)
    
    -- Set backdrop using WoW 11.2 compatible method
    backdrop:SetBackdrop({
        bgFile = config.backdropTexture,
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    
    -- Apply colors
    backdrop:SetBackdropBorderColor(unpack(config.borderColor))
    backdrop:SetBackdropColor(unpack(config.backdropColor))
    
    -- Store reference to prevent recreation
    bar.DamiaDBMBackdrop = backdrop
end

-- Create backdrop for icons using WoW 11.2 BackdropTemplate
function CreateIconBackdrop(icon, bar)
    if not icon or icon.DamiaDBMBackdrop then
        return -- Already has backdrop
    end
    
    -- Create backdrop frame using BackdropTemplate for WoW 11.2 compatibility
    local backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    backdrop:SetPoint("TOPRIGHT", icon, 1, 1)
    backdrop:SetPoint("BOTTOMLEFT", icon, -1, -1)
    backdrop:SetFrameLevel(0)
    
    -- Set backdrop using WoW 11.2 compatible method
    backdrop:SetBackdrop({
        bgFile = config.backdropTexture,
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1,
    })
    
    -- Apply colors
    backdrop:SetBackdropBorderColor(unpack(config.iconBorderColor))
    backdrop:SetBackdropColor(unpack(config.iconBackdropColor))
    
    -- Store reference to prevent recreation
    icon.DamiaDBMBackdrop = backdrop
end

-- Debug function to manually process existing bars
function DamiaDBM_ProcessExistingBars()
    print("DamiaDBM: Processing existing bars...")
    
    local processed = 0
    -- Check for existing DBM bars (they usually start with "DBT")
    for i = 1, 100 do
        local patterns = {"DBTBar", "DBT_Bar", "DBMBar", "DBM_Bar"}
        for _, pattern in ipairs(patterns) do
            local frameName = pattern .. i
            local frame = _G[frameName]
            if frame and not processedFrames[frameName] then
                ProcessDBMBar(frameName)
                processed = processed + 1
            end
        end
    end
    
    print("DamiaDBM: Processed " .. processed .. " existing bars")
end

-- Slash command for debugging
SLASH_DAMIADBM1 = "/damiadbm"
SlashCmdList["DAMIADBM"] = function(msg)
    local cmd = msg:lower():trim()
    
    if cmd == "process" or cmd == "reload" then
        DamiaDBM_ProcessExistingBars()
    elseif cmd == "status" then
        print("DamiaDBM Status:")
        print("  Left Icon: " .. (config.leftIcon and "Enabled" or "Disabled"))
        print("  Right Icon: " .. (config.rightIcon and "Enabled" or "Disabled"))
        print("  Bar Height: " .. config.barHeight)
        print("  Font Size: " .. config.fontSize)
        print("  Processed Frames: " .. #processedFrames)
    elseif cmd == "config" then
        print("DamiaDBM Configuration:")
        for k, v in pairs(config) do
            if type(v) ~= "table" then
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    else
        print("DamiaDBM Commands:")
        print("  /damiadbm process - Process existing bars")
        print("  /damiadbm status - Show status")
        print("  /damiadbm config - Show configuration")
    end
end

-- Initialize on load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "DamiaDBM" then
        print("|cff00FF7FDamiaDBM|r loaded successfully! Use /damiadbm for commands.")
        
        -- Process any existing bars after a short delay
        C_Timer.After(2, function()
            DamiaDBM_ProcessExistingBars()
        end)
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

print("DamiaDBM: Hook installed, waiting for DBM bars...")