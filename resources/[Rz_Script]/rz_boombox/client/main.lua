--[[
    rz_boombox / client/main.lua

    Remplace wasabi_boombox. Trois blocs :
      1. Pose (fantôme suivant la caméra via lib.raycast, validé/annulé
         au clavier) déclenchée par l'usage de l'item ox_inventory.
      2. Interactions ox_target une fois posée : jouer un son (ou un
         favori sauvegardé), l'arrêter, ranger la radio.
      3. Synchronisation : toutes les radios posées sont diffusées à
         -1 par le serveur (comme rz_airdrop pour ses caisses), donc
         chaque client les fait apparaître localement — pas d'entité
         réseau à gérer.
]]

local boomboxes = {}   -- [id] = { entity, x, y, z, heading, playing }
local placing = false


local function dbg(...)
    if Config.Debug then print('^3[rz_boombox]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  POSE ET APPARITION
-- ═══════════════════════════════════════════════════════════════════

local function soundId(id)
    return ('rz_boombox_%d'):format(id)
end


local function spawnBoombox(data)
    if boomboxes[data.id] then return end

    local hash = joaat(Config.PropModel)
    lib.requestModel(hash, 10000)

    local obj = CreateObject(hash, data.x, data.y, data.z, false, false, false)
    SetEntityHeading(obj, data.heading or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)

    boomboxes[data.id] = {
        entity = obj, x = data.x, y = data.y, z = data.z,
        heading = data.heading, playing = false,
    }

    exports.ox_target:addLocalEntity(obj, {
        {
            name     = 'rz_boombox_play_' .. data.id,
            icon     = 'fas fa-music',
            label    = 'Jouer un son',
            distance = Config.TargetDistance,
            onSelect = function() OpenBoomboxMenu(data.id) end,
        },
        {
            name        = 'rz_boombox_stop_' .. data.id,
            icon        = 'fas fa-stop',
            label       = 'Arrêter le son',
            distance    = Config.TargetDistance,
            canInteract = function()
                return boomboxes[data.id] and boomboxes[data.id].playing
            end,
            onSelect = function() TriggerServerEvent('rz_boombox:stop', data.id) end,
        },
        {
            name     = 'rz_boombox_pickup_' .. data.id,
            icon     = 'fas fa-hand',
            label    = 'Ranger',
            distance = Config.TargetDistance,
            onSelect = function() TriggerServerEvent('rz_boombox:pickup', data.id) end,
        },
    })

    dbg(('boombox %d posée'):format(data.id))
end


local function removeBoombox(id)
    local b = boomboxes[id]
    if not b then return end

    if b.playing then exports.xsound:Destroy(soundId(id)) end
    if b.entity and DoesEntityExist(b.entity) then DeleteEntity(b.entity) end

    boomboxes[id] = nil
end


RegisterNetEvent('rz_boombox:spawn', spawnBoombox)
RegisterNetEvent('rz_boombox:remove', removeBoombox)


-- ═══════════════════════════════════════════════════════════════════
--  USAGE DE L'ITEM (appelé par ox_inventory via client.export, cf.
--  data/items.lua — export = 'rz_boombox.useBoombox')
-- ═══════════════════════════════════════════════════════════════════

-- Isolée dans son propre thread : un export appelé depuis une AUTRE
-- ressource (ox_inventory ici) ne doit pas porter la boucle Wait(0)
-- elle-même, pour ne dépendre d'aucune hypothèse sur le contexte
-- d'exécution de l'appelant.
local function startPlacement()
    placing = true

    lib.notify({
        description = 'Choisis un emplacement — [E] valider, [Backspace] annuler',
        duration    = 6000,
    })

    CreateThread(function()
        local hash = joaat(Config.PropModel)
        lib.requestModel(hash, 10000)

        local playerCoords = GetEntityCoords(cache.ped)
        local preview = CreateObject(hash, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
        SetEntityAlpha(preview, 150, false)
        SetEntityCollision(preview, false, false)

        local placed, cancelled = false, false

        while placing do
            local hit, _, coords = lib.raycast.fromCamera(1 + 16, 4, Config.PlaceDistance)
            local heading = GetEntityHeading(cache.ped)

            if hit then
                SetEntityCoords(preview, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(preview, heading)
                SetEntityAlpha(preview, 150, false)
            else
                SetEntityAlpha(preview, 60, false)
            end

            if IsControlJustPressed(0, 38) then       -- E
                placed = true
                placing = false
            elseif IsControlJustPressed(0, 194) then   -- Backspace
                cancelled = true
                placing = false
            end

            Wait(0)
        end

        local finalCoords = GetEntityCoords(preview)
        local finalHeading = GetEntityHeading(preview)
        DeleteEntity(preview)
        SetModelAsNoLongerNeeded(hash)

        if placed then
            TriggerServerEvent('rz_boombox:confirmPlace', finalCoords, finalHeading)
        elseif cancelled then
            lib.notify({ type = 'info', description = 'Pose annulée' })
            TriggerServerEvent('rz_boombox:cancelPlace')
        end
    end)
end


exports('useBoombox', function(_, data)
    if placing then return end

    exports.ox_inventory:useItem(data, function(itemData)
        if not itemData then return end
        startPlacement()
    end)
end)


-- ═══════════════════════════════════════════════════════════════════
--  MENU : NOUVEAU SON / SONS SAUVEGARDÉS
-- ═══════════════════════════════════════════════════════════════════

local function promptNewSong(id)
    local input = lib.inputDialog('Jouer un son', {
        { type = 'input', label = 'Lien direct (mp3/ogg)', required = true },
        { type = 'input', label = 'Sauvegarder sous ce nom (optionnel)' },
    })
    if not input or not input[1] or input[1] == '' then return end

    TriggerServerEvent('rz_boombox:play', id, input[1])

    if input[2] and input[2] ~= '' then
        TriggerServerEvent('rz_boombox:saveSong', input[2], input[1])
    end
end


function OpenBoomboxMenu(id)
    local saved = lib.callback.await('rz_boombox:getSavedSongs', false) or {}

    local options = {
        {
            title    = 'Nouveau lien',
            icon     = 'link',
            onSelect = function() promptNewSong(id) end,
        },
    }

    for _, song in ipairs(saved) do
        options[#options + 1] = {
            title    = song.label,
            icon     = 'music',
            onSelect = function() TriggerServerEvent('rz_boombox:play', id, song.link) end,
        }
    end

    lib.registerContext({
        id      = 'rz_boombox_menu',
        title   = 'Boombox',
        options = options,
    })
    lib.showContext('rz_boombox_menu')
end


-- ═══════════════════════════════════════════════════════════════════
--  SON
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_boombox:playSound', function(id, url)
    local b = boomboxes[id]
    if not b then return end

    local sid = soundId(id)
    exports.xsound:PlayUrlPos(sid, url, Config.SoundVolume, vector3(b.x, b.y, b.z), true)
    exports.xsound:Distance(sid, Config.SoundDistance)
    b.playing = true
end)


RegisterNetEvent('rz_boombox:stopSound', function(id)
    local b = boomboxes[id]
    if not b then return end

    exports.xsound:Destroy(soundId(id))
    b.playing = false
end)


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION À LA CONNEXION / NETTOYAGE
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(3000)

    local list = lib.callback.await('rz_boombox:getBoomboxes', false) or {}
    for _, b in ipairs(list) do spawnBoombox(b) end

    if #list > 0 then
        dbg(('%d boombox(es) déjà posée(s)'):format(#list))
    end
end)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(boomboxes) do removeBoombox(id) end
end)
