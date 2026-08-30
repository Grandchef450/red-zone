--[[
    rz_airdrop / client/admin.lua
    Onglet « Largages » du menu admin.
]]

RegisterNUICallback('openAirdrop', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenAirdropMenu() end)
end)


RegisterCommand('airdropmenu', function() OpenAirdropMenu() end, false)


RegisterNetEvent('rz_airdrop:unlockAll', function()
    lib.notify({
        type = 'inform',
        title = 'Colis déverrouillés',
        description = 'Les caisses au sol sont ouvrables immédiatement.',
        duration = 8000,
    })
end)


function OpenAirdropMenu()
    local allowed = lib.callback.await('rz_airdrop:isAdmin', false)

    if not allowed then
        return lib.notify({
            type = 'error',
            title = 'Accès refusé',
            description = ('Permission %s requise.'):format(Config.Ace),
        })
    end

    local s = lib.callback.await('rz_airdrop:getState', false)
    if not s then return end

    lib.registerContext({
        id    = 'rz_airdrop_menu',
        title = 'Largages aériens',
        options = {
            {
                title       = s.enabled and 'Largages automatiques activés'
                                        or  'Largages SUSPENDUS',
                description = s.enabled
                    and ('Prochain dans %d minutes'):format(math.ceil(s.nextIn / 60))
                    or  'Aucun largage ne partira tout seul',
                icon        = s.enabled and 'fas fa-toggle-on' or 'fas fa-toggle-off',
                iconColor   = s.enabled and '#4ade80' or '#6b7280',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_airdrop:toggle', false)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    Wait(300)
                    OpenAirdropMenu()
                end,
            },
            {
                title       = 'Lancer un largage',
                description = s.flying and 'Un appareil est déjà en vol'
                                       or  'Quatre caisses, rareté croissante',
                icon        = 'fas fa-parachute-box',
                iconColor   = '#60a5fa',
                disabled    = s.flying,
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_airdrop:forceDrop', false)
                    lib.notify({
                        type = ok and 'success' or 'error',
                        description = msg,
                        duration = 8000,
                    })
                end,
            },
            {
                title       = ('Caisses au sol (%d)'):format(s.crates),
                description = s.protected > 0
                    and ('%d encore verrouillée(s)'):format(s.protected)
                    or  'Toutes ouvrables',
                icon        = 'fas fa-boxes-stacked',
                arrow       = true,
                disabled    = s.crates == 0,
                onSelect    = function() CrateList(s.list) end,
            },
            {
                title       = 'Déverrouiller tout',
                description = 'Lève le délai de cinq minutes sur les caisses au sol',
                icon        = 'fas fa-lock-open',
                iconColor   = '#fbbf24',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_airdrop:unlockAll', false)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
            {
                title       = 'Retirer toutes les caisses',
                description = 'Le butin non ramassé est perdu',
                icon        = 'fas fa-broom',
                iconColor   = '#f87171',
                onSelect    = function()
                    local c = lib.alertDialog({
                        header   = 'Tout retirer ?',
                        content  = ('%d caisse(s) et leur contenu seront supprimées.')
                            :format(s.crates),
                        centered = true, cancel = true,
                    })

                    if c ~= 'confirm' then return end

                    local ok, msg = lib.callback.await('rz_airdrop:clearCrates', false)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
        },
    })

    lib.showContext('rz_airdrop_menu')
end


function CrateList(list)
    local options = {}

    for _, c in ipairs(list or {}) do
        local etat
        if c.locked then
            etat = ('Verrouillée %d:%02d'):format(math.floor(c.lockLeft / 60), c.lockLeft % 60)
        elseif c.opened then
            etat = 'Ouverte'
        else
            etat = 'Ouvrable'
        end

        options[#options + 1] = {
            title       = c.label,
            description = ('%s · %d pile(s) · disparaît dans %d min\n%.0f, %.0f')
                :format(etat, c.piles, math.ceil(c.lifeLeft / 60), c.x, c.y),
            icon        = c.locked and 'fas fa-lock' or 'fas fa-box-open',
            iconColor   = c.locked and '#f87171'
                or c.opened and '#6b7280' or '#4ade80',
            onSelect    = function()
                SetEntityCoords(cache.ped, c.x, c.y, 300.0, false, false, false, false)
                lib.notify({ type = 'inform', description = 'Attention à la chute.' })
            end,
        }
    end

    lib.registerContext({
        id      = 'rz_airdrop_crates',
        title   = ('Caisses (%d)'):format(#(list or {})),
        menu    = 'rz_airdrop_menu',
        options = options,
    })

    lib.showContext('rz_airdrop_crates')
end
