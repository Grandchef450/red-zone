fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Grandchefstream'
description 'Annonce globale de bannissement (ox_lib) avec son de canon'
version '1.1.0'

dependency 'ox_lib'

shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'

-- Le son est joué par une petite page NUI : il doit être déclaré ici
-- pour être accessible en nui://BanNotif/...
ui_page 'html/index.html'

files {
    'html/index.html',
    'zz-hunger-games-cannon.mp3',
}
