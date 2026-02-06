<script setup lang="ts">
import { onMounted } from 'vue'
import Menu from '@/components/Menu.vue'
import Notifications from '@/components/Notifications.vue'
import ButtonHint from '@/components/ButtonHint.vue'
import InputDialog from '@/components/InputDialog.vue'
import AlertDialog from '@/components/AlertDialog.vue'
import Minigame from '@/components/Minigame.vue'
import ProgressBar from '@/components/ProgressBar.vue'
import { useMenuStore } from '@/stores/menu'
import { useNotificationStore } from '@/stores/notification'
import { useSettingsStore } from '@/stores/settings'
import { useHintStore } from '@/stores/hint'
import { useDialogStore } from '@/stores/dialog'
import { useMinigameStore, type MinigameConfig } from '@/stores/minigame'
import { useProgressStore, type ProgressBarData } from '@/stores/progress'
import { useNuiEvent, fetchNui, isInGame } from '@/composables/useNui'

const menuStore = useMenuStore()
const notificationStore = useNotificationStore()
const settingsStore = useSettingsStore()
const hintStore = useHintStore()
const dialogStore = useDialogStore()
const minigameStore = useMinigameStore()
const progressStore = useProgressStore()

// ─── Menu Events ───

useNuiEvent('setVisible', (visible: boolean) => {
  menuStore.setVisible(visible)
})

useNuiEvent('openMenu', (data: { title?: string; items: any[] }) => {
  menuStore.openMenu(data)
})

useNuiEvent('pushSubmenu', (data: { title?: string; items: any[] }) => {
  menuStore.openSubmenu(data)
})

useNuiEvent('closeMenu', () => {
  menuStore.closeMenu()
})

// ─── Notification Events ───

useNuiEvent('notification', (data: {
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message: string
  duration: number
}) => {
  notificationStore.addNotification(data.type, data.title, data.message, data.duration)
})

// ─── Config Events ───

useNuiEvent('setConfig', (data: { accentColor?: string }) => {
  // Only apply server config if user hasn't customized
  if (data.accentColor && settingsStore.accentColor === '#3b82f6') {
    settingsStore.setAccentColor(data.accentColor)
  }
})

// ─── Hint Events ───

useNuiEvent('setHintPosition', (data: { position: string }) => {
  hintStore.setPosition(data.position as any)
})

useNuiEvent('showHint', (data: { key: string; label: string; id?: string; icon?: string }) => {
  hintStore.showHint(data)
})

useNuiEvent('hideHint', (data?: { id?: string }) => {
  hintStore.hideHint(data?.id)
})

useNuiEvent('hideAllHints', () => {
  hintStore.hideAllHints()
})

// ─── Input Dialog Events ───

useNuiEvent('openInputDialog', (data: { title: string; fields: any[] }) => {
  dialogStore.openInputDialog(data)
})

useNuiEvent('closeInputDialog', () => {
  dialogStore.closeInputDialog()
})

// ─── Alert Dialog Events ───

useNuiEvent('openAlertDialog', (data: {
  header: string
  content?: string
  centered?: boolean
  cancel?: boolean
  confirmLabel?: string
  cancelLabel?: string
}) => {
  dialogStore.openAlertDialog(data)
})

useNuiEvent('closeAlertDialog', () => {
  dialogStore.closeAlertDialog()
})

// ─── Minigame Events ───

useNuiEvent('openMinigame', (data: MinigameConfig) => {
  minigameStore.openMinigame(data)
})

useNuiEvent('closeMinigame', () => {
  minigameStore.closeMinigame()
})

// ─── ProgressBar Events ───

useNuiEvent('startProgressBar', (data: ProgressBarData) => {
  progressStore.startProgress(data)
})

useNuiEvent('cancelProgressBar', () => {
  progressStore.closeProgress()
})

// ─── Settings Submenu ───

const settingsSubmenu = {
  title: 'UI Settings',
  items: [
    {
      id: '_settings_position',
      label: 'Menu Position',
      type: 'select' as const,
      value: settingsStore.menuPosition,
      options: ['left', 'center', 'right']
    },
    {
      id: '_settings_color',
      label: 'Accent Color',
      type: 'input' as const,
      value: settingsStore.accentColor,
      placeholder: '#ff0000'
    },
    {
      id: '_settings_reset',
      label: 'Reset to Defaults',
      description: 'Restore default settings'
    }
  ]
}

// Demo menu data with different item types
const demoMenu = {
  title: 'EF Menu',
  items: [
    { id: 'character', label: 'Character', description: 'Manage your character' },
    { id: 'inventory', label: 'Inventory', description: 'View your inventory' },
    {
      id: 'settings',
      label: 'Settings',
      description: 'Open settings menu',
      submenu: {
        title: 'Settings',
        items: [
          { id: 'notifications', label: 'Notifications', type: 'checkbox' as const, checked: true },
          { id: 'sound', label: 'Sound Effects', type: 'checkbox' as const, checked: false },
          { id: 'username', label: 'Username', type: 'input' as const, placeholder: 'Enter name...' },
          {
            id: 'ui_settings',
            label: 'UI Settings',
            description: 'Menu position & color',
            submenu: settingsSubmenu
          }
        ]
      }
    },
    { id: 'disconnect', label: 'Disconnect', description: 'Leave the server' },
  ]
}

onMounted(() => {
  fetchNui('nuiReady')

  // Dev mode: auto-show UI when not in FiveM
  if (!isInGame()) {
    // Settings store already applies saved accent color on init
    menuStore.openMenu(demoMenu)
    notificationStore.addNotification('info', 'Dev Mode', 'Press ESC to close menu', 3000)
  }
})
</script>

<template>
  <div class="app">
    <Menu />
    <Notifications />
    <ButtonHint />
    <InputDialog />
    <AlertDialog />
    <Minigame />
    <ProgressBar />
  </div>
</template>

<style scoped>
.app {
  width: 100%;
  height: 100%;
}
</style>
