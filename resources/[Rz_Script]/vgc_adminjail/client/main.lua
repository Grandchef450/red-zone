-- ============================================================
--  VGC ADMIN JAIL | client/main.lua
--  Deux roles dans ce fichier :
--   1) PANNEAU ADMIN (F11) — demande d'ouverture validee serveur
--   2) JOUEUR EMPRISONNE — TP, laisse anti-fuite, compte a
--      rebours en haut de l'ecran, musique en boucle (NUI)
-- ============================================================

local panelOpen = false
local jailed    = false
local jailPos   = nil   -- vector3 du point de prison
local leashCfg  = nil

local function dbg(msg)
    if Config.Debug then
        print(('^5[vgc_adminjail]^7 %s'):format(msg))
    end
end

local function sendUI(action, payload)
    payload        = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

-- ============================================================
--  PANNEAU ADMIN
-- ============================================================

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    SetNuiFocus(false, false)
    sendUI('closePanel')
end

RegisterCommand('adminjail', function()
    if panelOpen then
        closePanel()
        return
    end
    dbg('demande d\'ouverture du panneau jail')
    TriggerServerEvent('vgc_adminjail:server:requestOpen')
end, false)
RegisterKeyMapping('adminjail', 'Admin Jail (VGC)', 'keyboard', Config.OpenKey)

RegisterNetEvent('vgc_adminjail:client:openPanel', function(data)
    panelOpen = true
    SetNuiFocus(true, true)
    -- Position actuelle de l'admin pour l'option "Ma position"
    local pos = GetEntityCoords(PlayerPedId())
    data.myPos = { x = pos.x, y = pos.y, z = pos.z, heading = GetEntityHeading(PlayerPedId()) }
    sendUI('openPanel', { data = data })
end)

RegisterNetEvent('vgc_adminjail:client:panelData', function(data)
    if not panelOpen then return end
    local pos = GetEntityCoords(PlayerPedId())
    data.myPos = { x = pos.x, y = pos.y, z = pos.z, heading = GetEntityHeading(PlayerPedId()) }
    sendUI('panelData', { data = data })
end)

-- ── NUI callbacks du panneau ──────────────────────────────

RegisterNUICallback('closePanel', function(_, cb)
    closePanel()
    cb('ok')
end)

RegisterNUICallback('jail', function(data, cb)
    TriggerServerEvent('vgc_adminjail:server:jail', data)
    cb('ok')
end)

RegisterNUICallback('unjail', function(data, cb)
    TriggerServerEvent('vgc_adminjail:server:unjail', tostring(data.license or ''))
    cb('ok')
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('vgc_adminjail:server:refresh')
    cb('ok')
end)

-- ============================================================
--  JOUEUR EMPRISONNE
-- ============================================================

-- TP sur le sol le plus proche des coordonnees demandees
local function teleport(x, y, z, heading)
    local ped = PlayerPedId()
    -- Sort le joueur de son vehicule le cas echeant
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
        Wait(400)
        ped = PlayerPedId()
    end
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    if heading then SetEntityHeading(ped, heading + 0.0) end
    -- Ajuste sur le sol si la hauteur est approximative
    Wait(150)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
    if found and math.abs(groundZ - z) < 15.0 then
        SetEntityCoords(PlayerPedId(), x, y, groundZ + 0.5, false, false, false, false)
    end
end

RegisterNetEvent('vgc_adminjail:client:jail', function(data)
    jailed   = true
    jailPos  = vector3(data.coords.x, data.coords.y, data.coords.z)
    leashCfg = data.leash

    teleport(data.coords.x, data.coords.y, data.coords.z, data.coords.heading)

    -- Overlay compte a rebours + musique (PAS de focus NUI :
    -- le joueur garde le controle, seul l'affichage est ajoute)
    sendUI('jailStart', {
        seconds = data.seconds,
        reason  = data.reason,
        music   = data.music, -- { url, volume } ou nil
    })

    dbg(('emprisonne %ds a (%.1f, %.1f, %.1f)'):format(data.seconds, jailPos.x, jailPos.y, jailPos.z))

    -- ── Laisse anti-fuite ──
    if leashCfg and leashCfg.enabled then
        CreateThread(function()
            while jailed do
                Wait(1500)
                local ped = PlayerPedId()
                if #(GetEntityCoords(ped) - jailPos) > (leashCfg.radius or 25.0) then
                    teleport(jailPos.x, jailPos.y, jailPos.z, nil)
                    sendUI('jailLeash') -- petit flash "reste ici !" sur l'overlay
                end
            end
        end)
    end
end)

RegisterNetEvent('vgc_adminjail:client:release', function(releasePoint)
    if not jailed then return end
    jailed  = false
    jailPos = nil

    sendUI('jailEnd') -- coupe musique + overlay

    -- TP au point d'arrivee en ville (config serveur)
    teleport(releasePoint.x, releasePoint.y, releasePoint.z, releasePoint.heading)
    dbg('libere — TP au point d\'arrivee en ville')
end)

-- Nettoyage si la ressource s'arrete
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if panelOpen then SetNuiFocus(false, false) end
    if jailed then sendUI('jailEnd') end
end)

print('^2[vgc_adminjail]^7 client charge — F11 / commande "adminjail"')
