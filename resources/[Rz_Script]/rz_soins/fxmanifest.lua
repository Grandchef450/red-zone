--[[
    rz_soins — soins et virus (RedZone Survival)

    Les objets de soin rendent des points de vie, rien d'autre.
    Les virus donnent un bonus pendant un temps, puis rongent la vie
    jusqu'à l'injection de l'antivirus. Virus et antivirus ne
    s'injectent qu'avec le pistolet injecteur.

    Les valeurs (PV, durées, bonus) sont dans config.lua ; le tableau
    _docs/items_soins_virus.xlsx en est la copie lisible.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'RedZone'
description 'Soins, virus et antivirus'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'qbx_core',
    'rz_mort',
}
