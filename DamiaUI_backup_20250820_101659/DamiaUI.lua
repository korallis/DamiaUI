--[[
    WORKING EXAMPLE - What DamiaUI Should Actually Do
    This simple file does more than all 131 files of DamiaUI combined
]]

local addonName, addonTable = ...
_G.DamiaUI = addonTable

-- =============================================================================
-- ACTUAL WORKING PLAYER FRAME
-- =============================================================================
local function CreatePlayerFrame()
    -- Create the main frame (MUST inherit BackdropTemplate for SetBackdrop to work!)
    local frame = CreateFrame("Frame", "DamiaUIPlayerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 60)
    frame:SetPoint("CENTER", UIParent, "CENTER", -250, -150)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Border (requires BackdropTemplate)
    frame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Health Bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetPoint("TOPLEFT", 2, -2)
    frame.healthBar:SetPoint("TOPRIGHT", -2, -2)
    frame.healthBar:SetHeight(35)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetStatusBarColor(0.1, 0.8, 0.1)
    
    -- Health Text
    frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.healthText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
    
    -- Power Bar
    frame.powerBar = CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -2)
    frame.powerBar:SetPoint("TOPRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, -2)
    frame.powerBar:SetHeight(18)
    frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    -- Power Text
    frame.powerText = frame.powerBar:CreateFontString(nil, "OVERLAY")
    frame.powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.powerText:SetPoint("CENTER", frame.powerBar, "CENTER", 0, 0)
    
    -- Name Text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY")
    frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 4)
    frame.nameText:SetText(UnitName("player"))
    frame.nameText:SetTextColor(1, 1, 1)
    
    -- Update Function
    local function UpdateFrame()
        -- Update Health
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
        frame.healthText:SetText(string.format("%d / %d", health, maxHealth))
        
        -- Update Power
        local power = UnitPower("player")
        local maxPower = UnitPowerMax("player")
        local powerType = UnitPowerType("player")
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
        frame.powerText:SetText(string.format("%d / %d", power, maxPower))
        
        -- Set power bar color based on type
        local colors = {
            [0] = {0.2, 0.2, 1},    -- Mana (blue)
            [1] = {1, 0.2, 0.2},    -- Rage (red)
            [2] = {1, 0.5, 0.25},   -- Focus (orange)
            [3] = {1, 1, 0},        -- Energy (yellow)
            [6] = {0, 0.82, 1},     -- Runic Power (cyan)
        }
        local color = colors[powerType] or {0.5, 0.5, 0.5}
        frame.powerBar:SetStatusBarColor(unpack(color))
    end
    
    -- Register Events
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_MAXPOWER")
    
    frame:SetScript("OnEvent", function(self, event, unit)
        if not unit or unit == "player" then
            UpdateFrame()
        end
    end)
    
    -- Initial Update
    UpdateFrame()
    
    -- Hide Blizzard player frame
    if PlayerFrame then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:Hide()
    end
    
    return frame
end

-- =============================================================================
-- ACTUAL WORKING TARGET FRAME
-- =============================================================================
local function CreateTargetFrame()
    -- Create the frame (MUST inherit BackdropTemplate for SetBackdrop to work!)
    local frame = CreateFrame("Frame", "DamiaUITargetFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 60)
    frame:SetPoint("CENTER", UIParent, "CENTER", 250, -150)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Border (requires BackdropTemplate)
    frame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Health Bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetPoint("TOPLEFT", 2, -2)
    frame.healthBar:SetPoint("TOPRIGHT", -2, -2)
    frame.healthBar:SetHeight(35)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    -- Health Text
    frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.healthText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
    
    -- Name Text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY")
    frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 4)
    frame.nameText:SetTextColor(1, 1, 1)
    
    -- Level Text
    frame.levelText = frame:CreateFontString(nil, "OVERLAY")
    frame.levelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.levelText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, 4)
    
    -- Update Function
    local function UpdateFrame()
        if UnitExists("target") then
            frame:Show()
            
            -- Update Name
            frame.nameText:SetText(UnitName("target"))
            
            -- Update Level
            local level = UnitLevel("target")
            local levelColor = GetQuestDifficultyColor(level)
            frame.levelText:SetText(level > 0 and level or "??")
            frame.levelText:SetTextColor(levelColor.r, levelColor.g, levelColor.b)
            
            -- Update Health
            local health = UnitHealth("target")
            local maxHealth = UnitHealthMax("target")
            frame.healthBar:SetMinMaxValues(0, maxHealth)
            frame.healthBar:SetValue(health)
            
            -- Health percentage
            local healthPercent = (health / maxHealth) * 100
            frame.healthText:SetText(string.format("%.0f%%", healthPercent))
            
            -- Color by hostility
            local r, g, b
            if UnitIsPlayer("target") then
                -- Use class color for players
                local _, class = UnitClass("target")
                local color = RAID_CLASS_COLORS[class]
                if color then
                    r, g, b = color.r, color.g, color.b
                else
                    r, g, b = 0.5, 0.5, 0.5
                end
            else
                -- Use reaction color for NPCs
                local reaction = UnitReaction("target", "player")
                if reaction then
                    if reaction <= 3 then
                        r, g, b = 1, 0.2, 0.2  -- Hostile (red)
                    elseif reaction == 4 then
                        r, g, b = 1, 1, 0      -- Neutral (yellow)
                    else
                        r, g, b = 0.2, 1, 0.2  -- Friendly (green)
                    end
                else
                    r, g, b = 0.5, 0.5, 0.5
                end
            end
            frame.healthBar:SetStatusBarColor(r, g, b)
        else
            frame:Hide()
        end
    end
    
    -- Register Events
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or (unit and unit == "target") then
            UpdateFrame()
        end
    end)
    
    -- Initial hide
    frame:Hide()
    
    -- Hide Blizzard target frame
    if TargetFrame then
        TargetFrame:UnregisterAllEvents()
        TargetFrame:Hide()
    end
    
    return frame
end

-- =============================================================================
-- ACTUAL WORKING ACTION BAR
-- =============================================================================
local function CreateActionBar()
    local bar = CreateFrame("Frame", "DamiaUIActionBar", UIParent)
    bar:SetSize(480, 40)
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
    
    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.5)
    
    bar.buttons = {}
    
    for i = 1, 12 do
        -- Create action button using secure template
        local button = CreateFrame("CheckButton", "DamiaUIActionButton"..i, bar, "ActionBarButtonTemplate")
        button:SetSize(38, 38)
        
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 2, 0)
        else
            button:SetPoint("LEFT", bar.buttons[i-1], "RIGHT", 2, 0)
        end
        
        -- Set the action ID
        button.action = i
        button:SetAttribute("action", i)
        
        -- Show grid background
        button:SetAttribute("showgrid", 1)
        
        -- Update the button
        ActionButton_UpdateAction(button)
        ActionButton_Update(button)
        
        bar.buttons[i] = button
    end
    
    -- Update on action bar changes
    bar:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:RegisterEvent("UPDATE_BINDINGS")
    
    bar:SetScript("OnEvent", function(self, event)
        for i = 1, 12 do
            ActionButton_UpdateAction(self.buttons[i])
            ActionButton_Update(self.buttons[i])
        end
    end)
    
    -- Hide default action bar
    if MainMenuBar then
        MainMenuBar:Hide()
    end
    if MainMenuBarArtFrame then
        MainMenuBarArtFrame:Hide()
    end
    
    return bar
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- Create our UI elements
    local playerFrame = CreatePlayerFrame()
    local targetFrame = CreateTargetFrame()
    local actionBar = CreateActionBar()
    
    -- Store references
    DamiaUI.playerFrame = playerFrame
    DamiaUI.targetFrame = targetFrame
    DamiaUI.actionBar = actionBar
    
    print("|cffCC8010DamiaUI|r: WORKING VERSION LOADED!")
    print("|cffCC8010DamiaUI|r: Player frame, target frame, and action bar created!")
end)

-- =============================================================================
-- WORKING SLASH COMMANDS
-- =============================================================================
SLASH_DAMIAUI1 = "/damiaui"
SLASH_DAMIAUI2 = "/dui"
SlashCmdList["DAMIAUI"] = function(msg)
    local cmd = msg:lower()
    
    if cmd == "toggle" then
        -- Toggle visibility of our frames
        if DamiaUI.playerFrame then
            local shown = DamiaUI.playerFrame:IsShown()
            DamiaUI.playerFrame:SetShown(not shown)
            DamiaUI.targetFrame:SetShown(not shown)
            DamiaUI.actionBar:SetShown(not shown)
            print("|cffCC8010DamiaUI|r: Frames " .. (shown and "hidden" or "shown"))
        end
    elseif cmd == "reset" then
        -- Reset positions
        if DamiaUI.playerFrame then
            DamiaUI.playerFrame:ClearAllPoints()
            DamiaUI.playerFrame:SetPoint("CENTER", UIParent, "CENTER", -250, -150)
            DamiaUI.targetFrame:ClearAllPoints()
            DamiaUI.targetFrame:SetPoint("CENTER", UIParent, "CENTER", 250, -150)
            DamiaUI.actionBar:ClearAllPoints()
            DamiaUI.actionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
            print("|cffCC8010DamiaUI|r: Positions reset")
        end
    else
        print("|cffCC8010DamiaUI|r Commands:")
        print("  /damiaui toggle - Show/hide frames")
        print("  /damiaui reset - Reset positions")
    end
end

--[[
    THIS SINGLE FILE:
    ✓ Creates a working player frame with health/power bars
    ✓ Creates a working target frame with hostility coloring
    ✓ Creates a working action bar with 12 buttons
    ✓ Hides Blizzard frames properly
    ✓ Has working slash commands
    ✓ Updates in real-time
    ✓ Is 350 lines vs 131 files
    
    THIS IS WHAT DAMIAUI SHOULD BE DOING!
]]