--[[
    rz_spawn / client/unstuck.lua

    Sortir un joueur d'une situation sans issue.

    ─── POURQUOI TROIS MÉTHODES ───────────────────────────────────

    Téléporter directement au point d'apparition règle tout, mais
    c'est brutal : un joueur coincé dans un rocher à Paleto se
    retrouverait à Sandy Shores, à des kilomètres de son butin.

    On essaie donc du moins perturbant au plus radical :

      1. remonter au sol juste au-dessus
      2. chercher un sol praticable dans les environs
      3. renvoyer au point d'apparition

    Neuf fois sur dix, la première suffit.
]]

local lastUse = 0
local lastDamage = 0
local stuckSince = 0
local rescuing = false

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  RECHERCHE D'UN SOL PRATICABLE
-- ═══════════════════════════════════════════════════════════════════

---Hauteur du sol à une position, ou nil.
---@return number|nil
local function groundAt(x, y, fromZ)
    RequestCollisionAtCoord(x, y, fromZ)

    -- On sonde du haut vers le bas : partir d'en dessous
    -- retournerait le plafond d'un tunnel plutôt que le vrai sol.
    for z = fromZ, fromZ - 400.0, -25.0 do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)

        if found and groundZ > -180.0 then
            return groundZ
        end

        Wait(0)
    end

    return nil
end


---Cherche un sol praticable en spirale autour d'un point.
---@return vector3|nil
local function findSafeGround(coords)
    -- D'abord juste au-dessus : le cas le plus fréquent est le
    -- joueur passé au travers d'un sol qui existe bel et bien.
    if Config.Unstuck.tryGroundAbove then
        local z = groundAt(coords.x, coords.y, 800.0)

        if z then
            dbg(('sol trouvé au-dessus : %.1f'):format(z))
            return vec3(coords.x, coords.y, z + 1.0)
        end
    end

    -- Puis en spirale. Le pas s'élargit à mesure qu'on s'éloigne :
    -- inutile de sonder tous les mètres à cinquante mètres du
    -- point de départ.
    local max = Config.Unstuck.searchRadius

    for radius = 5.0, max, 5.0 do
        local points = math.max(8, math.floor(radius / 2))

        for i = 1, points do
            local angle = (i / points) * math.pi * 2
            local x = coords.x + math.cos(angle) * radius
            local y = coords.y + math.sin(angle) * radius

            local z = groundAt(x, y, coords.z + 200.0)

            if z then
                dbg(('sol trouvé à %.0f m : %.1f, %.1f, %.1f')
                    :format(radius, x, y, z))
                return vec3(x, y, z + 1.0)
            end
        end

        Wait(0)
    end

    return nil
end


-- ═══════════════════════════════════════════════════════════════════
--  SAUVETAGE
-- ═══════════════════════════════════════════════════════════════════

---Déplace le joueur vers une position sûre.
local function rescueTo(pos)
    local ped = cache.ped

    DoScreenFadeOut(500)
    Wait(600)

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    -- Trois mètres au-dessus : le sol peut ne pas être encore
    -- chargé, et un ped posé dans le vide retomberait au travers.
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z + 3.0, false, false, false)

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)

    local deadline = GetGameTimer() + 10000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        Wait(50)
    end

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)

    Wait(500)
    SetEntityInvincible(ped, false)

    DoScreenFadeIn(1000)

    stuckSince = 0
end


---Lance la procédure de déblocage.
function AttemptUnstuck(silent)
    if rescuing then return end

    local now = GetGameTimer()

    -- ─── VÉRIFICATIONS ─────────────────────────────────────────
    if (now - lastUse) < (Config.Unstuck.cooldown * 1000) then
        local left = math.ceil((Config.Unstuck.cooldown * 1000 - (now - lastUse)) / 1000)

        return lib.notify({
            type        = 'error',
            title       = 'Trop tôt',
            description = ('Encore %d secondes avant de pouvoir réessayer.'):format(left),
        })
    end

    -- On bloque après des dégâts récents : sans cette règle, la
    -- commande devient une porte de sortie gratuite en plein combat.
    if (now - lastDamage) < (Config.Unstuck.blockAfterDamageSeconds * 1000) then
        local left = math.ceil((Config.Unstuck.blockAfterDamageSeconds * 1000 - (now - lastDamage)) / 1000)

        return lib.notify({
            type        = 'error',
            title       = 'Impossible en plein combat',
            description = ('Tu as pris des dégâts récemment. Attends %d secondes.'):format(left),
        })
    end

    rescuing = true

    local ok = silent or lib.progressBar({
        duration     = Config.Unstuck.duration,
        label        = 'Recherche d\'une issue...',
        useWhileDead = true,
        canCancel    = true,
        disable      = { car = true, move = true, combat = true },
    })

    if not ok then
        rescuing = false
        return
    end

    lastUse = GetGameTimer()

    local coords = GetEntityCoords(cache.ped)
    local safe = findSafeGround(coords)

    if safe then
        rescueTo(safe)

        lib.notify({
            type        = 'success',
            title       = 'Débloqué',
            description = 'Tu as été replacé sur un sol praticable.',
            duration    = 7000,
        })

        TriggerServerEvent('rz_spawn:unstuckDone', {
            fromX = coords.x, fromY = coords.y, fromZ = coords.z,
            toX = safe.x, toY = safe.y, toZ = safe.z,
            method = 'sol',
        })

    elseif Config.Unstuck.fallbackToSpawn then
        -- Aucun sol trouvé dans les environs : le serveur renvoie
        -- au point d'apparition.
        lib.notify({
            type        = 'inform',
            description = 'Aucun sol praticable trouvé. Retour au point de départ.',
            duration    = 7000,
        })

        TriggerServerEvent('rz_spawn:request')

        TriggerServerEvent('rz_spawn:unstuckDone', {
            fromX = coords.x, fromY = coords.y, fromZ = coords.z,
            method = 'apparition',
        })
    else
        lib.notify({
            type        = 'error',
            description = 'Aucune issue trouvée. Contacte un membre du staff.',
        })
    end

    rescuing = false
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION AUTOMATIQUE
--
--  Le joueur ne pense pas toujours à taper une commande — surtout
--  s'il ne sait pas qu'elle existe. On propose donc de nous-mêmes.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    if not Config.Unstuck.autoDetect then return end

    local lastPos = nil
    local proposed = 0

    while true do
        Wait(5000)

        local ped = cache.ped
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            stuckSince = 0
            goto continue
        end

        do
            local c = GetEntityCoords(ped)

            -- ─── SOUS LA CARTE ─────────────────────────────────
            -- Cas sans ambiguïté : personne ne descend légitimement
            -- sous -120 dans GTA.
            if c.z < Config.Unstuck.underMapZ then
                if (GetGameTimer() - proposed) > 30000 then
                    proposed = GetGameTimer()

                    lib.notify({
                        type        = 'error',
                        title       = 'Tu es sous la carte',
                        description = 'Tape /unstuck pour être replacé.',
                        duration    = 15000,
                    })
                end
                goto continue
            end

            -- ─── IMMOBILE ET COINCÉ ────────────────────────────
            -- Immobile ne suffit pas : un joueur peut lire son
            -- inventaire. On vérifie qu'il ESSAIE de bouger sans y
            -- parvenir.
            if lastPos and IsControlPressed(0, 30) or IsControlPressed(0, 31) then
                local moved = lastPos and #(c - lastPos) or 999

                if moved < 0.3 and not IsPedInAnyVehicle(ped, false) then
                    if stuckSince == 0 then
                        stuckSince = GetGameTimer()
                    elseif (GetGameTimer() - stuckSince) > (Config.Unstuck.stuckSeconds * 1000) then
                        if (GetGameTimer() - proposed) > 60000 then
                            proposed = GetGameTimer()

                            lib.notify({
                                type        = 'warning',
                                title       = 'Tu sembles coincé',
                                description = 'Tape /unstuck si tu ne peux plus bouger.',
                                duration    = 12000,
                            })
                        end
                    end
                else
                    stuckSince = 0
                end
            end

            lastPos = c
        end

        ::continue::
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  SUIVI DES DÉGÂTS
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    local lastHealth = 200

    while true do
        Wait(1000)

        local ped = cache.ped
        if DoesEntityExist(ped) then
            local hp = GetEntityHealth(ped)

            if hp < lastHealth then
                lastDamage = GetGameTimer()
            end

            lastHealth = hp
        end
    end
end)


RegisterCommand('unstuck', function()
    AttemptUnstuck(false)
end, false)


-- Déplacement forcé par le staff : aucune vérification, aucune barre
RegisterNetEvent('rz_spawn:forceMove', function(pos)
    rescueTo(vec3(pos.x, pos.y, pos.z))

    lib.notify({
        type        = 'inform',
        title       = 'Déplacé par le staff',
        description = 'Un membre du staff t\'a repositionné.',
        duration    = 8000,
    })
end)
