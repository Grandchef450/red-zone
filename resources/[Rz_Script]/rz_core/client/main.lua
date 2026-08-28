--[[
    rz_core / client/main.lua
    Ambiance post-apocalyptique : monde vide, silence total.

    STRUCTURE EN TROIS TEMPS, et ce n'est pas cosmétique :

      • Une fois au démarrage — ce qui ne se remet jamais tout seul
        (radios, scanner, émetteurs, dispatch).

      • Toutes les demi-secondes — ce que le jeu réactive parfois de
        lui-même (niveau de recherche, flags audio après un cinématique).

      • À chaque frame — uniquement les natives suffixées ThisFrame,
        qui n'ont pas le choix.

    L'ancienne version appelait StartAudioScene et
    CancelCurrentPoliceReport soixante fois par seconde alors qu'un
    seul appel suffit. C'est corrigé.
]]

local isCrouching = false

local function dbg(...)
    if Config.Debug then print('^3[rz_core]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  SILENCE — RÉGLAGES DÉFINITIFS
-- ═══════════════════════════════════════════════════════════════════

local function silenceOnce()
    local a = Config.Audio

    if a.ambientScene then
        -- Scène audio qui étouffe l'ambiance générale du monde
        StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
    end

    if a.noRadio then
        SetUserRadioControlEnabled(false)
        SetRadioToStationName('OFF')
        SetMobileRadioEnabledDuringGameplay(false)
        SetAudioFlag('DisableFlightMusic', true)
    end

    if a.noScoreMusic then
        -- Musique dynamique : poursuites, tension, braquages
        SetAudioFlag('WantedMusicDisabled', true)
        SetAudioFlag('DisableFlightMusic', true)
        StopAudioScenes()
        if a.ambientScene then
            StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
        end
    end

    if a.noPoliceScanner then
        SetAudioFlag('PoliceScannerDisabled', true)
        CancelCurrentPoliceReport()
    end

    if a.noStaticEmitters then
        -- Sono des boîtes, radios de magasin, musique des salons de
        -- tatouage. Ce canal continue de jouer même quand tout le
        -- reste est coupé : c'est celui qu'on oublie et qui trahit
        -- un serveur prétendument silencieux.
        for _, emitter in ipairs(Config.StaticEmitters) do
            SetStaticEmitterEnabled(emitter, false)
        end
        dbg(('%d émetteur(s) statique(s) coupé(s)'):format(#Config.StaticEmitters))
    end

    if a.noAmbientZones then
        -- Oiseaux, vagues, vent, faune
        for _, zone in ipairs(Config.AmbientZones) do
            SetAmbientZoneListStatePersistent(zone, false, true)
            SetAmbientZoneStatePersistent(zone, false, true)
        end
        dbg(('%d zone(s) d\'ambiance neutralisée(s)'):format(#Config.AmbientZones))
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  MONDE — RÉGLAGES DÉFINITIFS
-- ═══════════════════════════════════════════════════════════════════

local function worldOnce()
    local w = Config.World

    if w.noTrains then
        SetRandomTrains(false)
        DeleteAllTrains()
    end

    if w.noBoats then
        SetRandomBoats(false)
    end

    if w.noGarbageTrucks then
        SetGarbageTrucks(false)
    end

    if w.noAmbientCops then
        SetCreateRandomCops(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetCreateRandomCopsOnScenarios(false)
        DistantCopCarSirens(false)
    end

    if w.noDispatch then
        -- 1 à 15 couvre police à pied, voitures, hélicos, ambulances,
        -- pompiers, gardes-côtes et l'armée.
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
    end

    if w.noWantedLevel then
        SetMaxWantedLevel(0)
    end

    dbg('monde configuré')
end


-- ═══════════════════════════════════════════════════════════════════
--  ENTRETIEN — CE QUE LE JEU RÉACTIVE PARFOIS SEUL
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Laisse la session s'établir avant de tout couper, sinon
    -- certains réglages sont écrasés par le chargement.
    Wait(2000)

    silenceOnce()
    worldOnce()

    while true do
        Wait(500)

        local player = PlayerId()
        local ped    = PlayerPedId()

        if Config.World.noWantedLevel then
            if GetPlayerWantedLevel(player) ~= 0 then
                ClearPlayerWantedLevel(player)
                SetPlayerWantedLevel(player, 0, false)
                SetPlayerWantedLevelNow(player, false)
            end
            SetPoliceIgnorePlayer(player, true)
            SetEveryoneIgnorePlayer(player, true)
        end

        if Config.Audio.noRadio then
            -- Monter dans un véhicule rallume sa radio
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetVehicleRadioEnabled(veh, false)
                SetVehRadioStation(veh, 'OFF')
            end
        end

        if Config.Audio.noPoliceScanner then
            CancelCurrentPoliceReport()
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  BOUCLE PAR FRAME
--  Uniquement les natives « ThisFrame », qui n'ont pas le choix.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    local d = Config.Density

    while true do
        -- Densité du monde
        SetVehicleDensityMultiplierThisFrame(d.vehicles)
        SetParkedVehicleDensityMultiplierThisFrame(d.parkedVehicles)
        SetRandomVehicleDensityMultiplierThisFrame(d.randomVehicles)
        SetPedDensityMultiplierThisFrame(d.peds)
        SetScenarioPedDensityMultiplierThisFrame(d.scenarioPeds, d.scenarioPeds)

        -- Interface
        for component, hide in pairs(Config.HideHud) do
            if hide then
                HideHudComponentThisFrame(component)
            end
        end

        Wait(0)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ACCROUPISSEMENT
--
--  L'ancienne version testait GetPedStealthMovement(playerPed) avec
--  une variable jamais déclarée : le blocage du mode furtif ne
--  fonctionnait donc pas du tout. Corrigé ici.
-- ═══════════════════════════════════════════════════════════════════

if Config.Crouch.enabled then
    CreateThread(function()
        local c = Config.Crouch

        -- Préchargement : évite le blocage au premier appui
        RequestAnimSet(c.clipset)
        RequestAnimSet(c.standUp)

        local timeout = GetGameTimer() + 10000
        while (not HasAnimSetLoaded(c.clipset) or not HasAnimSetLoaded(c.standUp))
              and GetGameTimer() < timeout do
            Wait(100)
        end

        if not HasAnimSetLoaded(c.clipset) then
            print('^1[rz_core]^7 jeu d\'animation accroupi introuvable, fonction désactivée')
            return
        end

        dbg('accroupissement prêt')

        while true do
            local ped = PlayerPedId()

            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                -- Mode furtif de GTA : bruyant et lent, on le coupe
                if GetPedStealthMovement(ped) == 1 then
                    SetPedStealthMovement(ped, false, '')
                end

                DisableControlAction(0, c.key, true)

                if not IsPauseMenuActive() and IsDisabledControlJustPressed(0, c.key) then
                    if isCrouching then
                        ResetPedMovementClipset(ped, 0.5)
                        ResetPedStrafeClipset(ped)
                        isCrouching = false
                    else
                        SetPedMovementClipset(ped, c.clipset, 0.55)
                        SetPedStrafeClipset(ped, c.strafe)
                        isCrouching = true
                    end
                end
            elseif isCrouching then
                -- Mort ou changement de personnage : on réinitialise
                isCrouching = false
            end

            Wait(0)
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  REMISE EN ÉTAT À L'ARRÊT
--  Sans ça, un /restart rz_core laisse le joueur muet et accroupi.
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local ped = PlayerPedId()

    ResetPedMovementClipset(ped, 0.5)
    ResetPedStrafeClipset(ped)

    StopAudioScenes()
    SetUserRadioControlEnabled(true)
    SetAudioFlag('PoliceScannerDisabled', false)
    SetAudioFlag('WantedMusicDisabled', false)

    for _, emitter in ipairs(Config.StaticEmitters) do
        SetStaticEmitterEnabled(emitter, true)
    end

    SetMaxWantedLevel(5)
    SetPoliceIgnorePlayer(PlayerId(), false)
    SetEveryoneIgnorePlayer(PlayerId(), false)
end)


-- ═══════════════════════════════════════════════════════════════════
--  EXPORTS
-- ═══════════════════════════════════════════════════════════════════

exports('IsCrouching', function() return isCrouching end)

exports('SetDensity', function(value)
    -- Permet à un script d'événement de repeupler temporairement
    -- une zone : une caravane de survivants, une horde scriptée.
    value = math.max(0.0, math.min(1.0, tonumber(value) or 0.0))
    Config.Density.vehicles       = value
    Config.Density.peds           = value
    Config.Density.randomVehicles = value
    Config.Density.parkedVehicles = value
    Config.Density.scenarioPeds   = value
end)
