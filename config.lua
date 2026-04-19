Config = {}

-- UI Accent Color (HEX Code)
-- Examples: '#3b82f6' (Blue), '#22c55e' (Green), '#ef4444' (Red), '#a855f7' (Purple)
Config.AccentColor = '#ff0000'

-- Enable Demo Menu (set to false in production)
-- When enabled, pressing the MenuKey will open a demo menu
Config.EnableDemo = false

-- Show mouse cursor in menus (default behavior)
-- true = Mouse + Keyboard control (cursor visible, clickable items)
-- false = Keyboard only (no cursor, player keeps camera control e.g. for wardrobe/clothing menus)
-- Can be overridden per-menu with: OpenMenu({ showCursor = true/false, ... })
Config.ShowCursor = false

-- Allow player movement while menu is open (global default)
-- true = Player can walk/run/look around while menu is open
-- false = Player is frozen in place while menu is open
-- Can be overridden per-menu with: OpenMenu({ allowMove = true/false, ... })
Config.AllowMove = true

-- Demo Menu Keybind (only used when EnableDemo = true)
Config.MenuKey = 'F2'
