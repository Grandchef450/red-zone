Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  RYTHME
-- ═══════════════════════════════════════════════════════════════════
Config.Schedule = {
    enabled = true,

    -- Minutes entre deux largages
    intervalMinutes = 60,

    -- Premier largage après le démarrage du serveur, en minutes.
    -- Assez pour que les joueurs se reconnectent après un reboot.
    firstDelayMinutes = 10,

    -- Nombre minimum de joueurs connectés pour qu'un largage parte.
    -- Un largage sans personne pour le ramasser encombre la carte
    -- et fausse les statistiques.
    minPlayers = 1,
}


-- ═══════════════════════════════════════════════════════════════════
--  LE LARGAGE
-- ═══════════════════════════════════════════════════════════════════
Config.Drop = {
    -- Nombre de caisses par largage
    crates = 4,

    -- Délai avant qu'une caisse puisse être ouverte, en secondes.
    -- C'est la fenêtre pendant laquelle les joueurs convergent et
    -- se disputent la position — le cœur de l'intérêt d'un largage.
    protectionSeconds = 300,     -- 5 minutes

    -- Durée de vie d'une caisse, en secondes. Passé ce délai, les
    -- caisses non ouvertes disparaissent.
    lifetimeSeconds = 1800,      -- 30 minutes

    -- Secondes entre deux largages successifs le long du trajet.
    -- Tirées au hasard dans cette fourchette.
    intervalMin = 20,
    intervalMax = 45,

    -- Distance minimale entre deux caisses d'un même largage.
    -- Sans ce minimum, les quatre pourraient tomber côte à côte et
    -- un seul groupe raflerait tout sans bouger.
    minSpacing = 400.0,

    -- Modèle de la caisse
    propModel = 'prop_box_ammo04a',

    -- Fumigène coloré sur la caisse, visible de loin
    smoke = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  L'AVION
--
--  AUCUN MODÈLE N'EST CHARGÉ. On n'affiche qu'un blip qui traverse
--  la carte en ligne droite : c'est ce que tu voulais, et c'est
--  aussi bien plus léger qu'un appareil streamé pour tous les
--  joueurs simultanément.
-- ═══════════════════════════════════════════════════════════════════
Config.Plane = {
    -- Vitesse du blip, en unités par seconde
    speed = 180.0,

    -- Distance parcourue avant le premier largage et après le
    -- dernier, pour que l'appareil semble venir de loin et
    -- repartir au loin.
    approach = 1500.0,

    blipSprite = 423,   -- avion
    blipColour = 5,     -- jaune
    blipScale  = 0.9,
}


-- ═══════════════════════════════════════════════════════════════════
--  ZONES DE LARGAGE
--
--  ⚠️  POURQUOI DES ZONES ET PAS DES COORDONNÉES LIBRES
--
--  Le serveur ne peut pas savoir si un point est sur terre : la
--  hauteur du sol et la présence d'eau sont des données CLIENT.
--  Tirer un point au hasard sur la carte finirait fatalement par
--  poser une caisse au milieu de l'océan.
--
--  Chaque zone ci-dessous est un cercle entièrement terrestre. Le
--  serveur y tire un point au hasard : la variété est préservée,
--  le risque de noyade nul.
--
--  Pour ajouter une zone : place-toi au centre, note tes
--  coordonnées avec dolu_tool, et choisis un rayon qui ne touche
--  ni la mer, ni un lac, ni une falaise.
-- ═══════════════════════════════════════════════════════════════════
Config.LandZones = {
    -- ─── NORD ──────────────────────────────────────────────────
    { label = 'Paleto Bay',        x = -180.0,  y = 6280.0,  r = 500.0 },
    { label = 'Mont Chiliad',      x = 480.0,   y = 5700.0,  r = 700.0 },
    { label = 'Forêts du nord',    x = -650.0,  y = 5300.0,  r = 800.0 },
    { label = 'Grapeseed',         x = 1900.0,  y = 4700.0,  r = 600.0 },
    { label = 'Braddock Pass',     x = 1500.0,  y = 6300.0,  r = 500.0 },

    -- ─── DÉSERT ────────────────────────────────────────────────
    { label = 'Sandy Shores',      x = 1900.0,  y = 3600.0,  r = 800.0 },
    { label = 'Grand Senora',      x = 900.0,   y = 3000.0,  r = 900.0 },
    { label = 'Aéroport de Sandy', x = 1700.0,  y = 3200.0,  r = 500.0 },
    { label = 'Harmony',           x = 300.0,   y = 2900.0,  r = 500.0 },
    { label = 'Route 68',          x = 200.0,   y = 3500.0,  r = 700.0 },

    -- ─── CENTRE ────────────────────────────────────────────────
    { label = 'Mont Gordo',        x = 2600.0,  y = 4200.0,  r = 600.0 },
    { label = 'Fort Zancudo',      x = -2050.0, y = 3200.0,  r = 700.0 },
    { label = 'Vallée de Chiliad', x = -400.0,  y = 4400.0,  r = 700.0 },
    { label = 'Tongva Hills',      x = -1400.0, y = 2000.0,  r = 700.0 },
    { label = 'Grand Senora est',  x = 1300.0,  y = 2100.0,  r = 600.0 },

    -- ─── SUD ───────────────────────────────────────────────────
    { label = 'Vinewood Hills',    x = -100.0,  y = 800.0,   r = 700.0 },
    { label = 'Los Santos nord',   x = 300.0,   y = -400.0,  r = 600.0 },
    { label = 'Los Santos centre', x = 200.0,   y = -1100.0, r = 600.0 },
    { label = 'Aéroport de LS',    x = -1000.0, y = -2500.0, r = 500.0 },
    { label = 'Chumash',           x = -3100.0, y = 1200.0,  r = 400.0 },
    { label = 'Banham Canyon',     x = -2000.0, y = 700.0,   r = 500.0 },
    { label = 'El Burro Heights',  x = 1400.0,  y = -1600.0, r = 500.0 },
    { label = 'Palomino',          x = 2400.0,  y = -400.0,  r = 600.0 },
}


-- ═══════════════════════════════════════════════════════════════════
--  RARETÉ CROISSANTE
--
--  La première caisse est ordinaire, la dernière rare. C'est ce qui
--  fait durer l'événement : partir dès la première caisse, c'est
--  passer à côté du vrai butin.
--
--  `items` limite le nombre d'objets NON consommables par caisse.
--  Les ressources ne sont pas comptées : elles peuvent être
--  nombreuses sans déséquilibrer quoi que ce soit.
-- ═══════════════════════════════════════════════════════════════════
Config.Tiers = {
    {
        key   = 'commun',
        label = 'Caisse de ravitaillement',
        note  = 'Matériaux de base, un peu de matériel',
        colour = 2,      -- vert
        smokeColour = { 40, 200, 80 },
        items = 1,       -- objets max
        resourceRolls = { min = 3, max = 5 },
    },
    {
        key   = 'peu_commun',
        label = 'Caisse militaire légère',
        note  = 'Matériaux transformés, outillage',
        colour = 5,      -- jaune
        smokeColour = { 230, 200, 40 },
        items = 2,
        resourceRolls = { min = 3, max = 6 },
    },
    {
        key   = 'rare',
        label = 'Caisse militaire lourde',
        note  = 'Équipement, protection, armes blanches',
        colour = 47,     -- orange
        smokeColour = { 240, 140, 30 },
        items = 3,
        resourceRolls = { min = 4, max = 7 },
    },
    {
        key   = 'tres_rare',
        label = 'Caisse scellée',
        note  = 'Le meilleur du largage. Elle se mérite.',
        colour = 1,      -- rouge
        smokeColour = { 240, 50, 50 },
        items = 4,
        resourceRolls = { min = 5, max = 9 },
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PLAFOND GLOBAL
--
--  Dix objets complets par largage, toutes caisses confondues. Sans
--  ce plafond, quatre caisses généreuses inonderaient le serveur
--  d'équipement en une soirée et videraient l'arbre de craft de son
--  intérêt.
--
--  Les RESSOURCES n'entrent pas dans ce compte : elles alimentent
--  le craft plutôt que de le remplacer.
-- ═══════════════════════════════════════════════════════════════════
Config.MaxItemsPerDrop = 10


-- ═══════════════════════════════════════════════════════════════════
--  ARMES
--
--  ⚠️  ARMES BLANCHES UNIQUEMENT.
--
--  Le filtre s'appuie sur le champ rzTier de weapons.lua : seules
--  les armes marquées « melee » peuvent sortir d'un largage. Aucune
--  arme à feu, quelle que soit la caisse.
-- ═══════════════════════════════════════════════════════════════════
Config.Weapons = {
    enabled = true,

    -- Seul palier autorisé
    allowedTier = 'melee',

    -- Chance qu'une caisse contienne une arme, par rareté
    chance = {
        commun      = 5,
        peu_commun  = 15,
        rare        = 40,
        tres_rare   = 70,
    },

    -- Armes à ne jamais larguer, même en melee
    blacklist = {
        'WEAPON_KNUCKLE',
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  ANNONCES
--
--  Passent par rz_signal_urgences, donc uniquement aux porteurs de
--  pager. Un largage qu'on apprend par hasard n'a pas la même
--  valeur que celui qu'on a anticipé.
-- ═══════════════════════════════════════════════════════════════════
Config.Announce = {
    enabled = true,

    -- Annoncer le décollage, avant le premier largage
    incoming = {
        'APPAREIL NON IDENTIFIE EN APPROCHE. LARGAGE IMMINENT.',
        'CONTACT RADAR. UN AVION TRAVERSE LE SECTEUR.',
        'RAVITAILLEMENT AERIEN DETECTE. PREPARE-TOI.',
    },

    -- Annoncer chaque caisse posée
    crateDropped = {
        'COLIS LARGUE PRES DE %s.',
        'UNE CAISSE VIENT DE TOMBER : %s.',
        'RAVITAILLEMENT AU SOL, SECTEUR %s.',
    },

    -- Fin de la fenêtre de ramassage
    expired = {
        'LES COLIS RESTANTS ONT ETE RECUPERES. TROP TARD.',
        'FIN DU LARGAGE. PLUS RIEN A RECUPERER.',
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.airdrop'
Config.AceSuper = 'rz_airdrop.admin'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.AceSuper)
        or IsPlayerAceAllowed(source, Config.Ace)
end

--[[
    server.cfg :
        add_ace group.admin rz_airdrop.admin allow
]]


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Un point tiré au hasard dans une zone terrestre.
---@param zone table
---@return number x, number y
function Config.RandomPointIn(zone)
    -- Racine carrée du tirage : sans elle, les points s'agglutinent
    -- au centre du cercle au lieu de s'y répartir uniformément.
    local angle = math.random() * math.pi * 2
    local radius = math.sqrt(math.random()) * zone.r

    return zone.x + math.cos(angle) * radius,
           zone.y + math.sin(angle) * radius
end


---Ce point est-il dans une zone terrestre ?
---@return table|nil la zone, ou nil
function Config.ZoneAt(x, y)
    for _, z in ipairs(Config.LandZones) do
        local dx, dy = x - z.x, y - z.y
        if (dx * dx + dy * dy) <= (z.r * z.r) then
            return z
        end
    end
    return nil
end


---Palier par son index, borné.
function Config.TierAt(index)
    return Config.Tiers[math.max(1, math.min(#Config.Tiers, index))]
end


---Tire un message au hasard.
function Config.PickMessage(category, ...)
    local list = Config.Announce[category]
    if not list or #list == 0 then return '' end

    local template = list[math.random(1, #list)]
    local args = { ... }

    if #args > 0 then return template:format(table.unpack(args)) end
    return template
end
