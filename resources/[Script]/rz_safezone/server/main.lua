--[[
    rz_safezone / server/main.lua

    Le serveur est l'autorité. Le client gère le confort (bandeau,
    rengainage, suppression de projectiles) mais un client modifié
    peut mentir sur tout ça. Ce qui protège réellement, ce sont les
    deux gestionnaires plus bas : weaponDamageEvent et explosionEvent,
    tous deux annulables côté serveur.
]]

Zones = {}          -- [zone_key] = { ... }
PlayerZones = {}    -- [source]   = { zone = key|nil, inBuffer = bool }

local lastLog = {}  -- anti-spam du journal

local function dbg(...)
    if Config.Debug then print('^3[rz_safezone]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  GÉOMÉTRIE
-- ═══════════════════════════════════════════════════════════════════

---Point dans polygone, par lancer de rayon.
---@param x number
---@param y number
---@param points table liste de { x, y }
---@return boolean
function PointInPolygon(x, y, points)
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


---Distance d'un point au bord du polygone. Sert à la zone tampon.
---@return number
function DistanceToPolygon(x, y, points)
    local best = math.huge
    local n = #points
    local j = n

    for i = 1, n do
        local a, b = points[i], points[j]

        -- Distance au segment [a, b]
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


---Cercle englobant d'un polygone : centre et rayon.
local function boundingCircle(points)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, p in ipairs(points) do
        if p.x < minX then minX = p.x end
        if p.x > maxX then maxX = p.x end
        if p.y < minY then minY = p.y end
        if p.y > maxY then maxY = p.y end
    end

    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2

    local radius = 0.0
    for _, p in ipairs(points) do
        local d = math.sqrt((p.x - cx) ^ 2 + (p.y - cy) ^ 2)
        if d > radius then radius = d end
    end

    return cx, cy, radius
end


---Dans quelle zone se trouve ce point, et est-il dans le tampon ?
---@return string|nil zoneKey, boolean inBuffer
function GetZoneAt(x, y, z)
    for key, zone in pairs(Zones) do
        if zone.enabled then
            -- Test vertical d'abord : c'est le moins coûteux
            if z >= zone.min_z and z <= zone.max_z then
                if PointInPolygon(x, y, zone.points) then
                    return key, false
                end

                if zone.buffer_meters > 0 then
                    local d = DistanceToPolygon(x, y, zone.points)
                    if d <= zone.buffer_meters then
                        return key, true
                    end
                end
            end
        end
    end

    return nil, false
end


---Position d'un joueur, ou nil s'il n'est pas dans le monde.
local function pedCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end


-- ═══════════════════════════════════════════════════════════════════
--  CHARGEMENT
-- ═══════════════════════════════════════════════════════════════════

function LoadZones()
    Zones = {}

    local rows = MySQL.query.await('SELECT * FROM rz_safezones WHERE enabled = 1') or {}

    for _, row in ipairs(rows) do
        local points = json.decode(row.points)

        if type(points) == 'table' and #points >= 3 then
            row.points = points
            row.enabled = row.enabled == 1
            Zones[row.zone_key] = row
        else
            print(('^1[rz_safezone]^7 zone « %s » ignorée : polygone invalide')
                :format(row.zone_key))
        end
    end

    dbg(('%d zone(s) chargée(s)'):format(#rows))

    SyncZombieSafezones()
    TriggerClientEvent('rz_safezone:sync', -1, GetClientZones())
end


---Version allégée envoyée aux clients : uniquement ce qui sert à
---dessiner et à détecter. Aucune donnée d'administration.
function GetClientZones()
    local out = {}

    for key, z in pairs(Zones) do
        out[#out + 1] = {
            key    = key,
            label  = z.label,
            points = z.points,
            minZ   = z.min_z,
            maxZ   = z.max_z,
            buffer = z.buffer_meters,

            blockWeapons     = z.block_weapons == 1,
            blockMelee       = z.block_melee == 1,
            blockProjectiles = z.block_projectiles == 1,
            blockVehicles    = z.block_vehicles == 1,
            blockRunover     = z.block_runover == 1,

            enterMessage = z.enter_message,
            exitMessage  = z.exit_message,

            blipEnabled = z.blip_enabled == 1,
            blipColor   = z.blip_color,
            blipAlpha   = z.blip_alpha,
        }
    end

    return out
end


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION AVEC LE SCRIPT DE ZOMBIES
--
--  Le script Fivecore est chiffré et ne gère que des cercles.
--  On lui déclare le cercle englobant de chaque polygone.
-- ═══════════════════════════════════════════════════════════════════

local registeredZombieZones = {}

function SyncZombieSafezones()
    if not Config.Zombies.enabled then return end

    local res = Config.Zombies.resource

    if GetResourceState(res) ~= 'started' then
        print(('^3[rz_safezone]^7 ressource « %s » non démarrée : zones zombies non synchronisées')
            :format(res))
        return
    end

    -- Retire les anciennes avant de reposer les nouvelles
    for _, id in ipairs(registeredZombieZones) do
        pcall(function() exports[res]:removeSafezone(id) end)
    end
    registeredZombieZones = {}

    for key, zone in pairs(Zones) do
        if zone.despawn_zombies == 1 then
            local cx, cy, radius = boundingCircle(zone.points)
            local id = 'rz_' .. key

            local ok, err = pcall(function()
                exports[res]:registerSafezone({
                    id             = id,
                    coords         = vec3(cx, cy, (zone.min_z + zone.max_z) / 2),
                    radius         = radius + Config.Zombies.margin,
                    createBlip     = false,
                    despawnZombies = true,
                })
            end)

            if ok then
                registeredZombieZones[#registeredZombieZones + 1] = id
                dbg(('zone zombies « %s » : rayon %.1f m'):format(id, radius))
            else
                print(('^1[rz_safezone]^7 échec registerSafezone pour %s : %s')
                    :format(id, tostring(err)))
            end
        end
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  SUIVI DES JOUEURS
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Detection.serverInterval)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local coords = pedCoords(src)

            if coords then
                local key, inBuffer = GetZoneAt(coords.x, coords.y, coords.z)
                PlayerZones[src] = { zone = key, inBuffer = inBuffer }
            else
                PlayerZones[src] = nil
            end
        end
    end
end)


AddEventHandler('playerDropped', function()
    PlayerZones[source] = nil
end)


---Ce joueur est-il protégé ? (dans une zone ou son tampon)
---@param source number
---@return boolean protected, string|nil zoneKey, boolean inBuffer
function IsProtected(source)
    local p = PlayerZones[source]
    if not p or not p.zone then return false end

    local zone = Zones[p.zone]
    if not zone or zone.block_damage ~= 1 then return false end

    return true, p.zone, p.inBuffer
end

exports('IsPlayerProtected', IsProtected)
exports('GetPlayerZone', function(source)
    local p = PlayerZones[source]
    return p and p.zone or nil
end)
exports('GetZoneAt', GetZoneAt)
exports('GetZones', function() return Zones end)
exports('ReloadZones', LoadZones)


-- ═══════════════════════════════════════════════════════════════════
--  JOURNAL
-- ═══════════════════════════════════════════════════════════════════

local function logBlock(zoneKey, attacker, victim, kind, weapon, fromInside)
    if not Config.Logging.enabled then return end

    -- Un tir automatique produirait des centaines de lignes par
    -- seconde. On n'en garde qu'une par joueur et par fenêtre.
    local now = os.time()
    local id = tostring(attacker or 'inconnu')

    if lastLog[id] and (now - lastLog[id]) < Config.Logging.cooldownSeconds then
        return
    end
    lastLog[id] = now

    MySQL.prepare([[
        INSERT INTO rz_safezone_blocks
            (zone_key, attacker, victim, kind, weapon, from_inside)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { zoneKey, attacker, victim, kind, weapon, fromInside and 1 or 0 })
end


local function identifierOf(source)
    if not source or source == 0 then return nil end
    return GetPlayerIdentifierByType(source, 'license')
end


-- ═══════════════════════════════════════════════════════════════════
--  ANNULATION DES DÉGÂTS D'ARME
--
--  C'EST LA PROTECTION QUI COMPTE. Elle est serveur, donc un client
--  modifié ne peut pas la contourner. Tout le reste (rengainage,
--  contrôles désactivés) n'est que du confort visuel.
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('weaponDamageEvent', function(sender, data)
    local attacker = tonumber(sender)

    -- Cas 1 : l'attaquant est dans une zone → il ne peut rien faire.
    local attackerProtected, attackerZone = IsProtected(attacker)

    if attackerProtected then
        CancelEvent()
        logBlock(attackerZone, identifierOf(attacker), nil, 'arme',
                 tostring(data.weaponType), true)
        return
    end

    -- Cas 2 : une des victimes est dans une zone → tir venu du
    -- dehors, annulé à l'arrivée.
    for _, netId in ipairs(data.hitGlobalIds or {}) do
        local entity = NetworkGetEntityFromNetworkId(netId)

        if entity and entity ~= 0 then
            local victim = NetworkGetEntityOwner(entity)

            -- On retrouve le joueur propriétaire du ped touché
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)

                if GetPlayerPed(src) == entity then
                    local protected, zoneKey = IsProtected(src)

                    if protected then
                        CancelEvent()
                        logBlock(zoneKey, identifierOf(attacker),
                                 identifierOf(src), 'arme',
                                 tostring(data.weaponType), false)

                        TriggerClientEvent('rz_safezone:damageBlocked', src)
                        return
                    end

                    break
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ANNULATION DES EXPLOSIONS
--
--  Couvre grenades, lance-roquettes, voitures piégées. Le test
--  porte sur le POINT D'IMPACT : une grenade lancée de l'extérieur
--  mais qui atterrit dedans est annulée.
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('explosionEvent', function(sender, ev)
    local key, inBuffer = GetZoneAt(ev.posX, ev.posY, ev.posZ)

    if key then
        local zone = Zones[key]

        if zone and zone.block_damage == 1 then
            CancelEvent()

            local attacker = tonumber(sender)
            logBlock(key, identifierOf(attacker), nil, 'explosion',
                     tostring(ev.explosionType), not inBuffer)

            dbg(('explosion annulée dans « %s »'):format(key))
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(2000)   -- laisse le script de zombies s'initialiser
    LoadZones()
end)


-- Un joueur qui vient de se connecter reçoit les zones
RegisterNetEvent('rz_safezone:requestSync', function()
    TriggerClientEvent('rz_safezone:sync', source, GetClientZones())
end)


-- Si le script de zombies redémarre, il perd nos zones : on les
-- redéclare dès qu'il est de nouveau prêt.
AddEventHandler('onResourceStart', function(resource)
    if resource == Config.Zombies.resource then
        Wait(3000)
        registeredZombieZones = {}
        SyncZombieSafezones()
    end
end)
