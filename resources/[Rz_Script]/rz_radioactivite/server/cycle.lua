--[[
    rz_radioactivite / server/cycle.lua

    Le cycle : accalmie → annonce → nuage → dissipation.

    POURQUOI UN CYCLE PLUTÔT QU'UNE MENACE PERMANENTE
    Une zone toujours présente devient un décor qu'on contourne
    machinalement. Une zone qui revient après une accalmie se
    remarque, se prépare, se raconte.

    L'ANNONCE EST LE CŒUR DU SYSTÈME
    Elle passe par rz_signal_urgences, donc uniquement aux porteurs
    de pager. C'est ce qui donne enfin sa valeur à l'objet : sans
    lui, on découvre le nuage en le traversant.
]]

-- 'dormante' | 'annonce' | 'active'
CycleState = 'dormante'

-- Scénario en cours, et progression sur son itinéraire
Current = {
    scenario = nil,
    index    = 1,      -- point de l'itinéraire visé
    startedAt = 0,
}

local nextChange = 0   -- os.time() du prochain basculement

local function dbg(...)
    if Config.Debug then print('^3[rz_radiation]^7', ...) end
end


---Diffuse un message du cycle sur les pagers.
local function announce(category, priority, ...)
    if GetResourceState('rz_signal_urgences') ~= 'started' then return end

    local text = Config.PickCycleMessage(category, ...)
    if text == '' then return end

    pcall(function()
        exports.rz_signal_urgences:AlertZone(nil, text, priority or 'alerte')
    end)

    dbg(('annonce [%s] %s'):format(category, text))
end


-- ═══════════════════════════════════════════════════════════════════
--  PASSAGE EN ACCALMIE
-- ═══════════════════════════════════════════════════════════════════

function GoDormant(silent)
    local wasActive = CycleState == 'active'

    CycleState = 'dormante'
    Zone.active = false
    Current.scenario = nil
    Current.index = 1

    local minutes = math.random(Config.Cycle.dormantMin, Config.Cycle.dormantMax)
    nextChange = os.time() + (minutes * 60)

    if wasActive and not silent then
        announce('ended', 'info')
    end

    dbg(('accalmie : %d minutes'):format(minutes))
end


-- ═══════════════════════════════════════════════════════════════════
--  ANNONCE PUIS APPARITION
-- ═══════════════════════════════════════════════════════════════════

---Prépare un nuage et prévient les pagers.
---@param forcedKey string|nil  imposer un scénario, sinon tirage
function StartWarning(forcedKey)
    local sc = forcedKey and Config.GetScenario(forcedKey) or Config.PickScenario()
    if not sc or not sc.path or #sc.path < 2 then
        print('^1[rz_radiation]^7 scénario invalide, accalmie prolongée')
        return GoDormant(true)
    end

    CycleState = 'annonce'
    Current.scenario = sc
    Current.index = 2          -- le point 1 est la position de départ

    -- Le nuage se place déjà, mais reste inactif : ça permet au
    -- blip d'apparaître pendant l'annonce, et donc de fuir dans la
    -- bonne direction.
    Zone.x, Zone.y = sc.path[1].x, sc.path[1].y
    Zone.radius = sc.radius or Config.Zone.radius
    Zone.speed  = sc.speed  or Config.Zone.speed
    Zone.active = false

    announce('incoming', 'critique', sc.label:upper())

    nextChange = os.time() + Config.Cycle.warningSeconds

    dbg(('annonce du scénario « %s », apparition dans %d s')
        :format(sc.label, Config.Cycle.warningSeconds))
end


function GoActive()
    if not Current.scenario then return GoDormant(true) end

    CycleState = 'active'
    Zone.active = true
    Current.startedAt = os.time()

    nextChange = os.time() + (Config.Cycle.maxActiveMinutes * 60)

    announce('started', 'critique')

    MySQL.prepare('INSERT INTO rz_radiation_logs (admin, action, detail) VALUES (?, ?, ?)', {
        nil, 'cycle_start', json.encode({
            scenario = Current.scenario.key,
            radius = Zone.radius,
            speed = Zone.speed,
        })
    })

    if GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('loot', {
                title  = ('Zone radioactive — %s'):format(Current.scenario.label),
                fields = {
                    { name = 'Rayon',   value = ('%.0f m'):format(Zone.radius) },
                    { name = 'Vitesse', value = tostring(Zone.speed) },
                },
            })
        end)
    end

    dbg(('nuage actif : %s'):format(Current.scenario.label))
end




-- ═══════════════════════════════════════════════════════════════════
--  ZONE MANUELLE
--
--  Un admin pose une contamination sur SA position. Elle ne suit
--  aucun itinéraire et disparaît d'elle-même au bout du temps
--  choisi, puis le cycle normal reprend.
-- ═══════════════════════════════════════════════════════════════════

---Crée une zone centrée sur un joueur.
---@param source number   l'admin, dont la position sert de centre
---@param radius number
---@param speed number    0 = immobile
---@param minutes number
---@param doAnnounce boolean
---@return boolean ok, string message
function CreateManualZone(source, radius, speed, minutes, doAnnounce)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false, 'Position introuvable.'
    end

    local coords = GetEntityCoords(ped)

    -- Plafond au plus large des scénarios automatiques. Sans cette
    -- limite, un curseur poussé au maximum couvrirait la carte et
    -- personne ne pourrait fuir.
    local maxRadius = Config.MaxScenarioRadius()
    radius = math.max(Config.Manual.minRadius, math.min(maxRadius, tonumber(radius) or 300.0))

    speed   = math.max(0.0, math.min(20.0, tonumber(speed) or 0.0))
    minutes = math.max(1, math.min(240, tonumber(minutes) or 30))

    CycleState = 'manuelle'
    Current.scenario = nil
    Current.index = 1
    Current.startedAt = os.time()

    Zone.x, Zone.y = coords.x, coords.y
    Zone.radius = radius
    Zone.speed  = speed
    Zone.active = true

    -- Une zone mobile sans itinéraire reprend le déplacement
    -- aléatoire : on lui donne une première cible.
    if speed > 0 then
        local b = Config.Movement.bounds
        Zone.targetX = b.minX + math.random() * (b.maxX - b.minX)
        Zone.targetY = b.minY + math.random() * (b.maxY - b.minY)
    end

    nextChange = os.time() + (minutes * 60)

    if doAnnounce then
        announce('manual', 'critique')
    end

    MySQL.prepare('INSERT INTO rz_radiation_logs (admin, action, detail) VALUES (?, ?, ?)', {
        GetPlayerIdentifierByType(source, 'license'), 'manualZone',
        json.encode({
            x = coords.x, y = coords.y,
            radius = radius, speed = speed, minutes = minutes,
            announced = doAnnounce,
        })
    })

    if GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('loot', {
                title  = 'Zone radioactive manuelle',
                source = source,
                fields = {
                    { name = 'Rayon',   value = ('%.0f m'):format(radius) },
                    { name = 'Durée',   value = ('%d min'):format(minutes) },
                    { name = 'Vitesse', value = tostring(speed) },
                },
            })
        end)
    end

    dbg(('zone manuelle : %.0f m sur %.0f,%.0f pendant %d min')
        :format(radius, coords.x, coords.y, minutes))

    return true, ('Zone de %.0f m créée sur ta position pour %d minutes.')
        :format(radius, minutes)
end

exports('CreateManualZone', CreateManualZone)


-- ═══════════════════════════════════════════════════════════════════
--  SUIVI DE L'ITINÉRAIRE
--
--  Remplace le déplacement aléatoire d'origine. Le nuage relie les
--  points dans l'ordre ; arrivé au dernier, il boucle ou se dissipe
--  selon le scénario.
-- ═══════════════════════════════════════════════════════════════════

---Avance le nuage vers son point suivant.
---@param step number  secondes écoulées depuis le dernier appel
function AdvanceOnPath(step)
    local sc = Current.scenario
    if not sc then return end

    local target = sc.path[Current.index]

    -- Fin de l'itinéraire
    if not target then
        if sc.loop then
            Current.index = 1
            target = sc.path[1]
        else
            dbg('itinéraire terminé, dissipation')
            return GoDormant()
        end
    end

    local dx, dy = target.x - Zone.x, target.y - Zone.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Point atteint : on vise le suivant
    if dist < 40.0 then
        Current.index = Current.index + 1
        dbg(('point %d/%d atteint'):format(Current.index - 1, #sc.path))
        return
    end

    local move = Zone.speed * step
    Zone.x = Zone.x + (dx / dist) * move
    Zone.y = Zone.y + (dy / dist) * move
end


-- ═══════════════════════════════════════════════════════════════════
--  HORLOGE DU CYCLE
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(5000)

    if Config.Cycle.enabled then
        if Config.Cycle.startDormant then
            GoDormant(true)
        else
            StartWarning()
        end
    end

    while true do
        Wait(5000)

        if Config.Cycle.enabled and os.time() >= nextChange then
            if CycleState == 'dormante' then
                StartWarning()
            elseif CycleState == 'annonce' then
                GoActive()
            elseif CycleState == 'active' then
                -- Durée maximale atteinte : on dissipe même si
                -- l'itinéraire n'est pas fini.
                dbg('durée maximale atteinte')
                GoDormant()
            elseif CycleState == 'manuelle' then
                -- La zone posée par un admin arrive à échéance :
                -- le cycle normal reprend la main.
                dbg('zone manuelle expirée')
                GoDormant()
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT, POUR LE MENU ADMIN
-- ═══════════════════════════════════════════════════════════════════

function GetCycleInfo()
    local remaining = math.max(0, nextChange - os.time())

    return {
        state      = CycleState,
        remaining  = remaining,
        maxRadius  = Config.MaxScenarioRadius(),
        scenario   = Current.scenario and Current.scenario.key or nil,
        label      = Current.scenario and Current.scenario.label or nil,
        note       = Current.scenario and Current.scenario.note or nil,
        step       = Current.index,
        steps      = Current.scenario and #Current.scenario.path or 0,
    }
end

exports('GetCycleInfo', GetCycleInfo)
exports('GoDormant', function() GoDormant() end)
exports('StartWarning', function(key) StartWarning(key) end)


lib.addCommand('radcycle', {
    help = 'État du cycle radioactif',
    restricted = Config.Ace,
}, function(source)
    local c = GetCycleInfo()

    local etat = ({
        dormante = 'Accalmie — aucune contamination',
        annonce  = 'Annonce diffusée, nuage imminent',
        active   = 'Nuage actif',
        manuelle = 'Zone posée par le staff',
    })[c.state] or c.state

    local lines = {
        ('**%s**'):format(etat),
        ('Prochain changement dans %d min %d s')
            :format(math.floor(c.remaining / 60), c.remaining % 60),
    }

    if c.label then
        lines[#lines + 1] = ''
        lines[#lines + 1] = ('Itinéraire : **%s**'):format(c.label)
        lines[#lines + 1] = c.note or ''
        lines[#lines + 1] = ('Progression : point %d sur %d'):format(c.step, c.steps)
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header   = 'Cycle radioactif',
        content  = table.concat(lines, '  \n'),
        centered = true,
    })
end)
