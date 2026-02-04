# EF Library - UI Framework Documentation

## Installation

1. Kopiere den `ef_lib` Ordner in deinen FiveM `resources` Ordner
2. Füge `ensure ef_lib` in deine `server.cfg` ein
3. Starte den Server neu

---

## Konfiguration

Bearbeite `config.lua` um die Grundeinstellungen anzupassen:

```lua
Config = {}

-- Akzentfarbe (HEX Code)
Config.AccentColor = '#3b82f6'

-- Demo-Menü aktivieren (in Produktion auf false setzen)
Config.EnableDemo = true

-- Taste für Demo-Menü (nur wenn EnableDemo = true)
Config.MenuKey = 'F2'
```

### Verfügbare Farben (Beispiele)
| Farbe | HEX Code |
|-------|----------|
| Blau | `#3b82f6` |
| Rot | `#ef4444` |
| Grün | `#22c55e` |
| Lila | `#a855f7` |
| Orange | `#f97316` |
| Gelb | `#eab308` |

---

## Menü System

### Menü öffnen

```lua
exports.ef_lib:OpenMenu({
    title = 'Menü Titel',
    items = {
        -- Items hier
    }
})
```

### Menü schließen

```lua
exports.ef_lib:CloseMenu()
```

### Menü Status prüfen

```lua
local isOpen = exports.ef_lib:IsMenuOpen()
```

---

## Item Typen

### 1. Button (Standard)

Normaler klickbarer Menüeintrag mit Pfeil-Indikator.

```lua
{
    id = 'unique_id',           -- Eindeutige ID (erforderlich)
    label = 'Button Text',      -- Angezeigter Text (erforderlich)
    description = 'Info Text',  -- Beschreibung unter dem Label (optional)
    icon = '🎮',                -- Emoji Icon (optional)
    disabled = false,           -- Deaktiviert (optional)
    data = { custom = 'data' }  -- Eigene Daten (optional)
}
```

**Beispiel:**
```lua
{ id = 'spawn', label = 'Spawn', description = 'Wähle einen Spawn-Punkt' }
```

---

### 2. Checkbox

Toggle-Element mit Häkchen.

```lua
{
    id = 'unique_id',
    label = 'Checkbox Text',
    type = 'checkbox',          -- Typ festlegen
    checked = true,             -- Anfangszustand (true/false)
    disabled = false
}
```

**Beispiel:**
```lua
{ id = 'notifications', label = 'Benachrichtigungen', type = 'checkbox', checked = true }
{ id = 'sound', label = 'Sound-Effekte', type = 'checkbox', checked = false }
```

---

### 3. Input

Texteingabefeld.

```lua
{
    id = 'unique_id',
    label = 'Input Label',
    type = 'input',             -- Typ festlegen
    placeholder = 'Platzhalter...',  -- Platzhaltertext (optional)
    value = '',                 -- Anfangswert (optional)
    disabled = false
}
```

**Beispiel:**
```lua
{ id = 'username', label = 'Name', type = 'input', placeholder = 'Dein Name...' }
{ id = 'amount', label = 'Betrag', type = 'input', placeholder = '0' }
```

---

### 4. Submenu

Verschachteltes Untermenü.

```lua
{
    id = 'unique_id',
    label = 'Submenu Label',
    description = 'Beschreibung',  -- Optional
    submenu = {
        title = 'Untermenü Titel',
        items = {
            -- Weitere Items hier (können auch Submenus enthalten)
        }
    }
}
```

**Beispiel:**
```lua
{
    id = 'settings',
    label = 'Einstellungen',
    description = 'Öffne Einstellungen',
    submenu = {
        title = 'Einstellungen',
        items = {
            { id = 'sound', label = 'Sound', type = 'checkbox', checked = true },
            { id = 'volume', label = 'Lautstärke', type = 'input', placeholder = '100' },
            {
                id = 'advanced',
                label = 'Erweitert',
                submenu = {
                    title = 'Erweiterte Einstellungen',
                    items = {
                        { id = 'debug', label = 'Debug Modus', type = 'checkbox', checked = false }
                    }
                }
            }
        }
    }
}
```

**Navigation:**
- `Enter` oder `Pfeil Rechts`: Submenu öffnen
- `ESC`, `Backspace` oder `Pfeil Links`: Zurück zum vorherigen Menü

---

### 5. Select

Auswahl-Element mit mehreren Optionen.

```lua
{
    id = 'unique_id',
    label = 'Select Label',
    type = 'select',            -- Typ festlegen
    value = 'option1',          -- Aktueller Wert (optional)
    options = { 'option1', 'option2', 'option3' },  -- Verfügbare Optionen
    disabled = false
}
```

**Beispiel:**
```lua
{ id = 'position', label = 'Position', type = 'select', value = 'left', options = { 'left', 'center', 'right' } }
{ id = 'language', label = 'Sprache', type = 'select', value = 'de', options = { 'de', 'en', 'fr' } }
```

**Bedienung:**
- `Enter` oder `Pfeil Rechts`: Zur nächsten Option wechseln

---

### 6. Confirmation (Bestätigungsdialog)

Füge `confirm` zu einem Item hinzu, um vor der Ausführung eine Bestätigung anzufordern.

```lua
{
    id = 'unique_id',
    label = 'Gefährliche Aktion',
    confirm = true              -- Einfache Bestätigung mit Standardtexten
}
```

**Mit eigenen Texten:**
```lua
{
    id = 'unique_id',
    label = 'Löschen',
    confirm = {
        title = 'Wirklich löschen?',         -- Titel des Dialogs
        message = 'Diese Aktion kann nicht rückgängig gemacht werden.',  -- Beschreibungstext
        confirmLabel = 'Ja, löschen',        -- Text für Bestätigen-Button
        cancelLabel = 'Abbrechen'            -- Text für Abbrechen-Button
    }
}
```

**Beispiel:**
```lua
{ id = 'reset', label = 'Zurücksetzen', confirm = true }
{ id = 'delete_account', label = 'Account löschen', confirm = { title = 'Account löschen?', message = 'Alle Daten werden gelöscht!', confirmLabel = 'Löschen', cancelLabel = 'Abbrechen' } }
```

**Funktionsweise:**
1. Spieler wählt das Item
2. Bestätigungsdialog erscheint als Submenu
3. Bei "Ja" wird die Aktion ausgeführt
4. Bei "Abbrechen" kehrt man zum vorherigen Menü zurück

**Hinweis:** Die Bestätigung funktioniert mit allen Item-Typen (Button, Checkbox, etc.).

---

## Events

### Menu Action Event

Wird ausgelöst wenn ein Item aktiviert wird.

```lua
AddEventHandler('ef_lib:menuAction', function(data)
    print('Item ID:', data.id)
    print('Item Type:', data.type)      -- 'button', 'checkbox', oder 'input'
    print('Item Label:', data.label)

    -- Für Checkbox
    if data.type == 'checkbox' then
        print('Checked:', data.checked)
    end

    -- Für Input
    if data.type == 'input' then
        print('Value:', data.value)
    end

    -- Eigene Daten
    if data.data then
        print('Custom Data:', json.encode(data.data))
    end
end)
```

---

## Benachrichtigungen

### Benachrichtigung senden

```lua
exports.ef_lib:SendNotification(type, title, message, duration)
```

**Parameter:**
| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| type | string | `'success'`, `'error'`, `'warning'`, `'info'` |
| title | string | Titel der Benachrichtigung |
| message | string | Nachrichtentext |
| duration | number | Anzeigedauer in ms (Standard: 5000) |

**Beispiele:**
```lua
-- Erfolg
exports.ef_lib:SendNotification('success', 'Gespeichert', 'Einstellungen wurden gespeichert.', 3000)

-- Fehler
exports.ef_lib:SendNotification('error', 'Fehler', 'Etwas ist schief gelaufen!', 5000)

-- Warnung
exports.ef_lib:SendNotification('warning', 'Achtung', 'Niedrige Munition.', 4000)

-- Info
exports.ef_lib:SendNotification('info', 'Info', 'Drücke E zum Interagieren.', 3000)
```

---

## Akzentfarbe zur Laufzeit ändern

```lua
exports.ef_lib:SetAccentColor('#ff0000')  -- Rot
exports.ef_lib:SetAccentColor('#22c55e')  -- Grün
```

---

## Button Hints (Interaktions-Hinweise)

Zeige Tastatur-Hinweise an, wenn der Spieler in eine Zone eintritt. Perfekt für interaktive Bereiche wie Shops, NPCs, oder Fahrzeuge.

### Hint anzeigen

```lua
exports.ef_lib:ShowHint(key, label, id)
```

**Parameter:**
| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| key | string | Die Taste (z.B. `'E'`, `'F'`, `'G'`) |
| label | string | Die Aktion (z.B. `'Shop öffnen'`, `'Sprechen'`) |
| id | string | Optionale ID für mehrere Hints (optional) |

**Beispiele:**
```lua
-- Einfacher Hint
exports.ef_lib:ShowHint('E', 'Shop öffnen')

-- Hint mit ID (für mehrere gleichzeitige Hints)
exports.ef_lib:ShowHint('E', 'Tür öffnen', 'door_hint')
exports.ef_lib:ShowHint('G', 'Inventar öffnen', 'inventory_hint')
```

### Hint verstecken

```lua
-- Bestimmten Hint verstecken
exports.ef_lib:HideHint('door_hint')

-- Alle Hints verstecken
exports.ef_lib:HideHint()
-- oder
exports.ef_lib:HideAllHints()
```

### Beispiel mit Zone

```lua
-- Wenn Spieler in Zone eintritt
local function OnEnterShopZone()
    exports.ef_lib:ShowHint('E', 'Shop öffnen', 'shop')
end

-- Wenn Spieler Zone verlässt
local function OnExitShopZone()
    exports.ef_lib:HideHint('shop')
end

-- Taste drücken um Aktion auszuführen
CreateThread(function()
    while true do
        Wait(0)
        if isInShopZone and IsControlJustPressed(0, 38) then -- E Taste
            exports.ef_lib:HideHint('shop')
            -- Shop-Menü öffnen
            exports.ef_lib:OpenMenu({ title = 'Shop', items = {...} })
        end
    end
end)
```

### Mehrere Hints gleichzeitig

```lua
-- Bei Fahrzeug in der Nähe
exports.ef_lib:ShowHint('F', 'Einsteigen', 'vehicle_enter')
exports.ef_lib:ShowHint('H', 'Kofferraum öffnen', 'vehicle_trunk')

-- Beim Verlassen der Zone
exports.ef_lib:HideAllHints()
```

---

## Vollständiges Beispiel

```lua
-- Menü mit allen Item-Typen
exports.ef_lib:OpenMenu({
    title = 'Einstellungen',
    items = {
        { id = 'profile', label = 'Profil', description = 'Bearbeite dein Profil' },
        { id = 'inventory', label = 'Inventar', description = 'Öffne dein Inventar' },
        { id = 'notifications', label = 'Benachrichtigungen', type = 'checkbox', checked = true },
        { id = 'music', label = 'Musik', type = 'checkbox', checked = false },
        { id = 'volume', label = 'Lautstärke', type = 'input', placeholder = '100' },
        { id = 'name', label = 'Anzeigename', type = 'input', value = 'Spieler' },
        { id = 'save', label = 'Speichern', description = 'Einstellungen speichern' },
    }
})

-- Event Handler
AddEventHandler('ef_lib:menuAction', function(data)
    if data.id == 'profile' then
        -- Profil öffnen
        exports.ef_lib:CloseMenu()
        TriggerEvent('openProfile')

    elseif data.id == 'notifications' then
        -- Benachrichtigungen toggle
        local status = data.checked and 'aktiviert' or 'deaktiviert'
        exports.ef_lib:SendNotification('info', 'Einstellung', 'Benachrichtigungen ' .. status, 2000)

    elseif data.id == 'save' then
        -- Speichern
        exports.ef_lib:CloseMenu()
        exports.ef_lib:SendNotification('success', 'Gespeichert', 'Deine Einstellungen wurden gespeichert.', 3000)
    end
end)
```

---

## Server-seitige Funktionen

### Benachrichtigung an Spieler senden

```lua
-- An einen Spieler
exports.ef_lib:SendNotification(source, 'success', 'Willkommen', 'Willkommen auf dem Server!', 5000)

-- An alle Spieler
exports.ef_lib:SendNotificationToAll('info', 'Server', 'Server Neustart in 5 Minuten', 10000)
```

### Menü für Spieler öffnen

```lua
exports.ef_lib:OpenMenuForPlayer(source, {
    title = 'Admin Menü',
    items = { ... }
})
```

---

## Client-Einstellungen (UI Settings)

Spieler können ihre eigenen UI-Einstellungen anpassen, die lokal gespeichert werden.

### Einfache Methode (Empfohlen)

Nutze die eingebaute Funktion um UI-Settings in dein Menü einzufügen:

```lua
exports.ef_lib:OpenMenu({
    title = 'Mein Menü',
    items = {
        { id = 'option1', label = 'Option 1' },
        { id = 'option2', label = 'Option 2' },
        exports.ef_lib:GetUISettingsMenu(),  -- Fügt UI Settings hinzu
    }
})
```

### Verfügbare Einstellungen

| Einstellung | Beschreibung |
|-------------|--------------|
| Menu Position | Links, Mitte oder Rechts |
| Accent Color | Eigene Akzentfarbe (HEX Code) |
| Notification Position | Position der Benachrichtigungen |
| Reset | Auf Standardwerte zurücksetzen |

**Hinweis:** Diese Einstellungen werden im Browser-Speicher (localStorage) gespeichert und überschreiben die Server-Konfiguration. Items mit IDs die mit `_settings_` beginnen werden intern behandelt.

---

## Suche (Search)

Bei Menüs mit mehr als 5 Items erscheint ein Such-Button. Drücke `/` um die Suche zu öffnen.

**Tastenkombinationen in der Suche:**
- `/` - Suche öffnen
- `ESC` - Suche schließen
- `↑ / ↓` - In Ergebnissen navigieren
- `Enter` - Item auswählen

Die Suche filtert Items nach Label und Beschreibung.

---

## Tastenkombinationen (In-Game)

| Taste | Funktion |
|-------|----------|
| F2 | Demo-Menü öffnen (wenn aktiviert) |
| ↑ / ↓ | Nach oben/unten navigieren |
| Enter / → | Item aktivieren / Submenu öffnen |
| ESC | Menü/Suche schließen |
| Backspace / ← | Zurück (im Submenu) |
| / | Suche öffnen (bei >5 Items) |

---

## Entwicklung (Browser Testing)

1. Navigiere zu `ef_lib/web/`
2. Führe `bun run dev` aus
3. Öffne `http://localhost:5173` im Browser
4. Das Menü öffnet sich automatisch im Dev-Modus

### Build für FiveM

```bash
cd ef_lib
bun run build
```

---

## Als Library nutzen

Um ef_lib in anderen Scripts zu verwenden:

### 1. Dependency hinzufügen

In deiner `fxmanifest.lua`:

```lua
dependencies { 'ef_lib' }
```

### 2. Demo deaktivieren

In `ef_lib/config.lua`:

```lua
Config.EnableDemo = false
```

### 3. Exports verwenden

```lua
-- Menü öffnen
exports.ef_lib:OpenMenu({ title = 'Mein Menü', items = {...} })

-- Menü schließen
exports.ef_lib:CloseMenu()

-- Menü Status
local isOpen = exports.ef_lib:IsMenuOpen()

-- Benachrichtigung
exports.ef_lib:SendNotification('success', 'Titel', 'Nachricht', 3000)

-- Akzentfarbe ändern
exports.ef_lib:SetAccentColor('#ff0000')

-- UI Settings Menü einfügen
exports.ef_lib:GetUISettingsMenu()

-- Button Hints
exports.ef_lib:ShowHint('E', 'Interagieren', 'my_hint')
exports.ef_lib:HideHint('my_hint')
exports.ef_lib:HideAllHints()
```

### Vollständiges Beispiel

Siehe `example.lua` im ef_lib Ordner für ein vollständiges Beispiel.

---

## Projektstruktur

```
ef_lib/
├── config.lua              # Konfiguration
├── fxmanifest.lua          # Resource Manifest
├── example.lua             # Beispiel-Script
├── client/
│   └── main.lua            # Client-seitige Logik
├── server/
│   └── main.lua            # Server-seitige Logik
└── web/
    ├── src/                # Vue.js Quellcode
    │   ├── components/     # UI Komponenten
    │   ├── stores/         # Pinia Stores
    │   └── composables/    # NUI Kommunikation
    └── dist/               # Gebaute Dateien
```
