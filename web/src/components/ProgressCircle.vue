<script setup lang="ts">
import { computed } from 'vue'
import { resolveIconClass } from '@/composables/icons'
import { fetchNui } from '@/composables/useNui'
import { useProgressStore } from '@/stores/progress'
import { t } from '@/i18n'

// Rendering only. Keys and cancelling live in ProgressBar.vue, which reads the same store.
const store = useProgressStore()
const TICKS = 36

const lit = computed(() => Math.floor(store.progress * TICKS))
const remainingSeconds = computed(() => (Math.max(0, (1 - store.progress) * store.duration) / 1000).toFixed(1))
const cancelLabel = computed(() => (store.cancelKey === 'ESCAPE' ? 'ESC' : store.cancelKey))

function cancel() {
  if (store.cancelProgress()) fetchNui('progressBarResult', { completed: false, cancelled: true })
}
</script>

<template>
  <Transition name="pc">
    <div v-if="store.visible && store.style === 'circle'" class="pc glass">
      <div class="pc-dial">
        <b v-for="i in TICKS" :key="i" :class="{ on: i <= lit }" :style="{ transform: `rotate(${(i - 1) * 10}deg)` }"></b>
        <i :class="resolveIconClass(store.icon || 'fa-hourglass-half')"></i>
      </div>
      <div class="pc-text">
        <div class="pc-label">{{ store.label }}</div>
        <div class="pc-sub">
          <span class="pc-time">{{ remainingSeconds }} s</span>
          <span v-if="store.canCancel" class="pc-cancel" @click="cancel"><kbd class="kbd">{{ cancelLabel }}</kbd> {{ t('Abbrechen') }}</span>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.pc {
  position: fixed;
  bottom: 48px;
  left: 50%;
  z-index: 900;
  display: flex;
  align-items: center;
  gap: 16px;
  max-width: 460px;
  padding: 10px 24px 10px 10px;
  border-radius: 48px;
  transform: translateX(-50%);
  pointer-events: none;
}

.pc-dial {
  position: relative;
  flex: none;
  width: 76px;
  height: 76px;
  display: grid;
  place-items: center;
  font-size: 20px;
  color: var(--accent-color);
}

.pc-dial b {
  position: absolute;
  left: 50%;
  top: 0;
  width: 3px;
  height: 10px;
  margin-left: -1.5px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.12);
  transform-origin: 1.5px 38px;
  transition: background 0.15s ease, box-shadow 0.15s ease;
}

.pc-dial b.on {
  background: var(--accent-color);
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.9);
}

.pc-text {
  min-width: 0;
}

.pc-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 15px;
  font-weight: 600;
  color: var(--text);
}

.pc-sub {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 3px;
  font-size: 12.5px;
  color: var(--text-3);
  white-space: nowrap;
}

.pc-time {
  font-variant-numeric: tabular-nums;
}

.pc-cancel {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  pointer-events: auto;
  cursor: pointer;
  transition: color 0.15s ease;
}

.pc-cancel:hover {
  color: var(--danger);
}

.pc-enter-active {
  transition: opacity 0.3s ease, transform 0.6s var(--spring);
}

.pc-leave-active {
  transition: opacity 0.2s var(--exit), transform 0.22s var(--exit);
}

.pc-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(18px) scale(0.9);
}

.pc-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(8px) scale(0.97);
}
</style>
