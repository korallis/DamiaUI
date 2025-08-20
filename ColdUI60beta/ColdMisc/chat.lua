------------------------------------------------------------------------
--	Enhance/rewrite a Blizzard feature, chatframe mousewheel. (Tukui script)
------------------------------------------------------------------------
local numlines = 3
function FloatingChatFrame_OnMouseScroll(self, delta)
	if delta < 0 then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		else
			for i=1, numlines do
				self:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		else
			for i=1, numlines do
				self:ScrollUp()
			end
		end
	end
end

-----------------------------------------------------------------------
-- SETUP COLDKIL CHATS (modified verions of tukui module)
-----------------------------------------------------------------------
local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end
	object.Show = function() end
	object:Hide()
end

local ColdChat = CreateFrame("Frame")
local tabalpha = 1
local tabnoalpha = 0
local _G = _G
local origs = {}
local type = type
local _TEXTURE = "Interface\\AddOns\\ColdMisc\\media\\flat2"
local blankTex = "Interface\\AddOns\\ColdMisc\\media\\flat2"
local backdropfull = {
	bgFile = _TEXTURE,
	edgeFile = blankTex,
	edgeSize = 1,
}

-- function to rename channel and other stuff
local AddMessage = function(self, text, ...)
	if(type(text) == "string") then
		text = text:gsub('|h%[(%d+)%. .-%]|h', '|h[%1]|h')
	end
	return origs[self](self, text, ...)
end

-- Shortcut channel name
_G.CHAT_BATTLEGROUND_GET = "|Hchannel:Battleground|hbg|h %s:\32"
_G.CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:Battleground|hbgL|h %s:\32"
_G.CHAT_BN_WHISPER_GET = "from %s:\32"
_G.CHAT_GUILD_GET = "|Hchannel:Guild|hg|h %s:\32"
_G.CHAT_OFFICER_GET = "|Hchannel:o|ho|h %s:\32"
_G.CHAT_PARTY_GET = "|Hchannel:Party|hp|h %s:\32"
_G.CHAT_PARTY_GUIDE_GET = "|Hchannel:party|hpG|h %s:\32"
_G.CHAT_PARTY_LEADER_GET = "|Hchannel:party|hpL|h %s:\32"
_G.CHAT_RAID_GET = "|Hchannel:raid|hr|h %s:\32"
_G.CHAT_RAID_LEADER_GET = "|Hchannel:raid|hrL|h %s:\32"
_G.CHAT_RAID_WARNING_GET = "RW %s:\32"
_G.CHAT_SAY_GET = "%s:\32"
_G.CHAT_WHISPER_GET = "from %s:\32"
_G.CHAT_YELL_GET = "%s:\32"

-- color afk, dnd, gm
_G.CHAT_FLAG_AFK = "|cffFF0000[afk]|r "
_G.CHAT_FLAG_DND = "|cffE7E716[dnd]|r "
_G.CHAT_FLAG_GM = "|cff4154F5[gm]|r "

-- customize online/offline msg
_G.ERR_FRIEND_ONLINE_SS = "|Hplayer:%s|h[%s]|h is now |cff298F00online|r!"
_G.ERR_FRIEND_OFFLINE_S = "%s is now |cffff0000offline|r!"

-- Adding brackets to Blizzard timestamps
_G.TIMESTAMP_FORMAT_HHMM = "[%I:%M] "
_G.TIMESTAMP_FORMAT_HHMMSS = "[%I:%M:%S] "
_G.TIMESTAMP_FORMAT_HHMMSS_24HR = "[%H:%M:%S] "
_G.TIMESTAMP_FORMAT_HHMMSS_AMPM = "[%I:%M:%S %p] "
_G.TIMESTAMP_FORMAT_HHMM_24HR = "[%H:%M] "
_G.TIMESTAMP_FORMAT_HHMM_AMPM = "[%I:%M %p] "

-- Hide friends micro button (added in 3.3.5)
--FriendsMicroButton:Kill()
Kill(FriendsMicroButton)
-- hide chat bubble menu button
Kill(ChatFrameMenuButton)

-- set the chat style
local function SetChatStyle(frame)
	local id = frame:GetID()
	local chat = frame:GetName()
	local tab = _G[chat.."Tab"]
	
	-- always set alpha to 1, don't fade it anymore
	tab:SetAlpha(1)
	tab.SetAlpha = UIFrameFadeRemoveFrame

	if not frame.temp then
		-- hide text when setting chat
		_G[chat.."TabText"]:Hide()
		
		-- now show text if mouse is found over tab.
		tab:HookScript("OnEnter", function() _G[chat.."TabText"]:Show() end)
		tab:HookScript("OnLeave", function() _G[chat.."TabText"]:Hide() end)
	end
	
	-- yeah baby
	_G[chat]:SetClampRectInsets(0,0,0,0)
	
	-- Removes crap from the bottom of the chatbox so it can go to the bottom of the screen.
	_G[chat]:SetClampedToScreen(false)
			
	-- Stop the chat chat from fading out
	_G[chat]:SetFading(false)
	
	-- set height/width
	_G[chat]:SetSize(300, 100)
	
	-- move the chat edit box and set the correct fonts
	_G[chat.."EditBox"]:ClearAllPoints()
	_G[chat.."EditBox"]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 10)
	_G[chat.."EditBox"]:SetSize(316, 17)
	_G[chat..'EditBox']:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
	_G[chat..'EditBox']:SetShadowOffset(0,0)
	_G[chat..'EditBoxHeader']:SetFont("Interface\\AddOns\\ColdMisc\\media\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
	_G[chat..'EditBoxHeader']:SetShadowOffset(0,0)
	
	_G[chat..'EditBox']:SetScript("OnShow", function(self) _G["dataTextPanel"]:Hide() end)
	_G[chat..'EditBox']:SetScript("OnHide", function(self) _G["dataTextPanel"]:Show() end)

	-- Hide textures
	for j = 1, #CHAT_FRAME_TEXTURES do
		_G[chat..CHAT_FRAME_TEXTURES[j]]:SetTexture(nil)
	end

	-- Removes Default ChatFrame Tabs texture				
	Kill(_G[format("ChatFrame%sTabLeft", id)])
	Kill(_G[format("ChatFrame%sTabMiddle", id)])
	Kill(_G[format("ChatFrame%sTabRight", id)])

	Kill(_G[format("ChatFrame%sTabSelectedLeft", id)])
	Kill(_G[format("ChatFrame%sTabSelectedMiddle", id)])
	Kill(_G[format("ChatFrame%sTabSelectedRight", id)])
	
	Kill(_G[format("ChatFrame%sTabHighlightLeft", id)])
	Kill(_G[format("ChatFrame%sTabHighlightMiddle", id)])
	Kill(_G[format("ChatFrame%sTabHighlightRight", id)])

	-- Killing off the new chat tab selected feature
	Kill(_G[format("ChatFrame%sTabSelectedLeft", id)])
	Kill(_G[format("ChatFrame%sTabSelectedMiddle", id)])
	Kill(_G[format("ChatFrame%sTabSelectedRight", id)])

	-- Kills off the new method of handling the Chat Frame scroll buttons as well as the resize button
	-- Note: This also needs to include the actual frame textures for the ButtonFrame onHover
	Kill(_G[format("ChatFrame%sButtonFrameUpButton", id)])
	Kill(_G[format("ChatFrame%sButtonFrameDownButton", id)])
	Kill(_G[format("ChatFrame%sButtonFrameBottomButton", id)])
	Kill(_G[format("ChatFrame%sButtonFrameMinimizeButton", id)])
	Kill(_G[format("ChatFrame%sButtonFrame", id)])

	-- Kills off the retarded new circle around the editbox
	Kill(_G[format("ChatFrame%sEditBoxFocusLeft", id)])
	Kill(_G[format("ChatFrame%sEditBoxFocusMid", id)])
	Kill(_G[format("ChatFrame%sEditBoxFocusRight", id)])

	-- Kill off editbox artwork
	local a, b, c = select(6, _G[chat.."EditBox"]:GetRegions()) Kill(a) Kill(b) Kill(c)
	
	-- bubble tex & glow killing from privates
	if tab.glow then Kill(tab.glow) end
	if tab.conversationIcon then Kill(tab.conversationIcon) end
				
	-- Disable alt key usage
	_G[chat.."EditBox"]:SetAltArrowKeyMode(false)
	
	-- hide editbox on login
	_G[chat.."EditBox"]:Hide()

	-- script to hide editbox instead of fading editbox to 0.35 alpha via IM Style
	_G[chat.."EditBox"]:HookScript("OnEditFocusLost", function(self) self:Hide() end)
	
	-- hide edit box every time we click on a tab
	_G[chat.."Tab"]:HookScript("OnClick", function() _G[chat.."EditBox"]:Hide() end)
			
	-- create our own texture for edit box
	local EditBoxBackground = CreateFrame("frame", "ColdChatEditBoxBackground", _G[chat.."EditBox"])
	EditBoxBackground:ClearAllPoints()
	EditBoxBackground:SetAllPoints(_G[chat.."EditBox"])
	EditBoxBackground:SetBackdrop(backdropfull)
	EditBoxBackground:SetBackdropColor(.2,.2,.2,.6)
	EditBoxBackground:SetBackdropBorderColor(0,0,0)
	EditBoxBackground:SetFrameStrata("LOW")
	EditBoxBackground:SetFrameLevel(1)
	
	local function colorize(r,g,b)
		EditBoxBackground:SetBackdropBorderColor(r, g, b)
	end
	
	-- update border color according where we talk
	hooksecurefunc("ChatEdit_UpdateHeader", function()
		local type = _G[chat.."EditBox"]:GetAttribute("chatType")
		if ( type == "CHANNEL" ) then
		local id = GetChannelName(_G[chat.."EditBox"]:GetAttribute("channelTarget"))
			if id == 0 then
				colorize(0,0,0)
			else
				colorize(ChatTypeInfo[type..id].r,ChatTypeInfo[type..id].g,ChatTypeInfo[type..id].b)
			end
		else
			colorize(ChatTypeInfo[type].r,ChatTypeInfo[type].g,ChatTypeInfo[type].b)
		end
	end)
	
	if _G[chat] ~= _G["ChatFrame2"] then
		origs[_G[chat]] = _G[chat].AddMessage
		_G[chat].AddMessage = AddMessage
	end
	
	frame.skinned = true
end

-- Setup chatframes 1 to 10 on login.
local function SetupChat(self)	
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G[format("ChatFrame%s", i)]
		_G["ChatFrame" .. i]:SetFont("Interface\\AddOns\\oUF_Coldkil\\fonts\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
		_G["ChatFrame" .. i]:SetShadowOffset(0,0)
		SetChatStyle(frame)
		FCFTab_UpdateAlpha(frame)
	end
				
	-- Remember last channel
	ChatTypeInfo.WHISPER.sticky = 1
	ChatTypeInfo.BN_WHISPER.sticky = 1
	ChatTypeInfo.OFFICER.sticky = 1
	ChatTypeInfo.RAID_WARNING.sticky = 1
	ChatTypeInfo.CHANNEL.sticky = 1
end

local function SetupChatPosAndFont(self)	
	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G[format("ChatFrame%s", i)]
		local tab = _G[format("ChatFrame%sTab", i)]
		local id = chat:GetID()
		local name = FCF_GetChatWindowInfo(id)
		local point = GetChatWindowSavedPosition(id)
		local _, fontSize = FCF_GetChatWindowInfo(id)

		FCF_SetChatWindowFontSize(nil, chat, 10)

		
		-- force chat position on #1 a
		if i == 1 then
			chat:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 35)
			FCF_SavePositionAndDimensions(chat)
		end
	end
			
	-- reposition battle.net popup over chat #1
	BNToastFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 6)
	end)
end

ColdChat:RegisterEvent("ADDON_LOADED")
ColdChat:RegisterEvent("PLAYER_ENTERING_WORLD")
ColdChat:SetScript("OnEvent", function(self, event, ...)
	local addon = ...
	if event == "ADDON_LOADED" then
		if addon == "Blizzard_CombatLog" then
			self:UnregisterEvent("ADDON_LOADED")
			SetupChat(self)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		SetupChatPosAndFont(self)
	end
end)

-- Setup temp chat (BN, WHISPER) when needed.
local function SetupTempChat()
	local frame = FCF_GetCurrentChatFrame()

	-- do a check if we already did a skinning earlier for this temp chat frame
	if frame.skinned then return end
	
	-- style it
	frame.temp = true
	SetChatStyle(frame)
end
hooksecurefunc("FCF_OpenTemporaryWindow", SetupTempChat)