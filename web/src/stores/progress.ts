import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface ProgressBarData {
  label: string
  duration: number
  icon?: string
  canCancel?: boolean
  cancelKey?: string
}

export const useProgressStore = defineStore('progress', () => {
  const visible = ref(false)
  const label = ref('')
  const duration = ref(0)
  const icon = ref<string | undefined>(undefined)
  const canCancel = ref(false)
  const cancelKey = ref('X')
  const startTime = ref(0)
  const progress = ref(0)
  const completed = ref(false)

  let animationFrame: number | null = null

  function startProgress(data: ProgressBarData) {
    stopAnimation()
    completed.value = false
    progress.value = 0

    label.value = data.label || ''
    duration.value = data.duration || 5000
    icon.value = data.icon
    canCancel.value = data.canCancel ?? false
    cancelKey.value = (data.cancelKey || 'X').toUpperCase()
    startTime.value = Date.now()

    visible.value = true
    animate()
  }

  function animate() {
    const elapsed = Date.now() - startTime.value
    const pct = Math.min(elapsed / duration.value, 1)
    progress.value = pct

    if (pct >= 1) {
      completed.value = true
      stopAnimation()
      return
    }

    animationFrame = requestAnimationFrame(animate)
  }

  function cancelProgress() {
    if (!canCancel.value || !visible.value) return false
    stopAnimation()
    return true
  }

  function closeProgress() {
    stopAnimation()
  }

  function stopAnimation() {
    if (animationFrame !== null) {
      cancelAnimationFrame(animationFrame)
      animationFrame = null
    }
    visible.value = false
  }

  const progressPercent = computed(() => Math.round(progress.value * 100))

  return {
    visible,
    label,
    duration,
    icon,
    canCancel,
    cancelKey,
    progress,
    progressPercent,
    completed,
    startProgress,
    cancelProgress,
    closeProgress,
  }
})
