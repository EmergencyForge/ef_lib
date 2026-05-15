<script setup lang="ts">
import { computed } from 'vue'
import { useHintStore } from '@/stores/hint'

const hintStore = useHintStore()

function resolveIconClass(icon: string): string {
  if (!icon) return ''
  if (/^fa-(solid|regular|brands|light|thin|duotone) /.test(icon)) return icon
  if (icon.startsWith('fa-')) return 'fa-solid ' + icon
  return 'fa-solid fa-' + icon
}

const positionClass = computed(() => `pos-${hintStore.position}`)

const isHorizontal = computed(() =>
  hintStore.position === 'bottom-center' || hintStore.position === 'top-center'
)
</script>

<template>
  <Transition name="hints-container">
    <div v-if="hintStore.hints.length > 0" class="hints-container" :class="positionClass">
      <TransitionGroup name="hint" tag="div" class="hints-list" :class="{ horizontal: isHorizontal, vertical: !isHorizontal }">
        <div
          v-for="hint in hintStore.hints"
          :key="hint.id || hint.key"
          class="hint-item"
        >
          <div v-if="hint.icon" class="hint-badge hint-icon">
            <i :class="resolveIconClass(hint.icon)"></i>
          </div>
          <div v-else-if="hint.key" class="hint-badge hint-key">
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
  z-index: 1000;
  pointer-events: none;
}

/* ─── Positions ─── */
.pos-bottom-center {
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
}

.pos-bottom-left {
  bottom: 40px;
  left: 40px;
}

.pos-bottom-right {
  bottom: 40px;
  right: 40px;
}

.pos-top-left {
  top: 40px;
  left: 40px;
}

.pos-top-center {
  top: 40px;
  left: 50%;
  transform: translateX(-50%);
}

.pos-top-right {
  top: 40px;
  right: 40px;
}

/* ─── Layout ─── */
.hints-list.horizontal {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  justify-content: center;
}

.hints-list.vertical {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-start;
}

.pos-bottom-right .hints-list.vertical,
.pos-top-right .hints-list.vertical {
  align-items: flex-end;
}

/* ─── Items ─── */
.hint-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0;
  background: transparent;
  border: none;
  box-shadow: none;
  filter: drop-shadow(0 2px 5px rgba(0, 0, 0, 0.7));
}

.hint-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 28px;
  height: 28px;
  padding: 0 8px;
  background: rgba(0, 0, 0, 0.6);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  color: #ffffff;
}

.hint-key {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  text-shadow: 0 1px 1px rgba(0, 0, 0, 0.8);
}

.hint-icon {
  font-size: 14px;
  line-height: 1;
  color: var(--accent-color);
}

.hint-icon i {
  display: block;
  line-height: 1;
}

.hint-label {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: -0.005em;
  white-space: nowrap;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.85), 0 0 1px rgba(0, 0, 0, 0.9);
}

/* ─── Container Transitions ─── */
.hints-container-enter-active,
.hints-container-leave-active {
  transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1), transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.pos-bottom-center.hints-container-enter-from,
.pos-bottom-center.hints-container-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(16px);
}

.pos-top-center.hints-container-enter-from,
.pos-top-center.hints-container-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(-16px);
}

.pos-bottom-left.hints-container-enter-from,
.pos-bottom-left.hints-container-leave-to,
.pos-top-left.hints-container-enter-from,
.pos-top-left.hints-container-leave-to {
  opacity: 0;
  transform: translateX(-16px);
}

.pos-bottom-right.hints-container-enter-from,
.pos-bottom-right.hints-container-leave-to,
.pos-top-right.hints-container-enter-from,
.pos-top-right.hints-container-leave-to {
  opacity: 0;
  transform: translateX(16px);
}

/* ─── Item Transitions ─── */
.hint-enter-active,
.hint-leave-active {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.hint-enter-from {
  opacity: 0;
  transform: scale(0.95);
}

.hint-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

.hint-move {
  transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>
