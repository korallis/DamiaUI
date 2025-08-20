-- DamiaUI Action Bars Module
-- Based on ColdBars, updated for WoW 11.2

local addonName, ns = ...
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
    
    ns:Print("Action Bars module loaded")
end

-- Create action button with 11.2 compatibility
function ActionBars:CreateActionButton(id, parent, size)
    local button = CreateFrame("Button", "DamiaUIActionButton"..id, parent, "SecureActionButtonTemplate")
    button:SetSize(size or self.config.size, size or self.config.size)
    
    -- Set as action button
    button:SetAttribute("type", "action")
    button:SetAttribute("action", id)
    button:RegisterForClicks("AnyUp")
    
    -- Create visual elements
    button:SetNormalTexture(ns.media.buttonBackground)
    local normal = button:GetNormalTexture()
    normal:SetAllPoints()
    normal:SetVertexColor(0.3, 0.3, 0.3)
    
    -- Icon
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Cooldown
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetPoint("TOPLEFT", 2, -2)
    button.cooldown:SetPoint("BOTTOMRIGHT", -2, 2)
    button.cooldown:SetDrawBling(false)
    button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    
    -- Count
    button.count = button:CreateFontString(nil, "OVERLAY")
    button.count:SetFont(ns.media.font, 12, "OUTLINE")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count:SetJustifyH("RIGHT")
    
    -- Hotkey
    button.hotkey = button:CreateFontString(nil, "OVERLAY")
    button.hotkey:SetFont(ns.media.font, 11, "OUTLINE")
    button.hotkey:SetPoint("TOPRIGHT", -2, -2)
    button.hotkey:SetJustifyH("RIGHT")
    
    -- Macro name
    button.name = button:CreateFontString(nil, "OVERLAY")
    button.name:SetFont(ns.media.font, 10, "OUTLINE")
    button.name:SetPoint("BOTTOM", 0, 2)
    button.name:SetJustifyH("CENTER")
    
    -- Border for equipped items
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", 2, -2)
    button.border:SetTexture(ns.media.buttonBackground)
    button.border:SetVertexColor(0, 1, 0, 0.3)
    button.border:Hide()
    
    -- Pushed texture
    button:SetPushedTexture(ns.media.buttonBackground)
    local pushed = button:GetPushedTexture()
    pushed:SetAllPoints()
    pushed:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    
    -- Highlight texture
    button:SetHighlightTexture(ns.media.buttonBackground)
    local highlight = button:GetHighlightTexture()
    highlight:SetAllPoints()
    highlight:SetVertexColor(1, 1, 1, 0.3)
    
    -- Checked texture
    button:SetCheckedTexture(ns.media.buttonBackground)
    local checked = button:GetCheckedTexture()
    checked:SetAllPoints()
    checked:SetVertexColor(1, 1, 1, 0.3)
    
    -- Create backdrop
    ns:CreateBackdrop(button, 0.9)
    
    -- Update function
    button.Update = function(self)
        local action = self:GetAttribute("action")
        if not action then return end
        
        -- Icon (11.2 compatible)
        local texture = GetActionTexture(action)
        if texture then
            self.icon:SetTexture(texture)
            self.icon:Show()
            self:SetAlpha(1)
        else
            if ActionBars.config and ActionBars.config.showgrid == 1 then
                self.icon:Hide()
                self:SetAlpha(0.4)
            else
                self.icon:Hide()
                self:SetAlpha(0)
            end
        end
        
        -- Cooldown (11.2 compatible)
        local cooldownInfo = C_ActionBar.GetActionCooldown and C_ActionBar.GetActionCooldown(action) or nil
        if cooldownInfo then
            local start, duration = cooldownInfo.startTime, cooldownInfo.duration
            if start > 0 and duration > 0 then
                self.cooldown:SetCooldown(start, duration)
            else
                self.cooldown:Clear()
            end
        else
            -- Fallback for older API
            local start, duration, enable = GetActionCooldown(action)
            if enable and enable ~= 0 and start > 0 and duration > 0 then
                self.cooldown:SetCooldown(start, duration)
            else
                self.cooldown:Clear()
            end
        end
        
        -- Count (11.2 compatible)
        local count = GetActionCount(action)
        if count and count > 1 then
            self.count:SetText(count)
            self.count:Show()
        else
            self.count:Hide()
        end
        
        -- Hotkey
        local key = GetBindingKey("ACTIONBUTTON"..action)
        if key and self.config and self.config.showkeybind == 1 then
            self.hotkey:SetText(key)
            self.hotkey:Show()
        else
            self.hotkey:Hide()
        end
        
        -- Macro name
        local text = GetActionText(action)
        if text and self.config and self.config.showmacro == 1 then
            self.name:SetText(text)
            self.name:Show()
        else
            self.name:Hide()
        end
        
        -- Range coloring
        local inRange = IsActionInRange(action)
        if inRange == false then
            self.icon:SetVertexColor(0.8, 0.1, 0.1)
        else
            self.icon:SetVertexColor(1, 1, 1)
        end
        
        -- Usability
        local isUsable, notEnoughMana = IsUsableAction(action)
        if notEnoughMana then
            self.icon:SetVertexColor(0.1, 0.3, 1)
        elseif not isUsable then
            self.icon:SetDesaturated(true)
        else
            self.icon:SetDesaturated(false)
        end
        
        -- Equipped item border
        if IsEquippedAction(action) then
            self.border:Show()
        else
            self.border:Hide()
        end
        
        -- Active spell highlight
        if IsCurrentAction(action) or IsAutoRepeatAction(action) then
            self:SetChecked(true)
        else
            self:SetChecked(false)
        end
    end
    
    -- Set config reference
    button.config = self.config
    
    -- Initial update
    button:Update()
    
    -- Store button reference
    self.buttons[id] = button
    
    return button
end

-- Setup events for button updates
function ActionBars:SetupButtonEvents(button)
    button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    button:RegisterEvent("UPDATE_INVENTORY_ALERTS")
    button:RegisterEvent("PLAYER_TARGET_CHANGED")
    button:RegisterEvent("SPELL_UPDATE_CHARGES")
    button:RegisterEvent("UPDATE_BINDINGS")
    
    button:SetScript("OnEvent", function(self, event, ...)
        if event == "ACTIONBAR_SLOT_CHANGED" then
            local slot = ...
            if slot == self:GetAttribute("action") or slot == 0 then
                self:Update()
            end
        else
            self:Update()
        end
    end)
    
    -- OnEnter/OnLeave for tooltips
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetAction(self:GetAttribute("action"))
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

-- Register module events
function ActionBars:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")
    
    frame:SetScript("OnEvent", function(self, event)
        if event == "ACTIONBAR_SHOWGRID" then
            ActionBars:ShowGrid()
        elseif event == "ACTIONBAR_HIDEGRID" then
            ActionBars:HideGrid()
        end
    end)
end

-- Show grid
function ActionBars:ShowGrid()
    for _, button in pairs(self.buttons) do
        if not HasAction(button:GetAttribute("action")) then
            button:SetAlpha(0.4)
        end
    end
end

-- Hide grid
function ActionBars:HideGrid()
    if self.config.showgrid ~= 1 then
        for _, button in pairs(self.buttons) do
            if not HasAction(button:GetAttribute("action")) then
                button:SetAlpha(0)
            end
        end
    end
end

-- Register with main addon
ns:RegisterModule("ActionBars", ActionBars)