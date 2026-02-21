--==========================================================
--  18AxaTab_BuyAreaSawit.lua
--  TAB 7: Buy Area Tanam Besar (Sawit / Palm Land)
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "buyareasawit_sawahindo"

if not frame then return end

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local workspace         = workspace

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = Remotes:WaitForChild("TutorialRemotes")
local RequestLahan    = TutorialRemotes:WaitForChild("RequestLahan")

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
            Title="Buy Area Sawit",
            Text=msg or "",
            Duration=dur or 3
        })
    end)
end

--==========================================================
-- DATA AREA
--==========================================================

local areaList = {}
local selectedIndex = 1

local function guessPriceFromPart(part)
    if not part then return nil end
    local attrPrice = part:GetAttribute("Price") or part:GetAttribute("Cost")
    if attrPrice then return attrPrice end
    -- bisa di-extend: cek ModuleConfig sendiri kalau mau
    return nil
end

local function isOwnedArea(part)
    if not part then return false end
    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        -- kalau tidak ada prompt lagi biasanya sudah owned
        return true
    end
    return not prompt.Enabled
end

local function rebuildAreas()
    areaList = {}
    local folder = workspace:FindFirstChild("AreaTanamBesar")
    if folder and folder:IsA("Folder") then
        for _, p in ipairs(folder:GetChildren()) do
            if p:IsA("BasePart") and p.Name:match("^AreaTanamBesar") then
                table.insert(areaList, p)
            end
        end
    else
        for _, p in ipairs(workspace:GetChildren()) do
            if p:IsA("BasePart") and p.Name:match("^AreaTanamBesar") then
                table.insert(areaList, p)
            end
        end
    end

    table.sort(areaList, function(a,b) return a.Name < b.Name end)
    selectedIndex = (#areaList>0) and 1 or 0
end

rebuildAreas()

local function getSelectedArea()
    if #areaList == 0 or selectedIndex == 0 then return nil end
    return areaList[selectedIndex]
end

local function doBuySelected()
    local part = getSelectedArea()
    if not part then
        notify("Tidak ada AreaTanamBesar yang dipilih.",2)
        return
    end
    local args = {
        "BUY",
        { PartName = part.Name }
    }
    pcall(function()
        RequestLahan:InvokeServer(unpack(args))
    end)
end

--==========================================================
-- UI
--==========================================================

local title = Instance.new("TextLabel")
title.Parent = frame
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1,-10,0,24)
title.Position = UDim2.new(0,5,0,5)
title.Text = "TAB 7: Buy Area Sawit (AreaTanamBesar)"

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

local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = body
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextColor3 = Color3.fromRGB(200,200,255)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Size = UDim2.new(1,0,0,40)
infoLabel.TextWrapped = true

local function refreshInfoLabel()
    local part = getSelectedArea()
    if not part then
        infoLabel.Text = "Area: <tidak ada>. Tekan Refresh."
        return
    end
    local owned = isOwnedArea(part)
    local price = guessPriceFromPart(part)
    infoLabel.Text = string.format(
        "Area: %s\nPrice: %s | Status: %s",
        part.Name,
        price and tostring(price) or "? (tidak terdeteksi, tetap bisa BUY)",
        owned and "Owned" or "Belum Dibeli"
    )
end
refreshInfoLabel()

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

button("Refresh Daftar AreaTanamBesar", function()
    rebuildAreas()
    refreshInfoLabel()
    notify("AreaTanamBesar ditemukan: "..tostring(#areaList),2)
end)

button("Ganti Area (Cycle)", function()
    if #areaList == 0 then
        notify("Tidak ada AreaTanamBesar.",2)
        return
    end
    selectedIndex = selectedIndex + 1
    if selectedIndex > #areaList then selectedIndex = 1 end
    refreshInfoLabel()
end)

button("Buy AreaTanamBesar (Selected)", function()
    local part = getSelectedArea()
    if not part then
        notify("Tidak ada area dipilih.",2)
        return
    end
    doBuySelected()
    task.delay(0.5, function()
        refreshInfoLabel()
    end)
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

print("[18AxaTab_BuyAreaSawit] Loaded.")