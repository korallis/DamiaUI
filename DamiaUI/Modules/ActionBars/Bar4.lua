-- DamiaUI Action Bar 4
-- Based on ColdBars bar4.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateBar4()
    if not self.config.bar4 or not self.config.bar4.enable then
        return
    end
    
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIBar4", UIParent, "SecureHandlerStateTemplate")
    
    -- Check orientation
    local isVertical = self.config.bar4.orientation == "VERTICAL"
    if isVertical then
        bar:SetSize(self.config.size, self.config.size * 12 + self.config.spacing * 11)
    else
        bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    end
    
    -- Position
    if self.config.bar4 and self.config.bar4.pos then
        bar:SetPoint(unpack(self.config.bar4.pos))
    else
        bar:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons (37-48 for Bar4)
    for i = 1, 12 do
        local buttonID = i + 36  -- Bar4 uses action slots 37-48
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
    self.bars.bar4 = bar
    
    return bar
end