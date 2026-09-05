fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — journalisation Discord centralisée'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/main.lua',
    'server/hooks.lua',
}

ox_libs { 'table' }

dependencies {
    'ox_lib',
}
