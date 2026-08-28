fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'rz_vip'
description 'Systeme VIP complet — 7 grades, peds, vestiaire, reanimations, boutique materiaux, farm (QBCore, JSON, 0 DB)'
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
