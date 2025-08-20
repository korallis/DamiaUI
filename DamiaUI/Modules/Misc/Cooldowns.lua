--------------------------------------------------------------------
-- DamiaUI Misc - Cooldown Text
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

-- Check if cooldown addons are already loaded (11.2 compatible)
if C_AddOns and C_AddOns.IsAddOnLoaded then
    if C_AddOns.IsAddOnLoaded("OmniCC") or C_AddOns.IsAddOnLoaded("ncCooldown") then 
        return 
    end
elseif IsAddOnLoaded then
    -- Fallback for older versions
    if IsAddOnLoaded("OmniCC") or IsAddOnLoaded("ncCooldown") then 
        return 
    end
end

local Cooldowns = {}

-- Module registration
ns:RegisterModule("Cooldowns", Cooldowns)

function Cooldowns:Initialize()
    if not ns:GetConfig("misc", "cooldownText") then
        return
    end
    
    self:SetupCooldowns()
end

function Cooldowns:SetupCooldowns()
    -- Constants
    OmniCC = true --hack to work around detection from other addons for OmniCC
    local ICON_SIZE = 36 --the normal size for an icon (don't change this)
    local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
    local DAYISH, HOURISH, MINUTEISH = 3600 * 23.5, 60 * 59.5, 59.5 --used for formatting text at transition points
    local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5 --used for calculating next update times
    
    local Round = function(number, decimals)
        if not decimals then decimals = 0 end
        return (("%%.%df"):format(decimals)):format(number)
    end
    
    local RGBToHex = function(r, g, b)
        r = r <= 1 and r >= 0 and r or 0
        g = g <= 1 and g >= 0 and g or 0
        b = b <= 1 and b >= 0 and b or 0
        return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    end
    
    -- Configuration settings
    local FONT_FACE = ns.media.font -- Use DamiaUI font
    local FONT_SIZE = 10 -- The base font size to use at a scale of 1
    local MIN_SCALE = 0.5 -- The minimum scale we want to show cooldown counts at
    local MIN_DURATION = 2.5 -- The minimum duration to show cooldown text for
    local EXPIRING_DURATION = 1.5 -- The minimum number of seconds a cooldown must be to display in the expiring format

    local EXPIRING_FORMAT = RGBToHex(1, 0, 0)..'%.1f|r' -- Format for timers that are soon to expire
    local SECONDS_FORMAT = RGBToHex(1, 1, 0)..'%d|r' -- Format for timers that have seconds remaining
    local MINUTES_FORMAT = RGBToHex(1, 1, 1)..'%dm|r' -- Format for timers that have minutes remaining
    local HOURS_FORMAT = RGBToHex(0.4, 1, 1)..'%dh|r' -- Format for timers that have hours remaining
    local DAYS_FORMAT = RGBToHex(0.4, 0.4, 1)..'%dh|r' -- Format for timers that have days remaining

    -- Local bindings
    local floor = math.floor
    local min = math.min
    local GetTime = GetTime

    -- Returns both what text to display, and how long until the next update
    local function getTimeText(s)
        -- Format text as seconds when below a minute
        if s < MINUTEISH then
            local seconds = tonumber(Round(s))
            if seconds > EXPIRING_DURATION then
                return SECONDS_FORMAT, seconds, s - (seconds - 0.51)
            else
                return EXPIRING_FORMAT, s, 0.051
            end
        -- Format text as minutes when below an hour
        elseif s < HOURISH then
            local minutes = tonumber(Round(s/MINUTE))
            return MINUTES_FORMAT, minutes, minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
        -- Format text as hours when below a day
        elseif s < DAYISH then
            local hours = tonumber(Round(s/HOUR))
            return HOURS_FORMAT, hours, hours > 1 and (s - (hours*HOUR - HALFHOURISH)) or (s - HOURISH)
        -- Format text as days
        else
            local days = tonumber(Round(s/DAY))
            return DAYS_FORMAT, days, days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
        end
    end

    -- Stops the timer
    local function Timer_Stop(self)
        self.enabled = nil
        self:Hide()
    end

    -- Forces the given timer to update on the next frame
    local function Timer_ForceUpdate(self)
        self.nextUpdate = 0
        self:Show()
    end

    -- Adjust font size whenever the timer's parent size changes
    -- Hide if it gets too tiny
    local function Timer_OnSizeChanged(self, width, height)
        local fontScale = Round(width) / ICON_SIZE
        if fontScale == self.fontScale then
            return
        end

        self.fontScale = fontScale
        if fontScale < MIN_SCALE then
            self:Hide()
        else
            self.text:SetFont(FONT_FACE, FONT_SIZE, 'OUTLINE, MONOCHROME')
            self.text:SetShadowColor(0, 0, 0, 0.5)
            self.text:SetShadowOffset(0, 0)
            if self.enabled then
                Timer_ForceUpdate(self)
            end
        end
    end

    -- Update timer text, if it needs to be
    -- Hide the timer if done
    local function Timer_OnUpdate(self, elapsed)
        if self.nextUpdate > 0 then
            self.nextUpdate = self.nextUpdate - elapsed
        else
            local remain = self.duration - (GetTime() - self.start)
            if tonumber(Round(remain)) > 0 then
                if (self.fontScale * self:GetEffectiveScale() / UIParent:GetScale()) < MIN_SCALE then
                    self.text:SetText('')
                    self.nextUpdate = 1
                else
                    local formatStr, time, nextUpdate = getTimeText(remain)
                    self.text:SetFormattedText(formatStr, time)
                    self.nextUpdate = nextUpdate
                end
            else
                Timer_Stop(self)
            end
        end
    end

    -- Returns a new timer object
    local function Timer_Create(self)
        -- A frame to watch for OnSizeChanged events
        -- Needed since OnSizeChanged has funny triggering if the frame with the handler is not shown
        local scaler = CreateFrame('Frame', nil, self)
        scaler:SetAllPoints(self)

        local timer = CreateFrame('Frame', nil, scaler)
        timer:Hide()
        timer:SetAllPoints(scaler)
        timer:SetScript('OnUpdate', Timer_OnUpdate)

        local text = timer:CreateFontString(nil, 'OVERLAY')
        text:SetPoint("CENTER", .5, .5)
        text:SetJustifyH("CENTER")
        timer.text = text

        Timer_OnSizeChanged(timer, scaler:GetSize())
        scaler:SetScript('OnSizeChanged', function(self, ...) Timer_OnSizeChanged(timer, ...) end)

        self.timer = timer
        return timer
    end

    -- Hook the SetCooldown method of all cooldown frames
    local function Timer_Start(self, start, duration)
        if self.noOCC then return end
        
        -- Start timer
        if start > 0 and duration > MIN_DURATION then
            local timer = self.timer or Timer_Create(self)
            timer.start = start
            timer.duration = duration
            timer.enabled = true
            timer.nextUpdate = 0
            if timer.fontScale >= MIN_SCALE then 
                timer:Show() 
            end
        -- Stop timer
        else
            local timer = self.timer
            if timer then
                Timer_Stop(timer)
            end
        end
    end

    -- Try to hook cooldown frames safely
    local function HookCooldownFrame()
        -- Try different methods to find a cooldown frame to hook
        local cooldownFrame
        
        if ActionButton1Cooldown then
            cooldownFrame = ActionButton1Cooldown
        elseif _G["ActionButton1"] and _G["ActionButton1"].cooldown then
            cooldownFrame = _G["ActionButton1"].cooldown
        end
        
        if cooldownFrame then
            hooksecurefunc(getmetatable(cooldownFrame).__index, "SetCooldown", Timer_Start)
        end
    end

    -- New function registers due to API updates
    local active = {}
    local hooked = {}

    local function cooldown_OnShow(self)
        active[self] = true
    end

    local function cooldown_OnHide(self)
        active[self] = nil
    end

    local function cooldown_ShouldUpdateTimer(self, start, duration)
        local timer = self.timer
        if not timer then
            return true
        end
        return timer.start ~= start
    end

    local function cooldown_Update(self)
        local button = self:GetParent()
        if button and button.action then
            local start, duration, enable = GetActionCooldown(button.action)
            if cooldown_ShouldUpdateTimer(self, start, duration) then
                Timer_Start(self, start, duration)
            end
        end
    end

    local EventWatcher = CreateFrame("Frame")
    EventWatcher:Hide()
    EventWatcher:SetScript("OnEvent", function(self, event)
        for cooldown in pairs(active) do
            cooldown_Update(cooldown)
        end
    end)
    EventWatcher:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

    local function actionButton_Register(frame)
        local cooldown = frame.cooldown
        if cooldown and not hooked[cooldown] then
            cooldown:HookScript("OnShow", cooldown_OnShow)
            cooldown:HookScript("OnHide", cooldown_OnHide)
            hooked[cooldown] = true
        end
    end

    -- Register existing action buttons
    if _G["ActionBarButtonEventsFrame"] and _G["ActionBarButtonEventsFrame"].frames then
        for i, frame in pairs(_G["ActionBarButtonEventsFrame"].frames) do
            actionButton_Register(frame)
        end
    end

    -- Hook future action button registrations
    if ActionBarButtonEventsFrame_RegisterFrame then
        hooksecurefunc("ActionBarButtonEventsFrame_RegisterFrame", actionButton_Register)
    end

    -- Initial hook attempt
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("PLAYER_LOGIN")
    hookFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            HookCooldownFrame()
            self:UnregisterEvent("PLAYER_LOGIN")
        end
    end)
end

return Cooldowns