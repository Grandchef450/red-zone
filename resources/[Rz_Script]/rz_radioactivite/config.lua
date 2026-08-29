Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  LA ZONE
--
--  ⚠️  À PROPOS DU RAYON
--
--  La zone jouable de GTA V mesure environ 8 500 unités d'est en
--  ouest et 12 000 du nord au sud. Los Santos et Paleto Bay sont
--  séparés d'environ 7 000 unités.
--
--  Un rayon de 5000 donne donc un cercle de 10 000 de DIAMÈTRE —
--  plus large que la carte dans un sens. Il n'y aurait nulle part
--  où fuir, et son déplacement n'aurait aucun sens puisque tout
--  serait toujours dedans.
--
--  Repères utiles :
--     300 →  petite poche, traversée en 30 secondes
--     500 →  contournable à pied, on peut la voir arriver     ← défaut
--    1000 →  couvre une ville et ses abords
--    1500 →  menace sérieuse, il faut vraiment se déplacer
--    5000 →  toute la carte, injouable
--
--  Le curseur du menu admin monte jusqu'à 5000 : tu peux tester en
--  un clic et revenir en arrière tout aussi vite.
-- ═══════════════════════════════════════════════════════════════════
Config.Zone = {
    radius = 500.0,

    -- Vitesse de déplacement, en unités par seconde.
    -- 3.0 ≈ la vitesse d'un joueur à pied. À 8.0, il faut un
    -- véhicule pour distancer le nuage.
    speed = 3.0,

    -- Hauteur : la contamination est atmosphérique, elle monte haut.
    -- Se réfugier sur un toit ne doit pas protéger.
    minZ = -200.0,
    maxZ = 1500.0,

    -- La zone démarre-t-elle active au lancement du serveur ?
    startActive = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉPLACEMENT
--
--  Le nuage rejoint un point tiré au hasard, puis en choisit un
--  autre à l'arrivée. Les bornes ci-dessous encadrent la carte
--  jouable : au-delà, la zone irait dériver au large.
-- ═══════════════════════════════════════════════════════════════════
Config.Movement = {
    enabled = true,

    bounds = {
        minX = -3200.0, maxX = 3800.0,
        minY = -3400.0, maxY = 7000.0,
    },

    -- Distance minimale d'un nouveau point, pour éviter que le nuage
    -- fasse du sur-place autour d'un même quartier.
    minTravel = 800.0,

    -- Fréquence de recalcul de la position, en ms. 1000 suffit :
    -- le client interpole entre deux synchronisations.
    tickMs = 1000,
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉGÂTS
--
--  ⚠️  À PROPOS DU RYTHME
--
--  La santé va de 0 à 200 dans GTA. À 0,25 point toutes les 30
--  secondes, un joueur perd 0,5 point par minute : il lui faudrait
--  plus de SIX HEURES pour mourir depuis la pleine santé.
--
--  Conséquence : le masque simple, qui protège 15 minutes, évite
--  7,5 points de dégâts. Personne ne le crafterait.
--
--  D'où l'option `escalate` ci-dessous. Elle laisse ton rythme au
--  début, puis l'accélère avec la durée d'exposition. Un joueur qui
--  traverse la zone s'en sort ; celui qui y campe une heure meurt.
--  Désactivée par défaut : teste d'abord ta version.
-- ═══════════════════════════════════════════════════════════════════
Config.Damage = {
    amount     = 0.25,   -- points de santé retirés par intervalle
    intervalMs = 30000,  -- 30 secondes

    -- Dégâts progressifs
    escalate = {
        enabled = false,

        -- Après ce délai d'exposition continue, les dégâts sont
        -- multipliés par `factor`. Le calcul est linéaire :
        -- à 2× rampMinutes, le multiplicateur vaut 2× factor.
        rampMinutes = 10,
        factor      = 3.0,

        -- Plafond, pour éviter la mort instantanée après une heure
        maxMultiplier = 20.0,
    },

    -- La santé ne descend jamais sous ce seuil par irradiation :
    -- le joueur agonise mais ne meurt pas du seul rayonnement.
    -- Mets 0 pour autoriser la mort par radiation.
    floor = 0,
}


-- ═══════════════════════════════════════════════════════════════════
--  LES MASQUES
--
--  Un masque s'ACTIVE en l'utilisant depuis l'inventaire. Il consomme
--  alors une charge et protège pendant sa durée.
--
--  Le décompte ne tourne QUE dans la zone : un masque activé par
--  erreur en pleine campagne ne se gaspille pas.
--
--  Tous les masques ont 5 charges. Un masque simple offre donc
--  5 × 15 min = 1 h 15 de protection cumulée, un double cartouche
--  5 × 60 min = 5 heures.
-- ═══════════════════════════════════════════════════════════════════
Config.Masks = {
    masque_simple = {
        label    = 'Masque simple',
        minutes  = 15,
    },
    masque_chimique = {
        label    = 'Masque chimique',
        minutes  = 30,
    },
    masque_cartouche = {
        label    = 'Masque à cartouche',
        minutes  = 45,
    },
    masque_double_cartouche = {
        label    = 'Masque à double cartouche',
        minutes  = 60,
    },
}

Config.MaskCharges = 5


-- ═══════════════════════════════════════════════════════════════════
--  AVERTISSEMENTS
--
--  Les signaux passent par rz_signal_urgences, donc uniquement aux
--  porteurs de pager. Sans pager, le joueur découvre la zone en la
--  traversant — ce qui est cohérent : le pager sert à savoir avant.
-- ═══════════════════════════════════════════════════════════════════
Config.Warnings = {
    enabled = true,

    -- Distance à laquelle on prévient de l'approche du nuage
    approachDistance = 400.0,

    -- Délai minimum entre deux avertissements, en secondes
    cooldown = 120,

    -- Alerte quand la protection du masque tombe sous ce seuil,
    -- en secondes restantes
    maskLowSeconds = 120,
}


-- ═══════════════════════════════════════════════════════════════════
--  RENDU VISUEL
-- ═══════════════════════════════════════════════════════════════════
Config.Visual = {
    -- Modificateur de cycle jour/nuit. REDMIST rougit la scène.
    timecycle         = 'REDMIST',
    timecycleStrength = 0.85,

    -- Assombrissement par-dessus, pour que la zone reste sombre en
    -- plein jour. 0 = rien, 1 = noir complet.
    darkness = 0.45,

    -- Voile rouge dessiné en surimpression (0 à 1)
    redVeil = 0.35,

    -- La bordure du nuage est plus légère : l'effet monte
    -- progressivement sur cette distance, en unités.
    fadeDistance = 120.0,

    -- Grain de compteur Geiger sur l'image
    grain = true,

    -- Blip sur la carte
    blip = {
        enabled = true,
        colour  = 1,     -- rouge
        alpha   = 90,
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.radiation'
Config.AceSuper = 'rz_radiation.admin'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.AceSuper)
        or IsPlayerAceAllowed(source, Config.Ace)
end

--[[
    server.cfg :
        add_ace group.admin rz_radiation.admin allow
]]
