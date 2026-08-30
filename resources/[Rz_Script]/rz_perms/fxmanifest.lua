fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchef / VoightQC'
description 'RedZone Survival — grades du staff et filtrage du menu admin'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/staff.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/staff.lua',
    'server/discord.lua',
}

ox_libs { 'locale' }

dependencies {
    'ox_lib',
    'oxmysql',
}
