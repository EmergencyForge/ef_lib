-- Kept per calling resource, so two scripts can use the same key without blocking each other
local cooldowns = {}
local writes = 0

local function sweep(now)
    for id, ends in pairs(cooldowns) do
        if ends <= now then cooldowns[id] = nil end
    end
end

--- Start a cooldown, unless it is still running
--- @param key string|number Anything that names the action, e.g. ('rob:%d'):format(source) on the server
--- @param duration number Milliseconds
--- @return boolean free true when it was free and starts now, false while it runs
--- @return number remaining Milliseconds left when not free
local function Cooldown(key, duration)
    local id = (GetInvokingResource() or GetCurrentResourceName()) .. ':' .. tostring(key)
    local now = GetGameTimer()
    local ends = cooldowns[id]
    if ends and ends > now then return false, ends - now end

    cooldowns[id] = now + (tonumber(duration) or 0)
    writes = writes + 1
    if writes % 500 == 0 then sweep(now) end
    return true, 0
end

--- Milliseconds left on a cooldown, 0 when it is free
local function GetCooldown(key)
    local ends = cooldowns[(GetInvokingResource() or GetCurrentResourceName()) .. ':' .. tostring(key)]
    return ends and math.max(0, ends - GetGameTimer()) or 0
end

local function ClearCooldown(key)
    cooldowns[(GetInvokingResource() or GetCurrentResourceName()) .. ':' .. tostring(key)] = nil
end

exports('Cooldown', Cooldown)
exports('GetCooldown', GetCooldown)
exports('ClearCooldown', ClearCooldown)
