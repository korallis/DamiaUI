local _, DamiaUI = ...

-- =============================================================================
-- ACTION BARS MODULE
-- =============================================================================
-- Follows GW2_UI patterns:
-- 1. Style existing buttons, not recreate them
-- 2. Use clean, minimal design with 1px borders
-- 3. Hide ALL Blizzard bar frames completely
-- 4. Hook into existing functionality instead of replacing
-- 5. Handle range indicators and cooldowns properly

local ActionBars = DamiaUI:CreateModule("ActionBars")

-- Constants
local BUTTON_SIZE = 36
local BUTTON_SPACING = 2
local MAIN_BAR_Y_OFFSET = 34 -- slightly above bottom to mirror screenshots

-- Frame names to hide from Blizzard UI
local BLIZZARD_HIDE_FRAME_NAMES = {
    "MainMenuBar",
    "MainMenuBarOverlayFrame", 
    "MainMenuBarTexture0",
    "MainMenuBarTexture1",
    "MainMenuBarTexture2",
    "MainMenuBarTexture3",
    "ReputationWatchBar",
    "HonorWatchBar",
    "ArtifactWatchBar", 
    "MainMenuExpBar",
    "ActionBarUpButton",
    "ActionBarDownButton",
    "MainMenuBarPageNumber",
    "MainMenuMaxLevelBar0",
    "MainMenuMaxLevelBar1",
    "MainMenuMaxLevelBar2", 
    "MainMenuMaxLevelBar3",
    "VerticalMultiBarsContainer",
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Hide Blizzard action bar elements
local function HideBlizzardActionBars()
    for _, frameName in pairs(BLIZZARD_HIDE_FRAME_NAMES) do
        local frame = _G[frameName]
        if frame then
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            if frame.UnregisterAllEvents then
                frame:UnregisterAllEvents()
            end
            if frame.Hide then
                frame:Hide()
            end
        end
    end
    
    -- Disable main menu bar mouse interaction
    local mainMenuBar = _G["MainMenuBar"]
    if mainMenuBar then
        mainMenuBar:EnableMouse(false)
        mainMenuBar:SetMovable(true)
        mainMenuBar:SetUserPlaced(true)
        mainMenuBar:SetMovable(false)
        mainMenuBar.ignoreFramePositionManager = true
    end
end

-- Create clean backdrop for action buttons
local function CreateButtonBackdrop(button)
    if button.DamiaBackdrop then
        return button.DamiaBackdrop
    end
    
    local backdrop = DamiaUI:CreateBackdropFrame(nil, button)
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(button:GetFrameLevel())
    
    -- Create background texture
    local bg = backdrop:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    -- Dark translucent background
    bg:SetColorTexture(unpack(DamiaUI.Theme.panelBg))
    backdrop.bg = bg
    
    -- Create 1px borders
    local borderColor = DamiaUI.Theme.border
    
    -- Top border
    local topBorder = backdrop:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT")
    topBorder:SetPoint("TOPRIGHT")
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(unpack(borderColor))
    
    -- Bottom border  
    local bottomBorder = backdrop:CreateTexture(nil, "BORDER")
    bottomBorder:SetPoint("BOTTOMLEFT")
    bottomBorder:SetPoint("BOTTOMRIGHT")
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(unpack(borderColor))
    
    -- Left border
    local leftBorder = backdrop:CreateTexture(nil, "BORDER")
    leftBorder:SetPoint("TOPLEFT")
    leftBorder:SetPoint("BOTTOMLEFT")
    leftBorder:SetWidth(1)
    leftBorder:SetColorTexture(unpack(borderColor))
    
    -- Right border
    local rightBorder = backdrop:CreateTexture(nil, "BORDER")
    rightBorder:SetPoint("TOPRIGHT")
    rightBorder:SetPoint("BOTTOMRIGHT") 
    rightBorder:SetWidth(1)
    rightBorder:SetColorTexture(unpack(borderColor))
    
    backdrop.borders = {topBorder, bottomBorder, leftBorder, rightBorder}
    
    button.DamiaBackdrop = backdrop
    return backdrop
end

-- Style an action button with clean, minimal design
local function StyleActionButton(button, buttonName)
    if not button or button.DamiaStyled then
        return
    end
    
    -- Set button size
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    
    -- Create backdrop
    CreateButtonBackdrop(button)
    
    -- Style icon with trimmed edges (same as GW2_UI)
    if button.icon then
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    
    -- Style cooldown
    if button.cooldown then
        button.cooldown:ClearAllPoints()
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.6)
        button.cooldown:SetDrawEdge(false)
        
        -- Style cooldown text
        if button.cooldown.text then
            DamiaUI:SetFont(button.cooldown.text, DamiaUI.DefaultFonts.number, 11, "OUTLINE")
            button.cooldown.text:SetTextColor(1, 1, 1)
        end
    end
    
    -- Style count text
    if button.Count then
        button.Count:ClearAllPoints()
        button.Count:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        DamiaUI:SetFont(button.Count, DamiaUI.DefaultFonts.number, 11, "OUTLINE")
        button.Count:SetTextColor(1, 1, 0.6)
        button.Count:SetJustifyH("RIGHT")
    end
    
    -- Style hotkey text
    if button.HotKey then
        button.HotKey:ClearAllPoints()
        button.HotKey:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
        button.HotKey:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        DamiaUI:SetFont(button.HotKey, DamiaUI.DefaultFonts.normal, 10, "OUTLINE")
        button.HotKey:SetTextColor(1, 1, 1)
        button.HotKey:SetJustifyH("CENTER")
    end
    
    -- Style macro name
    if button.Name then
        button.Name:ClearAllPoints()
        button.Name:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.Name:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        DamiaUI:SetFont(button.Name, DamiaUI.DefaultFonts.normal, 10, "OUTLINE")
        button.Name:SetTextColor(1, 1, 1)
        button.Name:SetJustifyH("LEFT")
        button.Name:SetAlpha(0.8)
    end
    
    -- Clean up Blizzard textures
    if button.NormalTexture then
        button.NormalTexture:SetTexture(nil)
        button.NormalTexture:SetAlpha(0)
    end
    
    if button.FloatingBG then
        button.FloatingBG:SetTexture(nil)
    end
    
    -- Clean pressed and highlight textures - use subtle effects
    button:SetPushedTexture("")
    button:SetHighlightTexture("")
    
    -- Create subtle highlight effect
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)
    button:SetHighlightTexture(highlight)
    
    -- Remove border art and slot art
    if button.Border then
        button.Border:SetTexture(nil)
        button.Border:SetAlpha(0)
    end
    
    if button.SlotArt then
        button.SlotArt:SetTexture(nil)
        button.SlotArt:SetAlpha(0)
    end
    
    if button.SlotBackground then
        button.SlotBackground:SetAlpha(0)
    end
    
    -- Remove icon mask for clean look
    if button.IconMask and button.icon then
        button.icon:RemoveMaskTexture(button.IconMask)
    end
    
    -- Store original vertex color for range indication
    if button.icon then
        button.icon.originalVertexColor = {button.icon:GetVertexColor()}
        
        -- Hook vertex color changes for range indication
        hooksecurefunc(button.icon, "SetVertexColor", function(self, r, g, b, a)
            if not self.rangeColorOverride then
                self.originalVertexColor = {r or 1, g or 1, b or 1, a or 1}
            end
        end)
    end
    
    button.DamiaStyled = true
end

-- Handle range indication with red tint
local function UpdateButtonRange(button)
    if not button or not button.action or not button.icon or not IsActionInRange then
        return
    end
    
    local valid = IsActionInRange(button.action)
    local checksRange = (valid ~= nil)
    local inRange = checksRange and valid
    
    if checksRange and not inRange then
        -- Out of range - apply red tint
        button.icon.rangeColorOverride = true
        button.icon:SetVertexColor(1, 0.2, 0.2, 1)
    else
        -- In range or doesn't check range - restore original color
        button.icon.rangeColorOverride = false
        if button.icon.originalVertexColor then
            button.icon:SetVertexColor(unpack(button.icon.originalVertexColor))
        else
            button.icon:SetVertexColor(1, 1, 1, 1)
        end
    end
end

-- =============================================================================
-- MAIN BAR CREATION
-- =============================================================================

-- Create and position the main action bar
local function CreateMainActionBar()
    -- Create container frame for main bar
    local mainBar = DamiaUI:CreateBorderedPanel("DamiaMainActionBar", UIParent)
    mainBar:SetFrameStrata("LOW")
    mainBar:SetFrameLevel(10)
    
    -- Position at bottom center
    local totalWidth = (BUTTON_SIZE * 12) + (BUTTON_SPACING * 11)
    mainBar:SetSize(totalWidth + 12, BUTTON_SIZE + 6)
    mainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, MAIN_BAR_Y_OFFSET)
    
    -- Store buttons for reference
    mainBar.buttons = {}
    
    -- Style existing action buttons 1-12
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:SetParent(mainBar)
            StyleActionButton(button, "ActionButton" .. i)
            
            -- Position button
            local xOffset = 6 + (i - 1) * (BUTTON_SIZE + BUTTON_SPACING)
            button:ClearAllPoints()
            button:SetPoint("LEFT", mainBar, "LEFT", xOffset, 0)
            
            mainBar.buttons[i] = button
            
            -- Disable default OnUpdate handler
            button:SetScript("OnUpdate", nil)
        end
    end
    
    return mainBar
end

-- =============================================================================
-- RANGE UPDATE SYSTEM
-- =============================================================================

-- Range update handler
local rangeUpdateFrame = CreateFrame("Frame")
local rangeTimer = 0
local RANGE_UPDATE_INTERVAL = 0.1

rangeUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    rangeTimer = rangeTimer + elapsed
    if rangeTimer >= RANGE_UPDATE_INTERVAL then
        rangeTimer = 0
        
        -- Update main action bar range indicators
        if ActionBars.mainBar then
            for i = 1, 12 do
                local button = ActionBars.mainBar.buttons[i]
                if button and button:IsVisible() then
                    UpdateButtonRange(button)
                end
            end
        end
    end
end)

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Handle action bar events
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "DamiaUI" then
            self:UnregisterEvent("ADDON_LOADED")
            ActionBars:Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-style buttons after entering world (some may not exist during ADDON_LOADED)
        C_Timer.After(1, function()
            ActionBars:RefreshActionButtons()
        end)
    elseif event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
        ActionBars:UpdateGridVisibility()
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
        ActionBars:UpdateCooldowns()
    end
end

-- =============================================================================
-- MODULE METHODS
-- =============================================================================

-- Initialize the action bars module
function ActionBars:Initialize()
    DamiaUI:Print("Initializing Action Bars...")
    
    -- Hide Blizzard action bars first
    HideBlizzardActionBars()
    
    -- Create our main action bar
    self.mainBar = CreateMainActionBar()
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", OnEvent)
    DamiaUI:RegisterFrameEvents(eventFrame, {
        "PLAYER_ENTERING_WORLD",
        "ACTIONBAR_SHOWGRID",
        "ACTIONBAR_HIDEGRID",
        "ACTIONBAR_UPDATE_COOLDOWN",
        "UPDATE_BINDINGS",
    })
    
    self.eventFrame = eventFrame
    
    DamiaUI:Print("Action Bars initialized")
end

-- Refresh action button styling
function ActionBars:RefreshActionButtons()
    if self.mainBar then
        for i = 1, 12 do
            local button = _G["ActionButton" .. i]
            if button then
                -- Force re-style the button
                button.DamiaStyled = false
                StyleActionButton(button, "ActionButton" .. i)
            end
        end
    end
end

-- Update grid visibility
function ActionBars:UpdateGridVisibility()
    if not self.mainBar or not HasAction then return end
    
    for i = 1, 12 do
        local button = self.mainBar.buttons[i]
        if button and button.DamiaBackdrop and button.action then
            local hasAction = HasAction(button.action)
            if hasAction then
                button.DamiaBackdrop:SetAlpha(1)
            else
                button.DamiaBackdrop:SetAlpha(0.3)
            end
        end
    end
end

-- Update cooldown displays
function ActionBars:UpdateCooldowns()
    if not self.mainBar then return end
    
    for i = 1, 12 do
        local button = self.mainBar.buttons[i]
        if button and button.cooldown and button.Update then
            button:Update()
        end
    end
end

-- Enable or disable the action bars
function ActionBars:SetEnabled(enabled)
    if self.mainBar then
        if enabled then
            self.mainBar:Show()
            if self.eventFrame then
                self.eventFrame:SetScript("OnEvent", OnEvent)
            end
        else
            self.mainBar:Hide()
            if self.eventFrame then
                self.eventFrame:SetScript("OnEvent", nil)
            end
        end
    end
end

-- =============================================================================
-- MODULE REGISTRATION
-- =============================================================================

-- Register event for initialization
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", OnEvent)

-- Register the module with DamiaUI
DamiaUI.modules.ActionBars = ActionBars

DamiaUI:Print("ActionBars module loaded")