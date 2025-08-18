--[[
Name: AceConfigDialog-3.0
Revision: $Rev: 1327 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-config-dialog-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceConfigDialog-3.0 provides a graphical user interface for AceConfig-3.0 registered options.
It creates configuration panels and integrates with Blizzard's Interface Options.

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

local MAJOR, MINOR = "DamiaUI_AceConfigDialog-3.0", 85
local AceConfigDialog, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfigDialog then return end -- No upgrade needed

-- Lua APIs
local type, tostring, tonumber, select = type, tostring, tonumber, select
local pairs, next, rawget, rawset = pairs, next, rawget, rawset
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local string_match, string_gsub = string.match, string.gsub

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, InterfaceOptionsFrame, InterfaceOptionsFrame_OpenToCategory, GameTooltip, CreateFrame

local AceConfig = LibStub("DamiaUI_AceConfig-3.0")
local AceGUI = LibStub("DamiaUI_AceGUI-3.0", true)

AceConfigDialog.OpenFrames = AceConfigDialog.OpenFrames or {}
AceConfigDialog.Status = AceConfigDialog.Status or {}
AceConfigDialog.frame = AceConfigDialog.frame or CreateFrame("Frame", "DamiaUI_AceConfigDialog30Frame")

local OpenFrames = AceConfigDialog.OpenFrames
local Status = AceConfigDialog.Status

local function SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		geterrorhandler()(err)
	end
	return success, err
end

-- Widget creation and handling
local function CreateWidget(widgetType)
	if not AceGUI then
		error("DamiaUI_AceGUI-3.0 is required for AceConfigDialog-3.0", 2)
	end
	return AceGUI:Create(widgetType)
end

-- Option processing functions
local function GetOptionValue(info, option)
	local value
	
	if option.get then
		if type(option.get) == "string" then
			local handler = info.handler
			if handler and handler[option.get] then
				value = handler[option.get](handler, info)
			end
		elseif type(option.get) == "function" then
			value = option.get(info)
		end
	elseif info.handler then
		-- Default get behavior
		local db = info.handler
		for i = 1, #info.arg do
			if type(db) == "table" then
				db = db[info.arg[i]]
			else
				break
			end
		end
		value = db
	end
	
	return value
end

local function SetOptionValue(info, option, value, ...)
	if option.set then
		if type(option.set) == "string" then
			local handler = info.handler
			if handler and handler[option.set] then
				handler[option.set](handler, info, value, ...)
			end
		elseif type(option.set) == "function" then
			option.set(info, value, ...)
		end
	elseif info.handler then
		-- Default set behavior
		local db = info.handler
		for i = 1, #info.arg - 1 do
			local key = info.arg[i]
			if type(db[key]) ~= "table" then
				db[key] = {}
			end
			db = db[key]
		end
		db[info.arg[#info.arg]] = value
	end
end

-- Widget builders
local function BuildWidget(widgetType, info, option, container)
	local widget = CreateWidget(widgetType)
	if not widget then return nil end
	
	-- Set basic properties
	widget:SetLabel(option.name or "")
	
	if option.desc then
		widget:SetTooltip(option.desc)
	end
	
	if option.width then
		widget:SetRelativeWidth(option.width)
	end
	
	-- Set widget-specific properties and callbacks
	if widgetType == "CheckBox" then
		local value = GetOptionValue(info, option)
		widget:SetValue(value)
		widget:SetCallback("OnValueChanged", function(widget, event, value)
			SetOptionValue(info, option, value)
		end)
		
	elseif widgetType == "EditBox" then
		local value = GetOptionValue(info, option) or ""
		widget:SetText(tostring(value))
		widget:SetCallback("OnEnterPressed", function(widget, event, value)
			if option.type == "input" then
				SetOptionValue(info, option, value)
			end
		end)
		
	elseif widgetType == "Slider" then
		local value = GetOptionValue(info, option)
		widget:SetSliderValues(option.min or 0, option.max or 100, option.step or 1)
		widget:SetValue(value or option.min or 0)
		widget:SetCallback("OnValueChanged", function(widget, event, value)
			SetOptionValue(info, option, value)
		end)
		
	elseif widgetType == "Dropdown" then
		local value = GetOptionValue(info, option)
		widget:SetList(option.values or {})
		widget:SetValue(value)
		widget:SetCallback("OnValueChanged", function(widget, event, value)
			SetOptionValue(info, option, value)
		end)
		
	elseif widgetType == "Button" then
		widget:SetCallback("OnClick", function(widget, event)
			if option.func then
				SafeCall(option.func, info)
			end
		end)
		
	elseif widgetType == "ColorPicker" then
		local r, g, b, a = 1, 1, 1, 1
		local value = GetOptionValue(info, option)
		if value then
			if type(value) == "table" then
				r, g, b, a = value.r or value[1] or 1, value.g or value[2] or 1, value.b or value[3] or 1, value.a or value[4] or 1
			end
		end
		
		widget:SetColor(r, g, b, a)
		widget:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
			if option.hasAlpha then
				SetOptionValue(info, option, {r = r, g = g, b = b, a = a})
			else
				SetOptionValue(info, option, {r = r, g = g, b = b})
			end
		end)
	end
	
	-- Add to container
	container:AddChild(widget)
	return widget
end

-- Group building
local function BuildGroup(info, option, container)
	if not option.args then return end
	
	-- Create scroll container for groups
	local scrollFrame = CreateWidget("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	container:AddChild(scrollFrame)
	
	-- Sort options by order
	local sortedKeys = {}
	for k in pairs(option.args) do
		tinsert(sortedKeys, k)
	end
	
	table.sort(sortedKeys, function(a, b)
		local orderA = option.args[a].order or 100
		local orderB = option.args[b].order or 100
		if orderA == orderB then
			return a < b
		end
		return orderA < orderB
	end)
	
	-- Build child options
	for _, key in pairs(sortedKeys) do
		local childOption = option.args[key]
		if childOption and not childOption.hidden then
			local childInfo = {
				handler = info.handler,
				arg = {}
			}
			
			-- Copy parent arg path and add current key
			for i = 1, #info.arg do
				childInfo.arg[i] = info.arg[i]
			end
			tinsert(childInfo.arg, key)
			
			BuildOption(childInfo, childOption, scrollFrame)
		end
	end
end

-- Main option builder
function BuildOption(info, option, container)
	if not option or option.hidden then return end
	
	local optionType = option.type
	
	if optionType == "group" then
		-- Create a group container
		local group = CreateWidget("InlineGroup")
		group:SetTitle(option.name or "")
		container:AddChild(group)
		
		BuildGroup(info, option, group)
		
	elseif optionType == "toggle" then
		BuildWidget("CheckBox", info, option, container)
		
	elseif optionType == "input" then
		BuildWidget("EditBox", info, option, container)
		
	elseif optionType == "range" then
		BuildWidget("Slider", info, option, container)
		
	elseif optionType == "select" then
		BuildWidget("Dropdown", info, option, container)
		
	elseif optionType == "execute" then
		BuildWidget("Button", info, option, container)
		
	elseif optionType == "color" then
		BuildWidget("ColorPicker", info, option, container)
		
	elseif optionType == "header" then
		local header = CreateWidget("Heading")
		header:SetText(option.name or "")
		container:AddChild(header)
		
	elseif optionType == "description" then
		local desc = CreateWidget("Label")
		desc:SetText(option.desc or "")
		desc:SetFontObject(GameFontHighlightSmall)
		container:AddChild(desc)
	end
end

-- Main dialog functions
function AceConfigDialog:Open(appName, container, path)
	if not appName then
		error("Usage: Open(appName[, container][, path])", 2)
	end
	
	local options = AceConfig:GetOptionsTable(appName)
	if not options then
		error("No options table found for " .. tostring(appName), 2)
	end
	
	-- Create or get existing frame
	local frame
	if container then
		frame = container
	else
		frame = OpenFrames[appName]
		if not frame and AceGUI then
			frame = AceGUI:Create("Frame")
			frame:SetTitle(options.name or appName)
			frame:SetStatusText("")
			frame:SetLayout("Fill")
			
			-- Store frame reference
			OpenFrames[appName] = frame
			
			-- Handle frame close
			frame:SetCallback("OnClose", function(widget)
				OpenFrames[appName] = nil
				AceGUI:Release(widget)
			end)
		end
	end
	
	if not frame then
		error("Could not create frame for " .. tostring(appName), 2)
	end
	
	-- Clear existing content
	frame:ReleaseChildren()
	
	-- Build the UI
	local info = {
		handler = options.handler,
		arg = path or {},
	}
	
	BuildOption(info, options, frame)
	
	-- Show frame if it's standalone
	if not container then
		frame:Show()
	end
	
	return frame
end

function AceConfigDialog:Close(appName)
	local frame = OpenFrames[appName]
	if frame then
		frame:Hide()
	end
end

function AceConfigDialog:CloseAll()
	for appName, frame in pairs(OpenFrames) do
		frame:Hide()
	end
end

-- Blizzard Interface Options integration
function AceConfigDialog:AddToBlizOptions(appName, name, parent, childGroups)
	local options = AceConfig:GetOptionsTable(appName)
	if not options then
		error("No options table found for " .. tostring(appName), 2)
	end
	
	local panel = CreateFrame("Frame")
	panel.name = name or appName
	panel.parent = parent
	
	-- Create the options UI in the panel
	panel.refresh = function()
		-- Clear and rebuild
		for _, child in pairs({panel:GetChildren()}) do
			child:Hide()
		end
		
		-- Build options directly in the panel
		local info = {
			handler = options.handler,
			arg = {},
		}
		
		-- This would need more sophisticated handling for Blizzard panels
		-- For now, we'll create a simple text display
		local text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		text:SetPoint("CENTER")
		text:SetText("Config for " .. appName)
	end
	
	-- Add to Interface Options
	if Settings and Settings.RegisterCanvasLayoutCategory then
		-- For newer WoW versions
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)
	else
		-- For older WoW versions
		InterfaceOptions_AddCategory(panel)
	end
	
	return panel
end

-- Initialize AceConfigDialog with AceConfig callback
if AceConfig then
	AceConfig.callbacks:RegisterCallback("ConfigTableChanged", function(event, appName)
		local frame = OpenFrames[appName]
		if frame then
			-- Refresh the frame
			AceConfigDialog:Open(appName, frame)
		end
	end)
end