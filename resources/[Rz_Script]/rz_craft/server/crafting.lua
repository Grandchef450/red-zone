--[[
    rz_craft / server/crafting.lua
    Moteur de craft : validation, réservation, minuterie, complétion.

    RÈGLE DE SÉCURITÉ : rien de ce que le client envoie n'est cru.
    Le client dit « je veux crafter la recette 42 en x3 » et c'est
    tout. Le serveur relit la recette en base, recalcule le coût,
    la durée, vérifie l'inventaire et la distance. Un client modifié
    ne peut rien obtenir qu'il n'aurait pas obtenu honnêtement.
]]

-- Sessions actives en mémoire : [source] = { sessionId, ... }
local Sessions = {}

-- Réservations : [source] = { [item] = qtyRéservée }
local Reserved = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_craft]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  RÉSERVATION D'ITEMS
--
--  Les matériaux restent VISIBLES dans l'inventaire pendant le craft,
--  mais deviennent intransportables. C'est ce qui empêche la faille
--  classique : lancer un craft, donner ses matériaux à un ami,
--  et récupérer l'item sans rien payer.
-- ═══════════════════════════════════════════════════════════════════

---Quantité réservée d'un item pour un joueur.
local function getReserved(source, item)
    local r = Reserved[source]
    return r and r[item] or 0
end

local function reserve(source, ingredients, quantity)
    local r = {}
    for _, ing in ipairs(ingredients) do
        r[ing.item] = (r[ing.item] or 0) + (ing.qty * quantity)
    end
    Reserved[source] = r
    dbg(('réservation posée pour %s'):format(source))
end

local function release(source)
    Reserved[source] = nil
    dbg(('réservation libérée pour %s'):format(source))
end

function ClearAllReservations()
    Reserved = {}
end


-- Hook ox_inventory : refuse tout mouvement touchant un item réservé.
-- Couvre le déplacement, le dépôt au sol, le don à un joueur et le
-- rangement en coffre — tous passent par swapItems.
local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
    local src = payload.source

    if not Reserved[src] then return true end

    local item = payload.fromSlot and payload.fromSlot.name
    if not item then return true end

    local needed = Reserved[src][item]
    if not needed or needed <= 0 then return true end

    -- Combien il en resterait après le mouvement ?
    local total = exports.ox_inventory:GetItemCount(src, item)
    local moving = payload.count or 0

    if (total - moving) < needed then
        TriggerClientEvent('ox_lib:notify', src, {
            type        = 'error',
            title       = 'Matériau réservé',
            description = 'Cet item est en cours d\'utilisation par ton craft.',
        })
        return false
    end

    return true
end, {
    print = false,
})


-- ═══════════════════════════════════════════════════════════════════
--  CALCULS
-- ═══════════════════════════════════════════════════════════════════

---Ce qui manque au joueur, et ce que ça coûterait en capsules.
---@return table missing, number capsuleCost, boolean payable
local function computeMissing(source, recipe, quantity)
    local missing     = {}
    local capsuleCost = 0
    local totalValue  = 0
    local missingValue = 0

    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.qty * quantity
        local have   = exports.ox_inventory:GetItemCount(source, ing.item)
        local value  = Cache.itemValues[ing.item] or 0

        totalValue = totalValue + (value * needed)

        if have < needed then
            local lack = needed - have

            -- Un item sans valeur déclarée n'est pas substituable
            if value <= 0 then
                return nil, 0, false
            end

            missing[#missing + 1] = { item = ing.item, qty = lack }
            missingValue = missingValue + (value * lack)
            capsuleCost  = capsuleCost + math.ceil(lack * value * Config.Capsules.multiplier)
        end
    end

    -- Plafond de substitution défini sur la recette
    if #missing > 0 then
        if recipe.allow_capsules ~= 1 then
            return missing, capsuleCost, false
        end

        local ratio = totalValue > 0 and (missingValue / totalValue * 100) or 0
        if ratio > (recipe.max_capsule_ratio or 50) then
            return missing, capsuleCost, false
        end
    end

    return missing, capsuleCost, true
end


---Surcoût du lot au-delà de la quantité gratuite.
local function computeBatchCost(recipe, quantity)
    if quantity <= Config.Batch.free then return 0 end

    local extra = quantity - Config.Batch.free
    local value = Cache.itemValues[recipe.output_item] or 0

    return math.ceil(extra * value * Config.Batch.surcharge)
end


---Le joueur est-il assez près de l'établi ?
local function isNearTable(source, craftTable, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local dist = #(coords - vec3(craftTable.x, craftTable.y, craftTable.z))

    return dist <= maxDist, dist
end


-- ═══════════════════════════════════════════════════════════════════
--  CALLBACKS CLIENT
-- ═══════════════════════════════════════════════════════════════════

---Liste des recettes d'un établi, avec l'état du joueur pour chacune.
lib.callback.register('rz_craft:getTableRecipes', function(source, tableId)
    local craftTable = Cache.tables[tableId]
    if not craftTable then return end

    local citizenid = GetCharId(source)
    if not citizenid then return end

    local ok = isNearTable(source, craftTable, Config.CraftZone.tolerance)
    if not ok then return end

    local result   = {}
    local progress = {}

    for _, recipeId in ipairs(Cache.tableRecipes[tableId] or {}) do
        local recipe = Cache.recipes[recipeId]
        if recipe then
            if not progress[recipe.category] then
                progress[recipe.category] = GetProgress(citizenid, recipe.category)
            end
            local p = progress[recipe.category]

            local ingredients = {}
            for _, ing in ipairs(recipe.ingredients) do
                ingredients[#ingredients + 1] = {
                    item  = ing.item,
                    qty   = ing.qty,
                    have  = exports.ox_inventory:GetItemCount(source, ing.item),
                    value = Cache.itemValues[ing.item] or 0,
                }
            end

            result[#result + 1] = {
                id           = recipe.id,
                output       = recipe.output_item,
                outputQty    = recipe.output_qty,
                category     = recipe.category,
                level        = recipe.required_level,
                playerLevel  = p.level,
                unlocked     = p.level >= recipe.required_level,
                craftTime    = Config.GetCraftTime(recipe.required_level),
                ingredients  = ingredients,
                allowCapsules= recipe.allow_capsules == 1,
            }
        end
    end

    return {
        tableLabel = craftTable.label,
        recipes    = result,
        progress   = progress,
    }
end)


---Détail chiffré avant lancement : durée, coût, manquants.
lib.callback.register('rz_craft:preview', function(source, recipeId, quantity)
    local recipe = Cache.recipes[recipeId]
    if not recipe then return end

    quantity = math.floor(tonumber(quantity) or 1)
    if quantity < 1 or quantity > Config.Batch.max then return end

    local missing, capsuleCost, payable = computeMissing(source, recipe, quantity)
    local batchCost = computeBatchCost(recipe, quantity)

    return {
        duration     = Config.GetBatchTime(recipe.required_level, quantity),
        missing      = missing or {},
        capsuleCost  = capsuleCost,
        batchCost    = batchCost,
        totalCost    = capsuleCost + batchCost,
        payable      = payable,
        capsulesHeld = exports.ox_inventory:GetItemCount(source, Config.Capsules.item),
    }
end)


-- ═══════════════════════════════════════════════════════════════════
--  LANCEMENT DU CRAFT
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_craft:start', function(source, tableId, recipeId, quantity)
    -- Un seul craft à la fois
    if Sessions[source] then
        return false, 'Tu as déjà un craft en cours.'
    end

    local citizenid = GetCharId(source)
    if not citizenid then return false, 'Personnage introuvable.' end

    local craftTable = Cache.tables[tableId]
    local recipe     = Cache.recipes[recipeId]
    if not craftTable or not recipe then return false, 'Recette introuvable.' end

    -- La recette est-elle bien disponible SUR CET ÉTABLI ?
    local allowed = false
    for _, id in ipairs(Cache.tableRecipes[tableId] or {}) do
        if id == recipeId then allowed = true break end
    end
    if not allowed then return false, 'Cette recette n\'est pas disponible ici.' end

    quantity = math.floor(tonumber(quantity) or 1)
    if quantity < 1 or quantity > Config.Batch.max then
        return false, ('Quantité invalide (1 à %d).'):format(Config.Batch.max)
    end

    -- Distance
    local near = isNearTable(source, craftTable, Config.CraftZone.radius)
    if not near then return false, 'Trop loin de l\'établi.' end

    -- Niveau
    local p = GetProgress(citizenid, recipe.category)
    if p.level < recipe.required_level then
        return false, ('Niveau %s requis : %d (tu es %d).')
            :format(recipe.category, recipe.required_level, p.level)
    end

    -- Coût
    local missing, capsuleCost, payable = computeMissing(source, recipe, quantity)
    if not payable then
        return false, 'Il te manque trop de matériaux pour compenser en capsules.'
    end

    local totalCost = capsuleCost + computeBatchCost(recipe, quantity)

    if totalCost > 0 then
        local held = exports.ox_inventory:GetItemCount(source, Config.Capsules.item)
        if held < totalCost then
            return false, ('Il te faut %d capsules (tu en as %d).'):format(totalCost, held)
        end

        if not exports.ox_inventory:RemoveItem(source, Config.Capsules.item, totalCost) then
            return false, 'Impossible de prélever les capsules.'
        end
    end

    -- Réservation : ce qu'il possède déjà et qui sera consommé
    local toReserve = {}
    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.qty * quantity
        local have   = exports.ox_inventory:GetItemCount(source, ing.item)
        local lock   = math.min(have, needed)
        if lock > 0 then
            toReserve[#toReserve + 1] = { item = ing.item, qty = lock }
        end
    end

    local duration = Config.GetBatchTime(recipe.required_level, quantity)
    local endsAt   = os.time() + math.ceil(duration / 1000)

    local sessionId = MySQL.insert.await([[
        INSERT INTO rz_craft_sessions
            (citizenid, recipe_id, table_id, quantity, reserved_items, capsules_paid, ends_at)
        VALUES (?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?))
    ]], { citizenid, recipeId, tableId, quantity, json.encode(toReserve), totalCost, endsAt })

    Sessions[source] = {
        id         = sessionId,
        citizenid     = citizenid,
        recipeId   = recipeId,
        tableId    = tableId,
        quantity   = quantity,
        capsules   = totalCost,
        outOfRange = 0,
    }

    reserve(source, recipe.ingredients, quantity)

    LogAction(citizenid, 'craft_start', {
        recipe = recipe.output_item, qty = quantity, capsules = totalCost,
    })

    -- Surveillance de la distance
    StartWatcher(source)

    -- Minuterie de complétion
    SetTimeout(duration, function()
        CompleteCraft(source)
    end)

    return true, {
        duration = duration,
        output   = recipe.output_item,
        quantity = quantity * recipe.output_qty,
    }
end)


-- ═══════════════════════════════════════════════════════════════════
--  SURVEILLANCE ET ANNULATION
-- ═══════════════════════════════════════════════════════════════════

function StartWatcher(source)
    CreateThread(function()
        while Sessions[source] do
            Wait(Config.CraftZone.checkInterval)

            local s = Sessions[source]
            if not s then return end

            local craftTable = Cache.tables[s.tableId]
            if not craftTable then return end

            local ok = isNearTable(source, craftTable, Config.CraftZone.tolerance)

            if ok then
                s.outOfRange = 0
            else
                s.outOfRange = s.outOfRange + (Config.CraftZone.checkInterval / 1000)

                if s.outOfRange >= Config.CraftZone.graceSeconds then
                    CancelCraft(source, 'craft_annule', 'Tu t\'es éloigné de l\'établi.')
                    return
                end

                TriggerClientEvent('rz_craft:warnRange', source,
                    Config.CraftZone.graceSeconds - s.outOfRange)
            end
        end
    end)
end


---Annule un craft et renvoie les capsules par colis.
function CancelCraft(source, reason, message)
    local s = Sessions[source]
    if not s then return end

    Sessions[source] = nil
    release(source)

    MySQL.prepare("UPDATE rz_craft_sessions SET status = 'annule' WHERE id = ?", { s.id })

    local recipe = Cache.recipes[s.recipeId]
    local label  = recipe and recipe.output_item or 'craft'

    if s.capsules > 0 then
        SendParcel(s.citizenid, {
            label    = ('Craft annulé — %s'):format(label),
            reason   = reason or 'craft_annule',
            contents = { { item = Config.Capsules.item, qty = s.capsules } },
        })
    end

    LogAction(s.citizenid, 'craft_cancel', { recipe = label, reason = reason })

    TriggerClientEvent('rz_craft:cancelled', source, message, s.capsules)
end


---Annulation volontaire depuis le client.
RegisterNetEvent('rz_craft:cancel', function()
    CancelCraft(source, 'craft_annule', 'Craft annulé.')
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMPLÉTION
-- ═══════════════════════════════════════════════════════════════════

function CompleteCraft(source)
    local s = Sessions[source]
    if not s then return end

    local recipe = Cache.recipes[s.recipeId]
    if not recipe then
        CancelCraft(source, 'craft_annule', 'Recette introuvable.')
        return
    end

    -- Le joueur est-il toujours là ?
    if not GetPlayerPed(source) or GetPlayerPed(source) == 0 then
        HandleDisconnect(source)
        return
    end

    -- Consommation. On prend le minimum entre ce qui est requis et ce
    -- que le joueur détient : le delta a déjà été payé en capsules au
    -- lancement, et le hook a empêché toute sortie entre-temps.
    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.qty * s.quantity
        local have   = exports.ox_inventory:GetItemCount(source, ing.item)
        local take   = math.min(have, needed)

        if take > 0 then
            exports.ox_inventory:RemoveItem(source, ing.item, take)
        end
    end

    Sessions[source] = nil
    release(source)

    -- Production
    local produced = recipe.output_qty * s.quantity
    local added = exports.ox_inventory:AddItem(source, recipe.output_item, produced)

    if not added then
        -- Inventaire plein : l'item part en colis plutôt que d'être perdu
        SendParcel(s.citizenid, {
            label    = ('Inventaire plein — %s'):format(recipe.output_item),
            reason   = 'craft_annule',
            contents = { { item = recipe.output_item, qty = produced } },
        })
    end

    -- XP
    local xp = (recipe.xp_gain or 10) * s.quantity
    local newLevel, leveledUp = AddXp(s.citizenid, recipe.category, xp)

    MySQL.prepare("UPDATE rz_craft_sessions SET status = 'termine' WHERE id = ?", { s.id })

    LogAction(s.citizenid, 'craft_done', {
        recipe = recipe.output_item, qty = produced, xp = xp, level = newLevel,
    })

    TriggerClientEvent('rz_craft:completed', source, {
        item      = recipe.output_item,
        quantity  = produced,
        xp        = xp,
        level     = newLevel,
        leveledUp = leveledUp,
        category  = recipe.category,
        toMailbox = not added,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉCONNEXION
-- ═══════════════════════════════════════════════════════════════════

function HandleDisconnect(source)
    local s = Sessions[source]
    if not s then return end

    Sessions[source] = nil
    release(source)

    MySQL.prepare("UPDATE rz_craft_sessions SET status = 'interrompu' WHERE id = ?", { s.id })

    local recipe = Cache.recipes[s.recipeId]
    local label  = recipe and recipe.output_item or 'craft'

    if s.capsules > 0 then
        SendParcel(s.citizenid, {
            label    = ('Craft interrompu — %s'):format(label),
            reason   = 'craft_deconnexion',
            contents = { { item = Config.Capsules.item, qty = s.capsules } },
        })
    end

    LogAction(s.citizenid, 'craft_disconnect', { recipe = label })
end

AddEventHandler('playerDropped', function()
    HandleDisconnect(source)
end)
