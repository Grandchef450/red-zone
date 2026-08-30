--[[
    rz_fps / client/main.lua

    Optimisation graphique et compteur de FPS.

    DEUX PRINCIPES

    1. AUCUN TIMECYCLE. L'ancien script assombrissait l'écran pour
       simuler un gain de performance. Ici, chaque réglage agit sur
       ce que la carte graphique doit réellement calculer — et rien
       n'entre en conflit avec le voile rouge de rz_radioactivite.

    2. LES RÉGLAGES PERSISTENT. Le choix du joueur est écrit dans le
       stockage local de FiveM : il le retrouve à sa reconnexion,
       sans avoir à recommencer à chaque session.
]]

local current = nil        -- profil actif
local showCounter = false
local uiOpen = false

local fps, frameAccum, frameCount = 0, 0.0, 0

local function dbg(...)
    if Config.Debug then print('^3[rz_fps]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  PERSISTANCE
--
--  SetResourceKvp écrit sur le disque du joueur. C'est ce qui
--  distingue un réglage utile d'un gadget qu'il faut reconfigurer
--  à chaque connexion.
-- ═══════════════════════════════════════════════════════════════════

local function save()
    SetResourceKvp('rz_fps:profile', current and current.key or Config.DefaultProfile)
    SetResourceKvp('rz_fps:counter', showCounter and '1' or '0')
end


local function load()
    local key = GetResourceKvpString('rz_fps:profile') or Config.DefaultProfile
    local counter = GetResourceKvpString('rz_fps:counter')

    showCounter = counter == '1'
        or (counter == nil and Config.Counter.enabledByDefault)

    return Config.GetProfile(key) or Config.GetProfile(Config.DefaultProfile)
end


-- ═══════════════════════════════════════════════════════════════════
--  APPLICATION D'UN PROFIL
--
--  Certains réglages tiennent une fois posés ; d'autres se réappliquent
--  à chaque frame parce que le moteur les réinitialise. Ils sont
--  séparés en deux fonctions pour ne pas gaspiller d'appels.
-- ═══════════════════════════════════════════════════════════════════

---Réglages durables, posés une seule fois.
local function applyPersistent(p)
    -- ─── OMBRES ────────────────────────────────────────────────
    -- Second poste de dépense après la géométrie. Recalculées à
    -- chaque frame, pour chaque source de lumière.
    CascadeShadowsEnableEntityTracker(p.shadows)
    CascadeShadowsSetAircraftMode(not p.shadows)
    CascadeShadowsSetDynamicDepthMode(p.shadows)
    CascadeShadowsSetShadowSampleType(p.shadows and 'CSM_ST_BOX3x3' or 'CSM_ST_POINT')

    if p.shadowBounds then
        CascadeShadowsSetCascadeBoundsScale(p.shadowBounds)
    end

    -- Ombres des objets lointains : coûteuses et peu visibles.
    SetFarShadowsSuppressed(not p.farShadows)

    -- ─── MÉMOIRE VIDÉO ─────────────────────────────────────────
    -- Le réglage décisif sur une machine à faible mémoire : c'est
    -- lui qui évite les textures qui mettent dix secondes à
    -- apparaître, et les chutes brutales en zone dense.
    SetReducePedModelBudget(p.reduceBudget)
    SetReduceVehicleModelBudget(p.reduceBudget)

    -- ─── LUMIÈRES ──────────────────────────────────────────────
    DistantCoronasDisabled(not p.coronas)

    if p.lightCutoff then
        SetLightsCutoffDistanceTweak(p.lightCutoff)
    end

    -- ─── TRACES AU SOL ─────────────────────────────────────────
    -- Chaque empreinte est une décalque persistante à dessiner.
    SetForcePedFootstepsTracks(p.tracks)
    SetForceVehicleTrails(p.tracks)

    -- ─── DISTANCE D'AFFICHAGE ──────────────────────────────────
    SetPedLodMultiplier(p.pedLod)

    dbg(('profil appliqué : %s'):format(p.label))
end


---Réglages que le moteur réinitialise à chaque frame.
local function applyPerFrame(p)
    -- LE levier principal. Réduit la distance à laquelle les objets
    -- passent en haute définition. Aucun autre réglage n'a autant
    -- d'effet sur les FPS.
    OverrideLodscaleThisFrame(p.lodScale)

    if not p.decals then
        SetDisableDecalRenderingThisFrame()
    end
end


function ApplyProfile(key, silent)
    local p = Config.GetProfile(key)
    if not p then return false end

    current = p
    applyPersistent(p)
    save()

    if not silent then
        lib.notify({
            type        = 'success',
            title       = ('Profil : %s'):format(p.label),
            description = p.note,
            duration    = 5000,
        })
    end

    SendNUIMessage({ action = 'profile', key = p.key })

    return true
end


-- ═══════════════════════════════════════════════════════════════════
--  BOUCLE DE RENDU
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    ApplyProfile((load() or Config.Profiles[1]).key, true)

    while true do
        if current then
            applyPerFrame(current)
        end
        Wait(0)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMPTEUR DE FPS
--
--  Moyenné sur l'intervalle de rafraîchissement plutôt que calculé
--  à l'instant : un chiffre qui saute vingt fois par seconde est
--  illisible et donne une fausse impression d'instabilité.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        frameAccum = frameAccum + GetFrameTime()
        frameCount = frameCount + 1
        Wait(0)
    end
end)


CreateThread(function()
    while true do
        Wait(Config.Counter.refresh)

        if frameCount > 0 and frameAccum > 0 then
            fps = math.floor(frameCount / frameAccum + 0.5)
            frameAccum, frameCount = 0.0, 0
        end

        if showCounter then
            SendNUIMessage({
                action = 'fps',
                value  = fps,
                good   = Config.Counter.good,
                warn   = Config.Counter.warning,
            })
        end
    end
end)


function ToggleCounter(state)
    showCounter = state
    save()

    SendNUIMessage({
        action   = 'counter',
        show     = showCounter,
        position = Config.Counter.position,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  INTERFACE
-- ═══════════════════════════════════════════════════════════════════

function OpenMenu()
    if uiOpen then return end
    uiOpen = true

    local list = {}
    for _, p in ipairs(Config.Profiles) do
        list[#list + 1] = {
            key   = p.key,
            label = p.label,
            note  = p.note,
            hint  = p.hint,
        }
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        profiles = list,
        current  = current and current.key or Config.DefaultProfile,
        counter  = showCounter,
        fps      = fps,
    })
end


local function closeMenu()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end


RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({})
end)


RegisterNUICallback('setProfile', function(data, cb)
    ApplyProfile(data.key)
    cb({})
end)


RegisterNUICallback('setCounter', function(data, cb)
    ToggleCounter(data.show and true or false)
    cb({})
end)


RegisterCommand(Config.Command, function()
    if uiOpen then closeMenu() else OpenMenu() end
end, false)

RegisterKeyMapping(Config.Command, 'Réglages graphiques RedZone', 'keyboard', Config.Key)




-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION AUTOMATIQUE
--
--  Pour le joueur qui ne sait pas où se situer. On bascule
--  temporairement sur le profil le plus exigeant, on mesure ce que
--  sa machine encaisse SANS aide, puis on recommande.
--
--  Mesurer sur un profil déjà allégé donnerait un chiffre flatteur
--  et un mauvais conseil : le joueur choisirait « performant » et
--  ramerait ensuite.
-- ═══════════════════════════════════════════════════════════════════

local detecting = false

function RunAutoDetect()
    if detecting then return end
    detecting = true

    local previous = current and current.key or Config.DefaultProfile

    -- On teste sans aucun bridage
    ApplyProfile('puissant', true)

    CreateThread(function()
        local warm = Config.Auto.warmup
        local total = Config.Auto.duration

        -- Chauffe : le temps que le profil s'applique et que le
        -- décor se recharge en haute définition.
        for i = warm, 1, -1 do
            SendNUIMessage({
                action = 'detecting',
                phase  = 'warmup',
                left   = i,
            })
            Wait(1000)
        end

        -- Mesure
        local samples, sum = 0, 0

        for i = total, 1, -1 do
            Wait(1000)

            if fps > 0 then
                sum = sum + fps
                samples = samples + 1
            end

            SendNUIMessage({
                action  = 'detecting',
                phase   = 'measure',
                left    = i,
                current = fps,
            })
        end

        local average = samples > 0 and math.floor(sum / samples + 0.5) or 0
        local recommended = Config.RecommendFor(average)
        local p = Config.GetProfile(recommended)

        detecting = false

        -- On applique la recommandation plutôt que de restaurer
        -- l'ancien profil : le joueur a lancé la détection pour
        -- qu'on décide à sa place.
        ApplyProfile(recommended, true)

        SendNUIMessage({
            action      = 'detected',
            average     = average,
            recommended = recommended,
            label       = p and p.label or recommended,
            hint        = p and p.hint or '',
        })

        lib.notify({
            type        = 'success',
            title       = ('Mesure : %d FPS en moyenne'):format(average),
            description = ('Profil appliqué : %s'):format(p and p.label or recommended),
            duration    = 10000,
        })

        dbg(('détection : %d FPS → %s (ancien : %s)')
            :format(average, recommended, previous))
    end)
end


RegisterNUICallback('autoDetect', function(_, cb)
    cb({})
    RunAutoDetect()
end)


-- ═══════════════════════════════════════════════════════════════════
--  EXPORTS
--
--  rz_radioactivite ou tout autre script peut interroger le profil
--  actif — par exemple pour adapter l'intensité d'un effet visuel
--  sur une machine modeste.
-- ═══════════════════════════════════════════════════════════════════

exports('GetProfile', function() return current and current.key or nil end)
exports('GetFps', function() return fps end)


AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(1500)
    SendNUIMessage({
        action   = 'counter',
        show     = showCounter,
        position = Config.Counter.position,
    })
end)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- On rend la main proprement : sans ça, un restart laisserait
    -- le joueur avec des ombres coupées et le curseur bloqué.
    SetNuiFocus(false, false)
    CascadeShadowsEnableEntityTracker(true)
    CascadeShadowsSetAircraftMode(false)
    SetPedLodMultiplier(1.0)
    SetForcePedFootstepsTracks(true)
    SetForceVehicleTrails(true)
end)
