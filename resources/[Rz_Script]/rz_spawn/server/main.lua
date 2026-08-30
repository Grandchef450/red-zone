--[[
    rz_spawn / server/main.lua

    Décide OÙ un joueur apparaît, et le lui dit.

    Le serveur choisit, le client exécute : lui seul connaît la
    dernière position enregistrée et les safe zones, deux données que
    le client ne doit pas pouvoir inventer.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


---Centre de la safe zone la plus proche d'un point.
---@param coords vector3|vector4
---@return vector4|nil
local function nearestSafezone(coords)
    if not Config.UseSafezones then return nil end
    if GetResourceState('rz_safezone') ~= 'started' then return nil end

    local ok, zones = pcall(function()
        return exports.rz_safezone:GetZones()
    end)

    if not ok or type(zones) ~= 'table' then return nil end

    local best, bestDist = nil, math.huge

    for _, z in pairs(zones) do
        if type(z.points) == 'table' and #z.points > 0 then
            -- Le centre d'un polygone, c'est la moyenne de ses coins
            local sx, sy = 0.0, 0.0
            for _, p in ipairs(z.points) do
                sx, sy = sx + p.x, sy + p.y
            end

            local cx, cy = sx / #z.points, sy / #z.points
            local d = #(vec2(coords.x, coords.y) - vec2(cx, cy))

            if d < bestDist then
                bestDist = d
                -- On vise le niveau du sol, pas le milieu du volume :
                -- le centre d'une zone qui monte à 200 m placerait le
                -- joueur en plein ciel.
                best = vec4(cx, cy, (z.min_z or 0.0) + 2.0, 0.0)
            end
        end
    end

    if best then
        dbg(('safe zone trouvée à %.0f m'):format(bestDist))
    end

    return best
end


---Position enregistrée d'un personnage, si elle est exploitable.
---@param source number
---@return vector4|nil
local function lastPosition(source)
    if not Config.Spawn.restoreLastPosition then return nil end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local pos = player.PlayerData.position
    if not pos then return nil end

    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    local z = tonumber(pos.z)

    if not x or not y or not z then return nil end

    -- Une position trop proche de l'origine signifie que le joueur a
    -- été déconnecté pendant un chargement. La restaurer le
    -- replacerait sous la carte à chaque connexion, sans qu'il
    -- puisse rien y faire.
    if math.sqrt(x * x + y * y) < Config.Spawn.minValidDistance then
        dbg(('position enregistrée invalide (%.1f, %.1f)'):format(x, y))
        return nil
    end

    -- Sous la carte : même raisonnement, et c'est le cas le plus
    -- fréquent après une chute non rattrapée.
    if z < Config.Detection.underMapZ then
        dbg(('position enregistrée sous la carte (z = %.1f)'):format(z))
        return nil
    end

    -- Zone interdite : un joueur déconnecté dans un endroit qui fait
    -- planter y replanterait à chaque connexion, et ne pourrait plus
    -- jamais revenir sur son personnage.
    local blocked = Config.BlacklistedAt(x, y, z)

    if blocked then
        dbg(('position enregistrée dans « %s », renvoi au départ')
            :format(blocked.label))
        return nil
    end

    return vec4(x, y, z, tonumber(pos.w) or 0.0)
end


---Envoie le joueur à sa position d'apparition.
function SpawnPlayer(source)
    local last = lastPosition(source)
    local isNew = last == nil
    local target

    if isNew then
        -- Nouveau personnage : safe zone la plus proche du point de
        -- départ, ou le point lui-même si aucune zone n'est tracée.
        target = nearestSafezone(Config.Spawn.default) or Config.Spawn.default
    else
        target = last
    end

    TriggerClientEvent('rz_spawn:goTo', source, {
        x = target.x, y = target.y, z = target.z, w = target.w or 0.0,
        health = Config.Spawn.health,
        armour = Config.Spawn.armour,
        isNew  = isNew,
    })

    dbg(('%s → %.0f, %.0f, %.0f (%s)'):format(
        GetPlayerName(source) or source,
        target.x, target.y, target.z,
        isNew and 'nouveau' or 'retour'))
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉCLENCHEURS
--
--  Qbox émet l'un ou l'autre selon sa version. On écoute les deux,
--  et un verrou évite qu'un joueur soit déplacé deux fois.
-- ═══════════════════════════════════════════════════════════════════

local spawning = {}

local function handleLoaded(src)
    if spawning[src] then return end
    spawning[src] = true

    -- Un court délai laisse à qbx_core le temps de finir de charger
    -- les données du personnage : sans lui, la position lue serait
    -- parfois vide.
    SetTimeout(1200, function()
        if GetPlayerName(src) then
            SpawnPlayer(src)
        end
        spawning[src] = nil
    end)
end


RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    handleLoaded(source)
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function()
    handleLoaded(source)
end)

-- Filet : le client demande lui-même s'il n'a rien reçu au bout de
-- quelques secondes. C'est ce qui évite l'écran noir sans fin quand
-- aucun des deux événements ci-dessus n'est émis.
RegisterNetEvent('rz_spawn:request', function()
    handleLoaded(source)
end)


AddEventHandler('playerDropped', function()
    spawning[source] = nil
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('respawn', {
    help = 'Se replacer au point d\'apparition',
}, function(source)
    SpawnPlayer(source)
end)


lib.addCommand('setspawn', {
    help = 'Relever ta position comme point de départ',
    restricted = 'rz.staff',
}, function(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)

    -- On ne réécrit pas le fichier : la valeur est donnée à copier
    -- à la main. Modifier un config.lua depuis le jeu, c'est le
    -- perdre au prochain déploiement.
    TriggerClientEvent('ox_lib:alertDialog', source, {
        header  = 'Point de départ',
        content = ('Copie cette ligne dans rz_spawn/config.lua :  \n\n`default = vec4(%.1f, %.1f, %.1f, %.1f),`')
            :format(c.x, c.y, c.z, h),
        centered = true,
    })
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local d = Config.Spawn.default
    print(('^2[rz_spawn]^7 point de départ : %.0f, %.0f, %.0f'):format(d.x, d.y, d.z))
end)
