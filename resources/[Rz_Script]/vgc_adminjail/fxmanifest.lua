fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'vgc_adminjail'
description 'Prison admin — TP, musique en boucle, compte a rebours, sortie au spawn ville (standalone, sans DB)'
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
