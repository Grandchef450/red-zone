--[[
    rz_signal_urgences / server/admin.lua
    Annonces du staff et pilotage du réseau, depuis le menu admin.
]]

local function canAnnounce(source) return Config.HasAce(source, Config.Ace.announce) end
local function canNetwork(source)  return Config.HasAce(source, Config.Ace.network)  end

local function deny(source, perm)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(perm),
    })
    return false
end

local function adminId(source)
    return GetPlayerIdentifierByType(source, 'license')
end


lib.callback.register('rz_signal:getPermissions', function(source)
    return {
        announce = canAnnounce(source),
        network  = canNetwork(source),
    }
end)


-- ═══════════════════════════════════════════════════════════════════
--  ANNONCE DU STAFF
--
--  Priorité 'staff' : traverse les pannes réseau. C'est ce qui la
--  distingue d'une alerte automatique et lui donne son autorité.
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_signal:announce', function(source, message, sender, zoneKey)
    if not canAnnounce(source) then
        return false, ('Permission %s requise.'):format(Config.Ace.announce)
    end

    message = tostring(message or ''):gsub('^%s+', ''):gsub('%s+$', '')

    if #message < 3 then
        return false, 'Message trop court.'
    end

    if #message > 200 then
        message = message:sub(1, 200)
    end

    local sent = Broadcast({
        message  = message:upper(),
        priority = 'staff',
        sender   = (sender and sender ~= '') and sender:upper() or 'STAFF REDZONE',
        zone     = (zoneKey ~= '' and zoneKey) or nil,
    })

    MySQL.prepare([[
        INSERT INTO rz_signal_logs (priority, sender, message, zone, recipients, admin)
        VALUES ('staff', ?, ?, ?, ?, ?)
    ]], { sender, message, zoneKey, sent, adminId(source) })

    return true, ('Annonce transmise à %d pager(s).'):format(sent)
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT DU RÉSEAU
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_signal:getZones', function(source)
    if not canNetwork(source) and not canAnnounce(source) then return {} end

    local out = {}

    for key, zone in pairs(Config.Zones) do
        out[#out + 1] = {
            key     = key,
            label   = zone.label,
            powered = NetworkUp[key] ~= false,
        }
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)


lib.callback.register('rz_signal:setNetwork', function(source, zoneKey, up)
    if not canNetwork(source) then
        return false, ('Permission %s requise.'):format(Config.Ace.network)
    end

    return SetNetwork(zoneKey, up, adminId(source))
end)


---Coupure générale : toutes les zones d'un coup.
lib.callback.register('rz_signal:blackoutAll', function(source, up)
    if not canNetwork(source) then
        return false, ('Permission %s requise.'):format(Config.Ace.network)
    end

    local count = 0

    for key in pairs(Config.Zones) do
        if (NetworkUp[key] ~= false) ~= up then
            SetNetwork(key, up, adminId(source))
            count = count + 1
            -- Un léger décalage évite d'envoyer six signaux dans la
            -- même frame, ce qui les rendrait illisibles.
            Wait(600)
        end
    end

    return true, ('%d zone(s) %s.'):format(count, up and 'rétablie(s)' or 'coupée(s)')
end)


-- ═══════════════════════════════════════════════════════════════════
--  HISTORIQUE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_signal:getHistory', function(source)
    if not canAnnounce(source) then return {} end

    return MySQL.query.await([[
        SELECT priority, sender, message, zone, recipients, created_at
        FROM rz_signal_logs
        ORDER BY created_at DESC
        LIMIT 30
    ]]) or {}
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES DE SECOURS
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('annonce', {
    help = 'Diffuser une annonce staff sur tous les pagers',
    params = {
        { name = 'message', type = 'string', help = 'Texte de l\'annonce' },
    },
    restricted = Config.Ace.announce,
}, function(source, args)
    local sent = Broadcast({
        message  = tostring(args.message):upper(),
        priority = 'staff',
        sender   = 'STAFF REDZONE',
    })

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Annonce transmise à %d pager(s).'):format(sent),
    })
end)


lib.addCommand('reseau', {
    help = 'Couper ou rétablir le réseau et le courant d\'une zone',
    params = {
        { name = 'zone',  type = 'string', help = 'Clé de la zone' },
        { name = 'etat',  type = 'string', help = 'on / off' },
    },
    restricted = Config.Ace.network,
}, function(source, args)
    local up = args.etat:lower() == 'on'
    local ok, msg = SetNetwork(args.zone, up, adminId(source))

    TriggerClientEvent('ox_lib:notify', source, {
        type = ok and 'success' or 'error',
        description = msg,
        duration = 6000,
    })
end)
