<script setup lang="ts">
import { useNotificationStore, type Notification } from '@/stores/notification'
import { useSettingsStore } from '@/stores/settings'

const notificationStore = useNotificationStore()
const settingsStore = useSettingsStore()

function getIcon(type: Notification['type']): string {
  switch (type) {
    case 'success': return 'fa-solid fa-check'
    case 'error':   return 'fa-solid fa-xmark'
    case 'warning': return 'fa-solid fa-exclamation'
    case 'info':    return 'fa-solid fa-info'
    default:        return 'fa-solid fa-info'
  }
}
</script>

<template>
  <div class="notifications-container" :class="`position-${settingsStore.notificationPosition}`">
    <TransitionGroup name="notification">
      <div
        v-for="notification in notificationStore.notifications"
        :key="notification.id"
        class="notification glass"
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
        <div class="notification-timer">
          <div class="notification-timer-bar" :style="{ animationDuration: `${notification.duration}ms` }"></div>
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
  gap: 10px;
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

.notification {
  width: 380px;
  overflow: hidden;
  pointer-events: auto;
}

.notification-body {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px 18px 14px;
}

.notification-icon {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 15px;
  line-height: 1;
}

.notification-icon i {
  display: block;
  line-height: 1;
}

.notification.success .notification-icon {
  color: var(--ok);
  background: rgba(var(--ok-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--ok-rgb), 0.3);
}

.notification.error .notification-icon {
  color: var(--danger);
  background: rgba(var(--danger-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--danger-rgb), 0.3);
}

.notification.warning .notification-icon {
  color: var(--warn);
  background: rgba(var(--warn-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--warn-rgb), 0.3);
}

.notification.info .notification-icon {
  color: var(--info);
  background: rgba(var(--info-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--info-rgb), 0.3);
}

.notification-content {
  flex: 1;
  min-width: 0;
  padding-top: 1px;
}

.notification-title {
  font-size: 14px;
  font-weight: 600;
  line-height: 1.35;
  color: var(--text);
}

.notification-message {
  margin-top: 3px;
  font-size: 13px;
  line-height: 1.45;
  color: var(--text-2);
}

/* Timer pill inset at the bottom */
.notification-timer {
  position: absolute;
  left: 16px;
  right: 16px;
  bottom: 7px;
  height: 3px;
  border-radius: 3px;
  background: var(--fill-2);
  overflow: hidden;
}

.notification-timer-bar {
  height: 100%;
  width: 100%;
  border-radius: inherit;
  background: currentColor;
  animation: timer-shrink 5s linear forwards;
}

.notification.success .notification-timer { color: var(--ok); }
.notification.error .notification-timer   { color: var(--danger); }
.notification.warning .notification-timer { color: var(--warn); }
.notification.info .notification-timer    { color: var(--info); }

@keyframes timer-shrink {
  from { width: 100%; }
  to { width: 0%; }
}

/* Transitions */
.notification-enter-active,
.notification-leave-active {
  transition: opacity 0.3s ease, transform 0.35s var(--ease);
}

.notification-move {
  transition: transform 0.3s var(--ease);
}

/* Right side animations */
.position-top-right .notification-enter-from,
.position-top-right .notification-leave-to,
.position-bottom-right .notification-enter-from,
.position-bottom-right .notification-leave-to {
  opacity: 0;
  transform: translateX(40px);
}

/* Left side animations */
.position-top-left .notification-enter-from,
.position-top-left .notification-leave-to,
.position-bottom-left .notification-enter-from,
.position-bottom-left .notification-leave-to {
  opacity: 0;
  transform: translateX(-40px);
}
</style>
