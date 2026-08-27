--[[
    rz_craft / client/craft.lua
    Interface de craft : menu de l'établi, choix de la quantité,
    barre de progression et retours au joueur.
]]

local activeCraft = nil   -- { tableId, label, endTime }
local rangeWarned = false


---Formate une durée en texte lisible.
local function fmtTime(ms)
    local s = math.floor(ms / 1000)
    if s < 60 then return ('%d s'):format(s) end
    return ('%d min %02d s'):format(math.floor(s / 60), s % 60)
end


---Construit les lignes de description d'une recette.
local function describeRecipe(recipe)
    local lines = {}

    for _, ing in ipairs(recipe.ingredients) do
        local ok = ing.have >= ing.qty
        lines[#lines + 1] = ('%s %s : %d / %d')
            :format(ok and '✓' or '✗', ing.item, ing.have, ing.qty)
    end

    return table.concat(lines, '  \n')
end


-- ═══════════════════════════════════════════════════════════════════
--  MENU DE L'ÉTABLI
-- ═══════════════════════════════════════════════════════════════════

function OpenCraftTable(tableId)
    if activeCraft then
        return lib.notify({
            type = 'error',
            description = 'Tu as déjà un craft en cours.',
        })
    end

    local data = lib.callback.await('rz_craft:getTableRecipes', false, tableId)

    if not data then
        return lib.notify({ type = 'error', description = 'Établi inaccessible.' })
    end

    if #data.recipes == 0 then
        return lib.notify({
            type = 'inform',
            description = 'Aucune recette disponible sur cet établi.',
        })
    end

    -- Regroupement par catégorie
    local byCategory = {}
    for _, r in ipairs(data.recipes) do
        local list = byCategory[r.category]
        if not list then
            list = {}
            byCategory[r.category] = list
        end
        list[#list + 1] = r
    end

    local options = {}

    for _, category in ipairs(Config.Categories) do
        local recipes = byCategory[category]
        if recipes then
            local p = data.progress[category] or { level = 0, xp = 0 }

            options[#options + 1] = {
                title       = category:upper(),
                description = ('Niveau %d  ·  %d XP  ·  %d recette(s)')
                    :format(p.level, p.xp, #recipes),
                icon        = 'fas fa-layer-group',
                arrow       = true,
                onSelect    = function()
                    OpenCategoryMenu(tableId, category, recipes, data.tableLabel)
                end,
            }
        end
    end

    lib.registerContext({
        id      = 'rz_craft_main',
        title   = data.tableLabel,
        options = options,
    })

    lib.showContext('rz_craft_main')
end


function OpenCategoryMenu(tableId, category, recipes, tableLabel)
    -- Débloquées d'abord, puis par niveau croissant
    table.sort(recipes, function(a, b)
        if a.unlocked ~= b.unlocked then return a.unlocked end
        return a.level < b.level
    end)

    local options = {}

    for _, r in ipairs(recipes) do
        local title = ('%s ×%d'):format(r.output, r.outputQty)

        if not r.unlocked then
            options[#options + 1] = {
                title       = ('🔒 %s'):format(title),
                description = ('Niveau %d requis (tu es %d)')
                    :format(r.level, r.playerLevel),
                disabled    = true,
            }
        else
            options[#options + 1] = {
                title       = title,
                description = ('Durée %s  ·  Niveau %d\n%s')
                    :format(fmtTime(r.craftTime), r.level, describeRecipe(r)),
                icon        = 'fas fa-hammer',
                arrow       = true,
                onSelect    = function()
                    OpenQuantityDialog(tableId, r)
                end,
            }
        end
    end

    lib.registerContext({
        id      = 'rz_craft_category',
        title   = ('%s — %s'):format(tableLabel, category),
        menu    = 'rz_craft_main',
        options = options,
    })

    lib.showContext('rz_craft_category')
end


-- ═══════════════════════════════════════════════════════════════════
--  CHOIX DE LA QUANTITÉ
-- ═══════════════════════════════════════════════════════════════════

function OpenQuantityDialog(tableId, recipe)
    local input = lib.inputDialog(recipe.output, {
        {
            type    = 'slider',
            label   = 'Quantité',
            default = 1,
            min     = 1,
            max     = Config.Batch.max,
            step    = 1,
        },
    }, { allowCancel = true })

    if not input then return end

    local quantity = math.floor(input[1] or 1)

    local preview = lib.callback.await('rz_craft:preview', false, recipe.id, quantity)
    if not preview then
        return lib.notify({ type = 'error', description = 'Calcul impossible.' })
    end

    -- Récapitulatif avant validation
    local lines = {
        ('**Production** : %d × %s'):format(quantity * recipe.outputQty, recipe.output),
        ('**Durée** : %s'):format(fmtTime(preview.duration)),
    }

    if #preview.missing > 0 then
        lines[#lines + 1] = ''
        lines[#lines + 1] = '**Matériaux manquants :**'
        for _, m in ipairs(preview.missing) do
            lines[#lines + 1] = ('· %s ×%d'):format(m.item, m.qty)
        end
    end

    if preview.totalCost > 0 then
        lines[#lines + 1] = ''
        if preview.capsuleCost > 0 then
            lines[#lines + 1] = ('Matériaux manquants : %d capsules'):format(preview.capsuleCost)
        end
        if preview.batchCost > 0 then
            lines[#lines + 1] = ('Lot au-delà de %d : %d capsules')
                :format(Config.Batch.free, preview.batchCost)
        end
        lines[#lines + 1] = ('**Total : %d capsules** (tu en as %d)')
            :format(preview.totalCost, preview.capsulesHeld)
    end

    if not preview.payable then
        lines[#lines + 1] = ''
        lines[#lines + 1] = '⚠️ Il te manque trop de matériaux pour compenser en capsules.'
    end

    local confirm = lib.alertDialog({
        header    = ('Crafter %s'):format(recipe.output),
        content   = table.concat(lines, '  \n'),
        centered  = true,
        cancel    = true,
        labels    = { confirm = 'Lancer', cancel = 'Annuler' },
    })

    if confirm ~= 'confirm' then return end

    StartCraft(tableId, recipe, quantity)
end


-- ═══════════════════════════════════════════════════════════════════
--  LANCEMENT ET PROGRESSION
-- ═══════════════════════════════════════════════════════════════════

function StartCraft(tableId, recipe, quantity)
    local ok, result = lib.callback.await('rz_craft:start', false,
        tableId, recipe.id, quantity)

    if not ok then
        return lib.notify({
            type        = 'error',
            title       = 'Craft impossible',
            description = result or 'Erreur inconnue.',
            duration    = 6000,
        })
    end

    activeCraft = {
        tableId = tableId,
        label   = result.output,
        endTime = GetGameTimer() + result.duration,
    }
    rangeWarned = false

    -- Animation d'établi
    lib.requestAnimDict('amb@world_human_hammering@male@base', 5000)
    TaskPlayAnim(cache.ped, 'amb@world_human_hammering@male@base',
        'base', 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Barre de progression annulable
    local finished = lib.progressBar({
        duration = result.duration,
        label    = ('Fabrication — %s'):format(result.output),
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = false, combat = true },
    })

    ClearPedTasks(cache.ped)

    -- Annulation volontaire par le joueur
    if not finished and activeCraft then
        TriggerServerEvent('rz_craft:cancel')
    end
end


-- Avertissement d'éloignement, envoyé par le serveur
RegisterNetEvent('rz_craft:warnRange', function(secondsLeft)
    if not activeCraft then return end

    if not rangeWarned then
        rangeWarned = true
    end

    lib.notify({
        id          = 'rz_craft_range',
        type        = 'warning',
        title       = 'Reviens à l\'établi',
        description = ('Craft annulé dans %d s'):format(math.ceil(secondsLeft)),
        duration    = 1200,
    })
end)


RegisterNetEvent('rz_craft:cancelled', function(message, capsules)
    activeCraft = nil
    ClearPedTasks(cache.ped)

    local desc = message or 'Craft annulé.'
    if capsules and capsules > 0 then
        desc = ('%s\n%d capsules renvoyées à ta boîte aux lettres.')
            :format(desc, capsules)
    end

    lib.notify({
        type        = 'error',
        title       = 'Craft interrompu',
        description = desc,
        duration    = 8000,
    })
end)


RegisterNetEvent('rz_craft:completed', function(data)
    activeCraft = nil
    ClearPedTasks(cache.ped)

    local desc = ('%d × %s  ·  +%d XP'):format(data.quantity, data.item, data.xp)

    if data.toMailbox then
        desc = desc .. '\n⚠️ Inventaire plein — envoyé à la boîte aux lettres.'
    end

    lib.notify({
        type        = 'success',
        title       = 'Fabrication terminée',
        description = desc,
        duration    = 7000,
    })

    if data.leveledUp then
        Wait(1200)
        lib.notify({
            type        = 'inform',
            title       = 'Niveau supérieur',
            description = ('%s — niveau %d'):format(data.category, data.level),
            duration    = 8000,
        })
    end
end)
