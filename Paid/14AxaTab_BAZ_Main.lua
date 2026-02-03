-- 14AxaTab_BAZ_Main.lua
-- TAB 14: Build a Zoo - Peanut X port into AxaHub Panel (Tahoe UI)

---------------------------------------------------------------------
-- ENV & BASIC SETUP
---------------------------------------------------------------------

local frame = TAB_FRAME
local tabId = TAB_ID or "baz_main"

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")

if not (frame and LocalPlayer) then
    return
end

frame:ClearAllChildren()
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0

_G.AxaHub = _G.AxaHub or {}
_G.AxaHub.TabCleanup = _G.AxaHub.TabCleanup or {}

local running     = true
local connections = {}

local function addConnection(conn)
    if conn then
        table.insert(connections, conn)
    end
    return conn
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "Build a Zoo",
            Text     = text or "",
            Duration = dur or 4,
        })
    end)
end

---------------------------------------------------------------------
-- UNIVERSAL CONFIG (ExHub/configuniversal.json)
---------------------------------------------------------------------

local CONFIG_FOLDER      = "ExHub"
local CONFIG_FILE        = CONFIG_FOLDER .. "/configuniversal.json"
local CURRENT_USER_KEY   = LocalPlayer.Name or ("User_" .. tostring(LocalPlayer.UserId or ""))
local allUniversalConfig = nil

local function ensureConfigFolder()
    if makefolder and isfolder then
        local ok, exists = pcall(function()
            return isfolder(CONFIG_FOLDER)
        end)
        if not (ok and exists) then
            pcall(function()
                makefolder(CONFIG_FOLDER)
            end)
        end
    end
end

local function loadUniversalConfigFile()
    if allUniversalConfig ~= nil then
        return allUniversalConfig
    end
    if not (isfile and readfile) then
        allUniversalConfig = {}
        return allUniversalConfig
    end

    local okExists, exists = pcall(function()
        return isfile(CONFIG_FILE)
    end)
    if not (okExists and exists) then
        allUniversalConfig = {}
        return allUniversalConfig
    end

    local okRead, content = pcall(function()
        return readfile(CONFIG_FILE)
    end)
    if not (okRead and type(content) == "string" and content ~= "") then
        allUniversalConfig = {}
        return allUniversalConfig
    end

    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not okDecode or type(data) ~= "table" then
        allUniversalConfig = {}
        return allUniversalConfig
    end

    allUniversalConfig = data
    return allUniversalConfig
end

local function saveUniversalConfigFile()
    if not (writefile and HttpService and allUniversalConfig) then
        return
    end
    ensureConfigFolder()
    local okEncode, encoded = pcall(function()
        return HttpService:JSONEncode(allUniversalConfig)
    end)
    if not (okEncode and type(encoded) == "string") then
        return
    end
    pcall(function()
        writefile(CONFIG_FILE, encoded)
    end)
end

---------------------------------------------------------------------
-- DEFAULT BUILD A ZOO SETTINGS (PEANUT X STYLE)
---------------------------------------------------------------------

local DEFAULT_BAZ_CONFIG = {
    Main = {
        AutoClaimCoins  = false,
        CoinMoveMethod  = "Teleport", -- "Teleport" / "Tween"
        AutoFishing     = false,
        FishBait        = "FishingBait3",
        FishingPos      = nil,        -- stored as {x=,y=,z=} table
        AutoPotion      = false,
        SelectedPotion  = "Potion_Coin",
    },
    Shop = {
        SelectedFruits       = {},
        AutoBuyFruit         = false,
        AutoDestroyFruits    = false,
        SelectedDestroyFruit = "",
        SelectedItem         = "Pet", -- "Pet"/"Egg"/"All"
    },
    Eggs = {
        SelectedEggs          = {},
        SelectedMutations     = {},
        AutoBuyEgg            = false,

        -- Set 2 (belum dipakai di UI, dibiarkan untuk future)
        SelectedEggs2         = {},
        SelectedMutations2    = {},
        AutoBuyEgg2           = false,

        SelectedSellEggs      = {},
        SelectedSellMutations = {},
        AutoSellEgg           = false,
        AutoHatch             = false,
    },
    Pets = {
        AutoTradePet        = false, -- AutoTrade belum di-port (future TAB)
        SelectedPet         = "",
        SelectedFeedFruits  = {},
        AutoFeed            = false,

        SelectedPet2        = "",
        SelectedFeedFruits2 = {},
        AutoFeed2           = false,

        SelectedPet3        = "",
        SelectedFeedFruits3 = {},
        AutoFeed3           = false,
    },
    Events = {
        FishSnow        = false,
        AutoFishingEvent= false,
        AutoEventTasks  = false,
        AutoDinoOnline  = false,
    },
    Player = {
        SelectedPlayer    = "",
        SelectedPlayerId  = nil,
        AutoLike          = false,
        GiftMode          = "Egg",
        SelectedGiftFruit = "",
        SelectedGiftEggs  = {},
        SelectedGiftMutations = {},
        AutoGift          = false,
    },
    Exchange = {
        SelectedExchangeItem = "300K Money",
        AutoExchangeItem     = false,
    },
    Redeem = {
        SelectedCode = "",
    },
    Settings = {
        WalkSpeed        = 29,
        JumpPower        = 9,   -- digunakan sebagai JumpHeight
        FlySpeed         = 50,
        FlyMode          = false,
        NoClip           = false,
        AntiAFK          = false,
        WebhookURL       = "",
        EnableWebhook    = false,
        AutoRejoin       = false,
        AutoRejoinDelay  = 900,
    },
}

_G.BuildAZooSettings = _G.BuildAZooSettings or {}

local function getBazSettings()
    local cfg = loadUniversalConfigFile() or {}
    local userCfg = cfg[CURRENT_USER_KEY]
    if type(userCfg) ~= "table" then
        userCfg = {}
        cfg[CURRENT_USER_KEY] = userCfg
    end

    local baz = userCfg.BuildAZoo
    if type(baz) ~= "table" then
        local ok, copy = pcall(function()
            return HttpService:JSONDecode(HttpService:JSONEncode(DEFAULT_BAZ_CONFIG))
        end)
        baz = ok and copy or DEFAULT_BAZ_CONFIG
        userCfg.BuildAZoo = baz
    end

    allUniversalConfig = cfg
    _G.BuildAZooSettings = baz
    return baz
end

local function saveBazSettings()
    if not allUniversalConfig then
        return
    end
    saveUniversalConfigFile()
end

local Settings = getBazSettings()

---------------------------------------------------------------------
-- PEANUT X ENV & CONSTANT DATA
---------------------------------------------------------------------

getgenv().PeanutX = getgenv().PeanutX or {}
local PX = getgenv().PeanutX

PX.Players           = Players
PX.ReplicatedStorage = ReplicatedStorage
PX.RunService        = RunService
PX.LocalPlayer       = LocalPlayer
PX.TweenService      = TweenService
PX.TeleportService   = TeleportService
PX.userId            = LocalPlayer.UserId

do
    local okPets, petsFolder = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Data"):WaitForChild("Pets")
    end)
    PX.PetsFolder = okPets and petsFolder or nil

    local okEggs, eggsFolder = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Data"):WaitForChild("Egg")
    end)
    PX.EggsFolder = okEggs and eggsFolder or nil
end

local remoteRoot = ReplicatedStorage:FindFirstChild("Remote")
if not remoteRoot then
    -- Kalau buka TAB di game yang salah, kasih info dan keluar
    local label = Instance.new("TextLabel")
    label.Name = "WrongGame"
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -16, 1, -16)
    label.Position = UDim2.new(0, 8, 0, 8)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 100, 100)
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = "[Build a Zoo]\n\nFolder 'Remote' tidak ditemukan.\nPastikan kamu sedang di game **Build a Zoo** sebelum membuka TAB ini."
    return
end

PX.RemoteRoot        = remoteRoot
PX.CharacterRE       = remoteRoot:FindFirstChild("CharacterRE")
PX.FishingRE         = remoteRoot:FindFirstChild("FishingRE")
PX.ShopRE            = remoteRoot:FindFirstChild("ShopRE")
PX.PetRE             = remoteRoot:FindFirstChild("PetRE")
PX.DeployRE          = remoteRoot:FindFirstChild("DeployRE")
PX.DestroyFoodRE     = remoteRoot:FindFirstChild("DestroyFoodRE")
PX.RedemptionCodeRE  = remoteRoot:FindFirstChild("RedemptionCodeRE")
PX.TradeRE           = remoteRoot:FindFirstChild("TradeRE")
PX.DinoEventRE       = remoteRoot:FindFirstChild("DinoEventRE")
PX.FoodStoreRE       = remoteRoot:FindFirstChild("FoodStoreRE")

PX.FruitsList = {
    "Strawberry",
    "Blueberry",
    "Watermelon",
    "Apple",
    "Orange",
    "Corn",
    "Banana",
    "Grape",
    "Pear",
    "Pineapple",
    "DragonFruit",
    "GoldMango",
    "BloodstoneCycad",
    "ColossalPinecone",
    "VoltGinkgo",
    "CandyCorn",
    "DeepseaPearlFruit",
    "Durian",
    "Pumpkin",
    "FrankenKiwi",
}

PX.EggsIDs = {
    ["Anglerfish Egg"]        = "AnglerfishEgg",
    ["Axe Shark Egg"]         = "BiteForceSharkEgg",
    ["Basic Egg"]             = "BasicEgg",
    ["Bone Dragon Egg"]       = "BoneDragonEgg",
    ["Bowser Egg"]            = "BowserEgg",
    ["Corn Egg"]              = "CornEgg",
    ["Dark Goaty Egg"]        = "DarkGoatyEgg",
    ["Demon Egg"]             = "DemonEgg",
    ["Dino Egg"]              = "DinoEgg",
    ["Epic Egg"]              = "EpicEgg",
    ["General Kong Egg"]      = "GeneralKongEgg",
    ["Godzilla Egg"]          = "GodzillaEgg",
    ["Halloween Egg"]         = "HalloweenEgg",
    ["Halloween Capy Egg"]    = "HalloweenCapyEgg",
    ["Hyper Egg"]             = "HyperEgg",
    ["Legend Egg"]            = "LegendEgg",
    ["Lionfish Egg"]          = "LionfishEgg",
    ["Metro Giraffe Egg"]     = "MetroGiraffeEgg",
    ["Octopus Egg"]           = "OctopusEgg",
    ["Pegasus Egg"]           = "PegasusEgg",
    ["Prismatic Egg"]         = "PrismaticEgg",
    ["Rare Egg"]              = "RareEgg",
    ["Rhino Rock Egg"]        = "RhinoRockEgg",
    ["Saber Cub Egg"]         = "SaberCubEgg",
    ["Sailfish Egg"]          = "SailfishEgg",
    ["Shark Egg"]             = "SharkEgg",
    ["Snowbunny Egg"]         = "SnowbunnyEgg",
    ["Super Rare Egg"]        = "SuperRareEgg",
    ["Ultra Egg"]             = "UltraEgg",
    ["Unicorn Egg"]           = "UnicornEgg",
    ["Unicorn Pro Egg"]       = "UnicornProEgg",
    ["Void Egg"]              = "VoidEgg",
}

PX.EggsList = {
    "Anglerfish Egg",
    "Axe Shark Egg",
    "Basic Egg",
    "Bone Dragon Egg",
    "Bowser Egg",
    "Corn Egg",
    "Dark Goaty Egg",
    "Demon Egg",
    "Dino Egg",
    "Epic Egg",
    "General Kong Egg",
    "Godzilla Egg",
    "Halloween Egg",
    "Halloween Capy Egg",
    "Hyper Egg",
    "Legend Egg",
    "Lionfish Egg",
    "Metro Giraffe Egg",
    "Octopus Egg",
    "Pegasus Egg",
    "Prismatic Egg",
    "Rare Egg",
    "Rhino Rock Egg",
    "Saber Cub Egg",
    "Sailfish Egg",
    "Shark Egg",
    "Snowbunny Egg",
    "Super Rare Egg",
    "Ultra Egg",
    "Unicorn Egg",
    "Unicorn Pro Egg",
    "Void Egg",
}

PX.MutationsList = {
    "None",
    "Golden",
    "Diamond",
    "Electirc",
    "Fire",
    "Dino",
    "Snow",
    "Halloween",
}

PX.RedeemCodes = {
    "ADQZP3MBW6N",
    "subtoZRGZeRoGhost",
    "Nyaa",
    "druscxlla",
    "DS5523YSQ3C",
    "Bunnsterss",
    "3XKK8Z2WB6G",
    "N7A68Q82H83",
    "4XW5RG4CHRY",
    "60KCCU919",
}

PX.ExchangeItems = {
    ["300K Money"]                = "GS_Item_1",
    ["Rainbow Potion"]            = "GS_Item_19",
    ["Pear"]                      = "GS_Item_2",
    ["Bloodstone Cycad"]          = "GS_Item_3",
    ["Pineapple"]                 = "GS_Item_4",
    ["Dragon Fruit"]              = "GS_Item_5",
    ["Gold Mango"]                = "GS_Item_6",
    ["[Snow] Kaiju Egg"]          = "GS_Item_7",
    ["[Halloween] General Kong Egg"] = "GS_Item_8",
    ["[Dino] Unicorn Pro Egg"]    = "GS_Item_9",
    ["[Dino] General Kong Egg"]   = "GS_Item_21",
    ["Halloween Home Board"]      = "GS_Item_20",
    ["Deepsea Pearl Fruit"]       = "GS_Item_10",
    ["Colossal Pinecone"]         = "GS_Item_11",
    ["Candy Corn"]                = "GS_Item_12",
    ["Durian"]                    = "GS_Item_13",
    ["Volt Ginkgo"]               = "GS_Item_14",
    ["Pumpkin"]                   = "GS_Item_15",
    ["Franken Kiwi"]              = "GS_Item_22",
}

PX.IslandName      = ""
PX.EggName         = "Unknown"
PX.EggMutate       = "None"
PX.FlyConnection   = nil
PX.FlyGyro         = nil
PX.FlyVel          = nil
PX.NoClipConnection= nil
PX._ClaimVisited   = {}

---------------------------------------------------------------------
-- SMALL HELPERS
---------------------------------------------------------------------

local function listContains(list, value)
    if not list then
        return false
    end
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then
        return nil, nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 then
        return hum, hrp
    end
    return nil, nil
end

---------------------------------------------------------------------
-- PETS & EGGS INFO TEXT
---------------------------------------------------------------------

local function buildPetsInfoText()
    local folder = PX.PetsFolder
    if not folder then
        return "Pets data folder tidak ditemukan."
    end

    local summary = {}
    for _, pet in ipairs(folder:GetChildren()) do
        local t = pet:GetAttribute("T") or "Unknown"
        local m = pet:GetAttribute("M") or "Normal"
        local key = t .. "_" .. m
        if not summary[key] then
            summary[key] = {
                type     = t,
                mutation = m,
                count    = 0,
            }
        end
        summary[key].count = summary[key].count + 1
    end

    if next(summary) == nil then
        return "Tidak ada pet di inventory."
    end

    local arr = {}
    for _, info in pairs(summary) do
        table.insert(arr, info)
    end
    table.sort(arr, function(a, b)
        return a.type < b.type
    end)

    local lines = {}
    for _, info in ipairs(arr) do
        table.insert(lines, string.format("[%s] %s = %d", info.mutation, info.type, info.count))
    end
    return table.concat(lines, "\n")
end

local function buildEggsInfoText()
    local folder = PX.EggsFolder
    if not folder then
        return "Egg data folder tidak ditemukan."
    end

    local summary = {}
    for _, egg in ipairs(folder:GetChildren()) do
        -- di script asli: hanya egg yang belum menetas (#children == 0)
        if #egg:GetChildren() == 0 then
            local t = egg:GetAttribute("T") or "Unknown"
            local m = egg:GetAttribute("M") or "Normal"
            local key = t .. "_" .. m
            if not summary[key] then
                summary[key] = {
                    type     = t,
                    mutation = m,
                    count    = 0,
                }
            end
            summary[key].count = summary[key].count + 1
        end
    end

    if next(summary) == nil then
        return "Tidak ada egg di inventory."
    end

    local arr = {}
    for _, info in pairs(summary) do
        table.insert(arr, info)
    end
    table.sort(arr, function(a, b)
        return a.type < b.type
    end)

    local lines = {}
    for _, info in ipairs(arr) do
        table.insert(lines, string.format("[%s] %s x%d", info.mutation, info.type, info.count))
    end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------
-- CORE LOGIC: COINS, FISHING, POTION, FRUITS, EGGS, EVENTS, PLAYER
---------------------------------------------------------------------

-----------------------
-- AUTO CLAIM COINS
-----------------------

local function autoClaimCoinsStep()
    if not Settings.Main.AutoClaimCoins then
        return
    end

    local petsFolder = workspace:FindFirstChild("Pets")
    if not petsFolder then
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    PX._ClaimVisited = PX._ClaimVisited or {}
    local userId = LocalPlayer.UserId

    local closest
    local closestDist = math.huge

    for _, coin in ipairs(petsFolder:GetChildren()) do
        if coin:IsA("BasePart") and coin:GetAttribute("UserId") == userId and not PX._ClaimVisited[coin] then
            local dist = (hrp.Position - coin.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = coin
            end
        end
    end

    if not closest then
        PX._ClaimVisited = {}
        return
    end

    local targetPos = closest.Position
    local destCFrame = CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    local method = Settings.Main.CoinMoveMethod or "Teleport"

    if method == "Tween" then
        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
            { CFrame = destCFrame }
        )
        tween:Play()
        pcall(function()
            tween.Completed:Wait()
        end)
    else
        hrp.CFrame = destCFrame
    end

    PX._ClaimVisited[closest] = true
end

-----------------------
-- FISHING CORE
-----------------------

local function getFishingPosCFrame()
    local posData = Settings.Main.FishingPos
    if type(posData) == "table" and posData.x and posData.y and posData.z then
        local pos = Vector3.new(posData.x, posData.y, posData.z)
        return CFrame.new(pos)
    end
    return nil
end

local function doFishingCast(worldPos)
    local charRE   = PX.CharacterRE
    local fishingRE= PX.FishingRE
    if not (charRE and fishingRE) then
        return
    end

    local bait = Settings.Main.FishBait or "FishingBait3"

    pcall(function()
        charRE:FireServer("Focus", "FishRob")
        task.wait(0.5)
        fishingRE:FireServer("Start")
        task.wait(0.5)
        fishingRE:FireServer("Throw", {
            Bait = bait,
            Pos  = worldPos,
        })
        task.wait(0.5)
        fishingRE:FireServer("POUT", { SUC = 1 })
    end)
end

local function autoFishingStep()
    if not Settings.Main.AutoFishing then
        return
    end

    local cf = getFishingPosCFrame()
    if not cf then
        Settings.Main.AutoFishing = false
        saveBazSettings()
        notify("Build a Zoo", "Simpan Fishing Position dulu sebelum Auto Fishing.", 3)
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    hrp.CFrame = cf
    hrp.Anchored = true

    doFishingCast(cf.Position)

    -- lepas anchor pelan-pelan supaya nggak ke-lock kalau tab di-off
    task.delay(2, function()
        if not running then
            return
        end
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChild("HumanoidRootPart")
            if h then
                h.Anchored = false
            end
        end
    end)
end

-----------------------
-- POTION
-----------------------

local function usePotionOnce()
    pcall(function()
        if PX.ShopRE then
            PX.ShopRE:FireServer("UsePotion", Settings.Main.SelectedPotion or "Potion_Coin")
        end
    end)
end

-----------------------
-- ISLAND & EGGS
-----------------------

local function updateIslandName()
    if PX.IslandName ~= "" then
        return
    end

    local art = workspace:FindFirstChild("Art")
    if not art then
        return
    end

    for _, plot in ipairs(art:GetChildren()) do
        local ownerId = plot:GetAttribute("OccupyingPlayerId")
        if ownerId and ownerId == PX.userId then
            PX.IslandName = plot.Name
            break
        end
    end
end

local function findEggNode(eggNamesList, mutationList)
    updateIslandName()
    if PX.IslandName == "" then
        return nil
    end

    local eggsFolder = ReplicatedStorage:FindFirstChild("Eggs")
    if not eggsFolder then
        return nil
    end

    local islandFolder = eggsFolder:FindFirstChild(PX.IslandName)
    if not islandFolder then
        return nil
    end

    local allowedTypes = {}
    for _, displayName in ipairs(eggNamesList or {}) do
        local id = PX.EggsIDs[displayName]
        if id then
            allowedTypes[id] = true
        else
            allowedTypes[displayName] = true
        end
    end

    local allowedMut = {}
    for _, mut in ipairs(mutationList or {}) do
        allowedMut[mut] = true
    end

    local bestEggName = nil
    local bestMut = "None"
    local bestNode = nil

    for _, node in ipairs(islandFolder:GetChildren()) do
        local t = node:GetAttribute("T")
        local m = node:GetAttribute("M") or "None"
        if t and (next(allowedTypes) == nil or allowedTypes[t]) then
            if next(allowedMut) == nil or allowedMut[m] or (allowedMut["None"] and m == "None") then
                bestNode    = node
                bestEggName = t
                bestMut     = m
                break
            end
        end
    end

    if bestNode then
        PX.EggName   = bestEggName or "Unknown"
        PX.EggMutate = bestMut or "None"
        return bestNode.Name
    end

    return nil
end

-----------------------
-- WEBHOOK LOG EGG
-----------------------

local function logEggWebhook()
    if not Settings.Settings.EnableWebhook then
        return
    end

    local url = Settings.Settings.WebhookURL or ""
    if url == "" or string.sub(url, 1, 4) ~= "http" then
        notify("Webhook Error", "URL webhook tidak valid.", 3)
        return
    end

    if PX.EggName == "Unknown" then
        return
    end

    local mut = PX.EggMutate or "None"
    local color =
        (mut == "Golden"   and 16766720) or
        (mut == "Diamond"  and 11993087) or
        (mut == "Fire"     and 16711680) or
        (mut == "Snow"     and 16777215) or
        (mut == "Halloween"and 16744192) or
        ((mut == "Electric" or mut == "Electirc") and 16776960) or
        3447003

    local embed = {
        embeds = {
            {
                title       = "NEW EGG ACQUIRED",
                description = "**" .. LocalPlayer.Name .. "** bought a new egg!",
                color       = color,
                fields = {
                    { name = " Egg Type",  value = "**`" .. tostring(PX.EggName) .. "`**", inline = true },
                    { name = " Mutation",  value = "**`" .. tostring(PX.EggMutate) .. "`**", inline = true },
                    { name = " Player",    value = "`" .. LocalPlayer.Name .. "`", inline = true },
                    { name = " User ID",   value = "`" .. tostring(LocalPlayer.UserId) .. "`", inline = true },
                    { name = " Time",      value = "`" .. os.date("%Y-%m-%d %H:%M:%S") .. "`", inline = false },
                },
                footer = {
                    text = "Peanut X • Build a Zoo",
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }
        },
        username   = "Peanut X Logger",
        avatar_url = "https://i.postimg.cc/05KMwhzz/20250818-104205.jpg",
    }

    local body = HttpService:JSONEncode(embed)
    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request

    if not requestFn then
        return
    end

    pcall(function()
        requestFn({
            Url     = url,
            Method  = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body    = body,
        })
    end)
end

-----------------------
-- BUY & SELL HELPERS
-----------------------

local function buyFruitsOnce()
    if not PX.FoodStoreRE then
        return
    end
    for _, fruitName in ipairs(Settings.Shop.SelectedFruits or {}) do
        pcall(function()
            PX.FoodStoreRE:FireServer(fruitName)
        end)
    end
end

local function destroyFruitOnce()
    local fruitName = Settings.Shop.SelectedDestroyFruit
    if not (fruitName and fruitName ~= "") then
        return
    end
    if not PX.CharacterRE or not PX.DestroyFoodRE then
        return
    end
    pcall(function()
        PX.CharacterRE:FireServer("Focus", fruitName)
        task.wait(0.2)
        PX.DestroyFoodRE:FireServer("Destroy")
    end)
end

local function sellItemsOnce()
    if not PX.PetRE then
        return
    end
    local itemType = Settings.Shop.SelectedItem or "Pet"
    pcall(function()
        if itemType == "All" then
            PX.PetRE:FireServer("SellAll", "All", "All")
        else
            PX.PetRE:FireServer("SellAll", "All", itemType)
        end
    end)
end

local function sellEggsOnce()
    if not (PX.PetRE and PX.EggsFolder) then
        return
    end

    local selectedEggs = {}
    for _, displayName in ipairs(Settings.Eggs.SelectedSellEggs or {}) do
        local id = PX.EggsIDs[displayName]
        if id then
            selectedEggs[id] = true
        else
            selectedEggs[displayName] = true
        end
    end

    local selectedMut = Settings.Eggs.SelectedSellMutations or {}
    local function mutationAllowed(m)
        if #selectedMut == 0 then
            return true
        end
        for _, mut in ipairs(selectedMut) do
            if mut == "None" and m == "None" then
                return true
            end
            if mut ~= "None" and m == mut then
                return true
            end
        end
        return false
    end

    local sold = 0

    for _, egg in ipairs(PX.EggsFolder:GetChildren()) do
        local t = egg:GetAttribute("T") or ""
        local m = egg:GetAttribute("M") or "None"
        if selectedEggs[t] and mutationAllowed(m) then
            local ok, err = pcall(function()
                PX.PetRE:FireServer("Sell", egg.Name, true)
            end)
            if ok then
                sold = sold + 1
            else
                warn("[BuildAZoo] Sell egg failed:", err)
            end
        end
    end

    if sold > 0 then
        notify("Auto Sell Eggs", "Berhasil menjual " .. sold .. " egg.", 3)
    end

    return sold
end

local function autoBuyEggsStep()
    if not Settings.Eggs.AutoBuyEgg then
        return
    end

    local nodeName = findEggNode(Settings.Eggs.SelectedEggs, Settings.Eggs.SelectedMutations)
    if not nodeName then
        return
    end

    logEggWebhook()

    if not PX.CharacterRE then
        return
    end

    pcall(function()
        PX.CharacterRE:FireServer("BuyEgg", nodeName)
    end)
end

local function autoHatchFromBlocksOnce()
    local builtBlocks = workspace:FindFirstChild("PlayerBuiltBlocks")
    if not builtBlocks then
        return
    end
    local uid = LocalPlayer.UserId
    local remotes = {}

    for _, block in ipairs(builtBlocks:GetChildren()) do
        if block:GetAttribute("UserId") == uid then
            local exMark = block:FindFirstChild("ExclamationMark")
            local root   = block:FindFirstChild("RootPart")
            if exMark and root then
                local rf = root:FindFirstChild("RF")
                if rf and rf:IsA("RemoteFunction") then
                    table.insert(remotes, rf)
                end
            end
        end
    end

    for _, rf in ipairs(remotes) do
        task.spawn(function()
            pcall(function()
                rf:InvokeServer("Hatch")
            end)
        end)
        task.wait(0.05)
    end
end

-----------------------
-- EVENTS
-----------------------

local function claimEventTasksOnce()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then
        return
    end
    local data = gui:FindFirstChild("Data")
    if not data then
        return
    end
    local dinoData = data:FindFirstChild("DinoEventTaskData")
    if not dinoData then
        return
    end
    local tasks = dinoData:FindFirstChild("Tasks")
    if not tasks then
        return
    end
    if not PX.DinoEventRE then
        return
    end

    local ids = {}
    for _, t in ipairs(tasks:GetChildren()) do
        local id = t:GetAttribute("Id")
        if id then
            table.insert(ids, id)
        end
    end

    for _, id in ipairs(ids) do
        pcall(function()
            PX.DinoEventRE:FireServer({
                {
                    event = "claimreward",
                    id    = id,
                },
            })
        end)
        task.wait(0.5)
    end
end

local function claimDinoOnlineOnce()
    if not PX.DinoEventRE then
        return
    end
    pcall(function()
        PX.DinoEventRE:FireServer({
            {
                event = "onlinepack",
            },
        })
    end)
end

local function autoFishSnowStep()
    if not Settings.Events.FishSnow then
        return
    end

    local fishPoints = workspace:FindFirstChild("FishPoints")
    if not fishPoints then
        return
    end

    local snowScope = nil
    for _, point in ipairs(fishPoints:GetChildren()) do
        local fx = point:FindFirstChild("FX_Fish_Special")
        if fx then
            local scope = fx:FindFirstChild("Scope")
            if scope then
                snowScope = scope
                break
            end
        end
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:FindFirstChild("HumanoidRootPart")

    if snowScope and hrp then
        local pos = snowScope.Position + Vector3.new(0, 2, 0)
        hrp.CFrame = CFrame.new(pos, pos + snowScope.CFrame.LookVector)
        hrp.Anchored = true
        doFishingCast(pos)
    elseif hrp then
        -- snow hilang → respawn supaya normal lagi
        hrp.Anchored = false
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        else
            char:BreakJoints()
        end
    end
end

local function autoFishEventStep()
    if not Settings.Events.AutoFishingEvent then
        return
    end

    local fishPoints = workspace:FindFirstChild("FishPoints")
    if not fishPoints then
        return
    end
    local fp1 = fishPoints:FindFirstChild("FishPoint1")
    if not fp1 then
        return
    end
    local fx = fp1:FindFirstChild("FX_Fish_Special_Wait")
    if not fx then
        return
    end
    local center = fx:FindFirstChild("Center")
    if not center then
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    hrp.CFrame  = center.CFrame + Vector3.new(0, 4, 0)
    hrp.Anchored = true

    doFishingCast(hrp.Position)
end

-----------------------
-- PLAYER, EXCHANGE, REDEEM
-----------------------

local function getOtherPlayersList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, string.format("%s (%d)", plr.Name, plr.UserId))
        end
    end
    return list
end

local function likePlotOnce()
    if not (PX.CharacterRE and Settings.Player.SelectedPlayerId) then
        return
    end
    pcall(function()
        PX.CharacterRE:FireServer("GiveLike", Settings.Player.SelectedPlayerId)
    end)
end

local function exchangeItemOnce()
    if not (PX.TradeRE and PX.ExchangeItems) then
        return
    end
    local itemName = Settings.Exchange.SelectedExchangeItem
    local id = PX.ExchangeItems[itemName]
    if not id then
        return
    end
    pcall(function()
        PX.TradeRE:FireServer({
            {
                event = "exchange",
                id    = id,
            },
        })
    end)
end

local function redeemCodeOnce(code)
    if not (PX.RedemptionCodeRE and code and code ~= "") then
        return
    end
    pcall(function()
        PX.RedemptionCodeRE:FireServer({
            {
                event = "usecode",
                code  = code,
            },
        })
    end)
end

local function redeemAllCodesOnce()
    if #PX.RedeemCodes == 0 then
        notify("Redeem", "Tidak ada kode yang tersedia.", 4)
        return
    end
    for _, code in ipairs(PX.RedeemCodes) do
        redeemCodeOnce(code)
        task.wait(1)
    end
    notify("Redeem", "Semua kode sudah dicoba/redeem.", 4)
end

-----------------------
-- MOVEMENT, FLY, NOCLIP, ANTI AFK, AUTOREJOIN
-----------------------

local function applyWalkSpeed()
    local hum = select(1, getHumanoid())
    if not hum then
        return
    end
    local ws = tonumber(Settings.Settings.WalkSpeed) or 29
    ws = math.clamp(ws, 1, 250)
    hum.WalkSpeed = ws
end

local function applyJump()
    local hum = select(1, getHumanoid())
    if not hum then
        return
    end
    local j = tonumber(Settings.Settings.JumpPower) or 9
    j = math.clamp(j, 1, 250)
    hum.UseJumpPower = false
    hum.JumpHeight   = j
end

local function startFly()
    if PX.FlyConnection then
        return
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local hum  = char:WaitForChild("Humanoid")

    hum.PlatformStand = true

    local gyro = Instance.new("BodyGyro")
    gyro.P         = 90000
    gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    gyro.CFrame    = hrp.CFrame
    gyro.Parent    = hrp

    local vel = Instance.new("BodyVelocity")
    vel.Velocity = Vector3.new(0, 0, 0)
    vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    vel.Parent   = hrp

    PX.FlyGyro = gyro
    PX.FlyVel  = vel

    PX.FlyConnection = RunService.Heartbeat:Connect(function()
        if not (running and Settings.Settings.FlyMode) then
            return
        end
        if not (hrp.Parent and hum.Parent) then
            return
        end

        local moveDir = hum.MoveDirection
        local cam     = workspace.CurrentCamera
        if not cam then
            return
        end

        local look  = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local speed = Settings.Settings.FlySpeed or 50
        local dir   = (look * moveDir:Dot(look) + right * moveDir:Dot(right)) * speed

        PX.FlyVel.Velocity = dir
        PX.FlyGyro.CFrame  = CFrame.new(hrp.Position, hrp.Position + Vector3.new(look.X, 0, look.Z))
    end)
end

local function stopFly()
    if PX.FlyConnection then
        pcall(function()
            PX.FlyConnection:Disconnect()
        end)
        PX.FlyConnection = nil
    end
    if PX.FlyGyro then
        pcall(function()
            PX.FlyGyro:Destroy()
        end)
        PX.FlyGyro = nil
    end
    if PX.FlyVel then
        pcall(function()
            PX.FlyVel:Destroy()
        end)
        PX.FlyVel = nil
    end

    local hum = select(1, getHumanoid())
    if hum then
        hum.PlatformStand = false
    end
end

local function setNoClip(enabled)
    Settings.Settings.NoClip = enabled
    if enabled then
        if PX.NoClipConnection then
            PX.NoClipConnection:Disconnect()
        end
        PX.NoClipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then
                return
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if PX.NoClipConnection then
            PX.NoClipConnection:Disconnect()
            PX.NoClipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Anti AFK
addConnection(LocalPlayer.Idled:Connect(function()
    if Settings.Settings.AntiAFK and VirtualUser then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- Auto Rejoin helper
local function findLowPopulationServer()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not (ok and body) then
        return nil
    end
    local data = HttpService:JSONDecode(body)
    if not data or not data.data then
        return nil
    end

    table.sort(data.data, function(a, b)
        return (a.playing or 0) < (b.playing or 0)
    end)

    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId then
            return server.id
        end
    end

    return nil
end

---------------------------------------------------------------------
-- BIG PET & AUTO FEED
---------------------------------------------------------------------

local function hasPetUID(uid)
    if not (PX.PetsFolder and uid) then
        return false
    end
    return PX.PetsFolder:FindFirstChild(uid) ~= nil
end

local function getBigPetCandidates()
    local folder = PX.PetsFolder
    if not folder then
        return {}
    end

    local names = {}

    for _, pet in ipairs(folder:GetChildren()) do
        local bpv  = pet:GetAttribute("BPV")
        local bpsk = pet:GetAttribute("BPSK")
        local t    = pet:GetAttribute("T")
        if bpv then
            local display = bpsk or t
            if display then
                table.insert(names, display)
            end
        end
    end

    table.sort(names, function(a, b)
        return a < b
    end)

    return names
end

local function assignBigPetSlot(slotIndex, displayName)
    if not (PX.PetsFolder and displayName) then
        return
    end

    local key = (slotIndex == 1 and "SelectedPet")
        or (slotIndex == 2 and "SelectedPet2")
        or "SelectedPet3"

    for _, pet in ipairs(PX.PetsFolder:GetChildren()) do
        if pet:GetAttribute("BPV") then
            local disp = pet:GetAttribute("BPSK") or pet:GetAttribute("T")
            if disp == displayName then
                Settings.Pets[key] = pet.Name
                saveBazSettings()
                return
            end
        end
    end
end

local function autoFeedSlotLoop(slotIndex)
    local petKey, fruitsKey, toggleKey
    if slotIndex == 1 then
        petKey    = "SelectedPet"
        fruitsKey = "SelectedFeedFruits"
        toggleKey = "AutoFeed"
    elseif slotIndex == 2 then
        petKey    = "SelectedPet2"
        fruitsKey = "SelectedFeedFruits2"
        toggleKey = "AutoFeed2"
    else
        petKey    = "SelectedPet3"
        fruitsKey = "SelectedFeedFruits3"
        toggleKey = "AutoFeed3"
    end

    while running do
        local cfg = Settings.Pets
        if cfg[toggleKey] then
            local petUID     = cfg[petKey]
            local fruitsList = cfg[fruitsKey] or {}
            if petUID ~= "" and hasPetUID(petUID) and #fruitsList > 0 then
                for _, uid in ipairs(fruitsList) do
                    if not cfg[toggleKey] or not running then
                        break
                    end
                    pcall(function()
                        if PX.DeployRE then
                            PX.DeployRE:FireServer({
                                event = "deploy",
                                uid   = uid,
                            })
                        end
                    end)
                    task.wait(0.5)
                    pcall(function()
                        if PX.CharacterRE then
                            PX.CharacterRE:FireServer("Focus", uid)
                        end
                    end)
                    task.wait(0.5)
                    pcall(function()
                        if PX.PetRE then
                            PX.PetRE:FireServer("Feed", petUID)
                        end
                    end)
                    task.wait(1)
                end
                -- cooldown antar sesi feed
                local cooldown = 30
                local t0 = tick()
                while running and cfg[toggleKey] and (tick() - t0 < cooldown) do
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end

---------------------------------------------------------------------
-- UI HELPERS (TAHOE STYLE)
---------------------------------------------------------------------

local function createMainLayout()
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = frame
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Position = UDim2.new(0, 8, 0, 8)
    header.Size = UDim2.new(1, -16, 0, 46)

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header

    local headerStroke = Instance.new("UIStroke")
    headerStroke.Thickness = 1
    headerStroke.Color = Color3.fromRGB(70, 70, 70)
    headerStroke.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Position = UDim2.new(0, 14, 0, 4)
    title.Size = UDim2.new(1, -28, 0, 20)
    title.Text = "Build a Zoo - Peanut X (AxaHub Port)"

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Parent = header
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitle.Position = UDim2.new(0, 14, 0, 22)
    subtitle.Size = UDim2.new(1, -28, 0, 18)
    subtitle.Text = "Farm, Eggs, Pets, Events, Player, Settings – tanpa window luar."

    local bodyScroll = Instance.new("ScrollingFrame")
    bodyScroll.Name = "BodyScroll"
    bodyScroll.Parent = frame
    bodyScroll.BackgroundTransparency = 1
    bodyScroll.BorderSizePixel = 0
    bodyScroll.Position = UDim2.new(0, 8, 0, 62)
    bodyScroll.Size = UDim2.new(1, -16, 1, -70)
    bodyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    bodyScroll.ScrollBarThickness = 4
    bodyScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    bodyScroll.ClipsDescendants = true

    local padding = Instance.new("UIPadding")
    padding.Parent = bodyScroll
    padding.PaddingTop    = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout")
    layout.Parent = bodyScroll
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 8)

    addConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        bodyScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end))

    return header, bodyScroll
end

local function createCard(parent, titleText, subtitleText, layoutOrder)
    local card = Instance.new("Frame")
    card.Name = titleText or "Card"
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.LayoutOrder = layoutOrder or 1
    card.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 70, 70)
    stroke.Thickness = 1
    stroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.Parent = card
    padding.PaddingTop    = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft   = UDim.new(0, 10)
    padding.PaddingRight  = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = card
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText or "Card"
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Size = UDim2.new(1, 0, 0, 18)

    local yOffset = 20

    if subtitleText and subtitleText ~= "" then
        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.Parent = card
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextSize = 12
        subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextWrapped = true
        subtitle.Text = subtitleText
        subtitle.Position = UDim2.new(0, 0, 0, 20)
        subtitle.Size = UDim2.new(1, 0, 0, 26)
        yOffset = 48
    end

    return card, yOffset
end

local function setToggleButtonState(button, labelText, state)
    if not button then
        return
    end
    labelText = labelText or "Toggle"
    if state then
        button.Text = labelText .. ": ON"
        button.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
    else
        button.Text = labelText .. ": OFF"
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end
end

local function createToggleButton(parent, labelText, initialState)
    local button = Instance.new("TextButton")
    button.Name = (labelText or "Toggle"):gsub("%s+", "") .. "Button"
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.Size = UDim2.new(1, 0, 0, 30)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    setToggleButtonState(button, labelText, initialState)
    return button
end

---------------------------------------------------------------------
-- BUILD UI CARDS
---------------------------------------------------------------------

local header, bodyScroll = createMainLayout()

-----------------------
-- INFO CARD
-----------------------

local function buildInfoCard()
    local card, y = createCard(
        bodyScroll,
        "Info - Inventory",
        "Ringkasan pet & egg langsung dari data player.",
        1
    )

    local container = Instance.new("Frame")
    container.Name = "InfoContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    local petsLabel = Instance.new("TextLabel")
    petsLabel.Name = "PetsInfo"
    petsLabel.Parent = container
    petsLabel.BackgroundTransparency = 1
    petsLabel.Font = Enum.Font.Gotham
    petsLabel.TextSize = 12
    petsLabel.TextXAlignment = Enum.TextXAlignment.Left
    petsLabel.TextYAlignment = Enum.TextYAlignment.Top
    petsLabel.TextWrapped = true
    petsLabel.Size = UDim2.new(1, 0, 0, 60)
    petsLabel.AutomaticSize = Enum.AutomaticSize.Y
    petsLabel.TextColor3 = Color3.fromRGB(210, 210, 255)
    petsLabel.Text = "Memuat data pets..."

    local eggsLabel = Instance.new("TextLabel")
    eggsLabel.Name = "EggsInfo"
    eggsLabel.Parent = container
    eggsLabel.BackgroundTransparency = 1
    eggsLabel.Font = Enum.Font.Gotham
    eggsLabel.TextSize = 12
    eggsLabel.TextXAlignment = Enum.TextXAlignment.Left
    eggsLabel.TextYAlignment = Enum.TextYAlignment.Top
    eggsLabel.TextWrapped = true
    eggsLabel.Size = UDim2.new(1, 0, 0, 60)
    eggsLabel.AutomaticSize = Enum.AutomaticSize.Y
    eggsLabel.TextColor3 = Color3.fromRGB(210, 255, 210)
    eggsLabel.Text = "Memuat data eggs..."

    task.spawn(function()
        while running do
            pcall(function()
                petsLabel.Text = buildPetsInfoText()
                eggsLabel.Text = buildEggsInfoText()
            end)
            task.wait(2.5)
        end
    end)
end

-----------------------
-- FARM CARD (Coins + Fishing + Potion + AutoHatch)
-----------------------

local function buildFarmCard()
    local card, y = createCard(
        bodyScroll,
        "Farm - Coins & Fishing",
        "Auto claim coins, auto fishing, auto potion, auto hatch.",
        2
    )

    local container = Instance.new("Frame")
    container.Name = "FarmContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    -- Coin Method (Teleport / Tween)
    local coinMethodButton = Instance.new("TextButton")
    coinMethodButton.Name = "CoinMethodButton"
    coinMethodButton.Parent = container
    coinMethodButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    coinMethodButton.BorderSizePixel  = 0
    coinMethodButton.AutoButtonColor  = true
    coinMethodButton.Font             = Enum.Font.Gotham
    coinMethodButton.TextSize         = 11
    coinMethodButton.TextColor3       = Color3.fromRGB(220, 220, 220)
    coinMethodButton.TextWrapped      = true
    coinMethodButton.Size             = UDim2.new(1, 0, 0, 26)

    local coinMethodCorner = Instance.new("UICorner")
    coinMethodCorner.CornerRadius = UDim.new(0, 8)
    coinMethodCorner.Parent = coinMethodButton

    local coinMethods = { "Teleport", "Tween" }
    local coinMethodIndex = 1
    for i, v in ipairs(coinMethods) do
        if v == Settings.Main.CoinMoveMethod then
            coinMethodIndex = i
            break
        end
    end

    local function refreshCoinMethodText()
        local mode = coinMethods[coinMethodIndex]
        Settings.Main.CoinMoveMethod = mode
        coinMethodButton.Text = "Coin Method: " .. mode
        saveBazSettings()
    end
    refreshCoinMethodText()

    addConnection(coinMethodButton.MouseButton1Click:Connect(function()
        coinMethodIndex = coinMethodIndex + 1
        if coinMethodIndex > #coinMethods then
            coinMethodIndex = 1
        end
        refreshCoinMethodText()
    end))

    -- Auto Coins
    local autoCoinsButton = createToggleButton(container, "Auto Coins", Settings.Main.AutoClaimCoins)
    addConnection(autoCoinsButton.MouseButton1Click:Connect(function()
        Settings.Main.AutoClaimCoins = not Settings.Main.AutoClaimCoins
        setToggleButtonState(autoCoinsButton, "Auto Coins", Settings.Main.AutoClaimCoins)
        saveBazSettings()
    end))

    -- Auto Hatch (PlayerBuiltBlocks)
    local autoHatchButton = createToggleButton(container, "Auto Hatch Blocks", Settings.Eggs.AutoHatch)
    addConnection(autoHatchButton.MouseButton1Click:Connect(function()
        Settings.Eggs.AutoHatch = not Settings.Eggs.AutoHatch
        setToggleButtonState(autoHatchButton, "Auto Hatch Blocks", Settings.Eggs.AutoHatch)
        saveBazSettings()
    end))

    -- Save Fishing Pos
    local savePosButton = Instance.new("TextButton")
    savePosButton.Name = "SaveFishingPosButton"
    savePosButton.Parent = container
    savePosButton.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    savePosButton.BorderSizePixel  = 0
    savePosButton.AutoButtonColor  = true
    savePosButton.Font             = Enum.Font.GothamSemibold
    savePosButton.TextSize         = 12
    savePosButton.TextColor3       = Color3.fromRGB(230, 230, 255)
    savePosButton.Text             = "Save Fishing Position (pakai posisi sekarang)"
    savePosButton.Size             = UDim2.new(1, 0, 0, 30)

    local savePosCorner = Instance.new("UICorner")
    savePosCorner.CornerRadius = UDim.new(0, 8)
    savePosCorner.Parent = savePosButton

    addConnection(savePosButton.MouseButton1Click:Connect(function()
        local _, hrp = getHumanoid()
        if not hrp then
            notify("Fishing Position", "HumanoidRootPart tidak ditemukan.", 3)
            return
        end
        local p = hrp.Position
        Settings.Main.FishingPos = { x = p.X, y = p.Y, z = p.Z }
        saveBazSettings()
        notify("Fishing Position", "Posisi fishing disimpan.", 2)
    end))

    -- Bait selector (cycle)
    local baitButton = Instance.new("TextButton")
    baitButton.Name = "BaitButton"
    baitButton.Parent = container
    baitButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    baitButton.BorderSizePixel  = 0
    baitButton.AutoButtonColor  = true
    baitButton.Font             = Enum.Font.Gotham
    baitButton.TextSize         = 11
    baitButton.TextColor3       = Color3.fromRGB(220, 220, 220)
    baitButton.TextWrapped      = true
    baitButton.Size             = UDim2.new(1, 0, 0, 26)

    local baitCorner = Instance.new("UICorner")
    baitCorner.CornerRadius = UDim.new(0, 8)
    baitCorner.Parent = baitButton

    local baitList = { "FishingBait1", "FishingBait2", "FishingBait3" }
    local baitIndex = 1
    for i, v in ipairs(baitList) do
        if v == Settings.Main.FishBait then
            baitIndex = i
            break
        end
    end
    local function refreshBaitText()
        local bait = baitList[baitIndex]
        Settings.Main.FishBait = bait
        baitButton.Text = "Fishing Bait: " .. bait
        saveBazSettings()
    end
    refreshBaitText()

    addConnection(baitButton.MouseButton1Click:Connect(function()
        baitIndex = baitIndex + 1
        if baitIndex > #baitList then
            baitIndex = 1
        end
        refreshBaitText()
    end))

    -- Auto Fish
    local autoFishButton = createToggleButton(container, "Auto Fish", Settings.Main.AutoFishing)
    addConnection(autoFishButton.MouseButton1Click:Connect(function()
        Settings.Main.AutoFishing = not Settings.Main.AutoFishing
        setToggleButtonState(autoFishButton, "Auto Fish", Settings.Main.AutoFishing)
        saveBazSettings()
        if Settings.Main.AutoFishing and not Settings.Main.FishingPos then
            notify("Auto Fish", "Simpan Fishing Position dulu.", 3)
        end
    end))

    -- Potion selector
    local potionButton = Instance.new("TextButton")
    potionButton.Name = "PotionButton"
    potionButton.Parent = container
    potionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    potionButton.BorderSizePixel  = 0
    potionButton.AutoButtonColor  = true
    potionButton.Font             = Enum.Font.Gotham
    potionButton.TextSize         = 11
    potionButton.TextColor3       = Color3.fromRGB(220, 220, 220)
    potionButton.TextWrapped      = true
    potionButton.Size             = UDim2.new(1, 0, 0, 26)

    local potionCorner = Instance.new("UICorner")
    potionCorner.CornerRadius = UDim.new(0, 8)
    potionCorner.Parent = potionButton

    local potionList = {
        "Potion_Luck",
        "Potion_Coin",
        "Potion_Hatch",
        "Potion_3in1",
    }
    local potionIndex = 1
    for i, v in ipairs(potionList) do
        if v == Settings.Main.SelectedPotion then
            potionIndex = i
            break
        end
    end
    local function refreshPotionText()
        local pName = potionList[potionIndex]
        Settings.Main.SelectedPotion = pName
        potionButton.Text = "Potion: " .. pName
        saveBazSettings()
    end
    refreshPotionText()

    addConnection(potionButton.MouseButton1Click:Connect(function()
        potionIndex = potionIndex + 1
        if potionIndex > #potionList then
            potionIndex = 1
        end
        refreshPotionText()
    end))

    -- Auto Potion
    local autoPotionButton = createToggleButton(container, "Auto Potion (5 menit)", Settings.Main.AutoPotion)
    addConnection(autoPotionButton.MouseButton1Click:Connect(function()
        Settings.Main.AutoPotion = not Settings.Main.AutoPotion
        setToggleButtonState(autoPotionButton, "Auto Potion (5 menit)", Settings.Main.AutoPotion)
        saveBazSettings()
    end))
end

-----------------------
-- SHOP CARD (Fruits + Sell Items)
-----------------------

local function buildShopCard()
    local card, y = createCard(
        bodyScroll,
        "Shop - Fruits & Sell",
        "Pilih buah untuk dibeli/dihancurkan, dan tipe item untuk dijual.",
        3
    )

    local container = Instance.new("Frame")
    container.Name = "ShopContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    -- Fruits selection
    local fruitsLabel = Instance.new("TextLabel")
    fruitsLabel.Name = "FruitsLabel"
    fruitsLabel.Parent = container
    fruitsLabel.BackgroundTransparency = 1
    fruitsLabel.Font = Enum.Font.GothamSemibold
    fruitsLabel.TextSize = 12
    fruitsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fruitsLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    fruitsLabel.Size = UDim2.new(1, 0, 0, 18)
    fruitsLabel.Text = "Buah untuk Auto Buy / Destroy:"

    local fruitsContainer = Instance.new("Frame")
    fruitsContainer.Name = "FruitsContainer"
    fruitsContainer.Parent = container
    fruitsContainer.BackgroundTransparency = 1
    fruitsContainer.BorderSizePixel = 0
    fruitsContainer.Size = UDim2.new(1, 0, 0, 0)
    fruitsContainer.AutomaticSize = Enum.AutomaticSize.Y

    local fruitsLayout = Instance.new("UIListLayout")
    fruitsLayout.Parent = fruitsContainer
    fruitsLayout.FillDirection = Enum.FillDirection.Vertical
    fruitsLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    fruitsLayout.Padding       = UDim.new(0, 4)

    local fruitFlags = {}
    for _, name in ipairs(Settings.Shop.SelectedFruits or {}) do
        fruitFlags[name] = true
    end

    local function rebuildSelectedFruits()
        Settings.Shop.SelectedFruits = {}
        for _, fname in ipairs(PX.FruitsList) do
            if fruitFlags[fname] then
                table.insert(Settings.Shop.SelectedFruits, fname)
            end
        end
        saveBazSettings()
    end

    for _, fname in ipairs(PX.FruitsList) do
        local btn = createToggleButton(fruitsContainer, fname, fruitFlags[fname] == true)
        addConnection(btn.MouseButton1Click:Connect(function()
            fruitFlags[fname] = not fruitFlags[fname]
            setToggleButtonState(btn, fname, fruitFlags[fname])
            rebuildSelectedFruits()
        end))
    end

    -- Auto Buy Fruits
    local autoFruitButton = createToggleButton(container, "Auto Buy Fruits (60s)", Settings.Shop.AutoBuyFruit)
    addConnection(autoFruitButton.MouseButton1Click:Connect(function()
        Settings.Shop.AutoBuyFruit = not Settings.Shop.AutoBuyFruit
        setToggleButtonState(autoFruitButton, "Auto Buy Fruits (60s)", Settings.Shop.AutoBuyFruit)
        saveBazSettings()
    end))

    -- Destroy Fruit selection (single)
    local destroyButton = Instance.new("TextButton")
    destroyButton.Name = "DestroyFruitButton"
    destroyButton.Parent = container
    destroyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    destroyButton.BorderSizePixel  = 0
    destroyButton.AutoButtonColor  = true
    destroyButton.Font             = Enum.Font.Gotham
    destroyButton.TextSize         = 11
    destroyButton.TextColor3       = Color3.fromRGB(220, 220, 220)
    destroyButton.TextWrapped      = true
    destroyButton.Size             = UDim2.new(1, 0, 0, 26)

    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 8)
    destroyCorner.Parent = destroyButton

    local destroyIndex = 1
    for i, v in ipairs(PX.FruitsList) do
        if v == Settings.Shop.SelectedDestroyFruit then
            destroyIndex = i
            break
        end
    end

    local function refreshDestroyText()
        local name = PX.FruitsList[destroyIndex]
        Settings.Shop.SelectedDestroyFruit = name
        destroyButton.Text = "Destroy Fruit: " .. name
        saveBazSettings()
    end
    refreshDestroyText()

    addConnection(destroyButton.MouseButton1Click:Connect(function()
        destroyIndex = destroyIndex + 1
        if destroyIndex > #PX.FruitsList then
            destroyIndex = 1
        end
        refreshDestroyText()
    end))

    -- Auto Destroy Fruit
    local autoDestroyButton = createToggleButton(container, "Auto Destroy Fruit", Settings.Shop.AutoDestroyFruits)
    addConnection(autoDestroyButton.MouseButton1Click:Connect(function()
        Settings.Shop.AutoDestroyFruits = not Settings.Shop.AutoDestroyFruits
        setToggleButtonState(autoDestroyButton, "Auto Destroy Fruit", Settings.Shop.AutoDestroyFruits)
        saveBazSettings()
    end))

    -- Item Type (Sell Items)
    local itemTypeButton = Instance.new("TextButton")
    itemTypeButton.Name = "ItemTypeButton"
    itemTypeButton.Parent = container
    itemTypeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemTypeButton.BorderSizePixel  = 0
    itemTypeButton.AutoButtonColor  = true
    itemTypeButton.Font             = Enum.Font.Gotham
    itemTypeButton.TextSize         = 11
    itemTypeButton.TextColor3       = Color3.fromRGB(220, 220, 220)
    itemTypeButton.TextWrapped      = true
    itemTypeButton.Size             = UDim2.new(1, 0, 0, 26)

    local itemTypeCorner = Instance.new("UICorner")
    itemTypeCorner.CornerRadius = UDim.new(0, 8)
    itemTypeCorner.Parent = itemTypeButton

    local itemTypes = { "All", "Pet", "Egg" }
    local itemTypeIndex = 1
    for i, v in ipairs(itemTypes) do
        if v == Settings.Shop.SelectedItem then
            itemTypeIndex = i
            break
        end
    end

    local function refreshItemTypeText()
        local t = itemTypes[itemTypeIndex]
        Settings.Shop.SelectedItem = t
        itemTypeButton.Text = "Sell Item Type: " .. t
        saveBazSettings()
    end
    refreshItemTypeText()

    addConnection(itemTypeButton.MouseButton1Click:Connect(function()
        itemTypeIndex = itemTypeIndex + 1
        if itemTypeIndex > #itemTypes then
            itemTypeIndex = 1
        end
        refreshItemTypeText()
    end))

    -- Sell Items now
    local sellBtn = Instance.new("TextButton")
    sellBtn.Name = "SellItemsButton"
    sellBtn.Parent = container
    sellBtn.BackgroundColor3 = Color3.fromRGB(80, 35, 35)
    sellBtn.BorderSizePixel  = 0
    sellBtn.AutoButtonColor  = true
    sellBtn.Font             = Enum.Font.GothamSemibold
    sellBtn.TextSize         = 12
    sellBtn.TextColor3       = Color3.fromRGB(255, 230, 230)
    sellBtn.Text             = "Sell Items Sekarang"
    sellBtn.Size             = UDim2.new(1, 0, 0, 30)

    local sellCorner = Instance.new("UICorner")
    sellCorner.CornerRadius = UDim.new(0, 8)
    sellCorner.Parent = sellBtn

    addConnection(sellBtn.MouseButton1Click:Connect(function()
        sellItemsOnce()
        notify("Sell Items", "Perintah jual " .. (Settings.Shop.SelectedItem or "All") .. " dikirim.", 2)
    end))
end

-----------------------
-- EGGS CARD (Set 1 + Sell Filter)
-----------------------

local function buildEggsCard()
    local card, y = createCard(
        bodyScroll,
        "Eggs - Buy & Sell",
        "Set 1 untuk Auto Buy + filter Auto Sell Eggs.",
        4
    )

    local container = Instance.new("Frame")
    container.Name = "EggsContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    --------------------------------------------------
    -- Egg Set 1 (Buy)
    --------------------------------------------------
    local set1Title = Instance.new("TextLabel")
    set1Title.Name = "Set1Title"
    set1Title.Parent = container
    set1Title.BackgroundTransparency = 1
    set1Title.Font = Enum.Font.GothamSemibold
    set1Title.TextSize = 12
    set1Title.TextXAlignment = Enum.TextXAlignment.Left
    set1Title.TextColor3 = Color3.fromRGB(200, 220, 255)
    set1Title.Size = UDim2.new(1, 0, 0, 18)
    set1Title.Text = "Egg Set 1 - Auto Buy"

    local eggs1Container = Instance.new("Frame")
    eggs1Container.Name = "EggsSet1"
    eggs1Container.Parent = container
    eggs1Container.BackgroundTransparency = 1
    eggs1Container.BorderSizePixel = 0
    eggs1Container.Size = UDim2.new(1, 0, 0, 0)
    eggs1Container.AutomaticSize = Enum.AutomaticSize.Y

    local eggs1Layout = Instance.new("UIListLayout")
    eggs1Layout.Parent = eggs1Container
    eggs1Layout.FillDirection = Enum.FillDirection.Vertical
    eggs1Layout.SortOrder     = Enum.SortOrder.LayoutOrder
    eggs1Layout.Padding       = UDim.new(0, 4)

    local egg1Flags = {}
    for _, name in ipairs(Settings.Eggs.SelectedEggs or {}) do
        egg1Flags[name] = true
    end

    local function rebuildEggSet1()
        Settings.Eggs.SelectedEggs = {}
        for _, name in ipairs(PX.EggsList) do
            if egg1Flags[name] then
                table.insert(Settings.Eggs.SelectedEggs, name)
            end
        end
        saveBazSettings()
    end

    for _, name in ipairs(PX.EggsList) do
        local btn = createToggleButton(eggs1Container, name, egg1Flags[name] == true)
        addConnection(btn.MouseButton1Click:Connect(function()
            egg1Flags[name] = not egg1Flags[name]
            setToggleButtonState(btn, name, egg1Flags[name])
            rebuildEggSet1()
        end))
    end

    local mutLabel1 = Instance.new("TextLabel")
    mutLabel1.Name = "MutLabel1"
    mutLabel1.Parent = container
    mutLabel1.BackgroundTransparency = 1
    mutLabel1.Font = Enum.Font.GothamSemibold
    mutLabel1.TextSize = 12
    mutLabel1.TextXAlignment = Enum.TextXAlignment.Left
    mutLabel1.TextColor3 = Color3.fromRGB(220, 220, 255)
    mutLabel1.Size = UDim2.new(1, 0, 0, 18)
    mutLabel1.Text = "Mutations (Set 1):"

    local mut1Container = Instance.new("Frame")
    mut1Container.Name = "MutSet1"
    mut1Container.Parent = container
    mut1Container.BackgroundTransparency = 1
    mut1Container.BorderSizePixel = 0
    mut1Container.Size = UDim2.new(1, 0, 0, 0)
    mut1Container.AutomaticSize = Enum.AutomaticSize.Y

    local mut1Layout = Instance.new("UIListLayout")
    mut1Layout.Parent = mut1Container
    mut1Layout.FillDirection = Enum.FillDirection.Vertical
    mut1Layout.SortOrder     = Enum.SortOrder.LayoutOrder
    mut1Layout.Padding       = UDim.new(0, 4)

    local mut1Flags = {}
    for _, m in ipairs(Settings.Eggs.SelectedMutations or {}) do
        mut1Flags[m] = true
    end

    local function rebuildMutSet1()
        Settings.Eggs.SelectedMutations = {}
        for _, m in ipairs(PX.MutationsList) do
            if mut1Flags[m] then
                table.insert(Settings.Eggs.SelectedMutations, m)
            end
        end
        saveBazSettings()
    end

    for _, m in ipairs(PX.MutationsList) do
        local btn = createToggleButton(mut1Container, m, mut1Flags[m] == true)
        addConnection(btn.MouseButton1Click:Connect(function()
            mut1Flags[m] = not mut1Flags[m]
            setToggleButtonState(btn, m, mut1Flags[m])
            rebuildMutSet1()
        end))
    end

    local autoBuyEggBtn = createToggleButton(container, "Auto Buy Eggs (Set 1)", Settings.Eggs.AutoBuyEgg)
    addConnection(autoBuyEggBtn.MouseButton1Click:Connect(function()
        Settings.Eggs.AutoBuyEgg = not Settings.Eggs.AutoBuyEgg
        setToggleButtonState(autoBuyEggBtn, "Auto Buy Eggs (Set 1)", Settings.Eggs.AutoBuyEgg)
        saveBazSettings()
    end))

    --------------------------------------------------
    -- Sell Filter
    --------------------------------------------------
    local sellTitle = Instance.new("TextLabel")
    sellTitle.Name = "SellTitle"
    sellTitle.Parent = container
    sellTitle.BackgroundTransparency = 1
    sellTitle.Font = Enum.Font.GothamSemibold
    sellTitle.TextSize = 12
    sellTitle.TextXAlignment = Enum.TextXAlignment.Left
    sellTitle.TextColor3 = Color3.fromRGB(200, 230, 200)
    sellTitle.Size = UDim2.new(1, 0, 0, 18)
    sellTitle.Text = "Filter Sell Eggs"

    local sellEggsContainer = Instance.new("Frame")
    sellEggsContainer.Name = "SellEggsSet"
    sellEggsContainer.Parent = container
    sellEggsContainer.BackgroundTransparency = 1
    sellEggsContainer.BorderSizePixel = 0
    sellEggsContainer.Size = UDim2.new(1, 0, 0, 0)
    sellEggsContainer.AutomaticSize = Enum.AutomaticSize.Y

    local sellEggsLayout = Instance.new("UIListLayout")
    sellEggsLayout.Parent = sellEggsContainer
    sellEggsLayout.FillDirection = Enum.FillDirection.Vertical
    sellEggsLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    sellEggsLayout.Padding       = UDim.new(0, 4)

    local sellEggFlags = {}
    for _, name in ipairs(Settings.Eggs.SelectedSellEggs or {}) do
        sellEggFlags[name] = true
    end

    local function rebuildSellEggsList()
        Settings.Eggs.SelectedSellEggs = {}
        for _, name in ipairs(PX.EggsList) do
            if sellEggFlags[name] then
                table.insert(Settings.Eggs.SelectedSellEggs, name)
            end
        end
        saveBazSettings()
    end

    for _, name in ipairs(PX.EggsList) do
        local btn = createToggleButton(sellEggsContainer, name, sellEggFlags[name] == true)
        addConnection(btn.MouseButton1Click:Connect(function()
            sellEggFlags[name] = not sellEggFlags[name]
            setToggleButtonState(btn, name, sellEggFlags[name])
            rebuildSellEggsList()
        end))
    end

    local sellMutLabel = Instance.new("TextLabel")
    sellMutLabel.Name = "SellMutLabel"
    sellMutLabel.Parent = container
    sellMutLabel.BackgroundTransparency = 1
    sellMutLabel.Font = Enum.Font.GothamSemibold
    sellMutLabel.TextSize = 12
    sellMutLabel.TextXAlignment = Enum.TextXAlignment.Left
    sellMutLabel.TextColor3 = Color3.fromRGB(200, 230, 200)
    sellMutLabel.Size = UDim2.new(1, 0, 0, 18)
    sellMutLabel.Text = "Mutations to Sell:"

    local sellMutContainer = Instance.new("Frame")
    sellMutContainer.Name = "SellMutContainer"
    sellMutContainer.Parent = container
    sellMutContainer.BackgroundTransparency = 1
    sellMutContainer.BorderSizePixel = 0
    sellMutContainer.Size = UDim2.new(1, 0, 0, 0)
    sellMutContainer.AutomaticSize = Enum.AutomaticSize.Y

    local sellMutLayout = Instance.new("UIListLayout")
    sellMutLayout.Parent = sellMutContainer
    sellMutLayout.FillDirection = Enum.FillDirection.Vertical
    sellMutLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    sellMutLayout.Padding       = UDim.new(0, 4)

    local sellMutFlags = {}
    for _, m in ipairs(Settings.Eggs.SelectedSellMutations or {}) do
        sellMutFlags[m] = true
    end

    local function rebuildSellMutList()
        Settings.Eggs.SelectedSellMutations = {}
        for _, m in ipairs(PX.MutationsList) do
            if sellMutFlags[m] then
                table.insert(Settings.Eggs.SelectedSellMutations, m)
            end
        end
        saveBazSettings()
    end

    for _, m in ipairs(PX.MutationsList) do
        local btn = createToggleButton(sellMutContainer, m, sellMutFlags[m] == true)
        addConnection(btn.MouseButton1Click:Connect(function()
            sellMutFlags[m] = not sellMutFlags[m]
            setToggleButtonState(btn, m, sellMutFlags[m])
            rebuildSellMutList()
        end))
    end

    local sellNowBtn = Instance.new("TextButton")
    sellNowBtn.Name = "SellFilteredEggsButton"
    sellNowBtn.Parent = container
    sellNowBtn.BackgroundColor3 = Color3.fromRGB(80, 35, 35)
    sellNowBtn.BorderSizePixel  = 0
    sellNowBtn.AutoButtonColor  = true
    sellNowBtn.Font             = Enum.Font.GothamSemibold
    sellNowBtn.TextSize         = 12
    sellNowBtn.TextColor3       = Color3.fromRGB(255, 230, 230)
    sellNowBtn.Text             = "Sell Filtered Eggs Sekarang"
    sellNowBtn.Size             = UDim2.new(1, 0, 0, 30)

    local sellNowCorner = Instance.new("UICorner")
    sellNowCorner.CornerRadius = UDim.new(0, 8)
    sellNowCorner.Parent = sellNowBtn

    addConnection(sellNowBtn.MouseButton1Click:Connect(function()
        local sold = sellEggsOnce() or 0
        notify("Sell Eggs", "Terjual " .. sold .. " egg.", 3)
    end))

    local autoSellBtn = createToggleButton(container, "Auto Sell Eggs (2s)", Settings.Eggs.AutoSellEgg)
    addConnection(autoSellBtn.MouseButton1Click:Connect(function()
        Settings.Eggs.AutoSellEgg = not Settings.Eggs.AutoSellEgg
        setToggleButtonState(autoSellBtn, "Auto Sell Eggs (2s)", Settings.Eggs.AutoSellEgg)
        saveBazSettings()
    end))
end

-----------------------
-- PETS CARD (Big Pet & Auto Feed)
-----------------------

local function buildPetsCard()
    local card, y = createCard(
        bodyScroll,
        "Pets - Big Pets & Feed",
        "Pilih Big Pet + buah untuk auto feed. Auto Trade belum di-port (nantinya TAB terpisah).",
        5
    )

    local container = Instance.new("Frame")
    container.Name = "PetsContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    -- Refresh candidate list
    local bigPetNames = getBigPetCandidates()

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Name = "RefreshBigPetsButton"
    refreshBtn.Parent = container
    refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    refreshBtn.BorderSizePixel  = 0
    refreshBtn.AutoButtonColor  = true
    refreshBtn.Font             = Enum.Font.GothamSemibold
    refreshBtn.TextSize         = 12
    refreshBtn.TextColor3       = Color3.fromRGB(230, 255, 230)
    refreshBtn.Text             = "Refresh Big Pet List"
    refreshBtn.Size             = UDim2.new(1, 0, 0, 30)

    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshBtn

    local function doRefreshBigPets()
        bigPetNames = getBigPetCandidates()
        if #bigPetNames == 0 then
            notify("Big Pets", "Tidak ada Big Pet dengan atribut BPV.", 3)
        else
            notify("Big Pets", "List Big Pet diperbarui. (" .. #bigPetNames .. ")", 2)
        end
    end

    addConnection(refreshBtn.MouseButton1Click:Connect(doRefreshBigPets))

    -- Helper cycle button per slot
    local function buildBigPetSlotUI(slotIndex, titleText, petKey)
        local btn = Instance.new("TextButton")
        btn.Name = "BigPet"..slotIndex.."Button"
        btn.Parent = container
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = true
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 11
        btn.TextColor3       = Color3.fromRGB(220, 220, 220)
        btn.TextWrapped      = true
        btn.Size             = UDim2.new(1, 0, 0, 26)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local idx = 0

        local function currentDisplay()
            local uid = Settings.Pets[petKey]
            if not (uid and uid ~= "" and PX.PetsFolder) then
                return "None"
            end
            local pet = PX.PetsFolder:FindFirstChild(uid)
            if not pet then
                return "None"
            end
            return pet:GetAttribute("BPSK") or pet:GetAttribute("T") or uid
        end

        local function refreshText()
            btn.Text = titleText .. ": " .. currentDisplay()
        end
        refreshText()

        addConnection(btn.MouseButton1Click:Connect(function()
            if #bigPetNames == 0 then
                doRefreshBigPets()
                if #bigPetNames == 0 then
                    return
                end
            end
            idx = idx + 1
            if idx > #bigPetNames then
                idx = 1
            end
            local selectedName = bigPetNames[idx]
            assignBigPetSlot(slotIndex, selectedName)
            refreshText()
        end))

        return btn
    end

    buildBigPetSlotUI(1, "Big Pet 1", "SelectedPet")
    buildBigPetSlotUI(2, "Big Pet 2", "SelectedPet2")
    buildBigPetSlotUI(3, "Big Pet 3", "SelectedPet3")

    -- Fruits selectors per slot
    local function buildFeedFruitsUI(slotIndex, titleText, fruitsKey, toggleKey)
        local label = Instance.new("TextLabel")
        label.Name = "FeedLabel"..slotIndex
        label.Parent = container
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(200, 255, 200)
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Text = titleText

        local fruitsContainer = Instance.new("Frame")
        fruitsContainer.Name = "FeedFruits"..slotIndex
        fruitsContainer.Parent = container
        fruitsContainer.BackgroundTransparency = 1
        fruitsContainer.BorderSizePixel = 0
        fruitsContainer.Size = UDim2.new(1, 0, 0, 0)
        fruitsContainer.AutomaticSize = Enum.AutomaticSize.Y

        local layout = Instance.new("UIListLayout")
        layout.Parent = fruitsContainer
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder     = Enum.SortOrder.LayoutOrder
        layout.Padding       = UDim.new(0, 4)

        local flags = {}
        for _, name in ipairs(Settings.Pets[fruitsKey] or {}) do
            flags[name] = true
        end

        local function rebuild()
            Settings.Pets[fruitsKey] = {}
            for _, name in ipairs(PX.FruitsList) do
                if flags[name] then
                    table.insert(Settings.Pets[fruitsKey], name)
                end
            end
            saveBazSettings()
        end

        for _, name in ipairs(PX.FruitsList) do
            local btn = createToggleButton(fruitsContainer, name, flags[name] == true)
            addConnection(btn.MouseButton1Click:Connect(function()
                flags[name] = not flags[name]
                setToggleButtonState(btn, name, flags[name])
                rebuild()
            end))
        end

        local autoBtn = createToggleButton(container, "Auto Feed "..titleText, Settings.Pets[toggleKey])
        addConnection(autoBtn.MouseButton1Click:Connect(function()
            Settings.Pets[toggleKey] = not Settings.Pets[toggleKey]
            setToggleButtonState(autoBtn, "Auto Feed "..titleText, Settings.Pets[toggleKey])
            saveBazSettings()
        end))
    end

    buildFeedFruitsUI(1, "Big Pet 1", "SelectedFeedFruits", "AutoFeed")
    buildFeedFruitsUI(2, "Big Pet 2", "SelectedFeedFruits2", "AutoFeed2")
    buildFeedFruitsUI(3, "Big Pet 3", "SelectedFeedFruits3", "AutoFeed3")
end

-----------------------
-- EVENTS CARD
-----------------------

local function buildEventsCard()
    local card, y = createCard(
        bodyScroll,
        "Events",
        "Snow fishing, event fishing, event tasks, dan online gift.",
        6
    )

    local container = Instance.new("Frame")
    container.Name = "EventsContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    local snowBtn = createToggleButton(container, "Auto Fish Snow", Settings.Events.FishSnow)
    addConnection(snowBtn.MouseButton1Click:Connect(function()
        Settings.Events.FishSnow = not Settings.Events.FishSnow
        setToggleButtonState(snowBtn, "Auto Fish Snow", Settings.Events.FishSnow)
        saveBazSettings()
    end))

    local eventFishBtn = createToggleButton(container, "Auto Fish Event", Settings.Events.AutoFishingEvent)
    addConnection(eventFishBtn.MouseButton1Click:Connect(function()
        Settings.Events.AutoFishingEvent = not Settings.Events.AutoFishingEvent
        setToggleButtonState(eventFishBtn, "Auto Fish Event", Settings.Events.AutoFishingEvent)
        saveBazSettings()
    end))

    local eventTasksBtn = createToggleButton(container, "Auto Claim Event Tasks", Settings.Events.AutoEventTasks)
    addConnection(eventTasksBtn.MouseButton1Click:Connect(function()
        Settings.Events.AutoEventTasks = not Settings.Events.AutoEventTasks
        setToggleButtonState(eventTasksBtn, "Auto Claim Event Tasks", Settings.Events.AutoEventTasks)
        saveBazSettings()
    end))

    local onlineGiftBtn = createToggleButton(container, "Auto Claim Online Gift", Settings.Events.AutoDinoOnline)
    addConnection(onlineGiftBtn.MouseButton1Click:Connect(function()
        Settings.Events.AutoDinoOnline = not Settings.Events.AutoDinoOnline
        setToggleButtonState(onlineGiftBtn, "Auto Claim Online Gift", Settings.Events.AutoDinoOnline)
        saveBazSettings()
    end))
end

-----------------------
-- PLAYER & EXCHANGE & REDEEM CARD
-----------------------

local function buildPlayerCard()
    local card, y = createCard(
        bodyScroll,
        "Player, Exchange & Redeem",
        "Pilih player untuk Like, exchange item, dan redeem codes.",
        7
    )

    local container = Instance.new("Frame")
    container.Name = "PlayerContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    -- Player selection (cycle through list)
    local curPlayers = getOtherPlayersList()
    local playerIndex = 0

    local playerBtn = Instance.new("TextButton")
    playerBtn.Name = "PlayerSelectButton"
    playerBtn.Parent = container
    playerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerBtn.BorderSizePixel  = 0
    playerBtn.AutoButtonColor  = true
    playerBtn.Font             = Enum.Font.Gotham
    playerBtn.TextSize         = 11
    playerBtn.TextColor3       = Color3.fromRGB(220, 220, 220)
    playerBtn.TextWrapped      = true
    playerBtn.Size             = UDim2.new(1, 0, 0, 26)

    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0, 8)
    playerCorner.Parent = playerBtn

    local function textForCurrentPlayer()
        if Settings.Player.SelectedPlayer ~= "" and Settings.Player.SelectedPlayerId then
            return string.format("Selected Player: %s (%d)", Settings.Player.SelectedPlayer, Settings.Player.SelectedPlayerId)
        else
            return "Selected Player: -"
        end
    end

    local function refreshPlayerButtonText()
        playerBtn.Text = textForCurrentPlayer()
    end
    refreshPlayerButtonText()

    local function cyclePlayer()
        curPlayers = getOtherPlayersList()
        if #curPlayers == 0 then
            Settings.Player.SelectedPlayer   = ""
            Settings.Player.SelectedPlayerId = nil
            refreshPlayerButtonText()
            notify("Player", "Tidak ada player lain di server.", 3)
            saveBazSettings()
            return
        end
        playerIndex = playerIndex + 1
        if playerIndex > #curPlayers then
            playerIndex = 1
        end
        local entry = curPlayers[playerIndex] -- "Name (UserId)"
        local name, idStr = string.match(entry, "^(.-) %((%d+)%)$")
        if name and idStr then
            Settings.Player.SelectedPlayer   = name
            Settings.Player.SelectedPlayerId = tonumber(idStr)
            saveBazSettings()
        end
        refreshPlayerButtonText()
    end

    addConnection(playerBtn.MouseButton1Click:Connect(cyclePlayer))

    addConnection(Players.PlayerAdded:Connect(function()
        task.delay(1, function()
            curPlayers = getOtherPlayersList()
        end)
    end))
    addConnection(Players.PlayerRemoving:Connect(function()
        task.delay(1, function()
            curPlayers = getOtherPlayersList()
        end)
    end))

    -- Like now button
    local likeBtn = Instance.new("TextButton")
    likeBtn.Name = "LikeButton"
    likeBtn.Parent = container
    likeBtn.BackgroundColor3 = Color3.fromRGB(35, 70, 35)
    likeBtn.BorderSizePixel  = 0
    likeBtn.AutoButtonColor  = true
    likeBtn.Font             = Enum.Font.GothamSemibold
    likeBtn.TextSize         = 12
    likeBtn.TextColor3       = Color3.fromRGB(230, 255, 230)
    likeBtn.Text             = "Like Plot Player"
    likeBtn.Size             = UDim2.new(1, 0, 0, 30)

    local likeCorner = Instance.new("UICorner")
    likeCorner.CornerRadius = UDim.new(0, 8)
    likeCorner.Parent = likeBtn

    addConnection(likeBtn.MouseButton1Click:Connect(function()
        if Settings.Player.SelectedPlayer ~= "" and Settings.Player.SelectedPlayerId then
            likePlotOnce()
            notify("Like", "Sudah Like plot " .. Settings.Player.SelectedPlayer, 2)
        else
            notify("Like", "Belum ada player yang dipilih.", 2)
        end
    end))

    local autoLikeBtn = createToggleButton(container, "Auto Like (30s)", Settings.Player.AutoLike)
    addConnection(autoLikeBtn.MouseButton1Click:Connect(function()
        Settings.Player.AutoLike = not Settings.Player.AutoLike
        setToggleButtonState(autoLikeBtn, "Auto Like (30s)", Settings.Player.AutoLike)
        saveBazSettings()
    end))

    -- Exchange
    local exchangeTitle = Instance.new("TextLabel")
    exchangeTitle.Name = "ExchangeTitle"
    exchangeTitle.Parent = container
    exchangeTitle.BackgroundTransparency = 1
    exchangeTitle.Font = Enum.Font.GothamSemibold
    exchangeTitle.TextSize = 12
    exchangeTitle.TextXAlignment = Enum.TextXAlignment.Left
    exchangeTitle.TextColor3 = Color3.fromRGB(230, 230, 200)
    exchangeTitle.Size = UDim2.new(1, 0, 0, 18)
    exchangeTitle.Text = "Gems Exchange Item:"

    local exchangeItemsList = {}
    for name, _ in pairs(PX.ExchangeItems) do
        table.insert(exchangeItemsList, name)
    end
    table.sort(exchangeItemsList)

    local exIndex = 1
    for i, v in ipairs(exchangeItemsList) do
        if v == Settings.Exchange.SelectedExchangeItem then
            exIndex = i
            break
        end
    end

    local exBtn = Instance.new("TextButton")
    exBtn.Name = "ExchangeItemButton"
    exBtn.Parent = container
    exBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    exBtn.BorderSizePixel  = 0
    exBtn.AutoButtonColor  = true
    exBtn.Font             = Enum.Font.Gotham
    exBtn.TextSize         = 11
    exBtn.TextColor3       = Color3.fromRGB(220, 220, 220)
    exBtn.TextWrapped      = true
    exBtn.Size             = UDim2.new(1, 0, 0, 26)

    local exCorner = Instance.new("UICorner")
    exCorner.CornerRadius = UDim.new(0, 8)
    exCorner.Parent = exBtn

    local function refreshExText()
        local name = exchangeItemsList[exIndex]
        Settings.Exchange.SelectedExchangeItem = name
        exBtn.Text = "Exchange Item: " .. name
        saveBazSettings()
    end
    refreshExText()

    addConnection(exBtn.MouseButton1Click:Connect(function()
        exIndex = exIndex + 1
        if exIndex > #exchangeItemsList then
            exIndex = 1
        end
        refreshExText()
    end))

    local autoExBtn = createToggleButton(container, "Auto Exchange (5s)", Settings.Exchange.AutoExchangeItem)
    addConnection(autoExBtn.MouseButton1Click:Connect(function()
        Settings.Exchange.AutoExchangeItem = not Settings.Exchange.AutoExchangeItem
        setToggleButtonState(autoExBtn, "Auto Exchange (5s)", Settings.Exchange.AutoExchangeItem)
        saveBazSettings()
    end))

    local exNowBtn = Instance.new("TextButton")
    exNowBtn.Name = "ExchangeNowButton"
    exNowBtn.Parent = container
    exNowBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
    exNowBtn.BorderSizePixel  = 0
    exNowBtn.AutoButtonColor  = true
    exNowBtn.Font             = Enum.Font.GothamSemibold
    exNowBtn.TextSize         = 12
    exNowBtn.TextColor3       = Color3.fromRGB(255, 240, 210)
    exNowBtn.Text             = "Exchange Sekarang"
    exNowBtn.Size             = UDim2.new(1, 0, 0, 30)

    local exNowCorner = Instance.new("UICorner")
    exNowCorner.CornerRadius = UDim.new(0, 8)
    exNowCorner.Parent = exNowBtn

    addConnection(exNowBtn.MouseButton1Click:Connect(function()
        exchangeItemOnce()
        notify("Exchange", "Exchange item dikirim.", 2)
    end))

    -- Redeem
    local redeemBtn = Instance.new("TextButton")
    redeemBtn.Name = "RedeemAllButton"
    redeemBtn.Parent = container
    redeemBtn.BackgroundColor3 = Color3.fromRGB(35, 60, 80)
    redeemBtn.BorderSizePixel  = 0
    redeemBtn.AutoButtonColor  = true
    redeemBtn.Font             = Enum.Font.GothamSemibold
    redeemBtn.TextSize         = 12
    redeemBtn.TextColor3       = Color3.fromRGB(220, 240, 255)
    redeemBtn.Text             = "Redeem All Codes (Peanut X)"
    redeemBtn.Size             = UDim2.new(1, 0, 0, 30)

    local redeemCorner = Instance.new("UICorner")
    redeemCorner.CornerRadius = UDim.new(0, 8)
    redeemCorner.Parent = redeemBtn

    addConnection(redeemBtn.MouseButton1Click:Connect(function()
        redeemAllCodesOnce()
    end))
end

-----------------------
-- SETTINGS CARD
-----------------------

local function buildSettingsCard()
    local card, y = createCard(
        bodyScroll,
        "Settings & Webhook",
        "Movement, Anti AFK, Auto Rejoin, dan Webhook Discord.",
        8
    )

    local container = Instance.new("Frame")
    container.Name = "SettingsContainer"
    container.Parent = card
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, y)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 6)

    -- WalkSpeed
    local wsLabel = Instance.new("TextLabel")
    wsLabel.Parent = container
    wsLabel.BackgroundTransparency = 1
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.TextSize = 11
    wsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    wsLabel.TextXAlignment = Enum.TextXAlignment.Left
    wsLabel.Size = UDim2.new(1, 0, 0, 18)
    wsLabel.Text = "WalkSpeed (1 - 250):"

    local wsBox = Instance.new("TextBox")
    wsBox.Name = "WalkSpeedBox"
    wsBox.Parent = container
    wsBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    wsBox.BorderSizePixel  = 0
    wsBox.Font             = Enum.Font.GothamSemibold
    wsBox.TextSize         = 11
    wsBox.TextColor3       = Color3.fromRGB(230, 230, 230)
    wsBox.ClearTextOnFocus = false
    wsBox.TextXAlignment   = Enum.TextXAlignment.Left
    wsBox.Size             = UDim2.new(1, 0, 0, 24)
    wsBox.Text             = tostring(Settings.Settings.WalkSpeed or 29)

    local wsCorner = Instance.new("UICorner")
    wsCorner.CornerRadius = UDim.new(0, 8)
    wsCorner.Parent = wsBox

    addConnection(wsBox.FocusLost:Connect(function()
        local v = tonumber(wsBox.Text)
        if not v then
            wsBox.Text = tostring(Settings.Settings.WalkSpeed or 29)
            return
        end
        Settings.Settings.WalkSpeed = v
        saveBazSettings()
        applyWalkSpeed()
    end))

    -- Jump
    local jLabel = Instance.new("TextLabel")
    jLabel.Parent = container
    jLabel.BackgroundTransparency = 1
    jLabel.Font = Enum.Font.Gotham
    jLabel.TextSize = 11
    jLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    jLabel.TextXAlignment = Enum.TextXAlignment.Left
    jLabel.Size = UDim2.new(1, 0, 0, 18)
    jLabel.Text = "Jump Height (1 - 250):"

    local jBox = Instance.new("TextBox")
    jBox.Name = "JumpBox"
    jBox.Parent = container
    jBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    jBox.BorderSizePixel  = 0
    jBox.Font             = Enum.Font.GothamSemibold
    jBox.TextSize         = 11
    jBox.TextColor3       = Color3.fromRGB(230, 230, 230)
    jBox.ClearTextOnFocus = false
    jBox.TextXAlignment   = Enum.TextXAlignment.Left
    jBox.Size             = UDim2.new(1, 0, 0, 24)
    jBox.Text             = tostring(Settings.Settings.JumpPower or 9)

    local jCorner = Instance.new("UICorner")
    jCorner.CornerRadius = UDim.new(0, 8)
    jCorner.Parent = jBox

    addConnection(jBox.FocusLost:Connect(function()
        local v = tonumber(jBox.Text)
        if not v then
            jBox.Text = tostring(Settings.Settings.JumpPower or 9)
            return
        end
        Settings.Settings.JumpPower = v
        saveBazSettings()
        applyJump()
    end))

    -- Fly speed
    local flyLabel = Instance.new("TextLabel")
    flyLabel.Parent = container
    flyLabel.BackgroundTransparency = 1
    flyLabel.Font = Enum.Font.Gotham
    flyLabel.TextSize = 11
    flyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    flyLabel.TextXAlignment = Enum.TextXAlignment.Left
    flyLabel.Size = UDim2.new(1, 0, 0, 18)
    flyLabel.Text = "Fly Speed (10 - 300):"

    local flyBox = Instance.new("TextBox")
    flyBox.Name = "FlySpeedBox"
    flyBox.Parent = container
    flyBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    flyBox.BorderSizePixel  = 0
    flyBox.Font             = Enum.Font.GothamSemibold
    flyBox.TextSize         = 11
    flyBox.TextColor3       = Color3.fromRGB(230, 230, 230)
    flyBox.ClearTextOnFocus = false
    flyBox.TextXAlignment   = Enum.TextXAlignment.Left
    flyBox.Size             = UDim2.new(1, 0, 0, 24)
    flyBox.Text             = tostring(Settings.Settings.FlySpeed or 50)

    local flyCorner = Instance.new("UICorner")
    flyCorner.CornerRadius = UDim.new(0, 8)
    flyCorner.Parent = flyBox

    addConnection(flyBox.FocusLost:Connect(function()
        local v = tonumber(flyBox.Text)
        if not v then
            flyBox.Text = tostring(Settings.Settings.FlySpeed or 50)
            return
        end
        v = math.clamp(v, 10, 300)
        Settings.Settings.FlySpeed = v
        flyBox.Text = tostring(v)
        saveBazSettings()
    end))

    local flyBtn = createToggleButton(container, "Fly Mode", Settings.Settings.FlyMode)
    addConnection(flyBtn.MouseButton1Click:Connect(function()
        Settings.Settings.FlyMode = not Settings.Settings.FlyMode
        setToggleButtonState(flyBtn, "Fly Mode", Settings.Settings.FlyMode)
        saveBazSettings()
        if Settings.Settings.FlyMode then
            startFly()
        else
            stopFly()
        end
    end))

    local noclipBtn = createToggleButton(container, "No Clip", Settings.Settings.NoClip)
    addConnection(noclipBtn.MouseButton1Click:Connect(function()
        Settings.Settings.NoClip = not Settings.Settings.NoClip
        setToggleButtonState(noclipBtn, "No Clip", Settings.Settings.NoClip)
        saveBazSettings()
        setNoClip(Settings.Settings.NoClip)
    end))

    local antiAfkBtn = createToggleButton(container, "Anti AFK", Settings.Settings.AntiAFK)
    addConnection(antiAfkBtn.MouseButton1Click:Connect(function()
        Settings.Settings.AntiAFK = not Settings.Settings.AntiAFK
        setToggleButtonState(antiAfkBtn, "Anti AFK", Settings.Settings.AntiAFK)
        saveBazSettings()
    end))

    local arLabel = Instance.new("TextLabel")
    arLabel.Parent = container
    arLabel.BackgroundTransparency = 1
    arLabel.Font = Enum.Font.Gotham
    arLabel.TextSize = 11
    arLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    arLabel.TextXAlignment = Enum.TextXAlignment.Left
    arLabel.Size = UDim2.new(1, 0, 0, 18)
    arLabel.Text = "Auto Rejoin Delay (detik):"

    local arBox = Instance.new("TextBox")
    arBox.Name = "AutoRejoinBox"
    arBox.Parent = container
    arBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    arBox.BorderSizePixel  = 0
    arBox.Font             = Enum.Font.GothamSemibold
    arBox.TextSize         = 11
    arBox.TextColor3       = Color3.fromRGB(230, 230, 230)
    arBox.ClearTextOnFocus = false
    arBox.TextXAlignment   = Enum.TextXAlignment.Left
    arBox.Size             = UDim2.new(1, 0, 0, 24)
    arBox.Text             = tostring(Settings.Settings.AutoRejoinDelay or 900)

    local arCorner = Instance.new("UICorner")
    arCorner.CornerRadius = UDim.new(0, 8)
    arCorner.Parent = arBox

    addConnection(arBox.FocusLost:Connect(function()
        local v = tonumber(arBox.Text)
        if not v then
            arBox.Text = tostring(Settings.Settings.AutoRejoinDelay or 900)
            return
        end
        v = math.max(v, 60)
        Settings.Settings.AutoRejoinDelay = v
        arBox.Text = tostring(v)
        saveBazSettings()
    end))

    local autoRejoinBtn = createToggleButton(container, "Auto Rejoin", Settings.Settings.AutoRejoin)
    addConnection(autoRejoinBtn.MouseButton1Click:Connect(function()
        Settings.Settings.AutoRejoin = not Settings.Settings.AutoRejoin
        setToggleButtonState(autoRejoinBtn, "Auto Rejoin", Settings.Settings.AutoRejoin)
        saveBazSettings()
    end))

    -- Webhook
    local whLabel = Instance.new("TextLabel")
    whLabel.Parent = container
    whLabel.BackgroundTransparency = 1
    whLabel.Font = Enum.Font.Gotham
    whLabel.TextSize = 11
    whLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    whLabel.TextXAlignment = Enum.TextXAlignment.Left
    whLabel.Size = UDim2.new(1, 0, 0, 18)
    whLabel.Text = "Webhook URL (Discord) untuk log egg:"

    local whBox = Instance.new("TextBox")
    whBox.Name = "WebhookBox"
    whBox.Parent = container
    whBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    whBox.BorderSizePixel  = 0
    whBox.Font             = Enum.Font.Gotham
    whBox.TextSize         = 11
    whBox.TextColor3       = Color3.fromRGB(230, 230, 230)
    whBox.ClearTextOnFocus = false
    whBox.TextXAlignment   = Enum.TextXAlignment.Left
    whBox.Size             = UDim2.new(1, 0, 0, 24)
    whBox.Text             = Settings.Settings.WebhookURL or ""

    local whCorner = Instance.new("UICorner")
    whCorner.CornerRadius = UDim.new(0, 8)
    whCorner.Parent = whBox

    addConnection(whBox.FocusLost:Connect(function()
        Settings.Settings.WebhookURL = whBox.Text or ""
        saveBazSettings()
    end))

    local whToggle = createToggleButton(container, "Enable Webhook Egg Log", Settings.Settings.EnableWebhook)
    addConnection(whToggle.MouseButton1Click:Connect(function()
        Settings.Settings.EnableWebhook = not Settings.Settings.EnableWebhook
        setToggleButtonState(whToggle, "Enable Webhook Egg Log", Settings.Settings.EnableWebhook)
        saveBazSettings()
    end))
end

---------------------------------------------------------------------
-- BUILD ALL UI
---------------------------------------------------------------------

buildInfoCard()
buildFarmCard()
buildShopCard()
buildEggsCard()
buildPetsCard()
buildEventsCard()
buildPlayerCard()
buildSettingsCard()

-- Apply initial movement settings
applyWalkSpeed()
applyJump()
if Settings.Settings.FlyMode then
    startFly()
end
setNoClip(Settings.Settings.NoClip)

---------------------------------------------------------------------
-- BACKGROUND LOOPS (GATED BY 'running' + SETTINGS)
---------------------------------------------------------------------

-- Auto coins
task.spawn(function()
    while running do
        local busyFishing =
            Settings.Main.AutoFishing or
            Settings.Events.FishSnow or
            Settings.Events.AutoFishingEvent
        if Settings.Main.AutoClaimCoins and not busyFishing then
            local ok, err = pcall(autoClaimCoinsStep)
            if not ok then
                warn("[BuildAZoo] AutoClaimCoins error:", err)
            end
            task.wait(0.15)
        else
            task.wait(0.3)
        end
    end
end)

-- Auto fishing (normal)
task.spawn(function()
    while running do
        if Settings.Main.AutoFishing and not Settings.Events.FishSnow and not Settings.Events.AutoFishingEvent then
            local ok, err = pcall(autoFishingStep)
            if not ok then
                warn("[BuildAZoo] AutoFishing error:", err)
            end
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- Snow fishing
task.spawn(function()
    while running do
        if Settings.Events.FishSnow then
            local ok, err = pcall(autoFishSnowStep)
            if not ok then
                warn("[BuildAZoo] Snow fishing error:", err)
            end
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- Event fishing
task.spawn(function()
    while running do
        if Settings.Events.AutoFishingEvent then
            local ok, err = pcall(autoFishEventStep)
            if not ok then
                warn("[BuildAZoo] Event fishing error:", err)
            end
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Potion (5 menit)
task.spawn(function()
    while running do
        if Settings.Main.AutoPotion then
            local ok, err = pcall(usePotionOnce)
            if not ok then
                warn("[BuildAZoo] AutoPotion error:", err)
            end
            local t0 = tick()
            while running and Settings.Main.AutoPotion and (tick() - t0 < 300) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Buy Fruits (60s)
task.spawn(function()
    while running do
        if Settings.Shop.AutoBuyFruit and #(Settings.Shop.SelectedFruits or {}) > 0 then
            local ok, err = pcall(buyFruitsOnce)
            if not ok then
                warn("[BuildAZoo] AutoBuyFruit error:", err)
            end
            local t0 = tick()
            while running and Settings.Shop.AutoBuyFruit and (tick() - t0 < 60) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Destroy Fruits
task.spawn(function()
    while running do
        if Settings.Shop.AutoDestroyFruits and Settings.Shop.SelectedDestroyFruit ~= "" then
            local ok, err = pcall(destroyFruitOnce)
            if not ok then
                warn("[BuildAZoo] AutoDestroyFruit error:", err)
            end
            task.wait(0.4)
        else
            task.wait(0.6)
        end
    end
end)

-- Auto Buy Eggs (Set 1)
task.spawn(function()
    while running do
        if Settings.Eggs.AutoBuyEgg then
            local ok, err = pcall(autoBuyEggsStep)
            if not ok then
                warn("[BuildAZoo] AutoBuyEgg error:", err)
            end
            task.wait(1)
        else
            task.wait(0.8)
        end
    end
end)

-- Auto Sell Eggs (filter)
task.spawn(function()
    while running do
        if Settings.Eggs.AutoSellEgg then
            local ok, err = pcall(sellEggsOnce)
            if not ok then
                warn("[BuildAZoo] AutoSellEgg error:", err)
            end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

-- Auto Hatch Blocks
task.spawn(function()
    while running do
        if Settings.Eggs.AutoHatch then
            local ok, err = pcall(autoHatchFromBlocksOnce)
            if not ok then
                warn("[BuildAZoo] AutoHatch error:", err)
            end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

-- Auto Event Tasks
task.spawn(function()
    while running do
        if Settings.Events.AutoEventTasks then
            local ok, err = pcall(claimEventTasksOnce)
            if not ok then
                warn("[BuildAZoo] AutoEventTasks error:", err)
            end
            local t0 = tick()
            while running and Settings.Events.AutoEventTasks and (tick() - t0 < 15) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Dino Online Gifts
task.spawn(function()
    while running do
        if Settings.Events.AutoDinoOnline then
            local ok, err = pcall(claimDinoOnlineOnce)
            if not ok then
                warn("[BuildAZoo] AutoDinoOnline error:", err)
            end
            local t0 = tick()
            while running and Settings.Events.AutoDinoOnline and (tick() - t0 < 30) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Like
task.spawn(function()
    while running do
        if Settings.Player.AutoLike and Settings.Player.SelectedPlayerId then
            local ok, err = pcall(likePlotOnce)
            if not ok then
                warn("[BuildAZoo] AutoLike error:", err)
            end
            local t0 = tick()
            while running and Settings.Player.AutoLike and (tick() - t0 < 30) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Exchange Item
task.spawn(function()
    while running do
        if Settings.Exchange.AutoExchangeItem then
            local ok, err = pcall(exchangeItemOnce)
            if not ok then
                warn("[BuildAZoo] AutoExchange error:", err)
            end
            local t0 = tick()
            while running and Settings.Exchange.AutoExchangeItem and (tick() - t0 < 5) do
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Feed Big Pets (3 slot)
task.spawn(function()
    autoFeedSlotLoop(1)
end)
task.spawn(function()
    autoFeedSlotLoop(2)
end)
task.spawn(function()
    autoFeedSlotLoop(3)
end)

-- Auto Rejoin
task.spawn(function()
    while running do
        if Settings.Settings.AutoRejoin then
            local delaySec = tonumber(Settings.Settings.AutoRejoinDelay) or 900
            delaySec = math.max(60, delaySec)
            local t0 = tick()
            while running and Settings.Settings.AutoRejoin and (tick() - t0 < delaySec) do
                task.wait(1)
            end
            if running and Settings.Settings.AutoRejoin then
                local serverId = findLowPopulationServer()
                if serverId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
                else
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            end
        else
            task.wait(2)
        end
    end
end)

---------------------------------------------------------------------
-- TAB CLEANUP
---------------------------------------------------------------------

_G.AxaHub.TabCleanup[tabId] = function()
    running = false

    -- stop movement helpers
    stopFly()
    setNoClip(false)

    -- reset anchored state if ada
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
        end
    end

    -- disconnect all connections
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    connections = {}

    -- clear UI
    if frame then
        pcall(function()
            frame:ClearAllChildren()
        end)
    end
end