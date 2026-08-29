--[[
    ZSX_Multicharacter — manifeste
    CORRIGÉ POUR REDZONE — 29 août 2026

    DEUX CHANGEMENTS

    1. '@qb-apartments/config.lua' retiré des shared_scripts.
       C'était une dépendance DURE : FiveM refusait de charger la
       ressource entière parce que ce fichier n'existe pas sur ce
       serveur. C'est l'erreur « Failed to load script
       @qb-apartments/config.lua » du log de démarrage.
       Le code lui-même teste GetResourceState('qb-apartments') avant
       de s'en servir, donc l'appartement reste optionnel à
       l'exécution. Seule la référence du manifeste posait problème.

    2. Les deux lignes ElectronAC en tête sont conservées mais
       commentées : l'anticheat ne démarre pas (licence verrouillée
       sur une autre IP), et cette référence empêcherait ZSX de se
       charger tant que ce n'est pas réglé.
       Décommente-les le jour où ElectronAC fonctionne.
]]

-- server_script '@ElectronAC/src/include/server.lua'
-- client_script '@ElectronAC/src/include/client.lua'

fx_version 'cerulean'
game 'gta5'
author '.zeusx#2743'
description 'Multicharacter'
lua54 'yes'

files {
    'client/html/*.html',
    'client/html/css/*.css',
    'client/html/css/ux/*.css',
    'client/html/js/*.js',
    'client/html/js/functions/*.js',
    'client/html/metadata/*.wav',
    'client/html/metadata/*.mp3',
}

ui_page 'client/html/index.html'

shared_scripts {
    'shared/functions/sh_fn.lua',
    'shared/config.lua',
    'shared/config_locations.lua',
    'shared/config_framework.lua',
    'shared/config_usersettings.lua',
    'shared/translations.lua',
    -- '@qb-apartments/config.lua',   ← RETIRÉ : ressource absente
}

client_scripts {
    'client/addons/*.lua',
    'client/algorithms/*.lua',
    'client/framework/*.lua',
    'client/functions/*.lua',
    'client/cl_main.lua',
    'client/cl_baseevents.lua',
    'client/cl_identity.lua',
    'client/cl_worker.lua',
    'client/cl_config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework/*.lua',
    'server/functions/*.lua',
    'server/errortracker/modules/*.lua',
    'server/errortracker/data/*.lua',
    'server/errortracker/*.lua',
    'server/sv_main.lua',
}

escrow_ignore {
    'client/framework/framework_functions.lua',
    'client/cl_baseevents.lua',
    'client/cl_config.lua',
    'client/cl_worker.lua',
    'client/cl_identity.lua',

    'server/framework/framework_functions.lua',
    'server/functions/addon.lua',
    'server/functions/buckets.lua',
    'server/functions/characters.lua',
    'server/functions/migrate.lua',
    'server/errortracker/modules/*.lua',
    'server/errortracker/data/*.lua',

    'shared/config_framework.lua',
    'shared/config_locations.lua',
    'shared/config_usersettings.lua',
    'shared/config.lua',
    'shared/translations.lua',
    'shared/functions/sh_fn.lua',
}

dependency '/assetpacks'
