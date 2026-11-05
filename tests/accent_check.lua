-- The accent colour the NUI reports reaches other resources through an export and an event.
-- From the repo root: lua tests/accent_check.lua

local anything = setmetatable({}, { __call = function() end, __index = function(self) return self end })
setmetatable(_G, { __index = function() return anything end })

local exported, nuiCallbacks, fired = {}, {}, {}

Config = { AccentColor = '#f0500a' }

function exports(name, fn) exported[name] = fn end
function RegisterNUICallback(name, fn) nuiCallbacks[name] = fn end
function TriggerEvent(name, ...)
    if name == 'ef_lib:accentChanged' then fired[#fired + 1] = ... end
end
function CreateThread() end
function GetCurrentResourceName() return 'ef_lib' end

assert(loadfile('client/main.lua'))()

local failed = 0
local function check(label, passed)
    print((passed and 'ok   ' or 'FAIL ') .. label)
    if not passed then failed = failed + 1 end
end

check('before the NUI reports, the config colour holds', exported.GetAccentColor() == '#f0500a')
nuiCallbacks.accentColor({ color = '#3b82f6' }, function() end)
check('the reported colour wins', exported.GetAccentColor() == '#3b82f6')
check('listeners hear about it', fired[1] == '#3b82f6')

nuiCallbacks.accentColor({ color = '#3b82f6' }, function() end)
check('a repeated report stays quiet', #fired == 1)
nuiCallbacks.accentColor({ color = 'red' }, function() end)
check('a malformed colour is ignored', exported.GetAccentColor() == '#3b82f6' and #fired == 1)

if failed > 0 then os.exit(1) end
