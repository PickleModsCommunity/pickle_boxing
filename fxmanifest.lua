fx_version 'cerulean'
dependencies { 'ox_lib', 'oxmysql', '/onesync' }
lua54 'yes'
game 'gta5'

name         'pickle_boxing'
version      '1.1.2'
description  'A fight system that has boxing & mma, broadcast-style scenes, and more!'
author       'Pickle Mods'

data_file 'DLC_ITYP_REQUEST' 'v_pfc.ytyp'

ui_page "nui/index.html"

files {
    "nui/index.html",
    "nui/assets/**/*.*",
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'core/shared.lua',
    "locales/*.lua",
    'modules/**/shared.lua',
    'bridge/**/shared.lua',
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
    'bridge/**/server.lua',
    'server_config.lua',
    'core/authority.lua',
    'modules/**/server.lua',
}

client_scripts {
    'core/client.lua',
    'bridge/**/client.lua',
    'modules/**/client.lua',
}

escrow_ignore {
	"config.lua",
	"_INSTALL/**/*.*",
	"bridge/**/**/*.*",
	"bridge/**/*.*",
    "locales/*.lua",

	-- COMMENT BELOW IF NOT SOURCE --

	"modules/**/*.*",
	"core/*.*",
}
dependency '/assetpacks'