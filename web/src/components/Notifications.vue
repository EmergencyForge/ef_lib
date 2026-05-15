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
        class="notification"
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
  gap: 12px;
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
  position: relative;
  min-width: 340px;
  max-width: 400px;
  border-radius: 5px;
  overflow: hidden;
  pointer-events: auto;
  background: linear-gradient(180deg, rgb(24, 24, 28) 0%, rgb(18, 18, 22) 100%);
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  isolation: isolate;
}

/* Soft top highlight per type */
.notification::before {
  content: '';
  position: absolute;
  inset: 0 0 auto 0;
  height: 1px;
  pointer-events: none;
}

.notification.success::before { background: linear-gradient(90deg, transparent, rgba(34, 197, 94, 0.2), transparent); }
.notification.error::before   { background: linear-gradient(90deg, transparent, rgba(239, 68, 68, 0.2), transparent); }
.notification.warning::before { background: linear-gradient(90deg, transparent, rgba(245, 158, 11, 0.2), transparent); }
.notification.info::before    { background: linear-gradient(90deg, transparent, rgba(59, 130, 246, 0.2), transparent); }

.notification-body {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 14px 14px 18px;
}

.notification-icon {
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  font-size: 0.95rem;
  flex-shrink: 0;
  margin-top: 1px;
  line-height: 1;
}

.notification-icon i {
  display: block;
  line-height: 1;
}

.notification.success .notification-icon {
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.22), rgba(34, 197, 94, 0.08));
  color: #4ade80;
  box-shadow: inset 0 0 0 1px rgba(34, 197, 94, 0.25);
}

.notification.error .notification-icon {
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.22), rgba(239, 68, 68, 0.08));
  color: #f87171;
  box-shadow: inset 0 0 0 1px rgba(239, 68, 68, 0.25);
}

.notification.warning .notification-icon {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.22), rgba(245, 158, 11, 0.08));
  color: #fbbf24;
  box-shadow: inset 0 0 0 1px rgba(245, 158, 11, 0.25);
}

.notification.info .notification-icon {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.22), rgba(59, 130, 246, 0.08));
  color: #60a5fa;
  box-shadow: inset 0 0 0 1px rgba(59, 130, 246, 0.25);
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
  line-height: 1.35;
  letter-spacing: -0.01em;
}

.notification-message {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.5;
  margin-top: 4px;
  letter-spacing: 0.005em;
}

/* Timer bar at bottom */
.notification-timer {
  position: relative;
  height: 2px;
  background: rgba(255, 255, 255, 0.04);
  overflow: visible;
}

.notification-timer-bar {
  position: relative;
  height: 100%;
  width: 100%;
  animation: timer-shrink 5s linear forwards;
  border-radius: 1px;
}

/* Upward glow halo on the timer bar */
.notification-timer-bar::before {
  content: '';
  position: absolute;
  inset: -3px 0 0 0;
  height: 4px;
  filter: blur(4px);
  opacity: 0.45;
  pointer-events: none;
}

.notification.success .notification-timer-bar         { background: linear-gradient(90deg, rgba(34, 197, 94, 0.7), rgba(74, 222, 128, 0.8)); }
.notification.success .notification-timer-bar::before { background: rgba(34, 197, 94, 0.5); }

.notification.error .notification-timer-bar           { background: linear-gradient(90deg, rgba(239, 68, 68, 0.7), rgba(248, 113, 113, 0.8)); }
.notification.error .notification-timer-bar::before   { background: rgba(239, 68, 68, 0.5); }

.notification.warning .notification-timer-bar         { background: linear-gradient(90deg, rgba(245, 158, 11, 0.7), rgba(251, 191, 36, 0.8)); }
.notification.warning .notification-timer-bar::before { background: rgba(245, 158, 11, 0.5); }

.notification.info .notification-timer-bar            { background: linear-gradient(90deg, rgba(59, 130, 246, 0.7), rgba(96, 165, 250, 0.8)); }
.notification.info .notification-timer-bar::before    { background: rgba(59, 130, 246, 0.5); }

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
