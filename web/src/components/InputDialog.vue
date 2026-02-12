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
    <div v-if="dialogStore.inputDialogVisible" class="dialog-overlay" ref="containerRef" @click.self="cancel">
      <div class="dialog-modal">
        <!-- Header -->
        <div class="dialog-header">
          <h2 class="dialog-title">{{ dialogStore.inputDialogTitle }}</h2>
          <button class="dialog-close" @click="cancel">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
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
                <svg v-if="dialogStore.inputDialogValues[index]" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
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
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.dialog-modal {
  width: 440px;
  max-height: 80vh;
  background: rgba(20, 20, 20, 0.95);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.dialog-title {
  font-size: 1.15rem;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.dialog-close {
  background: rgba(255, 255, 255, 0.05);
  border: none;
  border-radius: 6px;
  padding: 6px;
  color: rgba(255, 255, 255, 0.4);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.dialog-close:hover {
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
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
  padding: 10px 14px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  color: #ffffff;
  font-size: 0.9rem;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s ease, background 0.15s ease;
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
  width: 22px;
  height: 22px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  flex-shrink: 0;
}

.checkbox-box.checked {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

.checkbox-box svg {
  color: #ffffff;
}

.checkbox-label {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.6);
}

/* Select */
.field-select {
  width: 100%;
  padding: 10px 14px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  color: #ffffff;
  font-size: 0.9rem;
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
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--accent-color);
  background: rgba(255, 255, 255, 0.06);
  padding: 4px 8px;
  border-radius: 6px;
}

/* ─── Footer ─── */

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 16px 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(0, 0, 0, 0.2);
}

.btn {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  border: none;
  transition: all 0.15s ease;
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
