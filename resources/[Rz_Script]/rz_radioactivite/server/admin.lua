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

-- ═══════════════════════════════════════════════════════════════════
--  PILOTAGE DU CYCLE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_radiation:getCycle', function(source)
    if not Config.HasAce(source) then return end

    local info = GetCycleInfo()

    local scenarios = {}
    for _, sc in ipairs(Config.Scenarios) do
        scenarios[#scenarios + 1] = {
            value  = sc.key,
            label  = sc.label,
            note   = sc.note,
            weight = sc.weight or 1,
            steps  = #sc.path,
            radius = sc.radius or Config.Zone.radius,
            speed  = sc.speed or Config.Zone.speed,
            loop   = sc.loop == true,
        }
    end

    info.scenarios = scenarios
    info.cycleEnabled = Config.Cycle.enabled

    return info
end)


---Lance un scénario tout de suite, sans attendre la fin de l'accalmie.
lib.callback.register('rz_radiation:launchScenario', function(source, key)
    if not Config.HasAce(source) then return deny(source) end

    local sc = Config.GetScenario(key)
    if not sc then return false, 'Itinéraire inconnu.' end

    StartWarning(key)
    logChange(source, 'launchScenario', { scenario = key })

    return true, ('« %s » annoncé. Le nuage arrive dans %d secondes.')
        :format(sc.label, Config.Cycle.warningSeconds)
end)


---Dissipe le nuage immédiatement et repart en accalmie.
lib.callback.register('rz_radiation:forceDormant', function(source)
    if not Config.HasAce(source) then return deny(source) end

    GoDormant()
    logChange(source, 'forceDormant', {})

    return true, 'Nuage dissipé. Retour en accalmie.'
end)


---Saute l'attente : passe directement à l'étape suivante du cycle.
lib.callback.register('rz_radiation:skipPhase', function(source)
    if not Config.HasAce(source) then return deny(source) end

    if CycleState == 'dormante' then
        StartWarning()
        return true, 'Annonce lancée.'
    elseif CycleState == 'annonce' then
        GoActive()
        return true, 'Nuage apparu.'
    else
        GoDormant()
        return true, 'Nuage dissipé.'
    end
end)


lib.callback.register('rz_radiation:toggleCycle', function(source)
    if not Config.HasAce(source) then return deny(source) end

    Config.Cycle.enabled = not Config.Cycle.enabled

    if not Config.Cycle.enabled then
        -- Sans cycle, la zone reprend son déplacement aléatoire.
        Current.scenario = nil
    end

    logChange(source, 'toggleCycle', { enabled = Config.Cycle.enabled })

    return true, Config.Cycle.enabled
        and 'Cycle réactivé : accalmies et itinéraires.'
        or  'Cycle désactivé : la zone se déplace au hasard.'
end)

---Création d'une zone sur la position de l'admin.
lib.callback.register('rz_radiation:createManual', function(source, data)
    if not Config.HasAce(source) then return deny(source) end

    return CreateManualZone(
        source,
        data.radius,
        data.speed,
        data.minutes,
        data.announce
    )
end)


---Données nécessaires au formulaire de création.
lib.callback.register('rz_radiation:getManualOptions', function(source)
    if not Config.HasAce(source) then return end

    local durations = {}
    for _, m in ipairs(Config.Manual.durations) do
        durations[#durations + 1] = {
            value = m,
            label = m >= 60 and ('%d h %s'):format(m // 60,
                        m % 60 > 0 and ('%d min'):format(m % 60) or '')
                    or ('%d minutes'):format(m),
        }
    end

    return {
        maxRadius       = Config.MaxScenarioRadius(),
        minRadius       = Config.Manual.minRadius,
        durations       = durations,
        defaultDuration = Config.Manual.defaultDuration,
        defaultSpeed    = Config.Manual.defaultSpeed,
        announceDefault = Config.Manual.announceByDefault,
    }
end)

-- ═══════════════════════════════════════════════════════════════════
--  RÉGLAGES
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_radiation:getGroups', function(source)
    if not Config.HasAce(source) then return {} end

    local out = {}

    for _, g in ipairs(GROUPS) do
        local n = 0
        for _, def in ipairs(SETTINGS) do
            if def.group == g.key then n = n + 1 end
        end

        out[#out + 1] = {
            key = g.key, label = g.label, icon = g.icon, count = n,
        }
    end

    return out
end)


lib.callback.register('rz_radiation:getSettings', function(source, group)
    if not Config.HasAce(source) then return {} end

    local out = {}

    for _, def in ipairs(SETTINGS) do
        if not group or def.group == group then
            out[#out + 1] = {
                key   = def.key,
                label = def.label,
                note  = def.note,
                type  = def.type,
                min   = def.min,
                max   = def.max,
                step  = def.step,
                value = ReadSetting(def.key),
            }
        end
    end

    return out
end)


lib.callback.register('rz_radiation:setSetting', function(source, key, value)
    if not Config.HasAce(source) then return deny(source) end
    return SaveSetting(source, key, value)
end)


lib.callback.register('rz_radiation:resetGroup', function(source, group)
    if not Config.HasAce(source) then return deny(source) end

    local n = ResetGroup(source, group)

    return true, ('%d réglage(s) effacé(s). Relance la ressource pour retrouver les valeurs d\'origine.')
        :format(n)
end)


---Qui se trouve actuellement dans la zone, et avec quelle protection.
lib.callback.register('rz_radiation:getExposed', function(source)
    if not Config.HasAce(source) then return {} end

    local out = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)

        if exports[GetCurrentResourceName()]:IsInZone(src) then
            out[#out + 1] = {
                id        = src,
                name      = GetPlayerName(src),
                protected = exports[GetCurrentResourceName()]:IsProtected(src),
            }
        end
    end

    return out
end)
