<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useDialogStore, type InputDialogField } from '@/stores/dialog'
import { fetchNui } from '@/composables/useNui'

const dialogStore = useDialogStore()
const containerRef = ref<HTMLElement | null>(null)

function getSelectOptions(field: InputDialogField): Array<{ label: string; value: any }> {
  if (!field.options) return []
  return field.options.map(opt => {
    if (typeof opt === 'object' && opt !== null && 'label' in opt && 'value' in opt) {
      return opt as { label: string; value: any }
    }
    return { label: String(opt), value: opt }
  })
}

function onFieldInput(index: number, event: Event) {
  const target = event.target as HTMLInputElement
  const field = dialogStore.inputDialogFields[index]

  if (field.type === 'number') {
    const num = parseFloat(target.value)
    dialogStore.setInputDialogValue(index, isNaN(num) ? '' : num)
  } else {
    dialogStore.setInputDialogValue(index, target.value)
  }
}

function onCheckboxToggle(index: number) {
  const current = dialogStore.inputDialogValues[index]
  dialogStore.setInputDialogValue(index, !current)
}

function onSelectChange(index: number, event: Event) {
  const target = event.target as HTMLSelectElement
  const field = dialogStore.inputDialogFields[index]
  const options = getSelectOptions(field)
  const selected = options.find(o => String(o.value) === target.value)
  dialogStore.setInputDialogValue(index, selected ? selected.value : target.value)
}

function onSliderInput(index: number, event: Event) {
  const target = event.target as HTMLInputElement
  dialogStore.setInputDialogValue(index, parseFloat(target.value))
}

function confirm() {
  const results = dialogStore.getInputDialogResults()
  if (results === null) {
    // Required fields missing - flash the required ones
    return
  }
  dialogStore.closeInputDialog()
  fetchNui('inputDialogResult', { values: results })
}

function cancel() {
  dialogStore.closeInputDialog()
  fetchNui('inputDialogResult', { values: null })
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
  if (!dialogStore.inputDialogVisible) return

  if (event.key === 'Escape') {
    event.preventDefault()
    event.stopPropagation()
    cancel()
  } else if (event.key === 'Enter' && !(event.target instanceof HTMLTextAreaElement)) {
    // Don't submit on Enter inside textareas
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
  <Transition name="dialog">
    <div v-if="dialogStore.inputDialogVisible" class="dialog-overlay" ref="containerRef" @mousedown="onOverlayMouseDown" @click="onOverlayClick">
      <div class="dialog-modal">
        <!-- Header -->
        <div class="dialog-header">
          <h2 class="dialog-title">{{ dialogStore.inputDialogTitle }}</h2>
          <button class="dialog-close" @click="cancel" aria-label="Close">
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>

        <!-- Fields -->
        <div class="dialog-fields">
          <div
            v-for="(field, index) in dialogStore.inputDialogFields"
            :key="index"
            class="field-group"
          >
            <label class="field-label">
              {{ field.label }}
              <span v-if="field.required" class="field-required">*</span>
            </label>
            <span v-if="field.description" class="field-description">{{ field.description }}</span>

            <!-- Text Input -->
            <input
              v-if="field.type === 'input'"
              type="text"
              class="field-input"
              :placeholder="field.placeholder || ''"
              :value="dialogStore.inputDialogValues[index]"
              @input="onFieldInput(index, $event)"
              @keydown.stop
            />

            <!-- Number Input -->
            <input
              v-else-if="field.type === 'number'"
              type="number"
              class="field-input"
              :placeholder="field.placeholder || ''"
              :value="dialogStore.inputDialogValues[index]"
              :min="field.min"
              :max="field.max"
              :step="field.step || 1"
              @input="onFieldInput(index, $event)"
              @keydown.stop
            />

            <!-- Textarea -->
            <textarea
              v-else-if="field.type === 'textarea'"
              class="field-textarea"
              :placeholder="field.placeholder || ''"
              :value="dialogStore.inputDialogValues[index]"
              @input="onFieldInput(index, $event)"
              @keydown.stop
              rows="3"
            ></textarea>

            <!-- Checkbox -->
            <div
              v-else-if="field.type === 'checkbox'"
              class="field-checkbox"
              :class="{ checked: dialogStore.inputDialogValues[index] }"
              @click="onCheckboxToggle(index)"
            >
              <div class="checkbox-box" :class="{ checked: dialogStore.inputDialogValues[index] }">
                <i v-if="dialogStore.inputDialogValues[index]" class="fa-solid fa-check"></i>
              </div>
              <span class="checkbox-label">{{ dialogStore.inputDialogValues[index] ? 'Aktiviert' : 'Deaktiviert' }}</span>
            </div>

            <!-- Select -->
            <select
              v-else-if="field.type === 'select'"
              class="field-select"
              :value="String(dialogStore.inputDialogValues[index])"
              @change="onSelectChange(index, $event)"
              @keydown.stop
            >
              <option
                v-for="opt in getSelectOptions(field)"
                :key="String(opt.value)"
                :value="String(opt.value)"
              >
                {{ opt.label }}
              </option>
            </select>

            <!-- Slider -->
            <div v-else-if="field.type === 'slider'" class="field-slider-container">
              <input
                type="range"
                class="field-slider"
                :min="field.min ?? 0"
                :max="field.max ?? 100"
                :step="field.step ?? 1"
                :value="dialogStore.inputDialogValues[index]"
                @input="onSliderInput(index, $event)"
              />
              <span class="slider-value">{{ dialogStore.inputDialogValues[index] }}</span>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="dialog-footer">
          <button class="btn btn-cancel" @click="cancel">Abbrechen</button>
          <button class="btn btn-confirm" @click="confirm">Bestätigen</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.dialog-modal {
  width: 460px;
  max-height: 80vh;
  background: linear-gradient(180deg, rgb(24, 24, 28) 0%, rgb(18, 18, 22) 100%);
  border-radius: 5px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  isolation: isolate;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.dialog-title {
  font-size: 1rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
  letter-spacing: -0.01em;
  margin: 0;
}

.dialog-close {
  background: transparent;
  border: none;
  border-radius: 4px;
  padding: 6px 8px;
  color: rgba(255, 255, 255, 0.4);
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.dialog-close i {
  display: block;
  line-height: 1;
}

.dialog-close:hover {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.85);
}

/* ─── Fields ─── */

.dialog-fields {
  flex: 1;
  overflow-y: auto;
  padding: 16px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.field-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 0.9rem;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.9);
}

.field-required {
  color: var(--accent-color);
  margin-left: 2px;
}

.field-description {
  font-size: 0.78rem;
  color: rgba(255, 255, 255, 0.4);
  margin-top: -2px;
}

/* Input & Number */
.field-input,
.field-textarea {
  width: 100%;
  padding: 9px 12px;
  background: rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 4px;
  color: #ffffff;
  font-size: 0.875rem;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s ease, background-color 0.15s ease;
}

.field-input:focus,
.field-textarea:focus {
  border-color: var(--accent-color);
  background: rgba(255, 255, 255, 0.08);
}

.field-input::placeholder,
.field-textarea::placeholder {
  color: rgba(255, 255, 255, 0.3);
}

.field-textarea {
  resize: vertical;
  min-height: 60px;
}

/* Number spinner styling */
.field-input[type="number"]::-webkit-inner-spin-button,
.field-input[type="number"]::-webkit-outer-spin-button {
  opacity: 0.5;
}

/* Checkbox */
.field-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 8px 0;
}

.checkbox-box {
  width: 20px;
  height: 20px;
  border: 1.5px solid rgba(255, 255, 255, 0.25);
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease, border-color 0.15s ease;
  flex-shrink: 0;
}

.checkbox-box.checked {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

.checkbox-box i {
  color: #ffffff;
  font-size: 11px;
  line-height: 1;
}

.checkbox-label {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.6);
}

/* Select */
.field-select {
  width: 100%;
  padding: 9px 12px;
  background-color: rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 4px;
  color: #ffffff;
  font-size: 0.875rem;
  font-family: inherit;
  outline: none;
  appearance: none;
  cursor: pointer;
  transition: border-color 0.15s ease;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='rgba(255,255,255,0.4)' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  padding-right: 36px;
}

.field-select:focus {
  border-color: var(--accent-color);
}

.field-select option {
  background: #1a1a1a;
  color: #ffffff;
}

/* Slider */
.field-slider-container {
  display: flex;
  align-items: center;
  gap: 14px;
}

.field-slider {
  flex: 1;
  height: 6px;
  -webkit-appearance: none;
  appearance: none;
  background: rgba(255, 255, 255, 0.12);
  border-radius: 3px;
  outline: none;
}

.field-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent-color);
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.2);
  transition: transform 0.1s ease;
}

.field-slider::-webkit-slider-thumb:hover {
  transform: scale(1.15);
}

.field-slider::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent-color);
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.2);
}

.slider-value {
  min-width: 40px;
  text-align: center;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--accent-color);
  background: rgba(0, 0, 0, 0.35);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  padding: 3px 8px;
  border-radius: 3px;
  font-variant-numeric: tabular-nums;
}

/* ─── Footer ─── */

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 14px 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(0, 0, 0, 0.2);
}

.btn {
  padding: 9px 18px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  border: none;
  letter-spacing: 0.005em;
  transition: background-color 0.15s ease, color 0.15s ease, filter 0.15s ease;
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

.dialog-enter-active {
  transition: opacity 0.2s ease-out;
}

.dialog-leave-active {
  transition: opacity 0.15s ease-in;
}

.dialog-enter-active .dialog-modal {
  transition: transform 0.2s ease-out, opacity 0.2s ease-out;
}

.dialog-leave-active .dialog-modal {
  transition: transform 0.15s ease-in, opacity 0.15s ease-in;
}

.dialog-enter-from,
.dialog-leave-to {
  opacity: 0;
}

.dialog-enter-from .dialog-modal,
.dialog-leave-to .dialog-modal {
  transform: scale(0.92);
  opacity: 0;
}
</style>
