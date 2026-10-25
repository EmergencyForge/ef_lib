<script setup lang="ts">
import { t } from '@/i18n'
import { ref, computed, watch, onMounted, onUnmounted, type Component } from 'vue'
import { useMinigameStore } from '@/stores/minigame'
import { fetchNui } from '@/composables/useNui'
import { sfx, setSoundEnabled } from '@/composables/sfx'
import type { ReactionParams } from '@/minigames/params'
import Lockpick from './minigames/Lockpick.vue'
import SafeDial from './minigames/SafeDial.vue'
import ReactionChain from './minigames/ReactionChain.vue'
import Wires from './minigames/Wires.vue'

// The frame owns time, attempts, result and sound; each game only reports
// progress, misses and the win.
const store = useMinigameStore()

const GAMES = { lockpick: Lockpick, safedial: SafeDial, reactionchain: ReactionChain, wires: Wires }
// Each game types its own params; the union from the store fits whichever is active
const game = computed(() => GAMES[store.gameType] as Component)

const active = ref(false)
const timeLeft = ref(0)
const retriesLeft = ref(0)
const maxRetries = ref(0)
const misses = ref(0)
const done = ref(0)
const total = ref(0)
const resultVisible = ref(false)
const resultSuccess = ref(false)
const containerRef = ref<HTMLElement | null>(null)
let startedAt = 0

const timerWarn = computed(() => timeLeft.value < 5)
const retriesWarn = computed(() => retriesLeft.value <= 1)
const progressPct = computed(() => total.value ? (done.value / total.value) * 100 : 0)

const controls = computed<{ keys: string[]; label: string }[]>(() => {
  switch (store.gameType) {
    case 'lockpick': return [{ keys: [t('Maus halten')], label: t('Spannung') }, { keys: ['SPACE'], label: t('Pin setzen') }]
    case 'safedial': return [{ keys: ['A', 'D'], label: t('oder Mausrad drehen') }, { keys: ['SPACE'], label: t('Zahl prüfen') }]
    case 'reactionchain': return [{ keys: (store.params as ReactionParams).keys, label: t('wenn der Ring das Feld trifft') }]
    case 'wires': return [{ keys: [t('Maus')], label: t('Kabel zum passenden Anschluss ziehen') }]
  }
  return []
})

function start() {
  const p = store.params
  setSoundEnabled(p.sound)
  timeLeft.value = p.time
  retriesLeft.value = p.retries
  maxRetries.value = p.retries
  misses.value = 0
  done.value = 0
  total.value = 0
  resultVisible.value = false
  startedAt = performance.now()
  active.value = true
  lastTs = 0
  cancelAnimationFrame(animId)
  animId = requestAnimationFrame(loop)
}

function endGame(success: boolean) {
  if (!active.value) return
  active.value = false
  resultSuccess.value = success
  resultVisible.value = true
  success ? sfx.win() : sfx.lose()
  const time = Math.round((performance.now() - startedAt) / 10) / 100

  setTimeout(() => {
    store.closeMinigame()
    fetchNui('minigameResult', { success, time, misses: misses.value })
  }, 1400)
}

function onProgress(d: number, t: number) {
  done.value = d
  total.value = t
}

function onMiss() {
  if (!active.value) return
  misses.value++
  retriesLeft.value--
  sfx.miss()
  shake()
  if (retriesLeft.value <= 0) endGame(false)
}

function shake() {
  const el = containerRef.value
  if (!el) return
  // Restart the shake even if the last one is still running
  el.classList.remove('shake')
  void el.offsetWidth
  el.classList.add('shake')
}

let animId = 0
let lastTs = 0

function loop(ts: number) {
  if (!active.value) return
  const dt = lastTs ? (ts - lastTs) / 1000 : 0
  lastTs = ts
  timeLeft.value = Math.max(0, timeLeft.value - dt)
  if (timeLeft.value <= 0) return endGame(false)
  animId = requestAnimationFrame(loop)
}

function onKeyDown(e: KeyboardEvent) {
  if (active.value && e.key === 'Escape') endGame(false)
}

watch(() => store.session, () => { if (store.visible) start() })
watch(() => store.visible, v => { if (!v) { active.value = false; cancelAnimationFrame(animId) } })

onMounted(() => window.addEventListener('keydown', onKeyDown))
onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  cancelAnimationFrame(animId)
})
</script>

<template>
  <Transition name="mg" :duration="{ enter: 900, leave: 220 }">
    <div v-if="store.visible" class="mg-overlay">
      <div ref="containerRef" class="mg-container">

        <!-- ── TOP: time, title, attempts ── -->
        <div class="mg-top mg-stagger" style="--i: 0">
          <div class="mg-timer" :class="{ warn: timerWarn }">{{ timeLeft.toFixed(1) }}<small> s</small></div>
          <div class="mg-meta">
            <span class="mg-title">{{ t(store.typeLabel.title) }}</span>
            <span class="mg-attempts" :class="{ warn: retriesWarn }">
              <template v-if="maxRetries <= 8"><i v-for="n in maxRetries" :key="n" :class="{ off: n > retriesLeft }"></i></template>
              <template v-else>{{ retriesLeft }} Versuche</template>
            </span>
          </div>
        </div>

        <component
          :is="game"
          :key="store.session"
          class="mg-body mg-stagger"
          style="--i: 1"
          :params="store.params"
          :active="active"
          @progress="onProgress"
          @miss="onMiss"
          @win="endGame(true)"
        />

        <!-- ── PROGRESS ── -->
        <div class="mg-bottom mg-stagger" style="--i: 2">
          <div class="mg-progress-track">
            <div class="mg-progress-fill" :style="{ width: progressPct + '%' }"></div>
          </div>
          <div class="mg-progress-label">{{ done }} / {{ total }} {{ t(store.typeLabel.unit) }}</div>
        </div>

        <!-- ── RESULT OVERLAY ── -->
        <Transition name="result">
          <div v-if="resultVisible" class="mg-result" :class="{ success: resultSuccess, fail: !resultSuccess }">
            <div class="mg-result-content">
              <div class="mg-result-icon"><i :class="resultSuccess ? 'fa-solid fa-check' : 'fa-solid fa-xmark'"></i></div>
              <div class="mg-result-text">{{ resultSuccess ? t('Geschafft') : t('Fehlgeschlagen') }}</div>
            </div>
          </div>
        </Transition>
      </div>

      <div class="mg-controls mg-stagger" style="--i: 3">
        <span v-for="c in controls" :key="c.label" class="mg-ctrl">
          <kbd v-for="k in c.keys" :key="k" class="kbd">{{ k }}</kbd> {{ c.label }}
        </span>
        <span class="mg-ctrl"><kbd class="kbd">ESC</kbd> {{ t('Abbrechen') }}</span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* ══════════════════════════════════════════════════════════════
   SHARED LAYOUT
   No card: the game floats over the (Lua-blurred) game world, so the
   scrim carries readability when Config.ScreenBlur is off.
   ══════════════════════════════════════════════════════════════ */

.mg-overlay {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 18px;
  z-index: 1200;
  background: radial-gradient(60% 70% at 50% 50%, rgba(0, 0, 0, 0.62), rgba(0, 0, 0, 0.35));
}

.mg-container {
  position: relative;
  width: 560px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18px;
}

.mg-container.shake {
  animation: shake 0.42s cubic-bezier(0.36, 0.07, 0.19, 0.97);
}

@keyframes shake {
  15%, 85% { transform: translateX(-3px); }
  30%, 70% { transform: translateX(6px); }
  45% { transform: translateX(-8px); }
  60% { transform: translateX(8px); }
}

/* Children enter one after another */
.mg-stagger {
  transition: opacity 0.4s ease, transform 0.7s var(--spring), filter 0.4s ease;
  transition-delay: calc(var(--i) * 70ms);
}

/* ── Top: big time, title, attempts ── */
.mg-top {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.mg-timer {
  font-size: 64px;
  font-weight: 300;
  line-height: 1;
  letter-spacing: -0.03em;
  font-variant-numeric: tabular-nums;
  color: var(--text);
  text-shadow: 0 2px 24px rgba(0, 0, 0, 0.55);
  transition: color 0.3s ease;
}

.mg-timer small {
  font-size: 24px;
  color: var(--text-3);
}

.mg-timer.warn {
  color: var(--danger);
  animation: statPulse 0.6s ease-in-out infinite alternate;
}

@keyframes statPulse { to { opacity: 0.55; } }

.mg-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 13px;
  font-weight: 500;
  color: var(--text-2);
  text-shadow: 0 1px 6px rgba(0, 0, 0, 0.6);
}

.mg-attempts {
  display: flex;
  align-items: center;
  gap: 5px;
}

.mg-attempts i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent-color);
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.7);
  transition: background 0.3s ease, box-shadow 0.3s ease, transform 0.4s var(--spring);
}

.mg-attempts i.off {
  background: rgba(255, 255, 255, 0.18);
  box-shadow: none;
  transform: scale(0.8);
}

.mg-attempts.warn i:not(.off) {
  background: var(--danger);
  box-shadow: 0 0 6px rgba(var(--danger-rgb), 0.7);
}

/* ── Body ── */
.mg-body {
  min-height: 200px;
}

/* ── Progress ── */
.mg-bottom {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 320px;
}

.mg-progress-track {
  flex: 1;
  height: 4px;
  border-radius: var(--radius-pill);
  background: rgba(255, 255, 255, 0.12);
  overflow: hidden;
}

.mg-progress-fill {
  height: 100%;
  border-radius: inherit;
  background: var(--accent-color);
  box-shadow: 0 0 8px rgba(var(--accent-rgb), 0.6);
  transition: width 0.4s var(--ease);
}

.mg-progress-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-2);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

/* ── Controls hint ── */
.mg-controls {
  display: flex; align-items: center; gap: 8px;
  padding: 6px 14px;
  border-radius: var(--radius-pill);
  background: rgba(10, 10, 12, 0.6);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.12), inset 0 0 0 1px rgba(255, 255, 255, 0.06);
}

.mg-ctrl {
  font-size: 12px; color: var(--text-2);
  display: flex; align-items: center; gap: 4px;
}

.mg-ctrl + .mg-ctrl { margin-left: 8px; }


/* ── Result ── */
.mg-result {
  position: absolute;
  inset: -24px;
  display: flex; align-items: center; justify-content: center;
  z-index: 10;
  border-radius: 28px;
  /* Blurs the game UI underneath, which is inside the NUI page and therefore works */
  backdrop-filter: blur(12px);
  background: rgba(8, 8, 10, 0.45);
}

.mg-result-content { text-align: center; }

.mg-result-icon {
  width: 72px; height: 72px;
  margin: 0 auto 14px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 50%;
  font-size: 28px;
}

.mg-result.success .mg-result-icon {
  color: var(--ok);
  background: rgba(var(--ok-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--ok-rgb), 0.4), 0 0 40px rgba(var(--ok-rgb), 0.3);
}

.mg-result.fail .mg-result-icon {
  color: var(--danger);
  background: rgba(var(--danger-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--danger-rgb), 0.4), 0 0 40px rgba(var(--danger-rgb), 0.3);
}

.mg-result-text {
  font-size: 24px; font-weight: 600; letter-spacing: -0.01em;
}

.mg-result.success .mg-result-text { color: var(--ok); }
.mg-result.fail .mg-result-text { color: var(--danger); }

/* ══════════════════════════════════════════════════════════════
   TRANSITIONS
   ══════════════════════════════════════════════════════════════ */

.mg-enter-active { transition: opacity 0.3s ease; }
.mg-leave-active { transition: opacity 0.22s var(--exit); }
.mg-enter-from, .mg-leave-to { opacity: 0; }

.mg-enter-from .mg-stagger { opacity: 0; transform: translateY(14px) scale(0.96); filter: blur(6px); }
.mg-leave-active .mg-stagger { transition: opacity 0.2s var(--exit), transform 0.22s var(--exit); transition-delay: 0s; }
.mg-leave-to .mg-stagger { opacity: 0; transform: scale(0.98); }

.result-enter-active { transition: opacity 0.25s ease-out; }
.result-enter-active .mg-result-content { animation: resultPop 0.5s var(--spring); }
.result-leave-active { transition: opacity 0.15s ease-in; }
.result-enter-from, .result-leave-to { opacity: 0; }

@keyframes resultPop {
  from { opacity: 0; transform: scale(0.6) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
