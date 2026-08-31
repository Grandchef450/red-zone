--[[
    rz_spawn / server/rescue.lua

    Désenclavement des joueurs, et outils de déplacement pour le staff.

    ─── LE PIÈGE À ÉVITER ─────────────────────────────────────────

    Une commande de téléportation libre devient vite un outil de
    triche : on l'utilise pour fuir un combat, pour traverser une
    safe zone, pour échapper à un braquage.

    Le compte à rebours immobile règle ça. Quelqu'un réellement
    coincé attend quinze secondes sans problème ; quelqu'un qui fuit
    ne peut pas se permettre de rester immobile.
]]

-- [license] = horodatage de la dernière utilisation
local lastUse = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


local function licenseOf(source)
    return GetPlayerIdentifierByType(source, 'license')
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉSENCLAVEMENT
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_spawn:canUnstuck', function(source)
    if not Config.Unstuck.enabled then
        return false, 'Le désenclavement est désactivé.'
    end

    local license = licenseOf(source)
    if not license then return false, 'Identifiant introuvable.' end

    local last = lastUse[license]
    local now = os.time()

    if last then
        local left = Config.Unstuck.cooldown - (now - last)

        if left > 0 then
            return false, ('Encore %d min %d s avant de pouvoir réessayer.')
                :format(math.floor(left / 60), left % 60)
        end
    end

    return true, {
        countdown     = Config.Unstuck.countdown,
        tolerance     = Config.Unstuck.moveTolerance,
        cancelOnDamage = Config.Unstuck.cancelOnDamage,
        combatLock    = Config.Unstuck.combatLockSeconds,
    }
end)


---Le client a tenu le compte à rebours : on valide et on enregistre.
lib.callback.register('rz_spawn:confirmUnstuck', function(source, step)
    local license = licenseOf(source)
    if not license then return false end

    lastUse[license] = os.time()

    local ped = GetPlayerPed(source)
    local coords = ped ~= 0 and GetEntityCoords(ped) or vector3(0, 0, 0)

    MySQL.prepare([[
        INSERT INTO rz_spawn_logs (license, name, action, detail)
        VALUES (?, ?, 'unstuck', ?)
    ]], { license, GetPlayerName(source),
          json.encode({ step = step, x = coords.x, y = coords.y, z = coords.z }) })

    if GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('admin', {
                title  = 'Désenclavement',
                source = source,
                fields = {
                    { name = 'Méthode',  value = tostring(step) },
                    { name = 'Position', value = ('%.0f, %.0f, %.0f')
                        :format(coords.x, coords.y, coords.z) },
                },
            })
        end)
    end

    dbg(('%s désenclavé (%s)'):format(GetPlayerName(source) or source, step))

    return true
end)


---Point de départ, pour la dernière étape du désenclavement.
lib.callback.register('rz_spawn:getFallback', function(source)
    local d = Config.Spawn.default
    return { x = d.x, y = d.y, z = d.z, w = d.w or 0.0 }
end)


-- ═══════════════════════════════════════════════════════════════════
--  ZONES INTERDITES
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_spawn:getBlacklist', function(source)
    if not Config.HasAce(source) then return {} end
    return Config.Blacklist
end)


---Ajoute une zone interdite pour la session en cours.
lib.callback.register('rz_spawn:addBlacklist', function(source, label, radius)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 'Position introuvable.' end

    local c = GetEntityCoords(ped)
    radius = math.max(5.0, math.min(500.0, tonumber(radius) or 25.0))

    Config.Blacklist[#Config.Blacklist + 1] = {
        label = label or 'Zone à problème',
        x = c.x, y = c.y, z = c.z, r = radius,
    }

    MySQL.prepare([[
        INSERT INTO rz_spawn_blacklist (label, x, y, z, radius, added_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { label, c.x, c.y, c.z, radius, licenseOf(source) })

    dbg(('zone interdite ajoutée : %s (%.0f m)'):format(label, radius))

    -- La valeur est aussi donnée à copier : une zone ajoutée en jeu
    -- disparaît au redémarrage si elle n'est qu'en base. Celles du
    -- config.lua, elles, survivent à tout.
    return true, ('Zone « %s » interdite sur %.0f m.\n\nPour la rendre permanente, copie dans config.lua :\n{ label = \'%s\', x = %.1f, y = %.1f, z = %.1f, r = %.0f },')
        :format(label, radius, label, c.x, c.y, c.z, radius)
end)


lib.callback.register('rz_spawn:removeBlacklist', function(source, index)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    local zone = Config.Blacklist[index]
    if not zone then return false, 'Zone introuvable.' end

    table.remove(Config.Blacklist, index)

    MySQL.prepare('DELETE FROM rz_spawn_blacklist WHERE label = ? AND x = ? AND y = ?',
        { zone.label, zone.x, zone.y })

    return true, ('Zone « %s » retirée.'):format(zone.label)
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS STAFF
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_spawn:isAdmin', function(source)
    return Config.HasAce(source)
end)


---Liste des joueurs, avec ce qu'il faut pour repérer un bloqué.
lib.callback.register('rz_spawn:getPlayers', function(source)
    if not Config.HasAce(source) then return {} end

    local out = {}
    local myPed = GetPlayerPed(source)
    local myCoords = myPed ~= 0 and GetEntityCoords(myPed) or nil

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local ped = GetPlayerPed(src)

        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)

            -- Deux signes qui trahissent un joueur en difficulté
            local underMap = c.z < Config.Detection.underMapZ
            local atOrigin = math.sqrt(c.x * c.x + c.y * c.y) < 5.0

            out[#out + 1] = {
                id       = src,
                name     = GetPlayerName(src),
                x = c.x, y = c.y, z = c.z,
                distance = myCoords and #(myCoords - c) or nil,
                stuck    = underMap or atOrigin,
                reason   = underMap and 'sous la carte'
                        or atOrigin and 'position zéro' or nil,
                blacklist = Config.BlacklistedAt(c.x, c.y, c.z) ~= nil,
            }
        end
    end

    table.sort(out, function(a, b)
        -- Les joueurs en difficulté remontent en tête : c'est eux
        -- qu'on cherche quand on ouvre ce menu.
        if a.stuck ~= b.stuck then return a.stuck end
        return a.id < b.id
    end)

    return out
end)


---Déplace un joueur vers un autre, ou l'inverse.
lib.callback.register('rz_spawn:teleport', function(source, targetId, direction)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    local fromId = direction == 'bring' and targetId or source
    local toId   = direction == 'bring' and source or targetId

    local destPed = GetPlayerPed(toId)
    if not destPed or destPed == 0 then return false, 'Destination introuvable.' end

    local c = GetEntityCoords(destPed)

    -- Léger décalage : sans lui, les deux peds se superposent et
    -- l'un des deux est éjecté par la physique.
    TriggerClientEvent('rz_spawn:goTo', fromId, {
        x = c.x + 1.5, y = c.y + 1.5, z = c.z,
        w = GetEntityHeading(destPed),
        health = nil, armour = nil,
        isNew = false,
        silent = true,
    })

    MySQL.prepare([[
        INSERT INTO rz_spawn_logs (license, name, action, detail)
        VALUES (?, ?, 'teleport', ?)
    ]], { licenseOf(source), GetPlayerName(source),
          json.encode({ target = GetPlayerName(targetId), direction = direction }) })

    return true, direction == 'bring'
        and ('%s a été amené jusqu\'à toi.'):format(GetPlayerName(targetId))
        or  ('Tu as rejoint %s.'):format(GetPlayerName(targetId))
end)


---Renvoie un joueur au point de départ.
lib.callback.register('rz_spawn:sendToSpawn', function(source, targetId)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    local d = Config.Spawn.default

    TriggerClientEvent('rz_spawn:goTo', targetId, {
        x = d.x, y = d.y, z = d.z, w = d.w or 0.0,
        health = Config.Spawn.health,
        isNew = false,
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        type        = 'inform',
        title       = 'Déplacé par le staff',
        description = 'Tu as été replacé au point de départ.',
        duration    = 8000,
    })

    return true, ('%s renvoyé au point de départ.'):format(GetPlayerName(targetId))
end)


---Force le désenclavement d'un joueur, sans compte à rebours.
lib.callback.register('rz_spawn:forceUnstuck', function(source, targetId)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    TriggerClientEvent('rz_spawn:forceRescue', targetId)

    return true, ('Désenclavement lancé pour %s.'):format(GetPlayerName(targetId))
end)


-- ═══════════════════════════════════════════════════════════════════
--  CHARGEMENT
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(2000)

    -- On ajoute les zones enregistrées à celles du fichier : les
    -- premières sont modifiables en jeu, les secondes survivent à
    -- tout et servent de socle.
    local rows = MySQL.query.await(
        'SELECT label, x, y, z, radius FROM rz_spawn_blacklist') or {}

    for _, r in ipairs(rows) do
        Config.Blacklist[#Config.Blacklist + 1] = {
            label = r.label, x = r.x, y = r.y, z = r.z, r = r.radius,
        }
    end

    if #Config.Blacklist > 0 then
        print(('^2[rz_spawn]^7 %d zone(s) interdite(s)'):format(#Config.Blacklist))
    end
end)

---Réinitialise l'apparence d'un joueur à distance.
---Utile quand quelqu'un plante à chaque connexion : son apparence
---référence un vêtement d'un pack retiré depuis.
lib.callback.register('rz_spawn:resetAppearance', function(source, targetId)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    TriggerClientEvent('rz_spawn:forceResetAppearance', targetId)

    return true, ('Apparence de %s réinitialisée.'):format(GetPlayerName(targetId))
end)


lib.addCommand('fixskin', {
    help = 'Réinitialiser l\'apparence d\'un joueur qui plante',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
    },
    restricted = Config.Ace,
}, function(source, args)
    TriggerClientEvent('rz_spawn:forceResetAppearance', args.target)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Apparence de %s réinitialisée.')
            :format(GetPlayerName(args.target) or args.target),
    })
end)
