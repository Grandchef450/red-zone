local activeCarries = {}
local cooldowns = {}

local function CheckCooldown(source)
    local now = os.time()
    if cooldowns[source] and now - cooldowns[source] < Config.Cooldown then
        return false
    end
    cooldowns[source] = now
    return true
end

local function CheckDistance(source, target)
    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(target)
    if not sourcePed or not targetPed then return false end

    local sourceCoords = GetEntityCoords(sourcePed)
    local targetCoords = GetEntityCoords(targetPed)
    return #(sourceCoords - targetCoords) <= Config.MaxDistance + 1.0
end

local function IsInCarry(serverId)
    if activeCarries[serverId] then return true end
    for _, carried in pairs(activeCarries) do
        if carried == serverId then return true end
    end
    return false
end

RegisterNetEvent('Mg_carry:server:carry', function(targetServerId)
    local source = source
    if not targetServerId or type(targetServerId) ~= 'number' then return end
    if not GetPlayerPed(targetServerId) then return end
    if source == targetServerId then return end
    if not CheckCooldown(source) then return end
    if IsInCarry(source) or IsInCarry(targetServerId) then return end
    if not CheckDistance(source, targetServerId) then return end

    activeCarries[source] = targetServerId
    TriggerClientEvent('Mg_carry:client:startCarry', source, targetServerId)
    TriggerClientEvent('Mg_carry:client:beingCarried', targetServerId, source)
end)

RegisterNetEvent('Mg_carry:server:release', function(targetServerId)
    local source = source
    if not targetServerId or type(targetServerId) ~= 'number' then return end
    if activeCarries[source] ~= targetServerId then return end

    activeCarries[source] = nil
    TriggerClientEvent('Mg_carry:client:released', targetServerId)
end)

RegisterNetEvent('Mg_carry:server:forceRelease', function()
    local source = source
    for carrierId, carriedId in pairs(activeCarries) do
        if carriedId == source then
            activeCarries[carrierId] = nil
            TriggerClientEvent('Mg_carry:client:forceStop', carrierId)
            break
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source

    if activeCarries[source] then
        local carried = activeCarries[source]
        TriggerClientEvent('Mg_carry:client:released', carried)
        activeCarries[source] = nil
    end

    for carrierId, carriedId in pairs(activeCarries) do
        if carriedId == source then
            activeCarries[carrierId] = nil
            TriggerClientEvent('Mg_carry:client:forceStop', carrierId)
            break
        end
    end

    cooldowns[source] = nil
end)
