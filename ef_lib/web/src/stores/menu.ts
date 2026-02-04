import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface ConfirmConfig {
  title?: string
  message?: string
  confirmLabel?: string
  cancelLabel?: string
}

export interface MenuItem {
  id: string
  label: string
  description?: string
  icon?: string
  iconColor?: string
  readonly?: boolean
  disabled?: boolean
  data?: unknown
  // Item types: 'button' (default), 'checkbox', 'input', 'select'
  type?: 'button' | 'checkbox' | 'input' | 'select'
  // For checkbox
  checked?: boolean
  // For input
  value?: string
  placeholder?: string
  inputType?: 'text' | 'password' | 'number'
  // For select
  options?: string[]
  // For submenu
  submenu?: MenuData
  // For confirmation dialog (true for defaults, or config object)
  confirm?: boolean | ConfirmConfig
}

export interface MenuData {
  title?: string
  items: MenuItem[]
}

interface MenuHistoryEntry {
  title: string
  items: MenuItem[]
  selectedIndex: number
}

export const useMenuStore = defineStore('menu', () => {
  const isVisible = ref(false)
  const title = ref('')
  const items = ref<MenuItem[]>([])
  const selectedIndex = ref(0)
  const history = ref<MenuHistoryEntry[]>([])
  const pendingConfirmItem = ref<MenuItem | null>(null)
  const searchQuery = ref('')
  const isSearching = ref(false)

  // Filtered items based on search query
  const filteredItems = computed(() => {
    if (!searchQuery.value.trim()) {
      return items.value
    }
    const query = searchQuery.value.toLowerCase()
    return items.value.filter(item =>
      item.label.toLowerCase().includes(query) ||
      item.description?.toLowerCase().includes(query)
    )
  })

  function openMenu(data: MenuData) {
    history.value = []
    title.value = data.title || 'Menu'
    items.value = data.items || []
    selectedIndex.value = 0
    isVisible.value = true
  }

  function closeMenu() {
    isVisible.value = false
    items.value = []
    selectedIndex.value = 0
    history.value = []
  }

  function openSubmenu(submenu: MenuData) {
    // Save current state to history
    history.value.push({
      title: title.value,
      items: [...items.value],
      selectedIndex: selectedIndex.value
    })
    // Open submenu
    title.value = submenu.title || 'Menu'
    items.value = submenu.items || []
    selectedIndex.value = 0
  }

  function goBack(): boolean {
    if (history.value.length === 0) return false

    const previous = history.value.pop()!
    title.value = previous.title
    items.value = previous.items
    selectedIndex.value = previous.selectedIndex
    return true
  }

  function canGoBack(): boolean {
    return history.value.length > 0
  }

  function setVisible(visible: boolean) {
    isVisible.value = visible
  }

  function selectNext() {
    if (items.value.length === 0) return
    selectedIndex.value = (selectedIndex.value + 1) % items.value.length
  }

  function selectPrevious() {
    if (items.value.length === 0) return
    selectedIndex.value = (selectedIndex.value - 1 + items.value.length) % items.value.length
  }

  function selectItem(index: number) {
    if (index >= 0 && index < items.value.length) {
      selectedIndex.value = index
    }
  }

  function getSelectedItem(): MenuItem | null {
    return items.value[selectedIndex.value] || null
  }

  function updateItem(id: string, updates: Partial<MenuItem>) {
    const item = items.value.find(i => i.id === id)
    if (item) {
      Object.assign(item, updates)
    }
  }

  function toggleCheckbox(id: string) {
    const item = items.value.find(i => i.id === id)
    if (item && item.type === 'checkbox') {
      item.checked = !item.checked
    }
  }

  function setInputValue(id: string, value: string) {
    const item = items.value.find(i => i.id === id)
    if (item && item.type === 'input') {
      item.value = value
    }
  }

  function cycleSelectOption(id: string, direction: 'next' | 'prev' = 'next'): string | null {
    const item = items.value.find(i => i.id === id)
    if (item && item.type === 'select' && item.options && item.options.length > 0) {
      const currentIdx = item.options.indexOf(item.value || item.options[0])
      let newIdx = direction === 'next' ? currentIdx + 1 : currentIdx - 1
      if (newIdx >= item.options.length) newIdx = 0
      if (newIdx < 0) newIdx = item.options.length - 1
      item.value = item.options[newIdx]
      return item.value
    }
    return null
  }

  function showConfirmation(item: MenuItem) {
    const config = typeof item.confirm === 'object' ? item.confirm : {}
    pendingConfirmItem.value = item

    // Create confirmation submenu
    const confirmSubmenu: MenuData = {
      title: config.title || 'Bestätigen',
      items: [
        {
          id: '_confirm_yes',
          label: config.confirmLabel || 'Ja',
          description: config.message || `Are you sure?`
        },
        {
          id: '_confirm_no',
          label: config.cancelLabel || 'Abbrechen',
          description: 'Go back'
        }
      ]
    }

    openSubmenu(confirmSubmenu)
  }

  function confirmAction(): MenuItem | null {
    const item = pendingConfirmItem.value
    pendingConfirmItem.value = null
    goBack()
    return item
  }

  function cancelConfirmation() {
    pendingConfirmItem.value = null
    goBack()
  }

  function hasPendingConfirm(): boolean {
    return pendingConfirmItem.value !== null
  }

  function getPendingConfirmItem(): MenuItem | null {
    return pendingConfirmItem.value
  }

  function openSearch() {
    isSearching.value = true
    searchQuery.value = ''
    selectedIndex.value = 0
  }

  function closeSearch() {
    isSearching.value = false
    searchQuery.value = ''
    selectedIndex.value = 0
  }

  function setSearchQuery(query: string) {
    searchQuery.value = query
    selectedIndex.value = 0
  }

  function getFilteredSelectedItem(): MenuItem | null {
    return filteredItems.value[selectedIndex.value] || null
  }

  function selectNextFiltered() {
    if (filteredItems.value.length === 0) return
    selectedIndex.value = (selectedIndex.value + 1) % filteredItems.value.length
  }

  function selectPreviousFiltered() {
    if (filteredItems.value.length === 0) return
    selectedIndex.value = (selectedIndex.value - 1 + filteredItems.value.length) % filteredItems.value.length
  }

  return {
    isVisible,
    title,
    items,
    selectedIndex,
    history,
    pendingConfirmItem,
    searchQuery,
    isSearching,
    filteredItems,
    openMenu,
    closeMenu,
    openSubmenu,
    goBack,
    canGoBack,
    setVisible,
    selectNext,
    selectPrevious,
    selectItem,
    getSelectedItem,
    updateItem,
    toggleCheckbox,
    setInputValue,
    cycleSelectOption,
    showConfirmation,
    confirmAction,
    cancelConfirmation,
    hasPendingConfirm,
    getPendingConfirmItem,
    openSearch,
    closeSearch,
    setSearchQuery,
    getFilteredSelectedItem,
    selectNextFiltered,
    selectPreviousFiltered
  }
})
