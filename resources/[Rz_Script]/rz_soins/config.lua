Config = {}

Config.Debug = false

-- Vie maximale d'un joueur. rz_mort raisonne aussi sur 200.
Config.MaxHealth = 200


-- ═══════════════════════════════════════════════════════════════════
--  SOINS
--
--  Un soin ne fait qu'une chose : rendre des points de vie. Pas de
--  bonus, pas de vitesse, rien d'autre — les bonus, c'est le rôle
--  des virus, et c'est ce qui les rend tentants.
--
--      pv        points de vie rendus (sur 200)
--      duration  secondes de barre de progression
--      anim      clé de Config.Anims
--      others    peut être utilisé sur un autre joueur (via ox_target)
--      immobile  le joueur ne peut pas bouger pendant le soin
-- ═══════════════════════════════════════════════════════════════════
Config.Soins = {
    -- pansements : égratignures
    pansement_bob    = { pv = 10,  duration = 3,  anim = 'bandage' },
    pansement_dora   = { pv = 10,  duration = 3,  anim = 'bandage' },
    pansement_hello  = { pv = 10,  duration = 3,  anim = 'bandage' },
    pansement_flash  = { pv = 10,  duration = 3,  anim = 'bandage' },

    -- bandages
    bandage          = { pv = 25,  duration = 5,  anim = 'bandage', others = true },
    bandage_survie   = { pv = 20,  duration = 5,  anim = 'bandage', others = true },

    -- kits
    trousse_premiers_soins = { pv = 60,  duration = 8,  anim = 'kit', others = true },
    kit_medical            = { pv = 100, duration = 10, anim = 'kit', others = true },
    kit_medical_avance     = { pv = 150, duration = 12, anim = 'kit', others = true },

    -- perfusions : longues, immobiles, mais très efficaces
    kit_perfusion_saline   = { pv = 80,  duration = 15, anim = 'perfusion', others = true, immobile = true },
    kit_perfusion_sanguine = { pv = 140, duration = 20, anim = 'perfusion', others = true, immobile = true },

    -- injections et médicaments
    serum_salin        = { pv = 30, duration = 6, anim = 'injection', others = true },
    serum_salin_survie = { pv = 15, duration = 6, anim = 'injection', others = true },
    seringue_morphine  = { pv = 40, duration = 4, anim = 'injection', others = true },
    heparine           = { pv = 30, duration = 4, anim = 'injection', others = true },
    antidouleur        = { pv = 15, duration = 3, anim = 'pilule' },
    xanax              = { pv = 10, duration = 3, anim = 'pilule' },
    sirop_medicinal    = { pv = 20, duration = 4, anim = 'boire' },

    -- suture
    aiguille_suture    = { pv = 35, duration = 8, anim = 'suture', others = true },

    -- orthopédie
    attelle_survie     = { pv = 25, duration = 8,  anim = 'attelle', others = true },
    attelle_bras       = { pv = 35, duration = 8,  anim = 'attelle', others = true },
    attelle_jambe      = { pv = 45, duration = 10, anim = 'attelle', others = true },
    attelle_doigts     = { pv = 15, duration = 5,  anim = 'attelle', others = true },
    attelle_poignet    = { pv = 25, duration = 6,  anim = 'attelle', others = true },
    attelle_pression   = { pv = 50, duration = 12, anim = 'attelle', others = true },
    collier_cervical   = { pv = 30, duration = 10, anim = 'attelle', others = true },
    genouillere        = { pv = 25, duration = 6,  anim = 'attelle', others = true },
    cheviliere         = { pv = 20, duration = 6,  anim = 'attelle', others = true },
    couverture_survie  = { pv = 20, duration = 10, anim = 'kit',     others = true },

    -- ajouts (images burncream, icepack, suturekit, tweezers)
    creme_brulure      = { pv = 20, duration = 5,  anim = 'bandage', others = true },
    poche_glace        = { pv = 15, duration = 4,  anim = 'bandage', others = true },
    kit_suture         = { pv = 50, duration = 10, anim = 'suture',  others = true },
    pince_epiler       = { pv = 20, duration = 6,  anim = 'suture',  others = true },
}

-- Objets qui se déballent en d'autres objets à l'utilisation.
Config.Deballage = {
    boite_bandages = { item = 'bandage', count = 10 },
}

-- Outils réutilisables : ils s'usent (durabilité) au lieu de disparaître.
Config.Tools = {
    -- Obligatoire pour injecter un virus ou un antivirus.
    pistolet_injecteur = { wearPerUse = 5 },       -- 20 injections

    -- Gros soin sur UN AUTRE joueur uniquement. Ne relève pas un
    -- joueur à terre : cette règle appartient à rz_mort (seul
    -- l'épipen relève).
    defibrillateur = { pv = 100, duration = 15, wearPerUse = 10 },   -- 10 usages
    defibrillateur_portable = { pv = 80, duration = 12, wearPerUse = 20 },   -- 5 usages
}


-- ═══════════════════════════════════════════════════════════════════
--  MÉDICAMENTS (petites pilules, drogues)
--
--  Pas de soin : un bonus temporaire, puis retour à la normale avec
--  la « descente » : moins de faim et de soif. Pas d'antivirus à
--  prendre, l'effet s'éteint tout seul. Les bonus se cumulent ; on
--  refuse seulement le même médicament deux fois en même temps.
--
--      duration   secondes d'effet
--      armour     armure ajoutée (retirée à la fin)
--      maxHealth  vie maximale ajoutée au-dessus de 200 (retirée à la fin)
--      stamina    endurance illimitée
--      sprint     multiplicateur de course (max 1.49)
--      defense    multiplicateur de dégâts subis (0.85 = -15 %)
-- ═══════════════════════════════════════════════════════════════════
Config.Medicaments = {
    percocet_5  = { duration = 180, anim = 'pilule',    stamina = true },
    percocet_10 = { duration = 240, anim = 'pilule',    stamina = true, sprint = 1.10 },
    percocet_30 = { duration = 300, anim = 'pilule',    stamina = true, sprint = 1.15 },
    vicodin_5   = { duration = 180, anim = 'pilule',    maxHealth = 25 },
    vicodin_10  = { duration = 240, anim = 'pilule',    maxHealth = 50 },
    morphine_15 = { duration = 180, anim = 'pilule',    armour = 25, maxHealth = 25 },
    morphine_30 = { duration = 300, anim = 'pilule',    armour = 50, maxHealth = 50 },
    sedatif     = { duration = 240, anim = 'injection', armour = 50, defense = 0.85 },
}

-- La descente, en points de faim et de soif (sur 100).
Config.Comedown = { hunger = 35, thirst = 35 }


-- ═══════════════════════════════════════════════════════════════════
--  DROGUES (produits finaux, ceux qui se vendent)
--
--  Plus fort et plus long qu'un médicament. À la fin de l'effet, le
--  joueur reste « saoul » (démarche, caméra) jusqu'à ce qu'il prenne
--  UNE saline par drogue consommée. Deux drogues = deux salines.
--  Les bonus se cumulent (entre drogues, avec les médicaments, avec
--  un virus en phase 1) ; on refuse seulement le même produit deux
--  fois en même temps.
--
--      tool      objet requis (et usé) pour consommer
--      regenPv / regenEvery   régénération continue
-- ═══════════════════════════════════════════════════════════════════
Config.Drogues = {
    joint                = { duration = 360, anim = 'fumer',     defense = 0.90, regenPv = 1, regenEvery = 5 },
    cookie_cannabis      = { duration = 480, anim = 'manger',    defense = 0.90, regenPv = 2, regenEvery = 5 },
    sachet_weed          = { duration = 360, anim = 'fumer',     defense = 0.90, regenPv = 1, regenEvery = 5 },
    sachet_cocaine       = { duration = 480, anim = 'sniffer',   stamina = true, sprint = 1.20, meleeDamage = 1.25 },
    sachet_crack         = { duration = 360, anim = 'fumer',     stamina = true, sprint = 1.25, meleeDamage = 1.5, tool = 'pipe_crack' },
    seringue_crack       = { duration = 420, anim = 'injection', stamina = true, sprint = 1.25, meleeDamage = 1.5, armour = 25 },
    sachet_heroine       = { duration = 480, anim = 'sniffer',   defense = 0.70, maxHealth = 50 },
    seringue_heroine     = { duration = 600, anim = 'injection', defense = 0.65, maxHealth = 75, armour = 25 },
    sachet_fentanyl      = { duration = 480, anim = 'sniffer',   defense = 0.60, maxHealth = 25 },
    sachet_ketamine      = { duration = 480, anim = 'sniffer',   defense = 0.75, armour = 50 },
    seringue_meth        = { duration = 600, anim = 'injection', stamina = true, sprint = 1.25, meleeDamage = 1.5, armour = 25 },
    ecstasy              = { duration = 480, anim = 'pilule',    stamina = true, sprint = 1.15, regenPv = 2, regenEvery = 5 },
    buvard_lsd           = { duration = 480, anim = 'pilule',    regenPv = 3, regenEvery = 5, defense = 0.85 },
    champignons          = { duration = 360, anim = 'manger',    regenPv = 2, regenEvery = 5, maxHealth = 25 },
    chocolat_champignons = { duration = 480, anim = 'manger',    regenPv = 3, regenEvery = 5, maxHealth = 50 },
    opium                = { duration = 600, anim = 'fumer',     defense = 0.70, regenPv = 2, regenEvery = 5, tool = 'pipe' },
}

-- Usure des outils de consommation (pipe, pipe à crack), en %
Config.DrugToolWear = 10

-- Ce qui compte comme « une saline » pour lever une gueule de bois.
-- Utilisé pour ça, l'objet ne soigne pas en plus.
Config.SalineItems = {
    serum_salin          = true,
    serum_salin_survie   = true,
    kit_perfusion_saline = true,
}

-- Gueule de bois : démarche et caméra d'ivresse
Config.Hangover = {
    clipset = 'move_m@drunk@verydrunk',
    shake   = 'DRUNK_SHAKE',
    shakeAmplitude = 0.8,
    every   = 6,          -- secondes entre deux secousses
}

-- Plafonds quand les bonus se cumulent
Config.Caps = {
    sprint    = 1.49,     -- limite du jeu
    defense   = 0.40,     -- au mieux -60 % de dégâts subis
    maxHealth = 100,      -- au plus +100 (vie max 300)
}

Config.Injector = 'pistolet_injecteur'

-- Distance maximale pour soigner quelqu'un
Config.TargetDistance = 2.5


-- ═══════════════════════════════════════════════════════════════════
--  VIRUS
--
--  Cycle : injection → PHASE 1, le bonus, pendant safeMinutes →
--  PHASE 2, le virus ronge damagePerMinute points de vie par minute,
--  jusqu'à la mort ou l'antivirus. L'antivirus guérit à n'importe
--  quelle phase, et coupe le bonus.
--
--  Une seule souche à la fois : un joueur déjà infecté ne peut pas
--  s'injecter un second virus.
-- ═══════════════════════════════════════════════════════════════════
Config.Virus = {
    t = {
        item            = 'virus_t_injection',
        label           = 'Virus T',
        safeMinutes     = 20,
        damagePerMinute = 4,
        duration        = 6,            -- secondes d'injection
        symptom         = 'toux',
        -- En phase 2 seulement : les joueurs proches peuvent attraper
        -- le T, SANS bonus (ils passent directement en phase 2).
        contagious = { radius = 3.0, chance = 10, interval = 10 },   -- 10 % toutes les 10 s
    },
    n = {
        item            = 'virus_n_injection',
        label           = 'Virus Némésis',
        safeMinutes     = 15,
        damagePerMinute = 6,
        duration        = 6,
        symptom         = 'tremblements',
    },
    v = {
        item            = 'virus_v_injection',
        label           = 'Virus Veronica',
        safeMinutes     = 15,
        damagePerMinute = 5,
        duration        = 6,
        symptom         = 'vision',
    },
}

-- Bonus de phase 1, par souche.
Config.Bonus = {
    t = { sprint = 1.15, stamina = true },              -- course +15 %, endurance illimitée
    n = { defense = 0.7, meleeDamage = 1.5 },           -- dégâts subis -30 %, corps-à-corps +50 %
    v = { regenPv = 2, regenEvery = 5 },                -- +2 PV toutes les 5 s
}

-- Antivirus : quelles souches, combien de secondes d'injection.
Config.Antivirus = {
    antivirus_t_injection = { cures = { 't', 'n', 'v' }, duration = 8 },
}

-- Avertissement avant la fin de la phase 1 (minutes)
Config.WarnMinutes = 5

-- Effets visibles en phase 2 : secousse de caméra + flou, toutes les
-- `every` secondes.
Config.Symptoms = {
    every   = 25,
    shake   = 'DRUNK_SHAKE',
    shakeAmplitude = 0.35,
    postfx  = 'DrugsDrivingIn',
    postfxMs = 4000,
}

-- Cadence de la boucle serveur (secondes). Les dégâts de phase 2
-- sont appliqués à chaque passage : damagePerMinute × Tick / 60.
Config.Tick = 60


-- ═══════════════════════════════════════════════════════════════════
--  ANIMATIONS
--  Toutes remplaçables. flag 49 = haut du corps, en boucle.
-- ═══════════════════════════════════════════════════════════════════
Config.Anims = {
    bandage   = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
    kit       = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
    perfusion = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
    attelle   = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
    suture    = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
    injection = { dict = 'mp_suicide',          clip = 'pill',        flag = 49 },
    pilule    = { dict = 'mp_suicide',          clip = 'pill',        flag = 49 },
    boire     = { dict = 'mp_player_intdrink',  clip = 'loop_bottle', flag = 49 },
    manger    = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
    fumer     = { dict = 'amb@world_human_smoking@male@male_a@enter', clip = 'enter', flag = 49 },
    sniffer   = { dict = 'switch@trevor@trev_smoking_meth', clip = 'trev_smoking_meth_loop', flag = 49 },
}

-- Scénario joué quand on soigne quelqu'un d'autre
Config.TargetScenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD'

-- Commandes admin (/virus, /guerir) : groupe ace autorisé
Config.AdminGroup = 'group.admin'
