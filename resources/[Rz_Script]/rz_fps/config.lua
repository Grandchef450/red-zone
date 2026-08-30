Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  POURQUOI CE SCRIPT N'UTILISE AUCUN TIMECYCLE
--
--  L'ancien menu-fps appliquait SetTimecycleModifier('tunnel') pour
--  son mode « performance ». Ça ASSOMBRIT l'écran sans changer une
--  seule chose au coût de rendu : le joueur voit une différence,
--  croit que ça marche, et n'y gagne pas une image par seconde.
--
--  Pire, ça écrasait le voile rouge de rz_radioactivite. Un joueur
--  qui changeait de profil en zone contaminée effaçait l'effet.
--
--  Chaque réglage ci-dessous agit sur ce que la carte graphique
--  doit RÉELLEMENT calculer.
-- ═══════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════
--  LES TROIS PROFILS
--
--  Nommés par TYPE DE MACHINE, pas par niveau de qualité. Un joueur
--  qui ne connaît rien aux réglages sait reconnaître son ordinateur ;
--  il ne sait pas ce que « qualité moyenne » implique concrètement.
--
--  ─── CE QUE CHAQUE RÉGLAGE COÛTE ───────────────────────────────
--
--  lodScale      LE levier principal. Distance à laquelle les objets
--                passent en haute définition. Diviser par deux, c'est
--                deux fois moins de géométrie à l'écran. Aucun autre
--                réglage n'a autant d'effet.
--
--  pedLod        idem pour les personnages.
--
--  shadows       second poste de dépense. Les ombres en cascade sont
--                recalculées à chaque frame, pour chaque source de
--                lumière.
--
--  shadowBounds  portée des ombres. 0.3 les limite au très proche.
--  farShadows    ombres des objets lointains.
--
--  reduceBudget  réduit la mémoire allouée aux modèles de personnages
--                et de véhicules. Décisif sur une machine à faible
--                mémoire vidéo : c'est ce qui évite les textures qui
--                mettent dix secondes à apparaître.
--
--  decals        impacts de balles, sang, traces de pneus.
--  tracks        empreintes de pas et traînées de véhicules.
--  coronas       halos lumineux des lampadaires vus de loin.
--  lightCutoff   distance au-delà de laquelle les lumières ne sont
--                plus calculées.
-- ═══════════════════════════════════════════════════════════════════
Config.Profiles = {
    {
        key   = 'faible',
        label = 'Ordinateur modeste',
        note  = 'Portable, carte graphique intégrée, machine de plus de 6 ans',
        hint  = 'Si tu joues sous 30 FPS, c\'est ce profil qu\'il te faut.',

        lodScale     = 0.30,
        pedLod       = 0.30,
        shadows      = false,
        shadowBounds = 0.3,
        farShadows   = false,
        reduceBudget = true,
        decals       = false,
        tracks       = false,
        coronas      = false,
        lightCutoff  = 0.3,
    },
    {
        key   = 'moyen',
        label = 'Ordinateur correct',
        note  = 'Carte graphique dediee d\'entree de gamme, machine de 3 a 6 ans',
        hint  = 'Le bon compromis si tu tournes entre 30 et 60 FPS.',

        lodScale     = 0.60,
        pedLod       = 0.60,
        shadows      = true,
        shadowBounds = 0.6,
        farShadows   = false,
        reduceBudget = true,
        decals       = true,
        tracks       = false,
        coronas      = true,
        lightCutoff  = 0.7,
    },
    {
        key   = 'puissant',
        label = 'Ordinateur performant',
        note  = 'Carte graphique recente, machine de moins de 3 ans',
        hint  = 'Rien n\'est bride. A choisir si tu depasses 60 FPS sans effort.',

        lodScale     = 1.00,
        pedLod       = 1.00,
        shadows      = true,
        shadowBounds = 1.0,
        farShadows   = true,
        reduceBudget = false,
        decals       = true,
        tracks       = true,
        coronas      = true,
        lightCutoff  = 1.0,
    },
}

Config.DefaultProfile = 'moyen'


-- ═══════════════════════════════════════════════════════════════════
--  DETECTION AUTOMATIQUE
--
--  Pour le joueur qui ne sait pas ou se situer. On mesure ses FPS
--  reels pendant quelques secondes, puis on lui recommande le profil
--  correspondant.
--
--  La mesure se fait sur le profil « performant » : on veut savoir ce
--  que la machine encaisse SANS aide. Mesurer sur un profil deja
--  allege donnerait un resultat flatteur et un mauvais conseil.
-- ═══════════════════════════════════════════════════════════════════
Config.Auto = {
    -- Duree de la mesure, en secondes. Sous 8 secondes, le resultat
    -- depend trop de ce que le joueur regarde a cet instant.
    duration = 10,

    -- Secondes ignorees au debut : le temps que le profil de test
    -- s'applique et que le decor se recharge.
    warmup = 3,

    lowThreshold  = 32,   -- en dessous → ordinateur modeste
    highThreshold = 62,   -- au-dessus  → ordinateur performant
}


-- ═══════════════════════════════════════════════════════════════════
--  COMPTEUR DE FPS
-- ═══════════════════════════════════════════════════════════════════
Config.Counter = {
    enabledByDefault = false,

    -- 'haut-gauche', 'haut-droite', 'bas-gauche', 'bas-droite'
    position = 'haut-droite',

    -- Rafraichissement en ms. Sous 250, le chiffre saute trop pour
    -- etre lisible.
    refresh = 500,

    good    = 50,   -- vert au-dessus
    warning = 30,   -- orange entre les deux, rouge en dessous
}


-- ═══════════════════════════════════════════════════════════════════
--  OUVERTURE
-- ═══════════════════════════════════════════════════════════════════
Config.Command = 'fps'

-- Modifiable par le joueur dans les parametres FiveM, section
-- Keybinds. Jamais F8 : c'est la console du jeu.
Config.Key = 'F3'


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

function Config.GetProfile(key)
    for _, p in ipairs(Config.Profiles) do
        if p.key == key then return p end
    end
    return nil
end

---Profil recommande pour un nombre de FPS mesure.
function Config.RecommendFor(measured)
    if measured < Config.Auto.lowThreshold  then return 'faible' end
    if measured > Config.Auto.highThreshold then return 'puissant' end
    return 'moyen'
end
