-- A question the player answers with a key while playing on: invitations, searches, handing something over.
-- The keys are key mappings, so players can move them in the FiveM settings.
local current = nil

RegisterCommand('ef_request_accept', function() if current then current('accept') end end, false)
RegisterCommand('ef_request_decline', function() if current then current('decline') end end, false)
RegisterKeyMapping('ef_request_accept', L('Anfrage annehmen'), 'keyboard', Config.RequestKeys.accept)
RegisterKeyMapping('ef_request_decline', L('Anfrage ablehnen'), 'keyboard', Config.RequestKeys.decline)

-- The key the player bound, for the label on the prompt
local function boundKey(command, fallback)
    local key = GetControlInstructionalButton(0, joaat(command) | 0x80000000, true)
    return key and key:match('^t_(.+)$') or fallback
end

--- Ask the player and wait for the answer (blocks current thread). Requests that come in while one is
--- open wait their turn.
--- @param data table { title, message?, icon?, duration? = ms (default 15000), acceptLabel?, declineLabel? }
--- @return boolean accepted
--- @return string answer 'accept', 'decline' or 'timeout'
local function Request(data)
    if type(data) ~= 'table' or type(data.title) ~= 'string' then
        print('^1[EF_LIB] Request: data.title must be a string^0')
        return false, 'timeout'
    end

    while current do Wait(200) end

    local p = promise.new()
    local duration = tonumber(data.duration) or 15000

    current = function(answer)
        current = nil
        SendNUIMessage({ action = 'closeRequest', data = { result = answer } })
        p:resolve(answer)
    end
    local answerThis = current

    SendNUIMessage({
        action = 'openRequest',
        data = {
            title = data.title,
            message = data.message,
            icon = data.icon,
            duration = duration,
            accept = { key = boundKey('ef_request_accept', Config.RequestKeys.accept), label = data.acceptLabel },
            decline = { key = boundKey('ef_request_decline', Config.RequestKeys.decline), label = data.declineLabel },
        }
    })

    SetTimeout(duration, function()
        if current == answerThis then current('timeout') end
    end)

    local answer = Citizen.Await(p)
    return answer == 'accept', answer
end

exports('Request', Request)

-- From the server export Request(source, data)
RegisterNetEvent('ef_lib:request', function(id, data)
    local _, answer = Request(data)
    TriggerServerEvent('ef_lib:requestResult', id, answer)
end)
