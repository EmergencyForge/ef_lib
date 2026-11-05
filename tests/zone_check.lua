-- Zones behind the one polling thread: a stopped resource leaves nothing behind, and a callback
-- that throws ends nothing for the others. From the repo root: lua tests/zone_check.lua

local anything = setmetatable({}, { __call = function() end, __index = function(self) return self end })
setmetatable(_G, { __index = function() return anything end })

local exported, threads, stopHandlers, invoker = {}, {}, {}, nil

local vectorMeta = {}
function vector3(x, y, z) return setmetatable({ x = x, y = y, z = z }, vectorMeta) end
vectorMeta.__sub = function(a, b) return vector3(a.x - b.x, a.y - b.y, a.z - b.z) end
vectorMeta.__len = function(v) return math.sqrt(v.x ^ 2 + v.y ^ 2 + v.z ^ 2) end

function exports(name, fn) exported[name] = fn end
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end
function Wait() coroutine.yield() end
function GetInvokingResource() return invoker end
function GetCurrentResourceName() return 'ef_lib' end
function GetEntityCoords() return vector3(0.0, 0.0, 0.0) end
function AddEventHandler(name, fn)
    if name == 'onResourceStop' then stopHandlers[#stopHandlers + 1] = fn end
end

assert(loadfile('client/main.lua'))()
threads = {}

local function frame()
    local polling = threads[#threads]
    return polling ~= nil and coroutine.resume(polling) and coroutine.status(polling) ~= 'dead'
end

local function stop(resource)
    for _, handler in ipairs(stopHandlers) do handler(resource) end
end

local function zoneOf(resource, inside)
    invoker = resource
    return exported.CreateSphereZone({ coords = { x = 0.0, y = 0.0, z = 0.0 }, radius = 5.0, inside = inside })
end

local failed = 0
local function check(label, passed)
    print((passed and 'ok   ' or 'FAIL ') .. label)
    if not passed then failed = failed + 1 end
end

local garageCalls, otherCalls, garageGone = 0, 0, false

zoneOf('other', function() otherCalls = otherCalls + 1 end)
zoneOf('garage', function()
    if garageGone then error('Execution of function reference in script host failed') end
    garageCalls = garageCalls + 1
end)

frame()
check('zones of two resources are polled', garageCalls == 1 and otherCalls == 1)

stop('garage')
garageGone = true
check('the polling outlives a stopped resource', frame())
check('its zones are gone', garageCalls == 1)
check('the zones of the others stay', otherCalls == 2)

zoneOf('garage', function() garageCalls = garageCalls + 1 end)
frame()
check('the restarted resource gets its zones polled', garageCalls == 2)

zoneOf('broken', function() error('a bug in that resource') end)
check('a callback that throws ends nothing', frame())
check('and the others still run', otherCalls == 4)

print(failed == 0 and 'all checks passed' or (failed .. ' check(s) failed'))
os.exit(failed == 0 and 0 or 1)
