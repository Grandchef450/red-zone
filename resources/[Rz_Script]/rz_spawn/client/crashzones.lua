--[[
    rz_spawn / client/crashzones.lua

    Éloigne les joueurs des endroits qui font planter.

    On prévient à 80 mètres, on repousse à 25. L'écart entre les deux
    laisse le temps de faire demi-tour de son plein gré : personne
    n'aime être téléporté sans comprendre pourquoi.
]]

local zones = {}
local lastWarn = 0
local pushing = false


local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


RegisterNetEvent('rz_spawn:crashZones', function(list)
    zones = list or {}

    local n = 0
    for _ in pairs(zones) do n = n + 1 end

    dbg(('%d zone(s) à plantage reçue(s)'):format(n))
end)


---Repousse le joueur hors d'une zone.
local function pushOut(zone, coords)
    if pushing then return end
    pushing = true

    -- On le renvoie dans la direction d'où il venait, au-delà de la
    -- distance d'avertissement : le ramener au bord le ferait
    -- rentrer aussitôt.
    local dx = coords.x - zone.x
    local dy = coords.y - zone.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 1.0 then
        -- Pile au centre : on choisit une direction au hasard
        local angle = math.random() * math.pi * 2
        dx, dy, dist = math.cos(angle), math.sin(angle), 1.0
    end

    local target = zone.radius + Config.CrashZones.warnDistance + 20.0
    local x = zone.x + (dx / dist) * target
    local y = zone.y + (dy / dist) * target

    lib.notify({
        type        = 'error',
        title       = 'Zone instable',
        description = ('« %s » fait planter le jeu. Tu en as été écarté.')
            :format(zone.label or 'secteur'),
        duration    = 12000,
    })

    TriggerEvent('rz_spawn:forceMove', { x = x, y = y, z = coords.z })

    Wait(5000)
    pushing = false
end


CreateThread(function()
    while true do
        Wait(Config.CrashZones.checkInterval or 1000)

        if Config.CrashZones.enabled and next(zones) and not pushing then
            local ped = cache.ped

            if DoesEntityExist(ped) then
                local c = GetEntityCoords(ped)

                for _, zone in pairs(zones) do
                    local dx, dy = c.x - zone.x, c.y - zone.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    -- Repoussé sans discussion
                    if dist <= (zone.radius + Config.CrashZones.pushDistance) then
                        pushOut(zone, c)
                        break

                    -- Prévenu, libre de faire demi-tour
                    elseif dist <= (zone.radius + Config.CrashZones.warnDistance) then
                        local now = GetGameTimer()

                        if (now - lastWarn) > (Config.CrashZones.warnCooldown * 1000) then
                            lastWarn = now

                            lib.notify({
                                type        = 'warning',
                                title       = 'Zone instable devant toi',
                                description = ('« %s » fait planter le jeu. Fais demi-tour.')
                                    :format(zone.label or 'secteur'),
                                duration    = 10000,
                            })
                        end
                        break
                    end
                end
            end
        end
    end
end)


CreateThread(function()
    Wait(6000)
    zones = lib.callback.await('rz_spawn:getCrashZones', false) or {}
end)
