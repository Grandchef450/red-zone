fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — apparition des joueurs'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/rescue.lua',
    'client/appearance.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/rescue.lua',
}

ox_libs { 'locale' }

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
}
