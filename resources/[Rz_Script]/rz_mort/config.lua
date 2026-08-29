Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  AGONIE
--
--  Le joueur ne meurt pas d'un coup : il tombe, immobilisé, et
--  dispose d'un délai pendant lequel un autre survivant peut le
--  relever. Passé ce délai, la mort est définitive et son stuff
--  tombe au sol.
--
--  C'est ce sursis qui donne sa valeur au fait de jouer à plusieurs :
--  seul, on meurt ; accompagné, on a une chance.
-- ═══════════════════════════════════════════════════════════════════
Config.Agonie = {
    seconds = 180,          -- 3 minutes avant la mort définitive

    -- Le joueur peut abandonner et mourir tout de suite
    allowGiveUp = true,
    giveUpAfter = 30,       -- pas avant 30 s, pour éviter le réflexe

    -- Santé attribuée pendant l'agonie. Assez basse pour que la
    -- barre paraisse vide, assez haute pour ne pas remourir.
    health = 125,

    -- VUE SUBJECTIVE FORCÉE
    -- À terre, on ne voit plus la scène de haut : on est cloué au
    -- sol, à hauteur de visage. C'est ce qui rend l'agonie
    -- oppressante plutôt que confortable. La touche de changement
    -- de caméra est bloquée pendant toute la durée.
    forceFirstPerson = true,

    -- Appel à l'aide : signale sa position aux joueurs proches
    callDistance = 120.0,
    callCooldown = 30,
}


-- ═══════════════════════════════════════════════════════════════════
--  RÉANIMATION
-- ═══════════════════════════════════════════════════════════════════
Config.Revive = {
    -- UN SEUL ITEM RELÈVE : l'épipen.
    --
    -- Les bandages, attelles et trousses ne servent PAS à relever.
    -- Ils servent à se soigner après. Ce découpage est ce qui donne
    -- son prix à l'épipen : c'est le seul objet qui ramène quelqu'un,
    -- et il ne rend presque rien. Le vrai soin vient après, et il
    -- coûte d'autres ressources.
    item     = 'epipen',
    duration = 10000,          -- barre de progression du secouriste

    -- Santé rendue, en pourcentage du maximum.
    -- 10 % de 200 = 20 points : le relevé est debout, mais un coup
    -- de poing suffit à le remettre à terre.
    healthPercent = 10,

    -- Plancher absolu, pour qu'un réglage trop bas ne fasse pas
    -- remourir le joueur dans la seconde.
    healthFloor = 15,

    -- Distance maximale pour porter secours
    distance = 2.0,

    -- DÉLAI DE REDRESSEMENT
    -- Une fois l'injection faite, le joueur reste au sol le temps
    -- que le produit agisse. Le secouriste le voit se relever à la
    -- fin de ce délai, pas à la fin de sa barre de progression.
    standUpSeconds = 30,

    -- Après s'être relevé, encore un moment sans courir ni se battre
    groggySeconds = 15,
}


-- ═══════════════════════════════════════════════════════════════════
--  SAC MORTUAIRE
--
--  Tout tombe, SAUF ce que rz_coffres protège : un coffre de
--  sécurité encore sous minuteur reste avec son propriétaire. C'est
--  toute la raison d'être de cet objet.
-- ═══════════════════════════════════════════════════════════════════
Config.Bag = {
    -- Verrou propriétaire : lui seul peut rouvrir pendant ce délai
    ownerLockSeconds = 300,     -- 5 minutes

    -- Les sacs restent au sol jusqu'à cette ancienneté, en heures.
    -- Aligné sur le reboot quotidien du serveur.
    maxAgeHours = 24,

    slots     = 100,
    maxWeight = 500000,

    -- Prop posé au sol. NULL pour n'avoir qu'un marqueur.
    propModel = 'prop_mil_crate_01',

    -- Marqueur au sol, visible de loin
    marker = {
        enabled = true,
        distance = 40.0,
    },

    -- Blip visible UNIQUEMENT par le propriétaire, pendant le verrou.
    -- Sans lui, retrouver son sac dans un champ tiendrait du hasard.
    blipForOwner = true,

    -- La mort en safe zone ne fait rien tomber : on n'y meurt pas
    -- de la main d'un autre, et perdre son stuff sur une chute
    -- accidentelle en ville serait absurde.
    dropInSafezone = false,
}


-- ═══════════════════════════════════════════════════════════════════
--  RÉAPPARITION
--
--  Le joueur revient à la safe zone la plus proche de l'endroit où
--  il est mort. Les positions viennent de rz_safezone ; la liste
--  ci-dessous n'est qu'un filet de sécurité si cette ressource
--  n'est pas démarrée.
-- ═══════════════════════════════════════════════════════════════════
Config.Respawn = {
    -- Santé au réveil (max 200)
    health = 140,

    -- Écran noir avant la réapparition, en ms
    fadeMs = 3000,

    fallback = {
        vec3(1850.0, 3690.0, 34.2),    -- Sandy Shores
        vec3(-95.0,  6430.0, 31.5),    -- Paleto Bay
        vec3(1700.0, 4780.0, 42.0),    -- Grapeseed
        vec3(220.0,  -880.0, 30.7),    -- Los Santos
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  AFFICHAGE
-- ═══════════════════════════════════════════════════════════════════
Config.Display = {
    -- Effet d'écran pendant l'agonie
    screenEffect = 'DeathFailOut',

    -- Désaturation progressive à mesure que le temps s'écoule
    desaturate = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.mort'
Config.AceSuper = 'rz_mort.admin'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.AceSuper)
        or IsPlayerAceAllowed(source, Config.Ace)
end

--[[
    server.cfg :
        add_ace group.admin     rz_mort.admin allow
        add_ace group.moderator rz.mort       allow
]]
