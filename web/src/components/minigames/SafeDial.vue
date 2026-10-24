<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import type { SafeDialParams } from '@/minigames/params'
import { sfx } from '@/composables/sfx'

// The combination is hidden unless the script passes it in (a note the player
// found). Near the right number, turned the right way, the dial gets heavy,
// glows and clicks.
const props = defineProps<{ params: SafeDialParams; active: boolean }>()
const emit = defineEmits<{ progress: [done: number, total: number]; miss: []; win: [] }>()

const DEG_PER_SEC = 120
const FEEL = 3 // numbers around the target where the dial gets heavy

const canvas = ref<HTMLCanvasElement | null>(null)
const angle = ref(0)
const targets = ref<number[]>([])
const solved = ref<boolean[]>([])
const current = ref(0)
const turning = ref(0) // +1 left (A), -1 right (D)

const known = computed(() => !!props.params.code?.length)
const dpn = computed(() => 360 / props.params.numbers)
const number = computed(() => Math.round((((360 - angle.value) % 360 + 360) % 360) / dpn.value) % props.params.numbers)
// Classic safes: first turn right, then alternate
const wantDir = computed(() => (current.value % 2 === 0 ? -1 : 1))

function distance(a: number, b: number) {
  const n = props.params.numbers
  const d = Math.abs(a - b) % n
  return Math.min(d, n - d)
}

const lastDir = ref(0) // direction of the last turn; the feel only works the right way
const dist = computed(() => targets.value[current.value] === undefined ? 99 : distance(number.value, targets.value[current.value]))
const closeness = computed(() => {
  if (lastDir.value !== wantDir.value) return 0
  if (dist.value <= props.params.tolerance) return 1
  return Math.max(0, 1 - dist.value / (FEEL + 1))
})

let lastNumber = -1
let wasOn = false

function turn(dir: number, degrees: number) {
  lastDir.value = dir
  // Heavier close to the target, but only when turning the right way
  const heavy = dir === wantDir.value && dist.value <= FEEL ? 0.3 + 0.7 * (dist.value / FEEL) : 1
  angle.value = ((angle.value + dir * degrees * heavy) % 360 + 360) % 360
  if (number.value !== lastNumber) {
    lastNumber = number.value
    const on = dir === wantDir.value && dist.value <= props.params.tolerance
    on && !wasOn ? sfx.click() : sfx.tick()
    wasOn = on
  }
}

function start() {
  const n = props.params.numbers
  targets.value = known.value
    ? props.params.code!.map(c => ((Math.round(c) % n) + n) % n)
    : Array.from({ length: props.params.codes }, () => Math.floor(Math.random() * n))
  solved.value = targets.value.map(() => false)
  current.value = 0
  emit('progress', 0, targets.value.length)
}

function attempt() {
  if (!props.active || current.value >= targets.value.length) return
  if (dist.value <= props.params.tolerance && lastDir.value === wantDir.value) {
    solved.value[current.value] = true
    sfx.set(current.value * 3)
    current.value++
    lastDir.value = 0
    emit('progress', current.value, targets.value.length)
    if (current.value >= targets.value.length) emit('win')
  } else {
    emit('miss')
  }
}

// ── Drawing ──
function draw() {
  const c = canvas.value
  const ctx = c?.getContext('2d')
  if (!c || !ctx) return
  const W = c.width, CX = W / 2, CY = W / 2
  const outerR = 280, innerR = 200
  const n = props.params.numbers
  const accent = getComputedStyle(document.documentElement).getPropertyValue('--accent-rgb').trim() || '240, 80, 10'
  const glow = closeness.value

  ctx.clearRect(0, 0, W, W)

  // Outer ring, lights up the closer the dial is
  ctx.beginPath()
  ctx.arc(CX, CY, outerR, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(16, 16, 18, 0.75)'
  ctx.fill()
  ctx.lineWidth = 3
  ctx.strokeStyle = glow > 0 ? `rgba(${accent}, ${0.15 + glow * 0.75})` : 'rgba(255,255,255,0.14)'
  ctx.shadowColor = `rgba(${accent}, ${glow})`
  ctx.shadowBlur = glow * 30
  ctx.stroke()
  ctx.shadowBlur = 0

  const face = ctx.createRadialGradient(CX - 120, CY - 140, 20, CX, CY, outerR)
  face.addColorStop(0, 'rgba(58, 58, 64, 0.85)')
  face.addColorStop(1, 'rgba(20, 20, 23, 0.9)')
  ctx.beginPath()
  ctx.arc(CX, CY, innerR + 45, 0, Math.PI * 2)
  ctx.fillStyle = face
  ctx.fill()

  for (let i = 0; i < n; i++) {
    const a = (i * dpn.value + angle.value - 90) * Math.PI / 180
    const major = i % 5 === 0
    ctx.beginPath()
    ctx.moveTo(CX + Math.cos(a) * (outerR - (major ? 11 : 7)), CY + Math.sin(a) * (outerR - (major ? 11 : 7)))
    ctx.lineTo(CX + Math.cos(a) * (outerR - 2), CY + Math.sin(a) * (outerR - 2))
    ctx.strokeStyle = major ? 'rgba(255,255,255,0.5)' : 'rgba(255,255,255,0.15)'
    ctx.lineWidth = major ? 1.5 : 0.8
    ctx.stroke()
    if (major) {
      ctx.font = "500 13px Geist, 'Segoe UI', sans-serif"
      ctx.fillStyle = 'rgba(255,255,255,0.45)'
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillText(String(i), CX + Math.cos(a) * (outerR - 26), CY + Math.sin(a) * (outerR - 26))
    }
  }

  ctx.beginPath()
  ctx.arc(CX, CY, innerR - 18, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(10, 10, 12, 0.88)'
  ctx.fill()
  ctx.strokeStyle = 'rgba(255,255,255,0.1)'
  ctx.lineWidth = 1
  ctx.stroke()

  ctx.font = "700 64px Geist, 'Segoe UI', sans-serif"
  ctx.fillStyle = glow >= 1 ? `rgb(${accent})` : 'rgba(255,255,255,0.88)'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText(String(number.value), CX, CY - 6)

  for (let i = 0; i < 4; i++) {
    const a = (i * 90 + angle.value) * Math.PI / 180
    ctx.beginPath()
    ctx.moveTo(CX + Math.cos(a) * (innerR - 12), CY + Math.sin(a) * (innerR - 12))
    ctx.lineTo(CX + Math.cos(a) * (innerR + 36), CY + Math.sin(a) * (innerR + 36))
    ctx.strokeStyle = 'rgba(255,255,255,0.04)'
    ctx.lineWidth = 10
    ctx.lineCap = 'round'
    ctx.stroke()
  }
}

let raf = 0
let last = 0

function loop(ts: number) {
  const dt = last ? Math.min(0.05, (ts - last) / 1000) : 0
  last = ts
  if (props.active && turning.value) turn(turning.value, DEG_PER_SEC * dt)
  draw()
  raf = requestAnimationFrame(loop)
}

function onKeyDown(e: KeyboardEvent) {
  const k = e.key.toLowerCase()
  if (k === 'a' || k === 'arrowleft') turning.value = 1
  if (k === 'd' || k === 'arrowright') turning.value = -1
  if (k === ' ' || k === 'enter') { e.preventDefault(); if (!e.repeat) attempt() }
}
function onKeyUp(e: KeyboardEvent) {
  const k = e.key.toLowerCase()
  if ((k === 'a' || k === 'arrowleft') && turning.value === 1) turning.value = 0
  if ((k === 'd' || k === 'arrowright') && turning.value === -1) turning.value = 0
}
function onWheel(e: WheelEvent) {
  if (!props.active) return
  turn(e.deltaY > 0 ? -1 : 1, dpn.value)
}

onMounted(() => {
  start()
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
  window.addEventListener('wheel', onWheel, { passive: true })
  raf = requestAnimationFrame(loop)
})
onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('keyup', onKeyUp)
  window.removeEventListener('wheel', onWheel)
  cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="sd">
    <div class="dir" :class="wantDir === 1 ? 'left' : 'right'">
      <i :class="wantDir === 1 ? 'fa-solid fa-rotate-left' : 'fa-solid fa-rotate-right'"></i>
      {{ wantDir === 1 ? 'Nach links drehen' : 'Nach rechts drehen' }}
    </div>

    <div class="wrap" :class="{ hot: closeness >= 1 }">
      <div class="marker"></div>
      <canvas ref="canvas" width="600" height="600"></canvas>
    </div>

    <div class="combo">
      <span v-if="known" class="note"><i class="fa-solid fa-note-sticky"></i> Notiz</span>
      <template v-for="(t, i) in targets" :key="i">
        <span v-if="i > 0" class="sep">·</span>
        <div class="slot" :class="{ active: i === current, solved: solved[i] }">{{ solved[i] || known ? t : '?' }}</div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.sd { display: flex; flex-direction: column; align-items: center; gap: 16px; }

.dir {
  display: flex; align-items: center; justify-content: center; gap: 8px;
  min-width: 180px;
  padding: 6px 16px;
  border-radius: var(--radius-pill);
  font-size: 13px; font-weight: 500;
  transition: background 0.25s ease, color 0.25s ease, box-shadow 0.25s ease;
}
.dir.left { color: var(--info); background: rgba(var(--info-rgb), 0.14); box-shadow: inset 0 0 0 1px rgba(var(--info-rgb), 0.35); }
.dir.right { color: #c084fc; background: rgba(192, 132, 252, 0.14); box-shadow: inset 0 0 0 1px rgba(192, 132, 252, 0.35); }

.wrap { position: relative; width: 300px; height: 300px; }

canvas { width: 300px; height: 300px; filter: drop-shadow(0 8px 24px rgba(0, 0, 0, 0.45)); }

.marker {
  position: absolute; top: -3px; left: 50%;
  transform: translateX(-50%);
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 14px solid var(--accent-color);
  filter: drop-shadow(0 0 6px rgba(var(--accent-rgb), 0.5));
  z-index: 5;
  transition: transform 0.2s var(--spring);
}

.wrap.hot .marker { transform: translateX(-50%) translateY(3px) scale(1.15); }

.combo { display: flex; align-items: center; gap: 6px; }

.note {
  display: flex; align-items: center; gap: 6px;
  margin-right: 6px;
  font-size: 12px; color: var(--text-3);
}

.slot {
  width: 42px; height: 42px;
  display: flex; align-items: center; justify-content: center;
  border-radius: var(--radius-ctl);
  background: var(--well);
  box-shadow: var(--well-rim);
  color: var(--text-3);
  font-size: 16px; font-weight: 600;
  font-variant-numeric: tabular-nums;
  transition: background 0.25s ease, color 0.25s ease, box-shadow 0.25s ease, transform 0.4s var(--spring);
}

.slot.active {
  color: var(--text);
  background: rgba(var(--accent-rgb), 0.2);
  box-shadow: inset 0 0 0 1px var(--accent-color), 0 0 12px rgba(var(--accent-rgb), 0.25);
}

.slot.solved {
  color: var(--ok);
  background: rgba(var(--ok-rgb), 0.12);
  box-shadow: inset 0 0 0 1px rgba(var(--ok-rgb), 0.5);
  transform: scale(1.06);
}

.sep { color: var(--text-3); }
</style>
