--[[
Name: LibActionButton-1.0
Revision: $Rev: 91 $
Developed by: Nevcairiel, Funkydude, others

Description:
LibActionButton provides action button functionality that's compatible with Blizzard's
action button system but with enhanced customization options. It allows addons to create
custom action bars that work seamlessly with WoW's action system.

This implementation is compatible with WoW 11.2 (110200) and maintains backwards compatibility.

License: LGPL 2.1
]]

local MAJOR, MINOR = "LibActionButton-1.0", 91
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

-- WoW API changes for different versions
local IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local IsCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- Import necessary functions with fallbacks
local GetActionInfo = GetActionInfo or function() return nil end
local GetActionText = GetActionText or function() return "" end
local GetActionTexture = GetActionTexture or function() return nil end
local GetActionCount = GetActionCount or function() return 0 end
local GetActionCooldown = GetActionCooldown or function() return 0, 0, 0 end
local IsActionInRange = IsActionInRange or function() return 1 end
local IsUsableAction = IsUsableAction or function() return false, false end
local IsAttackAction = IsAttackAction or function() return false end
local IsAutoRepeatAction = IsAutoRepeatAction or function() return false end
local IsEquippedAction = IsEquippedAction or function() return false end
local IsCurrentAction = IsCurrentAction or function() return false end
local HasAction = HasAction or function() return false end
local UseAction = UseAction or function() end
local PickupAction = PickupAction or function() end
local PlaceAction = PlaceAction or function() end

-- Library constants
local ACTION_BUTTON_SHOW_GRID_REASON_EVENT = ACTION_BUTTON_SHOW_GRID_REASON_EVENT or 4
local ACTION_BUTTON_SHOW_GRID_REASON_CVAR = ACTION_BUTTON_SHOW_GRID_REASON_CVAR or 8

-- CallbackHandler for event management
local CallbackHandler = LibStub("CallbackHandler-1.0")
lib.callbacks = lib.callbacks or CallbackHandler:New(lib)

-- Button registry
lib.buttonRegistry = lib.buttonRegistry or {}
lib.activeButtons = lib.activeButtons or {}
lib.eventButtons = lib.eventButtons or {}

-- Generic update frame
lib.updateFrame = lib.updateFrame or CreateFrame("Frame")
lib.updateFrame:SetScript("OnUpdate", function(self, elapsed)
    lib:OnUpdate(elapsed)
end)

-- Event handling
lib.eventHandler = lib.eventHandler or CreateFrame("Frame")

local events = {
    "ACTIONBAR_SHOWGRID",
    "ACTIONBAR_HIDEGRID", 
    "ACTIONBAR_PAGE_CHANGED",
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_UPDATE_STATE",
    "ACTIONBAR_UPDATE_USABLE",
    "ACTIONBAR_UPDATE_COOLDOWN",
    "UPDATE_BINDINGS",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_ENTER_COMBAT",
    "PLAYER_LEAVE_COMBAT",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_USABLE",
    "SPELL_UPDATE_CHARGES",
    "BAG_UPDATE",
    "UNIT_INVENTORY_CHANGED",
    "LEARNED_SPELL_IN_TAB",
    "PET_BAR_UPDATE",
    "PET_BAR_UPDATE_COOLDOWN",
    "COMPANION_UPDATE",
    "UNIT_PET"
}

-- Add events based on WoW version
if IsRetail then
    local retailEvents = {
        "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
        "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "LOSS_OF_CONTROL_ADDED",
        "LOSS_OF_CONTROL_UPDATE"
    }
    for _, event in ipairs(retailEvents) do
        events[#events + 1] = event
    end
end

-- Register events
for _, event in ipairs(events) do
    lib.eventHandler:RegisterEvent(event)
end

lib.eventHandler:SetScript("OnEvent", function(self, event, ...)
    lib:OnEvent(event, ...)
end)

-- Button template
local buttonMT = {
    __index = function(self, key)
        if lib.prototype[key] then
            return lib.prototype[key]
        end
    end
}

-- Create library prototype
lib.prototype = lib.prototype or {}

-- Button creation function
function lib:CreateButton(id, name, parent, config)
    if lib.buttonRegistry[name] then
        error("Button name '" .. name .. "' is already in use", 2)
    end
    
    -- Create button frame
    local button = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:RegisterForDrag("LeftButton")
    
    -- Set up button properties
    button.id = id
    button.config = config or {}
    
    -- Apply metatable
    setmetatable(button, buttonMT)
    
    -- Initialize button state
    button:SetAttribute("type", "action")
    button:SetAttribute("action", id)
    
    -- Create button textures
    button.icon = button:CreateTexture(nil, "BACKGROUND", nil, 0)
    button.icon:SetAllPoints()
    
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetSwipeColor(0, 0, 0)
    button.cooldown:SetUseCircularEdge(true)
    
    button.count = button:CreateFontString(nil, "OVERLAY")
    button.count:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    button.count:SetPoint("BOTTOMRIGHT", 0, 2)
    button.count:SetJustifyH("RIGHT")
    button.count:SetTextColor(1, 1, 1)
    
    button.hotkey = button:CreateFontString(nil, "OVERLAY")
    button.hotkey:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    button.hotkey:SetPoint("TOPLEFT", 2, -2)
    button.hotkey:SetJustifyH("LEFT")
    button.hotkey:SetTextColor(0.6, 0.6, 0.6)
    
    button.name = button:CreateFontString(nil, "OVERLAY")
    button.name:SetFont("Fonts\\FRIZQT__.TTF", 8)
    button.name:SetPoint("BOTTOM", 0, 2)
    button.name:SetJustifyH("CENTER")
    button.name:SetTextColor(1, 1, 1)
    
    -- Flash texture
    button.flash = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.flash:SetAllPoints()
    button.flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
    button.flash:SetBlendMode("ADD")
    button.flash:Hide()
    
    -- Border textures
    button.border = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.border:SetAllPoints()
    button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.border:SetBlendMode("ADD")
    button.border:Hide()
    
    -- Button scripts
    button:SetScript("OnEnter", function(self)
        lib:OnEnter(self)
    end)
    
    button:SetScript("OnLeave", function(self)
        lib:OnLeave(self)
    end)
    
    button:SetScript("OnDragStart", function(self)
        lib:OnDragStart(self)
    end)
    
    button:SetScript("OnReceiveDrag", function(self)
        lib:OnReceiveDrag(self)
    end)
    
    -- Initialize button
    button:UpdateAction()
    button:UpdateState()
    button:UpdateUsable()
    button:UpdateCooldown()
    button:UpdateCount()
    button:UpdateHotkeys()
    
    -- Register button
    lib.buttonRegistry[name] = button
    lib.activeButtons[button] = true
    
    return button
end

-- Button prototype methods
function lib.prototype:UpdateAction()
    local action = self:GetAttribute("action")
    if not action then return end
    
    -- Update icon
    local texture = GetActionTexture(action)
    if texture then
        self.icon:SetTexture(texture)
        self.icon:Show()
    else
        self.icon:Hide()
    end
    
    -- Update text
    local text = GetActionText(action)
    if text and text ~= "" then
        self.name:SetText(text)
        self.name:Show()
    else
        self.name:Hide()
    end
    
    -- Update state
    self:UpdateState()
    self:UpdateUsable()
    self:UpdateCooldown()
    self:UpdateCount()
end

function lib.prototype:UpdateState()
    local action = self:GetAttribute("action")
    if not action then return end
    
    if IsCurrentAction(action) or IsAutoRepeatAction(action) then
        self:SetChecked(true)
    else
        self:SetChecked(false)
    end
    
    if IsAttackAction(action) then
        self.border:Show()
    else
        self.border:Hide()
    end
    
    if IsEquippedAction(action) then
        self.border:SetVertexColor(0, 1, 0, 0.5)
    else
        self.border:SetVertexColor(1, 1, 1, 0.5)
    end
end

function lib.prototype:UpdateUsable()
    local action = self:GetAttribute("action")
    if not action then return end
    
    local isUsable, notEnoughMana = IsUsableAction(action)
    
    if isUsable then
        self.icon:SetVertexColor(1, 1, 1)
    elseif notEnoughMana then
        self.icon:SetVertexColor(0.5, 0.5, 1)
    else
        self.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

function lib.prototype:UpdateCooldown()
    local action = self:GetAttribute("action")
    if not action then return end
    
    local start, duration, enable = GetActionCooldown(action)
    
    if start > 0 and duration > 1.5 then
        self.cooldown:SetCooldown(start, duration)
        self.cooldown:Show()
    else
        self.cooldown:Hide()
    end
end

function lib.prototype:UpdateCount()
    local action = self:GetAttribute("action")
    if not action then return end
    
    local count = GetActionCount(action)
    
    if count and count > 1 then
        self.count:SetText(count)
        self.count:Show()
    else
        self.count:Hide()
    end
end

function lib.prototype:UpdateHotkeys()
    local hotkey = GetBindingKey(format("ACTIONBUTTON%d", self.id))
    if hotkey then
        hotkey = gsub(hotkey, "CTRL%-", "C")
        hotkey = gsub(hotkey, "ALT%-", "A")
        hotkey = gsub(hotkey, "SHIFT%-", "S")
        self.hotkey:SetText(hotkey)
        self.hotkey:Show()
    else
        self.hotkey:Hide()
    end
end

function lib.prototype:UpdateFlash()
    local action = self:GetAttribute("action")
    if not action then return end
    
    if IsAttackAction(action) and IsCurrentAction(action) then
        self:StartFlash()
    else
        self:StopFlash()
    end
end

function lib.prototype:StartFlash()
    self.flashing = 1
    self.flashtime = 0
    self.flash:Show()
end

function lib.prototype:StopFlash()
    self.flashing = 0
    self.flash:Hide()
end

function lib.prototype:UpdateFlashTime(elapsed)
    if self.flashing == 1 then
        self.flashtime = self.flashtime - elapsed
        if self.flashtime <= 0 then
            local overtime = -self.flashtime
            if overtime >= ATTACK_BUTTON_FLASH_TIME then
                overtime = 0
            end
            self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime
            
            local flashTexture = self.flash
            if flashTexture:IsShown() then
                flashTexture:Hide()
            else
                flashTexture:Show()
            end
        end
    end
end

-- Event handlers
function lib:OnEvent(event, ...)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        for button in pairs(lib.activeButtons) do
            if button.id == slot or slot == 0 then
                button:UpdateAction()
            end
        end
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        for button in pairs(lib.activeButtons) do
            button:UpdateState()
            button:UpdateFlash()
        end
    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        for button in pairs(lib.activeButtons) do
            button:UpdateUsable()
        end
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
        for button in pairs(lib.activeButtons) do
            button:UpdateCooldown()
        end
    elseif event == "UPDATE_BINDINGS" then
        for button in pairs(lib.activeButtons) do
            button:UpdateHotkeys()
        end
    elseif event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
        for button in pairs(lib.activeButtons) do
            button:UpdateCount()
            button:UpdateUsable()
        end
    end
    
    -- Fire callback
    lib.callbacks:Fire(event, ...)
end

function lib:OnUpdate(elapsed)
    for button in pairs(lib.activeButtons) do
        if button.UpdateFlashTime then
            button:UpdateFlashTime(elapsed)
        end
    end
end

function lib:OnEnter(button)
    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    
    if GameTooltip:SetAction(button.id) then
        GameTooltip:Show()
    end
end

function lib:OnLeave(button)
    GameTooltip:Hide()
end

function lib:OnDragStart(button)
    if HasAction(button.id) then
        PickupAction(button.id)
    end
end

function lib:OnReceiveDrag(button)
    PlaceAction(button.id)
end

-- Public API
function lib:RegisterCallback(...)
    return self.callbacks:RegisterCallback(...)
end

function lib:UnregisterCallback(...)
    return self.callbacks:UnregisterCallback(...)
end

function lib:UnregisterAllCallbacks(...)
    return self.callbacks:UnregisterAllCallbacks(...)
end

-- Version compatibility
lib.GetLibraryVersion = function()
    return MAJOR, MINOR
end