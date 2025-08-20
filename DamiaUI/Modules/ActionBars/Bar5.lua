-- DamiaUI Action Bar 5
-- Based on ColdBars bar5.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateBar5()
    if not self.config.bar5 or not self.config.bar5.enable then
        return
    end
    
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIBar5", UIParent, "SecureHandlerStateTemplate")
    
    -- Check orientation
    local isVertical = self.config.bar5.orientation == "VERTICAL"
    if isVertical then
        bar:SetSize(self.config.size, self.config.size * 12 + self.config.spacing * 11)
    else
        bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    end
    
    -- Position
    if self.config.bar5 and self.config.bar5.pos then
        bar:SetPoint(unpack(self.config.bar5.pos))
    else
        bar:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons (49-60 for Bar5)
    for i = 1, 12 do
        local buttonID = i + 48  -- Bar5 uses action slots 49-60
        local button = self:CreateActionButton(buttonID, bar, self.config.size)
        
        -- Position buttons
        if i == 1 then
            if isVertical then
                button:SetPoint("TOP", bar, "TOP", 0, 0)
            else
                button:SetPoint("LEFT", bar, "LEFT", 0, 0)
            end
        else
            if isVertical then
                button:SetPoint("TOP", self.buttons[buttonID-1], "BOTTOM", 0, -self.config.spacing)
            else
                button:SetPoint("LEFT", self.buttons[buttonID-1], "RIGHT", self.config.spacing, 0)
            end
        end
        
        -- Setup events
        self:SetupButtonEvents(button)
        
        -- Setup action
        button:SetAttribute("action", buttonID)
    end
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.bar5 = bar
    
    return bar
end