fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'Zombies'
author 'Fivecore'
description ''
version '1.5.0'

ui_page 'script/ui/index.html'

files {
	'script/sounds/data/audioexample_sounds.dat54.rel',
	'script/sounds/audiodirectory/fivecore_zombies.awc',

	'script/ui/index.html',
	'script/ui/index.js',
	'script/ui/index.css',
	'script/ui/blood/*.png',
}

data_file 'AUDIO_WAVEPACK' 'script/sounds/audiodirectory'
data_file 'AUDIO_SOUNDDATA' 'script/sounds/data/audioexample_sounds.dat'

shared_scripts {
	'@ox_lib/init.lua'
}

client_scripts {
	'config_client.lua',
	'script/client/Zombie.lua',
	'script/client/Controller.lua',
}

server_scripts {
	'config_server.lua',
	'script/server/Zombie.lua',
	'script/server/Controller.lua',
}

dependencies {
  'ox_lib'
}

escrow_ignore {
  'config_server.lua',
  'config_client.lua'
}
dependency '/assetpacks'