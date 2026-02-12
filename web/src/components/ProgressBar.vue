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
      <div class="progress-card">
        <!-- Header: Icon + Label + Percent -->
        <div class="progress-header">
          <div class="progress-info">
            <div v-if="store.icon" class="progress-icon">
              <i :class="resolveIconClass(store.icon)"></i>
            </div>
            <span class="progress-label">{{ store.label }}</span>
          </div>
          <span class="progress-percent">{{ store.progressPercent }}%</span>
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
  width: 320px;
  padding: 16px 20px;
  background: rgb(18, 18, 22);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
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
  width: 30px;
  height: 30px;
  background: rgba(var(--accent-rgb), 0.12);
  border: 1px solid rgba(var(--accent-rgb), 0.25);
  border-radius: 8px;
  color: var(--accent-color);
  font-size: 13px;
  flex-shrink: 0;
}

.progress-label {
  font-size: 14px;
  font-weight: 500;
  color: #f0f0f0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.progress-percent {
  font-size: 13px;
  font-weight: 600;
  color: var(--accent-color);
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
  margin-left: 12px;
}

/* ─── Track & Fill ─── */

.progress-track {
  position: relative;
  width: 100%;
  height: 6px;
  background: rgba(255, 255, 255, 0.06);
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  background: var(--accent-color);
  border-radius: 3px;
  transition: width 0.06s linear;
}

.progress-glow {
  position: absolute;
  top: -4px;
  width: 14px;
  height: 14px;
  background: var(--accent-color);
  border-radius: 50%;
  filter: blur(8px);
  opacity: 0.5;
  transform: translateX(-50%);
  transition: left 0.06s linear;
  pointer-events: none;
}

/* ─── Cancel Hint ─── */

.progress-cancel {
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
  pointer-events: auto;
  cursor: pointer;
}

.cancel-key {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 24px;
  height: 22px;
  padding: 0 6px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: rgba(255, 255, 255, 0.5);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 5px;
}

.cancel-text {
  font-size: 12px;
  font-weight: 400;
  color: rgba(255, 255, 255, 0.35);
}

.progress-cancel:hover .cancel-key {
  color: rgba(255, 80, 80, 0.8);
  border-color: rgba(255, 80, 80, 0.3);
  background: rgba(255, 80, 80, 0.08);
}

.progress-cancel:hover .cancel-text {
  color: rgba(255, 80, 80, 0.6);
}

/* ─── Transitions ─── */

.progress-enter-active {
  transition: opacity 0.25s cubic-bezier(0.4, 0, 0.2, 1),
              transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.progress-leave-active {
  transition: opacity 0.2s cubic-bezier(0.4, 0, 0.2, 1),
              transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
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
