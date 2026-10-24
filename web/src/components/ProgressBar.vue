<script setup lang="ts">
import { onMounted, onUnmounted, computed } from 'vue'
import { useProgressStore } from '@/stores/progress'
import { fetchNui } from '@/composables/useNui'

const store = useProgressStore()

function resolveIconClass(icon: string): string {
  if (!icon) return ''
  if (/^fa-(solid|regular|brands|light|thin|duotone) /.test(icon)) return icon
  if (icon.startsWith('fa-')) return 'fa-solid ' + icon
  return 'fa-solid fa-' + icon
}

function handleCancel() {
  if (store.cancelProgress()) {
    fetchNui('progressBarResult', { completed: false, cancelled: true })
  }
}

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
    <div v-if="store.visible" class="progress-container">
      <div class="progress-pill glass">
        <div class="progress-fill" :style="{ clipPath: `inset(0 ${100 - store.progress * 100}% 0 0 round 22px)` }"></div>
        <div class="progress-content">
          <i v-if="store.icon" class="progress-icon" :class="resolveIconClass(store.icon)"></i>
          <span class="progress-label">{{ store.label }}</span>
          <span class="progress-time">{{ remainingSeconds }} s</span>
        </div>
      </div>

      <div v-if="store.canCancel" class="progress-cancel">
        <span class="cancel-key">{{ cancelLabel }}</span>
        <span class="cancel-text">Abbrechen</span>
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

.progress-pill {
  width: 420px;
  height: 52px;
  border-radius: 26px;
  overflow: hidden;
}

/* Full-width fill revealed by clip-path, so the rounded ends never squash */
.progress-fill {
  position: absolute;
  inset: 4px;
  border-radius: 22px;
  overflow: hidden;
  background: var(--accent-color);
  background-image: linear-gradient(180deg, rgba(255, 255, 255, 0.28), rgba(255, 255, 255, 0) 65%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.45), inset 0 -1px 0 rgba(0, 0, 0, 0.15);
  transition: clip-path 0.08s linear;
}

.progress-fill::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(100deg, transparent 30%, rgba(255, 255, 255, 0.35) 50%, transparent 70%);
  background-size: 200% 100%;
  animation: sheen 1.6s linear infinite;
}

@keyframes sheen {
  from { background-position: 150% 0; }
  to { background-position: -50% 0; }
}

.progress-content {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 20px;
  color: var(--text);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.45);
}

.progress-icon {
  font-size: 14px;
  line-height: 1;
}

.progress-label {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 500;
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
  border-radius: var(--radius-pill);
  background: rgba(10, 10, 12, 0.55);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1), inset 0 0 0 1px rgba(255, 255, 255, 0.06);
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
  border-radius: 10px;
  background: var(--fill-3);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
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
