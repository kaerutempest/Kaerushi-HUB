-- KaeruShi HUB | V.01 | Full Features
-- Tekan F untuk toggle UI

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- Konfigurasi
local Config = {
    AutoFish = false,
    AutoCatch = false,
    AutoSell = false,
    GPUSaver = false,
    AutoFavorite = true,
    FavoriteRarity = "Mythic",
    FishDelay = 1.2,
    CatchDelay = 0.4,
    SellDelay = 45,
}

-- Random delay dengan variasi normal
local function randDelay(mean, variance)
    local u1, u2 = math.random(), math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.max(0.05, mean + (variance * z0))
end

-- Remote events (nilai statis asli untuk hash SHA-256)
local function getRemotes()
    local net = RS.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fish = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        mini = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        fav = net:WaitForChild("RE/FavoriteItem")
    }
end
local ev = getRemotes()

-- Auto Favorite (module dari game)
local ItemUtility = require(RS.Shared.ItemUtility)
local Replion = require(RS.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")
local RarityTiers = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7 }
local function getRarityValue(r) return RarityTiers[r] or 0 end
local function getFishRarity(d) return d and d.Data and d.Data.Rarity or "Common" end

local favorited = {}
local function isFav(uuid)
    local s,r = pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            if it.UUID == uuid then return it.Favorited == true end
        end
        return false
    end)
    return s and r or false
end
local function autoFavorite()
    if not Config.AutoFavorite then return end
    local targetRarity = Config.FavoriteRarity
    local targetVal = getRarityValue(targetRarity)
    if targetVal < 6 then targetVal = 6 end
    pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            local data = ItemUtility:GetItemData(it.Id)
            if data and data.Data then
                local r = getFishRarity(data)
                if getRarityValue(r) == targetVal and targetVal >= 6 then
                    if not isFav(it.UUID) and not favorited[it.UUID] then
                        ev.fav:FireServer(it.UUID)
                        favorited[it.UUID] = true
                        task.wait(randDelay(0.3, 0.1))
                    end
                end
            end
        end
    end)
end
task.spawn(function()
    while task.wait(randDelay(10, 3)) do
        if Config.AutoFavorite then autoFavorite() end
    end
end)

-- Fishing core
local active = false
local casting = false

local function equipRod()
    local c = LP.Character
    if c and c:FindFirstChildOfClass("Tool") then return true end
    pcall(function()
        ev.equip:FireServer(1)
        task.wait(randDelay(0.05, 0.02))
    end)
    return true
end

local function cast()
    pcall(function()
        equipRod()
        ev.charge:InvokeServer(1755848498.4834)  -- nilai asli (hash valid)
        task.wait(randDelay(0.02, 0.01))
        ev.mini:InvokeServer(1.2854545116425, 1) -- nilai asli
    end)
end

local function reel()
    pcall(function() ev.fish:FireServer() end)
end

-- Loop utama
coroutine.wrap(function()
    while true do
        if active and not casting then
            casting = true
            task.wait(randDelay(0.4, 0.2))
            cast()
            task.wait(randDelay(Config.FishDelay, 0.3))
            reel()
            task.wait(randDelay(Config.CatchDelay, 0.15))
            casting = false
            task.wait(randDelay(0.8, 0.5))
        end
        task.wait(0.1)
    end
end)()

-- Auto catch (opsional, risiko tinggi)
task.spawn(function()
    while true do
        task.wait(randDelay(Config.CatchDelay, 0.1))
        if Config.AutoCatch and not casting then
            pcall(function() ev.fish:FireServer() end)
        end
    end
end)

-- Auto sell
local function sellAll()
    pcall(function() ev.sell:InvokeServer() end)
end
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then sellAll() end
    end
end)

-- Anti-AFK (gerakan mouse acak)
task.spawn(function()
    while active do
        task.wait(randDelay(45, 15))
        pcall(function()
            UIS:SetMouseDelta(Vector2.new(math.random(-8,8), math.random(-5,5)))
        end)
    end
end)

-- GPU Saver
local gpuActive, screen = false, nil
local function gpuOn()
    if gpuActive then return end
    gpuActive = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        setfpscap(8)
    end)
    screen = Instance.new("ScreenGui")
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 999999
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    f.Parent = screen
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0,400,0,100)
    l.Position = UDim2.new(0.5,-200,0.5,-50)
    l.BackgroundTransparency = 1
    l.Text = "GPU SAVER ACTIVE"
    l.TextColor3 = Color3.new(0,1,0)
    l.TextSize = 28
    l.Font = Enum.Font.GothamBold
    l.TextAlignment = Enum.TextAlignment.Center
    l.Parent = f
    screen.Parent = game.CoreGui
end
local function gpuOff()
    if not gpuActive then return end
    gpuActive = false
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        setfpscap(0)
    end)
    if screen then screen:Destroy() screen = nil end
end

-- Teleport locations
local LOCATIONS = {
    Spawn = CFrame.new(45.2788086, 252.562927, 2987.10913, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Sisyphus Statue"] = CFrame.new(-3728.21606, -135.074417, -1012.12744, -0.977224171, 7.74980258e-09, -0.212209702, 1.566994e-08, 1, -3.5640408e-08, 0.212209702, -3.81539813e-08, -0.977224171),
    ["Coral Reefs"] = CFrame.new(-3114.78198, 1.32066584, 2237.52295, -0.304758579, 1.6556676e-08, -0.952429652, -8.50574935e-08, 1, 4.46003305e-08, 0.952429652, 9.46036067e-08, -0.304758579),
    ["Esoteric Depths"] = CFrame.new(3248.37109, -1301.53027, 1403.82727, -0.920208454, 7.76270355e-08, 0.391428679, 4.56261056e-08, 1, -9.10549289e-08, -0.391428679, -6.5930152e-08, -0.920208454),
    ["Crater Island"] = CFrame.new(1016.49072, 20.0919304, 5069.27295, 0.838976264, 3.30379857e-09, -0.544168055, 2.63538391e-09, 1, 1.01344115e-08, 0.544168055, -9.93662219e-09, 0.838976264),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["Mount Hallow"] = CFrame.new(2136.62305, 78.9163895, 3272.50439, -0.977613986, -1.77645827e-08, 0.210406482, -2.42338203e-08, 1, -2.81680421e-08, -0.210406482, -3.26364251e-08, -0.977613986),
    ["Treasure Room"] = CFrame.new(-3606.34985, -266.57373, -1580.97339, 0.998743415, 1.12141152e-13, -0.0501160324, -1.56847693e-13, 1, -8.88127842e-13, 0.0501160324, 8.94872392e-13, 0.998743415),
    ["Kohana"] = CFrame.new(-663.904236, 3.04580712, 718.796875, -0.100799225, -2.14183729e-08, -0.994906783, -1.12300391e-08, 1, -2.03902459e-08, 0.994906783, 9.11752096e-09, -0.100799225),
    ["Underground Cellar"] = CFrame.new(2109.52148, -94.1875076, -708.609131, 0.418592364, 3.34794485e-08, -0.908174217, -5.24141512e-08, 1, 1.27060247e-08, 0.908174217, 4.22825366e-08, 0.418592364),
    ["Ancient Jungle"] = CFrame.new(1831.71362, 6.62499952, -299.279175, 0.213522509, 1.25553285e-07, -0.976938128, -4.32026184e-08, 1, 1.19074642e-07, 0.976938128, 1.67811702e-08, 0.213522509),
    ["Sacred Temple"] = CFrame.new(1466.92151, -21.8750591, -622.835693, -0.764787138, 8.14444334e-09, 0.644283056, 2.31097452e-08, 1, 1.4791004e-08, -0.644283056, 2.6201187e-08, -0.764787138)
}
local function teleportTo(locName)
    local cf = LOCATIONS[locName]
    if not cf then return end
    pcall(function()
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cf
        end
    end)
end

-- ====================================================================
-- RAYFIELD UI
-- ====================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KaeruShi HUB | V.01",
   LoadingTitle = "KaeruShi HUB",
   LoadingSubtitle = "V.01 | Preparation",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "KaeruShi_Configs",
      FileName = "MainConfig"
   },
   Discord = { Enabled = false },
   KeySystem = false
})

-- Keybind F untuk toggle UI
local function toggleUI()
    local gui = game.CoreGui:FindFirstChild("Rayfield")
    if gui then
        gui.Enabled = not gui.Enabled
    end
end
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleUI()
    end
end)

-- ========== TAB AUTOMATION ==========
local TabAutomation = Window:CreateTab("AUTOMATION", 4483345998)
TabAutomation:CreateSection("— MAIN FISHING —")
TabAutomation:CreateToggle({
   Name = "Auto Fish",
   CurrentValue = Config.AutoFish,
   Flag = "AutoFish",
   Callback = function(Value)
      Config.AutoFish = Value
      active = Value
      if not Value then pcall(function() ev.unequip:FireServer() end) end
   end,
})
TabAutomation:CreateToggle({
   Name = "Auto Catch (High Risk)",
   CurrentValue = Config.AutoCatch,
   Flag = "AutoCatch",
   Callback = function(Value) Config.AutoCatch = Value end,
})
TabAutomation:CreateSlider({
   Name = "Fish Delay (seconds)",
   Range = {0.5, 5},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = Config.FishDelay,
   Flag = "FishDelay",
   Callback = function(Value) Config.FishDelay = Value end,
})
TabAutomation:CreateSlider({
   Name = "Catch Delay (seconds)",
   Range = {0.2, 2},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = Config.CatchDelay,
   Flag = "CatchDelay",
   Callback = function(Value) Config.CatchDelay = Value end,
})

TabAutomation:CreateSection("— AUTO SELL —")
TabAutomation:CreateToggle({
   Name = "Auto Sell",
   CurrentValue = Config.AutoSell,
   Flag = "AutoSell",
   Callback = function(Value) Config.AutoSell = Value end,
})
TabAutomation:CreateSlider({
   Name = "Sell Delay (seconds)",
   Range = {15, 300},
   Increment = 5,
   Suffix = "s",
   CurrentValue = Config.SellDelay,
   Flag = "SellDelay",
   Callback = function(Value) Config.SellDelay = Value end,
})
TabAutomation:CreateButton({
   Name = "Sell All Now",
   Callback = sellAll,
})

-- ========== TAB VISUALS ==========
local TabVisuals = Window:CreateTab("VISUALS", 4483345998)
TabVisuals:CreateSection("— RENDERING —")
TabVisuals:CreateToggle({
   Name = "Anti-Lag Mode (GPU Saver)",
   CurrentValue = Config.GPUSaver,
   Flag = "GPUSaver",
   Callback = function(Value)
      Config.GPUSaver = Value
      if Value then gpuOn() else gpuOff() end
   end,
})
TabVisuals:CreateToggle({
   Name = "Full Bright",
   CurrentValue = false,
   Flag = "FullBright",
   Callback = function(Value)
      if Value then
         game.Lighting.Brightness = 2
         game.Lighting.ClockTime = 12
         game.Lighting.FogEnd = 100000
      else
         game.Lighting.Brightness = 1
         game.Lighting.ClockTime = 0
         game.Lighting.FogEnd = 100000
      end
   end,
})

-- ========== TAB TELEPORT ==========
local TabTeleport = Window:CreateTab("TELEPORT", 4483345998)
TabTeleport:CreateSection("— LOCATIONS —")
for locName, _ in pairs(LOCATIONS) do
    TabTeleport:CreateButton({
        Name = locName,
        Callback = function() teleportTo(locName) end,
    })
end

-- ========== TAB SETTINGS ==========
local TabSettings = Window:CreateTab("SETTINGS", 4483345998)
TabSettings:CreateSection("— INTERFACE —")
TabSettings:CreateColorPicker({
    Name = "UI Accent Color",
    Color = Color3.fromRGB(255, 0, 127),
    Flag = "UI_Color",
    Callback = function(Value)
        Rayfield:SetConfiguration({ AccentColor = Value })
    end
})
TabSettings:CreateSection("— AUTO FAVORITE —")
TabSettings:CreateToggle({
   Name = "Auto Favorite (Mythic/Secret)",
   CurrentValue = Config.AutoFavorite,
   Flag = "AutoFavorite",
   Callback = function(Value) Config.AutoFavorite = Value end,
})
TabSettings:CreateDropdown({
   Name = "Favorite Rarity",
   Options = {"Mythic", "Secret"},
   CurrentOption = Config.FavoriteRarity,
   Flag = "FavRarity",
   Callback = function(Option) Config.FavoriteRarity = Option end,
})
TabSettings:CreateButton({
   Name = "Favorite All Now",
   Callback = autoFavorite,
})
TabSettings:CreateButton({
   Name = "Unload Script",
   Callback = function()
        Rayfield:Destroy()
        if screen then screen:Destroy() end
   end,
})

-- ========== TAB INFO ==========
local TabInfo = Window:CreateTab("INFO", 4483345998)
TabInfo:CreateSection("— ABOUT —")
TabInfo:CreateParagraph({
   Title = "KaeruShi HUB | V.01",
   Content = "• Auto Fishing (Human-like delays)\n• Auto Sell (keeps favorited fish)\n• Auto Catch (high risk, optional)\n• Teleport to all locations\n• GPU Saver / Anti-Lag\n• Auto Favorite (Mythic/Secret)\n• Anti-AFK Protection\n• Keybind F to toggle UI"
})
TabInfo:CreateParagraph({
   Title = "Warning",
   Content = "Auto Catch may trigger anti-cheat. Use at your own risk.\nRecommended Fish Delay > 1.0s for safety."
})

-- Notifikasi
Rayfield:Notify({
   Title = "KaeruShi HUB",
   Content = "Interface Loaded. Press F to hide/show UI.",
   Duration = 5,
   Image = 4483345998,
})

print("KaeruShi HUB | V.01 | Fully loaded | Press F to toggle UI")
