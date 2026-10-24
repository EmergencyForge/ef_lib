Config = {}

-- UI Accent Color (HEX Code)
-- Examples: '#f0500a' (EmergencyForge orange), '#3b82f6' (Blue), '#22c55e' (Green), '#ef4444' (Red)
Config.AccentColor = '#f0500a'

-- Blur the game behind dialogs, minigames and the radial menu
-- The NUI cannot blur the game itself, this uses the screen blur effect instead
Config.ScreenBlur = true

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
