--[[
    rz_safezone / client/main.lua

    Côté joueur : détection de zone, restrictions d'armes, bandeau
    d'entrée, destruction des projectiles.

    Tout ce fichier relève du CONFORT. Un client modifié peut le
    contourner ; c'est le serveur qui protège réellement, en annulant
    les dégâts. Ne jamais compter sur ce code pour la sécurité.
]]

Zones      = {}
CurrentZone = nil       -- clé de la zone où l'on se trouve
InBuffer    = false     -- dans l'anneau tampon plutôt que dans la zone

local blips        = {}
local bannerText   = nil
local bannerUntil  = 0
local projectileHashes = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_safezone]^7', ...) end
end


-- Pré-calcul des hash de projectiles
CreateThread(function()
    for _, name in ipairs(Config.Projectiles) do
        projectileHashes[#projectileHashes + 1] = joaat(name)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  GÉOMÉTRIE (identique au serveur)
-- ═══════════════════════════════════════════════════════════════════

local function pointInPolygon(x, y, points)
    local inside = false
    local n = #points
    local j = n

    for i = 1, n do
        local pi, pj = points[i], points[j]
        if ((pi.y > y) ~= (pj.y > y)) and
           (x < (pj.x - pi.x) * (y - pi.y) / (pj.y - pi.y) + pi.x) then
            inside = not inside
        end
        j = i
    end

    return inside
end


local function distanceToPolygon(x, y, points)
    local best = math.huge
    local n = #points
    local j = n

    for i = 1, n do
        local a, b = points[i], points[j]
        local dx, dy = b.x - a.x, b.y - a.y
        local len2 = dx * dx + dy * dy

        local t = 0.0
        if len2 > 0 then
            t = ((x - a.x) * dx + (y - a.y) * dy) / len2
            t = math.max(0.0, math.min(1.0, t))
        end

        local px, py = a.x + t * dx, a.y + t * dy
        local d = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)

        if d < best then best = d end
        j = i
    end

    return best
end


---Centre approximatif d'une zone, pour le test de distance rapide.
local function zoneCenter(zone)
    if zone._cx then return zone._cx, zone._cy end

    local sx, sy = 0.0, 0.0
    for _, p in ipairs(zone.points) do
        sx, sy = sx + p.x, sy + p.y
    end

    zone._cx = sx / #zone.points
    zone._cy = sy / #zone.points

    return zone._cx, zone._cy
end


-- ═══════════════════════════════════════════════════════════════════
--  BLIPS DE ZONE
-- ═══════════════════════════════════════════════════════════════════

local function clearBlips()
    for _, b in ipairs(blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    blips = {}
end


---Dessine le polygone sur la carte. GTA n'a pas de blip polygonal :
---on approche avec un blip circulaire couvrant l'emprise.
local function createZoneBlips()
    clearBlips()

    for _, zone in ipairs(Zones) do
        if zone.blipEnabled then
            local minX, maxX = math.huge, -math.huge
            local minY, maxY = math.huge, -math.huge

            for _, p in ipairs(zone.points) do
                if p.x < minX then minX = p.x end
                if p.x > maxX then maxX = p.x end
                if p.y < minY then minY = p.y end
                if p.y > maxY then maxY = p.y end
            end

            local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
            local radius = math.max(maxX - minX, maxY - minY) / 2

            local area = AddBlipForRadius(cx, cy, 0.0, radius)
            SetBlipColour(area, zone.blipColor or 2)
            SetBlipAlpha(area, zone.blipAlpha or 128)
            blips[#blips + 1] = area

            local marker = AddBlipForCoord(cx, cy, 0.0)
            SetBlipSprite(marker, 487)
            SetBlipColour(marker, zone.blipColor or 2)
            SetBlipScale(marker, 0.8)
            SetBlipAsShortRange(marker, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(zone.label)
            EndTextCommandSetBlipName(marker)
            blips[#blips + 1] = marker
        end
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  BANDEAU HAUT-CENTRE
-- ═══════════════════════════════════════════════════════════════════

local function showBanner(text, duration)
    bannerText  = text
    bannerUntil = GetGameTimer() + (duration or Config.Display.bannerDuration)
end


local function drawBanner()
    local now = GetGameTimer()
    if not bannerText or now > bannerUntil then return end

    -- Fondu sur la dernière demi-seconde
    local remaining = bannerUntil - now
    local alpha = 255
    if remaining < 500 then
        alpha = math.floor(255 * (remaining / 500))
    end

    local c = InBuffer and Config.Display.colors.buffer
                       or Config.Display.colors.safe

    SetTextFont(4)
    SetTextScale(0.0, 0.62)
    SetTextColour(c[1], c[2], c[3], alpha)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(bannerText)
    DrawText(0.5, 0.055)
end


---Petit indicateur permanent tant qu'on est dans une zone.
local function drawPersistentHud()
    if not Config.Display.persistentHud or not CurrentZone then return end

    local zone = nil
    for _, z in ipairs(Zones) do
        if z.key == CurrentZone then zone = z break end
    end
    if not zone then return end

    local c = InBuffer and Config.Display.colors.buffer
                       or Config.Display.colors.safe

    local label = InBuffer and ('◈ ' .. zone.label .. ' — abords')
                           or ('◆ ' .. zone.label)

    SetTextFont(4)
    SetTextScale(0.0, 0.38)
    SetTextColour(c[1], c[2], c[3], 200)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(label)
    DrawText(0.5, 0.015)
end


CreateThread(function()
    while true do
        if bannerText or CurrentZone then
            drawBanner()
            drawPersistentHud()
            Wait(0)
        else
            Wait(200)
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION DE ZONE
-- ═══════════════════════════════════════════════════════════════════

local function findZone(coords)
    for _, zone in ipairs(Zones) do
        -- Test rapide : trop loin, on n'évalue même pas le polygone
        local cx, cy = zoneCenter(zone)
        local rough = #(vec2(coords.x, coords.y) - vec2(cx, cy))

        if rough < Config.Detection.maxTestDistance then
            if coords.z >= zone.minZ and coords.z <= zone.maxZ then
                if pointInPolygon(coords.x, coords.y, zone.points) then
                    return zone, false
                end

                if zone.buffer > 0 then
                    local d = distanceToPolygon(coords.x, coords.y, zone.points)
                    if d <= zone.buffer then
                        return zone, true
                    end
                end
            end
        end
    end

    return nil, false
end


CreateThread(function()
    while true do
        Wait(Config.Detection.clientInterval)

        if #Zones == 0 then goto continue end

        do
            local coords = GetEntityCoords(cache.ped)
            local zone, inBuffer = findZone(coords)

            local newKey = zone and zone.key or nil

            if newKey ~= CurrentZone or inBuffer ~= InBuffer then
                local wasInside = CurrentZone ~= nil

                CurrentZone = newKey
                InBuffer    = inBuffer

                if zone then
                    if not wasInside then
                        showBanner(inBuffer
                            and ('Abords de ' .. zone.label)
                            or  zone.enterMessage)
                    elseif not inBuffer then
                        showBanner(zone.enterMessage)
                    end

                    TriggerEvent('rz_safezone:entered', zone.key, inBuffer)
                else
                    -- On vient de sortir complètement
                    for _, z in ipairs(Zones) do
                        showBanner(z.exitMessage or 'Vous quittez la zone sûre')
                        break
                    end
                    TriggerEvent('rz_safezone:left')
                end

                dbg(('zone : %s (tampon: %s)'):format(newKey or 'aucune', tostring(inBuffer)))
            end
        end

        ::continue::
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  RESTRICTIONS
--
--  Boucle à chaque frame, mais uniquement quand on est dans une
--  zone. Hors zone, le thread dort et ne coûte rien.
-- ═══════════════════════════════════════════════════════════════════

local function currentZoneData()
    if not CurrentZone then return nil end
    for _, z in ipairs(Zones) do
        if z.key == CurrentZone then return z end
    end
    return nil
end


CreateThread(function()
    while true do
        local zone = currentZoneData()

        if not zone then
            Wait(300)
            goto continue
        end

        do
            local ped = cache.ped

            -- Dans le tampon, on ne désarme pas : le joueur doit
            -- pouvoir se défendre dès qu'il en sort. Seuls les
            -- dégâts sont annulés, côté serveur.
            if not InBuffer then
                if zone.blockWeapons then
                    -- Rengaine et empêche de ressortir une arme
                    SetCurrentPedWeapon(ped, joaat("WEAPON_UNARMED"), true)
                    DisablePlayerFiring(cache.playerId, true)
                    SetPlayerCanDoDriveBy(cache.playerId, false)

                    DisableControlAction(0, 24,  true)  -- attaque
                    DisableControlAction(0, 25,  true)  -- viser
                    DisableControlAction(0, 47,  true)  -- arme
                    DisableControlAction(0, 58,  true)  -- arme
                    DisableControlAction(0, 140, true)  -- mêlée légère
                    DisableControlAction(0, 141, true)  -- mêlée lourde
                    DisableControlAction(0, 142, true)  -- mêlée alternative
                    DisableControlAction(0, 257, true)  -- attaque 2
                    DisableControlAction(0, 263, true)  -- mêlée 1
                    DisableControlAction(0, 264, true)  -- mêlée 2
                    DisableControlAction(0, 45,  true)  -- recharger
                    DisableControlAction(0, 37,  true)  -- roue des armes
                end

                if zone.blockMelee then
                    SetPedCanPlayAmbientAnims(ped, true)
                    DisableControlAction(0, 140, true)
                    DisableControlAction(0, 141, true)
                    DisableControlAction(0, 142, true)
                end

                -- Le joueur ne peut pas être renversé
                if zone.blockRunover then
                    SetPedCanBeKnockedOffVehicle(ped, 1)
                    SetEntityProofs(ped, false, false, false, true, false, false, false, false)
                end
            end

            -- Protection locale : le serveur annule déjà les dégâts,
            -- mais ceci évite le clignotement de santé chez la victime.
            SetEntityCanBeDamaged(ped, false)
            SetPlayerInvincible(cache.playerId, true)
            NetworkSetFriendlyFireOption(false)
            SetCanAttackFriendly(ped, false, false)

            Wait(0)
        end

        ::continue::
    end
end)


---Rétablit l'état normal à la sortie.
AddEventHandler('rz_safezone:left', function()
    local ped = cache.ped

    SetEntityCanBeDamaged(ped, true)
    SetPlayerInvincible(cache.playerId, false)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    DisablePlayerFiring(cache.playerId, false)
    SetPlayerCanDoDriveBy(cache.playerId, true)
    NetworkSetFriendlyFireOption(true)
end)


-- ═══════════════════════════════════════════════════════════════════
--  PROJECTILES
--
--  Une grenade lancée depuis l'extérieur est détruite à l'entrée.
--  Le serveur annule déjà l'explosion, mais la supprimer évite
--  l'effet visuel et sonore, qui suffirait à gâcher la scène.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local zone = currentZoneData()

        if zone and zone.blockProjectiles and not InBuffer then
            for _, hash in ipairs(projectileHashes) do
                RemoveAllProjectilesOfTypeOwnedBy(hash, false)
            end
            Wait(100)
        else
            Wait(500)
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  RETOURS SERVEUR
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_safezone:sync', function(zones)
    Zones = zones or {}

    -- Réinitialise les centres mis en cache
    for _, z in ipairs(Zones) do
        z._cx, z._cy = nil, nil
    end

    createZoneBlips()
    dbg(('%d zone(s) reçue(s)'):format(#Zones))
end)


RegisterNetEvent('rz_safezone:damageBlocked', function()
    -- Un tir a été annulé sur nous : retour discret, sans spammer
    lib.notify({
        id          = 'rz_sz_blocked',
        type        = 'inform',
        title       = 'Zone sûre',
        description = 'Un tir venu de l\'extérieur a été bloqué.',
        duration    = 3000,
    })
end)


AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1500)
    TriggerServerEvent('rz_safezone:requestSync')
end)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    clearBlips()

    local ped = cache.ped
    SetEntityCanBeDamaged(ped, true)
    SetPlayerInvincible(cache.playerId, false)
    DisablePlayerFiring(cache.playerId, false)
end)


-- ═══════════════════════════════════════════════════════════════════
--  EXPORTS pour les autres ressources
-- ═══════════════════════════════════════════════════════════════════

exports('IsInSafezone', function() return CurrentZone ~= nil and not InBuffer end)
exports('IsInBuffer',   function() return InBuffer end)
exports('GetCurrentZone', function() return CurrentZone end)
