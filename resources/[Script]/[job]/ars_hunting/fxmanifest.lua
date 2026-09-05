--#--
--Fx info--
--#--
fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
version '1.0.0'
author 'Arius Scripts'


--#--
--Manifest--
--#--

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',

}

client_scripts {
    'client/modules/utils.lua',
    'client/missions.lua',
    'client/hunting.lua',
    'client/campfire.lua',
    'client/shops.lua',
    'client/aimblock.lua',
}

server_scripts {
    'server/bridge/qb.lua',   -- Qbox, via son pont « qb-core »
    'server/*.lua',
}

files {
    "locales/*.json",
    "_icons/*.png",
}
