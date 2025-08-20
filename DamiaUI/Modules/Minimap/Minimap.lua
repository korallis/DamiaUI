-- DamiaUI Minimap Module
-- Based on ColdMisc minimap.lua, updated for WoW 11.2 with modern Menu API

local addonName, ns = ...
local Minimap = {}
ns.Minimap = Minimap

-- Module registration
ns:RegisterModule("Minimap", Minimap)

-- API Compatibility checks
local hasModernMenuAPI = MenuUtil and MenuUtil.CreateContextMenu
local hasModernTrackingAPI = C_Minimap and C_Minimap.GetTrackingInfo and C_Minimap.SetTracking

-- Initialize module
function Minimap:Initialize()
    -- Get config with defaults
    self.config = ns:GetConfig("minimap") or {
        enabled = true,
        scale = 1.1,
        size = 140,
        showClock = true,
        showCalendar = true,
        showTracking = true,
        pos = {"TOPRIGHT", UIParent, "TOPRIGHT", -10, -10}
    }
    
    if not self.config.enabled then
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
    
    if ns.LogDebug then
        ns:LogDebug("Minimap module loaded")
    end
end

-- Setup minimap
function Minimap:SetupMinimap()
    -- Use MinimapCluster if it exists, otherwise use Minimap directly
    local minimapParent = MinimapCluster or _G.Minimap
    
    -- Set size and scale
    minimapParent:SetScale(self.config.scale or 1.1)
    _G.Minimap:SetSize(self.config.size or 140, self.config.size or 140)
    
    -- Position
    minimapParent:ClearAllPoints()
    if self.config.pos and type(self.config.pos) == "table" then
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
    _G.Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    
    -- Create backdrop
    if not _G.Minimap.backdrop then
        _G.Minimap.backdrop = CreateFrame("Frame", nil, _G.Minimap, "BackdropTemplate")
        _G.Minimap.backdrop:SetPoint("TOPLEFT", -3, 3)
        _G.Minimap.backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
        _G.Minimap.backdrop:SetFrameLevel(_G.Minimap:GetFrameLevel() - 1)
        
        _G.Minimap.backdrop:SetBackdrop({
            bgFile = ns.media.texture,
            edgeFile = ns.media.texture,
            edgeSize = 1,
        })
        _G.Minimap.backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        _G.Minimap.backdrop:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    -- Blip texture (player and party dots)
    _G.Minimap:SetBlipTexture("Interface\\Minimap\\ObjectIconsAtlas")
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
    -- Find and position the tracking button using multiple possible names
    local trackingButtons = {
        MiniMapTracking,
        MiniMapTrackingButton,
        MinimapCluster and MinimapCluster.Tracking,
        MinimapCluster and MinimapCluster.TrackingButton
    }
    
    local trackingButton
    for _, button in pairs(trackingButtons) do
        if button then
            trackingButton = button
            break
        end
    end
    
    if trackingButton then
        -- Position and scale the tracking button
        trackingButton:ClearAllPoints()
        trackingButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        trackingButton:SetScale(0.8)
        
        -- Ensure it's shown if tracking is available
        if hasModernTrackingAPI then
            local success, numTrackingTypes = pcall(C_Minimap.GetNumTrackingTypes)
            if success and numTrackingTypes and numTrackingTypes > 0 then
                trackingButton:Show()
            end
        end
        
        -- Override click handler to use modern API if available
        if hasModernTrackingAPI then
            trackingButton:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    -- Show tracking menu using modern Menu API
                    if MenuUtil and MenuUtil.CreateContextMenu then
                        MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
                            rootDescription:CreateTitle("Minimap Tracking")
                            
                            local hasTracking = false
                            for i = 1, numTrackingTypes do
                                local name, textureFileID, active, trackingType = C_Minimap.GetTrackingInfo(i)
                                if name then
                                    hasTracking = true
                                    local trackingOption = rootDescription:CreateButton(name, function()
                                        C_Minimap.SetTracking(i, not active)
                                    end)
                                    if active then
                                        trackingOption:SetChecked(true)
                                    end
                                end
                            end
                            
                            if not hasTracking then
                                rootDescription:CreateButton("No tracking available", function() end)
                            end
                        end)
                    end
                end
            end)
        end
    else
        -- Create a simple tracking indicator if no button exists
        if not self.trackingFrame and hasModernTrackingAPI then
            local success, numTrackingTypes = pcall(C_Minimap.GetNumTrackingTypes)
            if success and numTrackingTypes and numTrackingTypes > 0 then
                self.trackingFrame = CreateFrame("Button", "DamiaUITrackingButton", Minimap)
                self.trackingFrame:SetSize(16, 16)
                self.trackingFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
                
                local texture = self.trackingFrame:CreateTexture(nil, "ARTWORK")
                texture:SetAllPoints()
                texture:SetTexture("Interface\\Minimap\\Tracking\\None")
                
                self.trackingFrame:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" and hasModernMenuAPI then
                        MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
                            rootDescription:CreateTitle("Minimap Tracking")
                            
                            local success2, numTypes = pcall(C_Minimap.GetNumTrackingTypes)
                            if success2 and numTypes then
                                for i = 1, numTypes do
                                    local success3, name, textureFileID, active = pcall(C_Minimap.GetTrackingInfo, i)
                                    if success3 and name then
                                        local option = rootDescription:CreateButton(name, function()
                                            pcall(C_Minimap.SetTracking, i, not active)
                                        end)
                                        if active then
                                            option:SetChecked(true)
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)
                
                -- Tooltip
                self.trackingFrame:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:SetText("Tracking Options")
                    GameTooltip:AddLine("Left-click to open tracking menu", 1, 1, 1)
                    GameTooltip:Show()
                end)
                
                self.trackingFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            end
        end
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
    -- Check if coordinate APIs are available
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then
        if ns.LogDebug then
            ns:LogDebug("Map coordinate APIs not available")
        end
        return
    end
    
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
    
    -- Update coordinates with error handling
    local updateTimer = 0
    self.coords:SetScript("OnUpdate", function(self, elapsed)
        updateTimer = updateTimer + elapsed
        if updateTimer > 0.1 then
            updateTimer = 0
            
            -- Wrap coordinate fetching in pcall for safety
            local success, mapID = pcall(C_Map.GetBestMapForUnit, "player")
            if success and mapID then
                local success2, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
                if success2 and position then
                    local x, y = position:GetXY()
                    if x and y and x > 0 and y > 0 then
                        self.text:SetFormattedText("%.1f, %.1f", x * 100, y * 100)
                    else
                        self.text:SetText("---.-, ---.--")
                    end
                else
                    self.text:SetText("---.-, ---.--")
                end
            else
                self.text:SetText("---.-, ---.--")
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
    
    -- Right click menu using modern Menu API
    Minimap:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            -- Create context menu using modern Menu API
            if hasModernMenuAPI then
                local success, err = pcall(function()
                    MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
                        -- Add calendar option
                        rootDescription:CreateButton("Calendar", function()
                            if Calendar_Toggle then 
                                Calendar_Toggle() 
                            elseif GameTimeFrame then 
                                GameTimeFrame:Click() 
                            end
                        end)
                        
                        -- Add tracking submenu if modern tracking API is available
                        if hasModernTrackingAPI then
                            local trackingSubmenu = rootDescription:CreateButton("Tracking")
                            trackingSubmenu:CreateSubmenu(function(submenu)
                                local success2, numTrackingTypes = pcall(C_Minimap.GetNumTrackingTypes)
                                if success2 and numTrackingTypes and numTrackingTypes > 0 then
                                    for i = 1, numTrackingTypes do
                                        local success3, name, textureFileID, active, type, subType, spellID = pcall(C_Minimap.GetTrackingInfo, i)
                                        if success3 and name then
                                            local trackingButton = submenu:CreateButton(name, function()
                                                pcall(C_Minimap.SetTracking, i, not active)
                                            end)
                                            if active then
                                                trackingButton:SetChecked(true)
                                            end
                                        end
                                    end
                                else
                                    submenu:CreateButton("No tracking available", function() end)
                                end
                            end)
                        else
                            -- Fallback tracking option
                            rootDescription:CreateButton("Tracking", function()
                                if MiniMapTracking and MiniMapTracking:IsVisible() then
                                    MiniMapTracking:Click()
                                end
                            end)
                        end
                        
                        -- Add separator
                        rootDescription:CreateDivider()
                        
                        -- Add zoom options
                        rootDescription:CreateButton("Zoom In", function()
                            if Minimap_ZoomIn then
                                Minimap_ZoomIn()
                            end
                        end)
                        rootDescription:CreateButton("Zoom Out", function()
                            if Minimap_ZoomOut then
                                Minimap_ZoomOut()
                            end
                        end)
                    end)
                end)
                
                if not success and ns.LogDebug then
                    ns:LogDebug("Error creating context menu: " .. tostring(err))
                end
            else
                -- Fallback for clients without modern Menu API
                print("DamiaUI: Right-click menu unavailable (Menu API not found)")
                -- Try to open tracking button directly
                if MiniMapTracking and MiniMapTracking:IsVisible() then
                    MiniMapTracking:Click()
                elseif GameTimeFrame and GameTimeFrame:IsVisible() then
                    GameTimeFrame:Click()
                end
            end
        elseif button == "MiddleButton" then
            -- Toggle calendar with error handling
            local success = false
            if Calendar_Toggle then
                success = pcall(Calendar_Toggle)
            elseif GameTimeFrame and GameTimeFrame:IsVisible() then
                success = pcall(function() GameTimeFrame:Click() end)
            end
            
            if not success and ns.LogDebug then
                ns:LogDebug("Unable to toggle calendar")
            end
        end
    end)
end

-- Disable module and clean up
function Minimap:Disable()
    -- Unregister all events
    if self.zoneText then
        self.zoneText:UnregisterAllEvents()
        self.zoneText:SetScript("OnEvent", nil)
    end
    
    if self.coords then
        self.coords:SetScript("OnUpdate", nil)
    end
    
    if self.clockFrame then
        self.clockFrame:UnregisterAllEvents()
        self.clockFrame:SetScript("OnUpdate", nil)
    end
    
    -- Restore hidden elements if needed
    if MinimapZoomIn then MinimapZoomIn:Show() end
    if MinimapZoomOut then MinimapZoomOut:Show() end
    if MiniMapTracking then MiniMapTracking:Show() end
    if MiniMapWorldMapButton then MiniMapWorldMapButton:Show() end
    if MinimapNorthTag then MinimapNorthTag:Show() end
    
    -- Clear references to prevent memory leaks
    self.zoneText = nil
    self.coords = nil
    self.clockFrame = nil
    self.config = nil
    
    ns:Debug("Minimap module disabled and cleaned up")
end

-- Return module
return Minimap