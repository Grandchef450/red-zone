--[[
    rz_mort / client/main.lua

    Ce fichier détecte la chute, affiche l'agonie et pose les sacs.
    Il ne décide de rien : le chronomètre, l'inventaire et la
    réapparition sont gérés par le serveur.
]]

local isDowned    = false
local isRecovering = false      -- injecté, mais pas encore debout
local savedCamView = 0          -- vue à restaurer après l'agonie
local deadline    = 0
local canGiveUpAt = 0
local lastCall    = 0

local bags     = {}   -- [bagId] = { entity, blip, data }
local myCid    = nil

local function dbg(...)
    if Config.Debug then print('^3[rz_mort]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION DE LA CHUTE
--
--  On laisse le moteur tuer le joueur, puis on le ressuscite
--  aussitôt sur place en état d'agonie. C'est la méthode la plus
--  fiable : intercepter les dégâts avant la mort rate les chutes,
--  les noyades et les explosions.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(200)

        local ped = cache.ped

        if not isDowned and DoesEntityExist(ped) and IsEntityDead(ped) then
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)

            NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false)
            SetEntityInvincible(ped, false)
            ClearPedTasksImmediately(ped)

            isDowned = true
            TriggerServerEvent('rz_mort:downed')
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT D'AGONIE
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_mort:startDowned', function(data)
    isDowned    = true
    deadline    = GetGameTimer() + (data.seconds * 1000)
    canGiveUpAt = GetGameTimer() + (data.giveUpAfter * 1000)

    local ped = cache.ped
    SetEntityHealth(ped, data.health)

    if Config.Display.screenEffect then
        StartScreenEffect(Config.Display.screenEffect, 0, true)
    end

    -- Vue subjective : on mémorise le réglage du joueur pour le lui
    -- rendre intact une fois debout.
    if Config.Agonie.forceFirstPerson then
        savedCamView = GetFollowPedCamViewMode()
        SetFollowPedCamViewMode(4)
    end

    lib.requestAnimDict('combat@damage@writhe', 5000)

    SendNUIMessage({
        action    = 'downed',
        left      = data.seconds,
        total     = data.seconds,
        canGiveUp = false,
    })

    -- Rafraîchissement de l'affichage : une fois par seconde suffit,
    -- alors que la boucle de contrôles tourne à chaque frame. Les
    -- séparer évite d'envoyer 60 messages NUI par seconde.
    CreateThread(function()
        while isDowned do
            local left = math.max(0, math.floor((deadline - GetGameTimer()) / 1000))

            SendNUIMessage({
                action    = 'update',
                left      = left,
                total     = data.seconds,
                canGiveUp = Config.Agonie.allowGiveUp and GetGameTimer() >= canGiveUpAt,
            })

            Wait(1000)
        end
    end)

    CreateThread(function()
        while isDowned do
            local p = cache.ped

            if not IsEntityPlayingAnim(p, 'combat@damage@writhe', 'writhe_loop', 3) then
                TaskPlayAnim(p, 'combat@damage@writhe', 'writhe_loop',
                             8.0, -8.0, -1, 1, 0, false, false, false)
            end

            -- Immobilisation : on désactive tout ce qui permettrait
            -- de bouger, tirer ou interagir.
            DisableControlAction(0, 21, true)   -- sprint
            DisableControlAction(0, 22, true)   -- saut
            DisableControlAction(0, 23, true)   -- entrer véhicule
            DisableControlAction(0, 24, true)   -- attaque
            DisableControlAction(0, 25, true)   -- viser
            DisableControlAction(0, 30, true)   -- gauche/droite
            DisableControlAction(0, 31, true)   -- avant/arrière
            DisableControlAction(0, 37, true)   -- roue des armes
            DisableControlAction(0, 44, true)   -- couverture
            DisableControlAction(0, 140, true)  -- mêlée
            DisableControlAction(0, 257, true)

            -- On maintient la vue subjective à chaque frame : sans
            -- ça, le moindre événement du jeu remet la caméra à la
            -- troisième personne. Le contrôle 0 est la touche de
            -- changement de vue, on la bloque aussi.
            if Config.Agonie.forceFirstPerson then
                SetFollowPedCamViewMode(4)
                DisableControlAction(0, 0, true)
            end

            ReadDownedInput()

            Wait(0)
        end
    end)
end)


---Lecture des touches pendant l'agonie.
---L'affichage est géré par la NUI : ici on ne lit que les entrées.
function ReadDownedInput()
    -- G : appeler à l'aide
    if IsDisabledControlJustPressed(0, 47) then
        local now = GetGameTimer()
        if (now - lastCall) > (Config.Agonie.callCooldown * 1000) then
            lastCall = now
            TriggerServerEvent('rz_mort:callHelp')
        end
    end

    -- Retour arrière : abandonner
    if Config.Agonie.allowGiveUp
       and GetGameTimer() >= canGiveUpAt
       and IsDisabledControlJustPressed(0, 194) then
        TriggerServerEvent('rz_mort:giveUp')
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  RETOUR À LA VIE
-- ═══════════════════════════════════════════════════════════════════

local function stopDowned(keepCamera)
    isDowned = false
    ClearPedTasks(cache.ped)

    if not keepCamera then
        SendNUIMessage({ action = 'hide' })
    end

    if Config.Display.screenEffect then
        StopScreenEffect(Config.Display.screenEffect)
    end

    -- keepCamera = true pendant le redressement : le joueur est
    -- encore au sol, la vue subjective doit tenir jusqu'au bout.
    if Config.Agonie.forceFirstPerson and not keepCamera then
        SetFollowPedCamViewMode(savedCamView)
    end
end


RegisterNetEvent('rz_mort:revived', function(data)
    -- On garde la caméra bloquée : le joueur reste au sol pendant
    -- que le produit agit.
    stopDowned(true)

    isRecovering = true

    lib.notify({
        type        = 'inform',
        title       = 'Injection reçue',
        description = ('%s t\'a injecté un épipen. Tu te relèveras dans %d secondes.')
            :format(data.byName or 'Quelqu\'un', data.standUp or 30),
        duration    = 9000,
    })

    local standUpAt = GetGameTimer() + ((data.standUp or 30) * 1000)

    -- Rafraîchissement du compte à rebours de redressement
    CreateThread(function()
        while isRecovering do
            SendNUIMessage({
                action = 'recovery',
                left   = math.max(0, math.floor((standUpAt - GetGameTimer()) / 1000)),
            })
            Wait(1000)
        end
    end)

    -- ─── PHASE 1 : encore au sol, le produit fait effet ──────────
    CreateThread(function()
        lib.requestAnimDict('combat@damage@writhe', 3000)

        while isRecovering and GetGameTimer() < standUpAt do
            local ped = cache.ped

            if not IsEntityPlayingAnim(ped, 'combat@damage@writhe', 'writhe_loop', 3) then
                TaskPlayAnim(ped, 'combat@damage@writhe', 'writhe_loop',
                             8.0, -8.0, -1, 1, 0, false, false, false)
            end

            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 140, true)

            if Config.Agonie.forceFirstPerson then
                SetFollowPedCamViewMode(4)
                DisableControlAction(0, 0, true)
            end

            Wait(0)
        end

        -- ─── PHASE 2 : il se relève ──────────────────────────────
        isRecovering = false
        SendNUIMessage({ action = 'hide' })

        local ped = cache.ped
        ClearPedTasks(ped)
        SetEntityHealth(ped, data.health)

        if Config.Agonie.forceFirstPerson then
            SetFollowPedCamViewMode(savedCamView)
        end

        lib.notify({
            type        = 'success',
            title       = 'Tu es debout',
            description = 'Tu tiens à peine. Soigne-toi avant de repartir.',
            duration    = 9000,
        })

        -- ─── PHASE 3 : convalescence, ni course ni combat ────────
        local until_ = GetGameTimer() + ((data.groggy or 15) * 1000)

        while GetGameTimer() < until_ do
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            Wait(0)
        end
    end)
end)


RegisterNetEvent('rz_mort:finalDeath', function(data)
    isRecovering = false
    stopDowned()
    SendNUIMessage({ action = 'hide' })

    DoScreenFadeOut(data.fadeMs or 2000)
    Wait(data.fadeMs or 2000)

    local ped = cache.ped
    NetworkResurrectLocalPlayer(data.x, data.y, data.z, 0.0, true, false)
    SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, false)
    SetEntityHealth(ped, data.health or 140)
    ClearPedTasksImmediately(ped)

    Wait(800)
    DoScreenFadeIn(1500)

    if data.bagged then
        lib.notify({
            type        = 'error',
            title       = 'Tu as tout perdu sur place',
            description = 'Ton sac est resté là où tu es tombé. Cinq minutes avant que d\'autres puissent y toucher.',
            duration    = 12000,
        })
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  RÉANIMER QUELQU'UN
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)

    exports.ox_target:addGlobalPlayer({
        {
            name     = 'rz_mort_revive',
            icon     = 'fas fa-kit-medical',
            label    = 'Injecter un épipen',
            distance = Config.Revive.distance,

            canInteract = function(entity)
                local playerIdx = NetworkGetPlayerIndexFromPed(entity)
                if playerIdx == -1 then return false end

                local serverId = GetPlayerServerId(playerIdx)
                return Player(serverId).state.rzDowned == true
            end,

            onSelect = function(data)
                local playerIdx = NetworkGetPlayerIndexFromPed(data.entity)
                if playerIdx == -1 then return end

                ReviveTarget(GetPlayerServerId(playerIdx))
            end,
        },
    })
end)


function ReviveTarget(targetId)
    local ok, info = lib.callback.await('rz_mort:revive', false, targetId)

    if not ok then
        return lib.notify({ type = 'error', description = info })
    end

    lib.requestAnimDict('amb@medic@standing@kneel@base', 3000)
    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base',
                 8.0, -8.0, -1, 1, 0, false, false, false)

    -- La barre du secouriste ne couvre QUE l'injection. Son ami se
    -- relèvera 30 secondes plus tard, et il en sera prévenu.

    local finished = lib.progressBar({
        duration     = info.duration,
        label        = 'Injection d\'épipen...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not finished then return end

    local done, msg = lib.callback.await('rz_mort:confirmRevive', false, targetId, info.item)

    lib.notify({
        type        = done and 'success' or 'error',
        description = msg,
        duration    = 7000,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  SACS AU SOL
-- ═══════════════════════════════════════════════════════════════════

local function spawnBag(data)
    if bags[data.id] then return end

    local entry = { data = data }

    if Config.Bag.propModel and Config.Bag.propModel ~= '' then
        local hash = joaat(Config.Bag.propModel)
        lib.requestModel(hash, 8000)

        if HasModelLoaded(hash) then
            local obj = CreateObject(hash, data.x, data.y, data.z - 0.9, false, false, false)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetModelAsNoLongerNeeded(hash)

            entry.entity = obj

            exports.ox_target:addLocalEntity(obj, {
                {
                    name     = 'rz_mort_bag_' .. data.id,
                    icon     = 'fas fa-sack-xmark',
                    label    = 'Fouiller le sac',
                    distance = 2.0,
                    onSelect = function() OpenBag(data.id) end,
                },
            })
        end
    end

    -- Blip réservé au propriétaire, le temps du verrou. Sans lui,
    -- retrouver son sac dans un champ tiendrait du hasard pur.
    if Config.Bag.blipForOwner and myCid and data.owner == myCid then
        local blip = AddBlipForCoord(data.x, data.y, data.z)
        SetBlipSprite(blip, 351)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.85)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Ton sac')
        EndTextCommandSetBlipName(blip)

        entry.blip = blip
    end

    bags[data.id] = entry
end


local function removeBag(bagId)
    local b = bags[bagId]
    if not b then return end

    if b.entity and DoesEntityExist(b.entity) then DeleteEntity(b.entity) end
    if b.blip and DoesBlipExist(b.blip) then RemoveBlip(b.blip) end

    bags[bagId] = nil
end


function OpenBag(bagId)
    local result, remaining = lib.callback.await('rz_mort:openBag', false, bagId)

    if not result then
        if remaining then
            return lib.notify({
                type        = 'error',
                title       = 'Sac verrouillé',
                description = ('Encore %d s avant de pouvoir le fouiller.'):format(remaining),
                duration    = 6000,
            })
        end
        return
    end

    exports.ox_inventory:openInventory('stash', result)
end


RegisterNetEvent('rz_mort:addBag', spawnBag)
RegisterNetEvent('rz_mort:removeBag', removeBag)


CreateThread(function()
    Wait(3000)

    local list = lib.callback.await('rz_mort:getBags', false) or {}
    for _, b in ipairs(list) do spawnBag(b) end

    dbg(('%d sac(s) au sol'):format(#list))
end)


-- ═══════════════════════════════════════════════════════════════════
--  MARQUEUR AU SOL
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local wait = 800

        if Config.Bag.marker.enabled and next(bags) then
            local c = GetEntityCoords(cache.ped)

            for _, b in pairs(bags) do
                local d = #(c - vec3(b.data.x, b.data.y, b.data.z))

                if d < Config.Bag.marker.distance then
                    wait = 0
                    DrawMarker(21, b.data.x, b.data.y, b.data.z + 0.9,
                               0, 0, 0, 0, 0, 0, 0.6, 0.6, 0.4,
                               190, 40, 40, 130, true, false, 2,
                               false, nil, nil, false)
                end
            end
        end

        Wait(wait)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  APPEL À L'AIDE
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_mort:helpCall', function(coords, name)
    lib.notify({
        type        = 'warning',
        title       = 'Appel à l\'aide',
        description = ('%s est à terre, tout près d\'ici.'):format(name or 'Quelqu\'un'),
        duration    = 9000,
    })

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 153)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.9)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Blessé')
    EndTextCommandSetBlipName(blip)

    SetTimeout(45000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)


RegisterNetEvent('rz_mort:setCid', function(cid) myCid = cid end)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(bags) do removeBag(id) end

    SendNUIMessage({ action = 'hide' })

    if Config.Display.screenEffect then
        StopScreenEffect(Config.Display.screenEffect)
    end
end)
