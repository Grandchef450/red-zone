-- ============================================================
--  VGC REPORTS  |  client/main.lua
-- ============================================================

local resourceName = GetCurrentResourceName()
local isOpen = false
local amStaff = false

local function sendUI(a, p) p = p or {}; p.action = a; SendNUIMessage(p) end

-- ── Ouverture / fermeture ─────────────────────────────────
local function openUI()
    isOpen = true
    SetNuiFocus(true, true)
    sendUI('open', { staff = amStaff, categories = Config.Categories })
    TriggerServerEvent('vgc_reports:server:whoami')
end
local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    sendUI('close')
end
RegisterCommand('report', function() if isOpen then closeUI() else openUI() end end, false)
RegisterKeyMapping('report', 'Ouvrir les reports', 'keyboard', Config.OpenKey)
print('^2[vgc_reports]^7 client charge — /report ou ' .. Config.OpenKey)

-- Demande le statut staff au spawn (pour les notifs meme panneau fermé)
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    Wait(800)
    TriggerServerEvent('vgc_reports:server:whoami')
end)

-- ── Callbacks NUI ─────────────────────────────────────────
RegisterNUICallback('submit', function(d, cb)
    if type(d.message) == 'string' and #d.message > 1 then
        TriggerServerEvent('vgc_reports:server:submit', d.category, d.message)
    end
    cb('ok')
end)
RegisterNUICallback('reply', function(d, cb)
    if d.id and type(d.text) == 'string' then TriggerServerEvent('vgc_reports:server:reply', d.id, d.text) end
    cb('ok')
end)
RegisterNUICallback('claim', function(d, cb)
    if d.id then TriggerServerEvent('vgc_reports:server:claim', d.id) end; cb('ok')
end)
RegisterNUICallback('message', function(d, cb)
    if d.id and type(d.text) == 'string' then TriggerServerEvent('vgc_reports:server:message', d.id, d.text) end; cb('ok')
end)
RegisterNUICallback('closeReport', function(d, cb)
    if d.id then TriggerServerEvent('vgc_reports:server:close', d.id) end; cb('ok')
end)
RegisterNUICallback('deleteReport', function(d, cb)
    if d.id then TriggerServerEvent('vgc_reports:server:delete', d.id) end; cb('ok')
end)
RegisterNUICallback('goto', function(d, cb)
    if d.id then TriggerServerEvent('vgc_reports:server:goto', d.id) end; cb('ok')
end)
RegisterNUICallback('close', function(_, cb) closeUI(); cb('ok') end)

-- ── Reception serveur ─────────────────────────────────────
RegisterNetEvent('vgc_reports:client:whoami', function(staff)
    amStaff = staff and true or false
    if isOpen then sendUI('role', { staff = amStaff }) end
end)
RegisterNetEvent('vgc_reports:client:staffList', function(list)
    if isOpen then sendUI('staffList', { reports = list }) end
end)
RegisterNetEvent('vgc_reports:client:myReports', function(list)
    if isOpen then sendUI('myReports', { reports = list }) end
end)
RegisterNetEvent('vgc_reports:client:reportUpdated', function(r)
    if isOpen then sendUI('reportUpdated', { report = r }) end
end)
RegisterNetEvent('vgc_reports:client:notify', function(msg, kind)
    -- notif chat
    TriggerEvent('chat:addMessage', { color = {120,170,255}, args = { '[Reports]', msg } })
    if isOpen then sendUI('toast', { msg = msg, kind = kind }) end
end)
RegisterNetEvent('vgc_reports:client:teleport', function(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
    TriggerEvent('chat:addMessage', { color = {120,170,255}, args = { '[Reports]', 'Téléporté au joueur.' } })
end)

AddEventHandler('onResourceStop', function(res)
    if res == resourceName and isOpen then SetNuiFocus(false, false) end
end)
