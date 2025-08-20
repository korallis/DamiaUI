local _, DamiaUI = ...

-- =============================================================================
-- MINIMAP AND OBJECTIVE TRACKER STYLING
-- =============================================================================

local MinimapMod = DamiaUI:CreateModule("MinimapMod")

local function SkinMinimap()
	if not Minimap then return end
	-- Square look with dark border
	if Minimap.SetMaskTexture then
		Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8x8")
	end
	local panel = DamiaUI:CreateBorderedPanel("DamiaUIMinimapPanel", Minimap)
	panel:SetPoint("TOPLEFT", Minimap, -6, 6)
	panel:SetPoint("BOTTOMRIGHT", Minimap, 6, -6)
	panel:SetFrameStrata("LOW")
	-- Hide default rings/decoration if present
	for _, obj in ipairs({MinimapBorder, MinimapBorderTop, MinimapZoneTextButton, MinimapZoomIn, MinimapZoomOut, MinimapNorthTag}) do
		if obj and obj.Hide then obj:Hide() end
	end
	-- Move to top-right and size
	Minimap:ClearAllPoints()
	Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
	Minimap:SetSize(180, 180)
end

local function SkinObjectiveTracker()
	local f = ObjectiveTrackerFrame or ObjectiveTracker
	if not f then return end
	-- Anchor below minimap
	f:ClearAllPoints()
	f:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -12)
	-- Thin header backdrop
	if not f.DamiaPanel then
		local p = DamiaUI:CreateBorderedPanel(nil, f)
		p:SetPoint("TOPLEFT", f, -6, 6)
		p:SetPoint("BOTTOMRIGHT", f, 6, -6)
		p:SetAlpha(0.0) -- invisible frame to stabilize size; actual skin is heavy to replicate, keep minimal for now
		f.DamiaPanel = p
	end
end

function MinimapMod:Initialize()
	SkinMinimap()
	SkinObjectiveTracker()
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
	MinimapMod:Initialize()
end)

DamiaUI.modules.MinimapMod = MinimapMod
