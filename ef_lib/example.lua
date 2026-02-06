--[[
    ============================================================
    EF Library - Beispiel-Script
    Zeigt alle verfügbaren Features und deren Verwendung.
    ============================================================
    
    MIGRATION VON OX_LIB:
    
    | ox_lib (Alt)                                    | ef_lib (Neu)                                        |
    |-------------------------------------------------|-----------------------------------------------------|
    | lib.callback.await('name', false, ...)          | exports.ef_lib:CallbackAwait('name', ...)           |
    | lib.callback.register('name', fn)               | exports.ef_lib:RegisterCallback('name', fn)         |
    | lib.inputDialog('Title', {...})                  | exports.ef_lib:InputDialog('Title', {...})          |
    | lib.alertDialog({...})                           | exports.ef_lib:AlertDialog({...})                   |
    | lib.notify({...})                               | exports.ef_lib:SendNotification(type, title, msg)   |
    | lib.showTextUI(text)                            | exports.ef_lib:ShowHint(key, label, id)             |
    | lib.hideTextUI()                                | exports.ef_lib:HideHint() / HideAllHints()          |
]]

-- ============================================================
-- SERVER-SEITIGES BEISPIEL (server/*.lua)
-- ============================================================
if IsDuplicityVersion() then

    -- ───────────────────────────────────────────
    -- Callbacks registrieren
    -- ───────────────────────────────────────────
    
    exports.ef_lib:RegisterCallback('myScript:getPlayerMoney', function(source)
        return 50000
    end)
    
    exports.ef_lib:RegisterCallback('myScript:buyItem', function(source, itemName, amount)
        if not itemName or not amount then
            return false, 'Ungültige Parameter'
        end
        return true, 'Erfolgreich gekauft: ' .. amount .. 'x ' .. itemName
    end)
    
    exports.ef_lib:RegisterCallback('myScript:getVehicles', function(source, garageId)
        return {
            { id = 1, model = 'police', plate = 'LSPD 001' },
            { id = 2, model = 'ambulance', plate = 'LSFD 001' },
        }
    end)
    
    exports.ef_lib:RegisterCallback('myScript:createGarage', function(source, data)
        -- data enthält die Werte aus dem InputDialog
        print(('[Server] Garage erstellt: %s (Radius: %s)'):format(data.name, data.radius))
        return true, 'Garage erfolgreich erstellt!'
    end)

-- ============================================================
-- CLIENT-SEITIGES BEISPIEL (client/*.lua)
-- ============================================================
else

    -- ───────────────────────────────────────────
    -- Callbacks (blockierend / await)
    -- ───────────────────────────────────────────
    
    RegisterCommand('testcallback', function()
        local money = exports.ef_lib:CallbackAwait('myScript:getPlayerMoney')
        print('Geld:', money)
        
        local success, msg = exports.ef_lib:CallbackAwait('myScript:buyItem', 'bandage', 5)
        print('Erfolg:', success, 'Nachricht:', msg)
        
        exports.ef_lib:SendNotification('success', 'Callbacks', 'Alle Callbacks funktionieren!', 3000)
    end, false)
    
    -- ───────────────────────────────────────────
    -- Input Dialog
    -- ───────────────────────────────────────────
    
    RegisterCommand('testinput', function()
        -- Einfacher Input Dialog mit verschiedenen Feldtypen
        local result = exports.ef_lib:InputDialog('Garage erstellen', {
            { type = 'input',    label = 'Name',          placeholder = 'z.B. Polizei-Garage', required = true },
            { type = 'number',   label = 'Radius',        default = 10, min = 5, max = 100, step = 5 },
            { type = 'checkbox', label = 'Blip anzeigen', checked = true },
            { type = 'select',   label = 'Fraktion',      options = { 'Polizei', 'Feuerwehr', 'Rettungsdienst' } },
            { type = 'slider',   label = 'Max. Fahrzeuge', min = 1, max = 20, default = 5 },
            { type = 'textarea', label = 'Beschreibung',  placeholder = 'Optionale Beschreibung...' },
        })
        
        if not result then
            exports.ef_lib:SendNotification('warning', 'Abgebrochen', 'Dialog wurde abgebrochen', 3000)
            return
        end
        
        -- result ist ein Array in der Reihenfolge der Felder:
        -- result[1] = Name (string)
        -- result[2] = Radius (number)
        -- result[3] = Blip anzeigen (boolean)
        -- result[4] = Fraktion (string)
        -- result[5] = Max. Fahrzeuge (number)
        -- result[6] = Beschreibung (string)
        
        print('Name:', result[1])
        print('Radius:', result[2])
        print('Blip:', result[3])
        print('Fraktion:', result[4])
        print('Max Fahrzeuge:', result[5])
        print('Beschreibung:', result[6])
        
        -- Daten an Server senden
        local success, msg = exports.ef_lib:CallbackAwait('myScript:createGarage', {
            name = result[1],
            radius = result[2],
            showBlip = result[3],
            faction = result[4],
            maxVehicles = result[5],
            description = result[6],
        })
        
        if success then
            exports.ef_lib:SendNotification('success', 'Garage', msg, 3000)
        else
            exports.ef_lib:SendNotification('error', 'Fehler', msg or 'Unbekannter Fehler', 3000)
        end
    end, false)
    
    -- ───────────────────────────────────────────
    -- Alert Dialog (Bestätigung)
    -- ───────────────────────────────────────────
    
    RegisterCommand('testalert', function()
        -- Einfache Bestätigung
        local result = exports.ef_lib:AlertDialog({
            header = 'Garage löschen?',
            content = 'Möchtest du die Garage "Polizei HQ" wirklich löschen? Alle Fahrzeuge werden entfernt.',
            centered = true,
            cancel = true,
            confirmLabel = 'Ja, löschen',
            cancelLabel = 'Abbrechen'
        })
        
        if result == 'confirm' then
            exports.ef_lib:SendNotification('success', 'Gelöscht', 'Garage wurde gelöscht', 3000)
        else
            exports.ef_lib:SendNotification('info', 'Abgebrochen', 'Löschung abgebrochen', 3000)
        end
    end, false)
    
    -- ───────────────────────────────────────────
    -- Alert Dialog ohne Cancel-Button (nur OK)
    -- ───────────────────────────────────────────
    
    RegisterCommand('testalertinfo', function()
        local result = exports.ef_lib:AlertDialog({
            header = 'Hinweis',
            content = 'Dein Dienstfahrzeug wurde automatisch in die Garage zurückgestellt.',
            centered = true,
            cancel = false,          -- Kein Abbrechen-Button
            confirmLabel = 'Verstanden'
        })
        
        print('User hat bestätigt:', result) -- immer 'confirm'
    end, false)
    
    -- ───────────────────────────────────────────
    -- Kombiniertes Beispiel: Menü → InputDialog → Callback
    -- ───────────────────────────────────────────
    
    RegisterCommand('testflow', function()
        -- 1. Menü anzeigen
        exports.ef_lib:OpenMenu({
            title = 'Garage Verwaltung',
            items = {
                { id = 'create',  label = 'Garage erstellen',  description = 'Neue Garage anlegen', icon = '🏗️' },
                { id = 'list',    label = 'Garagen anzeigen',  description = 'Alle Garagen auflisten', icon = '📋' },
                { id = 'delete',  label = 'Garage löschen',    description = 'Garage entfernen', icon = '🗑️' },
            }
        })
    end, false)
    
    AddEventHandler('ef_lib:menuAction', function(data)
        if data.id == 'create' then
            exports.ef_lib:CloseMenu()
            
            -- 2. InputDialog für Daten
            local result = exports.ef_lib:InputDialog('Neue Garage', {
                { type = 'input',  label = 'Name', required = true, placeholder = 'Garagenname' },
                { type = 'number', label = 'Radius', default = 15, min = 5, max = 50 },
                { type = 'select', label = 'Typ', options = {
                    { label = 'PKW Garage', value = 'car' },
                    { label = 'Boot Garage', value = 'boat' },
                    { label = 'Helikopter', value = 'heli' },
                }},
            })
            
            if result then
                -- 3. Callback an Server
                local success, msg = exports.ef_lib:CallbackAwait('myScript:createGarage', {
                    name = result[1],
                    radius = result[2],
                    type = result[3],
                })
                
                if success then
                    exports.ef_lib:SendNotification('success', 'Erstellt', msg, 3000)
                end
            end
            
        elseif data.id == 'delete' then
            exports.ef_lib:CloseMenu()
            
            -- AlertDialog für Bestätigung
            local confirm = exports.ef_lib:AlertDialog({
                header = 'Wirklich löschen?',
                content = 'Diese Aktion kann nicht rückgängig gemacht werden.',
                confirmLabel = 'Löschen',
                cancelLabel = 'Abbrechen'
            })
            
            if confirm == 'confirm' then
                exports.ef_lib:SendNotification('success', 'Gelöscht', 'Garage wurde entfernt', 3000)
            end
        end
    end)
    
    -- ───────────────────────────────────────────
    -- Hints
    -- ───────────────────────────────────────────
    
    RegisterCommand('testhint', function()
        exports.ef_lib:ShowHint('E', 'Interagieren', 'test_hint')
        Wait(5000)
        exports.ef_lib:HideHint('test_hint')
    end, false)

    -- ProgressBar: Einfach
    RegisterCommand('efprogress', function()
        local completed = exports.ef_lib:ProgressBar({
            label = 'Verarbeitung...',
            duration = 5000,
            icon = 'fa-spinner',
            canCancel = true,
        })
        if completed then
            exports.ef_lib:SendNotification('success', 'Fertig', 'Aktion abgeschlossen!', 3000)
        else
            exports.ef_lib:SendNotification('error', 'Abgebrochen', 'Aktion wurde abgebrochen', 3000)
        end
    end, false)

    -- ProgressBar: Mit Animation + Prop + Control-Disabling
    RegisterCommand('efrepair', function()
        local completed = exports.ef_lib:ProgressBar({
            label = 'Fahrzeug reparieren...',
            duration = 8000,
            icon = 'fa-wrench',
            canCancel = true,
            anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
            prop = { model = 'prop_tool_wrench' },
            disableControls = { move = true, combat = true },
        })
        if completed then
            exports.ef_lib:SendNotification('success', 'Repariert', 'Fahrzeug wurde repariert!', 3000)
        end
    end, false)

end

--[[
    ============================================================
    MIGRATIONS-CHECKLISTE: ox_lib → ef_lib
    ============================================================
    
    | ox_lib (Alt)                                    | ef_lib (Neu)                                        |
    |-------------------------------------------------|-----------------------------------------------------|
    | lib.callback.await('name', false, ...)          | exports.ef_lib:CallbackAwait('name', ...)           |
    | lib.callback.register('name', fn)               | exports.ef_lib:RegisterCallback('name', fn)         |
    | lib.inputDialog('Title', {...})                  | exports.ef_lib:InputDialog('Title', {...})          |
    | lib.alertDialog({...})                           | exports.ef_lib:AlertDialog({...})                   |
    | lib.notify({...})                               | exports.ef_lib:SendNotification(type, title, msg)   |
    | lib.showTextUI(text)                            | exports.ef_lib:ShowHint(key, label, id)             |
    | lib.hideTextUI()                                | exports.ef_lib:HideHint() / HideAllHints()          |
    | lib.registerContext/showContext                  | exports.ef_lib:OpenMenu({...})                      |
    | lib.progressBar({...})                          | exports.ef_lib:ProgressBar({...})                   |
    
    ============================================================
    FELDTYPEN FÜR InputDialog:
    ============================================================
    
    | Typ       | Beschreibung         | Spezielle Optionen                  |
    |-----------|---------------------|-------------------------------------|
    | input     | Textfeld            | placeholder                         |
    | number    | Zahlenfeld          | min, max, step                      |
    | checkbox  | An/Aus              | checked (default: false)            |
    | select    | Dropdown            | options (strings oder {label,value})|
    | slider    | Schieberegler       | min, max, step, default             |
    | textarea  | Mehrzeiliges Text   | placeholder                         |
    
    Alle Felder: label (string), description? (string), required? (bool), default? (any)
    
    ============================================================
]]
