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

-- Maus-Cursor in Menüs anzeigen (globaler Standard)
-- true = Maus + Tastatur (Cursor sichtbar, Items klickbar)
-- false = Nur Tastatur (kein Cursor, Spieler behält Kamerasteuerung)
-- Kann pro Menü überschrieben werden: OpenMenu({ showCursor = true/false })
Config.ShowCursor = true

-- Spielerbewegung während Menü erlauben (globaler Standard)
-- true = Spieler kann sich bewegen/umsehen während Menü offen ist
-- false = Spieler ist eingefroren während Menü offen ist
-- Kann pro Menü überschrieben werden: OpenMenu({ allowMove = true/false })
Config.AllowMove = true

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

### Cursor-Steuerung (`Config.ShowCursor`)

| Wert | Steuerung | Beschreibung |
|------|-----------|-------------|
| `true` | Maus + Tastatur | Cursor sichtbar, Items klickbar. Standard-Verhalten. |
| `false` | Nur Tastatur | Kein Cursor, Spieler behält Kamerasteuerung (z.B. für Kleidung/Wardrobe-Menüs). |

Dies ist der **globale Standard** für alle Menüs. Einzelne Menüs können den Wert mit `showCursor` überschreiben:

```lua
-- Globaler Standard aus Config.ShowCursor wird verwendet
exports.ef_lib:OpenMenu({ title = 'Normal', items = { ... } })

-- Überschreibt den globalen Standard für dieses Menü
exports.ef_lib:OpenMenu({ title = 'Wardrobe', showCursor = false, items = { ... } })
```

**Priorität:** `menuData.showCursor` (wenn gesetzt) > `Config.ShowCursor` > `true` (Fallback)

### Bewegungssteuerung (`Config.AllowMove`)

| Wert | Verhalten | Beschreibung |
|------|-----------|-------------|
| `true` | Bewegung erlaubt | Spieler kann sich bewegen und umsehen während Menü offen ist. |
| `false` | Bewegung gesperrt | Spieler ist eingefroren während Menü offen ist (klassisches UI-Verhalten). |

Einzelne Menüs können den Wert mit `allowMove` überschreiben:

```lua
-- Spieler kann sich bewegen
exports.ef_lib:OpenMenu({ title = 'Wardrobe', allowMove = true, items = { ... } })

-- Spieler ist eingefroren
exports.ef_lib:OpenMenu({ title = 'Shop', allowMove = false, items = { ... } })
```

**Priorität:** `menuData.allowMove` (wenn gesetzt) > `Config.AllowMove` > `true` (Fallback)

---

## Callback System

Das Callback-System ermöglicht sichere Client-Server-Kommunikation. Der Client kann Server-Funktionen aufrufen und auf deren Ergebnis warten (synchron) oder asynchron reagieren.

### Server: Callback registrieren

```lua
exports.ef_lib:RegisterCallback('meinScript:getPlayerData', function(source, arg1, arg2)
    -- source = Server-ID des anfragenden Spielers
    -- arg1, arg2, ... = Parameter die der Client mitgibt
    
    local data = { name = 'Max', money = 50000 }
    return data
end)
```

### Server: Callback mit mehreren Rückgabewerten

```lua
exports.ef_lib:RegisterCallback('meinScript:buyItem', function(source, itemName, amount)
    if not itemName then
        return false, 'Kein Item angegeben'
    end
    
    -- Logik hier...
    return true, 'Erfolgreich gekauft: ' .. amount .. 'x ' .. itemName
end)
```

### Client: Callback aufrufen (blockierend / await)

```lua
-- Einfacher Callback
local data = exports.ef_lib:CallbackAwait('meinScript:getPlayerData')
print(data.name, data.money)

-- Mit Parametern und mehreren Rückgabewerten
local success, msg = exports.ef_lib:CallbackAwait('meinScript:buyItem', 'bandage', 5)
if success then
    print('OK:', msg)
else
    print('Fehler:', msg)
end
```

**Wichtig:** `CallbackAwait` blockiert den aktuellen Thread bis die Antwort kommt (max. 30 Sekunden Timeout). Verwende es in `CreateThread` oder Event-Handlern.

### Client: Callback aufrufen (asynchron / non-blocking)

```lua
exports.ef_lib:CallbackAsync('meinScript:getPlayerData', function(data)
    -- Wird aufgerufen wenn der Server antwortet
    print('Antwort erhalten:', data.name)
end)

-- Code hier läuft SOFORT weiter!
print('Warte nicht auf Antwort...')
```

### Server: Callback entfernen

```lua
exports.ef_lib:UnregisterCallback('meinScript:getPlayerData')
```

**Hinweis:** Callbacks werden automatisch aufgeräumt wenn die registrierende Resource gestoppt wird.

### Migration von ox_lib

```lua
-- VORHER (ox_lib):
lib.callback.register('name', function(source, ...) ... end)
local result = lib.callback.await('name', false, arg1, arg2)

-- NACHHER (ef_lib):
exports.ef_lib:RegisterCallback('name', function(source, ...) ... end)
local result = exports.ef_lib:CallbackAwait('name', arg1, arg2)
-- Hinweis: Der 2. Parameter (false/delay) entfällt komplett!
```

---

## Menü System

### Menü öffnen

```lua
exports.ef_lib:OpenMenu({
    title = 'Menü Titel',
    showCursor = true,      -- Maus-Cursor anzeigen (optional, Standard: true)
    items = {
        -- Items hier
    }
})
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|-------------|
| `title` | string | — | Titel des Menüs |
| `items` | table | — | Array von Menu Items |
| `showCursor` | boolean | `Config.ShowCursor` | Maus-Cursor anzeigen. Überschreibt den globalen `Config.ShowCursor` Wert. Auf `false` setzen für Menüs die Kamerasteuerung brauchen (z.B. Kleidung/Wardrobe) |
| `allowMove` | boolean | `Config.AllowMove` | Spielerbewegung erlauben. Überschreibt den globalen `Config.AllowMove` Wert. Auf `false` setzen um den Spieler einzufrieren. |

**Hinweis:** Bei `showCursor = false` behält der Spieler die Maus-/Kamerasteuerung. Navigation erfolgt über Tastatur (Pfeiltasten / WASD).

### Menü schließen

```lua
exports.ef_lib:CloseMenu()
```

### Menü Status prüfen

```lua
local isOpen = exports.ef_lib:IsMenuOpen()
```

### Menu Item aktualisieren

Aktualisiert ein bestehendes Menu Item zur Laufzeit (z.B. um Min/Max eines Number-Items zu ändern).

```lua
exports.ef_lib:UpdateMenuItem('item_id', {
    current = 0,
    max = 15,
    description = '16 verfügbar',
})
```

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `id` | string | Die ID des Items das aktualisiert werden soll |
| `updates` | table | Felder die aktualisiert werden sollen (current, max, min, description, etc.) |

### Menü Navigation (programmatisch)

Erlaubt es, das Menü von außen zu navigieren (z.B. über WASD-Forwarding vom Game Client).

```lua
exports.ef_lib:NavigateMenu('up')     -- Nach oben
exports.ef_lib:NavigateMenu('down')   -- Nach unten
exports.ef_lib:NavigateMenu('left')   -- Links / Wert verringern / Zurück
exports.ef_lib:NavigateMenu('right')  -- Rechts / Wert erhöhen / Aktivieren
exports.ef_lib:NavigateMenu('back')   -- Zurück zum vorherigen Menü
exports.ef_lib:NavigateMenu('close')  -- Menü schließen
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

---

### 2. Checkbox

```lua
{
    id = 'unique_id',
    label = 'Checkbox Text',
    type = 'checkbox',
    checked = true,
    disabled = false
}
```

---

### 3. Input

```lua
{
    id = 'unique_id',
    label = 'Input Label',
    type = 'input',
    placeholder = 'Platzhalter...',
    value = '',
    disabled = false
}
```

---

### 4. Submenu

```lua
{
    id = 'unique_id',
    label = 'Submenu Label',
    description = 'Beschreibung',
    submenu = {
        title = 'Untermenü Titel',
        items = { ... }
    }
}
```

**Navigation:**
- `Enter` oder `Pfeil Rechts`: Submenu öffnen
- `ESC`, `Backspace` oder `Pfeil Links`: Zurück zum vorherigen Menü

---

### 5. Select

```lua
{
    id = 'unique_id',
    label = 'Select Label',
    type = 'select',
    value = 'option1',
    options = { 'option1', 'option2', 'option3' },
    disabled = false
}
```

---

### 6. Number (Zahlenwähler)

Kompakter Zahlenwähler mit Links/Rechts-Pfeilen (`< Nr >`).

```lua
{
    id = 'unique_id',
    label = 'Drawable',
    description = '662 verfügbar',
    type = 'number',
    min = 0,               -- Minimaler Wert (optional, Standard: -∞)
    max = 661,              -- Maximaler Wert (optional, Standard: ∞)
    step = 1,               -- Schrittweite (optional, Standard: 1)
    current = 0             -- Aktueller Wert (optional, Standard: min oder 0)
}
```

**Navigation:**
- `← / A`: Wert verringern
- `→ / D`: Wert erhöhen
- Pfeiltasten im UI klickbar

**Event-Daten:**
```lua
if data.type == 'number' then
    print('Aktueller Wert:', data.value) -- Gibt den aktuellen Zahlenwert zurück
end
```

---

### 7. Confirmation (Bestätigungsdialog)

```lua
{
    id = 'unique_id',
    label = 'Gefährliche Aktion',
    confirm = true              -- Einfache Bestätigung
}
```

**Mit eigenen Texten:**
```lua
{
    id = 'unique_id',
    label = 'Löschen',
    confirm = {
        title = 'Wirklich löschen?',
        message = 'Diese Aktion kann nicht rückgängig gemacht werden.',
        confirmLabel = 'Ja, löschen',
        cancelLabel = 'Abbrechen'
    }
}
```

---

## Events

### Menu Action Event

```lua
AddEventHandler('ef_lib:menuAction', function(data)
    print('Item ID:', data.id)
    print('Item Type:', data.type)
    print('Item Label:', data.label)

    if data.type == 'checkbox' then
        print('Checked:', data.checked)
    end

    if data.type == 'input' then
        print('Value:', data.value)
    end

    if data.type == 'number' then
        print('Value:', data.value)
    end

    if data.data then
        print('Custom Data:', json.encode(data.data))
    end
end)
```

---

## Benachrichtigungen

### Client-seitig

```lua
exports.ef_lib:SendNotification(type, title, message, duration)
```

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| type | string | `'success'`, `'error'`, `'warning'`, `'info'` |
| title | string | Titel der Benachrichtigung |
| message | string | Nachrichtentext |
| duration | number | Anzeigedauer in ms (Standard: 5000) |

### Server-seitig

```lua
-- An einen Spieler
exports.ef_lib:SendNotification(source, 'success', 'Titel', 'Nachricht', 5000)

-- An alle Spieler
exports.ef_lib:SendNotificationToAll('info', 'Server', 'Nachricht an alle', 10000)
```

---

## Button Hints (Interaktions-Hinweise)

### Hint anzeigen

```lua
exports.ef_lib:ShowHint('E', 'Shop öffnen', 'shop_hint')
```

### Hint verstecken

```lua
exports.ef_lib:HideHint('shop_hint')
exports.ef_lib:HideAllHints()
```

### Mehrere Hints gleichzeitig

```lua
exports.ef_lib:ShowHint('F', 'Einsteigen', 'vehicle_enter')
exports.ef_lib:ShowHint('H', 'Kofferraum', 'vehicle_trunk')

-- Beim Verlassen der Zone
exports.ef_lib:HideAllHints()
```

---

## Akzentfarbe zur Laufzeit ändern

```lua
exports.ef_lib:SetAccentColor('#ff0000')
```

---

## Client-Einstellungen (UI Settings)

```lua
exports.ef_lib:OpenMenu({
    title = 'Mein Menü',
    items = {
        { id = 'option1', label = 'Option 1' },
        exports.ef_lib:GetUISettingsMenu(),
    }
})
```

---

## Tastenkombinationen (In-Game)

| Taste | Funktion |
|-------|----------|
| ↑ / W | Nach oben navigieren |
| ↓ / S | Nach unten navigieren |
| Enter / → / D | Item aktivieren / Submenu öffnen |
| ← / A | Zahlenwert verringern (bei Number-Typ) / Zurück |
| → / D | Zahlenwert erhöhen (bei Number-Typ) |
| ESC / Backspace | Zurück (im Submenu) / Menü schließen |
| / | Suche öffnen (bei >5 Items) |

**Hinweis:** Bei `showCursor = false` werden WASD-Tasten als Navigation an das Menü weitergeleitet, gleichzeitig werden sie an den Game Client durchgereicht (z.B. für Kamerasteuerung).

---

## Als Library nutzen

### 1. Dependency hinzufügen

```lua
dependencies { 'ef_lib' }
```

### 2. Demo deaktivieren

In `ef_lib/config.lua`:
```lua
Config.EnableDemo = false
```

### 3. Alle Exports auf einen Blick

**Client:**
```lua
-- Callback System
exports.ef_lib:CallbackAwait(name, ...)           -- Blockierend
exports.ef_lib:CallbackAsync(name, callback, ...)  -- Asynchron

-- Menü
exports.ef_lib:OpenMenu(menuData)                  -- Menü öffnen (menuData.showCursor optional)
exports.ef_lib:CloseMenu()                         -- Menü schließen
exports.ef_lib:ToggleMenu(show)                    -- Menü ein-/ausblenden
exports.ef_lib:IsMenuOpen()                        -- Status prüfen
exports.ef_lib:GetUISettingsMenu()                 -- UI-Einstellungen als Menü-Item
exports.ef_lib:UpdateMenuItem(id, updates)          -- Item zur Laufzeit aktualisieren
exports.ef_lib:NavigateMenu(action)                 -- Programmatische Navigation

-- Dialoge (blockierend)
exports.ef_lib:InputDialog(title, fields)           -- Eingabe-Dialog → table|nil
exports.ef_lib:AlertDialog(data)                    -- Bestätigungs-Dialog → 'confirm'|'cancel'

-- Context Menu (ox_lib Kompatibilität)
exports.ef_lib:RegisterContext(data)                -- Context Menu registrieren
exports.ef_lib:ShowContext(id)                      -- Registriertes Context Menu anzeigen
exports.ef_lib:ContextMenu(data)                    -- Registrieren + Anzeigen in einem Aufruf

-- Notifications
exports.ef_lib:SendNotification(type, title, message, duration)

-- UI Config
exports.ef_lib:SetConfig(config)
exports.ef_lib:SetAccentColor(hexColor)

-- Button Hints
exports.ef_lib:ShowHint(key, label, id, icon, position)
exports.ef_lib:SetHintPosition(position)
exports.ef_lib:HideHint(id)
exports.ef_lib:HideAllHints()

-- Minigames
exports.ef_lib:Minigame(gameType, difficulty, retries)

-- ProgressBar
exports.ef_lib:ProgressBar(data)                    -- Fortschrittsanzeige → boolean
exports.ef_lib:IsProgressBarActive()                -- Status prüfen
exports.ef_lib:CancelProgressBar()                  -- Progressbar abbrechen

-- Zonen
exports.ef_lib:CreateSphereZone(data)               -- Sphere Zone erstellen → zone
exports.ef_lib:CreateBoxZone(data)                   -- Box Zone erstellen → zone

-- Utilities
exports.ef_lib:RequestModel(model, timeout)          -- Model laden → boolean
exports.ef_lib:RequestAnimDict(dict, timeout)        -- AnimDict laden → boolean
```

**Server:**
```lua
-- Callback System
exports.ef_lib:RegisterCallback(name, handler)
exports.ef_lib:UnregisterCallback(name)

-- Notifications
exports.ef_lib:SendNotification(source, type, title, message, duration)
exports.ef_lib:SendNotificationToAll(type, title, message, duration)

-- Menu Control
exports.ef_lib:OpenMenuForPlayer(source, menuData)
exports.ef_lib:CloseMenuForPlayer(source)
```

---

## Projektstruktur

```
ef_lib/
├── config.lua              # Konfiguration
├── fxmanifest.lua          # Resource Manifest
├── example.lua             # Beispiel-Script
├── DOCUMENTATION.md        # Diese Datei
├── client/
│   └── main.lua            # Client: Menu, Callbacks, Dialoge, Hints, Zones, Minigames, ProgressBar
├── server/
│   └── main.lua            # Server: Callbacks, Notifications, Menu Control
└── web/
    ├── src/                # Vue.js Quellcode
    │   ├── components/     # UI Komponenten (Menu, InputDialog, AlertDialog, Notifications, etc.)
    │   ├── stores/         # Pinia Stores (menu, dialog, notifications, settings)
    │   └── composables/    # NUI Kommunikation (fetchNui, useNuiEvent)
    └── dist/               # Gebaute Dateien (automatisch generiert)
```

---

## Minigame System

Das Minigame-System bietet drei integrierte Minispiele die als Skill-Checks genutzt werden können. Alle blockieren den aktuellen Thread und geben `true` (Erfolg) oder `false` (Fehlgeschlagen) zurück.

### Grundnutzung

```lua
-- Einfacher Aufruf
local success = exports.ef_lib:Minigame('lockpick', 'medium')

if success then
    -- Spieler hat es geschafft
else
    -- Spieler hat versagt
end
```

### Parameter

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `gameType` | string | ✅ | `'lockpick'`, `'safedial'` oder `'reactionchain'` |
| `difficulty` | string | ❌ | `'easy'`, `'medium'`, `'hard'` oder `'extreme'` (Standard: `'medium'`) |
| `retries` | number | ❌ | Eigene Anzahl Versuche (überschreibt Standard der Schwierigkeit) |

### Verfügbare Minigames

#### 🔐 Lockpick (Pin-Tumbler Schloss)
Pins bewegen sich auf und ab. Spieler drückt `SPACE` wenn der Pin in der grünen Zone (Scherlinie) ist.

```lua
local success = exports.ef_lib:Minigame('lockpick', 'hard')
```

| Schwierigkeit | Pins | Zone | Zeit | Versuche |
|---------------|------|------|------|----------|
| easy | 3 | groß | 30s | 4 |
| medium | 5 | mittel | 20s | 3 |
| hard | 6 | klein | 15s | 2 |
| extreme | 7 | winzig | 10s | 1 |

**Ideal für:** Schlösser knacken, Fahrzeuge aufbrechen, Türen öffnen

#### 🔐 Safe Dial (Kombinations-Tresor)
Drehrad mit Zahlen. Spieler dreht mit `A`/`D` und bestätigt mit `SPACE` bei der richtigen Zahl. Mehrere Codes hintereinander, Richtung wechselt (links/rechts).

```lua
local success = exports.ef_lib:Minigame('safedial', 'medium')
```

| Schwierigkeit | Codes | Toleranz | Zeit | Versuche |
|---------------|-------|----------|------|----------|
| easy | 2 | ±4 | 30s | 4 |
| medium | 3 | ±3 | 20s | 3 |
| hard | 4 | ±2 | 15s | 2 |
| extreme | 5 | ±1 | 10s | 1 |

**Ideal für:** Tresore, Safes, Schließfächer, Waffenschränke

#### ⚡ Reaction Chain (Reaktionstest)
Farbige Felder leuchten zufällig auf. Spieler drückt `1`/`2`/`3`/`4` bevor die Zeit abläuft. Wird schneller mit jedem Treffer.

```lua
local success = exports.ef_lib:Minigame('reactionchain', 'hard')
```

| Schwierigkeit | Kette | Reaktion | Zeit | Versuche | Tasten |
|---------------|-------|----------|------|----------|--------|
| easy | 6 | 1200ms | 30s | 4 | 3 |
| medium | 8 | 900ms | 20s | 3 | 4 |
| hard | 12 | 700ms | 15s | 2 | 4 |
| extreme | 16 | 550ms | 10s | 1 | 4 |

**Ideal für:** CPR/Wiederbelebung, Reparaturen, Bomben entschärfen, Hacking

### Custom Retries

Alle Minigames unterstützen eine optionale Anzahl eigener Versuche:

```lua
-- Lockpicking mit 5 Versuchen statt dem Standard
local success = exports.ef_lib:Minigame('lockpick', 'hard', 5)

-- Safe mit nur 1 Versuch auf mittlerer Schwierigkeit
local success = exports.ef_lib:Minigame('safedial', 'medium', 1)
```

### Retry-System

Bei einem Fehlversuch werden alle Fortschritte (Pins, Codes, Kette) zurückgesetzt, aber der **Timer läuft weiter**. Sind alle Versuche aufgebraucht, endet das Spiel sofort als Fehlschlag.

### Praxisbeispiele

```lua
-- Fahrzeug aufbrechen
RegisterCommand('lockpick', function()
    local success = exports.ef_lib:Minigame('lockpick', 'hard')
    if success then
        exports.ef_lib:SendNotification('success', 'Aufgebrochen', 'Fahrzeug wurde geöffnet')
    else
        exports.ef_lib:SendNotification('error', 'Fehlgeschlagen', 'Das Schloss hat sich verklemmt')
    end
end)

-- Tresor knacken
RegisterCommand('safecrack', function()
    local success = exports.ef_lib:Minigame('safedial', 'extreme')
    if success then
        TriggerServerEvent('safe:opened', safeId)
    end
end)

-- Wiederbelebung
RegisterCommand('cpr', function()
    local success = exports.ef_lib:Minigame('reactionchain', 'medium')
    if success then
        TriggerServerEvent('medical:revive', targetId)
    end
end)
```

---

## ProgressBar System

Das ProgressBar-System bietet eine blockierende Fortschrittsanzeige mit optionaler Animation, Prop und Cancel-Möglichkeit. Der Spieler behält die Kamera-/Bewegungskontrolle (kein NUI-Focus nötig).

### Grundnutzung

```lua
-- Einfache Progressbar
local completed = exports.ef_lib:ProgressBar({
    label = 'Fahrzeug reparieren...',
    duration = 5000,
})

if completed then
    -- Aktion abgeschlossen
else
    -- Abgebrochen
end
```

### Vollständige Parameter

```lua
local completed = exports.ef_lib:ProgressBar({
    label = 'Motor reparieren...',          -- Text der angezeigt wird
    duration = 8000,                         -- Dauer in Millisekunden
    icon = 'fa-wrench',                      -- FontAwesome Icon (optional)
    canCancel = true,                        -- Abbrechbar mit X-Taste (default: false)
    cancelKey = 'X',                         -- Cancel-Taste (default: 'X')
    anim = {                                 -- Animation (optional)
        dict = 'mini@repair',
        clip = 'fixing_a_player',
        flag = 49,                           -- Anim flags (default: 49)
        blendIn = 3.0,                       -- Blend-In Speed (default: 3.0)
        blendOut = 1.0,                      -- Blend-Out Speed (default: 1.0)
    },
    prop = {                                 -- Prop zum Anhängen (optional)
        model = 'prop_tool_wrench',
        bone = 60309,                        -- Bone ID (default: SKEL_R_Hand / 60309)
        pos = vector3(0.0, 0.0, 0.0),       -- Offset Position
        rot = vector3(0.0, 0.0, 0.0),       -- Offset Rotation
    },
    disableControls = {                      -- Controls deaktivieren (optional)
        move = true,                         -- Bewegung (WASD/Sprint)
        car = false,                         -- Fahrzeug-Steuerung
        combat = true,                       -- Waffen/Angriff
        mouse = false,                       -- Kamera/Maus
    },
})
```

### Hilfsfunktionen

```lua
-- Prüfen ob eine Progressbar aktiv ist
local active = exports.ef_lib:IsProgressBarActive()

-- Aktive Progressbar programmatisch abbrechen
local wasCancelled = exports.ef_lib:CancelProgressBar()
```

### Server-seitige Events

```lua
-- Progressbar für einen Spieler starten
TriggerClientEvent('ef_lib:progressBar', source, {
    label = 'Verarbeitung...',
    duration = 3000,
})

-- Aktive Progressbar abbrechen
TriggerClientEvent('ef_lib:cancelProgressBar', source)
```

### Praxisbeispiele

```lua
-- Fahrzeug reparieren mit Animation und Prop
RegisterCommand('repair', function()
    local completed = exports.ef_lib:ProgressBar({
        label = 'Fahrzeug reparieren...',
        duration = 10000,
        icon = 'fa-wrench',
        canCancel = true,
        anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
        prop = { model = 'prop_tool_wrench' },
        disableControls = { move = true, combat = true },
    })
    if completed then
        local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, 0, 70)
        if DoesEntityExist(veh) then
            SetVehicleFixed(veh)
        end
        exports.ef_lib:SendNotification('success', 'Repariert', 'Fahrzeug wurde repariert')
    else
        exports.ef_lib:SendNotification('error', 'Abgebrochen', 'Reparatur abgebrochen')
    end
end)

-- Medizinische Behandlung
RegisterCommand('treat', function()
    local completed = exports.ef_lib:ProgressBar({
        label = 'Patienten behandeln...',
        duration = 6000,
        icon = 'fa-heart-pulse',
        disableControls = { move = true, combat = true },
    })
    if completed then
        TriggerServerEvent('medical:treatPatient', targetId)
    end
end)
```

---

## Dialog System

Modale Dialoge die den aktuellen Thread blockieren und auf Benutzereingabe warten. Funktioniert auch wenn ein Menü im Hintergrund geöffnet ist — der Cursor wird automatisch aktiviert und danach wiederhergestellt.

### InputDialog

Öffnet einen Dialog mit einem oder mehreren Eingabefeldern. Blockiert den Thread bis der Benutzer bestätigt oder abbricht.

```lua
local result = exports.ef_lib:InputDialog('Dialog Titel', {
    { type = 'input', label = 'Name', placeholder = 'Eingabe...', required = true },
    { type = 'number', label = 'Menge', min = 1, max = 100, default = 1 },
    { type = 'checkbox', label = 'Bestätigung', checked = false },
    { type = 'select', label = 'Auswahl', options = {
        { label = 'Option A', value = 'a' },
        { label = 'Option B', value = 'b' },
    }},
    { type = 'slider', label = 'Prozent', min = 0, max = 100, step = 5, default = 50 },
    { type = 'textarea', label = 'Beschreibung', placeholder = 'Text eingeben...' },
})

if not result then
    -- Dialog wurde abgebrochen (ESC / Abbrechen)
    return
end

-- result ist ein Array in Feld-Reihenfolge
local name = result[1]       -- string
local amount = result[2]     -- number
local confirmed = result[3]  -- boolean
local selected = result[4]   -- any (value)
local percent = result[5]    -- number
local text = result[6]       -- string
```

**Wichtig:** `InputDialog` blockiert den aktuellen Thread. Verwende es in `CreateThread` oder Event-Handlern.

#### Feld-Typen

| Typ | Beschreibung | Zusätzliche Parameter |
|-----|-------------|----------------------|
| `input` | Textfeld | `placeholder`, `required`, `default` |
| `number` | Zahlenfeld | `min`, `max`, `step`, `placeholder`, `required`, `default` |
| `checkbox` | Checkbox | `checked`, `default` |
| `select` | Dropdown-Auswahl | `options` (Array von `{label, value}` oder strings), `default` |
| `slider` | Schieberegler | `min`, `max`, `step`, `default` |
| `textarea` | Mehrzeiliges Textfeld | `placeholder`, `required`, `default` |

#### Rückgabewert

- `table` — Array der Werte in Feld-Reihenfolge (bei Bestätigung)
- `nil` — Dialog wurde abgebrochen

### AlertDialog

Öffnet einen Bestätigungs-/Warnungsdialog. Blockiert den Thread bis der Benutzer bestätigt oder abbricht.

```lua
local result = exports.ef_lib:AlertDialog({
    header = 'Löschen bestätigen',
    content = 'Soll der Eintrag wirklich gelöscht werden? Dies kann nicht rückgängig gemacht werden.',
    cancel = true,                      -- Abbrechen-Button anzeigen (Standard: true)
    centered = true,                    -- Text zentrieren (Standard: true)
    confirmLabel = 'Ja, löschen',       -- Text des Bestätigungs-Buttons (Standard: 'Bestätigen')
    cancelLabel = 'Nein, abbrechen',    -- Text des Abbruch-Buttons (Standard: 'Abbrechen')
})

if result == 'confirm' then
    -- Benutzer hat bestätigt
else
    -- Benutzer hat abgebrochen
end
```

#### Rückgabewert

- `'confirm'` — Benutzer hat bestätigt
- `'cancel'` — Benutzer hat abgebrochen

### Praxisbeispiele

```lua
-- Outfit speichern mit Namenseingabe
CreateThread(function()
    local result = exports.ef_lib:InputDialog('Outfit Speichern', {
        { type = 'input', label = 'Outfit Name', placeholder = 'Name eingeben...', required = true },
    })

    if not result or not result[1] or result[1] == '' then return end

    local outfitName = result[1]
    TriggerServerEvent('myResource:saveOutfit', outfitName)
end)

-- Bestätigungsdialog vor einer gefährlichen Aktion
CreateThread(function()
    local result = exports.ef_lib:AlertDialog({
        header = 'Fahrzeug löschen?',
        content = 'Das Fahrzeug wird dauerhaft entfernt.',
    })

    if result == 'confirm' then
        TriggerServerEvent('myResource:deleteVehicle', vehicleId)
    end
end)
```

---

## Context Menu System (ox_lib Kompatibilität)

Bietet das `registerContext`/`showContext` Muster für einfache Migration von ox_lib. Unterstützt `onSelect`-Callbacks direkt in den Optionen.

### Context Menu registrieren und anzeigen

```lua
-- Registrieren + Anzeigen in einem Aufruf
exports.ef_lib:ContextMenu({
    id = 'my_context',
    title = 'Aktionen',
    options = {
        {
            title = 'Reparieren',
            description = 'Fahrzeug reparieren',
            icon = 'fa-wrench',
            onSelect = function()
                print('Reparieren gewählt')
            end,
        },
        {
            title = 'Abschleppen',
            icon = 'fa-truck',
            disabled = false,
            onSelect = function()
                print('Abschleppen gewählt')
            end,
        },
    }
})
```

### Getrennt registrieren und anzeigen

```lua
-- Einmalig registrieren
exports.ef_lib:RegisterContext({
    id = 'shop_menu',
    title = 'Shop',
    options = { ... }
})

-- Später anzeigen
exports.ef_lib:ShowContext('shop_menu')
```

### Migration von ox_lib

```lua
-- VORHER (ox_lib):
lib.registerContext({ id = 'menu', title = 'Titel', options = { ... } })
lib.showContext('menu')

-- NACHHER (ef_lib):
exports.ef_lib:RegisterContext({ id = 'menu', title = 'Titel', options = { ... } })
exports.ef_lib:ShowContext('menu')
-- Oder zusammen:
exports.ef_lib:ContextMenu({ id = 'menu', title = 'Titel', options = { ... } })
```

---

## Zone System

Einfaches Zone-System mit Enter/Exit/Inside-Callbacks. Prüft alle 300ms die Spielerposition.

### Sphere Zone erstellen

```lua
local zone = exports.ef_lib:CreateSphereZone({
    coords = vector3(100.0, 200.0, 30.0),
    radius = 5.0,
    onEnter = function(self)
        print('Zone betreten')
        exports.ef_lib:ShowHint('E', 'Interagieren', 'zone_hint')
    end,
    onExit = function(self)
        print('Zone verlassen')
        exports.ef_lib:HideHint('zone_hint')
    end,
    inside = function(self)
        -- Wird jeden Tick aufgerufen solange der Spieler in der Zone ist
    end,
})

-- Zone entfernen
zone:remove()
```

### Box Zone erstellen

Box Zones verwenden intern die größte Dimension als Radius (vereinfachte Prüfung).

```lua
local zone = exports.ef_lib:CreateBoxZone({
    coords = vector3(100.0, 200.0, 30.0),
    size = vector3(4.0, 6.0, 2.0),
    onEnter = function(self)
        print('Box-Zone betreten')
    end,
    onExit = function(self)
        print('Box-Zone verlassen')
    end,
})
```

---

## Utility Exports

### Model laden

Lädt ein Modell asynchron mit Timeout. Gibt `true` zurück wenn erfolgreich geladen.

```lua
local success = exports.ef_lib:RequestModel('prop_tool_wrench')
-- Oder mit Hash:
local success = exports.ef_lib:RequestModel(joaat('prop_tool_wrench'))
-- Mit Timeout (Standard: 10000ms):
local success = exports.ef_lib:RequestModel('prop_tool_wrench', 5000)
```

### Animation Dictionary laden

Lädt ein Animation Dictionary asynchron mit Timeout.

```lua
local success = exports.ef_lib:RequestAnimDict('mini@repair')
-- Mit Timeout:
local success = exports.ef_lib:RequestAnimDict('mini@repair', 5000)
```

### Hint Position setzen

```lua
exports.ef_lib:SetHintPosition('bottom-left')  -- Standard-Position
```
