fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — système de craft, troc et boîte aux lettres'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/craft.lua',
    'client/mailbox.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/crafting.lua',
    'server/mailbox.lua',
    'server/admin.lua',
}

files {
    'locales/*.json',
}

ox_libs {
    'locale',
    'table',
    'math',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}
