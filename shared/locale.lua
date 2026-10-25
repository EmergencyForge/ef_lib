-- Visible texts are written in German. With Config.Locale = 'en' they are looked up here, anything missing stays German.
local en = {
    ['Neue Version verfügbar: v%s (%s)'] = 'New version available: v%s (%s)',
    ['Oberfläche'] = 'Interface',
    ['Menüposition und Farbe'] = 'Menu position and colour',
    ['Menüposition'] = 'Menu position',
    ['Akzentfarbe'] = 'Accent colour',
    ['Meldungen'] = 'Notifications',
    ['Position der Meldungen'] = 'Where notifications appear',
    ['Position'] = 'Position',
    ['Testmeldung'] = 'Test notification',
    ['Zeigt eine Meldung an der gewählten Position'] = 'Shows a notification at the chosen position',
    ['Zurücksetzen'] = 'Reset',
    ['Standardwerte wiederherstellen'] = 'Restore the defaults',
    ['Einstellungen zurücksetzen?'] = 'Reset settings?',
    ['Position und Farbe gehen auf die Standardwerte zurück.'] = 'Position and colour go back to their defaults.',
    ['Abbrechen'] = 'Cancel',
    ['Anfrage annehmen'] = 'Accept request',
    ['Anfrage ablehnen'] = 'Decline request',
    ['Links'] = 'Left',
    ['Mitte'] = 'Centre',
    ['Rechts'] = 'Right',
    ['Oben rechts'] = 'Top right',
    ['Oben links'] = 'Top left',
    ['Unten rechts'] = 'Bottom right',
    ['Unten links'] = 'Bottom left',
}

function L(text, ...)
    if Config.Locale == 'en' then text = en[text] or text end
    if select('#', ...) > 0 then return text:format(...) end
    return text
end
