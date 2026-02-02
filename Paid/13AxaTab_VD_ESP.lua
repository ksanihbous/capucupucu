--==========================================================
--  13AxaTab_VD_ESP.lua
--  Violence District - ESP & Radar (Tahoe AxaHub TAB)
--  Sekaligus initializer _G.VD_Config & _G.VD_API (jika belum ada)
--==========================================================
local frame = TAB_FRAME
local tabId = TAB_ID or "vd_esp"

if not frame then
    return
end

frame:ClearAllChildren()
frame.BackgroundTransparency = 1

------------------------------------------------------------
-- GLOBAL CONFIG + API INIT
------------------------------------------------------------
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Siapkan GLOBAL CONFIG (sekali saja)
_G.VD_Config = _G.VD_Config or {}
local VD_Config = _G.VD_Config

-- Helper default
local function ensureDefault(key, default)
    if VD_Config[key] == nil then
        VD_Config[key] = default
    end
end

-- Default boolean ESP / RADAR
ensureDefault("ESP_Enabled",        false)
ensureDefault("ESP_Killer",         false)
ensureDefault("ESP_Survivor",       false)

ensureDefault("ESP_Generator",      false)
ensureDefault("ESP_Gate",           false)
ensureDefault("ESP_Hook",           false)
ensureDefault("ESP_Pallet",         false)
ensureDefault("ESP_Window",         false)
ensureDefault("ESP_ClosestHook",    false)

ensureDefault("ESP_Names",          true)
ensureDefault("ESP_Distance",       true)
ensureDefault("ESP_Health",         false)
ensureDefault("ESP_Skeleton",       false)
ensureDefault("ESP_Offscreen",      true)
ensureDefault("ESP_Velocity",       false)

ensureDefault("ESP_PlayerChams",    false)
ensureDefault("ESP_ObjectChams",    false)

ensureDefault("RADAR_Enabled",      false)
ensureDefault("RADAR_Circle",       true)
ensureDefault("RADAR_Killer",       true)
ensureDefault("RADAR_Survivor",     true)
ensureDefault("RADAR_Generator",    false)
ensureDefault("RADAR_Pallet",       false)

-- Default numeric
ensureDefault("ESP_MaxDist",        500)   -- 100–1000
ensureDefault("RADAR_Size",         120)   -- 80–200

-- Siapkan GLOBAL API (Notify, dll)
_G.VD_API = _G.VD_API or {}
local VD_API = _G.VD_API

if type(VD_API.Notify) ~= "function" then
    function VD_API.Notify(text, duration)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title    = "ExHub | Violence District",
                Text     = tostring(text or ""),
                Duration = duration or 5
            })
        end)
    end
end

------------------------------------------------------------
-- PALET WARNA TAHOE
------------------------------------------------------------
local BG_COLOR      = Color3.fromRGB(10, 10, 16)
local CARD_COLOR    = Color3.fromRGB(18, 18, 26)
local CARD_BORDER   = Color3.fromRGB(60, 60, 80)
local TEXT_COLOR    = Color3.fromRGB(235, 235, 245)
local TEXT_MUTED    = Color3.fromRGB(150, 150, 165)
local ACCENT        = Color3.fromRGB(220, 70, 70)
local ACCENT_SOFT   = Color3.fromRGB(90, 220, 120)

frame.BackgroundColor3 = BG_COLOR

--==========================================================
--  BASE SCROLL CONTAINER
--==========================================================
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

--==========================================================
--  HELPER UI
--==========================================================
local function createCard(title, subtitle)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = CARD_COLOR
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

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
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
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
        sub.TextYAlignment = Enum.TextYAlignment.Top
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.TextWrapped = true
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
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Text = text
    lbl.Parent = parent
    return lbl
end

local function createRightContainer(parent, width)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(0, width or 120, 1, 0)
    holder.Parent = parent
    return holder
end

--==========================================================
--  TOGGLE
--==========================================================
local function createToggle(parent, labelText, cfgKey)
    local row = createRow(parent, 26)
    createLabel(row, labelText)
    local right = createRightContainer(row, 50)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 18)
    btn.AnchorPoint = Vector2.new(0, 0.5)
    btn.Position = UDim2.new(0, 0, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = right

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

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

--==========================================================
--  SLIDER (klik bar, tanpa drag terus menerus)
--==========================================================
local function createSlider(parent, labelText, cfgKey, minVal, maxVal, step)
    step = step or 1
    local row = createRow(parent, 32)
    createLabel(row, labelText)
    local right = createRightContainer(row, 140)

    local valLabel = Instance.new("TextLabel")
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextSize = 13
    valLabel.TextColor3 = TEXT_MUTED
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Size = UDim2.new(1, 0, 0, 16)
    valLabel.Text = ""
    valLabel.Parent = right

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, 0, 0, 4)
    bar.Position = UDim2.new(0, 0, 1, -4)
    bar.Parent = right

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = fill

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
        local mousePos = UserInputService:GetMouseLocation().X
        local absPos = bar.AbsolutePosition.X
        local width = bar.AbsoluteSize.X
        if width <= 0 then return end
        local pct = math.clamp((mousePos - absPos) / width, 0, 1)
        local v = minVal + pct * (maxVal - minVal)
        VD_Config[cfgKey] = clampValue(v)
        refresh()
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.Parent = bar
    clickBtn.ZIndex = bar.ZIndex + 1

    clickBtn.MouseButton1Click:Connect(setFromMouse)

    if type(VD_Config[cfgKey]) ~= "number" then
        VD_Config[cfgKey] = minVal
    end
    refresh()
end

--==========================================================
--  MODE TOGGLE (bool untuk mode Draw / Chams)
--==========================================================
local function createModeToggle(parent, labelText, cfgKey, leftText, rightText)
    local row = createRow(parent, 26)
    createLabel(row, labelText)
    local right = createRightContainer(row, 140)

    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = right

    local txt = Instance.new("TextLabel")
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 13
    txt.TextColor3 = TEXT_COLOR
    txt.TextXAlignment = Enum.TextXAlignment.Right
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Parent = btn

    local function refresh()
        local onChams = not not VD_Config[cfgKey]
        if onChams then
            txt.Text = leftText .. " | [" .. rightText .. "]"
        else
            txt.Text = "[" .. leftText .. "] | " .. rightText
        end
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

--==========================================================
--  BUILD UI: ESP & RADAR
--==========================================================

-- General
do
    local card = createCard("ESP General", "Master switch dan jarak maksimum ESP.")
    createToggle(card, "Enable ESP", "ESP_Enabled")
    createSlider(card, "Max Distance", "ESP_MaxDist", 100, 1000, 50)
end

-- Players
do
    local card = createCard("ESP Players", "Killer dan Survivor.")
    createToggle(card, "Killer", "ESP_Killer")
    createToggle(card, "Survivor", "ESP_Survivor")
    createModeToggle(card, "Player ESP Mode", "ESP_PlayerChams", "DRAW", "CHAMS")
end

-- Objects
do
    local card = createCard("ESP Objects", "Generator, gate, hook, pallet, dan window.")
    createToggle(card, "Generator", "ESP_Generator")
    createToggle(card, "Gate", "ESP_Gate")
    createToggle(card, "Hook", "ESP_Hook")
    createToggle(card, "Pallet", "ESP_Pallet")
    createToggle(card, "Window", "ESP_Window")
    createToggle(card, "Highlight Closest Hook", "ESP_ClosestHook")
    createModeToggle(card, "Object ESP Mode", "ESP_ObjectChams", "DRAW", "CHAMS")
end

-- Detail
do
    local card = createCard("ESP Detail", "Informasi tambahan di ESP.")
    createToggle(card, "Show Names", "ESP_Names")
    createToggle(card, "Show Distance", "ESP_Distance")
    createToggle(card, "Show Health Bar", "ESP_Health")
    createToggle(card, "Skeleton Lines", "ESP_Skeleton")
    createToggle(card, "Offscreen Arrow", "ESP_Offscreen")
    createToggle(card, "Velocity Arrow", "ESP_Velocity")
end

-- Radar
do
    local card = createCard("Radar", "Mini map pemain dan objek di pojok layar.")
    createToggle(card, "Enable Radar", "RADAR_Enabled")
    createSlider(card, "Radar Size", "RADAR_Size", 80, 200, 10)
    createToggle(card, "Circle Style", "RADAR_Circle")
    createToggle(card, "Show Killer", "RADAR_Killer")
    createToggle(card, "Show Survivors", "RADAR_Survivor")
    createToggle(card, "Show Generators", "RADAR_Generator")
    createToggle(card, "Show Pallets", "RADAR_Pallet")
end

------------------------------------------------------------
-- TAB CLEANUP: 13AxaTab_VD_ESP
------------------------------------------------------------
local AxaTabCleanup = _G.AxaTabCleanup or {}
_G.AxaTabCleanup = AxaTabCleanup

AxaTabCleanup[tabId] = function()
    local C = _G.VD_Config
    if not C then return end

    -- ESP players
    C.ESP_Enabled     = false
    C.ESP_Killer      = false
    C.ESP_Survivor    = false

    -- ESP objects
    C.ESP_Generator   = false
    C.ESP_Gate        = false
    C.ESP_Hook        = false
    C.ESP_Pallet      = false
    C.ESP_Window      = false
    C.ESP_ClosestHook = false

    -- ESP detail
    C.ESP_Names       = false
    C.ESP_Distance    = false
    C.ESP_Health      = false
    C.ESP_Skeleton    = false
    C.ESP_Offscreen   = false
    C.ESP_Velocity    = false

    -- Mode ESP
    C.ESP_PlayerChams = false
    C.ESP_ObjectChams = false

    -- Radar
    C.RADAR_Enabled   = false
    C.RADAR_Killer    = false
    C.RADAR_Survivor  = false
    C.RADAR_Generator = false
    C.RADAR_Pallet    = false
end