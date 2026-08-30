--[[
    rz_spawn / client/main.lua

    Place le joueur là où le serveur lui a dit d'aller.

    LE POINT DÉLICAT : ATTENDRE LE DÉCOR
    Téléporter puis afficher immédiatement montre un monde vide qui
    se remplit sous les yeux du joueur — bâtiments qui surgissent,
    sol qui apparaît en retard. Pire, un ped posé avant que le sol
    existe tombe à travers la carte.

    On demande donc explicitement le chargement de la zone, et on
    n'affiche qu'ensuite.
]]

local spawned = false

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


---Attend que le décor autour d'un point soit chargé.
---@param x number
---@param y number
---@param z number
local function waitForCollision(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)

    local deadline = GetGameTimer() + (Config.Fade.maxWaitSeconds * 1000)

    while not HasCollisionLoadedAroundEntity(cache.ped) do
        RequestCollisionAtCoord(x, y, z)
        Wait(50)

        -- Passé le délai, on affiche quand même : mieux vaut un
        -- décor incomplet qu'un écran noir sans fin.
        if GetGameTimer() > deadline then
            dbg('délai de chargement dépassé')
            break
        end
    end

    NewLoadSceneStop()
end


RegisterNetEvent('rz_spawn:goTo', function(data)
    if not data then return end

    spawned = true

    local ped = cache.ped

    DoScreenFadeOut(0)

    -- On rend le joueur invisible et intouchable pendant le
    -- placement : sans ça, il peut être vu en train de tomber, ou
    -- prendre des dégâts de chute avant même d'être arrivé.
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    -- Position en l'air d'abord : le sol n'existe pas encore, et
    -- poser le ped à sa hauteur finale le ferait passer au travers.
    SetEntityCoordsNoOffset(ped, data.x, data.y, data.z + 3.0, false, false, false)
    SetEntityHeading(ped, data.w or 0.0)

    waitForCollision(data.x, data.y, data.z)

    -- Maintenant que le sol est chargé, on pose vraiment
    SetEntityCoordsNoOffset(ped, data.x, data.y, data.z, false, false, false)
    SetEntityHeading(ped, data.w or 0.0)

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    -- Une téléportation du staff ne doit pas soigner le joueur :
    -- ce serait un moyen détourné de se remettre en pleine santé.
    if data.health then SetEntityHealth(ped, data.health) end
    if data.armour then SetPedArmour(ped, data.armour) end

    ClearPedTasksImmediately(ped)
    SetPlayerControl(PlayerId(), true, 0)

    -- Un dernier instant pour que les textures finissent d'arriver
    Wait(500)

    ShutdownLoadingScreenNui()
    DoScreenFadeIn(Config.Fade.inMs)

    dbg(('placé en %.0f, %.0f, %.0f'):format(data.x, data.y, data.z))

    -- silent : téléportation du staff, pas une apparition
    if Config.Welcome.enabled and not data.silent then
        Wait(1500)

        local msg = data.isNew and Config.Welcome.newCharacter
                               or  Config.Welcome.returning

        lib.notify({
            type        = 'inform',
            title       = msg.title,
            description = msg.text,
            duration    = 10000,
        })
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  FILET DE SÉCURITÉ
--
--  Si aucun événement de chargement n'arrive — c'est exactement ce
--  qui te bloquait dans le noir — le client réclame lui-même son
--  placement au bout de quelques secondes.
--
--  Sans ce filet, un joueur dont le personnage se charge mal reste
--  sous la carte, sans son, sans image, sans aucun moyen d'agir.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    -- On laisse d'abord le multicharacter faire son travail
    Wait(15000)

    while not spawned do
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and NetworkIsSessionStarted() then
            local c = GetEntityCoords(ped)

            -- Position proche de l'origine : le joueur est sous la
            -- carte, il n'a jamais été placé.
            if #(vec2(c.x, c.y) - vec2(0.0, 0.0)) < 5.0 then
                dbg('aucun placement reçu, demande au serveur')
                TriggerServerEvent('rz_spawn:request')
                Wait(8000)
            end
        end

        Wait(3000)
    end
end)


-- La commande /unstuck vit dans client/unstuck.lua : elle y fait
-- bien plus que demander un replacement, avec recherche de sol et
-- garde-fous contre l'abus en combat.
