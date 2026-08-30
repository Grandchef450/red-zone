--[[
    loadingscreen / client.lua
    RÉÉCRIT POUR QBOX — RedZone, 30 août 2026

    ─── POURQUOI L'ÉCRAN NE SE FERMAIT PLUS ───────────────────────

    Le fichier d'origine attendait l'événement « playerSpawned ».

    Celui-ci est émis par la ressource `spawnmanager`, que le
    server.cfg désactive volontairement : c'est qbx_core qui gère
    le spawn depuis la migration vers Qbox.

    L'événement n'arrivant jamais, ShutdownLoadingScreenNui() n'était
    jamais appelé — et comme le manifeste déclare
    « loadscreen_manual_shutdown 'yes' », FiveM ne fermait pas
    l'écran de lui-même. D'où la boucle infinie.

    ─── LA CORRECTION ─────────────────────────────────────────────

    On écoute maintenant PLUSIEURS signaux, et le premier qui arrive
    ferme l'écran :

      • QBCore:Client:OnPlayerLoaded  → le personnage est chargé
      • playerSpawned                 → si spawnmanager revient un jour
      • une sécurité de temps         → si rien n'arrive

    La sécurité est indispensable : sans elle, la moindre panne d'un
    script de spawn enferme le joueur dans un écran de chargement
    sans aucun moyen d'en sortir, sinon fermer le jeu.
]]

local closed = false


---Ferme l'écran de chargement. Sans effet si déjà fermé.
local function shutdown(reason)
    if closed then return end
    closed = true

    ShutdownLoadingScreenNui()

    print(('[loadingscreen] fermé — %s'):format(reason or 'raison inconnue'))
end


-- ─── Qbox : le personnage est prêt ─────────────────────────────
-- C'est le signal normal depuis la migration.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    shutdown('personnage chargé')
end)


-- ─── Qbox : nom d'événement alternatif ─────────────────────────
-- Selon les versions, qbx_core émet l'un ou l'autre.
RegisterNetEvent('qbx_core:client:playerLoaded', function()
    shutdown('personnage chargé (qbx)')
end)


-- ─── spawnmanager, si la ressource revient un jour ─────────────
AddEventHandler('playerSpawned', function()
    shutdown('playerSpawned')
end)


-- ═══════════════════════════════════════════════════════════════════
--  SÉCURITÉ
--
--  Si aucun des signaux ci-dessus n'arrive, on ferme quand même dès
--  que le joueur existe et que la session est active.
--
--  Ce filet n'est pas un luxe : sans lui, un script de spawn en
--  panne enferme le joueur dans l'écran de chargement, sans autre
--  issue que de fermer le jeu.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Délai raccourci à 20 secondes. Le précédent était de 60,
    -- pensé pour laisser à un multicharacter le temps de s'afficher.
    -- Puisque ZSX ne peut pas le faire — son interface n'est pas
    -- installée — attendre une minute ne sert qu'à faire patienter.
    local deadline = GetGameTimer() + 20000

    while not closed do
        Wait(500)

        -- Le joueur est dans le monde et la session tourne
        if NetworkIsSessionStarted() and DoesEntityExist(PlayerPedId()) then
            local ped = PlayerPedId()

            -- Un ped à la position 0,0,0 signifie que le monde n'est
            -- pas encore chargé : fermer maintenant afficherait le
            -- vide sous la carte.
            local c = GetEntityCoords(ped)

            if #(c - vec3(0.0, 0.0, 0.0)) > 1.0 then
                Wait(2000)   -- laisse le décor se charger
                shutdown('session active')
                break
            end

            -- Le ped existe mais reste à l'origine : le monde n'est
            -- pas encore chargé. On attend, sans bloquer la boucle.
        elseif GetGameTimer() > (deadline - 5000) then
            -- Cinq secondes avant l'échéance, on force l'affichage
            -- d'un message pour que le joueur sache que ça avance.
            print('[loadingscreen] en attente de la session...')
        end

        if GetGameTimer() > deadline then
            shutdown('délai de sécurité dépassé')
            break
        end
    end
end)
