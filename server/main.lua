--[[
    EF Library - Server Side
    Handles server-side events and data management
]]

-- Resource started
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('[EF_LIB] Server-side initialized')
end)

-- Send notification to a specific player
local function SendNotification(source, type, title, message, duration)
    TriggerClientEvent('ef_lib:notify', source, type, title, message, duration)
end

-- Send notification to all players
local function SendNotificationToAll(type, title, message, duration)
    TriggerClientEvent('ef_lib:notify', -1, type, title, message, duration)
end

-- Open menu for a specific player
local function OpenMenuForPlayer(source, menuData)
    TriggerClientEvent('ef_lib:openMenu', source, menuData)
end

-- Close menu for a specific player
local function CloseMenuForPlayer(source)
    TriggerClientEvent('ef_lib:closeMenu', source)
end

-- Exports
exports('SendNotification', SendNotification)
exports('SendNotificationToAll', SendNotificationToAll)
exports('OpenMenuForPlayer', OpenMenuForPlayer)
exports('CloseMenuForPlayer', CloseMenuForPlayer)

-- Example: Handle menu actions from client
RegisterNetEvent('ef_lib:serverMenuAction', function(data)
    local source = source
    print(('[EF_LIB] Player %s triggered action: %s'):format(source, data.action or 'unknown'))
end)
