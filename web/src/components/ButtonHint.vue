<script setup lang="ts">
import { resolveIconClass } from '@/composables/icons'
import { computed } from 'vue'
import { useHintStore } from '@/stores/hint'

const hintStore = useHintStore()

const positionClass = computed(() => `pos-${hintStore.position}`)

const isHorizontal = computed(() =>
  hintStore.position === 'bottom-center' || hintStore.position === 'top-center'
)
</script>

<template>
  <Transition name="hints-container">
    <div v-if="hintStore.hints.length > 0" class="hints-container" :class="positionClass">
      <TransitionGroup name="hint" tag="div" class="hints-list panel" :class="{ horizontal: isHorizontal, vertical: !isHorizontal }">
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

/* ─── One bar, hints are its segments ─── */
.hints-list {
  display: flex;
  padding: 4px;
}

.hints-list.horizontal {
  flex-direction: row;
  align-items: center;
}

.hints-list.vertical {
  flex-direction: column;
  align-items: stretch;
  min-width: 230px;
  padding: 8px 12px;
}

.hint-item {
  display: flex;
  align-items: center;
  gap: 9px;
  height: 30px;
  padding: 0 12px 0 4px;
  white-space: nowrap;
}

.horizontal .hint-item + .hint-item {
  border-left: 1px solid var(--divider);
  padding-left: 12px;
}

/* A list of keys: label left, key right */
.vertical .hint-item {
  flex-direction: row-reverse;
  justify-content: space-between;
  height: 28px;
  padding: 0;
}

.hint-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 5px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1;
}

.hint-key {
  background: var(--surface-3);
  box-shadow: inset 0 0 0 1px var(--line-2);
  color: var(--text);
  text-transform: uppercase;
}

.hint-icon {
  color: var(--text-2);
}

.hint-icon i {
  display: block;
  line-height: 1;
}

.hint-label {
  font-size: 12.5px;
  font-weight: 500;
  color: var(--text-2);
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
  clip-path: inset(0 50% 0 50% round 8px);
}

.hints-container-enter-from .vertical.hints-list {
  clip-path: inset(0 0 100% 0 round 8px);
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
