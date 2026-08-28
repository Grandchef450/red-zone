--[[
    rz_coffres / client/main.lua
    Interface de remise des coffres, depuis le menu admin (F5).
]]

RegisterNUICallback('openCoffres', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenChestMenu() end)
end)


RegisterCommand('coffremenu', function()
    OpenChestMenu()
end, false)


function OpenChestMenu()
    local perms = lib.callback.await('rz_coffres:getPermissions', false)

    if not perms or (not perms.give and not perms.admin) then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = 'Aucune permission sur les coffres de sécurité.',
        })
    end

    local options = {}

    if perms.give then
        options[#options + 1] = {
            title       = 'Remettre un coffre',
            description = 'Lie un coffre à un joueur pour une durée choisie',
            icon        = 'fas fa-box-archive',
            onSelect    = function() GiveChestDialog() end,
        }
    end

    if perms.admin then
        options[#options + 1] = {
            title       = 'Coffres actifs',
            description = 'Qui détient quoi, et jusqu\'à quand',
            icon        = 'fas fa-clock',
            arrow       = true,
            onSelect    = function() ShowHistory() end,
        }
    end

    lib.registerContext({
        id      = 'rz_coffres_menu',
        title   = 'Coffres de sécurité',
        options = options,
    })

    lib.showContext('rz_coffres_menu')
end


function GiveChestDialog()
    local players = lib.callback.await('rz_coffres:getPlayers', false) or {}
    local chests  = lib.callback.await('rz_coffres:getChestTypes', false) or {}

    if #players == 0 then
        return lib.notify({ type = 'error', description = 'Aucun joueur connecté.' })
    end

    if #chests == 0 then
        return lib.notify({
            type = 'error',
            description = 'Aucun coffre déclaré dans ox_inventory.',
        })
    end

    local durations = {}
    for _, d in ipairs(Config.Durations) do
        durations[#durations + 1] = { value = d.hours, label = d.label }
    end

    local input = lib.inputDialog('Remettre un coffre de sécurité', {
        {
            type = 'select', label = 'Joueur', options = players,
            required = true, searchable = true,
            description = 'Le coffre lui sera lié : personne d\'autre ne pourra l\'ouvrir.',
        },
        {
            type = 'select', label = 'Type de coffre', options = chests,
            required = true, searchable = true,
        },
        {
            type = 'select', label = 'Durée de protection', options = durations,
            required = true, default = 168,
            description = 'Passé ce délai, le coffre reste mais devient ouvrable par son porteur.',
        },
    })

    if not input then return end

    local confirm = lib.alertDialog({
        header   = 'Confirmer la remise',
        content  = ('Le coffre sera **lié définitivement** à ce joueur pour la durée choisie.  \nCette action est tracée en base et ne peut pas être annulée.'),
        centered = true,
        cancel   = true,
        labels   = { confirm = 'Remettre', cancel = 'Annuler' },
    })

    if confirm ~= 'confirm' then return end

    local ok, msg = lib.callback.await('rz_coffres:give', false,
        input[1], input[2], input[3])

    lib.notify({
        type        = ok and 'success' or 'error',
        title       = 'Coffre de sécurité',
        description = msg,
        duration    = 8000,
    })
end


function ShowHistory()
    local rows = lib.callback.await('rz_coffres:getHistory', false, nil) or {}

    if #rows == 0 then
        return lib.notify({
            type = 'inform',
            description = 'Aucun coffre remis pour le moment.',
        })
    end

    local options = {}

    for _, r in ipairs(rows) do
        local actif = r.status == 'actif'

        options[#options + 1] = {
            title       = r.owner_name or 'Inconnu',
            description = ('%s\n%s · %d h\nRemis le %s')
                :format(r.item_name,
                        actif and 'Actif' or 'Expiré',
                        r.duration_hours or 0,
                        tostring(r.granted_at):sub(1, 16)),
            icon        = actif and 'fas fa-lock' or 'fas fa-lock-open',
            iconColor   = actif and '#4ade80' or '#9ca3af',
            disabled    = true,
        }
    end

    lib.registerContext({
        id      = 'rz_coffres_history',
        title   = ('Coffres remis (%d)'):format(#rows),
        menu    = 'rz_coffres_menu',
        options = options,
    })

    lib.showContext('rz_coffres_history')
end
