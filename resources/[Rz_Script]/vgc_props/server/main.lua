-- ============================================================
--  VGC PROPS  |  server/main.lua
--  Persistance des props dans props.json (sans DB)
-- ============================================================

local RES  = GetCurrentResourceName()
local FILE = 'props.json'

-- props = liste de { id, label, model, x, y, z, h }
local props  = {}
local nextId = 1

local function dbg(msg)
    if Config.Debug then print(('^3[vgc_props]^7 (server) %s'):format(msg)) end
end

-- ── Disque ────────────────────────────────────────────────
local function loadFromDisk()
    local raw = LoadResourceFile(RES, FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' and type(data.props) == 'table' then
            props  = data.props
            nextId = data.nextId or (#props + 1)
            dbg(('props.json charge (%d props)'):format(#props))
            return
        end
        dbg('^1props.json illisible — on repart vide.')
    end
    props, nextId = {}, 1
end

local function saveToDisk()
    local ok = SaveResourceFile(RES, FILE, json.encode({ props = props, nextId = nextId }), -1)
    if not ok then dbg('^1Echec ecriture props.json (droits du dossier ?)') end
    return ok
end

loadFromDisk()

local function canEdit(src)
    if not Config.AdminOnly then return true end
    return IsPlayerAceAllowed(src, 'vgc.props')
end

local function broadcast()
    TriggerClientEvent('vgc_props:client:sync', -1, props)
end

-- ── Index par id ──────────────────────────────────────────
local function indexById(id)
    for i, p in ipairs(props) do if p.id == id then return i end end
    return nil
end

-- ── Events ────────────────────────────────────────────────

-- Un client demande la liste (au chargement)
RegisterNetEvent('vgc_props:server:request', function()
    TriggerClientEvent('vgc_props:client:sync', source, props)
end)

-- Ajout d'un prop place
RegisterNetEvent('vgc_props:server:add', function(data)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('vgc_props:client:error', src, 'Permission refusee.')
        return
    end
    if type(data) ~= 'table' or type(data.model) ~= 'string' then return end
    local p = {
        id    = nextId,
        label = type(data.label) == 'string' and data.label ~= '' and data.label or ('Prop ' .. nextId),
        model = data.model,
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        h = tonumber(data.h) or 0.0,
    }
    nextId = nextId + 1
    props[#props + 1] = p
    saveToDisk()
    dbg(('prop ajoute : [%d] "%s" (%s)'):format(p.id, p.label, p.model))
    broadcast()
    TriggerClientEvent('vgc_props:client:added', src, p)
end)

-- Renommage
RegisterNetEvent('vgc_props:server:rename', function(id, label)
    local src = source
    if not canEdit(src) then return end
    local i = indexById(id)
    if i and type(label) == 'string' and label ~= '' then
        props[i].label = label
        saveToDisk()
        broadcast()
    end
end)

-- Suppression
RegisterNetEvent('vgc_props:server:delete', function(id)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('vgc_props:client:error', src, 'Permission refusee.')
        return
    end
    local i = indexById(id)
    if i then
        table.remove(props, i)
        saveToDisk()
        dbg(('prop supprime : [%s]'):format(tostring(id)))
        broadcast()
    end
end)

print('^2[vgc_props]^7 server charge — props JSON (sans DB) prets')
