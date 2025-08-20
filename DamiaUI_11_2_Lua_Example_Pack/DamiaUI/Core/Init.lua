\
    local ADDON, NS = ...
    NS.DAMIA_NAME = "DamiaUI"

    -- Basic SavedVariables bootstrap (AceDB if present)
    local function initDB()
        if LibStub and LibStub("AceDB-3.0", true) then
            NS.db = LibStub("AceDB-3.0"):New("DamiaUI_DB", { profile = {} }, true)
        else
            DamiaUI_DB = DamiaUI_DB or { profile = {} }
            NS.db = DamiaUI_DB
        end
    end

    local function createOptionsPanel()
        local cfg = CreateFrame("Frame", "DamiaUIOptions", UIParent, "BackdropTemplate")
        cfg.name = NS.DAMIA_NAME

        local title = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(NS.DAMIA_NAME .. " Configuration")

        local v = cfg:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        v:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        v:SetText("Retail 11.2 compatible • /damia to open")

        -- Register with Settings API
        local category, layout = Settings.RegisterCanvasLayoutCategory(cfg, NS.DAMIA_NAME)
        Settings.RegisterAddOnCategory(category)
        NS.CATEGORY_ID = category:GetID()
    end

    local function openOptions()
        if NS.CATEGORY_ID then
            Settings.OpenToCategory(NS.CATEGORY_ID)
        else
            -- Fallback (older clients); should not be needed in Retail 11.x
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory(NS.DAMIA_NAME)
            end
        end
    end

    local function registerSlash()
        SLASH_DAMIA1 = "/damia"
        SLASH_DAMIA2 = "/damiaui"
        SlashCmdList.DAMIA = function(msg)
            msg = strtrim(msg or "")
            if msg == "" or msg == "config" then
                openOptions()
            elseif msg == "reset" then
                if NS.db and NS.db.profile then
                    wipe(NS.db.profile)
                    print("|cffff7f00DamiaUI:|r Profile reset.")
                end
            else
                print("|cffff7f00DamiaUI commands:|r /damia, /damia config, /damia reset")
            end
        end
    end

    local function OnEvent(self, event, ...)
        if event == "ADDON_LOADED" then
            local name = ...
            if name == ADDON then
                initDB()
                createOptionsPanel()
            end
        elseif event == "PLAYER_LOGIN" then
            -- Init modules that require the world to be loaded
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", OnEvent)

    registerSlash()
