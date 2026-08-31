Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  POURQUOI CETTE RESSOURCE EXISTE
--
--  Qbox délègue l'apparition à `qbx_spawn`, qui n'est pas installé
--  ici. Résultat : un personnage se crée correctement, mais rien ne
--  le place dans le monde. Il reste à la position zéro, sous la
--  carte — écran noir et silence total.
--
--  Cette ressource comble ce trou, et se branchera naturellement sur
--  rz_safezone le jour où tes zones existeront : même logique que le
--  point de réapparition de rz_mort.
-- ═══════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════
--  OÙ APPARAÎT UN JOUEUR
--
--  Trois cas, dans cet ordre :
--
--    1. NOUVEAU PERSONNAGE     → point de départ ci-dessous
--    2. RETOUR EN JEU          → là où il s'est déconnecté
--    3. POSITION INVALIDE      → point de départ, en secours
--
--  Le troisième cas compte plus qu'il n'y paraît : une position
--  enregistrée à 0,0,0 — parce que le joueur a été déconnecté
--  pendant un chargement — le replacerait sous la carte à chaque
--  connexion, sans qu'il puisse rien y faire.
-- ═══════════════════════════════════════════════════════════════════
Config.Spawn = {
    -- Point de départ d'un nouveau personnage : le mont Chiliad.
    --
    -- Isolé, dégagé, à 340 m d'altitude. Un vestiaire de départ
    -- loin de tout, où le joueur s'équipe avant de descendre.
    default = vec4(-431.4511, 1102.2653, 340.4395, 346.9962),

    -- Restaurer la dernière position connue au retour en jeu
    restoreLastPosition = true,

    -- Une position enregistrée plus proche que ça de l'origine est
    -- considérée comme invalide : on renvoie au point de départ.
    minValidDistance = 5.0,

    -- Santé et armure à l'apparition (santé max : 200)
    health = 200,
    armour = 0,
}


-- ═══════════════════════════════════════════════════════════════════
--  SAFE ZONES
--
--  Si rz_safezone tourne et que des zones sont tracées, un nouveau
--  personnage apparaît dans la plus proche du point de départ
--  plutôt qu'au point lui-même. Ça évite d'avoir à modifier ce
--  fichier chaque fois que tu déplaces ta zone principale.
-- ═══════════════════════════════════════════════════════════════════
Config.UseSafezones = true






-- ═══════════════════════════════════════════════════════════════════
--  PERSONNALISATION À LA CRÉATION
--
--  illenium-appearance contient bien une fonction InitializeCharacter,
--  mais RIEN NE L'APPELLE : c'est au pont du framework de le faire,
--  et celui de Qbox ne s'en charge pas.
--
--  Résultat : un nouveau personnage arrive avec l'apparence par
--  défaut, sans jamais avoir pu se créer un visage ni s'habiller.
--
--  On déclenche donc l'ouverture nous-mêmes, juste après
--  l'apparition.
-- ═══════════════════════════════════════════════════════════════════
Config.Appearance = {
    -- Ouvrir la personnalisation pour un nouveau personnage
    onFirstSpawn = true,

    -- Secondes d'attente avant l'ouverture. Le temps que le décor
    -- se charge : ouvrir le menu sur un monde vide donne un aperçu
    -- du personnage sur fond noir.
    delaySeconds = 3,

    -- Le joueur peut-il rouvrir la personnalisation lui-même ?
    -- Utile pendant les tests, à passer à false pour l'ouverture :
    -- sinon chacun change de visage quand il veut, et plus personne
    -- ne se reconnaît.
    allowCommand = true,
    command = 'apparence',

    -- Immobiliser le joueur pendant la personnalisation. Sans ça,
    -- il peut s'éloigner et se retrouver hors du décor prévu.
    freezeDuring = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉSENCLAVEMENT
--
--  Un joueur peut se retrouver coincé de plusieurs façons : sous la
--  carte après une chute, à l'intérieur d'un décor mal collisionné,
--  dans un MLO dont la porte ne s'ouvre plus, ou simplement figé
--  après un chargement raté.
--
--  ─── LE PIÈGE À ÉVITER ─────────────────────────────────────────
--
--  Une commande de téléportation libre devient vite un outil de
--  triche : on l'utilise pour fuir un combat, pour traverser une
--  safe zone, pour échapper à un braquage.
--
--  D'où le compte à rebours immobile : si le joueur bouge, prend
--  des dégâts ou tire, la procédure s'annule. Quelqu'un réellement
--  coincé attend sans problème ; quelqu'un qui fuit ne peut pas.
-- ═══════════════════════════════════════════════════════════════════
Config.Unstuck = {
    enabled = true,

    -- Secondes d'immobilité avant le déplacement
    countdown = 15,

    -- Délai entre deux utilisations, en secondes
    cooldown = 300,

    -- Annuler si le joueur se déplace de plus de tant de mètres
    moveTolerance = 2.0,

    -- Annuler s'il prend des dégâts pendant l'attente
    cancelOnDamage = true,

    -- Interdire pendant un combat récent, en secondes
    combatLockSeconds = 20,

    -- ─── ESCALADE DES TENTATIVES ───────────────────────────────
    -- On essaie du moins intrusif au plus radical. Renvoyer
    -- systématiquement au point de départ ferait perdre sa
    -- progression à quelqu'un simplement coincé derrière une caisse.
    steps = {
        'ground',    -- 1. remonter au sol, sur place
        'road',      -- 2. la route la plus proche
        'spawn',     -- 3. le point de départ
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION AUTOMATIQUE
--
--  Le client surveille sa propre situation. Sous une certaine
--  hauteur, il n'y a plus de carte du tout : inutile d'attendre que
--  le joueur s'en aperçoive et tape une commande.
-- ═══════════════════════════════════════════════════════════════════
Config.Detection = {
    enabled = true,

    -- Sous cette altitude, on est forcément sous la carte
    underMapZ = -150.0,

    -- Secondes sous la carte avant le secours automatique
    underMapDelay = 5,

    -- Prévenir le joueur qu'il est détecté comme bloqué
    notify = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  ZONES INTERDITES
--
--  Endroits où un joueur ne doit JAMAIS apparaître : un MLO qui
--  fait planter, un décor mal collisionné, une zone en travaux.
--
--  Si sa position enregistrée tombe dans l'une d'elles, il est
--  renvoyé au point de départ plutôt que replacé dans le piège.
--
--  Sans ce mécanisme, un joueur déconnecté au mauvais endroit
--  plante à chaque tentative de connexion — et ne peut plus jamais
--  revenir sur son personnage.
--
--  Ajout en jeu : place-toi au centre du problème et tape
--  /zoneinterdite <rayon>
-- ═══════════════════════════════════════════════════════════════════
Config.Blacklist = {
    -- { label = 'nom lisible', x = ..., y = ..., z = ..., r = rayon }
}


-- ═══════════════════════════════════════════════════════════════════
--  TRANSITION
-- ═══════════════════════════════════════════════════════════════════
Config.Fade = {
    -- Millisecondes d'écran noir avant l'apparition. Le temps que
    -- le décor se charge : apparaître trop tôt montre un monde vide
    -- qui se remplit sous les yeux du joueur.
    inMs = 1500,

    -- Secondes maximales d'attente du chargement du décor. Passé ce
    -- délai on affiche quand même : mieux vaut un décor incomplet
    -- qu'un écran noir sans fin.
    maxWaitSeconds = 15,
}


-- ═══════════════════════════════════════════════════════════════════
--  MESSAGE D'ACCUEIL
-- ═══════════════════════════════════════════════════════════════════
Config.Welcome = {
    enabled = true,

    newCharacter = {
        title = 'Bienvenue en Red Zone',
        text  = 'Tu n\'as rien. Trouve de quoi survivre avant la nuit.',
    },

    returning = {
        title = 'De retour',
        text  = 'Rien n\'a changé. Le monde est toujours aussi hostile.',
    },
}

-- ═══════════════════════════════════════════════════════════════════
--  DÉBLOCAGE
--
--  Trois situations distinctes, trois réponses :
--
--    SOUS LA CARTE      le joueur est passé au travers du sol
--    COINCÉ DANS UN DÉCOR  bloqué dans un mur, un rocher, un MLO
--    ZONE QUI FAIT PLANTER  un endroit précis fait crasher le jeu
--
--  Les deux premiers se règlent seuls. Le troisième demande une
--  intervention : le joueur ne peut pas signaler un plantage
--  puisqu'il est éjecté du jeu.
-- ═══════════════════════════════════════════════════════════════════
Config.Unstuck = {
    enabled = true,

    -- Délai entre deux utilisations, en secondes. Sans limite, la
    -- commande devient une téléportation gratuite pour fuir un
    -- combat ou traverser la carte.
    cooldown = 120,

    -- Interdire le déblocage si le joueur a pris des dégâts
    -- récemment. C'est ce qui empêche de s'en servir pour
    -- s'échapper d'une fusillade.
    blockAfterDamageSeconds = 30,

    -- Durée de la barre de progression, en ms. Assez longue pour
    -- qu'on ne l'utilise pas par réflexe.
    duration = 8000,

    -- ─── DÉTECTION AUTOMATIQUE ─────────────────────────────────
    -- Le client surveille en permanence et propose le déblocage
    -- de lui-même quand il détecte un problème.
    autoDetect = true,

    -- Sous cette hauteur, le joueur est forcément sous la carte :
    -- le point le plus bas de la carte GTA est à environ -100.
    underMapZ = -120.0,

    -- Immobile et sans contrôle pendant ce temps = coincé
    stuckSeconds = 20,

    -- ─── MÉTHODE DE SAUVETAGE ──────────────────────────────────
    -- On essaie dans cet ordre, du moins perturbant au plus radical.

    -- 1. Chercher le sol juste au-dessus du joueur
    tryGroundAbove = true,

    -- 2. Chercher un sol praticable en spirale autour de lui.
    --    Rayon maximum de la recherche, en mètres.
    searchRadius = 60.0,

    -- 3. En dernier recours, renvoyer au point d'apparition
    fallbackToSpawn = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  ZONES QUI FONT PLANTER
--
--  Un endroit qui crashe est un piège invisible : le joueur y
--  retourne, replante, et personne ne comprend pourquoi il n'arrive
--  plus à se connecter.
--
--  Le staff marque la zone depuis le menu admin. Ensuite :
--
--    • un joueur qui s'en approche est prévenu
--    • un joueur qui y entre est repoussé
--    • aucune apparition n'y est placée
--    • aucun sac mortuaire ni largage n'y tombe
-- ═══════════════════════════════════════════════════════════════════
Config.CrashZones = {
    enabled = true,

    -- Distance à laquelle on prévient le joueur
    warnDistance = 80.0,

    -- Distance à laquelle on le repousse de force
    pushDistance = 25.0,

    -- Délai entre deux avertissements, en secondes
    warnCooldown = 30,

    -- Fréquence de vérification, en ms. Une seconde suffit : on ne
    -- traverse pas 25 mètres en moins de temps que ça, même en
    -- véhicule rapide.
    checkInterval = 1000,
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.spawn'
Config.AceSuper = 'rz_spawn.admin'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.AceSuper)
        or IsPlayerAceAllowed(source, Config.Ace)
        or IsPlayerAceAllowed(source, 'rz.staff')
end

--[[
    server.cfg :
        add_ace group.admin      rz_spawn.admin allow
        add_ace group.moderateur rz.spawn       allow
]]


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Ce point est-il dans une zone interdite ?
---@return table|nil la zone, ou nil
function Config.BlacklistedAt(x, y, z)
    for _, b in ipairs(Config.Blacklist) do
        local dx, dy = x - b.x, y - b.y
        local dz = (z and b.z) and (z - b.z) or 0

        if (dx * dx + dy * dy + dz * dz) <= (b.r * b.r) then
            return b
        end
    end
    return nil
end


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.spawn'
Config.AceSuper = 'rz_spawn.admin'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.AceSuper)
        or IsPlayerAceAllowed(source, Config.Ace)
        or IsPlayerAceAllowed(source, 'rz.mort')
end

--[[
    server.cfg :
        add_ace group.admin      rz_spawn.admin allow
        add_ace group.moderateur rz.spawn       allow
]]
