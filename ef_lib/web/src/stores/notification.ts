import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface Notification {
  id: number
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message: string
  duration: number
}

let notificationId = 0

export const useNotificationStore = defineStore('notification', () => {
  const notifications = ref<Notification[]>([])

  function addNotification(
    type: Notification['type'],
    title: string,
    message: string,
    duration: number = 5000
  ) {
    const id = ++notificationId
    const notification: Notification = {
      id,
      type,
      title,
      message,
      duration
    }

    notifications.value.push(notification)

    if (duration > 0) {
      setTimeout(() => {
        removeNotification(id)
      }, duration)
    }

    return id
  }

  function removeNotification(id: number) {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index !== -1) {
      notifications.value.splice(index, 1)
    }
  }

  function clearAll() {
    notifications.value = []
  }

  return {
    notifications,
    addNotification,
    removeNotification,
    clearAll
  }
})
