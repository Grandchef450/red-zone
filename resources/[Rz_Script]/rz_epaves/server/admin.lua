--[[
    rz_epaves / server/admin.lua
    Réglage du butin depuis le menu admin, sans redémarrage.
]]

local function canEdit(source)
    return IsPlayerAceAllowed(source, Config.Ace)
        or IsPlayerAceAllowed(source, 'rz_epaves.admin')
end

local function deny(source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(Config.Ace),
    })
    return false
end

local function logAction(source, action, detail)
    MySQL.prepare('INSERT INTO rz_epave_logs (admin, action, detail) VALUES (?, ?, ?)', {
        GetPlayerIdentifierByType(source, 'license'),
        action,
        json.encode(detail or {}),
    })
end


lib.callback.register('rz_epaves:isAdmin', function(source)
    return canEdit(source)
end)


-- ═══════════════════════════════════════════════════════════════════
--  LECTURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_epaves:getSettings', function(source)
    if not canEdit(source) then return end

    local loot = MySQL.query.await([[
        SELECT item, min_count, max_count, chance, enabled
        FROM rz_epave_loot
        ORDER BY chance DESC, item ASC
    ]]) or {}

    -- Le libellé lisible vient d'ox_inventory, pas de notre base :
    -- ça évite de dupliquer une information qui existe déjà.
    local items = exports.ox_inventory:Items()

    for _, r in ipairs(loot) do
        r.label = items[r.item] and items[r.item].label or r.item
        r.enabled = r.enabled == 1
    end

    return {
        drawsMin       = Runtime.drawsMin,
        drawsMax       = Runtime.drawsMax,
        quantityMult   = Runtime.quantityMultiplier,
        respawnMinutes = Runtime.respawnMinutes,
        enabled        = Runtime.enabled,
        loot           = loot,
    }
end)


---Liste des items du serveur, pour ajouter une entrée au butin.
lib.callback.register('rz_epaves:getAllItems', function(source)
    if not canEdit(source) then return {} end

    local existing = {}
    for _, e in ipairs(Runtime.loot) do existing[e.item] = true end

    local out = {}

    for name, data in pairs(exports.ox_inventory:Items()) do
        -- On masque les armes : elles n'ont rien à faire dans une
        -- épave, et elles noieraient la liste de choix.
        if not existing[name] and not name:find('^WEAPON_') and not name:find('^ammo') then
            out[#out + 1] = { value = name, label = data.label or name }
        end
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉCRITURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_epaves:setSettings', function(source, data)
    if not canEdit(source) then return deny(source) end

    local minD = math.max(0, math.min(10, tonumber(data.drawsMin) or 1))
    local maxD = math.max(minD, math.min(10, tonumber(data.drawsMax) or 4))
    local mult = math.max(0.1, math.min(10.0, tonumber(data.quantityMult) or 1.0))
    local resp = math.max(1, math.min(1440, tonumber(data.respawnMinutes) or 45))

    local values = {
        drawsMin       = minD,
        drawsMax       = maxD,
        quantityMult   = mult,
        respawnMinutes = resp,
        enabled        = data.enabled and 1 or 0,
    }

    for k, v in pairs(values) do
        MySQL.prepare.await([[
            INSERT INTO rz_epave_settings (setting, value, updated_by)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)
        ]], { k, tostring(v), GetPlayerIdentifierByType(source, 'license') })
    end

    logAction(source, 'settings', values)
    LoadSettings()

    return true
end)


lib.callback.register('rz_epaves:setLootEntry', function(source, item, min, max, chance, enabled)
    if not canEdit(source) then return deny(source) end

    if not exports.ox_inventory:Items(item) then
        return false, ('L\'item « %s » n\'existe pas.'):format(item)
    end

    min = math.max(1, math.min(999, tonumber(min) or 1))
    max = math.max(min, math.min(999, tonumber(max) or min))
    chance = math.max(1, math.min(100, tonumber(chance) or 50))

    MySQL.prepare.await([[
        INSERT INTO rz_epave_loot (item, min_count, max_count, chance, enabled, updated_by)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            min_count = VALUES(min_count),
            max_count = VALUES(max_count),
            chance    = VALUES(chance),
            enabled   = VALUES(enabled),
            updated_by = VALUES(updated_by)
    ]], { item, min, max, chance, enabled and 1 or 0,
          GetPlayerIdentifierByType(source, 'license') })

    logAction(source, 'loot_set',
        { item = item, min = min, max = max, chance = chance, enabled = enabled })

    LoadSettings()
    return true, ('%s : %d-%d à %d %%'):format(item, min, max, chance)
end)


lib.callback.register('rz_epaves:removeLootEntry', function(source, item)
    if not canEdit(source) then return deny(source) end

    MySQL.prepare.await('DELETE FROM rz_epave_loot WHERE item = ?', { item })
    logAction(source, 'loot_remove', { item = item })
    LoadSettings()

    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  SIMULATION
--
--  Le calcul est peu intuitif : un item à 70 % de chance n'apparaît
--  pas dans 70 % des épaves, puisqu'il doit d'abord être tiré parmi
--  tous les autres. Cette simulation donne le vrai chiffre, celui
--  que les joueurs vivront.
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_epaves:simulate', function(source, runs)
    if not canEdit(source) then return end

    runs = math.max(100, math.min(20000, tonumber(runs) or 5000))

    local totals, appears = {}, {}
    local emptyCount = 0

    for _ = 1, runs do
        local pool = Runtime.loot
        local size = #pool

        if size > 0 then
            local draws = math.random(Runtime.drawsMin, Runtime.drawsMax)
            local picked = {}
            local got = 0

            for _ = 1, draws do
                local index, attempts = nil, 0

                repeat
                    index = math.random(1, size)
                    attempts = attempts + 1
                until not picked[index] or attempts > 20

                if not picked[index] then
                    picked[index] = true
                    local e = pool[index]

                    if math.random(1, 100) <= e.chance then
                        local count = math.floor(
                            math.random(e.min, e.max) * Runtime.quantityMultiplier + 0.5)

                        if count > 0 then
                            totals[e.item] = (totals[e.item] or 0) + count
                            appears[e.item] = (appears[e.item] or 0) + 1
                            got = got + 1
                        end
                    end
                end
            end

            if got == 0 then emptyCount = emptyCount + 1 end
        end
    end

    local result = {}
    for item, n in pairs(appears) do
        result[#result + 1] = {
            item     = item,
            rate     = n / runs * 100,               -- % d'épaves contenant l'item
            perWreck = totals[item] / runs,          -- quantité moyenne par épave
        }
    end

    table.sort(result, function(a, b) return a.rate > b.rate end)

    return {
        runs       = runs,
        emptyRate  = emptyCount / runs * 100,
        items      = result,
    }
end)
