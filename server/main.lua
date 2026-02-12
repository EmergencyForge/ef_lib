--[[
    EF Library - Server Side
    Handles server-side events, callbacks, and data management

    Usage from other scripts:
    exports.ef_lib:RegisterCallback('myCallback', function(source, arg1, arg2)
        return true, 'result'
    end)
    exports.ef_lib:SendNotification(source, 'success', 'Title', 'Message', 3000)
]]

-- Resource started
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('[EF_LIB] Server-side initialized (Callbacks, Notifications, Menu)')
end)

-----------------------
-- Callback System
-----------------------

local registeredCallbacks = {}
local callbackOwners = {} -- Track which resource registered each callback

--- Check if a value is callable (function or table with __call metamethod)
--- FiveM wraps functions passed via exports in "funcref" objects (type = 'table')
local function isCallable(fn)
    if type(fn) == 'function' then return true end
    local mt = type(fn) == 'table' and getmetatable(fn)
    return mt and type(mt.__call) == 'function'
end

--- Register a server callback that can be called from the client
--- @param name string Unique callback name (e.g. 'faction_garages:isBoss')
--- @param handler function Handler function receiving (source, ...) and returning results
local function RegisterCallback(name, handler)
    if type(name) ~= 'string' then
        return print('^1[EF_LIB] RegisterCallback: name must be a string^0')
    end
    if not isCallable(handler) then
        return print('^1[EF_LIB] RegisterCallback: handler must be a function (received ' .. type(handler) .. ')^0')
    end

    local invokingResource = GetInvokingResource() or GetCurrentResourceName()

    if registeredCallbacks[name] and callbackOwners[name] ~= invokingResource then
        print(('^3[EF_LIB] Warning: Callback "%s" (owned by "%s") overwritten by "%s"^0'):format(
            name, callbackOwners[name] or 'unknown', invokingResource
        ))
    end

    registeredCallbacks[name] = handler
    callbackOwners[name] = invokingResource
end

--- Unregister a callback
--- @param name string Callback name to remove
local function UnregisterCallback(name)
    registeredCallbacks[name] = nil
    callbackOwners[name] = nil
end

-- Clean up callbacks when a resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then return end

    local removed = 0
    for name, owner in pairs(callbackOwners) do
        if owner == resourceName then
            registeredCallbacks[name] = nil
            callbackOwners[name] = nil
            removed = removed + 1
        end
    end

    if removed > 0 then
        print(('[EF_LIB] Cleaned up %d callback(s) from stopped resource "%s"'):format(removed, resourceName))
    end
end)

-- Handle incoming callback requests from clients
RegisterNetEvent('ef_lib:cb:request', function(callbackName, requestId, ...)
    local src = source

    local handler = registeredCallbacks[callbackName]

    if not handler then
        print(('^1[EF_LIB] Callback "%s" not found (requested by player %s)^0'):format(callbackName, src))
        TriggerClientEvent('ef_lib:cb:response', src, requestId, nil, ('Callback "%s" not registered'):format(callbackName))
        return
    end

    -- pcall to safely execute the handler
    local results = table.pack(pcall(handler, src, ...))
    local success = results[1]

    if success then
        -- Send back all return values (skip the pcall success bool)
        TriggerClientEvent('ef_lib:cb:response', src, requestId, table.unpack(results, 2, results.n))
    else
        local errMsg = tostring(results[2])
        print(('^1[EF_LIB] Callback "%s" error: %s^0'):format(callbackName, errMsg))
        TriggerClientEvent('ef_lib:cb:response', src, requestId, nil, 'Server callback error')
    end
end)

-----------------------
-- Notifications
-----------------------

-- Send notification to a specific player
local function SendNotification(source, type, title, message, duration)
    TriggerClientEvent('ef_lib:notify', source, type, title, message, duration)
end

-- Send notification to all players
local function SendNotificationToAll(type, title, message, duration)
    TriggerClientEvent('ef_lib:notify', -1, type, title, message, duration)
end

-----------------------
-- Menu Control
-----------------------

-- Open menu for a specific player
local function OpenMenuForPlayer(source, menuData)
    TriggerClientEvent('ef_lib:openMenu', source, menuData)
end

-- Close menu for a specific player
local function CloseMenuForPlayer(source)
    TriggerClientEvent('ef_lib:closeMenu', source)
end

-----------------------
-- Exports
-----------------------

-- Callback System
exports('RegisterCallback', RegisterCallback)
exports('UnregisterCallback', UnregisterCallback)

-- Notifications
exports('SendNotification', SendNotification)
exports('SendNotificationToAll', SendNotificationToAll)

-- Menu Control
exports('OpenMenuForPlayer', OpenMenuForPlayer)
exports('CloseMenuForPlayer', CloseMenuForPlayer)

-----------------------
-- Events
-----------------------

RegisterNetEvent('ef_lib:serverMenuAction', function(data)
    local source = source
    print(('[EF_LIB] Player %s triggered action: %s'):format(source, data.action or 'unknown'))
end)
