-- DamiaUI Action Bar Drag Functionality
-- Based on ColdBars drag.lua, updated for WoW 11.2

local addonName, ns = ...

-- Make a frame movable
function ns:MakeMovable(frame, savePosition)
    if not frame then return end
    
    frame:SetMovable(true)
    frame:SetUserPlaced(savePosition or false)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Create overlay for drag indication
    if not frame.dragOverlay then
        frame.dragOverlay = CreateFrame("Frame", nil, frame)
        frame.dragOverlay:SetAllPoints(frame)
        frame.dragOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
        frame.dragOverlay:Hide()
        
        -- Create background
        frame.dragOverlay.bg = frame.dragOverlay:CreateTexture(nil, "BACKGROUND")
        frame.dragOverlay.bg:SetAllPoints()
        frame.dragOverlay.bg:SetColorTexture(0, 1, 0, 0.3)
        
        -- Create text
        frame.dragOverlay.text = frame.dragOverlay:CreateFontString(nil, "OVERLAY")
        frame.dragOverlay.text:SetFont(ns.media.font, 14, "OUTLINE")
        frame.dragOverlay.text:SetPoint("CENTER")
        frame.dragOverlay.text:SetText("Shift + Drag to Move")
        frame.dragOverlay.text:SetTextColor(1, 1, 1, 1)
    end
    
    -- Drag handlers
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self:StartMoving()
            self.dragOverlay:Show()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.dragOverlay:Hide()
        
        -- Save position if requested
        if savePosition then
            local point, _, relativePoint, x, y = self:GetPoint()
            if not DamiaUIDB then DamiaUIDB = {} end
            if not DamiaUIDB.framePositions then DamiaUIDB.framePositions = {} end
            DamiaUIDB.framePositions[self:GetName()] = {point, UIParent, relativePoint, x, y}
        end
    end)
    
    -- Show drag overlay on modifier key
    frame:SetScript("OnEnter", function(self)
        if IsShiftKeyDown() and not InCombatLockdown() then
            self.dragOverlay:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        if not self.isMoving then
            self.dragOverlay:Hide()
        end
    end)
    
    -- Restore saved position
    if savePosition and DamiaUIDB and DamiaUIDB.framePositions then
        local pos = DamiaUIDB.framePositions[frame:GetName()]
        if pos then
            frame:ClearAllPoints()
            frame:SetPoint(unpack(pos))
        end
    end
end

-- Lock/unlock all frames
function ns:ToggleLock()
    if InCombatLockdown() then
        print("|cffFF0000DamiaUI:|r Cannot toggle lock during combat")
        return
    end
    
    if not ns.unlocked then
        ns.unlocked = true
        print("|cff00FF7FDamiaUI:|r Frames unlocked - Shift+Drag to move")
        
        -- Show all drag overlays
        for name, module in pairs(ns.modules) do
            if module.bars then
                for _, bar in pairs(module.bars) do
                    if bar.dragOverlay then
                        bar.dragOverlay.bg:SetColorTexture(0, 1, 0, 0.3)
                        bar.dragOverlay:Show()
                    end
                end
            end
        end
    else
        ns.unlocked = false
        print("|cff00FF7FDamiaUI:|r Frames locked")
        
        -- Hide all drag overlays
        for name, module in pairs(ns.modules) do
            if module.bars then
                for _, bar in pairs(module.bars) do
                    if bar.dragOverlay then
                        bar.dragOverlay:Hide()
                    end
                end
            end
        end
    end
end

-- Reset all frame positions
function ns:ResetPositions()
    if InCombatLockdown() then
        print("|cffFF0000DamiaUI:|r Cannot reset positions during combat")
        return
    end
    
    if DamiaUIDB then
        DamiaUIDB.framePositions = nil
    end
    
    -- Reset all bars to default positions
    for name, module in pairs(ns.modules) do
        if module.bars then
            for barName, bar in pairs(module.bars) do
                bar:ClearAllPoints()
                -- Apply default position from config
                if module.config and module.config[barName] and module.config[barName].pos then
                    bar:SetPoint(unpack(module.config[barName].pos))
                end
            end
        end
    end
    
    print("|cff00FF7FDamiaUI:|r All frame positions reset to defaults")
end

-- Slash commands for drag functionality
SLASH_DAMIAUILOCK1 = "/duilock"
SLASH_DAMIAUILOCK2 = "/dui lock"
SlashCmdList["DAMIAUILOCK"] = function()
    ns:ToggleLock()
end

SLASH_DAMIAUIRESET1 = "/duireset"
SLASH_DAMIAUIRESET2 = "/dui reset"
SlashCmdList["DAMIAUIRESET"] = function()
    ns:ResetPositions()
end