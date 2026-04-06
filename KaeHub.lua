-- [[ 🌊 AQUA HUB | FISH IT (UI REDESIGN) ]]
-- All original features preserved: Auto Cast, Insta Fish, Auto Sell, Anti Staff, Anti AFK, Teleports, Config Save/Load
-- New UI: sleek dark theme, neon cyan accents, draggable window, toggle switches, clean layout

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- // 📂 SETTINGS (SAME AS ORIGINAL) //
_G.Settings = {
    AutoCast = false,
    InstaFish = false,
    AutoSell = false,
    AntiStaff = false,
    AntiAFK = true,
    InstaDelay = 0.5,
    InstaMode = "Perfect",
    CastDelay = 1.0,
    SellThreshold = 100,
    SellRarity = "All",
    AntiStaffMode = "Alert",
    TeleportSpots = {
        {name = "🏝️ Tropical Grove", cf = CFrame.new(-115, 4, 215)},
        {name = "🌋 Kohana Volcano", cf = CFrame.new(-490, 48, -112)},
        {name = "🪸 Coral Reefs", cf = CFrame.new(310, -12, -275)},
        {name = "🌊 Esoteric Depths", cf = CFrame.new(120, -85, 480)},
        {name = "🏝️ The Lost Isle", cf = CFrame.new(620, 15, -380)},
        {name = "🌋 Crater Island", cf = CFrame.new(-350, 32, 385)},
        {name = "🍄 Mushroom Grove", cf = CFrame.new(95, 22, -520)}
    },
    ThemeColor = Color3.fromRGB(0, 200, 255),  -- neon cyan
    BgColor = Color3.fromRGB(12, 12, 18),
    HeaderColor = Color3.fromRGB(8, 8, 12)
}

-- Fish counter & session
local FishCaught = 0
local SessionStart = os.time()

-- // 🔧 UTILITY FUNCTIONS (UNCHANGED) //
local function randomWait(minSec, maxSec)
    task.wait(math.random(minSec * 100, maxSec * 100) / 100)
end

local function getNet()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if not packages then return nil end
    local index = packages:FindFirstChild("_Index")
    if not index then return nil end
    for _, child in ipairs(index:GetChildren()) do
        if child.Name:match("sleitnick_net@") then
            local net = child:FindFirstChild("net")
            if net then return net end
        end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == "net" and obj:IsA("ModuleScript") then
            return obj
        end
    end
    return nil
end

local function GetRod()
    return lp.Character and lp.Character:FindFirstChildOfClass("Tool")
end

local function CastRod()
    local rod = GetRod()
    if rod then
        rod:Activate()
        local rem = ReplicatedStorage:FindFirstChild("Cast", true) or ReplicatedStorage:FindFirstChild("Events", true)
        if rem and rem:IsA("RemoteEvent") then
            rem:FireServer()
        end
    end
end

local function CatchFish(mode)
    mode = mode or _G.Settings.InstaMode
    local catchMode = mode
    if mode == "Random" then
        catchMode = (math.random() > 0.5) and "Perfect" or "Good"
    end

    local net = getNet()
    if not net then
        warn("[AQUA] Net library not found – fishing disabled")
        return
    end

    local equip = net:FindFirstChild("RE/EquipToolFromHotbar")
    local charge = net:FindFirstChild("RF/ChargeFishingRod")
    local startMinigame = net:FindFirstChild("RF/RequestFishingMinigameStarted")
    local complete = net:FindFirstChild("RE/FishingCompleted")

    if not (equip and charge and startMinigame and complete) then
        warn("[AQUA] Fishing remotes missing")
        return
    end

    equip:FireServer()
    randomWait(0.05, 0.15)
    charge:InvokeServer(1)
    randomWait(0.05, 0.15)
    startMinigame:InvokeServer(1, 1)
    randomWait(0.05, 0.15)
    complete:FireServer()

    FishCaught = FishCaught + 1
end

local function SellFish()
    local rem = ReplicatedStorage:FindFirstChild("SellFish", true) or ReplicatedStorage:FindFirstChild("Sell", true)
    if rem and rem:IsA("RemoteEvent") then
        rem:FireServer()
    else
        local sellButton = lp.PlayerGui:FindFirstChild("SellButton", true)
        if sellButton and sellButton:IsA("TextButton") then
            sellButton:Click()
        end
    end
end

local function IsStaff(player)
    if player:GetRankInGroup(123456) >= 200 then return true end
    if player.Name:lower():match("admin") then return true end
    return false
end

local function HandleStaff()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and IsStaff(player) then
            if _G.Settings.AntiStaffMode == "Alert" then
                print("[AQUA] Staff detected: " .. player.Name)
            elseif _G.Settings.AntiStaffMode == "AutoLeave" then
                lp:Kick("Staff detected")
            elseif _G.Settings.AntiStaffMode == "AutoHop" then
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end
            break
        end
    end
end

local function TeleportTo(spotCFrame)
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = spotCFrame
    end
end

local function SaveConfig()
    local configStr = game:GetService("HttpService"):JSONEncode(_G.Settings)
    setclipboard(configStr)
    print("[AQUA] Config saved to clipboard")
end

local function LoadConfig(jsonStr)
    local success, data = pcall(function() return game:GetService("HttpService"):JSONDecode(jsonStr) end)
    if success and data then
        for k, v in pairs(data) do
            _G.Settings[k] = v
        end
        print("[AQUA] Config loaded")
        return true
    else
        print("[AQUA] Invalid config")
        return false
    end
end

-- // 🎨 NEW UI CONSTRUCTION (REDESIGNED) //
local ScreenGui = Instance.new("ScreenGui", lp.PlayerGui)
ScreenGui.Name = "AquaHubUI"
ScreenGui.ResetOnSpawn = false

-- Floating Minimized Button
local FloatingBtn = Instance.new("TextButton", ScreenGui)
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Position = UDim2.new(0, 15, 0.5, -25)
FloatingBtn.BackgroundColor3 = _G.Settings.BgColor
FloatingBtn.Text = "🌊"
FloatingBtn.TextSize = 26
FloatingBtn.Visible = false
FloatingBtn.ZIndex = 15
local FloatCorner = Instance.new("UICorner", FloatingBtn)
FloatCorner.CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = _G.Settings.ThemeColor
FloatStroke.Thickness = 2

-- Main Window
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 520, 0, 440)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -220)
MainFrame.BackgroundColor3 = _G.Settings.BgColor
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = _G.Settings.ThemeColor
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3

-- Header (draggable)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = _G.Settings.HeaderColor
Header.BorderSizePixel = 0
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "🌊 AQUA HUB | FISH IT"
Title.TextColor3 = Color3.fromRGB(230, 240, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local MiniBtn = Instance.new("TextButton", Header)
MiniBtn.Size = UDim2.new(0, 40, 1, 0)
MiniBtn.Position = UDim2.new(1, -80, 0, 0)
MiniBtn.Text = "—"
MiniBtn.TextColor3 = Color3.fromRGB(255,255,255)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 20

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18

-- Tab Bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.new(0, 0, 0, 44)
TabBar.BackgroundTransparency = 1

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Content Container
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -104)
ContentFrame.Position = UDim2.new(0, 10, 0, 84)
ContentFrame.BackgroundTransparency = 1

-- Pages table
local Pages = {}
local function CreateTab(name, icon)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 90, 0, 32)
    btn.BackgroundTransparency = 1
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Color3.fromRGB(160, 170, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    
    local page = Instance.new("ScrollingFrame", ContentFrame)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 12)
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
    end)
    
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabBar:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(160, 170, 200) end end
        page.Visible = true
        btn.TextColor3 = _G.Settings.ThemeColor
    end)
    
    table.insert(Pages, page)
    return page
end

-- Helper: Create a card (rounded panel)
local function AddCard(parent, title)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    card.AutomaticSize = Enum.AutomaticSize.Y
    local cardCorner = Instance.new("UICorner", card)
    cardCorner.CornerRadius = UDim.new(0, 10)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(40, 40, 50)
    cardStroke.Thickness = 1
    
    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(200, 210, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local content = Instance.new("Frame", card)
    content.Size = UDim2.new(1, -20, 0, 0)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y
    
    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    return card, content
end

-- Modern Toggle Switch
local function CreateToggle(parent, text, initial, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 230, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local switchBg = Instance.new("Frame", frame)
    switchBg.Size = UDim2.new(0, 50, 0, 26)
    switchBg.Position = UDim2.new(1, -60, 0.5, -13)
    switchBg.BackgroundColor3 = initial and _G.Settings.ThemeColor or Color3.fromRGB(60, 60, 80)
    local switchCorner = Instance.new("UICorner", switchBg)
    switchCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", switchBg)
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = initial and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local toggled = initial
    switchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggled = not toggled
            switchBg.BackgroundColor3 = toggled and _G.Settings.ThemeColor or Color3.fromRGB(60, 60, 80)
            local targetPos = toggled and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = targetPos}):Play()
            callback(toggled)
        end
    end)
    
    return frame
end

-- Slider input (number)
local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 210, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = _G.Settings.ThemeColor
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local slider = Instance.new("Frame", frame)
    slider.Size = UDim2.new(1, 0, 0, 4)
    slider.Position = UDim2.new(0, 0, 0, 28)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = _G.Settings.ThemeColor
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", slider)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function updateSlider(inputPos)
        local relX = inputPos.X - slider.AbsolutePosition.X
        local width = slider.AbsoluteSize.X
        local t = math.clamp(relX / width, 0, 1)
        local val = min + t * (max - min)
        if val then
            val = math.floor(val * 100) / 100
            valueLabel.Text = tostring(val)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, -7, 0.5, -7)
            callback(val)
        end
    end
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return frame
end

-- Dropdown
local function CreateDropdown(parent, text, options, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 210, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.5, 0, 1, -8)
    btn.Position = UDim2.new(0.5, 0, 0, 4)
    btn.Text = default
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.TextColor3 = Color3.fromRGB(220, 230, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local menu = Instance.new("Frame", frame)
    menu.Size = UDim2.new(0.5, 0, 0, 0)
    menu.Position = UDim2.new(0.5, 0, 1, 0)
    menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    menu.Visible = false
    local menuCorner = Instance.new("UICorner", menu)
    menuCorner.CornerRadius = UDim.new(0, 6)
    local menuLayout = Instance.new("UIListLayout", menu)
    menuLayout.Padding = UDim.new(0, 2)
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", menu)
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.Text = opt
        optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        optBtn.TextColor3 = Color3.fromRGB(200, 210, 240)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = opt
            callback(opt)
            menu.Visible = false
            menu.Size = UDim2.new(0.5, 0, 0, 0)
        end)
    end
    
    btn.MouseButton1Click:Connect(function()
        if menu.Visible then
            menu.Visible = false
            menu.Size = UDim2.new(0.5, 0, 0, 0)
        else
            menu.Visible = true
            menu.Size = UDim2.new(0.5, 0, 0, #options * 32)
        end
    end)
    
    return frame
end

-- Simple button
local function AddButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.TextColor3 = Color3.fromRGB(220, 230, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- // BUILD TABS //
local mainTab = CreateTab("Main", "🎣")
local teleportTab = CreateTab("Teleport", "🗺️")
local settingsTab = CreateTab("Settings", "⚙️")

-- MAIN TAB
local mainCard, mainContent = AddCard(mainTab, "FISHING CONTROLS")
-- Auto Cast
CreateToggle(mainContent, "Auto Cast", _G.Settings.AutoCast, function(state)
    _G.Settings.AutoCast = state
end)
-- Insta Fish
CreateToggle(mainContent, "Instant Fishing", _G.Settings.InstaFish, function(state)
    _G.Settings.InstaFish = state
end)
-- Insta Delay slider
CreateSlider(mainContent, "Instant Delay (sec)", 0.1, 2.0, _G.Settings.InstaDelay, function(val)
    _G.Settings.InstaDelay = val
end)
-- Insta Mode dropdown
CreateDropdown(mainContent, "Catch Mode", {"Perfect", "Good", "Random"}, _G.Settings.InstaMode, function(val)
    _G.Settings.InstaMode = val
end)
-- Auto Cast delay slider
CreateSlider(mainContent, "Cast Delay (sec)", 0.5, 5.0, _G.Settings.CastDelay, function(val)
    _G.Settings.CastDelay = val
end)
-- Auto Sell
CreateToggle(mainContent, "Auto Sell", _G.Settings.AutoSell, function(state)
    _G.Settings.AutoSell = state
end)
CreateSlider(mainContent, "Sell Threshold (value ≤)", 10, 1000, _G.Settings.SellThreshold, function(val)
    _G.Settings.SellThreshold = val
end)
CreateDropdown(mainContent, "Sell Rarity", {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}, _G.Settings.SellRarity, function(val)
    _G.Settings.SellRarity = val
end)

-- Teleport Tab
local teleCard, teleContent = AddCard(teleportTab, "QUICK TRAVEL")
for _, spot in ipairs(_G.Settings.TeleportSpots) do
    AddButton(teleContent, spot.name, function()
        TeleportTo(spot.cf)
    end)
end

-- Settings Tab
local setCard, setContent = AddCard(settingsTab, "PROTECTION & CONFIG")
CreateToggle(setContent, "Anti AFK", _G.Settings.AntiAFK, function(state)
    _G.Settings.AntiAFK = state
end)
CreateToggle(setContent, "Anti Staff", _G.Settings.AntiStaff, function(state)
    _G.Settings.AntiStaff = state
end)
CreateDropdown(setContent, "Anti Staff Mode", {"Alert", "AutoLeave", "AutoHop"}, _G.Settings.AntiStaffMode, function(val)
    _G.Settings.AntiStaffMode = val
end)
AddButton(setContent, "💾 Save Config (to Clipboard)", SaveConfig)
AddButton(setContent, "📂 Load Config (paste from clipboard)", function()
    local clipboard = getclipboard()
    if clipboard and clipboard ~= "" then
        LoadConfig(clipboard)
    else
        print("[AQUA] Clipboard empty")
    end
end)

-- // ENGINE LOOP (SAME AS ORIGINAL) //
task.spawn(function()
    local lastCast = 0
    local lastStaffCheck = 0
    local lastSell = 0
    while task.wait(math.random(8, 15)/10) do
        local now = tick()
        if _G.Settings.AutoCast then
            local rod = GetRod()
            if rod and not rod:FindFirstChild("FishingLine") and now - lastCast >= _G.Settings.CastDelay then
                lastCast = now
                CastRod()
            end
        end
        if _G.Settings.InstaFish then
            local rod = GetRod()
            if rod and rod:FindFirstChild("FishingLine") then
                local delay = _G.Settings.InstaDelay
                if delay > 0 then
                    local variation = math.random(-20, 20)/100
                    local finalDelay = math.max(0, delay + variation)
                    task.wait(finalDelay)
                end
                CatchFish()
            end
        end
        if _G.Settings.AutoSell and now - lastSell > 5 then
            lastSell = now
            SellFish()
        end
        if _G.Settings.AntiStaff and now - lastStaffCheck > 5 then
            lastStaffCheck = now
            HandleStaff()
        end
    end
end)

-- Anti AFK (camera wiggle)
local cam = workspace.CurrentCamera
lp.Idled:Connect(function()
    if _G.Settings.AntiAFK and cam then
        local original = cam.CFrame
        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(1), 0)
        task.wait(0.2)
        cam.CFrame = original
    end
end)

-- Watermark
local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Size = UDim2.new(0, 240, 0, 28)
Watermark.Position = UDim2.new(1, -250, 1, -38)
Watermark.Text = "🌊 AQUA HUB | 🐟 0 | ⏱️ 00:00:00"
Watermark.TextColor3 = Color3.fromRGB(180, 200, 255)
Watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
Watermark.BackgroundTransparency = 0.5
Watermark.Font = Enum.Font.Gotham
Watermark.TextSize = 11
local wmCorner = Instance.new("UICorner", Watermark)
wmCorner.CornerRadius = UDim.new(0, 8)

task.spawn(function()
    while task.wait(1) do
        local elapsed = os.time() - SessionStart
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60
        Watermark.Text = string.format("🌊 AQUA HUB | 🐟 %d | ⏱️ %02d:%02d:%02d", FishCaught, hours, minutes, seconds)
    end
end)

-- // DRAG & MINIMIZE //
local function MakeDraggable(frame, handle)
    local drag = false
    local dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputChanged:Connect(function(input)
        if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)
end

MakeDraggable(MainFrame, Header)

MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)
FloatingBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingBtn.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Show first tab
Pages[1].Visible = true
local firstTab = TabBar:FindFirstChildOfClass("TextButton")
if firstTab then firstTab.TextColor3 = _G.Settings.ThemeColor end

print("🌊 AQUA HUB | FISH IT - UI Redesigned. All features preserved.")
