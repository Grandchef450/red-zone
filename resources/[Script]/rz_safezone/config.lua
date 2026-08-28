Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  SCRIPT DE ZOMBIES
--
--  Le script Fivecore est chiffré (escrow) : impossible de le
--  modifier. Mais il expose registerSafezone / removeSafezone.
--  Il ne connaît que des CERCLES, alors que nos zones sont des
--  polygones — on lui déclare donc le cercle englobant.
--
--  Le cercle étant plus large que le polygone, un peu de terrain
--  autour est aussi vidé de zombies. C'est voulu : évite qu'un
--  zombie t'attende à trois mètres de la sortie.
-- ═══════════════════════════════════════════════════════════════════
Config.Zombies = {
    enabled  = true,
    resource = 'zombies',   -- nom du DOSSIER de la ressource
    margin   = 15.0,        -- mètres ajoutés au rayon englobant
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION
-- ═══════════════════════════════════════════════════════════════════
Config.Detection = {
    -- Fréquence de test côté client, en ms. 250 est un bon
    -- compromis : imperceptible pour le joueur, négligeable en CPU.
    clientInterval = 250,

    -- Le serveur revérifie de son côté. C'est cette valeur qui
    -- compte pour la sécurité : un client modifié peut mentir sur
    -- sa position, mais pas contourner un test serveur.
    serverInterval = 1000,

    -- Distance au-delà de laquelle on ne teste plus une zone
    -- (optimisation : inutile de calculer un polygone à 3 km).
    maxTestDistance = 500.0,
}


-- ═══════════════════════════════════════════════════════════════════
--  AFFICHAGE
-- ═══════════════════════════════════════════════════════════════════
Config.Display = {
    -- Bandeau haut-centre à l'entrée dans la zone
    bannerDuration = 4000,   -- ms d'affichage du message d'entrée
    persistentHud  = true,   -- petit indicateur permanent tant qu'on est dedans

    colors = {
        safe   = { 74, 222, 128 },   -- vert : dans la zone
        buffer = { 250, 204, 21 },   -- jaune : zone tampon
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PROJECTILES
--
--  Les types détruits quand ils entrent dans une zone. Les balles
--  ordinaires ne sont pas des projectiles au sens du moteur : elles
--  sont traitées par l'annulation de dégâts côté serveur.
-- ═══════════════════════════════════════════════════════════════════
Config.Projectiles = {
    'WEAPON_GRENADE',
    'WEAPON_STICKYBOMB',
    'WEAPON_PROXMINE',
    'WEAPON_PIPEBOMB',
    'WEAPON_MOLOTOV',
    'WEAPON_SMOKEGRENADE',
    'WEAPON_BZGAS',
    'WEAPON_RPG',
    'WEAPON_HOMINGLAUNCHER',
    'WEAPON_GRENADELAUNCHER',
    'WEAPON_COMPACTLAUNCHER',
    'WEAPON_FIREWORK',
    'WEAPON_FLARE',
    'WEAPON_SNOWBALL',
    'WEAPON_BALL',
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = {
    edit = 'rz_safezone.edit',
    view = 'rz_safezone.view',
}

Config.AceSuper = 'rz_safezone.admin'

function Config.HasAce(source, permission)
    if IsPlayerAceAllowed(source, Config.AceSuper) then return true end
    return IsPlayerAceAllowed(source, permission)
end

--[[
    server.cfg :
        add_ace group.admin rz_safezone.admin allow
]]


-- ═══════════════════════════════════════════════════════════════════
--  JOURNALISATION
-- ═══════════════════════════════════════════════════════════════════
Config.Logging = {
    enabled = true,

    -- Ne pas écrire une ligne par balle : un tir automatique en
    -- produirait des centaines par seconde. On regroupe par joueur
    -- sur une fenêtre glissante.
    cooldownSeconds = 5,
}
