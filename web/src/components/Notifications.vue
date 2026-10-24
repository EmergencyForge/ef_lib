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

.notification.success { --c: var(--ok);     --c-rgb: var(--ok-rgb); }
.notification.error   { --c: var(--danger); --c-rgb: var(--danger-rgb); }
.notification.warning { --c: var(--warn);   --c-rgb: var(--warn-rgb); }
.notification.info    { --c: var(--info);   --c-rgb: var(--info-rgb); }

.notification {
  width: 380px;
  overflow: hidden;
  pointer-events: auto;
}

/* Type colour bleeding into the glass from the leading edge */
.notification::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: -1;
  background: radial-gradient(70% 140% at 0% 50%, rgba(var(--c-rgb), 0.26), transparent 70%);
}

.notification::after {
  content: '';
  position: absolute;
  left: 0;
  top: 14px;
  bottom: 14px;
  width: 3px;
  border-radius: 0 3px 3px 0;
  background: var(--c);
  box-shadow: 0 0 12px var(--c);
}

.notification-body {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 14px 16px 20px 20px;
}

.notification-icon {
  flex-shrink: 0;
  margin-top: 1px;
  color: var(--c);
  font-size: 18px;
  line-height: 1;
  filter: drop-shadow(0 0 8px rgba(var(--c-rgb), 0.6));
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

.notification-timer {
  position: absolute;
  left: 20px;
  right: 16px;
  bottom: 8px;
  height: 2px;
  border-radius: 2px;
  background: var(--fill-2);
  overflow: hidden;
}

/* scaleX instead of width: runs on the compositor */
.notification-timer-bar {
  height: 100%;
  width: 100%;
  background: var(--c);
  transform-origin: left;
  animation: timer-drain 5s linear forwards;
}

@keyframes timer-drain {
  from { transform: scaleX(1); }
  to { transform: scaleX(0); }
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
