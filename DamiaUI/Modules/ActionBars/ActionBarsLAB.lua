-- DamiaUI Action Bars Module with LibActionButton-1.0
-- Based on ColdBars, updated for WoW 11.2 with LAB

local addonName, ns = ...
local LibStub = _G.LibStub
local LAB = LibStub("LibActionButton-1.0")

local ActionBars = {}
ns.ActionBars = ActionBars

-- Module configuration
ActionBars.bars = {}
ActionBars.buttons = {}

-- Initialize module
function ActionBars:Initialize()
    -- Get config
    self.config = ns.config.actionbar
    
    if not self.config or not self.config.enabled then
        return
    end
    
    -- Setup LibActionButton callbacks
    self:SetupLABCallbacks()
    
    -- Create bars
    self:CreateMainBar()
    self:CreateBar2()
    self:CreateBar3()
    self:CreateBar4()
    self:CreateBar5()
    self:CreatePetBar()
    self:CreateStanceBar()
    self:CreateExtraBar()
    
    -- Setup paging
    self:SetupPaging()
    
    -- Register events
    self:RegisterEvents()
    
    ns:Print("Action Bars module loaded with LibActionButton")
end

-- Setup LibActionButton callbacks
function ActionBars:SetupLABCallbacks()
    -- Style callback
    LAB.RegisterCallback(self, "OnButtonCreated", function(_, button)
        self:StyleButton(button)
    end)
    
    -- Update callback
    LAB.RegisterCallback(self, "OnButtonUpdate", function(_, button)
        self:UpdateButton(button)
    end)
    
    -- State callback
    LAB.RegisterCallback(self, "OnButtonState", function(_, button, state)
        self:UpdateButtonState(button, state)
    end)
    
    -- Usable callback
    LAB.RegisterCallback(self, "OnButtonUsable", function(_, button)
        self:UpdateButtonUsable(button)
    end)
end

-- Style button
function ActionBars:StyleButton(button)
    local name = button:GetName()
    
    -- Remove default textures
    local normal = button:GetNormalTexture()
    if normal then normal:SetTexture(nil) end
    
    -- Icon
    local icon = button.icon
    if icon then
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Count
    local count = button.Count
    if count then
        count:SetFont(ns.media.font, 12, "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Hotkey
    local hotkey = button.HotKey
    if hotkey then
        hotkey:SetFont(ns.media.font, 11, "OUTLINE")
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        if self.config.showkeybind ~= 1 then
            hotkey:Hide()
        end
    end
    
    -- Macro name
    local name = button.Name
    if name then
        name:SetFont(ns.media.font, 10, "OUTLINE")
        name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        if self.config.showmacro ~= 1 then
            name:Hide()
        end
    end
    
    -- Border
    local border = button.Border
    if border then
        border:SetTexture(ns.media.outerShadow)
        border:SetVertexColor(0, 1, 0, 0.3)
    end
    
    -- Cooldown
    local cooldown = button.cooldown
    if cooldown then
        cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        cooldown:SetDrawBling(false)
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
    end
    
    -- Flash
    local flash = button.Flash
    if flash then
        flash:SetTexture(ns.media.buttonBackground)
        flash:SetVertexColor(1, 0, 0, 0.3)
    end
    
    -- Pushed texture
    button:SetPushedTexture(ns.media.buttonBackground)
    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    end
    
    -- Highlight texture
    button:SetHighlightTexture(ns.media.buttonBackground)
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetVertexColor(1, 1, 1, 0.3)
    end
    
    -- Checked texture
    button:SetCheckedTexture(ns.media.buttonBackground)
    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetVertexColor(1, 1, 1, 0.3)
    end
    
    -- Normal texture (background)
    button:SetNormalTexture(ns.media.buttonBackground)
    local normalNew = button:GetNormalTexture()
    if normalNew then
        normalNew:SetVertexColor(0.3, 0.3, 0.3)
        normalNew:SetAllPoints()
    end
    
    -- Create backdrop
    if not button.backdrop then
        button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.backdrop:SetPoint("TOPLEFT", -3, 3)
        button.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
        button.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
        ns:CreateBackdrop(button.backdrop)
    end
end

-- Update button
function ActionBars:UpdateButton(button)
    -- Grid visibility
    if self.config.showgrid == 1 then
        button:SetAlpha(1)
    else
        if button:IsEmpty() then
            button:SetAlpha(0)
        else
            button:SetAlpha(1)
        end
    end
end

-- Update button state
function ActionBars:UpdateButtonState(button, state)
    -- Handle state changes
end

-- Update button usability
function ActionBars:UpdateButtonUsable(button)
    local icon = button.icon
    if not icon then return end
    
    local isUsable, notEnoughMana = button:IsUsable()
    if notEnoughMana then
        icon:SetVertexColor(0.1, 0.3, 1)
    elseif not isUsable then
        icon:SetDesaturated(true)
    else
        icon:SetDesaturated(false)
        
        -- Range check
        local inRange = button:IsInRange()
        if inRange == false then
            icon:SetVertexColor(0.8, 0.1, 0.1)
        else
            icon:SetVertexColor(1, 1, 1)
        end
    end
end

-- Create main action bar using LAB
function ActionBars:CreateMainBar()
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIMainBar", UIParent, "SecureHandlerStateTemplate")
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    -- Position
    if self.config.mainbar and self.config.mainbar.pos then
        bar:SetPoint(unpack(self.config.mainbar.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 30)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons using LibActionButton
    for i = 1, 12 do
        local button = LAB:CreateButton(i, "DamiaUIActionButton"..i, bar)
        button:SetSize(self.config.size, self.config.size)
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[i-1], "RIGHT", self.config.spacing, 0)
        end
        
        -- Set state (for paging)
        button:SetState(0, "action", i)
        
        -- Store button reference
        self.buttons[i] = button
    end
    
    -- Paging setup
    local paging = {
        "[bar:2] 2",
        "[bar:3] 3",
        "[bar:4] 4",
        "[bar:5] 5",
        "[bar:6] 6",
        "[bonusbar:1] 7",
        "[bonusbar:2] 8",
        "[bonusbar:3] 9",
        "[bonusbar:4] 10",
        "[bonusbar:5] 11",
        "1",
    }
    
    -- Class-specific paging
    local _, class = UnitClass("player")
    if class == "DRUID" then
        paging = {
            "[bonusbar:1,nostealth] 7",
            "[bonusbar:1,stealth] 8",
            "[bonusbar:2] 9",
            "[bonusbar:3] 10",
            "[bonusbar:4] 11",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "ROGUE" then
        paging = {
            "[bonusbar:1] 7",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "WARRIOR" then
        paging = {
            "[stance:1] 7",
            "[stance:2] 8",
            "[stance:3] 9",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "PRIEST" then
        paging = {
            "[bonusbar:1] 7",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "MONK" then
        paging = {
            "[stance:1] 7",
            "[stance:2] 8",
            "[stance:3] 9",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "DEMONHUNTER" then
        paging = {
            "[bonusbar:1] 7",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "EVOKER" then
        paging = {
            "[bonusbar:1] 7",
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    end
    
    -- Apply paging to buttons
    bar:SetAttribute("_onstate-page", [[
        self:SetAttribute("state", newstate)
        control:ChildUpdate("state", newstate)
    ]])
    
    RegisterStateDriver(bar, "page", table.concat(paging, "; "))
    
    -- Apply state changes to buttons
    for i = 1, 12 do
        bar:SetFrameRef("button"..i, self.buttons[i])
        bar:Execute([[
            buttons = newtable()
            for i = 1, 12 do
                buttons[i] = self:GetFrameRef("button"..i)
            end
        ]])
        
        -- Update button states
        bar:SetAttribute("_onstate-page", [[
            local newstate = tonumber(newstate) or 1
            for i = 1, 12 do
                buttons[i]:SetAttribute("action", (newstate - 1) * 12 + i)
            end
        ]])
    end
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.mainbar = bar
    
    return bar
end

-- Create Bar 2 using LAB
function ActionBars:CreateBar2()
    if not self.config.bar2 or not self.config.bar2.enable then
        return
    end
    
    local bar = CreateFrame("Frame", "DamiaUIBar2", UIParent)
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    if self.config.bar2 and self.config.bar2.pos then
        bar:SetPoint(unpack(self.config.bar2.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 70)
    end
    
    bar:SetScale(self.config.scale or 1)
    
    for i = 1, 12 do
        local id = i + 12
        local button = LAB:CreateButton(id, "DamiaUIBar2Button"..i, bar)
        button:SetSize(self.config.size, self.config.size)
        
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[id-1], "RIGHT", self.config.spacing, 0)
        end
        
        button:SetState(0, "action", id)
        self.buttons[id] = button
    end
    
    ns:MakeMovable(bar, true)
    self.bars.bar2 = bar
    
    return bar
end

-- Create Bar 3 using LAB
function ActionBars:CreateBar3()
    if not self.config.bar3 or not self.config.bar3.enable then
        return
    end
    
    local bar = CreateFrame("Frame", "DamiaUIBar3", UIParent)
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    if self.config.bar3 and self.config.bar3.pos then
        bar:SetPoint(unpack(self.config.bar3.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 110)
    end
    
    bar:SetScale(self.config.scale or 1)
    
    for i = 1, 12 do
        local id = i + 24
        local button = LAB:CreateButton(id, "DamiaUIBar3Button"..i, bar)
        button:SetSize(self.config.size, self.config.size)
        
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[id-1], "RIGHT", self.config.spacing, 0)
        end
        
        button:SetState(0, "action", id)
        self.buttons[id] = button
    end
    
    ns:MakeMovable(bar, true)
    self.bars.bar3 = bar
    
    return bar
end

-- Create Bar 4 (vertical right)
function ActionBars:CreateBar4()
    if not self.config.bar4 or not self.config.bar4.enable then
        return
    end
    
    local bar = CreateFrame("Frame", "DamiaUIBar4", UIParent)
    
    if self.config.bar4.orientation == "VERTICAL" then
        bar:SetSize(self.config.size, self.config.size * 12 + self.config.spacing * 11)
    else
        bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    end
    
    if self.config.bar4 and self.config.bar4.pos then
        bar:SetPoint(unpack(self.config.bar4.pos))
    else
        bar:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
    end
    
    bar:SetScale(self.config.scale or 1)
    
    for i = 1, 12 do
        local id = i + 36
        local button = LAB:CreateButton(id, "DamiaUIBar4Button"..i, bar)
        button:SetSize(self.config.size, self.config.size)
        
        if i == 1 then
            if self.config.bar4.orientation == "VERTICAL" then
                button:SetPoint("TOP", bar, "TOP", 0, 0)
            else
                button:SetPoint("LEFT", bar, "LEFT", 0, 0)
            end
        else
            if self.config.bar4.orientation == "VERTICAL" then
                button:SetPoint("TOP", self.buttons[id-1], "BOTTOM", 0, -self.config.spacing)
            else
                button:SetPoint("LEFT", self.buttons[id-1], "RIGHT", self.config.spacing, 0)
            end
        end
        
        button:SetState(0, "action", id)
        self.buttons[id] = button
    end
    
    ns:MakeMovable(bar, true)
    self.bars.bar4 = bar
    
    return bar
end

-- Create Bar 5 (vertical right)
function ActionBars:CreateBar5()
    if not self.config.bar5 or not self.config.bar5.enable then
        return
    end
    
    local bar = CreateFrame("Frame", "DamiaUIBar5", UIParent)
    
    if self.config.bar5.orientation == "VERTICAL" then
        bar:SetSize(self.config.size, self.config.size * 12 + self.config.spacing * 11)
    else
        bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    end
    
    if self.config.bar5 and self.config.bar5.pos then
        bar:SetPoint(unpack(self.config.bar5.pos))
    else
        bar:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
    end
    
    bar:SetScale(self.config.scale or 1)
    
    for i = 1, 12 do
        local id = i + 48
        local button = LAB:CreateButton(id, "DamiaUIBar5Button"..i, bar)
        button:SetSize(self.config.size, self.config.size)
        
        if i == 1 then
            if self.config.bar5.orientation == "VERTICAL" then
                button:SetPoint("TOP", bar, "TOP", 0, 0)
            else
                button:SetPoint("LEFT", bar, "LEFT", 0, 0)
            end
        else
            if self.config.bar5.orientation == "VERTICAL" then
                button:SetPoint("TOP", self.buttons[id-1], "BOTTOM", 0, -self.config.spacing)
            else
                button:SetPoint("LEFT", self.buttons[id-1], "RIGHT", self.config.spacing, 0)
            end
        end
        
        button:SetState(0, "action", id)
        self.buttons[id] = button
    end
    
    ns:MakeMovable(bar, true)
    self.bars.bar5 = bar
    
    return bar
end

-- Placeholder functions for other bars
function ActionBars:CreatePetBar()
    -- TODO: Implement pet bar with LAB
end

function ActionBars:CreateStanceBar()
    -- TODO: Implement stance bar with LAB
end

function ActionBars:CreateExtraBar()
    -- TODO: Implement extra action bar
end

function ActionBars:SetupPaging()
    -- Paging is handled in CreateMainBar
end

function ActionBars:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    
    frame:SetScript("OnEvent", function(self, event)
        -- Handle combat lockdown
    end)
end

-- Register with main addon
ns:RegisterModule("ActionBars", ActionBars)