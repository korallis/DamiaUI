--[[
Name: AceEvent-3.0
Revision: $Rev: 1270 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-event-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceEvent-3.0 provides event registration and secure dispatching.
It allows for easy registration of Blizzard events and custom events.

License:
    Copyright (c) 2007, Ace3 Development Team

    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice,
          this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.
        * Redistribution of a standalone version is strictly prohibited without
          prior written authorization from the copyright holder.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local MAJOR, MINOR = "DamiaUI_AceEvent-3.0", 4
local AceEvent, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end -- No upgrade needed

-- Lua APIs
local pairs, select, unpack, type = pairs, select, unpack, type
local tconcat = table.concat
local tremove, tinsert = table.remove, table.insert

-- WoW APIs
local _G = _G
local frame

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, geterrorhandler

-- Constants
AceEvent.frame = AceEvent.frame or CreateFrame("Frame", "DamiaUI_AceEvent30Frame")
AceEvent.embeds = AceEvent.embeds or {}
AceEvent.registry = AceEvent.registry or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end})

-- Local variables
local registry = AceEvent.registry
local embeds = AceEvent.embeds
frame = AceEvent.frame

-- Utility functions
local function safecall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		geterrorhandler()(err)
	end
	return success, err
end

-- Event dispatcher
local function OnEvent(this, event, ...)
	local eventRegistry = registry[event]
	if eventRegistry then
		for object, method in pairs(eventRegistry) do
			if type(method) == "string" then
				if type(object[method]) == "function" then
					safecall(object[method], object, event, ...)
				end
			else
				if type(method) == "function" then
					safecall(method, object, event, ...)
				end
			end
		end
	end
end

frame:SetScript("OnEvent", OnEvent)

-- Message dispatcher
local function OnSendMessage(this, message, ...)
	local messageRegistry = registry[message]
	if messageRegistry then
		for object, method in pairs(messageRegistry) do
			if type(method) == "string" then
				if type(object[method]) == "function" then
					safecall(object[method], object, message, ...)
				end
			else
				if type(method) == "function" then
					safecall(method, object, message, ...)
				end
			end
		end
	end
end

-- Embedding targets
local mixins = {
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "IsEventRegistered",
	"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages", "IsMessageRegistered",
	"SendMessage"
}

-- Event handling methods
local function RegisterEvent(self, event, method)
	if type(event) ~= "string" then
		error("Usage: RegisterEvent(event, method)", 2)
	end
	
	method = method or event
	
	if registry[event][self] then
		-- already registered
		return
	end
	
	registry[event][self] = method
	frame:RegisterEvent(event)
end

local function UnregisterEvent(self, event)
	if not registry[event][self] then return end
	
	registry[event][self] = nil
	
	-- Check if any other objects are registered for this event
	local hasRegistry = false
	for k, v in pairs(registry[event]) do
		hasRegistry = true
		break
	end
	
	if not hasRegistry then
		frame:UnregisterEvent(event)
	end
end

local function UnregisterAllEvents(self)
	for event, eventRegistry in pairs(registry) do
		if eventRegistry[self] then
			UnregisterEvent(self, event)
		end
	end
end

local function IsEventRegistered(self, event)
	return registry[event][self] ~= nil
end

-- Message handling methods
local function RegisterMessage(self, message, method)
	if type(message) ~= "string" then
		error("Usage: RegisterMessage(message, method)", 2)
	end
	
	method = method or message
	registry[message][self] = method
end

local function UnregisterMessage(self, message)
	registry[message][self] = nil
end

local function UnregisterAllMessages(self)
	for message, messageRegistry in pairs(registry) do
		if messageRegistry[self] then
			UnregisterMessage(self, message)
		end
	end
end

local function IsMessageRegistered(self, message)
	return registry[message][self] ~= nil
end

local function SendMessage(self, message, ...)
	OnSendMessage(frame, message, ...)
end

-- Embedding
AceEvent.RegisterEvent = RegisterEvent
AceEvent.UnregisterEvent = UnregisterEvent
AceEvent.UnregisterAllEvents = UnregisterAllEvents
AceEvent.IsEventRegistered = IsEventRegistered
AceEvent.RegisterMessage = RegisterMessage
AceEvent.UnregisterMessage = UnregisterMessage
AceEvent.UnregisterAllMessages = UnregisterAllMessages
AceEvent.IsMessageRegistered = IsMessageRegistered
AceEvent.SendMessage = SendMessage

local mixinTargets = AceEvent.mixinTargets or {}
AceEvent.mixinTargets = mixinTargets

function AceEvent:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	embeds[target] = true
	mixinTargets[target] = true
	return target
end

-- Upgrade embedded
for target, v in pairs(mixinTargets) do
	AceEvent:Embed(target)
end

-- Cleanup on upgrade
if oldminor and oldminor < MINOR then
	-- Cleanup old registry
	for event, eventRegistry in pairs(registry) do
		local hasReg = false
		for k, v in pairs(eventRegistry) do
			hasReg = true
			break
		end
		if not hasReg then
			frame:UnregisterEvent(event)
		end
	end
end

-- Finish up
AceEvent.mixins = mixins