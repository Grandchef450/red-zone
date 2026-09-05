--[[
    Remplace wasabi_boombox : cette dernière plantait au démarrage
    (SCRIPT ERROR server.lua:52, « Config » nil) parce que son
    config.lua et tout son dossier client/ ont disparu du disque —
    il ne restait que fxmanifest.lua et server/server.lua.

    Comme il s'agit d'une ressource payante (Wasabi Scripts), le code
    d'origine ne pouvait pas être reconstitué. rz_boombox est une
    réécriture maison qui vise le même résultat en jeu (poser une
    radio, y jouer un lien, sons favoris) avec les briques déjà
    présentes sur ce serveur : ox_target, xsound, ox_inventory.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'RedZone'
description 'Boombox posable — remplace wasabi_boombox'
version '1.0.0'

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

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'xsound',
    'oxmysql',
    'qbx_core',
}
