<script setup lang="ts">
import { ref } from 'vue'
import { useNuiEvent } from '@/composables/useNui'
import { resolveIconClass } from '@/composables/icons'
import { t } from '@/i18n'

// Shown only. The keys are read by the game (client/request.lua), so the player keeps control.
interface Choice { key: string; label?: string }
interface RequestData {
  title: string
  message?: string
  icon?: string
  duration: number
  accept: Choice
  decline: Choice
}

const request = ref<RequestData | null>(null)
const answer = ref<'' | 'accept' | 'decline' | 'timeout'>('')
const session = ref(0)

useNuiEvent('openRequest', (data: RequestData) => {
  answer.value = ''
  session.value++
  request.value = data
})

useNuiEvent('closeRequest', (data: { result: 'accept' | 'decline' | 'timeout' }) => {
  answer.value = data.result
  const s = session.value
  setTimeout(() => { if (session.value === s) request.value = null }, data.result === 'timeout' ? 0 : 420)
})
</script>

<template>
  <Transition name="rq">
    <div v-if="request" :key="session" class="rq glass" :class="answer">
      <div class="rq-body">
        <i class="rq-icon" :class="resolveIconClass(request.icon || 'fa-circle-question')"></i>
        <div class="rq-text">
          <div class="rq-title">{{ request.title }}</div>
          <div v-if="request.message" class="rq-message">{{ request.message }}</div>
        </div>
      </div>
      <div class="rq-actions">
        <span class="rq-choice yes"><kbd class="kbd">{{ request.accept.key }}</kbd> {{ request.accept.label || t('Annehmen') }}</span>
        <span class="rq-choice no"><kbd class="kbd">{{ request.decline.key }}</kbd> {{ request.decline.label || t('Ablehnen') }}</span>
      </div>
      <div class="rq-timer">
        <div class="rq-timer-bar" :style="{ animationDuration: `${request.duration}ms` }"></div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.rq {
  position: fixed;
  top: 9vh;
  left: 50%;
  z-index: 9998;
  width: 400px;
  margin-left: -200px;
  overflow: hidden;
  pointer-events: none;
  transition: box-shadow 0.25s ease;
}

/* Same leading light as the notifications, in the accent colour, so it reads as something to answer */
.rq::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: -1;
  background: radial-gradient(80% 140% at 0% 50%, rgba(var(--c-rgb, var(--accent-rgb)), 0.28), transparent 70%);
  transition: background 0.25s ease;
}

.rq::after {
  content: '';
  position: absolute;
  left: 0;
  top: 16px;
  bottom: 16px;
  width: 3px;
  border-radius: 0 3px 3px 0;
  background: var(--c, var(--accent-color));
  box-shadow: 0 0 12px var(--c, var(--accent-color));
}

.rq.accept { --c: var(--ok); --c-rgb: var(--ok-rgb); }
.rq.decline { --c: var(--danger); --c-rgb: var(--danger-rgb); }

.rq-body {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 16px 18px 0 22px;
}

.rq-icon {
  flex-shrink: 0;
  margin-top: 1px;
  font-size: 18px;
  line-height: 1;
  color: var(--c, var(--accent-color));
  filter: drop-shadow(0 0 8px rgba(var(--c-rgb, var(--accent-rgb)), 0.6));
}

.rq-text { flex: 1; min-width: 0; }

.rq-title {
  font-size: 14px;
  font-weight: 600;
  line-height: 1.35;
  color: var(--text);
}

.rq-message {
  margin-top: 3px;
  font-size: 13px;
  line-height: 1.45;
  color: var(--text-2);
}

.rq-actions {
  display: flex;
  gap: 8px;
  padding: 12px 18px 20px 54px;
}

.rq-choice {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 4px 12px 4px 4px;
  border-radius: var(--radius-pill);
  font-size: 13px;
  font-weight: 500;
  color: var(--text-2);
  background: var(--fill-1);
  box-shadow: var(--ctl-rim);
  transition: background 0.2s ease, color 0.2s ease, transform 0.3s var(--spring);
}

.rq-choice .kbd { min-width: 22px; justify-content: center; }

.rq.accept .rq-choice.yes { color: #0b1a10; background: var(--ok); transform: scale(1.06); }
.rq.decline .rq-choice.no { color: #1f0b0b; background: var(--danger); transform: scale(1.06); }
.rq.accept .rq-choice.yes .kbd,
.rq.decline .rq-choice.no .kbd { background: rgba(0, 0, 0, 0.18); color: inherit; box-shadow: none; }

.rq-timer {
  position: absolute;
  left: 22px;
  right: 18px;
  bottom: 9px;
  height: 2px;
  border-radius: 2px;
  background: var(--fill-2);
  overflow: hidden;
}

.rq-timer-bar {
  height: 100%;
  background: var(--c, var(--accent-color));
  transform-origin: left;
  animation: drain 15s linear forwards;
}

.rq.accept .rq-timer-bar,
.rq.decline .rq-timer-bar { animation-play-state: paused; }

@keyframes drain {
  from { transform: scaleX(1); }
  to { transform: scaleX(0); }
}

.rq-enter-active { transition: opacity 0.3s ease, transform 0.6s var(--spring), filter 0.4s ease; }
.rq-leave-active { transition: opacity 0.22s var(--exit), transform 0.25s var(--exit), filter 0.22s ease; }
.rq-enter-from { opacity: 0; transform: translateY(-24px) scale(0.96); filter: blur(8px); }
.rq-leave-to { opacity: 0; transform: translateY(-12px) scale(0.98); filter: blur(6px); }
</style>
