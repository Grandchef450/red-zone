--[[
    rz_coffres / server/admin.lua
    Remise et suivi des coffres depuis le menu admin.
]]

local function canGive(source)  return Config.HasAce(source, Config.Ace.give)  end
local function canAdmin(source) return Config.HasAce(source, Config.Ace.admin) end


lib.callback.register('rz_coffres:getPermissions', function(source)
    return { give = canGive(source), admin = canAdmin(source) }
end)


---Liste des coffres déclarés dans ox_inventory, pour le menu.
lib.callback.register('rz_coffres:getChestTypes', function(source)
    if not canGive(source) then return {} end

    local out = {}

    for name, data in pairs(exports.ox_inventory:Items()) do
        if Config.IsChest(name) then
            out[#out + 1] = {
                value = name,
                label = data.label or name,
                hours = Config.GetDefaultHours(name),
            }
        end
    end

    table.sort(out, function(a, b)
        return (a.hours or 0) < (b.hours or 0)
    end)

    return out
end)


---Joueurs connectés, pour la liste déroulante.
lib.callback.register('rz_coffres:getPlayers', function(source)
    if not canGive(source) then return {} end

    local out = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local player = exports.qbx_core:GetPlayer(src)

        if player then
            local c = player.PlayerData.charinfo
            local name = c and ('%s %s'):format(c.firstname or '', c.lastname or '')
                           or GetPlayerName(src)

            out[#out + 1] = {
                value = src,
                label = ('[%d] %s'):format(src, name:gsub('^%s+', '')),
            }
        end
    end

    table.sort(out, function(a, b) return a.value < b.value end)
    return out
end)


---Remise d'un coffre.
lib.callback.register('rz_coffres:give', function(source, target, itemName, hours)
    if not canGive(source) then
        return false, ('Permission %s requise.'):format(Config.Ace.give)
    end

    target = tonumber(target)
    if not target or not GetPlayerName(target) then
        return false, 'Joueur introuvable ou déconnecté.'
    end

    local ok, msg = GiveChest(target, itemName, hours,
        GetPlayerIdentifierByType(source, 'license'))

    return ok, msg
end)


---Historique des coffres remis.
lib.callback.register('rz_coffres:getHistory', function(source, citizenid)
    if not canAdmin(source) then return {} end

    local rows

    if citizenid and citizenid ~= '' then
        rows = MySQL.query.await([[
            SELECT * FROM rz_secure_chests
            WHERE owner_citizenid = ?
            ORDER BY granted_at DESC LIMIT 50
        ]], { citizenid })
    else
        rows = MySQL.query.await([[
            SELECT * FROM rz_secure_chests
            ORDER BY granted_at DESC LIMIT 50
        ]])
    end

    return rows or {}
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES DE SECOURS
--
--  Le menu F5 reste le chemin normal. Ces commandes servent quand
--  l'interface ne répond pas, ou pour un traitement en série après
--  une vague d'achats sur la boutique.
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('givecoffre', {
    help = 'Remettre un coffre de sécurité lié à un joueur',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
        { name = 'item',   type = 'string',   help = 'Nom technique du coffre' },
        { name = 'hours',  type = 'number',   help = 'Durée en heures', optional = true },
    },
    restricted = Config.Ace.give,
}, function(source, args)
    local ok, msg = GiveChest(args.target, args.item, args.hours,
        GetPlayerIdentifierByType(source, 'license'))

    TriggerClientEvent('ox_lib:notify', source, {
        type        = ok and 'success' or 'error',
        title       = 'Coffre de sécurité',
        description = msg,
        duration    = 7000,
    })
end)


lib.addCommand('coffres', {
    help = 'Liste des coffres actifs',
    restricted = Config.Ace.admin,
}, function(source)
    local rows = MySQL.query.await([[
        SELECT owner_name, item_name, expires_at,
               TIMESTAMPDIFF(HOUR, NOW(), expires_at) AS heures
        FROM rz_secure_chests
        WHERE status = 'actif' AND expires_at > NOW()
        ORDER BY expires_at ASC
        LIMIT 30
    ]]) or {}

    if #rows == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'inform', description = 'Aucun coffre actif.' })
    end

    local lines = {}
    for _, r in ipairs(rows) do
        lines[#lines + 1] = ('%s — %s — %d h restantes')
            :format(r.owner_name, r.item_name, r.heures or 0)
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header   = ('Coffres actifs (%d)'):format(#rows),
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end)
