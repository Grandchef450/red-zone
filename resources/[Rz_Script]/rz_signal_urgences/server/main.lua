--[[
    rz_signal_urgences / server/main.lua

    Diffusion des signaux d'urgence sur les pagers.

    RÈGLE CENTRALE
    Un signal ordinaire ne traverse pas une panne réseau : le joueur
    situé dans une zone coupée ne reçoit rien. Une annonce du staff,
    elle, passe toujours — c'est ce qui la distingue et ce qui lui
    donne son autorité.

    POURQUOI CE SCRIPT PILOTE LE BLACKOUT
    Le script blackout est chiffré et n'émet aucun événement. Rien ne
    permet de savoir de l'extérieur qu'une zone vient d'être coupée.
    On inverse donc le sens : c'est ici qu'on coupe, et on relaie
    ensuite la commande au script blackout.
]]

-- [zoneKey] = true si le réseau fonctionne
NetworkUp = {}

-- [source] = clé de la zone où se trouve le joueur, ou nil
PlayerZone = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_signal]^7', ...) end
end


-- Toutes les zones démarrent alimentées
CreateThread(function()
    for key in pairs(Config.Zones) do
        NetworkUp[key] = true
    end
end)


---Le joueur possède-t-il un pager ?
local function hasPager(source)
    if not Config.RequireItem then return true end
    return exports.ox_inventory:GetItemCount(source, Config.ItemName) > 0
end


---Dans quelle zone se trouve ce joueur ?
---@return string|nil
local function zoneOf(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end

    local coords = GetEntityCoords(ped)

    for key, zone in pairs(Config.Zones) do
        if #(coords - zone.center) <= zone.radius then
            return key
        end
    end

    return nil
end


-- ═══════════════════════════════════════════════════════════════════
--  DIFFUSION
-- ═══════════════════════════════════════════════════════════════════

---Envoie un signal aux pagers.
---@param data table
---   message   string   texte affiché
---   priority  string   clé de Config.Priorities
---   sender    string?  expéditeur affiché
---   zone      string?  limiter à une zone ; nil = partout
---   exclude   string?  ne PAS envoyer aux joueurs de cette zone
---@return number destinataires
function Broadcast(data)
    local priority = Config.Priorities[data.priority] or Config.Priorities.info
    local sent = 0

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)

        if hasPager(src) then
            local zone = PlayerZone[src]
            local deliver = true

            -- Panne réseau : seules les annonces prioritaires passent
            if not priority.ignoreOutage then
                if zone and NetworkUp[zone] == false then
                    deliver = false
                end
            end

            -- Signal réservé à une zone
            if deliver and data.zone and zone ~= data.zone then
                deliver = false
            end

            -- Signal explicitement masqué à une zone
            if deliver and data.exclude and zone == data.exclude then
                deliver = false
            end

            if deliver then
                TriggerClientEvent('rz_signal:receive', src, {
                    message  = data.message,
                    priority = data.priority or 'info',
                    sender   = data.sender,
                    label    = priority.label,
                    color    = priority.color,
                    duration = priority.duration,
                    sound    = priority.sound,
                })
                sent = sent + 1
            end
        end
    end

    MySQL.prepare([[
        INSERT INTO rz_signal_logs (priority, sender, message, zone, recipients)
        VALUES (?, ?, ?, ?, ?)
    ]], { data.priority or 'info', data.sender, data.message, data.zone, sent })

    dbg(('signal « %s » → %d destinataire(s)'):format(data.message, sent))

    return sent
end

exports('Broadcast', Broadcast)


---Alerte destinée à une zone précise. Utilisé par rz_radioactivite.
---@param zoneKey string|nil
---@param message string
---@param priority string
exports('AlertZone', function(zoneKey, message, priority)
    return Broadcast({
        message  = message,
        priority = priority or 'alerte',
        zone     = zoneKey,
        sender   = 'AUTOMATIQUE',
    })
end)


---Alerte envoyée à UN joueur. Utilisé par rz_radioactivite pour les
---avertissements de proximité, qui ne concernent qu'une personne.
---@param source number
---@param message string
---@param priority string
exports('AlertPlayer', function(source, message, priority)
    if not hasPager(source) then return false end

    local p = Config.Priorities[priority] or Config.Priorities.alerte
    local zone = PlayerZone[source]

    if not p.ignoreOutage and zone and NetworkUp[zone] == false then
        return false
    end

    TriggerClientEvent('rz_signal:receive', source, {
        message  = message,
        priority = priority or 'alerte',
        sender   = 'AUTOMATIQUE',
        label    = p.label,
        color    = p.color,
        duration = p.duration,
        sound    = p.sound,
    })

    return true
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉTAT DU RÉSEAU
-- ═══════════════════════════════════════════════════════════════════

---Coupe ou rétablit le réseau d'une zone.
---@param zoneKey string
---@param up boolean
---@param adminId string|nil
---@return boolean ok, string message
function SetNetwork(zoneKey, up, adminId)
    local zone = Config.Zones[zoneKey]
    if not zone then
        return false, ('Zone « %s » inconnue.'):format(tostring(zoneKey))
    end

    if NetworkUp[zoneKey] == up then
        return false, ('%s est déjà %s.')
            :format(zone.label, up and 'alimentée' or 'coupée')
    end

    if up then
        -- On rétablit AVANT de diffuser, sinon la zone concernée
        -- ne recevrait pas son propre message de rétablissement.
        NetworkUp[zoneKey] = true

        Broadcast({
            message  = Config.PickMessage('blackout_end', zone.label:upper()),
            priority = 'info',
            sender   = 'RESEAU',
        })
    else
        -- On diffuse AVANT de couper : les joueurs sur place doivent
        -- voir le message qui annonce leur propre coupure.
        Broadcast({
            message  = Config.PickMessage('blackout_start', zone.label:upper()),
            priority = 'critique',
            sender   = 'RESEAU',
        })

        NetworkUp[zoneKey] = false
    end

    -- Relais vers le script blackout, qui gère l'éclairage réel
    if Config.Blackout.relayCommand then
        local cmd = ('%s %s %s'):format(
            Config.Blackout.commandName, zoneKey, up and 'on' or 'off')

        local ok = pcall(function() ExecuteCommand(cmd) end)

        if not ok then
            print(('^3[rz_signal]^7 relais blackout échoué : %s'):format(cmd))
        end
    end

    MySQL.prepare([[
        INSERT INTO rz_signal_network (zone_key, powered, changed_by)
        VALUES (?, ?, ?)
    ]], { zoneKey, up and 1 or 0, adminId })

    return true, ('%s : réseau %s.'):format(zone.label, up and 'rétabli' or 'coupé')
end

exports('SetNetwork', SetNetwork)
exports('IsNetworkUp', function(zoneKey) return NetworkUp[zoneKey] ~= false end)
exports('GetPlayerZone', function(source) return PlayerZone[source] end)


-- ═══════════════════════════════════════════════════════════════════
--  SUIVI DE POSITION
--
--  On prévient le joueur quand il entre ou sort d'une zone sans
--  réseau. C'est ce qui rend la coupure tangible : le pager devient
--  muet, et on comprend pourquoi.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Detection.interval)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local newZone = zoneOf(src)
            local oldZone = PlayerZone[src]

            if newZone ~= oldZone then
                PlayerZone[src] = newZone

                if hasPager(src) then
                    local wasDown = oldZone and NetworkUp[oldZone] == false
                    local isDown  = newZone and NetworkUp[newZone] == false

                    if isDown and not wasDown then
                        TriggerClientEvent('rz_signal:receive', src, {
                            message  = Config.PickMessage('signal_lost'),
                            priority = 'alerte',
                            sender   = 'RESEAU',
                            label    = Config.Priorities.alerte.label,
                            color    = Config.Priorities.alerte.color,
                            duration = 8000,
                            sound    = 'Beep_Red',
                        })

                    elseif wasDown and not isDown then
                        TriggerClientEvent('rz_signal:receive', src, {
                            message  = Config.PickMessage('signal_back'),
                            priority = 'info',
                            sender   = 'RESEAU',
                            label    = Config.Priorities.info.label,
                            color    = Config.Priorities.info.color,
                            duration = 6000,
                            sound    = 'NAV_UP_DOWN',
                        })
                    end
                end
            end
        end
    end
end)


AddEventHandler('playerDropped', function()
    PlayerZone[source] = nil
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Toutes les zones repartent alimentées après un redémarrage :
    -- laisser une coupure active sans que personne s'en souvienne
    -- créerait un bug invisible et très pénible à diagnostiquer.
    for key in pairs(Config.Zones) do
        NetworkUp[key] = true
    end

    dbg(('%d zone(s) de couverture, toutes alimentées'):format(
        #(function() local n = {} for k in pairs(Config.Zones) do n[#n+1] = k end return n end)()))
end)
