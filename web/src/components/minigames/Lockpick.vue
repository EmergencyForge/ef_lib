<script setup lang="ts">
import { t } from '@/i18n'
import { ref, computed, onMounted, onUnmounted } from 'vue'
import type { LockpickParams } from '@/minigames/params'
import { sfx } from '@/composables/sfx'

// Hold the mouse (or W) to put tension on the lock. Each pin only sets with
// the tension inside its band; too much and the pick slips and the last set
// pin drops again.
const props = defineProps<{ params: LockpickParams; active: boolean }>()
const emit = defineEmits<{ progress: [done: number, total: number]; miss: []; win: [] }>()

interface Pin {
  y: number
  dir: number
  speed: number
  lo: number
  hi: number
  locked: boolean
  flash: '' | 'set' | 'fail'
}

const CH = 260
const KEY_H = 48
const MARGIN = 8
const SHEAR = CH / 2
const TENSION_UP = 0.55   // per second while held
const TENSION_DOWN = 0.9  // per second when released
const SLIP_OVER = 0.1     // how far above the band before the pick slips

const pins = ref<Pin[]>([])
const current = ref(0)
const tension = ref(0)
const holding = ref(false)
const slipped = ref(false)

const pin = computed(() => pins.value[current.value])
const inBand = computed(() => !!pin.value && tension.value >= pin.value.lo && tension.value <= pin.value.hi)
const over = computed(() => !!pin.value && tension.value > pin.value.hi)

function makePins() {
  const w = props.params.tension
  pins.value = Array.from({ length: props.params.pins }, () => {
    const c = 0.35 + Math.random() * 0.4
    return {
      y: MARGIN + Math.random() * (CH - KEY_H - 2 * MARGIN),
      dir: Math.random() > 0.5 ? 1 : -1,
      speed: props.params.speed * (0.85 + Math.random() * 0.3),
      lo: c - w / 2,
      hi: c + w / 2,
      locked: false,
      flash: '' as const,
    }
  })
  emit('progress', 0, props.params.pins)
}

function flash(p: Pin, kind: Pin['flash']) {
  p.flash = kind
  setTimeout(() => { if (p.flash === kind) p.flash = '' }, 420)
}

function attempt() {
  if (!props.active || !pin.value) return
  const p = pin.value
  const center = p.y + KEY_H / 2
  const half = props.params.zone / 2
  if (center >= SHEAR - half && center <= SHEAR + half && inBand.value) {
    p.locked = true
    p.y = SHEAR - KEY_H / 2
    flash(p, 'set')
    sfx.set(current.value * 2)
    current.value++
    emit('progress', current.value, pins.value.length)
    if (current.value >= pins.value.length) emit('win')
  } else {
    flash(p, 'fail')
    tension.value *= 0.5
    emit('miss')
  }
}

function slip() {
  tension.value = 0
  holding.value = false
  slipped.value = true
  setTimeout(() => { slipped.value = false }, 450)
  sfx.slip()
  if (current.value > 0) {
    current.value--
    const p = pins.value[current.value]
    p.locked = false
    p.dir = -1
    flash(p, 'fail')
    emit('progress', current.value, pins.value.length)
  }
}

let raf = 0
let last = 0
let wasInBand = false

function loop(ts: number) {
  const dt = last ? Math.min(0.05, (ts - last) / 1000) : 0
  last = ts
  if (props.active) {
    tension.value = Math.min(1, Math.max(0, tension.value + (holding.value ? TENSION_UP : -TENSION_DOWN) * dt))
    if (pin.value && tension.value > pin.value.hi + SLIP_OVER) slip()
    if (inBand.value && !wasInBand) sfx.tick()
    wasInBand = inBand.value

    pins.value.forEach((p, i) => {
      if (p.locked) return
      // The right tension calms the active pin down
      const slow = i === current.value && inBand.value ? 0.55 : 1
      p.y += p.dir * p.speed * slow * 120 * dt
      if (p.y <= MARGIN) { p.y = MARGIN; p.dir = 1 }
      if (p.y >= CH - KEY_H - MARGIN) { p.y = CH - KEY_H - MARGIN; p.dir = -1 }
    })
  }
  raf = requestAnimationFrame(loop)
}

function onKeyDown(e: KeyboardEvent) {
  if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); if (!e.repeat) attempt() }
  if (e.key === 'w' || e.key === 'W') holding.value = true
}
function onKeyUp(e: KeyboardEvent) {
  if (e.key === 'w' || e.key === 'W') holding.value = false
}
function onMouseDown(e: MouseEvent) { if (e.button === 0) holding.value = true }
function onMouseUp(e: MouseEvent) { if (e.button === 0) holding.value = false }

onMounted(() => {
  makePins()
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
  window.addEventListener('mousedown', onMouseDown)
  window.addEventListener('mouseup', onMouseUp)
  raf = requestAnimationFrame(loop)
})
onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('keyup', onKeyUp)
  window.removeEventListener('mousedown', onMouseDown)
  window.removeEventListener('mouseup', onMouseUp)
  cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="lp" :class="{ slipped }">
    <div class="gauge">
      <div class="tension" :class="{ good: inBand, over }">
        <div v-if="pin" class="band" :style="{ bottom: pin.lo * 100 + '%', height: (pin.hi - pin.lo) * 100 + '%' }"></div>
        <div class="fill" :style="{ transform: `scaleY(${tension})` }"></div>
      </div>
      <span class="cap">{{ t('Spannung') }}</span>
    </div>

    <div class="area">
      <div class="shear" :style="{ top: SHEAR + 'px' }"></div>
      <div class="pins">
        <div
          v-for="(p, i) in pins"
          :key="i"
          class="col"
          :class="{ active: i === current, locked: p.locked, [p.flash]: !!p.flash }"
        >
          <div class="channel">
            <div class="zone" :style="{ top: SHEAR - params.zone / 2 + 'px', height: params.zone + 'px' }"></div>
            <div class="driver" :style="{ transform: `translateY(${p.y - 56}px)` }"></div>
            <div class="key" :style="{ transform: `translateY(${p.y}px)` }"></div>
          </div>
          <div class="num">{{ i + 1 }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.lp {
  display: flex;
  align-items: flex-start;
  gap: 28px;
  transition: transform 0.2s ease;
}

.lp.slipped { animation: slip 0.45s var(--ease); }

@keyframes slip {
  20% { transform: translateY(6px) rotate(-1deg); }
  50% { transform: translateY(-3px) rotate(0.6deg); }
}

/* ── Tension gauge ── */
.tension {
  position: relative;
  width: 14px;
  height: 260px;
  border-radius: 7px;
  background: rgba(0, 0, 0, 0.45);
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.45), inset 0 0 0 1px rgba(255, 255, 255, 0.06);
  overflow: hidden;
}

.band {
  position: absolute;
  left: 0;
  right: 0;
  background: rgba(var(--ok-rgb), 0.18);
  border-top: 1px solid rgba(var(--ok-rgb), 0.55);
  border-bottom: 1px solid rgba(var(--ok-rgb), 0.55);
  transition: bottom 0.4s var(--ease), height 0.4s var(--ease);
}

.fill {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(0deg, rgba(var(--accent-rgb), 0.55), var(--accent-color));
  transform-origin: bottom;
  opacity: 0.85;
}

.tension.good .fill { background: linear-gradient(0deg, rgba(var(--ok-rgb), 0.5), var(--ok)); box-shadow: 0 0 14px rgba(var(--ok-rgb), 0.6); }
.tension.over .fill { background: linear-gradient(0deg, rgba(var(--danger-rgb), 0.5), var(--danger)); }
.tension.good { box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.45), 0 0 16px rgba(var(--ok-rgb), 0.35); }

.gauge { display: flex; flex-direction: column; align-items: center; gap: 8px; }

.cap {
  font-size: 11px;
  color: var(--text-3);
  white-space: nowrap;
}

/* ── Pins ── */
.area { position: relative; }

.shear {
  position: absolute;
  left: -8px;
  right: -8px;
  height: 1.5px;
  background: var(--accent-color);
  opacity: 0.5;
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.5);
  z-index: 5;
  pointer-events: none;
}

.pins { display: flex; gap: 12px; }

.col { display: flex; flex-direction: column; align-items: center; width: 44px; }

.channel {
  position: relative;
  width: 36px;
  height: 260px;
  border-radius: 18px;
  background: rgba(0, 0, 0, 0.4);
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.45), inset 0 0 0 1px rgba(255, 255, 255, 0.05);
  overflow: hidden;
  transition: box-shadow 0.2s ease;
}

.zone {
  position: absolute;
  left: 0;
  right: 0;
  background: rgba(var(--ok-rgb), 0.12);
  border-top: 1px dashed rgba(var(--ok-rgb), 0.35);
  border-bottom: 1px dashed rgba(var(--ok-rgb), 0.35);
}

.driver, .key {
  position: absolute;
  top: 0;
  left: 4px;
  right: 4px;
  border-radius: 14px;
  will-change: transform;
}

.driver { height: 56px; background: rgba(255, 255, 255, 0.1); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.15); }
.key { height: 48px; background: rgba(255, 255, 255, 0.24); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.35); transition: background 0.15s ease; }

.num { margin-top: 8px; font-size: 12px; font-weight: 500; color: var(--text-3); }

.col.active .channel { box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.45), inset 0 0 0 1px rgba(var(--accent-rgb), 0.6), 0 0 18px rgba(var(--accent-rgb), 0.2); }
.col.active .key { background: var(--accent-color); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 0 12px rgba(var(--accent-rgb), 0.6); }
.col.active .num { color: var(--accent-color); }

.col.locked .key { background: var(--ok); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 0 10px rgba(var(--ok-rgb), 0.5); }
.col.locked .num { color: var(--ok); }

.col.set .channel { animation: seat 0.42s var(--spring); }
.col.fail .key { background: var(--danger); box-shadow: 0 0 12px rgba(var(--danger-rgb), 0.6); }
.col.fail .channel { animation: wobble 0.42s ease; }

@keyframes seat {
  30% { transform: translateY(3px) scaleY(0.98); }
}

@keyframes wobble {
  25% { transform: translateX(-3px); }
  75% { transform: translateX(3px); }
}
</style>
