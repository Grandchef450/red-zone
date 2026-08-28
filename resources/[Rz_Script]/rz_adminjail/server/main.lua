-- ============================================================
--  RZ ADMIN JAIL | server/main.lua
--  • Permissions : lit admins.json de rz_admintablet (memes
--    cles CFX que la tablette F3) + Config.ExtraAllowed
--  • Timer AUTORITAIRE cote serveur (max 5 min, borne dure)
--  • Persistance jails.json : la deconnexion ne libere pas
--  • Liberation → TP au point d'arrivee en ville (config)
-- ============================================================

local RES = GetCurrentResourceName()

local function dbg(msg)
    if Config.Debug then
        print(('^5[rz_adminjail:sv]^7 %s'):format(msg))
    end
end

-- ============================================================
--  PERMISSIONS — memes identifiants CFX que la tablette F3
-- ============================================================

local extraSet = {}
for _, id in ipairs(Config.ExtraAllowed) do
    extraSet[id:lower()] = true
end

local function getIdentifiers(src)
    local ids = {}
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then ids[#ids + 1] = id end
    end
    return ids
end

local function getLicense(src)
    for _, id in ipairs(getIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

-- Lit les admins de rz_admintablet a chaque verification :
-- un admin ajoute via la tablette F3 a acces IMMEDIATEMENT.
local function loadTabletAdmins()
    local res = Config.AdminTabletResource
    if GetResourceState(res) ~= 'started' then return {} end
    local raw = LoadResourceFile(res, 'admins.json')
    if not raw then return {} end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' and type(data.admins) == 'table' then
        return data.admins
    end
    return {}
end

local function isAllowed(src)
    -- 1. Permission ACE : le chemin normal.
    if Config.Ace and IsPlayerAceAllowed(src, Config.Ace) then
        return true
    end

    -- 2. Tablette admin, si elle existe un jour.
    local tabletAdmins = loadTabletAdmins()

    -- 3. Identifiants en dur (fondateurs).
    for _, id in ipairs(getIdentifiers(src)) do
        if extraSet[id:lower()] or tabletAdmins[id] then
            return true
        end
    end

    return false
end

-- ============================================================
--  ETAT DES PRISONS
--  jails[license] = { endsAt, name, coords={x,y,z,heading},
--                     music={url,volume}, reason, byName }
--  onlineByLicense[license] = src (si connecte)
-- ============================================================

local jails = {}

local function saveJails()
    SaveResourceFile(RES, Config.JailsFile, json.encode({ jails = jails }, { indent = true }), -1)
end

local function loadJails()
    local raw = LoadResourceFile(RES, Config.JailsFile)
    if not raw or raw == '' then jails = {} return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' and type(data.jails) == 'table' then
        jails = data.jails
        -- Purge des peines deja expirees pendant que le serveur etait off
        local now = os.time()
        local purged = 0
        for lic, j in pairs(jails) do
            if not j.endsAt or j.endsAt <= now then
                jails[lic] = nil
                purged = purged + 1
            end
        end
        if purged > 0 then saveJails() end
        local n = 0; for _ in pairs(jails) do n = n + 1 end
        dbg(('jails.json charge — %d peine(s) active(s), %d purgee(s)'):format(n, purged))
    else
        jails = {}
    end
end

loadJails()

local function findSrcByLicense(license)
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if getLicense(src) == license then return src end
    end
    return nil
end

local function notify(src, msg, ok)
    TriggerClientEvent('chat:addMessage', src, {
        color = ok and {120, 220, 140} or {255, 90, 90},
        args  = { '[Jail]', msg }
    })
end

-- ============================================================
--  JAIL / RELEASE
-- ============================================================

local function releasePlayer(license, silent)
    local j = jails[license]
    if not j then return end
    jails[license] = nil
    saveJails()

    local src = findSrcByLicense(license)
    if src then
        TriggerClientEvent('rz_adminjail:client:release', src, Config.ReleasePoint)
        if not silent then
            notify(src, 'Peine terminée — bienvenue en ville.', true)
        end
    end
    print(('^2[rz_adminjail:sv]^7 LIBERE : %s (%s)'):format(j.name or '?', license))
end

local function jailPlayer(adminSrc, targetSrc, seconds, coords, music, reason)
    local license = getLicense(targetSrc)
    if not license then
        notify(adminSrc, 'Impossible de lire le license du joueur.', false)
        return
    end

    -- Borne dure : jamais plus de Config.MaxSeconds (5 min)
    seconds = math.floor(math.max(10, math.min(seconds, Config.MaxSeconds)))

    jails[license] = {
        endsAt = os.time() + seconds,
        name   = GetPlayerName(targetSrc) or '?',
        coords = coords,
        music  = music,
        reason = reason,
        byName = GetPlayerName(adminSrc) or '?',
    }
    saveJails()

    TriggerClientEvent('rz_adminjail:client:jail', targetSrc, {
        coords  = coords,
        seconds = seconds,
        music   = music,
        reason  = reason,
        leash   = { enabled = Config.LeashEnabled, radius = Config.LeashRadius },
    })

    print(('^3[rz_adminjail:sv]^7 JAIL : %s (%s) — %ds par %s — raison: %s')
        :format(jails[license].name, license, seconds, jails[license].byName, reason or 'aucune'))
    notify(adminSrc, ('%s emprisonné pour %d:%02d'):format(jails[license].name, seconds // 60, seconds % 60), true)
end

-- ── Boucle de surveillance des fins de peine (1 Hz) ───────
CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        for license, j in pairs(jails) do
            if j.endsAt <= now then
                releasePlayer(license)
            end
        end
    end
end)

-- ── Reconnexion : reprise de peine ────────────────────────
AddEventHandler('playerJoining', function()
    local src = source
    local license = getLicense(src)
    if not license then return end
    local j = jails[license]
    if not j then return end

    local remaining = j.endsAt - os.time()
    if remaining <= 0 then
        jails[license] = nil
        saveJails()
        return
    end

    dbg(('reprise de peine : %s — %ds restants'):format(j.name or '?', remaining))
    -- Laisse le temps au client de charger avant le TP
    SetTimeout(8000, function()
        if GetPlayerName(src) then
            TriggerClientEvent('rz_adminjail:client:jail', src, {
                coords  = j.coords,
                seconds = math.max(1, j.endsAt - os.time()),
                music   = j.music,
                reason  = j.reason,
                leash   = { enabled = Config.LeashEnabled, radius = Config.LeashRadius },
            })
        end
    end)
end)

-- ============================================================
--  PAYLOAD DU PANNEAU ADMIN
-- ============================================================

local function buildPanelData()
    local players = {}
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        local lic = getLicense(src)
        players[#players + 1] = {
            serverId = src,
            name     = GetPlayerName(src),
            jailed   = (lic and jails[lic]) ~= nil,
        }
    end
    table.sort(players, function(a, b) return a.serverId < b.serverId end)

    local activeJails = {}
    local now = os.time()
    for lic, j in pairs(jails) do
        activeJails[#activeJails + 1] = {
            license   = lic,
            name      = j.name,
            remaining = math.max(0, j.endsAt - now),
            byName    = j.byName,
            reason    = j.reason,
            online    = findSrcByLicense(lic) ~= nil,
        }
    end
    table.sort(activeJails, function(a, b) return a.remaining < b.remaining end)

    return {
        players      = players,
        jails        = activeJails,
        locations    = Config.JailLocations,
        musicPresets = Config.MusicPresets,
        maxSeconds   = Config.MaxSeconds,
        defSeconds   = Config.DefaultSeconds,
        defVolume    = Config.DefaultVolume,
    }
end

-- ============================================================
--  EVENTS ADMIN (tout est revalide ici)
-- ============================================================

RegisterNetEvent('rz_adminjail:server:requestOpen', function()
    local src = source
    if not isAllowed(src) then
        notify(src, 'Accès refusé.', false)
        return
    end
    TriggerClientEvent('rz_adminjail:client:openPanel', src, buildPanelData())
end)

RegisterNetEvent('rz_adminjail:server:refresh', function()
    local src = source
    if not isAllowed(src) then return end
    TriggerClientEvent('rz_adminjail:client:panelData', src, buildPanelData())
end)

RegisterNetEvent('rz_adminjail:server:jail', function(data)
    local src = source
    if not isAllowed(src) then
        print(('^1[rz_adminjail:sv]^7 TENTATIVE jail non autorisee par %s (id %d)'):format(GetPlayerName(src) or '?', src))
        return
    end
    if type(data) ~= 'table' then return end

    -- Cible
    local target = tonumber(data.targetId)
    if not target or not GetPlayerName(target) then
        notify(src, 'Joueur introuvable (ID serveur invalide).', false)
        return
    end
    if target == src then
        notify(src, 'Tu ne peux pas t\'emprisonner toi-même.', false)
        return
    end
    if isAllowed(target) then
        notify(src, 'Impossible d\'emprisonner un autre admin.', false)
        return
    end

    -- Duree (borne dure re-appliquee dans jailPlayer)
    local seconds = tonumber(data.seconds) or Config.DefaultSeconds

    -- Coordonnees
    local c = data.coords
    if type(c) ~= 'table' then notify(src, 'Coordonnées manquantes.', false) return end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    local h = tonumber(c.heading) or 0.0
    if not x or not y or not z
    or x < -8192 or x > 8192 or y < -8192 or y > 12000 or z < -100 or z > 2000 then
        notify(src, 'Coordonnées hors map.', false)
        return
    end

    -- Musique : URL http(s) directe uniquement
    local music = nil
    if type(data.music) == 'table' and type(data.music.url) == 'string' and data.music.url ~= '' then
        local url = data.music.url
        if #url > 300 or not (url:match('^https?://')) then
            notify(src, 'URL musique invalide (http/https direct vers un .mp3/.ogg).', false)
            return
        end
        local vol = tonumber(data.music.volume) or Config.DefaultVolume
        music = { url = url, volume = math.max(0.0, math.min(1.0, vol)) }
    end

    local reason = (type(data.reason) == 'string' and data.reason:sub(1, 100)) or nil

    jailPlayer(src, target, seconds, { x = x, y = y, z = z, heading = h }, music, reason)
    TriggerClientEvent('rz_adminjail:client:panelData', src, buildPanelData())
end)

RegisterNetEvent('rz_adminjail:server:unjail', function(license)
    local src = source
    if not isAllowed(src) then return end
    if type(license) ~= 'string' or not jails[license] then
        notify(src, 'Peine introuvable.', false)
        return
    end
    local name = jails[license].name or '?'
    releasePlayer(license)
    notify(src, ('%s libéré manuellement.'):format(name), true)
    TriggerClientEvent('rz_adminjail:client:panelData', src, buildPanelData())
end)
