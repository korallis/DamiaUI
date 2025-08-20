\
    local function EachAura(unit, filter, handler)
        AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
            handler(auraData)
            return false -- continue
        end)
    end

    -- Example usage: count harmful auras on target whenever target changes
    local function CountTargetDebuffs()
        local n = 0
        EachAura("target", "HARMFUL", function(a) n = n + 1 end)
        -- print("Debuffs on target:", n)
        return n
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:SetScript("OnEvent", function() CountTargetDebuffs() end)
