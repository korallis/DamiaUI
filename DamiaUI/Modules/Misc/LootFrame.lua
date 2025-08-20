--------------------------------------------------------------------
-- DamiaUI Misc - Loot Frame Restyling
-- Based on ColdUI by Coldkil, adapted for DamiaUI and WoW 11.2
--------------------------------------------------------------------

local addonName, ns = ...

local LootFrame = {}

-- Module registration
ns:RegisterModule("LootFrame", LootFrame)

function LootFrame:Initialize()
    self:SetupLootFrame()
end

function LootFrame:SetupLootFrame()
    local tex = ns.media.texture
    local font = ns.media.font
    local fs = 10

    -- Our personal movable anchor
    local lootanchor = CreateFrame("Frame", "DamiaUI_Loot", LootFrame)
    lootanchor:SetSize(155, 120)
    lootanchor:SetPoint("LEFT", UIParent, "CENTER", 20, 0)

    local CreateBG = function(frame)
        local f = frame
        if frame:GetObjectType() == "Texture" then 
            f = frame:GetParent() 
        end

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", frame, -1, 1)
        bg:SetPoint("BOTTOMRIGHT", frame, 1, -1)
        bg:SetTexture(tex)
        bg:SetVertexColor(0, 0, 0)

        return bg
    end

    local CreateBD = function(f)
        f:SetBackdrop({
            bgFile = tex,
            edgeFile = tex,
            edgeSize = 1,
        })
        f:SetBackdropColor(.2, .2, .2, .6)
        f:SetBackdropBorderColor(0, 0, 0)
    end

    local function deleteoldlootframe(f, isButtonFrame)
        local name = f:GetName()
        if not name then return end

        -- Hide old frame elements safely
        local elements = {
            "Bg", "TitleBg", "Portrait", "PortraitFrame", "TopRightCorner", 
            "TopLeftCorner", "TopBorder", "TopTileStreaks", "BotLeftCorner", 
            "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder", "CloseButton"
        }
        
        for _, element in ipairs(elements) do
            local obj = _G[name..element]
            if obj then
                if element == "TopTileStreaks" then
                    obj:SetTexture("")
                else
                    obj:Hide()
                end
            end
        end

        if isButtonFrame then
            local buttonElements = {"BtnCornerLeft", "BtnCornerRight", "ButtonBottomBorder"}
            for _, element in ipairs(buttonElements) do
                local obj = _G[name..element]
                if obj then
                    obj:SetTexture("")
                end
            end

            if f.Inset then
                if f.Inset.Bg then
                    f.Inset.Bg:Hide()
                end
                f.Inset:DisableDrawLayer("BORDER")
            end
        end
    end

    -- Hide portrait overlay
    if LootFramePortraitOverlay then
        LootFramePortraitOverlay:Hide()
    end
    
    -- Hide additional frame elements
    local region19 = select(19, LootFrame:GetRegions())
    if region19 then
        region19:Hide()
    end

    -- Hook LootFrame_UpdateButton for styling
    hooksecurefunc("LootFrame_UpdateButton", function(index)
        local ic = _G["LootButton"..index.."IconTexture"]
        local te = _G["LootButton"..index.."Text"]
        local co = _G["LootButton"..index.."Count"]

        if not ic or ic.bg then return end
        
        local bu = _G["LootButton"..index]
        local pre = _G["LootButton"..index-1]

        -- Hide quest texture and name frame
        local questTexture = _G["LootButton"..index.."IconQuestTexture"]
        local nameFrame = _G["LootButton"..index.."NameFrame"]
        
        if questTexture then
            questTexture:SetAlpha(0)
        end
        if nameFrame then
            nameFrame:Hide()
        end

        -- Style the button
        bu:SetNormalTexture("")
        bu:SetPushedTexture("")
        
        bu:SetSize(26, 26)
        bu:ClearAllPoints()
        bu:SetParent(lootanchor)
        
        if index == 1 then
            bu:SetPoint("TOPLEFT")
        else	
            bu:SetPoint("TOP", pre, "BOTTOM", 0, -3)
        end
        
        -- Create backdrop
        local bd = CreateFrame("Frame", nil, bu, "BackdropTemplate")
        bd:SetPoint("TOPLEFT", 26, 0)
        bd:SetPoint("BOTTOMRIGHT", 130, 0)
        bd:SetFrameLevel(bu:GetFrameLevel()-1)
        CreateBD(bd)

        -- Style icon
        ic:SetTexCoord(.08, .92, .08, .92)
        ic.bg = CreateBG(ic)
        
        -- Reposition text
        te:ClearAllPoints()
        te:SetPoint("TOPLEFT", bd, "TOPLEFT", 3, -2)
        te:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -2, 2)
                
        -- Reposition count
        co:ClearAllPoints()
        co:SetPoint("BOTTOMRIGHT", 2, 0)
        co:SetTextColor(0, 1, 0)
        
        -- Set icon border color based on item quality
        local icon, _, _, quality, _, isQuestItem = GetLootSlotInfo(index)
        if isQuestItem then
            ic.bg:SetVertexColor(1, 0, 0)
        elseif icon then
            local color = ITEM_QUALITY_COLORS[quality]
            if color then
                ic.bg:SetVertexColor(color.r, color.g, color.b)
            else
                ic.bg:SetVertexColor(0, 0, 0)
            end
        else
            ic.bg:SetVertexColor(0, 0, 0)
        end
    end)

    -- Reposition navigation buttons
    if LootFrameDownButton then
        LootFrameDownButton:ClearAllPoints()
        LootFrameDownButton:SetPoint("BOTTOMRIGHT", lootanchor, "BOTTOMRIGHT", -4, 4)
    end
    
    if LootFrameUpButton then
        LootFrameUpButton:ClearAllPoints()
        LootFrameUpButton:SetPoint("BOTTOMLEFT", lootanchor, "BOTTOMLEFT", -4, 4)
    end
    
    if LootFramePrev then
        LootFramePrev:ClearAllPoints()
        LootFramePrev:SetPoint("LEFT", LootFrameUpButton, "RIGHT", 4, 0)
    end
    
    if LootFrameNext then
        LootFrameNext:ClearAllPoints()
        LootFrameNext:SetPoint("RIGHT", LootFrameDownButton, "LEFT", -4, 0)
    end

    -- Remove old Blizzard frame styling
    deleteoldlootframe(LootFrame, true)
    
    self.lootanchor = lootanchor
end

return LootFrame