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
        :class="[notification.type, { timed: notification.duration > 0 }]"
        :style="{ '--hold': `${notification.duration}ms` }"
      >
        <div class="notification-heat"></div>
        <div class="notification-edge"></div>
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

.notification.success { --c: var(--ok); --c-rgb: var(--ok-rgb); }
.notification.error   { --c: var(--danger); --c-rgb: var(--danger-rgb); }
.notification.warning { --c: var(--warn); --c-rgb: var(--warn-rgb); }
.notification.info    { --c: var(--info); --c-rgb: var(--info-rgb); }

.notification {
  position: relative;
  width: 320px;
  overflow: hidden;
  pointer-events: auto;
}

.notification-heat {
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, rgba(var(--c-rgb), 0.42), transparent 62%);
  animation: notification-heat 2s ease-out both;
}

.notification-edge {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  width: 4px;
  background: var(--c);
  transform-origin: bottom;
}

/* White hot, then the status colour, then cold steel. Its length is the time that is left. */
.notification.timed .notification-edge {
  animation: notification-cool var(--hold) linear both;
}

@keyframes notification-heat {
  to { opacity: 0; }
}

@keyframes notification-cool {
  0% { background: #fff; box-shadow: 0 0 20px 7px rgba(var(--c-rgb), 0.9); }
  14% { background: var(--c); box-shadow: 0 0 12px 3px rgba(var(--c-rgb), 0.6); }
  70% { background: var(--c); box-shadow: none; }
  100% { background: #4a4a50; box-shadow: none; transform: scaleY(0); }
}

.notification-body {
  position: relative;
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 12px 14px 12px 18px;
}

.notification-icon {
  flex-shrink: 0;
  color: var(--c);
  font-size: 18px;
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
  font-size: 13.5px;
  font-weight: 600;
  line-height: 1.35;
  color: var(--text);
}

.notification-message {
  font-size: 12px;
  line-height: 1.45;
  color: var(--text-2);
}

/* Transitions. The clip only lives while entering, it would cut the panel shadow off. */
.notification-enter-active {
  transition: clip-path 0.5s var(--ease);
}

.notification-enter-from {
  clip-path: inset(0 100% 0 0 round var(--radius-panel));
}

.notification-enter-to {
  clip-path: inset(0 0 0 0 round var(--radius-panel));
}

.notification-leave-active {
  position: absolute;
  transition: opacity 0.22s var(--exit), transform 0.25s var(--exit), filter 0.22s ease;
}

.notification-move {
  transition: transform 0.5s var(--spring);
}

.notification-leave-to {
  opacity: 0;
  filter: blur(8px);
}

.position-top-right .notification-leave-active,
.position-bottom-right .notification-leave-active { right: 0; }

.position-top-left .notification-leave-active,
.position-bottom-left .notification-leave-active { left: 0; }

.position-top-right .notification-leave-to,
.position-bottom-right .notification-leave-to { transform: translateX(24px) scale(0.98); }

.position-top-left .notification-leave-to,
.position-bottom-left .notification-leave-to { transform: translateX(-24px) scale(0.98); }
</style>
