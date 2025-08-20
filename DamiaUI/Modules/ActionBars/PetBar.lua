-- DamiaUI Pet Action Bar
-- Based on ColdBars petbar.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreatePetBar()
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIPetBar", UIParent, "SecureHandlerStateTemplate")
    
    -- Get pet bar specific config
    local size = self.config.petbar and self.config.petbar.size or 28
    local spacing = self.config.petbar and self.config.petbar.spacing or 4
    
    bar:SetSize(size * 10 + spacing * 9, size)
    
    -- Position
    if self.config.petbar and self.config.petbar.pos then
        bar:SetPoint(unpack(self.config.petbar.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create pet buttons
    for i = 1, 10 do
        local button = CreateFrame("CheckButton", "DamiaUIPetButton"..i, bar, "PetActionButtonTemplate")
        button:SetSize(size, size)
        button:RegisterForClicks("AnyUp")
        
        -- Clear default position
        button:ClearAllPoints()
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", _G["DamiaUIPetButton"..(i-1)], "RIGHT", spacing, 0)
        end
        
        -- Apply styling
        if self.StylePetButton then
            self:StylePetButton(button)
        end
        
        -- Store button reference
        if not self.petButtons then
            self.petButtons = {}
        end
        self.petButtons[i] = button
    end
    
    -- Visibility handler
    bar:SetAttribute("_onstate-visibility", [[
        if newstate == "hide" then
            self:Hide()
        else
            self:Show()
        end
    ]])
    
    -- Pet bar visibility conditions
    RegisterStateDriver(bar, "visibility", "[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists] hide; [pet] show; hide")
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.petbar = bar
    
    return bar
end