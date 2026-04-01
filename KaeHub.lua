-- ====================================================================
-- KaeruShi HUBFISH | V0.2 | Tablet Edition
-- UI: Rayfield | Anti-Detection Enhanced
-- ====================================================================

-- ====== CRITICAL DEPENDENCY VALIDATION ======
local success, errorMsg = pcall(function()
    local services = {
        game = game,
        workspace = workspace,
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        HttpService = game:GetService("HttpService")
    }
    for serviceName, service in pairs(services) do
        if not service then error("Critical service missing: " .. serviceName) end
    end
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then error("LocalPlayer not available") end
    return true
end)
if not success then
    error("❌ Critical dependency check failed: " .. tostring(errorMsg))
    return
end

-- ====================================================================
-- CORE SERVICES
-- ====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- ENHANCED ANTI-CHEAT (block kick, crash, and hide script)
-- ====================================================================
local function AntiCheatFix()
    -- Block kick
    local player = LocalPlayer
    if player and player.Kick then
        local oldKick = player.Kick
        player.Kick = function(self, ...)
            print("[AC] Kick blocked")
            fishingActive = false
            return nil
        end
    end
    -- Block crash
    if game.Crash then game.Crash = function() end end
    -- Hide from detection (experimental)
    if debug and debug.setupvalue then
        local gc = getgc and getgc(true) or {}
        for _, v in ipairs(gc) do
            if type(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.name and info.name:lower():match("detect") then
                    debug.setupvalue(v, 1, function() end)
                end
            end
        end
    end
    print("[AC] Enhanced protection loaded")
end
pcall(AntiCheatFix)

-- ====================================================================
-- HELPER: RANDOM DELAY (human-like variation)
-- ====================================================================
local function randomDelay(base, variance)
    return base + (math.random() * variance * 2 - variance)
end

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
local CONFIG_FOLDER = "KaeruShiConfig"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"
local DefaultConfig = {
    AutoFish = false,
    AutoSell = false,
    AutoCatch = false,     -- WARNING: high risk of detection
    GPUSaver = false,
    FishDelay = 1.2,
    CatchDelay = 0.4,
    SellDelay = 45,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite = true,
    FavoriteRarity = "Mythic"
}
local Config = {}
for k, v in pairs(DefaultConfig) do Config[k] = v end

-- Teleport Locations (unchanged)
local LOCATIONS = {
    ["Spawn"] = CFrame.new(45.2788086, 252.562927, 2987.10913, 1, 0, 0, 0, 1, 0, 0, 1),
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

-- Config functions (save/load)
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
    return isfolder(CONFIG_FOLDER)
end
local function saveConfig()
    if not writefile or not ensureFolder() then return end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) print("[Config] Saved") end)
end
local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do if DefaultConfig[k] == nil then Config[k] = v end end
        print("[Config] Loaded")
    end)
end
loadConfig()

-- ====================================================================
-- NETWORK EVENTS (verified from game)
-- ====================================================================
local function getNetworkEvents()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fishing = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem")
    }
end
local Events = getNetworkEvents()

-- Modules for favorite
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")

-- Rarity system
local RarityTiers = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7 }
local function getRarityValue(r) return RarityTiers[r] or 0 end
local function getFishRarity(data) return data and data.Data and data.Data.Rarity or "Common" end

-- Teleport
local Teleport = {}
function Teleport.to(locationName)
    local cf = LOCATIONS[locationName]
    if not cf then warn("[Teleport] Not found") return false end
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cf
            print("[Teleport] -> " .. locationName)
        end
    end)
    return true
end

-- GPU Saver (unchanged)
local gpuActive, whiteScreen = false, nil
local function enableGPU()
    if gpuActive then return end
    gpuActive = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        setfpscap(8)
    end)
    whiteScreen = Instance.new("ScreenGui")
    whiteScreen.ResetOnSpawn = false
    whiteScreen.DisplayOrder = 999999
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    frame.Parent = whiteScreen
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,400,0,100)
    label.Position = UDim2.new(0.5,-200,0.5,-50)
    label.BackgroundTransparency = 1
    label.Text = "GPU SAVER ACTIVE\nAuto Fishing"
    label.TextColor3 = Color3.new(0,1,0)
    label.TextSize = 28
    label.Font = Enum.Font.GothamBold
    label.TextAlignment = Enum.TextAlignment.Center
    label.Parent = frame
    whiteScreen.Parent = game.CoreGui
    print("[GPU] Enabled")
end
local function disableGPU()
    if not gpuActive then return end
    gpuActive = false
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        setfpscap(0)
    end)
    if whiteScreen then whiteScreen:Destroy() whiteScreen = nil end
    print("[GPU] Disabled")
end

-- Anti-AFK
LocalPlayer.Idle:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Auto Favorite (unchanged)
local favoritedItems = {}
local function isItemFavorited(uuid)
    local s,r = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        for _,it in ipairs(items) do if it.UUID == uuid then return it.Favorited == true end end
        return false
    end)
    return s and r or false
end
local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end
    local targetRarity = Config.FavoriteRarity
    local targetVal = getRarityValue(targetRarity)
    if targetVal < 6 then targetVal = 6 end
    local favorited = 0
    pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        if not items then return end
        for _,it in ipairs(items) do
            local data = ItemUtility:GetItemData(it.Id)
            if data and data.Data then
                local rarity = getFishRarity(data)
                if getRarityValue(rarity) == targetVal and targetVal >= 6 then
                    if not isItemFavorited(it.UUID) and not favoritedItems[it.UUID] then
                        Events.favorite:FireServer(it.UUID)
                        favoritedItems[it.UUID] = true
                        favorited = favorited + 1
                        print("[Favorite] " .. (data.Data.Name or "?") .. " (" .. rarity .. ")")
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
    if favorited > 0 then print("[Favorite] Done: " .. favorited) end
end
task.spawn(function() while true do task.wait(10) if Config.AutoFavorite then autoFavoriteByRarity() end end end)

-- ====================================================================
-- FISHING LOGIC (human-like, safe)
-- ====================================================================
local isFishing = false
local fishingActive = false
local lastEquipSlot = nil

local function equipRod()
    -- Only equip if not already equipped (check from toolbar or current tool)
    local char = LocalPlayer.Character
    local currentTool = char and char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool.Name:lower():find("rod") then
        return true
    end
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(randomDelay(0.05, 0.02))
        lastEquipSlot = 1
    end)
    return true
end

local function castRod()
    pcall(function()
        equipRod()
        -- Use original values (captured from game) to avoid hash mismatch
        local chargeVal = 1755848498.4834   -- original value
        local minigameVal = 1.2854545116425 -- original value
        Events.charge:InvokeServer(chargeVal)
        task.wait(randomDelay(0.02, 0.01))
        Events.minigame:InvokeServer(minigameVal, 1)
        print("[Fishing] Cast")
    end)
end

local function reelIn()
    pcall(function()
        Events.fishing:FireServer()
        print("[Fishing] Reel")
    end)
end

-- Main loop with random delays
local function normalFishingLoop()
    while fishingActive do
        if not isFishing then
            isFishing = true
            -- Random pre-cast wait (mimic human reaction)
            task.wait(randomDelay(0.3, 0.2))
            castRod()
            -- Wait for bite with variation
            local biteWait = randomDelay(Config.FishDelay, 0.3)
            task.wait(biteWait)
            reelIn()
            -- Post-catch delay
            local catchWait = randomDelay(Config.CatchDelay, 0.15)
            task.wait(catchWait)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- AUTO CATCH (optional but risky, we add warning)
task.spawn(function()
    while true do
        if Config.AutoCatch and not isFishing then
            pcall(function()
                Events.fishing:FireServer()
            end)
            task.wait(randomDelay(Config.CatchDelay, 0.15))
        else
            task.wait(0.5)
        end
    end
end)

-- Auto sell
local function simpleSell()
    print("[Sell] Selling...")
    local s = pcall(function() return Events.sell:InvokeServer() end)
    if s then print("[Sell] Done (favorites kept)") else warn("[Sell] Failed") end
end
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then simpleSell() end
    end
end)

-- ====================================================================
-- RAYFIELD UI - TABLET PROFESSIONAL
-- ====================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Custom theme for professional look
Rayfield:SetConfiguration({
    Theme = "Dark",
    Font = Enum.Font.Gotham,
    AccentColor = Color3.fromRGB(0, 150, 255),
    BackgroundColor = Color3.fromRGB(20, 20, 25),
    TextColor = Color3.fromRGB(240, 240, 240)
})

local Window = Rayfield:CreateWindow({
    Name = "KaeruShi HUB | v0.2",
    LoadingTitle = "KaeruShi Fishing",
    LoadingSubtitle = "Tablet Optimized",
    ConfigurationSaving = { Enabled = false },
    DisableWatermark = true,
    Size = UDim2.new(0, 550, 0, 620)  -- Comfortable for tablet
})

-- Destroy watermark
pcall(Rayfield.DestroyWatermark)

-- Create tabs
local MainTab = Window:CreateTab("🎣 Fishing", nil)
local TeleportTab = Window:CreateTab("🌍 Teleport", nil)
local SettingsTab = Window:CreateTab("⚙️ Settings", nil)
local InfoTab = Window:CreateTab("ℹ️ Info", nil)

-- Main tab
MainTab:CreateSection("Auto Fishing")
local AutoFishToggle = MainTab:CreateToggle({
    Name = "🤖 Auto Fish (Safe Mode)",
    CurrentValue = Config.AutoFish,
    Callback = function(v)
        Config.AutoFish = v
        fishingActive = v
        if v then
            print("[AutoFish] Started (safe mode)")
            task.spawn(normalFishingLoop)
        else
            print("[AutoFish] Stopped")
            pcall(function() Events.unequip:FireServer() end)
        end
        saveConfig()
    end
})

local AutoCatchToggle = MainTab:CreateToggle({
    Name = "⚠️ Auto Catch (High Risk)",
    CurrentValue = Config.AutoCatch,
    Callback = function(v)
        Config.AutoCatch = v
        if v then
            print("[WARNING] Auto Catch enabled - may trigger anti-cheat!")
        end
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Fish Delay (sec)",
    PlaceholderText = "Default: 1.2",
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 0.5 and num <= 5 then
            Config.FishDelay = num
            saveConfig()
        end
    end
})
MainTab:CreateInput({
    Name = "Catch Delay (sec)",
    PlaceholderText = "Default: 0.4",
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 0.2 and num <= 2 then
            Config.CatchDelay = num
            saveConfig()
        end
    end
})

MainTab:CreateSection("Auto Sell")
local AutoSellToggle = MainTab:CreateToggle({
    Name = "💰 Auto Sell (Keeps Favorites)",
    CurrentValue = Config.AutoSell,
    Callback = function(v)
        Config.AutoSell = v
        saveConfig()
    end
})
MainTab:CreateInput({
    Name = "Sell Delay (sec)",
    PlaceholderText = "Default: 45",
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 15 and num <= 300 then
            Config.SellDelay = num
            saveConfig()
        end
    end
})
MainTab:CreateButton({
    Name = "💰 Sell All Now",
    Callback = simpleSell
})

-- Teleport tab
TeleportTab:CreateSection("📍 Locations")
for name, _ in pairs(LOCATIONS) do
    TeleportTab:CreateButton({
        Name = name,
        Callback = function() Teleport.to(name) end
    })
end

-- Settings tab
SettingsTab:CreateSection("Performance")
local GPUToggle = SettingsTab:CreateToggle({
    Name = "💻 GPU Saver Mode",
    CurrentValue = Config.GPUSaver,
    Callback = function(v)
        Config.GPUSaver = v
        if v then enableGPU() else disableGPU() end
        saveConfig()
    end
})

SettingsTab:CreateSection("Auto Favorite")
local AutoFavToggle = SettingsTab:CreateToggle({
    Name = "⭐ Auto Favorite",
    CurrentValue = Config.AutoFavorite,
    Callback = function(v)
        Config.AutoFavorite = v
        saveConfig()
    end
})
local RarityDropdown = SettingsTab:CreateDropdown({
    Name = "Favorite Rarity",
    Options = {"Mythic", "Secret"},
    CurrentOption = Config.FavoriteRarity,
    Callback = function(opt)
        Config.FavoriteRarity = opt
        saveConfig()
    end
})
SettingsTab:CreateButton({
    Name = "⭐ Favorite All Now",
    Callback = autoFavoriteByRarity
})

-- Info tab
InfoTab:CreateParagraph({
    Title = "KaeruShi HUB v0.2",
    Content = [[
• Safe Auto Fishing (human-like delays)
• Auto Sell (keeps favorited fish)
• Teleport system
• GPU Saver / Anti-AFK
• Auto Favorite (Mythic/Secret)
• Optimized for tablet screens
    ]]
})
InfoTab:CreateParagraph({
    Title = "⚠️ Warning",
    Content = [[
Auto Catch feature is high risk.
Use at your own risk. 
Avoid using very low delays.
    ]]
})

-- Startup notification
Rayfield:Notify({
    Title = "KaeruShi HUB",
    Content = "Ready to fish | Safe Mode",
    Duration = 4,
    Image = 4483362458
})

print("KaeruShi HUB v0.2 Loaded - Tablet Edition")
print("Anti-Cheat enhanced | Safe fishing mode")
