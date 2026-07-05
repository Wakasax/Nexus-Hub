local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local running = true
local attackRunning = true
local bossAttackRunning = true
local killAuraEnabled = true
local autoFarmKillsEnabled = true
local windowOpen = true

local coinDelay = 1
local attackDelay = 0.1
local bossAttackDelay = 1
local killAuraDelay = 0.2

local currentTarget = nil
local hasTeleported = false
local normalWalkSpeed = 16

local attackRemote = nil
local dummiesFolder = nil

pcall(function()
    attackRemote = ReplicatedStorage:WaitForChild("jdskhfsIIIllliiIIIdchgdIiIIIlIlIli", 5)
end)

pcall(function()
    dummiesFolder = workspace:WaitForChild("MAP", 5):WaitForChild("dummies", 5)
end)

local bosses = {
    "ROCKY", "Griffin", "BOOSBEAR", "BOSSDEER",
    "CENTAUR", "CRABBOSS", "DragonGiraffe", "LavaGorilla"
}

local function getCharacterAndRoot()
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        return character, rootPart
    end
    return nil, nil
end

local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local char = otherPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < 10 and dist < shortestDist then
                    shortestDist = dist
                    closest = otherPlayer
                end
            end
        end
    end
    return closest
end

local function findFirstAliveDummy()
    if not dummiesFolder then return nil end
    for _, dummy in ipairs(dummiesFolder:GetChildren()) do
        if dummy.Name == "Dummy" and dummy:FindFirstChild("Humanoid") and dummy.Humanoid.Health > 0 then
            return dummy
        end
    end
    return nil
end

local function getAlivePlayers()
    local alivePlayers = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(alivePlayers, p)
        end
    end
    return alivePlayers
end

local function orbitAroundPlayer(targetHRP, myRoot)
    local radius = 5
    local angle = 0
    local center = targetHRP.Position
    local startTime = os.clock()
    while (os.clock() - startTime) < 1 do
        angle = angle + 0.1
        if angle >= 2 * math.pi then
            angle = 0
        end
        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        myRoot.CFrame = CFrame.new(center + offset)
        task.wait()
    end
end

local function collectCoins()
    while running do
        local coinContainer = workspace:FindFirstChild("CoinContainer")
        local coinEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CoinEvent")
        if coinContainer and coinEvent then
            for _, template in pairs(coinContainer:GetChildren()) do
                local coin = template:FindFirstChild("Coin")
                if coin and (coin:IsA("Part") or coin:IsA("MeshPart")) then
                    pcall(function()
                        coinEvent:FireServer()
                    end)
                    task.wait(coinDelay)
                end
            end
        end
        task.wait(1)
    end
end

local function attackDummies()
    hasTeleported = false
    currentTarget = nil
    while attackRunning do
        local character, rootPart = getCharacterAndRoot()
        if not character or not rootPart then
            player.CharacterAdded:Wait()
            character, rootPart = getCharacterAndRoot()
        end
        if currentTarget and currentTarget.Parent and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
            if attackRemote then
                pcall(function()
                    attackRemote:FireServer(currentTarget.Humanoid, 6)
                end)
            end
            task.wait(attackDelay)
        else
            local dummy = findFirstAliveDummy()
            if dummy then
                currentTarget = dummy
                if not hasTeleported and rootPart then
                    local dummyRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy.PrimaryPart
                    if dummyRoot then
                        rootPart.CFrame = dummyRoot.CFrame * CFrame.new(0, 0, 3)
                        hasTeleported = true
                        task.wait(attackDelay)
                    end
                end
            else
                task.wait(2)
            end
        end
    end
end

local function attackAllBosses()
    while bossAttackRunning do
        for _, bossName in ipairs(bosses) do
            local boss = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild(bossName)
            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                coroutine.wrap(function()
                    while bossAttackRunning and boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 do
                        if attackRemote then
                            pcall(function()
                                attackRemote:FireServer(boss.Humanoid, 5)
                            end)
                        end
                        task.wait(bossAttackDelay)
                    end
                end)()
            end
        end
        task.wait(1)
    end
end

local function killAura()
    while killAuraEnabled do
        local character, root = getCharacterAndRoot()
        if not character or not root then
            player.CharacterAdded:Wait()
            character, root = getCharacterAndRoot()
        end
        local enemy = getNearestEnemy()
        if enemy and enemy.Character then
            local humanoid = enemy.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if attackRemote then
                    pcall(function()
                        attackRemote:FireServer(humanoid, 1)
                    end)
                end
            end
        end
        task.wait(killAuraDelay)
    end
end

local function autoFarmKills()
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Wait()
        killAuraEnabled = false
    end)
    while autoFarmKillsEnabled do
        local myChar, myRoot = getCharacterAndRoot()
        if not myChar or not myRoot or myChar:FindFirstChild("Humanoid") == nil or myChar.Humanoid.Health <= 0 then
            player.CharacterAdded:Wait()
            task.wait(1)
        else
            local alivePlayers = getAlivePlayers()
            if #alivePlayers == 0 then
                task.wait(2)
            else
                for _, targetPlayer in pairs(alivePlayers) do
                    if not autoFarmKillsEnabled then break end
                    local targetChar = targetPlayer.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
                    if targetHRP and targetHum and targetHum.Health > 0 then
                        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
                        local tween = TweenService:Create(myRoot, tweenInfo, {CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)})
                        tween:Play()
                        tween.Completed:Wait()
                        orbitAroundPlayer(targetHRP, myRoot)
                        killAuraEnabled = true
                        coroutine.wrap(killAura)()
                    end
                end
            end
        end
        task.wait(0.5)
    end
    killAuraEnabled = false
end

local Window = Fluent:CreateWindow({
    Title = "Nexus Hub",
    SubTitle = "Anime Astral Simulator",
    TabWidth = 160,
    Size = UDim2.new(0, 580, 0, 460),
    Acrylic = false,
    Theme = "Dark",
    Source = "https://github.com/Wakasax/Nexus-Hub"
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

Tabs.Home:AddParagraph({
    Title = "Bem-vindo ao Nexus Hub!",
    Content = "Anime Astral Simulator Auto Farm Script\nDesenvolvido por: Wakasa\n\nUse as abas para controlar o script!"
})

Tabs.Home:AddButton({
    Title = "Copiar Discord",
    Description = "Copie o link do Discord",
    Callback = function()
        setclipboard("https://discord.gg/AEZRrzUaTR")
        Window:Dialog({
            Title = "Sucesso!",
            Content = "Link do Discord copiado para a área de transferência!",
            Buttons = {
                {
                    Title = "OK",
                    Callback = function() end
                }
            }
        })
    end
})

Tabs.AutoFarm:AddToggle("Toggle_Coins", {
    Title = "Coletar Moedas",
    Default = running,
    Callback = function(Value)
        running = Value
        if Value then
            coroutine.wrap(collectCoins)()
        end
    end
})

Tabs.AutoFarm:AddToggle("Toggle_Dummy", {
    Title = "Atacar Bonecos (Dummy)",
    Default = attackRunning,
    Callback = function(Value)
        attackRunning = Value
        if Value then
            coroutine.wrap(attackDummies)()
        end
    end
})

Tabs.AutoFarm:AddToggle("Toggle_Boss", {
    Title = "Atacar Chefes (Boss)",
    Default = bossAttackRunning,
    Callback = function(Value)
        bossAttackRunning = Value
        if Value then
            coroutine.wrap(attackAllBosses)()
        end
    end
})

Tabs.AutoFarm:AddToggle("Toggle_KillAura", {
    Title = "Kill Aura",
    Default = killAuraEnabled,
    Callback = function(Value)
        killAuraEnabled = Value
        if Value then
            coroutine.wrap(killAura)()
        end
    end
})

Tabs.AutoFarm:AddToggle("Toggle_AutoFarmKills", {
    Title = "Auto Farm Kills",
    Default = autoFarmKillsEnabled,
    Callback = function(Value)
        autoFarmKillsEnabled = Value
        if Value then
            coroutine.wrap(autoFarmKills)()
        end
    end
})

Tabs.AutoFarm:AddDivider()

Tabs.AutoFarm:AddSlider("Slider_CoinDelay", {
    Title = "Delay Coleta de Moedas",
    Description = "Tempo em segundos",
    Min = 0.1,
    Max = 5,
    Rounding = 0.1,
    Callback = function(Value)
        coinDelay = Value
    end
})

Tabs.AutoFarm:AddSlider("Slider_AttackDelay", {
    Title = "Delay Ataque Normal",
    Description = "Tempo em segundos",
    Min = 0.05,
    Max = 2,
    Rounding = 0.05,
    Callback = function(Value)
        attackDelay = Value
    end
})

Tabs.AutoFarm:AddSlider("Slider_BossDelay", {
    Title = "Delay Ataque Boss",
    Description = "Tempo em segundos",
    Min = 0.1,
    Max = 3,
    Rounding = 0.1,
    Callback = function(Value)
        bossAttackDelay = Value
    end
})

Tabs.AutoFarm:AddSlider("Slider_AuraDelay", {
    Title = "Delay Kill Aura",
    Description = "Tempo em segundos",
    Min = 0.1,
    Max = 2,
    Rounding = 0.05,
    Callback = function(Value)
        killAuraDelay = Value
    end
})

Tabs.Settings:AddButton({
    Title = "Parar Tudo",
    Description = "Desativa todas as funções",
    Callback = function()
        running = false
        attackRunning = false
        bossAttackRunning = false
        killAuraEnabled = false
        autoFarmKillsEnabled = false
        Window:Dialog({
            Title = "Aviso",
            Content = "Todos os scripts foram parados!",
            Buttons = {
                {
                    Title = "OK",
                    Callback = function() end
                }
            }
        })
    end
})

Tabs.Settings:AddButton({
    Title = "Iniciar Tudo",
    Description = "Ativa todas as funções",
    Callback = function()
        running = true
        attackRunning = true
        bossAttackRunning = true
        killAuraEnabled = true
        autoFarmKillsEnabled = true
        coroutine.wrap(collectCoins)()
        coroutine.wrap(attackDummies)()
        coroutine.wrap(attackAllBosses)()
        coroutine.wrap(killAura)()
        coroutine.wrap(autoFarmKills)()
        Window:Dialog({
            Title = "Sucesso",
            Content = "Todos os scripts foram iniciados!",
            Buttons = {
                {
                    Title = "OK",
                    Callback = function() end
                }
            }
        })
    end
})

Tabs.Settings:AddParagraph({
    Title = "Info",
    Content = "Pressione a tecla K para abrir/fechar a interface"
})

local FloatingButton = Instance.new("ScreenGui")
FloatingButton.Name = "NexusFloatingButton"
FloatingButton.ResetOnSpawn = false
FloatingButton.Parent = player:WaitForChild("PlayerGui")

local ButtonFrame = Instance.new("ImageButton")
ButtonFrame.Name = "FloatingButton"
ButtonFrame.Size = UDim2.new(0, 60, 0, 60)
ButtonFrame.Position = UDim2.new(1, -80, 1, -80)
ButtonFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonFrame.BackgroundTransparency = 0.3
ButtonFrame.Image = "rbxassetid://109968882783196"
ButtonFrame.ScaleType = Enum.ScaleType.Stretch
ButtonFrame.Draggable = true
ButtonFrame.Parent = FloatingButton

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 30)
UICorner.Parent = ButtonFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(100, 200, 255)
UIStroke.Parent = ButtonFrame

ButtonFrame.MouseButton1Click:Connect(function()
    windowOpen = not windowOpen
    Window:Toggle(windowOpen)
end)

ButtonFrame.MouseEnter:Connect(function()
    TweenService:Create(ButtonFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(150, 255, 100)}):Play()
end)

ButtonFrame.MouseLeave:Connect(function()
    TweenService:Create(ButtonFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(UIStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(100, 200, 255)}):Play()
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetOption("Dockable", false)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

Window:Dialog({
    Title = "Bem-vindo!",
    Content = "Nexus Hub carregado com sucesso!\n\nClique no botão flutuante para abrir/fechar a interface",
    Buttons = {
        {
            Title = "Começar",
            Callback = function() end
        }
    }
})

coroutine.wrap(collectCoins)()
coroutine.wrap(attackDummies)()
coroutine.wrap(attackAllBosses)()
coroutine.wrap(killAura)()
coroutine.wrap(autoFarmKills)()
