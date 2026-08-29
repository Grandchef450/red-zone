--[[
    rz_mort / client/admin.lua
    Onglet « Mort et sacs » du menu admin.
]]

RegisterNUICallback('openMort', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenMortMenu() end)
end)


RegisterCommand('sacs', function() OpenMortMenu() end, false)


function OpenMortMenu()
    local allowed = lib.callback.await('rz_mort:isAdmin', false)

    if not allowed then
        return lib.notify({
            type = 'error',
            title = 'Accès refusé',
            description = ('Permission %s requise.'):format(Config.Ace),
        })
    end

    local bagList = lib.callback.await('rz_mort:listBags', false) or {}

    lib.registerContext({
        id    = 'rz_mort_menu',
        title = 'Mort et sacs',
        options = {
            {
                title       = ('Sacs au sol (%d)'):format(#bagList),
                description = 'Les localiser, s\'y téléporter, les supprimer',
                icon        = 'fas fa-sack-xmark',
                arrow       = true,
                onSelect    = function() BagList(bagList) end,
            },
            {
                title       = 'Tout nettoyer',
                description = 'Supprime TOUS les sacs et leur contenu',
                icon        = 'fas fa-broom',
                iconColor   = '#f87171',
                onSelect    = function()
                    local c = lib.alertDialog({
                        header   = 'Supprimer tous les sacs ?',
                        content  = ('%d sac(s) et tout leur contenu seront perdus définitivement.')
                            :format(#bagList),
                        centered = true, cancel = true,
                    })

                    if c == 'confirm' then
                        local ok, msg = lib.callback.await('rz_mort:clearBags', false)
                        lib.notify({ type = ok and 'success' or 'error', description = msg })
                    end
                end,
            },
        },
    })

    lib.showContext('rz_mort_menu')
end


function BagList(bagList)
    local options = {}

    for _, b in ipairs(bagList) do
        options[#options + 1] = {
            title       = b.owner or 'Inconnu',
            description = ('%s · déposé il y a %d min\n%.0f, %.0f, %.0f')
                :format(b.locked and ('Verrouillé %d s'):format(b.lockLeft) or 'Libre',
                        b.ageMin, b.x, b.y, b.z),
            icon        = b.locked and 'fas fa-lock' or 'fas fa-lock-open',
            iconColor   = b.locked and '#fbbf24' or '#9ca3af',
            onSelect    = function()
                SetEntityCoords(cache.ped, b.x, b.y, b.z + 1.0, false, false, false, false)
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Aucun sac au sol', disabled = true }
    end

    lib.registerContext({
        id      = 'rz_mort_bags',
        title   = ('Sacs (%d)'):format(#bagList),
        menu    = 'rz_mort_menu',
        options = options,
    })

    lib.showContext('rz_mort_bags')
end
