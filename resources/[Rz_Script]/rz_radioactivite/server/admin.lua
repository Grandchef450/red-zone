--[[
    rz_radioactivite / server/admin.lua
    Pilotage de la zone depuis le menu admin.
]]

local function deny(source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = ('Permission %s requise.'):format(Config.Ace),
    })
    return false
end

local function logChange(source, action, detail)
    MySQL.prepare('INSERT INTO rz_radiation_logs (admin, action, detail) VALUES (?, ?, ?)', {
        GetPlayerIdentifierByType(source, 'license'), action, json.encode(detail or {})
    })
end


lib.callback.register('rz_radiation:isAdmin', function(source)
    return Config.HasAce(source)
end)


lib.callback.register('rz_radiation:getState', function(source)
    if not Config.HasAce(source) then return end

    local inside = 0
    for _, playerId in ipairs(GetPlayers()) do
        if exports[GetCurrentResourceName()]:IsInZone(tonumber(playerId)) then
            inside = inside + 1
        end
    end

    return {
        active     = Zone.active,
        x          = Zone.x,
        y          = Zone.y,
        radius     = Zone.radius,
        speed      = Zone.speed,
        targetX    = Zone.targetX,
        targetY    = Zone.targetY,
        moving     = Config.Movement.enabled,
        playersIn  = inside,
    }
end)


lib.callback.register('rz_radiation:setState', function(source, data)
    if not Config.HasAce(source) then return deny(source) end

    if data.radius then
        Zone.radius = math.max(50.0, math.min(5000.0, tonumber(data.radius) or 500.0))
    end

    if data.speed then
        Zone.speed = math.max(0.0, math.min(50.0, tonumber(data.speed) or 3.0))
    end

    if data.active ~= nil then
        Zone.active = data.active and true or false
    end

    if data.moving ~= nil then
        Config.Movement.enabled = data.moving and true or false
    end

    logChange(source, 'setState', {
        radius = Zone.radius, speed = Zone.speed,
        active = Zone.active, moving = Config.Movement.enabled,
    })

    return true, ('Rayon %.0f · vitesse %.1f · %s · %s'):format(
        Zone.radius, Zone.speed,
        Zone.active and 'active' or 'inactive',
        Config.Movement.enabled and 'mobile' or 'immobile')
end)


---Déplace la zone sur la position de l'admin.
lib.callback.register('rz_radiation:moveHere', function(source)
    if not Config.HasAce(source) then return deny(source) end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 'Position introuvable.' end

    local c = GetEntityCoords(ped)
    Zone.x, Zone.y = c.x, c.y

    logChange(source, 'moveHere', { x = c.x, y = c.y })

    return true, ('Zone déplacée sur %.0f, %.0f.'):format(c.x, c.y)
end)


---Envoie la zone ailleurs, au hasard.
lib.callback.register('rz_radiation:relocate', function(source)
    if not Config.HasAce(source) then return deny(source) end

    local b = Config.Movement.bounds
    Zone.x = b.minX + math.random() * (b.maxX - b.minX)
    Zone.y = b.minY + math.random() * (b.maxY - b.minY)

    logChange(source, 'relocate', { x = Zone.x, y = Zone.y })

    return true, ('Zone relocalisée sur %.0f, %.0f.'):format(Zone.x, Zone.y)
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES DE SECOURS
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('radiation', {
    help = 'État de la zone radioactive',
    restricted = Config.Ace,
}, function(source)
    TriggerClientEvent('ox_lib:alertDialog', source, {
        header = 'Zone radioactive',
        content = ('Position : %.0f, %.0f  \nRayon : %.0f  \nVitesse : %.1f  \nCap : %.0f, %.0f  \nÉtat : %s')
            :format(Zone.x, Zone.y, Zone.radius, Zone.speed,
                    Zone.targetX, Zone.targetY,
                    Zone.active and 'active' or 'inactive'),
        centered = true,
    })
end)
-- rebuild du blip apres changement de rayon

RegisterNetEvent('rz_radiation:requestBlipRebuild', function()
    if not Config.HasAce(source) then return end
    TriggerClientEvent('rz_radiation:rebuildBlip', -1)
end)
