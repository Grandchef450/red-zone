fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'hate'
description 'hate-pager'
version '1.0.0'

ui_page "html/index.html"

files {
    'html/index.html',
    'html/script.js',
    'html/style.css', -- styles.css yerine style.css
    'html/pager.png',
}

shared_scripts {
	'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {'client.lua'}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Add MySQL dependency
    'server.lua'
}

escrow_ignore {
    'config.lua',
}
dependency '/assetpacks'