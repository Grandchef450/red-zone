--[[
    rz_epaves / server/main.lua

    Fouille des épaves de décor.

    POURQUOI CE SCRIPT EXISTE
    Les épaves de la map Apocalypse_Mapping sont des PROPS, pas des
    véhicules. Elles n'ont ni coffre ni boîte à gants, donc la table
    inventory:vehicleloot d'ox_inventory ne peut pas s'y appliquer.
    On leur greffe donc un contenant à nous.

    IDENTIFICATION PAR POSITION
    Un prop de map se recharge en permanence et change d'identifiant
    réseau à chaque fois. Impossible de s'y fier. On identifie donc
    chaque épave par ses COORDONNÉES arrondies, qui elles ne bougent
    jamais. Deux joueurs qui fouillent la même carcasse tombent sur
    le même contenant, et ce qui a été pris reste pris.
]]

-- [stashId] = horodatage du dernier remplissage
local filled = {}

-- ═══════════════════════════════════════════════════════════════════
--  RÉGLAGES VIVANTS
--
--  Le config.lua ne sert plus que de valeurs par défaut, utilisées
--  au tout premier démarrage pour amorcer la base. Ensuite c'est la
--  base qui fait foi, et le menu admin la modifie à chaud.
-- ═══════════════════════════════════════════════════════════════════
Runtime = {
    drawsMin           = Config.Loot.draws.min,
    drawsMax           = Config.Loot.draws.max,
    quantityMultiplier = 1.0,
    respawnMinutes     = Config.Respawn.minutes,
    searchDuration     = Config.Search.duration,
    enabled            = true,
    loot               = {},   -- { item, min, max, chance }
}

local function dbg(...)
    if Config.Debug then print('^3[rz_epaves]^7', ...) end
end


---Identifiant stable d'une épave, dérivé de sa position.
---@param coords vector3
---@return string
local function stashIdFromCoords(coords)
    local g = Config.Respawn.gridSize

    return ('rzepave_%d_%d_%d'):format(
        math.floor(coords.x / g),
        math.floor(coords.y / g),
        math.floor(coords.z / g)
    )
end


---Tire une fournée de butin.
---@return table liste de { item, count }
local function rollLoot()
    local pool = Runtime.loot
    local size = #pool

    if size == 0 then return {} end

    local draws = math.random(Runtime.drawsMin, Runtime.drawsMax)

    local picked, result = {}, {}

    for _ = 1, draws do
        if #result >= size then break end

        -- Tirage sans remise : un même item ne sort pas deux fois
        local attempts = 0
        local index

        repeat
            index = math.random(1, size)
            attempts = attempts + 1
        until not picked[index] or attempts > 20

        if not picked[index] then
            picked[index] = true

            local entry = pool[index]

            if math.random(1, 100) <= entry.chance then
                local count = math.random(entry.min, entry.max)
                count = math.floor(count * Runtime.quantityMultiplier + 0.5)

                if count > 0 then
                    result[#result + 1] = { item = entry.item, count = count }
                end
            end
        end
    end

    return result
end


---Remplit une épave de butin frais.
local function fillWreck(stashId, coords)
    exports.ox_inventory:RegisterStash(
        stashId,
        'Épave',
        Config.Search.slots,
        Config.Search.maxWeight,
        false,          -- owner : false = accessible à tous
        nil,            -- groups
        coords
    )

    -- Vide ce qui restait du passage précédent avant de regarnir
    exports.ox_inventory:ClearInventory(stashId)

    local loot = rollLoot()

    for _, entry in ipairs(loot) do
        exports.ox_inventory:AddItem(stashId, entry.item, entry.count)
    end

    filled[stashId] = os.time()

    dbg(('%s regarni : %d pile(s)'):format(stashId, #loot))
end


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_epaves:search', function(source, coords)
    if not Runtime.enabled then return false end

    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then
        return false
    end

    local pos = vec3(coords.x, coords.y, coords.z)

    -- Le client annonce une position : on la vérifie contre la sienne.
    -- Sans ce test, un client modifié fouillerait la carte entière
    -- depuis son canapé.
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local dist = #(GetEntityCoords(ped) - pos)
    if dist > (Config.Search.distance + 2.0) then
        dbg(('%s trop loin : %.1f m'):format(source, dist))
        return false
    end

    local stashId = stashIdFromCoords(pos)
    local last = filled[stashId]
    local delay = Runtime.respawnMinutes * 60

    -- Jamais fouillée, ou délai écoulé : on regarnit
    if not last or (os.time() - last) >= delay then
        fillWreck(stashId, pos)
    else
        -- Déjà fouillée récemment : on ouvre en l'état. Un autre
        -- joueur peut y trouver ce que le premier a laissé.
        exports.ox_inventory:RegisterStash(
            stashId, 'Épave',
            Config.Search.slots, Config.Search.maxWeight,
            false, nil, pos
        )
    end

    return stashId
end)


-- ═══════════════════════════════════════════════════════════════════
--  ENTRETIEN
--
--  On libère de la mémoire les épaves dont le délai est écoulé et
--  qui ne sont pas ouvertes. Sans ça, une longue session finirait
--  par garder des milliers de contenants inutiles.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(300000)   -- 5 minutes

        local now = os.time()
        local delay = Runtime.respawnMinutes * 60
        local removed = 0

        for stashId, at in pairs(filled) do
            -- On garde une marge : libérer pile à l'échéance ferait
            -- perdre le butin d'un joueur en train de fouiller.
            if (now - at) >= (delay * 2) then
                pcall(function()
                    exports.ox_inventory:RemoveInventory(stashId)
                end)
                filled[stashId] = nil
                removed = removed + 1
            end
        end

        if removed > 0 then
            dbg(('%d épave(s) libérée(s) de la mémoire'):format(removed))
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DIAGNOSTIC
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('epaveinfo', {
    help = 'Épaves fouillées et temps avant régénération',
    restricted = Config.Ace,
}, function(source)
    local now = os.time()
    local delay = Runtime.respawnMinutes * 60
    local total, ready = 0, 0

    for _, at in pairs(filled) do
        total = total + 1
        if (now - at) >= delay then ready = ready + 1 end
    end

    TriggerClientEvent('ox_lib:notify', source, {
        type        = 'inform',
        title       = 'Épaves',
        description = ('%d fouillée(s) en mémoire, %d régénérable(s).')
            :format(total, ready),
        duration    = 8000,
    })
end)


-- ═══════════════════════════════════════════════════════════════════
--  CHARGEMENT DES RÉGLAGES
-- ═══════════════════════════════════════════════════════════════════

function LoadSettings()
    local rows = MySQL.query.await('SELECT setting, value FROM rz_epave_settings') or {}

    for _, r in ipairs(rows) do
        local n = tonumber(r.value)

        if r.setting == 'drawsMin'           then Runtime.drawsMin = n or Runtime.drawsMin
        elseif r.setting == 'drawsMax'       then Runtime.drawsMax = n or Runtime.drawsMax
        elseif r.setting == 'quantityMult'   then Runtime.quantityMultiplier = n or 1.0
        elseif r.setting == 'respawnMinutes' then Runtime.respawnMinutes = n or Runtime.respawnMinutes
        elseif r.setting == 'searchDuration' then Runtime.searchDuration = n or Runtime.searchDuration
        elseif r.setting == 'enabled'        then Runtime.enabled = (r.value == '1')
        end
    end

    local loot = MySQL.query.await(
        'SELECT item, min_count, max_count, chance FROM rz_epave_loot WHERE enabled = 1') or {}

    Runtime.loot = {}
    for _, r in ipairs(loot) do
        Runtime.loot[#Runtime.loot + 1] = {
            item   = r.item,
            min    = r.min_count,
            max    = r.max_count,
            chance = r.chance,
        }
    end

    dbg(('réglages chargés : %d item(s), tirage %d-%d, ×%.2f, respawn %d min')
        :format(#Runtime.loot, Runtime.drawsMin, Runtime.drawsMax,
                Runtime.quantityMultiplier, Runtime.respawnMinutes))
end

exports('ReloadSettings', LoadSettings)
exports('GetRuntime', function() return Runtime end)


---Premier démarrage : on amorce la base avec le config.lua.
local function seedFromConfig()
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM rz_epave_loot')
    if existing and existing > 0 then return end

    for _, e in ipairs(Config.Loot.items) do
        MySQL.prepare.await([[
            INSERT IGNORE INTO rz_epave_loot (item, min_count, max_count, chance)
            VALUES (?, ?, ?, ?)
        ]], { e[1], e[2], e[3], e[4] or 50 })
    end

    local defaults = {
        drawsMin       = Config.Loot.draws.min,
        drawsMax       = Config.Loot.draws.max,
        quantityMult   = 1.0,
        respawnMinutes = Config.Respawn.minutes,
        searchDuration = Config.Search.duration,
        enabled        = 1,
    }

    for k, v in pairs(defaults) do
        MySQL.prepare.await(
            'INSERT IGNORE INTO rz_epave_settings (setting, value) VALUES (?, ?)',
            { k, tostring(v) })
    end

    print(('^2[rz_epaves]^7 base amorcée avec %d item(s) depuis config.lua')
        :format(#Config.Loot.items))
end


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(1000)
    seedFromConfig()
    LoadSettings()
end)
