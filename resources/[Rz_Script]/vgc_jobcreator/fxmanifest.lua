fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'vgc_jobcreator'
description 'Generateur de configuration de jobs (standalone, sans DB) — grades, vehicules, blips, boss, stash, vestiaire'
author      'Grandchef'
version     '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
