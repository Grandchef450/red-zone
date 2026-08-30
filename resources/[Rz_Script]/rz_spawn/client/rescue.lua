--[[
    rz_spawn / client/rescue.lua

    Désenclavement du joueur, et outils de déplacement pour le staff.
]]

local rescuing = false
local lastDamage = 0
local lastCombat = 0

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  TROUVER OÙ POSER LE JOUEUR
--
--  Trois méthodes, de la moins intrusive à la plus radicale.
--  Renvoyer systématiquement au point de départ ferait perdre sa
--  progression à quelqu'un simplement coincé derrière une caisse.
-- ═══════════════════════════════════════════════════════════════════

---1. Remonter au sol, à la verticale de la position actuelle.
local function findGround()
    local c = GetEntityCoords(cache.ped)

    -- On sonde de haut en bas : GetGroundZFor_3dCoord échoue quand
    -- on l'appelle depuis sous la carte, il faut partir d'au-dessus.
    for height = 1000, -200, -25 do
        local found, z = GetGroundZFor_3dCoord(c.x, c.y, height + 0.0, false)

        if found and z > -100.0 then
            return vec3(c.x, c.y, z + 1.0)
        end

        Wait(0)
    end

    return nil
end


---2. La route carrossable la plus proche.
local function findRoad()
    local c = GetEntityCoords(cache.ped)

    -- Si on est sous la carte, on cherche depuis la surface plutôt
    -- que depuis notre position réelle.
    local searchZ = c.z < Config.Detection.underMapZ and 50.0 or c.z

    local found, pos = GetClosestVehicleNode(c.x, c.y, searchZ, 1, 3.0, 0)

    if found and pos then
        return vec3(pos.x, pos.y, pos.z + 1.0)
    end

    return nil
end


---3. Le point de départ du serveur.
local function findSpawn()
    local d = lib.callback.await('rz_spawn:getFallback', false)
    if not d then return nil end
    return vec3(d.x, d.y, d.z)
end


---Déplace réellement le joueur, en attendant le décor.
local function placeAt(pos)
    local ped = cache.ped

    DoScreenFadeOut(400)
    Wait(500)

    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z + 2.0, false, false, false)

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)

    local deadline = GetGameTimer() + 10000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        Wait(50)
    end

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)

    Wait(300)
    DoScreenFadeIn(1000)
end


-- ═══════════════════════════════════════════════════════════════════
--  LE COMPTE À REBOURS
--
--  C'est lui qui empêche l'abus. Quelqu'un réellement coincé attend
--  quinze secondes sans problème ; quelqu'un qui fuit un combat ne
--  peut pas se permettre de rester immobile.
-- ═══════════════════════════════════════════════════════════════════

---@param force boolean  ignorer le compte à rebours (staff)
function StartRescue(force)
    if rescuing then return end

    local ok, info = lib.callback.await('rz_spawn:canUnstuck', false)

    if not ok and not force then
        return lib.notify({ type = 'error', description = info, duration = 8000 })
    end

    -- Le combat récent bloque : sans ça, le désenclavement devient
    -- une porte de sortie gratuite en pleine fusillade.
    if not force and info and info.combatLock then
        local since = (GetGameTimer() - lastCombat) / 1000

        if lastCombat > 0 and since < info.combatLock then
            return lib.notify({
                type        = 'error',
                title       = 'Impossible pour l\'instant',
                description = ('Tu viens de te battre. Attends %d secondes.')
                    :format(math.ceil(info.combatLock - since)),
                duration    = 7000,
            })
        end
    end

    rescuing = true

    local step = 'ground'

    if not force then
        local start = GetEntityCoords(cache.ped)
        local seconds = info.countdown
        local cancelled = false

        lastDamage = 0

        for i = seconds, 1, -1 do
            for _ = 1, 10 do
                Wait(100)

                local c = GetEntityCoords(cache.ped)

                if #(c - start) > info.tolerance then
                    cancelled = 'tu as bougé'
                    break
                end

                if info.cancelOnDamage and lastDamage > 0 then
                    cancelled = 'tu as été touché'
                    break
                end
            end

            if cancelled then break end

            lib.notify({
                id          = 'rz_unstuck',
                type        = 'inform',
                title       = 'Désenclavement',
                description = ('Reste immobile encore %d seconde%s.')
                    :format(i, i > 1 and 's' or ''),
                duration    = 1100,
            })
        end

        if cancelled then
            rescuing = false
            return lib.notify({
                type        = 'error',
                title       = 'Annulé',
                description = ('Le désenclavement a été interrompu : %s.'):format(cancelled),
                duration    = 7000,
            })
        end
    end

    -- ─── ESCALADE ──────────────────────────────────────────────
    local target = findGround()

    if not target then
        step = 'road'
        target = findRoad()
    end

    if not target then
        step = 'spawn'
        target = findSpawn()
    end

    if not target then
        rescuing = false
        return lib.notify({
            type        = 'error',
            description = 'Aucune position sûre trouvée. Préviens un membre du staff.',
            duration    = 10000,
        })
    end

    placeAt(target)

    lib.callback.await('rz_spawn:confirmUnstuck', false, step)

    local labels = {
        ground = 'remonté au sol',
        road   = 'déplacé sur la route la plus proche',
        spawn  = 'renvoyé au point de départ',
    }

    lib.notify({
        type        = 'success',
        title       = 'Désenclavement',
        description = ('Tu as été %s.'):format(labels[step] or step),
        duration    = 8000,
    })

    dbg(('désenclavé par %s'):format(step))

    rescuing = false
end


RegisterNetEvent('rz_spawn:forceRescue', function()
    lib.notify({
        type        = 'inform',
        title       = 'Le staff intervient',
        description = 'Un membre du staff te débloque.',
        duration    = 6000,
    })

    StartRescue(true)
end)


-- ═══════════════════════════════════════════════════════════════════
--  SURVEILLANCE DES DÉGÂTS
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    local lastHealth = GetEntityHealth(PlayerPedId())

    while true do
        Wait(200)

        local ped = PlayerPedId()
        local hp = GetEntityHealth(ped)

        if hp < lastHealth then
            lastDamage = GetGameTimer()
        end

        lastHealth = hp

        -- Tirer compte comme un combat, même sans toucher personne
        if IsPedShooting(ped) or IsPedInMeleeCombat(ped) then
            lastCombat = GetGameTimer()
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION AUTOMATIQUE
--
--  Sous une certaine hauteur, il n'y a plus de carte du tout.
--  Inutile d'attendre que le joueur s'en aperçoive et tape une
--  commande : à ce stade il ne voit qu'un écran noir.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(20000)   -- laisse le temps à l'apparition normale

    local underSince = 0

    while true do
        Wait(1000)

        if Config.Detection.enabled and not rescuing then
            local ped = PlayerPedId()

            if DoesEntityExist(ped) then
                local c = GetEntityCoords(ped)

                if c.z < Config.Detection.underMapZ then
                    if underSince == 0 then
                        underSince = GetGameTimer()

                        if Config.Detection.notify then
                            lib.notify({
                                type        = 'warning',
                                title       = 'Sous la carte',
                                description = 'Position anormale détectée. Récupération en cours.',
                                duration    = 6000,
                            })
                        end
                    end

                    if (GetGameTimer() - underSince) > (Config.Detection.underMapDelay * 1000) then
                        underSince = 0
                        dbg('sous la carte, secours automatique')
                        StartRescue(true)
                    end
                else
                    underSince = 0
                end
            end
        end
    end
end)


RegisterCommand('unstuck', function()
    StartRescue(false)
end, false)
