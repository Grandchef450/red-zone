local table = lib.table
-- START EVERY event/callback, etc with so we get player source and player statebags:
    -- local player = Ox.GetPlayer(source)
    -- local state = Player(source).state
--print(variable)
--print(json.encode(variable, { indent = true }))

local ResetStress = false

RegisterNetEvent('hud:server:GainStress', function(amount)
    if Config.DisableStress then return end
    local player = Ox.GetPlayer(source)
    local state = Player(source).state
    local src = source
    local Job = state.inService
    local newStress
    if not player or Config.WhitelistedJobs[Job] then return end
    if not ResetStress then
        newStress = player.getStatus('stress') + amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    player.setStatus('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    --TriggerClientEvent('QBCore:Notify', src, 'Gained Stress', 'error', 1500)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    if Config.DisableStress then return end
    local player = Ox.GetPlayer(source)
    local state = Player(source).state
    local src = source
    local newStress
    if not player then return end
    if not ResetStress then
        newStress = player.getStatus('stress') - amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    player.setStatus('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    --TriggerClientEvent('QBCore:Notify', src, 'Feeling Much Better')
end)