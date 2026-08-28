-- ============================================================
--  VGC VIP | client/main.lua
--  Tablette (F4), application des peds valides serveur,
--  reanimation hopital, marqueurs de farm en ville.
-- ============================================================

local isOpen = false

local function dbg(msg)
    if Config.Debug then print(('^5[vgc_vip]^7 %s'):format(msg)) end
end

local function sendUI(action, payload)
    payload        = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

-- ============================================================
--  OUVERTURE / FERMETURE
-- ============================================================

local function closeTablet()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    sendUI('close')
end

RegisterCommand('vip', function()
    if isOpen then closeTablet() return end
    TriggerServerEvent('vgc_vip:server:requestOpen')
end, false)
RegisterKeyMapping('vip', 'Tablette VIP (VGC)', 'keyboard', Config.OpenKey)

RegisterNetEvent('vgc_vip:client:open', function(state)
    isOpen = true
    SetNuiFocus(true, true)
    sendUI('open', { state = state })
end)

RegisterNetEvent('vgc_vip:client:state', function(state)
    sendUI('state', { state = state })
end)

RegisterNetEvent('vgc_vip:client:result', function(res)
    sendUI('result', { data = res })
end)

-- ============================================================
--  NUI CALLBACKS → events serveur (tout est valide la-bas)
-- ============================================================

RegisterNUICallback('close', function(_, cb) closeTablet() cb('ok') end)
RegisterNUICallback('refresh', function(_, cb) TriggerServerEvent('vgc_vip:server:refresh') cb('ok') end)
RegisterNUICallback('buyTier', function(d, cb) TriggerServerEvent('vgc_vip:server:buyTier', tonumber(d.id)) cb('ok') end)
RegisterNUICallback('choosePed', function(d, cb) TriggerServerEvent('vgc_vip:server:choosePed', tostring(d.model)) cb('ok') end)
RegisterNUICallback('applyPed', function(d, cb) TriggerServerEvent('vgc_vip:server:applyPed', tostring(d.model)) cb('ok') end)
RegisterNUICallback('useFreeRevive', function(_, cb) TriggerServerEvent('vgc_vip:server:useFreeRevive') cb('ok') end)
RegisterNUICallback('craftKit', function(_, cb) TriggerServerEvent('vgc_vip:server:craftKit') cb('ok') end)
RegisterNUICallback('useKit', function(_, cb) TriggerServerEvent('vgc_vip:server:useKit') cb('ok') end)
RegisterNUICallback('buyShopItem', function(d, cb) TriggerServerEvent('vgc_vip:server:buyShopItem', tostring(d.id)) cb('ok') end)

RegisterNUICallback('resetPed', function(_, cb)
    -- Ped d'origine : recharge le skin via l'appearance si dispo,
    -- sinon retombe sur le freemode masculin.
    if GetResourceState(Config.ReloadSkin.resource) == 'started' then
        TriggerEvent(Config.ReloadSkin.event)
    else
        local model = joaat('mp_m_freemode_01')
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        SetPlayerModel(PlayerId(), model)
        SetPedDefaultComponentVariation(PlayerPedId())
        SetModelAsNoLongerNeeded(model)
    end
    cb('ok')
end)

-- ============================================================
--  APPLICATION D'UN PED (approuve par le serveur uniquement)
-- ============================================================

RegisterNetEvent('vgc_vip:client:applyPed', function(model)
    local hash = joaat(model)
    if not IsModelValid(hash) or not IsModelInCdimage(hash) then
        dbg(('modele invalide : %s'):format(model))
        return
    end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return end

    SetPlayerModel(PlayerId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetPedRandomComponentVariation(PlayerPedId(), 0)
    SetModelAsNoLongerNeeded(hash)
    dbg(('ped applique : %s'):format(model))
end)

-- ============================================================
--  REANIMATION HOPITAL IMMEDIATE (achat boutique)
-- ============================================================

RegisterNetEvent('vgc_vip:client:reviveHospital', function(hosp)
    DoScreenFadeOut(400)
    Wait(500)
    SetEntityCoords(PlayerPedId(), hosp.x, hosp.y, hosp.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), hosp.heading or 0.0)
    TriggerEvent(Config.ReviveEvent)
    Wait(300)
    DoScreenFadeIn(400)
end)

-- ============================================================
--  POINTS DE FARM EN VILLE
--  Marqueurs + texte 3D + E pour recolter (validation serveur)
-- ============================================================

local farming = false

local function draw3DText(x, y, z, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 215)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function harvest(index, spot)
    if farming then return end
    farming = true
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
    -- Barre de progression minimaliste via le chat (remplace par ta progressbar si tu en as une)
    TriggerEvent('chat:addMessage', { color = {120,170,255}, args = { '[Farm]', ('Récolte de %s…'):format(spot.label) } })
    Wait(spot.duration or 6000)
    ClearPedTasks(ped)
    TriggerServerEvent('vgc_vip:server:farm', index)
    farming = false
end

RegisterNetEvent('vgc_vip:client:farmed', function(material, amount)
    dbg(('recolte : %dx %s'):format(amount, material))
end)

CreateThread(function()
    while true do
        local wait = 1000
        local pos = GetEntityCoords(PlayerPedId())
        for i, spot in ipairs(Config.FarmSpots) do
            local dist = #(pos - vector3(spot.x, spot.y, spot.z))
            if dist < 20.0 then
                wait = 0
                DrawMarker(2, spot.x, spot.y, spot.z + 0.3, 0, 0, 0, 0, 0, 0,
                    0.35, 0.35, 0.35,
                    Config.FarmMarker.r, Config.FarmMarker.g, Config.FarmMarker.b, Config.FarmMarker.a,
                    true, true, 2, false, nil, nil, false)
                if dist < 2.0 then
                    draw3DText(spot.x, spot.y, spot.z + 0.8, ('~b~[E]~w~ %s'):format(spot.label))
                    if IsControlJustReleased(0, 38) and not farming then -- E
                        harvest(i, spot)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

-- Nettoyage
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)

print('^2[vgc_vip]^7 client charge — F4 / commande "vip"')
