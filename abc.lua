local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Bezpieczna emulacja kliknięć
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Pobieramy bezpieczną dla Twojego executora przestrzeń interfejsu
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Statusy (Domyślnie włączają się od razu automatycznie)
local lilyEspEnabled = true
local chestEspEnabled = true
local autoFarmEnabled = false

local savedLilies = {}
local savedChests = {}

-- Obiekty fizyczne do blokady pozycji (Weld-Lock)
local farmWeld = nil

-- Czyszczenie starych śmieci
if PlayerGui:FindFirstChild("NoGui_RenderScreen") then PlayerGui.NoGui_RenderScreen:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoGui_RenderScreen"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Powiadomienie tekstowe o uruchomieniu
local function createNotify(txt, color)
    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(0, 300, 0, 30)
    nt.Position = UDim2.new(0.5, -150, 0.15, 0)
    nt.BackgroundTransparency = 1
    nt.Text = txt
    nt.TextColor3 = color
    nt.TextSize = 20
    nt.Font = Enum.Font.SourceSansBold
    nt.TextStrokeTransparency = 0
    nt.Parent = screenGui
    task.wait(2.5)
    nt:Destroy()
end

task.spawn(function() createNotify("🚀 SKRYPT ZAŁADOWANY! [L]-Lilie [P]-Skrzynie [H]-Farm", Color3.fromRGB(50, 255, 100)) end)

-- Funkcja uwalniająca postać z blokady (Weld-Lock)
local function clearLockOn()
    if farmWeld then pcall(function() farmWeld:Destroy() end) farmWeld = nil end
    
    local myChar = LocalPlayer.Character
    if myChar then
        local humanoid = myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = false end
        -- Przywracamy standardową grawitację i kolizje
        if myRoot then myRoot.CanCollide = true end
    end
end

-- Przypisanie klawiszy do przełączania funkcji
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        lilyEspEnabled = not lilyEspEnabled
        task.spawn(function() createNotify("🌸 Lily ESP: " .. (lilyEspEnabled and "ON" or "OFF"), lilyEspEnabled and Color3.fromRGB(255,100,100) or Color3.fromRGB(200,200,200)) end)
    elseif input.KeyCode == Enum.KeyCode.P then
        chestEspEnabled = not chestEspEnabled
        task.spawn(function() createNotify("📦 Chest ESP: " .. (chestEspEnabled and "ON" or "OFF"), chestEspEnabled and Color3.fromRGB(255,180,50) or Color3.fromRGB(200,200,200)) end)
    elseif input.KeyCode == Enum.KeyCode.H then
        autoFarmEnabled = not autoFarmEnabled
        if not autoFarmEnabled then clearLockOn() end
        task.spawn(function() createNotify("⚔️ Auto Farm & Attack: " .. (autoFarmEnabled and "ON" or "OFF"), autoFarmEnabled and Color3.fromRGB(50,255,100) or Color3.fromRGB(200,200,200)) end)
    end
end)

-- Funkcja pomocnicza dla linii i tekstu ESP
local function createVisuals(color)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 200, 0, 30)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Visible = false
    textLabel.Parent = screenGui

    local tracer = Instance.new("Frame")
    tracer.Size = UDim2.new(0, 2, 0, 0)
    tracer.BackgroundColor3 = color
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.Visible = false
    tracer.Parent = screenGui

    return textLabel, tracer
end

-- Bezpieczne pobieranie najbliższego NPC (Grove Raider)
local function getClosestNPC()
    local closestNPC = nil
    local shortestDistance = math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    pcall(function()
        local folder = workspace.Humanoids.Regions.Temporary.ActiveNpcs["Grove Raider"]
        for _, npc in ipairs(folder:GetChildren()) do
            if npc.Name == "Grove Raider" and npc:FindFirstChild("HumanoidRootPart") then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (myRoot.Position - npc.HumanoidRootPart.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestNPC = npc
                    end
                end
            end
        end
    end)
    return closestNPC
end

-- PĘTLA AUTO ATTACK (Wykonuje automatyczne kliknięcia, kiedy farm jest włączony)
task.spawn(function()
    while true do
        if autoFarmEnabled and farmWeld and farmWeld.Parent then
            pcall(function()
                -- Emuluje fizyczne kliknięcie lewego myszki (Mouse Button 1) na środku ekranu
                VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1)
            end)
        end
        task.wait(0.1) -- Szybkość ataku: 10 razy na sekundę
    end
end)

-- Skaner w tle (wykrywa spawny przedmiotów)
task.spawn(function()
    while true do
        pcall(function()
            local debree = workspace:FindFirstChild("Debree")
            if debree then
                for _, child in ipairs(debree:GetChildren()) do
                    if (child.Name == "Spider Lily" or child.Name == "SpiderLily") and not savedLilies[child] then
                        local p = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                        if p then
                            local l, t = createVisuals(Color3.fromRGB(255, 40, 40))
                            savedLilies[child] = { Position = p.Position, Label = l, Tracer = t, LastSeen = tick() }
                        end
                    end
                    if savedLilies[child] then savedLilies[child].LastSeen = tick() end
                end
            end
        end)

        pcall(function()
            local chests = workspace:FindFirstChild("Chests")
            if chests then
                for _, child in ipairs(chests:GetChildren()) do
                    if child.Name == "Sealed Cache T1" and not savedChests[child] then
                        local p = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                        if p then
                            local l, t = createVisuals(Color3.fromRGB(255, 165, 0))
                            savedChests[child] = { Position = p.Position, Label = l, Tracer = t, LastSeen = tick() }
                        end
                    end
                    if savedChests[child] then savedChests[child].LastSeen = tick() end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- Renderer ESP
local function updateEspGroup(database, enabledFlag, iconName, maxCollectDist)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for object, data in pairs(database) do
        local isCollected = false
        if myRoot then
            local distToPoint = (myRoot.Position - data.Position).Magnitude
            if distToPoint < maxCollectDist and (tick() - data.LastSeen) > 5 then
                isCollected = true
            end
        end

        if isCollected then
            data.Label:Destroy()
            data.Tracer:Destroy()
            database[object] = nil
        elseif enabledFlag then
            local screenPos, onScreen = Camera:WorldToViewportPoint(data.Position)
            if onScreen then
                local distance = myRoot and math.round((myRoot.Position - data.Position).Magnitude) or 0
                data.Label.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - 40)
                data.Label.Text = iconName .. " [" .. distance .. " studs]"
                data.Label.Visible = true
                
                local screenWidth, screenHeight = Camera.ViewportSize.X, Camera.ViewportSize.Y
                local startX, startY = screenWidth / 2, screenHeight
                local deltaX, deltaY = screenPos.X - startX, screenPos.Y - startY
                
                data.Tracer.Position = UDim2.new(0, startX, 0, startY)
                data.Tracer.Size = UDim2.new(0, 2, 0, math.sqrt(deltaX^2 + deltaY^2))
                data.Tracer.Rotation = math.deg(math.atan2(deltaY, deltaX)) - 90
                data.Tracer.Visible = true
            else
                data.Label.Visible = false
                data.Tracer.Visible = false
            end
        else
            data.Label.Visible = false
            data.Tracer.Visible = false
        end
    end
end

-- SYSTEM REJESTRACJI I UNIERUCHOMIENIA KONTROLI FAZY RUCHU
local isTweening = false

RunService.RenderStepped:Connect(function()
    updateEspGroup(savedLilies, lilyEspEnabled, "🌸 Spider Lily", 80)
    updateEspGroup(savedChests, chestEspEnabled, "📦 Sealed Cache T1", 50)
    
    if autoFarmEnabled then
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
        
        if myRoot and humanoid and humanoid.Health > 0 then
