local _, DamiaUI = ...

-- API Safety Wrappers and Verified Functions
-- Based on WoW 11.2 API state

-- =============================================================================
-- THEME (Aesthetics shared across modules)
-- =============================================================================

DamiaUI.Theme = DamiaUI.Theme or {
    -- Gold bar color used throughout screenshots
    gold = {0.82, 0.68, 0.22},
    -- Panel background and borders
    panelBg = {0, 0, 0, 0.80},
    border = {0.25, 0.25, 0.25, 1},
    text = {1, 1, 1, 1},
}

-- Create a simple 1px border panel matching the screenshots
function DamiaUI:CreateBorderedPanel(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetBackdrop({ edgeFile = self.DefaultTextures.white or "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropBorderColor(unpack(self.Theme.border))
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(self.Theme.panelBg))
    frame.bg = bg
    return frame
end

-- =============================================================================
-- FRAME CREATION WITH BACKDROP SUPPORT
-- =============================================================================

-- Safe backdrop creation for 11.2+
function DamiaUI:CreateBackdropFrame(name, parent, template, backdrop)
    local frame
    
    -- Use BackdropTemplate for frames that need SetBackdrop
    if backdrop then
        frame = CreateFrame("Frame", name, parent, template and (template .. ", BackdropTemplate") or "BackdropTemplate")
        
        -- Set backdrop if provided
        if frame.SetBackdrop then
            frame:SetBackdrop(backdrop)
        else
            DamiaUI:Debug("Warning: Frame doesn't support SetBackdrop despite BackdropTemplate")
        end
    else
        frame = CreateFrame("Frame", name, parent, template)
    end
    
    return frame
end

-- Safe status bar creation
function DamiaUI:CreateStatusBar(name, parent, template)
    local bar = CreateFrame("StatusBar", name, parent, template)
    
    -- Set default texture that always exists
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    return bar
end

-- =============================================================================
-- UNIT FRAME API WRAPPERS
-- =============================================================================

-- Safe unit information getters
function DamiaUI:GetUnitInfo(unit)
    if not UnitExists(unit) then
        return nil
    end
    
    local info = {
        name = UnitName(unit),
        level = UnitLevel(unit),
        health = UnitHealth(unit),
        maxHealth = UnitHealthMax(unit),
        power = UnitPower(unit),
        maxPower = UnitPowerMax(unit),
        powerType = UnitPowerType(unit),
        class = select(2, UnitClass(unit)),
        race = select(2, UnitRace(unit)),
        isPlayer = UnitIsPlayer(unit),
        isConnected = UnitIsConnected(unit),
        isDead = UnitIsDead(unit),
        isGhost = UnitIsGhost(unit),
    }
    
    -- Reaction for NPCs
    if not info.isPlayer then
        info.reaction = UnitReaction(unit, "player")
    end
    
    return info
end

-- Safe color retrieval
function DamiaUI:GetUnitColor(unit)
    if not UnitExists(unit) then
        return 0.5, 0.5, 0.5
    end
    
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b
        end
    else
        local reaction = UnitReaction(unit, "player")
        if reaction then
            if reaction <= 3 then
                return 1, 0.2, 0.2  -- Hostile
            elseif reaction == 4 then
                return 1, 1, 0      -- Neutral
            else
                return 0.2, 1, 0.2  -- Friendly
            end
        end
    end
    
    return 0.5, 0.5, 0.5  -- Default gray
end

-- Power type colors
DamiaUI.PowerColors = {
    [0] = {0.2, 0.2, 1},    -- Mana (blue)
    [1] = {1, 0.2, 0.2},    -- Rage (red)
    [2] = {1, 0.5, 0.25},   -- Focus (orange)
    [3] = {1, 1, 0},        -- Energy (yellow)
    [4] = {0, 1, 1},        -- Happiness (cyan) - deprecated but kept for safety
    [5] = {1, 0, 1},        -- Runes (magenta) - not used directly
    [6] = {0, 0.82, 1},     -- Runic Power (cyan)
    [7] = {0.5, 0.5, 1},    -- Soul Shards (purple)
    [8] = {0.5, 1, 0.5},    -- Eclipse (green)
    [9] = {1, 0.5, 0},      -- Holy Power (orange)
    [11] = {0.7, 0.3, 0.7}, -- Maelstrom (purple)
    [12] = {0.8, 0.4, 0},   -- Chi (orange)
    [13] = {0.6, 0.2, 0.8}, -- Insanity (purple)
    [16] = {1, 1, 0.5},     -- Arcane Charges (yellow)
    [17] = {0.5, 1, 0.75},  -- Fury (green)
    [18] = {0.8, 0.4, 0.8}, -- Pain (pink)
    [19] = {0.5, 0.5, 0.5}, -- Essence (gray)
}

function DamiaUI:GetPowerColor(powerType)
    return self.PowerColors[powerType] or {0.5, 0.5, 0.5}
end

-- =============================================================================
-- ACTION BAR API WRAPPERS
-- =============================================================================

-- Safe action button creation
function DamiaUI:CreateActionButton(id, name, parent)
    -- Verify ActionBarButtonTemplate exists
    if not ActionBarButtonTemplate then
        DamiaUI:Debug("Warning: ActionBarButtonTemplate not available")
        return nil
    end
    
    local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")
    if not button then
        DamiaUI:Debug("Failed to create action button:", name)
        return nil
    end
    
    -- Set action ID
    button.action = id
    button:SetAttribute("action", id)
    button:SetAttribute("showgrid", 1)
    
    -- Update functions exist check
    if ActionButton_UpdateAction then
        ActionButton_UpdateAction(button)
    end
    if ActionButton_Update then
        ActionButton_Update(button)
    end
    
    return button
end

-- =============================================================================
-- EVENT REGISTRATION HELPERS
-- =============================================================================

-- Safe event registration with validation
function DamiaUI:RegisterFrameEvents(frame, events)
    if not frame or not events then
        DamiaUI:Debug("Invalid frame or events for registration")
        return false
    end
    
    for _, event in ipairs(events) do
        if type(event) == "string" then
            frame:RegisterEvent(event)
            DamiaUI:Debug("Registered event:", event, "for frame:", frame:GetName() or "unnamed")
        end
    end
    
    return true
end

-- =============================================================================
-- ADDON DETECTION
-- =============================================================================

-- Check if addon is loaded
function DamiaUI:IsAddonLoaded(addonName)
    return C_AddOns.IsAddOnLoaded(addonName)
end

-- Check if addon exists
function DamiaUI:DoesAddonExist(addonName)
    return select(4, C_AddOns.GetAddOnMetadata(addonName, "Title")) ~= nil
end

-- =============================================================================
-- TEXTURE AND MEDIA HELPERS
-- =============================================================================

-- Safe texture setting
function DamiaUI:SetTexture(textureObject, texturePath, fallback)
    if not textureObject then
        return false
    end
    
    local success = pcall(textureObject.SetTexture, textureObject, texturePath)
    if not success and fallback then
        pcall(textureObject.SetTexture, textureObject, fallback)
    end
    
    return success
end

-- Default textures that should always be available
DamiaUI.DefaultTextures = {
    statusBar = "Interface\\TargetingFrame\\UI-StatusBar",
    white = "Interface\\Buttons\\WHITE8x8",
    backdrop = "Interface\\Tooltips\\UI-Tooltip-Background",
    border = "Interface\\Tooltips\\UI-Tooltip-Border",
}

-- =============================================================================
-- SPECIALIZATION AND ROLE DETECTION
-- =============================================================================

-- Safe specialization info
function DamiaUI:GetPlayerSpecInfo()
    local spec = GetSpecialization()
    if not spec then
        return nil
    end
    
    local specID, specName, description, icon, role = GetSpecializationInfo(spec)
    
    return {
        id = specID,
        name = specName,
        description = description,
        icon = icon,
        role = role
    }
end

-- Safe role detection with fallbacks
function DamiaUI:GetPlayerRole()
    -- Try assigned role first
    local assignedRole = UnitGroupRolesAssigned("player")
    if assignedRole and assignedRole ~= "NONE" then
        return assignedRole
    end
    
    -- Fall back to spec role
    local specInfo = self:GetPlayerSpecInfo()
    if specInfo then
        return specInfo.role
    end
    
    return "NONE"
end

-- =============================================================================
-- FONT HELPERS
-- =============================================================================

-- Safe font setting with fallbacks
function DamiaUI:SetFont(fontString, fontPath, size, flags)
    if not fontString then
        return false
    end
    
    -- Try the requested font first
    local success = pcall(fontString.SetFont, fontString, fontPath, size or 12, flags or "OUTLINE")
    
    -- Fallback to default font if needed
    if not success then
        success = pcall(fontString.SetFont, fontString, "Fonts\\FRIZQT__.TTF", size or 12, flags or "OUTLINE")
    end
    
    return success
end

-- Default fonts
DamiaUI.DefaultFonts = {
    normal = "Fonts\\FRIZQT__.TTF",
    number = "Fonts\\ARIALN.TTF",
    chat = "Fonts\\ARIALN.TTF",
}

-- =============================================================================
-- INITIALIZATION AND CLEANUP
-- =============================================================================

function DamiaUI:CleanupFrame(frame)
    if not frame then return end
    
    -- Unregister all events
    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    
    -- Hide frame
    frame:Hide()
    
    -- Clear scripts
    frame:SetScript("OnEvent", nil)
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
end

DamiaUI:Print("API wrappers loaded with safety checks")