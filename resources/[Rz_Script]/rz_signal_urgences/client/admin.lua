--[[
    rz_signal_urgences / client/admin.lua
    Onglet « Annonces pager » du menu admin.
]]

RegisterNUICallback('openSignal', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenSignalMenu() end)
end)


RegisterCommand('pagerstaff', function()
    OpenSignalMenu()
end, false)


function OpenSignalMenu()
    local perms = lib.callback.await('rz_signal:getPermissions', false)

    if not perms or (not perms.announce and not perms.network) then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = 'Aucune permission sur les signaux d\'urgence.',
        })
    end

    local options = {}

    if perms.announce then
        options[#options + 1] = {
            title       = 'Annonce officielle',
            description = 'Traverse les coupures réseau et atteint tous les pagers',
            icon        = 'fas fa-bullhorn',
            iconColor   = '#60a5fa',
            onSelect    = function() AnnounceDialog() end,
        }
    end

    if perms.network then
        options[#options + 1] = {
            title       = 'État du réseau',
            description = 'Couper ou rétablir le courant et les relais par zone',
            icon        = 'fas fa-tower-broadcast',
            arrow       = true,
            onSelect    = function() NetworkMenu() end,
        }
        options[#options + 1] = {
            title       = 'Coupure générale',
            description = 'Plonger toute la carte dans le noir, ou tout rétablir',
            icon        = 'fas fa-power-off',
            iconColor   = '#f87171',
            arrow       = true,
            onSelect    = function() BlackoutAllMenu() end,
        }
    end

    if perms.announce then
        options[#options + 1] = {
            title       = 'Historique des signaux',
            description = 'Les 30 derniers, avec leur nombre de destinataires',
            icon        = 'fas fa-clock-rotate-left',
            arrow       = true,
            onSelect    = function() HistoryMenu() end,
        }
    end

    lib.registerContext({
        id      = 'rz_signal_menu',
        title   = 'Signaux d\'urgence',
        options = options,
    })

    lib.showContext('rz_signal_menu')
end


-- ═══════════════════════════════════════════════════════════════════
--  ANNONCE
-- ═══════════════════════════════════════════════════════════════════

function AnnounceDialog()
    local zones = lib.callback.await('rz_signal:getZones', false) or {}

    local zoneOptions = { { value = '', label = 'Toute la carte' } }
    for _, z in ipairs(zones) do
        zoneOptions[#zoneOptions + 1] = {
            value = z.key,
            label = ('%s%s'):format(z.label, z.powered and '' or '  (réseau coupé)'),
        }
    end

    local input = lib.inputDialog('Annonce officielle', {
        {
            type = 'textarea', label = 'Message', required = true,
            placeholder = 'Redémarrage du serveur dans 15 minutes',
            description = 'Affiché en majuscules sur les pagers. 200 caractères maximum.',
            max = 200,
        },
        {
            type = 'input', label = 'Signature', default = 'STAFF REDZONE',
            description = 'Affichée sous le message.',
        },
        {
            type = 'select', label = 'Destinataires', options = zoneOptions, default = '',
            description = 'Une annonce officielle passe même dans les zones sans réseau.',
        },
    })

    if not input then return end

    local ok, msg = lib.callback.await('rz_signal:announce', false,
        input[1], input[2], input[3])

    lib.notify({
        type        = ok and 'success' or 'error',
        title       = 'Annonce pager',
        description = msg,
        duration    = 7000,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  RÉSEAU
-- ═══════════════════════════════════════════════════════════════════

function NetworkMenu()
    local zones = lib.callback.await('rz_signal:getZones', false) or {}
    local options = {}

    for _, z in ipairs(zones) do
        options[#options + 1] = {
            title       = ('%s %s'):format(z.powered and '🟢' or '🔴', z.label),
            description = z.powered
                and 'Alimentée — cliquer pour couper le courant et les relais'
                or  'Coupée — cliquer pour rétablir',
            icon        = z.powered and 'fas fa-plug' or 'fas fa-plug-circle-xmark',
            iconColor   = z.powered and '#4ade80' or '#f87171',
            onSelect    = function()
                local ok, msg = lib.callback.await('rz_signal:setNetwork', false,
                    z.key, not z.powered)

                lib.notify({
                    type = ok and 'success' or 'error',
                    description = msg,
                    duration = 6000,
                })

                Wait(400)
                NetworkMenu()
            end,
        }
    end

    lib.registerContext({
        id      = 'rz_signal_network',
        title   = 'Réseau par zone',
        menu    = 'rz_signal_menu',
        options = options,
    })

    lib.showContext('rz_signal_network')
end


function BlackoutAllMenu()
    lib.registerContext({
        id    = 'rz_signal_all',
        title = 'Coupure générale',
        menu  = 'rz_signal_menu',
        options = {
            {
                title       = 'Tout couper',
                description = 'Toutes les zones perdent courant et réseau, une par une',
                icon        = 'fas fa-power-off',
                iconColor   = '#f87171',
                onSelect    = function()
                    local confirm = lib.alertDialog({
                        header   = 'Plonger la carte dans le noir ?',
                        content  = 'Toutes les zones seront coupées avec quelques secondes d\'écart.  \nLes joueurs perdront la réception de leur pager, sauf pour les annonces officielles.',
                        centered = true, cancel = true,
                    })

                    if confirm == 'confirm' then
                        local ok, msg = lib.callback.await('rz_signal:blackoutAll', false, false)
                        lib.notify({ type = ok and 'success' or 'error', description = msg })
                    end
                end,
            },
            {
                title       = 'Tout rétablir',
                description = 'Le courant et les relais reviennent partout',
                icon        = 'fas fa-bolt',
                iconColor   = '#4ade80',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_signal:blackoutAll', false, true)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
        },
    })

    lib.showContext('rz_signal_all')
end


-- ═══════════════════════════════════════════════════════════════════
--  HISTORIQUE
-- ═══════════════════════════════════════════════════════════════════

function HistoryMenu()
    local rows = lib.callback.await('rz_signal:getHistory', false) or {}

    if #rows == 0 then
        return lib.notify({
            type = 'inform',
            description = 'Aucun signal diffusé pour le moment.',
        })
    end

    local options = {}

    for _, r in ipairs(rows) do
        options[#options + 1] = {
            title       = r.message,
            description = ('%s · %s · %d destinataire(s)\n%s')
                :format(r.priority:upper(),
                        r.sender or 'AUTOMATIQUE',
                        r.recipients or 0,
                        tostring(r.created_at):sub(1, 16)),
            icon        = r.priority == 'staff' and 'fas fa-bullhorn'
                       or r.priority == 'critique' and 'fas fa-triangle-exclamation'
                       or 'fas fa-tower-broadcast',
            disabled    = true,
        }
    end

    lib.registerContext({
        id      = 'rz_signal_history',
        title   = ('Historique (%d)'):format(#rows),
        menu    = 'rz_signal_menu',
        options = options,
    })

    lib.showContext('rz_signal_history')
end
