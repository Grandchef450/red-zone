--[[
    rz_perms / client/main.lua

    Passerelle entre l'interface du panneau admin et le serveur.

    Le bloc HTML injecté dans le panneau ne peut pas interroger le
    serveur directement : une NUI ne parle qu'aux callbacks d'une
    ressource. Ce fichier fait le relais.
]]

RegisterNUICallback('getTools', function(_, cb)
    local data = lib.callback.await('rz_perms:getTools', false)
    cb(data or { tools = {}, separator = false })
end)


RegisterCommand('rzgrade', function()
    local info = lib.callback.await('rz_perms:getMyGrade', false)
    if not info then return end

    local lines = {}

    if info.grade then
        lines[#lines + 1] = ('**Grade** : %s'):format(info.grade)
        if info.note then lines[#lines + 1] = info.note end
    else
        lines[#lines + 1] = '**Grade** : aucun grade complet'
        lines[#lines + 1] = 'Tes droits ne correspondent exactement à aucun grade prévu.'
    end

    if info.granted and #info.granted > 0 then
        lines[#lines + 1] = ''
        lines[#lines + 1] = ('**Outils accessibles** (%d)'):format(#info.granted)
        lines[#lines + 1] = table.concat(info.granted, ' · ')
    end

    lib.alertDialog({
        header   = 'Tes permissions RedZone',
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end, false)
