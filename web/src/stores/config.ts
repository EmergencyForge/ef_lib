import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useConfigStore = defineStore('config', () => {
  const accentColor = ref('#3b82f6')

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
  }

  // Apply on init
  applyTheme()

  return {
    accentColor,
    accentRgb,
    setAccentColor
  }
})
