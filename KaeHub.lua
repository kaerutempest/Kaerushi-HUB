-- KaeruShi HUB v0.3 | Manual UI Edition
-- Anti-Cheat Optimized | No Rayfield

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ====================================================================
-- HIDDEN STATE (tidak terekspos ke global)
-- ====================================================================
local _ = {}
_.active = false
_.casting = false
_.currentTab = 1
_.cfg = {}
_.defCfg = {
    af = false, as = false, ac = false, gpu = false,
    fd = 1.2, cd = 0.4, sd = 45, loc = "Sisyphus Statue",
    afav = true, favR = "Mythic"
}
for k, v in pairs(_.defCfg) do _.cfg[k] = v end

-- ====================================================================
-- RANDOM DELAY (distribusi normal)
-- ====================================================================
local function randDelay(mean, variance)
    local u1, u2 = math.random(), math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.max(0.05, mean + (variance * z0))
end

-- ====================================================================
-- CONFIG SAVE/LOAD
-- ====================================================================
local cfgFolder = "KaeruShiData"
local cfgFile = cfgFolder .. "/cfg_" .. LP.UserId .. ".json"
local function ensureFolder()
    if not isfolder then return false end
    if not isfolder(cfgFolder) then pcall(function() makefolder(cfgFolder) end) end
    return isfolder(cfgFolder)
end
local function saveCfg()
    if not writefile or not ensureFolder() then return end
    pcall(function() writefile(cfgFile, HS:JSONEncode(_.cfg)) end)
end
local function loadCfg()
    if not readfile or not isfile or not isfile(cfgFile) then return end
    pcall(function()
        local d = HS:JSONDecode(readfile(cfgFile))
        for k, v in pairs(d) do if _.defCfg[k] == nil then _.cfg[k] = v end end
    end)
end
loadCfg()

-- ====================================================================
-- LOCATIONS (sama seperti sebelumnya)
-- ====================================================================
local locs = {
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
local function tp(n)
    local cf = locs[n]
    if not cf then return end
    pcall(function()
        local c = LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = cf
        end
    end)
end

-- ====================================================================
-- GPU SAVER
-- ====================================================================
local gpuActive, ws = false, nil
local function gpuOn()
    if gpuActive then return end
    gpuActive = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        setfpscap(8)
    end)
    ws = Instance.new("ScreenGui")
    ws.ResetOnSpawn = false
    ws.DisplayOrder = 999999
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    f.Parent = ws
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
    ws.Parent = game.CoreGui
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
    if ws then ws:Destroy() ws = nil end
end

-- ====================================================================
-- NETWORK EVENTS
-- ====================================================================
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

-- ====================================================================
-- FAVORITE MODULES
-- ====================================================================
local ItemUtility = require(RS.Shared.ItemUtility)
local Replion = require(RS.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")
local RarityTiers = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7 }
local function getRarityValue(r) return RarityTiers[r] or 0 end
local function getFishRarity(d) return d and d.Data and d.Data.Rarity or "Common" end

local faved = {}
local function isFav(uuid)
    local s,r = pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            if it.UUID == uuid then return it.Favorited == true end
        end
        return false
    end)
    return s and r or false
end
local function autoFav()
    if not _.cfg.afav then return end
    local target = _.cfg.favR
    local tv = getRarityValue(target)
    if tv < 6 then tv = 6 end
    pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            local data = ItemUtility:GetItemData(it.Id)
            if data and data.Data then
                local r = getFishRarity(data)
                if getRarityValue(r) == tv and tv >= 6 then
                    if not isFav(it.UUID) and not faved[it.UUID] then
                        ev.fav:FireServer(it.UUID)
                        faved[it.UUID] = true
                        task.wait(randDelay(0.3, 0.1))
                    end
                end
            end
        end
    end)
end
task.spawn(function() while task.wait(randDelay(10, 3)) do if _.cfg.afav then autoFav() end end end)

-- ====================================================================
-- FISHING CORE
-- ====================================================================
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
        ev.charge:InvokeServer(1755848498.4834)
        task.wait(randDelay(0.02, 0.01))
        ev.mini:InvokeServer(1.2854545116425, 1)
    end)
end

local function reel()
    pcall(function() ev.fish:FireServer() end)
end

-- Main loop (tersembunyi)
local fishingState = { _.active, false }
coroutine.wrap(function()
    while true do
        if fishingState[1] and not fishingState[2] then
            fishingState[2] = true
            task.wait(randDelay(0.4, 0.2))
            cast()
            task.wait(randDelay(_.cfg.fd, 0.3))
            reel()
            task.wait(randDelay(_.cfg.cd, 0.15))
            fishingState[2] = false
            task.wait(randDelay(0.8, 0.5))
        end
        task.wait(0.1)
    end
end)()

-- Auto catch
task.spawn(function()
    while true do
        task.wait(randDelay(_.cfg.cd, 0.1))
        if _.cfg.ac and not fishingState[2] then
            pcall(function() ev.fish:FireServer() end)
        end
    end
end)

-- Auto sell
local function sell()
    pcall(function() ev.sell:InvokeServer() end)
end
task.spawn(function()
    while true do
        task.wait(_.cfg.sd)
        if _.cfg.as then sell() end
    end
end)

-- Anti-AFK
task.spawn(function()
    while _.active do
        task.wait(randDelay(45, 15))
        pcall(function()
            UIS:SetMouseDelta(Vector2.new(math.random(-8,8), math.random(-5,5)))
        end)
    end
end)

-- ====================================================================
-- UI MANUAL (Tanpa Rayfield)
-- ====================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "KS"  -- nama pendek tidak mencurigakan
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 540)
frame.Position = UDim2.new(0.5, -180, 0.5, -270)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(255, 255, 255)
shadow.Transparency = 0.9
shadow.Thickness = 1
shadow.Parent = frame

-- Blur effect
local blur = Instance.new("BlurEffect")
blur.Size = 8
blur.Parent = frame

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ KaeruShi HUB"
title.TextColor3 = Color3.fromRGB(0, 150, 255)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 20)
subtitle.Position = UDim2.new(0, 20, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Fish It | v0.3"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = titleBar

-- Tab buttons
local tabs = {"🎣 Fishing", "🌍 Teleport", "⚙️ Settings", "ℹ️ Info"}
local tabButtons = {}
local tabFrames = {}

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 0, 35)
    btn.Position = UDim2.new((i-1)*0.25, 0, 0, 45)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(35, 35, 45)
    btn.BackgroundTransparency = i == 1 and 0.2 or 0.5
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    tabButtons[i] = btn
    
    -- Tab content frame
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 1, -90)
    tabFrame.Position = UDim2.new(0, 10, 0, 85)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = i == 1
    tabFrame.Parent = frame
    tabFrames[i] = tabFrame
    
    btn.MouseButton1Click:Connect(function()
        for j, tb in ipairs(tabButtons) do
            tb.BackgroundColor3 = j == i and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(35, 35, 45)
            tb.BackgroundTransparency = j == i and 0.2 or 0.5
        end
        for j, tf in ipairs(tabFrames) do
            tf.Visible = j == i
        end
        _.currentTab = i
    end)
end

-- ========== TAB 1: FISHING ==========
local t1 = tabFrames[1]

-- Auto Fish toggle
local afBtn = Instance.new("TextButton")
afBtn.Size = UDim2.new(1, 0, 0, 45)
afBtn.Position = UDim2.new(0, 0, 0, 0)
afBtn.BackgroundColor3 = _.cfg.af and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
afBtn.Text = _.cfg.af and "▶ Auto Fish: ON" or "⏸ Auto Fish: OFF"
afBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
afBtn.TextSize = 14
afBtn.Font = Enum.Font.GothamSemibold
afBtn.BorderSizePixel = 0

local afCorner = Instance.new("UICorner")
afCorner.CornerRadius = UDim.new(0, 8)
afCorner.Parent = afBtn
afBtn.Parent = t1

afBtn.MouseButton1Click:Connect(function()
    _.cfg.af = not _.cfg.af
    _.active = _.cfg.af
    afBtn.Text = _.cfg.af and "▶ Auto Fish: ON" or "⏸ Auto Fish: OFF"
    afBtn.BackgroundColor3 = _.cfg.af and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
    statusLabel.Text = _.cfg.af and "● Fishing..." or "● Idle"
    statusLabel.TextColor3 = _.cfg.af and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 150, 150)
    saveCfg()
end)

-- Auto Catch toggle (risky)
local acBtn = Instance.new("TextButton")
acBtn.Size = UDim2.new(1, 0, 0, 45)
acBtn.Position = UDim2.new(0, 0, 0, 55)
acBtn.BackgroundColor3 = _.cfg.ac and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(45, 45, 55)
acBtn.Text = _.cfg.ac and "⚠️ Auto Catch: ON (RISK)" or "🎯 Auto Catch: OFF"
acBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
acBtn.TextSize = 14
acBtn.Font = Enum.Font.GothamSemibold
acBtn.BorderSizePixel = 0

local acCorner = Instance.new("UICorner")
acCorner.CornerRadius = UDim.new(0, 8)
acCorner.Parent = acBtn
acBtn.Parent = t1

acBtn.MouseButton1Click:Connect(function()
    _.cfg.ac = not _.cfg.ac
    acBtn.Text = _.cfg.ac and "⚠️ Auto Catch: ON (RISK)" or "🎯 Auto Catch: OFF"
    acBtn.BackgroundColor3 = _.cfg.ac and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(45, 45, 55)
    saveCfg()
end)

-- Fish Delay input
local fdLabel = Instance.new("TextLabel")
fdLabel.Size = UDim2.new(0.5, -5, 0, 30)
fdLabel.Position = UDim2.new(0, 0, 0, 110)
fdLabel.BackgroundTransparency = 1
fdLabel.Text = "Fish Delay: " .. _.cfg.fd .. "s"
fdLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
fdLabel.TextSize = 12
fdLabel.TextXAlignment = Enum.TextXAlignment.Left
fdLabel.Font = Enum.Font.Gotham
fdLabel.Parent = t1

local fdInput = Instance.new("TextBox")
fdInput.Size = UDim2.new(0.4, 0, 0, 30)
fdInput.Position = UDim2.new(0.6, 0, 0, 110)
fdInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
fdInput.Text = tostring(_.cfg.fd)
fdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
fdInput.TextSize = 12
fdInput.Font = Enum.Font.Gotham
fdInput.PlaceholderText = "1.2"
fdInput.Parent = t1

local fdCorner = Instance.new("UICorner")
fdCorner.CornerRadius = UDim.new(0, 6)
fdCorner.Parent = fdInput

fdInput.FocusLost:Connect(function()
    local n = tonumber(fdInput.Text)
    if n and n >= 0.8 and n <= 5 then
        _.cfg.fd = n
        fdLabel.Text = "Fish Delay: " .. n .. "s"
        saveCfg()
    else
        fdInput.Text = tostring(_.cfg.fd)
    end
end)

-- Catch Delay input
local cdLabel = Instance.new("TextLabel")
cdLabel.Size = UDim2.new(0.5, -5, 0, 30)
cdLabel.Position = UDim2.new(0, 0, 0, 145)
cdLabel.BackgroundTransparency = 1
cdLabel.Text = "Catch Delay: " .. _.cfg.cd .. "s"
cdLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
cdLabel.TextSize = 12
cdLabel.TextXAlignment = Enum.TextXAlignment.Left
cdLabel.Font = Enum.Font.Gotham
cdLabel.Parent = t1

local cdInput = Instance.new("TextBox")
cdInput.Size = UDim2.new(0.4, 0, 0, 30)
cdInput.Position = UDim2.new(0.6, 0, 0, 145)
cdInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
cdInput.Text = tostring(_.cfg.cd)
cdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
cdInput.TextSize = 12
cdInput.Font = Enum.Font.Gotham
cdInput.Parent = t1

local cdCorner = Instance.new("UICorner")
cdCorner.CornerRadius = UDim.new(0, 6)
cdCorner.Parent = cdInput

cdInput.FocusLost:Connect(function()
    local n = tonumber(cdInput.Text)
    if n and n >= 0.2 and n <= 2 then
        _.cfg.cd = n
        cdLabel.Text = "Catch Delay: " .. n .. "s"
        saveCfg()
    else
        cdInput.Text = tostring(_.cfg.cd)
    end
end)

-- Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 1)
sep.Position = UDim2.new(0, 0, 0, 190)
sep.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
sep.BackgroundTransparency = 0.5
sep.Parent = t1

-- Auto Sell toggle
local asBtn = Instance.new("TextButton")
asBtn.Size = UDim2.new(1, 0, 0, 45)
asBtn.Position = UDim2.new(0, 0, 0, 200)
asBtn.BackgroundColor3 = _.cfg.as and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
asBtn.Text = _.cfg.as and "💰 Auto Sell: ON" or "💰 Auto Sell: OFF"
asBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
asBtn.TextSize = 14
asBtn.Font = Enum.Font.GothamSemibold
asBtn.BorderSizePixel = 0

local asCorner = Instance.new("UICorner")
asCorner.CornerRadius = UDim.new(0, 8)
asCorner.Parent = asBtn
asBtn.Parent = t1

asBtn.MouseButton1Click:Connect(function()
    _.cfg.as = not _.cfg.as
    asBtn.Text = _.cfg.as and "💰 Auto Sell: ON" or "💰 Auto Sell: OFF"
    asBtn.BackgroundColor3 = _.cfg.as and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
    saveCfg()
end)

-- Sell Delay input
local sdLabel = Instance.new("TextLabel")
sdLabel.Size = UDim2.new(0.5, -5, 0, 30)
sdLabel.Position = UDim2.new(0, 0, 0, 255)
sdLabel.BackgroundTransparency = 1
sdLabel.Text = "Sell Delay: " .. _.cfg.sd .. "s"
sdLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
sdLabel.TextSize = 12
sdLabel.TextXAlignment = Enum.TextXAlignment.Left
sdLabel.Font = Enum.Font.Gotham
sdLabel.Parent = t1

local sdInput = Instance.new("TextBox")
sdInput.Size = UDim2.new(0.4, 0, 0, 30)
sdInput.Position = UDim2.new(0.6, 0, 0, 255)
sdInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
sdInput.Text = tostring(_.cfg.sd)
sdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
sdInput.TextSize = 12
sdInput.Font = Enum.Font.Gotham
sdInput.Parent = t1

local sdCorner = Instance.new("UICorner")
sdCorner.CornerRadius = UDim.new(0, 6)
sdCorner.Parent = sdInput

sdInput.FocusLost:Connect(function()
    local n = tonumber(sdInput.Text)
    if n and n >= 15 and n <= 300 then
        _.cfg.sd = n
        sdLabel.Text = "Sell Delay: " .. n .. "s"
        saveCfg()
    else
        sdInput.Text = tostring(_.cfg.sd)
    end
end)

-- Sell Now button
local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(1, 0, 0, 40)
sellBtn.Position = UDim2.new(0, 0, 0, 295)
sellBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
sellBtn.Text = "💰 Sell All Now"
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.TextSize = 14
sellBtn.Font = Enum.Font.GothamSemibold
sellBtn.BorderSizePixel = 0

local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 8)
sellCorner.Parent = sellBtn
sellBtn.Parent = t1

sellBtn.MouseButton1Click:Connect(function()
    sellBtn.Text = "⏳ Selling..."
    task.spawn(function()
        sell()
        task.wait(0.5)
        sellBtn.Text = "💰 Sell All Now"
    end)
end)

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, 345)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = _.active and "● Fishing..." or "● Idle"
statusLabel.TextColor3 = _.active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = t1

-- ========== TAB 2: TELEPORT ==========
local t2 = tabFrames[2]

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.Position = UDim2.new(0, 0, 0, 0)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #locs * 40)
scroll.ScrollBarThickness = 4
scroll.Parent = t2

local yPos = 0
for name, _ in pairs(locs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = "📍 " .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = scroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function() tp(name) end)
    yPos = yPos + 40
end

-- ========== TAB 3: SETTINGS ==========
local t3 = tabFrames[3]

-- GPU Saver toggle
local gpuBtn = Instance.new("TextButton")
gpuBtn.Size = UDim2.new(1, 0, 0, 45)
gpuBtn.Position = UDim2.new(0, 0, 0, 0)
gpuBtn.BackgroundColor3 = _.cfg.gpu and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
gpuBtn.Text = _.cfg.gpu and "💻 GPU Saver: ON" or "💻 GPU Saver: OFF"
gpuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
gpuBtn.TextSize = 14
gpuBtn.Font = Enum.Font.GothamSemibold
gpuBtn.BorderSizePixel = 0

local gpuCorner = Instance.new("UICorner")
gpuCorner.CornerRadius = UDim.new(0, 8)
gpuCorner.Parent = gpuBtn
gpuBtn.Parent = t3

gpuBtn.MouseButton1Click:Connect(function()
    _.cfg.gpu = not _.cfg.gpu
    gpuBtn.Text = _.cfg.gpu and "💻 GPU Saver: ON" or "💻 GPU Saver: OFF"
    gpuBtn.BackgroundColor3 = _.cfg.gpu and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
    if _.cfg.gpu then gpuOn() else gpuOff() end
    saveCfg()
end)

-- Auto Favorite toggle
local favBtn = Instance.new("TextButton")
favBtn.Size = UDim2.new(1, 0, 0, 45)
favBtn.Position = UDim2.new(0, 0, 0, 55)
favBtn.BackgroundColor3 = _.cfg.afav and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
favBtn.Text = _.cfg.afav and "⭐ Auto Favorite: ON" or "⭐ Auto Favorite: OFF"
favBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
favBtn.TextSize = 14
favBtn.Font = Enum.Font.GothamSemibold
favBtn.BorderSizePixel = 0

local favCorner = Instance.new("UICorner")
favCorner.CornerRadius = UDim.new(0, 8)
favCorner.Parent = favBtn
favBtn.Parent = t3

favBtn.MouseButton1Click:Connect(function()
    _.cfg.afav = not _.cfg.afav
    favBtn.Text = _.cfg.afav and "⭐ Auto Favorite: ON" or "⭐ Auto Favorite: OFF"
    favBtn.BackgroundColor3 = _.cfg.afav and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(45, 45, 55)
    saveCfg()
end)

-- Favorite Rarity dropdown
local favLabel = Instance.new("TextLabel")
favLabel.Size = UDim2.new(1, 0, 0, 30)
favLabel.Position = UDim2.new(0, 0, 0, 110)
favLabel.BackgroundTransparency = 1
favLabel.Text = "Favorite Rarity: " .. _.cfg.favR
favLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
favLabel.TextSize = 13
favLabel.Font = Enum.Font.Gotham
favLabel.Parent = t3

local favRarityBtn = Instance.new("TextButton")
favRarityBtn.Size = UDim2.new(0.5, 0, 0, 35)
favRarityBtn.Position = UDim2.new(0.25, 0, 0, 145)
favRarityBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
favRarityBtn.Text = _.cfg.favR
favRarityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
favRarityBtn.TextSize = 13
favRarityBtn.Font = Enum.Font.GothamSemibold
favRarityBtn.BorderSizePixel = 0
favRarityBtn.Parent = t3

local favRarityCorner = Instance.new("UICorner")
favRarityCorner.CornerRadius = UDim.new(0, 8)
favRarityCorner.Parent = favRarityBtn

local rarityOptions = {"Mythic", "Secret"}
local rarityIndex = rarityOptions[1] == _.cfg.favR and 1 or 2
favRarityBtn.MouseButton1Click:Connect(function()
    rarityIndex = rarityIndex % 2 + 1
    local newRarity = rarityOptions[rarityIndex]
    _.cfg.favR = newRarity
    favLabel.Text = "Favorite Rarity: " .. newRarity
    favRarityBtn.Text = newRarity
    saveCfg()
end)

-- Favorite Now button
local favNowBtn = Instance.new("TextButton")
favNowBtn.Size = UDim2.new(1, 0, 0, 40)
favNowBtn.Position = UDim2.new(0, 0, 0, 195)
favNowBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 40)
favNowBtn.Text = "⭐ Favorite All Now"
favNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
favNowBtn.TextSize = 14
favNowBtn.Font = Enum.Font.GothamSemibold
favNowBtn.BorderSizePixel = 0

local favNowCorner = Instance.new("UICorner")
favNowCorner.CornerRadius = UDim.new(0, 8)
favNowCorner.Parent = favNowBtn
favNowBtn.Parent = t3

favNowBtn.MouseButton1Click:Connect(function()
    favNowBtn.Text = "⏳ Processing..."
    task.spawn(function()
        autoFav()
        task.wait(0.5)
        favNowBtn.Text = "⭐ Favorite All Now"
    end)
end)

-- ========== TAB 4: INFO ==========
local t4 = tabFrames[4]

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, 0, 0, 35)
infoTitle.Position = UDim2.new(0, 0, 0, 0)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = "KaeruShi HUB v0.3"
infoTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
infoTitle.TextSize = 18
infoTitle.Font = Enum.Font.GothamBold
infoTitle.Parent = t4

local infoContent = Instance.new("TextLabel")
infoContent.Size = UDim2.new(1, 0, 0, 200)
infoContent.Position = UDim2.new(0, 0, 0, 40)
infoContent.BackgroundTransparency = 1
infoContent.Text = "• Auto Fishing (Human-like)\n• Auto Sell (Keeps Favorites)\n• Auto Catch (High Risk)\n• Teleport System\n• GPU Saver Mode\n• Auto Favorite (Mythic/Secret)\n• Anti-AFK Protection\n• Tablet Optimized"
infoContent.TextColor3 = Color3.fromRGB(200, 200, 220)
infoContent.TextSize = 12
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextYAlignment = Enum.TextYAlignment.Top
infoContent.Font = Enum.Font.Gotham
infoContent.Parent = t4

local warning = Instance.new("TextLabel")
warning.Size = UDim2.new(1, 0, 0, 80)
warning.Position = UDim2.new(0, 0, 0, 250)
warning.BackgroundTransparency = 1
warning.Text = "⚠️ Auto Catch = High Risk\nUse at your own risk.\nRecommended Fish Delay > 1.0s"
warning.TextColor3 = Color3.fromRGB(255, 150, 100)
warning.TextSize = 11
warning.TextXAlignment = Enum.TextXAlignment.Left
warning.Font = Enum.Font.Gotham
warning.Parent = t4

-- Watermark (tanpa nama library)
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, 0, 0, 20)
watermark.Position = UDim2.new(0, 0, 1, -25)
watermark.BackgroundTransparency = 1
watermark.Text = "KS | v0.3"
watermark.TextColor3 = Color3.fromRGB(100, 100, 120)
watermark.TextSize = 10
watermark.Font = Enum.Font.Gotham
watermark.Parent = frame

-- Drag functionality
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Keybind toggle (F)
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        frame.Visible = not frame.Visible
    end
end)

frame.Parent = gui

print("KaeruShi HUB v0.3 | Manual UI | Ready")
