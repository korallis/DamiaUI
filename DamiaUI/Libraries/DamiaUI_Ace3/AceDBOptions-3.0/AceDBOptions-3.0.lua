--[[
Name: AceDBOptions-3.0
Revision: $Rev: 1313 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-db-options-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceDBOptions-3.0 provides a configuration interface for AceDB-3.0 database profiles.
It generates AceConfig-3.0 option tables for profile management.

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

local MAJOR, MINOR = "DamiaUI_AceDBOptions-3.0", 15
local AceDBOptions, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceDBOptions then return end -- No upgrade needed

-- Lua APIs
local type, pairs, next = type, pairs, next
local tinsert, sort = table.insert, table.sort

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub

AceDBOptions.optionTables = AceDBOptions.optionTables or {}
local optionTables = AceDBOptions.optionTables

local defaultProfiles
local tempProfiles = {}

-- Build profile list
local function GetProfiles(db)
	local profiles = {}
	
	-- Get available profiles
	local availableProfiles = db:GetProfiles()
	if availableProfiles then
		for _, profile in pairs(availableProfiles) do
			profiles[profile] = profile
		end
	end
	
	-- Get current profile
	local currentProfile = db:GetCurrentProfile()
	if currentProfile and not profiles[currentProfile] then
		profiles[currentProfile] = currentProfile
	end
	
	return profiles
end

-- Create the options table
local function CreateOptionsTable(db)
	local optionTable = {
		type = "group",
		name = "Profiles",
		desc = "Manage addon profiles",
		args = {
			choose = {
				name = "Current Profile",
				desc = "Select your current profile",
				type = "select",
				order = 1,
				get = function()
					return db:GetCurrentProfile()
				end,
				set = function(info, value)
					db:SetProfile(value)
				end,
				values = function()
					return GetProfiles(db)
				end,
			},
			new = {
				name = "New Profile",
				desc = "Create a new profile",
				type = "input",
				order = 2,
				get = function()
					return ""
				end,
				set = function(info, value)
					if value and value:trim() ~= "" then
						db:SetProfile(value)
					end
				end,
			},
			choose_desc = {
				name = "You can create a new profile by entering a name in the editbox above.",
				type = "description",
				order = 3,
			},
			delete = {
				name = "Delete Profile",
				desc = "Delete an existing profile",
				type = "select",
				order = 4,
				get = function()
					return ""
				end,
				set = function(info, value)
					if value and value ~= db:GetCurrentProfile() then
						local profiles = GetProfiles(db)
						if profiles[value] then
							db:DeleteProfile(value)
						end
					end
				end,
				values = function()
					local profiles = GetProfiles(db)
					local current = db:GetCurrentProfile()
					local deleteProfiles = {}
					
					for profile in pairs(profiles) do
						if profile ~= current then
							deleteProfiles[profile] = profile
						end
					end
					
					return deleteProfiles
				end,
				confirmText = "Are you sure you want to delete the selected profile?",
			},
			delete_desc = {
				name = "Select a profile to delete from the dropdown above.",
				type = "description",
				order = 5,
			},
			copyfrom = {
				name = "Copy From",
				desc = "Copy settings from another profile",
				type = "select",
				order = 6,
				get = function()
					return ""
				end,
				set = function(info, value)
					if value then
						db:CopyProfile(value)
					end
				end,
				values = function()
					local profiles = GetProfiles(db)
					local current = db:GetCurrentProfile()
					local copyProfiles = {}
					
					for profile in pairs(profiles) do
						if profile ~= current then
							copyProfiles[profile] = profile
						end
					end
					
					return copyProfiles
				end,
			},
			copy_desc = {
				name = "Select a profile to copy settings from.",
				type = "description",
				order = 7,
			},
			reset = {
				name = "Reset Profile",
				desc = "Reset the current profile to defaults",
				type = "execute",
				order = 8,
				func = function()
					db:ResetProfile()
				end,
				confirmText = "Are you sure you want to reset the current profile?",
			},
			reset_desc = {
				name = "Reset the current profile back to its default values, losing all current settings.",
				type = "description",
				order = 9,
			},
		},
	}
	
	return optionTable
end

-- Main functions
function AceDBOptions:GetOptionsTable(db, noDefaultProfiles)
	if type(db) ~= "table" then
		error("Usage: GetOptionsTable(db, noDefaultProfiles) - db must be a database object", 2)
	end
	
	if not optionTables[db] then
		optionTables[db] = CreateOptionsTable(db)
	end
	
	return optionTables[db]
end