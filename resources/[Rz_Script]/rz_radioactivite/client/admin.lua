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

    local cycle = lib.callback.await('rz_radiation:getCycle', false)

    local etatCycle = ({
        dormante = 'Accalmie',
        annonce  = 'Annonce diffusée',
        active   = 'Nuage actif',
        manuelle = 'Zone posée par le staff',
    })[cycle and cycle.state] or '—'

    lib.registerContext({
        id    = 'rz_rad_menu',
        title = 'Zone radioactive',
        options = {
            {
                title       = ('Cycle : %s'):format(etatCycle),
                description = cycle and cycle.label
                    and ('%s · point %d/%d · bascule dans %d min')
                        :format(cycle.label, cycle.step, cycle.steps,
                                math.ceil(cycle.remaining / 60))
                    or (cycle and ('Prochain nuage dans %d min')
                        :format(math.ceil(cycle.remaining / 60)) or 'Cycle désactivé'),
                icon        = 'fas fa-clock-rotate-left',
                iconColor   = cycle and cycle.state == 'active' and '#f87171'
                    or cycle and cycle.state == 'annonce' and '#fbbf24' or '#4ade80',
                arrow       = true,
                onSelect    = function() CycleMenu(cycle) end,
            },
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
                title       = 'Réglages',
                description = 'Dégâts, masques, cycle, alertes, rendu, volume',
                icon        = 'fas fa-sliders',
                arrow       = true,
                onSelect    = function() SettingsGroups() end,
            },
            {
                title       = 'Joueurs exposés',
                description = 'Qui est dans la zone, et qui est protégé',
                icon        = 'fas fa-users',
                arrow       = true,
                onSelect    = function() ExposedList() end,
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

-- ═══════════════════════════════════════════════════════════════════
--  MENU DU CYCLE
-- ═══════════════════════════════════════════════════════════════════

function CycleMenu(cycle)
    if not cycle then return end

    local options = {
        {
            title       = cycle.cycleEnabled and 'Cycle activé' or 'Cycle DÉSACTIVÉ',
            description = cycle.cycleEnabled
                and 'Accalmies, annonces et itinéraires s\'enchaînent'
                or  'La zone se déplace au hasard, sans accalmie',
            icon        = cycle.cycleEnabled and 'fas fa-toggle-on' or 'fas fa-toggle-off',
            iconColor   = cycle.cycleEnabled and '#4ade80' or '#6b7280',
            onSelect    = function()
                local ok, msg = lib.callback.await('rz_radiation:toggleCycle', false)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                Wait(300)
                OpenRadiationMenu()
            end,
        },
        {
            title       = 'Passer à l\'étape suivante',
            description = 'Sans attendre la fin du compte à rebours',
            icon        = 'fas fa-forward',
            onSelect    = function()
                local ok, msg = lib.callback.await('rz_radiation:skipPhase', false)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                Wait(300)
                OpenRadiationMenu()
            end,
        },
        {
            title       = 'Dissiper le nuage',
            description = 'Retour immédiat en accalmie',
            icon        = 'fas fa-wind',
            iconColor   = '#4ade80',
            onSelect    = function()
                local ok, msg = lib.callback.await('rz_radiation:forceDormant', false)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                Wait(300)
                OpenRadiationMenu()
            end,
        },
    }

    -- ─── LISTE DÉROULANTE DES ITINÉRAIRES ──────────────────────
    -- Une liste déroulante plutôt qu'un bouton par scénario : à cinq
    -- itinéraires le menu tenait encore, à quinze il déborderait.
    options[#options + 1] = {
        title       = 'Lancer un itinéraire',
        description = ('%d itinéraire(s) disponible(s)'):format(#(cycle.scenarios or {})),
        icon        = 'fas fa-route',
        iconColor   = '#60a5fa',
        onSelect    = function() ScenarioPicker(cycle) end,
    }

    options[#options + 1] = {
        title       = 'Créer une zone ici',
        description = ('Centrée sur ta position · rayon maximum %.0f m')
            :format(cycle.maxRadius or 800),
        icon        = 'fas fa-location-crosshairs',
        iconColor   = '#fbbf24',
        onSelect    = function() ManualZoneDialog() end,
    }

    lib.registerContext({
        id      = 'rz_rad_cycle',
        title   = 'Cycle et itinéraires',
        menu    = 'rz_rad_menu',
        options = options,
    })

    lib.showContext('rz_rad_cycle')
end

-- ═══════════════════════════════════════════════════════════════════
--  CHOIX D'UN ITINÉRAIRE
-- ═══════════════════════════════════════════════════════════════════

function ScenarioPicker(cycle)
    local list = {}

    for _, sc in ipairs(cycle.scenarios or {}) do
        list[#list + 1] = {
            value = sc.value,
            label = ('%s%s  —  %d points, rayon %.0f, vitesse %.1f%s')
                :format(sc.value == cycle.scenario and '▶ ' or '',
                        sc.label, sc.steps, sc.radius, sc.speed,
                        sc.loop and ', en boucle' or ''),
        }
    end

    if #list == 0 then
        return lib.notify({
            type = 'error',
            description = 'Aucun itinéraire configuré.',
        })
    end

    local input = lib.inputDialog('Lancer un itinéraire', {
        {
            type = 'select', label = 'Itinéraire', options = list,
            required = true, searchable = true,
            default = cycle.scenario,
            description = 'Chaque itinéraire a son propre rayon et sa propre vitesse.',
        },
    })

    if not input then return end

    local confirm = lib.alertDialog({
        header   = 'Lancer maintenant ?',
        content  = 'L\'annonce part immédiatement sur les pagers.  \nLe nuage apparaît trois minutes plus tard.',
        centered = true, cancel = true,
    })

    if confirm ~= 'confirm' then return end

    local ok, msg = lib.callback.await('rz_radiation:launchScenario', false, input[1])

    lib.notify({
        type        = ok and 'success' or 'error',
        description = msg,
        duration    = 8000,
    })

    Wait(400)
    OpenRadiationMenu()
end


-- ═══════════════════════════════════════════════════════════════════
--  CRÉATION D'UNE ZONE SUR SA POSITION
-- ═══════════════════════════════════════════════════════════════════

function ManualZoneDialog()
    local opt = lib.callback.await('rz_radiation:getManualOptions', false)
    if not opt then return end

    local coords = GetEntityCoords(cache.ped)

    local input = lib.inputDialog('Créer une zone contaminée', {
        {
            type = 'slider', label = 'Rayon (mètres)',
            default = math.min(300, opt.maxRadius),
            min = math.floor(opt.minRadius),
            max = math.floor(opt.maxRadius),
            step = 25,
            description = ('Plafonné à %.0f m, le plus large des itinéraires automatiques. Au-delà, plus personne ne pourrait fuir.')
                :format(opt.maxRadius),
        },
        {
            type = 'select', label = 'Durée', options = opt.durations,
            default = opt.defaultDuration, required = true,
            description = 'Passé ce délai, la zone disparaît et le cycle normal reprend.',
        },
        {
            type = 'number', label = 'Vitesse de déplacement',
            default = opt.defaultSpeed, min = 0, max = 20, step = 0.5,
            description = '0 pour un foyer immobile. Au-dessus, le nuage dérive au hasard.',
        },
        {
            type = 'checkbox', label = 'Annoncer sur les pagers',
            checked = opt.announceDefault,
            description = 'Décoche pour une contamination discrète.',
        },
    })

    if not input then return end

    local confirm = lib.alertDialog({
        header   = 'Confirmer',
        content  = ('Zone de **%d m** centrée sur ta position actuelle.  \n`%.0f, %.0f`  \n\nDurée : %d minutes.')
            :format(input[1], coords.x, coords.y, input[2]),
        centered = true, cancel = true,
    })

    if confirm ~= 'confirm' then return end

    local ok, msg = lib.callback.await('rz_radiation:createManual', false, {
        radius   = input[1],
        minutes  = input[2],
        speed    = input[3],
        announce = input[4],
    })

    lib.notify({
        type        = ok and 'success' or 'error',
        title       = 'Zone contaminée',
        description = msg,
        duration    = 9000,
    })

    Wait(400)
    OpenRadiationMenu()
end

-- ═══════════════════════════════════════════════════════════════════
--  RÉGLAGES
--
--  Groupés par thème : à trente réglages dans une seule liste,
--  plus personne ne trouve celui qu'il cherche.
-- ═══════════════════════════════════════════════════════════════════

function SettingsGroups()
    local groups = lib.callback.await('rz_radiation:getGroups', false) or {}
    local options = {}

    for _, g in ipairs(groups) do
        options[#options + 1] = {
            title       = g.label,
            description = ('%d réglage(s)'):format(g.count),
            icon        = 'fas ' .. (g.icon or 'fa-gear'),
            arrow       = true,
            onSelect    = function() SettingsList(g) end,
        }
    end

    lib.registerContext({
        id      = 'rz_rad_settings',
        title   = 'Réglages',
        menu    = 'rz_rad_menu',
        options = options,
    })

    lib.showContext('rz_rad_settings')
end


function SettingsList(group)
    local list = lib.callback.await('rz_radiation:getSettings', false, group.key) or {}
    local options = {}

    for _, st in ipairs(list) do
        local shown

        if st.type == 'boolean' then
            shown = st.value and 'Activé' or 'Désactivé'
        elseif st.type == 'seconds' then
            shown = ('%d s'):format(st.value or 0)
        else
            shown = tostring(st.value)
        end

        options[#options + 1] = {
            title       = st.label,
            description = ('%s%s'):format(shown, st.note and ('\n' .. st.note) or ''),
            icon        = st.type == 'boolean'
                and (st.value and 'fas fa-toggle-on' or 'fas fa-toggle-off')
                or 'fas fa-pen',
            iconColor   = st.type == 'boolean'
                and (st.value and '#4ade80' or '#6b7280') or nil,
            onSelect    = function() EditSetting(st, group) end,
        }
    end

    options[#options + 1] = {
        title       = 'Réinitialiser ce groupe',
        description = 'Efface les valeurs enregistrées',
        icon        = 'fas fa-rotate-left',
        iconColor   = '#f87171',
        onSelect    = function()
            local c = lib.alertDialog({
                header   = ('Réinitialiser « %s » ?'):format(group.label),
                content  = 'Les valeurs enregistrées seront effacées.  \nIl faudra relancer la ressource pour retrouver celles du fichier.',
                centered = true, cancel = true,
            })

            if c ~= 'confirm' then return end

            local ok, msg = lib.callback.await('rz_radiation:resetGroup', false, group.key)
            lib.notify({ type = ok and 'success' or 'error', description = msg, duration = 8000 })
        end,
    }

    lib.registerContext({
        id      = 'rz_rad_setlist',
        title   = group.label,
        menu    = 'rz_rad_settings',
        options = options,
    })

    lib.showContext('rz_rad_setlist')
end


function EditSetting(st, group)
    -- Un interrupteur bascule directement : ouvrir une boîte de
    -- dialogue pour cocher une case serait un clic de trop.
    if st.type == 'boolean' then
        local ok, msg = lib.callback.await('rz_radiation:setSetting', false,
            st.key, not st.value)

        lib.notify({ type = ok and 'success' or 'error', description = msg })
        Wait(250)
        return SettingsList(group)
    end

    local field

    -- Un curseur quand les bornes sont serrées et le pas entier,
    -- une saisie libre sinon : glisser un curseur au centième est
    -- impossible en pratique.
    if st.step and st.step >= 1 and (st.max - st.min) <= 1000 then
        field = {
            type = 'slider', label = st.label,
            default = math.floor(tonumber(st.value) or st.min),
            min = math.floor(st.min), max = math.floor(st.max),
            step = math.floor(st.step),
            description = st.note,
        }
    else
        field = {
            type = 'number', label = st.label,
            default = tonumber(st.value) or st.min,
            min = st.min, max = st.max, step = st.step,
            description = ('%s%s'):format(
                st.note and (st.note .. '\n') or '',
                ('Entre %s et %s'):format(st.min, st.max)),
        }
    end

    local input = lib.inputDialog(group.label, { field })
    if not input then return end

    local ok, msg = lib.callback.await('rz_radiation:setSetting', false, st.key, input[1])

    lib.notify({
        type        = ok and 'success' or 'error',
        description = msg,
        duration    = 6000,
    })

    Wait(250)
    SettingsList(group)
end


-- ═══════════════════════════════════════════════════════════════════
--  JOUEURS EXPOSÉS
-- ═══════════════════════════════════════════════════════════════════

function ExposedList()
    local list = lib.callback.await('rz_radiation:getExposed', false) or {}

    if #list == 0 then
        return lib.notify({
            type = 'inform',
            description = 'Personne dans la zone en ce moment.',
        })
    end

    local options = {}

    for _, p in ipairs(list) do
        options[#options + 1] = {
            title       = ('[%d] %s'):format(p.id, p.name or '?'),
            description = p.protected and 'Filtre actif' or 'AUCUNE PROTECTION',
            icon        = p.protected and 'fas fa-mask-face' or 'fas fa-skull',
            iconColor   = p.protected and '#4ade80' or '#f87171',
            disabled    = true,
        }
    end

    lib.registerContext({
        id      = 'rz_rad_exposed',
        title   = ('Dans la zone (%d)'):format(#list),
        menu    = 'rz_rad_menu',
        options = options,
    })

    lib.showContext('rz_rad_exposed')
end
