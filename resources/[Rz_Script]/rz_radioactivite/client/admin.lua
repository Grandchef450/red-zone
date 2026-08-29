--[[
    rz_radioactivite / client/admin.lua
    Pilotage de la zone depuis le menu admin (F5).
]]

RegisterNUICallback('openRadiation', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenRadiationMenu() end)
end)


RegisterCommand('radzone', function()
    OpenRadiationMenu()
end, false)


function OpenRadiationMenu()
    local allowed = lib.callback.await('rz_radiation:isAdmin', false)

    if not allowed then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = ('Permission %s requise.'):format(Config.Ace),
        })
    end

    local s = lib.callback.await('rz_radiation:getState', false)
    if not s then return end

    lib.registerContext({
        id    = 'rz_rad_menu',
        title = 'Zone radioactive',
        options = {
            {
                title       = s.active and 'Zone ACTIVE' or 'Zone désactivée',
                description = s.active
                    and ('%d joueur(s) à l\'intérieur en ce moment'):format(s.playersIn)
                    or  'Aucune contamination sur la carte',
                icon        = s.active and 'fas fa-radiation' or 'fas fa-ban',
                iconColor   = s.active and '#f87171' or '#6b7280',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_radiation:setState', false,
                        { active = not s.active })
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    Wait(300)
                    OpenRadiationMenu()
                end,
            },
            {
                title       = ('Rayon : %.0f'):format(s.radius),
                description = 'Repères — 500 contournable · 1000 une ville · 5000 toute la carte',
                icon        = 'fas fa-circle-notch',
                onSelect    = function() EditRadius(s) end,
            },
            {
                title       = ('Vitesse : %.1f u/s'):format(s.speed),
                description = s.moving
                    and '3 = un joueur à pied · 8 = il faut un véhicule'
                    or  'Déplacement arrêté',
                icon        = 'fas fa-gauge-high',
                onSelect    = function() EditSpeed(s) end,
            },
            {
                title       = s.moving and 'Déplacement activé' or 'Zone IMMOBILE',
                description = 'Basculer le déplacement automatique',
                icon        = s.moving and 'fas fa-arrows-turn-right' or 'fas fa-thumbtack',
                iconColor   = s.moving and '#4ade80' or '#fbbf24',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_radiation:setState', false,
                        { moving = not s.moving })
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    Wait(300)
                    OpenRadiationMenu()
                end,
            },
            {
                title       = 'Amener la zone ici',
                description = 'Le nuage se recentre sur ta position',
                icon        = 'fas fa-location-crosshairs',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_radiation:moveHere', false)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
            {
                title       = 'Envoyer la zone ailleurs',
                description = 'Relocalisation au hasard sur la carte',
                icon        = 'fas fa-shuffle',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_radiation:relocate', false)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
            {
                title       = 'S\'y téléporter',
                description = ('Centre actuel : %.0f, %.0f'):format(s.x, s.y),
                icon        = 'fas fa-person-walking-arrow-right',
                onSelect    = function()
                    -- 100 m au-dessus : le sol n'est pas forcément
                    -- chargé à l'arrivée, on laisse tomber dessus.
                    SetEntityCoords(cache.ped, s.x, s.y, 300.0, false, false, false, false)
                    lib.notify({ type = 'inform', description = 'Attention à la chute.' })
                end,
            },
        },
    })

    lib.showContext('rz_rad_menu')
end


function EditRadius(s)
    local input = lib.inputDialog('Rayon de la zone', {
        {
            type = 'number', label = 'Rayon (unités)',
            default = math.floor(s.radius), min = 50, max = 5000,
            description = 'La carte fait environ 8500 × 12000. Au-delà de 3000, il devient impossible de fuir.',
        },
    })

    if not input then return end

    local ok, msg = lib.callback.await('rz_radiation:setState', false, { radius = input[1] })

    lib.notify({ type = ok and 'success' or 'error', description = msg })

    -- Le blip de rayon ne se redimensionne pas : il faut le recréer
    TriggerServerEvent('rz_radiation:requestBlipRebuild')

    Wait(300)
    OpenRadiationMenu()
end


function EditSpeed(s)
    local input = lib.inputDialog('Vitesse de déplacement', {
        {
            type = 'number', label = 'Unités par seconde',
            default = s.speed, min = 0, max = 50, step = 0.5,
            description = '0 immobilise la zone. 3 correspond à un joueur à pied, 8 oblige à prendre un véhicule.',
        },
    })

    if not input then return end

    local ok, msg = lib.callback.await('rz_radiation:setState', false, { speed = input[1] })
    lib.notify({ type = ok and 'success' or 'error', description = msg })

    Wait(300)
    OpenRadiationMenu()
end
