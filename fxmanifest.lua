fx_version 'adamant'
game 'gta5'

author 'Crystal2K'
description 'C2K JOB MANAGER by Crystal2K'
version "1.0.0"

server_scripts {
    'config.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

client_scripts {
    'config.lua',
    '@menuv/menuv.lua',
    'client/*.lua',
}

ui_page('ui/index.html')

files {
    'ui/index.html',
    'ui/css/main.css',
    'ui/js/main.js',
}
