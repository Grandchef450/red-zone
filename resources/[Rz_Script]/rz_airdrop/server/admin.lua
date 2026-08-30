--[[
    rz_airdrop / server/admin.lua
    Pilotage des largages depuis le menu F5.
]]

local function deny(source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(Config.Ace),
    })
    return false
end


lib.callback.register('rz_airdrop:isAdmin', function(source)
    return Config.HasAce(source)
end)


lib.callback.register('rz_airdrop:getState', function(source)
    if not Config.HasAce(source) then return end

    local info = GetAirdropInfo()

    local list = {}
    local now = os.time()

    for id, c in pairs(Crates) do
        list[#list + 1] = {
            id        = id,
            label     = c.label,
            tier      = c.tier,
            x = c.x, y = c.y,
            locked    = now < c.openableAt,
            lockLeft  = math.max(0, c.openableAt - now),
            lifeLeft  = math.max(0, c.expiresAt - now),
            opened    = c.opened,
            piles     = #c.contents,
        }
    end

    table.sort(list, function(a, b) return a.tier > b.tier end)
    info.list = list

    return info
end)


lib.callback.register('rz_airdrop:forceDrop', function(source)
    if not Config.HasAce(source) then return deny(source) end

    local ok, msg = LaunchDrop(true)

    if ok then
        MySQL.prepare('INSERT INTO rz_airdrop_logs (admin, action, detail) VALUES (?, ?, ?)', {
            GetPlayerIdentifierByType(source, 'license'), 'forceDrop', '{}'
        })
    end

    return ok, msg
end)


lib.callback.register('rz_airdrop:toggle', function(source)
    if not Config.HasAce(source) then return deny(source) end

    Config.Schedule.enabled = not Config.Schedule.enabled

    return true, Config.Schedule.enabled
        and 'Largages automatiques réactivés.'
        or  'Largages automatiques suspendus.'
end)


lib.callback.register('rz_airdrop:clearCrates', function(source)
    if not Config.HasAce(source) then return deny(source) end

    local n = 0

    for id in pairs(Crates) do
        pcall(function() exports.ox_inventory:RemoveInventory(id) end)
        TriggerClientEvent('rz_airdrop:removeCrate', -1, id)
        Crates[id] = nil
        n = n + 1
    end

    return true, ('%d caisse(s) retirée(s).'):format(n)
end)


---Déverrouille toutes les caisses tout de suite. Utile pour un
---événement animé, ou quand un largage tombe cinq minutes avant
---un redémarrage.
lib.callback.register('rz_airdrop:unlockAll', function(source)
    if not Config.HasAce(source) then return deny(source) end

    local now = os.time()
    local n = 0

    for _, c in pairs(Crates) do
        if now < c.openableAt then
            c.openableAt = now
            n = n + 1
        end
    end

    if n > 0 then
        TriggerClientEvent('rz_airdrop:unlockAll', -1)
    end

    return true, ('%d caisse(s) déverrouillée(s).'):format(n)
end)


lib.addCommand('airdrop', {
    help = 'Lancer un largage immédiatement',
    restricted = Config.Ace,
}, function(source)
    local ok, msg = LaunchDrop(true)

    TriggerClientEvent('ox_lib:notify', source, {
        type = ok and 'success' or 'error',
        description = msg,
        duration = 8000,
    })
end)


lib.addCommand('airdropinfo', {
    help = 'État des largages',
    restricted = Config.Ace,
}, function(source)
    local i = GetAirdropInfo()

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header = 'Largages',
        content = ([[
**%s**

Prochain largage dans **%d min**
Caisses au sol : **%d** (dont %d verrouillées)
Avion en vol : %s]]):format(
            i.enabled and 'Automatique activé' or 'Automatique suspendu',
            math.ceil(i.nextIn / 60), i.crates, i.protected,
            i.flying and 'oui' or 'non'),
        centered = true,
    })
end)
