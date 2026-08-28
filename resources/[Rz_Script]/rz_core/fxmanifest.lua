--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'rz_core'
version      '0.2.0'
license      'GPL-3.0-or-later'
author       'VoightQC / Grandchef'
description  'RedZone Survival — ambiance post-apocalyptique : monde vide et silence total'

--[[ Manifest ]]--
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
}
