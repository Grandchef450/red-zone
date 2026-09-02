--[[
    rz_invcheck / client/main.lua
    Recherche + ouverture d'un inventaire depuis F5 ou /invcheck.
]]

local function openResult(r)
    if r.online then
        local c = lib.alertDialog({
            header   = r.label,
            content  = 'Ouvre une vue à deux panneaux, comme looter un corps : '
                    .. 'tu peux y déposer ou en retirer des objets. Continuer ?',
            centered = true, cancel = true,
        })

        if c ~= 'confirm' then return end

        local ok, msg = lib.callback.await(
            'rz_invcheck:inspectOnline', false, r.source, r.label, r.citizenid)

        if not ok then
            lib.notify({ type = 'error', description = msg, duration = 7000 })
        end

        return
    end

    -- Hors ligne : instantané en lecture seule.
    local snapshot = lib.callback.await(
        'rz_invcheck:inspectOffline', false, r.citizenid, r.label)

    if not snapshot then
        return lib.notify({ type = 'error', description = 'Impossible de lire cet inventaire.' })
    end

    if snapshot.empty then
        return lib.alertDialog({
            header   = snapshot.label,
            content  = 'Inventaire vide, ou jamais sauvegardé.',
            centered = true,
        })
    end

    local lines = {}
    for _, item in ipairs(snapshot.items) do
        lines[#lines + 1] = ('%d × %s  `%s`'):format(item.count, item.label, item.name)
    end

    lib.alertDialog({
        header   = ('%s — hors ligne'):format(snapshot.label),
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end


local function showResults(results)
    if #results == 0 then
        return lib.notify({ type = 'error', description = 'Aucun résultat.' })
    end

    if #results == 1 then
        return openResult(results[1])
    end

    local options = {}

    for _, r in ipairs(results) do
        options[#options + 1] = {
            title       = r.label,
            description = r.online and 'En ligne' or 'Hors ligne',
            icon        = r.online and 'fas fa-circle' or 'fas fa-circle-notch',
            iconColor   = r.online and '#4ade80' or '#6b7280',
            onSelect    = function() openResult(r) end,
        }
    end

    lib.registerContext({
        id      = 'rz_invcheck_results',
        title   = ('Résultats (%d)'):format(#results),
        options = options,
    })

    lib.showContext('rz_invcheck_results')
end


function OpenInvCheck()
    local input = lib.inputDialog('Vérifier un inventaire', {
        {
            type        = 'input',
            label       = 'ID en jeu ou nom du personnage',
            description = 'Un nombre cherche un joueur connecté par son ID. Du texte cherche par nom, connecté ou non.',
            required    = true,
        },
    })

    if not input or not input[1] or input[1] == '' then return end

    local results = lib.callback.await('rz_invcheck:search', false, input[1])
    showResults(results or {})
end


RegisterCommand('invcheck', function() OpenInvCheck() end, false)


RegisterNUICallback('openPanel', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenInvCheck() end)
end)
