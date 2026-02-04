import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { useConfigStore } from './config'

export type MenuPosition = 'left' | 'center' | 'right'
export type NotificationPosition = 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'

const STORAGE_KEY = 'ef_lib_settings'

interface StoredSettings {
  menuPosition: MenuPosition
  accentColor: string
  notificationPosition: NotificationPosition
}

function loadSettings(): StoredSettings {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) {
      const parsed = JSON.parse(stored)
      return {
        menuPosition: parsed.menuPosition || 'left',
        accentColor: parsed.accentColor || '#3b82f6',
        notificationPosition: parsed.notificationPosition || 'top-right'
      }
    }
  } catch (e) {
    console.warn('Failed to load settings:', e)
  }
  return {
    menuPosition: 'left',
    accentColor: '#3b82f6',
    notificationPosition: 'top-right'
  }
}

function saveSettings(settings: StoredSettings) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
  } catch (e) {
    console.warn('Failed to save settings:', e)
  }
}

export const useSettingsStore = defineStore('settings', () => {
  const stored = loadSettings()

  const menuPosition = ref<MenuPosition>(stored.menuPosition)
  const accentColor = ref(stored.accentColor)
  const notificationPosition = ref<NotificationPosition>(stored.notificationPosition)

  const configStore = useConfigStore()

  // Apply accent color on load
  configStore.setAccentColor(accentColor.value)

  // Watch for changes and save
  watch([menuPosition, accentColor, notificationPosition], () => {
    saveSettings({
      menuPosition: menuPosition.value,
      accentColor: accentColor.value,
      notificationPosition: notificationPosition.value
    })
  })

  function setMenuPosition(position: MenuPosition) {
    menuPosition.value = position
  }

  function setAccentColor(color: string) {
    accentColor.value = color
    configStore.setAccentColor(color)
  }

  function setNotificationPosition(position: NotificationPosition) {
    notificationPosition.value = position
  }

  function resetToDefaults() {
    menuPosition.value = 'left'
    accentColor.value = '#3b82f6'
    notificationPosition.value = 'top-right'
    configStore.setAccentColor('#3b82f6')
  }

  return {
    menuPosition,
    accentColor,
    notificationPosition,
    setMenuPosition,
    setAccentColor,
    setNotificationPosition,
    resetToDefaults
  }
})
