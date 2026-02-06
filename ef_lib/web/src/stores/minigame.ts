import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export type MinigameType = 'lockpick' | 'safedial' | 'reactionchain'
export type Difficulty = 'easy' | 'medium' | 'hard' | 'extreme'

export interface MinigameConfig {
  type: MinigameType
  difficulty: Difficulty
  retries?: number
}

export const DIFFICULTY_LABELS: Record<Difficulty, string> = {
  easy: 'Leicht',
  medium: 'Mittel',
  hard: 'Schwer',
  extreme: 'Extrem',
}

export const TYPE_LABELS: Record<MinigameType, { title: string; subtitle: string }> = {
  lockpick: { title: 'Lockpick', subtitle: 'Pin-Tumbler Schloss' },
  safedial: { title: 'Safe Dial', subtitle: 'Kombinations-Tresor' },
  reactionchain: { title: 'Reaction Chain', subtitle: 'Reaktionstest' },
}

export const useMinigameStore = defineStore('minigame', () => {
  const visible = ref(false)
  const gameType = ref<MinigameType>('lockpick')
  const difficulty = ref<Difficulty>('medium')
  const customRetries = ref<number | null>(null)

  const typeLabel = computed(() => TYPE_LABELS[gameType.value])
  const diffLabel = computed(() => DIFFICULTY_LABELS[difficulty.value])

  function openMinigame(config: MinigameConfig) {
    gameType.value = config.type
    difficulty.value = config.difficulty || 'medium'
    customRetries.value = config.retries ?? null
    visible.value = true
  }

  function closeMinigame() {
    visible.value = false
  }

  return {
    visible,
    gameType,
    difficulty,
    customRetries,
    typeLabel,
    diffLabel,
    openMinigame,
    closeMinigame,
  }
})
