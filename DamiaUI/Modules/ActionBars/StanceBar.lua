-- DamiaUI Stance Bar
-- Based on ColdBars stancebar.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateStanceBar()
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIStanceBar", UIParent, "SecureHandlerStateTemplate")
    
    -- Get stance bar specific config
    local size = self.config.stancebar and self.config.stancebar.size or 32
    local spacing = self.config.stancebar and self.config.stancebar.spacing or 4
    
    -- Initial size (will be adjusted based on number of stances)
    bar:SetSize(size * 10 + spacing * 9, size)
    
    -- Position
    if self.config.stancebar and self.config.stancebar.pos then
        bar:SetPoint(unpack(self.config.stancebar.pos))
    else
        bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 150)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create stance buttons
    local numStances = GetNumShapeshiftForms() or 0
    local stanceButtons = {}
    
    for i = 1, 10 do
        local button = CreateFrame("CheckButton", "DamiaUIStanceButton"..i, bar, "StanceButtonTemplate")
        button:SetSize(size, size)
        
        -- Clear default position
        button:ClearAllPoints()
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", stanceButtons[i-1], "RIGHT", spacing, 0)
        end
        
        -- Apply styling
        if self.StyleStanceButton then
            self:StyleStanceButton(button)
        end
        
        -- Hide unused buttons initially
        if i > numStances then
            button:Hide()
        end
        
        stanceButtons[i] = button
    end
    
    -- Update bar size based on number of stances
    local function UpdateStanceBar()
        local numStances = GetNumShapeshiftForms() or 0
        if numStances > 0 then
            bar:SetSize(size * numStances + spacing * (numStances - 1), size)
            for i = 1, 10 do
                if i <= numStances then
                    stanceButtons[i]:Show()
                else
                    stanceButtons[i]:Hide()
                end
            end
            bar:Show()
        else
            bar:Hide()
        end
    end
    
    -- Register events
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    bar:RegisterEvent("PLAYER_REGEN_ENABLED")
    bar:SetScript("OnEvent", UpdateStanceBar)
    
    -- Initial update
    UpdateStanceBar()
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.stancebar = bar
    self.stanceButtons = stanceButtons
    
    return bar
end