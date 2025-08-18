# WoW Widget API Documentation

This document provides comprehensive documentation of the Widget API - methods available on UI objects (frames) in World of Warcraft.

## Table of Contents
1. [Frame Hierarchy](#frame-hierarchy)
2. [Common Widget Types](#common-widget-types)
3. [Base Frame Methods](#base-frame-methods)
4. [Position and Size](#position-and-size)
5. [Visibility and Display](#visibility-and-display)
6. [Event Handling](#event-handling)
7. [Script Handlers](#script-handlers)
8. [Texture and Font](#texture-and-font)
9. [Frame-Specific Methods](#frame-specific-methods)

---

## Frame Hierarchy

All UI widgets inherit from a base Frame type:

```
UIObject
  └── Region
        └── LayeredRegion
        │     ├── FontString
        │     └── Texture
        └── Frame
              ├── Button
              │     └── CheckButton
              ├── Cooldown
              ├── ColorSelect
              ├── EditBox
              ├── GameTooltip
              ├── MessageFrame
              ├── Minimap
              ├── Model
              ├── ScrollFrame
              ├── SimpleHTML
              ├── Slider
              └── StatusBar
```

---

## Common Widget Types

### Frame
The base widget type for all interactive UI elements.

### Button
A clickable frame that can have different states (normal, pushed, highlight, disabled).

### CheckButton
A checkbox or radio button widget.

### EditBox
A text input field.

### ScrollFrame
A frame that can display content larger than its visible area.

### Slider
A draggable slider for value selection.

### StatusBar
A bar that displays a value within a range (health bars, cast bars, etc.).

### GameTooltip
Special frame type for displaying tooltips.

---

## Base Frame Methods

### Creation and Setup

#### :SetParent(parent)
Sets the parent of the frame.
```lua
frame:SetParent(UIParent)
```

#### :GetParent()
Returns the frame's parent.
```lua
local parent = frame:GetParent()
```

#### :GetName()
Returns the frame's global name.
```lua
local name = frame:GetName()
```

#### :SetFrameStrata(strata)
Sets the frame's strata level.
```lua
frame:SetFrameStrata("HIGH")
-- Valid strata: "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"
```

#### :GetFrameStrata()
Returns the frame's strata.
```lua
local strata = frame:GetFrameStrata()
```

#### :SetFrameLevel(level)
Sets the frame's level within its strata.
```lua
frame:SetFrameLevel(5)
```

#### :GetFrameLevel()
Returns the frame's level.
```lua
local level = frame:GetFrameLevel()
```

#### :SetID(id)
Sets the frame's ID number.
```lua
frame:SetID(1)
```

#### :GetID()
Returns the frame's ID.
```lua
local id = frame:GetID()
```

---

## Position and Size

### Positioning

#### :SetPoint(point [, relativeTo] [, relativePoint] [, offsetX] [, offsetY])
Sets an anchor point for the frame.
```lua
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetPoint("TOPLEFT", 10, -10)
```

#### :GetPoint(index)
Returns information about an anchor point.
```lua
local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
```

#### :GetNumPoints()
Returns the number of anchor points.
```lua
local numPoints = frame:GetNumPoints()
```

#### :ClearAllPoints()
Removes all anchor points.
```lua
frame:ClearAllPoints()
```

### Sizing

#### :SetWidth(width)
Sets the frame's width.
```lua
frame:SetWidth(200)
```

#### :GetWidth()
Returns the frame's width.
```lua
local width = frame:GetWidth()
```

#### :SetHeight(height)
Sets the frame's height.
```lua
frame:SetHeight(100)
```

#### :GetHeight()
Returns the frame's height.
```lua
local height = frame:GetHeight()
```

#### :SetSize(width, height)
Sets both width and height.
```lua
frame:SetSize(200, 100)
```

#### :GetSize()
Returns width and height.
```lua
local width, height = frame:GetSize()
```

#### :SetScale(scale)
Sets the frame's scale.
```lua
frame:SetScale(1.5)
```

#### :GetScale()
Returns the frame's scale.
```lua
local scale = frame:GetScale()
```

#### :GetEffectiveScale()
Returns the frame's effective scale (including parent scaling).
```lua
local effectiveScale = frame:GetEffectiveScale()
```

### Bounds

#### :GetRect()
Returns the frame's rectangle coordinates.
```lua
local left, bottom, width, height = frame:GetRect()
```

#### :GetBoundsRect()
Returns the frame's bounding rectangle.
```lua
local left, bottom, width, height = frame:GetBoundsRect()
```

#### :GetCenter()
Returns the frame's center coordinates.
```lua
local x, y = frame:GetCenter()
```

#### :GetLeft()
Returns the left edge coordinate.
```lua
local left = frame:GetLeft()
```

#### :GetRight()
Returns the right edge coordinate.
```lua
local right = frame:GetRight()
```

#### :GetTop()
Returns the top edge coordinate.
```lua
local top = frame:GetTop()
```

#### :GetBottom()
Returns the bottom edge coordinate.
```lua
local bottom = frame:GetBottom()
```

---

## Visibility and Display

### Show/Hide

#### :Show()
Shows the frame.
```lua
frame:Show()
```

#### :Hide()
Hides the frame.
```lua
frame:Hide()
```

#### :IsShown()
Returns true if the frame is shown.
```lua
local isShown = frame:IsShown()
```

#### :IsVisible()
Returns true if the frame is visible (shown and all parents shown).
```lua
local isVisible = frame:IsVisible()
```

#### :SetShown(shown)
Shows or hides based on boolean.
```lua
frame:SetShown(true)
```

### Alpha

#### :SetAlpha(alpha)
Sets the frame's alpha (0-1).
```lua
frame:SetAlpha(0.5)
```

#### :GetAlpha()
Returns the frame's alpha.
```lua
local alpha = frame:GetAlpha()
```

#### :GetEffectiveAlpha()
Returns the effective alpha (including parent alpha).
```lua
local effectiveAlpha = frame:GetEffectiveAlpha()
```

---

## Event Handling

### Event Registration

#### :RegisterEvent(event)
Registers the frame for an event.
```lua
frame:RegisterEvent("PLAYER_LOGIN")
```

#### :UnregisterEvent(event)
Unregisters an event.
```lua
frame:UnregisterEvent("PLAYER_LOGIN")
```

#### :RegisterAllEvents()
Registers for all events (use sparingly).
```lua
frame:RegisterAllEvents()
```

#### :UnregisterAllEvents()
Unregisters all events.
```lua
frame:UnregisterAllEvents()
```

#### :IsEventRegistered(event)
Checks if an event is registered.
```lua
local isRegistered = frame:IsEventRegistered("PLAYER_LOGIN")
```

### Unit Events

#### :RegisterUnitEvent(event [, unit1, ...])
Registers for a unit event.
```lua
frame:RegisterUnitEvent("UNIT_HEALTH", "player", "target")
```

---

## Script Handlers

### Setting Scripts

#### :SetScript(handler, function)
Sets a script handler.
```lua
frame:SetScript("OnClick", function(self, button)
    print("Clicked with " .. button)
end)
```

#### :GetScript(handler)
Returns a script handler function.
```lua
local handler = frame:GetScript("OnClick")
```

#### :HookScript(handler, function)
Hooks a script handler (calls after existing).
```lua
frame:HookScript("OnShow", function(self)
    print("Frame shown")
end)
```

### Common Script Handlers

#### OnLoad
Called when the frame is created.
```lua
frame:SetScript("OnLoad", function(self)
    -- Initialize frame
end)
```

#### OnShow
Called when the frame is shown.
```lua
frame:SetScript("OnShow", function(self)
    -- Frame shown
end)
```

#### OnHide
Called when the frame is hidden.
```lua
frame:SetScript("OnHide", function(self)
    -- Frame hidden
end)
```

#### OnUpdate
Called every frame (use sparingly).
```lua
frame:SetScript("OnUpdate", function(self, elapsed)
    -- Update logic
end)
```

#### OnEvent
Called when a registered event fires.
```lua
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Handle login
    end
end)
```

### Mouse Handlers

#### OnEnter
Mouse enters the frame.
```lua
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Tooltip text")
    GameTooltip:Show()
end)
```

#### OnLeave
Mouse leaves the frame.
```lua
frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
```

#### OnMouseDown
Mouse button pressed.
```lua
frame:SetScript("OnMouseDown", function(self, button)
    -- Handle mouse down
end)
```

#### OnMouseUp
Mouse button released.
```lua
frame:SetScript("OnMouseUp", function(self, button)
    -- Handle mouse up
end)
```

#### OnClick
Frame clicked (Button widgets).
```lua
button:SetScript("OnClick", function(self, button, down)
    -- Handle click
end)
```

#### OnDoubleClick
Frame double-clicked.
```lua
frame:SetScript("OnDoubleClick", function(self, button)
    -- Handle double click
end)
```

### Drag Handlers

#### OnDragStart
Drag started.
```lua
frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
```

#### OnDragStop
Drag stopped.
```lua
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)
```

---

## Texture and Font

### Creating Textures

#### :CreateTexture([name] [, layer] [, inherits] [, sublevel])
Creates a texture on the frame.
```lua
local texture = frame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints()
texture:SetColorTexture(0, 0, 0, 0.5)
```

### Creating Font Strings

#### :CreateFontString([name] [, layer] [, inherits])
Creates a font string on the frame.
```lua
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("Hello World")
```

### Backdrop (Requires BackdropTemplate)

#### :SetBackdrop(backdrop)
Sets the frame's backdrop (frame must inherit BackdropTemplate).
```lua
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
```

#### :SetBackdropColor(r, g, b [, a])
Sets backdrop color.
```lua
frame:SetBackdropColor(0, 0, 0, 0.5)
```

#### :SetBackdropBorderColor(r, g, b [, a])
Sets backdrop border color.
```lua
frame:SetBackdropBorderColor(1, 1, 1, 1)
```

---

## Frame-Specific Methods

### Button Methods

#### :SetNormalTexture(texture)
Sets the normal state texture.
```lua
button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
```

#### :SetPushedTexture(texture)
Sets the pushed state texture.
```lua
button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
```

#### :SetHighlightTexture(texture [, blend])
Sets the highlight texture.
```lua
button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
```

#### :SetDisabledTexture(texture)
Sets the disabled state texture.
```lua
button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
```

#### :Enable()
Enables the button.
```lua
button:Enable()
```

#### :Disable()
Disables the button.
```lua
button:Disable()
```

#### :IsEnabled()
Returns true if enabled.
```lua
local isEnabled = button:IsEnabled()
```

#### :SetText(text)
Sets button text.
```lua
button:SetText("Click Me")
```

#### :GetText()
Returns button text.
```lua
local text = button:GetText()
```

#### :RegisterForClicks(...)
Registers which mouse buttons trigger OnClick.
```lua
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
```

### EditBox Methods

#### :SetText(text)
Sets the text.
```lua
editBox:SetText("Initial text")
```

#### :GetText()
Returns the text.
```lua
local text = editBox:GetText()
```

#### :SetMaxLetters(max)
Sets maximum character count.
```lua
editBox:SetMaxLetters(255)
```

#### :SetNumeric(numeric)
Sets whether only numbers are allowed.
```lua
editBox:SetNumeric(true)
```

#### :SetPassword(password)
Sets password mode.
```lua
editBox:SetPassword(true)
```

#### :SetMultiLine(multiLine)
Enables multi-line input.
```lua
editBox:SetMultiLine(true)
```

#### :SetFocus()
Sets keyboard focus.
```lua
editBox:SetFocus()
```

#### :ClearFocus()
Clears keyboard focus.
```lua
editBox:ClearFocus()
```

#### :HasFocus()
Returns true if has focus.
```lua
local hasFocus = editBox:HasFocus()
```

#### :HighlightText([start] [, end])
Highlights text.
```lua
editBox:HighlightText() -- Highlight all
editBox:HighlightText(0, 5) -- Highlight first 5 characters
```

#### :Insert(text)
Inserts text at cursor.
```lua
editBox:Insert("inserted text")
```

### Slider Methods

#### :SetMinMaxValues(min, max)
Sets the value range.
```lua
slider:SetMinMaxValues(0, 100)
```

#### :GetMinMaxValues()
Returns the value range.
```lua
local min, max = slider:GetMinMaxValues()
```

#### :SetValue(value)
Sets the current value.
```lua
slider:SetValue(50)
```

#### :GetValue()
Returns the current value.
```lua
local value = slider:GetValue()
```

#### :SetValueStep(step)
Sets the step amount.
```lua
slider:SetValueStep(1)
```

#### :GetValueStep()
Returns the step amount.
```lua
local step = slider:GetValueStep()
```

#### :SetOrientation(orientation)
Sets slider orientation.
```lua
slider:SetOrientation("HORIZONTAL") -- or "VERTICAL"
```

#### :GetOrientation()
Returns slider orientation.
```lua
local orientation = slider:GetOrientation()
```

#### :Enable()
Enables the slider.
```lua
slider:Enable()
```

#### :Disable()
Disables the slider.
```lua
slider:Disable()
```

### StatusBar Methods

#### :SetMinMaxValues(min, max)
Sets the value range.
```lua
statusBar:SetMinMaxValues(0, 100)
```

#### :GetMinMaxValues()
Returns the value range.
```lua
local min, max = statusBar:GetMinMaxValues()
```

#### :SetValue(value)
Sets the current value.
```lua
statusBar:SetValue(75)
```

#### :GetValue()
Returns the current value.
```lua
local value = statusBar:GetValue()
```

#### :SetStatusBarTexture(texture)
Sets the bar texture.
```lua
statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
```

#### :GetStatusBarTexture()
Returns the bar texture object.
```lua
local texture = statusBar:GetStatusBarTexture()
```

#### :SetStatusBarColor(r, g, b [, a])
Sets the bar color.
```lua
statusBar:SetStatusBarColor(0, 1, 0) -- Green
```

#### :GetStatusBarColor()
Returns the bar color.
```lua
local r, g, b, a = statusBar:GetStatusBarColor()
```

#### :SetOrientation(orientation)
Sets bar orientation.
```lua
statusBar:SetOrientation("HORIZONTAL") -- or "VERTICAL"
```

#### :SetReverseFill(reverse)
Sets reverse fill direction.
```lua
statusBar:SetReverseFill(true)
```

#### :GetReverseFill()
Returns reverse fill setting.
```lua
local reverse = statusBar:GetReverseFill()
```

### ScrollFrame Methods

#### :SetScrollChild(child)
Sets the scrollable content frame.
```lua
scrollFrame:SetScrollChild(contentFrame)
```

#### :GetScrollChild()
Returns the scroll child.
```lua
local child = scrollFrame:GetScrollChild()
```

#### :GetHorizontalScroll()
Returns horizontal scroll position.
```lua
local hScroll = scrollFrame:GetHorizontalScroll()
```

#### :SetHorizontalScroll(scroll)
Sets horizontal scroll position.
```lua
scrollFrame:SetHorizontalScroll(0)
```

#### :GetVerticalScroll()
Returns vertical scroll position.
```lua
local vScroll = scrollFrame:GetVerticalScroll()
```

#### :SetVerticalScroll(scroll)
Sets vertical scroll position.
```lua
scrollFrame:SetVerticalScroll(0)
```

#### :GetHorizontalScrollRange()
Returns horizontal scroll range.
```lua
local range = scrollFrame:GetHorizontalScrollRange()
```

#### :GetVerticalScrollRange()
Returns vertical scroll range.
```lua
local range = scrollFrame:GetVerticalScrollRange()
```

#### :UpdateScrollChildRect()
Updates the scroll child's rectangle.
```lua
scrollFrame:UpdateScrollChildRect()
```

### CheckButton Methods

#### :SetChecked(checked)
Sets checked state.
```lua
checkButton:SetChecked(true)
```

#### :GetChecked()
Returns checked state.
```lua
local isChecked = checkButton:GetChecked()
```

#### :SetCheckedTexture(texture)
Sets the checked texture.
```lua
checkButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
```

#### :GetCheckedTexture()
Returns the checked texture.
```lua
local texture = checkButton:GetCheckedTexture()
```

#### :SetDisabledCheckedTexture(texture)
Sets the disabled checked texture.
```lua
checkButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
```

### FontString Methods

#### :SetText(text)
Sets the text.
```lua
fontString:SetText("Hello World")
```

#### :GetText()
Returns the text.
```lua
local text = fontString:GetText()
```

#### :SetFormattedText(format, ...)
Sets formatted text.
```lua
fontString:SetFormattedText("Health: %d/%d", current, max)
```

#### :SetFont(font, size [, flags])
Sets the font.
```lua
fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
```

#### :GetFont()
Returns font information.
```lua
local font, size, flags = fontString:GetFont()
```

#### :SetFontObject(fontObject)
Sets font from a font object.
```lua
fontString:SetFontObject("GameFontNormal")
```

#### :GetFontObject()
Returns the font object.
```lua
local fontObject = fontString:GetFontObject()
```

#### :SetTextColor(r, g, b [, a])
Sets text color.
```lua
fontString:SetTextColor(1, 0, 0) -- Red
```

#### :GetTextColor()
Returns text color.
```lua
local r, g, b, a = fontString:GetTextColor()
```

#### :SetJustifyH(justify)
Sets horizontal justification.
```lua
fontString:SetJustifyH("LEFT") -- "LEFT", "CENTER", "RIGHT"
```

#### :SetJustifyV(justify)
Sets vertical justification.
```lua
fontString:SetJustifyV("TOP") -- "TOP", "MIDDLE", "BOTTOM"
```

#### :SetWordWrap(wrap)
Enables word wrapping.
```lua
fontString:SetWordWrap(true)
```

#### :GetStringWidth()
Returns the string width.
```lua
local width = fontString:GetStringWidth()
```

#### :GetStringHeight()
Returns the string height.
```lua
local height = fontString:GetStringHeight()
```

### Texture Methods

#### :SetTexture(texture [, horizontalWrap] [, verticalWrap] [, filterMode])
Sets the texture.
```lua
texture:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
texture:SetTexture(134400) -- FileDataID
```

#### :GetTexture()
Returns the texture path or ID.
```lua
local texturePath = texture:GetTexture()
```

#### :SetColorTexture(r, g, b [, a])
Sets a solid color texture.
```lua
texture:SetColorTexture(0, 0, 0, 0.5)
```

#### :SetGradient(orientation, minR, minG, minB, maxR, maxG, maxB)
Sets a gradient texture.
```lua
texture:SetGradient("VERTICAL", 0, 0, 0, 1, 1, 1)
```

#### :SetTexCoord(left, right, top, bottom)
Sets texture coordinates for cropping.
```lua
texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
```

#### :GetTexCoord()
Returns texture coordinates.
```lua
local left, right, top, bottom = texture:GetTexCoord()
```

#### :SetVertexColor(r, g, b [, a])
Sets vertex color (tint).
```lua
texture:SetVertexColor(1, 0, 0) -- Red tint
```

#### :GetVertexColor()
Returns vertex color.
```lua
local r, g, b, a = texture:GetVertexColor()
```

#### :SetBlendMode(mode)
Sets blend mode.
```lua
texture:SetBlendMode("ADD") -- "DISABLE", "BLEND", "ALPHAKEY", "ADD", "MOD"
```

#### :GetBlendMode()
Returns blend mode.
```lua
local mode = texture:GetBlendMode()
```

#### :SetDesaturated(desaturated)
Sets desaturation.
```lua
texture:SetDesaturated(true)
```

#### :IsDesaturated()
Returns desaturation state.
```lua
local isDesaturated = texture:IsDesaturated()
```

---

## GameTooltip Methods

### Positioning

#### :SetOwner(owner [, anchor] [, offsetX] [, offsetY])
Sets the tooltip owner and anchor.
```lua
GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
```

#### :SetDefaultAnchor(parent)
Sets default anchor position.
```lua
GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
```

### Content

#### :SetText(text [, r] [, g] [, b] [, textWrap])
Sets simple text.
```lua
GameTooltip:SetText("Tooltip Title", 1, 1, 1)
```

#### :AddLine(text [, r] [, g] [, b] [, textWrap])
Adds a line of text.
```lua
GameTooltip:AddLine("Additional information", 0.5, 0.5, 0.5)
```

#### :AddDoubleLine(leftText, rightText [, leftR] [, leftG] [, leftB] [, rightR] [, rightG] [, rightB])
Adds a double line (left and right text).
```lua
GameTooltip:AddDoubleLine("Left text", "Right text", 1, 1, 1, 0, 1, 0)
```

#### :ClearLines()
Clears all tooltip content.
```lua
GameTooltip:ClearLines()
```

### Special Content

#### :SetUnit(unit)
Shows unit tooltip.
```lua
GameTooltip:SetUnit("target")
```

#### :SetSpell(spellID)
Shows spell tooltip.
```lua
GameTooltip:SetSpell(12345)
```

#### :SetItem(item)
Shows item tooltip.
```lua
GameTooltip:SetItem("item:12345")
```

#### :SetAction(slot)
Shows action button tooltip.
```lua
GameTooltip:SetAction(1)
```

#### :SetBagItem(bag, slot)
Shows bag item tooltip.
```lua
GameTooltip:SetBagItem(0, 1)
```

#### :SetInventoryItem(unit, slot)
Shows equipped item tooltip.
```lua
GameTooltip:SetInventoryItem("player", 16) -- Main hand
```

---

## Animation System

### Creating Animations

#### :CreateAnimationGroup([name] [, inheritsFrom])
Creates an animation group.
```lua
local animGroup = frame:CreateAnimationGroup()
```

### Animation Group Methods

#### :Play()
Plays the animation.
```lua
animGroup:Play()
```

#### :Stop()
Stops the animation.
```lua
animGroup:Stop()
```

#### :Pause()
Pauses the animation.
```lua
animGroup:Pause()
```

#### :IsPlaying()
Returns true if playing.
```lua
local isPlaying = animGroup:IsPlaying()
```

#### :SetLooping(loopType)
Sets looping behavior.
```lua
animGroup:SetLooping("REPEAT") -- "NONE", "REPEAT", "BOUNCE"
```

### Creating Specific Animations

#### :CreateAnimation(animationType [, name] [, inheritsFrom])
Creates a specific animation type.
```lua
local alpha = animGroup:CreateAnimation("Alpha")
alpha:SetFromAlpha(0)
alpha:SetToAlpha(1)
alpha:SetDuration(1)

local translation = animGroup:CreateAnimation("Translation")
translation:SetOffset(100, 0)
translation:SetDuration(0.5)

local scale = animGroup:CreateAnimation("Scale")
scale:SetScale(2, 2)
scale:SetDuration(0.3)

local rotation = animGroup:CreateAnimation("Rotation")
rotation:SetDegrees(360)
rotation:SetDuration(2)
```

---

## Model Frame Methods

### Model Display

#### :SetModel(file)
Sets the model file.
```lua
modelFrame:SetModel("Interface\\Buttons\\TalkToMeQuestionMark.mdx")
```

#### :SetCreature(creatureID)
Sets a creature model.
```lua
modelFrame:SetCreature(12345)
```

#### :SetUnit(unit)
Sets model to a unit.
```lua
modelFrame:SetUnit("player")
```

#### :SetDisplayInfo(displayID)
Sets model by display ID.
```lua
modelFrame:SetDisplayInfo(12345)
```

#### :ClearModel()
Clears the model.
```lua
modelFrame:ClearModel()
```

### Model Control

#### :SetPosition(x, y, z)
Sets model position.
```lua
modelFrame:SetPosition(0, 0, 0)
```

#### :SetFacing(facing)
Sets model facing (radians).
```lua
modelFrame:SetFacing(math.pi)
```

#### :SetModelScale(scale)
Sets model scale.
```lua
modelFrame:SetModelScale(1.5)
```

#### :SetRotation(rotation)
Sets model rotation.
```lua
modelFrame:SetRotation(math.rad(45))
```

#### :SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
Sets model lighting.
```lua
modelFrame:SetLight(true, false, -1, 0, 0, 0.8, 1, 1, 1, 0.5, 1, 1, 1)
```

---

## Secure Templates

### SecureActionButtonTemplate
Used for action buttons that perform protected actions.

```lua
local button = CreateFrame("Button", "MySecureButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "action")
button:SetAttribute("action", 1)
```

### Common Secure Attributes

- `type` - Action type ("action", "spell", "item", "macro", "pet", "stance", etc.)
- `action` - Action slot number
- `spell` - Spell name
- `item` - Item name or link
- `macro` - Macro index or name
- `macrotext` - Macro text to execute
- `unit` - Unit to target

### SecureHandlerStateTemplate
Used for state-driven secure frames.

```lua
local frame = CreateFrame("Frame", "MyStateFrame", UIParent, "SecureHandlerStateTemplate")
RegisterStateDriver(frame, "visibility", "[combat] hide; show")
```

---

## Miscellaneous Methods

### Movement and Resizing

#### :StartMoving()
Starts moving the frame.
```lua
frame:StartMoving()
```

#### :StopMovingOrSizing()
Stops moving or resizing.
```lua
frame:StopMovingOrSizing()
```

#### :SetMovable(movable)
Makes frame movable.
```lua
frame:SetMovable(true)
```

#### :IsMovable()
Returns if frame is movable.
```lua
local isMovable = frame:IsMovable()
```

#### :SetResizable(resizable)
Makes frame resizable.
```lua
frame:SetResizable(true)
```

#### :IsResizable()
Returns if frame is resizable.
```lua
local isResizable = frame:IsResizable()
```

#### :SetUserPlaced(userPlaced)
Marks frame as user-placed.
```lua
frame:SetUserPlaced(true)
```

#### :IsUserPlaced()
Returns if frame is user-placed.
```lua
local isUserPlaced = frame:IsUserPlaced()
```

#### :SetClampedToScreen(clamped)
Prevents frame from going off-screen.
```lua
frame:SetClampedToScreen(true)
```

#### :IsClampedToScreen()
Returns if frame is clamped to screen.
```lua
local isClamped = frame:IsClampedToScreen()
```

### Mouse Interaction

#### :EnableMouse(enable)
Enables mouse interaction.
```lua
frame:EnableMouse(true)
```

#### :IsMouseEnabled()
Returns if mouse is enabled.
```lua
local isMouseEnabled = frame:IsMouseEnabled()
```

#### :EnableMouseWheel(enable)
Enables mouse wheel events.
```lua
frame:EnableMouseWheel(true)
```

#### :IsMouseWheelEnabled()
Returns if mouse wheel is enabled.
```lua
local isMouseWheelEnabled = frame:IsMouseWheelEnabled()
```

#### :EnableKeyboard(enable)
Enables keyboard input.
```lua
frame:EnableKeyboard(true)
```

#### :IsKeyboardEnabled()
Returns if keyboard is enabled.
```lua
local isKeyboardEnabled = frame:IsKeyboardEnabled()
```

### Hit Testing

#### :SetHitRectInsets(left, right, top, bottom)
Sets hit rectangle insets.
```lua
frame:SetHitRectInsets(10, 10, 10, 10)
```

#### :GetHitRectInsets()
Returns hit rectangle insets.
```lua
local left, right, top, bottom = frame:GetHitRectInsets()
```

#### :IsMouseOver([offsetTop] [, offsetBottom] [, offsetLeft] [, offsetRight])
Returns if mouse is over frame.
```lua
local isOver = frame:IsMouseOver()
```

---

## Notes

1. Many methods require specific frame types or templates
2. Some methods are protected and can only be called from secure code
3. Performance considerations: Avoid OnUpdate scripts when possible
4. Always unregister events when frames are hidden/unused
5. Use frame pooling for frequently created/destroyed frames
6. Be careful with global names to avoid conflicts