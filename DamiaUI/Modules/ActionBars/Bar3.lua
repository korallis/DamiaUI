-- DamiaUI Action Bar 3
-- Based on ColdBars bar3.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateBar3()
    if not self.config.bar3 or not self.config.bar3.enable then
        return
    end
    
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIBar3", UIParent, "SecureHandlerStateTemplate")
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    -- Position
    if self.config.bar3 and self.config.bar3.pos then
        bar:SetPoint(unpack(self.config.bar3.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 110)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons (25-36 for Bar3)
    for i = 1, 12 do
        local buttonID = i + 24  -- Bar3 uses action slots 25-36
        local button = self:CreateActionButton(buttonID, bar, self.config.size)
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[buttonID-1], "RIGHT", self.config.spacing, 0)
        end
        
        -- Setup events
        self:SetupButtonEvents(button)
        
        -- Setup action
        button:SetAttribute("action", buttonID)
    end
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.bar3 = bar
    
    return bar
end