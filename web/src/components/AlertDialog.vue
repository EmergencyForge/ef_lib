<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useDialogStore } from '@/stores/dialog'
import { fetchNui } from '@/composables/useNui'

const dialogStore = useDialogStore()

function confirm() {
  dialogStore.closeAlertDialog()
  fetchNui('alertDialogResult', { result: 'confirm' })
}

function cancel() {
  dialogStore.closeAlertDialog()
  fetchNui('alertDialogResult', { result: 'cancel' })
}

// Only cancel when both mousedown and mouseup happen on the overlay itself,
// so dragging a text selection out of the modal doesn't close it.
let overlayMouseDown = false

function onOverlayMouseDown(e: MouseEvent) {
  overlayMouseDown = e.target === e.currentTarget
}

function onOverlayClick(e: MouseEvent) {
  if (overlayMouseDown && e.target === e.currentTarget) cancel()
  overlayMouseDown = false
}

function handleKeyDown(event: KeyboardEvent) {
  if (!dialogStore.alertDialogVisible) return

  if (event.key === 'Escape') {
    event.preventDefault()
    event.stopPropagation()
    cancel()
  } else if (event.key === 'Enter') {
    event.preventDefault()
    event.stopPropagation()
    confirm()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown, true)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown, true)
})
</script>

<template>
  <Transition name="alert">
    <div v-if="dialogStore.alertDialogVisible" class="alert-overlay" @mousedown="onOverlayMouseDown" @click="onOverlayClick">
      <div class="alert-modal glass" :class="{ centered: dialogStore.alertDialogData.centered }">
        <!-- Icon -->
        <div class="alert-icon">
          <i class="fa-solid fa-circle-exclamation"></i>
        </div>

        <!-- Header -->
        <h2 class="alert-header">{{ dialogStore.alertDialogData.header }}</h2>

        <!-- Content -->
        <p v-if="dialogStore.alertDialogData.content" class="alert-content">
          {{ dialogStore.alertDialogData.content }}
        </p>

        <!-- Buttons -->
        <div class="alert-buttons">
          <button
            v-if="dialogStore.alertDialogData.cancel"
            class="btn btn-cancel"
            @click="cancel"
          >
            {{ dialogStore.alertDialogData.cancelLabel || 'Abbrechen' }}
          </button>
          <button class="btn btn-confirm" @click="confirm">
            {{ dialogStore.alertDialogData.confirmLabel || 'Bestätigen' }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.alert-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at center, rgba(0, 0, 0, 0.35), rgba(0, 0, 0, 0.6));
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
}

.alert-modal {
  width: 420px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.alert-modal.centered {
  text-align: center;
  align-items: center;
}

/* Icon */
.alert-icon {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  border-radius: 50%;
  background: rgba(var(--accent-rgb), 0.18);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.2);
  color: var(--accent-color);
  font-size: 19px;
  line-height: 1;
}

.alert-icon i {
  display: block;
  line-height: 1;
}

/* Header */
.alert-header {
  font-size: 18px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text);
  margin: 0;
}

/* Content */
.alert-content {
  font-size: 14px;
  line-height: 1.5;
  color: var(--text-2);
  margin: 0;
}

/* Buttons */
.alert-buttons {
  display: flex;
  gap: 10px;
  margin-top: 16px;
  width: 100%;
}

.centered .alert-buttons {
  justify-content: center;
}

.btn {
  flex: 1;
  height: 42px;
  padding: 0 20px;
  border: none;
  border-radius: var(--radius-ctl);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease, filter 0.15s ease;
}

.btn-cancel {
  background: var(--fill-2);
  color: var(--text);
  box-shadow: var(--ctl-rim);
}

.btn-cancel:hover {
  background: var(--fill-3);
}

.btn-confirm {
  background: var(--accent-color);
  background-image: linear-gradient(180deg, rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0));
  color: var(--on-accent);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 6px 18px -6px rgba(var(--accent-rgb), 0.7);
}

.btn-confirm:hover {
  filter: brightness(1.08);
}

/* ─── Transitions ─── */

.alert-enter-active {
  transition: opacity 0.2s ease-out;
}

.alert-leave-active {
  transition: opacity 0.15s ease-in;
}

.alert-enter-active .alert-modal {
  transition: transform 0.3s var(--ease), opacity 0.2s ease-out;
}

.alert-leave-active .alert-modal {
  transition: transform 0.15s ease-in, opacity 0.15s ease-in;
}

.alert-enter-from,
.alert-leave-to {
  opacity: 0;
}

.alert-enter-from .alert-modal,
.alert-leave-to .alert-modal {
  transform: scale(0.94);
  opacity: 0;
}
</style>
