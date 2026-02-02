--==========================================================
--  13AxaTab_VD_MISC.lua
--  Violence District - Visual, FOV, Fling, Panic
--==========================================================
local frame = TAB_FRAME
local tabId = TAB_ID or "vd_misc"

if not frame then return end
frame:ClearAllChildren()
frame.BackgroundTransparency = 1

local VD_Config = _G.VD_Config or {}
local VD_API    = _G.VD_API    or {}

if not VD_Config then
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -20, 0, 60)
    msg.Position = UDim2.new(0, 10, 0, 10)
    msg.BackgroundTransparency = 1
    msg.Font = Enum.Font.GothamBold
    msg.TextSize = 16
    msg.TextColor3 = Color3.fromRGB(255, 80, 80)
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.Text = "[VD MISC] Jalankan dulu script Violence District utama agar _G.VD_Config tersedia."
    msg.Parent = frame
    return
end

local UserInputService = game:GetService("UserInputService")

local BG_COLOR      = Color3.fromRGB(10, 10, 16)
local CARD_COLOR    = Color3.fromRGB(18, 18, 26)
local CARD_BORDER   = Color3.fromRGB(60, 60, 80)
local TEXT_COLOR    = Color3.fromRGB(235, 235, 245)
local TEXT_MUTED    = Color3.fromRGB(150, 150, 165)
local ACCENT        = Color3.fromRGB(220, 70, 70)
local ACCENT_SOFT   = Color3.fromRGB(90, 220, 120)

frame.BackgroundColor3 = BG_COLOR

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Parent = frame
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 0, 0, 0)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageTransparency = 0.2
scroll.ScrollBarImageColor3 = CARD_BORDER

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

local pad = Instance.new("UIPadding")
pad.Parent = scroll
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)

local function createCard(title, subtitle)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = CARD_COLOR
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = scroll

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = CARD_BORDER
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.Parent = card
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)

    local vlayout = Instance.new("UIListLayout")
    vlayout.Parent = card
    vlayout.SortOrder = Enum.SortOrder.LayoutOrder
    vlayout.Padding = UDim.new(0, 4)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = TEXT_COLOR
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.Text = title
    titleLabel.Parent = card

    if subtitle and subtitle ~= "" then
        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 13
        sub.TextColor3 = TEXT_MUTED
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextWrapped = true
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Text = subtitle
        sub.Parent = card
    end

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = card

    local clayout = Instance.new("UIListLayout")
    clayout.Parent = container
    clayout.SortOrder = Enum.SortOrder.LayoutOrder
    clayout.Padding = UDim.new(0, 2)

    return container
end

local function createRow(parent, height)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, height or 26)
    row.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = row

    return row
end

local function createLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = TEXT_COLOR
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Text = text
    lbl.Parent = parent
    return lbl
end

local function createRight(parent, width)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(0, width or 150, 1, 0)
    f.Parent = parent
    return f
end

-- Toggle
local function createToggle(parent, labelText, cfgKey)
    local row = createRow(parent, 26)
    createLabel(row, labelText)
    local right = createRight(row, 50)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 18)
    btn.AnchorPoint = Vector2.new(0, 0.5)
    btn.Position = UDim2.new(0, 0, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = right
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = not not VD_Config[cfgKey]
        btn.BackgroundColor3 = on and ACCENT_SOFT or Color3.fromRGB(60, 60, 80)
        knob.Position = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    end

    btn.MouseButton1Click:Connect(function()
        VD_Config[cfgKey] = not VD_Config[cfgKey]
        refresh()
    end)

    if VD_Config[cfgKey] == nil then
        VD_Config[cfgKey] = false
    end
    refresh()
end

-- Slider
local function createSlider(parent, labelText, cfgKey, minVal, maxVal, step)
    step = step or 1
    local row = createRow(parent, 32)
    createLabel(row, labelText)
    local right = createRight(row, 150)

    local valLabel = Instance.new("TextLabel")
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextSize = 13
    valLabel.TextColor3 = TEXT_MUTED
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Size = UDim2.new(1, 0, 0, 16)
    valLabel.Parent = right

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, 0, 0, 4)
    bar.Position = UDim2.new(0, 0, 1, -4)
    bar.Parent = right
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

    local function clampValue(v)
        v = math.clamp(v, minVal, maxVal)
        v = math.floor(v / step + 0.5) * step
        return v
    end

    local function refresh()
        local v = VD_Config[cfgKey]
        if type(v) ~= "number" then
            v = minVal
            VD_Config[cfgKey] = v
        end
        v = clampValue(v)
        local t = (v - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(t, 0, 1, 0)
        if step < 1 then
            valLabel.Text = string.format("%.2f", v)
        else
            valLabel.Text = tostring(v)
        end
    end

    local function setFromMouse()
        local mouseX = UserInputService:GetMouseLocation().X
        local absX = bar.AbsolutePosition.X
        local width = bar.AbsoluteSize.X
        if width <= 0 then return end
        local pct = math.clamp((mouseX - absX) / width, 0, 1)
        local v = minVal + pct * (maxVal - minVal)
        VD_Config[cfgKey] = clampValue(v)
        refresh()
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.Parent = bar
    clickBtn.MouseButton1Click:Connect(setFromMouse)

    if type(VD_Config[cfgKey]) ~= "number" then
        VD_Config[cfgKey] = minVal
    end
    refresh()
end

-- Keybind
local KeyNames = {
    [Enum.KeyCode.Home] = "HOME",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Delete] = "DEL",
}
local function getKeyName(k)
    return KeyNames[k] or tostring(k):gsub("Enum.KeyCode.", "")
end

local waitingKey
UserInputService.InputBegan:Connect(function(input, gp)
    if not waitingKey then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.Escape then
        waitingKey.button.Text = waitingKey.oldText
    else
        VD_Config[waitingKey.key] = input.KeyCode
        waitingKey.button.Text = "[" .. getKeyName(input.KeyCode) .. "]"
    end
    waitingKey = nil
end)

local function createKeybind(parent, labelText, cfgKey)
    local row = createRow(parent, 26)
    createLabel(row, labelText)
    local right = createRight(row, 90)

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.AutoButtonColor = false
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.AnchorPoint = Vector2.new(0, 0.5)
    btn.Position = UDim2.new(0, 0, 0.5, 0)
    btn.Text = ""
    btn.Parent = right
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = TEXT_COLOR
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = btn

    local function refresh()
        local key = VD_Config[cfgKey]
        if typeof(key) ~= "EnumItem" then
            label.Text = "[None]"
        else
            label.Text = "[" .. getKeyName(key) .. "]"
        end
    end

    btn.MouseButton1Click:Connect(function()
        waitingKey = {
            key = cfgKey,
            button = label,
            oldText = label.Text,
        }
        label.Text = "[...]"
    end)

    refresh()
end

-- Button
local function createButton(parent, text, callback)
    local row = createRow(parent, 26)
    local lbl = createLabel(row, text)
    lbl.Size = UDim2.new(1, -110, 1, 0)
    local right = createRight(row, 100)

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.AutoButtonColor = true
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.AnchorPoint = Vector2.new(0, 0.5)
    btn.Position = UDim2.new(0, 0, 0.5, 0)
    btn.Text = "GO"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = TEXT_COLOR
    btn.Parent = right
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        if callback then
            pcall(callback)
        end
    end)
end

--==========================================================
--  BUILD UI
--==========================================================

-- Visual
do
    local card = createCard("Visual", "Bersihkan fog dan atur FOV.")
    createToggle(card, "No Fog", "NO_Fog")
    createToggle(card, "Custom FOV Enabled", "CAM_FOVEnabled")
    createSlider(card, "Camera FOV", "CAM_FOV", 30, 120, 5)
end

-- Fling
do
    local card = createCard("Fling", "Fling character ke pemain lain.")
    createToggle(card, "Enable Fling", "FLING_Enabled")
    createSlider(card, "Fling Strength", "FLING_Strength", 1000, 50000, 1000)

    createButton(card, "Fling Nearest", function()
        if VD_API and VD_API.FlingNearest then
            VD_API.FlingNearest()
        else
            warn("[VD_MISC] VD_API.FlingNearest not available")
        end
    end)

    createButton(card, "Fling All", function()
        if VD_API and VD_API.FlingAll then
            VD_API.FlingAll()
        else
            warn("[VD_MISC] VD_API.FlingAll not available")
        end
    end)
end

-- Hotkeys
do
    local card = createCard("Hotkeys", "Panic key untuk mematikan script VD utama.")
    createKeybind(card, "Panic Key", "KEY_Panic")
end

------------------------------------------------------------
-- TAB CLEANUP: 13AxaTab_VD_MISC
------------------------------------------------------------
local AxaTabCleanup = _G.AxaTabCleanup or {}
_G.AxaTabCleanup = AxaTabCleanup

AxaTabCleanup[tabId] = function()
    local C = _G.VD_Config
    if not C then return end

    -- Visual
    C.NO_Fog          = false
    C.CAM_FOVEnabled  = false

    -- Fling
    C.FLING_Enabled   = false

    -- Menu / hotkey tidak perlu di-reset, cukup biar default:
    -- C.MENU_Open  (biar core AxaHub yang control)
end