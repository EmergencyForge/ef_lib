fx_version 'cerulean'
game 'gta5'

author 'EmergencyForge'
description 'EF Library - Core UI Framework'
version '1.0.0'

lua54 'yes'

ui_page 'web/dist/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/vehicleProperties.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/dist/**/*'
}

escrow_ignore {
    'config.lua',
    'example.lua',
    'DOCUMENTATION.md',
    'fxmanifest.lua',
    'web/dist/**',
}