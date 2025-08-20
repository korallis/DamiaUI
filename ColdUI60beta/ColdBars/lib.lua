--get the addon namespace
local addon, ns = ...

-- frame holder for the functions
local B = CreateFrame("Frame")

local backdrop = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
}

B.setstate = function(f, v)
      local t = ColdBars
      for w, d in string.gmatch(f, "([%w_]+)(.?)") do
        if d == "." then      -- not last field?
          t[w] = t[w] or {}   -- create table if absent
          t = t[w]            -- get the table
        else                  -- last field
          t[w] = v            -- do the assignment
        end
      end
    end
	
B.checkstate = function(f)
	  if not ColdBars then return end
      local v = ColdBars
      for w in string.gmatch(f, "[%w_]+") do
        v = v[w]
      end
      return v
end

B.makedrag = function (f)
	local fn = f:GetName()
	f:SetScript("OnDragStart", function(s) s:StartMoving() end)
    f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
	f:SetMovable(true)
	f:SetUserPlaced(true)
	
	local d = CreateFrame("Frame", nil, UIParent)
	d:SetBackdrop(backdrop)
	d:SetBackdropColor(0,1,0,.5)
	d:SetAllPoints(f)
	d:SetFrameLevel(f:GetFrameLevel()+5)
	d:SetFrameStrata"HIGH"
	d:SetAlpha(0)  
	f.handle = d
	
	local n = d:CreateFontString(nil, "OVERLAY")
	n:SetFont("Interface\\AddOns\\oUF_Coldkil\\fonts\\homespun.ttf", 10, "OUTLINE, MONOCHROME")
	n:SetText(fn)
	n:SetPoint("CENTER", d, "CENTER")
	n:SetJustifyH"CENTER"
	
	local btn = CreateFrame("Frame", fn.."btn", d)
	btn:SetBackdrop(backdrop)
	btn:SetBackdropColor(1,0,0)
	btn:SetBackdropBorderColor(0,0,0)
	btn:SetSize(10,10)
	btn:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -2, 2)
	btn:Hide()
	f.btn = btn
	
	btn:SetScript("OnMouseUp", function(self, b)
	 if f:IsShown() then
		B.setstate(fn, false)
	    f:Hide()
	  else
		B.setstate(fn, true)
        f:Show()      
	  end
	end)
end

-- handover to use the functions in other files
ns.B = B