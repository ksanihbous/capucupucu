--==========================================================
--  18AxaTab_BuyBibit.lua
--  TAB 2: Auto / Manual Buy Bibit (GET_LIST)
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "buybibit_sawahindo"

if not frame then return end

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = Remotes:WaitForChild("TutorialRemotes")
local RequestShop     = TutorialRemotes:WaitForChild("RequestShop")

frame:ClearAllChildren()
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0

_G.AxaHub            = _G.AxaHub or {}
_G.AxaHub.TabCleanup = _G.AxaHub.TabCleanup or {}

local running     = true
local connections = {}

local function addConn(c)
    if c then table.insert(connections, c) end
    return c
end

local function notify(text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "Buy Bibit",
            Text     = text or "",
            Duration = dur or 3
        })
    end)
end

--==========================================================
-- DATA BIBIT (GET_LIST)
--==========================================================

local Seeds = {}
local defaultBuyAmount = 10

local function fetchSeeds()
    local args = { "GET_LIST" }
    local ok, data = pcall(function()
        return RequestShop:InvokeServer(unpack(args))
    end)
    if not ok or type(data) ~= "table" or type(data.Seeds) ~= "table" then
        notify("Gagal GET_LIST Bibit")
        return
    end

    Seeds = {}
    for idx, info in pairs(data.Seeds) do
        if type(info) == "table" and info.Name then
            table.insert(Seeds, info)
        end
    end

    table.sort(Seeds, function(a,b)
        local sa = tonumber(a.SortOrder or 999) or 999
        local sb = tonumber(b.SortOrder or 999) or 999
        return sa < sb
    end)
end

local function doBuySeed(seedName, amount)
    if not seedName or not amount or amount <= 0 then return end
    local args = { "BUY", seedName, amount }
    pcall(function()
        RequestShop:InvokeServer(unpack(args))
    end)
end

--==========================================================
-- UI HELPERS
--==========================================================

local function createMainLayout()
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1,-10,0,24)
    title.Position = UDim2.new(0,5,0,5)
    title.Text = "TAB 2: Buy Bibit (Shop Request)"

    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = frame
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0,5,0,32)
    scroll.Size = UDim2.new(1,-10,1,-37)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 4
    scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

    local padding = Instance.new("UIPadding")
    padding.Parent = scroll
    padding.PaddingTop = UDim.new(0,4)
    padding.PaddingLeft = UDim.new(0,2)
    padding.PaddingRight = UDim.new(0,2)
    padding.PaddingBottom = UDim.new(0,4)

    local layout = Instance.new("UIListLayout")
    layout.Parent = scroll
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)

    addConn(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    end))

    return scroll
end

local function card(parent)
    local f = Instance.new("Frame")
    f.Parent = parent
    f.BackgroundColor3 = Color3.fromRGB(20,20,20)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1,0,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = f

    local pad = Instance.new("UIPadding")
    pad.Parent = f
    pad.PaddingTop = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,6)
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)

    local inner = Instance.new("Frame")
    inner.Parent = f
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1,0,0,0)
    inner.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = inner
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)

    return inner
end

local function makeButton(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Parent = parent
    b.Size = UDim2.new(1,0,0,26)
    b.BackgroundColor3 = Color3.fromRGB(35,35,35)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(230,230,230)
    b.Text = text

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,6)
    c.Parent = b

    addConn(b.MouseButton1Click:Connect(function()
        if cb then cb() end
    end))

    return b
end

local function makeNumberBox(parent, labelText, defaultValue, cb)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1,0,0,16)
    lbl.Text = labelText

    local box = Instance.new("TextBox")
    box.Parent = parent
    box.Size = UDim2.new(1,0,0,24)
    box.BackgroundColor3 = Color3.fromRGB(35,35,35)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(230,230,230)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Text = tostring(defaultValue)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,6)
    c.Parent = box

    addConn(box.FocusLost:Connect(function()
        local raw = (box.Text or ""):gsub(",", ".")
        local n = tonumber(raw)
        if not n or n <= 0 then
            box.Text = tostring(defaultValue)
            return
        end
        defaultBuyAmount = math.floor(n)
        box.Text = tostring(defaultBuyAmount)
        if cb then cb(defaultBuyAmount) end
    end))

    return box
end

--==========================================================
-- BUILD UI
--==========================================================

local body = createMainLayout()

do
    local topCard = card(body)

    local label = Instance.new("TextLabel")
    label.Parent = topCard
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextColor3 = Color3.fromRGB(200,200,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1,0,0,18)
    label.Text = "Config Umum:"

    makeNumberBox(topCard, "Jumlah buy per klik (default 10)", defaultBuyAmount)

    makeButton(topCard, "Refresh List Bibit (GET_LIST)", function()
        fetchSeeds()
        notify("Refresh Bibit: "..tostring(#Seeds).." item", 2)
    end)
end

local listContainer = card(body)

local function rebuildSeedButtons()
    listContainer:ClearAllChildren()
    local layout = Instance.new("UIListLayout")
    layout.Parent = listContainer
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)

    for _, seed in ipairs(Seeds) do
        local row = Instance.new("Frame")
        row.Parent = listContainer
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1,0,0,32)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = row
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(0.6,0,1,0)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = Color3.fromRGB(230,230,230)
        local display = seed.DisplayName or seed.Name or "?"
        local price = seed.Price or 0
        local owned = seed.Owned or 0
        nameLabel.Text = string.format("%s  | Price: %d | Owned: %d", display, price, owned)

        local btn = Instance.new("TextButton")
        btn.Parent = row
        btn.AnchorPoint = Vector2.new(1,0.5)
        btn.Position = UDim2.new(1,0,0.5,0)
        btn.Size = UDim2.new(0.35,0,0.8,0)
        btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.Text = "Buy x"..tostring(defaultBuyAmount)

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,6)
        c.Parent = btn

        addConn(btn.MouseButton1Click:Connect(function()
            doBuySeed(seed.Name, defaultBuyAmount)
        end))
    end
end

fetchSeeds()
rebuildSeedButtons()

-- recreate list when Seeds berubah (dipanggil manual)
local oldFetch = fetchSeeds
fetchSeeds = function()
    oldFetch()
    rebuildSeedButtons()
end

--==========================================================
-- TAB CLEANUP
--==========================================================

_G.AxaHub.TabCleanup[tabId] = function()
    running = false
    frame:ClearAllChildren()
    for _, c in ipairs(connections) do
        pcall(function()
            if c and c.Disconnect then c:Disconnect() end
        end)
    end
    connections = {}
end

print("[18AxaTab_BuyBibit] Loaded.")