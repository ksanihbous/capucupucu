--==========================================================
--  18AxaTab_NPCTeleport.lua
--  TAB 5: Teleport NPC & Mandi
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "npc_sawahindo"

if not frame then return end

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui  = game:GetService("StarterGui")
local workspace   = workspace

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
            Title="NPC Teleport",
            Text=msg or "",
            Duration=dur or 3
        })
    end)
end

-- NPC coords
local NPC_BIBIT           = Vector3.new(-42.70, 49.07, -202.54)
local NPC_SELL            = Vector3.new(-62.00, 49.64, -205.61)
local NPC_ALAT            = Vector3.new(-39.97, 49.76, -181.19)
local NPC_PEDAGANGTELUR   = Vector3.new(-97.74, 49.77, -178.64)
local NPC_PEDAGANGSAWIT   = Vector3.new(55.90, 49.69, -205.92)

local options = {}
local selectedIndex = 1

local function rebuildOptions()
    options = {
        {Name="NPC Bibit", Pos=NPC_BIBIT},
        {Name="NPC Jual Hasil", Pos=NPC_SELL},
        {Name="NPC Alat", Pos=NPC_ALAT},
        {Name="NPC Pedagang Telur", Pos=NPC_PEDAGANGTELUR},
        {Name="NPC Pedagang Sawit", Pos=NPC_PEDAGANGSAWIT},
    }

    local mandiFolder = workspace:FindFirstChild("Mandi")
    if mandiFolder then
        for _, m in ipairs(mandiFolder:GetChildren()) do
            if m:IsA("BasePart") then
                table.insert(options, {
                    Name = "Mandi: "..m.Name,
                    Pos  = m.Position + Vector3.new(0,3,0)
                })
            end
        end
    end
    selectedIndex = (#options > 0) and 1 or 0
end

rebuildOptions()

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
title.Text = "TAB 5: NPC Teleport"

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
selectedLabel.Text = "Target: <kosong>"

local function refreshSelectedLabel()
    if #options == 0 then
        selectedLabel.Text = "Target: <tidak ada opsi>"
    else
        selectedLabel.Text = "Target: "..options[selectedIndex].Name
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

button("Refresh Opsi (NPC + Mandi1-6)", function()
    rebuildOptions()
    refreshSelectedLabel()
    notify("Opsi teleport: "..tostring(#options),2)
end)

button("Ganti Target (Cycle)", function()
    if #options == 0 then
        notify("Belum ada opsi.",2)
        return
    end
    selectedIndex = selectedIndex + 1
    if selectedIndex > #options then selectedIndex = 1 end
    refreshSelectedLabel()
end)

button("Teleport Now", function()
    if #options == 0 then return end
    local target = options[selectedIndex]
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(target.Pos + Vector3.new(0,0,0))
    end
end)

-- Cleanup
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

print("[18AxaTab_NPCTeleport] Loaded.")