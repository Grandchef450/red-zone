-- ============================================================
--  RZ VIP | server/main.lua — QBCore, persistance JSON (0 DB)
--  TOUT est valide ici : grades, peds, reanimations, craft,
--  boutique materiaux, farm. Le client ne decide jamais rien.
-- ============================================================

local QBCore = exports['qb-core']:GetCoreObject()
local RES = GetCurrentResourceName()

local function dbg(msg)
    if Config.Debug then print(('^5[rz_vip:sv]^7 %s'):format(msg)) end
end

-- ============================================================
--  LOOKUPS CONFIG
-- ============================================================

local TIER_BY_ID = {}
for _, t in ipairs(Config.Tiers) do TIER_BY_ID[t.id] = t end

local PED_BY_MODEL = {}
for _, p in ipairs(Config.Peds) do PED_BY_MODEL[p.model] = p end

local SHOP_BY_ID = {}
for _, s in ipairs(Config.MaterialShop) do SHOP_BY_ID[s.id] = s end

local MATERIAL_SET = {}
for _, m in ipairs(Config.Materials) do MATERIAL_SET[m.item] = true end

-- ============================================================
--  PERSISTANCE — vip.json
--  players[citizenid] = {
--    tier, since, peds = {model,...},
--    lastFreeRevive,                       -- grades 1-3
--    kits, usedCount, craftLockUntil,      -- grades 4-6
--    windowStart, windowCrafted,           -- grade 7
--  }
-- ============================================================

local db = { players = {} }

local function loadDb()
    local raw = LoadResourceFile(RES, Config.VipFile)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' and type(data.players) == 'table' then
            db = data
            local n = 0; for _ in pairs(db.players) do n = n + 1 end
            dbg(('vip.json charge — %d joueur(s) VIP'):format(n))
            return
        end
        print('^1[rz_vip:sv]^7 vip.json corrompu — reinitialise en memoire (non ecrase avant prochaine sauvegarde)')
    end
    db = { players = {} }
end

local function saveDb()
    if not SaveResourceFile(RES, Config.VipFile, json.encode(db, { indent = true }), -1) then
        print('^1[rz_vip:sv]^7 ECHEC ecriture vip.json')
    end
end

loadDb()

local function getRecord(cid)
    if not db.players[cid] then
        db.players[cid] = {
            tier = 0, since = 0, peds = {},
            lastFreeRevive = 0,
            kits = 0, usedCount = 0, craftLockUntil = 0,
            windowStart = 0, windowCrafted = 0,
        }
    end
    return db.players[cid]
end

-- ============================================================
--  HELPERS JOUEUR
-- ============================================================

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

local function cidOf(Player)
    return Player.PlayerData.citizenid
end

local function notifyResult(src, ok, msg)
    TriggerClientEvent('rz_vip:client:result', src, { ok = ok, msg = msg })
end

-- Quantites de materiaux du joueur (pour l'UI et les verifications)
local function getMaterialCounts(Player)
    local counts = {}
    for _, m in ipairs(Config.Materials) do
        local it = Player.Functions.GetItemByName(m.item)
        counts[m.item] = (it and it.amount) or 0
    end
    return counts
end

-- Verifie et retire un cout { item = qty } — tout ou rien
local function chargeMaterials(Player, cost)
    for item, qty in pairs(cost) do
        local it = Player.Functions.GetItemByName(item)
        if not it or it.amount < qty then
            return false, item
        end
    end
    for item, qty in pairs(cost) do
        Player.Functions.RemoveItem(item, qty)
    end
    return true
end

-- ============================================================
--  ETAT COMPLET POUR L'UI
-- ============================================================

local function buildState(src, Player)
    local rec = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    local now = os.time()

    -- Etat reanimation selon le grade
    local revive = { mode = 'none' }
    if tier then
        if tier.freeReviveHours then
            local readyAt = rec.lastFreeRevive + tier.freeReviveHours * 3600
            revive = {
                mode = 'free',
                cooldownHours = tier.freeReviveHours,
                readyIn = math.max(0, readyAt - now),
            }
        elseif tier.craft then
            if tier.craft.quota then
                -- Grade 7 : quota par fenetre glissante
                local windowEnd = rec.windowStart + tier.craft.windowHours * 3600
                local crafted = (now < windowEnd) and rec.windowCrafted or 0
                revive = {
                    mode = 'quota',
                    kits = rec.kits, max = tier.craft.quota,
                    quotaLeft = tier.craft.quota - crafted,
                    windowHours = tier.craft.windowHours,
                    windowResetIn = (crafted > 0 and now < windowEnd) and (windowEnd - now) or 0,
                    craftCost = Config.ReviveKitCost,
                }
            else
                -- Grades 4-6 : stock max + verrou apres epuisement
                revive = {
                    mode = 'craft',
                    kits = rec.kits, max = tier.craft.max,
                    lockHours = tier.craft.lockHours,
                    lockRemain = math.max(0, rec.craftLockUntil - now),
                    craftCost = Config.ReviveKitCost,
                }
            end
        end
    end

    return {
        tier      = rec.tier,
        tiers     = Config.Tiers,
        peds      = Config.Peds,
        ownedPeds = rec.peds,
        pedSlots  = tier and tier.pedSlots or 0,
        revive    = revive,
        materials = getMaterialCounts(Player),
        matDefs   = Config.Materials,
        shop      = Config.MaterialShop,
        money     = Player.PlayerData.money[Config.PayAccount] or 0,
        payAccount = Config.PayAccount,
        upgradeDiff = Config.UpgradePayDifference,
        farmSpots = Config.FarmSpots,
    }
end

local function pushState(src, Player)
    TriggerClientEvent('rz_vip:client:state', src, buildState(src, Player))
end

-- ============================================================
--  OUVERTURE
-- ============================================================

RegisterNetEvent('rz_vip:server:requestOpen', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    TriggerClientEvent('rz_vip:client:open', src, buildState(src, Player))
end)

RegisterNetEvent('rz_vip:server:refresh', function()
    local src = source
    local Player = getPlayer(src)
    if Player then pushState(src, Player) end
end)

-- ============================================================
--  ACHAT DE GRADE
-- ============================================================

RegisterNetEvent('rz_vip:server:buyTier', function(tierId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local tier = TIER_BY_ID[tonumber(tierId) or -1]
    if not tier then notifyResult(src, false, 'Grade inconnu') return end

    local rec = getRecord(cidOf(Player))
    if tier.id <= rec.tier then
        notifyResult(src, false, 'Tu possèdes déjà ce grade (ou un supérieur)')
        return
    end

    -- Prix : difference si upgrade et option activee
    local price = tier.price
    if Config.UpgradePayDifference and rec.tier > 0 then
        price = tier.price - (TIER_BY_ID[rec.tier] and TIER_BY_ID[rec.tier].price or 0)
    end
    price = math.max(0, price)

    if not Player.Functions.RemoveMoney(Config.PayAccount, price, 'achat-vip') then
        notifyResult(src, false, ('Fonds insuffisants (%s$ requis en %s)'):format(price, Config.PayAccount))
        return
    end

    rec.tier  = tier.id
    rec.since = os.time()
    -- Coupe les peds excedentaires si jamais (securite)
    while #rec.peds > (tier.pedSlots or 0) do table.remove(rec.peds) end
    saveDb()

    print(('^2[rz_vip:sv]^7 %s (%s) a achete %s pour %d$'):format(Player.PlayerData.name or '?', cidOf(Player), tier.label, price))
    notifyResult(src, true, ('%s activé ! (-%d$)'):format(tier.label, price))
    pushState(src, Player)
end)

-- ============================================================
--  PEDS — choix (slots) + vestiaire (application)
-- ============================================================

RegisterNetEvent('rz_vip:server:choosePed', function(model)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    model = tostring(model or '')
    local ped = PED_BY_MODEL[model]
    if not ped then notifyResult(src, false, 'Ped inconnu') return end

    local rec  = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    local slots = tier and tier.pedSlots or 0
    if slots == 0 then notifyResult(src, false, 'Ton grade ne permet pas de choisir de ped') return end

    for _, m in ipairs(rec.peds) do
        if m == model then notifyResult(src, false, 'Tu possèdes déjà ce ped') return end
    end
    if #rec.peds >= slots then
        notifyResult(src, false, ('Tous tes slots de ped sont utilisés (%d/%d)'):format(#rec.peds, slots))
        return
    end

    -- Ped premium : paye en plus
    if (ped.price or 0) > 0 then
        if not Player.Functions.RemoveMoney(Config.PayAccount, ped.price, 'achat-ped-vip') then
            notifyResult(src, false, ('Fonds insuffisants pour ce ped premium (%d$)'):format(ped.price))
            return
        end
    end

    rec.peds[#rec.peds + 1] = model
    saveDb()
    notifyResult(src, true, ('Ped "%s" ajouté à ton vestiaire'):format(ped.label))
    pushState(src, Player)
end)

RegisterNetEvent('rz_vip:server:applyPed', function(model)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    model = tostring(model or '')

    local rec  = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    -- Le vestiaire est un avantage de TOUS les grades VIP
    if not tier then notifyResult(src, false, 'Le vestiaire est réservé aux VIP') return end

    local owned = false
    for _, m in ipairs(rec.peds) do
        if m == model then owned = true break end
    end
    if not owned then notifyResult(src, false, 'Tu ne possèdes pas ce ped') return end

    TriggerClientEvent('rz_vip:client:applyPed', src, model)
    notifyResult(src, true, 'Ped appliqué')
end)

-- ============================================================
--  REANIMATIONS
-- ============================================================

-- Grades 1-3 : reanimation gratuite avec cooldown
RegisterNetEvent('rz_vip:server:useFreeRevive', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local rec  = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    if not tier or not tier.freeReviveHours then
        notifyResult(src, false, 'Ton grade n\'a pas de réanimation gratuite')
        return
    end
    local now = os.time()
    local readyAt = rec.lastFreeRevive + tier.freeReviveHours * 3600
    if now < readyAt then
        local mins = math.ceil((readyAt - now) / 60)
        notifyResult(src, false, ('Réanimation disponible dans %dh%02d'):format(mins // 60, mins % 60))
        return
    end
    rec.lastFreeRevive = now
    saveDb()
    TriggerClientEvent(Config.ReviveEvent, src)
    notifyResult(src, true, 'Réanimation instantanée utilisée !')
    pushState(src, Player)
end)

-- Grades 4-7 : crafter un kit
RegisterNetEvent('rz_vip:server:craftKit', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local rec  = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    if not tier or not tier.craft then
        notifyResult(src, false, 'Ton grade ne permet pas de crafter des réanimations')
        return
    end
    local now = os.time()

    if tier.craft.quota then
        -- Grade 7 : fenetre de 12h
        local windowEnd = rec.windowStart + tier.craft.windowHours * 3600
        if now >= windowEnd then
            rec.windowStart, rec.windowCrafted = now, 0
        end
        if rec.windowCrafted >= tier.craft.quota then
            local mins = math.ceil((rec.windowStart + tier.craft.windowHours * 3600 - now) / 60)
            notifyResult(src, false, ('Quota atteint (%d/%dh) — reset dans %dh%02d')
                :format(tier.craft.quota, tier.craft.windowHours, mins // 60, mins % 60))
            return
        end
        if rec.kits >= tier.craft.quota then
            notifyResult(src, false, 'Stock de kits plein')
            return
        end
    else
        -- Grades 4-6
        if now < rec.craftLockUntil then
            local mins = math.ceil((rec.craftLockUntil - now) / 60)
            notifyResult(src, false, ('Crafting verrouillé — dispo dans %dh%02d'):format(mins // 60, mins % 60))
            return
        end
        if rec.kits >= tier.craft.max then
            notifyResult(src, false, ('Stock plein (%d/%d)'):format(rec.kits, tier.craft.max))
            return
        end
    end

    local ok, missing = chargeMaterials(Player, Config.ReviveKitCost)
    if not ok then
        notifyResult(src, false, ('Matériaux insuffisants (%s manquant)'):format(missing))
        return
    end

    rec.kits = rec.kits + 1
    if tier.craft.quota then
        rec.windowCrafted = rec.windowCrafted + 1
    end
    saveDb()
    notifyResult(src, true, ('Kit de réanimation crafté (%d en stock)'):format(rec.kits))
    pushState(src, Player)
end)

-- Grades 4-7 : utiliser un kit
RegisterNetEvent('rz_vip:server:useKit', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local rec  = getRecord(cidOf(Player))
    local tier = TIER_BY_ID[rec.tier]
    if not tier or not tier.craft then
        notifyResult(src, false, 'Ton grade n\'utilise pas de kits')
        return
    end
    if rec.kits <= 0 then
        notifyResult(src, false, 'Aucun kit en stock — crafte-en un')
        return
    end

    rec.kits = rec.kits - 1

    -- Grades 4-6 : une fois les `max` kits UTILISES, verrou de lockHours
    if tier.craft.max then
        rec.usedCount = (rec.usedCount or 0) + 1
        if rec.usedCount >= tier.craft.max then
            rec.craftLockUntil = os.time() + tier.craft.lockHours * 3600
            rec.usedCount = 0
        end
    end

    saveDb()
    TriggerClientEvent(Config.ReviveEvent, src)
    notifyResult(src, true, ('Réanimation utilisée (%d kit(s) restant(s))'):format(rec.kits))
    pushState(src, Player)
end)

-- ============================================================
--  BOUTIQUE MATERIAUX
-- ============================================================

RegisterNetEvent('rz_vip:server:buyShopItem', function(itemId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local entry = SHOP_BY_ID[tostring(itemId or '')]
    if not entry then notifyResult(src, false, 'Article inconnu') return end

    local ok, missing = chargeMaterials(Player, entry.cost)
    if not ok then
        notifyResult(src, false, ('Matériaux insuffisants (%s manquant)'):format(missing))
        return
    end

    if entry.give.type == 'item' then
        Player.Functions.AddItem(entry.give.name, entry.give.amount or 1)
        TriggerClientEvent('inventory:client:ItemBox', src,
            QBCore.Shared.Items[entry.give.name], 'add', entry.give.amount or 1)
    elseif entry.give.type == 'revive_hospital' then
        TriggerClientEvent('rz_vip:client:reviveHospital', src, Config.Hospital)
    end

    print(('^2[rz_vip:sv]^7 %s a achete "%s" en materiaux'):format(Player.PlayerData.name or '?', entry.label))
    notifyResult(src, true, ('"%s" acheté !'):format(entry.label))
    pushState(src, Player)
end)

-- ============================================================
--  FARM — validation serveur (distance + anti-macro)
-- ============================================================

local lastFarm = {} -- [src] = timestamp

RegisterNetEvent('rz_vip:server:farm', function(spotIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local spot = Config.FarmSpots[tonumber(spotIndex) or -1]
    if not spot then return end

    local now = os.time()
    if lastFarm[src] and now - lastFarm[src] < Config.FarmCooldown then return end

    -- Verification de distance cote serveur (anti-triche)
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    local dist = #(pos - vector3(spot.x, spot.y, spot.z))
    if dist > 5.0 then
        print(('^1[rz_vip:sv]^7 farm refuse (distance %.1fm) pour %s'):format(dist, Player.PlayerData.name or src))
        return
    end

    lastFarm[src] = now
    local amount = math.random(spot.min, spot.max)
    Player.Functions.AddItem(spot.material, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[spot.material], 'add', amount)
    TriggerClientEvent('rz_vip:client:farmed', src, spot.material, amount)
end)

AddEventHandler('playerDropped', function()
    lastFarm[source] = nil
end)

-- ============================================================
--  ADMIN — /setvip <idServeur> <grade 0-7> (console ou ace rz.vip)
-- ============================================================

RegisterCommand('setvip', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'rz.vip') then return end
    local target = tonumber(args[1])
    local tierId = tonumber(args[2])
    if not target or not tierId or (tierId ~= 0 and not TIER_BY_ID[tierId]) then
        print('Usage: setvip <idServeur> <0-7>')
        return
    end
    local Player = getPlayer(target)
    if not Player then print('Joueur introuvable') return end

    local rec = getRecord(cidOf(Player))
    rec.tier  = tierId
    rec.since = os.time()
    local tier = TIER_BY_ID[tierId]
    while #rec.peds > (tier and tier.pedSlots or 0) do table.remove(rec.peds) end
    saveDb()
    print(('^2[rz_vip:sv]^7 setvip : %s → grade %d'):format(Player.PlayerData.name or '?', tierId))
    notifyResult(target, true, tierId > 0 and ('Grade %s accordé par le staff'):format(tier.label) or 'Grade VIP retiré')
    pushState(target, Player)
end, true)
