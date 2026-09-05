--[[
    rz_soins / server/main.lua

    Autorité sur l'inventaire (consommation, usure des outils), sur
    les chronomètres (virus, médicaments, drogues), sur la gueule de
    bois et sur la contagion. L'infection et la gueule de bois sont
    écrites dans les métadonnées du personnage (rzVirus, rzHangover)
    pour survivre à la déconnexion ; un bonus en cours, lui, s'arrête
    avec la déconnexion.
]]

local infected = {}     -- [src] = { strain, since, phase, warned }
local active   = {}     -- [src] = { [token] = { item, kind, endsAt } }
local hangover = {}     -- [src] = nombre de salines à prendre
local downedAt = {}     -- [src] = os.time() de la dernière chute (rz_mort)

local virusByItem = {}
for key, v in pairs(Config.Virus) do virusByItem[v.item] = key end

local function dbg(...)
    if Config.Debug then print('^3[rz_soins]^7', ...) end
end

local function notify(src, msg, type, title)
    TriggerClientEvent('ox_lib:notify', src, { title = title or 'Soins', description = msg, type = type or 'inform' })
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function isDowned(src)
    return Player(src).state.rzDowned == true
end

local function contains(t, v)
    for _, x in ipairs(t) do if x == v then return true end end
    return false
end

local function itemLabel(name)
    local it = exports.ox_inventory:Items(name)
    return it and it.label or name
end


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT VIRAL
-- ═══════════════════════════════════════════════════════════════════

local function saveVirus(src)
    local p = getPlayer(src)
    if not p then return end
    local i = infected[src]
    p.Functions.SetMetaData('rzVirus', i and { strain = i.strain, since = i.since } or false)
end

local function sendVirus(src)
    local i = infected[src]
    local state = false
    if i then
        state = { strain = i.strain, phase = i.phase,
                  remaining = math.max(0, Config.Virus[i.strain].safeMinutes * 60 - (os.time() - i.since)) }
    end
    TriggerClientEvent('rz_soins:virusState', src, state)
end

local function phaseOf(strain, since)
    return (os.time() - since) >= Config.Virus[strain].safeMinutes * 60 and 2 or 1
end

local function infect(src, strain, withBonus)
    local v = Config.Virus[strain]
    local since = os.time()
    if not withBonus then
        since = since - (v.safeMinutes * 60)     -- directement en phase 2
    end
    infected[src] = { strain = strain, since = since, phase = phaseOf(strain, since), warned = not withBonus }
    saveVirus(src)
    sendVirus(src)
    dbg(('infection %s -> %s (bonus %s)'):format(src, strain, tostring(withBonus)))
end

local function cure(src)
    infected[src] = nil
    saveVirus(src)
    sendVirus(src)
end


-- ═══════════════════════════════════════════════════════════════════
--  BONUS (médicaments, drogues) ET GUEULE DE BOIS
-- ═══════════════════════════════════════════════════════════════════

local function saveHangover(src)
    local p = getPlayer(src)
    if not p then return end
    p.Functions.SetMetaData('rzHangover', hangover[src] or 0)
end

local function bonusList(src)
    local list, now = {}, os.time()
    for token, b in pairs(active[src] or {}) do
        list[#list + 1] = { token = token, item = b.item, kind = b.kind, remaining = math.max(0, b.endsAt - now) }
    end
    return list
end

local function sendBonus(src)
    TriggerClientEvent('rz_soins:bonusState', src, bonusList(src), hangover[src] or 0)
end

local function hasActive(src, item)
    for _, b in pairs(active[src] or {}) do
        if b.item == item then return true end
    end
    return false
end

local function comedown(src, item)
    local cur = {
        hunger = tonumber(Player(src).state.hunger) or exports.qbx_core:GetMetadata(src, 'hunger') or 100,
        thirst = tonumber(Player(src).state.thirst) or exports.qbx_core:GetMetadata(src, 'thirst') or 100,
    }
    for k, loss in pairs(Config.Comedown) do
        exports.qbx_core:SetMetadata(src, k, math.max(0, cur[k] - loss))
    end
    notify(src, ('L\'effet du %s se dissipe. La faim et la soif te tombent dessus (-%d %%).')
        :format(itemLabel(item), Config.Comedown.hunger), 'warning', 'Médicament')
end

local function startBonus(src, item, kind, cfg)
    local token = ('%s_%d_%d'):format(item, os.time(), math.random(100000, 999999))
    active[src] = active[src] or {}
    active[src][token] = { item = item, kind = kind, endsAt = os.time() + cfg.duration }
    sendBonus(src)

    SetTimeout(cfg.duration * 1000, function()
        local a = active[src]
        if not a or not a[token] then return end     -- déconnecté, ou purgé
        a[token] = nil
        if not GetPlayerName(src) then return end

        if kind == 'med' then
            comedown(src, item)
        else
            hangover[src] = (hangover[src] or 0) + 1
            saveHangover(src)
            notify(src, ('%s : la descente. Une saline pour t\'en remettre (%d à prendre).')
                :format(itemLabel(item), hangover[src]), 'warning', 'Drogue')
        end
        sendBonus(src)
    end)
end

local function clearBonuses(src)
    active[src] = nil
    hangover[src] = 0
    saveHangover(src)
    sendBonus(src)
end


-- ═══════════════════════════════════════════════════════════════════
--  CHARGEMENT / DÉCONNEXION
-- ═══════════════════════════════════════════════════════════════════

local function restore(src)
    local p = getPlayer(src)
    if not p then return end
    local md = p.PlayerData.metadata or {}
    local v = md.rzVirus
    if v and v.strain and Config.Virus[v.strain] and v.since then
        infected[src] = { strain = v.strain, since = v.since, phase = phaseOf(v.strain, v.since), warned = false }
    else
        infected[src] = nil
    end
    hangover[src] = tonumber(md.rzHangover) or 0
    sendVirus(src)
    sendBonus(src)
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(1500, function() restore(src) end)
end)

AddEventHandler('playerDropped', function()
    infected[source] = nil
    active[source]   = nil
    hangover[source] = nil
    downedAt[source] = nil
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in pairs(exports.qbx_core:GetQBPlayers()) do
        restore(p.PlayerData.source)
    end
end)

-- Chute (rz_mort) : mémorisée pour valider la mort définitive
AddStateBagChangeHandler('rzDowned', nil, function(bagName, _, value)
    local src = GetPlayerFromStateBagName(bagName)
    if not src or src == 0 then return end
    if value then downedAt[src] = os.time() end
end)

-- Mort définitive : le virus part avec le corps
RegisterNetEvent('rz_soins:finalDeath', function()
    local src = source
    if not infected[src] then return end
    local t = downedAt[src]
    if t and os.time() - t <= 900 then
        cure(src)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS (pistolet injecteur, défibrillateurs, pipes)
-- ═══════════════════════════════════════════════════════════════════

local function findTool(src, name)
    local slots = exports.ox_inventory:Search(src, 'slots', name)
    if not slots then return end
    for _, s in ipairs(slots) do
        local d = s.metadata and tonumber(s.metadata.durability)
        if d == nil or d > 0 then return s end
    end
end

local function wearTool(src, slot, per)
    local md = slot.metadata or {}
    md.durability = math.max(0, (tonumber(md.durability) or 100) - per)
    exports.ox_inventory:SetMetadata(src, slot.slot, md)
    return md.durability
end


-- ═══════════════════════════════════════════════════════════════════
--  CONTRÔLES AVANT USAGE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_soins:canUseMed', function(src, itemName)
    if not Config.Medicaments[itemName] then return false, 'Objet inconnu.' end
    if isDowned(src) then return false, 'Impossible à terre.' end
    if hasActive(src, itemName) then
        return false, ('Tu es déjà sous l\'effet de %s.'):format(itemLabel(itemName))
    end
    return true
end)

lib.callback.register('rz_soins:canUseDrogue', function(src, itemName)
    local cfg = Config.Drogues[itemName]
    if not cfg then return false, 'Objet inconnu.' end
    if isDowned(src) then return false, 'Impossible à terre.' end
    if hasActive(src, itemName) then
        return false, ('Tu es déjà sous l\'effet de %s.'):format(itemLabel(itemName))
    end
    if cfg.tool and not findTool(src, cfg.tool) then
        return false, ('Il te faut : %s.'):format(itemLabel(cfg.tool))
    end
    return true
end)

lib.callback.register('rz_soins:canInject', function(src, itemName)
    local strain = virusByItem[itemName]
    local anti   = Config.Antivirus[itemName]
    if not strain and not anti then return false, 'Objet inconnu.' end
    if isDowned(src) then return false, 'Impossible à terre.' end
    if not findTool(src, Config.Injector) then
        return false, 'Il te faut un pistolet injecteur en état de marche.'
    end

    local i = infected[src]
    if strain then
        if i then return false, ('Tu es déjà infecté (%s).'):format(Config.Virus[i.strain].label) end
    else
        if not i then return false, 'Tu n\'es pas infecté.' end
        if not contains(anti.cures, i.strain) then
            return false, 'Cet antivirus n\'agit pas sur cette souche.'
        end
    end
    return true
end)

lib.callback.register('rz_soins:canUnpack', function(src, itemName)
    local cfg = Config.Deballage[itemName]
    if not cfg then return false, 'Objet inconnu.' end
    if not exports.ox_inventory:CanCarryItem(src, cfg.item, cfg.count) then
        return false, ('Il te faut de la place pour %d × %s.'):format(cfg.count, itemLabel(cfg.item))
    end
    return true
end)

lib.callback.register('rz_soins:status', function(src)
    local i = infected[src]
    if not i then return false end
    local safe = Config.Virus[i.strain].safeMinutes * 60
    return { strain = i.strain, phase = i.phase, remaining = safe - (os.time() - i.since) }
end)


-- ═══════════════════════════════════════════════════════════════════
--  EFFETS APRÈS CONSOMMATION (ox_inventory:usedItem)
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('ox_inventory:usedItem', function(src, itemName)
    -- déballage
    local unpack = Config.Deballage[itemName]
    if unpack then
        exports.ox_inventory:AddItem(src, unpack.item, unpack.count)
        notify(src, ('+%d × %s'):format(unpack.count, itemLabel(unpack.item)), 'success')
        return
    end

    -- saline pendant une gueule de bois
    if Config.SalineItems[itemName] and (hangover[src] or 0) > 0 then
        hangover[src] = hangover[src] - 1
        saveHangover(src)
        if hangover[src] > 0 then
            notify(src, ('Ça va un peu mieux. Encore %d saline(s).'):format(hangover[src]), 'inform', 'Drogue')
        else
            notify(src, 'Les idées redeviennent claires.', 'success', 'Drogue')
        end
        sendBonus(src)
        return
    end

    -- médicament
    local med = Config.Medicaments[itemName]
    if med then
        if hasActive(src, itemName) then return notify(src, 'Déjà sous effet : la dose est perdue.', 'error') end
        startBonus(src, itemName, 'med', med)
        notify(src, ('%s : effet pendant %d min. La descente suivra.')
            :format(itemLabel(itemName), math.floor(med.duration / 60)), 'success', 'Médicament')
        return
    end

    -- drogue
    local drug = Config.Drogues[itemName]
    if drug then
        if hasActive(src, itemName) then return notify(src, 'Déjà sous effet : la dose est perdue.', 'error') end
        if drug.tool then
            local slot = findTool(src, drug.tool)
            if not slot then return notify(src, ('Sans %s, la dose est perdue.'):format(itemLabel(drug.tool)), 'error') end
            if wearTool(src, slot, Config.DrugToolWear) <= 0 then
                notify(src, ('%s hors d\'usage.'):format(itemLabel(drug.tool)), 'error')
            end
        end
        startBonus(src, itemName, 'drogue', drug)
        notify(src, ('%s : effet pendant %d min. Il faudra une saline après.')
            :format(itemLabel(itemName), math.floor(drug.duration / 60)), 'success', 'Drogue')
        return
    end

    -- virus / antivirus
    local strain = virusByItem[itemName]
    local anti   = Config.Antivirus[itemName]
    if not strain and not anti then return end

    local inj = findTool(src, Config.Injector)
    if not inj then
        return notify(src, 'Sans pistolet injecteur, la dose est perdue.', 'error')
    end
    local left = wearTool(src, inj, Config.Tools[Config.Injector].wearPerUse)

    if strain then
        if infected[src] then return notify(src, 'Déjà infecté : la dose est perdue.', 'error') end
        infect(src, strain, true)
        local v = Config.Virus[strain]
        notify(src, ('%s dans le sang. Bonus pendant %d min, puis il te faudra l\'antivirus.')
            :format(v.label, v.safeMinutes), 'success', 'Virus')
    else
        local i = infected[src]
        if i and contains(anti.cures, i.strain) then
            cure(src)
            notify(src, 'Le virus est neutralisé. Le bonus disparaît avec lui.', 'success', 'Virus')
        else
            notify(src, 'Rien à neutraliser : la dose est perdue.', 'error')
        end
    end

    if left <= 0 then
        notify(src, 'Ton pistolet injecteur est hors d\'usage.', 'error')
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  SOIGNER QUELQU'UN D'AUTRE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_soins:healOther', function(src, targetId, itemName)
    targetId = tonumber(targetId)
    if not targetId or targetId == src or not GetPlayerName(targetId) then
        return false, 'Personne à soigner.'
    end
    if isDowned(src) then return false, 'Impossible à terre.' end
    if isDowned(targetId) then return false, 'Il est à terre : il lui faut un épipen.' end

    local srcPed, tgtPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if #(GetEntityCoords(srcPed) - GetEntityCoords(tgtPed)) > Config.TargetDistance + 1.5 then
        return false, 'Trop loin.'
    end

    local pv
    local tool = Config.Tools[itemName]
    if tool and tool.pv then
        local slot = findTool(src, itemName)
        if not slot then return false, ('Pas de %s en état de marche.'):format(itemLabel(itemName)) end
        wearTool(src, slot, tool.wearPerUse)
        pv = tool.pv
    else
        local cfg = Config.Soins[itemName]
        if not cfg or not cfg.others then return false, 'Cet objet ne se pose pas sur quelqu\'un d\'autre.' end
        if not exports.ox_inventory:RemoveItem(src, itemName, 1) then
            return false, 'Tu n\'as plus cet objet.'
        end
        pv = cfg.pv
    end

    local label = itemLabel(itemName)
    TriggerClientEvent('rz_soins:heal', targetId, pv, label)
    return true, ('%s : +%d PV pour %s.'):format(label, pv, GetPlayerName(targetId))
end)


-- ═══════════════════════════════════════════════════════════════════
--  CONTAGION (souche T, phase 2)
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_soins:contagion', function(targetId)
    local src = source
    local i = infected[src]
    targetId = tonumber(targetId)
    if not i or i.phase ~= 2 then return end
    local v = Config.Virus[i.strain]
    if not v.contagious or not targetId or targetId == src or not GetPlayerName(targetId) then return end
    if infected[targetId] or isDowned(targetId) then return end

    local d = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId)))
    if d > v.contagious.radius + 1.0 then return end

    infect(targetId, i.strain, false)
    notify(targetId, 'Une fièvre te prend. Quelque chose ne va pas.', 'error', 'Virus')
end)


-- ═══════════════════════════════════════════════════════════════════
--  BOUCLE VIRALE : avertissements, bascule en phase 2, dégâts
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Tick * 1000)
        local now = os.time()

        for src, i in pairs(infected) do
            if not GetPlayerName(src) then
                infected[src] = nil
            else
                local v = Config.Virus[i.strain]
                local remaining = v.safeMinutes * 60 - (now - i.since)

                if i.phase == 1 then
                    if remaining <= 0 then
                        i.phase = 2
                        sendVirus(src)
                        notify(src, ('%s : le virus se retourne contre toi. -%d PV par minute jusqu\'à l\'antivirus.')
                            :format(v.label, v.damagePerMinute), 'error', 'Virus')
                    elseif not i.warned and remaining <= Config.WarnMinutes * 60 then
                        i.warned = true
                        notify(src, ('%s : encore %d min de bonus. Prépare l\'antivirus.')
                            :format(v.label, math.ceil(remaining / 60)), 'warning', 'Virus')
                    end
                end

                if i.phase == 2 and not isDowned(src) then
                    TriggerClientEvent('rz_soins:drain', src, v.damagePerMinute * Config.Tick / 60)
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  EXPORTS ADMIN (menu admin : boutons « Annuler les effets » et
--  « Soigner », à côté de « Réanimer »)
-- ═══════════════════════════════════════════════════════════════════

-- Annule tout : virus, bonus en cours (médicaments, drogues) et
-- gueule de bois. Le client remet vie max, armure, démarche et
-- compteur à la normale en recevant les états vides.
exports('AdminClearEffects', function(targetId)
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return false end
    cure(targetId)
    clearBonuses(targetId)
    TriggerClientEvent('rz_soins:adminReset', targetId)
    notify(targetId, 'Un membre du staff a annulé tous tes effets.', 'inform', 'Staff')
    return true
end)

-- Remet le joueur en pleine santé (vie et armure). Ne relève pas un
-- joueur à terre : c'est le rôle de « Réanimer ».
exports('AdminHeal', function(targetId)
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return false end
    TriggerClientEvent('rz_soins:adminHeal', targetId)
    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  ADMIN : /virus_admin <id> <t|n|v>   /guerir <id>
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('virus_admin', {
    help = 'Infecter un joueur (test)',
    restricted = Config.AdminGroup,
    params = {
        { name = 'id', type = 'playerId', help = 'ID du joueur' },
        { name = 'souche', type = 'string', help = 't, n ou v' },
    },
}, function(src, args)
    if not Config.Virus[args.souche] then return notify(src, 'Souche inconnue (t, n, v).', 'error') end
    infect(args.id, args.souche, true)
    notify(src, ('Joueur %d infecté (%s).'):format(args.id, args.souche), 'success')
end)

lib.addCommand('guerir', {
    help = 'Guérir un joueur : virus, bonus en cours et gueule de bois',
    restricted = Config.AdminGroup,
    params = { { name = 'id', type = 'playerId', help = 'ID du joueur' } },
}, function(src, args)
    cure(args.id)
    clearBonuses(args.id)
    notify(src, ('Joueur %d guéri.'):format(args.id), 'success')
end)
