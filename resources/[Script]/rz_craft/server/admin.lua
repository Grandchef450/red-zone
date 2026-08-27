--[[
    rz_craft / server/admin.lua
    Créateur de craft : écriture en base depuis le menu admin.

    RÈGLE : chaque callback revérifie la permission ACE. Le fait que
    le bouton n'apparaisse pas dans l'interface n'est PAS une sécurité
    — un joueur peut déclencher un callback à la main. La seule
    barrière qui compte est celle-ci, côté serveur.
]]

---Droit d'édition : créer, modifier, supprimer.
local function canEdit(source)
    return Config.HasAce(source, Config.Ace.edit)
end

---Droit de consultation seule.
local function canView(source)
    return Config.HasAce(source, Config.Ace.view) or canEdit(source)
end

local function deny(source, permission)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(permission or Config.Ace.edit),
    })
    return false
end


---Recharge le cache et fait reconstruire le monde chez tous les joueurs.
local function refreshAll()
    LoadAll()
    TriggerClientEvent('rz_craft:rebuildWorld', -1)
end


-- ═══════════════════════════════════════════════════════════════════
--  DROIT D'ACCÈS
--  Interrogé par le client avant d'afficher quoi que ce soit.
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:getPermissions', function(source)
    return {
        edit = canEdit(source),
        view = canView(source),
        mail = Config.HasAce(source, Config.Ace.mail),
    }
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTABLIS
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:admin:createTable', function(source, data)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    local id = MySQL.insert.await([[
        INSERT INTO rz_craft_tables
            (label, tier, x, y, z, heading, prop_model,
             blip_sprite, blip_color, in_safezone, safezone_id, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.label, data.tier or 1,
        data.x, data.y, data.z, data.heading,
        data.prop_model,
        data.blip_sprite, data.blip_color,
        data.in_safezone and 1 or 0, data.safezone_id,
        GetPlayerIdentifier(source, 0),
    })

    LogAction(GetCharId(source) or 0, 'admin_create_table',
        { id = id, label = data.label })

    refreshAll()
    return id
end)


lib.callback.register('rz_craft:admin:updateTable', function(source, id, data)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    MySQL.prepare.await([[
        UPDATE rz_craft_tables
        SET label = ?, tier = ?, x = ?, y = ?, z = ?, heading = ?,
            prop_model = ?, in_safezone = ?, safezone_id = ?
        WHERE id = ?
    ]], {
        data.label, data.tier,
        data.x, data.y, data.z, data.heading,
        data.prop_model,
        data.in_safezone and 1 or 0, data.safezone_id,
        id,
    })

    LogAction(GetCharId(source) or 0, 'admin_update_table', { id = id })
    refreshAll()
    return true
end)


lib.callback.register('rz_craft:admin:deleteTable', function(source, id)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    -- ON DELETE CASCADE nettoie rz_craft_table_recipes tout seul.
    MySQL.prepare.await('DELETE FROM rz_craft_tables WHERE id = ?', { id })

    LogAction(GetCharId(source) or 0, 'admin_delete_table', { id = id })
    refreshAll()
    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  POINTS DE RETRAIT (facteurs)
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:admin:createMailPoint', function(source, data)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    local id = MySQL.insert.await([[
        INSERT INTO rz_mailbox_points
            (label, x, y, z, heading, ped_model, scenario,
             prop_model, blip_sprite, blip_color, safezone_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.label, data.x, data.y, data.z, data.heading,
        data.ped_model, data.scenario,
        data.prop_model, data.blip_sprite, data.blip_color,
        data.safezone_id,
    })

    LogAction(GetCharId(source) or 0, 'admin_create_mailpoint',
        { id = id, label = data.label })

    refreshAll()
    return id
end)


lib.callback.register('rz_craft:admin:deleteMailPoint', function(source, id)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    MySQL.prepare.await('DELETE FROM rz_mailbox_points WHERE id = ?', { id })
    LogAction(GetCharId(source) or 0, 'admin_delete_mailpoint', { id = id })
    refreshAll()
    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  RECETTES
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:admin:createRecipe', function(source, data)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    if not data.output_item or #(data.ingredients or {}) == 0 then
        return false, 'Recette incomplète.'
    end

    local recipeId = MySQL.insert.await([[
        INSERT INTO rz_craft_recipes
            (output_item, output_qty, category, required_level,
             xp_gain, craft_time, allow_capsules, max_capsule_ratio)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.output_item, data.output_qty or 1,
        data.category, data.required_level or 0,
        data.xp_gain or 10,
        Config.GetCraftTime(data.required_level or 0),
        data.allow_capsules and 1 or 0,
        data.max_capsule_ratio or 50,
    })

    for _, ing in ipairs(data.ingredients) do
        MySQL.prepare.await(
            'INSERT INTO rz_craft_ingredients (recipe_id, item, qty) VALUES (?, ?, ?)',
            { recipeId, ing.item, ing.qty })
    end

    -- Rattachement immédiat aux établis choisis
    for _, tableId in ipairs(data.tables or {}) do
        MySQL.prepare.await(
            'INSERT IGNORE INTO rz_craft_table_recipes (table_id, recipe_id) VALUES (?, ?)',
            { tableId, recipeId })
    end

    LogAction(GetCharId(source) or 0, 'admin_create_recipe',
        { id = recipeId, output = data.output_item })

    refreshAll()
    return recipeId
end)


lib.callback.register('rz_craft:admin:deleteRecipe', function(source, id)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    MySQL.prepare.await('DELETE FROM rz_craft_recipes WHERE id = ?', { id })
    LogAction(GetCharId(source) or 0, 'admin_delete_recipe', { id = id })
    refreshAll()
    return true
end)


---Attache ou détache une recette d'un établi.
lib.callback.register('rz_craft:admin:toggleRecipeOnTable', function(source, tableId, recipeId)
    if not canEdit(source) then return deny(source, Config.Ace.edit) end

    local existing = MySQL.single.await(
        'SELECT 1 AS ok FROM rz_craft_table_recipes WHERE table_id = ? AND recipe_id = ?',
        { tableId, recipeId })

    if existing then
        MySQL.prepare.await(
            'DELETE FROM rz_craft_table_recipes WHERE table_id = ? AND recipe_id = ?',
            { tableId, recipeId })
        refreshAll()
        return false   -- détaché
    end

    MySQL.prepare.await(
        'INSERT INTO rz_craft_table_recipes (table_id, recipe_id) VALUES (?, ?)',
        { tableId, recipeId })
    refreshAll()
    return true        -- attaché
end)


-- ═══════════════════════════════════════════════════════════════════
--  LISTES POUR LES MENUS
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:admin:getLists', function(source)
    if not isAdmin(source) then return end

    local tables, recipes, points = {}, {}, {}

    for id, t in pairs(Cache.tables) do
        tables[#tables + 1] = {
            id = id, label = t.label, tier = t.tier,
            x = t.x, y = t.y, z = t.z,
            recipeCount = #(Cache.tableRecipes[id] or {}),
        }
    end

    for id, r in pairs(Cache.recipes) do
        recipes[#recipes + 1] = {
            id = id, output = r.output_item, qty = r.output_qty,
            category = r.category, level = r.required_level,
            ingredients = r.ingredients,
        }
    end

    for id, p in pairs(Cache.mailPoints) do
        points[#points + 1] = {
            id = id, label = p.label, x = p.x, y = p.y, z = p.z,
        }
    end

    table.sort(tables,  function(a, b) return a.label < b.label end)
    table.sort(recipes, function(a, b) return a.output < b.output end)

    return { tables = tables, recipes = recipes, mailPoints = points }
end)


---Liste des items connus, pour les menus déroulants du créateur.
lib.callback.register('rz_craft:admin:getItems', function(source)
    if not isAdmin(source) then return {} end

    local items = {}
    for name, data in pairs(exports.ox_inventory:Items()) do
        items[#items + 1] = { value = name, label = data.label or name }
    end

    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end)


---Recettes rattachées à un établi donné.
lib.callback.register('rz_craft:admin:getTableRecipeIds', function(source, tableId)
    if not isAdmin(source) then return {} end

    local set = {}
    for _, id in ipairs(Cache.tableRecipes[tableId] or {}) do
        set[id] = true
    end
    return set
end)
