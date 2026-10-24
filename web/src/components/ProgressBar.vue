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
      <div class="progress-card glass">
        <!-- Header: Icon + Label + Time + Percent -->
        <div class="progress-header">
          <div class="progress-info">
            <div v-if="store.icon" class="progress-icon">
              <i :class="resolveIconClass(store.icon)"></i>
            </div>
            <span class="progress-label">{{ store.label }}</span>
          </div>
          <span class="progress-time">{{ remainingSeconds }}s</span>
        </div>

        <!-- Bar -->
        <div class="progress-track">
          <div
            class="progress-fill"
            :style="{ width: (store.progress * 100) + '%' }"
          />
          <div
            class="progress-glow"
            :style="{ left: (store.progress * 100) + '%' }"
          />
        </div>

        <!-- Cancel hint -->
        <div v-if="store.canCancel" class="progress-cancel">
          <span class="cancel-key">{{ cancelLabel }}</span>
          <span class="cancel-text">Abbrechen</span>
        </div>
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
  pointer-events: none;
}

.progress-card {
  width: 400px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ─── Header ─── */

.progress-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.progress-info {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  flex: 1;
}

.progress-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  flex-shrink: 0;
  border-radius: 50%;
  background: rgba(var(--accent-rgb), 0.2);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.35);
  color: var(--accent-color);
  font-size: 13px;
  line-height: 1;
}

.progress-icon i {
  display: block;
  line-height: 1;
}

.progress-label {
  font-size: 14px;
  font-weight: 500;
  color: var(--text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.progress-time {
  flex-shrink: 0;
  margin-left: 12px;
  font-size: 13px;
  font-weight: 500;
  color: var(--text-2);
  font-variant-numeric: tabular-nums;
}

/* ─── Track & Fill ─── */

.progress-track {
  position: relative;
  width: 100%;
  height: 8px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
  overflow: hidden;
}

.progress-fill {
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  border-radius: inherit;
  background: var(--accent-color);
  /* Highlight on top of the tube, works for any accent colour */
  background-image: linear-gradient(180deg, rgba(255, 255, 255, 0.35), rgba(255, 255, 255, 0) 60%);
  box-shadow: 0 0 12px rgba(var(--accent-rgb), 0.6);
  transition: width 0.06s linear;
}

.progress-glow {
  display: none;
}

/* ─── Cancel Hint ─── */

.progress-cancel {
  display: flex;
  align-items: center;
  gap: 6px;
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
  border-radius: 6px;
  background: var(--fill-3);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 1px 0 rgba(0, 0, 0, 0.4);
  color: var(--text);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  transition: background 0.15s ease, color 0.15s ease;
}

.cancel-text {
  font-size: 12px;
  color: var(--text-3);
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
  transition: opacity 0.25s ease, transform 0.35s var(--ease);
}

.progress-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.progress-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(20px);
}

.progress-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(12px);
}
</style>
