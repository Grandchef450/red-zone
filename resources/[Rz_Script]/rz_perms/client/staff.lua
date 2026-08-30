--[[
    rz_perms / client/staff.lua
    Menu de gestion des grades, ouvert depuis le F5.
]]

RegisterNUICallback('openStaff', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenStaffMenu() end)
end)


RegisterCommand('staff', function() OpenStaffMenu() end, false)


function OpenStaffMenu()
    local allowed = lib.callback.await('rz_perms:canManage', false)

    if not allowed then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = 'Seuls les développeurs gèrent les grades.',
        })
    end

    local staff = lib.callback.await('rz_perms:getStaff', false) or {}

    local options = {
        {
            title       = 'Accorder un grade',
            description = 'À un joueur connecté, sans saisir sa licence',
            icon        = 'fas fa-user-plus',
            iconColor   = '#4ade80',
            onSelect    = function() GrantDialog() end,
        },
    }

    for _, s in ipairs(staff) do
        options[#options + 1] = {
            title       = ('%s%s'):format(s.online and '🟢 ' or '', s.name or 'Inconnu'),
            description = ('%s%s\n`%s`'):format(
                s.gradeLabel,
                s.note and (' — ' .. s.note) or '',
                s.license),
            icon        = 'fas fa-user-shield',
            arrow       = true,
            onSelect    = function() StaffActions(s) end,
        }
    end

    lib.registerContext({
        id      = 'rz_staff_menu',
        title   = ('Équipe (%d)'):format(#staff),
        options = options,
    })

    lib.showContext('rz_staff_menu')
end


function GrantDialog()
    local players = lib.callback.await('rz_perms:getOnline', false) or {}
    local grades  = lib.callback.await('rz_perms:getGrades', false) or {}

    if #players == 0 then
        return lib.notify({ type = 'error', description = 'Aucun joueur connecté.' })
    end

    local input = lib.inputDialog('Accorder un grade', {
        {
            type = 'select', label = 'Joueur', options = players,
            required = true, searchable = true,
            description = 'Seuls les joueurs connectés apparaissent. Pour quelqu\'un d\'absent, passe par la base.',
        },
        { type = 'select', label = 'Grade', options = grades, required = true },
        {
            type = 'input', label = 'Note', max = 200,
            description = 'Pourquoi ? Utile dans six mois quand personne ne s\'en souviendra.',
        },
    })

    if not input then return end

    -- On retrouve le pseudo à partir de la licence choisie
    local name
    for _, p in ipairs(players) do
        if p.value == input[1] then name = p.name break end
    end

    local confirm = lib.alertDialog({
        header   = 'Confirmer',
        content  = ('**%s** deviendra **%s**.  \n\nLe changement est immédiat et tracé en base.')
            :format(name or '?', input[2]),
        centered = true, cancel = true,
    })

    if confirm ~= 'confirm' then return end

    local ok, msg = lib.callback.await('rz_perms:setGrade', false,
        input[1], name, input[2], input[3])

    lib.notify({
        type        = ok and 'success' or 'error',
        description = msg,
        duration    = 8000,
    })

    if ok then Wait(400) OpenStaffMenu() end
end


function StaffActions(s)
    local grades = lib.callback.await('rz_perms:getGrades', false) or {}

    lib.registerContext({
        id    = 'rz_staff_actions',
        title = s.name or 'Inconnu',
        menu  = 'rz_staff_menu',
        options = {
            {
                title       = 'Changer de grade',
                description = ('Actuellement : %s'):format(s.gradeLabel),
                icon        = 'fas fa-arrows-up-down',
                onSelect    = function()
                    local input = lib.inputDialog(s.name or 'Membre', {
                        { type = 'select', label = 'Nouveau grade',
                          options = grades, default = s.grade, required = true },
                        { type = 'input', label = 'Note', default = s.note, max = 200 },
                    })

                    if not input then return end

                    local ok, msg = lib.callback.await('rz_perms:setGrade', false,
                        s.license, s.name, input[1], input[2])

                    lib.notify({
                        type = ok and 'success' or 'error',
                        description = msg,
                        duration = 8000,
                    })

                    if ok then Wait(400) OpenStaffMenu() end
                end,
            },
            {
                title     = 'Retirer le grade',
                icon      = 'fas fa-user-minus',
                iconColor = '#f87171',
                onSelect  = function()
                    local c = lib.alertDialog({
                        header   = 'Retirer le grade ?',
                        content  = ('**%s** perdra tous ses accès staff, immédiatement s\'il est connecté.')
                            :format(s.name or s.license),
                        centered = true, cancel = true,
                    })

                    if c ~= 'confirm' then return end

                    local ok, msg = lib.callback.await('rz_perms:removeGrade', false, s.license)

                    lib.notify({
                        type = ok and 'success' or 'error',
                        description = msg,
                        duration = 8000,
                    })

                    if ok then Wait(400) OpenStaffMenu() end
                end,
            },
        },
    })

    lib.showContext('rz_staff_actions')
end
