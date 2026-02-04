--[[
    EF Library - Client Side
    Handles NUI communication, menu state, and server callbacks

    Usage from other scripts:
    exports.ef_lib:OpenMenu({ title = 'My Menu', items = {...} })
    exports.ef_lib:CloseMenu()
    exports.ef_lib:SendNotification('success', 'Title', 'Message', 3000)
    exports.ef_lib:CallbackAwait('myCallback', arg1, arg2)
]]

local isMenuOpen = false
local contextMenuOpen = false
local activeContextCallbacks = {}
local contextNavigated = false
local inputDialogPromise = nil
local alertDialogPromise = nil

-----------------------
-- Callback System
-----------------------

local pendingCallbacks = {}
local callbackCounter = 0
local CALLBACK_TIMEOUT = 30000 -- 30 seconds

-- Response handler: server sends results back here
RegisterNetEvent('ef_lib:cb:response', function(requestId, ...)
    if source == '' then return end -- Security: only accept from server

    local cb = pendingCallbacks[requestId]
    if not cb then return end

    pendingCallbacks[requestId] = nil
    cb(...)
end)

--- Call a server-registered callback and wait for the result (blocks current thread)
--- @param name string Callback name registered on server
--- @param ... any Arguments to pass to the server handler
--- @return ... Results from the server handler
local function CallbackAwait(name, ...)
    if type(name) ~= 'string' then
        print('^1[EF_LIB] CallbackAwait: name must be a string^0')
        return nil
    end

    -- Generate unique request ID
    callbackCounter = callbackCounter + 1
    local requestId = ('%s:%s:%d'):format(name, callbackCounter, math.random(0, 99999))

    local p = promise.new()

    pendingCallbacks[requestId] = function(...)
        p:resolve(table.pack(...))
    end

    -- Fire the request to server
    TriggerServerEvent('ef_lib:cb:request', name, requestId, ...)

    -- Timeout protection
    SetTimeout(CALLBACK_TIMEOUT, function()
        if pendingCallbacks[requestId] then
            pendingCallbacks[requestId] = nil
            print(('^1[EF_LIB] Callback "%s" timed out (ID: %s)^0'):format(name, requestId))
            p:resolve(table.pack(nil, ('Callback "%s" timed out'):format(name)))
        end
    end)

    -- Block this thread until we get a response
    local result = Citizen.Await(p)
    return table.unpack(result, 1, result.n)
end

--- Call a server callback with an async callback function (non-blocking)
--- @param name string Callback name registered on server
--- @param cb function Callback function receiving the results
--- Check if a value is callable (function or FiveM funcref)
local function isCallable(fn)
    if type(fn) == 'function' then return true end
    local mt = type(fn) == 'table' and getmetatable(fn)
    return mt and type(mt.__call) == 'function'
end

--- @param ... any Arguments to pass to the server handler
local function CallbackAsync(name, cb, ...)
    if type(name) ~= 'string' then
        return print('^1[EF_LIB] CallbackAsync: name must be a string^0')
    end
    if not isCallable(cb) then
        return print('^1[EF_LIB] CallbackAsync: cb must be a function^0')
    end

    callbackCounter = callbackCounter + 1
    local requestId = ('%s:%s:%d'):format(name, callbackCounter, math.random(0, 99999))

    pendingCallbacks[requestId] = function(...)
        cb(...)
    end

    TriggerServerEvent('ef_lib:cb:request', name, requestId, ...)

    -- Timeout cleanup
    SetTimeout(CALLBACK_TIMEOUT, function()
        if pendingCallbacks[requestId] then
            pendingCallbacks[requestId] = nil
            print(('^3[EF_LIB] Async callback "%s" timed out, cleaning up^0'):format(name))
        end
    end)
end

-----------------------
-- Zone System
-----------------------

local registeredZones = {}
local zoneIdCounter = 0
local zoneThreadActive = false
local ZONE_CHECK_INTERVAL = 300 -- ms between zone checks (same as ox_lib)

--- Create a sphere zone with enter/exit callbacks
--- @param data table { coords = vector3, radius = number, onEnter? = function(self), onExit? = function(self), inside? = function(self), ... }
--- @return table Zone object with :remove() method
local function CreateSphereZone(data)
    if not data.coords then
        print('^1[EF_LIB] CreateSphereZone: coords is required^0')
        return nil
    end

    zoneIdCounter = zoneIdCounter + 1
    local zoneId = zoneIdCounter

    local zone = {
        id = zoneId,
        coords = type(data.coords) == 'vector3' and data.coords or vector3(data.coords.x or data.coords[1], data.coords.y or data.coords[2], data.coords.z or data.coords[3]),
        radius = tonumber(data.radius) or 2.0,
        onEnter = data.onEnter,
        onExit = data.onExit,
        inside = data.inside,
        isInside = false,
        distance = 0.0,
        data = data.data, -- custom user data
    }

    -- Copy any extra custom properties
    for k, v in pairs(data) do
        if not zone[k] and k ~= 'coords' and k ~= 'radius' and k ~= 'onEnter' and k ~= 'onExit' and k ~= 'inside' and k ~= 'data' then
            zone[k] = v
        end
    end

    function zone:remove()
        registeredZones[self.id] = nil
        if self.isInside and self.onExit then
            self:onExit()
        end
        self.isInside = false
    end

    registeredZones[zoneId] = zone

    -- Start the zone check thread if not already running
    if not zoneThreadActive then
        zoneThreadActive = true
        CreateThread(function()
            while zoneThreadActive do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local hasZones = false

                for id, z in pairs(registeredZones) do
                    hasZones = true
                    local dist = #(playerCoords - z.coords)
                    z.distance = dist

                    if dist < z.radius then
                        -- Player is inside
                        if not z.isInside then
                            z.isInside = true
                            if z.onEnter then
                                z:onEnter()
                            end
                        end
                        if z.inside then
                            z:inside()
                        end
                    else
                        -- Player is outside
                        if z.isInside then
                            z.isInside = false
                            if z.onExit then
                                z:onExit()
                            end
                        end
                    end
                end

                -- Stop thread if no zones registered
                if not hasZones then
                    zoneThreadActive = false
                    break
                end

                Wait(ZONE_CHECK_INTERVAL)
            end
        end)
    end

    return zone
end

--- Create a box zone (simplified - uses sphere check with max dimension as radius)
--- For precise box zones, use ox_lib. This is a convenience wrapper.
--- @param data table { coords = vector3, size = vector3, onEnter?, onExit?, inside? }
--- @return table Zone object with :remove() method
local function CreateBoxZone(data)
    if data.size then
        -- Use the largest dimension as the effective radius
        local s = data.size
        local sx = type(s) == 'vector3' and s.x or (s[1] or 2)
        local sy = type(s) == 'vector3' and s.y or (s[2] or 2)
        local sz = type(s) == 'vector3' and s.z or (s[3] or 2)
        data.radius = math.max(sx, sy, sz) / 2
    end
    return CreateSphereZone(data)
end

-----------------------
-- Request Model
-----------------------

local NativeRequestModel = RequestModel -- Cache native before our function shadows it

--- Request and load a model asynchronously, with timeout
--- @param model string|number Model name or hash
--- @param timeout? number Timeout in ms (default: 10000)
--- @return boolean success Whether the model was loaded successfully
local function RequestModel(model, timeout)
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelValid(model) then
        print(('^1[EF_LIB] RequestModel: Invalid model hash %s^0'):format(model))
        return false
    end

    if HasModelLoaded(model) then
        return true
    end

    NativeRequestModel(model)
    timeout = timeout or 10000
    local startTime = GetGameTimer()

    while not HasModelLoaded(model) do
        if GetGameTimer() - startTime > timeout then
            print(('^1[EF_LIB] RequestModel: Timeout loading model %s^0'):format(model))
            return false
        end
        Wait(10)
    end

    return true
end

local NativeRequestAnimDict = RequestAnimDict -- Cache native

--- Request and load an animation dictionary asynchronously, with timeout
--- @param dict string Animation dictionary name
--- @param timeout? number Timeout in ms (default: 10000)
--- @return boolean success Whether the anim dict was loaded successfully
local function RequestAnimDict(dict, timeout)
    if type(dict) ~= 'string' then
        print('^1[EF_LIB] RequestAnimDict: dict must be a string^0')
        return false
    end

    if HasAnimDictLoaded(dict) then
        return true
    end

    NativeRequestAnimDict(dict)
    timeout = timeout or 10000
    local startTime = GetGameTimer()

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - startTime > timeout then
            print(('^1[EF_LIB] RequestAnimDict: Timeout loading dict %s^0'):format(dict))
            return false
        end
        Wait(10)
    end

    return true
end

-----------------------
-- Core Menu Functions
-----------------------

-- Open the menu (allows player movement while open)
local function OpenMenu(menuData)
    if isMenuOpen then return end

    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        data = menuData or {}
    })
end

-- Close the menu
local function CloseMenu()
    if not isMenuOpen then return end

    isMenuOpen = false
    contextMenuOpen = false
    contextNavigated = false
    activeContextCallbacks = {}

    -- Only remove NUI focus if no dialog is currently open
    if not inputDialogPromise and not alertDialogPromise then
        SetNuiFocus(false, false)
    end

    SendNUIMessage({
        action = 'closeMenu'
    })
end

-- Toggle menu visibility (legacy support)
local function ToggleMenu(show)
    isMenuOpen = show
    SetNuiFocus(show, show)
    SendNUIMessage({
        action = 'setVisible',
        data = show
    })
end

-----------------------
-- Notifications
-----------------------

-- Send notification to UI
local function SendNotification(type, title, message, duration)
    SendNUIMessage({
        action = 'notification',
        data = {
            type = type or 'info',
            title = title or '',
            message = message or '',
            duration = duration or 5000
        }
    })
end

-----------------------
-- UI Config
-----------------------

-- Set UI config (accent color etc.)
local function SetConfig(config)
    SendNUIMessage({
        action = 'setConfig',
        data = config or {}
    })
end

-- Set accent color (hex code, e.g. "#ff0000")
local function SetAccentColor(hexColor)
    SetConfig({ accentColor = hexColor })
end

-----------------------
-- Button Hints
-----------------------

-- Show a button hint (key, label, optional id for multiple hints)
local function ShowHint(key, label, id, icon)
    SendNUIMessage({
        action = 'showHint',
        data = {
            key = key or '',
            label = label,
            id = id,
            icon = icon
        }
    })
end

-- Hide a specific hint by id, or all hints if no id provided
local function HideHint(id)
    SendNUIMessage({
        action = 'hideHint',
        data = { id = id }
    })
end

-- Hide all hints
local function HideAllHints()
    SendNUIMessage({
        action = 'hideAllHints'
    })
end

-----------------------
-- UI Settings Submenu
-----------------------

-- Get the built-in UI Settings submenu (for including in your menus)
local function GetUISettingsMenu()
    return {
        id = '_ui_settings',
        label = 'UI Settings',
        description = 'Menu position & color',
        submenu = {
            title = 'UI Settings',
            items = {
                { id = '_settings_position', label = 'Menu Position', type = 'select', value = 'left', options = { 'left', 'center', 'right' } },
                { id = '_settings_color', label = 'Accent Color', type = 'input', value = '#3b82f6', placeholder = '#ff0000' },
                {
                    id = '_settings_notifications',
                    label = 'Notifications',
                    description = 'Notification settings',
                    submenu = {
                        title = 'Notification Settings',
                        items = {
                            { id = '_settings_notif_position', label = 'Position', type = 'select', value = 'top-right', options = { 'top-right', 'top-left', 'bottom-right', 'bottom-left' } },
                            { id = '_settings_notif_test', label = 'Test Notification', description = 'Send a test notification' }
                        }
                    }
                },
                {
                    id = '_settings_reset',
                    label = 'Reset to Defaults',
                    description = 'Restore default settings',
                    confirm = {
                        title = 'Reset Settings?',
                        message = 'Reset all UI settings to defaults',
                        confirmLabel = 'Yes, Reset',
                        cancelLabel = 'Cancel'
                    }
                }
            }
        }
    }
end

-----------------------
-- NUI Callbacks
-----------------------

RegisterNUICallback('closeMenu', function(data, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('setKeyboardFocus', function(data, cb)
    -- Menu now always has full NUI focus, this is a no-op
    cb('ok')
end)

RegisterNUICallback('nuiReady', function(data, cb)
    print('[EF_LIB] NUI is ready')
    SetConfig({ accentColor = Config.AccentColor })
    cb('ok')
end)

-----------------------
-- Menu Controls Thread
-----------------------

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            -- Disable pause menu
            DisableControlAction(0, 200, true)

            -- ESC - Close menu
            if IsDisabledControlJustPressed(0, 200) then
                CloseMenu()
            end

            -- Arrow Up - Navigate up
            if IsControlJustPressed(0, 172) then
                SendNUIMessage({ action = 'navigate', data = 'up' })
            end

            -- Arrow Down - Navigate down
            if IsControlJustPressed(0, 173) then
                SendNUIMessage({ action = 'navigate', data = 'down' })
            end

            -- Enter - Select item
            if IsControlJustPressed(0, 191) then
                SendNUIMessage({ action = 'navigate', data = 'select' })
            end

            -- Backspace - Close menu
            if IsControlJustPressed(0, 177) then
                SendNUIMessage({ action = 'navigate', data = 'close' })
            end

            -- Arrow Right - Select/Enter submenu
            if IsControlJustPressed(0, 175) then
                SendNUIMessage({ action = 'navigate', data = 'select' })
            end
        end
    end
end)

-----------------------
-- Context Menu (ox_lib Compatibility)
-----------------------
-- Provides registerContext/showContext pattern for easy migration from ox_lib.
-- Stores onSelect callbacks and routes menuAction events to them.

local registeredContexts = {}

--- Register a context menu (ox_lib compatible)
--- @param data table { id = string, title = string, options = { { title, description?, icon?, iconColor?, disabled?, onSelect? } } }
local function RegisterContext(data)
    if not data or not data.id then
        print('^1[EF_LIB] RegisterContext: id is required^0')
        return
    end
    registeredContexts[data.id] = data
end

--- Show a previously registered context menu
--- @param id string The context menu ID
local function ShowContext(id)
    local ctx = registeredContexts[id]
    if not ctx then
        print(('^1[EF_LIB] ShowContext: Context "%s" not registered^0'):format(tostring(id)))
        return
    end

    -- Map ox_lib options → ef_lib items and store callbacks
    -- Don't clear activeContextCallbacks - keep previous callbacks alive for goBack
    local items = {}

    for i, opt in ipairs(ctx.options or {}) do
        local itemId = ('ctx_%s_%d'):format(id, i)

        items[#items + 1] = {
            id = itemId,
            label = opt.title or opt.label or '',
            description = opt.description,
            icon = opt.icon,
            iconColor = opt.iconColor,
            disabled = opt.disabled,
            readonly = opt.readonly,
        }

        if opt.onSelect then
            activeContextCallbacks[itemId] = opt.onSelect
        end
    end

    local menuData = {
        title = ctx.title or 'Menu',
        items = items
    }

    if isMenuOpen then
        -- Push as submenu → preserves history for ArrowLeft goBack
        contextNavigated = true
        SendNUIMessage({
            action = 'pushSubmenu',
            data = menuData
        })
    else
        -- Open fresh menu
        isMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openMenu',
            data = menuData
        })
    end
    contextMenuOpen = true
end

--- Shortcut: register + show in one call
--- @param data table Same as RegisterContext
local function ContextMenu(data)
    RegisterContext(data)
    ShowContext(data.id)
end

-- Route menuAction events to stored onSelect callbacks

RegisterNUICallback('menuAction', function(data, cb)
    cb('ok')

    -- Fire the generic event for non-context usage
    TriggerEvent('ef_lib:menuAction', data)

    -- Check if this is a context menu item with stored callback
    if contextMenuOpen and data.id and activeContextCallbacks[data.id] then
        local callback = activeContextCallbacks[data.id]
        contextNavigated = false

        -- Run callback (may be blocking if it opens a dialog)
        CreateThread(function()
            callback(data)
        end)

        -- Parallel: auto-close if onSelect didn't push a new context
        CreateThread(function()
            Wait(100)
            if not contextNavigated and isMenuOpen and contextMenuOpen then
                CloseMenu()
            end
        end)
    end
end)

-----------------------
-- Demo Menu (Optional)
-----------------------

if Config.EnableDemo then
    RegisterCommand('efmenu', function()
        if isMenuOpen then
            CloseMenu()
        else
            OpenMenu({
                title = 'EF Library Demo',
                items = {
                    { id = 'demo_button', label = 'Button Example', description = 'A simple button' },
                    { id = 'demo_checkbox', label = 'Checkbox Example', type = 'checkbox', checked = true },
                    { id = 'demo_input', label = 'Input Example', type = 'input', placeholder = 'Type here...' },
                    { id = 'demo_select', label = 'Select Example', type = 'select', value = 'option1', options = { 'option1', 'option2', 'option3' } },
                    {
                        id = 'demo_submenu',
                        label = 'Submenu Example',
                        description = 'Open a submenu',
                        submenu = {
                            title = 'Submenu',
                            items = {
                                { id = 'sub_item1', label = 'Submenu Item 1' },
                                { id = 'sub_item2', label = 'Submenu Item 2' },
                                { id = 'sub_back', label = 'Go Back', description = 'Return to main menu' }
                            }
                        }
                    },
                    {
                        id = 'demo_confirm',
                        label = 'Confirm Example',
                        description = 'Action with confirmation',
                        confirm = true
                    },
                    GetUISettingsMenu(),
                }
            })
        end
    end, false)

    RegisterKeyMapping('efmenu', 'Open EF Demo Menu', 'keyboard', Config.MenuKey)

    -- Demo event handler
    AddEventHandler('ef_lib:menuAction', function(data)
        if data.id == 'demo_button' then
            SendNotification('success', 'Button Clicked', 'You clicked the demo button!', 3000)
        elseif data.id == 'demo_confirm' then
            SendNotification('warning', 'Confirmed', 'Action was confirmed!', 3000)
        end
    end)
end

-----------------------
-- Input Dialog System
-----------------------

--- Open a multi-field input dialog and wait for user input
--- @param title string Dialog title
--- @param fields table Array of field definitions: { type, label, description?, placeholder?, required?, default?, min?, max?, step?, checked?, options? }
---   type: 'input' | 'number' | 'checkbox' | 'select' | 'slider' | 'textarea'
--- @return table|nil Array of values in field order, or nil if cancelled
local function InputDialog(title, fields)
    if inputDialogPromise then
        print('^3[EF_LIB] InputDialog: Another dialog is already open^0')
        return nil
    end

    if type(title) ~= 'string' then
        print('^1[EF_LIB] InputDialog: title must be a string^0')
        return nil
    end
    if type(fields) ~= 'table' then
        print('^1[EF_LIB] InputDialog: fields must be a table^0')
        return nil
    end

    inputDialogPromise = promise.new()

    -- Enable NUI cursor focus for the dialog
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openInputDialog',
        data = {
            title = title,
            fields = fields
        }
    })

    -- Block until user confirms or cancels
    local result = Citizen.Await(inputDialogPromise)
    inputDialogPromise = nil

    -- Restore focus: if menu is open keep cursor, otherwise release
    if isMenuOpen then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end

    return result
end

-- NUI Callback: receives result from InputDialog Vue component
RegisterNUICallback('inputDialogResult', function(data, cb)
    if inputDialogPromise then
        inputDialogPromise:resolve(data.values) -- values = array or nil
    end
    cb('ok')
end)

-----------------------
-- Alert Dialog System
-----------------------

--- Open a confirmation/alert dialog and wait for user response
--- @param data table Dialog config: { header, content?, centered?, cancel?, confirmLabel?, cancelLabel? }
--- @return string 'confirm' or 'cancel'
local function AlertDialog(data)
    if alertDialogPromise then
        print('^3[EF_LIB] AlertDialog: Another dialog is already open^0')
        return 'cancel'
    end

    if type(data) ~= 'table' then
        print('^1[EF_LIB] AlertDialog: data must be a table^0')
        return 'cancel'
    end

    alertDialogPromise = promise.new()

    -- Enable NUI cursor focus for the dialog
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openAlertDialog',
        data = data
    })

    -- Block until user confirms or cancels
    local result = Citizen.Await(alertDialogPromise)
    alertDialogPromise = nil

    -- Restore focus: if menu is open keep cursor, otherwise release
    if isMenuOpen then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end

    return result
end

-- NUI Callback: receives result from AlertDialog Vue component
RegisterNUICallback('alertDialogResult', function(data, cb)
    if alertDialogPromise then
        alertDialogPromise:resolve(data.result) -- 'confirm' or 'cancel'
    end
    cb('ok')
end)

-----------------------
-- Exports
-----------------------

-- Callback System
exports('CallbackAwait', CallbackAwait)
exports('CallbackAsync', CallbackAsync)

-- Menu System
exports('OpenMenu', OpenMenu)
exports('CloseMenu', CloseMenu)
exports('ToggleMenu', ToggleMenu)
exports('IsMenuOpen', function() return isMenuOpen end)
exports('GetUISettingsMenu', GetUISettingsMenu)

-- Notifications
exports('SendNotification', SendNotification)

-- UI Config
exports('SetConfig', SetConfig)
exports('SetAccentColor', SetAccentColor)

-- Button Hints
exports('ShowHint', ShowHint)
exports('HideHint', HideHint)
exports('HideAllHints', HideAllHints)

-- Dialogs
exports('InputDialog', InputDialog)
exports('AlertDialog', AlertDialog)

-- Context Menu (ox_lib Compatibility)
exports('RegisterContext', RegisterContext)
exports('ShowContext', ShowContext)
exports('ContextMenu', ContextMenu)

-- Zone System
exports('CreateSphereZone', CreateSphereZone)
exports('CreateBoxZone', CreateBoxZone)

-- Utilities
exports('RequestModel', RequestModel)
exports('RequestAnimDict', RequestAnimDict)

-----------------------
-- Events
-----------------------

RegisterNetEvent('ef_lib:openMenu', OpenMenu)
RegisterNetEvent('ef_lib:closeMenu', CloseMenu)
RegisterNetEvent('ef_lib:notify', function(type, title, message, duration)
    SendNotification(type, title, message, duration)
end)
RegisterNetEvent('ef_lib:showHint', function(key, label, id, icon)
    ShowHint(key, label, id, icon)
end)
RegisterNetEvent('ef_lib:hideHint', function(id)
    HideHint(id)
end)
RegisterNetEvent('ef_lib:hideAllHints', HideAllHints)
