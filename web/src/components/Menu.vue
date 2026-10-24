<script setup lang="ts">
import { onMounted, onUnmounted, computed, nextTick, watch } from 'vue'
import { useMenuStore, type MenuItem } from '@/stores/menu'
import { useSettingsStore } from '@/stores/settings'
import { DEFAULT_ACCENT } from '@/stores/config'
import { useNotificationStore } from '@/stores/notification'
import { fetchNui } from '@/composables/useNui'

const menuStore = useMenuStore()
const settingsStore = useSettingsStore()
const notificationStore = useNotificationStore()

// Resolve icon name to FontAwesome class
// Handles: 'warehouse' → 'fa-solid fa-warehouse', 'fa-car' → 'fa-solid fa-car', 'fa-solid fa-car' → as-is
function resolveIconClass(icon: string): string {
  if (!icon) return ''
  // Already has fa- prefix with style (fa-solid, fa-regular, fa-brands)
  if (/^fa-(solid|regular|brands|light|thin|duotone) /.test(icon)) return icon
  // Has fa- prefix but no style
  if (icon.startsWith('fa-')) return 'fa-solid ' + icon
  // Plain name like 'warehouse'
  return 'fa-solid fa-' + icon
}

const displayItems = computed(() => menuStore.items)

function handleKeyDown(event: KeyboardEvent) {
  if (!menuStore.isVisible) return

  const selectedItem = getCurrentSelectedItem()

  // Don't handle navigation keys when typing in input
  if (selectedItem?.type === 'input' && event.target instanceof HTMLInputElement) {
    if (event.key === 'Escape') {
      event.preventDefault()
      closeMenu()
    }
    return
  }

  switch (event.key) {
    case 'ArrowUp':
      event.preventDefault()
      navigateUp()
      break
    case 'ArrowDown':
      event.preventDefault()
      navigateDown()
      break
    case 'ArrowLeft':
      if (selectedItem?.type === 'number') {
        event.preventDefault()
        menuStore.decrementNumber(selectedItem.id)
        sendAction(selectedItem)
      } else if (menuStore.canGoBack()) {
        event.preventDefault()
        menuStore.goBack()
      }
      break
    case 'ArrowRight':
      if (selectedItem?.type === 'number') {
        event.preventDefault()
        menuStore.incrementNumber(selectedItem.id)
        sendAction(selectedItem)
      } else {
        event.preventDefault()
        activateCurrentItem()
      }
      break
    case 'w':
    case 'W':
    case 'a':
    case 'A':
    case 's':
    case 'S':
    case 'd':
    case 'D':
      event.preventDefault()
      fetchNui('keyPress', { key: event.key.toLowerCase() })
      break
    case 'Enter':
      event.preventDefault()
      activateCurrentItem()
      break
    case 'Backspace':
      event.preventDefault()
      if (menuStore.canGoBack()) {
        menuStore.goBack()
      } else {
        closeMenu()
      }
      break
    case 'Escape':
      event.preventDefault()
      if (menuStore.canGoBack()) {
        menuStore.goBack()
      } else {
        closeMenu()
      }
      break

  }
}

// Auto-scroll selected item into view whenever selection or items change
watch(
  () => [menuStore.selectedIndex, menuStore.items],
  () => {
    nextTick(() => {
      const el = document.querySelector('.menu-items .menu-item.selected') as HTMLElement | null
      if (el) {
        el.scrollIntoView({ block: 'nearest' })
      }
    })
  }
)

function navigateUp() {
  menuStore.selectPrevious()
}

function navigateDown() {
  menuStore.selectNext()
}

function getCurrentSelectedItem(): MenuItem | null {
  return menuStore.getSelectedItem()
}

function activateCurrentItem() {
  const item = getCurrentSelectedItem()
  if (!item || item.disabled || item.readonly) return

  // Handle confirmation dialog items
  if (item.id === '_confirm_yes') {
    const confirmedItem = menuStore.confirmAction()
    if (confirmedItem) {
      // Route back to appropriate handler based on item type
      if (confirmedItem.id.startsWith('_settings_')) {
        executeSettingsAction(confirmedItem)
      } else {
        executeItemAction(confirmedItem)
      }
    }
    return
  }
  if (item.id === '_confirm_no') {
    menuStore.cancelConfirmation()
    return
  }

  // Handle internal settings items
  if (item.id.startsWith('_settings_')) {
    handleSettingsAction(item)
    return
  }

  // Check if item needs confirmation
  if (item.confirm) {
    menuStore.showConfirmation(item)
    return
  }

  executeItemAction(item)
}

function executeItemAction(item: MenuItem) {
  if (item.submenu) {
    menuStore.openSubmenu(item.submenu)
  } else if (item.type === 'checkbox') {
    toggleCheckbox(item)
  } else if (item.type === 'select') {
    cycleSelect(item)
  } else if (item.type === 'input') {
    focusInput(item.id)
  } else {
    sendAction(item)
  }
}

function handleSettingsAction(item: MenuItem) {
  // If the settings item has a submenu, open it
  if (item.submenu) {
    menuStore.openSubmenu(item.submenu)
    return
  }

  // Check if item needs confirmation
  if (item.confirm) {
    menuStore.showConfirmation(item)
    return
  }

  executeSettingsAction(item)
}

function executeSettingsAction(item: MenuItem) {
  switch (item.id) {
    case '_settings_position':
      const newPos = menuStore.cycleSelectOption(item.id)
      if (newPos) {
        settingsStore.setMenuPosition(newPos as 'left' | 'center' | 'right')
      }
      break
    case '_settings_color':
      focusInput(item.id)
      break
    case '_settings_notif_position':
      const newNotifPos = menuStore.cycleSelectOption(item.id)
      if (newNotifPos) {
        settingsStore.setNotificationPosition(newNotifPos as 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left')
      }
      break
    case '_settings_notif_test':
      notificationStore.addNotification('info', 'Testmeldung', 'So sehen Meldungen an dieser Position aus.', 3000)
      break
    case '_settings_reset':
      // Perform the actual reset
      settingsStore.resetToDefaults()
      // Update menu items to reflect reset values
      menuStore.updateItem('_settings_position', { value: 'left' })
      menuStore.updateItem('_settings_color', { value: DEFAULT_ACCENT })
      menuStore.updateItem('_settings_notif_position', { value: 'top-right' })
      // Show success notification
      notificationStore.addNotification('success', 'Zurückgesetzt', 'Position und Farbe stehen wieder auf Standard.', 3000)
      break
  }
}

function focusInput(itemId: string) {
  // Enable keyboard focus for typing
  fetchNui('setKeyboardFocus', { enabled: true })
  setTimeout(() => {
    const input = document.querySelector(`input[data-id="${itemId}"]`) as HTMLInputElement
    input?.focus()
  }, 50)
}

function onInputBlur() {
  // Disable keyboard focus when done typing
  fetchNui('setKeyboardFocus', { enabled: false })
}

function cycleSelect(item: MenuItem) {
  menuStore.cycleSelectOption(item.id)
  sendAction(item)
}

function sendAction(item: MenuItem) {
  fetchNui('menuAction', {
    id: item.id,
    type: item.type || 'button',
    label: item.label,
    checked: item.checked,
    value: item.type === 'number' ? item.current : item.value,
    data: item.data
  })
}

function toggleCheckbox(item: MenuItem) {
  menuStore.toggleCheckbox(item.id)
  sendAction({ ...item, checked: !item.checked })
}

function onInputChange(item: MenuItem, event: Event) {
  const value = (event.target as HTMLInputElement).value
  menuStore.setInputValue(item.id, value)

  // Handle settings color change
  if (item.id === '_settings_color' && /^#[0-9A-Fa-f]{6}$/.test(value)) {
    settingsStore.setAccentColor(value)
  }
}

function onInputEnter(item: MenuItem) {
  // Blur input and restore game keyboard focus
  const input = document.activeElement as HTMLInputElement
  input?.blur()

  // Don't send NUI action for internal settings items
  if (item.id.startsWith('_settings_')) {
    if (item.id === '_settings_color') {
      const value = item.value || ''
      if (/^#[0-9A-Fa-f]{6}$/.test(value)) {
        settingsStore.setAccentColor(value)
      }
    }
    return
  }
  sendAction(item)
}

function closeMenu() {
  fetchNui('closeMenu')
}

function onItemClick(item: MenuItem) {
  if (item.disabled || item.readonly) return

  if (item.type === 'checkbox') {
    toggleCheckbox(item)
  } else if (item.type === 'select') {
    cycleSelect(item)
  } else if (item.type === 'input') {
    // Focus the input field
    const input = document.querySelector(`input[data-id="${item.id}"]`) as HTMLInputElement
    input?.focus()
  } else {
    activateCurrentItem()
  }
}

// Handle navigation messages from game client (allows walking while menu open)
function handleNuiMessage(event: MessageEvent) {
  const { action, data } = event.data
  if (action !== 'navigate' || !menuStore.isVisible) return

  const selectedItem = getCurrentSelectedItem()

  // Don't handle when typing in input (except back)
  if (selectedItem?.type === 'input' && document.activeElement instanceof HTMLInputElement) {
    if (data === 'back') {
      (document.activeElement as HTMLInputElement).blur()
    }
    return
  }

  switch (data) {
    case 'up':
      navigateUp()
      break
    case 'down':
      navigateDown()
      break
    case 'left': {
      const item = getCurrentSelectedItem()
      if (item?.type === 'number') {
        menuStore.decrementNumber(item.id)
        sendAction(item)
      } else if (menuStore.canGoBack()) {
        menuStore.goBack()
      }
      break
    }
    case 'right': {
      const item = getCurrentSelectedItem()
      if (item?.type === 'number') {
        menuStore.incrementNumber(item.id)
        sendAction(item)
      } else {
        activateCurrentItem()
      }
      break
    }
    case 'select':
      activateCurrentItem()
      break
    case 'back':
      if (menuStore.canGoBack()) {
        menuStore.goBack()
      } else {
        closeMenu()
      }
      break
    case 'close':
      closeMenu()
      break
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
  window.addEventListener('message', handleNuiMessage)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('message', handleNuiMessage)
})
</script>

<template>
  <Transition name="menu" :duration="{ enter: 600, leave: 200 }">
    <div v-if="menuStore.isVisible" class="menu-container" :class="`position-${settingsStore.menuPosition}`">
      <div class="menu glass">
        <div class="menu-header">
          <h2 class="menu-title">{{ menuStore.title }}</h2>

        </div>

        <div class="menu-items" :class="{ 'no-mouse': !menuStore.cursorEnabled }">
          <div
            v-for="(item, index) in displayItems"
            :key="item.id"
            class="menu-item"
            :class="{
              'glass-active': index === menuStore.selectedIndex,
              selected: index === menuStore.selectedIndex,
              disabled: item.disabled,
              readonly: item.readonly
            }"
            @mouseenter="menuStore.selectedIndex = index"
            @click="onItemClick(item)"
          >
            <div class="item-icon" v-if="item.icon" :style="item.iconColor ? { color: item.iconColor } : {}">
              <i :class="resolveIconClass(item.icon)"></i>
            </div>
            <div class="item-content" :class="{ 'with-input': item.type === 'input' }">
              <span class="item-label">{{ item.label }}</span>
              <span v-if="item.description && item.type !== 'input'" class="item-description">
                {{ item.description }}
              </span>
            </div>
            <!-- Input Field -->
            <input
              v-if="item.type === 'input'"
              :data-id="item.id"
              type="text"
              class="item-input"
              :placeholder="item.placeholder || ''"
              :value="item.value || ''"
              :disabled="item.disabled"
              @input="onInputChange(item, $event)"
              @keydown.enter="onInputEnter(item)"
              @keydown.stop
              @click.stop
              @blur="onInputBlur"
            />
            <!-- Checkbox -->
            <div v-if="item.type === 'checkbox'" class="item-checkbox" :class="{ checked: item.checked }"></div>
            <!-- Select -->
            <div v-if="item.type === 'select'" class="item-select">
              <span
                v-for="opt in item.options"
                :key="opt"
                class="select-option"
                :class="{ active: item.value === opt }"
              >
                {{ opt.charAt(0).toUpperCase() + opt.slice(1) }}
              </span>
            </div>
            <!-- Number selector -->
            <div v-if="item.type === 'number'" class="item-number">
              <button class="number-arrow" @click.stop="menuStore.decrementNumber(item.id)">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <polyline points="15 18 9 12 15 6"></polyline>
                </svg>
              </button>
              <span class="number-value">{{ item.current ?? item.min ?? 0 }}</span>
              <button class="number-arrow" @click.stop="menuStore.incrementNumber(item.id)">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </button>
            </div>
            <!-- Submenu indicator -->
            <div v-if="item.submenu" class="item-indicator submenu">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </div>
            <!-- Arrow indicator for buttons (not for disabled/readonly) -->
            <div v-else-if="!item.disabled && !item.readonly && item.type !== 'input' && item.type !== 'checkbox' && item.type !== 'select' && item.type !== 'number'" class="item-indicator">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </div>
          </div>
        </div>

        <div class="menu-footer">
          <span class="hint">
            <span><kbd class="kbd">↑</kbd><kbd class="kbd">↓</kbd> Navigation</span>
            <span><kbd class="kbd">Enter</kbd> Auswählen</span>
            <span><kbd class="kbd">ESC</kbd> Schließen</span>
          </span>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.menu-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
}

/* Position: Left (default) */
.menu-container.position-left {
  justify-content: flex-start;
  padding-left: 56px;
  background: linear-gradient(90deg, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.15) 40%, transparent 70%);
}

/* Position: Center */
.menu-container.position-center {
  justify-content: center;
  background: radial-gradient(circle at center, rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0.15) 70%);
}

/* Position: Right */
.menu-container.position-right {
  justify-content: flex-end;
  padding-right: 56px;
  background: linear-gradient(270deg, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.15) 40%, transparent 70%);
}

.menu {
  width: 400px;
  max-height: 80vh;
  padding: 10px;
  display: flex;
  flex-direction: column;
}

.menu-header {
  padding: 12px 12px 14px;
}

.menu-title {
  font-size: 17px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text);
}

.menu-items {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow-y: auto;
}

/* Cursor unsichtbar → keine Maus-Steuerung, damit die Spieler-Maus nicht
   versehentlich Items vorwählt während mit Tastatur navigiert wird. */
.menu-items.no-mouse {
  pointer-events: none;
}

.menu-item {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  min-height: 52px;
  padding: 10px 12px;
  border-radius: var(--radius-ctl);
  transition: background 0.15s ease, box-shadow 0.15s ease;
  cursor: pointer;
}

.menu-item.disabled {
  opacity: 0.45;
  pointer-events: none;
}

.menu-item.readonly {
  pointer-events: none;
}

.item-icon {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--fill-2);
  border-radius: 8px;
  color: var(--text-2);
  font-size: 14px;
  transition: background 0.15s ease, color 0.15s ease;
}

.menu-item.selected .item-icon {
  background: var(--accent-color);
  color: var(--on-accent);
}

.item-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.item-label {
  font-size: 14px;
  font-weight: 500;
  color: var(--text);
}

.item-description {
  font-size: 12px;
  color: var(--text-3);
}

.menu-item.selected .item-description {
  color: var(--text-2);
}

.item-indicator {
  display: flex;
  color: var(--text-3);
  transition: transform 0.2s var(--ease), color 0.15s ease;
}

.menu-item.selected .item-indicator {
  color: var(--text);
  transform: translateX(3px);
}

/* Checkbox as switch */
.item-checkbox {
  position: relative;
  width: 40px;
  height: 24px;
  flex-shrink: 0;
  border-radius: var(--radius-pill);
  background: var(--fill-3);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  transition: background 0.2s ease;
}

.item-checkbox::after {
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

.item-checkbox.checked {
  background: var(--accent-color);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.item-checkbox.checked::after {
  transform: translateX(16px);
}

/* Select as segmented control */
.item-select {
  display: flex;
  flex-shrink: 0;
  padding: 3px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
}

.select-option {
  padding: 4px 10px;
  border-radius: var(--radius-pill);
  font-size: 12px;
  color: var(--text-3);
  transition: background 0.15s ease, color 0.15s ease;
}

.select-option.active {
  background: var(--fill-3);
  color: var(--text);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

/* Number selector */
.item-number {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  padding: 3px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
}

.number-arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  padding: 0;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-2);
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease;
}

.number-arrow:hover {
  background: var(--fill-3);
  color: var(--text);
}

.number-value {
  min-width: 34px;
  text-align: center;
  font-size: 13px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: var(--text);
}

/* Input */
.item-content.with-input {
  flex: 1;
}

.item-input {
  width: 130px;
  height: 30px;
  margin-left: auto;
  padding: 0 10px;
  border: none;
  border-radius: 8px;
  background: var(--well);
  box-shadow: var(--well-rim);
  color: var(--text);
  font-size: 13px;
  outline: none;
  text-align: right;
  transition: box-shadow 0.15s ease;
}

.item-input::placeholder {
  color: var(--text-3);
}

.item-input:focus {
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.35), inset 0 0 0 1px var(--accent-color);
}

.item-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.menu-footer {
  margin-top: 8px;
  padding: 12px 12px 4px;
  border-top: 1px solid var(--divider);
}

.hint {
  display: flex;
  align-items: center;
  gap: 14px;
  font-size: 11.5px;
  color: var(--text-3);
}

.hint .kbd {
  margin-right: 3px;
}

/* Transitions */
.menu-enter-active {
  transition: opacity 0.3s ease-out;
}

.menu-leave-active {
  transition: opacity 0.2s var(--exit);
}

.menu-enter-active .menu {
  transition: transform 0.6s var(--ease), opacity 0.3s ease-out, filter 0.35s ease;
}

.menu-leave-active .menu {
  transition: transform 0.2s var(--exit), opacity 0.18s var(--exit);
}

.menu-enter-from .menu {
  filter: blur(6px);
}

.menu-enter-from,
.menu-leave-to {
  opacity: 0;
}

/* Left position animation */
.position-left.menu-enter-from .menu,
.position-left.menu-leave-to .menu {
  transform: translateX(-30px);
  opacity: 0;
}

/* Center position animation */
.position-center.menu-enter-from .menu,
.position-center.menu-leave-to .menu {
  transform: scale(0.94);
  opacity: 0;
}

/* Right position animation */
.position-right.menu-enter-from .menu,
.position-right.menu-leave-to .menu {
  transform: translateX(30px);
  opacity: 0;
}
</style>
