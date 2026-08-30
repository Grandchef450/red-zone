--[[
    rz_airdrop / server/main.lua

    Largages aériens.

    ─── LE PROBLÈME DE L'EAU ──────────────────────────────────────

    Le serveur ne peut pas savoir si un point est sur terre : la
    hauteur du sol et la présence d'eau sont des données CLIENT.
    Tirer un point au hasard sur la carte finirait fatalement par
    poser une caisse au fond de l'océan.

    D'où les zones terrestres du config : chacune est un cercle
    entièrement sur terre, et le serveur y tire un point au hasard.
    La variété est préservée, le risque nul.

    ─── LA TRAJECTOIRE ────────────────────────────────────────────

    On tire un cap, on projette une ligne à travers la carte, et on
    ne retient que les portions qui traversent une zone terrestre.
    Si la ligne n'en croise pas assez, on en tire une autre.

    L'avion n'est jamais chargé comme entité : seul un blip le
    représente. C'est plus léger, et c'est ce qui était demandé.
]]

-- [crateId] = { x, y, z, tier, contents, droppedAt, openableAt, opened }
Crates = {}

-- Largage en cours
Flight = {
    active   = false,
    startedAt = 0,
    points   = {},     -- positions de largage prévues
    dropped  = 0,
}

local nextDrop = 0
local crateSeq = 0

local function dbg(...)
    if Config.Debug then print('^3[rz_airdrop]^7', ...) end
end


local function announce(category, priority, ...)
    if not Config.Announce.enabled then return end
    if GetResourceState('rz_signal_urgences') ~= 'started' then return end

    local text = Config.PickMessage(category, ...)
    if text == '' then return end

    pcall(function()
        exports.rz_signal_urgences:AlertZone(nil, text, priority or 'alerte')
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  CALCUL DE LA TRAJECTOIRE
-- ═══════════════════════════════════════════════════════════════════

---Cherche une ligne droite qui traverse assez de zones terrestres.
---@return table|nil  { from = vec2, to = vec2, points = { vec2, ... } }
local function computeRoute()
    local needed = Config.Drop.crates
    local spacing = Config.Drop.minSpacing

    -- Vingt essais suffisent largement : avec vingt-trois zones
    -- réparties sur la carte, une diagonale en croise presque
    -- toujours quatre.
    for attempt = 1, 20 do
        -- Un cap au hasard, et un point de passage au centre de la
        -- carte pour que la ligne la traverse vraiment.
        local angle = math.random() * math.pi * 2
        local cx = -500 + math.random() * 2500
        local cy = 500 + math.random() * 3500

        local dx, dy = math.cos(angle), math.sin(angle)

        -- On échantillonne la ligne sur 12 000 unités, de part et
        -- d'autre du point de passage.
        local candidates = {}
        local step = 120.0

        for t = -6000, 6000, step do
            local x, y = cx + dx * t, cy + dy * t
            local zone = Config.ZoneAt(x, y)

            if zone then
                -- On respecte l'écart minimum avec le point retenu
                -- précédemment : sans ça, les quatre caisses
                -- tomberaient côte à côte dans la même zone.
                local last = candidates[#candidates]

                if not last or math.sqrt((x - last.x) ^ 2 + (y - last.y) ^ 2) >= spacing then
                    candidates[#candidates + 1] = {
                        x = x, y = y, zone = zone, t = t,
                    }
                end
            end
        end

        if #candidates >= needed then
            -- On répartit les largages sur toute la longueur plutôt
            -- que de prendre les quatre premiers : le trajet doit
            -- traverser la carte, pas s'arrêter au premier tiers.
            local picked = {}
            local stride = #candidates / needed

            for i = 1, needed do
                local index = math.floor((i - 0.5) * stride) + 1
                picked[#picked + 1] = candidates[math.min(index, #candidates)]
            end

            local first, last = picked[1], picked[#picked]
            local approach = Config.Plane.approach

            dbg(('trajectoire trouvée en %d essai(s), %d point(s) candidat(s)')
                :format(attempt, #candidates))

            return {
                from   = { x = first.x - dx * approach, y = first.y - dy * approach },
                to     = { x = last.x + dx * approach,  y = last.y + dy * approach },
                points = picked,
            }
        end
    end

    dbg('aucune trajectoire valable après 20 essais')
    return nil
end


-- ═══════════════════════════════════════════════════════════════════
--  LARGAGE
-- ═══════════════════════════════════════════════════════════════════

local function spawnCrate(point, tierIndex, contents)
    crateSeq = crateSeq + 1

    local id = ('rzcrate_%d_%d'):format(os.time(), crateSeq)
    local now = os.time()
    local tier = Config.TierAt(tierIndex)

    local crate = {
        id         = id,
        x          = point.x,
        y          = point.y,
        z          = 0.0,          -- le client posera la caisse au sol
        tier       = tierIndex,
        tierKey    = tier.key,
        label      = tier.label,
        colour     = tier.colour,
        smoke      = tier.smokeColour,
        contents   = contents,
        droppedAt  = now,
        openableAt = now + Config.Drop.protectionSeconds,
        expiresAt  = now + Config.Drop.lifetimeSeconds,
        opened     = false,
    }

    Crates[id] = crate

    -- Le stash n'est créé qu'à la première ouverture : inutile de
    -- réserver quatre inventaires pour des caisses que personne ne
    -- trouvera peut-être.

    TriggerClientEvent('rz_airdrop:addCrate', -1, {
        id         = id,
        x          = point.x,
        y          = point.y,
        tier       = tierIndex,
        label      = tier.label,
        colour     = tier.colour,
        smoke      = tier.smokeColour,
        openableAt = crate.openableAt,
        expiresAt  = crate.expiresAt,
    })

    announce('crateDropped', 'info', (point.zone and point.zone.label or 'secteur inconnu'):upper())

    MySQL.prepare([[
        INSERT INTO rz_airdrop_crates (crate_id, tier, x, y, items, expires_at)
        VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?))
    ]], { id, tier.key, point.x, point.y, json.encode(contents), crate.expiresAt })

    dbg(('caisse %s (%s) posée en %.0f, %.0f'):format(id, tier.key, point.x, point.y))
end


---Lance un largage complet.
---@param forced boolean  ignore le minimum de joueurs
---@return boolean ok, string message
function LaunchDrop(forced)
    if Flight.active then
        return false, 'Un largage est déjà en cours.'
    end

    local players = #GetPlayers()

    if not forced and players < Config.Schedule.minPlayers then
        dbg(('largage annulé : %d joueur(s)'):format(players))
        return false, ('Pas assez de joueurs (%d).'):format(players)
    end

    local route = computeRoute()
    if not route then
        return false, 'Aucune trajectoire valable trouvée.'
    end

    local crates = RollDrop()

    Flight.active = true
    Flight.startedAt = os.time()
    Flight.points = route.points
    Flight.dropped = 0

    announce('incoming', 'alerte')

    -- Le blip de l'avion part tout de suite : les joueurs le voient
    -- traverser et peuvent anticiper le point de chute.
    TriggerClientEvent('rz_airdrop:startFlight', -1, {
        from  = route.from,
        to    = route.to,
        speed = Config.Plane.speed,
    })

    -- Chaque caisse tombe à son tour, à intervalle irrégulier.
    CreateThread(function()
        for i, point in ipairs(route.points) do
            local wait = math.random(Config.Drop.intervalMin, Config.Drop.intervalMax)

            -- La première attend moins : l'avion vient de la zone
            -- d'approche, il est déjà en route.
            if i == 1 then wait = math.floor(wait / 2) end

            Wait(wait * 1000)

            local data = crates[i]
            if data then
                spawnCrate(point, data.tier, data.contents)
                Flight.dropped = Flight.dropped + 1
            end
        end

        Wait(5000)
        Flight.active = false
        TriggerClientEvent('rz_airdrop:endFlight', -1)

        dbg('largage terminé')
    end)

    return true, ('Largage lancé : %d caisse(s).'):format(#route.points)
end


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_airdrop:openCrate', function(source, crateId)
    local crate = Crates[crateId]
    if not crate then return false, 'Caisse introuvable.' end

    local now = os.time()

    -- Le verrou de cinq minutes. C'est la fenêtre pendant laquelle
    -- les joueurs convergent et se disputent la position : sans
    -- elle, le premier arrivé repart avant que quiconque ait vu
    -- le blip.
    if now < crate.openableAt then
        return false, crate.openableAt - now
    end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 'Position introuvable.' end

    local coords = GetEntityCoords(ped)
    if #(vec2(coords.x, coords.y) - vec2(crate.x, crate.y)) > 5.0 then
        return false, 'Trop loin de la caisse.'
    end

    -- Premier ouvreur : on crée l'inventaire et on y verse le butin
    if not crate.opened then
        crate.opened = true

        exports.ox_inventory:RegisterStash(
            crateId, crate.label, 20, 200000,
            false, nil, vec3(crate.x, crate.y, crate.z)
        )

        for _, entry in ipairs(crate.contents) do
            exports.ox_inventory:AddItem(crateId, entry.item, entry.count)
        end

        MySQL.prepare([[
            UPDATE rz_airdrop_crates
            SET opened_at = NOW(), opened_by = ?
            WHERE crate_id = ?
        ]], { GetPlayerIdentifierByType(source, 'license'), crateId })

        LogCrateOpened(source, crate)

        dbg(('caisse %s ouverte par %s'):format(crateId, GetPlayerName(source)))
    end

    return crateId
end)


-- ═══════════════════════════════════════════════════════════════════
--  ENTRETIEN
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(30000)

        local now = os.time()
        local removed = 0

        for id, crate in pairs(Crates) do
            if now >= crate.expiresAt then
                -- Une caisse ouverte peut encore contenir du butin :
                -- on la retire quand même, sinon la carte se couvre
                -- de conteneurs oubliés.
                pcall(function()
                    exports.ox_inventory:RemoveInventory(id)
                end)

                Crates[id] = nil
                TriggerClientEvent('rz_airdrop:removeCrate', -1, id)
                removed = removed + 1
            end
        end

        if removed > 0 then
            announce('expired', 'info')
            dbg(('%d caisse(s) expirée(s)'):format(removed))
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  HORLOGE
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(10000)

    nextDrop = os.time() + (Config.Schedule.firstDelayMinutes * 60)

    while true do
        Wait(10000)

        if Config.Schedule.enabled and os.time() >= nextDrop then
            LaunchDrop(false)
            nextDrop = os.time() + (Config.Schedule.intervalMinutes * 60)
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT
-- ═══════════════════════════════════════════════════════════════════

function GetAirdropInfo()
    local now = os.time()
    local active, protected = 0, 0

    for _, c in pairs(Crates) do
        active = active + 1
        if now < c.openableAt then protected = protected + 1 end
    end

    return {
        enabled   = Config.Schedule.enabled,
        flying    = Flight.active,
        nextIn    = math.max(0, nextDrop - now),
        crates    = active,
        protected = protected,
    }
end

exports('GetInfo', GetAirdropInfo)
exports('LaunchDrop', LaunchDrop)


lib.callback.register('rz_airdrop:getCrates', function()
    local out = {}
    local now = os.time()

    for id, c in pairs(Crates) do
        out[#out + 1] = {
            id         = id,
            x          = c.x,
            y          = c.y,
            tier       = c.tier,
            label      = c.label,
            colour     = c.colour,
            smoke      = c.smoke,
            openableAt = c.openableAt,
            expiresAt  = c.expiresAt,
        }
    end

    return out
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Les caisses ne survivent pas à un redémarrage : elles n'ont
    -- qu'une demi-heure de vie, et en restaurer d'anciennes créerait
    -- plus de confusion que de valeur.
    MySQL.prepare('DELETE FROM rz_airdrop_crates WHERE expires_at < NOW()')

    print(('^2[rz_airdrop]^7 %d zone(s) terrestre(s), largage toutes les %d min')
        :format(#Config.LandZones, Config.Schedule.intervalMinutes))
end)

-- ═══════════════════════════════════════════════════════════════════
--  JOURNAL DISCORD
--
--  Volontairement minimal : QUI a ouvert, et QUOI il y avait dedans.
--
--  Pas de coordonnées, pas d'horaires, pas de statistiques. Un log
--  qu'on lit vraiment vaut mieux qu'un log exhaustif que personne
--  n'ouvre — et le contenu d'une caisse est la seule information
--  qui serve à arbitrer une contestation.
-- ═══════════════════════════════════════════════════════════════════

---Nom lisible d'un item, tel qu'il apparaît dans l'inventaire.
local function itemLabel(name)
    local items = exports.ox_inventory:Items()
    local data = items and items[name]
    return data and data.label or name
end


---Nom du personnage, avec le pseudo entre parenthèses.
local function describePlayer(source)
    local pseudo = GetPlayerName(source) or 'Inconnu'

    if GetResourceState('qbx_core') ~= 'started' then
        return pseudo
    end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if ok and player and player.PlayerData and player.PlayerData.charinfo then
        local c = player.PlayerData.charinfo
        local nom = ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('^%s+', '')

        if nom ~= '' then
            return ('%s (%s)'):format(nom, pseudo)
        end
    end

    return pseudo
end


---Envoie l'ouverture d'une caisse sur Discord.
function LogCrateOpened(source, crate)
    if GetResourceState('rz_logs') ~= 'started' then return end

    -- On liste le contenu tel qu'il a été tiré au largage, pas ce
    -- qui reste dans la caisse : c'est bien ça qui intéresse en cas
    -- de contestation.
    local lines = {}

    for _, entry in ipairs(crate.contents or {}) do
        lines[#lines + 1] = ('%d × %s'):format(entry.count, itemLabel(entry.item))
    end

    local contenu = #lines > 0 and table.concat(lines, '\n') or 'Vide'

    pcall(function()
        exports.rz_logs:Log('airdrop', {
            title       = ('Caisse ouverte — %s'):format(crate.label or 'Largage'),
            description = describePlayer(source),
            fields      = {
                { name = 'Contenu', value = contenu, inline = false },
            },
        })
    end)
end
