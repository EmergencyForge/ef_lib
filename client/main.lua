--[[
    EF Library - Client Side
    Handles NUI communication and menu state

    Usage from other scripts:
    exports.ef_lib:OpenMenu({ title = 'My Menu', items = {...} })
    exports.ef_lib:CloseMenu()
    exports.ef_lib:SendNotification('success', 'Title', 'Message', 3000)
]]

local isMenuOpen = false

-----------------------
-- Core Functions
-----------------------

-- Open the menu (allows player movement while open)
local function OpenMenu(menuData)
    if isMenuOpen then return end

    isMenuOpen = true
    SetNuiFocus(false, false) -- No cursor, keyboard goes to game
    SendNUIMessage({
        action = 'openMenu',
        data = menuData or {}
    })
end

-- Close the menu
local function CloseMenu()
    if not isMenuOpen then return end

    isMenuOpen = false
    SetNuiFocus(false, false)
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

-- Show a button hint (key, label, optional id for multiple hints)
local function ShowHint(key, label, id)
    SendNUIMessage({
        action = 'showHint',
        data = {
            key = key,
            label = label,
            id = id
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

RegisterNUICallback('menuAction', function(data, cb)
    TriggerEvent('ef_lib:menuAction', data)
    cb('ok')
end)

RegisterNUICallback('setKeyboardFocus', function(data, cb)
    local enabled = data.enabled
    if isMenuOpen then
        SetNuiFocus(enabled, false)
    end
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

            -- Backspace - Go back
            if IsControlJustPressed(0, 177) then
                SendNUIMessage({ action = 'navigate', data = 'back' })
            end

            -- Arrow Left - Go back
            if IsControlJustPressed(0, 174) then
                SendNUIMessage({ action = 'navigate', data = 'back' })
            end

            -- Arrow Right - Select/Enter submenu
            if IsControlJustPressed(0, 175) then
                SendNUIMessage({ action = 'navigate', data = 'select' })
            end
        end
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
-- Exports
-----------------------

exports('OpenMenu', OpenMenu)
exports('CloseMenu', CloseMenu)
exports('ToggleMenu', ToggleMenu)
exports('SendNotification', SendNotification)
exports('SetConfig', SetConfig)
exports('SetAccentColor', SetAccentColor)
exports('IsMenuOpen', function() return isMenuOpen end)
exports('GetUISettingsMenu', GetUISettingsMenu)
exports('ShowHint', ShowHint)
exports('HideHint', HideHint)
exports('HideAllHints', HideAllHints)

-----------------------
-- Events
-----------------------

RegisterNetEvent('ef_lib:openMenu', OpenMenu)
RegisterNetEvent('ef_lib:closeMenu', CloseMenu)
RegisterNetEvent('ef_lib:notify', function(type, title, message, duration)
    SendNotification(type, title, message, duration)
end)
RegisterNetEvent('ef_lib:showHint', function(key, label, id)
    ShowHint(key, label, id)
end)
RegisterNetEvent('ef_lib:hideHint', function(id)
    HideHint(id)
end)
RegisterNetEvent('ef_lib:hideAllHints', HideAllHints)
