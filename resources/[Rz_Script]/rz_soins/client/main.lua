--[[
    rz_soins / client/main.lua

    Soins sur soi (export ox_inventory), soins sur les autres
    (ox_target), médicaments et drogues à bonus cumulables, gueule de
    bois, état viral (bonus en phase 1, symptômes et dégâts en
    phase 2) et compteur en haut à gauche. Le serveur décide de tout
    ce qui touche à l'inventaire et aux chronomètres.
]]

local busy     = false
local virus    = false     -- { strain, phase, remaining } ou false
local bonuses  = {}        -- [token] = { item, cfg, kind, granted = {}, regenAt }
local hangover = 0         -- salines à prendre

local function dbg(...)
    if Config.Debug then print('^3[rz_soins]^7', ...) end
end

local function notify(msg, type, title)
    lib.notify({ title = title or 'Soins', description = msg, type = type or 'inform' })
end

local function isDowned()
    return LocalPlayer.state.rzDowned == true
end

local function itemLabel(name)
    local it = exports.ox_inventory:Items(name)
    return it and it.label or name
end

local function progress(label, seconds, animKey, immobile)
    return lib.progressBar({
        duration     = seconds * 1000,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = immobile or false, car = true, combat = true },
        anim         = Config.Anims[animKey] or nil,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  BONUS CUMULÉS : vie max, armure, modificateurs
-- ═══════════════════════════════════════════════════════════════════

local function grantedMaxHealth()
    local t = 0
    for _, b in pairs(bonuses) do t = t + (b.granted.maxHealth or 0) end
    return math.min(Config.Caps.maxHealth, t)
end

local function maxHealth()
    return Config.MaxHealth + grantedMaxHealth()
end

local function applyMaxHealth()
    local ped = cache.ped
    local newMax = maxHealth()
    SetEntityMaxHealth(ped, newMax)
    if GetEntityHealth(ped) > newMax then SetEntityHealth(ped, newMax) end
end

local function activeConfigs()
    local list = {}
    if virus and virus.phase == 1 and Config.Bonus[virus.strain] then
        list[#list + 1] = Config.Bonus[virus.strain]
    end
    for _, b in pairs(bonuses) do list[#list + 1] = b.cfg end
    return list
end

local function recompute()
    local sprint, defense, melee = 1.0, 1.0, 1.0
    for _, b in ipairs(activeConfigs()) do
        if b.sprint      then sprint  = math.max(sprint, b.sprint) end
        if b.defense     then defense = defense * b.defense end
        if b.meleeDamage then melee   = math.max(melee, b.meleeDamage) end
    end
    local pid = PlayerId()
    SetRunSprintMultiplierForPlayer(pid, math.min(Config.Caps.sprint, sprint))
    defense = math.max(Config.Caps.defense, defense)
    SetPlayerWeaponDefenseModifier(pid, defense)
    SetPlayerMeleeWeaponDefenseModifier(pid, defense)
    SetPlayerMeleeWeaponDamageModifier(pid, melee)
end

local function wantStamina()
    for _, b in ipairs(activeConfigs()) do
        if b.stamina then return true end
    end
    return false
end

local function heal(pv, label)
    local ped = cache.ped
    if IsEntityDead(ped) then return end
    local before = GetEntityHealth(ped)
    local after  = math.min(maxHealth(), before + pv)
    SetEntityHealth(ped, after)
    notify(('%s : +%d PV (%d/%d)'):format(label, after - before, after, maxHealth()), 'success')
end

local function bonusText(cfg)
    local p = {}
    if cfg.stamina     then p[#p + 1] = 'endurance' end
    if cfg.sprint      then p[#p + 1] = ('course +%d %%'):format((cfg.sprint - 1) * 100 + 0.5) end
    if cfg.meleeDamage then p[#p + 1] = ('corps-à-corps +%d %%'):format((cfg.meleeDamage - 1) * 100 + 0.5) end
    if cfg.defense     then p[#p + 1] = ('dégâts subis -%d %%'):format((1 - cfg.defense) * 100 + 0.5) end
    if cfg.armour      then p[#p + 1] = ('armure +%d'):format(cfg.armour) end
    if cfg.maxHealth   then p[#p + 1] = ('vie max +%d'):format(cfg.maxHealth) end
    if cfg.regenPv     then p[#p + 1] = ('+%d PV/%d s'):format(cfg.regenPv, cfg.regenEvery or 5) end
    return table.concat(p, ' · ')
end


-- ═══════════════════════════════════════════════════════════════════
--  COMPTEUR EN HAUT À GAUCHE
-- ═══════════════════════════════════════════════════════════════════

local function refreshHud()
    local entries = {}
    if virus then
        local v = Config.Virus[virus.strain]
        if virus.phase == 1 then
            entries[#entries + 1] = { label = v.label, sub = bonusText(Config.Bonus[virus.strain] or {}),
                                      remaining = virus.remaining, total = v.safeMinutes * 60, kind = 'virus' }
        else
            entries[#entries + 1] = { label = v.label, sub = ('-%d PV/min · antivirus !'):format(v.damagePerMinute),
                                      remaining = false, total = 0, kind = 'danger' }
        end
    end
    local list = {}
    for _, b in pairs(bonuses) do list[#list + 1] = b end
    table.sort(list, function(a, b) return a.remaining < b.remaining end)
    for _, b in ipairs(list) do
        entries[#entries + 1] = { label = itemLabel(b.item), sub = bonusText(b.cfg),
                                  remaining = b.remaining, total = b.cfg.duration, kind = 'bonus' }
    end
    SendNUIMessage({ action = 'state', entries = entries, hangover = hangover })
end


-- ═══════════════════════════════════════════════════════════════════
--  RÉCEPTION DES BONUS (serveur → client)
-- ═══════════════════════════════════════════════════════════════════

local function addBonus(token, item, kind, remaining)
    local cfg = (kind == 'med') and Config.Medicaments[item] or Config.Drogues[item]
    if not cfg then return end
    local ped = cache.ped
    local b = { item = item, cfg = cfg, kind = kind, granted = {}, remaining = remaining, regenAt = 0 }
    bonuses[token] = b

    if cfg.maxHealth then
        local room = Config.Caps.maxHealth - grantedMaxHealth()
        b.granted.maxHealth = math.max(0, math.min(cfg.maxHealth, room))
        applyMaxHealth()
        SetEntityHealth(ped, math.min(maxHealth(), GetEntityHealth(ped) + b.granted.maxHealth))
    end
    if cfg.armour then
        local cur = GetPedArmour(ped)
        local add = math.min(100 - cur, cfg.armour)
        if add > 0 then
            SetPedArmour(ped, cur + add)
            b.granted.armour = add
        end
    end
end

local function removeBonus(token)
    local b = bonuses[token]
    if not b then return end
    bonuses[token] = nil
    local ped = cache.ped
    if b.granted.maxHealth then applyMaxHealth() end
    if b.granted.armour then
        SetPedArmour(ped, math.max(0, GetPedArmour(ped) - b.granted.armour))
    end
end

RegisterNetEvent('rz_soins:bonusState', function(list, hang)
    local seen = {}
    for _, e in ipairs(list or {}) do
        seen[e.token] = true
        if bonuses[e.token] then
            bonuses[e.token].remaining = e.remaining
        else
            addBonus(e.token, e.item, e.kind, e.remaining)
        end
    end
    for token in pairs(bonuses) do
        if not seen[token] then removeBonus(token) end
    end
    hangover = hang or 0
    recompute()
    refreshHud()
end)

RegisterNetEvent('rz_soins:virusState', function(state)
    virus = state or false
    recompute()
    refreshHud()
    dbg('état viral', json.encode(virus))
end)


-- ═══════════════════════════════════════════════════════════════════
--  SOINS SUR SOI (client.export dans data/items.lua)
--
--  Comme rz_boombox : un export appelé depuis ox_inventory ne doit
--  pas porter lui-même les attentes (barre de progression), on isole
--  le travail dans un thread et on rend la main tout de suite.
-- ═══════════════════════════════════════════════════════════════════

exports('useSoin', function(_, data)
    if busy then return end
    local cfg = Config.Soins[data.name]
    if not cfg then return end
    if isDowned() then return notify('Impossible à terre.', 'error') end

    -- Une saline pendant une gueule de bois sert à ça, et à rien d'autre
    local saline = Config.SalineItems[data.name] and hangover > 0

    if not saline and GetEntityHealth(cache.ped) >= maxHealth() then
        return notify('Tu es déjà en pleine forme.')
    end

    busy = true
    CreateThread(function()
        local label = itemLabel(data.name)
        if progress(label, cfg.duration, cfg.anim, cfg.immobile) then
            if saline then
                exports.ox_inventory:useItem(data)   -- le serveur lève la gueule de bois
            else
                exports.ox_inventory:useItem(data, function(item)
                    if item then heal(cfg.pv, label) end
                end)
            end
        end
        busy = false
    end)
end)


exports('useDeballage', function(_, data)
    if busy then return end
    local cfg = Config.Deballage[data.name]
    if not cfg then return end

    busy = true
    CreateThread(function()
        local ok, msg = lib.callback.await('rz_soins:canUnpack', false, data.name)
        if not ok then
            busy = false
            return notify(msg, 'error')
        end
        if progress(itemLabel(data.name), 1, nil) then
            exports.ox_inventory:useItem(data)   -- le serveur ajoute le contenu (ox_inventory:usedItem)
        end
        busy = false
    end)
end)


-- ═══════════════════════════════════════════════════════════════════
--  MÉDICAMENTS ET DROGUES : bonus chronométré par le serveur
-- ═══════════════════════════════════════════════════════════════════

local function useBonusItem(data, cfg, callback, seconds)
    if busy then return end
    if isDowned() then return notify('Impossible à terre.', 'error') end

    busy = true
    CreateThread(function()
        local ok, msg = lib.callback.await(callback, false, data.name)
        if not ok then
            busy = false
            return notify(msg, 'error')
        end
        if progress(itemLabel(data.name), seconds, cfg.anim or 'pilule') then
            exports.ox_inventory:useItem(data)   -- le serveur lance l'effet et son chronomètre
        end
        busy = false
    end)
end

exports('useMedicament', function(_, data)
    local cfg = Config.Medicaments[data.name]
    if cfg then useBonusItem(data, cfg, 'rz_soins:canUseMed', 3) end
end)

exports('useDrogue', function(_, data)
    local cfg = Config.Drogues[data.name]
    if cfg then useBonusItem(data, cfg, 'rz_soins:canUseDrogue', 4) end
end)


-- ═══════════════════════════════════════════════════════════════════
--  VIRUS ET ANTIVIRUS (injection au pistolet injecteur)
-- ═══════════════════════════════════════════════════════════════════

local function injectionConfig(name)
    for _, v in pairs(Config.Virus) do
        if v.item == name then return v end
    end
    return Config.Antivirus[name]
end

exports('useVirus', function(_, data)
    if busy then return end
    local cfg = injectionConfig(data.name)
    if not cfg then return end

    busy = true
    CreateThread(function()
        local ok, msg = lib.callback.await('rz_soins:canInject', false, data.name)
        if not ok then
            busy = false
            return notify(msg, 'error')
        end
        if progress(('Injection : %s'):format(itemLabel(data.name)), cfg.duration or 6, 'injection', true) then
            exports.ox_inventory:useItem(data)   -- le serveur applique l'effet (ox_inventory:usedItem)
        end
        busy = false
    end)
end)


-- ═══════════════════════════════════════════════════════════════════
--  SOIGNER QUELQU'UN D'AUTRE (ox_target)
-- ═══════════════════════════════════════════════════════════════════

local function healTarget(targetId, itemName, cfg)
    if busy then return end
    busy = true

    local ped = cache.ped
    TaskStartScenarioInPlace(ped, Config.TargetScenario, 0, true)
    local done = lib.progressBar({
        duration     = cfg.duration * 1000,
        label        = ('%s sur le survivant'):format(itemLabel(itemName)),
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
    })
    ClearPedTasks(ped)

    if done then
        local ok, msg = lib.callback.await('rz_soins:healOther', false, targetId, itemName)
        notify(msg, ok and 'success' or 'error')
    end
    busy = false
end

local function openHealMenu(targetId)
    local options = {}

    for name, cfg in pairs(Config.Soins) do
        if cfg.others then
            local count = exports.ox_inventory:Search('count', name)
            if count and count > 0 then
                options[#options + 1] = {
                    title       = ('%s ×%d'):format(itemLabel(name), count),
                    description = ('+%d PV · %d s'):format(cfg.pv, cfg.duration),
                    icon        = 'kit-medical',
                    onSelect    = function() healTarget(targetId, name, cfg) end,
                }
            end
        end
    end

    for name, tool in pairs(Config.Tools) do
        if tool.pv then
            local slots = exports.ox_inventory:Search('slots', name)
            if slots and #slots > 0 then
                local dur = slots[1].metadata and slots[1].metadata.durability
                if dur == nil or dur > 0 then
                    options[#options + 1] = {
                        title       = ('%s (%d %%)'):format(itemLabel(name), dur or 100),
                        description = ('+%d PV · %d s · -%d %% d\'usure'):format(tool.pv, tool.duration, tool.wearPerUse),
                        icon        = 'heart-pulse',
                        onSelect    = function() healTarget(targetId, name, tool) end,
                    }
                end
            end
        end
    end

    if #options == 0 then
        return notify('Tu n\'as rien pour soigner quelqu\'un.', 'error')
    end

    table.sort(options, function(a, b) return a.title < b.title end)
    lib.registerContext({ id = 'rz_soins_target', title = 'Soigner', options = options })
    lib.showContext('rz_soins_target')
end

CreateThread(function()
    Wait(2000)
    exports.ox_target:addGlobalPlayer({
        {
            name     = 'rz_soins_heal',
            icon     = 'fas fa-briefcase-medical',
            label    = 'Soigner',
            distance = Config.TargetDistance,

            canInteract = function(entity)
                if isDowned() then return false end
                local idx = NetworkGetPlayerIndexFromPed(entity)
                if idx == -1 then return false end
                return Player(GetPlayerServerId(idx)).state.rzDowned ~= true
            end,

            onSelect = function(data)
                local idx = NetworkGetPlayerIndexFromPed(data.entity)
                if idx == -1 then return end
                openHealMenu(GetPlayerServerId(idx))
            end,
        },
    })
end)

-- Soin reçu de quelqu'un d'autre
RegisterNetEvent('rz_soins:heal', function(pv, label)
    heal(pv, label)
end)


-- ═══════════════════════════════════════════════════════════════════
--  BOUCLES : dégâts viraux, endurance, régénération, symptômes,
--  gueule de bois, contagion, compteur
-- ═══════════════════════════════════════════════════════════════════

-- Dégâts de phase 2, envoyés par le serveur
RegisterNetEvent('rz_soins:drain', function(amount)
    if isDowned() then return end
    local ped = cache.ped
    if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then return end
    ApplyDamageToPed(ped, math.floor(amount), false)
end)

-- Endurance et régénération (virus phase 1, médicaments, drogues)
CreateThread(function()
    local virusRegenAt = 0
    while true do
        Wait(1000)
        if (virus or next(bonuses)) and not isDowned() then
            if wantStamina() then RestorePlayerStamina(PlayerId(), 1.0) end

            local ped = cache.ped
            local h = GetEntityHealth(ped)
            local alive = h > 0 and not IsEntityDead(ped)
            local now = GetGameTimer()

            if alive and virus and virus.phase == 1 then
                local b = Config.Bonus[virus.strain]
                if b and b.regenPv and now >= virusRegenAt then
                    virusRegenAt = now + (b.regenEvery * 1000)
                    if h < maxHealth() then SetEntityHealth(ped, math.min(maxHealth(), h + b.regenPv)) end
                end
            end
            if alive then
                for _, b in pairs(bonuses) do
                    if b.cfg.regenPv and now >= b.regenAt then
                        b.regenAt = now + ((b.cfg.regenEvery or 5) * 1000)
                        h = GetEntityHealth(ped)
                        if h < maxHealth() then SetEntityHealth(ped, math.min(maxHealth(), h + b.cfg.regenPv)) end
                    end
                end
            end

            -- décompte local, le serveur reste la référence
            for _, b in pairs(bonuses) do
                if b.remaining and b.remaining > 0 then b.remaining = b.remaining - 1 end
            end
            if virus and virus.remaining and virus.remaining > 0 then virus.remaining = virus.remaining - 1 end
        end
    end
end)

-- Symptômes de phase 2
CreateThread(function()
    while true do
        Wait(Config.Symptoms.every * 1000)
        if virus and virus.phase == 2 and not isDowned() then
            ShakeGameplayCam(Config.Symptoms.shake, Config.Symptoms.shakeAmplitude)
            AnimpostfxPlay(Config.Symptoms.postfx, Config.Symptoms.postfxMs, false)
        end
    end
end)

-- Gueule de bois : démarche et caméra d'ivresse tant qu'il reste des salines à prendre
CreateThread(function()
    local drunk = false
    while true do
        local wait = 1000
        local ped = cache.ped
        if hangover > 0 and not isDowned() and not IsEntityDead(ped) then
            if not drunk then
                lib.requestAnimSet(Config.Hangover.clipset, 5000)
                SetPedMovementClipset(ped, Config.Hangover.clipset, 1.0)
                SetPedIsDrunk(ped, true)
                drunk = true
            end
            ShakeGameplayCam(Config.Hangover.shake, Config.Hangover.shakeAmplitude)
            wait = Config.Hangover.every * 1000
        elseif drunk then
            ResetPedMovementClipset(ped, 1.0)
            SetPedIsDrunk(ped, false)
            StopGameplayCamShaking(true)
            drunk = false
        end
        Wait(wait)
    end
end)

-- Contagion (phase 2, souche contagieuse)
CreateThread(function()
    while true do
        local wait = 10000
        if virus and virus.phase == 2 and not isDowned() then
            local v = Config.Virus[virus.strain]
            if v and v.contagious then
                wait = v.contagious.interval * 1000
                local me = cache.ped
                local mine = GetEntityCoords(me)
                for _, p in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(p)
                    if ped ~= me and #(GetEntityCoords(ped) - mine) <= v.contagious.radius
                       and math.random(100) <= v.contagious.chance then
                        TriggerServerEvent('rz_soins:contagion', GetPlayerServerId(p))
                    end
                end
            end
        end
        Wait(wait)
    end
end)

-- Menu admin : « Annuler les effets » — remise à zéro locale, au cas
-- où le client aurait perdu la synchro avec le serveur
RegisterNetEvent('rz_soins:adminReset', function()
    for token in pairs(bonuses) do removeBonus(token) end
    virus = false
    hangover = 0
    local ped = cache.ped
    SetEntityMaxHealth(ped, Config.MaxHealth)
    if GetEntityHealth(ped) > Config.MaxHealth then SetEntityHealth(ped, Config.MaxHealth) end
    ResetPedMovementClipset(ped, 0.5)
    SetPedIsDrunk(ped, false)
    StopGameplayCamShaking(true)
    AnimpostfxStopAll()
    recompute()
    refreshHud()
end)

-- Menu admin : « Soigner » — pleine vie et armure
RegisterNetEvent('rz_soins:adminHeal', function()
    local ped = cache.ped
    if IsEntityDead(ped) or isDowned() then
        return notify('À terre : il faut une réanimation, pas un soin.', 'error', 'Staff')
    end
    SetEntityHealth(ped, maxHealth())
    SetPedArmour(ped, 100)
    notify('Un membre du staff t\'a soigné.', 'success', 'Staff')
end)

-- Mort définitive (rz_mort) : le serveur efface l'infection
RegisterNetEvent('rz_mort:finalDeath', function()
    if virus then TriggerServerEvent('rz_soins:finalDeath') end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for token in pairs(bonuses) do removeBonus(token) end
    virus = false
    hangover = 0
    recompute()
    local ped = cache.ped
    ResetPedMovementClipset(ped, 0.0)
    SetPedIsDrunk(ped, false)
    SendNUIMessage({ action = 'state', entries = {}, hangover = 0 })
end)


-- ═══════════════════════════════════════════════════════════════════
--  /virus : où en suis-je ?
-- ═══════════════════════════════════════════════════════════════════

RegisterCommand('virus', function()
    for _, b in pairs(bonuses) do
        notify(('%s : encore %d min.'):format(itemLabel(b.item), math.ceil((b.remaining or 0) / 60)), 'inform', 'Bonus')
    end
    if hangover > 0 then
        notify(('Gueule de bois : %d saline(s) pour t\'en remettre.'):format(hangover), 'warning')
    end
    if not virus then return notify('Aucun virus dans ton sang.') end
    local v = Config.Virus[virus.strain]
    local state = lib.callback.await('rz_soins:status', false)
    if not state then return end

    if state.phase == 1 then
        notify(('%s — bonus actif, encore %d min avant que le virus ne se retourne contre toi.')
            :format(v.label, math.max(0, math.ceil(state.remaining / 60))), 'inform', 'Virus')
    else
        notify(('%s — il te ronge : -%d PV par minute. Injecte l\'antivirus.')
            :format(v.label, v.damagePerMinute), 'error', 'Virus')
    end
end, false)
