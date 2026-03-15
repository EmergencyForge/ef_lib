# ef_lib - Core UI Framework für FiveM

![GitHub commit activity](https://img.shields.io/github/commit-activity/m/EmergencyForge/ef_lib)

Das Ziel von **ef_lib** ist es, eine umfassende und moderne UI-Bibliothek für FiveM-Server bereitzustellen. Das Framework bietet ein vollständiges Menü-, Dialog-, Benachrichtigungs- und Interaktionssystem und dient als Alternative zu bestehenden Lösungen wie ox_lib. Die Benutzeroberfläche basiert auf **Vue.js 3** mit **TypeScript** und lässt sich über eine einfache Konfiguration an das eigene Serverprojekt anpassen. Das System befindet sich aktuell in Entwicklung und wird stetig erweitert.

### **Der Vorteil - immer kostenlos & immer Open Source!**

Das Projekt wird hobbymäßig von **EmergencyForge** entwickelt und ist für jegliche Unterstützung, Anpassungen, Wünsche & Ideen offen. Das Projekt ist vollkommen Open Source und kann von jedem angewandt, umgesetzt und verändert/angepasst werden.

---

## Features

- **Menüsystem** - Dynamische Menüs mit Buttons, Checkboxen, Inputs, Selects, Nummernfeldern, Untermenüs & Bestätigungen inkl. Suchfunktion
- **Dialogsystem** - Input-Dialoge mit verschiedenen Feldtypen (Input, Number, Checkbox, Select, Slider, Textarea) sowie Alert-Dialoge
- **Callback-System** - Synchrone & asynchrone Client-Server-Kommunikation mit automatischem Timeout und Cleanup
- **Benachrichtigungen** - Toast-Notifications mit den Typen: Success, Error, Warning & Info
- **Minispiele** - Drei integrierte Skillchecks: Lockpick, Tresor-Dial & Reaction Chain mit konfigurierbaren Schwierigkeitsgraden
- **Progressbar** - Fortschrittsanzeige mit Animationen, Prop-Attachment und Steuerungssperren
- **Zonen** - Sphere- und Box-Zonen mit onEnter, onExit & inside-Callbacks
- **Button Hints** - Interaktive Tastaturhinweise (z. B. E, F)
- **Context Menu** - Kontextmenü-System (ox_lib-kompatibel)
- **Vehicle Properties** - Vollständiges Fahrzeugeigenschaften-System zum Speichern & Wiederherstellen (ox_lib-kompatibel)
- **UI-Konfiguration** - Anpassbare Akzentfarbe, Cursor- und Bewegungseinstellungen pro Menü oder global

---

## Benutzte Assets & Technologien

- [Vue.js 3](https://vuejs.org/) mit [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vitejs.dev/) als Build-Tool
- [Pinia](https://pinia.vuejs.org/) für State Management
- [Font Awesome (Free)](https://fontawesome.com/)

---

## Installation

1. Repository klonen oder herunterladen
2. In den `web/`-Ordner wechseln und `npm install` sowie `npm run build` ausführen
3. Die Resource in den Server-Resourcen-Ordner verschieben
4. `ensure ef_lib` in die `server.cfg` eintragen
5. Konfiguration in `config.lua` nach Bedarf anpassen

---

## Konfiguration

| Einstellung | Typ | Standard | Beschreibung |
|---|---|---|---|
| `Config.AccentColor` | string | `'#ff0000'` | Akzentfarbe der UI (HEX) |
| `Config.EnableDemo` | boolean | `false` | Demo-Menü per F2 anzeigen |
| `Config.ShowCursor` | boolean | `false` | Globale Cursor-Sichtbarkeit |
| `Config.AllowMove` | boolean | `true` | Spielerbewegung in Menüs erlauben |

---

## Dokumentation

Eine vollständige Dokumentation aller Exports, Funktionen und Anwendungsbeispiele befindet sich in der [DOCUMENTATION.md](DOCUMENTATION.md). Zusätzlich enthält die [example.lua](example.lua) praxisnahe Codebeispiele für alle Features.

---

> [!CAUTION]
> Es handelt sich hierbei um ein **kontinuierliches Entwicklungsprojekt**! Es kommt zu stetigen Anpassungen. Wir garantieren **nicht** für Fehlerfreiheit und Datensicherheit!
