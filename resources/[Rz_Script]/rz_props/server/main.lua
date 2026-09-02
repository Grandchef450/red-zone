-- ============================================================
--  RZ PROPS  |  server/main.lua
--  Persistance des props dans props.json (sans DB)
-- ============================================================

local RES  = GetCurrentResourceName()
local FILE = 'props.json'
local PRESETS_FILE = 'presets.json'

-- props = liste de { id, label, model, x, y, z, h }
local props  = {}
local nextId = 1

-- raccourcis ajoutes a la main, en plus de Config.PropPresets.
-- customPresets = liste de { model, label, addedBy }
local customPresets = {}

local function dbg(msg)
    if Config.Debug then print(('^3[rz_props]^7 (server) %s'):format(msg)) end
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

-- ── Raccourcis personnalises ──────────────────────────────
-- Meme principe que props.json : un fichier a cote du script,
-- pas une table MySQL. rz_props n'a jamais eu de dependance DB,
-- pas de raison d'en ajouter une pour un simple raccourci nom+modele.
local function loadPresetsFromDisk()
    local raw = LoadResourceFile(RES, PRESETS_FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            customPresets = data
            dbg(('presets.json charge (%d raccourcis)'):format(#customPresets))
            return
        end
        dbg('^1presets.json illisible — on repart vide.')
    end
    customPresets = {}
end

local function savePresetsToDisk()
    local ok = SaveResourceFile(RES, PRESETS_FILE, json.encode(customPresets), -1)
    if not ok then dbg('^1Echec ecriture presets.json (droits du dossier ?)') end
    return ok
end

loadPresetsFromDisk()

---Liste complete envoyee au client : les presets du config.lua
---d'abord, puis ceux ajoutes a la main.
local function allPresets()
    local out = {}
    for _, p in ipairs(Config.PropPresets) do
        out[#out + 1] = { model = p.model, label = p.label, builtin = true }
    end
    for _, p in ipairs(customPresets) do
        out[#out + 1] = { model = p.model, label = p.label, builtin = false }
    end
    return out
end

local function canEdit(src)
    if not Config.AdminOnly then return true end
    return IsPlayerAceAllowed(src, 'rz.props')
end

local function broadcast()
    TriggerClientEvent('rz_props:client:sync', -1, props)
end

local function broadcastPresets()
    TriggerClientEvent('rz_props:client:presets', -1, allPresets())
end

-- ── Index par id ──────────────────────────────────────────
local function indexById(id)
    for i, p in ipairs(props) do if p.id == id then return i end end
    return nil
end

-- ── Events ────────────────────────────────────────────────

-- Un client demande la liste (au chargement)
RegisterNetEvent('rz_props:server:request', function()
    TriggerClientEvent('rz_props:client:sync', source, props)
    TriggerClientEvent('rz_props:client:presets', source, allPresets())
end)


-- Ajout d'un raccourci (modele + nom), a la main depuis le panneau.
-- Persiste dans presets.json : survit aux redemarrages, sans toucher
-- a config.lua ni a une base de donnees.
RegisterNetEvent('rz_props:server:addPreset', function(data)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('rz_props:client:error', src, 'Permission refusee.')
        return
    end

    if type(data) ~= 'table' or type(data.model) ~= 'string' or data.model == '' then
        TriggerClientEvent('rz_props:client:error', src, 'Modele manquant.')
        return
    end

    local model = data.model:gsub('%s+', '')
    local label = (type(data.label) == 'string' and data.label ~= '') and data.label or model

    -- Pas de doublon : un modele deja present (raccourci de base ou
    -- deja ajoute a la main) se met juste a jour au lieu de dupliquer.
    for _, p in ipairs(customPresets) do
        if p.model == model then
            p.label = label
            savePresetsToDisk()
            broadcastPresets()
            return
        end
    end

    customPresets[#customPresets + 1] = {
        model   = model,
        label   = label,
        addedBy = GetPlayerName(src) or tostring(src),
    }

    savePresetsToDisk()
    dbg(('raccourci ajoute : "%s" (%s) par %s'):format(label, model, GetPlayerName(src) or src))
    broadcastPresets()
end)


-- Suppression d'un raccourci ajoute a la main. Les presets de
-- config.lua ne se suppriment pas d'ici — il faut editer le fichier.
RegisterNetEvent('rz_props:server:deletePreset', function(model)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('rz_props:client:error', src, 'Permission refusee.')
        return
    end

    for i, p in ipairs(customPresets) do
        if p.model == model then
            table.remove(customPresets, i)
            savePresetsToDisk()
            dbg(('raccourci supprime : %s'):format(model))
            broadcastPresets()
            return
        end
    end
end)

-- Ajout d'un prop place
RegisterNetEvent('rz_props:server:add', function(data)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('rz_props:client:error', src, 'Permission refusee.')
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
    TriggerClientEvent('rz_props:client:added', src, p)
end)

-- Renommage
RegisterNetEvent('rz_props:server:rename', function(id, label)
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
RegisterNetEvent('rz_props:server:delete', function(id)
    local src = source
    if not canEdit(src) then
        TriggerClientEvent('rz_props:client:error', src, 'Permission refusee.')
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

print('^2[rz_props]^7 server charge — props JSON (sans DB) prets')
