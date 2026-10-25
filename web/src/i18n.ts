import { ref } from 'vue'

export type Locale = 'de' | 'en'

// Config.Locale, sent with setConfig. Texts are written in German and looked up here for English,
// so a missing entry shows German instead of a key.
export const locale = ref<Locale>('de')

const en: Record<string, string> = {
  'Abbrechen': 'Cancel',
  'Bestätigen': 'Confirm',
  'Aktiviert': 'On',
  'Deaktiviert': 'Off',
  'Datum wählen': 'Pick a date',
  'Ja': 'Yes',
  'Bist du sicher?': 'Are you sure?',
  'Zurück': 'Back',
  'Navigation': 'Navigate',
  'Auswählen': 'Select',
  'Schließen': 'Close',
  'Testmeldung': 'Test notification',
  'So sehen Meldungen an dieser Position aus.': 'This is how notifications look in this spot.',
  'Zurückgesetzt': 'Reset',
  'Position und Farbe stehen wieder auf Standard.': 'Position and colour are back to their defaults.',
  'Geschafft': 'Done',
  'Fehlgeschlagen': 'Failed',
  'Maus halten': 'Hold mouse',
  'Spannung': 'Tension',
  'Pin setzen': 'Set pin',
  'oder Mausrad drehen': 'or scroll to turn',
  'Zahl prüfen': 'Check number',
  'wenn der Ring das Feld trifft': 'when the ring meets the field',
  'Maus': 'Mouse',
  'Kabel zum passenden Anschluss ziehen': 'Drag each wire to its socket',
  'Nach links drehen': 'Turn left',
  'Nach rechts drehen': 'Turn right',
  'Notiz': 'Note',
  'Schloss knacken': 'Pick the lock',
  'Tresor öffnen': 'Crack the safe',
  'Reaktionskette': 'Reaction chain',
  'Kabel verbinden': 'Connect the wires',
  'Pins': 'pins',
  'Codes': 'codes',
  'Treffer': 'hits',
  'Kabel': 'wires',
  'Annehmen': 'Accept',
  'Ablehnen': 'Decline',
}

export function t(text: string): string {
  return locale.value === 'en' ? en[text] ?? text : text
}
