-- Runs CallbackAwait the way a resource meets it: behind an export, which hands back only
-- what stands before the first nil. From the repo root: lua tests/callback_check.lua

local anything = setmetatable({}, { __call = function() end, __index = function(self) return self end })
setmetatable(_G, { __index = function() return anything end })

local exported, onResponse, answer = {}, nil, nil

function exports(name, fn) exported[name] = fn end

function RegisterNetEvent(name, fn)
    if name == 'ef_lib:cb:response' then onResponse = fn end
end

function TriggerServerEvent(_, _, requestId)
    if answer then onResponse(requestId, table.unpack(answer, 1, answer.n)) end
end

function SetTimeout(_, fn) fn() end

source = 1
promise = { new = function() return { resolve = function(self, value) self.value = value end } end }
Citizen = setmetatable({ Await = function(p) return p.value end }, { __index = anything })

assert(loadfile('client/main.lua'))()

local function overExport()
    local results = table.pack(exported.CallbackAwait('test'))
    local kept = {}
    for index = 1, results.n do
        if results[index] == nil then break end
        kept[index] = results[index]
    end
    return kept
end

local function expect(label, wanted, ...)
    answer = wanted and table.pack(...)
    local got = overExport()
    local shown = {}
    for index, value in ipairs(got) do shown[index] = tostring(value) end
    assert(table.concat(shown, ' ') == label, ('wanted %q, got %q'):format(label, table.concat(shown, ' ')))
end

expect('false nope', true, nil, 'nope')
expect('true false data', true, true, nil, 'data')
expect('false false data', true, nil, nil, 'data')
expect('true fine', true, true, 'fine')
expect('', true, nil)
expect('', true, nil, nil)
expect('false Callback "test" timed out', false)

print('all checks passed')
