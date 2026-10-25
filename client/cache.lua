-- Values scripts keep asking for, refreshed every 100 ms. A change fires
-- AddEventHandler('ef_lib:cache', function(key, value, old) end), which is the cheap way to react to
-- getting into a vehicle or drawing a weapon. GetCache is an export call, so per-frame code should
-- call the native instead.
local cache = {}

local function set(key, value)
    local old = cache[key]
    if value == old then return end
    cache[key] = value
    TriggerEvent('ef_lib:cache', key, value, old)
end

local function seatOf(ped, vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end
    return false
end

CreateThread(function()
    local unarmed = joaat('WEAPON_UNARMED')
    while true do
        local playerId = PlayerId()
        local ped = PlayerPedId()
        set('playerId', playerId)
        set('serverId', GetPlayerServerId(playerId))
        set('ped', ped)

        -- false instead of nil, so the key stays in the table and the event carries a value
        local vehicle = GetVehiclePedIsIn(ped, false)
        set('vehicle', vehicle ~= 0 and vehicle or false)
        set('seat', vehicle ~= 0 and seatOf(ped, vehicle) or false)

        local _, weapon = GetCurrentPedWeapon(ped, true)
        set('weapon', weapon ~= unarmed and weapon or false)

        Wait(100)
    end
end)

--- @param key? string playerId, serverId, ped, vehicle, seat or weapon; without a key the whole table
exports('GetCache', function(key)
    if key then return cache[key] end
    return cache
end)
