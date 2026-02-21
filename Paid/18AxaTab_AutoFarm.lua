--==========================================================
--  18AxaTab_AutoFarm.lua
--  TAB 1: Auto Farm Sawah (Smart Plant + Auto Panen)
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "autofarm_sawahindo"

if not frame then return end

local Players             = game:GetService("Players")
local LocalPlayer         = Players.LocalPlayer
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local StarterGui          = game:GetService("StarterGui")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UIS                 = game:GetService("UserInputService")
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

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
addConn(LocalPlayer.CharacterAdded:Connect(function(c) character = c end))

local function getHRP()
    local char = character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then
        return hrp
    end
    return nil
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "Sawah AutoFarm",
            Text     = text or "",
            Duration = dur or 3
        })
    end)
end

--==========================================================
-- REMOTES & SYNCDATA
--==========================================================

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = Remotes:WaitForChild("TutorialRemotes")

local RequestShop  = TutorialRemotes:WaitForChild("RequestShop")
local PlantCrop    = TutorialRemotes:WaitForChild("PlantCrop")
local RequestSell  = TutorialRemotes:WaitForChild("RequestSell")

local SyncDataRF   = Remotes:FindFirstChild("SyncData")

local clientBoot = LocalPlayer:FindFirstChild("ClientBoot")
local SafeRemote, GameRemotes

pcall(function()
    if clientBoot then
        SafeRemote  = require(clientBoot.Core.SafeRemote)
        GameRemotes = require(clientBoot.Remotes)
    end
end)

local lastSyncTime  = 0
local cachedSync    = nil

local function SyncData(force)
    local now = tick()
    if not force and cachedSync and now - lastSyncTime < 1 then
        return cachedSync
    end
    lastSyncTime = now

    if SafeRemote and GameRemotes and GameRemotes.SyncData then
        local ok, data = pcall(function()
            return SafeRemote.Invoke(GameRemotes.SyncData)
        end)
        if ok and type(data) == "table" then
            cachedSync = data
            return data
        end
    end

    if SyncDataRF and SyncDataRF:IsA("RemoteFunction") then
        local ok, data = pcall(function()
            return SyncDataRF:InvokeServer()
        end)
        if ok and type(data) == "table" then
            cachedSync = data
            return data
        end
    end
    return cachedSync
end

local function getInventoryCount(name)
    local data = SyncData(false)
    if data and type(data.Inventory) == "table" then
        return data.Inventory[name] or 0
    end
    return 0
end

--==========================================================
-- REMOTE HELPERS
--==========================================================

local RemoteLimiter = {
    Plant   = {Last = 0, Cooldown = 0.06},
    Harvest = {Last = 0, Cooldown = 0.03},
}

local function canFireLimiter(key)
    local cfg = RemoteLimiter[key]
    if not cfg then return true end
    local t = tick()
    if t - cfg.Last >= cfg.Cooldown then
        cfg.Last = t
        return true
    end
    return false
end

local function doPlantAt(pos)
    if not PlantCrop or not pos then return end
    if not canFireLimiter("Plant") then return end
    pcall(function()
        PlantCrop:FireServer(pos)
    end)
end

local function firePrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if not canFireLimiter("Harvest") then return end

    if fireproximityprompt then
        local hold = tonumber(prompt.HoldDuration) or 0
        fireproximityprompt(prompt, hold)
    else
        -- fallback
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0) + 0.1)
        prompt:InputHoldEnd()
    end
end

--==========================================================
-- SMART GRID AREA TANAM
--==========================================================

local AreaFolderName = "AreaTanam"  -- bisa folder "AreaTanam" atau part2 "AreaTanam1-7"

local areaParts   = {}
local selectedIdx = 1
local gridSpacing = 2
local smartGrid   = {}

local manualPlots = {}

local function refreshAreaParts()
    table.clear(areaParts)
    local folder = workspace:FindFirstChild(AreaFolderName)

    if folder and folder:IsA("Folder") then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(areaParts, child)
            end
        end
    else
        -- cari langsung part bernama AreaTanam, AreaTanam2, dst
        for _, inst in ipairs(workspace:GetChildren()) do
            if inst:IsA("BasePart") and inst.Name:match("^AreaTanam") then
                table.insert(areaParts, inst)
            end
        end
    end

    table.sort(areaParts, function(a,b) return a.Name < b.Name end)

    if #areaParts == 0 then
        notify("Sawah AutoFarm", "Tidak menemukan AreaTanam di workspace.", 4)
    end

    if selectedIdx > #areaParts then
        selectedIdx = (#areaParts > 0) and 1 or 0
    end
end

local function buildSmartGrid()
    table.clear(smartGrid)
    local part = areaParts[selectedIdx]
    if not (part and part:IsA("BasePart")) then
        return
    end

    local spacing = math.max(0.5, gridSpacing)
    local size    = part.Size
    local cf      = part.CFrame

    local halfX = size.X * 0.5 - 0.5
    local halfZ = size.Z * 0.5 - 0.5

    -- offset sedikit dari tengah agar rapi
    local startX = -halfX + spacing * 0.5
    local startZ = -halfZ + spacing * 0.5

    for x = startX, halfX - spacing * 0.25, spacing do
        for z = startZ, halfZ - spacing * 0.25, spacing do
            local offset   = Vector3.new(x, size.Y * 0.5 + 0.1, z)
            local worldPos = (cf * CFrame.new(offset)).p
            table.insert(smartGrid, worldPos)
        end
    end
end

local function addManualPlotHere()
    local hrp = getHRP()
    if not hrp then return end
    table.insert(manualPlots, hrp.Position)
end

local function clearManualPlots()
    table.clear(manualPlots)
end

--==========================================================
-- AUTO PLANT LOOP + AUTO HARVEST LOOP
--==========================================================

local autoPlantEnabled   = true
local autoHarvestEnabled = true
local plantSpacingBox    -- UI
local selectedAreaLabel  -- UI

local function getAllPlantPositions()
    local list = {}
    for _, p in ipairs(manualPlots) do
        table.insert(list, p)
    end
    for _, p in ipairs(smartGrid) do
        table.insert(list, p)
    end
    return list
end

local function autoPlantLoop()
    while running do
        if autoPlantEnabled then
            if #areaParts == 0 then
                refreshAreaParts()
                buildSmartGrid()
            end

            local seedCount = getInventoryCount("Bibit Padi")
            if seedCount > 0 then
                local positions = getAllPlantPositions()
                if #positions == 0 then
                    -- jika belum ada grid, build
                    if #areaParts > 0 and selectedIdx > 0 then
                        buildSmartGrid()
                        positions = getAllPlantPositions()
                    end
                end

                for _, pos in ipairs(positions) do
                    if not running or not autoPlantEnabled then break end
                    doPlantAt(pos)
                    task.wait(0.06)
                end
            end
        end
        task.wait(0.5)
    end
end

local function isPanenPrompt(prompt)
    if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled) then
        return false
    end
    local act = (prompt.ActionText or ""):lower()
    local obj = (prompt.ObjectText or ""):lower()
    return act:find("panen") or obj:find("panen")
end

local function autoHarvestLoop()
    while running do
        if autoHarvestEnabled then
            local folder = workspace:FindFirstChild("ActiveCrops")
            if folder then
                local hrp = getHRP()
                for _, inst in ipairs(folder:GetDescendants()) do
                    if not running or not autoHarvestEnabled then break end
                    local prompt
                    if inst:IsA("ProximityPrompt") then
                        prompt = inst
                    elseif inst:IsA("BasePart") then
                        prompt = inst:FindFirstChildOfClass("ProximityPrompt")
                    end
                    if prompt and isPanenPrompt(prompt) then
                        -- pastikan dekat, kalau jauh TP dikit
                        if hrp then
                            local ppPart = prompt.Parent:IsA("BasePart") and prompt.Parent
                                or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                            if ppPart then
                                local dist = (hrp.Position - ppPart.Position).Magnitude
                                if dist > (prompt.MaxActivationDistance or 12) - 1 then
                                    hrp.CFrame = CFrame.new(ppPart.Position + Vector3.new(0, 3, 0))
                                    task.wait(0.05)
                                end
                            end
                        end
                        firePrompt(prompt)
                        task.wait(0.03)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end

--==========================================================
-- UI HELPERS
--==========================================================

local function createMainLayout()
    local header = Instance.new("TextLabel")
    header.Parent = frame
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -10, 0, 24)
    header.Position = UDim2.new(0, 5, 0, 5)
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 18
    header.TextColor3 = Color3.new(1,1,1)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "TAB 1: Auto Farm Sawah Indo"

    local body = Instance.new("Frame")
    body.Parent = frame
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 5, 0, 32)
    body.Size = UDim2.new(1, -10, 1, -37)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = body
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1,0,1,0)
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
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    addConn(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
    end))

    return scroll
end

local function createCard(parent, titleText)
    local card = Instance.new("Frame")
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(20,20,20)
    card.BackgroundTransparency = 0.1
    card.Size = UDim2.new(1,0,0,0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = card

    local padding = Instance.new("UIPadding")
    padding.Parent = card
    padding.PaddingTop = UDim.new(0,6)
    padding.PaddingBottom = UDim.new(0,6)
    padding.PaddingLeft = UDim.new(0,8)
    padding.PaddingRight = UDim.new(0,8)

    local title = Instance.new("TextLabel")
    title.Parent = card
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1,0,0,18)
    title.Text = titleText or "Card"

    local inner = Instance.new("Frame")
    inner.Parent = card
    inner.BackgroundTransparency = 1
    inner.Position = UDim2.new(0,0,0,22)
    inner.Size = UDim2.new(1,0,0,0)
    inner.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = inner
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    return inner
end

local function makeToggle(parent, text, initial, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1,0,0,26)
    btn.BackgroundColor3 = initial and Color3.fromRGB(40,90,50) or Color3.fromRGB(35,35,35)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Text = text .. ": " .. (initial and "ON" or "OFF")

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = btn

    local state = initial and true or false

    addConn(btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(40,90,50) or Color3.fromRGB(35,35,35)
        if callback then
            callback(state)
        end
    end))

    return btn
end

local function makeButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1,0,0,26)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Text = text

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = btn

    addConn(btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end))

    return btn
end

local function makeNumberBox(parent, labelText, defaultValue, callback, minVal, maxVal)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextColor3 = Color3.fromRGB(200,200,200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1,0,0,16)
    label.Text = labelText

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

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = box

    addConn(box.FocusLost:Connect(function()
        local raw = (box.Text or ""):gsub(",", ".")
        local num = tonumber(raw)
        if not num then
            box.Text = tostring(defaultValue)
            return
        end
        num = math.clamp(num, minVal or -1e9, maxVal or 1e9)
        defaultValue = num
        box.Text = tostring(defaultValue)
        if callback then callback(num) end
    end))

    return box
end

--==========================================================
-- BUILD UI
--==========================================================

local function buildUI()
    local body = createMainLayout()

    -- Card Smart Plant
    local c1 = createCard(body, "Smart Plant Bibit (AreaTanam)")
    selectedAreaLabel = Instance.new("TextLabel")
    selectedAreaLabel.Parent = c1
    selectedAreaLabel.BackgroundTransparency = 1
    selectedAreaLabel.Size = UDim2.new(1,0,0,18)
    selectedAreaLabel.Font = Enum.Font.Gotham
    selectedAreaLabel.TextSize = 11
    selectedAreaLabel.TextColor3 = Color3.fromRGB(200,200,255)
    selectedAreaLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedAreaLabel.Text = "AreaTanam: <refresh dulu>"

    makeButton(c1, "Refresh Daftar AreaTanam", function()
        refreshAreaParts()
        if #areaParts > 0 then
            buildSmartGrid()
            selectedAreaLabel.Text = "AreaTanam Aktif: " .. areaParts[selectedIdx].Name ..
                "  | GridPos: " .. tostring(#smartGrid)
        else
            selectedAreaLabel.Text = "AreaTanam: TIDAK ADA"
        end
    end)

    makeButton(c1, "Ganti Area (Cycle)", function()
        if #areaParts == 0 then
            refreshAreaParts()
        end
        if #areaParts == 0 then
            selectedAreaLabel.Text = "AreaTanam: TIDAK ADA"
            return
        end
        selectedIdx = selectedIdx + 1
        if selectedIdx > #areaParts then selectedIdx = 1 end
        buildSmartGrid()
        selectedAreaLabel.Text = "AreaTanam Aktif: " .. areaParts[selectedIdx].Name ..
            "  | GridPos: " .. tostring(#smartGrid)
    end)

    plantSpacingBox = makeNumberBox(
        c1,
        "Jarak Antar Plant (stud, default 2)",
        gridSpacing,
        function(v)
            gridSpacing = math.clamp(v, 0.5, 10)
            buildSmartGrid()
            if #areaParts > 0 and areaParts[selectedIdx] then
                selectedAreaLabel.Text = "AreaTanam Aktif: " .. areaParts[selectedIdx].Name ..
                    "  | GridPos: " .. tostring(#smartGrid)
            end
        end,
        0.5,
        10
    )

    makeToggle(c1, "Auto Plant ALL Posisi", autoPlantEnabled, function(state)
        autoPlantEnabled = state
    end)

    -- Card Manual Plot
    local c2 = createCard(body, "Manual Plot (Tambahan)")
    makeButton(c2, "Record Posisi Saat Ini sebagai Plot", function()
        addManualPlotHere()
        notify("AutoFarm", "Plot manual ditambahkan. Total: "..#manualPlots, 2)
    end)
    makeButton(c2, "Clear Semua Plot Manual", function()
        clearManualPlots()
        notify("AutoFarm", "Semua plot manual dihapus.", 2)
    end)

    -- Card Auto Panen
    local c3 = createCard(body, "Auto Panen Padi (ProximityPrompt)")
    makeToggle(c3, "Auto Panen 'Panen' di ActiveCrops", autoHarvestEnabled, function(state)
        autoHarvestEnabled = state
    end)

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Parent = c3
    infoLabel.BackgroundTransparency = 1
    infoLabel.Size = UDim2.new(1,0,0,32)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.TextColor3 = Color3.fromRGB(180,180,180)
    infoLabel.TextWrapped = true
    infoLabel.Text = "- Scan folder Workspace.ActiveCrops\n- Cari ProximityPrompt ActionText/ObjectText berisi 'Panen'."
end

buildUI()

--==========================================================
-- START LOOPS
--==========================================================

task.spawn(autoPlantLoop)
task.spawn(autoHarvestLoop)

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

print("[18AxaTab_AutoFarm] Loaded.")