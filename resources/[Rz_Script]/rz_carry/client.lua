local isCarrying = false
local isCarried = false
local carriedPlayer = nil
local carrierPlayer = nil
local lastUse = 0

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do
        Wait(100)
        timeout += 1
    end
end

local function GetClosestPlayer()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestPlayer = nil
    local closestDist = Config.MaxDistance

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(myCoords - targetCoords)
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = playerId
                end
            end
        end
    end

    return closestPlayer
end

local function StartCarry(targetServerId)
    local myPed = PlayerPedId()
    LoadAnimDict(Config.CarrierAnim.dict)
    TaskPlayAnim(myPed, Config.CarrierAnim.dict, Config.CarrierAnim.anim, 8.0, -8.0, -1, Config.CarrierAnim.flag, 0, false, false, false)
    isCarrying = true
    carriedPlayer = targetServerId
end

local function StopCarry()
    local myPed = PlayerPedId()
    ClearPedTasks(myPed)
    isCarrying = false
    if carriedPlayer then
        TriggerServerEvent('Mg_carry:server:release', carriedPlayer)
        carriedPlayer = nil
    end
end

local function StartBeingCarried(carrierServerId)
    local myPed = PlayerPedId()
    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierServerId))
    if not carrierPed or not DoesEntityExist(carrierPed) then return end

    LoadAnimDict(Config.CarriedAnim.dict)
    TaskPlayAnim(myPed, Config.CarriedAnim.dict, Config.CarriedAnim.anim, 8.0, -8.0, -1, Config.CarriedAnim.flag, 0, false, false, false)

    AttachEntityToEntity(myPed, carrierPed, GetPedBoneIndex(carrierPed, Config.AttachBone),
        Config.AttachOffset.x, Config.AttachOffset.y, Config.AttachOffset.z,
        Config.AttachRotation.x, Config.AttachRotation.y, Config.AttachRotation.z,
        false, false, false, true, 0, true
    )

    isCarried = true
    carrierPlayer = carrierServerId
end

local function StopBeingCarried()
    local myPed = PlayerPedId()
    DetachEntity(myPed, true, false)
    ClearPedTasks(myPed)
    isCarried = false
    carrierPlayer = nil
end

RegisterCommand(Config.Command, function()
    local now = GetGameTimer()
    if now - lastUse < Config.Cooldown * 1000 then return end
    lastUse = now

    if isCarrying then
        StopCarry()
        return
    end

    if isCarried then return end

    local myPed = PlayerPedId()
    if IsPedDeadOrDying(myPed) or IsPedInAnyVehicle(myPed, false) then return end

    local target = GetClosestPlayer()
    if not target then return end

    local targetServerId = GetPlayerServerId(target)
    local targetPed = GetPlayerPed(target)
    if IsPedInAnyVehicle(targetPed, false) then return end

    TriggerServerEvent('Mg_carry:server:carry', targetServerId)
end, false)

RegisterNetEvent('Mg_carry:client:startCarry', function(targetServerId)
    StartCarry(targetServerId)
end)

RegisterNetEvent('Mg_carry:client:beingCarried', function(carrierServerId)
    StartBeingCarried(carrierServerId)
end)

RegisterNetEvent('Mg_carry:client:released', function()
    StopBeingCarried()
end)

RegisterNetEvent('Mg_carry:client:forceStop', function()
    if isCarrying then StopCarry() end
    if isCarried then StopBeingCarried() end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if isCarrying and carriedPlayer then
            local targetPlayer = GetPlayerFromServerId(carriedPlayer)
            if targetPlayer == -1 then
                StopCarry()
            else
                local targetPed = GetPlayerPed(targetPlayer)
                if not DoesEntityExist(targetPed) or IsPedDeadOrDying(targetPed) then
                    StopCarry()
                end
            end
        end

        if isCarried and carrierPlayer then
            local sourcePlayer = GetPlayerFromServerId(carrierPlayer)
            if sourcePlayer == -1 then
                StopBeingCarried()
            else
                local sourcePed = GetPlayerPed(sourcePlayer)
                if not DoesEntityExist(sourcePed) or IsPedDeadOrDying(sourcePed) then
                    StopBeingCarried()
                end
            end
        end

        if isCarried then
            local myPed = PlayerPedId()
            if IsPedInAnyVehicle(myPed, false) then
                StopBeingCarried()
                TriggerServerEvent('Mg_carry:server:forceRelease')
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isCarrying then StopCarry() end
    if isCarried then StopBeingCarried() end
end)
