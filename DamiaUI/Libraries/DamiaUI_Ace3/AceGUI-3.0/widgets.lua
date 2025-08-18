--[[
AceGUI-3.0 Widget Collection
Core widgets for DamiaUI with namespace isolation
Compatible with WoW 11.2
--]]

local AceGUI = LibStub("DamiaUI_AceGUI-3.0")

-- Lua APIs
local type, tostring, tonumber = type, tostring, tonumber
local pairs, ipairs, next = pairs, ipairs, next
local tinsert, tremove = table.insert, table.remove
local string_match = string.match

-- WoW APIs
local _G = _G

-- Global references
-- GLOBALS: UIParent, CreateFrame, GameFontNormal, GameFontHighlight, GameTooltip

--[[-----------------------------------------------------------------------------
Frame Widget
-------------------------------------------------------------------------------]]
do
	local Type = "Frame"
	local Version = 28
	
	local function OnAcquire(self)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self.frame:SetFrameLevel(100)
		self:EnableResize(true)
		self:SetStatusText("")
		self:Show()
		self:SetTitle("")
	end
	
	local function OnRelease(self)
		self.status:SetText("")
		self.statustext:GetFontObject()
		self.titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		self.titletext:GetFontObject()
		for i = 1, 4 do
			local border = self.borders[i]
			border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
			border:SetTexCoord(0, 1, 0, 1)
		end
	end
	
	local function SetTitle(self, title)
		self.titletext:SetText(title or "")
		self.titlebg:SetWidth((self.titletext:GetStringWidth() or 0) + 10)
	end
	
	local function SetStatusText(self, text)
		self.statustext:SetText(text or "")
	end
	
	local function Hide(self)
		self.frame:Hide()
	end
	
	local function Show(self)
		self.frame:Show()
	end
	
	local function EnableResize(self, state)
		local func = state and "Show" or "Hide"
		self.sizer_se[func](self.sizer_se)
		self.sizer_s[func](self.sizer_s)
		self.sizer_e[func](self.sizer_e)
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:Hide()
		frame:SetWidth(700)
		frame:SetHeight(500)
		frame:SetPoint("CENTER")
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetResizable(true)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 6, top = 8, bottom = 8 }
		})
		frame:SetBackdropColor(0, 0, 0, 1)
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
		
		-- Title
		local titletext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		titletext:SetPoint("TOP", frame, "TOP", 0, -5)
		self.titletext = titletext
		
		local titlebg = frame:CreateTexture(nil, "OVERLAY")
		titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg:SetPoint("TOP", frame, "TOP", 0, 12)
		titlebg:SetHeight(40)
		self.titlebg = titlebg
		
		-- Content area
		local content = CreateFrame("Frame", nil, frame)
		content:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -27)
		content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 45)
		self.content = content
		
		-- Status bar
		local statusbg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		statusbg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
		statusbg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -132, 15)
		statusbg:SetHeight(24)
		statusbg:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, edgeSize = 16,
			insets = { left = 3, right = 3, top = 5, bottom = 3 }
		})
		statusbg:SetBackdropColor(0, 0, 0, 0.75)
		statusbg:SetBackdropBorderColor(0.4, 0.4, 0.4)
		self.statusbg = statusbg
		
		local statustext = statusbg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		statustext:SetPoint("TOPLEFT", statusbg, "TOPLEFT", 7, -2)
		statustext:SetPoint("BOTTOMRIGHT", statusbg, "BOTTOMRIGHT", -7, 2)
		statustext:SetJustifyH("LEFT")
		statustext:SetJustifyV("TOP")
		statustext:SetText("")
		self.statustext = statustext
		
		-- Close button
		local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		closebutton:SetScript("OnClick", function()
			self:FireCallback("OnClose")
		end)
		closebutton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -27, 17)
		closebutton:SetHeight(20)
		closebutton:SetWidth(100)
		closebutton:SetText("Close")
		self.closebutton = closebutton
		
		-- Resizers
		local sizer_se = CreateFrame("Frame", nil, frame)
		sizer_se:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 25)
		sizer_se:SetWidth(25)
		sizer_se:SetHeight(25)
		sizer_se:EnableMouse(true)
		sizer_se:SetScript("OnMouseDown", function(f, button)
			if button == "LeftButton" then
				frame:StartSizing("BOTTOMRIGHT")
			end
		end)
		sizer_se:SetScript("OnMouseUp", function(f, button)
			frame:StopMovingOrSizing()
		end)
		local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line1:SetWidth(14)
		line1:SetHeight(14)
		line1:SetPoint("BOTTOMRIGHT", sizer_se, "BOTTOMRIGHT", -8, 8)
		line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		line1:SetTexCoord(0.7, 1, 0.7, 1)
		self.sizer_se = sizer_se
		
		-- Add borders
		self.borders = {}
		
		-- Movement
		frame:SetScript("OnMouseDown", function(frame, button)
			if button == "LeftButton" then
				frame:StartMoving()
			end
		end)
		frame:SetScript("OnMouseUp", function(frame, button)
			frame:StopMovingOrSizing()
		end)
		
		-- Container methods
		self.IsContainer = true
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetTitle = SetTitle
		self.SetStatusText = SetStatusText
		self.Hide = Hide
		self.Show = Show
		self.EnableResize = EnableResize
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
InlineGroup Widget
-------------------------------------------------------------------------------]]
do
	local Type = "InlineGroup"
	local Version = 6
	
	local function OnAcquire(self)
		self:SetWidth(300)
		self:SetHeight(100)
		self:SetTitle("")
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetTitle(self, title)
		self.titletext:SetText(title or "")
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(100)
		frame:SetWidth(300)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		
		-- Border
		local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		border:SetPoint("TOPLEFT", 0, -17)
		border:SetPoint("BOTTOMRIGHT")
		border:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		border:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
		border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
		
		-- Title
		local titletext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, 0)
		titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, 0)
		titletext:SetJustifyH("LEFT")
		titletext:SetHeight(18)
		self.titletext = titletext
		
		-- Content area
		local content = CreateFrame("Frame", nil, border)
		content:SetPoint("TOPLEFT", border, "TOPLEFT", 10, -10)
		content:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -10, 10)
		self.content = content
		
		-- Container methods
		self.IsContainer = true
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetTitle = SetTitle
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
ScrollFrame Widget
-------------------------------------------------------------------------------]]
do
	local Type = "ScrollFrame"
	local Version = 9
	
	local function OnAcquire(self)
		self:SetScroll(0)
		self:SetHeight(200)
		self:SetWidth(200)
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.scrollbar:SetValue(0)
	end
	
	local function SetScroll(self, value)
		local scrollbar = self.scrollbar
		scrollbar:SetValue(value)
		self:FixScroll()
	end
	
	local function FixScroll(self)
		local scrollbar = self.scrollbar
		local min, max = scrollbar:GetMinMaxValues()
		if scrollbar:GetValue() == 0 then
			scrollbar:Hide()
		else
			scrollbar:Show()
		end
		self:DoLayout()
	end
	
	local function Constructor()
		local frame = CreateFrame("ScrollFrame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(200)
		frame:SetWidth(200)
		frame:EnableMouseWheel(true)
		frame:SetScript("OnMouseWheel", function(frame, value)
			self.scrollbar:SetValue(self.scrollbar:GetValue() - value * 20)
		end)
		
		-- Scroll bar
		local scrollbar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
		scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", -16, 0)
		scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -16, 0)
		scrollbar:SetMinMaxValues(0, 400)
		scrollbar:SetValueStep(1)
		scrollbar:SetValue(0)
		scrollbar:SetWidth(16)
		scrollbar:SetScript("OnValueChanged", function()
			self:FixScroll()
		end)
		self.scrollbar = scrollbar
		
		-- Content frame
		local content = CreateFrame("Frame", nil, frame)
		content:SetHeight(400)
		content:SetWidth(200)
		frame:SetScrollChild(content)
		self.content = content
		
		-- Container methods
		self.IsContainer = true
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetScroll = SetScroll
		self.FixScroll = FixScroll
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
CheckBox Widget
-------------------------------------------------------------------------------]]
do
	local Type = "CheckBox"
	local Version = 24
	
	local function OnAcquire(self)
		self:SetWidth(200)
		self:SetHeight(24)
		self:SetValue(false)
		self:SetLabel("")
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetValue(self, value)
		self.check:SetChecked(value and true or false)
		self.checked = value and true or false
	end
	
	local function GetValue(self)
		return self.checked
	end
	
	local function SetLabel(self, text)
		self.text:SetText(text or "")
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(24)
		frame:SetWidth(200)
		
		-- Check button
		local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
		check:SetPoint("TOPLEFT")
		check:SetScript("OnClick", function()
			self.checked = check:GetChecked()
			self:FireCallback("OnValueChanged", self.checked)
		end)
		self.check = check
		
		-- Label
		local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("LEFT", check, "RIGHT", 2, 1)
		text:SetPoint("RIGHT", frame, "RIGHT")
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		self.text = text
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetValue = SetValue
		self.GetValue = GetValue
		self.SetLabel = SetLabel
		self.checked = false
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
EditBox Widget
-------------------------------------------------------------------------------]]
do
	local Type = "EditBox"
	local Version = 28
	
	local function OnAcquire(self)
		self:SetHeight(44)
		self:SetWidth(200)
		self:SetLabel("")
		self:SetText("")
		self.editbox:SetFocus()
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.editbox:ClearFocus()
	end
	
	local function SetText(self, text)
		self.editbox:SetText(text or "")
		self.editbox:SetCursorPosition(0)
	end
	
	local function GetText(self)
		return self.editbox:GetText()
	end
	
	local function SetLabel(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -18)
		else
			self.label:Hide()
			self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
		end
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(44)
		frame:SetWidth(200)
		
		-- Label
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
		label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)
		self.label = label
		
		-- Edit box
		local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		editbox:SetHeight(20)
		editbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18)
		editbox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -18)
		editbox:SetScript("OnEnterPressed", function()
			self:FireCallback("OnEnterPressed", editbox:GetText())
		end)
		editbox:SetScript("OnTextChanged", function()
			self:FireCallback("OnTextChanged", editbox:GetText())
		end)
		self.editbox = editbox
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetText = SetText
		self.GetText = GetText
		self.SetLabel = SetLabel
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
Button Widget
-------------------------------------------------------------------------------]]
do
	local Type = "Button"
	local Version = 24
	
	local function OnAcquire(self)
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetText("")
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.frame:SetText(text or "")
	end
	
	local function Constructor()
		local frame = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(24)
		frame:SetWidth(200)
		frame:SetScript("OnClick", function()
			self:FireCallback("OnClick")
		end)
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetText = SetText
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
Label Widget
-------------------------------------------------------------------------------]]
do
	local Type = "Label"
	local Version = 24
	
	local function OnAcquire(self)
		self:SetHeight(18)
		self:SetWidth(200)
		self:SetText("")
		self:SetColor(1, 1, 1)
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
	end
	
	local function SetColor(self, r, g, b)
		self.label:SetTextColor(r or 1, g or 1, b or 1)
	end
	
	local function SetFontObject(self, font)
		self.label:SetFontObject(font or GameFontHighlight)
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(18)
		frame:SetWidth(200)
		
		-- Label text
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("TOPLEFT")
		label:SetPoint("BOTTOMRIGHT")
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
		self.label = label
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetText = SetText
		self.SetColor = SetColor
		self.SetFontObject = SetFontObject
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--[[-----------------------------------------------------------------------------
Heading Widget
-------------------------------------------------------------------------------]]
do
	local Type = "Heading"
	local Version = 24
	
	local function OnAcquire(self)
		self:SetHeight(18)
		self:SetWidth(200)
		self:SetText("")
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		local self = {}
		self.type = Type
		self.frame = frame
		
		frame:SetHeight(18)
		frame:SetWidth(200)
		
		-- Label text
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT")
		label:SetPoint("BOTTOMRIGHT")
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
		self.label = label
		
		-- Methods
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetText = SetText
		
		return self
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end