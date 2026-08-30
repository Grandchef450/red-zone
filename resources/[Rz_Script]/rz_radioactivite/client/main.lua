--[[
    rz_radioactivite / client/main.lua

    Rendu de la zone : voile rouge, assombrissement, blip.

    Ce fichier ne décide RIEN. Il reçoit la position du nuage et
    l'affiche. Les dégâts sont appliqués côté serveur, donc masquer
    l'effet visuel ne protège de rien.
]]

local zone = { active = false, x = 0.0, y = 0.0, radius = 0.0, minZ = -200.0, maxZ = 1500.0 }
local inside, intensity = false, 0.0
local blipArea, blipCentre = nil, nil
local effectOn = false


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_radiation:sync', function(data)
    zone = data

    -- Pendant l'ANNONCE, le nuage n'est pas encore dangereux mais
    -- son blip doit apparaître : c'est ce qui permet de fuir dans
    -- la bonne direction plutôt qu'au hasard.
    local showBlip = zone.active or zone.incoming

    if not showBlip then
        if blipArea then RemoveBlip(blipArea) blipArea = nil end
        if blipCentre then RemoveBlip(blipCentre) blipCentre = nil end
        return
    end

    if Config.Visual.blip.enabled then
        if not blipArea then
            blipArea = AddBlipForRadius(zone.x, zone.y, 0.0, zone.radius)
            SetBlipColour(blipArea, Config.Visual.blip.colour)
            SetBlipAlpha(blipArea, Config.Visual.blip.alpha)
            SetBlipHiddenOnLegend(blipArea, true)

            blipCentre = AddBlipForCoord(zone.x, zone.y, 0.0)
            SetBlipSprite(blipCentre, 76)      -- symbole de danger
            SetBlipColour(blipCentre, Config.Visual.blip.colour)
            SetBlipScale(blipCentre, 0.9)
            SetBlipAsShortRange(blipCentre, false)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(
                zone.incoming and 'Contamination imminente' or 'Zone contaminée')
            EndTextCommandSetBlipName(blipCentre)
        else
            -- Un blip de rayon ne se redimensionne pas : on le
            -- recrée si le rayon a changé, sinon on le déplace.
            SetBlipCoords(blipArea, zone.x, zone.y, 0.0)
            SetBlipCoords(blipCentre, zone.x, zone.y, 0.0)

            -- Clignote tant que le nuage n'est pas là : impossible
            -- de confondre une alerte avec une contamination réelle.
            SetBlipFlashes(blipCentre, zone.incoming == true)
        end
    end
end)


-- Le rayon a changé côté admin : on refait le blip de zone
RegisterNetEvent('rz_radiation:rebuildBlip', function()
    if blipArea then RemoveBlip(blipArea) blipArea = nil end
    if blipCentre then RemoveBlip(blipCentre) blipCentre = nil end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION ET INTENSITÉ
--
--  L'effet ne s'allume pas d'un coup à la frontière : il monte sur
--  les derniers mètres. Sans ce fondu, franchir la limite donnerait
--  un clignotement brutal à chaque pas de côté.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(250)

        -- zone.incoming ne compte pas : le nuage est annoncé mais
        -- n'a pas encore d'effet.
        if not zone.active then
            if inside then
                inside = false
                SetEffect(false)
            end
            goto continue
        end

        do
            local c = GetEntityCoords(cache.ped)
            local dist = #(vec2(c.x, c.y) - vec2(zone.x, zone.y))

            local inVolume = c.z >= zone.minZ and c.z <= zone.maxZ
            local nowInside = inVolume and dist <= zone.radius

            -- Intensité : 0 au bord, 1 à fadeDistance à l'intérieur
            local depth = zone.radius - dist
            local newIntensity = 0.0

            if nowInside then
                newIntensity = math.min(1.0, depth / Config.Visual.fadeDistance)
            end

            if nowInside ~= inside then
                inside = nowInside
                SetEffect(inside)
            end

            if inside and math.abs(newIntensity - intensity) > 0.02 then
                intensity = newIntensity
                SendNUIMessage({ action = 'intensity', value = intensity })
            end
        end

        ::continue::
    end
end)


---Allume ou éteint tout l'habillage.
function SetEffect(on)
    if on == effectOn then return end
    effectOn = on

    if on then
        SetTimecycleModifier(Config.Visual.timecycle)
        SetTimecycleModifierStrength(Config.Visual.timecycleStrength)

        SendNUIMessage({
            action    = 'show',
            darkness  = Config.Visual.darkness,
            redVeil   = Config.Visual.redVeil,
            grain     = Config.Visual.grain,
            intensity = intensity,
        })

        PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    else
        ClearTimecycleModifier()
        SendNUIMessage({ action = 'hide' })
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  RETOURS SERVEUR
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_radiation:tick', function(data)
    -- Léger sursaut visuel à chaque prise de dégâts
    SendNUIMessage({ action = 'pulse' })

    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
end)


RegisterNetEvent('rz_radiation:maskActive', function(data)
    lib.notify({
        type        = 'success',
        title       = data.label,
        description = ('Filtre actif — %d minutes de protection dans la zone.')
            :format(data.minutes),
        duration    = 8000,
    })

    SendNUIMessage({ action = 'mask', on = true })
end)


RegisterNetEvent('rz_radiation:maskExpired', function()
    lib.notify({
        type        = 'error',
        title       = 'Filtre saturé',
        description = 'Tu n\'es plus protégé. Sors de la zone.',
        duration    = 10000,
    })

    SendNUIMessage({ action = 'mask', on = false })
end)


-- ═══════════════════════════════════════════════════════════════════
--  UTILISATION D'UN MASQUE
--
--  ox_inventory déclenche cet événement quand le joueur utilise
--  l'item. Le nom de l'événement suit sa convention.
-- ═══════════════════════════════════════════════════════════════════

for itemName in pairs(Config.Masks) do
    RegisterNetEvent('ox_inventory:usedItem', function(name, slot)
        if not Config.Masks[name] then return end

        local ok, msg = lib.callback.await('rz_radiation:useMask', false, slot)

        if not ok then
            lib.notify({ type = 'error', description = msg })
        end
    end)
    break   -- un seul écouteur suffit, il filtre lui-même
end


-- ═══════════════════════════════════════════════════════════════════
--  COMPTEUR
-- ═══════════════════════════════════════════════════════════════════

RegisterCommand('geiger', function()
    local s = lib.callback.await('rz_radiation:getStatus', false)
    if not s then return end

    if not s.active then
        return lib.notify({ type = 'inform', description = 'Aucune contamination détectée.' })
    end

    local lines = {}

    if s.inside then
        lines[#lines + 1] = '**TU ES DANS LA ZONE CONTAMINÉE**'
    elseif s.distance then
        lines[#lines + 1] = ('Nuage à **%.0f m**'):format(s.distance - s.radius)
    end

    if s.protected then
        lines[#lines + 1] = ('Filtre : %s — %d min restantes')
            :format(s.maskLabel or 'actif', math.ceil(s.maskLeft / 60))
    else
        lines[#lines + 1] = 'Aucun filtre actif'
    end

    lib.alertDialog({
        header   = 'Compteur Geiger',
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end, false)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    ClearTimecycleModifier()
    SendNUIMessage({ action = 'hide' })

    if blipArea then RemoveBlip(blipArea) end
    if blipCentre then RemoveBlip(blipCentre) end
end)
