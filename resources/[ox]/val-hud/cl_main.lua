if Config.FrameWork == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.FrameWork == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
else
    --n/a
end

local table = lib.table

-- RÉÉCRIT POUR QBOX — RedZone, 30 août 2026
--
-- La ligne d'origine était :  local player = Ox.GetPlayer()
--
-- Elle s'exécutait SANS CONDITION, même avec Config.FrameWork = 'qb'.
-- Une fois ox_core sorti du dossier resources, la table globale Ox
-- n'existe plus et le script plantait dès son chargement :
--   « attempt to index a nil value (global 'Ox') »
--
-- Faim, soif et stress viennent désormais des métadonnées Qbox.
local PlayerData = {}
local playerState = LocalPlayer.state -- Access client's own StateBag

local thirst, stress, hunger, voice, currentId, oxygen, playertalking = 999, 0, 999, 2, 999, 100, false
local showSeatbelt, seatbeltOn, rpm, fuel, enginehealth = false, false, 100, 20, 300
local isLoggedIn = false
local lolbelt = false
local harness = 0
local cashAmount = 0
local bankAmount = 0
local nomfuel = 10

showCompass = false
gpswatchUsed = false

exports('val-hud:gpswatch', function(data, slot)
	if not gpswatchUsed then
		gpswatchUsed = true
		Wait(100)
		TriggerEvent("val-hud:togglecompass")
	else
		gpswatchUsed = false
		Wait(100)
		TriggerEvent("val-hud:togglecompass")
	end
end)

RegisterNetEvent("val-hud:togglecompass")
AddEventHandler("val-hud:togglecompass", function()
	if not gpswatchUsed then
		
		showCompass = not showCompass
	else
		showCompass = true
	end
end)

RegisterNetEvent("val-hud:voicemode")
AddEventHandler("val-hud:voicemode", function(mode)
    voice = mode
end)

RegisterNetEvent("val-hud:playertalking")
AddEventHandler("val-hud:playertalking", function(talking)
    playertalking = talking
end)

-- Display radar and zoom level adjustments
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do
        Wait(10)
    end
    while true do
        Wait(500)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            DisplayRadar(true)
            SetRadarBigmapEnabled(false, false)

            BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
        else
            DisplayRadar(false)
        end
    end
end)

-- Event handlers for updating needs and seatbelt status
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger, thirst = newHunger, newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
end)

-- ═══════════════════════════════════════════════════════════════
--  FAIM, SOIF ET STRESS
--
--  ox_core émettait « ox:statusTick » avec un objet joueur exposant
--  getStatus(). Qbox n'a pas d'équivalent : ces valeurs vivent dans
--  les MÉTADONNÉES du personnage, mises à jour par qbx_core.
--
--  On écoute donc son événement de rafraîchissement, et on lit les
--  valeurs directement.
-- ═══════════════════════════════════════════════════════════════

---Met à jour la barre de faim, de soif et de stress.
local function refreshNeeds(meta)
    if not meta then return end

    local newHunger = tonumber(meta.hunger) or hunger
    local newThirst = tonumber(meta.thirst) or thirst
    local newStress = tonumber(meta.stress) or stress

    if newThirst ~= thirst or newHunger ~= hunger then
        TriggerEvent('hud:client:UpdateNeeds', newHunger, newThirst)
    end

    if newStress ~= stress then
        TriggerEvent('hud:client:UpdateStress', newStress)
    end
end


-- Qbox pousse les métadonnées à chaque changement
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data or {}
    refreshNeeds(PlayerData.metadata)
end)


-- Filet de sécurité : certaines versions de Qbox ne poussent les
-- métadonnées qu'au chargement. Sans cette boucle, les jauges
-- resteraient figées sur leur valeur initiale.
CreateThread(function()
    while true do
        Wait(5000)

        if isLoggedIn and QBCore then
            local ok, data = pcall(function()
                return QBCore.Functions.GetPlayerData()
            end)

            if ok and data and data.metadata then
                refreshNeeds(data.metadata)
            end
        end
    end
end)

-- Initialize HUD visibility

-- ═══════════════════════════════════════════════════════════════
--  AFFICHAGE DE L'INTERFACE
--
--  « ox:playerLoaded » et « ox:playerLogout » n'existent plus.
--  On écoute les équivalents Qbox, sous leurs deux noms possibles
--  selon la version.
-- ═══════════════════════════════════════════════════════════════

local function onLoaded()
    if playerLoaded then return end

    isLoggedIn = true
    playerLoaded = true

    SendNUIMessage({ type = 'showhud', show = true })
    TriggerEvent('hud:client:minimap')

    -- On lit les valeurs de départ tout de suite : sans ça, les
    -- jauges affichent zéro jusqu'au premier changement.
    if QBCore then
        local ok, data = pcall(function()
            return QBCore.Functions.GetPlayerData()
        end)

        if ok and data then
            PlayerData = data
            refreshNeeds(data.metadata)
        end
    end
end


local function onLogout()
    Citizen.Wait(1000)

    PlayerData = {}
    isLoggedIn = false
    playerLoaded = false

    SendNUIMessage({ type = 'hidehud', show = false })
end


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', onLoaded)
RegisterNetEvent('qbx_core:client:playerLoaded', onLoaded)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', onLogout)
RegisterNetEvent('qbx_core:client:playerLogout', onLogout)


-- Filet : si le joueur est déjà connecté au moment où la ressource
-- démarre — cas d'un restart en jeu — aucun de ces événements ne
-- sera émis, et l'interface resterait invisible.
CreateThread(function()
    Wait(3000)

    if not playerLoaded and QBCore then
        local ok, data = pcall(function()
            return QBCore.Functions.GetPlayerData()
        end)

        if ok and data and data.citizenid then
            onLoaded()
        end
    end
end)


RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        lib.notify({ description = 'Cash: $ ' .. amount, icon = 'dollar', type = 'success' })
    else
        lib.notify({ description = 'Bank: $ ' .. amount, icon = 'dollar', type = 'success' })
    end
end)

-- Main thread for updating HUD elements

local function getCardinalDirection(heading)
    local directions = { "N", "NW", "W", "SW", "S", "SE", "E", "NE" }
    heading = (heading % 360 + 360) % 360
    local index = math.floor((heading + 22.5) / 45) % 8
    return directions[index + 1]
end

local function hasHarness() --harness
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local _harness = false
    local hasHarness = exports['qb-smallresources']:HasHarness()
    local hasHarness = false
    if hasHarness then
        _harness = true
    else
        _harness = false
    end

    harness = _harness
end

-- Stress Gain

if Config.FrameWork == 'qb' then
    CreateThread(function() -- Speeding
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    local vehClass = GetVehicleClass(veh)
                    local speed = GetEntitySpeed(veh) * 2.23694
                    local vehHash = GetEntityModel(veh)
                    if Config.VehClassStress[tostring(vehClass)] and not Config.WhitelistedVehicles[vehHash] then
                        local stressSpeed
                        if vehClass == 8 then -- Motorcycle exception for seatbelt
                            stressSpeed = Config.MinimumSpeed
                        else
                            stressSpeed = seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled
                        end
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)
else
    CreateThread(function() -- Speeding
        while true do
            if isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    local vehClass = GetVehicleClass(veh)
                    local speed = GetEntitySpeed(veh) * 2.23694
                    local vehHash = GetEntityModel(veh)
                    if Config.VehClassStress[tostring(vehClass)] and not Config.WhitelistedVehicles[vehHash] then
                        local stressSpeed
                        if vehClass == 8 then -- Motorcycle exception for seatbelt
                            stressSpeed = Config.MinimumSpeed
                        else
                            stressSpeed = seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled
                        end
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)
end

if Config.FrameWork == 'qb' then
    CreateThread(function() -- Shooting
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not Config.WhitelistedWeaponStress[weapon] then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else
                    Wait(1000)
                end
            end
            Wait(0)
        end
    end)
else
    CreateThread(function() -- Shooting
        while true do
            if isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not Config.WhitelistedWeaponStress[weapon] then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else
                    Wait(1000)
                end
            end
            Wait(0)
        end
    end)
end

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(Config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local effectInterval = GetEffectInterval(stress)
        if stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= Config.MinimumStress then
            local BlurIntensity = GetBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

CreateThread(function()
    while true do
        Citizen.Wait(50)
        if isLoggedIn then
            local playerPed = PlayerPedId()
            local health = (GetEntityHealth(playerPed)*100)/200
            if GetEntityHealth(playerPed) == 1 then
                health = 0
            end
            local armor = GetPedArmour(playerPed)
            local player = PlayerPedId()
            local playerId = PlayerId()

            local inVehicle = IsPedInAnyVehicle(playerPed, false)
            local speed = 0

            if not IsEntityInWater(player) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end
            -- Oxygen
            if IsEntityInWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end

            if inVehicle or showCompass then
                if inVehicle then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    --local speed = GetEntitySpeed(veh) * 2.23694
                    speed = GetEntitySpeed(vehicle) * 3.6
                    rpm = GetVehicleCurrentRpm(vehicle) * 1000 / 10
                    fuel = Entity(vehicle).state.fuel
                    enginehealth = GetVehicleEngineHealth(vehicle) / 10
                end

                

                -- Location update
                local pos = GetEntityCoords(playerPed)
                local heading = GetEntityHeading(playerPed)
                local cardinalDirection = getCardinalDirection(heading) -- Convert heading to cardinal direction
                local streetNameHash, crossingHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
                local streetName = GetStreetNameFromHashKey(streetNameHash)
                local areaName = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))

                SendNUIMessage({
                    type = 'updateLocation',
                    heading = cardinalDirection, -- Use cardinal direction
                    street = streetName,
                    area = areaName,
                    x = pos.x,
                    y = pos.y,
                    z = pos.z
                })
            end

            -- Update HUD with vehicle and player information
            SendNUIMessage({
                type = 'updatehud',
                health = health,
                armor = armor,
                oxygen = oxygen,
                stress = stress,
                hunger = hunger,
                thirst = thirst,
                voice = voice,   -- VOICE LEVEL
                currentId = GetPlayerServerId(PlayerId()),  -- Current player ID
                --currentId = 999,   -- for UI test
                playertalking = playertalking,
                speed = math.floor(speed), -- Ensure speed is an integer
                belt = seatbeltOn,
                rpm = rpm,
                fuel = fuel,
                harness = harness,
                inVehicle = inVehicle,
                engine = enginehealth
            })

            -- Show or hide location HUD based on vehicle status
            if inVehicle or showCompass then
                SendNUIMessage({
                    type = 'showLocationHUD'
                })
            else
                if not showCompass then
                    SendNUIMessage({
                        type = 'hideLocationHUD'
                    })
                else
                    SendNUIMessage({
                        type = 'showLocationHUD'
                    })
                end
            end
        end
    end
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp) --harness
    hp = harnessHp
end)

-- Map loading and texture replacement
RegisterNetEvent("hud:client:LoadMap", function()
    --print('loaded?')
    Wait(50)
    -- Credit to Dalrae for the solve.
    local defaultAspectRatio = 1920 / 1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end
    RequestStreamedTextureDict("squaremap", false)
    if not HasStreamedTextureDictLoaded("squaremap") then
        Wait(150)
    end
    SetMinimapClipType(1)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
    -- Adjust Y-position to move the minimap down
    -- Increase the fourth parameter to move it down
    SetMinimapComponentPosition("minimap", "L", "B", 0.0, -0.012, 0.1638, 0.183) -- Main minimap

    -- icons within map
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0, 0.02, 0.128, 0.20) -- Minimap mask

    -- Adjust Y-position to move the blur down
    SetMinimapComponentPosition("minimap_blur", "L", "B", -0.011, 0.059, 0.265, 0.295) -- Blur effect
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(1)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

local function BlackBars()
    local screenW, screenH = GetScreenResolution()
    local barHeight = screenH * 0.1 -- Adjust height as needed (10% of screen height)

    -- Top black bar
    DrawRect(0.5, -0.05 + (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)

    -- Bottom black bar
    DrawRect(0.5, 1.05 - (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)
end


if Config.FrameWork == 'qb' then
    CreateThread(function()
        while true do
            Wait(15000)
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    hasHarness()
                    local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                    if seatbeltOn ~= true and IsThisModelACar(veh) then
                        TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                    end
                end
            end
        end
    end)
else
    CreateThread(function()
        while true do
            Wait(15000)
            if isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                    if seatbeltOn ~= true and IsThisModelACar(veh) then
                        TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                    end
                end
            end
        end
    end)
end

CreateThread(function()
    local isPaused = false
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(playerPed, false)

        if IsPauseMenuActive() and not isPaused then
            SendNUIMessage({
                type = 'hidehud',
                show = false
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
            isPaused = true
        elseif not IsPauseMenuActive() and isPaused then
            SendNUIMessage({
                type = 'showhud',
                show = true
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'showLocationHUD'
                })
            end
            isPaused = false
        end
    end
end)

local cinematic = false

RegisterCommand('cinematic', function()
    local playerPed = PlayerPedId() -- Make sure to get the player ped
    if not cinematic then
        cinematic = true
        SendNUIMessage({ type = 'hidehud', show = true })
        while cinematic do
            Wait(1)
            DisplayRadar(false)
            BlackBars()

            -- Dynamically check if the player is in a vehicle
            local inVehicle = IsPedInAnyVehicle(playerPed, false)

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            else
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
        end
    else
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        if inVehicle then
            SendNUIMessage({
                type = 'showLocationHUD'
            })
        end
        cinematic = false
        SendNUIMessage({ type = 'showhud', show = true })
        DisplayRadar(true)
    end
end)

-- Map zoom data levels for various scenarios
RegisterNetEvent('hud:client:minimap', function()
    Citizen.Wait(1000) -- Add a delay to ensure everything is fully loaded
    SetMapZoomDataLevel(0, 0.96, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(1, 1.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(2, 8.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(3, 12.3, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(4, 22.3, 0.9, 0.08, 0.0, 0.0)
    TriggerEvent('hud:client:LoadMap')
end)

RegisterCommand('resethud', function()
    TriggerEvent('hud:client:minimap')
end)
