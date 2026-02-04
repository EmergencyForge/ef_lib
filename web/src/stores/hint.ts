import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface HintData {
  key: string           // The key to press (e.g., "E", "F", "G")
  label: string         // The action label (e.g., "Open Shop", "Talk")
  id?: string           // Optional ID for multiple hints
}

export const useHintStore = defineStore('hint', () => {
  const hints = ref<HintData[]>([])

  function showHint(data: HintData) {
    // Remove existing hint with same ID if it exists
    if (data.id) {
      hints.value = hints.value.filter(h => h.id !== data.id)
    }
    hints.value.push(data)
  }

  function hideHint(id?: string) {
    if (id) {
      hints.value = hints.value.filter(h => h.id !== id)
    } else {
      // Hide all hints
      hints.value = []
    }
  }

  function hideAllHints() {
    hints.value = []
  }

  return {
    hints,
    showHint,
    hideHint,
    hideAllHints
  }
})
