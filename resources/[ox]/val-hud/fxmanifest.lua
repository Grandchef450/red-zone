fx_version 'cerulean'
game 'gta5'

author 'Vallen'

client_scripts {
    'cl_main.lua',
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    'server.lua'
}

shared_script {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
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