fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — fouille des épaves de décor'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/admin.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/admin.lua',
}

ox_libs { 'table' }

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}
