local addonName, DamiaUI = ...

-- Settings manager and interface
DamiaUI.Settings = {}
local Settings = DamiaUI.Settings

-- Local references
local db, charDB, globalDB
local settingsFrame
local categoryPanels = {}

-- Initialize settings system
function Settings:Initialize()
    -- Initialize SavedVariables
    if not DamiaUIDB then
        DamiaUIDB = DamiaUI:GetGlobalDefaults()
    end
    
    if not DamiaUICharacterDB then
        DamiaUICharacterDB = DamiaUI:DeepCopy(DamiaUI.Defaults.char)
    end
    
    -- Set up database references
    globalDB = DamiaUIDB
    charDB = DamiaUICharacterDB
    
    -- Initialize currentProfile if it doesn't exist
    if not globalDB.currentProfile then
        globalDB.currentProfile = "Default"
    end
    
    -- Ensure current profile exists
    if not globalDB.profiles[globalDB.currentProfile] then
        globalDB.profiles[globalDB.currentProfile] = DamiaUI:GetDefaults().profile
    end
    
    db = globalDB.profiles[globalDB.currentProfile]
    
    -- Migration check
    DamiaUI.Migration:CheckMigration(db)
    DamiaUI.Migration:MigrateLegacyAddons()
    
    -- Initialize interface panel
    DamiaUI.InterfacePanel:Initialize()
    
    -- Register events
    self:RegisterEvents()
    
    DamiaUI.Debug("Settings system initialized")
end


-- Toggle module on/off
function Settings:ToggleModule(moduleName, enabled)
    DamiaUI.Debug("Toggling module", moduleName, "to", enabled and "enabled" or "disabled")
    
    if moduleName == "actionbars" and DamiaUI.ActionBars then
        if enabled then
            DamiaUI.ActionBars:Enable()
        else
            DamiaUI.ActionBars:Disable()
        end
    elseif moduleName == "unitframes" and DamiaUI.UnitFrames then
        if enabled then
            DamiaUI.UnitFrames:Enable()
        else
            DamiaUI.UnitFrames:Disable()
        end
    end
    
    -- Fire callback for other modules to respond
    DamiaUI.callbacks:Fire("MODULE_TOGGLED", moduleName, enabled)
end

-- Open Action Bar settings
function Settings:OpenActionBarSettings()
    -- TODO: Implement detailed action bar settings panel
    print("Action Bar settings panel coming in future update!")
end

-- Open Unit Frame settings  
function Settings:OpenUnitFrameSettings()
    -- TODO: Implement detailed unit frame settings panel
    print("Unit Frame settings panel coming in future update!")
end

-- Open Profile Manager
function Settings:OpenProfileManager()
    -- TODO: Implement profile management system
    print("Profile manager coming in future update!")
end

-- Register events
function Settings:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGOUT")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == addonName then
                Settings:OnAddonLoaded()
            end
        elseif event == "PLAYER_LOGOUT" then
            Settings:OnPlayerLogout()
        end
    end)
end

-- Handle addon loaded
function Settings:OnAddonLoaded()
    -- Any post-load initialization
    DamiaUI.Debug("Settings loaded for", UnitName("player"))
end

-- Handle player logout  
function Settings:OnPlayerLogout()
    -- Any cleanup before logout
    self:SaveSettings()
end

-- Save settings
function Settings:SaveSettings()
    -- Settings are automatically saved via SavedVariables
    DamiaUI.Debug("Settings saved")
end

-- Cancel settings changes
function Settings:CancelSettings()
    -- Reload from saved settings
    self:ReloadSettings()
    DamiaUI.Debug("Settings changes cancelled")
end

-- Reset to defaults
function Settings:ResetSettings()
    StaticPopup_Show("DAMIAUI_RESET_SETTINGS")
end

-- Reload settings from database
function Settings:ReloadSettings()
    db = globalDB.profiles[globalDB.currentProfile]
    
    -- Notify interface panel to refresh
    if DamiaUI.InterfacePanel then
        -- Interface panel handles its own refresh on show
    end
    
    DamiaUI.Debug("Settings reloaded")
end

-- Get current database references
function Settings:GetDB()
    return db, charDB, globalDB
end

-- Get setting value with fallback to default
function Settings:Get(path, default)
    local keys = {strsplit(".", path)}
    local current = db
    
    for i = 1, #keys do
        if current and current[keys[i]] ~= nil then
            current = current[keys[i]]
        else
            return default
        end
    end
    
    return current
end

-- Set setting value
function Settings:Set(path, value)
    local keys = {strsplit(".", path)}
    local current = db
    
    for i = 1, #keys - 1 do
        if not current[keys[i]] then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    current[keys[#keys]] = value
    
    -- Fire callback
    DamiaUI.callbacks:Fire("SETTING_CHANGED", path, value)
end

-- Static popup for reset confirmation
StaticPopupDialogs["DAMIAUI_RESET_SETTINGS"] = {
    text = "Are you sure you want to reset all DamiaUI settings to defaults? This cannot be undone.",
    button1 = "Yes",
    button2 = "No", 
    OnAccept = function()
        -- Reset to defaults
        local defaults = DamiaUI:GetDefaults().profile
        wipe(db)
        for k, v in pairs(defaults) do
            db[k] = DamiaUI:DeepCopy(v)
        end
        
        -- Reload interface
        Settings:ReloadSettings()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Slash commands for settings
SLASH_DAMIAUI_CONFIG1 = "/duiconfig"
SLASH_DAMIAUI_CONFIG2 = "/damiaconfig"
SlashCmdList["DAMIAUI_CONFIG"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "reset" then
        StaticPopup_Show("DAMIAUI_RESET_SETTINGS")
    elseif msg == "reload" then
        ReloadUI()
    else
        if DamiaUI.InterfacePanel then
            DamiaUI.InterfacePanel:Show()
        else
            DamiaUI:Print("Settings system not initialized yet")
        end
    end
end

-- Initialize settings when this file loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        Settings:Initialize()
        self:UnregisterAllEvents()
    end
end)