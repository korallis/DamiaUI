-- DamiaUI Chat Module
-- Based on ColdMisc chat.lua, updated for WoW 11.2

local addonName, ns = ...
local Chat = {}
ns.Chat = Chat

-- Configuration
Chat.config = {}

-- Initialize module
function Chat:Initialize()
    -- Get config
    self.config = ns.config.chat
    
    if not self.config or not self.config.enabled then
        return
    end
    
    -- Setup chat frames
    self:SetupChatFrames()
    
    -- Setup chat tabs
    self:SetupChatTabs()
    
    -- Setup editbox
    self:SetupEditBox()
    
    -- Setup chat strings
    self:SetupChatStrings()
    
    -- Setup chat bubbles
    self:SetupChatBubbles()
    
    -- Hide buttons if configured
    if self.config.hideButtons then
        self:HideChatButtons()
    end
    
    -- Setup fading
    if self.config.fadeout then
        self:SetupChatFading()
    end
    
    -- Setup sticky channels
    self:SetupStickyChannels()
    
    -- Setup URL copy
    self:SetupURLCopy()
    
    ns:Print("Chat module loaded")
end

-- Setup chat frames
function Chat:SetupChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            -- Set font
            local font, size = frame:GetFont()
            frame:SetFont(self.config.font or ns.media.font, self.config.fontSize or 12, "OUTLINE")
            frame:SetShadowOffset(0, 0)
            frame:SetShadowColor(0, 0, 0, 0)
            
            -- Set frame properties
            frame:SetClampedToScreen(false)
            frame:SetClampRectInsets(0, 0, 0, 0)
            frame:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
            frame:SetMinResize(100, 50)
            
            -- Scale
            frame:SetScale(self.config.scale or 1)
            
            -- Remove background
            if frame.Background then
                frame.Background:Hide()
            end
            
            -- Create custom background
            if not frame.customBg then
                frame.customBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                frame.customBg:SetPoint("TOPLEFT", -3, 3)
                frame.customBg:SetPoint("BOTTOMRIGHT", 3, -3)
                frame.customBg:SetFrameLevel(frame:GetFrameLevel() - 1)
                ns:CreateBackdrop(frame.customBg, 0.5)
            end
            
            -- Timestamps
            if self.config.timestamps then
                frame:SetTimeVisible(120)
            end
            
            -- Max lines
            frame:SetMaxLines(1024)
            
            -- Disable mouse wheel without modifier
            frame:SetScript("OnMouseWheel", function(self, delta)
                if IsShiftKeyDown() then
                    if delta > 0 then
                        self:ScrollUp()
                    else
                        self:ScrollDown()
                    end
                end
            end)
        end
    end
end

-- Setup chat tabs
function Chat:SetupChatTabs()
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame"..i.."Tab"]
        if tab then
            -- Set font
            local tabText = _G["ChatFrame"..i.."TabText"]
            if tabText then
                tabText:SetFont(self.config.tabFont or ns.media.font, self.config.tabFontSize or 11, "OUTLINE")
                tabText:SetShadowOffset(0, 0)
            end
            
            -- Alpha
            tab:SetAlpha(1)
            tab.noMouseAlpha = 0.3
            
            -- Hide tab backgrounds
            local tabLeft = _G["ChatFrame"..i.."TabLeft"]
            local tabMiddle = _G["ChatFrame"..i.."TabMiddle"]
            local tabRight = _G["ChatFrame"..i.."TabRight"]
            
            if tabLeft then tabLeft:SetTexture(nil) end
            if tabMiddle then tabMiddle:SetTexture(nil) end
            if tabRight then tabRight:SetTexture(nil) end
            
            -- Hide active/flash textures
            local tabSelLeft = _G["ChatFrame"..i.."TabSelectedLeft"]
            local tabSelMiddle = _G["ChatFrame"..i.."TabSelectedMiddle"]
            local tabSelRight = _G["ChatFrame"..i.."TabSelectedRight"]
            
            if tabSelLeft then tabSelLeft:SetTexture(nil) end
            if tabSelMiddle then tabSelMiddle:SetTexture(nil) end
            if tabSelRight then tabSelRight:SetTexture(nil) end
            
            local tabHighLeft = _G["ChatFrame"..i.."TabHighlightLeft"]
            local tabHighMiddle = _G["ChatFrame"..i.."TabHighlightMiddle"]
            local tabHighRight = _G["ChatFrame"..i.."TabHighlightRight"]
            
            if tabHighLeft then tabHighLeft:SetTexture(nil) end
            if tabHighMiddle then tabHighMiddle:SetTexture(nil) end
            if tabHighRight then tabHighRight:SetTexture(nil) end
            
            -- Glow
            local tabGlow = _G["ChatFrame"..i.."TabGlow"]
            if tabGlow then
                tabGlow:SetTexture(nil)
            end
        end
    end
end

-- Setup editbox
function Chat:SetupEditBox()
    for i = 1, NUM_CHAT_WINDOWS do
        local editbox = _G["ChatFrame"..i.."EditBox"]
        if editbox then
            -- Hide textures
            local editboxLeft = _G["ChatFrame"..i.."EditBoxLeft"]
            local editboxMid = _G["ChatFrame"..i.."EditBoxMid"]
            local editboxRight = _G["ChatFrame"..i.."EditBoxRight"]
            
            if editboxLeft then editboxLeft:Hide() end
            if editboxMid then editboxMid:Hide() end
            if editboxRight then editboxRight:Hide() end
            
            -- Position
            editbox:ClearAllPoints()
            editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -2, 2)
            editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 2, 2)
            
            -- Font
            editbox:SetFont(self.config.font or ns.media.font, self.config.fontSize or 12, "OUTLINE")
            editbox:SetShadowOffset(0, 0)
            
            -- Height
            editbox:SetHeight(22)
            
            -- Create backdrop
            if not editbox.backdrop then
                editbox.backdrop = CreateFrame("Frame", nil, editbox, "BackdropTemplate")
                editbox.backdrop:SetPoint("TOPLEFT", -3, 3)
                editbox.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
                editbox.backdrop:SetFrameLevel(editbox:GetFrameLevel() - 1)
                ns:CreateBackdrop(editbox.backdrop, 0.7)
            end
            
            -- Alt arrow keys
            editbox:SetAltArrowKeyMode(false)
            
            -- Hide focus texture
            local focusLeft = _G["ChatFrame"..i.."EditBoxFocusLeft"]
            local focusMid = _G["ChatFrame"..i.."EditBoxFocusMid"]
            local focusRight = _G["ChatFrame"..i.."EditBoxFocusRight"]
            
            if focusLeft then focusLeft:SetTexture(nil) end
            if focusMid then focusMid:SetTexture(nil) end
            if focusRight then focusRight:SetTexture(nil) end
            
            -- Language icon
            local lang = _G["ChatFrame"..i.."EditBoxLanguage"]
            if lang then
                lang:ClearAllPoints()
                lang:SetPoint("LEFT", editbox, "RIGHT", 2, 0)
            end
        end
    end
end

-- Setup chat strings (simplify channel names)
function Chat:SetupChatStrings()
    -- Channel replacements
    CHAT_WHISPER_INFORM_GET = "To %s: "
    CHAT_WHISPER_GET = "From %s: "
    CHAT_BN_WHISPER_INFORM_GET = "To %s: "
    CHAT_BN_WHISPER_GET = "From %s: "
    CHAT_YELL_GET = "%s: "
    CHAT_SAY_GET = "%s: "
    CHAT_BATTLEGROUND_GET = "|Hchannel:Battleground|hBG|h %s: "
    CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:Battleground|hBGL|h %s: "
    CHAT_GUILD_GET = "|Hchannel:Guild|hG|h %s: "
    CHAT_OFFICER_GET = "|Hchannel:Officer|hO|h %s: "
    CHAT_PARTY_GET = "|Hchannel:Party|hP|h %s: "
    CHAT_PARTY_LEADER_GET = "|Hchannel:Party|hPL|h %s: "
    CHAT_PARTY_GUIDE_GET = "|Hchannel:Party|hPG|h %s: "
    CHAT_RAID_GET = "|Hchannel:Raid|hR|h %s: "
    CHAT_RAID_LEADER_GET = "|Hchannel:Raid|hRL|h %s: "
    CHAT_RAID_WARNING_GET = "RW %s: "
    CHAT_INSTANCE_CHAT_GET = "|Hchannel:Instance|hI|h %s: "
    CHAT_INSTANCE_CHAT_LEADER_GET = "|Hchannel:Instance|hIL|h %s: "
    
    -- Remove brackets from player links
    local function RemoveBrackets(self, event, msg, ...)
        msg = msg:gsub("|Hplayer:(.-)|h%[(.-)%]|h", "|Hplayer:%1|h%2|h")
        msg = msg:gsub("|HBNplayer:(.-)|h%[(.-)%]|h", "|HBNplayer:%1|h%2|h")
        return false, msg, ...
    end
    
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", RemoveBrackets)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", RemoveBrackets)
end

-- Setup chat bubbles
function Chat:SetupChatBubbles()
    -- Style chat bubbles
    local function StyleBubble(frame)
        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
            elseif region:GetObjectType() == "FontString" then
                region:SetFont(ns.media.font, 12, "OUTLINE")
                region:SetShadowOffset(0, 0)
            end
        end
        
        if not frame.backdrop then
            frame.backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame.backdrop:SetPoint("TOPLEFT", -3, 3)
            frame.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
            frame.backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
            ns:CreateBackdrop(frame.backdrop, 0.8)
        end
    end
    
    -- Hook chat bubble creation
    local function HookBubbles(...)
        for index = 1, select("#", ...) do
            local frame = select(index, ...)
            if frame and frame:GetObjectType() == "Frame" and not frame.styled then
                StyleBubble(frame)
                frame.styled = true
            end
        end
    end
    
    local bubbleHook = CreateFrame("Frame")
    bubbleHook:SetScript("OnUpdate", function()
        HookBubbles(WorldFrame:GetChildren())
    end)
end

-- Hide chat buttons
function Chat:HideChatButtons()
    -- Hide chat menu button
    ChatFrameMenuButton:Hide()
    ChatFrameMenuButton:SetScript("OnShow", function(self) self:Hide() end)
    
    -- Hide channel button
    ChatFrameChannelButton:Hide()
    ChatFrameChannelButton:SetScript("OnShow", function(self) self:Hide() end)
    
    -- Hide voice buttons
    if ChatFrameToggleVoiceDeafenButton then
        ChatFrameToggleVoiceDeafenButton:Hide()
        ChatFrameToggleVoiceDeafenButton:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    if ChatFrameToggleVoiceMuteButton then
        ChatFrameToggleVoiceMuteButton:Hide()
        ChatFrameToggleVoiceMuteButton:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    -- Hide quick join toast button
    QuickJoinToastButton:Hide()
    QuickJoinToastButton:SetScript("OnShow", function(self) self:Hide() end)
    
    -- Hide social button
    local button = _G["ChatFrame1ButtonFrame"]
    if button then
        button:Hide()
        button:SetScript("OnShow", function(self) self:Hide() end)
    end
end

-- Setup chat fading
function Chat:SetupChatFading()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            frame:SetFading(true)
            frame:SetFadeDuration(0.5)
            frame:SetTimeVisible(self.config.fadeoutTime or 10)
        end
    end
end

-- Setup sticky channels
function Chat:SetupStickyChannels()
    ChatTypeInfo["SAY"].sticky = 1
    ChatTypeInfo["PARTY"].sticky = 1
    ChatTypeInfo["RAID"].sticky = 1
    ChatTypeInfo["GUILD"].sticky = 1
    ChatTypeInfo["OFFICER"].sticky = 1
    ChatTypeInfo["YELL"].sticky = 0
    ChatTypeInfo["WHISPER"].sticky = 1
    ChatTypeInfo["BN_WHISPER"].sticky = 1
    ChatTypeInfo["CHANNEL"].sticky = 1
    ChatTypeInfo["INSTANCE_CHAT"].sticky = 1
end

-- Setup URL copy
function Chat:SetupURLCopy()
    local patterns = {
        "(https?://[%w%._%-%%%+%?&=/#@:]+)",
        "(www%.[%w%._%-%%%+%?&=/#@:]+)",
        "([%w%._%-]+@[%w%._%-]+%.%a+)",
    }
    
    for _, event in pairs({
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_BATTLEGROUND",
        "CHAT_MSG_BATTLEGROUND_LEADER",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_BN_WHISPER",
        "CHAT_MSG_BN_WHISPER_INFORM",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_INSTANCE_CHAT",
    }) do
        ChatFrame_AddMessageEventFilter(event, function(self, event, msg, ...)
            for _, pattern in pairs(patterns) do
                msg = msg:gsub(pattern, "|cff00ccff|Hurl:%1|h[%1]|h|r")
            end
            return false, msg, ...
        end)
    end
    
    -- Handle URL clicks
    local origSetHyperlink = ItemRefTooltip.SetHyperlink
    function ItemRefTooltip:SetHyperlink(link, ...)
        if link:match("^url:") then
            local url = link:sub(5)
            if not ChatEdit_GetActiveWindow() then
                ChatFrame_OpenChat(url, SELECTED_CHAT_FRAME)
            else
                ChatEdit_GetActiveWindow():Insert(url)
            end
        else
            origSetHyperlink(self, link, ...)
        end
    end
end

-- Register module
ns:RegisterModule("Chat", Chat)