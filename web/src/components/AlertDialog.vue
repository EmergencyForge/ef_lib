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
      <div class="alert-modal" :class="{ centered: dialogStore.alertDialogData.centered }">
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
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
}

.alert-modal {
  width: 400px;
  background: linear-gradient(180deg, rgb(24, 24, 28) 0%, rgb(18, 18, 22) 100%);
  border-radius: 5px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  padding: 22px 22px 20px 22px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  isolation: isolate;
}

.alert-modal.centered {
  text-align: center;
  align-items: center;
}

/* Icon */
.alert-icon {
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(var(--accent-rgb), 0.22), rgba(var(--accent-rgb), 0.08));
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.25);
  border-radius: 4px;
  color: var(--accent-color);
  font-size: 14px;
  line-height: 1;
  margin-bottom: 2px;
}

.alert-icon i {
  display: block;
  line-height: 1;
}

/* Header */
.alert-header {
  font-size: 1rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
  letter-spacing: -0.01em;
  margin: 0;
}

/* Content */
.alert-content {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.5;
  margin: 0;
}

/* Buttons */
.alert-buttons {
  display: flex;
  gap: 8px;
  margin-top: 10px;
  width: 100%;
}

.centered .alert-buttons {
  justify-content: center;
}

.btn {
  padding: 9px 20px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  border: none;
  letter-spacing: 0.005em;
  transition: background-color 0.15s ease, color 0.15s ease, filter 0.15s ease;
  flex: 1;
}

.btn-cancel {
  background: rgba(255, 255, 255, 0.05);
  color: rgba(255, 255, 255, 0.7);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.1);
}

.btn-cancel:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #ffffff;
}

.btn-confirm {
  background: var(--accent-color);
  color: #ffffff;
}

.btn-confirm:hover {
  filter: brightness(1.12);
}

/* ─── Transitions ─── */

.alert-enter-active {
  transition: opacity 0.2s ease-out;
}

.alert-leave-active {
  transition: opacity 0.15s ease-in;
}

.alert-enter-active .alert-modal {
  transition: transform 0.2s ease-out, opacity 0.2s ease-out;
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
  transform: scale(0.92);
  opacity: 0;
}
</style>
