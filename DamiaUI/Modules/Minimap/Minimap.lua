-- DamiaUI Minimap Module
-- Based on ColdMisc minimap.lua, updated for WoW 11.2

local addonName, ns = ...
local Minimap = {}
ns.Minimap = Minimap

-- Configuration
Minimap.config = {}

-- Initialize module
function Minimap:Initialize()
    -- Get config
    self.config = ns.config.minimap
    
    if not self.config or not self.config.enabled then
        return
    end
    
    -- Setup minimap
    self:SetupMinimap()
    
    -- Setup clock
    if self.config.showClock then
        self:SetupClock()
    end
    
    -- Setup calendar
    if self.config.showCalendar then
        self:SetupCalendar()
    end
    
    -- Setup tracking
    if self.config.showTracking then
        self:SetupTracking()
    end
    
    -- Setup zone text
    self:SetupZoneText()
    
    -- Setup coordinates
    self:SetupCoordinates()
    
    -- Hide unnecessary elements
    self:HideElements()
    
    -- Setup mouse wheel zoom
    self:SetupMouseWheel()
    
    ns:Print("Minimap module loaded")
end

-- Setup minimap
function Minimap:SetupMinimap()
    -- Use MinimapCluster if it exists, otherwise use Minimap directly
    local minimapParent = MinimapCluster or Minimap
    
    -- Set size and scale
    minimapParent:SetScale(self.config.scale or 1.1)
    Minimap:SetSize(self.config.size or 140, self.config.size or 140)
    
    -- Position
    minimapParent:ClearAllPoints()
    if self.config.pos then
        minimapParent:SetPoint(unpack(self.config.pos))
    else
        minimapParent:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
    end
    
    -- Make movable
    minimapParent:SetMovable(true)
    minimapParent:SetUserPlaced(true)
    minimapParent:SetClampedToScreen(true)
    minimapParent:EnableMouse(true)
    minimapParent:RegisterForDrag("LeftButton")
    minimapParent:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    minimapParent:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Square shape
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    
    -- Create backdrop
    if not Minimap.backdrop then
        Minimap.backdrop = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        Minimap.backdrop:SetPoint("TOPLEFT", -3, 3)
        Minimap.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
        Minimap.backdrop:SetFrameLevel(Minimap:GetFrameLevel() - 1)
        ns:CreateBackdrop(Minimap.backdrop)
    end
    
    -- Blip texture (player and party dots)
    Minimap:SetBlipTexture("Interface\\Minimap\\ObjectIconsAtlas")
end

-- Setup clock
function Minimap:SetupClock()
    -- Create clock frame if needed
    if not TimeManagerClockButton then return end
    
    local clock = TimeManagerClockButton
    local region = clock:GetRegions()
    region:Hide()
    clock:ClearAllPoints()
    clock:SetPoint("TOP", Minimap, "BOTTOM", 0, -5)
    clock:SetScript("OnClick", function()
        if TimeManager_Toggle then
            TimeManager_Toggle()
        else
            TimeManagerFrame:SetShown(not TimeManagerFrame:IsShown())
        end
    end)
    
    -- Style clock text
    local text = TimeManagerClockTicker
    if text then
        text:SetFont(ns.media.font, 12, "OUTLINE")
        text:SetTextColor(1, 1, 1)
    end
end

-- Setup calendar
function Minimap:SetupCalendar()
    if not GameTimeFrame then return end
    
    GameTimeFrame:SetParent(Minimap)
    GameTimeFrame:SetScale(0.8)
    GameTimeFrame:ClearAllPoints()
    GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
    GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
    GameTimeFrame:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
    GameTimeFrame:SetNormalTexture("Interface\\Calendar\\UI-Calendar-Button")
    GameTimeFrame:SetPushedTexture(nil)
    GameTimeFrame:SetHighlightTexture(nil)
    
    -- Create border
    local border = GameTimeFrame:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER")
end

-- Setup tracking
function Minimap:SetupTracking()
    -- Tracking button in 11.2
    if MiniMapTracking then
        MiniMapTracking:ClearAllPoints()
        MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        MiniMapTracking:SetScale(0.8)
    end
    
    -- New tracking in modern WoW
    if MiniMapTrackingButton then
        MiniMapTrackingButton:ClearAllPoints()
        MiniMapTrackingButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        MiniMapTrackingButton:SetScale(0.8)
    end
end

-- Setup zone text
function Minimap:SetupZoneText()
    -- Create zone text frame
    if not self.zoneText then
        self.zoneText = CreateFrame("Frame", "DamiaUIMinimapZone", Minimap)
        self.zoneText:SetPoint("TOP", Minimap, "TOP", 0, -2)
        self.zoneText:SetSize(130, 20)
        
        self.zoneText.text = self.zoneText:CreateFontString(nil, "OVERLAY")
        self.zoneText.text:SetFont(ns.media.font, 11, "OUTLINE")
        self.zoneText.text:SetPoint("CENTER")
        self.zoneText.text:SetJustifyH("CENTER")
        self.zoneText.text:SetTextColor(1, 1, 1)
    end
    
    -- Update zone text
    local function UpdateZoneText()
        local zone = GetMinimapZoneText()
        local pvpType = GetZonePVPInfo()
        local r, g, b = 1, 1, 1
        
        if pvpType == "sanctuary" then
            r, g, b = 0.41, 0.8, 0.94
        elseif pvpType == "arena" or pvpType == "combat" then
            r, g, b = 1, 0.1, 0.1
        elseif pvpType == "contested" then
            r, g, b = 1, 0.7, 0
        elseif pvpType == "friendly" then
            r, g, b = 0.1, 1, 0.1
        elseif pvpType == "hostile" then
            r, g, b = 1, 0.1, 0.1
        end
        
        self.zoneText.text:SetText(zone)
        self.zoneText.text:SetTextColor(r, g, b)
    end
    
    -- Register events
    self.zoneText:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.zoneText:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.zoneText:RegisterEvent("ZONE_CHANGED")
    self.zoneText:RegisterEvent("ZONE_CHANGED_INDOORS")
    self.zoneText:SetScript("OnEvent", UpdateZoneText)
    
    UpdateZoneText()
end

-- Setup coordinates
function Minimap:SetupCoordinates()
    -- Create coordinate frame
    if not self.coords then
        self.coords = CreateFrame("Frame", "DamiaUIMinimapCoords", Minimap)
        self.coords:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 2)
        self.coords:SetSize(80, 20)
        
        self.coords.text = self.coords:CreateFontString(nil, "OVERLAY")
        self.coords.text:SetFont(ns.media.font, 11, "OUTLINE")
        self.coords.text:SetPoint("CENTER")
        self.coords.text:SetTextColor(1, 1, 1)
    end
    
    -- Update coordinates
    local updateTimer = 0
    self.coords:SetScript("OnUpdate", function(self, elapsed)
        updateTimer = updateTimer + elapsed
        if updateTimer > 0.1 then
            updateTimer = 0
            
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local position = C_Map.GetPlayerMapPosition(mapID, "player")
                if position then
                    local x, y = position:GetXY()
                    if x and y then
                        self.text:SetFormattedText("%.1f, %.1f", x * 100, y * 100)
                    else
                        self.text:SetText("")
                    end
                else
                    self.text:SetText("")
                end
            else
                self.text:SetText("")
            end
        end
    end)
end

-- Hide unnecessary elements
function Minimap:HideElements()
    local elementsToHide = {
        MinimapBorder,
        MinimapBorderTop,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapVoiceChatFrame,
        MinimapNorthTag,
        MiniMapWorldMapButton,
        MinimapZoneTextButton,
        MiniMapMailBorder,
        MiniMapInstanceDifficulty,
        GuildInstanceDifficulty,
        MiniMapChallengeMode,
        MinimapBackdrop,
        -- Modern elements
        MinimapCompassTexture,
        ExpansionLandingPageMinimapButton,
        QueueStatusMinimapButton,
    }
    
    -- Add MinimapCluster.BorderTop if it exists
    if MinimapCluster and MinimapCluster.BorderTop then
        table.insert(elementsToHide, MinimapCluster.BorderTop)
    end
    
    for _, element in pairs(elementsToHide) do
        if element then
            element:Hide()
            element.Show = function() end
        end
    end
    
    -- Handle mail icon
    if MiniMapMailFrame then
        MiniMapMailFrame:ClearAllPoints()
        MiniMapMailFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
        
        if MiniMapMailIcon then
            MiniMapMailIcon:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
        end
    end
    
    -- Handle LFG icon
    if QueueStatusMinimapButton then
        QueueStatusMinimapButton:ClearAllPoints()
        QueueStatusMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
        QueueStatusMinimapButtonBorder:Hide()
    end
    
    -- Handle garrison/mission button
    if GarrisonLandingPageMinimapButton then
        GarrisonLandingPageMinimapButton:SetScale(0.8)
        GarrisonLandingPageMinimapButton:ClearAllPoints()
        GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    end
    
    if ExpansionLandingPageMinimapButton then
        ExpansionLandingPageMinimapButton:SetScale(0.8)
        ExpansionLandingPageMinimapButton:ClearAllPoints()
        ExpansionLandingPageMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    end
end

-- Setup mouse wheel zoom
function Minimap:SetupMouseWheel()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
    
    -- Right click menu (moved inside function)
    Minimap:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            -- Toggle tracking menu
            local dropdown = CreateFrame("Frame", "DamiaUIMinimapDropdown", UIParent, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
            
            -- In modern WoW, use the built-in minimap tracking menu
            if MiniMapTrackingDropDown then
                ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self, 0, 0)
            else
                -- Create custom menu
                local menuList = {}
                table.insert(menuList, {text = "Calendar", func = function() 
                    if Calendar_Toggle then Calendar_Toggle() else GameTimeFrame:Click() end
                end})
                table.insert(menuList, {text = "Tracking", func = function() 
                    if MiniMapTracking then MiniMapTracking:Click() end
                end})
                
                EasyMenu(menuList, dropdown, "cursor", 0, 0, "MENU", 2)
            end
        elseif button == "MiddleButton" then
            -- Toggle calendar
            if Calendar_Toggle then
                Calendar_Toggle()
            else
                if GameTimeFrame then
                    GameTimeFrame:Click()
                end
            end
        end
    end)
end

-- Register module
ns:RegisterModule("Minimap", Minimap)