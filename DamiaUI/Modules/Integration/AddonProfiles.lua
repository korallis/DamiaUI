--[[
    DamiaUI - Addon Positioning Profiles System
    
    Comprehensive profiles for popular addon positioning and integration.
    Implements viewport-first design philosophy with intelligent positioning
    based on addon type and functionality.
    
    Features:
    - Pre-configured profiles for popular addons
    - Intelligent conflict resolution
    - Dynamic positioning based on screen resolution
    - Category-based priority system
    - Compatibility layer for various addon types
    
    Author: DamiaUI Development Team
    Version: 1.0.0
]]

local addonName, DamiaUI = ...
if not DamiaUI then return end

-- Local references for performance
local _G = _G
local pairs, ipairs, type = pairs, ipairs, type
local math = math
local string = string

-- Module initialization
local AddonProfiles = {}
DamiaUI.Integration = DamiaUI.Integration or {}
DamiaUI.Integration.AddonProfiles = AddonProfiles

-- Module state
local profiles = {}
local categories = {}
local viewportConfig = {}
local conflictResolutions = {}

-- Default positioning templates
local POSITION_TEMPLATES = {
    -- Combat/DPS meters - bottom right, out of combat view
    dps_meter = {
        targetZone = "bottomRight",
        offsetX = -50, offsetY = 50,
        anchor = "BOTTOMRIGHT",
        scale = 0.9,
        alpha = 0.95,
        lockPosition = true
    },
    
    -- Raid/Dungeon tools - top center for visibility
    raid_tool = {
        targetZone = "topCenter",
        offsetX = 0, offsetY = -25,
        anchor = "TOP",
        scale = 1.0,
        alpha = 0.9,
        lockPosition = true
    },
    
    -- WeakAuras - centered above unit frames
    weakauras = {
        targetZone = "gameplay",
        offsetX = 0, offsetY = 100,
        anchor = "CENTER",
        scale = 1.0,
        alpha = 1.0,
        allowOverlap = true
    },
    
    -- Action bar replacements - bottom center
    action_bars = {
        targetZone = "bottomCenter",
        offsetX = 0, offsetY = 80,
        anchor = "BOTTOM",
        scale = 1.0,
        alpha = 0.95,
        lockPosition = true
    },
    
    -- Nameplates - integrated with existing UI
    nameplates = {
        targetZone = "gameplay",
        offsetX = 0, offsetY = 0,
        anchor = "CENTER",
        scale = 1.0,
        alpha = 1.0,
        integrated = true
    },
    
    -- Chat enhancements - left side
    chat = {
        targetZone = "leftSide",
        offsetX = 50, offsetY = 0,
        anchor = "LEFT",
        scale = 0.95,
        alpha = 0.9
    },
    
    -- Utility/Enhancement addons - right side
    utility = {
        targetZone = "rightSide",
        offsetX = -50, offsetY = 0,
        anchor = "RIGHT",
        scale = 0.9,
        alpha = 0.85
    }
}

--[[
    Comprehensive Addon Profiles
]]

local ADDON_PROFILES = {
    -- Combat/DPS Addons
    ["Details"] = {
        category = "DPS_METERS",
        positioning = POSITION_TEMPLATES.dps_meter,
        frames = function()
            local frames = {}
            if _detalhes then
                for i = 1, 5 do
                    local instance = _detalhes:GetInstance(i)
                    if instance and instance.baseFrame then
                        table.insert(frames, instance.baseFrame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if _detalhes then
                    for i = 1, 5 do
                        local instance = _detalhes:GetInstance(i)
                        if instance and instance.baseFrame then
                            table.insert(frames, instance.baseFrame)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinDetailsFrames",
            loadDelay = 2,
            checkFunction = function() return _detalhes and _detalhes:GetCurrentInstance() end
        },
        requirements = {
            minVersion = "1.0.0",
            dependencies = {}
        },
        configuration = {
            autoHide = true,
            combatOnly = false,
            backgroundAlpha = 0.8
        }
    },
    
    ["Recount"] = {
        category = "DPS_METERS", 
        positioning = POSITION_TEMPLATES.dps_meter,
        frames = { "RecountMainWindow", "RecountConfigWindow" },
        skinningData = {
            frames = { "RecountMainWindow", "RecountConfigWindow" },
            skinFunction = "SkinRecountFrames",
            loadDelay = 1,
            checkFunction = function() return Recount and Recount.MainWindow end
        },
        conflicts = { "Details", "Skada" }, -- Don't position if these are active
        configuration = {
            autoHide = true,
            combatOnly = false
        }
    },
    
    ["Skada"] = {
        category = "DPS_METERS",
        positioning = POSITION_TEMPLATES.dps_meter,
        frames = function()
            local frames = {}
            if Skada then
                for _, window in ipairs(Skada:GetWindows()) do
                    if window.bargroup and window.bargroup.frame then
                        table.insert(frames, window.bargroup.frame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if Skada then
                    for _, window in ipairs(Skada:GetWindows()) do
                        if window.bargroup and window.bargroup.frame then
                            table.insert(frames, window.bargroup.frame)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinSkadaFrames",
            loadDelay = 2,
            checkFunction = function() return Skada end
        },
        conflicts = { "Details", "Recount" }
    },
    
    -- WeakAuras - Special handling for aura positioning
    ["WeakAuras"] = {
        category = "RAID_COMBAT",
        positioning = {
            targetZone = "gameplay",
            offsetX = 0, offsetY = 120,
            anchor = "CENTER",
            scale = 1.0,
            alpha = 1.0,
            specialHandling = "weakauras_groups"
        },
        frames = function()
            local frames = {}
            if WeakAuras then
                -- Get WeakAuras display regions
                for id, data in pairs(WeakAuras.regions) do
                    if data.region then
                        table.insert(frames, data.region)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function() 
                local frames = {}
                if WeakAuras and WeakAuras.GetOptionsFrame then
                    local optionsFrame = WeakAuras.GetOptionsFrame()
                    if optionsFrame then
                        table.insert(frames, optionsFrame)
                    end
                end
                return frames
            end,
            skinFunction = "SkinWeakAurasFrames",
            loadDelay = 3,
            checkFunction = function() return WeakAuras end
        },
        specialIntegration = true,
        configuration = {
            autoPosition = true,
            respectGroups = true,
            centerBias = true
        }
    },
    
    -- Raid/Dungeon Tools
    ["DBM-Core"] = {
        category = "RAID_COMBAT",
        positioning = POSITION_TEMPLATES.raid_tool,
        frames = function()
            local frames = {}
            if DBM and DBM.Bars then
                -- Get DBM bar frames
                local bars = DBM.Bars:GetActiveBars()
                for _, bar in pairs(bars) do
                    if bar.frame then
                        table.insert(frames, bar.frame)
                    end
                end
                -- Add warning frames
                if DBM.Flash then
                    table.insert(frames, DBM.Flash)
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if DBM and DBM.Bars then
                    for _, bar in pairs(DBM.Bars:GetActiveBars()) do
                        if bar.frame then
                            table.insert(frames, bar.frame)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinDBMFrames",
            loadDelay = 2,
            checkFunction = function() return DBM end
        },
        conflicts = { "BigWigs" },
        configuration = {
            warningPosition = "top",
            barAnchor = "topCenter"
        }
    },
    
    ["BigWigs"] = {
        category = "RAID_COMBAT",
        positioning = POSITION_TEMPLATES.raid_tool,
        frames = { "BigWigsAnchor", "BigWigsEmphasizeAnchor", "BigWigsMessagesAnchor" },
        skinningData = {
            frames = { "BigWigsAnchor", "BigWigsEmphasizeAnchor" },
            skinFunction = "SkinBigWigsFrames", 
            loadDelay = 1,
            checkFunction = function() return BigWigs end
        },
        conflicts = { "DBM-Core" },
        configuration = {
            messagePosition = "top",
            emphasizePosition = "center"
        }
    },
    
    -- Nameplate Addons
    ["Plater"] = {
        category = "ENHANCEMENT",
        positioning = POSITION_TEMPLATES.nameplates,
        frames = function()
            local frames = {}
            if Plater then
                -- Plater manages its own nameplate frames
                -- We mainly want to ensure proper integration
                if Plater.GetAllShownPlates then
                    local plates = Plater.GetAllShownPlates()
                    for _, plateFrame in pairs(plates) do
                        table.insert(frames, plateFrame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            integrated = true, -- Plater handles its own styling
            applyAuroraTheme = false
        },
        specialIntegration = true,
        configuration = {
            integratedStyling = true,
            respectDamiaTheme = true
        }
    },
    
    ["TidyPlates"] = {
        category = "ENHANCEMENT",
        positioning = POSITION_TEMPLATES.nameplates,
        frames = { "TidyPlatesConfigPanel" },
        skinningData = {
            frames = { "TidyPlatesConfigPanel" },
            skinFunction = "SkinTidyPlatesFrames",
            loadDelay = 1,
            checkFunction = function() return TidyPlates end
        },
        conflicts = { "Plater", "KuiNameplates" }
    },
    
    -- Action Bar Addons
    ["Bartender4"] = {
        category = "UTILITY",
        positioning = POSITION_TEMPLATES.action_bars,
        frames = function()
            local frames = {}
            if Bartender4 then
                for i = 1, 10 do
                    local bar = Bartender4:GetModule("ActionBars"):GetActionBar(i)
                    if bar and bar.frame then
                        table.insert(frames, bar.frame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if Bartender4 then
                    for i = 1, 10 do
                        local bar = _G["BT4Bar" .. i]
                        if bar then
                            table.insert(frames, bar)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinBartender4Frames",
            loadDelay = 1,
            checkFunction = function() return Bartender4 end
        },
        conflicts = { "Dominos", "ElvUI" },
        configuration = {
            alignWithDamiaUI = true,
            hideInCombat = false
        }
    },
    
    ["Dominos"] = {
        category = "UTILITY",
        positioning = POSITION_TEMPLATES.action_bars,
        frames = function()
            local frames = {}
            if Dominos then
                for i = 1, 14 do
                    local bar = Dominos:GetModule("ActionBar" .. i)
                    if bar and bar.frame then
                        table.insert(frames, bar.frame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if Dominos then
                    for i = 1, 14 do
                        local bar = _G["DominosActionBar" .. i]
                        if bar then
                            table.insert(frames, bar)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinDominosFrames",
            loadDelay = 1,
            checkFunction = function() return Dominos end
        },
        conflicts = { "Bartender4", "ElvUI" }
    },
    
    -- UI Replacement Suites
    ["ElvUI"] = {
        category = "CRITICAL_UI",
        positioning = {
            targetZone = "fullscreen",
            integrated = true,
            compatibilityMode = true
        },
        frames = function()
            local frames = {}
            if ElvUI then
                -- ElvUI has comprehensive frame management
                -- We need to integrate rather than replace
                local E = unpack(ElvUI)
                if E and E.private and E.private.general and E.private.general.installed then
                    -- ElvUI is installed, use compatibility mode
                    return {}
                end
            end
            return frames
        end,
        specialIntegration = true,
        compatibility = {
            disableDamiaUIFrames = { "ActionBars", "UnitFrames" },
            enableIntegration = true
        },
        configuration = {
            compatibilityMode = true,
            respectElvUILayout = true
        }
    },
    
    ["TukUI"] = {
        category = "CRITICAL_UI",
        positioning = {
            integrated = true,
            compatibilityMode = true
        },
        specialIntegration = true,
        compatibility = {
            disableDamiaUIFrames = { "ActionBars", "UnitFrames" },
            enableIntegration = true
        }
    },
    
    -- Chat Enhancement
    ["Prat"] = {
        category = "ENHANCEMENT",
        positioning = POSITION_TEMPLATES.chat,
        frames = function()
            local frames = {}
            for i = 1, NUM_CHAT_WINDOWS or 10 do
                local frame = _G["ChatFrame" .. i]
                if frame and frame.PratHistory then
                    table.insert(frames, frame)
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                for i = 1, NUM_CHAT_WINDOWS or 10 do
                    local frame = _G["ChatFrame" .. i]
                    if frame and frame.PratHistory then
                        table.insert(frames, frame)
                    end
                end
                return frames
            end,
            skinFunction = "SkinPratFrames",
            loadDelay = 1,
            checkFunction = function() return Prat end
        },
        configuration = {
            integrateWithDamiaChat = true
        }
    },
    
    ["WIM"] = {
        category = "ENHANCEMENT",
        positioning = POSITION_TEMPLATES.utility,
        frames = function()
            local frames = {}
            if WIM_Windows then
                for _, window in pairs(WIM_Windows) do
                    if window.frame then
                        table.insert(frames, window.frame)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if WIM_Windows then
                    for _, window in pairs(WIM_Windows) do
                        if window.frame then
                            table.insert(frames, window.frame)
                        end
                    end
                end
                return frames
            end,
            skinFunction = "SkinWIMFrames",
            loadDelay = 1,
            checkFunction = function() return WIM end
        }
    },
    
    -- Economic/Trading Addons
    ["TradeSkillMaster"] = {
        category = "ECONOMIC",
        positioning = POSITION_TEMPLATES.utility,
        frames = function()
            local frames = {}
            if TSM_API then
                local mainFrame = TSM_API.GetMainFrame and TSM_API.GetMainFrame()
                if mainFrame then
                    table.insert(frames, mainFrame)
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                if TSM_API and TSM_API.GetMainFrame then
                    local mainFrame = TSM_API.GetMainFrame()
                    if mainFrame then
                        table.insert(frames, mainFrame)
                    end
                end
                return frames
            end,
            skinFunction = "SkinTSMFrames",
            loadDelay = 2,
            checkFunction = function() return TSM_API end
        },
        configuration = {
            minimizeInCombat = true,
            autoHide = false
        }
    },
    
    ["Auctionator"] = {
        category = "ECONOMIC",
        positioning = POSITION_TEMPLATES.utility,
        frames = { "AuctionatorFrame", "AuctionatorConfigFrame" },
        skinningData = {
            frames = { "AuctionatorFrame", "AuctionatorConfigFrame" },
            skinFunction = "SkinAuctionatorFrames",
            loadDelay = 1,
            checkFunction = function() return Auctionator end
        }
    },
    
    -- Healing Addons
    ["VuhDo"] = {
        category = "RAID_COMBAT",
        positioning = {
            targetZone = "leftSide",
            offsetX = 100, offsetY = 0,
            anchor = "LEFT",
            scale = 0.95,
            alpha = 0.9
        },
        frames = function()
            local frames = {}
            if VuhDo then
                for i = 1, 10 do
                    local panel = _G["VuhDoPanel" .. i]
                    if panel then
                        table.insert(frames, panel)
                    end
                end
            end
            return frames
        end,
        skinningData = {
            frames = function()
                local frames = {}
                for i = 1, 10 do
                    local panel = _G["VuhDoPanel" .. i]
                    if panel then
                        table.insert(frames, panel)
                    end
                end
                return frames
            end,
            skinFunction = "SkinVuhDoFrames",
            loadDelay = 2,
            checkFunction = function() return VuhDo end
        },
        configuration = {
            integrateWithUnitFrames = false,
            respectRaidLayout = true
        }
    },
    
    ["Grid2"] = {
        category = "RAID_COMBAT",
        positioning = {
            targetZone = "leftSide",
            offsetX = 80, offsetY = 0,
            anchor = "LEFT",
            scale = 1.0,
            alpha = 0.95
        },
        frames = function()
            local frames = {}
            if Grid2 then
                -- Grid2 uses a complex frame structure
                if Grid2Layout and Grid2Layout.db and Grid2Layout.db.profile then
                    local layout = Grid2Layout.db.profile
                    for _, config in pairs(layout) do
                        if config.frameAnchor then
                            local frame = _G[config.frameAnchor]
                            if frame then
                                table.insert(frames, frame)
                            end
                        end
                    end
                end
            end
            return frames
        end,
        specialIntegration = true,
        conflicts = { "VuhDo", "Healbot" }
    },
    
    -- Miscellaneous Popular Addons
    ["AllTheThings"] = {
        category = "UTILITY",
        positioning = POSITION_TEMPLATES.utility,
        frames = { "AllTheThingsMainFrame", "AllTheThingsSettingsFrame" },
        skinningData = {
            frames = { "AllTheThingsMainFrame", "AllTheThingsSettingsFrame" },
            skinFunction = "SkinAllTheThingsFrames",
            loadDelay = 1,
            checkFunction = function() return AllTheThings end
        }
    },
    
    ["AtlasLoot"] = {
        category = "UTILITY",
        positioning = POSITION_TEMPLATES.utility,
        frames = { "AtlasLootDefaultFrame", "AtlasLootItemsFrame" },
        skinningData = {
            frames = { "AtlasLootDefaultFrame", "AtlasLootItemsFrame" },
            skinFunction = "SkinAtlasLootFrames",
            loadDelay = 1,
            checkFunction = function() return AtlasLoot end
        }
    }
}

--[[
    Core Profile Management
]]

function AddonProfiles:Initialize(viewportConfiguration, addonCategories)
    DamiaUI:LogDebug("AddonProfiles: Initializing profile system")
    
    -- Store configuration references
    viewportConfig = viewportConfiguration or {}
    categories = addonCategories or {}
    
    -- Initialize profiles
    profiles = ADDON_PROFILES
    
    -- Setup conflict resolution
    self:InitializeConflictResolution()
    
    -- Validate profiles
    local validProfiles = self:ValidateProfiles()
    
    DamiaUI:LogInfo(string.format("AddonProfiles: Initialized with %d valid profiles", validProfiles))
    return true
end

function AddonProfiles:InitializeConflictResolution()
    -- Build conflict resolution matrix
    for addonName, profile in pairs(profiles) do
        if profile.conflicts then
            for _, conflictingAddon in ipairs(profile.conflicts) do
                if not conflictResolutions[conflictingAddon] then
                    conflictResolutions[conflictingAddon] = {}
                end
                table.insert(conflictResolutions[conflictingAddon], addonName)
            end
        end
    end
    
    DamiaUI:LogDebug("AddonProfiles: Conflict resolution matrix initialized")
end

function AddonProfiles:ValidateProfiles()
    local validCount = 0
    local invalidProfiles = {}
    
    for addonName, profile in pairs(profiles) do
        if self:ValidateProfile(addonName, profile) then
            validCount = validCount + 1
        else
            table.insert(invalidProfiles, addonName)
        end
    end
    
    if #invalidProfiles > 0 then
        DamiaUI:LogWarning("AddonProfiles: Invalid profiles found: " .. table.concat(invalidProfiles, ", "))
    end
    
    return validCount
end

function AddonProfiles:ValidateProfile(addonName, profile)
    -- Basic structure validation
    if not profile.category then
        DamiaUI:LogWarning("AddonProfiles: Profile missing category: " .. addonName)
        return false
    end
    
    if not profile.positioning and not profile.specialIntegration then
        DamiaUI:LogWarning("AddonProfiles: Profile missing positioning or specialIntegration: " .. addonName)
        return false
    end
    
    -- Validate positioning structure
    if profile.positioning then
        local pos = profile.positioning
        if not pos.targetZone and not pos.integrated then
            DamiaUI:LogWarning("AddonProfiles: Profile positioning missing targetZone: " .. addonName)
            return false
        end
        
        if pos.targetZone and not viewportConfig.zones[pos.targetZone] then
            DamiaUI:LogWarning("AddonProfiles: Profile references unknown zone: " .. addonName .. " -> " .. pos.targetZone)
            return false
        end
    end
    
    return true
end

--[[
    Profile Access and Management
]]

function AddonProfiles:GetProfile(addonName)
    local profile = profiles[addonName]
    if not profile then
        return nil
    end
    
    -- Check for conflicts
    if self:HasActiveConflicts(addonName) then
        DamiaUI:LogDebug("AddonProfiles: Skipping profile due to conflicts: " .. addonName)
        return nil
    end
    
    -- Add category information
    if profile.category and categories[profile.category] then
        profile.category = categories[profile.category]
    end
    
    return profile
end

function AddonProfiles:HasProfile(addonName)
    return profiles[addonName] ~= nil
end

function AddonProfiles:GetAllProfiles()
    local validProfiles = {}
    
    for addonName, profile in pairs(profiles) do
        if not self:HasActiveConflicts(addonName) then
            -- Add category information
            if profile.category and categories[profile.category] then
                profile.category = categories[profile.category]
            end
            validProfiles[addonName] = profile
        end
    end
    
    return validProfiles
end

function AddonProfiles:HasActiveConflicts(addonName)
    local profile = profiles[addonName]
    if not profile or not profile.conflicts then
        return false
    end
    
    -- Check if any conflicting addons are loaded and active
    for _, conflictingAddon in ipairs(profile.conflicts) do
        if IsAddOnLoaded(conflictingAddon) then
            -- Additional check - is the conflicting addon actually active?
            if self:IsAddonActive(conflictingAddon) then
                return true
            end
        end
    end
    
    return false
end

function AddonProfiles:IsAddonActive(addonName)
    -- Basic activity checks for common addons
    if addonName == "Details" then
        return _detalhes and _detalhes:GetCurrentInstance()
    elseif addonName == "Recount" then
        return Recount and Recount.MainWindow and Recount.MainWindow:IsVisible()
    elseif addonName == "Skada" then
        return Skada and #Skada:GetWindows() > 0
    elseif addonName == "DBM-Core" then
        return DBM and DBM.Revision
    elseif addonName == "BigWigs" then
        return BigWigs and BigWigs.revision
    elseif addonName == "ElvUI" then
        local E = unpack(ElvUI or {})
        return E and E.private and E.private.general and E.private.general.installed
    elseif addonName == "Bartender4" then
        return Bartender4 and Bartender4.revision
    elseif addonName == "Dominos" then
        return Dominos and Dominos.version
    end
    
    -- Default: if loaded, assume active
    return IsAddOnLoaded(addonName)
end

--[[
    Dynamic Profile Generation
]]

function AddonProfiles:CreateDynamicProfile(addonName, detectedData)
    -- Generate a basic profile for unknown addons
    local profile = {
        category = detectedData.category or categories.ENHANCEMENT,
        positioning = {
            targetZone = "rightSide",
            offsetX = -50, 
            offsetY = 0,
            anchor = "RIGHT",
            scale = 0.9,
            alpha = 0.85
        },
        frames = detectedData.frameNames,
        skinningData = {
            frames = detectedData.frameNames,
            skinFunction = "ApplyGenericSkinning",
            loadDelay = 1.5,
            checkFunction = function() return IsAddOnLoaded(addonName) end
        },
        dynamicallyGenerated = true,
        confidence = detectedData.confidence or 0
    }
    
    -- Store temporarily (not persisted)
    profiles[addonName] = profile
    
    DamiaUI:LogDebug("AddonProfiles: Created dynamic profile for " .. addonName)
    return profile
end

--[[
    Positioning Utilities
]]

function AddonProfiles:GetOptimalPosition(addonName, preferredZone)
    local profile = self:GetProfile(addonName)
    if not profile then
        return nil
    end
    
    local positioning = profile.positioning
    if not positioning then
        return nil
    end
    
    -- Use preferred zone if specified and available
    if preferredZone and viewportConfig.zones[preferredZone] then
        local modifiedPositioning = {}
        for k, v in pairs(positioning) do
            modifiedPositioning[k] = v
        end
        modifiedPositioning.targetZone = preferredZone
        return modifiedPositioning
    end
    
    return positioning
end

function AddonProfiles:GetZoneOccupancy()
    local occupancy = {}
    
    -- Initialize zone counters
    for zoneName in pairs(viewportConfig.zones) do
        occupancy[zoneName] = 0
    end
    
    -- Count profiles assigned to each zone
    for addonName, profile in pairs(profiles) do
        if IsAddOnLoaded(addonName) and profile.positioning and profile.positioning.targetZone then
            local zone = profile.positioning.targetZone
            if occupancy[zone] then
                occupancy[zone] = occupancy[zone] + 1
            end
        end
    end
    
    return occupancy
end

function AddonProfiles:SuggestAlternativeZone(originalZone, addonCategory)
    local occupancy = self:GetZoneOccupancy()
    
    -- Zone preferences by addon category
    local categoryPreferences = {
        DPS_METERS = { "bottomRight", "rightSide", "bottomLeft" },
        RAID_COMBAT = { "topCenter", "gameplay", "leftSide" },
        UTILITY = { "rightSide", "leftSide", "bottomRight" },
        ENHANCEMENT = { "leftSide", "rightSide", "topCenter" },
        ECONOMIC = { "rightSide", "bottomRight", "utility" }
    }
    
    local preferences = categoryPreferences[addonCategory] or { "rightSide", "leftSide" }
    
    -- Find least occupied preferred zone
    local bestZone = originalZone
    local bestOccupancy = occupancy[originalZone] or 999
    
    for _, zoneName in ipairs(preferences) do
        local zoneOccupancy = occupancy[zoneName] or 0
        if zoneOccupancy < bestOccupancy and viewportConfig.zones[zoneName] then
            bestZone = zoneName
            bestOccupancy = zoneOccupancy
        end
    end
    
    return bestZone
end

--[[
    Profile Customization
]]

function AddonProfiles:CustomizeProfile(addonName, customization)
    local profile = profiles[addonName]
    if not profile then
        return false
    end
    
    -- Create customized copy
    local customProfile = {}
    for k, v in pairs(profile) do
        customProfile[k] = type(v) == "table" and self:DeepCopy(v) or v
    end
    
    -- Apply customizations
    if customization.positioning then
        for k, v in pairs(customization.positioning) do
            if customProfile.positioning then
                customProfile.positioning[k] = v
            end
        end
    end
    
    if customization.configuration then
        customProfile.configuration = customProfile.configuration or {}
        for k, v in pairs(customization.configuration) do
            customProfile.configuration[k] = v
        end
    end
    
    -- Store customized profile
    profiles[addonName] = customProfile
    
    DamiaUI:LogDebug("AddonProfiles: Customized profile for " .. addonName)
    return true
end

--[[
    Utility Functions
]]

function AddonProfiles:DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = type(v) == "table" and self:DeepCopy(v) or v
    end
    return copy
end

function AddonProfiles:GetSupportedAddonCount()
    local count = 0
    for _ in pairs(profiles) do
        count = count + 1
    end
    return count
end

function AddonProfiles:GetLoadedSupportedAddons()
    local loadedAddons = {}
    for addonName in pairs(profiles) do
        if IsAddOnLoaded(addonName) then
            table.insert(loadedAddons, addonName)
        end
    end
    return loadedAddons
end

--[[
    Debug and Information Functions
]]

function AddonProfiles:GetProfileInfo(addonName)
    local profile = profiles[addonName]
    if not profile then
        return nil
    end
    
    return {
        addonName = addonName,
        category = profile.category,
        hasPositioning = profile.positioning ~= nil,
        hasSpecialIntegration = profile.specialIntegration == true,
        hasConflicts = profile.conflicts ~= nil and #profile.conflicts > 0,
        conflicts = profile.conflicts,
        targetZone = profile.positioning and profile.positioning.targetZone,
        isLoaded = IsAddOnLoaded(addonName),
        isActive = self:IsAddonActive(addonName),
        hasActiveConflicts = self:HasActiveConflicts(addonName)
    }
end

function AddonProfiles:PrintProfileSummary()
    DamiaUI:LogInfo("=== AddonProfiles Summary ===")
    
    local totalProfiles = 0
    local loadedProfiles = 0
    local activeProfiles = 0
    local conflictedProfiles = 0
    
    for addonName, profile in pairs(profiles) do
        totalProfiles = totalProfiles + 1
        
        if IsAddOnLoaded(addonName) then
            loadedProfiles = loadedProfiles + 1
            
            if self:IsAddonActive(addonName) then
                activeProfiles = activeProfiles + 1
            end
            
            if self:HasActiveConflicts(addonName) then
                conflictedProfiles = conflictedProfiles + 1
            end
        end
    end
    
    DamiaUI:LogInfo(string.format("Total Profiles: %d", totalProfiles))
    DamiaUI:LogInfo(string.format("Loaded Addons: %d", loadedProfiles))
    DamiaUI:LogInfo(string.format("Active Addons: %d", activeProfiles))
    DamiaUI:LogInfo(string.format("Conflicted Addons: %d", conflictedProfiles))
    
    -- Zone occupancy
    local occupancy = self:GetZoneOccupancy()
    DamiaUI:LogInfo("Zone Occupancy:")
    for zoneName, count in pairs(occupancy) do
        if count > 0 then
            DamiaUI:LogInfo(string.format("  %s: %d addons", zoneName, count))
        end
    end
end

return AddonProfiles