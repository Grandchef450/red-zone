--[[
    rz_craft / client/admin.lua
    Créateur de craft : placement au prop fantôme et menus d'édition.

    Point d'entrée : un bouton dans le panneau admin (F5) appelle le
    callback NUI « openCreator » de CETTE ressource. Aucune logique
    n'est ajoutée au panneau lui-même.
]]

local placing = false   -- mode placement actif


-- ═══════════════════════════════════════════════════════════════════
--  POINT D'ENTRÉE DEPUIS LE PANNEAU ADMIN
--
--  Une interface NUI peut appeler le callback d'une autre ressource.
--  Le bouton du panneau vise https://rz_craft/openCreator, donc rien
--  à enregistrer côté panneau.
-- ═══════════════════════════════════════════════════════════════════

RegisterNUICallback('openCreator', function(_, cb)
    cb({ ok = true })

    -- Laisse le panneau se refermer et rendre le focus avant
    -- d'ouvrir notre menu, sinon les deux se disputent la souris.
    CreateThread(function()
        Wait(250)
        OpenCreator()
    end)
end)


-- Secours si le bouton NUI ne répond pas : commande classique.
RegisterCommand('craftcreator', function()
    OpenCreator()
end, false)


-- ═══════════════════════════════════════════════════════════════════
--  MENU PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

function OpenCreator()
    local allowed = lib.callback.await('rz_craft:isAdmin', false)
    if not allowed then
        return lib.notify({
            type = 'error',
            title = 'Accès refusé',
            description = 'Permission rz_craft.admin requise.',
        })
    end

    local lists = lib.callback.await('rz_craft:admin:getLists', false) or
                  { tables = {}, recipes = {}, mailPoints = {} }

    lib.registerContext({
        id    = 'rz_creator',
        title = 'Créateur de craft',
        options = {
            {
                title = 'Poser un établi',
                description = 'Place un nouvel établi avec un prop déplaçable',
                icon = 'fas fa-hammer',
                onSelect = function() PlaceTable() end,
            },
            {
                title = 'Poser un facteur',
                description = 'Place le ped qui remet les colis',
                icon = 'fas fa-box-open',
                onSelect = function() PlaceMailPoint() end,
            },
            {
                title = 'Créer une recette',
                description = 'Niveau, ingrédients, item produit',
                icon = 'fas fa-scroll',
                arrow = true,
                onSelect = function() NewRecipe() end,
            },
            {
                title = ('Établis existants (%d)'):format(#lists.tables),
                icon = 'fas fa-list',
                arrow = true,
                onSelect = function() ListTables(lists) end,
            },
            {
                title = ('Recettes existantes (%d)'):format(#lists.recipes),
                icon = 'fas fa-book',
                arrow = true,
                onSelect = function() ListRecipes(lists) end,
            },
            {
                title = ('Facteurs existants (%d)'):format(#lists.mailPoints),
                icon = 'fas fa-user-tie',
                arrow = true,
                onSelect = function() ListMailPoints(lists) end,
            },
        },
    })

    lib.showContext('rz_creator')
end


-- ═══════════════════════════════════════════════════════════════════
--  MODE PLACEMENT — PROP FANTÔME
--
--  Le prop flotte devant le joueur, semi-transparent et sans
--  collision. Les touches ajustent la distance, la hauteur et
--  l'orientation. Entrée valide, Échap annule.
-- ═══════════════════════════════════════════════════════════════════

---@param model string modèle à afficher
---@param onConfirm fun(coords: vector3, heading: number)
function StartPlacement(model, onConfirm)
    if placing then
        return lib.notify({ type = 'error', description = 'Placement déjà en cours.' })
    end

    local hash = joaat(model)
    lib.requestModel(hash, 10000)

    if not HasModelLoaded(hash) then
        return lib.notify({
            type = 'error',
            description = ('Modèle introuvable : %s'):format(model),
        })
    end

    placing = true

    local ghost = CreateObject(hash, GetEntityCoords(cache.ped), false, false, false)
    SetEntityAlpha(ghost, 160, false)
    SetEntityCollision(ghost, false, false)
    SetEntityInvincible(ghost, true)
    FreezeEntityPosition(ghost, true)
    SetModelAsNoLongerNeeded(hash)

    local distance = 2.0
    local height   = 0.0
    local heading  = GetEntityHeading(cache.ped)

    lib.showTextUI([[
**Placement**
[Molette] distance · [PageHaut/Bas] hauteur
[Q / E] rotation · [Maj] rotation rapide
[Entrée] valider · [Échap] annuler
    ]], { position = 'left-center' })

    CreateThread(function()
        while placing do
            local ped    = cache.ped
            local coords = GetEntityCoords(ped)
            local fwd    = GetEntityForwardVector(ped)

            local target = vec3(
                coords.x + fwd.x * distance,
                coords.y + fwd.y * distance,
                coords.z + height - 1.0
            )

            SetEntityCoords(ghost, target.x, target.y, target.z, false, false, false, false)
            SetEntityHeading(ghost, heading)

            -- Molette : distance
            if IsControlJustPressed(0, 241) then distance = math.min(distance + 0.2, 10.0) end
            if IsControlJustPressed(0, 242) then distance = math.max(distance - 0.2, 0.5) end

            -- Page haut / bas : hauteur
            if IsControlPressed(0, 10)  then height = height + 0.02 end
            if IsControlPressed(0, 11)  then height = height - 0.02 end

            -- Q / E : rotation (Maj = plus rapide)
            local step = IsControlPressed(0, 21) and 3.0 or 0.7
            if IsControlPressed(0, 44) then heading = (heading - step) % 360 end
            if IsControlPressed(0, 38) then heading = (heading + step) % 360 end

            -- Entrée : valider
            if IsControlJustPressed(0, 191) then
                local final = GetEntityCoords(ghost)
                placing = false
                lib.hideTextUI()
                DeleteEntity(ghost)
                onConfirm(final, heading)
                return
            end

            -- Échap : annuler
            if IsControlJustPressed(0, 200) then
                placing = false
                lib.hideTextUI()
                DeleteEntity(ghost)
                lib.notify({ type = 'inform', description = 'Placement annulé.' })
                return
            end

            Wait(0)
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  CRÉATION D'UN ÉTABLI
-- ═══════════════════════════════════════════════════════════════════

function PlaceTable()
    local input = lib.inputDialog('Nouvel établi', {
        { type = 'input',  label = 'Nom affiché', required = true,
          placeholder = 'Établi de Sandy Shores' },
        { type = 'input',  label = 'Modèle du prop', default = 'prop_toolchest_01',
          description = 'Laisser vide pour utiliser un objet déjà sur la map' },
        { type = 'number', label = 'Palier (tier)', default = 1, min = 1, max = 10,
          description = '1 = établi de base, présent dans toutes les safe zones' },
        { type = 'checkbox', label = 'Située en safe zone', checked = true },
        { type = 'input',  label = 'ID de la safe zone',
          description = 'Doit correspondre à zombies/config_server.lua',
          placeholder = 'safezone_sandy' },
        { type = 'number', label = 'Blip (0 = aucun)', default = 566 },
    })

    if not input then return end

    local model = input[2]
    if not model or model == '' then model = 'prop_toolchest_01' end

    StartPlacement(model, function(coords, heading)
        local id = lib.callback.await('rz_craft:admin:createTable', false, {
            label       = input[1],
            prop_model  = (input[2] ~= '' and input[2]) or nil,
            tier        = input[3],
            in_safezone = input[4],
            safezone_id = (input[5] ~= '' and input[5]) or nil,
            blip_sprite = (input[6] > 0) and input[6] or nil,
            blip_color  = 5,
            x = coords.x, y = coords.y, z = coords.z, heading = heading,
        })

        if id then
            lib.notify({
                type = 'success',
                title = 'Établi créé',
                description = ('« %s » — id %d\nPense à y attacher des recettes.')
                    :format(input[1], id),
                duration = 8000,
            })
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  CRÉATION D'UN FACTEUR
-- ═══════════════════════════════════════════════════════════════════

function PlaceMailPoint()
    local input = lib.inputDialog('Nouveau facteur', {
        { type = 'input', label = 'Nom affiché', required = true,
          placeholder = 'Le Facteur — Sandy' },
        { type = 'select', label = 'Modèle du ped', default = 'a_m_m_hillbilly_01',
          options = {
            { value = 'a_m_m_hillbilly_01', label = 'Survivant rural' },
            { value = 'a_m_m_hillbilly_02', label = 'Survivant rural (variante)' },
            { value = 'a_m_m_tramp_01',     label = 'Vagabond' },
            { value = 's_m_m_dockwork_01',  label = 'Docker' },
            { value = 's_m_y_dealer_01',    label = 'Marchand' },
            { value = 'a_m_m_prolhost_01',  label = 'Tenancier' },
          } },
        { type = 'select', label = 'Animation', default = 'WORLD_HUMAN_CLIPBOARD',
          options = {
            { value = 'WORLD_HUMAN_CLIPBOARD',   label = 'Consulte un registre' },
            { value = 'WORLD_HUMAN_GUARD_STAND', label = 'Monte la garde' },
            { value = 'WORLD_HUMAN_AA_COFFEE',   label = 'Boit un café' },
            { value = 'WORLD_HUMAN_SMOKING',     label = 'Fume' },
            { value = 'WORLD_HUMAN_LEANING',     label = 'Adossé' },
          } },
        { type = 'input', label = 'ID de la safe zone', placeholder = 'safezone_sandy' },
    })

    if not input then return end

    StartPlacement(input[2], function(coords, heading)
        local id = lib.callback.await('rz_craft:admin:createMailPoint', false, {
            label       = input[1],
            ped_model   = input[2],
            scenario    = input[3],
            safezone_id = (input[4] ~= '' and input[4]) or nil,
            blip_sprite = 480,
            blip_color  = 5,
            x = coords.x, y = coords.y, z = coords.z, heading = heading,
        })

        if id then
            lib.notify({
                type = 'success',
                title = 'Facteur posé',
                description = ('« %s » — id %d'):format(input[1], id),
            })
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  CRÉATION D'UNE RECETTE
--
--  Trois blocs, comme demandé : le niveau, les ingrédients en lignes
--  qu'on ajoute au besoin, puis l'item produit.
-- ═══════════════════════════════════════════════════════════════════

local draft = nil   -- recette en cours de composition

function NewRecipe()
    local items = lib.callback.await('rz_craft:admin:getItems', false) or {}

    if #items == 0 then
        return lib.notify({ type = 'error', description = 'Aucun item chargé.' })
    end

    local categories = {}
    for _, c in ipairs(Config.Categories) do
        categories[#categories + 1] = { value = c, label = c:upper() }
    end

    local input = lib.inputDialog('Nouvelle recette — étape 1/3', {
        { type = 'select', label = 'Item produit', options = items, required = true,
          searchable = true },
        { type = 'number', label = 'Quantité produite', default = 1, min = 1, max = 100 },
        { type = 'select', label = 'Catégorie', options = categories, required = true },
        { type = 'number', label = 'Niveau requis', default = 0, min = 0,
          description = 'Détermine aussi la durée du craft' },
        { type = 'number', label = 'XP gagnée', default = 10, min = 0 },
        { type = 'checkbox', label = 'Paiement en capsules autorisé', checked = true },
        { type = 'slider', label = 'Part max payable en capsules (%)',
          default = 50, min = 0, max = 100, step = 10 },
    })

    if not input then return end

    draft = {
        output_item       = input[1],
        output_qty        = input[2],
        category          = input[3],
        required_level    = input[4],
        xp_gain           = input[5],
        allow_capsules    = input[6],
        max_capsule_ratio = input[7],
        ingredients       = {},
        tables            = {},
        items             = items,
    }

    IngredientsMenu()
end


function IngredientsMenu()
    if not draft then return end

    local options = {}

    for i, ing in ipairs(draft.ingredients) do
        options[#options + 1] = {
            title       = ('%s ×%d'):format(ing.item, ing.qty),
            description = 'Cliquer pour retirer cette ligne',
            icon        = 'fas fa-minus-circle',
            iconColor   = '#f87171',
            onSelect    = function()
                table.remove(draft.ingredients, i)
                IngredientsMenu()
            end,
        }
    end

    options[#options + 1] = {
        title     = 'Ajouter un ingrédient',
        icon      = 'fas fa-plus',
        iconColor = '#4ade80',
        onSelect  = function() AddIngredient() end,
    }

    if #draft.ingredients > 0 then
        options[#options + 1] = {
            title       = 'Continuer',
            description = ('%d ingrédient(s) — durée estimée %d s')
                :format(#draft.ingredients,
                        math.floor(Config.GetCraftTime(draft.required_level) / 1000)),
            icon        = 'fas fa-arrow-right',
            iconColor   = '#60a5fa',
            onSelect    = function() ChooseTables() end,
        }
    end

    options[#options + 1] = {
        title     = 'Abandonner',
        icon      = 'fas fa-xmark',
        iconColor = '#9ca3af',
        onSelect  = function()
            draft = nil
            OpenCreator()
        end,
    }

    lib.registerContext({
        id      = 'rz_creator_ings',
        title   = ('Ingrédients — %s'):format(draft.output_item),
        options = options,
    })

    lib.showContext('rz_creator_ings')
end


function AddIngredient()
    local input = lib.inputDialog('Ajouter un ingrédient', {
        { type = 'select', label = 'Item', options = draft.items,
          required = true, searchable = true },
        { type = 'number', label = 'Quantité', default = 1, min = 1, max = 999 },
    })

    if not input then return IngredientsMenu() end

    -- Fusionne si l'item est déjà présent, au lieu de créer un doublon
    for _, ing in ipairs(draft.ingredients) do
        if ing.item == input[1] then
            ing.qty = ing.qty + input[2]
            return IngredientsMenu()
        end
    end

    draft.ingredients[#draft.ingredients + 1] = { item = input[1], qty = input[2] }
    IngredientsMenu()
end


function ChooseTables()
    if not draft then return end

    local lists = lib.callback.await('rz_craft:admin:getLists', false)
    if not lists or #lists.tables == 0 then
        return SaveRecipe()   -- aucun établi : on enregistre sans rattacher
    end

    local selected = {}
    for _, id in ipairs(draft.tables) do selected[id] = true end

    local options = {}

    for _, t in ipairs(lists.tables) do
        local on = selected[t.id]
        options[#options + 1] = {
            title       = ('%s %s'):format(on and '☑' or '☐', t.label),
            description = ('Palier %d · %d recette(s)'):format(t.tier, t.recipeCount),
            onSelect    = function()
                if on then
                    for i, id in ipairs(draft.tables) do
                        if id == t.id then table.remove(draft.tables, i) break end
                    end
                else
                    draft.tables[#draft.tables + 1] = t.id
                end
                ChooseTables()
            end,
        }
    end

    options[#options + 1] = {
        title       = 'Enregistrer la recette',
        description = ('Sur %d établi(s)'):format(#draft.tables),
        icon        = 'fas fa-floppy-disk',
        iconColor   = '#4ade80',
        onSelect    = function() SaveRecipe() end,
    }

    lib.registerContext({
        id      = 'rz_creator_tables',
        title   = 'Disponible sur quels établis ?',
        menu    = 'rz_creator_ings',
        options = options,
    })

    lib.showContext('rz_creator_tables')
end


function SaveRecipe()
    if not draft then return end

    local payload = {
        output_item       = draft.output_item,
        output_qty        = draft.output_qty,
        category          = draft.category,
        required_level    = draft.required_level,
        xp_gain           = draft.xp_gain,
        allow_capsules    = draft.allow_capsules,
        max_capsule_ratio = draft.max_capsule_ratio,
        ingredients       = draft.ingredients,
        tables            = draft.tables,
    }

    local id = lib.callback.await('rz_craft:admin:createRecipe', false, payload)

    if id then
        lib.notify({
            type        = 'success',
            title       = 'Recette enregistrée',
            description = ('%s ×%d — id %d')
                :format(draft.output_item, draft.output_qty, id),
            duration    = 7000,
        })
    else
        lib.notify({ type = 'error', description = 'Enregistrement refusé.' })
    end

    draft = nil
end


-- ═══════════════════════════════════════════════════════════════════
--  LISTES ET SUPPRESSION
-- ═══════════════════════════════════════════════════════════════════

function ListTables(lists)
    local options = {}

    for _, t in ipairs(lists.tables) do
        options[#options + 1] = {
            title       = t.label,
            description = ('Palier %d · %d recette(s)\n%.1f, %.1f, %.1f')
                :format(t.tier, t.recipeCount, t.x, t.y, t.z),
            icon        = 'fas fa-hammer',
            arrow       = true,
            onSelect    = function() TableActions(t) end,
        }
    end

    lib.registerContext({
        id = 'rz_creator_list_tables',
        title = 'Établis',
        menu = 'rz_creator',
        options = options,
    })
    lib.showContext('rz_creator_list_tables')
end


function TableActions(t)
    lib.registerContext({
        id    = 'rz_creator_table_actions',
        title = t.label,
        menu  = 'rz_creator_list_tables',
        options = {
            {
                title = 'S\'y téléporter',
                icon = 'fas fa-location-arrow',
                onSelect = function()
                    SetEntityCoords(cache.ped, t.x, t.y, t.z + 1.0, false, false, false, false)
                end,
            },
            {
                title = 'Gérer les recettes',
                description = 'Attacher ou détacher des recettes',
                icon = 'fas fa-link',
                arrow = true,
                onSelect = function() ManageTableRecipes(t) end,
            },
            {
                title = 'Supprimer',
                icon = 'fas fa-trash',
                iconColor = '#f87171',
                onSelect = function()
                    local ok = lib.alertDialog({
                        header = 'Supprimer cet établi ?',
                        content = ('« %s » sera retiré, ainsi que ses liens vers les recettes.\nLes recettes elles-mêmes sont conservées.')
                            :format(t.label),
                        centered = true, cancel = true,
                    })
                    if ok == 'confirm' then
                        lib.callback.await('rz_craft:admin:deleteTable', false, t.id)
                        lib.notify({ type = 'success', description = 'Établi supprimé.' })
                    end
                end,
            },
        },
    })
    lib.showContext('rz_creator_table_actions')
end


function ManageTableRecipes(t)
    local lists  = lib.callback.await('rz_craft:admin:getLists', false)
    local linked = lib.callback.await('rz_craft:admin:getTableRecipeIds', false, t.id) or {}

    local options = {}

    for _, r in ipairs(lists.recipes) do
        local on = linked[r.id]
        options[#options + 1] = {
            title       = ('%s %s ×%d'):format(on and '☑' or '☐', r.output, r.qty),
            description = ('%s · niveau %d'):format(r.category, r.level),
            onSelect    = function()
                lib.callback.await('rz_craft:admin:toggleRecipeOnTable', false, t.id, r.id)
                ManageTableRecipes(t)
            end,
        }
    end

    lib.registerContext({
        id = 'rz_creator_table_recipes',
        title = ('Recettes — %s'):format(t.label),
        menu = 'rz_creator_table_actions',
        options = options,
    })
    lib.showContext('rz_creator_table_recipes')
end


function ListRecipes(lists)
    local options = {}

    for _, r in ipairs(lists.recipes) do
        local ings = {}
        for _, ing in ipairs(r.ingredients or {}) do
            ings[#ings + 1] = ('%s ×%d'):format(ing.item, ing.qty)
        end

        options[#options + 1] = {
            title       = ('%s ×%d'):format(r.output, r.qty),
            description = ('%s · niveau %d\n%s')
                :format(r.category, r.level, table.concat(ings, ', ')),
            icon        = 'fas fa-scroll',
            onSelect    = function()
                local ok = lib.alertDialog({
                    header = 'Supprimer cette recette ?',
                    content = ('%s sera retirée de tous les établis.'):format(r.output),
                    centered = true, cancel = true,
                })
                if ok == 'confirm' then
                    lib.callback.await('rz_craft:admin:deleteRecipe', false, r.id)
                    lib.notify({ type = 'success', description = 'Recette supprimée.' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'rz_creator_list_recipes',
        title = 'Recettes',
        menu = 'rz_creator',
        options = options,
    })
    lib.showContext('rz_creator_list_recipes')
end


function ListMailPoints(lists)
    local options = {}

    for _, p in ipairs(lists.mailPoints) do
        options[#options + 1] = {
            title       = p.label,
            description = ('%.1f, %.1f, %.1f'):format(p.x, p.y, p.z),
            icon        = 'fas fa-user-tie',
            onSelect    = function()
                local ok = lib.alertDialog({
                    header = 'Supprimer ce facteur ?',
                    content = ('« %s » disparaîtra.\nLes colis en attente ne sont PAS perdus : ils restent en base et seront récupérables au prochain facteur.')
                        :format(p.label),
                    centered = true, cancel = true,
                })
                if ok == 'confirm' then
                    lib.callback.await('rz_craft:admin:deleteMailPoint', false, p.id)
                    lib.notify({ type = 'success', description = 'Facteur supprimé.' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'rz_creator_list_mail',
        title = 'Facteurs',
        menu = 'rz_creator',
        options = options,
    })
    lib.showContext('rz_creator_list_mail')
end
