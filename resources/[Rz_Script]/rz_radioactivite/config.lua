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
--  LE CYCLE
--
--  La zone n'est plus permanente. Elle alterne entre deux états :
--
--    DORMANT   aucune contamination sur la carte. Les joueurs
--              respirent, farment, s'installent.
--    ACTIF     un nuage parcourt un itinéraire, puis se dissipe.
--
--  Ce rythme vaut mieux qu'une menace continue : une zone toujours
--  présente devient un décor qu'on contourne machinalement. Une
--  zone qui revient après une accalmie se remarque.
--
--  Entre les deux, une ANNONCE sur les pagers laisse le temps de
--  se préparer. C'est ce qui donne sa valeur au pager : sans lui,
--  on découvre le nuage en le traversant.
-- ═══════════════════════════════════════════════════════════════════
Config.Cycle = {
    enabled = true,

    -- Durée de l'accalmie, en minutes. Tirée au hasard dans cette
    -- fourchette à chaque fois.
    dormantMin = 45,
    dormantMax = 120,

    -- Délai entre l'annonce et l'apparition réelle du nuage.
    -- Assez pour évacuer, trop court pour organiser une expédition.
    warningSeconds = 180,

    -- Durée de vie maximale d'un nuage, en minutes. Il se dissipe
    -- même si son itinéraire n'est pas terminé — sinon un trajet
    -- long immobiliserait le cycle pendant des heures.
    maxActiveMinutes = 90,

    -- La zone démarre-t-elle en accalmie au lancement du serveur ?
    -- true évite qu'un redémarrage fasse apparaître un nuage sur
    -- des joueurs qui viennent de se reconnecter.
    startDormant = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  LES ITINÉRAIRES
--
--  Chaque scénario décrit un trajet à travers la carte. À la fin
--  d'une accalmie, un scénario est tiré au sort selon son poids.
--
--  Un nuage qui suit un chemin connu est bien plus intéressant
--  qu'un déplacement aléatoire : les joueurs finissent par
--  reconnaître les couloirs de passage, et éviter d'y bâtir.
--
--  ─── COMMENT AJOUTER UN ITINÉRAIRE ─────────────────────────────
--  Place-toi aux endroits voulus, note tes coordonnées avec
--  dolu_tool, et ajoute une entrée ici. Le nuage relie les points
--  dans l'ordre, en ligne droite.
--
--  `weight` est la probabilité relative : un scénario à 3 sort
--  trois fois plus souvent qu'un scénario à 1.
-- ═══════════════════════════════════════════════════════════════════
Config.Scenarios = {
    {
        key    = 'vent_du_nord',
        label  = 'Vent du nord',
        note   = 'Descend de Paleto vers Los Santos par l\'intérieur',
        weight = 3,
        radius = 500.0,
        speed  = 3.5,
        path = {
            vec2(-300.0,  6300.0),   -- Paleto Bay
            vec2(100.0,   5000.0),   -- forêts du nord
            vec2(800.0,   3800.0),   -- Grand Senora
            vec2(1200.0,  2200.0),   -- Sandy est
            vec2(600.0,   200.0),    -- Vinewood
            vec2(200.0,  -1200.0),   -- Los Santos centre
        },
    },
    {
        key    = 'derive_cotiere',
        label  = 'Dérive côtière',
        note   = 'Longe la côte ouest, du sud vers le nord',
        weight = 2,
        radius = 450.0,
        speed  = 4.0,
        path = {
            vec2(-1600.0, -1200.0),  -- Vespucci
            vec2(-2000.0,  100.0),   -- Del Perro
            vec2(-2600.0,  1800.0),  -- Pacific Bluffs
            vec2(-2200.0,  3200.0),  -- côte de Zancudo
            vec2(-800.0,   4800.0),  -- Chumash nord
            vec2(-400.0,   6200.0),  -- Paleto
        },
    },
    {
        key    = 'boucle_du_desert',
        label  = 'Boucle du désert',
        note   = 'Tourne autour de Sandy Shores et Grapeseed',
        weight = 3,
        radius = 600.0,
        speed  = 3.0,
        loop   = true,           -- revient au premier point
        path = {
            vec2(1400.0,  3200.0),
            vec2(2400.0,  3600.0),
            vec2(2200.0,  4600.0),
            vec2(1400.0,  4900.0),
            vec2(800.0,   4200.0),
        },
    },
    {
        key    = 'couloir_militaire',
        label  = 'Couloir militaire',
        note   = 'Part de Fort Zancudo vers la ville. Nuage dense.',
        weight = 1,
        radius = 800.0,          -- le plus large des quatre
        speed  = 2.5,            -- et le plus lent : difficile à fuir
        path = {
            vec2(-2100.0, 3200.0),   -- Fort Zancudo
            vec2(-1400.0, 2000.0),
            vec2(-800.0,  600.0),
            vec2(-200.0, -800.0),    -- Los Santos
        },
    },
    {
        key    = 'traversee_est',
        label  = 'Traversée de l\'est',
        note   = 'Du mont Chiliad aux docks, en diagonale',
        weight = 2,
        radius = 550.0,
        speed  = 4.5,            -- le plus rapide : il faut un véhicule
        path = {
            vec2(500.0,   5600.0),   -- mont Chiliad
            vec2(1800.0,  3900.0),
            vec2(2600.0,  1800.0),
            vec2(1600.0,  100.0),
            vec2(1000.0, -1800.0),   -- docks est
        },
    },
}




-- ═══════════════════════════════════════════════════════════════════
--  ZONE MANUELLE
--
--  Créée par un admin depuis le menu, centrée sur SA position.
--  Utile pour un événement scénarisé, un test, ou une contamination
--  ponctuelle qui ne suit aucun itinéraire.
--
--  Le rayon est PLAFONNÉ au plus large des scénarios automatiques.
--  Sans cette limite, un curseur poussé au maximum couvrirait la
--  carte entière et rendrait le serveur injouable — avec un nuage
--  que personne ne pourrait fuir.
-- ═══════════════════════════════════════════════════════════════════
Config.Manual = {
    -- Durées proposées, en minutes
    durations = { 5, 10, 15, 30, 45, 60, 90, 120 },
    defaultDuration = 30,

    -- Vitesse par défaut. 0 = nuage immobile, ce qui convient à un
    -- événement localisé.
    defaultSpeed = 0.0,

    -- Annoncer sur les pagers, comme un nuage automatique ?
    -- Décochable : un admin peut vouloir une contamination discrète.
    announceByDefault = true,

    -- Plancher : en dessous, la zone est trop petite pour se voir
    minRadius = 50.0,
}


---Rayon le plus large parmi les scénarios automatiques.
---C'est le plafond de la création manuelle.
---@return number
function Config.MaxScenarioRadius()
    local max = Config.Zone.radius

    for _, sc in ipairs(Config.Scenarios) do
        local r = sc.radius or Config.Zone.radius
        if r > max then max = r end
    end

    return max
end


-- ═══════════════════════════════════════════════════════════════════
--  MESSAGES DU CYCLE
--
--  %s est remplacé par le nom de l'itinéraire. Une variante est
--  tirée au hasard : au bout de vingt cycles, un texte unique
--  devient du bruit que plus personne ne lit.
-- ═══════════════════════════════════════════════════════════════════
Config.CycleMessages = {

    -- Fin d'accalmie, avant l'apparition du nuage
    incoming = {
        'ALERTE : NUAGE CONTAMINE EN FORMATION. TRAJECTOIRE %s.',
        'RELEVES ANORMAUX. UNE ZONE CONTAMINEE SE LEVE : %s.',
        'LE COMPTEUR S EMBALLE. CONTAMINATION ATTENDUE SUR %s.',
        'AVIS DE CONTAMINATION. AXE DE PASSAGE : %s.',
    },

    -- Le nuage vient d'apparaître
    started = {
        'LE NUAGE EST LA. NE RESTE PAS DEHORS.',
        'CONTAMINATION ACTIVE. LE COMPTEUR HURLE.',
        'ZONE CONTAMINEE CONFIRMEE. DEGAGE DE SA ROUTE.',
    },

    -- Contamination créée par le staff, sans itinéraire
    manual = {
        'CONTAMINATION LOCALISEE DETECTEE. EVITE LE SECTEUR.',
        'RELEVES CRITIQUES SUR UNE ZONE FIXE. NE T APPROCHE PAS.',
        'FOYER DE CONTAMINATION IDENTIFIE. PERIMETRE A EVITER.',
    },

    -- Le nuage s'est dissipé
    ended = {
        'LE NUAGE S EST DISSIPE. L AIR REDEVIENT RESPIRABLE.',
        'PLUS AUCUN RELEVE. LA CONTAMINATION EST PASSEE.',
        'RETOUR A LA NORMALE. PROFITE, CA NE DURERA PAS.',
    },
}


---Tire un message au hasard dans une catégorie du cycle.
function Config.PickCycleMessage(category, ...)
    local list = Config.CycleMessages[category]
    if not list or #list == 0 then return '' end

    local template = list[math.random(1, #list)]
    local args = { ... }

    if #args > 0 then
        return template:format(table.unpack(args))
    end

    return template
end


---Tire un scénario au hasard, pondéré par son poids.
---@return table|nil
function Config.PickScenario()
    local total = 0
    for _, sc in ipairs(Config.Scenarios) do
        total = total + (sc.weight or 1)
    end

    if total <= 0 then return Config.Scenarios[1] end

    local roll = math.random() * total
    local acc = 0

    for _, sc in ipairs(Config.Scenarios) do
        acc = acc + (sc.weight or 1)
        if roll <= acc then return sc end
    end

    return Config.Scenarios[#Config.Scenarios]
end


---Scénario par sa clé.
function Config.GetScenario(key)
    for _, sc in ipairs(Config.Scenarios) do
        if sc.key == key then return sc end
    end
    return nil
end


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
