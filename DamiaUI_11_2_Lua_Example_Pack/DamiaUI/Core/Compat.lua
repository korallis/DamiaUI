\
    local _G = _G

    DamiaUI_Compat = {}

    -- Backdrop helper: create a frame that supports SetBackdrop in modern clients
    function DamiaUI_Compat:CreateBackdropFrame(parent, name)
        local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
        if not f.SetBackdrop then
            -- Should not happen on Retail 11.x, but guard anyway
            f.SetBackdrop = _G.Frame.SetBackdrop
        end
        return f
    end

    -- Bag helpers (modernized): wrapper accessors for C_Container
    local CC = C_Container
    function DamiaUI_Compat:GetItemInfo(bag, slot)
        if CC and CC.GetContainerItemInfo then
            return CC.GetContainerItemInfo(bag, slot)
        end
        -- Legacy fallback (unlikely in retail 11.x)
        local texture, itemCount, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        return { iconFileID = texture, stackCount = itemCount, isLocked = locked, quality = quality }, link
    end
