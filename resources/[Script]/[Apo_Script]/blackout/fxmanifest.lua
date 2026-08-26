fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Hate Dev'
description 'Blackout System with PolyZones - Compatible with QBCore and ESX'
version '1.1.0'

shared_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

escrow_ignore {
    'config.lua',
}

dependency {
    'PolyZone'
}

dependency '/assetpacks'