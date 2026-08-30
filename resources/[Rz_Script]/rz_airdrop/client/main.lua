--[[
    rz_airdrop / client/main.lua

    Affichage des largages.

    L'AVION N'EXISTE PAS. Aucun modèle n'est chargé : on anime
    seulement un blip qui traverse la carte en ligne droite. C'est
    ce qui était demandé, et c'est aussi bien plus léger qu'un
    appareil streamé pour tous les joueurs à la fois.
]]

-- [crateId] = { entity, blip, data }
local crates = {}

local planeBlip = nil
local flying = false


local function dbg(...)
    if Config.Debug then print('^3[rz_airdrop]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  L'AVION
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_airdrop:startFlight', function(data)
    if flying then return end
    flying = true

    if planeBlip and DoesBlipExist(planeBlip) then RemoveBlip(planeBlip) end

    planeBlip = AddBlipForCoord(data.from.x, data.from.y, 0.0)
    SetBlipSprite(planeBlip, Config.Plane.blipSprite)
    SetBlipColour(planeBlip, Config.Plane.blipColour)
    SetBlipScale(planeBlip, Config.Plane.blipScale)
    SetBlipAsShortRange(planeBlip, false)
    SetBlipFlashes(planeBlip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Appareil non identifié')
    EndTextCommandSetBlipName(planeBlip)

    lib.notify({
        type        = 'inform',
        title       = 'Contact radar',
        description = 'Un appareil traverse le secteur.',
        duration    = 8000,
    })

    -- Déplacement du blip le long de la ligne. On calcule la durée
    -- totale à l'avance : le blip avance ainsi à vitesse constante,
    -- quelle que soit la longueur du trajet.
    CreateThread(function()
        local dx = data.to.x - data.from.x
        local dy = data.to.y - data.from.y
        local dist = math.sqrt(dx * dx + dy * dy)
        local duration = (dist / (data.speed or 180.0)) * 1000

        local started = GetGameTimer()

        -- Le cap oriente l'icône : un avion qui vole de côté sur la
        -- carte trahit immédiatement le trucage.
        local heading = math.deg(math.atan(dy, dx))
        SetBlipRotation(planeBlip, math.floor((90 - heading) % 360))

        while flying do
            local elapsed = GetGameTimer() - started
            local t = math.min(1.0, elapsed / duration)

            SetBlipCoords(planeBlip,
                data.from.x + dx * t,
                data.from.y + dy * t, 0.0)

            if t >= 1.0 then break end
            Wait(200)
        end
    end)
end)


RegisterNetEvent('rz_airdrop:endFlight', function()
    flying = false

    if planeBlip and DoesBlipExist(planeBlip) then
        RemoveBlip(planeBlip)
        planeBlip = nil
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  LES CAISSES
-- ═══════════════════════════════════════════════════════════════════

local function spawnCrate(data)
    if crates[data.id] then return end

    local entry = { data = data }

    -- ─── LE PROP ───────────────────────────────────────────────
    -- PlaceObjectOnGroundProperly fait le travail que le serveur ne
    -- peut pas faire : trouver la hauteur du sol. C'est aussi ce
    -- qui garantit que la caisse ne flotte pas dans le vide.
    local hash = joaat(Config.Drop.propModel)
    lib.requestModel(hash, 10000)

    if HasModelLoaded(hash) then
        local obj = CreateObject(hash, data.x, data.y, 0.0, false, false, false)

        -- On monte le prop très haut puis on le laisse tomber :
        -- placer directement à z=0 le ferait apparaître sous la
        -- carte dans les zones en altitude.
        SetEntityCoords(obj, data.x, data.y, 1500.0, false, false, false, false)
        Wait(100)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        SetModelAsNoLongerNeeded(hash)

        entry.entity = obj

        exports.ox_target:addLocalEntity(obj, {
            {
                name     = 'rz_airdrop_' .. data.id,
                icon     = 'fas fa-box-open',
                label    = 'Ouvrir la caisse',
                distance = 2.0,
                onSelect = function() OpenCrate(data.id) end,
            },
        })
    end

    -- ─── LE BLIP ───────────────────────────────────────────────
    local blip = AddBlipForCoord(data.x, data.y, 0.0)
    SetBlipSprite(blip, 478)          -- caisse
    SetBlipColour(blip, data.colour or 5)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label or 'Largage')
    EndTextCommandSetBlipName(blip)

    entry.blip = blip

    crates[data.id] = entry

    dbg(('caisse %s posée'):format(data.id))
end


local function removeCrate(id)
    local c = crates[id]
    if not c then return end

    if c.entity and DoesEntityExist(c.entity) then DeleteEntity(c.entity) end
    if c.blip and DoesBlipExist(c.blip) then RemoveBlip(c.blip) end

    crates[id] = nil
end


RegisterNetEvent('rz_airdrop:addCrate', function(data)
    spawnCrate(data)

    lib.notify({
        type        = 'success',
        title       = data.label or 'Largage',
        description = 'Un colis vient de tomber. Il s\'ouvrira dans cinq minutes.',
        duration    = 10000,
    })
end)


RegisterNetEvent('rz_airdrop:removeCrate', removeCrate)


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE
-- ═══════════════════════════════════════════════════════════════════

function OpenCrate(id)
    local c = crates[id]
    if not c then return end

    local result, remaining = lib.callback.await('rz_airdrop:openCrate', false, id)

    -- Le serveur renvoie les secondes restantes quand le verrou
    -- n'est pas levé : c'est plus utile qu'un simple refus.
    if not result then
        if type(remaining) == 'number' then
            return lib.notify({
                type        = 'error',
                title       = 'Colis verrouillé',
                description = ('Encore %d min %d s avant l\'ouverture.')
                    :format(math.floor(remaining / 60), remaining % 60),
                duration    = 7000,
            })
        end

        return lib.notify({ type = 'error', description = tostring(remaining) })
    end

    exports.ox_inventory:openInventory('stash', result)
end


-- ═══════════════════════════════════════════════════════════════════
--  FUMIGÈNE ET COMPTE À REBOURS
--
--  Une seule boucle pour tout ce qui s'affiche en 3D. On l'endort
--  complètement quand aucune caisse n'est proche : à 30 secondes
--  d'intervalle, elle ne coûte plus rien.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local wait = 1000

        if next(crates) then
            local coords = GetEntityCoords(cache.ped)
            local now = GetCloudTimeAsInt()

            for id, c in pairs(crates) do
                local d = #(vec2(coords.x, coords.y) - vec2(c.data.x, c.data.y))

                if d < 150.0 and c.entity and DoesEntityExist(c.entity) then
                    wait = 0

                    local pos = GetEntityCoords(c.entity)

                    -- Fumigène coloré selon la rareté
                    if Config.Drop.smoke and c.data.smoke then
                        UseParticleFxAsset('core')
                        SetParticleFxNonLoopedColour(
                            c.data.smoke[1] / 255,
                            c.data.smoke[2] / 255,
                            c.data.smoke[3] / 255)
                        StartParticleFxNonLoopedAtCoord(
                            'exp_grd_flare_smoke',
                            pos.x, pos.y, pos.z + 0.4,
                            0.0, 0.0, 0.0, 1.2, false, false, false)
                    end

                    -- Compte à rebours au-dessus de la caisse
                    if d < 25.0 then
                        local left = (c.data.openableAt or 0) - now

                        local text
                        if left > 0 then
                            text = ('~r~Verrouillé~s~  %d:%02d')
                                :format(math.floor(left / 60), left % 60)
                        else
                            text = '~g~[E]~s~  Ouvrir'
                        end

                        SetDrawOrigin(pos.x, pos.y, pos.z + 1.1, 0)
                        SetTextFont(4)
                        SetTextScale(0.0, 0.42)
                        SetTextColour(255, 255, 255, 220)
                        SetTextCentre(true)
                        SetTextOutline()
                        SetTextEntry('STRING')
                        AddTextComponentSubstringPlayerName(text)
                        DrawText(0.0, 0.0)
                        ClearDrawOrigin()
                    end
                end
            end
        else
            wait = 3000
        end

        Wait(wait)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION À LA CONNEXION
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(4000)

    local list = lib.callback.await('rz_airdrop:getCrates', false) or {}
    for _, c in ipairs(list) do spawnCrate(c) end

    if #list > 0 then
        dbg(('%d caisse(s) déjà au sol'):format(#list))
    end
end)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(crates) do removeCrate(id) end

    if planeBlip and DoesBlipExist(planeBlip) then RemoveBlip(planeBlip) end
end)
