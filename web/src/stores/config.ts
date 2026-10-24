import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const DEFAULT_ACCENT = '#f0500a'

// Dark ink on light accents (EF orange gets #111113), white on dark ones.
// 0.1791 is where contrast against white equals contrast against black.
export function inkOn(hex: string): string {
  const lin = (i: number) => {
    const c = parseInt(hex.substring(i, i + 2), 16) / 255
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
  }
  const l = 0.2126 * lin(1) + 0.7152 * lin(3) + 0.0722 * lin(5)
  return l > 0.1791 ? '#111113' : '#ffffff'
}

export const useConfigStore = defineStore('config', () => {
  const accentColor = ref(DEFAULT_ACCENT)

  // Convert hex to RGB for rgba() usage
  const accentRgb = computed(() => {
    const hex = accentColor.value.replace('#', '')
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)
    return `${r}, ${g}, ${b}`
  })

  function setAccentColor(hex: string) {
    if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
      accentColor.value = hex
      applyTheme()
    }
  }

  function applyTheme() {
    document.documentElement.style.setProperty('--accent-color', accentColor.value)
    document.documentElement.style.setProperty('--accent-rgb', accentRgb.value)
    document.documentElement.style.setProperty('--on-accent', inkOn(accentColor.value))
  }

  // Apply on init
  applyTheme()

  return {
    accentColor,
    accentRgb,
    setAccentColor
  }
})
