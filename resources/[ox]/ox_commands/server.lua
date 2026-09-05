lib.addCommand('freeze', {
    help = 'Fige le joueur',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID serveur du joueur ciblé',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local entity = GetPlayerPed(args.target)

    if entity ~= 0 then
        TriggerClientEvent('ox_commands:freeze', args.target, true, true)
        return TriggerClientEvent('ox_commands:notify', source, { type = 'success', description = 'success' })
    end

    lib.notify(source, { type = 'error', description = 'invalid_target' })
end)

lib.addCommand('thaw', {
    help = 'Libère le joueur',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID serveur du joueur ciblé',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local entity = GetPlayerPed(args.target)

    if entity ~= 0 then
        TriggerClientEvent('ox_commands:freeze', args.target, false, true)
        return TriggerClientEvent('ox_commands:notify', source, { type = 'success', description = 'success' })
    end

    lib.notify(source, { type = 'error', description = 'invalid_target' })
end)
