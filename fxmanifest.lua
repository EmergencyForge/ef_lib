fx_version 'cerulean'
game 'gta5'

author 'EmergencyForge'
description 'EF Library - Core UI Framework'
version '1.0.0'

lua54 'yes'

ui_page 'web/dist/index.html'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'shared/cooldown.lua'
}

client_scripts {
    'client/main.lua',
    'client/cache.lua',
    'client/request.lua',
    'client/vehicleProperties.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/dist/**/*'
}

-- Open source under GPL-3.0: nothing gets encrypted on a Cfx escrow upload
escrow_ignore {
    '*.lua',
    '*.md',
    'client/**',
    'server/**',
    'shared/**',
    'docs/**',
    'web/**',
}