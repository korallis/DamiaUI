--------------------------------------------------------------------
-- DamiaUI Misc - Blizzard UI Reskin
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

local BlizzReskin = {}

-- Module registration
ns:RegisterModule("BlizzReskin", BlizzReskin)

function BlizzReskin:Initialize()
    self:SetupChatBubbles()
    self:SetupMirrorTimers()
end

function BlizzReskin:SetupChatBubbles()
    -------------------------------------------------------------------
    -- Chat Bubbles reskin
    -------------------------------------------------------------------
    
    local chatbubblehook = CreateFrame("Frame", nil, UIParent)
    local noscalemult = 1
    local tslu = 0
    local numkids = 0
    local bubbles = {}

    local function skinbubble(frame)
        local offset = UIParent:GetScale() / frame:GetEffectiveScale()
        for i=1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
            elseif region:GetObjectType() == "FontString" then
                frame.text = region
                frame.text:SetFont(ns.media.font, 10*offset, "OUTLINE, MONOCHROME")
            end
        end
        
        frame:SetBackdrop({
            bgFile = ns.media.texture,
            edgeFile = ns.media.texture,
            edgeSize = offset,
        })
        frame:SetBackdropBorderColor(.6, .6, .6)
        frame:SetBackdropColor(.1, .1, .1, .8)
        
        table.insert(bubbles, frame)
    end

    local function ischatbubble(frame)
        if frame:GetName() then return end
        if not frame:GetRegions() then return end
        return frame:GetRegions():GetTexture() == [[Interface\Tooltips\ChatBubble-Background]]
    end

    chatbubblehook:SetScript("OnUpdate", function(chatbubblehook, elapsed)
        tslu = tslu + elapsed

        if tslu > .05 then
            tslu = 0

            local newnumkids = WorldFrame:GetNumChildren()
            if newnumkids ~= numkids then
                for i=numkids + 1, newnumkids do
                    local frame = select(i, WorldFrame:GetChildren())

                    if ischatbubble(frame) then
                        skinbubble(frame)
                    end
                end
                numkids = newnumkids
            end
            
            for i, frame in next, bubbles do
                if frame.text then
                    local r, g, b = frame.text:GetTextColor()
                    frame:SetBackdropBorderColor(r, g, b, .8)
                end
            end
        end
    end)
end

function BlizzReskin:SetupMirrorTimers()
    ---------------------------------------------------------------------
    -- Mirror bar (breath, fatigue, feign death), original by haste
    ---------------------------------------------------------------------
    
    local _DEFAULTS = {
        width = 250,
        height = 13,
        texture = ns.media.texture,

        position = {
            ["BREATH"] = 'TOP#UIParent#TOP#0#-156';
            ["EXHAUSTION"] = 'TOP#UIParent#TOP#0#-179';
            ["FEIGNDEATH"] = 'TOP#UIParent#TOP#0#-202';
        };

        colors = {
            EXHAUSTION = {1, .9, 0};
            BREATH = {0.31, 0.45, 0.63};
            DEATH = {1, .7, 0};
            FEIGNDEATH = {1, .7, 0};
        };
    }

    local settings = _DEFAULTS

    local Spawn, PauseAll
    do
        local barPool = {}

        local loadPosition = function(self)
            local pos = settings.position[self.type]
            local p1, frame, p2, x, y = strsplit("#", pos)

            return self:SetPoint(p1, frame, p2, x, y)
        end

        local OnUpdate = function(self, elapsed)
            if(self.paused) then return end

            self:SetValue(GetMirrorTimerProgress(self.type) / 1e3)
        end

        local Start = function(self, value, maxvalue, scale, paused, text)
            if(paused > 0) then
                self.paused = 1
            elseif(self.paused) then
                self.paused = nil
            end

            self.text:SetText(text)

            self:SetMinMaxValues(0, maxvalue / 1e3)
            self:SetValue(value / 1e3)

            if(not self:IsShown()) then self:Show() end
        end

        local Stop = function(self)
            self:Hide()
        end

        function Spawn(type)
            if(barPool[type]) then return barPool[type] end
            local frame = CreateFrame('StatusBar', nil, UIParent)

            frame:SetScript("OnUpdate", OnUpdate)

            local r, g, b = unpack(settings.colors[type])
            
            local backdrop = {
                bgFile = ns.media.texture,
                edgeFile = ns.media.texture,
                edgeSize = 1,
            }
            
            local border = CreateFrame("Frame", nil, frame)
            border:SetPoint("TOPLEFT", frame, -1, 1)
            border:SetPoint("BOTTOMRIGHT", frame, 1, -1)
            border:SetBackdrop(backdrop)
            border:SetBackdropColor(.2, .2, .2, .6)
            border:SetBackdropBorderColor(0, 0, 0)
            border:SetFrameLevel(0)

            local text = frame:CreateFontString(nil, 'OVERLAY')
            text:SetFont(ns.media.font, 10, "OUTLINE, MONOCHROME")
            text:SetJustifyH('CENTER')
            text:SetTextColor(1, 1, 1)
            text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 1)
            text:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 1)

            frame:SetSize(settings.width, settings.height)
            frame:SetStatusBarTexture(settings.texture)
            frame:SetStatusBarColor(r, g, b)
            frame.type = type
            frame.text = text
            frame.Start = Start
            frame.Stop = Stop

            loadPosition(frame)

            barPool[type] = frame
            return frame
        end

        function PauseAll(val)
            for _, bar in next, barPool do
                bar.paused = val
            end
        end
    end

    local frame = CreateFrame('Frame')
    frame:SetScript('OnEvent', function(self, event, ...)
        return self[event](self, ...)
    end)

    function frame:ADDON_LOADED(addon)
        if(addon == addonName) then
            UIParent:UnregisterEvent('MIRROR_TIMER_START')

            self:UnregisterEvent('ADDON_LOADED')
            self.ADDON_LOADED = nil
        end
    end
    frame:RegisterEvent('ADDON_LOADED')

    function frame:PLAYER_ENTERING_WORLD()
        for i=1, MIRRORTIMER_NUMTIMERS do
            local type, value, maxvalue, scale, paused, text = GetMirrorTimerInfo(i)
            if(type ~= 'UNKNOWN') then
                Spawn(type):Start(value, maxvalue, scale, paused, text)
            end
        end
    end
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')

    function frame:MIRROR_TIMER_START(type, value, maxvalue, scale, paused, text)
        return Spawn(type):Start(value, maxvalue, scale, paused, text)
    end
    frame:RegisterEvent('MIRROR_TIMER_START')

    function frame:MIRROR_TIMER_STOP(type)
        return Spawn(type):Hide()
    end
    frame:RegisterEvent('MIRROR_TIMER_STOP')

    function frame:MIRROR_TIMER_PAUSE(duration)
        return PauseAll((duration > 0 and duration) or nil)
    end
    frame:RegisterEvent('MIRROR_TIMER_PAUSE')
end

return BlizzReskin