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
          class="hint-item glass"
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
  padding: 5px 14px 5px 5px;
  border-radius: var(--radius-pill);
}

.hint-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 30px;
  height: 30px;
  padding: 0 9px;
  border-radius: var(--radius-pill);
}

.hint-key {
  background: rgba(255, 255, 255, 0.92);
  color: var(--on-accent);
  box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.15);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
}

.hint-icon {
  background: rgba(var(--accent-rgb), 0.2);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.4);
  color: var(--accent-color);
  font-size: 13px;
  line-height: 1;
}

.hint-icon i {
  display: block;
  line-height: 1;
}

.hint-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--text);
  white-space: nowrap;
}

/* ─── Container Transitions ─── */
.hints-container-enter-active,
.hints-container-leave-active {
  transition: opacity 0.3s ease, transform 0.35s var(--ease);
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
  transition: opacity 0.25s ease, transform 0.3s var(--ease);
}

.hint-enter-from,
.hint-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

.hint-move {
  transition: transform 0.25s var(--ease);
}
</style>
