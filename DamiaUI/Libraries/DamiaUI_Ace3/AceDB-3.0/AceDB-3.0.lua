--[[
Name: AceDB-3.0
Revision: $Rev: 1312 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-db-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceDB-3.0 provides a powerful database API for World of Warcraft addons.
It handles defaults, profiles, and database management with character/server specific data.

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

local MAJOR, MINOR = "DamiaUI_AceDB-3.0", 27
local AceDB, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceDB then return end -- No upgrade needed

-- Lua APIs
local type, getmetatable, setmetatable, rawset, rawget, next, pairs = type, getmetatable, setmetatable, rawset, rawget, next, pairs
local tconcat, tremove, tinsert = table.concat, table.remove, table.insert
local tostring, string_gsub, strmatch = tostring, string.gsub, string.match
local error, assert = error, assert

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, DEFAULT_CHAT_FRAME, geterrorhandler, UnitName, GetRealmName

AceDB.db_registry = AceDB.db_registry or {}
AceDB.frame = AceDB.frame or CreateFrame("Frame", "DamiaUI_AceDB30Frame")

local CallbackHandler = LibStub("CallbackHandler-1.0")

local db_registry = AceDB.db_registry
local frame = AceDB.frame
local mixins = {"RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks", "FireCallback"}

-- Utility functions
local function copyTable(src, dest)
	for k, v in pairs(src) do
		if type(v) == "table" then
			dest[k] = {}
			copyTable(v, dest[k])
		else
			dest[k] = v
		end
	end
end

local function copyDefaults(dest, src)
	for k, v in pairs(src) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				local mt = {
					__index = function(t, key)
						if type(v) == "table" then
							local tbl = {}
							copyDefaults(tbl, v)
							rawset(t, key, tbl)
							return tbl
						else
							return v
						end
					end,
				}
				setmetatable(dest, mt)
			else
				local mt = {
					__index = function(t, key)
						return v
					end,
				}
				setmetatable(dest, mt)
			end
		elseif type(v) == "table" then
			if not rawget(dest, k) then
				dest[k] = {}
			end
			if type(dest[k]) == "table" then
				copyDefaults(dest[k], v)
			end
		else
			if rawget(dest, k) == nil then
				dest[k] = v
			end
		end
	end
end

local function cleanupDefaults(db_obj, defaults, blocker)
	if not defaults then return end
	for k, v in pairs(defaults) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				-- Find and cleanup matching keys
				for key, data in pairs(db_obj) do
					if not blocker or not blocker[key] then
						cleanupDefaults(data, v, blocker and blocker[key])
					end
				end
			end
		elseif type(v) == "table" then
			if db_obj[k] and type(db_obj[k]) == "table" then
				cleanupDefaults(db_obj[k], v, blocker and blocker[k])
				-- If table became empty after cleanup, remove it
				if not next(db_obj[k]) then
					db_obj[k] = nil
				end
			end
		else
			-- Remove if matches default value
			if db_obj[k] == v then
				db_obj[k] = nil
			end
		end
	end
	
	-- Clean up metatable if needed
	if getmetatable(db_obj) and not next(db_obj) then
		setmetatable(db_obj, nil)
	end
end

-- Profile methods
local function getPlayerKey()
	return UnitName("player") .. " - " .. GetRealmName()
end

local function getPlayerClass()
	return select(2, UnitClass("player"))
end

local function getFactionKey()
	return UnitFactionGroup("player")
end

-- Database object prototype
local DBObjectLib = {}

function DBObjectLib:SetProfile(name)
	if type(name) ~= "string" then
		error("Usage: SetProfile(name)", 2)
	end
	
	if name == self.keys.profile then return end
	
	local sv = self.sv
	local old_profile = self.profile
	local new_profile
	
	-- Ensure the profile exists
	if not sv.profiles[name] then
		sv.profiles[name] = {}
	end
	
	-- Get the new profile
	new_profile = sv.profiles[name]
	
	-- Apply defaults
	if self.defaults and self.defaults.profile then
		copyDefaults(new_profile, self.defaults.profile)
	end
	
	-- Update the profile reference
	self.keys.profile = name
	self.profile = new_profile
	
	-- Fire callback
	self:FireCallback("OnProfileChanged", self, name)
	self:FireCallback("OnDatabaseChanged", self, name)
end

function DBObjectLib:GetProfiles()
	local profiles = {}
	for k in pairs(self.sv.profiles) do
		tinsert(profiles, k)
	end
	return profiles
end

function DBObjectLib:GetCurrentProfile()
	return self.keys.profile
end

function DBObjectLib:DeleteProfile(name, silent)
	if type(name) ~= "string" then
		error("Usage: DeleteProfile(name, silent)", 2)
	end
	
	if name == self.keys.profile then
		error("Cannot delete active profile", 2)
	end
	
	if not self.sv.profiles[name] and not silent then
		error("Profile " .. name .. " does not exist", 2)
	end
	
	self.sv.profiles[name] = nil
	
	-- Fire callback
	self:FireCallback("OnProfileDeleted", self, name)
end

function DBObjectLib:CopyProfile(name, silent)
	if type(name) ~= "string" then
		error("Usage: CopyProfile(name, silent)", 2)
	end
	
	if name == self.keys.profile then
		error("Cannot copy active profile", 2)
	end
	
	if not self.sv.profiles[name] and not silent then
		error("Profile " .. name .. " does not exist", 2)
	end
	
	-- Copy the profile
	copyTable(self.sv.profiles[name], self.profile)
	
	-- Fire callback
	self:FireCallback("OnProfileCopied", self, name)
	self:FireCallback("OnDatabaseChanged", self, name)
end

function DBObjectLib:ResetProfile(noCallbacks)
	local profile = self.profile
	
	-- Clear all data
	for k, v in pairs(profile) do
		profile[k] = nil
	end
	
	-- Remove metatable
	setmetatable(profile, nil)
	
	-- Reapply defaults
	if self.defaults and self.defaults.profile then
		copyDefaults(profile, self.defaults.profile)
	end
	
	-- Fire callback
	if not noCallbacks then
		self:FireCallback("OnProfileReset", self)
		self:FireCallback("OnDatabaseChanged", self)
	end
end

function DBObjectLib:ResetDB(noCallbacks)
	-- Reset profile
	self:ResetProfile(true)
	
	-- Clear global
	if self.global then
		for k, v in pairs(self.global) do
			self.global[k] = nil
		end
		setmetatable(self.global, nil)
		if self.defaults and self.defaults.global then
			copyDefaults(self.global, self.defaults.global)
		end
	end
	
	-- Clear char
	if self.char then
		for k, v in pairs(self.char) do
			self.char[k] = nil
		end
		setmetatable(self.char, nil)
		if self.defaults and self.defaults.char then
			copyDefaults(self.char, self.defaults.char)
		end
	end
	
	-- Clear realm
	if self.realm then
		for k, v in pairs(self.realm) do
			self.realm[k] = nil
		end
		setmetatable(self.realm, nil)
		if self.defaults and self.defaults.realm then
			copyDefaults(self.realm, self.defaults.realm)
		end
	end
	
	-- Clear class
	if self.class then
		for k, v in pairs(self.class) do
			self.class[k] = nil
		end
		setmetatable(self.class, nil)
		if self.defaults and self.defaults.class then
			copyDefaults(self.class, self.defaults.class)
		end
	end
	
	-- Clear race
	if self.race then
		for k, v in pairs(self.race) do
			self.race[k] = nil
		end
		setmetatable(self.race, nil)
		if self.defaults and self.defaults.race then
			copyDefaults(self.race, self.defaults.race)
		end
	end
	
	-- Clear faction
	if self.faction then
		for k, v in pairs(self.faction) do
			self.faction[k] = nil
		end
		setmetatable(self.faction, nil)
		if self.defaults and self.defaults.faction then
			copyDefaults(self.faction, self.defaults.faction)
		end
	end
	
	-- Fire callbacks
	if not noCallbacks then
		self:FireCallback("OnDatabaseReset", self)
		self:FireCallback("OnDatabaseChanged", self)
	end
end

-- Main AceDB functions
function AceDB:New(tbl, defaults, defaultProfile)
	if type(tbl) == "string" then
		error("Usage: New(tbl, defaults, defaultProfile)", 2)
	end
	
	if type(tbl) ~= "table" then
		error("Usage: New(tbl, defaults, defaultProfile)", 2)
	end
	
	-- Create the database object
	local db = {}
	
	-- Set up callback system
	CallbackHandler:New(db)
	
	-- Set up the structure
	if not tbl.profiles then tbl.profiles = {} end
	if not tbl.global then tbl.global = {} end
	if not tbl.char then tbl.char = {} end
	if not tbl.realm then tbl.realm = {} end
	if not tbl.class then tbl.class = {} end
	if not tbl.race then tbl.race = {} end
	if not tbl.faction then tbl.faction = {} end
	
	-- Character key
	local char = getPlayerKey()
	local class = getPlayerClass()
	local race = select(2, UnitRace("player"))
	local faction = getFactionKey()
	local realm = GetRealmName()
	
	-- Ensure sub-tables exist
	if not tbl.char[char] then tbl.char[char] = {} end
	if not tbl.class[class] then tbl.class[class] = {} end
	if not tbl.race[race] then tbl.race[race] = {} end
	if not tbl.faction[faction] then tbl.faction[faction] = {} end
	if not tbl.realm[realm] then tbl.realm[realm] = {} end
	
	-- Set up profile
	local profileKey = defaultProfile or char
	if not tbl.profiles[profileKey] then
		tbl.profiles[profileKey] = {}
	end
	
	-- Set up database object
	db.sv = tbl
	db.defaults = defaults
	db.keys = {
		profile = profileKey,
		char = char,
		class = class,
		race = race,
		faction = faction,
		realm = realm,
	}
	
	-- Set up direct access
	db.profile = tbl.profiles[profileKey]
	db.global = tbl.global
	db.char = tbl.char[char]
	db.class = tbl.class[class]
	db.race = tbl.race[race]
	db.faction = tbl.faction[faction]
	db.realm = tbl.realm[realm]
	
	-- Apply defaults
	if defaults then
		if defaults.profile then
			copyDefaults(db.profile, defaults.profile)
		end
		if defaults.global then
			copyDefaults(db.global, defaults.global)
		end
		if defaults.char then
			copyDefaults(db.char, defaults.char)
		end
		if defaults.class then
			copyDefaults(db.class, defaults.class)
		end
		if defaults.race then
			copyDefaults(db.race, defaults.race)
		end
		if defaults.faction then
			copyDefaults(db.faction, defaults.faction)
		end
		if defaults.realm then
			copyDefaults(db.realm, defaults.realm)
		end
	end
	
	-- Add methods
	for name, func in pairs(DBObjectLib) do
		db[name] = func
	end
	
	-- Register database
	db_registry[db] = true
	
	return db
end

-- Cleanup on logout
local function OnEvent(frame, event)
	if event == "PLAYER_LOGOUT" then
		for db in pairs(db_registry) do
			-- Clean up defaults
			if db.defaults then
				if db.defaults.profile then
					cleanupDefaults(db.profile, db.defaults.profile)
				end
				if db.defaults.global then
					cleanupDefaults(db.global, db.defaults.global)
				end
				if db.defaults.char then
					cleanupDefaults(db.char, db.defaults.char)
				end
				if db.defaults.class then
					cleanupDefaults(db.class, db.defaults.class)
				end
				if db.defaults.race then
					cleanupDefaults(db.race, db.defaults.race)
				end
				if db.defaults.faction then
					cleanupDefaults(db.faction, db.defaults.faction)
				end
				if db.defaults.realm then
					cleanupDefaults(db.realm, db.defaults.realm)
				end
			end
		end
	end
end

frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", OnEvent)