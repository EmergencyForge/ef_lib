import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { resolveParams, TYPES, type Difficulty, type MinigameType, type Params } from '@/minigames/params'

export type { Difficulty, MinigameType } from '@/minigames/params'

/** What Lua sends: type, difficulty and any parameter to override */
export interface MinigameConfig {
  type: MinigameType
  difficulty?: Difficulty
  [key: string]: unknown
}

export const DIFFICULTY_LABELS: Record<Difficulty, string> = {
  easy: 'Leicht',
  medium: 'Mittel',
  hard: 'Schwer',
  extreme: 'Extrem',
}

export const TYPE_LABELS: Record<MinigameType, { title: string; unit: string }> = {
  lockpick: { title: 'Schloss knacken', unit: 'Pins' },
  safedial: { title: 'Tresor öffnen', unit: 'Codes' },
  reactionchain: { title: 'Reaktionskette', unit: 'Treffer' },
  wires: { title: 'Kabel verbinden', unit: 'Kabel' },
}

export const useMinigameStore = defineStore('minigame', () => {
  const visible = ref(false)
  const gameType = ref<MinigameType>('lockpick')
  const difficulty = ref<Difficulty>('medium')
  const params = ref<Params>(resolveParams('lockpick', 'medium'))
  // Bumped on every open so the game component remounts with fresh state
  const session = ref(0)

  const typeLabel = computed(() => TYPE_LABELS[gameType.value])

  function openMinigame(config: MinigameConfig) {
    if (!TYPES.includes(config.type)) return
    gameType.value = config.type
    difficulty.value = config.difficulty && config.difficulty in DIFFICULTY_LABELS ? config.difficulty : 'medium'
    params.value = resolveParams(gameType.value, difficulty.value, config)
    session.value++
    visible.value = true
  }

  function closeMinigame() {
    visible.value = false
  }

  return {
    visible,
    gameType,
    difficulty,
    params,
    session,
    typeLabel,
    openMinigame,
    closeMinigame,
  }
})
