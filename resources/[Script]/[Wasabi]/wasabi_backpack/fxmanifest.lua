server_script '@ElectronAC/src/include/server.lua'
client_script '@ElectronAC/src/include/client.lua'




fx_version 'cerulean'
game 'gta5'
lua54 'yes'

version '1.0.4'

client_scripts {
    'client/**.lua'
}

server_scripts {
  'server/**.lua'
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}