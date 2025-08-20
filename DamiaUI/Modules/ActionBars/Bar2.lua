-- DamiaUI Action Bar 2
-- Based on ColdBars bar2.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateBar2()
    if not self.config.bar2 or not self.config.bar2.enable then
        return
    end
    
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIBar2", UIParent, "SecureHandlerStateTemplate")
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    -- Position
    if self.config.bar2 and self.config.bar2.pos then
        bar:SetPoint(unpack(self.config.bar2.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 70)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons (13-24 for MultiBarBottomLeft)
    for i = 1, 12 do
        local id = i + 12
        local button = self:CreateActionButton(id, bar, self.config.size)
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[id-1], "RIGHT", self.config.spacing, 0)
        end
        
        -- Setup events
        self:SetupButtonEvents(button)
        
        -- Set action ID
        button:SetAttribute("action", id)
    end
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.bar2 = bar
    
    return bar
end