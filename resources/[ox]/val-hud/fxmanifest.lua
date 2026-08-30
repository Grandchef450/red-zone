fx_version 'cerulean'
game 'gta5'

author 'Vallen'

--[[
    CORRIGÉ POUR QBOX — RedZone, 30 août 2026

    LE PROBLÈME
    Le manifeste chargeait '@ox_core/lib/init.lua' dans ses
    shared_script. Ce fichier est lu AU DÉMARRAGE de la ressource,
    avant même que config.lua soit évalué : le réglage
    Config.FrameWork = 'qb' arrivait donc trop tard.

    D'où l'erreur « Failed to load script @ox_core/lib/init.lua »
    une fois ox_core sorti du dossier resources.

    LA CORRECTION
    La ligne est retirée. val-hud lit désormais son config.lua et
    utilise le pont qb-core de Qbox, comme prévu.

    ⚠️  Si tu remets un jour ox_core, il faudra remettre cette ligne
    ET repasser Config.FrameWork sur 'ox'. Les deux vont ensemble.
]]

client_scripts {
    'cl_main.lua',
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    'server.lua'
}

shared_script {
    '@ox_lib/init.lua',
    -- '@ox_core/lib/init.lua',   ← RETIRÉ : ox_core n'est plus utilisé
    'config.lua'
}

ui_page 'nui/ui.html'

files {
    'nui/ui.html',
    'nui/styles.css',
    'nui/script.js',
    'nui/img/*.png'
}

lua54 'yes'

escrow_ignore {
    'config.lua'
}
