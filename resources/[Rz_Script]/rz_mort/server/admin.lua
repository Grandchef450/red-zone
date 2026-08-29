--[[
    rz_mort / server/admin.lua
    Outils staff : relever un joueur, gérer les sacs au sol.
]]

lib.callback.register('rz_mort:isAdmin', function(source)
    return Config.HasAce(source)
end)


lib.callback.register('rz_mort:adminRevive', function(source, targetId)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        return false, 'Joueur introuvable.'
    end

    TriggerClientEvent('rz_mort:revived', targetId, {
        health = 200,
        groggy = 0,
        byName = 'le staff',
    })

    -- On force la sortie d'agonie même si le joueur n'y était pas :
    -- ça sert aussi à débloquer quelqu'un resté coincé.
    if Player(targetId) then
        Player(targetId).state:set('rzDowned', false, true)
    end

    pcall(function()
        exports.qbx_core:SetMetadata(targetId, 'inlaststand', false)
        exports.qbx_core:SetMetadata(targetId, 'isdead', false)
    end)

    return true, 'Joueur relevé.'
end)


lib.callback.register('rz_mort:listBags', function(source)
    if not Config.HasAce(source) then return {} end

    local now = os.time()
    local out = {}

    for id, b in pairs(Bags) do
        out[#out + 1] = {
            id        = id,
            owner     = b.ownerName,
            x = b.x, y = b.y, z = b.z,
            ageMin    = math.floor((now - b.createdAt) / 60),
            locked    = now < b.lockUntil,
            lockLeft  = math.max(0, b.lockUntil - now),
        }
    end

    table.sort(out, function(a, b) return a.ageMin < b.ageMin end)
    return out
end)


lib.callback.register('rz_mort:clearBags', function(source)
    if not Config.HasAce(source) then return false, 'Permission requise.' end

    local n = 0

    for id in pairs(Bags) do
        pcall(function() exports.ox_inventory:RemoveInventory(id) end)
        TriggerClientEvent('rz_mort:removeBag', -1, id)
        Bags[id] = nil
        n = n + 1
    end

    MySQL.prepare('DELETE FROM rz_mort_bags')

    return true, ('%d sac(s) supprimé(s).'):format(n)
end)


lib.addCommand('reanimer', {
    help = 'Relever un joueur à terre',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
    },
    restricted = Config.Ace,
}, function(source, args)
    TriggerClientEvent('rz_mort:revived', args.target, {
        health = 200, groggy = 0, byName = 'le staff',
    })

    if Player(args.target) then
        Player(args.target).state:set('rzDowned', false, true)
    end

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success', description = 'Joueur relevé.',
    })
end)
