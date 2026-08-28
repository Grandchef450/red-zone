--[[
    rz_coffres / server/main.lua

    Coffres de sécurité liés à un joueur pour une durée déterminée.

    PRINCIPE : la protection ne dépend PAS de l'endroit où se trouve
    le coffre. Elle est portée par les métadonnées de l'item lui-même
    (propriétaire + date d'expiration). Que le coffre soit dans
    l'inventaire du propriétaire, dans un sac au sol, ou dans les
    poches de celui qui l'a ramassé, la règle reste la même : tant que
    le minuteur tourne, seul le propriétaire l'ouvre.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_coffres]^7', ...) end
end


---citizenid Qbox d'une source.
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end


---Nom affichable d'un joueur.
local function getPlayerName(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return 'Inconnu' end

    local c = player.PlayerData.charinfo
    if c then
        return ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('^%s+', '')
    end

    return GetPlayerName(source) or 'Inconnu'
end


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT D'UN COFFRE
-- ═══════════════════════════════════════════════════════════════════

---@return boolean locked, number remaining (secondes)
local function chestState(metadata)
    if not metadata or not metadata.rzExpiresAt then
        -- Coffre sans liaison : conteneur ordinaire, libre d'accès.
        return false, 0
    end

    local remaining = metadata.rzExpiresAt - os.time()
    return remaining > 0, math.max(0, remaining)
end


---Texte lisible d'une durée restante.
local function formatRemaining(seconds)
    if seconds <= 0 then return 'expiré' end

    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)

    if d > 0 then return ('%d j %d h'):format(d, h) end
    if h > 0 then return ('%d h %d min'):format(h, m) end
    if m > 0 then return ('%d min'):format(m) end
    return ('%d s'):format(seconds)
end


---Description affichée au survol de l'item.
local function buildDescription(metadata)
    local locked, remaining = chestState(metadata)

    if not metadata.rzOwnerName then
        return 'Coffre libre — ouvrable par son porteur.'
    end

    if locked then
        return ('%s Verrouillé — %s\nPropriétaire : %s\nOuverture libre dans %s')
            :format(Config.Tooltip.lockedIcon,
                    formatRemaining(remaining),
                    metadata.rzOwnerName,
                    formatRemaining(remaining))
    end

    return ('%s Protection expirée\nAncien propriétaire : %s\nOuvrable par son porteur.')
        :format(Config.Tooltip.unlockedIcon, metadata.rzOwnerName)
end

exports('BuildDescription', buildDescription)
exports('ChestState', chestState)


-- ═══════════════════════════════════════════════════════════════════
--  LIAISON D'UN COFFRE À UN JOUEUR
-- ═══════════════════════════════════════════════════════════════════

---Remet un coffre lié à un joueur.
---@param target number  source du joueur receveur
---@param itemName string
---@param hours number|nil  durée ; déduite du nom si absente
---@param grantedBy string|nil  identifiant de l'admin
---@return boolean ok, string message
function GiveChest(target, itemName, hours, grantedBy)
    if not Config.IsChest(itemName) then
        return false, ('« %s » n\'est pas un coffre de sécurité.'):format(itemName)
    end

    local citizenid = getCitizenId(target)
    if not citizenid then
        return false, 'Personnage introuvable.'
    end

    hours = tonumber(hours) or Config.GetDefaultHours(itemName)
    if not hours or hours <= 0 then
        return false, 'Durée invalide.'
    end

    if not exports.ox_inventory:CanCarryItem(target, itemName, 1) then
        return false, 'Inventaire plein chez le destinataire.'
    end

    local expiresAt = os.time() + math.floor(hours * 3600)
    local ownerName = getPlayerName(target)

    local metadata = {
        rzOwner     = citizenid,
        rzOwnerName = ownerName,
        rzExpiresAt = expiresAt,
        rzGrantedAt = os.time(),
        rzHours     = hours,
    }
    metadata.description = buildDescription(metadata)

    local added = exports.ox_inventory:AddItem(target, itemName, 1, metadata)
    if not added then
        return false, 'Impossible d\'ajouter l\'item.'
    end

    -- On relit l'item pour récupérer l'identifiant de conteneur
    -- généré par ox_inventory : c'est lui qui suit le coffre partout.
    local containerId
    local items = exports.ox_inventory:GetInventoryItems(target)

    for _, item in pairs(items or {}) do
        if item.name == itemName
           and item.metadata
           and item.metadata.rzExpiresAt == expiresAt then
            containerId = item.metadata.container
            break
        end
    end

    MySQL.insert([[
        INSERT INTO rz_secure_chests
            (container_id, item_name, owner_citizenid, owner_name,
             granted_by, expires_at, duration_hours)
        VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?), ?)
    ]], { containerId, itemName, citizenid, ownerName,
          grantedBy, expiresAt, hours })

    dbg(('coffre %s remis à %s pour %d h'):format(itemName, ownerName, hours))

    TriggerClientEvent('ox_lib:notify', target, {
        type        = 'success',
        title       = 'Coffre de sécurité reçu',
        description = ('Lié à toi pendant %s.'):format(formatRemaining(hours * 3600)),
        duration    = 10000,
    })

    return true, ('Coffre remis à %s pour %d h.'):format(ownerName, hours)
end

exports('GiveChest', GiveChest)


-- ═══════════════════════════════════════════════════════════════════
--  PROTECTION À L'UTILISATION
--
--  Un conteneur ox_inventory s'ouvre en faisant « Utiliser ». C'est
--  donc le premier verrou, et le plus important.
-- ═══════════════════════════════════════════════════════════════════

exports.ox_inventory:registerHook('usingItem', function(payload)
    local item = payload.item
    if not item or not Config.IsChest(item.name) then return true end

    local locked, remaining = chestState(item.metadata)
    if not locked then return true end

    local citizenid = getCitizenId(payload.source)

    if citizenid == item.metadata.rzOwner then
        return true
    end

    TriggerClientEvent('ox_lib:notify', payload.source, {
        type        = 'error',
        title       = 'Coffre verrouillé',
        description = ('Ce coffre appartient à %s.\nOuverture libre dans %s.')
            :format(item.metadata.rzOwnerName or 'un autre survivant',
                    formatRemaining(remaining)),
        duration    = 7000,
    })

    return false
end, { print = false })


-- ═══════════════════════════════════════════════════════════════════
--  PROTECTION À L'OUVERTURE DU CONTENEUR
--
--  Deuxième verrou : certains chemins ouvrent un conteneur sans
--  passer par « Utiliser ». On revérifie ici.
-- ═══════════════════════════════════════════════════════════════════

exports.ox_inventory:registerHook('openInventory', function(payload)
    if payload.inventoryType ~= 'container' then return true end
    if not payload.slot then return true end

    local item = exports.ox_inventory:GetSlot(payload.source, payload.slot)
    if not item or not Config.IsChest(item.name) then return true end

    local locked = chestState(item.metadata)
    if not locked then return true end

    local citizenid = getCitizenId(payload.source)
    if citizenid == item.metadata.rzOwner then return true end

    return false
end, { print = false })


-- ═══════════════════════════════════════════════════════════════════
--  BLOCAGE DU TRANSFERT
--
--  Un coffre sous protection est lié : il ne se donne pas, ne se
--  range pas chez un tiers. Le propriétaire peut le déplacer dans
--  son propre inventaire, rien de plus.
-- ═══════════════════════════════════════════════════════════════════

if Config.Behaviour.blockTransferWhileLocked then
    exports.ox_inventory:registerHook('swapItems', function(payload)
        local item = payload.fromSlot
        if not item or not Config.IsChest(item.name) then return true end

        local locked = chestState(item.metadata)
        if not locked then return true end

        -- Déplacement à l'intérieur de son propre inventaire : autorisé
        if payload.fromInventory == payload.toInventory then return true end

        local citizenid = getCitizenId(payload.source)
        if citizenid ~= item.metadata.rzOwner then return false end

        TriggerClientEvent('ox_lib:notify', payload.source, {
            type        = 'error',
            title       = 'Coffre lié',
            description = 'Tant qu\'il est sous protection, ce coffre ne peut pas quitter ton inventaire.',
            duration    = 6000,
        })

        return false
    end, { print = false })
end


-- ═══════════════════════════════════════════════════════════════════
--  RAFRAÎCHISSEMENT DE L'INFOBULLE
--
--  ox_inventory affiche metadata.description au survol. On le
--  réécrit pour que le décompte soit vivant — mais UNIQUEMENT quand
--  le texte change réellement. Passer de « 3 j 14 h » à « 3 j 14 h »
--  ne déclenche aucune écriture, donc aucun trafic réseau inutile.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Tooltip.refreshSeconds * 1000)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local items = exports.ox_inventory:GetInventoryItems(src)

            for slot, item in pairs(items or {}) do
                if Config.IsChest(item.name) and item.metadata
                   and item.metadata.rzExpiresAt then

                    local wanted = buildDescription(item.metadata)

                    if item.metadata.description ~= wanted then
                        local meta = item.metadata
                        meta.description = wanted
                        exports.ox_inventory:SetMetadata(src, slot, meta)
                    end
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  MORT DU JOUEUR
--
--  Un coffre encore sous protection ne tombe pas : c'est toute la
--  raison d'être du système. Un coffre expiré tombe comme le reste.
--
--  Cet export est destiné au futur script de sac mortuaire : il lui
--  dit quels slots ne doivent PAS être vidés.
-- ═══════════════════════════════════════════════════════════════════

---Slots à conserver lors d'une mort.
---@param source number
---@return table<number, true>
function GetProtectedSlots(source)
    local keep = {}

    if not Config.Behaviour.keepOnDeathWhileLocked then
        return keep
    end

    local citizenid = getCitizenId(source)
    local items = exports.ox_inventory:GetInventoryItems(source)

    for slot, item in pairs(items or {}) do
        if Config.IsChest(item.name) and item.metadata then
            local locked = chestState(item.metadata)

            -- Seul le coffre du propriétaire est préservé. Celui qu'on
            -- a ramassé sur un cadavre tombe normalement.
            if locked and item.metadata.rzOwner == citizenid then
                keep[slot] = true
            end
        end
    end

    return keep
end

exports('GetProtectedSlots', GetProtectedSlots)


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Marque en base les coffres arrivés à échéance. Purement
    -- informatif : la vérité reste dans les métadonnées de l'item.
    MySQL.prepare([[
        UPDATE rz_secure_chests
        SET status = 'expire'
        WHERE status = 'actif' AND expires_at < NOW()
    ]])

    dbg('démarré')
end)
