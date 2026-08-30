--[[
    rz_radioactivite / server/main.lua

    Zone radioactive mobile.

    LE SERVEUR EST L'AUTORITÉ. Le client ne fait qu'afficher : il
    reçoit la position du nuage et dessine le rendu. Toute la logique
    — position, dégâts, état des masques — vit ici. Un client modifié
    peut masquer le voile rouge, il prendra quand même les dégâts.
]]

Zone = {
    active  = Config.Zone.startActive,
    x       = 0.0,
    y       = 0.0,
    radius  = Config.Zone.radius,
    speed   = Config.Zone.speed,
    targetX = 0.0,
    targetY = 0.0,
}

-- [source] = { since = timestamp d'entrée, warned = timestamp }
local exposure = {}

-- [source] = { item, expiresAt } — protection active
local protection = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_radiation]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉPLACEMENT
-- ═══════════════════════════════════════════════════════════════════

---Choisit un nouveau point de destination, suffisamment loin.
local function pickTarget()
    local b = Config.Movement.bounds
    local x, y, dist
    local tries = 0

    repeat
        x = b.minX + math.random() * (b.maxX - b.minX)
        y = b.minY + math.random() * (b.maxY - b.minY)
        dist = math.sqrt((x - Zone.x) ^ 2 + (y - Zone.y) ^ 2)
        tries = tries + 1
    until dist >= Config.Movement.minTravel or tries > 30

    Zone.targetX, Zone.targetY = x, y
    dbg(('nouveau cap : %.0f, %.0f (%.0f m)'):format(x, y, dist))
end


---Position de départ : au hasard sur la carte.
local function placeRandom()
    local b = Config.Movement.bounds
    Zone.x = b.minX + math.random() * (b.maxX - b.minX)
    Zone.y = b.minY + math.random() * (b.maxY - b.minY)
    pickTarget()
end


CreateThread(function()
    placeRandom()

    local step = Config.Movement.tickMs / 1000.0

    while true do
        Wait(Config.Movement.tickMs)

        if Zone.active and Config.Movement.enabled then
            -- Avec le cycle actif, le nuage suit un ITINÉRAIRE.
            -- Le déplacement aléatoire d'origine ne sert plus que
            -- si le cycle est désactivé, ou si un admin a placé la
            -- zone à la main hors scénario.
            if Config.Cycle.enabled and Current and Current.scenario then
                AdvanceOnPath(step)
            else
                local dx, dy = Zone.targetX - Zone.x, Zone.targetY - Zone.y
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist < 25.0 then
                    pickTarget()
                else
                    local move = Zone.speed * step
                    Zone.x = Zone.x + (dx / dist) * move
                    Zone.y = Zone.y + (dy / dist) * move
                end
            end
        end

        -- On envoie aussi l'état du cycle : pendant l'annonce, le
        -- blip doit apparaître alors que la zone n'est pas encore
        -- dangereuse. C'est ce qui permet de fuir dans la bonne
        -- direction plutôt qu'au hasard.
        TriggerClientEvent('rz_radiation:sync', -1, {
            active   = Zone.active,
            incoming = CycleState == 'annonce',
            x        = Zone.x,
            y        = Zone.y,
            radius   = Zone.radius,
            minZ     = Config.Zone.minZ,
            maxZ     = Config.Zone.maxZ,
        })
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Distance d'un joueur au centre du nuage, ou nil s'il est absent.
local function distanceOf(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end

    local c = GetEntityCoords(ped)

    if c.z < Config.Zone.minZ or c.z > Config.Zone.maxZ then
        return nil
    end

    return math.sqrt((c.x - Zone.x) ^ 2 + (c.y - Zone.y) ^ 2)
end


---Ce joueur est-il protégé en ce moment ?
local function isProtected(source)
    local p = protection[source]
    return p and p.expiresAt > os.time()
end

exports('IsProtected', isProtected)
exports('GetZone', function() return Zone end)
exports('IsInZone', function(source)
    local d = distanceOf(source)
    return d ~= nil and d <= Zone.radius
end)


---Envoie un avertissement via rz_signal_urgences, s'il est présent.
local function warn(source, category, ...)
    if not Config.Warnings.enabled then return end
    if GetResourceState('rz_signal_urgences') ~= 'started' then return end

    local msg = exports.rz_signal_urgences and nil
    local text = ({
        approach = 'RAYONNEMENT DETECTE EN APPROCHE. FAIS DEMI-TOUR.',
        entered  = 'DOSE CRITIQUE. TU ES DANS LA ZONE CONTAMINEE.',
        maskLow  = 'FILTRE PRESQUE SATURE. MOINS DE 2 MINUTES.',
        maskOut  = 'FILTRE SATURE. TU N ES PLUS PROTEGE.',
    })[category]

    if not text then return end

    pcall(function()
        exports.rz_signal_urgences:AlertPlayer(source, text,
            category == 'approach' and 'alerte' or 'critique')
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉGÂTS
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Damage.intervalMs)

        if Zone.active then
            local now = os.time()

            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local dist = distanceOf(src)
                local inside = dist ~= nil and dist <= Zone.radius

                if inside then
                    local e = exposure[src]

                    if not e then
                        e = { since = now, warned = 0 }
                        exposure[src] = e
                        warn(src, 'entered')
                    end

                    if isProtected(src) then
                        -- Le décompte du masque ne tourne QUE dans la
                        -- zone : un masque activé par erreur en pleine
                        -- campagne ne se gaspille pas.
                        local p = protection[src]
                        local left = p.expiresAt - now

                        if left <= Config.Warnings.maskLowSeconds
                           and (now - (e.warned or 0)) > 60 then
                            e.warned = now
                            warn(src, 'maskLow')
                        end
                    else
                        -- Dégâts
                        local amount = Config.Damage.amount
                        local esc = Config.Damage.escalate

                        if esc.enabled then
                            local minutes = (now - e.since) / 60
                            local mult = 1.0 + (minutes / esc.rampMinutes) * (esc.factor - 1.0)
                            amount = amount * math.min(mult, esc.maxMultiplier)
                        end

                        local ped = GetPlayerPed(src)
                        local hp = GetEntityHealth(ped)
                        local target = math.max(Config.Damage.floor, hp - amount)

                        if target < hp then
                            SetEntityHealth(ped, math.floor(target))
                        end

                        TriggerClientEvent('rz_radiation:tick', src, {
                            amount   = amount,
                            exposure = now - e.since,
                        })
                    end
                else
                    if exposure[src] then
                        exposure[src] = nil
                    end
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉCOMPTE DES MASQUES
--
--  Séparé de la boucle de dégâts, parce qu'il doit tourner à la
--  seconde alors que les dégâts n'interviennent que toutes les 30.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(5000)

        local now = os.time()

        for src, p in pairs(protection) do
            local dist = distanceOf(src)
            local inside = dist ~= nil and dist <= Zone.radius

            if inside then
                -- Hors zone, on repousse l'échéance : le filtre ne se
                -- consomme que face au rayonnement.
                if p.expiresAt <= now then
                    protection[src] = nil
                    warn(src, 'maskOut')
                    TriggerClientEvent('rz_radiation:maskExpired', src)
                end
            else
                p.expiresAt = p.expiresAt + 5
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  APPROCHE
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(15000)

        if Zone.active and Config.Warnings.enabled then
            local now = os.time()

            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local dist = distanceOf(src)

                if dist and dist > Zone.radius
                   and dist <= (Zone.radius + Config.Warnings.approachDistance) then

                    local e = exposure[src] or { warned = 0 }

                    if (now - (e.warned or 0)) > Config.Warnings.cooldown then
                        e.warned = now
                        exposure[src] = nil   -- il n'est pas encore dedans
                        warn(src, 'approach')
                    end
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ACTIVATION D'UN MASQUE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_radiation:useMask', function(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item then return false, 'Masque introuvable.' end

    local mask = Config.Masks[item.name]
    if not mask then return false, 'Cet objet n\'est pas un masque.' end

    if isProtected(source) then
        local left = protection[source].expiresAt - os.time()
        return false, ('Un filtre est déjà actif : %d min restantes.')
            :format(math.ceil(left / 60))
    end

    local metadata = item.metadata or {}
    local durability = tonumber(metadata.durability) or 100
    local perUse = 100 / Config.MaskCharges

    if durability < perUse then
        return false, 'Ce masque est hors d\'usage.'
    end

    metadata.durability = math.max(0, durability - perUse)
    exports.ox_inventory:SetMetadata(source, slot, metadata)

    protection[source] = {
        item      = item.name,
        expiresAt = os.time() + (mask.minutes * 60),
    }

    local chargesLeft = math.floor(metadata.durability / perUse + 0.5)

    TriggerClientEvent('rz_radiation:maskActive', source, {
        label   = mask.label,
        minutes = mask.minutes,
    })

    return true, ('%s activé : %d minutes de protection. %d charge(s) restante(s).')
        :format(mask.label, mask.minutes, chargesLeft)
end)


lib.callback.register('rz_radiation:getStatus', function(source)
    local dist = distanceOf(source)
    local p = protection[source]

    return {
        active     = Zone.active,
        inside     = dist ~= nil and dist <= Zone.radius,
        distance   = dist,
        radius     = Zone.radius,
        protected  = isProtected(source),
        maskLeft   = p and math.max(0, p.expiresAt - os.time()) or 0,
        maskLabel  = p and Config.Masks[p.item] and Config.Masks[p.item].label or nil,
    }
end)


AddEventHandler('playerDropped', function()
    exposure[source] = nil
    protection[source] = nil
end)
