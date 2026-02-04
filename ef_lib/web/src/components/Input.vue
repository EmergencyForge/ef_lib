<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  modelValue: string
  label?: string
  placeholder?: string
  type?: 'text' | 'password' | 'number' | 'email'
  disabled?: boolean
  maxlength?: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'enter': []
}>()

const inputValue = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter') {
    emit('enter')
  }
  // Prevent menu navigation when typing
  event.stopPropagation()
}
</script>

<template>
  <div class="input-container" :class="{ disabled }">
    <label v-if="label" class="input-label">{{ label }}</label>
    <div class="input-wrapper">
      <input
        v-model="inputValue"
        :type="type || 'text'"
        :placeholder="placeholder"
        :disabled="disabled"
        :maxlength="maxlength"
        class="input"
        @keydown="onKeydown"
      />
    </div>
  </div>
</template>

<style scoped>
.input-container {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.input-container.disabled {
  opacity: 0.5;
}

.input-label {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.6);
  padding-left: 2px;
}

.input-wrapper {
  position: relative;
}

.input {
  width: 100%;
  padding: 12px 14px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #ffffff;
  font-size: 0.9rem;
  font-family: inherit;
  outline: none;
  transition: all 0.15s ease;
}

.input::placeholder {
  color: rgba(255, 255, 255, 0.3);
}

.input:hover:not(:disabled) {
  border-color: rgba(255, 255, 255, 0.2);
}

.input:focus {
  border-color: var(--accent-color);
  background: rgba(var(--accent-rgb), 0.05);
}

.input:disabled {
  cursor: not-allowed;
}

/* Remove number input arrows */
.input[type="number"]::-webkit-outer-spin-button,
.input[type="number"]::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.input[type="number"] {
  -moz-appearance: textfield;
}
</style>
