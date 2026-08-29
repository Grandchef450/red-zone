Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  MODÈLES D'ÉPAVE FOUILLABLES
--
--  ⚠️  LISTE DE DÉPART, À COMPLÉTER AVEC TES PROPRES MODÈLES.
--
--  Ta map Apocalypse_Mapping est un asset pack chiffré : impossible
--  de savoir quels modèles d'épave elle place. Ils sont peut-être
--  personnalisés, auquel cas aucun nom ci-dessous ne correspondra.
--
--  POUR TROUVER TES MODÈLES :
--  vise une épave et tape /epavemodel. La commande affiche le nom du
--  modèle et le copie dans le presse-papier. Ajoute-le ici, puis
--  restart rz_epaves. Aucun redémarrage serveur nécessaire.
-- ═══════════════════════════════════════════════════════════════════
Config.WreckModels = {
    -- Épaves et carcasses de base GTA V
    'prop_rub_carwreck_1',
    'prop_rub_carwreck_2',
    'prop_rub_carwreck_3',
    'prop_rub_carwreck_4',
    'prop_rub_carwreck_5',
    'prop_rub_carwreck_6',
    'prop_rub_carwreck_7',
    'prop_rub_carwreck_8',
    'prop_rub_carwreck_9',
    'prop_rub_carwreck_10',
    'prop_rub_carwreck_11',
    'prop_rub_carwreck_12',
    'prop_rub_carwreck_13',
    'prop_rub_carwreck_14',
    'prop_rub_carwreck_15',
    'prop_rub_carwreck_16',

    -- Carcasses de casse
    'prop_car_ldeluxe',
    'prop_car_ldeluxe_2',
    'prop_car_ldeluxe_3',
    'prop_car_ldeluxe_4',

    -- Ajoute ici les modèles relevés avec /epavemodel
}


-- ═══════════════════════════════════════════════════════════════════
--  FOUILLE
-- ═══════════════════════════════════════════════════════════════════
Config.Search = {
    -- Distance maximale pour déclencher la fouille
    distance = 2.5,

    -- Durée de la barre de progression, en ms
    duration = 6000,

    label = 'Fouiller l\'épave',
    icon  = 'fas fa-magnifying-glass',

    -- Capacité du contenant temporaire
    slots     = 8,
    maxWeight = 20000,

    -- Animation de fouille
    animDict = 'amb@prop_human_bum_bin@base',
    animName = 'base',
}


-- ═══════════════════════════════════════════════════════════════════
--  RESPAWN
--
--  Chaque épave est identifiée par sa POSITION arrondie, pas par son
--  entité : les props de map se rechargent constamment et changent
--  d'identifiant réseau. La position, elle, ne bouge jamais.
--
--  Doit rester aligné sur inventory:cleartime et
--  rz_core Config.LootRespawn.minutes.
-- ═══════════════════════════════════════════════════════════════════
Config.Respawn = {
    minutes = 45,

    -- Précision de l'arrondi de position, en mètres. 1.0 suffit :
    -- deux épaves distinctes ne sont jamais à moins d'un mètre.
    gridSize = 1.0,
}


-- ═══════════════════════════════════════════════════════════════════
--  TABLE DE LOOT
--
--  Format : { item, minimum, maximum, chance en % }
--
--  À chaque fouille, on tire `draws` fois dans la table, avec un jet
--  séparé par item. Une chance de 70 ne signifie donc pas 70 % de
--  trouver l'item : il faut d'abord qu'il soit tiré.
--
--  Volontairement plus généreuse que la table des bennes : une épave
--  demande de se déplacer hors ville, souvent en zone infestée. Le
--  risque doit payer.
-- ═══════════════════════════════════════════════════════════════════
Config.Loot = {
    draws = { min = 1, max = 4 },

    items = {
        { 'ferraille',          1, 4, 75 },
        { 'plastique',          1, 3, 65 },
        { 'caoutchouc',         1, 3, 60 },
        { 'fil_fer',            1, 3, 55 },
        { 'ressort',            1, 3, 50 },
        { 'tissu_use',          1, 2, 50 },
        { 'verre',              1, 2, 45 },
        { 'elastique',          1, 2, 40 },
        { 'ruban_adhesif',      1, 1, 35 },
        { 'tuyau_caoutchouc',   1, 1, 30 },
        { 'tuyau_plastique',    1, 1, 30 },
        { 'tube_cuivre',        1, 2, 28 },
        { 'batterie_usee',      1, 1, 25 },
        { 'bouteille_eau_sale', 1, 1, 20 },
        { 'colle_construction', 1, 1, 15 },
        { 'cle_molette',        1, 1, 12 },
        { 'cle_cric',           1, 1, 10 },
        { 'capsule',            5, 25, 30 },
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.staff'   -- pour /epavemodel et /epaveinfo
