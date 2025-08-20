-- DamiaUI Override Action Bar
-- Based on ColdBars overridebar.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateOverrideBar()
    -- Override bar is used in vehicles and special encounters
    local bar = OverrideActionBar
    if not bar then
        return
    end
    
    -- Clear default position
    bar:ClearAllPoints()
    
    -- Position (same as main bar when active)
    if self.config.mainbar and self.config.mainbar.pos then
        bar:SetPoint(unpack(self.config.mainbar.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 30)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Style override buttons
    for i = 1, 6 do
        local button = _G["OverrideActionBarButton"..i]
        if button then
            -- Apply custom styling
            if self.StyleButton then
                self:StyleButton(button)
            end
            
            -- Fix icon texture
            if button.icon then
                button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            end
            
            -- Adjust size
            button:SetSize(self.config.size, self.config.size)
            
            -- Reposition buttons
            button:ClearAllPoints()
            if i == 1 then
                button:SetPoint("LEFT", bar, "LEFT", 0, 0)
            else
                button:SetPoint("LEFT", _G["OverrideActionBarButton"..(i-1)], "RIGHT", self.config.spacing, 0)
            end
        end
    end
    
    -- Style leave button
    local leaveButton = OverrideActionBarLeaveFrameLeaveButton
    if leaveButton then
        leaveButton:SetSize(self.config.size, self.config.size)
        leaveButton:ClearAllPoints()
        leaveButton:SetPoint("LEFT", OverrideActionBarButton6, "RIGHT", self.config.spacing * 2, 0)
        
        -- Apply styling
        if self.StyleButton then
            self:StyleButton(leaveButton)
        end
    end
    
    -- Hide pitch/up/down buttons (vehicle UI)
    local vehicleButtons = {
        OverrideActionBarPitchUpButton,
        OverrideActionBarPitchDownButton,
    }
    
    for _, button in pairs(vehicleButtons) do
        if button then
            button:Hide()
            button.Show = function() end
        end
    end
    
    -- Store bar reference
    self.bars.overridebar = bar
    
    return bar
end