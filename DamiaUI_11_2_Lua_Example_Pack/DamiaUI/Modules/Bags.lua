\
    local ADDON, NS = ...

    local function ForEachSlot(fn)
        for bag = 0, NUM_BAG_SLOTS do
            local slots = C_Container.GetContainerNumSlots(bag)
            if slots and slots > 0 then
                for slot = 1, slots do
                    fn(bag, slot)
                end
            end
        end
    end

    local function DebugBags()
        ForEachSlot(function(bag, slot)
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local count = info.stackCount or 1
                local link = C_Container.GetContainerItemLink(bag, slot)
                -- Example debug output (commented to avoid chat spam)
                -- print(string.format("Bag %d Slot %d: %s x%d", bag, slot, link or "nil", count))
            end
        end)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:SetScript("OnEvent", function()
        -- Hook your actual bag UI refresh here
        DebugBags()
    end)
