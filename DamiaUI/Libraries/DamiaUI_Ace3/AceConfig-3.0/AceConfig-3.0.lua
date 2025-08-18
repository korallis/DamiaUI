--[[
Name: AceConfig-3.0
Revision: $Rev: 1312 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-config-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceConfig-3.0 provides a centralized location for addon configuration.
It handles configuration validation and provides a common interface for configuration GUIs.

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

local MAJOR, MINOR = "DamiaUI_AceConfig-3.0", 3
local AceConfig, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfig then return end -- No upgrade needed

-- Lua APIs
local type, tostring, select = type, tostring, select
local pairs, next, rawget, rawset = pairs, next, rawget, rawset
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub

AceConfig.apps = AceConfig.apps or {}
AceConfig.callbacks = AceConfig.callbacks or LibStub("CallbackHandler-1.0"):New(AceConfig)

local apps = AceConfig.apps

-- Configuration validation
local function ValidateOption(optionTbl, keypath, appName)
	if type(optionTbl) ~= "table" then
		error(("Usage: \\n%s:\\nBad 'option' - not a table"):format(keypath), 3)
	end
	
	local optionType = optionTbl.type
	if not optionType then
		error(("Usage: \\n%s:\\n'type' is required"):format(keypath), 3)
	end
	
	if optionType == "group" then
		if not optionTbl.args then
			error(("Usage: \\n%s:\\nGroups require an 'args' table"):format(keypath), 3)
		end
		if type(optionTbl.args) ~= "table" then
			error(("Usage: \\n%s:\\n'args' must be a table"):format(keypath), 3)
		end
		
		-- Recursively validate group contents
		for k, v in pairs(optionTbl.args) do
			if type(v) == "table" then
				ValidateOption(v, keypath .. ".args." .. k, appName)
			end
		end
	elseif optionType == "execute" then
		if not optionTbl.func then
			error(("Usage: \\n%s:\\nExecute options require a 'func'"):format(keypath), 3)
		end
	elseif optionType == "input" then
		-- Input options are flexible
	elseif optionType == "toggle" then
		-- Toggle options are basic
	elseif optionType == "range" then
		if not optionTbl.min or not optionTbl.max then
			error(("Usage: \\n%s:\\nRange options require 'min' and 'max'"):format(keypath), 3)
		end
	elseif optionType == "select" then
		if not optionTbl.values then
			error(("Usage: \\n%s:\\nSelect options require 'values'"):format(keypath), 3)
		end
	elseif optionType == "multiselect" then
		if not optionTbl.values then
			error(("Usage: \\n%s:\\nMultiselect options require 'values'"):format(keypath), 3)
		end
	elseif optionType == "color" then
		-- Color options can have additional properties but work as-is
	elseif optionType == "keybinding" then
		-- Keybinding options work as-is
	elseif optionType == "header" then
		-- Headers are just for display
	elseif optionType == "description" then
		-- Descriptions are just for display
	else
		error(("Usage: \\n%s:\\nUnknown option type '%s'"):format(keypath, optionType), 3)
	end
end

-- Value retrieval and setting
local function GetOptionValue(info)
	local handler = info.handler
	local option = info.option
	
	if option.get then
		if type(option.get) == "string" then
			if handler and handler[option.get] then
				return handler[option.get](handler, info)
			else
				error(("Cannot find method %q"):format(option.get), 2)
			end
		elseif type(option.get) == "function" then
			return option.get(info)
		end
	end
	
	-- Default behavior: use arg path in handler/database
	if handler then
		local db = handler
		for i = 1, #info.arg do
			local key = info.arg[i]
			if type(db) == "table" and db[key] ~= nil then
				db = db[key]
			else
				return nil
			end
		end
		return db
	end
	
	return nil
end

local function SetOptionValue(info, value, ...)
	local handler = info.handler
	local option = info.option
	
	if option.set then
		if type(option.set) == "string" then
			if handler and handler[option.set] then
				return handler[option.set](handler, info, value, ...)
			else
				error(("Cannot find method %q"):format(option.set), 2)
			end
		elseif type(option.set) == "function" then
			return option.set(info, value, ...)
		end
	end
	
	-- Default behavior: set in handler/database
	if handler then
		local db = handler
		for i = 1, #info.arg - 1 do
			local key = info.arg[i]
			if type(db[key]) ~= "table" then
				db[key] = {}
			end
			db = db[key]
		end
		local finalKey = info.arg[#info.arg]
		db[finalKey] = value
	end
end

-- Core AceConfig functions
function AceConfig:RegisterOptionsTable(appName, options, slashcmd)
	if type(appName) ~= "string" then
		error("Usage: RegisterOptionsTable(appName, options[, slashcmd])", 2)
	end
	
	if type(options) ~= "table" and type(options) ~= "function" then
		error("Usage: RegisterOptionsTable(appName, options[, slashcmd])", 2)
	end
	
	-- Validate the options table if it's not a function
	if type(options) == "table" then
		ValidateOption(options, appName, appName)
	end
	
	-- Register the app
	apps[appName] = {
		type = "group",
		options = options,
		slashcmd = slashcmd,
		name = appName,
	}
	
	-- Register slash command if provided
	if slashcmd then
		local AceConsole = LibStub("DamiaUI_AceConsole-3.0", true)
		if AceConsole then
			AceConsole:RegisterChatCommand(slashcmd, function()
				-- Open config dialog
				local AceConfigDialog = LibStub("DamiaUI_AceConfigDialog-3.0", true)
				if AceConfigDialog then
					AceConfigDialog:Open(appName)
				end
			end)
		end
	end
	
	-- Fire callback
	self.callbacks:Fire("ConfigTableChanged", appName)
end

function AceConfig:UnregisterOptionsTable(appName)
	if apps[appName] then
		apps[appName] = nil
		self.callbacks:Fire("ConfigTableChanged", appName)
	end
end

function AceConfig:GetOptionsTable(appName)
	local app = apps[appName]
	if not app then return nil end
	
	if type(app.options) == "function" then
		return app.options()
	else
		return app.options
	end
end

function AceConfig:GetAppInfo(appName)
	return apps[appName]
end

-- Iterator for registered apps
function AceConfig:IterateApps()
	return pairs(apps)
end

-- Configuration dialog integration
function AceConfig:ConfigTableChanged(appName)
	self.callbacks:Fire("ConfigTableChanged", appName)
end

-- Utility function to create option info
function AceConfig:CreateInfo(handler, ...)
	local info = {
		handler = handler,
		arg = {...},
	}
	return info
end

-- Value handling utilities
AceConfig.GetOptionValue = GetOptionValue
AceConfig.SetOptionValue = SetOptionValue
AceConfig.ValidateOption = ValidateOption