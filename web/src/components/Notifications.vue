<script setup lang="ts">
import { useNotificationStore, type Notification } from '@/stores/notification'
import { useSettingsStore } from '@/stores/settings'

const notificationStore = useNotificationStore()
const settingsStore = useSettingsStore()

function getIcon(type: Notification['type']): string {
  switch (type) {
    case 'success': return 'fa-solid fa-circle-check'
    case 'error':   return 'fa-solid fa-circle-xmark'
    case 'warning': return 'fa-solid fa-triangle-exclamation'
    case 'info':    return 'fa-solid fa-circle-info'
    default:        return 'fa-solid fa-circle-info'
  }
}
</script>

<template>
  <div class="notifications-container" :class="`position-${settingsStore.notificationPosition}`">
    <TransitionGroup name="notification">
      <div
        v-for="notification in notificationStore.notifications"
        :key="notification.id"
        class="notification panel"
        :class="notification.type"
      >
        <div class="notification-body">
          <div class="notification-icon">
            <i :class="getIcon(notification.type)"></i>
          </div>
          <div class="notification-content">
            <div class="notification-title">{{ notification.title }}</div>
            <div v-if="notification.message" class="notification-message">
              {{ notification.message }}
            </div>
          </div>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.notifications-container {
  position: fixed;
  display: flex;
  flex-direction: column;
  gap: 6px;
  z-index: 9999;
  pointer-events: none;
}

/* Position variants */
.notifications-container.position-top-right {
  top: 24px;
  right: 24px;
}

.notifications-container.position-top-left {
  top: 24px;
  left: 24px;
}

.notifications-container.position-bottom-right {
  bottom: 24px;
  right: 24px;
  flex-direction: column-reverse;
}

.notifications-container.position-bottom-left {
  bottom: 24px;
  left: 24px;
  flex-direction: column-reverse;
}

.notification.success { --c: var(--ok); }
.notification.error   { --c: var(--danger); }
.notification.warning { --c: var(--warn); }
.notification.info    { --c: var(--info); }

.notification {
  width: 300px;
  overflow: hidden;
  pointer-events: auto;
}

.notification-body {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
}

.notification-icon {
  flex-shrink: 0;
  color: var(--c);
  font-size: 15px;
  line-height: 1;
}

.notification-icon i {
  display: block;
  line-height: 1;
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-size: 13px;
  font-weight: 600;
  line-height: 1.35;
  color: var(--text);
}

.notification-message {
  font-size: 11.5px;
  line-height: 1.45;
  color: var(--text-2);
}

/* Transitions */
.notification-enter-active {
  transition: opacity 0.35s ease, transform 0.7s var(--spring), filter 0.45s ease;
}

.notification-leave-active {
  position: absolute;
  transition: opacity 0.22s var(--exit), transform 0.25s var(--exit), filter 0.22s ease;
}

.notification-move {
  transition: transform 0.5s var(--spring);
}

.notification-enter-from,
.notification-leave-to {
  opacity: 0;
  filter: blur(8px);
}

.position-top-right .notification-leave-active,
.position-bottom-right .notification-leave-active { right: 0; }

.position-top-left .notification-leave-active,
.position-bottom-left .notification-leave-active { left: 0; }

.position-top-right .notification-enter-from,
.position-bottom-right .notification-enter-from { transform: translateX(40px) scale(0.96); }

.position-top-left .notification-enter-from,
.position-bottom-left .notification-enter-from { transform: translateX(-40px) scale(0.96); }

.position-top-right .notification-leave-to,
.position-bottom-right .notification-leave-to { transform: translateX(24px) scale(0.98); }

.position-top-left .notification-leave-to,
.position-bottom-left .notification-leave-to { transform: translateX(-24px) scale(0.98); }
</style>
