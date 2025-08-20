-- DamiaUI Action Bar Styling
-- Exact copy of ColdBars style.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

-- ColdUI backdrop configuration
local backdrop = {
    bgFile = ns.media.buttonBackgroundFlat,
    tile = false,
    tileSize = 32,
    edgeSize = 5,
    insets = {left = 5, right = 5, top = 5.5, bottom = 5},
}

-- Apply ColdUI background style
local function applyBackground(bu)
    if not bu or (bu and bu.bg) then return end
    if bu:GetFrameLevel() < 1 then bu:SetFrameLevel(1) end
    bu.bg = CreateFrame("Frame", nil, bu, "BackdropTemplate")
    bu.bg:SetAllPoints(bu)
    bu.bg:SetPoint("TOPLEFT", bu, "TOPLEFT", -4, 4)
    bu.bg:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", 4, -4)
    bu.bg:SetFrameLevel(bu:GetFrameLevel()-1)
    bu.bg:SetBackdrop(backdrop)
    bu.bg:SetBackdropColor(.2, .2, .2, .6)
    bu.bg:SetBackdropBorderColor(0, 0, 0)
end

-- Style an action button (ColdUI style)
function ActionBars:StyleButton(button)
    if not button or button.styled then return end
    
    local action = button.action
    local name = button:GetName()
    local icon = _G[name.."Icon"] or button.icon
    local count = _G[name.."Count"] or button.Count
    local border = _G[name.."Border"] or button.Border
    local hotkey = _G[name.."HotKey"] or button.HotKey
    local cooldown = _G[name.."Cooldown"] or button.cooldown
    local macro = _G[name.."Name"] or button.Name
    local flash = _G[name.."Flash"] or button.Flash
    local normal = _G[name.."NormalTexture"] or button.NormalTexture
    local floatingBG = _G[name.."FloatingBG"]
    
    -- Hide floating background
    if floatingBG then floatingBG:Hide() end
    
    -- Hide border
    if border then border:SetTexture(nil) end
    
    -- Hotkey (ColdUI style)
    if hotkey then
        if self.config.showkeybind == 1 then
            hotkey:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
            hotkey:ClearAllPoints()
            hotkey:SetPoint("BOTTOMLEFT", 1, 1.5)
            hotkey:SetPoint("BOTTOMRIGHT", 1, 1.5)
        else
            hotkey:Hide()
        end
    end
    
    -- Item count (ColdUI style)
    if count then
        if self.config.showcount == 1 then
            count:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
            count:ClearAllPoints()
            count:SetPoint("TOPRIGHT", 1, .5)
            count:SetTextColor(0, 1, 0)
        else
            count:Hide()
        end
    end
    
    -- Hide macro name
    if macro then macro:Hide() end
    
    -- Apply textures (ColdUI style)
    if flash then flash:SetTexture(ns.media.flash) end
    button:SetHighlightTexture(ns.media.hover)
    button:SetPushedTexture(ns.media.pushed)
    button:SetCheckedTexture(ns.media.checked)
    button:SetNormalTexture(ns.media.gloss)
    
    -- Icon texture coords
    if icon then
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Cooldown positioning
    if cooldown then
        cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    end
    
    -- Apply normal texture coloring (ColdUI style)
    if normal then
        if action and IsEquippedAction(action) then
            button:SetNormalTexture(ns.media.glossGrey)
            normal:SetVertexColor(.1, .5, .1)
        else
            button:SetNormalTexture(ns.media.gloss)
            normal:SetVertexColor(.37, .3, .3)
        end
        normal:SetAllPoints(button)
        
        -- Hook to prevent Blizzard from resetting colors
        hooksecurefunc(normal, "SetVertexColor", function(nt, r, g, b, a)
            local bu = nt:GetParent()
            local action = bu.action
            if r==1 and g==1 and b==1 and action and IsEquippedAction(action) then
                nt:SetVertexColor(0.999, 0.999, 0.999, 1)
            elseif r==0.5 and g==0.5 and b==1 then
                -- Blizzard OOM color
                nt:SetVertexColor(0.499, 0.499, 0.999, 1)
            elseif r==1 and g==1 and b==1 then
                nt:SetVertexColor(0.999, 0.999, 0.999, 1)
            end
        end)
    end
    
    -- Apply background
    if not button.bg then applyBackground(button) end
    
    button.styled = true
end

-- Style pet button (ColdUI style)
function ActionBars:StylePetButton(button)
    if not button or button.styled then return end
    
    local name = button:GetName()
    local icon = _G[name.."Icon"]
    local flash = _G[name.."Flash"]
    local normal = _G[name.."NormalTexture2"]
    
    if normal then
        normal:SetAllPoints(button)
        normal:SetVertexColor(.37, .3, .3, 1)
    end
    
    -- Setting textures
    if flash then flash:SetTexture(ns.media.flash) end
    button:SetHighlightTexture(ns.media.hover)
    button:SetPushedTexture(ns.media.pushed)
    button:SetCheckedTexture(ns.media.checked)
    button:SetNormalTexture(ns.media.gloss)
    
    hooksecurefunc(button, "SetNormalTexture", function(self, texture)
        if texture and texture ~= ns.media.gloss then
            self:SetNormalTexture(ns.media.gloss)
        end
    end)
    
    -- Icon
    if icon then
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Background
    if not button.bg then applyBackground(button) end
    button.styled = true
end

-- Style stance button (ColdUI style)
function ActionBars:StyleStanceButton(button)
    if not button or button.styled then return end
    
    local name = button:GetName()
    local icon = _G[name.."Icon"]
    local flash = _G[name.."Flash"]
    local normal = _G[name.."NormalTexture2"]
    
    if normal then
        normal:SetAllPoints(button)
        normal:SetVertexColor(.37, .3, .3, 1)
    end
    
    -- Setting textures
    if flash then flash:SetTexture(ns.media.flash) end
    button:SetHighlightTexture(ns.media.hover)
    button:SetPushedTexture(ns.media.pushed)
    button:SetCheckedTexture(ns.media.checked)
    button:SetNormalTexture(ns.media.gloss)
    
    -- Icon
    if icon then
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Background
    if not button.bg then applyBackground(button) end
    button.styled = true
end

-- Style extra action button (ColdUI style)
function ActionBars:StyleExtraButton(button)
    if not button or button.styled then return end
    
    local name = button:GetName()
    local hotkey = _G[name.."HotKey"]
    
    -- Remove style background
    if button.style then
        button.style:SetTexture(nil)
        hooksecurefunc(button.style, "SetTexture", function(self, texture)
            if texture then
                self:SetTexture(nil)
            end
        end)
    end
    
    -- Icon
    if button.icon then
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Cooldown
    if button.cooldown then
        button.cooldown:SetAllPoints(button.icon)
    end
    
    -- Hotkey
    if hotkey then hotkey:Hide() end
    
    -- Add normal texture
    button:SetNormalTexture(ns.media.gloss)
    local nt = button:GetNormalTexture()
    if nt then
        nt:SetVertexColor(.37, .3, .3)
        nt:SetAllPoints(button)
    end
    
    -- Background
    if not button.bg then applyBackground(button) end
    button.styled = true
end

-- Update button border based on state
function ActionBars:UpdateButtonBorder(button)
    if not button or not button.customBorder then return end
    
    local action = button.action or button:GetAttribute("action")
    if not action then return end
    
    local isUsable, notEnoughMana = IsUsableAction(action)
    local inRange = IsActionInRange(action)
    
    -- Set border color based on state
    if notEnoughMana then
        button.customBorder:SetVertexColor(0.5, 0.5, 1, 1)  -- Blue for OOM
    elseif inRange == false then
        button.customBorder:SetVertexColor(0.8, 0.1, 0.1, 1)  -- Red for out of range
    else
        button.customBorder:SetVertexColor(0, 0, 0, 0)  -- Transparent when normal
    end
end

-- Apply grid visibility (11.2 compatible - no ShowGrid/HideGrid)
function ActionBars:UpdateGrid()
    local showgrid = self.config.showgrid == 1
    
    for _, button in pairs(self.buttons) do
        if button then
            button:SetAttribute("showgrid", showgrid and 1 or 0)
            
            -- Update alpha based on grid state and action
            local action = button:GetAttribute("action")
            local hasAction = action and HasAction(action)
            
            if showgrid or hasAction then
                button:SetAlpha(1)
            else
                button:SetAlpha(0)
            end
        end
    end
end

-- Shorten hotkey names (ColdUI style)
local replace = string.gsub
function ActionBars:UpdateHotkey(button)
    local hotkey = button.HotKey or _G[button:GetName() .. 'HotKey']
    if not hotkey then return end
    
    local text = hotkey:GetText()
    if not text then return end
    
    text = replace(text, '(s%-)', 's')
    text = replace(text, '(a%-)', 'a')
    text = replace(text, '(c%-)', 'c')
    text = replace(text, '(Mouse Button )', 'm')
    text = replace(text, '(Middle Mouse)', 'm3')
    text = replace(text, '(Mouse Wheel Up)', 'mU')
    text = replace(text, '(Mouse Wheel Down)', 'mD')
    text = replace(text, '(Num Pad )', 'n')
    text = replace(text, '(Page Up)', 'pu')
    text = replace(text, '(Page Down)', 'pd')
    text = replace(text, '(Spacebar)', 'spb')
    text = replace(text, '(Insert)', 'ins')
    text = replace(text, '(Home)', 'hm')
    text = replace(text, '(Delete)', 'del')
    
    if hotkey:GetText() == _G['RANGE_INDICATOR'] then
        hotkey:SetText('')
    else
        hotkey:SetText(text)
    end
end