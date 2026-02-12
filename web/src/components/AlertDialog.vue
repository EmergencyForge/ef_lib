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
    <div v-if="dialogStore.alertDialogVisible" class="alert-overlay" @click.self="cancel">
      <div class="alert-modal" :class="{ centered: dialogStore.alertDialogData.centered }">
        <!-- Icon -->
        <div class="alert-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
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
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
}

.alert-modal {
  width: 380px;
  background: rgba(20, 20, 20, 0.95);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
  padding: 28px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.alert-modal.centered {
  text-align: center;
  align-items: center;
}

/* Icon */
.alert-icon {
  width: 52px;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(var(--accent-rgb), 0.12);
  border-radius: 50%;
  color: var(--accent-color);
  margin-bottom: 4px;
}

/* Header */
.alert-header {
  font-size: 1.15rem;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

/* Content */
.alert-content {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.55);
  line-height: 1.5;
  margin: 0;
}

/* Buttons */
.alert-buttons {
  display: flex;
  gap: 10px;
  margin-top: 8px;
  width: 100%;
}

.centered .alert-buttons {
  justify-content: center;
}

.btn {
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  border: none;
  transition: all 0.15s ease;
  flex: 1;
}

.btn-cancel {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.7);
}

.btn-cancel:hover {
  background: rgba(255, 255, 255, 0.12);
  color: #ffffff;
}

.btn-confirm {
  background: var(--accent-color);
  color: #ffffff;
}

.btn-confirm:hover {
  filter: brightness(1.15);
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
