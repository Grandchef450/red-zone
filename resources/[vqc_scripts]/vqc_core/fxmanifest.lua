--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'vqc_core'
version      '0.0.1'
license      'GPL-3.0-or-later'
author       'VoightQC'
repository   'https://github.com/'

--[[ Manifest ]]--
shared_scripts {
    --'@ox_lib/init.lua',
    --'@ox_core/lib/init.lua',
	'config.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	--'@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

files {
	'locales/*.json',
}

-- dependencies {
-- 	'oxmysql',
-- 	'ox_lib',
-- }

ox_libs {
    'locale',
    'table',
}