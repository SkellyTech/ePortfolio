-- Full Death Recap System (Client Side)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowDeathRecap = ReplicatedStorage:WaitForChild("ShowDeathRecap")

local gui = script.Parent:WaitForChild("DeathRecapFrame")
gui.Visible = false

-- Helper function to display attacker info
local function displayAttackerInfo(attackerName, info)
    local labelText = attackerName .. " killed you"
    gui.AttackerLabel.Text = labelText
    gui.DamageLabel.Text = "Total Damage: " .. info.total
    if info.sources[1] then
        gui.SourceLabel.Text = "With: " .. info.sources[1].source
    else
        gui.SourceLabel.Text = "With: Kopis"
    end
    if info.distance then
        gui.DistanceLabel.Text = string.format("Distance: %.2f studs", info.distance)
    else
        gui.DistanceLabel.Text = ""
    end
end

ShowDeathRecap.OnClientEvent:Connect(function(summary)
    gui.Visible = true

    -- Find top attacker by total damage
    local topAttacker, topInfo
    for attacker, info in pairs(summary) do
        if not topInfo or info.total > topInfo.total then
            topAttacker, topInfo = attacker, info
        end
    end

    if topAttacker then
        displayAttackerInfo(topAttacker, topInfo)
    else
        gui.AttackerLabel.Text = "You died"
        gui.DamageLabel.Text = "Damage: 0"
        gui.SourceLabel.Text = "With: Kopis"
        gui.DistanceLabel.Text = "Distance:"
    end

    -- Optional: hide GUI after 5 seconds
    delay(15, function()
        gui.Visible = false
    end)
end)
