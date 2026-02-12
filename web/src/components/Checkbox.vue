<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  modelValue: boolean
  label?: string
  disabled?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const isChecked = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

function toggle() {
  if (!props.disabled) {
    isChecked.value = !isChecked.value
  }
}
</script>

<template>
  <div
    class="checkbox-container"
    :class="{ disabled, checked: isChecked }"
    @click="toggle"
  >
    <div class="checkbox">
      <svg
        v-if="isChecked"
        xmlns="http://www.w3.org/2000/svg"
        width="14"
        height="14"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="3"
      >
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
    </div>
    <span v-if="label" class="checkbox-label">{{ label }}</span>
  </div>
</template>

<style scoped>
.checkbox-container {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 6px;
  transition: background 0.15s ease;
}

.checkbox-container:hover {
  background: rgba(255, 255, 255, 0.05);
}

.checkbox-container.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.checkbox {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  background: transparent;
}

.checkbox-container.checked .checkbox {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

.checkbox svg {
  color: #ffffff;
}

.checkbox-label {
  font-size: 0.9rem;
  color: #ffffff;
  user-select: none;
}
</style>
