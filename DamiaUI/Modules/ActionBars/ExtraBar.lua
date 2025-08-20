-- DamiaUI Extra Action Bar
-- Based on ColdBars extrabar.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateExtraBar()
    -- Extra Action Bar is a special Blizzard frame
    local bar = ExtraActionBarFrame
    if not bar then
        return
    end
    
    -- Get extra bar specific config
    local size = self.config.extrabar and self.config.extrabar.size or 40
    
    -- Clear default position
    bar:ClearAllPoints()
    
    -- Position
    if self.config.extrabar and self.config.extrabar.pos then
        bar:SetPoint(unpack(self.config.extrabar.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Style the extra action button
    local button = ExtraActionButton1
    if button then
        -- Remove default textures
        button.style:SetAlpha(0)
        
        -- Resize
        button:SetSize(size, size)
        
        -- Apply custom styling
        if self.StyleExtraButton then
            self:StyleExtraButton(button)
        end
        
        -- Fix icon texture
        if button.icon then
            button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        end
        
        -- Style cooldown
        if button.cooldown then
            button.cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            button.cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        end
    end
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.extrabar = bar
    
    return bar
end