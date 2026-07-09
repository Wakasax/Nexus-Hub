-- Nexus Hub (minimal)
-- Mantém apenas a library Fluent e um botão para ligar/desligar o auto-click

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

-- Estado do auto-click
local autoClick = false
local clickDelay = 0.1 -- segundos entre cliques

local function startAutoClick()
    if autoClick then return end
    autoClick = true
    coroutine.wrap(function()
        while autoClick do
            pcall(function()
                -- Simula clique do botão esquerdo na posição (0,0)
                VirtualUser:Button1Down(Vector2.new(0, 0))
                VirtualUser:Button1Up(Vector2.new(0, 0))
            end)
            task.wait(clickDelay)
        end
    end)()
end

local function stopAutoClick()
    autoClick = false
end

-- Interface mínima com Fluent
local Window = Fluent:CreateWindow({
    Title = "Nexus Hub",
    SubTitle = "Minimal",
    Size = UDim2.new(0, 300, 0, 150),
    Theme = "Dark",
    Source = "https://github.com/Wakasax/Nexus-Hub"
})

local Tab = Window:AddTab({ Title = "Main", Icon = "power" })

Tab:AddParagraph({
    Title = "Auto Click",
    Content = "Use o toggle abaixo para ligar/desligar o auto-click."
})

Tab:AddToggle("Toggle_AutoClick", {
    Title = "Ativar Auto-Click",
    Default = false,
    Callback = function(Value)
        if Value then
            startAutoClick()
        else
            stopAutoClick()
        end
    end
})

Window:Dialog({
    Title = "Pronto",
    Content = "Interface mínima carregada.",
    Buttons = {{ Title = "OK", Callback = function() end }}
})
