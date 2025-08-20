--------------------------------------------------------------------
-- DamiaUI Misc - Error Handler
-- Basic error handling system for DamiaUI
--------------------------------------------------------------------

local addonName, ns = ...

local ErrorHandler = {}

-- Module registration
ns:RegisterModule("ErrorHandler", ErrorHandler)

function ErrorHandler:Initialize()
    if not ns:GetConfig("misc", "hideErrors") then
        return
    end
    
    self:SetupErrorHandling()
end

function ErrorHandler:SetupErrorHandling()
    -- Hide error frame when configured
    if UIErrorsFrame then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    end
    
    -- Custom error message filtering
    local originalAddMessage = UIErrorsFrame.AddMessage
    UIErrorsFrame.AddMessage = function(self, text, r, g, b, a, id)
        -- Filter out specific annoying errors
        local filteredMessages = {
            ["Target needs to be in front of you"] = true,
            ["Spell is not ready yet"] = true,
            ["You are too far away"] = true,
            ["Invalid target"] = true,
            ["Out of range"] = true,
            ["Not enough mana"] = true,
            ["Not enough energy"] = true,
            ["Not enough rage"] = true,
            ["Ability is not ready yet"] = true,
        }
        
        if not filteredMessages[text] then
            originalAddMessage(self, text, r, g, b, a, id)
        end
    end
    
    -- Setup seterrorhandler for addon errors
    seterrorhandler(function(err)
        -- Only handle DamiaUI errors
        if string.find(err, addonName) then
            ns:Print("Error:", err)
            return true
        end
        return false
    end)
end

return ErrorHandler