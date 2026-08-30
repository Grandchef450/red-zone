--[[
    rz_logs / server/hooks.lua

    Capture des mouvements d'items via les hooks d'ox_inventory.

    CE QUE CE FICHIER COUVRE
    Les transferts entre inventaires : don à un joueur, dépôt dans
    un coffre, ramassage au sol, achat chez un marchand.

    CE QU'IL NE COUVRE PAS
    Les appels AddItem et RemoveItem faits directement par un script
    — donc les /giveitem du staff. ox_inventory n'expose pas de hook
    pour ceux-là : ils passent par lib.logger, qu'on branche via le
    correctif d'ox_lib fourni à part.
]]

local function itemLabel(name)
    local items = exports.ox_inventory:Items()
    local data = items and items[name]
    return data and data.label or name
end


---Nom lisible d'un inventaire, quel que soit son type.
local function describeInventory(id, invType)
    if not id then return 'inconnu' end

    id = tostring(id)

    -- Un inventaire joueur porte son source comme identifiant
    local src = tonumber(id)
    if src and GetPlayerName(src) then
        return ('%s `[%d]`'):format(GetPlayerName(src), src)
    end

    local prefixes = {
        ['trunk']    = 'Coffre de véhicule',
        ['glove']    = 'Boîte à gants',
        ['drop']     = 'Objets au sol',
        ['rzsac_']   = 'Sac mortuaire',
        ['rzepave_'] = 'Épave fouillée',
        ['stash']    = 'Coffre',
    }

    for prefix, label in pairs(prefixes) do
        if id:sub(1, #prefix) == prefix then
            return ('%s `%s`'):format(label, id)
        end
    end

    return ('`%s`'):format(id)
end


-- ═══════════════════════════════════════════════════════════════════
--  TRANSFERTS D'ITEMS
--
--  Le hook renvoie TOUJOURS true : on observe, on ne bloque jamais.
--  Un système de logs qui refuserait une action serait une source
--  de bugs incompréhensibles.
-- ═══════════════════════════════════════════════════════════════════

if Config.Inventory.logTransfers then
    exports.ox_inventory:registerHook('swapItems', function(payload)
        local item = payload.fromSlot

        if type(item) ~= 'table' or not item.name then return true end
        if Config.IsIgnoredItem(item.name) then return true end

        local count = payload.count or item.count or 1
        if count < Config.Inventory.minCount then return true end

        local from = tostring(payload.fromInventory)
        local to   = tostring(payload.toInventory)

        -- Rangement interne : presque toujours du bruit
        if from == to and not Config.Inventory.logInternalMoves then
            return true
        end

        Log('inventaire', {
            title  = ('Transfert — %s ×%d'):format(itemLabel(item.name), count),
            source = payload.source,
            fields = {
                { name = 'Depuis', value = describeInventory(from) },
                { name = 'Vers',   value = describeInventory(to) },
                { name = 'Item',   value = ('`%s`'):format(item.name) },
            },
        })

        return true
    end, { print = false })
end


-- ═══════════════════════════════════════════════════════════════════
--  ACHATS
-- ═══════════════════════════════════════════════════════════════════

exports.ox_inventory:registerHook('buyItem', function(payload)
    local item = payload.itemName or (payload.item and payload.item.name)
    if not item then return true end

    Log('inventaire', {
        title  = ('Achat — %s ×%s'):format(itemLabel(item), payload.count or 1),
        source = payload.source,
        fields = {
            { name = 'Prix',    value = tostring(payload.price or '?') },
            { name = 'Magasin', value = tostring(payload.shopType or '?') },
        },
    })

    return true
end, { print = false })


-- ═══════════════════════════════════════════════════════════════════
--  FABRICATIONS
-- ═══════════════════════════════════════════════════════════════════

exports.ox_inventory:registerHook('craftItem', function(payload)
    Log('craft', {
        title  = 'Fabrication (ox_inventory)',
        source = payload.source,
        fields = {
            { name = 'Recette', value = tostring(payload.recipe and payload.recipe.name or '?') },
            { name = 'Quantité', value = tostring(payload.count or 1) },
        },
    })

    return true
end, { print = false })


-- ═══════════════════════════════════════════════════════════════════
--  PONT DEPUIS OX_LIB
--
--  Appelé par le correctif d'ox_lib. C'est ce qui capture les
--  AddItem et RemoveItem faits par un script — donc les /giveitem
--  du staff, et tout ce que nos propres ressources ajoutent ou
--  retirent d'un inventaire.
--
--  `source` est ici le PROPRIÉTAIRE de l'inventaire concerné, pas
--  forcément celui qui a déclenché l'action.
-- ═══════════════════════════════════════════════════════════════════

exports('OxLog', function(source, event, message)
    if not Config.Inventory.logScriptChanges then return end

    -- On sépare les actions du staff du bruit ordinaire : un
    -- /giveitem n'a pas la même valeur qu'un item consommé.
    local category = 'inventaire'
    local title = event

    if event == 'addItem' then
        title = 'Item ajouté par un script'
    elseif event == 'removeItem' then
        title = 'Item retiré par un script'
    elseif event == 'swapSlots' then
        title = 'Déplacement d\'item'
        if not Config.Inventory.logInternalMoves then return end
    elseif event == 'createItem' then
        title = 'Item créé'
    end

    -- Le message d'ox_inventory contient le nom de la ressource
    -- appelante entre guillemets. Si c'est ox_commands, c'est un
    -- /giveitem : ça va dans le salon admin.
    if type(message) == 'string' and message:find('ox_commands') then
        category = 'admin'
        title = 'Commande staff sur inventaire'
    end

    Log(category, {
        title       = title,
        description = tostring(message),
        source      = tonumber(source),
    })
end)
