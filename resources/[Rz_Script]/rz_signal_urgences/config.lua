Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  ITEM REQUIS
--
--  Seuls les porteurs d'un pager reçoivent les signaux. C'est ce qui
--  donne sa valeur à l'objet : sans lui, tu ne sais rien de ce qui
--  se passe ailleurs.
-- ═══════════════════════════════════════════════════════════════════
Config.RequireItem = true
Config.ItemName    = 'pager'


-- ═══════════════════════════════════════════════════════════════════
--  ZONES DE COUVERTURE RÉSEAU
--
--  Chaque zone a un relais. Quand une zone perd le courant, son
--  relais tombe et les pagers qui s'y trouvent ne reçoivent plus
--  rien — sauf les annonces du staff, qui passent toujours.
--
--  La couverture radio est circulaire par nature : un centre et un
--  rayon suffisent, inutile de reprendre les polygones du blackout.
--
--  ⚠️  Les clés doivent correspondre EXACTEMENT à celles de
--      blackout/config.lua, sinon la commande de coupure échouera.
-- ═══════════════════════════════════════════════════════════════════
Config.Zones = {
    sandy_shores = {
        label  = 'Sandy Shores',
        center = vec3(1850.0, 3400.0, 34.0),
        radius = 900.0,
    },
    paleto_bay = {
        label  = 'Paleto Bay',
        center = vec3(-100.0, 6350.0, 31.0),
        radius = 800.0,
    },
    grapeseed = {
        label  = 'Grapeseed',
        center = vec3(1750.0, 4580.0, 41.0),
        radius = 600.0,
    },
    zancudo = {
        label  = 'Fort Zancudo',
        center = vec3(-2000.0, 3200.0, 32.0),
        radius = 1200.0,
    },
    los_santos_centre = {
        label  = 'Los Santos — Centre',
        center = vec3(50.0, -800.0, 30.0),
        radius = 1400.0,
    },
    harmony = {
        label  = 'Harmony',
        center = vec3(300.0, 2900.0, 43.0),
        radius = 500.0,
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  PILOTAGE DU BLACKOUT
--
--  Le script blackout est chiffré et n'émet aucun événement : il est
--  impossible de savoir de l'extérieur quand une zone est coupée.
--  C'est donc NOUS qui pilotons — on enregistre l'état, on diffuse
--  l'alerte, puis on relaie la commande au script blackout.
-- ═══════════════════════════════════════════════════════════════════
Config.Blackout = {
    -- Relayer automatiquement vers le script blackout
    relayCommand = true,

    -- Doit correspondre à Config.CommandName de blackout/config.lua
    commandName = 'electricite',
}


-- ═══════════════════════════════════════════════════════════════════
--  NIVEAUX DE PRIORITÉ
--
--  `ignoreOutage` est la règle qui fait tout : une annonce du staff
--  traverse une panne réseau, une alerte automatique non.
-- ═══════════════════════════════════════════════════════════════════
Config.Priorities = {
    staff = {
        label        = 'ANNONCE OFFICIELLE',
        color        = '#60a5fa',
        ignoreOutage = true,
        duration     = 15000,
        sound        = 'CHECKPOINT_PERFECT',
    },
    critique = {
        label        = 'ALERTE CRITIQUE',
        color        = '#f87171',
        ignoreOutage = false,
        duration     = 14000,
        sound        = 'Beep_Red',
    },
    alerte = {
        label        = 'ALERTE',
        color        = '#fbbf24',
        ignoreOutage = false,
        duration     = 12000,
        sound        = 'Beep_Green',
    },
    info = {
        label        = 'BULLETIN',
        color        = '#4ade80',
        ignoreOutage = false,
        duration     = 10000,
        sound        = 'NAV_UP_DOWN',
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  MESSAGES AUTOMATIQUES
--
--  %s est remplacé par le nom de la zone.
--  Une variante est tirée au hasard à chaque déclenchement : au bout
--  de vingt coupures, un texte unique deviendrait du bruit de fond
--  que plus personne ne lit.
-- ═══════════════════════════════════════════════════════════════════
Config.Messages = {

    -- Envoyé AVANT la coupure, aux zones encore alimentées
    blackout_start = {
        'CHUTE DE TENSION SUR %s. RELAIS EN DEFAILLANCE.',
        'PERTE DU RESEAU ELECTRIQUE : %s. SECTEUR ISOLE.',
        'COUPURE CONFIRMEE SUR %s. PLUS AUCUN SIGNAL DU SECTEUR.',
        'LE RELAIS DE %s NE REPOND PLUS. SILENCE RADIO.',
    },

    -- Envoyé au rétablissement, y compris dans la zone concernée
    blackout_end = {
        'RETOUR DU COURANT SUR %s. RELAIS OPERATIONNEL.',
        'RESEAU RETABLI : %s. TRANSMISSIONS RESTAUREES.',
        '%s DE NOUVEAU EN LIGNE. SIGNAL STABLE.',
    },

    -- Envoyé au joueur qui entre dans une zone sans réseau
    signal_lost = {
        'AUCUN SIGNAL. TU ES HORS COUVERTURE.',
        'PLUS DE RESEAU. LE RELAIS LOCAL EST MORT.',
        'SIGNAL PERDU. TU N ENTENDS PLUS PERSONNE.',
    },

    -- Envoyé au joueur qui retrouve la couverture
    signal_back = {
        'SIGNAL RETROUVE. RECEPTION NORMALE.',
        'RESEAU DE NOUVEAU DISPONIBLE.',
    },

    -- Réservé au futur script rz_radioactivite
    radiation_approach = {
        'RAYONNEMENT DETECTE EN APPROCHE DE %s. FAIS DEMI-TOUR.',
        'COMPTEUR EN ALERTE : %s. NIVEAU DANGEREUX.',
        'ZONE CONTAMINEE DEVANT TOI : %s.',
    },
    radiation_critical = {
        'DOSE CRITIQUE. SORS DE LA ZONE IMMEDIATEMENT.',
        'IRRADIATION SEVERE EN COURS. REPLIE-TOI.',
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  AFFICHAGE
-- ═══════════════════════════════════════════════════════════════════
Config.Display = {
    -- 'screen' : bandeau LCD en haut de l'écran, dans l'esprit du pager
    -- 'notify' : notification ox_lib classique, plus discrète
    mode = 'screen',

    -- Vibration de la manette et léger flash à la réception
    haptic = true,

    -- Anti-spam : délai minimum entre deux signaux, en secondes
    cooldown = 3,
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉTECTION DE ZONE
-- ═══════════════════════════════════════════════════════════════════
Config.Detection = {
    -- Fréquence de vérification de la zone du joueur, en ms
    interval = 3000,
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = {
    announce = 'rz.signal.announce',   -- annonces staff
    network  = 'rz.signal.network',    -- couper/rétablir une zone
}

Config.AceSuper = 'rz_signal.admin'

function Config.HasAce(source, permission)
    if IsPlayerAceAllowed(source, Config.AceSuper) then return true end
    return IsPlayerAceAllowed(source, permission)
end

--[[
    server.cfg :
        add_ace group.admin     rz_signal.admin        allow
        add_ace group.moderator rz.signal.announce     allow
]]


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Tire un message au hasard dans une catégorie.
---@param category string
---@param ... any  arguments de formatage
---@return string
function Config.PickMessage(category, ...)
    local list = Config.Messages[category]
    if not list or #list == 0 then return '' end

    local template = list[math.random(1, #list)]
    local args = { ... }

    if #args > 0 then
        return template:format(table.unpack(args))
    end

    return template
end
