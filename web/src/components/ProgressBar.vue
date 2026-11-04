<script setup lang="ts">
import { resolveIconClass } from '@/composables/icons'
import { t } from '@/i18n'
import { onMounted, onUnmounted, computed } from 'vue'
import { useProgressStore } from '@/stores/progress'
import { fetchNui } from '@/composables/useNui'

// 59 segments of 4 + 2 px fill the 352 px inside the card exactly
const SEGMENTS = 59

const store = useProgressStore()

function handleCancel() {
  if (store.cancelProgress()) {
    fetchNui('progressBarResult', { completed: false, cancelled: true })
  }
}

// Also serves ProgressCircle, both read this store
function handleKeyDown(e: KeyboardEvent) {
  if (!store.visible || !store.canCancel) return

  if (e.key.toUpperCase() === store.cancelKey || e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    handleCancel()
  }
}

const cancelLabel = computed(() => {
  const key = store.cancelKey
  if (key === 'ESCAPE') return 'ESC'
  return key
})

const fillWidth = computed(() => Math.max(0, Math.floor(store.progress * SEGMENTS) * 6 - 2))

const remainingSeconds = computed(() => {
  const ms = Math.max(0, (1 - store.progress) * store.duration)
  return (ms / 1000).toFixed(1)
})

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown, true)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown, true)
})
</script>

<template>
  <Transition name="progress">
    <div v-if="store.visible && store.style === 'bar'" class="progress-container">
      <div class="progress-card panel">
        <div class="progress-content">
          <i v-if="store.icon" class="progress-icon" :class="resolveIconClass(store.icon)"></i>
          <span class="progress-label">{{ store.label }}</span>
          <span class="progress-time">{{ remainingSeconds }} s</span>
        </div>
        <div class="ef-track"><i :style="{ width: `${fillWidth}px` }"></i></div>
      </div>

      <div v-if="store.canCancel" class="progress-cancel">
        <span class="cancel-key">{{ cancelLabel }}</span>
        <span class="cancel-text">{{ t('Abbrechen') }}</span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.progress-container {
  position: fixed;
  bottom: 48px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 900;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  pointer-events: none;
}

.progress-card {
  width: 380px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.progress-content {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--text);
}

.progress-icon {
  color: var(--accent-color);
  font-size: 14px;
  line-height: 1;
}

.progress-label {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 13px;
  font-weight: 600;
}

.progress-time {
  flex-shrink: 0;
  margin-left: auto;
  font-size: 13px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
}

/* ─── Cancel Hint ─── */

.progress-cancel {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px 4px 4px;
  border-radius: var(--radius-ctl);
  background: var(--surface);
  box-shadow: var(--rim);
  pointer-events: auto;
  cursor: pointer;
}

.cancel-key {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 5px;
  border-radius: 5px;
  background: var(--surface-3);
  color: var(--text);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  transition: background 0.15s ease, color 0.15s ease;
}

.cancel-text {
  font-size: 12px;
  color: var(--text-2);
  transition: color 0.15s ease;
}

.progress-cancel:hover .cancel-key {
  background: rgba(var(--danger-rgb), 0.2);
  color: var(--danger);
}

.progress-cancel:hover .cancel-text {
  color: var(--danger);
}

/* ─── Transitions ─── */

.progress-enter-active {
  transition: opacity 0.3s ease, transform 0.6s var(--spring);
}

.progress-leave-active {
  transition: opacity 0.2s var(--exit), transform 0.22s var(--exit);
}

.progress-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(18px) scale(0.94);
}

.progress-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(8px) scale(0.98);
}
</style>
