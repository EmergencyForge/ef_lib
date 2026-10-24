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
      <TransitionGroup name="hint" tag="div" class="hints-list glass" :class="{ horizontal: isHorizontal, vertical: !isHorizontal }">
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

/* ─── One glass bar, hints are its segments ─── */
.hints-list {
  display: flex;
  padding: 5px;
  border-radius: 23px;
}

.hints-list.horizontal {
  flex-direction: row;
  align-items: center;
}

.hints-list.vertical {
  flex-direction: column;
  align-items: stretch;
  border-radius: 18px;
}

.hint-item {
  display: flex;
  align-items: center;
  gap: 9px;
  height: 36px;
  padding: 0 14px 0 6px;
  white-space: nowrap;
}

.horizontal .hint-item + .hint-item {
  border-left: 1px solid var(--divider);
  padding-left: 14px;
}

.vertical .hint-item + .hint-item {
  border-top: 1px solid var(--divider);
}

.hint-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 26px;
  height: 26px;
  padding: 0 7px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
}

.hint-key {
  background: rgba(255, 255, 255, 0.14);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.25), 0 1px 0 rgba(0, 0, 0, 0.35);
  color: var(--text);
  text-transform: uppercase;
}

.hint-icon {
  background: rgba(var(--accent-rgb), 0.25);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.35);
  color: var(--accent-color);
}

.hint-icon i {
  display: block;
  line-height: 1;
}

.hint-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--text);
}

/* ─── Container: the bar opens from its centre ─── */
.hints-container-enter-active,
.hints-container-leave-active {
  transition: opacity 0.6s ease, transform 0.6s var(--ease);
}

.hints-container-leave-active {
  transition-duration: 0.25s;
  transition-timing-function: var(--exit);
}

.hints-container-enter-active .hints-list {
  transition: clip-path 0.6s var(--ease);
}

.hints-container-enter-from .hints-list {
  clip-path: inset(0 50% 0 50% round 23px);
}

.hints-container-enter-from .vertical.hints-list {
  clip-path: inset(0 0 100% 0 round 18px);
}

.hints-container-enter-from,
.hints-container-leave-to {
  opacity: 0;
}

.pos-bottom-center.hints-container-enter-from,
.pos-bottom-center.hints-container-leave-to {
  transform: translateX(-50%) translateY(10px);
}

.pos-top-center.hints-container-enter-from,
.pos-top-center.hints-container-leave-to {
  transform: translateX(-50%) translateY(-10px);
}

/* ─── Single hints inside an open bar ─── */
.hint-enter-active {
  transition: opacity 0.35s ease 0.08s, transform 0.5s var(--spring) 0.08s;
}

.hint-leave-active {
  transition: opacity 0.18s var(--exit);
}

.hint-enter-from {
  opacity: 0;
  transform: translateY(6px);
}

.hint-leave-to {
  opacity: 0;
}

.hint-move {
  transition: transform 0.4s var(--ease);
}
</style>
