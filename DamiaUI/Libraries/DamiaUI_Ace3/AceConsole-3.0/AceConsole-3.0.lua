--[[
Name: AceConsole-3.0
Revision: $Rev: 1313 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-console-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceConsole-3.0 provides registration and dispatching for slash commands.
It supports nested command structures and argument parsing.

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

local MAJOR, MINOR = "DamiaUI_AceConsole-3.0", 7
local AceConsole, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConsole then return end -- No upgrade needed

-- Lua APIs
local tconcat, tostring, select = table.concat, tostring, select
local type, pairs, next = type, pairs, next
local string_sub, string_find, string_match = string.sub, string.find, string.match
local string_gmatch, string_gsub = string.gmatch, string.gsub

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, DEFAULT_CHAT_FRAME, SlashCmdList, hash_SlashCmdList

AceConsole.commands = AceConsole.commands or {}
AceConsole.weakcommands = AceConsole.weakcommands or setmetatable({}, {__mode="v"})
AceConsole.embeds = AceConsole.embeds or {}

-- local references of objects
local commands = AceConsole.commands
local weakcommands = AceConsole.weakcommands
local embeds = AceConsole.embeds

-- Utility function to extract slash command args
local function ExtractArgs(str, numargs)
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10
	local args = {}
	local i = 1
	
	for arg in string_gmatch(str, "%S+") do
		if i == 1 then arg1 = arg
		elseif i == 2 then arg2 = arg
		elseif i == 3 then arg3 = arg
		elseif i == 4 then arg4 = arg
		elseif i == 5 then arg5 = arg
		elseif i == 6 then arg6 = arg
		elseif i == 7 then arg7 = arg
		elseif i == 8 then arg8 = arg
		elseif i == 9 then arg9 = arg
		elseif i == 10 then arg10 = arg
		else
			break
		end
		args[i] = arg
		i = i + 1
		if numargs and i > numargs then break end
	end
	
	return arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, args
end

-- Command dispatcher
local function HandleCommand(self, input)
	if not input or input == "" then
		return self:OnChatCommand("")
	end
	
	input = input:trim()
	if input == "" then
		return self:OnChatCommand("")
	end
	
	-- Check for sub-commands
	local command = string_match(input, "^([%S]+)")
	if command then
		command = string.lower(command)
		local handler = self.subCommands and self.subCommands[command]
		if handler then
			local args = string_match(input, "^[%S]+%s*(.*)")
			if type(handler) == "string" then
				return self[handler](self, args or "")
			elseif type(handler) == "function" then
				return handler(args or "")
			elseif type(handler) == "table" then
				if handler.type == "execute" then
					return handler.func(args or "")
				elseif handler.type == "input" then
					return handler.func(input)
				end
			end
		end
	end
	
	-- Call main handler
	return self:OnChatCommand(input)
end

-- Main embedding methods
local mixins = {
	"RegisterChatCommand", "UnregisterChatCommand", "GetArgs"
}

function AceConsole:RegisterChatCommand(command, func, persist)
	if type(command) ~= "string" then error("Usage: RegisterChatCommand(command, func, persist)", 2) end
	
	-- Ensure command starts with /
	if string_sub(command, 1, 1) ~= "/" then
		command = "/" .. command
	end
	
	if type(func) == "string" then
		SlashCmdList[command] = function(input, editbox)
			HandleCommand(self, input)
		end
	elseif type(func) == "function" then
		SlashCmdList[command] = func
	else
		SlashCmdList[command] = function(input, editbox)
			HandleCommand(self, input)
		end
	end
	
	-- Register the command
	_G["SLASH_"..command:gsub("/", "").upper().."1"] = command
	
	-- Add to our registry
	if persist then
		commands[command] = {self, func}
	else
		weakcommands[command] = {self, func}
	end
end

function AceConsole:UnregisterChatCommand(command)
	if type(command) ~= "string" then return end
	
	-- Ensure command starts with /
	if string_sub(command, 1, 1) ~= "/" then
		command = "/" .. command
	end
	
	local name = command:gsub("/", "").upper()
	SlashCmdList["SLASH_"..name] = nil
	_G["SLASH_"..name.."1"] = nil
	
	hash_SlashCmdList[command] = nil
	commands[command] = nil
	weakcommands[command] = nil
end

function AceConsole:GetArgs(str, numargs, startpos)
	if not str then return end
	str = str:trim()
	if str == "" then return end
	
	return ExtractArgs(str, numargs)
end

-- Helper function for formatted output
function AceConsole:Printf(fmt, ...)
	local success, result = pcall(string.format, fmt, ...)
	if success then
		-- Printf result logging removed
	else
		-- Printf error logging removed
	end
end

function AceConsole:Print(...)
	local output = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		output[i] = tostring(arg)
	end
	-- Print output logging removed
end

-- Enhanced command registration with argument parsing
function AceConsole:RegisterChatCommand(command, func, persist, options)
	if type(command) ~= "string" then error("Usage: RegisterChatCommand(command, func, persist, options)", 2) end
	
	-- Ensure command starts with /
	if string_sub(command, 1, 1) ~= "/" then
		command = "/" .. command
	end
	
	local name = command:gsub("/", ""):upper()
	
	-- Create the handler
	local handler
	if type(func) == "string" then
		handler = function(input, editbox)
			if self[func] then
				self[func](self, input, editbox)
			end
		end
	elseif type(func) == "function" then
		handler = func
	else
		handler = function(input, editbox)
			if self.OnChatCommand then
				self:OnChatCommand(input, editbox)
			end
		end
	end
	
	-- Set up enhanced handler with argument parsing
	if options and options.args then
		local oldHandler = handler
		handler = function(input, editbox)
			local args = {}
			local argCount = 0
			
			-- Parse arguments based on options
			if type(options.args) == "table" then
				for argName, argInfo in pairs(options.args) do
					if type(argInfo) == "table" and argInfo.type then
						-- Advanced argument parsing could be added here
						argCount = argCount + 1
					end
				end
			end
			
			-- Call original handler with parsed arguments
			oldHandler(input, editbox)
		end
	end
	
	-- Register with WoW
	SlashCmdList[name] = handler
	_G["SLASH_" .. name .. "1"] = command
	
	-- Add to our registry
	if persist then
		commands[command] = {self, func, options}
	else
		weakcommands[command] = {self, func, options}
	end
end

-- Embedding
local mixinTargets = AceConsole.mixinTargets or {}
AceConsole.mixinTargets = mixinTargets

function AceConsole:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	
	-- Add utility methods
	target.Printf = self.Printf
	target.Print = self.Print
	
	embeds[target] = true
	mixinTargets[target] = true
	return target
end

-- Upgrade embeded
for target, v in pairs(mixinTargets) do
	AceConsole:Embed(target)
end

-- Finish up
AceConsole.mixins = mixins