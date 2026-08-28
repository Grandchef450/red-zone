fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — coffres de sécurité liés au joueur, à durée limitée'
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
    'server/admin.lua',
}

ox_libs {
    'locale',
    'table',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
