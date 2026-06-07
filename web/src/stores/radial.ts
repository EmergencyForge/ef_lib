import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface RadialItem {
  id: string
  label: string
  icon?: string
  submenu?: RadialItem[]
}

export interface RadialData {
  items: RadialItem[]
}

export const useRadialStore = defineStore('radial', () => {
  const visible = ref(false)
  const items = ref<RadialItem[]>([])
  const activeIndex = ref<number | null>(null)
  const history = ref<RadialItem[][]>([])

  function open(data: RadialData) {
    items.value = (data.items || []).slice(0, 8)
    activeIndex.value = null
    history.value = []
    visible.value = true
  }

  function close() {
    visible.value = false
    items.value = []
    activeIndex.value = null
    history.value = []
  }

  function setActive(index: number | null) {
    activeIndex.value = index
  }

  function drillInto(submenu: RadialItem[]) {
    history.value.push(items.value)
    items.value = submenu.slice(0, 8)
    activeIndex.value = null
  }

  function drillBack(): boolean {
    if (history.value.length === 0) return false
    items.value = history.value.pop()!
    activeIndex.value = null
    return true
  }

  return {
    visible,
    items,
    activeIndex,
    history,
    open,
    close,
    setActive,
    drillInto,
    drillBack,
  }
})
