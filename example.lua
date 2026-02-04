--[[
    EF Library - Example Usage
    This file shows how to use ef_lib from another resource

    Add this to your fxmanifest.lua:
    dependencies { 'ef_lib' }
]]

-- Example: Open a simple menu
RegisterCommand('mymenu', function()
    exports.ef_lib:OpenMenu({
        title = 'My Custom Menu',
        items = {
            { id = 'option1', label = 'Option 1', description = 'First option' },
            { id = 'option2', label = 'Option 2', description = 'Second option' },
            { id = 'option3', label = 'Option 3', description = 'Third option' },
        }
    })
end, false)

-- Example: Menu with all item types
RegisterCommand('fullmenu', function()
    exports.ef_lib:OpenMenu({
        title = 'Full Example',
        items = {
            -- Button (default type)
            { id = 'btn', label = 'Click Me', description = 'A clickable button' },

            -- Checkbox
            { id = 'check', label = 'Enable Feature', type = 'checkbox', checked = false },

            -- Input field
            { id = 'input', label = 'Your Name', type = 'input', placeholder = 'Enter name...' },

            -- Select dropdown
            { id = 'select', label = 'Choose Option', type = 'select', value = 'a', options = { 'a', 'b', 'c' } },

            -- Submenu
            {
                id = 'submenu',
                label = 'More Options',
                submenu = {
                    title = 'Sub Menu',
                    items = {
                        { id = 'sub1', label = 'Sub Item 1' },
                        { id = 'sub2', label = 'Sub Item 2' },
                    }
                }
            },

            -- Button with confirmation
            {
                id = 'dangerous',
                label = 'Delete All',
                description = 'Requires confirmation',
                confirm = {
                    title = 'Are you sure?',
                    message = 'This action cannot be undone',
                    confirmLabel = 'Yes, Delete',
                    cancelLabel = 'Cancel'
                }
            },

            -- Include built-in UI Settings
            exports.ef_lib:GetUISettingsMenu(),
        }
    })
end, false)

-- Handle menu actions
AddEventHandler('ef_lib:menuAction', function(data)
    -- data contains: id, type, label, checked, value, data

    if data.id == 'btn' then
        exports.ef_lib:SendNotification('success', 'Clicked!', 'You clicked the button', 3000)

    elseif data.id == 'check' then
        local status = data.checked and 'enabled' or 'disabled'
        exports.ef_lib:SendNotification('info', 'Toggle', 'Feature ' .. status, 2000)

    elseif data.id == 'input' then
        exports.ef_lib:SendNotification('info', 'Input', 'You entered: ' .. (data.value or ''), 3000)

    elseif data.id == 'select' then
        exports.ef_lib:SendNotification('info', 'Selected', 'You chose: ' .. (data.value or ''), 2000)

    elseif data.id == 'dangerous' then
        exports.ef_lib:SendNotification('warning', 'Deleted', 'Action confirmed!', 3000)
        exports.ef_lib:CloseMenu()
    end
end)

-- Example: Notifications
RegisterCommand('testnotify', function()
    exports.ef_lib:SendNotification('success', 'Success', 'Operation completed!', 3000)
    Wait(500)
    exports.ef_lib:SendNotification('error', 'Error', 'Something went wrong!', 3000)
    Wait(500)
    exports.ef_lib:SendNotification('warning', 'Warning', 'Be careful!', 3000)
    Wait(500)
    exports.ef_lib:SendNotification('info', 'Info', 'Just so you know...', 3000)
end, false)

-- Example: Change accent color at runtime
RegisterCommand('setcolor', function(source, args)
    local color = args[1] or '#3b82f6'
    exports.ef_lib:SetAccentColor(color)
    exports.ef_lib:SendNotification('success', 'Color Changed', 'Accent color set to ' .. color, 3000)
end, false)

-- Example: Check if menu is open
RegisterCommand('checkmenu', function()
    local isOpen = exports.ef_lib:IsMenuOpen()
    print('Menu is ' .. (isOpen and 'open' or 'closed'))
end, false)

-- Example: Button Hints
RegisterCommand('showhint', function()
    -- Show a single hint
    exports.ef_lib:ShowHint('E', 'Open Shop', 'shop_hint')
end, false)

RegisterCommand('hidehint', function()
    -- Hide specific hint
    exports.ef_lib:HideHint('shop_hint')
end, false)

RegisterCommand('multiplehints', function()
    -- Show multiple hints at once
    exports.ef_lib:ShowHint('E', 'Enter Vehicle', 'vehicle_enter')
    exports.ef_lib:ShowHint('G', 'Open Trunk', 'vehicle_trunk')
    exports.ef_lib:ShowHint('H', 'Lock Vehicle', 'vehicle_lock')
end, false)

RegisterCommand('hideallhints', function()
    -- Hide all hints
    exports.ef_lib:HideAllHints()
end, false)

--[[
    Available Exports:

    exports.ef_lib:OpenMenu(menuData)       -- Open a menu
    exports.ef_lib:CloseMenu()              -- Close the menu
    exports.ef_lib:IsMenuOpen()             -- Check if menu is open
    exports.ef_lib:SendNotification(type, title, message, duration)
    exports.ef_lib:SetAccentColor(hexColor) -- Change accent color
    exports.ef_lib:SetConfig(config)        -- Set UI config
    exports.ef_lib:GetUISettingsMenu()      -- Get the built-in UI Settings menu item
    exports.ef_lib:ShowHint(key, label, id) -- Show a button hint
    exports.ef_lib:HideHint(id)             -- Hide a specific hint (or all if no id)
    exports.ef_lib:HideAllHints()           -- Hide all hints

    Available Events:

    ef_lib:menuAction                       -- Fired when a menu item is activated
    ef_lib:openMenu                         -- Server can trigger to open menu
    ef_lib:closeMenu                        -- Server can trigger to close menu
    ef_lib:notify                           -- Server can trigger notifications
    ef_lib:showHint                         -- Server can trigger to show hints
    ef_lib:hideHint                         -- Server can trigger to hide hints
    ef_lib:hideAllHints                     -- Server can trigger to hide all hints
]]
