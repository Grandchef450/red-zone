fx_version 'bodacious'
game 'gta5'
author 'Dev'
description 'Admin System | https://youtube.com/'
lua54 'yes'

Version '1.0.11'

client_script {
  'Client/*.lua',
}

server_script {
  '@oxmysql/lib/MySQL.lua',
  'Server/*.lua',
}

shared_script {
  '@ox_lib/init.lua',
  'Editable/**/*.lua',
  'Locale/*.lua',
  'Config/Setting.lua',
  'Config/Security.lua',
  'Config/Logs.lua',
  'Bridge.lua'
}

ui_page 'Nui/index.html'

files {
  'Nui/**/*.*'
}