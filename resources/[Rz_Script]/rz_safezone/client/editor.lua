--[[
    rz_safezone / client/editor.lua

    Éditeur de zone : le joueur marche le long du périmètre et pose
    des points. Le polygone se dessine en direct, avec le volume
    vertical visualisé par des colonnes.
]]

local editing   = false
local points    = {}
local editMinZ  = -50.0
local editMaxZ  = 200.0


local function notify(msg, kind)
    lib.notify({ type = kind or 'inform', description = msg, duration = 3000 })
end


-- ═══════════════════════════════════════════════════════════════════
--  RENDU DU TRACÉ
-- ═══════════════════════════════════════════════════════════════════

local function drawEditor()
    local n = #points

    for i = 1, n do
        local p = points[i]

        -- Marqueur au sol
        DrawMarker(1, p.x, p.y, p.z - 1.0, 0, 0, 0, 0, 0, 0,
                   1.0, 1.0, 0.4, 0, 200, 255, 140, false, false, 2,
                   false, nil, nil, false)

        -- Colonne verticale : matérialise le volume protégé
        DrawLine(p.x, p.y, editMinZ, p.x, p.y, editMaxZ, 0, 200, 255, 120)

        -- Numéro du point
        local onScreen, sx, sy = World3dToScreen2d(p.x, p.y, p.z + 1.0)
        if onScreen then
            SetTextFont(4)
            SetTextScale(0.0, 0.4)
            SetTextColour(255, 255, 255, 220)
            SetTextCentre(true)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentSubstringPlayerName(tostring(i))
            DrawText(sx, sy)
        end

        -- Arête vers le point suivant (le dernier referme le tracé)
        local nxt = points[i + 1] or (n >= 3 and points[1] or nil)
        if nxt then
            DrawLine(p.x, p.y, p.z, nxt.x, nxt.y, nxt.z, 0, 255, 140, 200)
            DrawLine(p.x, p.y, editMaxZ, nxt.x, nxt.y, editMaxZ, 0, 255, 140, 90)
            DrawLine(p.x, p.y, editMinZ, nxt.x, nxt.y, editMinZ, 0, 255, 140, 90)
        end
    end
end


local function updateHelp()
    lib.showTextUI(([[
**Tracé de zone — %d point(s)**
[E] poser un point · [Retour arrière] retirer le dernier
[Page haut/bas] plafond : %.0f m
[Origine/Fin] plancher : %.0f m
[Entrée] enregistrer · [Échap] annuler
    ]]):format(#points, editMaxZ, editMinZ), { position = 'left-center' })
end


-- ═══════════════════════════════════════════════════════════════════
--  BOUCLE D'ÉDITION
-- ═══════════════════════════════════════════════════════════════════

function StartZoneEditor(onFinish)
    if editing then
        return notify('Un tracé est déjà en cours.', 'error')
    end

    editing  = true
    points   = {}
    editMinZ = -50.0
    editMaxZ = 200.0

    updateHelp()
    notify('Marche le long du périmètre et appuie sur E à chaque coin.')

    CreateThread(function()
        while editing do
            drawEditor()

            local coords = GetEntityCoords(cache.ped)

            -- E : poser un point
            if IsControlJustPressed(0, 38) then
                points[#points + 1] = { x = coords.x, y = coords.y, z = coords.z }

                -- Le plancher suit le terrain, avec une marge
                if coords.z - 10.0 < editMinZ or #points == 1 then
                    editMinZ = coords.z - 10.0
                end

                updateHelp()
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Retour arrière : retirer le dernier point
            if IsControlJustPressed(0, 194) and #points > 0 then
                table.remove(points)
                updateHelp()
                PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Plafond
            if IsControlPressed(0, 10) then editMaxZ = editMaxZ + 0.5 updateHelp() end
            if IsControlPressed(0, 11) then editMaxZ = math.max(editMinZ + 5.0, editMaxZ - 0.5) updateHelp() end

            -- Plancher
            if IsControlPressed(0, 213) then editMinZ = math.min(editMaxZ - 5.0, editMinZ + 0.5) updateHelp() end
            if IsControlPressed(0, 214) then editMinZ = editMinZ - 0.5 updateHelp() end

            -- Entrée : valider
            if IsControlJustPressed(0, 191) then
                if #points < 3 then
                    notify('Il faut au moins 3 points pour former une zone.', 'error')
                else
                    editing = false
                    lib.hideTextUI()

                    local result = {
                        points = points,
                        minZ   = editMinZ,
                        maxZ   = editMaxZ,
                    }

                    points = {}
                    onFinish(result)
                    return
                end
            end

            -- Échap : abandonner
            if IsControlJustPressed(0, 200) then
                editing = false
                points  = {}
                lib.hideTextUI()
                notify('Tracé annulé.')
                return
            end

            Wait(0)
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  MENU ADMIN
-- ═══════════════════════════════════════════════════════════════════

RegisterNUICallback('openSafezones', function(_, cb)
    cb({ ok = true })
    CreateThread(function()
        Wait(250)
        OpenSafezoneMenu()
    end)
end)


RegisterCommand('safezones', function()
    OpenSafezoneMenu()
end, false)


function OpenSafezoneMenu()
    local perms = lib.callback.await('rz_safezone:getPermissions', false)

    if not perms or not perms.view then
        return notify('Aucune permission sur les zones sûres.', 'error')
    end

    local zones = lib.callback.await('rz_safezone:admin:getZones', false) or {}

    local options = {}

    if perms.edit then
        options[#options + 1] = {
            title       = 'Tracer une nouvelle zone',
            description = 'Marche le long du périmètre et pose des points',
            icon        = 'fas fa-draw-polygon',
            onSelect    = function() NewZone() end,
        }
    end

    for _, z in ipairs(zones) do
        options[#options + 1] = {
            title       = z.label,
            description = ('%d points · plancher %.0f · plafond %.0f · tampon %.0f m')
                :format(z.pointCount, z.minZ, z.maxZ, z.buffer),
            icon        = 'fas fa-shield-halved',
            arrow       = true,
            onSelect    = function() ZoneActions(z, perms) end,
        }
    end

    lib.registerContext({
        id      = 'rz_sz_menu',
        title   = ('Zones sûres (%d)'):format(#zones),
        options = options,
    })

    lib.showContext('rz_sz_menu')
end


function NewZone()
    local input = lib.inputDialog('Nouvelle zone sûre', {
        { type = 'input', label = 'Identifiant technique', required = true,
          placeholder = 'safezone_sandy',
          description = 'Sans espace ni accent. Sert de lien avec les autres scripts.' },
        { type = 'input', label = 'Nom affiché', required = true,
          placeholder = 'Sandy Shores' },
        { type = 'number', label = 'Zone tampon (mètres)', default = 25, min = 0, max = 200,
          description = 'Anneau extérieur où les dégâts sont aussi annulés. Empêche le camping de sortie.' },
        { type = 'input', label = 'Message d\'entrée', default = 'Vous êtes en zone sûre' },
        { type = 'checkbox', label = 'Vider la zone de zombies', checked = true },
        { type = 'checkbox', label = 'Interdire les véhicules', checked = false },
    })

    if not input then return end

    StartZoneEditor(function(result)
        local ok, msg = lib.callback.await('rz_safezone:admin:createZone', false, {
            zone_key        = input[1],
            label           = input[2],
            buffer_meters   = input[3],
            enter_message   = input[4],
            despawn_zombies = input[5],
            block_vehicles  = input[6],
            points          = result.points,
            min_z           = result.minZ,
            max_z           = result.maxZ,
        })

        if ok then
            lib.notify({
                type = 'success',
                title = 'Zone créée',
                description = ('« %s » — %d points, hauteur %.0f à %.0f')
                    :format(input[2], #result.points, result.minZ, result.maxZ),
                duration = 8000,
            })
        else
            lib.notify({ type = 'error', title = 'Échec', description = msg or 'Erreur.' })
        end
    end)
end


function ZoneActions(z, perms)
    local options = {
        {
            title = 'S\'y téléporter',
            icon = 'fas fa-location-arrow',
            onSelect = function()
                SetEntityCoords(cache.ped, z.centerX, z.centerY, z.maxZ - 50.0,
                                false, false, false, false)
                Wait(500)
                notify('Attention à la chute.')
            end,
        },
    }

    if perms.edit then
        options[#options + 1] = {
            title       = 'Modifier les règles',
            description = 'Tampon, hauteur, messages, restrictions',
            icon        = 'fas fa-sliders',
            onSelect    = function() EditZoneRules(z) end,
        }
        options[#options + 1] = {
            title       = 'Retracer le périmètre',
            description = 'Repart de zéro sur le polygone',
            icon        = 'fas fa-draw-polygon',
            onSelect    = function()
                StartZoneEditor(function(result)
                    lib.callback.await('rz_safezone:admin:updatePoints', false, z.id, {
                        points = result.points,
                        min_z  = result.minZ,
                        max_z  = result.maxZ,
                    })
                    notify('Périmètre mis à jour.', 'success')
                end)
            end,
        }
        options[#options + 1] = {
            title     = 'Supprimer',
            icon      = 'fas fa-trash',
            iconColor = '#f87171',
            onSelect  = function()
                local ok = lib.alertDialog({
                    header   = 'Supprimer cette zone ?',
                    content  = ('« %s » ne protégera plus personne dès validation.')
                        :format(z.label),
                    centered = true, cancel = true,
                })
                if ok == 'confirm' then
                    lib.callback.await('rz_safezone:admin:deleteZone', false, z.id)
                    notify('Zone supprimée.', 'success')
                end
            end,
        }
    end

    lib.registerContext({
        id      = 'rz_sz_actions',
        title   = z.label,
        menu    = 'rz_sz_menu',
        options = options,
    })

    lib.showContext('rz_sz_actions')
end


function EditZoneRules(z)
    local input = lib.inputDialog(('Règles — %s'):format(z.label), {
        { type = 'number', label = 'Zone tampon (mètres)', default = z.buffer, min = 0, max = 200 },
        { type = 'number', label = 'Plafond (Z max)', default = z.maxZ,
          description = 'Doit passer au-dessus des toits pour désarmer les campeurs' },
        { type = 'number', label = 'Plancher (Z min)', default = z.minZ },
        { type = 'input',  label = 'Message d\'entrée', default = z.enterMessage },
        { type = 'checkbox', label = 'Annuler les dégâts',        checked = z.blockDamage },
        { type = 'checkbox', label = 'Désarmer',                  checked = z.blockWeapons },
        { type = 'checkbox', label = 'Bloquer la mêlée',          checked = z.blockMelee },
        { type = 'checkbox', label = 'Détruire les projectiles',  checked = z.blockProjectiles },
        { type = 'checkbox', label = 'Interdire les véhicules',   checked = z.blockVehicles },
        { type = 'checkbox', label = 'Vider de zombies',          checked = z.despawnZombies },
    })

    if not input then return end

    lib.callback.await('rz_safezone:admin:updateRules', false, z.id, {
        buffer_meters     = input[1],
        max_z             = input[2],
        min_z             = input[3],
        enter_message     = input[4],
        block_damage      = input[5],
        block_weapons     = input[6],
        block_melee       = input[7],
        block_projectiles = input[8],
        block_vehicles    = input[9],
        despawn_zombies   = input[10],
    })

    notify('Règles enregistrées.', 'success')
end
