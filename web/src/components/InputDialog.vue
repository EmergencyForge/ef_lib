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

// WebKit has no filled-track pseudo element, the fill is a gradient stop
function sliderPercent(field: { min?: number; max?: number }, value: unknown): number {
  const min = field.min ?? 0
  const max = field.max ?? 100
  return max > min ? ((Number(value) - min) / (max - min)) * 100 : 0
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
  <Transition name="dialog" :duration="{ enter: 550, leave: 180 }">
    <div v-if="dialogStore.inputDialogVisible" class="dialog-overlay" ref="containerRef" @mousedown="onOverlayMouseDown" @click="onOverlayClick">
      <div class="dialog-modal glass">
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
              <div class="checkbox-box" :class="{ checked: dialogStore.inputDialogValues[index] }"></div>
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
                :style="{ '--pct': sliderPercent(field, dialogStore.inputDialogValues[index]) + '%' }"
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
  background: radial-gradient(circle at center, rgba(0, 0, 0, 0.35), rgba(0, 0, 0, 0.6));
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.dialog-modal {
  width: 460px;
  max-height: 80vh;
  padding: 8px;
  display: flex;
  flex-direction: column;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 8px 12px 16px;
}

.dialog-title {
  font-size: 17px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text);
  margin: 0;
}

.dialog-close {
  width: 30px;
  height: 30px;
  padding: 0;
  border: none;
  border-radius: 50%;
  background: var(--fill-2);
  box-shadow: var(--ctl-rim);
  color: var(--text-2);
  font-size: 13px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s ease, color 0.15s ease;
}

.dialog-close i {
  display: block;
  line-height: 1;
}

.dialog-close:hover {
  background: var(--fill-3);
  color: var(--text);
}

/* ─── Fields ─── */

.dialog-fields {
  flex: 1;
  overflow-y: auto;
  padding: 8px 16px 16px;
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
  font-size: 13px;
  font-weight: 500;
  color: var(--text);
}

.field-required {
  color: var(--accent-color);
  margin-left: 2px;
}

.field-description {
  font-size: 12px;
  color: var(--text-3);
  margin-top: -2px;
}

/* Input & Number */
.field-input,
.field-textarea {
  width: 100%;
  padding: 10px 12px;
  border: none;
  border-radius: var(--radius-ctl);
  background: var(--well);
  box-shadow: var(--well-rim);
  color: var(--text);
  font-size: 14px;
  outline: none;
  transition: box-shadow 0.15s ease, background 0.15s ease;
}

.field-input:focus,
.field-textarea:focus {
  background: rgba(0, 0, 0, 0.36);
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.35), inset 0 0 0 1px var(--accent-color), 0 0 0 3px rgba(var(--accent-rgb), 0.2);
}

.field-input::placeholder,
.field-textarea::placeholder {
  color: var(--text-3);
}

.field-textarea {
  resize: vertical;
  min-height: 60px;
}

.field-input[type="number"]::-webkit-inner-spin-button,
.field-input[type="number"]::-webkit-outer-spin-button {
  opacity: 0.5;
}

/* Checkbox as switch */
.field-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 4px 0;
  cursor: pointer;
}

.checkbox-box {
  position: relative;
  width: 40px;
  height: 24px;
  flex-shrink: 0;
  border-radius: var(--radius-pill);
  background: var(--fill-3);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  transition: background 0.2s ease;
}

.checkbox-box::after {
  content: '';
  position: absolute;
  top: 3px;
  left: 3px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
  transition: transform 0.2s var(--ease);
}

.checkbox-box.checked {
  background: var(--accent-color);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.checkbox-box.checked::after {
  transform: translateX(16px);
}

.checkbox-label {
  font-size: 13px;
  color: var(--text-2);
}

/* Select */
.field-select {
  width: 100%;
  padding: 10px 36px 10px 12px;
  border: none;
  border-radius: var(--radius-ctl);
  background-color: var(--fill-2);
  box-shadow: var(--ctl-rim);
  color: var(--text);
  font-size: 14px;
  outline: none;
  appearance: none;
  cursor: pointer;
  transition: box-shadow 0.15s ease, background-color 0.15s ease;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='rgba(255,255,255,0.55)' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
}

.field-select:hover {
  background-color: var(--fill-3);
}

.field-select:focus {
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.14), inset 0 0 0 1px var(--accent-color), 0 0 0 3px rgba(var(--accent-rgb), 0.2);
}

.field-select option {
  background: #1b1b1e;
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
  border-radius: var(--radius-pill);
  background: linear-gradient(90deg, var(--accent-color) var(--pct, 0%), rgba(0, 0, 0, 0.3) var(--pct, 0%));
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06);
  outline: none;
}

.field-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: #ffffff;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.45), inset 0 -2px 0 rgba(0, 0, 0, 0.08);
  cursor: pointer;
  transition: transform 0.15s var(--ease);
}

.field-slider::-webkit-slider-thumb:hover {
  transform: scale(1.1);
}

.slider-value {
  min-width: 44px;
  padding: 4px 8px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
  text-align: center;
  font-size: 12px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: var(--text);
}

/* ─── Footer ─── */

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 12px 8px 8px;
  border-top: 1px solid var(--divider);
}

.btn {
  height: 40px;
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

.dialog-enter-active {
  transition: opacity 0.25s ease-out;
}

.dialog-leave-active {
  transition: opacity 0.18s var(--exit);
}

.dialog-enter-active .dialog-modal {
  transition: transform 0.55s var(--spring), opacity 0.25s ease-out, filter 0.3s ease;
}

.dialog-leave-active .dialog-modal {
  transition: transform 0.18s var(--exit), opacity 0.16s var(--exit);
}

.dialog-enter-from,
.dialog-leave-to {
  opacity: 0;
}

.dialog-enter-from .dialog-modal {
  transform: scale(0.92) translateY(8px);
  opacity: 0;
  filter: blur(6px);
}

.dialog-leave-to .dialog-modal {
  transform: scale(0.97);
  opacity: 0;
}
</style>
