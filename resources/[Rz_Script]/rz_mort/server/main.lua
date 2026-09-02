--[[
    rz_mort / server/main.lua

    Agonie, sac mortuaire, réapparition.

    LE SERVEUR DÉCIDE DE TOUT. Le client signale qu'il est tombé,
    mais c'est ici qu'on tient le chronomètre, qu'on vide
    l'inventaire et qu'on décide où le joueur revient. Un client
    modifié peut masquer l'écran d'agonie, il ne peut pas se
    relever tout seul ni empêcher son sac de tomber.
]]

-- [source] = { since, deadline }
local downed = {}

-- [bagId] = { owner, ownerName, x, y, z, createdAt, lockUntil }
Bags = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_mort]^7', ...) end
end


local function citizenIdOf(source)
    local p = exports.qbx_core:GetPlayer(source)
    return p and p.PlayerData and p.PlayerData.citizenid or nil
end


local function nameOf(source)
    local p = exports.qbx_core:GetPlayer(source)
    if not p then return GetPlayerName(source) or 'Inconnu' end

    local c = p.PlayerData.charinfo
    if c then
        return (('%s %s'):format(c.firstname or '', c.lastname or '')):gsub('^%s+', '')
    end

    return GetPlayerName(source) or 'Inconnu'
end


---Envoie vers le salon Discord « mort ». N'importe pas si rz_logs
---est absent ou en redémarrage : la mort est déjà en base, Discord
---n'est qu'une alerte en plus.
local function logDiscord(title, description, fields)
    if GetResourceState('rz_logs') ~= 'started' then return end

    pcall(function()
        exports.rz_logs:Log('mort', {
            title       = title,
            description = description,
            fields      = fields,
        })
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  SAFE ZONES
-- ═══════════════════════════════════════════════════════════════════

---Le joueur est-il dans une zone sûre ?
local function inSafezone(source)
    if GetResourceState('rz_safezone') ~= 'started' then return false end

    local ok, result = pcall(function()
        return exports.rz_safezone:GetPlayerZone(source)
    end)

    return ok and result ~= nil
end


---Point de réapparition le plus proche d'une position.
local function nearestRespawn(coords)
    local best, bestDist = nil, math.huge

    -- On préfère les vraies safe zones : leur centre est calculé
    -- depuis le polygone tracé en jeu, donc toujours à jour.
    if GetResourceState('rz_safezone') == 'started' then
        local ok, zones = pcall(function()
            return exports.rz_safezone:GetZones()
        end)

        if ok and type(zones) == 'table' then
            for _, z in pairs(zones) do
                if type(z.points) == 'table' and #z.points > 0 then
                    local sx, sy = 0.0, 0.0
                    for _, p in ipairs(z.points) do sx, sy = sx + p.x, sy + p.y end

                    local c = vec3(sx / #z.points, sy / #z.points,
                                   (z.min_z + z.max_z) / 2)
                    local d = #(vec2(coords.x, coords.y) - vec2(c.x, c.y))

                    if d < bestDist then
                        bestDist = d
                        -- On vise le niveau du sol plutôt que le milieu
                        -- du volume, qui serait en plein ciel.
                        best = vec3(c.x, c.y, z.min_z + 12.0)
                    end
                end
            end
        end
    end

    if best then return best end

    -- Filet de sécurité si rz_safezone est absent
    for _, p in ipairs(Config.Respawn.fallback) do
        local d = #(vec2(coords.x, coords.y) - vec2(p.x, p.y))
        if d < bestDist then bestDist, best = d, p end
    end

    return best or Config.Respawn.fallback[1]
end


-- ═══════════════════════════════════════════════════════════════════
--  AGONIE
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_mort:downed', function()
    local src = source
    if downed[src] then return end

    local now = os.time()

    downed[src] = {
        since    = now,
        deadline = now + Config.Agonie.seconds,
    }

    -- Le statebag est répliqué : les autres clients s'en servent
    -- pour savoir qui peut être relevé, sans requête serveur.
    Player(src).state:set('rzDowned', true, true)

    pcall(function()
        exports.qbx_core:SetMetadata(src, 'inlaststand', true)
    end)

    TriggerClientEvent('rz_mort:startDowned', src, {
        seconds     = Config.Agonie.seconds,
        allowGiveUp = Config.Agonie.allowGiveUp,
        giveUpAfter = Config.Agonie.giveUpAfter,
        health      = Config.Agonie.health,
    })

    dbg(('%s est à terre'):format(nameOf(src)))
end)


---Sort le joueur de l'agonie, dans un sens ou dans l'autre.
local function clearDowned(source)
    downed[source] = nil

    if GetPlayerName(source) then
        Player(source).state:set('rzDowned', false, true)

        pcall(function()
            exports.qbx_core:SetMetadata(source, 'inlaststand', false)
        end)
    end
end


-- Chronomètre : une seule boucle pour tous les agonisants
CreateThread(function()
    while true do
        Wait(1000)

        local now = os.time()

        for src, d in pairs(downed) do
            if not GetPlayerName(src) then
                downed[src] = nil
            elseif now >= d.deadline then
                FinalDeath(src)
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  RÉANIMATION
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_mort:revive', function(source, targetId)
    targetId = tonumber(targetId)

    if not targetId or not downed[targetId] then
        return false, 'Cette personne n\'a pas besoin d\'aide.'
    end

    if targetId == source then
        return false, 'Tu ne peux pas te relever toi-même.'
    end

    local ped, targetPed = GetPlayerPed(source), GetPlayerPed(targetId)
    if not ped or not targetPed or ped == 0 or targetPed == 0 then
        return false, 'Cible introuvable.'
    end

    local dist = #(GetEntityCoords(ped) - GetEntityCoords(targetPed))
    if dist > (Config.Revive.distance + 1.5) then
        return false, 'Trop loin.'
    end

    -- Un seul item relève : l'épipen. Les bandages et trousses
    -- servent à se soigner APRÈS, pas à ramener quelqu'un.
    if exports.ox_inventory:GetItemCount(source, Config.Revive.item) < 1 then
        return false, 'Il te faut un épipen.'
    end

    return true, {
        item     = Config.Revive.item,
        duration = Config.Revive.duration,
    }
end)


---Confirmé par le client une fois la barre de progression terminée.
lib.callback.register('rz_mort:confirmRevive', function(source, targetId, itemName)
    targetId = tonumber(targetId)

    if not targetId or not downed[targetId] then
        return false, 'Trop tard.'
    end

    -- On revérifie l'item : entre le lancement et la fin de la barre,
    -- le joueur a pu le donner ou le jeter.
    if not exports.ox_inventory:RemoveItem(source, Config.Revive.item, 1) then
        return false, 'Épipen introuvable.'
    end

    -- 10 % du maximum. Le relevé tient debout, mais un coup suffit
    -- à le remettre à terre : il devra se soigner par lui-même.
    local health = math.max(
        Config.Revive.healthFloor,
        math.floor(200 * (Config.Revive.healthPercent / 100))
    )

    -- On sort de l'agonie tout de suite côté logique : le minuteur
    -- de mort définitive doit cesser dès l'injection, même si le
    -- joueur met encore 30 secondes à se redresser.
    clearDowned(targetId)

    TriggerClientEvent('rz_mort:revived', targetId, {
        health   = health,
        standUp  = Config.Revive.standUpSeconds,
        groggy   = Config.Revive.groggySeconds,
        byName   = nameOf(source),
    })

    -- Le secouriste est prévenu au moment où son ami se relève
    -- vraiment, pas à la fin de sa propre barre de progression.
    SetTimeout(Config.Revive.standUpSeconds * 1000, function()
        if GetPlayerName(source) then
            TriggerClientEvent('ox_lib:notify', source, {
                type        = 'success',
                title       = 'Il est debout',
                description = ('%s a repris ses esprits.'):format(nameOf(targetId)),
                duration    = 6000,
            })
        end
    end)

    MySQL.prepare([[
        INSERT INTO rz_mort_logs (citizenid, action, detail)
        VALUES (?, 'revive', ?)
    ]], { citizenIdOf(targetId), json.encode({ by = citizenIdOf(source), item = Config.Revive.item }) })

    logDiscord('Réanimation', ('**%s** relevé par **%s**.'):format(nameOf(targetId), nameOf(source)))

    return true, ('Injection faite. %s se relèvera dans %d secondes.')
        :format(nameOf(targetId), Config.Revive.standUpSeconds)
end)


---Le joueur abandonne.
RegisterNetEvent('rz_mort:giveUp', function()
    local src = source
    local d = downed[src]
    if not d then return end

    if (os.time() - d.since) < Config.Agonie.giveUpAfter then return end

    FinalDeath(src)
end)


-- ═══════════════════════════════════════════════════════════════════
--  MORT DÉFINITIVE
-- ═══════════════════════════════════════════════════════════════════

function FinalDeath(source)
    local d = downed[source]
    clearDowned(source)

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local citizenid = citizenIdOf(source)

    pcall(function()
        exports.qbx_core:SetMetadata(source, 'isdead', true)
    end)

    -- Le stuff ne tombe pas en zone sûre : perdre son inventaire sur
    -- une chute accidentelle en ville n'aurait aucun sens.
    local shouldDrop = Config.Bag.dropInSafezone or not inSafezone(source)
    local bagId

    if shouldDrop then
        bagId = CreateDeathBag(source, coords, citizenid)
    end

    local point = nearestRespawn(coords)

    TriggerClientEvent('rz_mort:finalDeath', source, {
        x = point.x, y = point.y, z = point.z,
        fadeMs = Config.Respawn.fadeMs,
        health = Config.Respawn.health,
        bagged = bagId ~= nil,
    })

    MySQL.prepare([[
        INSERT INTO rz_mort_logs (citizenid, action, detail)
        VALUES (?, 'death', ?)
    ]], { citizenid, json.encode({
        x = coords.x, y = coords.y, z = coords.z,
        bag = bagId, safezone = not shouldDrop,
    }) })

    logDiscord('Mort', ('**%s** est mort.'):format(nameOf(source)), {
        { name = 'Position', value = ('%.0f, %.0f, %.0f'):format(coords.x, coords.y, coords.z) },
        { name = 'Sac',      value = bagId and ('`%s`'):format(bagId) or 'Aucun (zone sûre)' },
    })

    dbg(('%s est mort%s'):format(nameOf(source), bagId and ' — sac déposé' or ''))
end

exports('FinalDeath', FinalDeath)


-- ═══════════════════════════════════════════════════════════════════
--  SAC MORTUAIRE
-- ═══════════════════════════════════════════════════════════════════

function CreateDeathBag(source, coords, citizenid)
    local items = exports.ox_inventory:GetInventoryItems(source)
    if not items then return nil end

    -- Les coffres encore sous protection restent avec leur
    -- propriétaire : c'est toute la raison d'être de cet objet.
    local protected = {}

    if GetResourceState('rz_coffres') == 'started' then
        local ok, result = pcall(function()
            return exports.rz_coffres:GetProtectedSlots(source)
        end)
        if ok and type(result) == 'table' then protected = result end
    end

    local loot, count = {}, 0

    for slot, item in pairs(items) do
        if not protected[slot] then
            loot[#loot + 1] = { item.name, item.count, item.metadata }
            count = count + 1
        end
    end

    if count == 0 then return nil end

    local bagId = ('rzsac_%d_%d'):format(os.time(), math.random(1000, 9999))
    local now = os.time()

    exports.ox_inventory:RegisterStash(
        bagId, 'Sac mortuaire',
        Config.Bag.slots, Config.Bag.maxWeight,
        false, nil, coords
    )

    for _, entry in ipairs(loot) do
        exports.ox_inventory:AddItem(bagId, entry[1], entry[2], entry[3])
    end

    -- On ne vide QUE ce qui a été transféré : les slots protégés
    -- restent en place.
    for slot, item in pairs(items) do
        if not protected[slot] then
            exports.ox_inventory:RemoveItem(source, item.name, item.count, item.metadata, slot)
        end
    end

    Bags[bagId] = {
        owner     = citizenid,
        ownerName = nameOf(source),
        x = coords.x, y = coords.y, z = coords.z,
        createdAt = now,
        lockUntil = now + Config.Bag.ownerLockSeconds,
    }

    MySQL.prepare([[
        INSERT INTO rz_mort_bags (bag_id, owner_citizenid, owner_name, x, y, z, lock_until)
        VALUES (?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?))
    ]], { bagId, citizenid, nameOf(source),
          coords.x, coords.y, coords.z, Bags[bagId].lockUntil })

    TriggerClientEvent('rz_mort:addBag', -1, {
        id = bagId,
        x = coords.x, y = coords.y, z = coords.z,
        owner = citizenid,
        lockUntil = Bags[bagId].lockUntil,
    })

    dbg(('sac %s créé : %d pile(s)'):format(bagId, count))

    return bagId
end


-- Verrou propriétaire : le hook est la seule barrière qui compte,
-- puisqu'un client modifié pourrait ouvrir n'importe quel stash.
exports.ox_inventory:registerHook('openInventory', function(payload)
    if payload.inventoryType ~= 'stash' then return true end

    local bag = Bags[payload.inventoryId]
    if not bag then return true end

    local now = os.time()
    if now >= bag.lockUntil then return true end

    if citizenIdOf(payload.source) == bag.owner then return true end

    TriggerClientEvent('ox_lib:notify', payload.source, {
        type        = 'error',
        title       = 'Sac verrouillé',
        description = ('Encore %d s avant que ce sac soit pillable.')
            :format(bag.lockUntil - now),
        duration    = 6000,
    })

    return false
end, { print = false })


lib.callback.register('rz_mort:openBag', function(source, bagId)
    local bag = Bags[bagId]
    if not bag then return false end

    local ped = GetPlayerPed(source)
    if #(GetEntityCoords(ped) - vec3(bag.x, bag.y, bag.z)) > 3.0 then
        return false
    end

    local now = os.time()

    if now < bag.lockUntil and citizenIdOf(source) ~= bag.owner then
        return false, bag.lockUntil - now
    end

    return bagId
end)


-- ═══════════════════════════════════════════════════════════════════
--  ENTRETIEN
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(600000)   -- 10 minutes

        local limit = os.time() - (Config.Bag.maxAgeHours * 3600)
        local removed = 0

        for bagId, bag in pairs(Bags) do
            if bag.createdAt < limit then
                pcall(function() exports.ox_inventory:RemoveInventory(bagId) end)
                Bags[bagId] = nil
                TriggerClientEvent('rz_mort:removeBag', -1, bagId)
                removed = removed + 1
            end
        end

        if removed > 0 then
            MySQL.prepare('DELETE FROM rz_mort_bags WHERE created_at < FROM_UNIXTIME(?)', { limit })
            dbg(('%d sac(s) périmé(s) retiré(s)'):format(removed))
        end
    end
end)


AddEventHandler('playerDropped', function()
    downed[source] = nil
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
--
--  Les sacs sont rechargés depuis la base : un simple restart de la
--  ressource ne doit pas faire disparaître le stuff des joueurs.
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(1500)

    local limit = os.time() - (Config.Bag.maxAgeHours * 3600)
    MySQL.prepare.await('DELETE FROM rz_mort_bags WHERE created_at < FROM_UNIXTIME(?)', { limit })

    local rows = MySQL.query.await([[
        SELECT bag_id, owner_citizenid, owner_name, x, y, z,
               UNIX_TIMESTAMP(created_at) AS created_ts,
               UNIX_TIMESTAMP(lock_until) AS lock_ts
        FROM rz_mort_bags
    ]]) or {}

    for _, r in ipairs(rows) do
        Bags[r.bag_id] = {
            owner     = r.owner_citizenid,
            ownerName = r.owner_name,
            x = r.x, y = r.y, z = r.z,
            createdAt = r.created_ts,
            lockUntil = r.lock_ts,
        }

        exports.ox_inventory:RegisterStash(
            r.bag_id, 'Sac mortuaire',
            Config.Bag.slots, Config.Bag.maxWeight,
            false, nil, vec3(r.x, r.y, r.z)
        )
    end

    if #rows > 0 then
        print(('^2[rz_mort]^7 %d sac(s) rechargé(s) depuis la base'):format(#rows))
    end
end)


lib.callback.register('rz_mort:getBags', function()
    local out = {}

    for id, b in pairs(Bags) do
        out[#out + 1] = {
            id = id, x = b.x, y = b.y, z = b.z,
            owner = b.owner, lockUntil = b.lockUntil,
        }
    end

    return out
end)


-- ═══════════════════════════════════════════════════════════════════
--  APPEL À L'AIDE
--
--  Seuls les joueurs assez proches sont prévenus : une alerte
--  serveur entier transformerait chaque mort en événement public.
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_mort:callHelp', function()
    local src = source
    if not downed[src] then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local name = nameOf(src)

    for _, playerId in ipairs(GetPlayers()) do
        local other = tonumber(playerId)

        if other ~= src and not downed[other] then
            local otherPed = GetPlayerPed(other)

            if otherPed and otherPed ~= 0 then
                if #(GetEntityCoords(otherPed) - coords) <= Config.Agonie.callDistance then
                    TriggerClientEvent('rz_mort:helpCall', other, coords, name)
                end
            end
        end
    end
end)


-- Le client a besoin de son propre citizenid pour savoir quels sacs
-- lui appartiennent, et donc quels blips afficher.
AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(8000, function()
        local cid = citizenIdOf(src)
        if cid then TriggerClientEvent('rz_mort:setCid', src, cid) end
    end)
end)

RegisterNetEvent('rz_mort:requestCid', function()
    local cid = citizenIdOf(source)
    if cid then TriggerClientEvent('rz_mort:setCid', source, cid) end
end)
