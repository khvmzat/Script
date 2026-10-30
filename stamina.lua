local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MAX_STAMINA = 100
local enabled = true

local status = Drawing.new("Text")
pcall(function()
    status.Visible = true
    status.Outline = true
    status.Center = false
    status.Color = Color3.fromRGB(0, 255, 120)
    status.Position = Vector2.new(20, 20)
    status.Text = "Infinite Stamina: ON"
end)

local function setStatus(s)
    pcall(function() status.Text = s end)
end

-- Boucle principale : sécurisée, se rattache à chaque nouveau personnage
task.spawn(function()
    while true do
        if enabled then
            local ok, err = pcall(function()
                local char = LocalPlayer.Character
                if char then
                    char:SetAttribute("Stamina", MAX_STAMINA)
                end
            end)
            if not ok then
                setStatus("Infinite Stamina: ERREUR " .. tostring(err))
            end
        end
        task.wait(0.03)
    end
end)

-- Essai d'ajout d'un toggle dans le menu Matcha (facultatif, le script marche sans)
pcall(function()
    UI.AddTab("Street Life", function(tab)
        local sec = tab:Section("Player", "Left")
        sec:Toggle("inf_stamina", "Infinite Stamina", function(state)
            enabled = state
            setStatus(state and "Infinite Stamina: ON" or "Infinite Stamina: OFF")
        end)
    end)
end)
