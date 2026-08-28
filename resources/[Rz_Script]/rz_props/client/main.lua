-- ============================================================
--  RZ PROPS  |  client/main.lua
--  Pose de props nommes + synchro des props sauvegardes.
-- ============================================================

local resourceName = GetCurrentResourceName()
local isOpen     = false
local placing    = false
local spawned    = {}     -- [id] = handle de l'objet
local lastList   = {}     -- derniere liste recue (pour l'UI)

local function dbg(msg)
    if Config.Debug then print(('^3[rz_props]^7 %s'):format(msg)) end
end

local function sendUI(action, payload)
    payload = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

-- ── Chargement de modele ──────────────────────────────────
local function loadModel(model)
    local hash = (type(model) == 'number') and model or GetHashKey(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

-- ============================================================
--  SYNCHRO DES PROPS SAUVEGARDES
-- ============================================================
local function spawnProp(p)
    if spawned[p.id] then return end
    local hash = loadModel(p.model)
    if not hash then
        dbg(('^1modele invalide ignore : %s'):format(tostring(p.model)))
        return
    end
    local obj = CreateObject(hash, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false)
    SetEntityHeading(obj, p.h + 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    spawned[p.id] = obj
end

local function removeProp(id)
    local obj = spawned[id]
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    spawned[id] = nil
end

local function syncProps(list)
    lastList = list or {}
    -- ids presents dans la liste
    local present = {}
    for _, p in ipairs(lastList) do
        present[p.id] = true
        spawnProp(p)
    end
    -- supprime ce qui n'est plus dans la liste
    for id in pairs(spawned) do
        if not present[id] then removeProp(id) end
    end
    -- met a jour l'UI si ouverte
    if isOpen then sendUI('list', { props = lastList }) end
end

RegisterNetEvent('rz_props:client:sync', function(list)
    syncProps(list)
end)

RegisterNetEvent('rz_props:client:added', function(p)
    dbg(('prop place enregistre : [%d] %s'):format(p.id, p.label))
end)

RegisterNetEvent('rz_props:client:error', function(msg)
    sendUI('error', { msg = msg })
end)

-- Demande la liste au demarrage / spawn
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    Wait(500)
    TriggerServerEvent('rz_props:server:request')
end)

-- ============================================================
--  MODE PLACEMENT
-- ============================================================
local function drawHelp()
    SetTextFont(4)
    SetTextScale(0.34, 0.34)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(
        'ZQSD/WASD: deplacer  ~n~Fleches G/D: tourner  Fleches H/B: monter/descendre  ~n~Shift: rapide  G: poser au sol  ~n~[ENTREE] Valider   [ECHAP] Annuler')
    DrawText(0.5, 0.86)
    -- petit fond
    DrawRect(0.5, 0.90, 0.42, 0.12, 0, 0, 0, 140)
end

-- Place un prop ; renvoie {x,y,z,h} ou nil si annule
local function placementMode(model)
    local hash = loadModel(model)
    if not hash then
        sendUI('error', { msg = 'Modele invalide : ' .. tostring(model) })
        return nil
    end

    local ped = PlayerPedId()
    local pc  = GetEntityCoords(ped)
    local camRot = GetGameplayCamRot(2)
    local yaw = math.rad(camRot.z)
    local fwd = vector3(-math.sin(yaw), math.cos(yaw), 0.0)

    -- position de depart : 2m devant la camera, colle au sol
    local pos = vector3(pc.x + fwd.x * 2.0, pc.y + fwd.y * 2.0, pc.z)
    local found, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pc.z + 1.0, false)
    if found then pos = vector3(pos.x, pos.y, gz) end
    local heading = GetEntityHeading(ped)

    local obj = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityAlpha(obj, 180, false)

    placing = true
    local result = nil

    while placing do
        Wait(0)

        -- direction relative a la camera
        local cr = GetGameplayCamRot(2)
        local ry = math.rad(cr.z)
        local f  = vector3(-math.sin(ry), math.cos(ry), 0.0)
        local r  = vector3(math.cos(ry), math.sin(ry), 0.0)

        local step = IsDisabledControlPressed(0, 21) and Config.MoveStepFast or Config.MoveStep

        -- desactive les controles genants
        for _, c in ipairs({24, 257, 25, 263, 264, 32, 33, 34, 35, 44, 38, 23, 75, 172, 173, 174, 175, 199, 200}) do
            DisableControlAction(0, c, true)
        end

        -- deplacement
        if IsDisabledControlPressed(0, 32) then pos = pos + f * step end          -- avant
        if IsDisabledControlPressed(0, 33) then pos = pos - f * step end          -- arriere
        if IsDisabledControlPressed(0, 34) then pos = pos - r * step end          -- gauche
        if IsDisabledControlPressed(0, 35) then pos = pos + r * step end          -- droite
        if IsDisabledControlPressed(0, 172) then pos = pos + vector3(0,0, step) end -- monter
        if IsDisabledControlPressed(0, 173) then pos = pos - vector3(0,0, step) end -- descendre
        if IsDisabledControlPressed(0, 174) then heading = heading + Config.RotateStep end -- tourner G
        if IsDisabledControlPressed(0, 175) then heading = heading - Config.RotateStep end -- tourner D

        -- poser au sol (G = 47)
        if IsDisabledControlJustPressed(0, 47) or IsControlJustPressed(0, 47) then
            local ok, g = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
            if ok then pos = vector3(pos.x, pos.y, g) end
        end

        SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(obj, heading)

        drawHelp()

        -- valider (Entree = 201) / annuler (Echap = 202)
        if IsControlJustPressed(0, 201) then
            result = { x = pos.x, y = pos.y, z = pos.z, h = heading % 360.0 }
            placing = false
        elseif IsControlJustPressed(0, 202) then
            result = nil
            placing = false
        end
    end

    if DoesEntityExist(obj) then DeleteEntity(obj) end
    return result
end

-- ============================================================
--  OUVERTURE / FERMETURE
-- ============================================================
local function openUI()
    isOpen = true
    SetNuiFocus(true, true)
    sendUI('open', {
        resource = resourceName,
        presets  = Config.PropPresets,
        props    = lastList,
    })
    TriggerServerEvent('rz_props:server:request')
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    sendUI('close')
end

RegisterCommand('props', function() if isOpen then closeUI() else openUI() end end, false)
RegisterKeyMapping('props', 'Ouvrir le placeur de props', 'keyboard', Config.OpenKey)
print('^2[rz_props]^7 client charge — /props ou ' .. Config.OpenKey)

-- ============================================================
--  CALLBACKS NUI
-- ============================================================

-- Lance le mode placement (cache l'UI le temps de placer)
RegisterNUICallback('startPlace', function(data, cb)
    if type(data.model) ~= 'string' or data.model == '' then cb({ ok = false }); return end
    local label = (type(data.label) == 'string' and data.label ~= '') and data.label or 'Prop'

    -- on libere le focus et on cache l'UI pendant le placement
    SetNuiFocus(false, false)
    sendUI('hide')
    cb({ ok = true })

    CreateThread(function()
        local res = placementMode(data.model)
        if res then
            TriggerServerEvent('rz_props:server:add', {
                model = data.model, label = label,
                x = res.x, y = res.y, z = res.z, h = res.h,
            })
        end
        -- on rouvre l'UI
        if isOpen then
            SetNuiFocus(true, true)
            sendUI('show', { props = lastList })
        end
    end)
end)

RegisterNUICallback('rename', function(data, cb)
    if data.id and type(data.label) == 'string' then
        TriggerServerEvent('rz_props:server:rename', data.id, data.label)
    end
    cb('ok')
end)

RegisterNUICallback('delete', function(data, cb)
    if data.id then TriggerServerEvent('rz_props:server:delete', data.id) end
    cb('ok')
end)

RegisterNUICallback('teleport', function(data, cb)
    -- petit confort : se tp pres d'un prop pour le verifier
    local p
    for _, item in ipairs(lastList) do if item.id == data.id then p = item break end end
    if p then SetEntityCoords(PlayerPedId(), p.x + 0.0, p.y + 0.0, p.z + 1.0, false, false, false, false) end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- Nettoyage
AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end
    if isOpen then SetNuiFocus(false, false) end
    for id in pairs(spawned) do removeProp(id) end
end)

-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE DEPUIS LE MENU ADMIN (F5)
--
--  Le panneau admin appelle https://rz_props/openPanel. On relaie sur
--  la commande existante, ce qui evite de dupliquer la logique
--  d'ouverture et garde un seul chemin de code a maintenir.
-- ═══════════════════════════════════════════════════════════════════

RegisterNUICallback('openPanel', function(_, cb)
    cb({ ok = true })

    -- Laisse le panneau admin rendre le focus avant d'ouvrir le notre,
    -- sinon les deux se disputent la souris.
    SetTimeout(250, function()
        ExecuteCommand('props')
    end)
end)
