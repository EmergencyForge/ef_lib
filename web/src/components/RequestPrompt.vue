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
    <div v-if="request" :key="session" class="rq panel" :class="answer">
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
  width: 360px;
  margin-left: -180px;
  overflow: hidden;
  pointer-events: none;
}

.rq.accept { --c: var(--ok); }
.rq.decline { --c: var(--danger); }

.rq-body {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 14px 0;
}

.rq-icon {
  flex-shrink: 0;
  margin-top: 1px;
  font-size: 15px;
  line-height: 1;
  color: var(--c, var(--accent-color));
}

.rq-text { flex: 1; min-width: 0; }

.rq-title {
  font-size: 13px;
  font-weight: 600;
  line-height: 1.35;
  color: var(--text);
}

.rq-message {
  font-size: 11.5px;
  line-height: 1.45;
  color: var(--text-2);
}

.rq-actions {
  display: flex;
  gap: 8px;
  padding: 10px 14px 16px 39px;
}

.rq-choice {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 3px 10px 3px 3px;
  border-radius: var(--radius-ctl);
  font-size: 12.5px;
  font-weight: 500;
  color: var(--text-2);
  background: var(--surface-2);
  box-shadow: var(--rim);
  transition: background 0.2s ease, color 0.2s ease, transform 0.3s var(--spring);
}

.rq-choice .kbd { min-width: 22px; justify-content: center; }

.rq.accept .rq-choice.yes { color: #0b1a10; background: var(--ok); transform: scale(1.06); }
.rq.decline .rq-choice.no { color: #1f0b0b; background: var(--danger); transform: scale(1.06); }
.rq.accept .rq-choice.yes .kbd,
.rq.decline .rq-choice.no .kbd { background: rgba(0, 0, 0, 0.18); color: inherit; box-shadow: none; }

.rq-timer {
  position: absolute;
  left: 14px;
  right: 14px;
  bottom: 7px;
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
