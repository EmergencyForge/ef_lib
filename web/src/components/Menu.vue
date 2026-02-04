<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref } from 'vue'
import { useMenuStore, type MenuItem } from '@/stores/menu'
import { useSettingsStore } from '@/stores/settings'
import { useNotificationStore } from '@/stores/notification'
import { fetchNui } from '@/composables/useNui'

const menuStore = useMenuStore()
const settingsStore = useSettingsStore()
const notificationStore = useNotificationStore()

const searchInputRef = ref<HTMLInputElement | null>(null)

// Use filtered items when searching, otherwise use all items
const displayItems = computed(() => {
  return menuStore.isSearching ? menuStore.filteredItems : menuStore.items
})

function handleKeyDown(event: KeyboardEvent) {
  if (!menuStore.isVisible) return

  const selectedItem = getCurrentSelectedItem()

  // Handle search input typing
  if (menuStore.isSearching && event.target === searchInputRef.value) {
    if (event.key === 'Escape') {
      event.preventDefault()
      closeSearch()
    } else if (event.key === 'ArrowDown') {
      event.preventDefault()
      navigateDown()
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      navigateUp()
    } else if (event.key === 'Enter') {
      event.preventDefault()
      activateCurrentItem()
    }
    return
  }

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
    case 'w':
    case 'W':
      event.preventDefault()
      navigateUp()
      break
    case 'ArrowDown':
    case 's':
    case 'S':
      event.preventDefault()
      navigateDown()
      break
    case 'Enter':
    case 'ArrowRight':
      event.preventDefault()
      activateCurrentItem()
      break
    case 'Escape':
    case 'Backspace':
    case 'ArrowLeft':
      event.preventDefault()
      goBackOrClose()
      break
    case '/':
      // Open search with "/" key
      if (!menuStore.isSearching) {
        event.preventDefault()
        openSearch()
      }
      break
  }
}

function navigateUp() {
  if (menuStore.isSearching) {
    menuStore.selectPreviousFiltered()
  } else {
    menuStore.selectPrevious()
  }
}

function navigateDown() {
  if (menuStore.isSearching) {
    menuStore.selectNextFiltered()
  } else {
    menuStore.selectNext()
  }
}

function getCurrentSelectedItem(): MenuItem | null {
  if (menuStore.isSearching) {
    return menuStore.getFilteredSelectedItem()
  }
  return menuStore.getSelectedItem()
}

function openSearch() {
  menuStore.openSearch()
  fetchNui('setKeyboardFocus', { enabled: true })
  setTimeout(() => {
    searchInputRef.value?.focus()
  }, 50)
}

function closeSearch() {
  menuStore.closeSearch()
  fetchNui('setKeyboardFocus', { enabled: false })
}

function onSearchInput(event: Event) {
  const value = (event.target as HTMLInputElement).value
  menuStore.setSearchQuery(value)
}

function onSearchBlur() {
  // Small delay to allow clicking on items
  setTimeout(() => {
    if (menuStore.isSearching && menuStore.searchQuery === '') {
      closeSearch()
    }
  }, 100)
}

function activateCurrentItem() {
  const item = getCurrentSelectedItem()
  if (!item || item.disabled) return

  // Close search if open when selecting an item
  if (menuStore.isSearching) {
    closeSearch()
  }

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
      notificationStore.addNotification('info', 'Test Notification', 'This is a test notification to preview the position.', 3000)
      break
    case '_settings_reset':
      // Perform the actual reset
      settingsStore.resetToDefaults()
      // Update menu items to reflect reset values
      menuStore.updateItem('_settings_position', { value: 'left' })
      menuStore.updateItem('_settings_color', { value: '#3b82f6' })
      menuStore.updateItem('_settings_notif_position', { value: 'top-right' })
      // Show success notification
      notificationStore.addNotification('success', 'Settings Reset', 'All UI settings have been restored to defaults.', 3000)
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

function goBackOrClose() {
  // Close search first if open
  if (menuStore.isSearching) {
    closeSearch()
    return
  }
  if (!menuStore.goBack()) {
    closeMenu()
  }
}

function sendAction(item: MenuItem) {
  fetchNui('menuAction', {
    id: item.id,
    type: item.type || 'button',
    label: item.label,
    checked: item.checked,
    value: item.value,
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

// Handle navigation messages from game client (allows walking while menu open)
function handleNuiMessage(event: MessageEvent) {
  const { action, data } = event.data
  if (action !== 'navigate' || !menuStore.isVisible) return

  const selectedItem = getCurrentSelectedItem()

  // Don't handle when typing in search or input (except back)
  if (menuStore.isSearching || (selectedItem?.type === 'input' && document.activeElement instanceof HTMLInputElement)) {
    if (data === 'back') {
      if (menuStore.isSearching) {
        closeSearch()
      } else {
        (document.activeElement as HTMLInputElement).blur()
      }
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
    case 'select':
      activateCurrentItem()
      break
    case 'back':
      goBackOrClose()
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
  <Transition name="menu">
    <div v-if="menuStore.isVisible" class="menu-container" :class="`position-${settingsStore.menuPosition}`">
      <div class="menu">
        <div class="menu-header">
          <div v-if="menuStore.canGoBack()" class="back-indicator">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
          </div>
          <h2 v-if="!menuStore.isSearching" class="menu-title">{{ menuStore.title }}</h2>
          <div v-else class="search-container">
            <svg class="search-icon" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input
              ref="searchInputRef"
              type="text"
              class="search-input"
              placeholder="Search..."
              :value="menuStore.searchQuery"
              @input="onSearchInput"
              @blur="onSearchBlur"
              @keydown.stop
            />
          </div>
          <button v-if="!menuStore.isSearching && menuStore.items.length > 5" class="search-button" @click="openSearch">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
          </button>
        </div>

        <div class="menu-items">
          <div v-if="menuStore.isSearching && displayItems.length === 0" class="no-results">
            No results found
          </div>
          <div
            v-for="(item, index) in displayItems"
            :key="item.id"
            class="menu-item"
            :class="{
              selected: index === menuStore.selectedIndex,
              disabled: item.disabled
            }"
          >
            <div class="item-icon" v-if="item.icon">
              {{ item.icon }}
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
            <div v-if="item.type === 'checkbox'" class="item-checkbox" :class="{ checked: item.checked }">
              <svg v-if="item.checked" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                <polyline points="20 6 9 17 4 12"></polyline>
              </svg>
            </div>
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
            <!-- Submenu indicator -->
            <div v-if="item.submenu" class="item-indicator submenu">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </div>
            <!-- Arrow indicator for buttons -->
            <div v-else-if="item.type !== 'input' && item.type !== 'checkbox' && item.type !== 'select'" class="item-indicator">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </div>
          </div>
        </div>

        <div class="menu-footer">
          <span class="hint">
            <kbd>↑</kbd><kbd>↓</kbd> Navigate
            <kbd>Enter</kbd> Select
            <template v-if="menuStore.isSearching"><kbd>ESC</kbd> Close Search</template>
            <template v-else>
              <kbd v-if="menuStore.canGoBack()">←</kbd><template v-if="menuStore.canGoBack()"> Back</template>
              <kbd v-if="menuStore.items.length > 5">/</kbd><template v-if="menuStore.items.length > 5"> Search</template>
              <kbd>ESC</kbd> Close
            </template>
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
  padding-left: 50px;
  background: linear-gradient(90deg, rgba(0, 0, 0, 0.7) 0%, rgba(0, 0, 0, 0.3) 50%, transparent 100%);
}

/* Position: Center */
.menu-container.position-center {
  justify-content: center;
  background: rgba(0, 0, 0, 0.5);
}

/* Position: Right */
.menu-container.position-right {
  justify-content: flex-end;
  padding-right: 50px;
  background: linear-gradient(270deg, rgba(0, 0, 0, 0.7) 0%, rgba(0, 0, 0, 0.3) 50%, transparent 100%);
}

.menu {
  width: 400px;
  max-height: 80vh;
  background: rgba(15, 15, 15, 0.95);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.menu-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.menu-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.back-indicator {
  color: rgba(255, 255, 255, 0.5);
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Search */
.search-container {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 8px 12px;
}

.search-icon {
  color: rgba(255, 255, 255, 0.4);
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: #ffffff;
  font-size: 0.95rem;
  font-family: inherit;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.3);
}

.search-button {
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

.search-button:hover {
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
}

.no-results {
  padding: 24px 20px;
  text-align: center;
  color: rgba(255, 255, 255, 0.4);
  font-size: 0.9rem;
}

.menu-items {
  flex: 1;
  overflow-y: auto;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 20px;
  transition: all 0.15s ease;
  border-left: 3px solid transparent;
}

.menu-item.selected {
  border-left-color: var(--accent-color);
  background: linear-gradient(90deg, rgba(var(--accent-rgb), 0.25) 0%, transparent 60%);
}

.menu-item.disabled {
  opacity: 0.5;
}

.item-icon {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  font-size: 1.25rem;
}

.item-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.item-label {
  font-size: 0.95rem;
  font-weight: 500;
  color: #ffffff;
}

.item-description {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.5);
}

.item-indicator {
  color: rgba(255, 255, 255, 0.3);
  transition: all 0.2s;
}

.menu-item.selected .item-indicator {
  color: var(--accent-color);
  transform: translateX(4px);
}

/* Checkbox */
.item-checkbox {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  flex-shrink: 0;
}

.item-checkbox.checked {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

.item-checkbox svg {
  color: #ffffff;
}

/* Select */
.item-select {
  display: flex;
  gap: 4px;
}

.select-option {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 0.8rem;
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.5);
  transition: all 0.15s ease;
}

.select-option.active {
  background: var(--accent-color);
  color: #ffffff;
}

/* Input */
.item-content.with-input {
  flex: 1;
}

.item-input {
  width: 120px;
  margin-left: auto;
  padding: 4px 0;
  background: transparent;
  border: none;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  color: #ffffff;
  font-size: 0.9rem;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s ease;
  text-align: right;
}

.item-input::placeholder {
  color: rgba(255, 255, 255, 0.3);
}

.item-input:focus {
  border-bottom-color: var(--accent-color);
}

.item-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.menu-footer {
  padding: 12px 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(0, 0, 0, 0.3);
}

.hint {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.4);
  display: flex;
  align-items: center;
  gap: 8px;
}

kbd {
  padding: 2px 6px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
  font-family: inherit;
  font-size: 0.7rem;
  margin-right: 2px;
}

/* Transitions */
.menu-enter-active {
  transition: opacity 0.25s ease-out;
}

.menu-leave-active {
  transition: opacity 0.2s ease-in;
}

.menu-enter-active .menu,
.menu-leave-active .menu {
  transition: transform 0.25s ease-out, opacity 0.25s ease-out;
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
  transform: scale(0.9);
  opacity: 0;
}

/* Right position animation */
.position-right.menu-enter-from .menu,
.position-right.menu-leave-to .menu {
  transform: translateX(30px);
  opacity: 0;
}
</style>
