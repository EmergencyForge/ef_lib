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

-- Event banner for one player, or everyone with -1
local function Banner(source, data)
    TriggerClientEvent('ef_lib:banner', source, data)
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
-- Requests
-----------------------

local pendingRequests = {}
local requestCounter = 0

--- Ask a player and wait for the answer (blocks current thread). Shown with the accept and decline keys,
--- the player keeps control meanwhile. See client/request.lua for the fields of data.
--- @return boolean accepted
--- @return string answer 'accept', 'decline' or 'timeout'
local function Request(source, data)
    requestCounter = requestCounter + 1
    local id = requestCounter
    local p = promise.new()
    pendingRequests[id] = { source = tonumber(source), promise = p }
    TriggerClientEvent('ef_lib:request', source, id, data)

    -- The client times out on its own. This one is for players who leave or have other requests queued first.
    SetTimeout((tonumber(data and data.duration) or 15000) + 60000, function()
        if pendingRequests[id] then
            pendingRequests[id] = nil
            p:resolve('timeout')
        end
    end)

    local answer = Citizen.Await(p)
    return answer == 'accept', answer
end

RegisterNetEvent('ef_lib:requestResult', function(id, answer)
    local pending = pendingRequests[id]
    if not pending or pending.source ~= source then return end
    pendingRequests[id] = nil
    pending.promise:resolve((answer == 'accept' or answer == 'decline') and answer or 'timeout')
end)

AddEventHandler('playerDropped', function()
    local src = source
    for id, pending in pairs(pendingRequests) do
        if pending.source == src then
            pendingRequests[id] = nil
            pending.promise:resolve('timeout')
        end
    end
end)

-----------------------
-- Version Check
-----------------------

local VERSION_URL = 'https://emergencyforge.de/api/versions/%s'
local BANNER_WIDTH = 82
local BANNER = {
    "^1  ______                                               ^0______                      ",
    "^1 |  ____|                                             ^0|  ____|                     ",
    "^1 | |__   _ __ ___   ___ _ __ __ _  ___ _ __   ___ _   _^0| |__ ___  _ __ __ _  ___   ",
    "^1 |  __| | '_ ` _ \\ / _ \\ '__/ _` |/ _ \\ '_ \\ / __| | | ^0|  __/ _ \\| '__/ _` |/ _ \\  ",
    "^1 | |____| | | | | |  __/ | | (_| |  __/ | | | (__| |_| ^0| | | (_) | | | (_| |  __/  ",
    "^1 |______|_| |_| |_|\\___|_|  \\__, |\\___|_| |_|\\___|\\__, ^0|_|  \\___/|_|  \\__, |\\___|  ",
    "^1                            __/ |                 __/ ^0|               __/ |       ",
    "^1                           |___/                 |___/ ^0               |___/        ",
}

local function rightAlign(text, color)
    local width = #text:gsub('%^%d', '')
    return color .. string.rep(' ', math.max(0, BANNER_WIDTH - width)) .. text .. '^0'
end

local function versionNumber(version)
    local major, minor, patch = tostring(version):match('(%d+)%.?(%d*)%.?(%d*)')
    return (tonumber(major) or 0) * 1000000 + (tonumber(minor) or 0) * 1000 + (tonumber(patch) or 0)
end

--- Print the EmergencyForge banner for the calling resource and say in the console when a newer release exists.
--- The current version is the one in the caller's fxmanifest.lua.
--- @param label? string Name in the banner (default: the resource name)
--- @param repo? string Name on emergencyforge.de/api/versions, when the resource folder is named differently
local function CheckVersion(label, repo)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local current = GetResourceMetadata(resource, 'version', 0) or '0.0.0'

    print('')
    for _, line in ipairs(BANNER) do print(line) end
    print(rightAlign((label or resource) .. ' ^3v' .. current, '^0'))
    print('')

    PerformHttpRequest(VERSION_URL:format(repo or resource), function(status, body)
        if status ~= 200 or not body then return end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' or not data.version then return end
        if versionNumber(data.version) > versionNumber(current) then
            print(('^2[%s] %s^0'):format(resource, L('Neue Version verfügbar: v%s (%s)', data.version, data.commit or '?')))
            if data.url then print(('^2[%s] %s^0'):format(resource, data.url)) end
        end
    end, 'GET', '', { ['User-Agent'] = 'ef_lib/' .. resource })
end

-----------------------
-- Exports
-----------------------

-- Version Check
exports('CheckVersion', CheckVersion)

-- Requests
exports('Request', Request)

-- Callback System
exports('RegisterCallback', RegisterCallback)
exports('UnregisterCallback', UnregisterCallback)

-- Notifications
exports('SendNotification', SendNotification)
exports('SendNotificationToAll', SendNotificationToAll)
exports('Banner', Banner)

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
