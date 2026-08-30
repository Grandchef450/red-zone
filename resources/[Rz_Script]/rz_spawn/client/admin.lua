--[[
    rz_spawn / client/admin.lua
    Onglet « Sauvetage » du menu admin.
]]

RegisterNUICallback('openSpawn', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenSpawnMenu() end)
end)


RegisterCommand('sauvetage', function() OpenSpawnMenu() end, false)


function OpenSpawnMenu()
    local allowed = lib.callback.await('rz_spawn:isAdmin', false)

    if not allowed then
        return lib.notify({
            type = 'error',
            title = 'Accès refusé',
            description = ('Permission %s requise.'):format(Config.Ace),
        })
    end

    local players = lib.callback.await('rz_spawn:getPlayers', false) or {}
    local zones = lib.callback.await('rz_spawn:getCrashZones', false) or {}

    local nz = 0
    for _ in pairs(zones) do nz = nz + 1 end

    local suspects = 0
    for _, p in ipairs(players) do
        if p.suspect then suspects = suspects + 1 end
    end

    lib.registerContext({
        id    = 'rz_spawn_menu',
        title = 'Sauvetage',
        options = {
            {
                title       = ('Joueurs (%d)'):format(#players),
                description = suspects > 0
                    and ('⚠ %d semble(nt) bloqué(s)'):format(suspects)
                    or  'Aucun problème détecté',
                icon        = 'fas fa-users',
                iconColor   = suspects > 0 and '#f87171' or nil,
                arrow       = true,
                onSelect    = function() PlayerList(players) end,
            },
            {
                title       = ('Zones à plantage (%d)'):format(nz),
                description = 'Endroits qui font crasher le jeu',
                icon        = 'fas fa-triangle-exclamation',
                iconColor   = '#fbbf24',
                arrow       = true,
                onSelect    = function() CrashZoneMenu(zones) end,
            },
        },
    })

    lib.showContext('rz_spawn_menu')
end


function PlayerList(players)
    local options = {}

    for _, p in ipairs(players) do
        local etat

        if p.underMap then
            etat = '⚠ SOUS LA CARTE'
        elseif p.atOrigin then
            etat = '⚠ JAMAIS APPARU'
        elseif p.inCrash then
            etat = ('⚠ dans « %s »'):format(p.inCrash)
        else
            etat = 'Normal'
        end

        options[#options + 1] = {
            title       = ('[%d] %s'):format(p.id, p.name or '?'),
            description = ('%s\n%.0f, %.0f, %.0f'):format(etat, p.x, p.y, p.z),
            icon        = p.suspect and 'fas fa-person-falling' or 'fas fa-user',
            iconColor   = p.suspect and '#f87171' or nil,
            arrow       = true,
            onSelect    = function() PlayerActions(p) end,
        }
    end

    lib.registerContext({
        id      = 'rz_spawn_players',
        title   = ('Joueurs (%d)'):format(#players),
        menu    = 'rz_spawn_menu',
        options = options,
    })

    lib.showContext('rz_spawn_players')
end


function PlayerActions(p)
    lib.registerContext({
        id    = 'rz_spawn_actions',
        title = p.name or '?',
        menu  = 'rz_spawn_players',
        options = {
            {
                title       = 'Le renvoyer au point d\'apparition',
                description = 'La solution la plus sûre pour un joueur sous la carte',
                icon        = 'fas fa-house',
                iconColor   = '#4ade80',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_spawn:rescuePlayer', false, p.id)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
            {
                title       = 'L\'amener près de moi',
                description = 'Pour lui parler avant de le replacer',
                icon        = 'fas fa-person-arrow-down-to-line',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_spawn:bringPlayer', false, p.id)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
            {
                title       = 'Me téléporter sur lui',
                description = 'Pour constater le problème sur place',
                icon        = 'fas fa-person-walking-arrow-right',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_spawn:goToPlayer', false, p.id)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                end,
            },
        },
    })

    lib.showContext('rz_spawn_actions')
end


-- ═══════════════════════════════════════════════════════════════════
--  ZONES À PLANTAGE
-- ═══════════════════════════════════════════════════════════════════

function CrashZoneMenu(zones)
    local options = {
        {
            title       = 'Marquer cet endroit',
            description = 'Centré sur ta position actuelle',
            icon        = 'fas fa-map-pin',
            iconColor   = '#f87171',
            onSelect    = function() AddCrashZone() end,
        },
    }

    for id, z in pairs(zones) do
        options[#options + 1] = {
            title       = z.label or 'Sans nom',
            description = ('Rayon %.0f m\n%.0f, %.0f, %.0f%s')
                :format(z.radius, z.x, z.y, z.z,
                        z.note and ('\n' .. z.note) or ''),
            icon        = 'fas fa-radiation',
            iconColor   = '#fbbf24',
            arrow       = true,
            onSelect    = function() CrashZoneActions(z) end,
        }
    end

    lib.registerContext({
        id      = 'rz_spawn_crash',
        title   = 'Zones à plantage',
        menu    = 'rz_spawn_menu',
        options = options,
    })

    lib.showContext('rz_spawn_crash')
end


function AddCrashZone()
    local c = GetEntityCoords(cache.ped)

    local input = lib.inputDialog('Marquer une zone instable', {
        {
            type = 'input', label = 'Nom', required = true, max = 64,
            description = 'Affiché aux joueurs qui s\'en approchent.',
        },
        {
            type = 'slider', label = 'Rayon (mètres)',
            default = 50, min = 10, max = 500, step = 10,
            description = 'Assez large pour couvrir tout le décor défectueux.',
        },
        {
            type = 'textarea', label = 'Note interne', max = 255,
            description = 'Ce qui plante exactement. Utile dans six mois.',
        },
    })

    if not input then return end

    local confirm = lib.alertDialog({
        header   = 'Confirmer',
        content  = ('Zone de **%d m** centrée sur ta position.  \n`%.0f, %.0f, %.0f`  \n\nPlus personne ne pourra y entrer, et aucune apparition n\'y sera placée.')
            :format(input[2], c.x, c.y, c.z),
        centered = true, cancel = true,
    })

    if confirm ~= 'confirm' then return end

    local ok, msg = lib.callback.await('rz_spawn:addCrashZone', false, {
        label = input[1], radius = input[2], note = input[3],
    })

    lib.notify({
        type = ok and 'success' or 'error',
        description = msg,
        duration = 8000,
    })

    if ok then Wait(400) OpenSpawnMenu() end
end


function CrashZoneActions(z)
    lib.registerContext({
        id    = 'rz_spawn_crashact',
        title = z.label or 'Zone',
        menu  = 'rz_spawn_crash',
        options = {
            {
                title       = 'S\'y téléporter',
                description = '⚠ Cette zone fait planter le jeu',
                icon        = 'fas fa-location-crosshairs',
                iconColor   = '#f87171',
                onSelect    = function()
                    local c = lib.alertDialog({
                        header   = 'Vraiment ?',
                        content  = 'Cette zone est marquée comme faisant planter le jeu.  \nTu risques de te faire éjecter.',
                        centered = true, cancel = true,
                    })

                    if c == 'confirm' then
                        SetEntityCoords(cache.ped, z.x, z.y, z.z + 2.0,
                            false, false, false, false)
                    end
                end,
            },
            {
                title       = 'Retirer cette zone',
                description = 'Si le problème a été corrigé',
                icon        = 'fas fa-trash',
                iconColor   = '#4ade80',
                onSelect    = function()
                    local ok, msg = lib.callback.await('rz_spawn:removeCrashZone', false, z.id)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    if ok then Wait(400) OpenSpawnMenu() end
                end,
            },
        },
    })

    lib.showContext('rz_spawn_crashact')
end
