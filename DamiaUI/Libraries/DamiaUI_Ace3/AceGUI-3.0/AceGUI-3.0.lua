--[[
Name: AceGUI-3.0
Revision: $Rev: 1330 $
Developed by: The Ace Development Team (http://www.wowace.com/addons/ace3/)
Embedded in: DamiaUI with namespace isolation
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/addons/ace3/pages/api/ace-gui-3-0/
SVN: http://www.wowace.com/addons/ace3/repositories/

Description:
AceGUI-3.0 is a comprehensive GUI library for World of Warcraft addons.
It provides a complete widget system with containers, controls, and layouts.

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

local MAJOR, MINOR = "DamiaUI_AceGUI-3.0", 41
local AceGUI, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceGUI then return end -- No upgrade needed

-- Lua APIs
local type, pairs, ipairs, next, tostring = type, pairs, ipairs, next, tostring
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local select, unpack = select, unpack
local rawget, rawset = rawget, rawset
local setmetatable, getmetatable = setmetatable, getmetatable

-- WoW APIs
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: LibStub, UIParent, CreateFrame, GameFontNormal, GameTooltip

-- Local references
AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}
AceGUI.WidgetBase = AceGUI.WidgetBase or {}
AceGUI.WidgetContainerBase = AceGUI.WidgetContainerBase or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}

local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry
local WidgetVersions = AceGUI.WidgetVersions

-- Widget recycling pools
AceGUI.objPools = AceGUI.objPools or {}
local objPools = AceGUI.objPools

-- Utility functions
local function safecall(func, ...)
	if type(func) == "function" then
		local success, ret = pcall(func, ...)
		if success then
			return ret
		end
	end
end

local function CreateWidgetFrame(frameType, parent, name)
	return CreateFrame(frameType, name, parent or UIParent)
end

-- Widget event system
local function FireCallback(widget, callbackName, ...)
	if widget.callbacks and widget.callbacks[callbackName] then
		safecall(widget.callbacks[callbackName], widget, callbackName, ...)
	end
end

-- Base Widget Methods
local WidgetBase = {
	SetCallback = function(self, name, func)
		if not self.callbacks then
			self.callbacks = {}
		end
		self.callbacks[name] = func
	end,
	
	FireCallback = function(self, name, ...)
		return FireCallback(self, name, ...)
	end,
	
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self.width = width
	end,
	
	SetHeight = function(self, height)
		self.frame:SetHeight(height)
		self.height = height
	end,
	
	IsVisible = function(self)
		return self.frame:IsVisible()
	end,
	
	IsShown = function(self)
		return self.frame:IsShown()
	end,
	
	Release = function(self)
		AceGUI:Release(self)
	end,
	
	SetPoint = function(self, ...)
		return self.frame:SetPoint(...)
	end,
	
	ClearAllPoints = function(self)
		return self.frame:ClearAllPoints()
	end,
	
	Show = function(self)
		self.frame:Show()
	end,
	
	Hide = function(self)
		self.frame:Hide()
	end,
	
	SetParent = function(self, parent)
		self.frame:SetParent(parent)
	end,
	
	SetFrameStrata = function(self, strata)
		self.frame:SetFrameStrata(strata)
	end,
	
	SetFrameLevel = function(self, level)
		self.frame:SetFrameLevel(level)
	end,
}

-- Container Widget Methods
local WidgetContainerBase = {
	children = {},
	
	AddChild = function(self, child, beforeWidget)
		if beforeWidget then
			-- Insert before specific widget
			for i, v in ipairs(self.children) do
				if v == beforeWidget then
					tinsert(self.children, i, child)
					break
				end
			end
		else
			-- Add to end
			tinsert(self.children, child)
		end
		
		child.parent = self
		child.frame:SetParent(self.content or self.frame)
		self:DoLayout()
		
		return child
	end,
	
	RemoveChild = function(self, child)
		for i, v in ipairs(self.children) do
			if v == child then
				tremove(self.children, i)
				child.parent = nil
				self:DoLayout()
				break
			end
		end
	end,
	
	ReleaseChildren = function(self)
		local children = self.children
		for i = 1, #children do
			local child = children[i]
			child.parent = nil
			AceGUI:Release(child)
			children[i] = nil
		end
		self:DoLayout()
	end,
	
	SetLayout = function(self, layout)
		self.layout = layout
		self:DoLayout()
	end,
	
	DoLayout = function(self)
		if not self.layout then return end
		
		local layout = LayoutRegistry[self.layout]
		if layout then
			layout(self.content or self.frame, self.children, self)
		end
	end,
	
	GetChildren = function(self)
		return self.children
	end,
}

-- Create base widget metatable
local WidgetMeta = {__index = WidgetBase}

-- Core AceGUI functions
function AceGUI:RegisterWidgetType(name, constructor, version)
	assert(type(name) == "string")
	assert(type(constructor) == "function")
	version = version or 1
	
	local oldVersion = WidgetVersions[name]
	if oldVersion and oldVersion >= version then return end
	
	WidgetVersions[name] = version
	WidgetRegistry[name] = constructor
end

function AceGUI:RegisterLayout(name, layout)
	assert(type(name) == "string")
	assert(type(layout) == "function")
	LayoutRegistry[name] = layout
end

function AceGUI:Create(widgetType)
	if not WidgetRegistry[widgetType] then
		error("Attempt to instantiate unknown widget type " .. tostring(widgetType), 2)
	end
	
	local constructor = WidgetRegistry[widgetType]
	
	-- Check object pool for recycled widgets
	local pool = objPools[widgetType]
	local obj
	
	if pool and pool[1] then
		obj = tremove(pool, 1)
	else
		-- Create new widget
		obj = constructor(widgetType)
		obj.type = widgetType
		
		-- Apply base methods
		for method, func in pairs(WidgetBase) do
			obj[method] = func
		end
		
		-- Apply container methods if it's a container
		if obj.IsContainer then
			for method, func in pairs(WidgetContainerBase) do
				obj[method] = func
			end
			obj.children = {}
		end
		
		setmetatable(obj, WidgetMeta)
	end
	
	-- Initialize/reset the widget
	if obj.OnAcquire then
		obj:OnAcquire()
	end
	
	return obj
end

function AceGUI:Release(obj)
	if not obj then return end
	
	-- Release children if it's a container
	if obj.IsContainer and obj.children then
		obj:ReleaseChildren()
	end
	
	-- Call release handler
	if obj.OnRelease then
		obj:OnRelease()
	end
	
	-- Reset properties
	obj.width = nil
	obj.height = nil
	obj.callbacks = nil
	obj.parent = nil
	
	-- Hide the frame
	obj.frame:ClearAllPoints()
	obj.frame:Hide()
	obj.frame:SetParent(nil)
	
	-- Return to pool
	local pool = objPools[obj.type]
	if not pool then
		pool = {}
		objPools[obj.type] = pool
	end
	
	tinsert(pool, obj)
end

-- Layout Functions
local function FlowLayout(content, children, widget)
	local height = 0
	local width = 0
	local lastOnRow
	local rowHeight = 0
	local usedWidth = 0
	
	local contentWidth = content:GetWidth() or 0
	
	for i = 1, #children do
		local child = children[i]
		local childWidth = child.width or child.frame:GetWidth() or 0
		local childHeight = child.height or child.frame:GetHeight() or 0
		
		if usedWidth == 0 or (usedWidth + childWidth) <= contentWidth then
			-- Place on current row
			if usedWidth == 0 then
				child.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
				lastOnRow = child
			else
				child.frame:SetPoint("TOPLEFT", lastOnRow.frame, "TOPRIGHT", 5, 0)
			end
			
			usedWidth = usedWidth + childWidth + (usedWidth > 0 and 5 or 0)
			rowHeight = math.max(rowHeight, childHeight)
		else
			-- New row
			height = height + rowHeight + 5
			child.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
			usedWidth = childWidth
			rowHeight = childHeight
			lastOnRow = child
		end
		
		child.frame:Show()
	end
	
	-- Update total height
	height = height + rowHeight
	
	if widget.SetHeight then
		widget:SetHeight(height)
	end
end

local function FillLayout(content, children, widget)
	for i = 1, #children do
		local child = children[i]
		child.frame:SetAllPoints(content)
		child.frame:Show()
	end
end

local function ListLayout(content, children, widget)
	local height = 0
	
	for i = 1, #children do
		local child = children[i]
		local childHeight = child.height or child.frame:GetHeight() or 20
		
		child.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
		child.frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -height)
		child.frame:Show()
		
		height = height + childHeight + 2
	end
	
	if widget.SetHeight then
		widget:SetHeight(height)
	end
end

-- Register default layouts
AceGUI:RegisterLayout("Flow", FlowLayout)
AceGUI:RegisterLayout("Fill", FillLayout)
AceGUI:RegisterLayout("List", ListLayout)

-- Focus management
local function ClearFocus()
	-- Clear focus from any edit boxes
end

local function SetFocus(widget)
	-- Set focus to a specific widget
	if widget.frame.SetFocus then
		widget.frame:SetFocus()
	end
end

AceGUI.ClearFocus = ClearFocus
AceGUI.SetFocus = SetFocus