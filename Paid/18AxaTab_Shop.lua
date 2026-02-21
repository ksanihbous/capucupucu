--==========================================================
--  18AxaTab_Shop.lua
--  TAB 3: Info Shop Tools (ToolShopConfig)
--==========================================================

local frame = TAB_FRAME
local tabId = TAB_ID or "shop_sawahindo"

if not frame then return end

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = Remotes:WaitForChild("TutorialRemotes")

local NPC_ALAT = Vector3.new(-39.97, 49.76, -181.19)

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
            Title = "Sawah Shop",
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

-- ToolShopConfig
local ToolShopConfig = nil
pcall(function()
    local mod = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ToolShopConfig")
    ToolShopConfig = require(mod)
end)

local toolsList = {}
local caps = {}

local function refreshTools()
    if not ToolShopConfig then return end
    toolsList = {}
    caps = ToolShopConfig.Caps or {}

    if ToolShopConfig.GetSortedTools then
        for _, t in ipairs(ToolShopConfig.GetSortedTools()) do
            table.insert(toolsList, t)
        end
    elseif ToolShopConfig.Tools then
        for _, t in ipairs(ToolShopConfig.Tools) do
            table.insert(toolsList, t)
        end
    end
end

refreshTools()

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
    title.Text = "TAB 3: Tool Shop Info"

    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = frame
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0,5,0,32)
    scroll.Size = UDim2.new(1,-10,1,-37)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 4
    scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

    local pad = Instance.new("UIPadding")
    pad.Parent = scroll
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingBottom = UDim.new(0,4)
    pad.PaddingLeft = UDim.new(0,2)
    pad.PaddingRight = UDim.new(0,2)

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
    layout.Padding = UDim.new(0,4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

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

--==========================================================
-- BUILD UI
--==========================================================

local body = createMainLayout()

do
    local top = card(body)

    makeButton(top, "Refresh Data ToolShopConfig", function()
        refreshTools()
        notify("Refresh ToolShopConfig: "..tostring(#toolsList).." tools", 2)
    end)

    makeButton(top, "Teleport ke NPC Alat", function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(NPC_ALAT + Vector3.new(0,3,0))
        end
    end)

    local capsText = "Caps:\n"
    if caps.MaxXPFlat then capsText = capsText .. " - MaxXPFlat: "..tostring(caps.MaxXPFlat).."\n" end
    if caps.MaxGrowthReduction then capsText = capsText .. " - MaxGrowthReduction: "..tostring(caps.MaxGrowthReduction).."\n" end
    if caps.MaxHarvestSpeed then capsText = capsText .. " - MaxHarvestSpeed: "..tostring(caps.MaxHarvestSpeed).."\n" end
    if caps.AutoCollectRadius then capsText = capsText .. " - AutoCollectRadius: "..tostring(caps.AutoCollectRadius).."\n" end
    if caps.RainDuration then capsText = capsText .. " - RainDuration: "..tostring(caps.RainDuration).."\n" end
    if caps.RainCooldown then capsText = capsText .. " - RainCooldown: "..tostring(caps.RainCooldown).."\n" end

    local capsLbl = Instance.new("TextLabel")
    capsLbl.Parent = top
    capsLbl.BackgroundTransparency = 1
    capsLbl.Font = Enum.Font.Gotham
    capsLbl.TextSize = 11
    capsLbl.TextColor3 = Color3.fromRGB(200,200,200)
    capsLbl.TextXAlignment = Enum.TextXAlignment.Left
    capsLbl.TextYAlignment = Enum.TextYAlignment.Top
    capsLbl.TextWrapped = true
    capsLbl.Size = UDim2.new(1,0,0,60)
    capsLbl.Text = capsText
end

local toolsCard = card(body)

local function rebuildToolsView()
    toolsCard:ClearAllChildren()
    local layout = Instance.new("UIListLayout")
    layout.Parent = toolsCard
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local data = SyncData(false)
    local ownedTools = (data and data.OwnedTools) or {}

    for _, t in ipairs(toolsList) do
        local row = Instance.new("Frame")
        row.Parent = toolsCard
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1,0,0,48)

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(230,230,230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.TextWrapped = true
        lbl.Size = UDim2.new(1,0,1,0)

        local eff = t.Effects or {}
        local effParts = {}
        if eff.XP_FLAT then table.insert(effParts, "XP+"..eff.XP_FLAT) end
        if eff.GROWTH_REDUCTION then table.insert(effParts, "Grow- "..tostring(eff.GROWTH_REDUCTION)) end
        if eff.HARVEST_SPEED then table.insert(effParts, "HarvestSpeed x"..eff.HARVEST_SPEED) end
        if eff.SLOT_BONUS then table.insert(effParts, "Slot+"..eff.SLOT_BONUS) end
        if eff.AUTO_COLLECT then table.insert(effParts, "AUTO_COLLECT") end
        if eff.RAIN_SUMMON then table.insert(effParts, "RAIN_SUMMON") end
        if eff.UMBRELLA then table.insert(effParts, "UMBRELLA") end
        if eff.KITE then table.insert(effParts, "KITE") end
        if eff.BIKE then table.insert(effParts, "BIKE") end

        local ownedStr = (ownedTools[t.Name] and "Owned") or "Not Owned"
        lbl.Text = string.format(
            "%s [%s]\nPrice: %d | MinLvl: %d | Status: %s\nEffects: %s",
            t.Name or "?",
            t.Tier or "?",
            t.Price or 0,
            t.MinLevel or 0,
            ownedStr,
            (#effParts>0 and table.concat(effParts,", ") or "-")
        )
    end
end

rebuildToolsView()

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

print("[18AxaTab_Shop] Loaded.")