<script setup lang="ts">
import { useHintStore } from '@/stores/hint'

const hintStore = useHintStore()
</script>

<template>
  <Transition name="hints-container">
    <div v-if="hintStore.hints.length > 0" class="hints-container">
      <TransitionGroup name="hint" tag="div" class="hints-list">
        <div
          v-for="hint in hintStore.hints"
          :key="hint.id || hint.key"
          class="hint-item"
        >
          <div class="hint-key">
            {{ hint.key }}
          </div>
          <div class="hint-label">{{ hint.label }}</div>
        </div>
      </TransitionGroup>
    </div>
  </Transition>
</template>

<style scoped>
.hints-container {
  position: fixed;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1000;
  pointer-events: none;
}

.hints-list {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
}

.hint-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 18px 10px 10px;
  background: rgb(18, 18, 22);
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.5);
}

.hint-key {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 34px;
  height: 34px;
  padding: 0 10px;
  background: rgba(var(--accent-rgb), 0.15);
  border: 1px solid rgba(var(--accent-rgb), 0.3);
  border-radius: 7px;
  font-size: 13px;
  font-weight: 700;
  color: var(--accent-color);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.hint-label {
  font-size: 14px;
  font-weight: 500;
  color: #f0f0f0;
  white-space: nowrap;
}

/* Container transition */
.hints-container-enter-active,
.hints-container-leave-active {
  transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1), transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.hints-container-enter-from,
.hints-container-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(16px);
}

/* Individual hint transitions */
.hint-enter-active,
.hint-leave-active {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.hint-enter-from {
  opacity: 0;
  transform: translateY(12px) scale(0.95);
}

.hint-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(0.95);
}

.hint-move {
  transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>
