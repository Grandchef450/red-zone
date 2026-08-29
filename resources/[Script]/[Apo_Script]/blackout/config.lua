Config = {}

-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — BLACKOUT
--  Corrigé le 29 août 2026
--
--  ⚠️  Les zones d'origine étaient des EXEMPLES laissés par l'auteur :
--  une « safezone » vers Sandy Shores et une « prison », toutes deux
--  alimentées. Elles n'avaient aucun rapport avec la carte RedZone.
--
--  PARTI PRIS POST-APOCALYPTIQUE
--  Le réseau électrique est mort. Toutes les zones démarrent donc
--  éteintes (hasElectricity = false), SAUF celles où les survivants
--  ont remonté un générateur. C'est l'inverse du réglage d'un serveur
--  RP classique, et c'est ce qui donne sa texture au monde : la
--  lumière devient une ressource, pas un acquis.
--
--  ⚠️  SYNCHRONISATION AVEC rz_safezone
--  Ce script garde ses propres polygones : il est chiffré (.fxap),
--  impossible de lui faire lire ceux de rz_safezone. Si tu déplaces
--  une zone sûre, pense à corriger ici aussi. C'est le seul endroit
--  du serveur où des coordonnées sont dupliquées.
-- ═══════════════════════════════════════════════════════════════════

-- Qbox expose ses exports sous le nom « qb-core » : l'option 'qb'
-- fonctionne telle quelle grâce au pont de compatibilité.
Config.Framework = 'qb'


-- ═══════════════════════════════════════════════════════════════════
--  ZONES ÉLECTRIQUES
--
--  ⚠️  LES COORDONNÉES CI-DESSOUS SONT DES POINTS DE DÉPART.
--  Elles couvrent les agglomérations connues de la carte, mais elles
--  ne correspondent pas encore à TES zones sûres.
--
--  POUR RELEVER TES PROPRES COORDONNÉES :
--  place-toi à chaque coin de la zone et note ta position avec
--  dolu_tool, déjà installé. Trois points minimum, dans l'ordre du
--  tracé — le polygone se referme tout seul.
--
--  minZ / maxZ : le plafond doit passer AU-DESSUS des toits, sinon
--  un joueur en hauteur sort de la zone et garde la lumière.
-- ═══════════════════════════════════════════════════════════════════
Config.PowerZones = {

    -- ─── SANDY SHORES ─────────────────────────────────────────────
    -- Générateur communautaire : la ville est éclairée.
    ['sandy_shores'] = {
        name = "Sandy Shores",
        points = {
            vector3(1560.0, 3520.0, 35.0),
            vector3(2100.0, 3560.0, 35.0),
            vector3(2150.0, 3280.0, 35.0),
            vector3(1520.0, 3240.0, 35.0),
        },
        minZ = 0.0,
        maxZ = 150.0,
        hasElectricity = true
    },

    -- ─── PALETO BAY ───────────────────────────────────────────────
    ['paleto_bay'] = {
        name = "Paleto Bay",
        points = {
            vector3(-450.0, 6100.0, 20.0),
            vector3(250.0,  6250.0, 20.0),
            vector3(300.0,  6600.0, 20.0),
            vector3(-500.0, 6500.0, 20.0),
        },
        minZ = 0.0,
        maxZ = 150.0,
        hasElectricity = true
    },

    -- ─── GRAPESEED ────────────────────────────────────────────────
    ['grapeseed'] = {
        name = "Grapeseed",
        points = {
            vector3(1600.0, 4700.0, 40.0),
            vector3(1900.0, 4750.0, 40.0),
            vector3(1950.0, 4450.0, 40.0),
            vector3(1600.0, 4400.0, 40.0),
        },
        minZ = 0.0,
        maxZ = 150.0,
        hasElectricity = false   -- village abandonné
    },

    -- ─── FORT ZANCUDO ─────────────────────────────────────────────
    -- Tu as le MLO Better_Zancudo : une base militaire encore
    -- alimentée est un excellent objectif de fin de progression.
    ['zancudo'] = {
        name = "Fort Zancudo",
        points = {
            vector3(-2500.0, 3600.0, 15.0),
            vector3(-1600.0, 3700.0, 15.0),
            vector3(-1500.0, 2800.0, 15.0),
            vector3(-2450.0, 2750.0, 15.0),
        },
        minZ = 0.0,
        maxZ = 300.0,
        hasElectricity = true
    },

    -- ─── LOS SANTOS — CENTRE ──────────────────────────────────────
    -- Éteint : la grande ville est le cœur de l'infestation.
    ['los_santos_centre'] = {
        name = "Los Santos — Centre",
        points = {
            vector3(-400.0, -1200.0, 30.0),
            vector3(400.0,  -1100.0, 30.0),
            vector3(500.0,  -400.0,  30.0),
            vector3(-300.0, -500.0,  30.0),
        },
        minZ = -50.0,
        maxZ = 400.0,   -- gratte-ciel
        hasElectricity = false
    },

    -- ─── HARMONY ──────────────────────────────────────────────────
    ['harmony'] = {
        name = "Harmony",
        points = {
            vector3(150.0,  3050.0, 40.0),
            vector3(450.0,  3100.0, 40.0),
            vector3(450.0,  2800.0, 40.0),
            vector3(150.0,  2780.0, 40.0),
        },
        minZ = 0.0,
        maxZ = 150.0,
        hasElectricity = false
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDE
--
--  Usage : /electricite <zone> <on|off>
--  Le nom de zone est la CLÉ du tableau ci-dessus, pas le libellé :
--  donc « sandy_shores », pas « Sandy Shores ».
-- ═══════════════════════════════════════════════════════════════════
Config.CommandName = "electricite"
Config.AdminOnly = true


-- ═══════════════════════════════════════════════════════════════════
--  TEXTES
-- ═══════════════════════════════════════════════════════════════════
Config.Language = 'fr'

Config.Locales = {
    ['fr'] = {
        ['zone_not_found']   = 'Zone introuvable. Utilise la clé technique, pas le nom affiché.',
        ['electricity_on']   = 'Courant rétabli sur %s.',
        ['electricity_off']  = 'Courant coupé sur %s.',
        ['invalid_command']  = 'Usage : /%s [zone] [on/off]',
        ['command_help']     = 'Couper ou rétablir le courant dans une zone',
        ['zone_param']       = 'Clé de la zone',
        ['state_param']      = 'on / off'
    },
    ['en'] = {
        ['zone_not_found']   = 'Zone not found!',
        ['electricity_on']   = 'Electricity turned ON for %s.',
        ['electricity_off']  = 'Electricity turned OFF for %s.',
        ['invalid_command']  = 'Invalid command! Usage: /%s [zone] [on/off]',
        ['command_help']     = 'Control electricity in zones',
        ['zone_param']       = 'Zone name',
        ['state_param']      = 'on/off'
    },
}
