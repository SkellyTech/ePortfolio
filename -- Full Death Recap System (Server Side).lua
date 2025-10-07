-- Full Death Recap System (Server Side)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for sending death recap
local ShowDeathRecap = ReplicatedStorage:FindFirstChild("ShowDeathRecap")
if not ShowDeathRecap then
    ShowDeathRecap = Instance.new("RemoteEvent")
    ShowDeathRecap.Name = "ShowDeathRecap"
    ShowDeathRecap.Parent = ReplicatedStorage
end

-- Table to track damage per player
-- playerDamageData[victimPlayer] = { [attackerPlayer] = {total = X, sources = {{source="Gun", damage=Y}, ...}}, ... }
local playerDamageData = {}

-- Call this whenever a player takes damage
local function registerDamage(victimPlayer, attackerPlayer, damageAmount, source)
    if not victimPlayer then return end
    if not playerDamageData[victimPlayer] then
        playerDamageData[victimPlayer] = {}
    end

    local attackerData = playerDamageData[victimPlayer][attackerPlayer]
    if not attackerData then
        attackerData = {total = 0, sources = {}}
        playerDamageData[victimPlayer][attackerPlayer] = attackerData
    end

    attackerData.total = attackerData.total + damageAmount
    table.insert(attackerData.sources, {source = source, damage = damageAmount})
    
    -- Track last attacker for convenience
    victimPlayer.LastAttacker = attackerPlayer
    victimPlayer.LastDamage = damageAmount
end

-- Connect humanoid death to death recap
local function connectHumanoid(humanoid)
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player then return end

    humanoid.Died:Connect(function()
        local summary = playerDamageData[player] or {}

        -- Calculate distances for each attacker
        for attacker, info in pairs(summary) do
            if player.Character and attacker.Character and 
               player.Character:FindFirstChild("HumanoidRootPart") and 
               attacker.Character:FindFirstChild("HumanoidRootPart") then

                local distance = (player.Character.HumanoidRootPart.Position - attacker.Character.HumanoidRootPart.Position).Magnitude
                info.distance = distance
            end
        end

        -- Fire the death recap to the client
        ShowDeathRecap:FireClient(player, summary)

        -- Optional: handle environmental/unknown kills
        if next(summary) == nil then
            ShowDeathRecap:FireClient(player, {
                ["Unknown"] = {total = 0, sources = {}, distance = 0}
            })
        end

        -- Clear damage data
        playerDamageData[player] = nil
    end)
end

-- Hook new and existing players
local function hookPlayer(player)
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        connectHumanoid(humanoid)
    end)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        connectHumanoid(player.Character.Humanoid)
    end
end

for _, player in pairs(Players:GetPlayers()) do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

-- Example: integrate with Laketech damage system
-- Whenever Laketech applies damage, call:
-- registerDamage(victimPlayer, attackerPlayer, damageAmount, attackSource)
