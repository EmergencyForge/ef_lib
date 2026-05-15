import { defineStore } from 'pinia'
import { ref } from 'vue'

export type HintPosition = 'bottom-center' | 'bottom-left' | 'bottom-right' | 'top-left' | 'top-center' | 'top-right'

export interface HintData {
  key: string           // The key to press (e.g., "E", "F", "G") - empty string for no key
  label: string         // The action label (e.g., "Open Shop", "Talk")
  id?: string           // Optional ID for multiple hints
  icon?: string         // Optional FontAwesome icon (e.g., "fa-solid fa-tv")
}

export const useHintStore = defineStore('hint', () => {
  const hints = ref<HintData[]>([])
  const position = ref<HintPosition>('bottom-left')

  function setPosition(pos: HintPosition) {
    position.value = pos || 'bottom-left'
  }

  function showHint(data: HintData) {
    if (data.id) {
      hints.value = hints.value.filter(h => h.id !== data.id)
    }
    hints.value.push(data)
  }

  function hideHint(id?: string) {
    if (id) {
      hints.value = hints.value.filter(h => h.id !== id)
    } else {
      hints.value = []
    }
  }

  function hideAllHints() {
    hints.value = []
    position.value = 'bottom-left'
  }

  return {
    hints,
    position,
    setPosition,
    showHint,
    hideHint,
    hideAllHints
  }
})
