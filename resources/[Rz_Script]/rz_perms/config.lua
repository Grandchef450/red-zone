Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  LES OUTILS DU MENU ADMIN
--
--  Chaque entrée décrit un bouton du F5 : la ressource visée, le
--  callback à appeler, et la permission qui en ouvre l'accès.
--
--  Ce tableau sert UNIQUEMENT à décider quels boutons afficher. La
--  sécurité réelle reste dans chaque ressource, côté serveur : un
--  bouton caché n'a jamais empêché personne de déclencher un
--  callback à la main.
-- ═══════════════════════════════════════════════════════════════════
Config.Tools = {
    {
        id       = 'rz-staff',
        resource = 'rz_perms',
        callback = 'openStaff',
        label    = 'Équipe',
        icon     = 'fa-user-shield',
        -- Accorder un grade, c'est pouvoir s'accorder tous les
        -- autres. Réservé au droit le plus élevé.
        perms    = { 'rz_perms.manage', 'rz_craft.admin' },
    },
    {
        id       = 'rz-craft',
        resource = 'rz_craft',
        callback = 'openCreator',
        label    = 'Craft Creator',
        icon     = 'fa-hammer',
        -- Le premier droit trouvé suffit : voir suffit à ouvrir le
        -- menu, même sans pouvoir éditer.
        perms    = { 'rz_craft.admin', 'rz_craft.edit', 'rz_craft.view' },
    },
    {
        id       = 'rz-safezones',
        resource = 'rz_safezone',
        callback = 'openSafezones',
        label    = 'Zones sûres',
        icon     = 'fa-shield-halved',
        perms    = { 'rz_safezone.admin', 'rz_safezone.edit', 'rz_safezone.view' },
    },
    {
        id       = 'rz-coffres',
        resource = 'rz_coffres',
        callback = 'openCoffres',
        label    = 'Coffres',
        icon     = 'fa-box-archive',
        perms    = { 'rz_coffres.admin', 'rz.coffres.give' },
    },
    {
        id       = 'rz-epaves',
        resource = 'rz_epaves',
        callback = 'openEpaves',
        label    = 'Loot épaves',
        icon     = 'fa-car-burst',
        perms    = { 'rz_epaves.admin', 'rz.staff' },
    },
    {
        id       = 'rz-signal',
        resource = 'rz_signal_urgences',
        callback = 'openSignal',
        label    = 'Annonces pager',
        icon     = 'fa-tower-broadcast',
        perms    = { 'rz_signal.admin', 'rz.signal.announce', 'rz.signal.network' },
    },
    {
        id       = 'rz-airdrop',
        resource = 'rz_airdrop',
        callback = 'openAirdrop',
        label    = 'Largages',
        icon     = 'fa-parachute-box',
        perms    = { 'rz_airdrop.admin', 'rz.airdrop' },
    },
    {
        id       = 'rz-radiation',
        resource = 'rz_radioactivite',
        callback = 'openRadiation',
        label    = 'Zone radioactive',
        icon     = 'fa-radiation',
        perms    = { 'rz_radiation.admin', 'rz.radiation' },
    },
    {
        id       = 'rz-spawn',
        resource = 'rz_spawn',
        callback = 'openSpawn',
        label    = 'Sauvetage',
        icon     = 'fa-person-falling',
        perms    = { 'rz_spawn.admin', 'rz.spawn', 'rz.staff' },
    },
    {
        id       = 'rz-mort',
        resource = 'rz_mort',
        callback = 'openMort',
        label    = 'Mort et sacs',
        icon     = 'fa-skull',
        perms    = { 'rz_mort.admin', 'rz.mort' },
    },
    {
        id       = 'rz-props',
        resource = 'rz_props',
        callback = 'openPanel',
        label    = 'Props',
        icon     = 'fa-cubes',
        perms    = { 'rz.props' },
    },
    {
        id       = 'rz-jobs',
        resource = 'rz_jobcreator',
        callback = 'openPanel',
        label    = 'Jobs',
        icon     = 'fa-briefcase',
        perms    = { 'rz.jobcreator' },
    },
    {
        id       = 'rz-jail',
        resource = 'rz_adminjail',
        callback = 'openPanel',
        label    = 'Prison',
        icon     = 'fa-handcuffs',
        perms    = { 'rz.jail' },
    },
    {
        id       = 'rz-reports',
        resource = 'rz_reports',
        callback = 'openPanel',
        label    = 'Reports',
        icon     = 'fa-flag',
        perms    = { 'rz.staff' },
    },
    {
        id       = 'rz-vip',
        resource = 'rz_vip',
        callback = 'openPanel',
        label    = 'VIP',
        icon     = 'fa-crown',
        perms    = { 'rz.vip' },
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  LES GRADES
--
--  Documentaires : les droits réels sont donnés par les add_ace du
--  server.cfg. Ce tableau sert à l'affichage de /grade et à repérer
--  un écart entre ce qui est prévu et ce qui est réellement accordé.
--
--  ─── LE DÉCOUPAGE ──────────────────────────────────────────────
--
--  CONSTRUIRE  établis, recettes, zones, loot, radioactivité.
--              Ça façonne le serveur.  → développeur, admin
--
--  ARBITRER    réanimer, statistiques de tir, prison, reports.
--              Ça règle des situations entre joueurs. → modérateur
--
--  DÉPANNER    colis, coffres, VIP.
--              Ça répare ce qui a mal tourné. → support
-- ═══════════════════════════════════════════════════════════════════
Config.Grades = {
    {
        key   = 'developpeur',
        label = 'Développeur',
        group = 'group.developpeur',
        note  = 'Tout, sans exception. C\'est lui qui construit.',
        perms = {
            'rz_craft.admin', 'rz_safezone.admin', 'rz_coffres.admin',
            'rz_epaves.admin', 'rz_signal.admin', 'rz_radiation.admin',
            'rz_mort.admin',
            'rz.staff', 'rz.props', 'rz.jobcreator', 'rz.jail', 'rz.vip',
            'rz.radiation', 'rz.mort', 'rz.signal.announce',
            'rz.signal.network', 'rz.coffres.give',
            'rz_craft.edit', 'rz_craft.view', 'rz_craft.mail',
            'rz_safezone.edit', 'rz_safezone.view',
        },
    },
    {
        key   = 'admin',
        label = 'Admin',
        group = 'group.admin',
        note  = 'Tout, sauf les réglages de conception qui touchent '
             .. 'l\'équilibrage global.',
        -- rz_epaves et le rayon de la zone radioactive restent chez
        -- le développeur : un curseur bougé un soir change l'économie
        -- sans que personne sache pourquoi.
        perms = {
            'rz_craft.admin', 'rz_safezone.admin', 'rz_coffres.admin',
            'rz_signal.admin', 'rz_mort.admin',
            'rz.staff', 'rz.props', 'rz.jobcreator', 'rz.jail', 'rz.vip',
            'rz.mort', 'rz.signal.announce', 'rz.signal.network',
            'rz.coffres.give',
            'rz_craft.edit', 'rz_craft.view', 'rz_craft.mail',
            'rz_safezone.edit', 'rz_safezone.view',
        },
    },
    {
        key   = 'moderateur',
        label = 'Modérateur',
        group = 'group.moderateur',
        note  = 'Ce qui sert à arbitrer. Rien qui modifie le monde.',
        perms = {
            'rz.mort',              -- relever un joueur bloqué
            'rz_safezone.view',     -- qui tire dans les safe zones
            'rz_craft.view',        -- consulter sans éditer
            'rz.jail',              -- prison
            'rz.staff',             -- reports, diagnostic
            'rz.signal.announce',   -- annoncer, sans couper le courant
        },
    },
    {
        key   = 'support',
        label = 'Support',
        group = 'group.support',
        note  = 'Ce qui sert à dépanner un joueur.',
        perms = {
            'rz.coffres.give',      -- remise après achat Discord
            'rz_craft.mail',        -- colis de compensation
            'rz.staff',             -- reports
            'rz.vip',              -- gestion VIP
        },
    },
}




-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION DEPUIS DISCORD
--
--  Attribue les grades d'après les rôles Discord, à chaque connexion.
--  Plus besoin de toucher au server.cfg quand quelqu'un change de
--  grade : tu déplaces son rôle sur Discord, il se reconnecte, c'est
--  appliqué.
--
--  ─── CE QU'IL FAUT AVANT ───────────────────────────────────────
--
--  1. UN BOT DISCORD dans ton serveur.
--     https://discord.com/developers/applications → New Application
--     → Bot → Reset Token → copier le jeton.
--
--     Dans l'onglet Bot, ACTIVER « Server Members Intent ». Sans
--     lui, l'API refuse de lister les rôles et rien ne fonctionne.
--
--     Inviter le bot : onglet OAuth2 → URL Generator → cocher
--     « bot » → permission « Read Messages/View Channels » suffit.
--
--  2. L'ID DE TON SERVEUR DISCORD.
--     Paramètres Discord → Avancés → Mode développeur, puis clic
--     droit sur ton serveur → Copier l'identifiant.
--
--  3. LES ID DE RÔLES, de la même façon : clic droit sur un rôle
--     dans Paramètres du serveur → Rôles.
--
--  4. LE JOUEUR DOIT AVOIR DISCORD OUVERT en jouant. FiveM ne
--     transmet l'identifiant Discord que si l'application tourne.
--
--  ⚠️  LE JETON EST UN SECRET. Quiconque l'obtient contrôle ton bot.
--  Ajoute ce fichier à ton .gitignore.
-- ═══════════════════════════════════════════════════════════════════
Config.Discord = {
    enabled = false,          -- passe à true une fois configuré

    token   = '',             -- jeton du bot, SANS le préfixe « Bot »
    guildId = '',             -- identifiant de ton serveur Discord

    -- Rôle Discord → grade RedZone.
    -- L'ordre compte : le PREMIER rôle trouvé l'emporte. Place donc
    -- les grades les plus élevés en haut, sinon un développeur qui
    -- porte aussi le rôle support serait traité comme un support.
    roles = {
        { roleId = '', grade = 'developpeur' },
        { roleId = '', grade = 'admin' },
        { roleId = '', grade = 'moderateur' },
        { roleId = '', grade = 'support' },
    },

    -- Durée de validité du cache, en minutes. Évite d'appeler
    -- l'API Discord à chaque reconnexion d'un même joueur.
    cacheMinutes = 15,

    -- Retirer le grade quand le rôle Discord a disparu. À laisser
    -- à true : sinon un ancien modérateur garde ses droits pour
    -- toujours, et personne ne s'en rend compte.
    revokeWhenRemoved = true,

    -- Journaliser chaque attribution dans le salon « admin » de
    -- rz_logs, si la ressource tourne.
    logChanges = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  ACCÈS AU MENU
-- ═══════════════════════════════════════════════════════════════════

-- Comportement des boutons non autorisés :
--   'grise'  → affiché mais inactif, sans message d'erreur
--   'cache'  → absent de la liste
--
-- « grise » a un avantage : le joueur voit ce qui existe et
-- comprend qu'il lui manque un grade, sans qu'on ait à le lui dire.
Config.UnauthorizedStyle = 'grise'

-- Afficher le titre « REDZONE » au-dessus des boutons
Config.ShowSeparator = true


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

function Config.GetGrade(key)
    for _, g in ipairs(Config.Grades) do
        if g.key == key then return g end
    end
    return nil
end
