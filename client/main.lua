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
local menuHasCursor = true
local menuAllowMove = true
local contextMenuOpen = false
local activeContextCallbacks = {}
local contextNavigated = false
local inputDialogPromise = nil
local alertDialogPromise = nil
local minigamePromise = nil

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

-- Open the menu
-- menuData.showCursor (boolean, optional) — overrides Config.ShowCursor per-menu
-- menuData.allowMove (boolean, optional) — overrides Config.AllowMove per-menu
local function OpenMenu(menuData)
    if isMenuOpen then return end

    isMenuOpen = true
    local showCursor = menuData and menuData.showCursor
    if showCursor == nil then
        showCursor = Config.ShowCursor ~= false
    end
    menuHasCursor = showCursor

    local allowMove = menuData and menuData.allowMove
    if allowMove == nil then
        allowMove = Config.AllowMove ~= false
    end
    menuAllowMove = allowMove

    SetNuiFocus(true, menuHasCursor)
    SetNuiFocusKeepInput(menuAllowMove)
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
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'closeMenu'
    })

    -- Notify listeners that the menu was closed
    TriggerEvent('ef_lib:menuClosed')
end

-- Toggle menu visibility (legacy support)
local function ToggleMenu(show)
    isMenuOpen = show
    SetNuiFocus(show, show and menuHasCursor)
    SetNuiFocusKeepInput(show and menuAllowMove)
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
local function SetHintPosition(position)
    SendNUIMessage({
        action = 'setHintPosition',
        data = { position = position or 'bottom-center' }
    })
end

local function ShowHint(key, label, id, icon, position)
    if position then
        SetHintPosition(position)
    end
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

-- Hide all hints (also resets position to default)
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
    if data.enabled then
        -- Enable cursor so the user can type in input fields
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false) -- Disable keepInput while typing
    else
        -- Restore the menu's cursor/movement preferences
        SetNuiFocus(true, menuHasCursor)
        SetNuiFocusKeepInput(menuAllowMove)
    end
    cb('ok')
end)

RegisterNUICallback('keyPress', function(data, cb)
    TriggerEvent('ef_lib:keyPress', data.key)
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

            -- ESC - Close menu (always handle to prevent pause menu)
            if IsDisabledControlJustPressed(0, 200) then
                CloseMenu()
            end

            -- When allowMove is true, NUI keyboard handler already processes
            -- arrow keys / enter / backspace directly — skip game-side navigation
            -- to avoid double-step (both NUI and game firing the same action).
            if not menuAllowMove then
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

    -- Exclusive NUI keyboard focus: no game-input leak into other resources' keybinds
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

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

    -- Restore focus: if menu is open restore its cursor/keepInput state, otherwise release
    if isMenuOpen then
        SetNuiFocus(true, menuHasCursor)
        SetNuiFocusKeepInput(menuAllowMove)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
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

    -- Exclusive NUI keyboard focus: no game-input leak into other resources' keybinds
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'openAlertDialog',
        data = data
    })

    -- Block until user confirms or cancels
    local result = Citizen.Await(alertDialogPromise)
    alertDialogPromise = nil

    -- Restore focus: if menu is open restore its cursor/keepInput state, otherwise release
    if isMenuOpen then
        SetNuiFocus(true, menuHasCursor)
        SetNuiFocusKeepInput(menuAllowMove)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
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
-- Minigame System
-----------------------

--- Open a minigame and wait for the result (blocks current thread)
--- @param gameType string 'lockpick' | 'safedial' | 'reactionchain'
--- @param difficulty? string 'easy' | 'medium' | 'hard' | 'extreme' (default: 'medium')
--- @param retries? number Custom number of retries (overrides difficulty default)
--- @return boolean success Whether the player completed the minigame
local function Minigame(gameType, difficulty, retries)
    if minigamePromise then
        print('^3[EF_LIB] Minigame: Another minigame is already open^0')
        return false
    end

    if type(gameType) ~= 'string' then
        print('^1[EF_LIB] Minigame: gameType must be a string^0')
        return false
    end

    local validTypes = { lockpick = true, safedial = true, reactionchain = true }
    if not validTypes[gameType] then
        print('^1[EF_LIB] Minigame: Invalid gameType "' .. tostring(gameType) .. '". Use: lockpick, safedial, reactionchain^0')
        return false
    end

    minigamePromise = promise.new()

    -- Exclusive NUI keyboard focus: no game-input leak into other resources' keybinds
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'openMinigame',
        data = {
            type = gameType,
            difficulty = difficulty or 'medium',
            retries = retries or nil,
        }
    })

    local result = Citizen.Await(minigamePromise)
    minigamePromise = nil

    if isMenuOpen then
        SetNuiFocus(true, menuHasCursor)
        SetNuiFocusKeepInput(menuAllowMove)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    return result == true
end

-- NUI Callback: receives result from Minigame Vue component
RegisterNUICallback('minigameResult', function(data, cb)
    if minigamePromise then
        minigamePromise:resolve(data.success == true)
    end
    cb('ok')
end)

-----------------------
-- ProgressBar System
-----------------------

local progressBarPromise = nil
local progressBarActive = false

--- Open a progressbar that blocks the current thread until completed or cancelled
--- @param data table ProgressBar config:
---   label: string          - Text to display
---   duration: number       - Duration in ms
---   icon?: string          - FontAwesome icon (e.g. 'fa-wrench', 'fa-solid fa-heart')
---   canCancel?: boolean    - Allow cancellation (default: false)
---   cancelKey?: string     - Key name for cancel (default: 'X' / INPUT_VEH_DUCK)
---   anim?: table           - Animation { dict: string, clip: string, flag?: number, blendIn?: number, blendOut?: number }
---   prop?: table           - Prop to attach { model: string, bone?: number, pos?: vec3, rot?: vec3 }
---   disableControls?: table - { move?: bool, car?: bool, combat?: bool, mouse?: bool } (default: all false)
--- @return boolean completed  true = finished, false = cancelled
local function ProgressBar(data)
    if progressBarPromise then
        print('^3[EF_LIB] ProgressBar: Another progressbar is already active^0')
        return false
    end

    if type(data) ~= 'table' then
        print('^1[EF_LIB] ProgressBar: data must be a table^0')
        return false
    end

    if not data.duration or data.duration <= 0 then
        print('^1[EF_LIB] ProgressBar: duration must be > 0^0')
        return false
    end

    progressBarPromise = promise.new()
    progressBarActive = true

    local ped = PlayerPedId()
    local duration = data.duration
    local canCancel = data.canCancel == true
    local disableControls = data.disableControls or {}
    local propEntity = nil

    -- Start animation if specified
    if data.anim and data.anim.dict and data.anim.clip then
        if RequestAnimDict(data.anim.dict) then
            TaskPlayAnim(
                ped,
                data.anim.dict,
                data.anim.clip,
                data.anim.blendIn or 3.0,
                data.anim.blendOut or 1.0,
                -1,
                data.anim.flag or 49,
                0, false, false, false
            )
        end
    end

    -- Attach prop if specified
    if data.prop and data.prop.model then
        local modelHash = type(data.prop.model) == 'string' and joaat(data.prop.model) or data.prop.model
        if RequestModel(modelHash) then
            local pos = data.prop.pos or vector3(0.0, 0.0, 0.0)
            local rot = data.prop.rot or vector3(0.0, 0.0, 0.0)
            local bone = data.prop.bone or 60309 -- SKEL_R_Hand

            propEntity = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, true)
            AttachEntityToEntity(
                propEntity, ped,
                GetPedBoneIndex(ped, bone),
                pos.x, pos.y, pos.z,
                rot.x, rot.y, rot.z,
                true, true, false, true, 0, true
            )
            SetModelAsNoLongerNeeded(modelHash)
        end
    end

    -- Send to NUI
    SendNUIMessage({
        action = 'startProgressBar',
        data = {
            label = data.label or '',
            duration = duration,
            icon = data.icon,
            canCancel = canCancel,
            cancelKey = data.cancelKey or 'X',
        }
    })

    -- Monitor thread: cancel key detection + control disabling + completion check
    local startTime = GetGameTimer()

    CreateThread(function()
        while progressBarActive do
            local elapsed = GetGameTimer() - startTime

            -- Completed
            if elapsed >= duration then
                progressBarActive = false
                -- Close NUI
                SendNUIMessage({ action = 'cancelProgressBar' })
                -- Cleanup
                if data.anim then
                    StopAnimTask(ped, data.anim.dict, data.anim.clip, 1.0)
                end
                if propEntity and DoesEntityExist(propEntity) then
                    DeleteEntity(propEntity)
                    propEntity = nil
                end
                if progressBarPromise then
                    progressBarPromise:resolve(true)
                end
                return
            end

            -- Cancel detection (47 = INPUT_VEH_DUCK / X key)
            if canCancel and IsControlJustPressed(0, 73) then
                progressBarActive = false
                SendNUIMessage({ action = 'cancelProgressBar' })
                if data.anim then
                    StopAnimTask(ped, data.anim.dict, data.anim.clip, 1.0)
                end
                if propEntity and DoesEntityExist(propEntity) then
                    DeleteEntity(propEntity)
                    propEntity = nil
                end
                if progressBarPromise then
                    progressBarPromise:resolve(false)
                end
                return
            end

            -- Disable controls while active
            if disableControls.move then
                DisableControlAction(0, 30, true)  -- MoveLeftRight
                DisableControlAction(0, 31, true)  -- MoveUpDown
                DisableControlAction(0, 36, true)  -- Duck
                DisableControlAction(0, 21, true)  -- Sprint
            end
            if disableControls.car then
                DisableControlAction(0, 63, true)  -- VehMoveLeftRight
                DisableControlAction(0, 64, true)  -- VehMoveUpDown
                DisableControlAction(0, 71, true)  -- VehAccelerate
                DisableControlAction(0, 72, true)  -- VehBrake
                DisableControlAction(0, 75, true)  -- VehExit
            end
            if disableControls.combat then
                DisableControlAction(0, 24, true)  -- Attack
                DisableControlAction(0, 25, true)  -- Aim
                DisableControlAction(0, 47, true)  -- Weapon
                DisableControlAction(0, 58, true)  -- Throw Grenade
                DisableControlAction(0, 140, true) -- MeleeAttackLight
                DisableControlAction(0, 141, true) -- MeleeAttackHeavy
                DisableControlAction(0, 142, true) -- MeleeAttackAlternate
                DisableControlAction(0, 143, true) -- MeleeBlock
            end
            if disableControls.mouse then
                DisableControlAction(0, 1, true)  -- LookLeftRight
                DisableControlAction(0, 2, true)  -- LookUpDown
            end

            Wait(0)
        end
    end)

    -- Block until resolved
    local result = Citizen.Await(progressBarPromise)
    progressBarPromise = nil

    return result == true
end

-- NUI Callback: cancel from NUI side (user pressed cancel key in browser)
RegisterNUICallback('progressBarResult', function(data, cb)
    if progressBarActive and data.cancelled then
        progressBarActive = false
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        if progressBarPromise then
            progressBarPromise:resolve(false)
        end
    end
    cb('ok')
end)

--- Check if a progressbar is currently active
--- @return boolean
local function IsProgressBarActive()
    return progressBarActive
end

--- Cancel the currently active progressbar programmatically
--- @return boolean cancelled Whether a progressbar was actually cancelled
local function CancelProgressBar()
    if not progressBarActive then return false end

    progressBarActive = false
    SendNUIMessage({ action = 'cancelProgressBar' })

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    if progressBarPromise then
        progressBarPromise:resolve(false)
    end

    return true
end

-----------------------
-- Radial Menu System
-----------------------

local radialCallback = nil
local radialOpen = false

--- Open a radial wheel for quick actions. Hold-to-trigger pattern:
--- call OpenRadial(...) on key-down, CloseRadial() on key-up — the
--- onSelect callback fires with the id of the item the cursor was on
--- when the key was released (or with nil if no slice was active).
--- @param data table { items: { id, label, icon? }[], onSelect: function(id) }
local function OpenRadial(data)
    if radialOpen then return end
    if type(data) ~= 'table' or type(data.items) ~= 'table' or #data.items == 0 then
        print('^1[EF_LIB] OpenRadial: data.items must be a non-empty table^0')
        return
    end

    radialCallback = data.onSelect
    radialOpen = true

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = 'openRadial',
        data = { items = data.items }
    })
end

--- Close the active radial. The NUI side immediately sends back the
--- currently hovered item id via the radialResult callback, which then
--- invokes the onSelect from OpenRadial.
local function CloseRadial()
    if not radialOpen then return end
    radialOpen = false

    SendNUIMessage({ action = 'closeRadial' })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end

-- NUI Callback: receives the selected item id when the radial closes
RegisterNUICallback('radialResult', function(data, cb)
    local cbFn = radialCallback
    radialCallback = nil

    -- NUI closed itself (left-click on an end-item) → reset state and free focus
    if data.selfClosed then
        radialOpen = false
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end

    if cbFn and data.id then
        local ok, err = pcall(cbFn, data.id)
        if not ok then print('^1[EF_LIB] Radial onSelect error: ' .. tostring(err) .. '^0') end
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
exports('UpdateMenuItem', function(id, updates)
    if not id or not updates then return end
    updates.id = id
    SendNUIMessage({ action = 'updateMenuItem', data = updates })
end)
exports('NavigateMenu', function(action)
    SendNUIMessage({ action = 'navigate', data = action })
end)

-- Notifications
exports('SendNotification', SendNotification)

-- UI Config
exports('SetConfig', SetConfig)
exports('SetAccentColor', SetAccentColor)

-- Button Hints
exports('ShowHint', ShowHint)
exports('SetHintPosition', SetHintPosition)
exports('HideHint', HideHint)
exports('HideAllHints', HideAllHints)

-- Dialogs
exports('InputDialog', InputDialog)
exports('AlertDialog', AlertDialog)

-- Minigames
exports('Minigame', Minigame)

-- ProgressBar
exports('ProgressBar', ProgressBar)
exports('IsProgressBarActive', IsProgressBarActive)
exports('CancelProgressBar', CancelProgressBar)

-- Context Menu (ox_lib Compatibility)
exports('RegisterContext', RegisterContext)
exports('ShowContext', ShowContext)
exports('ContextMenu', ContextMenu)

-- Zone System
exports('CreateSphereZone', CreateSphereZone)
exports('CreateBoxZone', CreateBoxZone)

-- Radial Menu
exports('OpenRadial', OpenRadial)
exports('CloseRadial', CloseRadial)

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
RegisterNetEvent('ef_lib:showHint', function(key, label, id, icon, position)
    ShowHint(key, label, id, icon, position)
end)
RegisterNetEvent('ef_lib:hideHint', function(id)
    HideHint(id)
end)
RegisterNetEvent('ef_lib:hideAllHints', HideAllHints)
RegisterNetEvent('ef_lib:minigame', function(gameType, difficulty, retries)
    Minigame(gameType, difficulty, retries)
end)
RegisterNetEvent('ef_lib:progressBar', function(data)
    ProgressBar(data)
end)
RegisterNetEvent('ef_lib:cancelProgressBar', function()
    CancelProgressBar()
end)
