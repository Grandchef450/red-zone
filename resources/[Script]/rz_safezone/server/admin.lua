--[[
    rz_safezone / server/admin.lua
    Création et modification des zones depuis le menu admin.
]]

local function canEdit(source) return Config.HasAce(source, Config.Ace.edit) end
local function canView(source) return Config.HasAce(source, Config.Ace.view) or canEdit(source) end

local function deny(source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(Config.Ace.edit),
    })
    return false
end


lib.callback.register('rz_safezone:getPermissions', function(source)
    return { edit = canEdit(source), view = canView(source) }
end)


---Liste des zones pour le menu, avec leur centre pré-calculé.
lib.callback.register('rz_safezone:admin:getZones', function(source)
    if not canView(source) then return {} end

    local out = {}

    for key, z in pairs(Zones) do
        local sx, sy = 0.0, 0.0
        for _, p in ipairs(z.points) do sx, sy = sx + p.x, sy + p.y end

        out[#out + 1] = {
            id         = z.id,
            key        = key,
            label      = z.label,
            pointCount = #z.points,
            minZ       = z.min_z,
            maxZ       = z.max_z,
            buffer     = z.buffer_meters,
            centerX    = sx / #z.points,
            centerY    = sy / #z.points,

            enterMessage     = z.enter_message,
            blockDamage      = z.block_damage == 1,
            blockWeapons     = z.block_weapons == 1,
            blockMelee       = z.block_melee == 1,
            blockProjectiles = z.block_projectiles == 1,
            blockVehicles    = z.block_vehicles == 1,
            despawnZombies   = z.despawn_zombies == 1,
        }
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)


lib.callback.register('rz_safezone:admin:createZone', function(source, data)
    if not canEdit(source) then return deny(source) end

    if type(data.points) ~= 'table' or #data.points < 3 then
        return false, 'Il faut au moins 3 points.'
    end

    -- L'identifiant doit rester utilisable comme clé par les autres
    -- scripts : pas d'espace, pas d'accent, pas de majuscule.
    local key = (data.zone_key or ''):lower():gsub('[^a-z0-9_]', '_')
    if key == '' then return false, 'Identifiant invalide.' end

    local exists = MySQL.single.await(
        'SELECT id FROM rz_safezones WHERE zone_key = ?', { key })
    if exists then
        return false, ('L\'identifiant « %s » est déjà pris.'):format(key)
    end

    -- On ne garde que x et y : le z du tracé ne sert qu'à l'affichage
    -- pendant l'édition, le volume est défini par min_z et max_z.
    local clean = {}
    for _, p in ipairs(data.points) do
        clean[#clean + 1] = {
            x = tonumber(string.format('%.3f', p.x)),
            y = tonumber(string.format('%.3f', p.y)),
        }
    end

    MySQL.insert.await([[
        INSERT INTO rz_safezones
            (zone_key, label, points, min_z, max_z, buffer_meters,
             enter_message, despawn_zombies, block_vehicles, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        key, data.label, json.encode(clean),
        data.min_z, data.max_z, data.buffer_meters,
        data.enter_message,
        data.despawn_zombies and 1 or 0,
        data.block_vehicles and 1 or 0,
        GetPlayerIdentifierByType(source, 'license'),
    })

    LoadZones()
    return true
end)


lib.callback.register('rz_safezone:admin:updatePoints', function(source, id, data)
    if not canEdit(source) then return deny(source) end

    if type(data.points) ~= 'table' or #data.points < 3 then
        return false, 'Il faut au moins 3 points.'
    end

    local clean = {}
    for _, p in ipairs(data.points) do
        clean[#clean + 1] = {
            x = tonumber(string.format('%.3f', p.x)),
            y = tonumber(string.format('%.3f', p.y)),
        }
    end

    MySQL.prepare.await([[
        UPDATE rz_safezones SET points = ?, min_z = ?, max_z = ? WHERE id = ?
    ]], { json.encode(clean), data.min_z, data.max_z, id })

    LoadZones()
    return true
end)


lib.callback.register('rz_safezone:admin:updateRules', function(source, id, data)
    if not canEdit(source) then return deny(source) end

    MySQL.prepare.await([[
        UPDATE rz_safezones SET
            buffer_meters = ?, min_z = ?, max_z = ?, enter_message = ?,
            block_damage = ?, block_weapons = ?, block_melee = ?,
            block_projectiles = ?, block_vehicles = ?, despawn_zombies = ?
        WHERE id = ?
    ]], {
        data.buffer_meters, data.min_z, data.max_z, data.enter_message,
        data.block_damage and 1 or 0,
        data.block_weapons and 1 or 0,
        data.block_melee and 1 or 0,
        data.block_projectiles and 1 or 0,
        data.block_vehicles and 1 or 0,
        data.despawn_zombies and 1 or 0,
        id,
    })

    LoadZones()
    return true
end)


lib.callback.register('rz_safezone:admin:deleteZone', function(source, id)
    if not canEdit(source) then return deny(source) end

    MySQL.prepare.await('DELETE FROM rz_safezones WHERE id = ?', { id })
    LoadZones()
    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  DIAGNOSTIC
--  Qui insiste le plus à tirer dans les zones ?
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('szstats', {
    help = 'Tentatives de tir bloquées dans les zones sûres (7 derniers jours)',
    restricted = Config.Ace.view,
}, function(source)
    local rows = MySQL.query.await([[
        SELECT attacker, zone_key, COUNT(*) AS n
        FROM rz_safezone_blocks
        WHERE created_at > NOW() - INTERVAL 7 DAY
        GROUP BY attacker, zone_key
        ORDER BY n DESC
        LIMIT 15
    ]]) or {}

    if #rows == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'inform', description = 'Aucune tentative bloquée cette semaine.' })
    end

    local lines = {}
    for _, r in ipairs(rows) do
        lines[#lines + 1] = ('%s — %s : %d')
            :format(r.attacker or 'inconnu', r.zone_key, r.n)
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header  = 'Tentatives bloquées (7 jours)',
        content = table.concat(lines, '  \n'),
        centered = true,
    })
end)
