--[[
    rz_sacs / server/main.lua

    Usure des sacs à dos, uniquement à l'ouverture.

    POURQUOI PAS `degrade` D'OX_INVENTORY : ce champ fait décroître la
    durabilité avec le TEMPS, y compris quand le sac dort au fond d'un
    coffre. Ce n'est pas ce qui est voulu — et le serveur RedZone n'a
    aucune péremption. On gère donc la décrémentation à la main, en
    réutilisant le champ `durability` qu'ox_inventory affiche déjà
    sous forme de barre dans l'infobulle.
]]

-- Anti double-comptage : [source] = { [slot] = timestamp }
local lastWear = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_sacs]^7', ...) end
end


local function notify(source, kind, title, description, duration)
    TriggerClientEvent('ox_lib:notify', source, {
        type        = kind,
        title       = title,
        description = description,
        duration    = duration or 5000,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉCHIRURE
--
--  À 0 %, le sac cède. Son contenu tombe aux pieds du joueur plutôt
--  que de disparaître : perdre son sac est une punition suffisante,
--  perdre tout ce qu'il y avait dedans serait de la cruauté.
-- ═══════════════════════════════════════════════════════════════════

local function tearBag(source, slot, item)
    local containerId = item.metadata and item.metadata.container
    local dropped = 0

    if containerId then
        local contents = exports.ox_inventory:GetInventoryItems(containerId)

        if contents and next(contents) then
            local ped    = GetPlayerPed(source)
            local coords = GetEntityCoords(ped)

            local loot = {}
            for _, entry in pairs(contents) do
                loot[#loot + 1] = {
                    entry.name,
                    entry.count,
                    entry.metadata,
                }
                dropped = dropped + 1
            end

            exports.ox_inventory:CustomDrop(
                'Sac déchiré',
                loot,
                coords.x, coords.y, coords.z - 0.9
            )

            -- Vide le conteneur : son contenu est désormais au sol
            exports.ox_inventory:ClearInventory(containerId)
        end
    end

    exports.ox_inventory:RemoveItem(source, item.name, 1, item.metadata, slot)

    notify(source, 'error', 'Ton sac a cédé',
        dropped > 0
            and ('Les coutures ont lâché. %d pile(s) d\'objets sont tombées à tes pieds.')
                :format(dropped)
            or  'Les coutures ont lâché. Il était vide.',
        12000)

    dbg(('sac déchiré chez %s : %d piles au sol'):format(source, dropped))
end


-- ═══════════════════════════════════════════════════════════════════
--  USURE À L'OUVERTURE
-- ═══════════════════════════════════════════════════════════════════

local function wearBag(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item then return end

    local bag = Config.GetBag(item.name)
    if not bag then return end

    -- Anti double-comptage
    local now = os.time()
    lastWear[source] = lastWear[source] or {}

    if lastWear[source][slot] and (now - lastWear[source][slot]) < Config.Wear.cooldown then
        return
    end
    lastWear[source][slot] = now

    local metadata = item.metadata or {}
    local current  = tonumber(metadata.durability) or 100
    local wear     = Config.GetWearPerOpen(item.name)

    local newValue = math.max(0, current - wear)

    -- Arrondi à deux décimales : sur un sac de 7000 ouvertures, la
    -- perte unitaire vaut 0,0143 point. Sans cet arrondi, on
    -- accumulerait des flottants illisibles dans les métadonnées.
    newValue = math.floor(newValue * 100 + 0.5) / 100

    metadata.durability = newValue

    if newValue <= 0 then
        if Config.Wear.onBroken == 'tear' then
            -- Petit délai : laisse l'interface finir d'ouvrir le
            -- conteneur avant qu'on le supprime sous ses pieds.
            SetTimeout(400, function() tearBag(source, slot, item) end)
        else
            exports.ox_inventory:SetMetadata(source, slot, metadata)
            notify(source, 'error', 'Sac hors d\'usage',
                'Il faut le réparer avant de pouvoir l\'ouvrir de nouveau.', 8000)
        end
        return
    end

    exports.ox_inventory:SetMetadata(source, slot, metadata)

    -- Avertissements : on ne prévient qu'au moment du franchissement,
    -- pas à chaque ouverture en dessous du seuil.
    if current > Config.Wear.criticalAt and newValue <= Config.Wear.criticalAt then
        notify(source, 'error', 'Sac au bord de la rupture',
            ('Il ne reste que %.0f %%. Répare-le ou vide-le.'):format(newValue), 10000)

    elseif current > Config.Wear.warnAt and newValue <= Config.Wear.warnAt then
        notify(source, 'warning', 'Sac usé',
            ('Durabilité à %.0f %%. Pense à le réparer.'):format(newValue), 7000)
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  ACCROCHE
--
--  Le hook openInventory ne doit PAS bloquer : on laisse le sac
--  s'ouvrir, et on décrémente juste après. Décrémenter dans le hook
--  lui-même provoquerait un conflit avec l'ouverture en cours.
-- ═══════════════════════════════════════════════════════════════════

exports.ox_inventory:registerHook('openInventory', function(payload)
    if payload.inventoryType ~= 'container' then return true end
    if not payload.slot then return true end

    local source, slot = payload.source, payload.slot

    SetTimeout(150, function()
        wearBag(source, slot)
    end)

    return true
end, { print = false })


AddEventHandler('playerDropped', function()
    lastWear[source] = nil
end)


-- ═══════════════════════════════════════════════════════════════════
--  RÉPARATION
--
--  Chaque réparation abaisse le plafond de durabilité. Un sac
--  recousu six fois plafonne à 40 % et n'est plus réparable — il
--  faut en crafter un neuf. Sans ce plafond dégressif, un seul sac
--  durerait éternellement et le craft de sacs n'aurait plus d'usage.
-- ═══════════════════════════════════════════════════════════════════

---@return boolean ok, string message
function RepairBag(source, slot)
    if not Config.Repair.enabled then
        return false, 'La réparation est désactivée.'
    end

    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item then return false, 'Sac introuvable.' end

    local bag = Config.GetBag(item.name)
    if not bag then return false, 'Cet objet n\'est pas un sac.' end

    local metadata = item.metadata or {}
    local current  = tonumber(metadata.durability) or 100
    local cap      = tonumber(metadata.rzCap) or 100

    if current >= cap then
        return false, ('Ce sac est déjà au maximum (%d %%).'):format(cap)
    end

    local newCap = cap - Config.Repair.capLossPerRepair
    if newCap < Config.Repair.minCap then
        return false, 'Ce sac est trop abîmé pour être réparé. Il faut en crafter un neuf.'
    end

    -- Coût proportionnel à la taille du sac
    local needed = {}
    for _, mat in ipairs(Config.Repair.materials) do
        local qty = math.max(1, math.ceil(bag.slots / mat.divisor))
        needed[#needed + 1] = { item = mat.item, qty = qty }

        if exports.ox_inventory:GetItemCount(source, mat.item) < qty then
            return false, ('Il te faut %d × %s.'):format(qty, mat.item)
        end
    end

    for _, mat in ipairs(needed) do
        exports.ox_inventory:RemoveItem(source, mat.item, mat.qty)
    end

    metadata.durability = newCap
    metadata.rzCap      = newCap
    metadata.rzRepairs  = (tonumber(metadata.rzRepairs) or 0) + 1

    exports.ox_inventory:SetMetadata(source, slot, metadata)

    return true, ('Sac réparé — %d %% (plafond abaissé, réparation n°%d).')
        :format(newCap, metadata.rzRepairs)
end

exports('RepairBag', RepairBag)


lib.callback.register('rz_sacs:repair', function(source, slot)
    return RepairBag(source, slot)
end)


-- ═══════════════════════════════════════════════════════════════════
--  DIAGNOSTIC
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('sacinfo', {
    help = 'État d\'usure des sacs que tu portes',
}, function(source)
    local items = exports.ox_inventory:GetInventoryItems(source)
    local lines = {}

    for slot, item in pairs(items or {}) do
        local bag = Config.GetBag(item.name)
        if bag then
            local d   = tonumber(item.metadata and item.metadata.durability) or 100
            local cap = tonumber(item.metadata and item.metadata.rzCap) or 100
            local left = math.floor(d / 100 * bag.opens)

            lines[#lines + 1] = ('Slot %d — %s : %.1f %% (plafond %d %%)  ~%d ouvertures')
                :format(slot, item.name, d, cap, left)
        end
    end

    if #lines == 0 then
        return notify(source, 'inform', 'Sacs', 'Tu ne portes aucun sac.')
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header   = 'État de tes sacs',
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end)
