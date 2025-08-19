--[[
Name: AceAddon-3.0
Revision: $Rev: 1297 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-addon-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceAddon-3.0 is a lightweight addon framework for World of Warcraft.
It provides a modular architecture for building addons with mixins.

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

local MAJOR, MINOR = "DamiaUI_AceAddon-3.0", 13
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end -- No upgrade needed

-- Lua APIs
local tconcat, tostring, select = table.concat, tostring, select
local type, pairs, next, pcall, xpcall = type, pairs, next, pcall, xpcall
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, DEFAULT_CHAT_FRAME, geterrorhandler

-- Constants
AceAddon.frame = AceAddon.frame or CreateFrame("Frame", "DamiaUI_AceAddon30Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end})

-- Local variables
local addons = AceAddon.addons
local statuses = AceAddon.statuses
local initializequeue = AceAddon.initializequeue
local enablequeue = AceAddon.enablequeue
local embeds = AceAddon.embeds

local AddonStatus_Loaded = "Loaded"
local AddonStatus_Initialized = "Initialized"
local AddonStatus_Enabled = "Enabled"

-- Addon prototype
local AddonProto = {}
local AddonMeta = {__index = AddonProto}

-- Mixins
local mixins = {
	"NewModule", "GetModule", "GetName", "SetDefaultModuleState", "SetDefaultModuleLibraries", 
	"SetEnabledState", "IsEnabled", "GetModules", "SetDefaultModulePrototype",
	"EnableModule", "DisableModule", "SetModuleState", "IterateModules"
}

-- Event handling
local events = {}
local frame = AceAddon.frame
frame:UnregisterAllEvents()
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(frame, event, ...)
	if events[event] then
		events[event](AceAddon, event, ...)
	end
end)

-- Utility functions
local function safecall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		geterrorhandler()(err)
	end
	return success, err
end

local function GetAddonMetadata(name)
	local title = (GetAddOnMetadata(name, "Title") or name):trim()
	local notes = GetAddOnMetadata(name, "Notes")
	local author = GetAddOnMetadata(name, "Author")
	local version = GetAddOnMetadata(name, "Version")
	
	return title, notes, author, version
end

-- Status checking functions
local function IsDisabled(name)
	return statuses[name] == false
end

local function IsEnabled(name)
	return statuses[name] ~= false
end

-- Initialize addon
local function AddonLog(addon, ...)
	local name = addon.moduleName or addon.name or "(Unknown)"
	-- Debug logging removed
end

-- Event handlers
events.ADDON_LOADED = function(self, event, name)
	local addon = addons[name]
	if not addon then return end
	
	if type(addon.OnLoad) == "function" then
		safecall(addon.OnLoad, addon)
	end
	
	-- Initialize if not already done
	if statuses[addon.name] ~= AddonStatus_Initialized and statuses[addon.name] ~= AddonStatus_Enabled then
		if IsEnabled(addon.name) and type(addon.OnInitialize) == "function" then
			statuses[addon.name] = AddonStatus_Initialized
			safecall(addon.OnInitialize, addon)
		end
	end
	
	statuses[name] = AddonStatus_Loaded
end

events.PLAYER_LOGIN = function(self, event)
	for i = 1, #initializequeue do
		local addon = initializequeue[i]
		if IsEnabled(addon.name) then
			if type(addon.OnInitialize) == "function" then
				statuses[addon.name] = AddonStatus_Initialized
				safecall(addon.OnInitialize, addon)
			end
		end
	end
	
	for i = 1, #enablequeue do
		local addon = enablequeue[i]
		if IsEnabled(addon.name) then
			if type(addon.OnEnable) == "function" then
				statuses[addon.name] = AddonStatus_Enabled
				safecall(addon.OnEnable, addon)
			end
		end
	end
end

-- Addon prototype methods
function AddonProto:GetName()
	return self.name
end

function AddonProto:IsEnabled()
	return IsEnabled(self.name)
end

function AddonProto:SetEnabledState(enabled)
	statuses[self.name] = enabled
end

function AddonProto:Print(...)
	local name = self.moduleName or self.name
	-- Print logging removed
end

function AddonProto:EnableModule(module)
	if type(module) == "string" then
		module = self.modules and self.modules[module]
	end
	if module then
		statuses[module.name] = true
		if statuses[self.name] == AddonStatus_Enabled and type(module.OnEnable) == "function" then
			safecall(module.OnEnable, module)
		end
	end
end

function AddonProto:DisableModule(module)
	if type(module) == "string" then
		module = self.modules and self.modules[module]
	end
	if module then
		statuses[module.name] = false
		if type(module.OnDisable) == "function" then
			safecall(module.OnDisable, module)
		end
	end
end

function AddonProto:SetModuleState(module, enabled)
	if enabled then
		self:EnableModule(module)
	else
		self:DisableModule(module)
	end
end

function AddonProto:GetModule(name, silent)
	if not self.modules then return nil end
	local module = self.modules[name]
	if not module and not silent then
		error(("Module %q does not exist in addon %q"):format(tostring(name), self.name), 2)
	end
	return module
end

function AddonProto:NewModule(name, ...)
	if not name then error("Usage: NewModule(name, [prototype], [...])", 2) end
	if type(name) ~= "string" then error("Usage: NewModule(name, [prototype], [...])", 2) end
	if self.modules and self.modules[name] then error("Module " .. name .. " already exists.", 2) end
	
	-- Create module
	local module = {}
	module.name = name
	module.moduleName = name
	
	-- Set up modules table if needed
	if not self.modules then
		self.modules = {}
	end
	
	-- Add to modules
	self.modules[name] = module
	addons[name] = module
	
	-- Set up prototype
	local prototype = self.defaultModulePrototype
	if select("#", ...) > 0 then
		local arg1 = select(1, ...)
		if type(arg1) == "table" then
			prototype = arg1
		end
	end
	
	if prototype then
		for k, v in pairs(prototype) do
			module[k] = v
		end
	end
	
	-- Apply default libraries
	if self.defaultModuleLibraries then
		for i = 1, #self.defaultModuleLibraries, 2 do
			local libname = self.defaultModuleLibraries[i]
			local libproto = self.defaultModuleLibraries[i+1]
			local lib = LibStub:GetLibrary(libname, true)
			if lib then
				if libproto == true then
					lib:Embed(module)
				elseif libproto then
					for k, v in pairs(libproto) do
						module[k] = v
					end
					lib:Embed(module)
				else
					lib:Embed(module)
				end
			end
		end
	end
	
	-- Default state
	statuses[name] = self.defaultModuleState ~= false
	
	return module
end

function AddonProto:GetModules()
	return self.modules
end

function AddonProto:IterateModules()
	if self.modules then
		return pairs(self.modules)
	else
		return function() end
	end
end

function AddonProto:SetDefaultModuleState(state)
	self.defaultModuleState = state
end

function AddonProto:SetDefaultModuleLibraries(...)
	self.defaultModuleLibraries = {...}
end

function AddonProto:SetDefaultModulePrototype(prototype)
	self.defaultModulePrototype = prototype
end

-- Main AceAddon functions
function AceAddon:NewAddon(name, ...)
	if type(name) ~= "string" then error("Usage: NewAddon(name, [prototype], [...])", 2) end
	if addons[name] then error("Addon " .. name .. " already exists.", 2) end
	
	local addon = setmetatable({}, AddonMeta)
	addon.name = name
	
	-- Handle prototypes and libraries
	local libs = {...}
	for i = 1, #libs do
		local lib = libs[i]
		if type(lib) == "string" then
			local libobj = LibStub:GetLibrary(lib, true)
			if libobj then
				libobj:Embed(addon)
			end
		elseif type(lib) == "table" then
			-- Prototype
			for k, v in pairs(lib) do
				addon[k] = v
			end
		end
	end
	
	-- Register addon
	addons[name] = addon
	
	-- Set default enabled state
	if statuses[name] == nil then
		statuses[name] = true
	end
	
	-- Add to initialize queue
	initializequeue[#initializequeue + 1] = addon
	enablequeue[#enablequeue + 1] = addon
	
	return addon
end

function AceAddon:GetAddon(name, silent)
	if not addons[name] and not silent then
		error("Addon " .. tostring(name) .. " not found.", 2)
	end
	return addons[name]
end

function AceAddon:IterateAddons()
	return pairs(addons)
end

-- Embedding
local mixinTargets = AceAddon.mixinTargets or {}
AceAddon.mixinTargets = mixinTargets

function AceAddon:Embed(target)
	for k, v in pairs(AddonProto) do
		target[k] = v
	end
	
	-- Add to embeds
	embeds[target] = true
	
	-- Add to mixins list
	mixinTargets[target] = true
	
	return target
end

-- Upgrade embeded
for target, v in pairs(mixinTargets) do
	AceAddon:Embed(target)
end

-- Finish up
AceAddon.mixins = mixins