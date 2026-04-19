# ef_lib - Notification System

Das Benachrichtigungssystem von **ef_lib** bietet Toast-Notifications mit vier verschiedenen Typen, konfigurierbarer Position und automatischem Timeout. Notifications können sowohl client- als auch serverseitig ausgelöst werden.

---

## Notification-Typen

| Typ | Icon | Akzentfarbe | Beschreibung |
|---|---|---|---|
| `success` | ✓ | Grün (`#22c55e`) | Erfolgreiche Aktionen |
| `error` | ✕ | Rot (`#ef4444`) | Fehlermeldungen |
| `warning` | ! | Orange (`#f59e0b`) | Warnungen |
| `info` | i | Blau (`#3b82f6`) | Informationen |

---

## Client-seitige Verwendung

### Export

```lua
exports.ef_lib:SendNotification(type, title, message, duration)
```

### Parameter

| Parameter | Typ | Standard | Beschreibung |
|---|---|---|---|
| `type` | string | `'info'` | Notification-Typ: `'success'`, `'error'`, `'warning'`, `'info'` |
| `title` | string | `''` | Titel der Benachrichtigung |
| `message` | string | `''` | Nachrichtentext (optional, kann leer sein) |
| `duration` | number | `5000` | Anzeigedauer in Millisekunden |

### Beispiele

```lua
-- Einfache Erfolgsmeldung
exports.ef_lib:SendNotification('success', 'Gespeichert', 'Deine Änderungen wurden gespeichert.', 3000)

-- Fehlermeldung mit Standard-Dauer (5 Sekunden)
exports.ef_lib:SendNotification('error', 'Fehler', 'Die Aktion konnte nicht ausgeführt werden.')

-- Warnung
exports.ef_lib:SendNotification('warning', 'Achtung', 'Du hast nicht genügend Geld.', 4000)

-- Info ohne Nachrichtentext (nur Titel)
exports.ef_lib:SendNotification('info', 'Willkommen!')
```

---

## Server-seitige Verwendung

### Notification an einen bestimmten Spieler

```lua
exports.ef_lib:SendNotification(source, type, title, message, duration)
```

| Parameter | Typ | Standard | Beschreibung |
|---|---|---|---|
| `source` | number | — | Server-ID des Zielspielers |
| `type` | string | `'info'` | Notification-Typ |
| `title` | string | `''` | Titel der Benachrichtigung |
| `message` | string | `''` | Nachrichtentext |
| `duration` | number | `5000` | Anzeigedauer in Millisekunden |

### Notification an alle Spieler

```lua
exports.ef_lib:SendNotificationToAll(type, title, message, duration)
```

| Parameter | Typ | Standard | Beschreibung |
|---|---|---|---|
| `type` | string | `'info'` | Notification-Typ |
| `title` | string | `''` | Titel der Benachrichtigung |
| `message` | string | `''` | Nachrichtentext |
| `duration` | number | `5000` | Anzeigedauer in Millisekunden |

### Beispiele

```lua
-- Benachrichtigung an einen Spieler
exports.ef_lib:SendNotification(source, 'success', 'Gehalt', 'Du hast dein Gehalt erhalten.', 3000)

-- Benachrichtigung an alle Spieler
exports.ef_lib:SendNotificationToAll('warning', 'Serverwarnung', 'Der Server wird in 5 Minuten neugestartet.', 10000)
```

---

## Positionierung

Die Position der Notifications kann vom Spieler über das Einstellungsmenü angepasst werden. Die Einstellung wird im `localStorage` des NUI-Browsers gespeichert und bleibt über Sessions hinweg erhalten.

### Verfügbare Positionen

| Position | Beschreibung |
|---|---|
| `top-right` | Oben rechts **(Standard)** |
| `top-left` | Oben links |
| `bottom-right` | Unten rechts |
| `bottom-left` | Unten links |

Die Position kann programmatisch über das integrierte Einstellungsmenü geändert werden, welches über `exports.ef_lib:GetUISettingsMenu()` als Untermenü eingebunden werden kann.

---

## Events

Das System nutzt intern das NetEvent `ef_lib:notify` zur Kommunikation zwischen Server und Client:

```lua
-- Wird automatisch registriert - kein manuelles Setup nötig
RegisterNetEvent('ef_lib:notify', function(type, title, message, duration)
    SendNotification(type, title, message, duration)
end)
```

Dieses Event kann auch direkt von anderen Server-Ressourcen getriggert werden:

```lua
-- Von einer anderen Server-Ressource aus
TriggerClientEvent('ef_lib:notify', targetSource, 'info', 'Titel', 'Nachricht', 5000)

-- An alle Spieler
TriggerClientEvent('ef_lib:notify', -1, 'info', 'Titel', 'Nachricht', 5000)
```

> [!NOTE]
> Es wird empfohlen, die Exports statt der direkten Events zu verwenden, um Kompatibilität bei zukünftigen Updates sicherzustellen.

---

## UI-Verhalten

- Notifications werden mit einer **Slide-In-Animation** angezeigt (von der jeweiligen Seite)
- Jede Notification hat eine **Timer-Leiste** am unteren Rand, die die verbleibende Anzeigezeit visualisiert
- Notifications können manuell über den **Schließen-Button** (✕) entfernt werden
- Mehrere Notifications werden untereinander gestapelt mit einem Abstand von `10px`
- Breite: mindestens `300px`, maximal `380px`
- Bei `duration: 0` bleibt die Notification dauerhaft sichtbar, bis sie manuell geschlossen wird

---

## Übersicht der Exports

| Export | Seite | Beschreibung |
|---|---|---|
| `SendNotification(type, title, message, duration)` | Client | Notification auf dem eigenen Bildschirm anzeigen |
| `SendNotification(source, type, title, message, duration)` | Server | Notification an einen bestimmten Spieler senden |
| `SendNotificationToAll(type, title, message, duration)` | Server | Notification an alle Spieler senden |
