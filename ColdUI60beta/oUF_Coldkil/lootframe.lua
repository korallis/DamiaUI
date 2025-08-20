--get the addon namespace
local addon, ns = ...

--get the config values
local cfg = ns.cfg

-- get the library
local lib = ns.lib

if not cfg.plugins.lootframe then return end

local tex = cfg.tex

-- our personal movable anchor
local lootanchor =  CreateFrame("Frame", "ColdLoot", LootFrame)
lootanchor:SetSize(155, 120)
lootanchor:SetPoint("LEFT", UIParent, "CENTER", 20, 0)
lib.dragalize(lootanchor)

local CreateBG = function(frame)
	local f = frame
	if frame:GetObjectType() == "Texture" then f = frame:GetParent() end

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", frame, -1, 1)
	bg:SetPoint("BOTTOMRIGHT", frame, 1, -1)
	bg:SetTexture(tex)
	bg:SetVertexColor(0, 0, 0)

	return bg
end

local CreateBD = function(f)
	f:SetBackdrop({
		bgFile = tex,
		edgeFile = tex,
		edgeSize = 1,
	})
	f:SetBackdropColor(.2,.2,.2, .6)
	f:SetBackdropBorderColor(0, 0, 0)
end

local deleteoldlootframe = function(f, isButtonFrame)
	local name = f:GetName()

	_G[name.."Bg"]:Hide()
	_G[name.."TitleBg"]:Hide()
	_G[name.."Portrait"]:Hide()
	_G[name.."PortraitFrame"]:Hide()
	_G[name.."TopRightCorner"]:Hide()
	_G[name.."TopLeftCorner"]:Hide()
	_G[name.."TopBorder"]:Hide()
	_G[name.."TopTileStreaks"]:SetTexture("")
	_G[name.."BotLeftCorner"]:Hide()
	_G[name.."BotRightCorner"]:Hide()
	_G[name.."BottomBorder"]:Hide()
	_G[name.."LeftBorder"]:Hide()
	_G[name.."RightBorder"]:Hide()
	_G[name.."CloseButton"]:Hide()

	if isButtonFrame then
		_G[name.."BtnCornerLeft"]:SetTexture("")
		_G[name.."BtnCornerRight"]:SetTexture("")
		_G[name.."ButtonBottomBorder"]:SetTexture("")

		f.Inset.Bg:Hide()
		f.Inset:DisableDrawLayer("BORDER")
	end
end

LootFramePortraitOverlay:Hide()
select(19, LootFrame:GetRegions()):Hide()

hooksecurefunc("LootFrame_UpdateButton", function(index)
	local ic = _G["LootButton"..index.."IconTexture"]
	local te = _G["LootButton"..index.."Text"]
	local co = _G["LootButton"..index.."Count"]

	if not ic.bg then
		local bu = _G["LootButton"..index]
		local pre = _G["LootButton"..index-1]

		_G["LootButton"..index.."IconQuestTexture"]:SetAlpha(0)
		_G["LootButton"..index.."NameFrame"]:Hide()

		bu:SetNormalTexture("")
		bu:SetPushedTexture("")
		
		bu:SetSize(26,26)
		bu:ClearAllPoints()
		bu:SetParent(lootanchor)
		if index == 1 then
			bu:SetPoint"TOPLEFT"
		else	
			bu:SetPoint("TOP", pre, "BOTTOM", 0, -3)
		end
		
		local bd = CreateFrame("Frame", nil, bu)
		bd:SetPoint("TOPLEFT", 26, 0)
		bd:SetPoint("BOTTOMRIGHT", 130, 0)
		bd:SetFrameLevel(bu:GetFrameLevel()-1)
		CreateBD(bd)

		ic:SetTexCoord(.08, .92, .08, .92)
		ic.bg = CreateBG(ic)
		
		te:ClearAllPoints()
		te:SetPoint("TOPLEFT", bd, "TOPLEFT", 3, -2)
		te:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -2, 2)
		
		co:ClearAllPoints()
		co:SetPoint("BOTTOMRIGHT",2,0)
		co:SetTextColor(0, 1, 0)
	end
	
	local icon, _, _, quality, _, isQuestItem, _, _ = GetLootSlotInfo(index)
	if isQuestItem then
		ic.bg:SetVertexColor(1, 0, 0)
	elseif icon then
		local color = ITEM_QUALITY_COLORS[quality]
		ic.bg:SetVertexColor(color.r, color.g, color.b)
	else
		ic.bg:SetVertexColor(0,0,0)
	end
end)

-- reposition prev/next buttons (until i find a way to display more than # items).
LootFrameDownButton:ClearAllPoints()
LootFrameDownButton:SetPoint("BOTTOMRIGHT", lootanchor, "BOTTOMRIGHT", -4, 4)
LootFrameUpButton:ClearAllPoints()
LootFrameUpButton:SetPoint("BOTTOMLEFT", lootanchor, "BOTTOMLEFT", -4, 4)
LootFramePrev:ClearAllPoints()
LootFramePrev:SetPoint("LEFT", LootFrameUpButton, "RIGHT", 4, 0)
LootFrameNext:ClearAllPoints()
LootFrameNext:SetPoint("RIGHT", LootFrameDownButton, "LEFT", -4, 0)

-- get rid of blizz frame (ideally :D)
deleteoldlootframe(LootFrame, true)