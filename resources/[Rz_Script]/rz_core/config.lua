Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  DENSITÉ DU MONDE
--
--  0.0 = monde totalement mort. Aucun véhicule, aucun passant,
--  aucune scène de vie. C'est le réglage post-apocalyptique.
--
--  Ces valeurs vont de 0.0 à 1.0 et s'appliquent à chaque frame.
--  Si tu veux un jour quelques épaves qui roulent, 0.02 suffit.
-- ═══════════════════════════════════════════════════════════════════
Config.Density = {
    vehicles       = 0.0,   -- trafic : aucune voiture ne roule
    randomVehicles = 0.0,   -- véhicules aléatoires
    peds           = 0.0,   -- passants
    scenarioPeds   = 0.0,   -- PNJ en animation (bancs, téléphone, balayage)

    -- Voitures garées : 0.0, le décor d'épaves vient de la map
    -- Apocalypse_Mapping. Le loot passe par rz_epaves, qui rend
    -- fouillables les props d'épave déjà posés — bien plus cohérent
    -- que des berlines intactes apparues au milieu des ruines.
    parkedVehicles = 0.0,
}

-- Types de circulation à supprimer complètement.
-- Les trains et bateaux fantômes cassent l'immersion plus que tout.
Config.World = {
    noTrains        = true,
    noBoats         = true,
    noGarbageTrucks = true,
    noAmbientCops   = true,
    noDispatch      = true,   -- police, ambulances, pompiers, hélicos
    noWantedLevel   = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  RESPAWN DU LOOT DES VÉHICULES
--
--  Les bennes se régénèrent seules via le convar du server.cfg :
--      setr inventory:cleartime 45
--
--  Les coffres de véhicule, eux, ne suivent pas ce délai : ox_inventory
--  ne les libère que si le véhicule disparaît. Ce module force la
--  libération après le même délai.
--
--  Note : avec parkedVehicles à 0.0 il n'y a quasiment aucun véhicule
--  ambiant sur la carte. Ce module ne sert donc qu'aux véhicules des
--  joueurs. La vraie récupération passe par rz_epaves.
-- ═══════════════════════════════════════════════════════════════════
Config.LootRespawn = {
    enabled = true,
    minutes = 45,   -- doit rester aligné sur inventory:cleartime
}


-- ═══════════════════════════════════════════════════════════════════
--  SILENCE
--
--  Le silence n'est pas un seul interrupteur : GTA produit du son par
--  une dizaine de canaux indépendants. Chacun se coupe séparément.
-- ═══════════════════════════════════════════════════════════════════
Config.Audio = {
    -- Scène audio qui étouffe l'ambiance générale du monde
    ambientScene   = true,

    -- Radios : véhicules, radio mobile, contrôle par le joueur
    noRadio        = true,

    -- Musique de score dynamique (poursuites, braquages, tension)
    noScoreMusic   = true,

    -- Scanner de police et rapports radio
    noPoliceScanner = true,

    -- Émetteurs statiques : sono des boîtes de nuit, radios de
    -- magasin, musique des stands de tir. Ils continuent de jouer
    -- même quand tout le reste est coupé — c'est le canal que les
    -- gens oublient et qui trahit un serveur « silencieux ».
    noStaticEmitters = true,

    -- Ambiance naturelle : oiseaux, vent dans les arbres, vagues
    noAmbientZones = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  INTERFACE
--
--  Composants du HUD masqués. L'argent est masqué parce que
--  l'économie RedZone tourne aux capsules, pas aux dollars.
-- ═══════════════════════════════════════════════════════════════════
Config.HideHud = {
    [1]  = true,   -- WANTED_STARS
    [2]  = true,   -- WEAPON_ICON
    [3]  = true,   -- CASH
    [4]  = true,   -- MP_CASH
    [5]  = true,   -- MP_MESSAGE
    [6]  = true,   -- VEHICLE_NAME
    [7]  = true,   -- AREA_NAME
    [8]  = true,   -- VEHICLE_CLASS
    [9]  = true,   -- STREET_NAME
    [10] = false,  -- HELP_TEXT        ← garder : sert aux interactions
    [11] = false,  -- FLOATING_HELP_1
    [12] = false,  -- FLOATING_HELP_2
    [13] = true,   -- CASH_CHANGE
    [14] = false,  -- RETICLE          ← garder : viseur
    [15] = false,  -- SUBTITLE_TEXT
    [16] = true,   -- RADIO_STATIONS
    [17] = true,   -- SAVING_GAME
    [18] = true,   -- GAME_STREAM
    [19] = true,   -- WEAPON_WHEEL
    [20] = true,   -- WEAPON_WHEEL_STATS
    [21] = false,  -- HUD_COMPONENTS
    [22] = false,  -- HUD_WEAPONS
}


-- ═══════════════════════════════════════════════════════════════════
--  ACCROUPISSEMENT
--
--  Remplace le mode furtif de GTA, qui ralentit et fait du bruit,
--  par un vrai accroupissement.
-- ═══════════════════════════════════════════════════════════════════
Config.Crouch = {
    enabled = true,
    key     = 36,     -- 36 = Ctrl gauche (INPUT_DUCK)

    -- Jeux d'animation. Le second est la posture debout de retour.
    clipset = 'move_ped_crouched',
    strafe  = 'move_ped_crouched_strafing',
    standUp = 'MOVE_M@TOUGH_GUY@',
}


-- ═══════════════════════════════════════════════════════════════════
--  ÉMETTEURS STATIQUES À COUPER
--
--  Liste non exhaustive : ce sont les sources sonores fixes de la
--  carte. Ajoute-en si tu entends encore de la musique quelque part.
-- ═══════════════════════════════════════════════════════════════════
Config.StaticEmitters = {
    'LOS_SANTOS_VANILLA_UNICORN_01_STAGE',
    'LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM',
    'LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM',
    'LOS_SANTOS_VANILLA_UNICORN_STAGE_HIGH',
    'LOS_SANTOS_VANILLA_UNICORN_MAIN_ROOM_HIGH',
    'LOS_SANTOS_VANILLA_UNICORN_BACK_ROOM_HIGH',
    'SE_DLC_Biker_Biker_Club_01_Interior_Music',
    'SE_DLC_Biker_Biker_Club_02_Interior_Music',
    'SE_DLC_Biker_Biker_Club_03_Interior_Music',
    'SE_DLC_Biker_Biker_Club_04_Interior_Music',
    'SE_DLC_Biker_Biker_Club_05_Interior_Music',
    'SE_Music_Stripclub_01_Stage',
    'SE_Music_Stripclub_02_Main_Room',
    'SE_Music_Stripclub_03_Back_Room',
    'SE_Music_TattooParlour_01',
    'SE_Music_TattooParlour_02',
    'SE_Music_TattooParlour_03',
    'SE_Music_TattooParlour_04',
    'SE_Music_TattooParlour_05',
    'SE_Shop_Lo_Clothes_Music',
    'SE_Shop_Hi_Clothes_Music',
    'SE_Shop_Mid_Clothes_Music',
    'SE_Shop_Gun_Club_Music',
    'SE_Shop_247_Music',
    'SE_Shop_Rob_Liquor_Music',
    'SE_Shop_Barbers_Music',
    'SE_Shop_Carmod_Music',
    'SE_Shop_Ammunation_Music',
}


-- ═══════════════════════════════════════════════════════════════════
--  ZONES D'AMBIANCE À NEUTRALISER
--  Oiseaux, vagues, vent, faune. Le son « naturel » de la carte.
-- ═══════════════════════════════════════════════════════════════════
Config.AmbientZones = {
    'AZ_COUNTRYSIDE_BIRDS',
    'AZ_COUNTRYSIDE_INSECTS',
    'AZ_CITY_BIRDS',
    'AZ_BEACH_BIRDS',
    'AZ_PARK_BIRDS',
    'AZ_FOREST_BIRDS',
    'AZ_WATER_WAVES',
    'AZ_DISTANT_SIRENS',
    'AZ_AIRPORT_AMBIENCE',
    'AZ_ROLLERCOASTER_AMBIENCE',
    'AZ_CINEMA_AMBIENCE',
}
