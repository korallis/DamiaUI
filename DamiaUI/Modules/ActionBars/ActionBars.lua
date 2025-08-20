-- DamiaUI Action Bars Module
-- Rewritten for WoW 11.2 using LibActionButton-1.0

local addonName, ns = ...
local ActionBars = {}
ns.ActionBars = ActionBars

-- Get LibActionButton-1.0
local LAB = LibStub("LibActionButton-1.0-ElvUI")
if not LAB then
    print("[DamiaUI] ERROR: LibActionButton-1.0 not found!")
    return
end

-- Module configuration
ActionBars.bars = {}
ActionBars.buttons = {}
ActionBars.buttonsLAB = {}

-- ColdUI styling configuration
local BUTTON_SIZE = 28
local BUTTON_SPACING = 0  -- Shows as 2px visual gap due to backdrop
local BACKDROP_PADDING = 4

-- Initialize module
function ActionBars:Initialize()
    print("[DEBUG] ActionBars:Initialize() called")
    
    -- Get config
    self.config = ns.config.actionbar
    print("[DEBUG] ActionBars config retrieved: " .. tostring(self.config ~= nil))
    
    if not self.config then
        print("[DEBUG] ActionBars: No config found, returning")
        return
    end
    
    if not self.config.enabled then
        print("[DEBUG] ActionBars: Module disabled in config, returning")
        return
    end
    
    print("[DEBUG] ActionBars: Config enabled, proceeding with initialization")
    
    -- Initialize bars
    self:CreateMainBar()
    self:CreateBar2()
    self:CreateBar3()
    self:CreateBar4()
    self:CreateBar5()
    self:CreatePetBar()
    self:CreateStanceBar()
    self:CreateExtraBar()
    
    -- Setup visibility and paging
    self:SetupVisibility()
    
    print("[DEBUG] ActionBars: Initialization completed successfully")
    ns:Print("Action Bars module loaded")
end

-- Create LibActionButton-1.0 button
function ActionBars:CreateLABButton(id, parent, barName)
    local buttonName = "DamiaUILAB" .. barName .. "Button" .. id
    
    -- Create the button using LibActionButton
    local button = LAB:CreateButton(id, buttonName, parent, self.config)
    
    if not button then
        print("[DEBUG] Failed to create LAB button: " .. buttonName)
        return nil
    end
    
    -- Set size
    local size = self.config.size or BUTTON_SIZE
    button:SetSize(size, size)
    
    -- Apply ColdUI styling
    self:StyleLABButton(button)
    
    -- Store reference
    self.buttonsLAB[buttonName] = button
    
    print("[DEBUG] Created LAB button: " .. buttonName)
    return button
end

-- Apply ColdUI styling to LAB button
function ActionBars:StyleLABButton(button)
    if not button then return end
    
    -- Hide default textures we'll replace
    if button.NormalTexture then
        button.NormalTexture:SetTexture(nil)
    end
    
    -- ColdUI backdrop
    if not button.bg then
        button.bg = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.bg:SetPoint("TOPLEFT", button, "TOPLEFT", -BACKDROP_PADDING, BACKDROP_PADDING)
        button.bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", BACKDROP_PADDING, -BACKDROP_PADDING)
        button.bg:SetFrameLevel(button:GetFrameLevel() - 1)
        button.bg:SetBackdrop({
            bgFile = ns.media.buttonBackgroundFlat,
            tile = false,
            tileSize = 32,
            edgeSize = 5,
            insets = {left = 5, right = 5, top = 5.5, bottom = 5},
        })
        button.bg:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
        button.bg:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    -- Apply ColdUI textures
    button:SetNormalTexture(ns.media.gloss)
    local normal = button:GetNormalTexture()
    if normal then
        normal:SetAllPoints()
        normal:SetVertexColor(0.37, 0.3, 0.3, 1)
    end
    
    button:SetPushedTexture(ns.media.pushed)
    button:SetHighlightTexture(ns.media.hover)
    button:SetCheckedTexture(ns.media.checked)
    
    -- Style icon
    if button.icon then
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        button.icon:SetPoint("TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    end
    
    -- Style cooldown
    if button.cooldown then
        button.cooldown:SetPoint("TOPLEFT", 1, -1)
        button.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
        button.cooldown:SetDrawBling(false)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    end
    
    -- Style count
    if button.Count then
        button.Count:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
        button.Count:SetPoint("BOTTOMRIGHT", -1, 1)
        button.Count:SetTextColor(1, 1, 1, 1)
    end
    
    -- Style hotkey with ColdUI abbreviations
    if button.HotKey then
        button.HotKey:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
        button.HotKey:SetPoint("TOPRIGHT", -1, -1)
        button.HotKey:SetTextColor(0.75, 0.75, 0.75, 1)
        
        -- Apply hotkey abbreviations
        local UpdateHotkeys = button.UpdateHotkeys
        if UpdateHotkeys then
            hooksecurefunc(button, "UpdateHotkeys", function(self)
                local hotkey = self.HotKey:GetText()
                if hotkey then
                    hotkey = string.gsub(hotkey, 'SHIFT%-', 's')
                    hotkey = string.gsub(hotkey, 'ALT%-', 'a')
                    hotkey = string.gsub(hotkey, 'CTRL%-', 'c')
                    hotkey = string.gsub(hotkey, 'BUTTON', 'm')
                    hotkey = string.gsub(hotkey, 'MOUSEWHEELUP', 'MU')
                    hotkey = string.gsub(hotkey, 'MOUSEWHEELDOWN', 'MD')
                    hotkey = string.gsub(hotkey, 'NUMPAD', 'N')
                    hotkey = string.gsub(hotkey, 'PAGEUP', 'PU')
                    hotkey = string.gsub(hotkey, 'PAGEDOWN', 'PD')
                    hotkey = string.gsub(hotkey, 'SPACE', 'SpB')
                    hotkey = string.gsub(hotkey, 'INSERT', 'Ins')
                    hotkey = string.gsub(hotkey, 'HOME', 'Hm')
                    hotkey = string.gsub(hotkey, 'DELETE', 'Del')
                    hotkey = string.gsub(hotkey, 'CAPSLOCK', 'CL')
                    self.HotKey:SetText(hotkey)
                end
            end)
        end
    end
    
    -- Hide macro name by default (ColdUI style)
    if button.Name then
        button.Name:Hide()
    end
    
    -- Style border
    if button.Border then
        button.Border:SetTexture(ns.media.gloss)
        button.Border:SetVertexColor(0, 1, 0, 0.5)
        button.Border:SetPoint("TOPLEFT", -2, 2)
        button.Border:SetPoint("BOTTOMRIGHT", 2, -2)
    end
    
    -- Style flash
    if button.Flash then
        button.Flash:SetTexture(ns.media.flash)
        button.Flash:SetAllPoints()
    end
end

-- Create bar container
function ActionBars:CreateBar(name, numButtons, config)
    local bar = CreateFrame("Frame", "DamiaUI" .. name, UIParent, "SecureHandlerStateTemplate")
    
    -- Calculate size
    local size = config.size or self.config.size or BUTTON_SIZE
    local spacing = config.spacing or self.config.spacing or BUTTON_SPACING
    local isVertical = config.orientation == "VERTICAL"
    
    if isVertical then
        bar:SetSize(size, size * numButtons + spacing * (numButtons - 1))
    else
        bar:SetSize(size * numButtons + spacing * (numButtons - 1), size)
    end
    
    -- Position
    if config.pos then
        bar:SetPoint(unpack(config.pos))
    end
    
    -- Scale
    bar:SetScale(config.scale or self.config.scale or 1)
    
    -- Make movable
    ns:MakeMovable(bar, true)
    
    -- Store reference
    self.bars[name] = bar
    
    return bar
end

-- Setup visibility conditions
function ActionBars:SetupVisibility()
    -- This will be called after all bars are created
    -- Individual bars handle their own visibility and state drivers
end

-- Create Extra Action Bar (for special zone abilities)
function ActionBars:CreateExtraBar()
    -- The ExtraActionBar is handled by Blizzard
    -- We just need to style it if needed
    if ExtraActionBarFrame then
        -- Apply some basic positioning if needed
        ExtraActionBarFrame:ClearAllPoints()
        ExtraActionBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 250)
    end
end

-- Register module
ns:RegisterModule("ActionBars", ActionBars)
print("[DEBUG] ActionBars module registered")