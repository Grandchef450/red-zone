--[[
    rz_craft / server/main.lua
    Chargement des données en mémoire au démarrage.

    Principe : la base n'est lue qu'UNE fois. Tout le jeu tourne
    ensuite sur le cache. Les écritures (édition admin) mettent à
    jour la base ET le cache, sans redémarrage.
]]

Cache = {
    recipes      = {},   -- [recipe_id]  = { ..., ingredients = { {item, qty}, ... } }
    tables       = {},   -- [table_id]   = { ... }
    tableRecipes = {},   -- [table_id]   = { recipe_id, ... }
    itemValues   = {},   -- [item]       = valeur en capsules
    mailPoints   = {},   -- [point_id]   = { ... }
}

local function dbg(...)
    if Config.Debug then print('^3[rz_craft]^7', ...) end
end

---Recharge tout depuis la base.
function LoadAll()
    -- Recettes
    Cache.recipes = {}
    local recipes = MySQL.query.await('SELECT * FROM rz_craft_recipes WHERE enabled = 1') or {}
    for _, r in ipairs(recipes) do
        r.ingredients = {}
        Cache.recipes[r.id] = r
    end

    -- Ingrédients rattachés
    local ings = MySQL.query.await('SELECT * FROM rz_craft_ingredients') or {}
    for _, ing in ipairs(ings) do
        local recipe = Cache.recipes[ing.recipe_id]
        if recipe then
            recipe.ingredients[#recipe.ingredients + 1] = { item = ing.item, qty = ing.qty }
        end
    end

    -- Établis
    Cache.tables = {}
    local tables = MySQL.query.await('SELECT * FROM rz_craft_tables') or {}
    for _, t in ipairs(tables) do
        Cache.tables[t.id] = t
    end

    -- Liaison établi <-> recettes
    Cache.tableRecipes = {}
    local links = MySQL.query.await('SELECT * FROM rz_craft_table_recipes') or {}
    for _, l in ipairs(links) do
        local list = Cache.tableRecipes[l.table_id]
        if not list then
            list = {}
            Cache.tableRecipes[l.table_id] = list
        end
        list[#list + 1] = l.recipe_id
    end

    -- Valeurs en capsules
    Cache.itemValues = {}
    local values = MySQL.query.await('SELECT * FROM rz_item_values') or {}
    for _, v in ipairs(values) do
        Cache.itemValues[v.item] = v.capsule_value
    end

    -- Points de retrait du courrier
    Cache.mailPoints = {}
    local points = MySQL.query.await('SELECT * FROM rz_mailbox_points') or {}
    for _, p in ipairs(points) do
        Cache.mailPoints[p.id] = p
    end

    dbg(('chargé : %d recettes, %d établis, %d valeurs, %d boîtes')
        :format(#recipes, #tables, #values, #points))
end


---Récupère le citizenid Qbox d'une source.
---C'est une CHAÎNE (ex. 'ABC12345'), pas un entier : les colonnes
---de la base sont en VARCHAR(50), pas en INT.
---@param source number
---@return string|nil
function GetCharId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end


---Progression d'un joueur dans une catégorie.
---@param citizenid number
---@param category string
---@return table { level, xp, total_crafted }
function GetProgress(citizenid, category)
    local row = MySQL.single.await(
        'SELECT level, xp, total_crafted FROM rz_player_crafting WHERE citizenid = ? AND category = ?',
        { citizenid, category }
    )
    return row or { level = 0, xp = 0, total_crafted = 0 }
end


---Ajoute de l'XP et recalcule le niveau.
---@param citizenid number
---@param category string
---@param amount number
---@return number newLevel, boolean leveledUp
function AddXp(citizenid, category, amount)
    local p        = GetProgress(citizenid, category)
    local newXp    = p.xp + amount
    local newLevel = Config.GetLevelFromXp(newXp)

    MySQL.prepare.await([[
        INSERT INTO rz_player_crafting (citizenid, category, level, xp, total_crafted)
        VALUES (?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE
            level = VALUES(level),
            xp = VALUES(xp),
            total_crafted = total_crafted + 1
    ]], { citizenid, category, newLevel, newXp })

    return newLevel, newLevel > p.level
end


---Écrit une ligne de journal.
---@param citizenid number
---@param action string
---@param detail table
function LogAction(citizenid, action, detail)
    MySQL.prepare('INSERT INTO rz_craft_logs (citizenid, action, detail) VALUES (?, ?, ?)',
        { citizenid, action, json.encode(detail or {}) })
end


-- ═══ DONNÉES ENVOYÉES AU CLIENT ════════════════════════════════════
-- Uniquement ce qui doit être affiché dans le monde : positions,
-- props, blips. Aucune recette, aucun coût — tout cela reste serveur
-- et n'est calculé qu'à l'ouverture d'un établi.

lib.callback.register('rz_craft:getWorldData', function(source)
    local tables, points = {}, {}

    for id, t in pairs(Cache.tables) do
        tables[#tables + 1] = {
            id = id, label = t.label, tier = t.tier,
            x = t.x, y = t.y, z = t.z, heading = t.heading,
            prop = t.prop_model,
            blipSprite = t.blip_sprite, blipColor = t.blip_color,
        }
    end

    for id, p in pairs(Cache.mailPoints) do
        points[#points + 1] = {
            id = id, label = p.label,
            x = p.x, y = p.y, z = p.z, heading = p.heading,
            ped = p.ped_model, scenario = p.scenario, frozen = p.ped_frozen == 1,
            prop = p.prop_model,
            blipSprite = p.blip_sprite, blipColor = p.blip_color,
        }
    end

    return { tables = tables, mailPoints = points }
end)


-- ═══ EXPORTS pour les autres ressources ════════════════════════════

exports('GetRecipe', function(id) return Cache.recipes[id] end)
exports('GetCraftTable', function(id) return Cache.tables[id] end)
exports('GetItemValue', function(item) return Cache.itemValues[item] or 0 end)
exports('ReloadCraftData', LoadAll)


-- ═══ DÉMARRAGE ═════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    LoadAll()

    -- Reprise après crash : toute session restée « en_cours » est
    -- orpheline, puisque les timers vivaient en mémoire.
    local orphans = MySQL.query.await(
        "SELECT * FROM rz_craft_sessions WHERE status = 'en_cours'") or {}

    for _, s in ipairs(orphans) do
        if s.capsules_paid > 0 then
            local recipe = Cache.recipes[s.recipe_id]
            local label  = recipe and recipe.output_item or 'craft inconnu'

            SendParcel(s.citizenid, {
                label    = ('Craft interrompu — %s'):format(label),
                reason   = 'craft_crash',
                contents = { { item = Config.Capsules.item, qty = s.capsules_paid } },
            })
        end

        MySQL.prepare("UPDATE rz_craft_sessions SET status = 'interrompu' WHERE id = ?", { s.id })
    end

    if #orphans > 0 then
        print(('^3[rz_craft]^7 %d session(s) orpheline(s) reprise(s) après redémarrage')
            :format(#orphans))
    end
end)


-- Sécurité : à l'arrêt de la ressource, on libère toutes les
-- réservations pour ne pas laisser d'items verrouillés à vie.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ClearAllReservations()
end)
