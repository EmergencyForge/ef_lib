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

### 6. Confirmation (Bestätigungsdialog)

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
| ↑ / ↓ | Nach oben/unten navigieren |
| Enter / → | Item aktivieren / Submenu öffnen |
| ESC | Menü/Suche schließen |
| Backspace / ← | Zurück (im Submenu) |
| / | Suche öffnen (bei >5 Items) |

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
exports.ef_lib:OpenMenu(menuData)
exports.ef_lib:CloseMenu()
exports.ef_lib:IsMenuOpen()
exports.ef_lib:GetUISettingsMenu()

-- Notifications
exports.ef_lib:SendNotification(type, title, message, duration)

-- UI Config
exports.ef_lib:SetConfig(config)
exports.ef_lib:SetAccentColor(hexColor)

-- Button Hints
exports.ef_lib:ShowHint(key, label, id)
exports.ef_lib:HideHint(id)
exports.ef_lib:HideAllHints()
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
│   └── main.lua            # Client: Menu, Callbacks, Hints, Notifications
├── server/
│   └── main.lua            # Server: Callbacks, Notifications, Menu Control
└── web/
    ├── src/                # Vue.js Quellcode
    │   ├── components/     # UI Komponenten
    │   ├── stores/         # Pinia Stores
    │   └── composables/    # NUI Kommunikation
    └── dist/               # Gebaute Dateien
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
