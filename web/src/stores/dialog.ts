import { defineStore } from 'pinia'
import { ref } from 'vue'

// ─── Input Dialog Types ───

export interface InputDialogField {
  type: 'input' | 'number' | 'checkbox' | 'select' | 'slider' | 'textarea'
  label: string
  description?: string
  placeholder?: string
  required?: boolean
  default?: any
  // For number / slider
  min?: number
  max?: number
  step?: number
  // For checkbox
  checked?: boolean
  // For select
  options?: Array<{ label: string; value: any }> | string[] | number[]
}

export interface InputDialogData {
  title: string
  fields: InputDialogField[]
}

// ─── Alert Dialog Types ───

export interface AlertDialogData {
  header: string
  content?: string
  centered?: boolean
  cancel?: boolean
  confirmLabel?: string
  cancelLabel?: string
}

export const useDialogStore = defineStore('dialog', () => {
  // ─── Input Dialog State ───
  const inputDialogVisible = ref(false)
  const inputDialogTitle = ref('')
  const inputDialogFields = ref<InputDialogField[]>([])
  const inputDialogValues = ref<any[]>([])

  // ─── Alert Dialog State ───
  const alertDialogVisible = ref(false)
  const alertDialogData = ref<AlertDialogData>({
    header: '',
    content: '',
    cancel: true
  })

  // ─── Input Dialog Methods ───

  function openInputDialog(data: InputDialogData) {
    inputDialogTitle.value = data.title || 'Input'
    inputDialogFields.value = data.fields || []

    // Initialize values from defaults
    inputDialogValues.value = data.fields.map(field => {
      if (field.type === 'checkbox') {
        return field.checked ?? field.default ?? false
      }
      if (field.type === 'number' || field.type === 'slider') {
        return field.default ?? field.min ?? 0
      }
      if (field.type === 'select') {
        if (field.default !== undefined) return field.default
        if (field.options && field.options.length > 0) {
          const first = field.options[0]
          return typeof first === 'object' ? first.value : first
        }
        return null
      }
      return field.default ?? ''
    })

    inputDialogVisible.value = true
  }

  function closeInputDialog() {
    inputDialogVisible.value = false
  }

  function setInputDialogValue(index: number, value: any) {
    if (index >= 0 && index < inputDialogValues.value.length) {
      inputDialogValues.value[index] = value
    }
  }

  function getInputDialogResults(): any[] | null {
    // Validate required fields
    for (let i = 0; i < inputDialogFields.value.length; i++) {
      const field = inputDialogFields.value[i]
      const value = inputDialogValues.value[i]

      if (field.required) {
        if (value === '' || value === null || value === undefined) {
          return null
        }
      }
    }

    return [...inputDialogValues.value]
  }

  // ─── Alert Dialog Methods ───

  function openAlertDialog(data: AlertDialogData) {
    alertDialogData.value = {
      header: data.header || 'Confirm',
      content: data.content || '',
      centered: data.centered ?? true,
      cancel: data.cancel ?? true,
      confirmLabel: data.confirmLabel || 'Bestätigen',
      cancelLabel: data.cancelLabel || 'Abbrechen'
    }
    alertDialogVisible.value = true
  }

  function closeAlertDialog() {
    alertDialogVisible.value = false
  }

  return {
    // Input Dialog
    inputDialogVisible,
    inputDialogTitle,
    inputDialogFields,
    inputDialogValues,
    openInputDialog,
    closeInputDialog,
    setInputDialogValue,
    getInputDialogResults,

    // Alert Dialog
    alertDialogVisible,
    alertDialogData,
    openAlertDialog,
    closeAlertDialog
  }
})
