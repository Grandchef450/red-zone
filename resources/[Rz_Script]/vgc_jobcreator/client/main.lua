-- ============================================================
--  VGC JOB CREATOR  |  client/main.lua
--  Outil de generation de config jobs. Capture la position du
--  joueur pour spawns/blips/stash/vestiaire/boss. Aucun framework.
-- ============================================================

local isOpen = false
local resourceName = GetCurrentResourceName()
local previewBlips = {}

local function dbg(msg)
    if Config.Debug then
        print(('^6[vgc_jobcreator]^7 %s'):format(msg))
    end
end

local function sendUI(action, payload)
    payload = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

-- Position courante du joueur, arrondie
local function getCoords()
    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    local h   = GetEntityHeading(ped)
    return {
        x = math.floor(c.x * 1000 + 0.5) / 1000,
        y = math.floor(c.y * 1000 + 0.5) / 1000,
        z = math.floor(c.z * 1000 + 0.5) / 1000,
        h = math.floor(h   * 100  + 0.5) / 100,
    }
end

-- ── Apercu des blips d'un job en cours d'edition ──────────
local function clearPreview()
    for _, b in ipairs(previewBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    previewBlips = {}
end

local function drawPreview(blips)
    clearPreview()
    if type(blips) ~= 'table' then return end
    for _, b in ipairs(blips) do
        local c = b.coords
        if c then
            local blip = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
            SetBlipSprite(blip, math.floor(b.sprite or 1))
            SetBlipColour(blip, math.floor(b.color or 0))
            SetBlipScale(blip, (b.scale or 0.8) + 0.0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(tostring(b.label or 'Blip'))
            EndTextCommandSetBlipName(blip)
            previewBlips[#previewBlips + 1] = blip
        end
    end
    dbg(('apercu : %d blip(s) dessine(s)'):format(#previewBlips))
end

-- ============================================================
--  OUVERTURE / FERMETURE
-- ============================================================
local function openUI()
    isOpen = true
    SetNuiFocus(true, true)
    sendUI('open', {
        resource    = resourceName,
        blipSprites = Config.BlipSprites,
        blipColors  = Config.BlipColors,
    })
    -- Demande la liste des jobs deja enregistres
    TriggerServerEvent('vgc_jobcreator:server:list')
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    clearPreview()
    sendUI('close')
end

local function toggleUI()
    if isOpen then closeUI() else openUI() end
end

RegisterCommand('jobcreator', toggleUI, false)
RegisterKeyMapping('jobcreator', 'Ouvrir le createur de jobs', 'keyboard', Config.OpenKey)

print('^2[vgc_jobcreator]^7 client charge — /jobcreator ou '..Config.OpenKey)

-- ============================================================
--  CALLBACKS NUI
-- ============================================================

RegisterNUICallback('getCoords', function(_, cb)
    cb(getCoords())
end)

RegisterNUICallback('list', function(_, cb)
    TriggerServerEvent('vgc_jobcreator:server:list')
    cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
    if type(data.name) ~= 'string' or type(data.job) ~= 'table' then
        cb({ ok = false }); return
    end
    TriggerServerEvent('vgc_jobcreator:server:save', data.name, data.job)
    cb({ ok = true })
end)

RegisterNUICallback('delete', function(data, cb)
    if type(data.name) == 'string' then
        TriggerServerEvent('vgc_jobcreator:server:delete', data.name)
    end
    cb({ ok = true })
end)

RegisterNUICallback('previewBlips', function(data, cb)
    drawPreview(data.blips)
    cb('ok')
end)

RegisterNUICallback('clearPreview', function(_, cb)
    clearPreview()
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- ============================================================
--  RECEPTION SERVEUR -> UI
-- ============================================================

RegisterNetEvent('vgc_jobcreator:client:jobsList', function(jobs)
    sendUI('jobsList', { jobs = jobs or {} })
end)

RegisterNetEvent('vgc_jobcreator:client:saved', function(name)
    sendUI('saved', { name = name })
end)

RegisterNetEvent('vgc_jobcreator:client:deleted', function(name)
    sendUI('deleted', { name = name })
end)

RegisterNetEvent('vgc_jobcreator:client:error', function(msg)
    sendUI('error', { msg = msg })
end)

-- Nettoyage si la ressource s'arrete UI ouverte
AddEventHandler('onResourceStop', function(res)
    if res == resourceName then
        if isOpen then SetNuiFocus(false, false) end
        clearPreview()
    end
end)
