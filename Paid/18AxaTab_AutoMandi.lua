--==========================================================
--  18AxaTab_AutoMandi.lua
--  TAB 6: Auto Mandi (ProximityPrompt)
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "automandi_sawahindo"

if not frame then return end

local Players             = game:GetService("Players")
local LocalPlayer         = Players.LocalPlayer
local StarterGui          = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local workspace           = workspace

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
            Title="Auto Mandi",
            Text=msg or "",
            Duration=dur or 3
        })
    end)
end

local mandiList = {}
local selectedIndex = 1

local function rebuildMandi()
    mandiList = {}
    local folder = workspace:FindFirstChild("Mandi")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("BasePart") then
                table.insert(mandiList, m)
            end
        end
    end
    table.sort(mandiList, function(a,b) return a.Name < b.Name end)
    selectedIndex = (#mandiList>0) and 1 or 0
end

rebuildMandi()

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
end

local function getSelectedMandi()
    if #mandiList == 0 or selectedIndex == 0 then return nil end
    return mandiList[selectedIndex]
end

local function getMandiPrompt(mandiPart)
    if not mandiPart then return nil end
    local prompt = mandiPart:FindFirstChildOfClass("ProximityPrompt")
    if prompt then return prompt end
    for _, d in ipairs(mandiPart:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            return d
        end
    end
    return nil
end

local function activatePrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then
        fireproximityprompt(prompt, prompt.HoldDuration)
    else
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0.5) + 0.1)
        prompt:InputHoldEnd()
    end
end

local autoMandi = false

local function autoMandiLoop()
    while running do
        if autoMandi then
            local mandiPart = getSelectedMandi()
            local hrp = getHRP()
            local prompt = getMandiPrompt(mandiPart)

            if mandiPart and hrp and prompt then
                -- teleport dekat mandi
                hrp.CFrame = mandiPart.CFrame + Vector3.new(0,3,0)
                task.wait(0.1)
                activatePrompt(prompt)
            end
        end
        task.wait(2.0)
    end
end

-- UI
local title = Instance.new("TextLabel")
title.Parent = frame
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1,-10,0,24)
title.Position = UDim2.new(0,5,0,5)
title.Text = "TAB 6: Auto Mandi"

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

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Parent = body
selectedLabel.BackgroundTransparency = 1
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextSize = 11
selectedLabel.TextColor3 = Color3.fromRGB(200,200,255)
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Size = UDim2.new(1,0,0,18)
selectedLabel.Text = "Mandi: <kosong>"

local function refreshSelectedLabel()
    if #mandiList == 0 then
        selectedLabel.Text = "Mandi: <tidak ada>"
    else
        selectedLabel.Text = "Mandi: "..mandiList[selectedIndex].Name
    end
end
refreshSelectedLabel()

local function button(text, cb)
    local b = Instance.new("TextButton")
    b.Parent = body
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
end

local function toggle(text, initial, cb)
    local b = button("", nil)
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
end

button("Refresh Mandi1-6", function()
    rebuildMandi()
    refreshSelectedLabel()
    notify("Mandi ditemukan: "..tostring(#mandiList),2)
end)

button("Ganti Mandi (Cycle)", function()
    if #mandiList == 0 then
        notify("Mandi tidak ditemukan.",2)
        return
    end
    selectedIndex = selectedIndex + 1
    if selectedIndex > #mandiList then selectedIndex = 1 end
    refreshSelectedLabel()
end)

button("Teleport Now (Manual Mandi)", function()
    local m = getSelectedMandi()
    local hrp = getHRP()
    if m and hrp then
        hrp.CFrame = m.CFrame + Vector3.new(0,3,0)
    end
end)

toggle("AutoMandi", autoMandi, function(state)
    autoMandi = state
end)

task.spawn(autoMandiLoop)

_G.AxaHub.TabCleanup[tabId] = function()
    running = false
    frame:ClearAllChildren()
    for _,c in ipairs(connections) do
        pcall(function()
            if c and c.Disconnect then c:Disconnect() end
        end)
    end
    connections = {}
end

print("[18AxaTab_AutoMandi] Loaded.")