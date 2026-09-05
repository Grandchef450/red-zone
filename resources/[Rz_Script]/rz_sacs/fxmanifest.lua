fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — usure des sacs à dos à l usage'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }

ox_libs { 'table' }

dependencies {
    'ox_lib',
    'ox_inventory',
}
