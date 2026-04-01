-- ====================================================================
-- KaeruShi HUBFISH | V0.1 |
-- Based on Working test.lua Fishing Method
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
        if not service then
            error("Critical service missing: " .. serviceName)
        end
    end

    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then
        error("LocalPlayer not available")
    end

    return true
end)
if not success then
    error("❌ [Auto Fish] Critical dependency check failed: " .. tostring(errorMsg))
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
-- ANTI-CHEAT FIX (enhanced)
-- ====================================================================
local function AntiCheatFix()
    -- Block kick attempts
    local player = LocalPlayer
    if player and player.Kick then
        local oldKick = player.Kick
        player.Kick = function(self, ...)
            print("[Anti-Cheat] ⚠️ Kick attempt blocked")
            -- Stop fishing to prevent further detection
            fishingActive = false
            return nil
        end
    end

    -- Block game crash
    if game.Crash then
        game.Crash = function() end
    end

    -- Hide script from detection (advanced)
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

    -- Additional: prevent detection by hooking some game functions (optional)
    pcall(function()
        if getgenv and getgenv()._G then
            -- Attempt to hide from environment scanning
            getgenv()._G = nil
        end
    end)

    print("[Anti-Cheat] Enhanced protection loaded")
end
pcall(AntiCheatFix)

-- ====================================================================
-- HELPER FUNCTIONS FOR RANDOMIZATION
-- ====================================================================
local function randomDelay(base, variance)
    return base + (math.random() * variance * 2 - variance)
end

-- Generate randomized values for remote parameters (to bypass SHA-256 hash checks)
local function getChargeValue()
    -- Base value from original, but add small random variation
    return 1755848498.4834 + (math.random() * 10 - 5)
end

local function getMinigameValue()
    return 1.2854545116425 + (math.random() * 0.1 - 0.05)
end

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
local CONFIG_FOLDER = "OptimizedAutoFish"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"
local DefaultConfig = {
    AutoFish = false,
    AutoSell = false,
    AutoCatch = false,
    GPUSaver = false,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite = true,
    FavoriteRarity = "Mythic"
}

local Config = {}
for k, v in pairs(DefaultConfig) do
    Config[k] = v
end

-- Teleport Locations (COMPLETE LIST)
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

-- ====================================================================
-- CONFIG FUNCTIONS
-- ====================================================================
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
    return isfolder(CONFIG_FOLDER)
end

local function saveConfig()
    if not writefile or not ensureFolder() then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        print("[Config] Settings saved!")
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do
            if DefaultConfig[k] == nil then Config[k] = v end
        end
        print("[Config] Settings loaded!")
    end)
end

loadConfig()

-- ====================================================================
-- NETWORK EVENTS
-- ====================================================================
local function getNetworkEvents()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fishing = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel = net:WaitForChild("RF/CancelFishingInputs"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem")
    }
end

local Events = getNetworkEvents()

-- ====================================================================
-- MODULES FOR AUTO FAVORITE
-- ====================================================================
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")

-- ====================================================================
-- RARITY SYSTEM
-- ====================================================================
local RarityTiers = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Secret = 7
}

local function getRarityValue(rarity)
    return RarityTiers[rarity] or 0
end

local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

-- ====================================================================
-- TELEPORT SYSTEM (from dev1.lua)
-- ====================================================================
local Teleport = {}
function Teleport.to(locationName)
    local cframe = LOCATIONS[locationName]
    if not cframe then
        warn("[Teleport] Location not found: " .. tostring(locationName))
        return false
    end
    local success = pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        rootPart.CFrame = cframe
        print("[Teleport] Moved to " .. locationName)
    end)
    return success
end

-- ====================================================================
-- GPU SAVER
-- ====================================================================
local gpuActive = false
local whiteScreen = nil

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
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.Parent = whiteScreen

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 100)
    label.Position = UDim2.new(0.5, -200, 0.5, -50)
    label.BackgroundTransparency = 1
    label.Text = "GPU SAVER ACTIVE\n\nAuto Fish Running..."
    label.TextColor3 = Color3.new(0, 1, 0)
    label.TextSize = 28
    label.Font = Enum.Font.GothamBold
    label.TextAlignment = Enum.TextAlignment.Center
    label.Parent = frame

    whiteScreen.Parent = game.CoreGui
    print("[GPU] GPU Saver enabled")
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
    if whiteScreen then
        whiteScreen:Destroy()
        whiteScreen = nil
    end
    print("[GPU] GPU Saver disabled")
end

-- ====================================================================
-- ANTI-AFK
-- ====================================================================
LocalPlayer.Idle:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
print("[Anti-AFK] Protection enabled")

-- ====================================================================
-- AUTO FAVORITE
-- ====================================================================
local favoritedItems = {}

local function isItemFavorited(uuid)
    local success, result = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        for _, item in ipairs(items) do
            if item.UUID == uuid then
                return item.Favorited == true
            end
        end
        return false
    end)
    return success and result or false
end

local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end

    local targetRarity = Config.FavoriteRarity
    local targetValue = getRarityValue(targetRarity)
    if targetValue < 6 then targetValue = 6 end

    local favorited = 0
    local skipped = 0

    local success = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        if not items or #items == 0 then return end

        for i, item in ipairs(items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local itemName = data.Data.Name or "Unknown"
                local rarity = getFishRarity(data)
                local rarityValue = getRarityValue(rarity)
                if rarityValue == targetValue and rarityValue >= 6 then
                    if not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        favorited = favorited + 1
                        print("[Auto Favorite] Favorited: " .. itemName .. " (" .. rarity .. ")")
                        task.wait(0.3)
                    else
                        skipped = skipped + 1
                    end
                end
            end
        end
    end)

    if favorited > 0 then
        print("[Auto Favorite] Complete! Favorited: " .. favorited)
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavoriteByRarity()
        end
    end
end)

-- ====================================================================
-- FISHING LOGIC (Modified: randomized delays and parameters)
-- ====================================================================
local isFishing = false
local fishingActive = false

-- Helper functions with randomization
local function castRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(randomDelay(0.05, 0.02))
        local chargeVal = getChargeValue()
        Events.charge:InvokeServer(chargeVal)
        task.wait(randomDelay(0.02, 0.01))
        local minigameVal = getMinigameValue()
        Events.minigame:InvokeServer(minigameVal, 1)
        print("[Fishing] 🎣 Cast (randomized)")
    end)
end

local function reelIn()
    pcall(function()
        -- Single reel, no spam
        Events.fishing:FireServer()
        print("[Fishing] 🎣 Reel")
    end)
end

-- Normal fishing loop with random delays
local function normalFishingLoop()
    while fishingActive do
        if not isFishing then
            isFishing = true
            -- Random pre-cast delay (human-like)
            task.wait(randomDelay(0.2, 0.1))
            castRod()
            -- Wait for fish to bite with random variation
            local fishWait = randomDelay(Config.FishDelay, 0.15)
            task.wait(fishWait)
            reelIn()
            -- Post-reel delay with random variation
            local catchWait = randomDelay(Config.CatchDelay, 0.1)
            task.wait(catchWait)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- ====================================================================
-- AUTO CATCH (Modified: single reel with random delay)
-- ====================================================================
task.spawn(function()
    while true do
        if Config.AutoCatch and not isFishing then
            pcall(function()
                Events.fishing:FireServer()
            end)
            -- Use random delay to avoid pattern
            task.wait(randomDelay(Config.CatchDelay, 0.1))
        else
            task.wait(0.5)
        end
    end
end)

-- ====================================================================
-- AUTO SELL
-- ====================================================================
local function simpleSell()
    print(" ")
    print("[Auto Sell] Selling all non-favorited items...")
    local sellSuccess = pcall(function()
        return Events.sell:InvokeServer()
    end)
    if sellSuccess then
        print("[Auto Sell] SOLD! (Favorited fish kept safe)")
    else
        warn("[Auto Sell] Sell failed")
    end
    print(" ")
end

task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then
            simpleSell()
        end
    end
end)

-- ====================================================================
-- RAYFIELD UI (renamed to KaeruShi HUB V0.1, watermark removed)
-- ====================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "KaeruShi HUB V0.1",
    LoadingTitle = "Ultra-Fast Fishing",
    LoadingSubtitle = "Working Method Implementation",
    ConfigurationSaving = {
        Enabled = false
    },
    DisableWatermark = true   -- Remove Rayfield watermark
})

-- Ensure watermark is destroyed (fallback)
pcall(function()
    Rayfield:DestroyWatermark()
end)

-- MAIN TAB
local MainTab = Window:CreateTab(" Main", 4483362458)

MainTab:CreateSection("Auto Fishing")

local AutoFishToggle = MainTab:CreateToggle({
    Name = "🤖 Auto Fish",
    CurrentValue = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        fishingActive = value
        if value then
            print("[Auto Fish] 🟢 Started (Normal Mode)")
            task.spawn(normalFishingLoop)
        else
            print("[Auto Fish] 🔴 Stopped")
            pcall(function() Events.unequip:FireServer() end)
        end
        saveConfig()
    end
})

local AutoCatchToggle = MainTab:CreateToggle({
    Name = "🎯 Auto Catch (Extra Speed)",
    CurrentValue = Config.AutoCatch,
    Callback = function(value)
        Config.AutoCatch = value
        print("[Auto Catch] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Fish Delay (seconds)",
    PlaceholderText = "Default: 0.9",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.FishDelay = num
            print("[Config] ✅ Fish delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 0.1-10)")
        end
    end
})

MainTab:CreateInput({
    Name = "Catch Delay (seconds)",
    PlaceholderText = "Default: 0.2",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.CatchDelay = num
            print("[Config] ✅ Catch delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 0.1-10)")
        end
    end
})

MainTab:CreateSection("Auto Sell")

local AutoSellToggle = MainTab:CreateToggle({
    Name = "💰 Auto Sell (Keeps Favorited)",
    CurrentValue = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
        print("[Auto Sell] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Sell Delay (seconds)",
    PlaceholderText = "Default: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 10 and num <= 300 then
            Config.SellDelay = num
            print("[Config] ✅ Sell delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 10-300)")
        end
    end
})

MainTab:CreateButton({
    Name = "💰 Sell All Now",
    Callback = function()
        simpleSell()
    end
})

-- TELEPORT TAB (from dev1.lua)
local TeleportTab = Window:CreateTab("🌍 Teleport", nil)

TeleportTab:CreateSection("📍 Locations")
for locationName, _ in pairs(LOCATIONS) do
    TeleportTab:CreateButton({
        Name = locationName,
        Callback = function()
            Teleport.to(locationName)
        end
    })
end

-- SETTINGS TAB
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateSection("Performance")

local GPUToggle = SettingsTab:CreateToggle({
    Name = "💻 GPU Saver Mode",
    CurrentValue = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        if value then
            enableGPU()
        else
            disableGPU()
        end
        saveConfig()
    end
})

SettingsTab:CreateSection("Auto Favorite")

local AutoFavoriteToggle = SettingsTab:CreateToggle({
    Name = "⭐ Auto Favorite Fish",
    CurrentValue = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
        print("[Auto Favorite] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

local FavoriteRarityDropdown = SettingsTab:CreateDropdown({
    Name = "Favorite Rarity (Mythic/Secret Only)",
    Options = {"Mythic", "Secret"},
    CurrentOption = Config.FavoriteRarity,
    Callback = function(option)
        Config.FavoriteRarity = option
        print("[Config] Favorite rarity set to: " .. option .. "+")
        saveConfig()
    end
})

SettingsTab:CreateButton({
    Name = "⭐ Favorite All Mythic/Secret Now",
    Callback = function()
        autoFavoriteByRarity()
    end
})

-- INFO TAB
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateParagraph({
    Title = "Features",
    Content = [[
• Fast Auto Fishing
• Simple Auto Sell (keeps favorited fish)
• Auto Catch for extra speed
• GPU Saver Mode
• Anti-AFK Protection
• Auto Save Configuration
• Teleport System (dev1.lua method)
• Auto Favorite (Mythic & Secret only)
]]
})

-- STARTUP
Rayfield:Notify({
    Title = "KaeruShi HUB Loaded",
    Content = "Ready to fish!",
    Duration = 5,
    Image = 4483362458
})

print("KaeruShi HUB V0.1 - Loaded!")
print("Using YOUR working fishing method")
print("Teleport system from dev1.lua integrated")
print("Anti-Cheat protection active")
print("Ready to fish!")
