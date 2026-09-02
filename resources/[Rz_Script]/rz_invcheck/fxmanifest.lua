fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — vérification des inventaires joueurs'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ox_libs { 'locale' }

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'oxmysql',
}
