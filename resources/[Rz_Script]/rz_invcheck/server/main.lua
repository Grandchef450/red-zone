--[[
    rz_invcheck / server/main.lua

    Recherche un joueur par ID (s'il est connecté) ou par nom de
    personnage (connecté ou non), puis ouvre son inventaire.

    EN LIGNE : exports.ox_inventory:InspectInventory ouvre la vue à
    deux panneaux, exactement comme looter un corps — interactif, pas
    juste une lecture.

    HORS LIGNE : pas d'inventaire vivant à ouvrir. On relit la
    dernière sauvegarde dans la table `ox_inventory` et on affiche un
    instantané en lecture seule — impossible de faire autrement sans
    le joueur connecté.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_invcheck]^7', ...) end
end


---Nom complet d'un citizenid, depuis son charinfo en base.
local function nameFromCharinfo(charinfo)
    local ok, c = pcall(json.decode, charinfo or '{}')
    if not ok or not c then return 'Inconnu' end
    return ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
end


---La source d'un joueur EN LIGNE, si son citizenid correspond.
local function onlineSourceFor(citizenid)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local ok, player = pcall(function() return exports.qbx_core:GetPlayer(src) end)

        if ok and player and player.PlayerData and player.PlayerData.citizenid == citizenid then
            return src
        end
    end
    return nil
end


---Journal Discord : qui a inspecté qui.
local function logInspect(source, targetLabel, targetCitizenid, online)
    if GetResourceState('rz_logs') ~= 'started' then return end

    pcall(function()
        exports.rz_logs:Log('admin', {
            title  = 'Inventaire inspecté',
            source = source,
            fields = {
                { name = 'Joueur',  value = targetLabel },
                { name = 'Citizen', value = ('`%s`'):format(targetCitizenid) },
                { name = 'État',    value = online and 'En ligne (vue interactive)' or 'Hors ligne (lecture seule)' },
            },
        })
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  RECHERCHE
-- ═══════════════════════════════════════════════════════════════════

---@return table[] résultats : { citizenid, label, online, source? }
lib.callback.register('rz_invcheck:search', function(source, query)
    if not Config.HasAce(source) then return {} end

    query = type(query) == 'string' and query:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if query == '' then return {} end

    -- Un nombre pur qui correspond à un joueur connecté : on saute
    -- directement à un résultat unique, pas la peine de chercher en base.
    local asId = tonumber(query)
    if asId and GetPlayerName(asId) then
        local ok, player = pcall(function() return exports.qbx_core:GetPlayer(asId) end)

        if ok and player and player.PlayerData then
            return {{
                citizenid = player.PlayerData.citizenid,
                label     = ('%s [%d]'):format(GetPlayerName(asId), asId),
                online    = true,
                source    = asId,
            }}
        end
    end

    -- Recherche par nom de personnage, en base : le prénom/nom vit
    -- dans le JSON charinfo, pas dans la colonne `name` (qui ne
    -- reflète pas le personnage sur ce serveur).
    --
    -- ⚠️  LOWER() des deux côtés, explicitement : la collation de
    -- cette base est sensible à la casse (vérifié — un LIKE nu ne
    -- trouvait pas « Jean » en tapant « jean »). Sans ça, la moitié
    -- des recherches échouerait pour une simple différence de
    -- majuscule, sans le moindre message d'erreur.
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo
        FROM players
        WHERE LOWER(CONCAT_WS(' ',
                  JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')),
                  JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))
              )) LIKE CONCAT('%', LOWER(?), '%')
        LIMIT ?
    ]], { query, Config.MaxResults }) or {}

    local out = {}

    for _, row in ipairs(rows) do
        local onlineSource = onlineSourceFor(row.citizenid)

        out[#out + 1] = {
            citizenid = row.citizenid,
            label     = nameFromCharinfo(row.charinfo) .. (onlineSource and (' [%d]'):format(onlineSource) or ''),
            online    = onlineSource ~= nil,
            source    = onlineSource,
        }
    end

    return out
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE — JOUEUR EN LIGNE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_invcheck:inspectOnline', function(source, targetSource, label, citizenid)
    if not Config.HasAce(source) then return false, 'Permission refusée.' end

    targetSource = tonumber(targetSource)
    if not targetSource or not GetPlayerName(targetSource) then
        return false, 'Ce joueur n\'est plus connecté.'
    end

    local ok = pcall(function()
        exports.ox_inventory:InspectInventory(source, targetSource)
    end)

    if not ok then return false, 'Échec de l\'ouverture (ox_inventory).' end

    logInspect(source, label or GetPlayerName(targetSource), citizenid or '?', true)
    dbg(('%s inspecte l\'inventaire de %s'):format(GetPlayerName(source), GetPlayerName(targetSource)))

    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE — JOUEUR HORS LIGNE (instantané lecture seule)
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_invcheck:inspectOffline', function(source, citizenid, label)
    if not Config.HasAce(source) then return nil end
    if type(citizenid) ~= 'string' or citizenid == '' then return nil end

    local raw = MySQL.scalar.await('SELECT data FROM ox_inventory WHERE name = ?', { citizenid })
    if not raw then return { label = label, items = {}, empty = true } end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return { label = label, items = {}, empty = true } end

    local itemDefs = exports.ox_inventory:Items()
    local items = {}

    for _, entry in pairs(data) do
        if type(entry) == 'table' and entry.name and entry.count then
            local def = itemDefs and itemDefs[entry.name]
            items[#items + 1] = {
                name  = entry.name,
                label = def and def.label or entry.name,
                count = entry.count,
            }
        end
    end

    table.sort(items, function(a, b) return a.label < b.label end)

    logInspect(source, label or citizenid, citizenid, false)
    dbg(('%s consulte l\'instantané hors ligne de %s (%d items)')
        :format(GetPlayerName(source), citizenid, #items))

    return { label = label, items = items, empty = #items == 0 }
end)
