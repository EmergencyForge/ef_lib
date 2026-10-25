<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useNuiEvent, fetchNui } from '@/composables/useNui'
import { sfx, setSoundEnabled } from '@/composables/sfx'

// A dot runs round the ring once; press the key while it is inside the bright arc. Several stages
// in a row, the first wrong press or a lap without a press fails the whole check.
interface Stage { zone: number; speed: number }

const R = 54
const C = 2 * Math.PI * R

const visible = ref(false)
const stages = ref<Stage[]>([])
const keys = ref<string[]>([])
const index = ref(0)
const key = ref('E')
const angle = ref(0)
const zoneStart = ref(0)
const state = ref<'' | 'hit' | 'miss'>('')

const stage = computed(() => stages.value[index.value])
const zoneDash = computed(() => `${(stage.value?.zone ?? 0) / 360 * C} ${C}`)

let raf = 0
let started = 0
let busy = false

function startStage() {
  const s = stage.value
  // Never right at the start, so there is always a moment to react
  zoneStart.value = 110 + Math.random() * (360 - 130 - s.zone)
  key.value = keys.value[Math.floor(Math.random() * keys.value.length)]
  angle.value = 0
  state.value = ''
  busy = false
  started = performance.now()
  cancelAnimationFrame(raf)
  raf = requestAnimationFrame(loop)
}

function loop(t: number) {
  angle.value = ((t - started) / 1000 / stage.value.speed) * 360
  if (angle.value >= 360) return finish(false)
  raf = requestAnimationFrame(loop)
}

function finish(success: boolean) {
  cancelAnimationFrame(raf)
  busy = true
  state.value = success ? 'hit' : 'miss'
  if (!success) sfx.miss()
  else if (index.value === stages.value.length - 1) sfx.win()
  else sfx.hit(false)

  setTimeout(() => {
    if (success && index.value < stages.value.length - 1) {
      index.value++
      startStage()
      return
    }
    visible.value = false
    fetchNui('skillCheckResult', { success })
  }, success ? 220 : 380)
}

function onKeyDown(e: KeyboardEvent) {
  if (!visible.value || busy || e.repeat) return
  const pressed = e.key.toUpperCase()
  if (!keys.value.includes(pressed)) return
  const inZone = pressed === key.value && angle.value >= zoneStart.value && angle.value <= zoneStart.value + stage.value.zone
  finish(inZone)
}

useNuiEvent('openSkillCheck', (data: { stages: Stage[]; keys: string[]; sound?: boolean }) => {
  setSoundEnabled(data.sound !== false)
  stages.value = data.stages
  keys.value = data.keys.map(k => k.toUpperCase())
  index.value = 0
  visible.value = true
  startStage()
})

useNuiEvent('cancelSkillCheck', () => {
  if (!visible.value) return
  cancelAnimationFrame(raf)
  visible.value = false
  fetchNui('skillCheckResult', { success: false })
})

onMounted(() => window.addEventListener('keydown', onKeyDown))
onUnmounted(() => {
  cancelAnimationFrame(raf)
  window.removeEventListener('keydown', onKeyDown)
})
</script>

<template>
  <Transition name="sc">
    <div v-if="visible" class="sc" :class="state">
      <div class="disc glass">
        <svg viewBox="0 0 132 132" class="ring">
          <circle class="track" cx="66" cy="66" :r="R" />
          <circle
            class="zone"
            cx="66" cy="66" :r="R"
            :stroke-dasharray="zoneDash"
            :transform="`rotate(${zoneStart - 90} 66 66)`"
          />
          <g :transform="`rotate(${angle} 66 66)`">
            <circle class="dot" cx="66" :cy="66 - R" r="7" />
          </g>
        </svg>
        <kbd class="key">{{ key }}</kbd>
      </div>
      <div v-if="stages.length > 1" class="steps">
        <span v-for="(_, i) in stages" :key="i" :class="{ done: i < index, now: i === index }"></span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.sc {
  position: fixed;
  left: 50%;
  bottom: 21vh;
  transform: translateX(-50%);
  z-index: 950;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  pointer-events: none;
}

.disc {
  position: relative;
  width: 148px;
  height: 148px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: box-shadow 0.2s ease;
}

.ring {
  position: absolute;
  inset: 8px;
  width: 132px;
  height: 132px;
}

.track {
  fill: none;
  stroke: rgba(255, 255, 255, 0.09);
  stroke-width: 10;
}

.zone {
  fill: none;
  stroke: var(--accent-color);
  stroke-width: 10;
  /* Butt ends: round caps would draw the arc wider than the part that counts */
  filter: drop-shadow(0 0 6px rgba(var(--accent-rgb), 0.7));
}

.dot {
  fill: #fff;
  filter: drop-shadow(0 0 5px rgba(255, 255, 255, 0.8));
}

.key {
  min-width: 44px;
  height: 44px;
  padding: 0 10px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  font-family: var(--font);
  font-size: 20px;
  font-weight: 600;
  color: var(--text);
  background: var(--fill-2);
  box-shadow: var(--ctl-rim);
  transition: background 0.15s ease, color 0.15s ease;
}

.sc.hit .zone { stroke: var(--ok); filter: drop-shadow(0 0 8px rgba(var(--ok-rgb), 0.8)); }
.sc.hit .key { background: var(--ok); color: #0b1a10; }
.sc.hit .disc { animation: pop 0.22s var(--spring); }

.sc.miss .zone { stroke: var(--danger); filter: drop-shadow(0 0 8px rgba(var(--danger-rgb), 0.8)); }
.sc.miss .key { background: var(--danger); color: #1f0b0b; }
.sc.miss .disc { animation: shake 0.32s ease; }

@keyframes pop {
  50% { transform: scale(1.07); }
}

@keyframes shake {
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

.steps { display: flex; gap: 6px; }

.steps span {
  width: 18px;
  height: 4px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.18);
  transition: background 0.2s ease, width 0.3s var(--spring);
}

.steps span.now { width: 28px; background: rgba(255, 255, 255, 0.6); }
.steps span.done { background: var(--ok); }

.sc-enter-active { transition: opacity 0.2s ease, transform 0.35s var(--spring); }
.sc-leave-active { transition: opacity 0.18s var(--exit), transform 0.18s var(--exit); }
.sc-enter-from { opacity: 0; transform: translateX(-50%) scale(0.85); }
.sc-leave-to { opacity: 0; transform: translateX(-50%) scale(0.92); }
</style>
