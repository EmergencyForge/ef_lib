<script setup lang="ts">
import { useNotificationStore, type Notification } from '@/stores/notification'
import { useSettingsStore } from '@/stores/settings'

const notificationStore = useNotificationStore()
const settingsStore = useSettingsStore()

function getIcon(type: Notification['type']): string {
  switch (type) {
    case 'success': return '✓'
    case 'error': return '✕'
    case 'warning': return '!'
    case 'info': return 'i'
    default: return 'i'
  }
}
</script>

<template>
  <div class="notifications-container" :class="`position-${settingsStore.notificationPosition}`">
    <TransitionGroup name="notification">
      <div
        v-for="notification in notificationStore.notifications"
        :key="notification.id"
        class="notification"
        :class="notification.type"
      >
        <div class="notification-accent"></div>
        <div class="notification-body">
          <div class="notification-icon">
            {{ getIcon(notification.type) }}
          </div>
          <div class="notification-content">
            <div class="notification-title">{{ notification.title }}</div>
            <div v-if="notification.message" class="notification-message">
              {{ notification.message }}
            </div>
          </div>
          <button
            class="notification-close"
            @click="notificationStore.removeNotification(notification.id)"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
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
  top: 20px;
  right: 20px;
}

.notifications-container.position-top-left {
  top: 20px;
  left: 20px;
}

.notifications-container.position-bottom-right {
  bottom: 20px;
  right: 20px;
  flex-direction: column-reverse;
}

.notifications-container.position-bottom-left {
  bottom: 20px;
  left: 20px;
  flex-direction: column-reverse;
}

.notification {
  position: relative;
  min-width: 300px;
  max-width: 380px;
  border-radius: 10px;
  overflow: hidden;
  pointer-events: auto;
  background: rgb(18, 18, 22);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.5),
    0 1px 4px rgba(0, 0, 0, 0.3);
}

/* Colored accent bar on the left */
.notification-accent {
  position: absolute;
  top: 0;
  left: 0;
  width: 3px;
  height: 100%;
}

.notification.success .notification-accent { background: #22c55e; }
.notification.error .notification-accent { background: #ef4444; }
.notification.warning .notification-accent { background: #f59e0b; }
.notification.info .notification-accent { background: #3b82f6; }

.notification-body {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px 12px 18px;
}

.notification-icon {
  width: 26px;
  height: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 0.75rem;
  font-weight: 700;
  flex-shrink: 0;
  margin-top: 1px;
}

.notification.success .notification-icon {
  background: rgba(34, 197, 94, 0.15);
  color: #4ade80;
}

.notification.error .notification-icon {
  background: rgba(239, 68, 68, 0.15);
  color: #f87171;
}

.notification.warning .notification-icon {
  background: rgba(245, 158, 11, 0.15);
  color: #fbbf24;
}

.notification.info .notification-icon {
  background: rgba(59, 130, 246, 0.15);
  color: #60a5fa;
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: #f0f0f0;
  line-height: 1.3;
}

.notification-message {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.55);
  line-height: 1.45;
  margin-top: 3px;
}

.notification-close {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.25);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
  flex-shrink: 0;
  margin-top: 1px;
}

.notification-close:hover {
  color: rgba(255, 255, 255, 0.7);
  background: rgba(255, 255, 255, 0.08);
}

/* Timer bar at bottom */
.notification-timer {
  height: 2px;
  background: rgba(255, 255, 255, 0.04);
}

.notification-timer-bar {
  height: 100%;
  width: 100%;
  animation: timer-shrink 5s linear forwards;
}

.notification.success .notification-timer-bar { background: rgba(34, 197, 94, 0.5); }
.notification.error .notification-timer-bar { background: rgba(239, 68, 68, 0.5); }
.notification.warning .notification-timer-bar { background: rgba(245, 158, 11, 0.5); }
.notification.info .notification-timer-bar { background: rgba(59, 130, 246, 0.5); }

@keyframes timer-shrink {
  from { width: 100%; }
  to { width: 0%; }
}

/* Transitions */
.notification-enter-active,
.notification-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.notification-move {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
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
