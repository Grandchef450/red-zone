--[[
    rz_spawn / server/unstuck.lua

    Zones qui font planter, et outils de sauvetage pour le staff.

    ─── LE PROBLÈME DES ZONES QUI PLANTENT ────────────────────────

    Un endroit qui fait crasher est un piège invisible. Le joueur y
    retourne — souvent parce que son personnage y a été sauvegardé —
    replante, et finit par croire que le serveur est cassé.

    Et il ne peut pas le signaler : il est éjecté du jeu avant.

    C'est donc au staff de marquer la zone. Ensuite le serveur s'en
    charge : personne n'y apparaît, personne n'y entre.
]]

-- [id] = { x, y, z, radius, label, note }
CrashZones = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  ZONES À PLANTAGE
-- ═══════════════════════════════════════════════════════════════════

---Ce point est-il dans une zone dangereuse ?
---@return table|nil
function CrashZoneAt(x, y, z)
    if not Config.CrashZones.enabled then return nil end

    for _, zone in pairs(CrashZones) do
        local dx, dy = x - zone.x, y - zone.y
        local dist = math.sqrt(dx * dx + dy * dy)

        -- On ignore la hauteur : un plantage lié au décor affecte
        -- toute la colonne, du sous-sol au ciel.
        if dist <= zone.radius then
            return zone
        end
    end

    return nil
end

exports('CrashZoneAt', CrashZoneAt)


---Charge les zones depuis la base.
local function loadCrashZones()
    local rows = MySQL.query.await([[
        SELECT id, x, y, z, radius, label, note
        FROM rz_crash_zones WHERE enabled = 1
    ]]) or {}

    CrashZones = {}

    for _, r in ipairs(rows) do
        CrashZones[r.id] = {
            id = r.id, x = r.x, y = r.y, z = r.z,
            radius = r.radius, label = r.label, note = r.note,
        }
    end

    -- Les clients ont besoin de la liste pour prévenir et repousser
    TriggerClientEvent('rz_spawn:crashZones', -1, CrashZones)

    dbg(('%d zone(s) à plantage chargée(s)'):format(#rows))
    return #rows
end


lib.callback.register('rz_spawn:getCrashZones', function()
    return CrashZones
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS DU STAFF
-- ═══════════════════════════════════════════════════════════════════

local function deny(source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(Config.Ace),
    })
    return false
end


lib.callback.register('rz_spawn:isAdmin', function(source)
    return Config.HasAce(source)
end)


---Liste des joueurs, avec détection de ceux qui semblent bloqués.
lib.callback.register('rz_spawn:getPlayers', function(source)
    if not Config.HasAce(source) then return {} end

    local out = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local ped = GetPlayerPed(src)

        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)

            -- Deux signes de blocage, sans ambiguïté
            local underMap = c.z < Config.Unstuck.underMapZ
            local atOrigin = math.sqrt(c.x * c.x + c.y * c.y) < 5.0

            local zone = CrashZoneAt(c.x, c.y, c.z)

            out[#out + 1] = {
                id       = src,
                name     = GetPlayerName(src),
                x = c.x, y = c.y, z = c.z,
                underMap = underMap,
                atOrigin = atOrigin,
                inCrash  = zone and zone.label or nil,
                suspect  = underMap or atOrigin or zone ~= nil,
            }
        end
    end

    table.sort(out, function(a, b)
        -- Les joueurs en difficulté d'abord : c'est eux qu'on cherche
        if a.suspect ~= b.suspect then return a.suspect end
        return a.id < b.id
    end)

    return out
end)


---Renvoie un joueur à son point d'apparition.
lib.callback.register('rz_spawn:rescuePlayer', function(source, targetId)
    if not Config.HasAce(source) then return deny(source) end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    SpawnPlayer(targetId)

    MySQL.prepare('INSERT INTO rz_spawn_logs (admin, target, action, detail) VALUES (?, ?, ?, ?)', {
        GetPlayerIdentifierByType(source, 'license'),
        GetPlayerIdentifierByType(targetId, 'license'),
        'rescue', '{}'
    })

    return true, ('%s renvoyé au point d\'apparition.'):format(GetPlayerName(targetId))
end)


---Téléporte un joueur sur la position de l'admin.
lib.callback.register('rz_spawn:bringPlayer', function(source, targetId)
    if not Config.HasAce(source) then return deny(source) end

    targetId = tonumber(targetId)
    local ped = GetPlayerPed(source)

    if not targetId or not GetPlayerName(targetId) or not ped or ped == 0 then
        return false, 'Impossible.'
    end

    local c = GetEntityCoords(ped)

    TriggerClientEvent('rz_spawn:forceMove', targetId, {
        x = c.x + 1.5, y = c.y + 1.5, z = c.z
    })

    MySQL.prepare('INSERT INTO rz_spawn_logs (admin, target, action, detail) VALUES (?, ?, ?, ?)', {
        GetPlayerIdentifierByType(source, 'license'),
        GetPlayerIdentifierByType(targetId, 'license'),
        'bring', json.encode({ x = c.x, y = c.y, z = c.z })
    })

    return true, ('%s amené près de toi.'):format(GetPlayerName(targetId))
end)


---Se téléporte sur un joueur.
lib.callback.register('rz_spawn:goToPlayer', function(source, targetId)
    if not Config.HasAce(source) then return deny(source) end

    targetId = tonumber(targetId)
    local ped = GetPlayerPed(targetId)

    if not ped or ped == 0 then return false, 'Joueur introuvable.' end

    local c = GetEntityCoords(ped)

    TriggerClientEvent('rz_spawn:forceMove', source, {
        x = c.x + 1.5, y = c.y + 1.5, z = c.z
    })

    return true, ('Téléporté sur %s.'):format(GetPlayerName(targetId))
end)


-- ═══════════════════════════════════════════════════════════════════
--  GESTION DES ZONES À PLANTAGE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_spawn:addCrashZone', function(source, data)
    if not Config.HasAce(source) then return deny(source) end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 'Position introuvable.' end

    local c = GetEntityCoords(ped)
    local radius = math.max(10.0, math.min(500.0, tonumber(data.radius) or 50.0))

    local id = MySQL.insert.await([[
        INSERT INTO rz_crash_zones (x, y, z, radius, label, note, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { c.x, c.y, c.z, radius, data.label, data.note,
          GetPlayerIdentifierByType(source, 'license') })

    loadCrashZones()

    return true, ('Zone « %s » marquée sur %.0f m.'):format(data.label, radius)
end)


lib.callback.register('rz_spawn:removeCrashZone', function(source, id)
    if not Config.HasAce(source) then return deny(source) end

    MySQL.prepare.await('DELETE FROM rz_crash_zones WHERE id = ?', { tonumber(id) })
    loadCrashZones()

    return true, 'Zone retirée.'
end)


-- ═══════════════════════════════════════════════════════════════════
--  JOURNAL
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_spawn:unstuckDone', function(data)
    local src = source

    MySQL.prepare([[
        INSERT INTO rz_spawn_logs (target, action, detail)
        VALUES (?, 'unstuck', ?)
    ]], { GetPlayerIdentifierByType(src, 'license'), json.encode(data or {}) })

    -- Un joueur qui se débloque souvent au même endroit signale un
    -- décor défectueux. C'est ce qui permet de repérer les pièges
    -- avant qu'ils ne fassent fuir du monde.
    if GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('suspect', {
                title  = 'Déblocage manuel',
                source = src,
                fields = {
                    { name = 'Depuis', value = ('%.0f, %.0f, %.0f')
                        :format(data.fromX or 0, data.fromY or 0, data.fromZ or 0) },
                    { name = 'Méthode', value = data.method or '?' },
                },
            })
        end)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('rescue', {
    help = 'Renvoyer un joueur à son point d\'apparition',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
    },
    restricted = Config.Ace,
}, function(source, args)
    SpawnPlayer(args.target)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('%s replacé.'):format(GetPlayerName(args.target) or args.target),
    })
end)


lib.addCommand('crashzones', {
    help = 'Liste des zones qui font planter',
    restricted = Config.Ace,
}, function(source)
    local lines = {}

    for _, z in pairs(CrashZones) do
        lines[#lines + 1] = ('**%s** — %.0f m  \n`%.0f, %.0f, %.0f`%s')
            :format(z.label, z.radius, z.x, z.y, z.z,
                    z.note and ('  \n' .. z.note) or '')
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header  = ('Zones à plantage (%d)'):format(#lines),
        content = #lines > 0 and table.concat(lines, '  \n\n')
            or 'Aucune zone marquée.',
        centered = true,
    })
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(2000)
    local n = loadCrashZones()

    if n > 0 then
        print(('^3[rz_spawn]^7 %d zone(s) à plantage active(s)'):format(n))
    end
end)


AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(5000, function()
        if GetPlayerName(src) then
            TriggerClientEvent('rz_spawn:crashZones', src, CrashZones)
        end
    end)
end)
