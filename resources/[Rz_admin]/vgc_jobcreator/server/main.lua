-- ============================================================
--  VGC JOB CREATOR  |  server/main.lua
--  Persistance des jobs dans jobs.json (SaveResourceFile)
--  Aucune base de donnees, aucun framework.
-- ============================================================

local RES  = GetCurrentResourceName()
local FILE = 'jobs.json'

-- jobs = { ["police"] = { label=..., grades={...}, vehicleSpawns={...}, blips={...}, boss={...}, stashes={...}, wardrobes={...} } }
local jobs = {}

local function dbg(msg)
    if Config.Debug then
        print(('^6[vgc_jobcreator]^7 (server) %s'):format(msg))
    end
end

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- ── Chargement / ecriture disque ──────────────────────────
local function loadFromDisk()
    local raw = LoadResourceFile(RES, FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            jobs = data
            dbg(('jobs.json charge (%d jobs)'):format(count(jobs)))
            return
        end
        dbg('^1jobs.json illisible — on repart d\'un fichier vide.')
    end
    jobs = {}
end

local function saveToDisk()
    local ok = SaveResourceFile(RES, FILE, json.encode(jobs), -1)
    if not ok then
        dbg('^1Echec d\'ecriture de jobs.json (droits du dossier ?)')
    end
    return ok
end

loadFromDisk()

-- ── Permission ────────────────────────────────────────────
local function canEdit(src)
    if not Config.AdminOnly then return true end
    return IsPlayerAceAllowed(src, 'vgc.jobcreator')
end

-- ── Nettoyage / validation d'un job recu du client ────────
-- On ne garde que des types attendus (anti-injection de structures).
local function num(v, default) return type(v) == 'number' and v or (default or 0) end
local function str(v, default) return type(v) == 'string' and v or (default or '') end

local function sanitizeCoords(c)
    if type(c) ~= 'table' then return nil end
    return { x = num(c.x), y = num(c.y), z = num(c.z), h = num(c.h) }
end

local function sanitizeJob(raw)
    if type(raw) ~= 'table' then return nil end
    local j = {
        label    = str(raw.label, 'Sans nom'),
        grades   = {},
        vehicleSpawns = {},
        blips    = {},
        stashes  = {},
        wardrobes = {},
        boss     = nil,
    }

    -- Grades : { [niveau] = { name, salary, isBoss } }
    if type(raw.grades) == 'table' then
        for k, g in pairs(raw.grades) do
            if type(g) == 'table' then
                j.grades[tostring(k)] = {
                    name   = str(g.name, 'Grade'),
                    salary = num(g.salary, 0),
                    isBoss = g.isBoss == true,
                }
            end
        end
    end

    -- Spawns vehicules
    if type(raw.vehicleSpawns) == 'table' then
        for _, s in ipairs(raw.vehicleSpawns) do
            if type(s) == 'table' and s.coords then
                local vehicles = {}
                if type(s.vehicles) == 'table' then
                    for _, v in ipairs(s.vehicles) do
                        if type(v) == 'string' and v ~= '' then vehicles[#vehicles+1] = v end
                    end
                end
                j.vehicleSpawns[#j.vehicleSpawns+1] = {
                    label    = str(s.label, 'Spawn'),
                    coords   = sanitizeCoords(s.coords),
                    vehicles = vehicles,
                }
            end
        end
    end

    -- Blips
    if type(raw.blips) == 'table' then
        for _, b in ipairs(raw.blips) do
            if type(b) == 'table' and b.coords then
                j.blips[#j.blips+1] = {
                    label  = str(b.label, 'Blip'),
                    coords = sanitizeCoords(b.coords),
                    sprite = math.floor(num(b.sprite, 1)),
                    color  = math.floor(num(b.color, 0)),
                    scale  = num(b.scale, 0.8),
                }
            end
        end
    end

    -- Stashes
    if type(raw.stashes) == 'table' then
        for _, s in ipairs(raw.stashes) do
            if type(s) == 'table' and s.coords then
                j.stashes[#j.stashes+1] = {
                    label  = str(s.label, 'Coffre'),
                    coords = sanitizeCoords(s.coords),
                    slots  = math.floor(num(s.slots, 50)),
                    weight = math.floor(num(s.weight, 100000)),
                }
            end
        end
    end

    -- Vestiaires
    if type(raw.wardrobes) == 'table' then
        for _, w in ipairs(raw.wardrobes) do
            if type(w) == 'table' and w.coords then
                j.wardrobes[#j.wardrobes+1] = {
                    label  = str(w.label, 'Vestiaire'),
                    coords = sanitizeCoords(w.coords),
                }
            end
        end
    end

    -- Boss menu (point unique)
    if type(raw.boss) == 'table' and raw.boss.coords then
        j.boss = {
            label  = str(raw.boss.label, 'Boss'),
            coords = sanitizeCoords(raw.boss.coords),
        }
    end

    return j
end

-- Nom de job valide : minuscules/chiffres/underscore
local function validJobName(name)
    return type(name) == 'string' and name:match('^[a-z0-9_]+$') ~= nil and #name <= 30
end

-- ── Events ────────────────────────────────────────────────

RegisterNetEvent('vgc_jobcreator:server:list', function()
    local src = source
    TriggerClientEvent('vgc_jobcreator:client:jobsList', src, jobs)
end)

RegisterNetEvent('vgc_jobcreator:server:save', function(name, jobData)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('vgc_jobcreator:client:error', src, 'Permission refusee.')
        return
    end
    if not validJobName(name) then
        TriggerClientEvent('vgc_jobcreator:client:error', src, 'Nom de job invalide (a-z, 0-9, _).')
        return
    end
    local clean = sanitizeJob(jobData)
    if not clean then
        TriggerClientEvent('vgc_jobcreator:client:error', src, 'Donnees de job invalides.')
        return
    end
    jobs[name] = clean
    saveToDisk()
    dbg(('job sauve : "%s" (%d grades)'):format(name, count(clean.grades)))
    TriggerClientEvent('vgc_jobcreator:client:saved', src, name)
    TriggerClientEvent('vgc_jobcreator:client:jobsList', src, jobs)
end)

RegisterNetEvent('vgc_jobcreator:server:delete', function(name)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('vgc_jobcreator:client:error', src, 'Permission refusee.')
        return
    end
    if jobs[name] then
        jobs[name] = nil
        saveToDisk()
        dbg(('job supprime : "%s"'):format(tostring(name)))
    end
    TriggerClientEvent('vgc_jobcreator:client:deleted', src, name)
    TriggerClientEvent('vgc_jobcreator:client:jobsList', src, jobs)
end)

print('^2[vgc_jobcreator]^7 server/main.lua charge — jobs JSON (sans DB) prets')
