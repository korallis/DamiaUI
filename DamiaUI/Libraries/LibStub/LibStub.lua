--[[
Name: LibStub
Revision: $Rev: 103 $
Developed by: The World of Warcraft AddOn community

Description:
A library stub for addons to detect and retrieve library instances.
This is the standard LibStub implementation used by Ace3 and thousands of WoW addons.

Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
License: Public Domain
Supports: WoW 1.12+, 2.4.3+, 3.3.5+, 4.3.4+, 5.4.8+, 6.2.4+, 7.3.5+, 8.3.7+, 9.2.7+, 10.2.7+, 11.2+
]]

local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2
local LibStub = _G[LIBSTUB_MAJOR]

if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or {libs = {}, minors = {} }
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR
	
	-- Register a new library version
	-- @param major: string - library name (required)
	-- @param minor: number/string - version number, must contain a number (required)
	-- @return: library table if registered, nil if version is not newer
	-- @return: old minor version number if library was upgraded
	function LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")
		
		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end
	
	-- Retrieve a library instance
	-- @param major: string - library name (required)
	-- @param silent: boolean - suppress error if library not found (optional)
	-- @return: library table if found
	-- @return: minor version number
	function LibStub:GetLibrary(major, silent)
		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end
	
	-- Iterator for all registered libraries
	-- @return: iterator function for pairs()
	function LibStub:IterateLibraries() 
		return pairs(self.libs) 
	end
	
	-- Allow calling LibStub(...) as shorthand for LibStub:GetLibrary(...)
	setmetatable(LibStub, { __call = LibStub.GetLibrary })
end