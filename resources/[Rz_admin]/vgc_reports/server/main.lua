-- ============================================================
--  VGC REPORTS  |  server/main.lua
--  Reports en JSON (sans DB). Staff via ACE.
-- ============================================================

local RES  = GetCurrentResourceName()
local FILE = 'reports.json'

local reports = {}     -- liste de reports
local nextId  = 1

local function dbg(msg) if Config.Debug then print(('^5[vgc_reports]^7 (server) %s'):format(msg)) end end

-- ── Persistance ───────────────────────────────────────────
local function loadFromDisk()
    local raw = LoadResourceFile(RES, FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' and type(data.reports) == 'table' then
            reports = data.reports
            nextId  = data.nextId or (#reports + 1)
            dbg(('reports.json charge (%d reports)'):format(#reports))
            return
        end
    end
    reports, nextId = {}, 1
end
local function saveToDisk()
    SaveResourceFile(RES, FILE, json.encode({ reports = reports, nextId = nextId }), -1)
end
loadFromDisk()

local function isStaff(src) return IsPlayerAceAllowed(src, Config.StaffAce) end

local function findById(id)
    for i, r in ipairs(reports) do if r.id == id then return r, i end end
    return nil
end

-- Envoie la liste a tous les staff connectes
local function pushToStaff()
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if isStaff(src) then
            TriggerClientEvent('vgc_reports:client:staffList', src, reports)
        end
    end
end

-- Notifie un joueur (chat + UI)
local function notify(src, msg, kind)
    TriggerClientEvent('vgc_reports:client:notify', src, msg, kind or 'info')
end

-- ── Le client demande son statut staff ────────────────────
RegisterNetEvent('vgc_reports:server:whoami', function()
    local src = source
    TriggerClientEvent('vgc_reports:client:whoami', src, isStaff(src))
    if isStaff(src) then
        TriggerClientEvent('vgc_reports:client:staffList', src, reports)
    else
        -- renvoie au joueur SES propres reports
        local mine = {}
        local lic = GetPlayerIdentifierByType(src, 'license')
        for _, r in ipairs(reports) do
            if r.license == lic then mine[#mine+1] = r end
        end
        TriggerClientEvent('vgc_reports:client:myReports', src, mine)
    end
end)

-- ── Joueur : soumettre un report ──────────────────────────
RegisterNetEvent('vgc_reports:server:submit', function(category, message)
    local src = source
    if type(message) ~= 'string' or #message < 2 then return end
    if #message > 500 then message = message:sub(1, 500) end
    local r = {
        id        = nextId,
        name      = GetPlayerName(src) or ('Joueur ' .. src),
        src       = src,
        license   = GetPlayerIdentifierByType(src, 'license') or ('id:' .. src),
        category  = type(category) == 'string' and category or 'Autre',
        status    = 'open',
        claimedBy = nil, claimedById = nil,
        messages  = { { from = 'player', name = GetPlayerName(src), text = message, t = os.time() } },
        created   = os.time(),
    }
    nextId = nextId + 1
    reports[#reports+1] = r
    saveToDisk()
    dbg(('report #%d de %s [%s]'):format(r.id, r.name, r.category))
    notify(src, 'Ton report a été envoyé au staff.', 'ok')
    -- alerte staff
    for _, pid in ipairs(GetPlayers()) do
        local s = tonumber(pid)
        if isStaff(s) then notify(s, ('Nouveau report #%d de %s'):format(r.id, r.name), 'info') end
    end
    pushToStaff()
    -- maj de la liste perso du joueur
    local mine = {}
    for _, rr in ipairs(reports) do if rr.license == r.license then mine[#mine+1] = rr end end
    TriggerClientEvent('vgc_reports:client:myReports', src, mine)
end)

-- ── Joueur : repondre dans son report ─────────────────────
RegisterNetEvent('vgc_reports:server:reply', function(id, text)
    local src = source
    if type(text) ~= 'string' or #text < 1 then return end
    local r = findById(id)
    if not r then return end
    local lic = GetPlayerIdentifierByType(src, 'license')
    if r.license ~= lic then return end  -- uniquement son propre report
    if r.status == 'closed' then notify(src, 'Ce report est fermé.', 'err'); return end
    r.messages[#r.messages+1] = { from = 'player', name = r.name, text = text:sub(1,500), t = os.time() }
    saveToDisk()
    if r.claimedById then notify(r.claimedById, ('%s a répondu au report #%d'):format(r.name, r.id), 'info') end
    pushToStaff()
    TriggerClientEvent('vgc_reports:client:reportUpdated', src, r)
end)

-- ── Staff : prendre en charge ─────────────────────────────
RegisterNetEvent('vgc_reports:server:claim', function(id)
    local src = source
    if not isStaff(src) then return end
    local r = findById(id)
    if not r or r.status == 'closed' then return end
    r.status = 'claimed'
    r.claimedBy = GetPlayerName(src)
    r.claimedById = src
    saveToDisk()
    notify(r.src, ('%s prend en charge ton report #%d'):format(r.claimedBy, r.id), 'info')
    pushToStaff()
end)

-- ── Staff : envoyer un message au joueur ──────────────────
RegisterNetEvent('vgc_reports:server:message', function(id, text)
    local src = source
    if not isStaff(src) then return end
    if type(text) ~= 'string' or #text < 1 then return end
    local r = findById(id)
    if not r then return end
    r.messages[#r.messages+1] = { from = 'staff', name = GetPlayerName(src), text = text:sub(1,500), t = os.time() }
    saveToDisk()
    notify(r.src, ('[Staff] %s : %s'):format(GetPlayerName(src), text), 'staff')
    -- maj du joueur s'il a le panneau ouvert
    TriggerClientEvent('vgc_reports:client:reportUpdated', r.src, r)
    pushToStaff()
end)

-- ── Staff : fermer ────────────────────────────────────────
RegisterNetEvent('vgc_reports:server:close', function(id)
    local src = source
    if not isStaff(src) then return end
    local r = findById(id)
    if not r then return end
    r.status = 'closed'
    saveToDisk()
    notify(r.src, ('Ton report #%d a été fermé.'):format(r.id), 'info')
    pushToStaff()
end)

-- ── Staff : supprimer ─────────────────────────────────────
RegisterNetEvent('vgc_reports:server:delete', function(id)
    local src = source
    if not isStaff(src) then return end
    local r, i = findById(id)
    if i then table.remove(reports, i); saveToDisk(); pushToStaff() end
end)

-- ── Staff : se TP au joueur (OneSync) ─────────────────────
RegisterNetEvent('vgc_reports:server:goto', function(id)
    local src = source
    if not isStaff(src) then return end
    local r = findById(id)
    if not r then return end
    local ped = GetPlayerPed(r.src)
    if not ped or ped == 0 then notify(src, 'Joueur hors-ligne.', 'err'); return end
    local c = GetEntityCoords(ped)
    TriggerClientEvent('vgc_reports:client:teleport', src, c.x, c.y, c.z)
end)

print(('^2[vgc_reports]^7 server charge — staff ACE="%s"'):format(Config.StaffAce))
