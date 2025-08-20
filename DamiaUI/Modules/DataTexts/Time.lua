-- DamiaUI Time DataText
-- Based on ColdMisc time.lua, updated for WoW 11.2

local addonName, ns = ...

-- Create data text
local TimeDataText = CreateFrame("Frame", "DamiaUITimeDataText", UIParent)
TimeDataText:SetSize(60, 20)
TimeDataText:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 5)

-- Create text
TimeDataText.text = TimeDataText:CreateFontString(nil, "OVERLAY")
TimeDataText.text:SetFont(ns.media.font, 11, "OUTLINE, MONOCHROME")
TimeDataText.text:SetPoint("CENTER")

-- Update function
local function UpdateTime()
    local hour, minute = GetGameTime()
    local text
    
    -- 12-hour format
    if ns.config and ns.config.datatexts and ns.config.datatexts.time24 then
        text = string.format("%02d:%02d", hour, minute)
    else
        local period = "AM"
        if hour >= 12 then
            period = "PM"
            if hour > 12 then
                hour = hour - 12
            end
        elseif hour == 0 then
            hour = 12
        end
        text = string.format("%d:%02d %s", hour, minute, period)
    end
    
    TimeDataText.text:SetText(text)
end

-- Tooltip
TimeDataText:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    
    -- Server time
    local hour, minute = GetGameTime()
    GameTooltip:AddLine("Time", 1, 1, 1)
    GameTooltip:AddDoubleLine("Server Time:", string.format("%02d:%02d", hour, minute), 1, 1, 1, 1, 1, 1)
    
    -- Local time
    local localTime = date("%H:%M")
    GameTooltip:AddDoubleLine("Local Time:", localTime, 1, 1, 1, 1, 1, 1)
    
    -- FPS and Latency
    local fps = GetFramerate()
    local _, _, latencyHome, latencyWorld = GetNetStats()
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("FPS:", string.format("%.1f", fps), 1, 1, 1, 0, 1, 0)
    GameTooltip:AddDoubleLine("Latency (Home):", string.format("%d ms", latencyHome), 1, 1, 1, 0, 1, 0)
    GameTooltip:AddDoubleLine("Latency (World):", string.format("%d ms", latencyWorld), 1, 1, 1, 0, 1, 0)
    
    GameTooltip:Show()
end)

TimeDataText:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Click to open calendar
TimeDataText:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        if Calendar_Toggle then
            Calendar_Toggle()
        elseif ToggleCalendar then
            ToggleCalendar()
        end
    elseif button == "RightButton" then
        if TimeManager_Toggle then
            TimeManager_Toggle()
        elseif ToggleTimeManager then
            ToggleTimeManager()
        end
    end
end)

-- Update timer
local elapsed = 0
TimeDataText:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        UpdateTime()
    end
end)

-- Initial update
UpdateTime()