--[[
    CORRIGÉ POUR REDZONE — 30 août 2026

    ─── TROIS CHANGEMENTS ─────────────────────────────────────────

    1. « @mysql-async/lib/MySQL.lua » → « @oxmysql/lib/MySQL.lua »

       mysql-async est l'ancien système de base de données, remplacé
       par oxmysql. Il n'est pas installé ici, donc la ressource ne
       pouvait pas démarrer.

       Aucune ligne de code n'a eu besoin d'être touchée : oxmysql
       fournit une couche de compatibilité complète — MySQL.ready,
       MySQL.Sync et MySQL.Async y sont tous exposés.

    2. shared_scripts REMONTÉ AVANT server_scripts.

       ⚠️  C'est la correction la plus subtile du lot.

       FiveM charge les scripts dans l'ordre où ils apparaissent
       dans le manifeste. Avec server_scripts déclaré en premier,
       server.lua s'exécutait AVANT config.lua — et trouvait donc
       la table Config vide.

       Le bug existait depuis toujours, mais restait invisible : la
       détection du framework échouait, la branche qb ne s'exécutait
       jamais, et la ligne fautive n'était jamais atteinte. Réparer
       la détection l'a révélé.

       D'où « attempt to index a nil value (global 'Config') » à la
       ligne 53 de server.lua.

    3. Les deux lignes ElectronAC sont commentées.

       L'anticheat ne démarre pas tant que sa licence est verrouillée
       sur une autre IP. Une ressource qui le déclare échoue avec lui.

    ─── LA TABLE SQL ──────────────────────────────────────────────

    Rien à importer : server.lua crée « boombox_songs » tout seul au
    premier démarrage, en version citizenid puisqu'on est sous Qbox.
]]

-- server_script '@ElectronAC/src/include/server.lua'
-- client_script '@ElectronAC/src/include/client.lua'

-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

fx_version "cerulean"
game "gta5"

description 'Wasabi ESX/QB Boombox'
version '2.1.5'

lua54 'yes'

-- EN PREMIER : config.lua doit être chargé avant tout le reste,
-- sinon la table Config n'existe pas encore quand server.lua
-- l'interroge.
shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
    'client/**.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/**.lua'
}

dependencies {
  'xsound',
  'ox_lib'
}
