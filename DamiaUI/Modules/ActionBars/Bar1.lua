-- DamiaUI Main Action Bar (Bar 1)
-- Based on ColdBars bar1.lua, updated for WoW 11.2

local addonName, ns = ...
local ActionBars = ns.ActionBars

function ActionBars:CreateMainBar()
    -- Create bar frame
    local bar = CreateFrame("Frame", "DamiaUIMainBar", UIParent, "SecureHandlerStateTemplate")
    bar:SetSize(self.config.size * 12 + self.config.spacing * 11, self.config.size)
    
    -- Position
    if self.config.mainbar and self.config.mainbar.pos then
        bar:SetPoint(unpack(self.config.mainbar.pos))
    else
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 30)
    end
    
    -- Scale
    bar:SetScale(self.config.scale or 1)
    
    -- Create buttons
    for i = 1, 12 do
        local button = self:CreateActionButton(i, bar, self.config.size)
        
        -- Position buttons
        if i == 1 then
            button:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.buttons[i-1], "RIGHT", self.config.spacing, 0)
        end
        
        -- Setup events
        self:SetupButtonEvents(button)
        
        -- Setup paging
        button:SetAttribute("action", i)
    end
    
    -- Paging for main bar
    bar:SetAttribute("_onstate-page", [[
        self:SetAttribute("state", newstate)
        for i = 1, 12 do
            local button = self:GetFrameRef("button"..i)
            local action = (tonumber(newstate) - 1) * 12 + i
            button:SetAttribute("action", action)
        end
    ]])
    
    -- Register buttons for paging
    for i = 1, 12 do
        bar:SetFrameRef("button"..i, self.buttons[i])
    end
    
    -- Default paging conditions
    local paging = {
        "[bar:2] 2",
        "[bar:3] 3",
        "[bar:4] 4",
        "[bar:5] 5",
        "[bar:6] 6",
        "[bonusbar:1] 7",
        "[bonusbar:2] 8",
        "[bonusbar:3] 9",
        "[bonusbar:4] 10",
        "[bonusbar:5] 11",
        "1",
    }
    
    -- Class-specific paging
    local _, class = UnitClass("player")
    if class == "DRUID" then
        paging = {
            "[bonusbar:1,nostealth] 7",  -- Cat Form
            "[bonusbar:1,stealth] 8",     -- Prowl
            "[bonusbar:2] 9",              -- Bear Form
            "[bonusbar:3] 10",             -- Moonkin Form
            "[bonusbar:4] 11",             -- Travel Form
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "ROGUE" then
        paging = {
            "[bonusbar:1] 7",  -- Stealth
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "WARRIOR" then
        paging = {
            "[stance:1] 7",  -- Battle Stance
            "[stance:2] 8",  -- Defensive Stance
            "[stance:3] 9",  -- Berserker Stance
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "PRIEST" then
        paging = {
            "[bonusbar:1] 7",  -- Shadowform
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "MONK" then
        paging = {
            "[stance:1] 7",  -- Stance of the Fierce Tiger
            "[stance:2] 8",  -- Stance of the Sturdy Ox
            "[stance:3] 9",  -- Stance of the Wise Serpent
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    elseif class == "DEMONHUNTER" then
        paging = {
            "[bonusbar:1] 7",  -- Metamorphosis
            "[bar:2] 2",
            "[bar:3] 3",
            "[bar:4] 4",
            "[bar:5] 5",
            "[bar:6] 6",
            "1",
        }
    end
    
    -- Set paging
    RegisterStateDriver(bar, "page", table.concat(paging, "; "))
    
    -- Make movable when not in combat
    ns:MakeMovable(bar, true)
    
    -- Store bar reference
    self.bars.mainbar = bar
    
    return bar
end