--[[
    CORRIGÉ POUR REDZONE — 30 août 2026

    ─── DEUX CHANGEMENTS ──────────────────────────────────────────

    1. « @mysql-async/lib/MySQL.lua » → « @oxmysql/lib/MySQL.lua »

       mysql-async est l'ancien système de base de données, remplacé
       par oxmysql depuis des années. Il n'est pas installé ici, donc
       la ressource ne pouvait pas démarrer.

       Aucune ligne de code n'a eu besoin d'être touchée : oxmysql
       fournit une couche de compatibilité complète — MySQL.ready,
       MySQL.Sync et MySQL.Async y sont tous exposés. Les dix
       requêtes de server.lua fonctionnent telles quelles.

    2. Les deux lignes ElectronAC sont commentées.

       L'anticheat ne démarre pas tant que sa licence est verrouillée
       sur une autre IP. Une ressource qui le déclare échoue avec lui.
       À décommenter le jour où ElectronAC fonctionne.

    ─── LA TABLE SQL ──────────────────────────────────────────────

    Rien à importer : server.lua crée « boombox_songs » tout seul au
    premier démarrage, en version citizenid puisqu'on est sous Qbox.
    Chaque joueur y garde sa propre liste de morceaux.
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

client_scripts {
    'client/**.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/**.lua'
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

dependencies {
  'xsound',
  'ox_lib'
}
