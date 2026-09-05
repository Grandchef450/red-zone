--[[
    ElectronAC reste verrouillé sur une autre IP et ne démarre pas
    (ensure ElectronAC est commenté dans server.cfg). Une ressource
    qui référence encore ses fichiers via @ElectronAC/... échoue au
    chargement avec elle — rs_outfitbagv2 ne démarrait donc jamais.

    Décommente les deux lignes le jour où ElectronAC fonctionne.
]]

-- server_script '@ElectronAC/src/include/server.lua'
-- client_script '@ElectronAC/src/include/client.lua'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'


author 'Renovax Scripts | Golden Meow'
description '[FREE] Outfit bag V2'
version '2.0.1'


shared_scripts {
	'@ox_lib/init.lua',
	'config/config.lua',
	'config/language.lua',
}

client_scripts {
	'config/autodetection/cl_autodetection.lua',
	'client/*.lua',
	'config/cl_edit.lua',
}

server_script {
	'server/*.lua',
	'config/autodetection/sv_autodetection.lua',
	'config/sv_edit.lua',
}


dependencies {
	'ox_lib',
	'ox_target'
 }

export 'place'
