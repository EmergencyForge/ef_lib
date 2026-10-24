<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import type { ReactionParams } from '@/minigames/params'
import { sfx } from '@/composables/sfx'

// A ring closes in on a field; press its key when the ring meets the edge.
// Misses cost an attempt, the chain keeps going.
const props = defineProps<{ params: ReactionParams; active: boolean }>()
const emit = defineEmits<{ progress: [done: number, total: number]; miss: []; win: [] }>()

interface Note { id: number; lane: number; arrive: number; state: 'open' | 'hit' | 'miss' }

const SYMBOLS = ['fa-bolt', 'fa-droplet', 'fa-fire', 'fa-heart-pulse', 'fa-shield-halved', 'fa-star']
const COLORS = ['var(--accent-color)', '#38bdf8', '#f472b6', '#a3e635', '#fbbf24', '#a78bfa']
const RING_START = 1.9 // ring scale when it appears

const now = ref(performance.now())
const notes = ref<Note[]>([])
const hits = ref(0)
const flash = ref<Record<number, 'hit' | 'perfect' | 'miss'>>({})

let nextId = 0
let nextSpawn = 0
let lastLane = -1

function laneFlash(lane: number, kind: 'hit' | 'perfect' | 'miss') {
  flash.value = { ...flash.value, [lane]: kind }
  setTimeout(() => {
    if (flash.value[lane] === kind) {
      const f = { ...flash.value }
      delete f[lane]
      flash.value = f
    }
  }, 260)
}

function spawn(t: number) {
  const lanes = props.params.keys.length
  let lane = Math.floor(Math.random() * lanes)
  if (lane === lastLane && lanes > 2) lane = (lane + 1 + Math.floor(Math.random() * (lanes - 1))) % lanes
  lastLane = lane
  notes.value.push({ id: nextId++, lane, arrive: t + props.params.approach, state: 'open' })
  nextSpawn = t + props.params.interval * (0.8 + Math.random() * 0.4)
}

function open() {
  return notes.value.filter(n => n.state === 'open')
}

function resolve(n: Note, state: 'hit' | 'miss', perfect = false) {
  n.state = state
  if (state === 'hit') {
    hits.value++
    sfx.hit(perfect)
    laneFlash(n.lane, perfect ? 'perfect' : 'hit')
    emit('progress', hits.value, props.params.notes)
    if (hits.value >= props.params.notes) emit('win')
  } else {
    laneFlash(n.lane, 'miss')
    emit('miss')
  }
  // Keep resolved notes a moment for their fade, then drop them
  setTimeout(() => { notes.value = notes.value.filter(x => x !== n) }, 300)
}

function press(lane: number) {
  if (!props.active) return
  const t = performance.now()
  const w = props.params.window
  // Earliest open ring on this lane that has already appeared
  const n = open().filter(x => x.lane === lane && x.arrive - props.params.approach <= t).sort((a, b) => a.arrive - b.arrive)[0]
  if (!n) {
    laneFlash(lane, 'miss')
    emit('miss')
    return
  }
  const dt = Math.abs(t - n.arrive)
  resolve(n, dt <= w ? 'hit' : 'miss', dt <= w / 2)
}

let raf = 0

function loop(t: number) {
  now.value = t
  if (props.active) {
    // Stop spawning once enough rings are on screen to finish the chain
    if (t >= nextSpawn && hits.value + open().length < props.params.notes) spawn(t)
    for (const n of open()) if (t > n.arrive + props.params.window) resolve(n, 'miss')
  }
  raf = requestAnimationFrame(loop)
}

function ringScale(n: Note) {
  const left = (n.arrive - now.value) / props.params.approach
  return 1 + Math.max(-0.15, left) * (RING_START - 1)
}

function ringOpacity(n: Note) {
  if (n.state !== 'open') return 0
  const left = (n.arrive - now.value) / props.params.approach
  return Math.min(1, (1 - left) * 2.5)
}

function onKeyDown(e: KeyboardEvent) {
  if (e.repeat) return
  const lane = props.params.keys.indexOf(e.key.toUpperCase())
  if (lane >= 0) press(lane)
}

onMounted(() => {
  emit('progress', 0, props.params.notes)
  nextSpawn = performance.now() + 700
  window.addEventListener('keydown', onKeyDown)
  raf = requestAnimationFrame(loop)
})
onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="rc">
    <div
      v-for="(key, lane) in params.keys"
      :key="lane"
      class="field"
      :class="flash[lane]"
      :style="{ '--c': COLORS[lane] }"
      @mousedown="press(lane)"
    >
      <i class="sym fa-solid" :class="SYMBOLS[lane]"></i>
      <span class="key">{{ key }}</span>
      <div
        v-for="n in notes.filter(x => x.lane === lane)"
        :key="n.id"
        class="ring"
        :style="{ transform: `scale(${ringScale(n)})`, opacity: ringOpacity(n) }"
      ></div>
    </div>
  </div>
</template>

<style scoped>
.rc { display: flex; gap: 18px; padding: 50px 30px; }

.field {
  position: relative;
  width: 96px;
  height: 96px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 50%;
  color: var(--c);
  background: rgba(10, 10, 12, 0.55);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.15);
  cursor: pointer;
  transition: box-shadow 0.15s ease, background 0.15s ease, transform 0.3s var(--spring);
}

.sym { font-size: 26px; filter: drop-shadow(0 0 8px currentColor); }

.key {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-2);
}

.ring {
  position: absolute;
  inset: -2px;
  border-radius: 50%;
  border: 3px solid currentColor;
  box-shadow: 0 0 12px -2px currentColor, inset 0 0 12px -2px currentColor;
  pointer-events: none;
  will-change: transform, opacity;
}

.field.hit, .field.perfect { box-shadow: inset 0 0 0 3px currentColor, 0 0 28px -4px currentColor; transform: scale(1.06); }
.field.perfect { background: rgba(255, 255, 255, 0.08); }
.field.miss { color: var(--danger); box-shadow: inset 0 0 0 3px var(--danger), 0 0 24px -4px var(--danger); animation: nudge 0.26s ease; }

@keyframes nudge {
  30% { transform: translateX(-4px); }
  70% { transform: translateX(4px); }
}
</style>
