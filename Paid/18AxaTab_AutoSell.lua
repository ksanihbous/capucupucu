--==========================================================
--  18AxaTab_AutoSell.lua
--  TAB 4: Auto Sell Padi + Sell All
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "autosell_sawahindo"

if not frame then return end

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = Remotes:WaitForChild("TutorialRemotes")
local RequestSell     = TutorialRemotes:WaitForChild("RequestSell")

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

local function notify(msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Sell",
            Text  = msg or "",
            Duration = dur or 3
        })
    end)
end

-- SyncData helper
local SyncDataRF = Remotes:FindFirstChild("SyncData")
local clientBoot = LocalPlayer:FindFirstChild("ClientBoot")
local SafeRemote, GameRemotes
pcall(function()
    if clientBoot then
        SafeRemote  = require(clientBoot.Core.SafeRemote)
        GameRemotes = require(clientBoot.Remotes)
    end
end)

local lastSync, cachedSync = 0, nil
local function SyncData(force)
    local now = tick()
    if not force and cachedSync and now - lastSync < 2 then
        return cachedSync
    end
    lastSync = now

    if SafeRemote and GameRemotes and GameRemotes.SyncData then
        local ok, data = pcall(function()
            return SafeRemote.Invoke(GameRemotes.SyncData)
        end)
        if ok and type(data)=="table" then
            cachedSync = data
            return data
        end
    end
    if SyncDataRF and SyncDataRF:IsA("RemoteFunction") then
        local ok, data = pcall(function()
            return SyncDataRF:InvokeServer()
        end)
        if ok and type(data)=="table" then
            cachedSync = data
            return data
        end
    end
    return cachedSync
end

local function doSell(cropName, amount)
    if not cropName or not amount or amount <= 0 then return end
    local args = {"SELL", cropName, amount}
    pcall(function()
        RequestSell:InvokeServer(unpack(args))
    end)
end

local autoSellEnabled = true
local padiThreshold   = 20
local padiBatch       = 20

local function autoSellLoop()
    while running do
        if autoSellEnabled then
            local data = SyncData(false)
            if data and type(data.Inventory)=="table" then
                local inv = data.Inventory
                local have = inv["Padi"] or 0
                if have >= padiThreshold then
                    local qty = math.min(padiBatch, have)
                    if qty > 0 then
                        doSell("Padi", qty)
                        task.wait(0.2)
                    end
                end
            end
        end
        task.wait(1.0)
    end
end

local function sellAllCrops()
    local data = SyncData(true)
    if not (data and data.Inventory) then return end
    for name,count in pairs(data.Inventory) do
        if type(name)=="string" and count>0 then
            if not name:lower():find("bibit") then
                doSell(name, count)
                task.wait(0.1)
            end
        end
    end
end

--==========================================================
-- UI
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
    title.Text = "TAB 4: Auto Sell Sawah Indo"

    local body = Instance.new("Frame")
    body.Parent = frame
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0,5,0,32)
    body.Size = UDim2.new(1,-10,1,-37)

    local layout = Instance.new("UIListLayout")
    layout.Parent = body
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    return body
end

local function button(parent, text, cb)
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

local function toggle(parent, text, initial, cb)
    local b = button(parent, "", nil)
    local state = initial and true or false

    local function refresh()
        b.Text = text .. ": " .. (state and "ON" or "OFF")
        b.BackgroundColor3 = state and Color3.fromRGB(40,90,50) or Color3.fromRGB(35,35,35)
    end
    refresh()

    addConn(b.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        if cb then cb(state) end
    end))

    return b
end

local function numBox(parent, labelText, defaultValue, cb, minVal, maxVal)
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
        local raw = (box.Text or ""):gsub(",",".")
        local n = tonumber(raw)
        if not n then
            box.Text = tostring(defaultValue)
            return
        end
        n = math.clamp(math.floor(n), minVal or 1, maxVal or 99999)
        defaultValue = n
        box.Text = tostring(defaultValue)
        if cb then cb(n) end
    end))
end

local body = createMainLayout()

toggle(body, "Auto Sell Padi", autoSellEnabled, function(state)
    autoSellEnabled = state
end)

numBox(body, "Threshold Auto Sell Padi (>= ini)", padiThreshold, function(v)
    padiThreshold = v
end,1,99999)

numBox(body, "Batch Sell Padi per request", padiBatch, function(v)
    padiBatch = v
end,1,99999)

button(body, "Sell Padi (All Sekali)", function()
    local data = SyncData(true)
    if not (data and data.Inventory) then return end
    local count = data.Inventory["Padi"] or 0
    if count > 0 then
        doSell("Padi", count)
    else
        notify("Tidak ada Padi di inventory.",2)
    end
end)

button(body, "Sell All Crops (kecuali bibit)", function()
    sellAllCrops()
end)

--==========================================================
-- START LOOP & CLEANUP
--==========================================================

task.spawn(autoSellLoop)

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

print("[18AxaTab_AutoSell] Loaded.")