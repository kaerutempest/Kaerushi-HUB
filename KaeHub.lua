-- 🌸 KaeruShi HUB | V0.1 | Fish It
-- UI: Floating Logo + Popup (from Kae Tempest)
-- Core: Original KaeruShi fishing logic (random delays, original remote values)

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

-- ========================
-- KONFIGURASI (dari KaeruShi original)
-- ========================
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
    AntiStaff = false,
    AntiStaffMode = "Alert",
    AntiAFK = true,
}

-- Helper: random delay (distribusi normal)
local function randDelay(mean, variance)
    local u1, u2 = math.random(), math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.max(0.05, mean + (variance * z0))
end

-- ========================
-- NETWORK EVENTS & FISHING CORE (dari KaeruShi original)
-- ========================
local ev = {}
local function getRemotes()
    local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
    if not net then return {} end
    local r = net:FindFirstChild("net")
    if not r then return {} end
    local remotes = {}
    local names = {"RE/FishingCompleted", "RF/SellAllItems", "RF/ChargeFishingRod", "RF/RequestFishingMinigameStarted", "RE/EquipToolFromHotbar", "RE/UnequipToolFromHotbar", "RE/FavoriteItem"}
    for _, name in ipairs(names) do
        local obj = r:FindFirstChild(name)
        if obj then remotes[name] = obj end
    end
    return remotes
end
ev = getRemotes()

-- Modules untuk auto favorite
local ItemUtility, Replion, PlayerData
pcall(function()
    ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    Replion = require(ReplicatedStorage.Packages.Replion)
    PlayerData = Replion.Client:WaitReplion("Data")
end)

local RarityTiers = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7 }
local function getRarityValue(r) return RarityTiers[r] or 0 end
local function getFishRarity(d) return d and d.Data and d.Data.Rarity or "Common" end

local favorited = {}
local function isFav(uuid)
    if not PlayerData then return false end
    local s,r = pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            if it.UUID == uuid then return it.Favorited == true end
        end
        return false
    end)
    return s and r or false
end
local function autoFavorite()
    if not Config.AutoFavorite or not PlayerData then return end
    local targetRarity = Config.FavoriteRarity
    local targetVal = getRarityValue(targetRarity)
    if targetVal < 6 then targetVal = 6 end
    pcall(function()
        for _,it in ipairs(PlayerData:GetExpect("Inventory").Items) do
            local data = ItemUtility and ItemUtility:GetItemData(it.Id)
            if data and data.Data then
                local r = getFishRarity(data)
                if getRarityValue(r) == targetVal and targetVal >= 6 then
                    if not isFav(it.UUID) and not favorited[it.UUID] then
                        if ev["RE/FavoriteItem"] then
                            ev["RE/FavoriteItem"]:FireServer(it.UUID)
                            favorited[it.UUID] = true
                            task.wait(randDelay(0.3, 0.1))
                        end
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
    local c = lp.Character
    if c and c:FindFirstChildOfClass("Tool") then return true end
    if ev["RE/EquipToolFromHotbar"] then
        pcall(function()
            ev["RE/EquipToolFromHotbar"]:FireServer(1)
            task.wait(randDelay(0.05, 0.02))
        end)
    end
    return true
end

local function cast()
    if not ev["RF/ChargeFishingRod"] or not ev["RF/RequestFishingMinigameStarted"] then return end
    pcall(function()
        equipRod()
        ev["RF/ChargeFishingRod"]:InvokeServer(1755848498.4834)  -- nilai asli
        task.wait(randDelay(0.02, 0.01))
        ev["RF/RequestFishingMinigameStarted"]:InvokeServer(1.2854545116425, 1) -- nilai asli
    end)
end

local function reel()
    if ev["RE/FishingCompleted"] then
        pcall(function() ev["RE/FishingCompleted"]:FireServer() end)
    end
end

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

-- Auto catch
task.spawn(function()
    while true do
        task.wait(randDelay(Config.CatchDelay, 0.1))
        if Config.AutoCatch and not casting and ev["RE/FishingCompleted"] then
            pcall(function() ev["RE/FishingCompleted"]:FireServer() end)
        end
    end
end)

-- Auto sell
local function sellAll()
    if ev["RF/SellAllItems"] then
        pcall(function() ev["RF/SellAllItems"]:InvokeServer() end)
    end
end
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then sellAll() end
    end
end)

-- Anti-AFK (camera wiggle)
local cam = workspace.CurrentCamera
lp.Idled:Connect(function()
    if Config.AntiAFK and cam then
        local original = cam.CFrame
        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(1), 0)
        task.wait(0.2)
        cam.CFrame = original
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

-- ========================
-- TELEPORT LOCATIONS (Mount Hallow dihapus)
-- ========================
local LOCATIONS = {
    Spawn = CFrame.new(45.2788086, 252.562927, 2987.10913, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Sisyphus Statue"] = CFrame.new(-3728.21606, -135.074417, -1012.12744, -0.977224171, 7.74980258e-09, -0.212209702, 1.566994e-08, 1, -3.5640408e-08, 0.212209702, -3.81539813e-08, -0.977224171),
    ["Coral Reefs"] = CFrame.new(-3114.78198, 1.32066584, 2237.52295, -0.304758579, 1.6556676e-08, -0.952429652, -8.50574935e-08, 1, 4.46003305e-08, 0.952429652, 9.46036067e-08, -0.304758579),
    ["Esoteric Depths"] = CFrame.new(3248.37109, -1301.53027, 1403.82727, -0.920208454, 7.76270355e-08, 0.391428679, 4.56261056e-08, 1, -9.10549289e-08, -0.391428679, -6.5930152e-08, -0.920208454),
    ["Crater Island"] = CFrame.new(1016.49072, 20.0919304, 5069.27295, 0.838976264, 3.30379857e-09, -0.544168055, 2.63538391e-09, 1, 1.01344115e-08, 0.544168055, -9.93662219e-09, 0.838976264),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298, 1, 0, 0, 0, 1, 0, 0, 1),
    ["Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    -- Mount Hallow dihapus karena event selesai
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
        local char = lp.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cf
        end
    end)
end

-- ========================
-- ANTI STAFF
-- ========================
local function IsStaff(player)
    if player:GetRankInGroup(123456) >= 200 then return true end
    if player.Name:lower():match("admin") then return true end
    return false
end

local function HandleStaff()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and IsStaff(player) then
            if Config.AntiStaffMode == "Alert" then
                print("[KaeruShi] Staff detected: " .. player.Name)
            elseif Config.AntiStaffMode == "AutoLeave" then
                lp:Kick("Staff detected")
            elseif Config.AntiStaffMode == "AutoHop" then
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end
            break
        end
    end
end

task.spawn(function()
    while task.wait(5) do
        if Config.AntiStaff then HandleStaff() end
    end
end)

-- ========================
-- UI (dari Kae Tempest, dimodifikasi)
-- ========================
local ScreenGui = Instance.new("ScreenGui", lp.PlayerGui)
ScreenGui.Name = "KaeruShiHub"
ScreenGui.ResetOnSpawn = false

-- Floating Logo
local FloatingIcon = Instance.new("TextButton", ScreenGui)
FloatingIcon.Size = UDim2.new(0, 55, 0, 55)
FloatingIcon.Position = UDim2.new(0, 20, 0.5, -25)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(10,10,10)
FloatingIcon.Text = "🌸"
FloatingIcon.TextSize = 28
FloatingIcon.Visible = false
FloatingIcon.ZIndex = 15
local IconCorner = Instance.new("UICorner", FloatingIcon)
IconCorner.CornerRadius = UDim.new(1, 0)
local IconStroke = Instance.new("UIStroke", FloatingIcon)
IconStroke.Color = Color3.fromRGB(255,10,140)
IconStroke.Thickness = 2.5

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255,10,140)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4

-- Header (draggable)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(15,15,15)
Header.BorderSizePixel = 0
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "🌸 KaeruShi HUB | V0.1"
Title.TextColor3 = Color3.fromRGB(240,240,240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18

local MiniBtn = Instance.new("TextButton", Header)
MiniBtn.Size = UDim2.new(0, 40, 1, 0)
MiniBtn.Position = UDim2.new(1, -80, 0, 0)
MiniBtn.Text = "—"
MiniBtn.TextColor3 = Color3.fromRGB(255,255,255)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 18

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 150, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(8,8,8)
Sidebar.BorderSizePixel = 0

local SidebarLine = Instance.new("Frame", Sidebar)
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, 0, 0, 0)
SidebarLine.BackgroundColor3 = Color3.fromRGB(255,10,140)
SidebarLine.Transparency = 0.7

local ActiveLine = Instance.new("Frame", Sidebar)
ActiveLine.Size = UDim2.new(0, 3, 0, 32)
ActiveLine.Position = UDim2.new(0, 0, 0, 20)
ActiveLine.BackgroundColor3 = Color3.fromRGB(255,10,140)
ActiveLine.BorderSizePixel = 0
ActiveLine.ZIndex = 10

local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 20)
TabContainer.BackgroundTransparency = 1
local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.Padding = UDim.new(0, 8)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Content area
local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -170, 1, -55)
PageContainer.Position = UDim2.new(0, 165, 0, 55)
PageContainer.BackgroundTransparency = 1

local Pages = {}
local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton", TabContainer)
    TabBtn.Size = UDim2.new(0, 130, 0, 38)
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = icon .. "  " .. name
    TabBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 13
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local Pad = Instance.new("UIPadding", TabBtn); Pad.PaddingLeft = UDim.new(0, 15)

    local Page = Instance.new("ScrollingFrame", PageContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 4
    Page.CanvasSize = UDim2.new(0,0,0,0)
    local PageLayout = Instance.new("UIListLayout", Page); PageLayout.Padding = UDim.new(0, 10)
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0,0,0, PageLayout.AbsoluteContentSize.Y)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabContainer:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(140, 140, 140) end end
        Page.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TweenService:Create(ActiveLine, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, TabBtn.Position.Y)}):Play()
    end)

    table.insert(Pages, Page)
    return Page
end

-- Helper: Show popup (like Kae Tempest)
local function ShowSimplePopup(title, contentBuilder)
    local popup = Instance.new("Frame", ScreenGui)
    popup.Size = UDim2.new(0, 260, 0, 160)
    popup.Position = UDim2.new(0.5, -130, 0.5, -80)
    popup.BackgroundColor3 = Color3.fromRGB(10,10,10)
    popup.BackgroundTransparency = 0.1
    popup.BorderSizePixel = 0
    popup.ZIndex = 20
    local corner = Instance.new("UICorner", popup)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", popup)
    stroke.Color = Color3.fromRGB(255,10,140)
    stroke.Thickness = 1.5

    local header = Instance.new("Frame", popup)
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundColor3 = Color3.fromRGB(15,15,15)
    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 8)

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240,240,240)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local close = Instance.new("TextButton", header)
    close.Size = UDim2.new(0, 32, 1, 0)
    close.Position = UDim2.new(1, -32, 0, 0)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.BackgroundTransparency = 1
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.MouseButton1Click:Connect(function() popup:Destroy() end)

    local content = Instance.new("Frame", popup)
    content.Size = UDim2.new(1, -16, 1, -45)
    content.Position = UDim2.new(0, 8, 0, 40)
    content.BackgroundTransparency = 1

    contentBuilder(content, function() popup:Destroy() end)
end

-- Helper: Input box
local function CreateInputBox(parent, label, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1

    local labelText = Instance.new("TextLabel", frame)
    labelText.Size = UDim2.new(0.4, 0, 1, 0)
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(200,200,200)
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.BackgroundTransparency = 1
    labelText.TextXAlignment = Enum.TextXAlignment.Left

    local inputBox = Instance.new("TextBox", frame)
    inputBox.Size = UDim2.new(0.5, 0, 1, -4)
    inputBox.Position = UDim2.new(0.45, 0, 0, 2)
    inputBox.Text = tostring(default)
    inputBox.PlaceholderText = "Write ur input here"
    inputBox.TextColor3 = Color3.fromRGB(255,255,255)
    inputBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    local inputCorner = Instance.new("UICorner", inputBox)
    inputCorner.CornerRadius = UDim.new(0, 4)

    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            callback(num)
        else
            inputBox.Text = tostring(default)
            callback(default)
        end
    end)
    return frame
end

-- Helper: Dropdown
local function CreateDropdownSimple(parent, label, options, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundTransparency = 1

    local labelText = Instance.new("TextLabel", frame)
    labelText.Size = UDim2.new(0.4, 0, 1, 0)
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(200,200,200)
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.BackgroundTransparency = 1
    labelText.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton", frame)
    dropdownBtn.Size = UDim2.new(0.5, 0, 1, -4)
    dropdownBtn.Position = UDim2.new(0.45, 0, 0, 2)
    dropdownBtn.Text = default
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", dropdownBtn)
    btnCorner.CornerRadius = UDim.new(0, 4)

    local dropdownMenu = Instance.new("Frame", frame)
    dropdownMenu.Size = UDim2.new(0.5, 0, 0, 0)
    dropdownMenu.Position = UDim2.new(0.45, 0, 1, 0)
    dropdownMenu.BackgroundColor3 = Color3.fromRGB(30,30,30)
    dropdownMenu.Visible = false
    dropdownMenu.ZIndex = 2
    local menuCorner = Instance.new("UICorner", dropdownMenu)
    menuCorner.CornerRadius = UDim.new(0, 4)
    local listLayout = Instance.new("UIListLayout", dropdownMenu)
    listLayout.Padding = UDim.new(0, 2)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropdownMenu)
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.Text = opt
        optBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.MouseButton1Click:Connect(function()
            dropdownBtn.Text = opt
            callback(opt)
            dropdownMenu.Visible = false
            dropdownMenu.Size = UDim2.new(0.5, 0, 0, 0)
        end)
    end

    dropdownBtn.MouseButton1Click:Connect(function()
        if dropdownMenu.Visible then
            dropdownMenu.Visible = false
            dropdownMenu.Size = UDim2.new(0.5, 0, 0, 0)
        else
            dropdownMenu.Visible = true
            dropdownMenu.Size = UDim2.new(0.5, 0, 0, #options * 30)
        end
    end)
    return frame
end

-- Helper: Toggle switch
local function CreateSwitch(parent, initial, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0, 55, 0, 28)
    frame.BackgroundColor3 = initial and Color3.fromRGB(255,10,140) or Color3.fromRGB(80,80,80)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame", frame)
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = initial and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1,0)

    local toggled = initial
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggled = not toggled
            frame.BackgroundColor3 = toggled and Color3.fromRGB(255,10,140) or Color3.fromRGB(80,80,80)
            local targetPos = toggled and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
            callback(toggled)
        end
    end)
    return frame
end

-- Helper: Section header
local function AddSection(parent, name)
    local Label = Instance.new("TextLabel", parent)
    Label.Size = UDim2.new(1, 0, 0, 34)
    Label.Text = "[ " .. name:upper() .. " ]"
    Label.TextColor3 = Color3.fromRGB(110,110,110)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
end

-- Helper: Feature with toggle (no popup)
local function AddToggleFeature(parent, text, settingKey, callback)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1, -12, 0, 50)
    Row.BackgroundColor3 = Color3.fromRGB(22,22,22)
    local RowCorner = Instance.new("UICorner", Row); RowCorner.CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 18, 0, 0)
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230,230,230)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local switch = CreateSwitch(Row, Config[settingKey], function(state)
        Config[settingKey] = state
        if callback then callback(state) end
    end)
    switch.Position = UDim2.new(1, -65, 0.5, -14)
    return Row
end

-- Helper: Feature with simple popup (for adjustable settings)
local function AddSimplePopupFeature(parent, text, popupBuilder)
    local Row = Instance.new("TextButton", parent)
    Row.Size = UDim2.new(1, -12, 0, 50)
    Row.BackgroundColor3 = Color3.fromRGB(22,22,22)
    Row.AutoButtonColor = false
    Row.Text = ""
    local RowCorner = Instance.new("UICorner", Row); RowCorner.CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 18, 0, 0)
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230,230,230)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Arrow = Instance.new("TextLabel", Row)
    Arrow.Size = UDim2.new(0, 40, 1, 0)
    Arrow.Position = UDim2.new(1, -45, 0, 0)
    Arrow.Text = "⚙️"
    Arrow.TextColor3 = Color3.fromRGB(90,90,90)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 18
    Arrow.BackgroundTransparency = 1

    Row.MouseButton1Click:Connect(popupBuilder)
    return Row
end

-- ========================
-- CREATE TABS
-- ========================
local MainTab = CreateTab("Main", "🏠")
local TeleportTab = CreateTab("Teleport", "🗺️")
local SecurityTab = CreateTab("Security", "🛡️")
local SettingsTab = CreateTab("Settings", "⚙️")

-- Main Tab
AddSection(MainTab, "Fishing Engine")
-- Auto Fish (toggle)
AddToggleFeature(MainTab, "Auto Fish", "AutoFish", function(state)
    active = state
    if not state then
        pcall(function() if ev["RE/UnequipToolFromHotbar"] then ev["RE/UnequipToolFromHotbar"]:FireServer() end end)
    end
end)
-- Auto Catch (toggle, risky)
AddToggleFeature(MainTab, "Auto Catch (High Risk)", "AutoCatch", nil)
-- Auto Sell (toggle)
AddToggleFeature(MainTab, "Auto Sell", "AutoSell", nil)

-- Fish Delay popup
AddSimplePopupFeature(MainTab, "Fish Delay", function()
    ShowSimplePopup("Fish Delay", function(content, close)
        CreateInputBox(content, "Delay (seconds)", Config.FishDelay, function(val)
            if val and val >= 0.5 and val <= 5 then Config.FishDelay = val end
        end)
        local saveBtn = Instance.new("TextButton", content)
        saveBtn.Size = UDim2.new(0.8, 0, 0, 32)
        saveBtn.Position = UDim2.new(0.1, 0, 1, -35)
        saveBtn.Text = "Save & Close"
        saveBtn.BackgroundColor3 = Color3.fromRGB(255,10,140)
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", saveBtn)
        btnCorner.CornerRadius = UDim.new(0, 5)
        saveBtn.MouseButton1Click:Connect(close)
    end)
end)
-- Catch Delay popup
AddSimplePopupFeature(MainTab, "Catch Delay", function()
    ShowSimplePopup("Catch Delay", function(content, close)
        CreateInputBox(content, "Delay (seconds)", Config.CatchDelay, function(val)
            if val and val >= 0.2 and val <= 2 then Config.CatchDelay = val end
        end)
        local saveBtn = Instance.new("TextButton", content)
        saveBtn.Size = UDim2.new(0.8, 0, 0, 32)
        saveBtn.Position = UDim2.new(0.1, 0, 1, -35)
        saveBtn.Text = "Save & Close"
        saveBtn.BackgroundColor3 = Color3.fromRGB(255,10,140)
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", saveBtn)
        btnCorner.CornerRadius = UDim.new(0, 5)
        saveBtn.MouseButton1Click:Connect(close)
    end)
end)
-- Sell Delay popup
AddSimplePopupFeature(MainTab, "Sell Delay", function()
    ShowSimplePopup("Sell Delay", function(content, close)
        CreateInputBox(content, "Delay (seconds)", Config.SellDelay, function(val)
            if val and val >= 15 and val <= 300 then Config.SellDelay = val end
        end)
        local saveBtn = Instance.new("TextButton", content)
        saveBtn.Size = UDim2.new(0.8, 0, 0, 32)
        saveBtn.Position = UDim2.new(0.1, 0, 1, -35)
        saveBtn.Text = "Save & Close"
        saveBtn.BackgroundColor3 = Color3.fromRGB(255,10,140)
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", saveBtn)
        btnCorner.CornerRadius = UDim.new(0, 5)
        saveBtn.MouseButton1Click:Connect(close)
    end)
end)
-- Sell Now button
local sellNowBtn = Instance.new("TextButton", MainTab)
sellNowBtn.Size = UDim2.new(1, -12, 0, 45)
sellNowBtn.Position = UDim2.new(0, 6, 0, 0)
sellNowBtn.Text = "💰 Sell All Now"
sellNowBtn.BackgroundColor3 = Color3.fromRGB(60,100,60)
sellNowBtn.TextColor3 = Color3.fromRGB(255,255,255)
sellNowBtn.Font = Enum.Font.GothamBold
sellNowBtn.TextSize = 14
local sellNowCorner = Instance.new("UICorner", sellNowBtn)
sellNowCorner.CornerRadius = UDim.new(0, 8)
sellNowBtn.MouseButton1Click:Connect(sellAll)

-- GPU Saver toggle
AddToggleFeature(MainTab, "GPU Saver (Anti-Lag)", "GPUSaver", function(state)
    if state then gpuOn() else gpuOff() end
end)

-- Teleport Tab
AddSection(TeleportTab, "Teleport to Map")
for locName, _ in pairs(LOCATIONS) do
    local btn = Instance.new("TextButton", TeleportTab)
    btn.Size = UDim2.new(1, -12, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(22,22,22)
    btn.Text = locName
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function() teleportTo(locName) end)
end

-- Security Tab
AddSection(SecurityTab, "Protection System")
AddToggleFeature(SecurityTab, "Anti AFK", "AntiAFK", nil)
AddSimplePopupFeature(SecurityTab, "Anti Staff", function()
    ShowSimplePopup("Anti Staff", function(content, close)
        local statusFrame = Instance.new("Frame", content)
        statusFrame.Size = UDim2.new(1, 0, 0, 32)
        statusFrame.BackgroundTransparency = 1
        local statusLabel = Instance.new("TextLabel", statusFrame)
        statusLabel.Size = UDim2.new(0.5, 0, 1, 0)
        statusLabel.Text = "Status:"
        statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 12
        local statusSwitch = CreateSwitch(statusFrame, Config.AntiStaff, function(state)
            Config.AntiStaff = state
        end)
        statusSwitch.Position = UDim2.new(0.6, 0, 0.5, -14)

        CreateDropdownSimple(content, "Mode", {"Alert", "AutoLeave", "AutoHop"}, Config.AntiStaffMode, function(val)
            Config.AntiStaffMode = val
        end)

        local saveBtn = Instance.new("TextButton", content)
        saveBtn.Size = UDim2.new(0.8, 0, 0, 32)
        saveBtn.Position = UDim2.new(0.1, 0, 1, -35)
        saveBtn.Text = "Save & Close"
        saveBtn.BackgroundColor3 = Color3.fromRGB(255,10,140)
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", saveBtn)
        btnCorner.CornerRadius = UDim.new(0, 5)
        saveBtn.MouseButton1Click:Connect(close)
    end)
end)

-- Settings Tab
AddSection(SettingsTab, "Auto Favorite")
AddToggleFeature(SettingsTab, "Auto Favorite", "AutoFavorite", nil)
AddSimplePopupFeature(SettingsTab, "Favorite Rarity", function()
    ShowSimplePopup("Favorite Rarity", function(content, close)
        CreateDropdownSimple(content, "Rarity", {"Mythic", "Secret"}, Config.FavoriteRarity, function(val)
            Config.FavoriteRarity = val
        end)
        local saveBtn = Instance.new("TextButton", content)
        saveBtn.Size = UDim2.new(0.8, 0, 0, 32)
        saveBtn.Position = UDim2.new(0.1, 0, 1, -35)
        saveBtn.Text = "Save & Close"
        saveBtn.BackgroundColor3 = Color3.fromRGB(255,10,140)
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", saveBtn)
        btnCorner.CornerRadius = UDim.new(0, 5)
        saveBtn.MouseButton1Click:Connect(close)
    end)
end)
local favNowBtn = Instance.new("TextButton", SettingsTab)
favNowBtn.Size = UDim2.new(1, -12, 0, 45)
favNowBtn.Text = "⭐ Favorite All Now"
favNowBtn.BackgroundColor3 = Color3.fromRGB(100,80,40)
favNowBtn.TextColor3 = Color3.fromRGB(255,255,255)
favNowBtn.Font = Enum.Font.GothamBold
favNowBtn.TextSize = 14
local favNowCorner = Instance.new("UICorner", favNowBtn)
favNowCorner.CornerRadius = UDim.new(0, 8)
favNowBtn.MouseButton1Click:Connect(autoFavorite)

-- Unload button
local unloadBtn = Instance.new("TextButton", SettingsTab)
unloadBtn.Size = UDim2.new(1, -12, 0, 45)
unloadBtn.Text = "Unload Script"
unloadBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
unloadBtn.TextColor3 = Color3.fromRGB(255,255,255)
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 14
local unloadCorner = Instance.new("UICorner", unloadBtn)
unloadCorner.CornerRadius = UDim.new(0, 8)
unloadBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if screen then screen:Destroy() end
end)

-- Watermark (fish counter optional, but we can include)
local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Size = UDim2.new(0, 220, 0, 28)
Watermark.Position = UDim2.new(1, -230, 1, -38)
Watermark.Text = "🌸 KaeruShi HUB | V0.1"
Watermark.TextColor3 = Color3.fromRGB(200,200,200)
Watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
Watermark.BackgroundTransparency = 0.5
Watermark.Font = Enum.Font.Gotham
Watermark.TextSize = 12
local watermarkCorner = Instance.new("UICorner", Watermark)
watermarkCorner.CornerRadius = UDim.new(0, 5)

-- ========================
-- DRAG FUNCTIONALITY
-- ========================
local function MakeDraggable(frame, handle)
    local drag, dinput, dstart, spos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dstart = input.Position; spos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dstart
            frame.Position = UDim2.new(spos.X.Scale, spos.X.Offset + delta.X, spos.Y.Scale, spos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)
end

MakeDraggable(MainFrame, Header)
MakeDraggable(FloatingIcon, FloatingIcon)

-- Minimize / Restore
MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingIcon.Visible = true
end)
FloatingIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingIcon.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Keybind F untuk toggle UI (seperti sebelumnya)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if MainFrame.Visible then
            MainFrame.Visible = false
            FloatingIcon.Visible = true
        else
            MainFrame.Visible = true
            FloatingIcon.Visible = false
        end
    end
end)

-- Initialize: show MainTab first
Pages[1].Visible = true
TabContainer:FindFirstChildOfClass("TextButton").TextColor3 = Color3.fromRGB(255,255,255)

print("🌸 KaeruShi HUB | V0.1 Loaded – Press F to toggle UI")
