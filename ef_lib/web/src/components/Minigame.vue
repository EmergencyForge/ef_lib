<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick, computed } from 'vue'
import { useMinigameStore, DIFFICULTY_LABELS, type Difficulty } from '@/stores/minigame'
import { fetchNui } from '@/composables/useNui'

const store = useMinigameStore()

// ══════════════════════════════════════════════════════════════
//  SHARED STATE
// ══════════════════════════════════════════════════════════════

const active = ref(false)
const resolved = ref(false)
const timeLeft = ref(0)
const retriesLeft = ref(0)
const maxRetries = ref(0)
const resultSuccess = ref(false)
const resultVisible = ref(false)

// ══════════════════════════════════════════════════════════════
//  DIFFICULTY CONFIGS
// ══════════════════════════════════════════════════════════════

const LOCKPICK_CFG: Record<Difficulty, { pins: number; sweetSpotPx: number; time: number; speed: number; retries: number }> = {
  easy:    { pins: 3, sweetSpotPx: 56, time: 30, speed: 1.4, retries: 4 },
  medium:  { pins: 5, sweetSpotPx: 42, time: 20, speed: 2.0, retries: 3 },
  hard:    { pins: 6, sweetSpotPx: 32, time: 15, speed: 2.8, retries: 2 },
  extreme: { pins: 7, sweetSpotPx: 22, time: 10, speed: 3.6, retries: 1 },
}

const SAFEDIAL_CFG: Record<Difficulty, { codes: number; tolerance: number; time: number; numbers: number; retries: number }> = {
  easy:    { codes: 2, tolerance: 4, time: 30, numbers: 20, retries: 4 },
  medium:  { codes: 3, tolerance: 3, time: 20, numbers: 30, retries: 3 },
  hard:    { codes: 4, tolerance: 2, time: 15, numbers: 40, retries: 2 },
  extreme: { codes: 5, tolerance: 1, time: 10, numbers: 50, retries: 1 },
}

const REACTION_CFG: Record<Difficulty, { chain: number; reactionMs: number; speedUp: number; time: number; retries: number; keys: number }> = {
  easy:    { chain: 6,  reactionMs: 1200, speedUp: 30,  time: 30, retries: 4, keys: 3 },
  medium:  { chain: 8,  reactionMs: 900,  speedUp: 40,  time: 20, retries: 3, keys: 4 },
  hard:    { chain: 12, reactionMs: 700,  speedUp: 35,  time: 15, retries: 2, keys: 4 },
  extreme: { chain: 16, reactionMs: 550,  speedUp: 30,  time: 10, retries: 1, keys: 4 },
}

// ══════════════════════════════════════════════════════════════
//  LOCKPICK STATE
// ══════════════════════════════════════════════════════════════

interface LockPin {
  y: number
  direction: number
  speed: number
  sweetTop: number
  sweetBottom: number
  locked: boolean
  failed: boolean
  travelMin: number
  travelMax: number
}

const CHANNEL_HEIGHT = 260
const PIN_KEY_H = 48
const BOUNCE_MARGIN = 8

const lpPins = ref<LockPin[]>([])
const lpCurrentPin = ref(0)

// ══════════════════════════════════════════════════════════════
//  SAFEDIAL STATE
// ══════════════════════════════════════════════════════════════

const sdDialAngle = ref(0)
const sdCurrentNumber = ref(0)
const sdTargets = ref<number[]>([])
const sdDirections = ref<number[]>([])
const sdCurrentCode = ref(0)
const sdSolved = ref<boolean[]>([])
const sdRotating = ref(0)
const dialCanvas = ref<HTMLCanvasElement | null>(null)

// ══════════════════════════════════════════════════════════════
//  REACTION CHAIN STATE
// ══════════════════════════════════════════════════════════════

const rcChainLength = ref(0)
const rcCurrentStep = ref(0)
const rcHits = ref<boolean[]>([])
const rcLitKey = ref<number | null>(null)
const rcLitTime = ref(0)
const rcReactionWindow = ref(900)
const rcWaitingForInput = ref(false)
const rcCooldown = ref(false)
const rcTimingPct = ref(0)
const rcKeyCount = ref(4)
const rcFlashKey = ref<number | null>(null)
const rcFlashType = ref<'hit' | 'miss' | null>(null)

const RC_COLORS = ['var(--accent-color)', '#fb923c', '#f472b6', '#a78bfa']
const RC_LABELS = ['Links', 'Mitte-L', 'Mitte-R', 'Rechts']

// ══════════════════════════════════════════════════════════════
//  COMPUTED
// ══════════════════════════════════════════════════════════════

const timerWarn = computed(() => timeLeft.value < 5)
const retriesWarn = computed(() => retriesLeft.value <= 1)

const lpProgress = computed(() => {
  const locked = lpPins.value.filter(p => p.locked).length
  return lpPins.value.length > 0 ? (locked / lpPins.value.length) * 100 : 0
})

const sdProgress = computed(() => {
  const s = sdSolved.value.filter(Boolean).length
  return sdTargets.value.length > 0 ? (s / sdTargets.value.length) * 100 : 0
})

const rcProgress = computed(() => {
  const h = rcHits.value.filter(Boolean).length
  return rcChainLength.value > 0 ? (h / rcChainLength.value) * 100 : 0
})

// ══════════════════════════════════════════════════════════════
//  START / STOP
// ══════════════════════════════════════════════════════════════

function startGame() {
  resolved.value = false
  resultVisible.value = false
  active.value = true

  const diff = store.difficulty

  switch (store.gameType) {
    case 'lockpick': startLockpick(diff); break
    case 'safedial': startSafeDial(diff); break
    case 'reactionchain': startReaction(diff); break
  }
}

function endGame(success: boolean) {
  active.value = false
  resolved.value = true
  resultSuccess.value = success
  resultVisible.value = true

  setTimeout(() => {
    store.closeMinigame()
    fetchNui('minigameResult', { success })
  }, 1400)
}

function flashContainer() {
  const el = document.querySelector('.mg-container') as HTMLElement
  if (!el) return
  el.style.outline = '2px solid #f87171'
  el.style.outlineOffset = '-2px'
  setTimeout(() => { el.style.outline = 'none' }, 350)
}

// ══════════════════════════════════════════════════════════════
//  LOCKPICK LOGIC
// ══════════════════════════════════════════════════════════════

function startLockpick(diff: Difficulty) {
  const cfg = LOCKPICK_CFG[diff]
  timeLeft.value = cfg.time
  retriesLeft.value = store.customRetries ?? cfg.retries
  maxRetries.value = retriesLeft.value
  lpCurrentPin.value = 0

  const shearY = CHANNEL_HEIGHT * 0.5
  const sweetHalf = cfg.sweetSpotPx / 2

  lpPins.value = Array.from({ length: cfg.pins }, () => {
    const travelMin = BOUNCE_MARGIN
    const travelMax = CHANNEL_HEIGHT - PIN_KEY_H - BOUNCE_MARGIN
    return {
      y: travelMin + Math.random() * (travelMax - travelMin),
      direction: Math.random() > 0.5 ? 1 : -1,
      speed: cfg.speed * (0.85 + Math.random() * 0.3),
      sweetTop: shearY - sweetHalf,
      sweetBottom: shearY + sweetHalf,
      locked: false,
      failed: false,
      travelMin,
      travelMax,
    }
  })
}

function lpAttempt() {
  if (!active.value || resolved.value) return
  const pin = lpPins.value[lpCurrentPin.value]
  if (!pin) return

  const center = pin.y + PIN_KEY_H / 2
  if (center >= pin.sweetTop && center <= pin.sweetBottom) {
    pin.locked = true
    pin.y = (pin.sweetTop + pin.sweetBottom) / 2 - PIN_KEY_H / 2
    lpCurrentPin.value++
    if (lpCurrentPin.value >= lpPins.value.length) endGame(true)
  } else {
    retriesLeft.value--
    if (retriesLeft.value <= 0) {
      pin.failed = true
      endGame(false)
    } else {
      lpResetPins()
    }
  }
}

function lpResetPins() {
  const cfg = LOCKPICK_CFG[store.difficulty]
  lpCurrentPin.value = 0
  lpPins.value.forEach(pin => {
    pin.locked = false
    pin.failed = false
    pin.y = pin.travelMin + Math.random() * (pin.travelMax - pin.travelMin)
    pin.direction = Math.random() > 0.5 ? 1 : -1
    pin.speed = cfg.speed * (0.85 + Math.random() * 0.3)
  })
  flashContainer()
}

// ══════════════════════════════════════════════════════════════
//  SAFEDIAL LOGIC
// ══════════════════════════════════════════════════════════════

function startSafeDial(diff: Difficulty) {
  const cfg = SAFEDIAL_CFG[diff]
  timeLeft.value = cfg.time
  retriesLeft.value = store.customRetries ?? cfg.retries
  maxRetries.value = retriesLeft.value
  sdDialAngle.value = 0
  sdCurrentNumber.value = 0
  sdCurrentCode.value = 0
  sdRotating.value = 0

  sdTargets.value = Array.from({ length: cfg.codes }, () => Math.floor(Math.random() * cfg.numbers))
  sdDirections.value = Array.from({ length: cfg.codes }, (_, i) => i % 2 === 0 ? -1 : 1)
  sdSolved.value = new Array(cfg.codes).fill(false)
}

function sdAttempt() {
  if (!active.value || resolved.value || sdCurrentCode.value >= sdTargets.value.length) return
  const cfg = SAFEDIAL_CFG[store.difficulty]
  const target = sdTargets.value[sdCurrentCode.value]

  let delta = Math.abs(sdCurrentNumber.value - target)
  if (delta > cfg.numbers / 2) delta = cfg.numbers - delta

  if (delta <= cfg.tolerance) {
    sdSolved.value[sdCurrentCode.value] = true
    sdCurrentCode.value++
    if (sdCurrentCode.value >= sdTargets.value.length) endGame(true)
  } else {
    retriesLeft.value--
    if (retriesLeft.value <= 0) {
      endGame(false)
    } else {
      sdReset()
    }
  }
}

function sdReset() {
  const cfg = SAFEDIAL_CFG[store.difficulty]
  sdCurrentCode.value = 0
  sdDialAngle.value = 0
  sdCurrentNumber.value = 0
  sdSolved.value = new Array(cfg.codes).fill(false)
  sdTargets.value = Array.from({ length: cfg.codes }, () => Math.floor(Math.random() * cfg.numbers))
  flashContainer()
}

function renderDial() {
  const canvas = dialCanvas.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  const cfg = SAFEDIAL_CFG[store.difficulty]
  const W = canvas.width
  const H = canvas.height
  const CX = W / 2
  const CY = H / 2

  ctx.clearRect(0, 0, W, H)

  const outerR = 280
  const innerR = 200

  // Outer ring
  ctx.beginPath()
  ctx.arc(CX, CY, outerR, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(20, 20, 20, 0.9)'
  ctx.fill()
  ctx.strokeStyle = 'rgba(255,255,255,0.08)'
  ctx.lineWidth = 1.5
  ctx.stroke()

  // Dial face
  const grad = ctx.createRadialGradient(CX, CY, innerR * 0.3, CX, CY, outerR)
  grad.addColorStop(0, 'rgba(30, 35, 48, 0.9)')
  grad.addColorStop(1, 'rgba(18, 22, 32, 0.95)')
  ctx.beginPath()
  ctx.arc(CX, CY, innerR + 45, 0, Math.PI * 2)
  ctx.fillStyle = grad
  ctx.fill()

  // Numbers and ticks
  const degreesPerNum = 360 / cfg.numbers
  const accentCSS = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#3b82f6'

  for (let i = 0; i < cfg.numbers; i++) {
    const angle = (i * degreesPerNum + sdDialAngle.value - 90) * Math.PI / 180
    const isMajor = i % 5 === 0

    const tStart = isMajor ? outerR - 11 : outerR - 7
    const tEnd = outerR - 2
    ctx.beginPath()
    ctx.moveTo(CX + Math.cos(angle) * tStart, CY + Math.sin(angle) * tStart)
    ctx.lineTo(CX + Math.cos(angle) * tEnd, CY + Math.sin(angle) * tEnd)
    ctx.strokeStyle = isMajor ? 'rgba(255,255,255,0.5)' : 'rgba(255,255,255,0.15)'
    ctx.lineWidth = isMajor ? 1.5 : 0.8
    ctx.stroke()

    if (isMajor) {
      const numR = outerR - 26
      const nx = CX + Math.cos(angle) * numR
      const ny = CY + Math.sin(angle) * numR
      const isTarget = !resolved.value && sdCurrentCode.value < sdTargets.value.length && i === sdTargets.value[sdCurrentCode.value]

      ctx.font = `${isTarget ? '700' : '500'} ${isTarget ? '18px' : '13px'} 'Segoe UI', sans-serif`
      ctx.fillStyle = isTarget ? accentCSS : 'rgba(255,255,255,0.45)'
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'

      if (isTarget) {
        ctx.shadowColor = accentCSS
        ctx.shadowBlur = 12
      }
      ctx.fillText(String(i), nx, ny)
      ctx.shadowBlur = 0
    }
  }

  // Inner circle
  ctx.beginPath()
  ctx.arc(CX, CY, innerR - 18, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(15, 18, 26, 0.95)'
  ctx.fill()
  ctx.strokeStyle = 'rgba(255,255,255,0.05)'
  ctx.lineWidth = 1
  ctx.stroke()

  // Current number
  ctx.font = "800 64px 'Segoe UI', sans-serif"
  ctx.fillStyle = 'rgba(255,255,255,0.85)'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText(String(sdCurrentNumber.value), CX, CY - 6)

  ctx.font = "500 10px 'Segoe UI', sans-serif"
  ctx.fillStyle = 'rgba(255,255,255,0.3)'
  ctx.fillText('AKTUELL', CX, CY + 36)

  // Grip lines
  for (let i = 0; i < 4; i++) {
    const a = (i * 90 + sdDialAngle.value) * Math.PI / 180
    ctx.beginPath()
    ctx.moveTo(CX + Math.cos(a) * (innerR - 12), CY + Math.sin(a) * (innerR - 12))
    ctx.lineTo(CX + Math.cos(a) * (innerR + 36), CY + Math.sin(a) * (innerR + 36))
    ctx.strokeStyle = 'rgba(255,255,255,0.04)'
    ctx.lineWidth = 10
    ctx.lineCap = 'round'
    ctx.stroke()
  }
}

// ══════════════════════════════════════════════════════════════
//  REACTION CHAIN LOGIC
// ══════════════════════════════════════════════════════════════

function startReaction(diff: Difficulty) {
  const cfg = REACTION_CFG[diff]
  timeLeft.value = cfg.time
  retriesLeft.value = store.customRetries ?? cfg.retries
  maxRetries.value = retriesLeft.value
  rcChainLength.value = cfg.chain
  rcCurrentStep.value = 0
  rcHits.value = new Array(cfg.chain).fill(false)
  rcLitKey.value = null
  rcWaitingForInput.value = false
  rcCooldown.value = false
  rcReactionWindow.value = cfg.reactionMs
  rcTimingPct.value = 0
  rcKeyCount.value = cfg.keys

  setTimeout(() => rcLightUp(), 800)
}

function rcLightUp() {
  if (!active.value || resolved.value || rcCurrentStep.value >= rcChainLength.value) return
  const cfg = REACTION_CFG[store.difficulty]

  let key: number
  do { key = Math.floor(Math.random() * cfg.keys) + 1 }
  while (key === rcLitKey.value && cfg.keys > 1)

  rcLitKey.value = key
  rcLitTime.value = performance.now()
  rcWaitingForInput.value = true
}

function rcAttempt(pressed: number) {
  if (!active.value || resolved.value || !rcWaitingForInput.value) return

  const currentLit = rcLitKey.value
  const elapsed = performance.now() - rcLitTime.value
  rcWaitingForInput.value = false
  rcLitKey.value = null

  if (pressed === currentLit && elapsed <= rcReactionWindow.value) {
    // Hit!
    rcFlashKey.value = pressed; rcFlashType.value = 'hit'
    setTimeout(() => { rcFlashKey.value = null; rcFlashType.value = null }, 250)

    rcHits.value[rcCurrentStep.value] = true
    rcCurrentStep.value++
    const cfg = REACTION_CFG[store.difficulty]
    rcReactionWindow.value = Math.max(300, rcReactionWindow.value - cfg.speedUp)

    if (rcCurrentStep.value >= rcChainLength.value) {
      endGame(true)
    } else {
      rcCooldown.value = true
      const delay = 300 + Math.random() * 500
      setTimeout(() => {
        rcCooldown.value = false
        rcLightUp()
      }, delay)
    }
  } else {
    // Miss
    rcFlashKey.value = pressed; rcFlashType.value = 'miss'
    setTimeout(() => { rcFlashKey.value = null; rcFlashType.value = null }, 350)

    retriesLeft.value--
    if (retriesLeft.value <= 0) {
      endGame(false)
    } else {
      rcResetChain()
    }
  }
}

function rcResetChain() {
  const cfg = REACTION_CFG[store.difficulty]
  rcCurrentStep.value = 0
  rcHits.value = new Array(rcChainLength.value).fill(false)
  rcReactionWindow.value = cfg.reactionMs
  rcLitKey.value = null
  rcWaitingForInput.value = false
  rcFlashKey.value = null
  rcFlashType.value = null
  flashContainer()
  setTimeout(() => rcLightUp(), 1000)
}

// ══════════════════════════════════════════════════════════════
//  GAME LOOP
// ══════════════════════════════════════════════════════════════

let animId = 0
let lastTime = 0

function loop(ts: number) {
  const dt = lastTime ? (ts - lastTime) / 1000 : 0
  lastTime = ts

  if (active.value && !resolved.value) {
    // Timer
    timeLeft.value -= dt
    if (timeLeft.value <= 0) {
      timeLeft.value = 0
      endGame(false)
      animId = requestAnimationFrame(loop)
      return
    }

    // Type-specific updates
    if (store.gameType === 'lockpick') {
      const cfg = LOCKPICK_CFG[store.difficulty]
      lpPins.value.forEach(pin => {
        if (pin.locked || pin.failed) return
        pin.y += pin.direction * pin.speed * 120 * dt
        if (pin.y <= pin.travelMin) { pin.y = pin.travelMin; pin.direction = 1 }
        if (pin.y >= pin.travelMax) { pin.y = pin.travelMax; pin.direction = -1 }
      })
    }

    if (store.gameType === 'safedial') {
      if (sdRotating.value !== 0) {
        const cfg = SAFEDIAL_CFG[store.difficulty]
        sdDialAngle.value = ((sdDialAngle.value + sdRotating.value * 120 * dt) % 360 + 360) % 360
        const dpn = 360 / cfg.numbers
        const norm = ((360 - sdDialAngle.value) % 360 + 360) % 360
        sdCurrentNumber.value = Math.round(norm / dpn) % cfg.numbers
      }
      renderDial()
    }

    if (store.gameType === 'reactionchain') {
      if (rcWaitingForInput.value && rcLitTime.value) {
        const elapsed = performance.now() - rcLitTime.value
        rcTimingPct.value = Math.min(100, (elapsed / rcReactionWindow.value) * 100)
        if (elapsed > rcReactionWindow.value) {
          rcWaitingForInput.value = false
          rcLitKey.value = null
          retriesLeft.value--
          if (retriesLeft.value <= 0) {
            endGame(false)
          } else {
            rcResetChain()
          }
        }
      } else {
        rcTimingPct.value = 0
      }
    }
  }

  animId = requestAnimationFrame(loop)
}

// ══════════════════════════════════════════════════════════════
//  INPUT
// ══════════════════════════════════════════════════════════════

function onKeyDown(e: KeyboardEvent) {
  if (!active.value || resolved.value) return

  if (store.gameType === 'lockpick') {
    if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); lpAttempt() }
    if (e.key === 'Escape') endGame(false)
  }

  if (store.gameType === 'safedial') {
    if (e.key === 'a' || e.key === 'A' || e.key === 'ArrowLeft') sdRotating.value = 1
    if (e.key === 'd' || e.key === 'D' || e.key === 'ArrowRight') sdRotating.value = -1
    if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); sdAttempt() }
    if (e.key === 'Escape') endGame(false)
  }

  if (store.gameType === 'reactionchain') {
    const k = parseInt(e.key)
    if (k >= 1 && k <= 4) rcAttempt(k)
    if (e.key === 'Escape') endGame(false)
  }
}

function onKeyUp(e: KeyboardEvent) {
  if (store.gameType === 'safedial') {
    if ((e.key === 'a' || e.key === 'A' || e.key === 'ArrowLeft') && sdRotating.value === 1) sdRotating.value = 0
    if ((e.key === 'd' || e.key === 'D' || e.key === 'ArrowRight') && sdRotating.value === -1) sdRotating.value = 0
  }
}

function onClickLockpick() {
  if (store.gameType === 'lockpick') lpAttempt()
}

function onClickReaction(key: number) {
  if (store.gameType === 'reactionchain') rcAttempt(key)
}

// ══════════════════════════════════════════════════════════════
//  LIFECYCLE
// ══════════════════════════════════════════════════════════════

watch(() => store.visible, (val) => {
  if (val) {
    nextTick(() => startGame())
  } else {
    active.value = false
    resolved.value = false
    resultVisible.value = false
  }
})

onMounted(() => {
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
  lastTime = 0
  animId = requestAnimationFrame(loop)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('keyup', onKeyUp)
  cancelAnimationFrame(animId)
})
</script>

<template>
  <Transition name="mg">
    <div v-if="store.visible" class="mg-overlay" @click.self="endGame(false)">
      <div class="mg-container">

        <!-- ── HEADER ── -->
        <div class="mg-header">
          <div class="mg-brand">
            <div class="mg-icon">
              <svg v-if="store.gameType === 'lockpick'" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              <svg v-if="store.gameType === 'safedial'" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg>
              <svg v-if="store.gameType === 'reactionchain'" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
            </div>
            <div>
              <div class="mg-title">{{ store.typeLabel.title }}</div>
              <div class="mg-subtitle">{{ store.typeLabel.subtitle }}</div>
            </div>
          </div>
          <div class="mg-stats">
            <div class="mg-stat">
              <div class="mg-stat-label">Versuche</div>
              <div class="mg-stat-value" :class="{ warn: retriesWarn }">{{ retriesLeft }}</div>
            </div>
            <div class="mg-stat">
              <div class="mg-stat-label">Zeit</div>
              <div class="mg-stat-value" :class="{ warn: timerWarn }">{{ timeLeft.toFixed(1) }}s</div>
            </div>
          </div>
        </div>

        <!-- ══════════ LOCKPICK ══════════ -->
        <div v-if="store.gameType === 'lockpick'" class="mg-body" @click="onClickLockpick">
          <div class="lp-area">
            <!-- Shear line -->
            <div class="lp-shear" :style="{ top: (CHANNEL_HEIGHT * 0.5) + 'px' }">
              <span class="lp-shear-label">Scherlinie</span>
            </div>
            <!-- Pins -->
            <div class="lp-pins">
              <div
                v-for="(pin, i) in lpPins"
                :key="i"
                class="lp-col"
                :class="{ active: i === lpCurrentPin && !pin.locked && !resolved, locked: pin.locked, failed: pin.failed }"
              >
                <div class="lp-channel">
                  <div class="lp-sweet" :style="{ top: pin.sweetTop + 'px', height: (pin.sweetBottom - pin.sweetTop) + 'px' }"></div>
                  <div class="lp-pin lp-driver" :style="{ top: (pin.y - 56) + 'px' }"></div>
                  <div class="lp-pin lp-key" :style="{ top: pin.y + 'px' }"></div>
                </div>
                <div class="lp-label">{{ i + 1 }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- ══════════ SAFEDIAL ══════════ -->
        <div v-if="store.gameType === 'safedial'" class="mg-body sd-body">
          <!-- Direction -->
          <div class="sd-direction" :class="{ left: sdDirections[sdCurrentCode] === -1, right: sdDirections[sdCurrentCode] === 1 }">
            {{ sdDirections[sdCurrentCode] === -1 ? '◄ LINKS DREHEN' : 'RECHTS DREHEN ►' }}
          </div>
          <!-- Canvas -->
          <div class="sd-canvas-wrap">
            <div class="sd-marker"></div>
            <canvas ref="dialCanvas" width="600" height="600" class="sd-canvas"></canvas>
          </div>
          <!-- Combo display -->
          <div class="sd-combo">
            <template v-for="(t, i) in sdTargets" :key="i">
              <span v-if="i > 0" class="sd-sep">·</span>
              <div class="sd-num" :class="{ active: i === sdCurrentCode && !resolved, solved: sdSolved[i] }">{{ t }}</div>
            </template>
          </div>
        </div>

        <!-- ══════════ REACTION CHAIN ══════════ -->
        <div v-if="store.gameType === 'reactionchain'" class="mg-body rc-body">
          <!-- Keys -->
          <div class="rc-grid">
            <div
              v-for="k in rcKeyCount"
              :key="k"
              class="rc-cell"
              :class="{ lit: rcLitKey === k, hit: rcFlashKey === k && rcFlashType === 'hit', miss: rcFlashKey === k && rcFlashType === 'miss' }"
              :style="{ '--cell-color': RC_COLORS[k - 1] }"
              @mousedown="onClickReaction(k)"
            >
              <div class="rc-letter">{{ k }}</div>
              <div class="rc-label">{{ RC_LABELS[k - 1] }}</div>
            </div>
          </div>
          <!-- Timing bar -->
          <div class="rc-timing-wrap">
            <span class="rc-timing-label">Reaktionszeit</span>
            <div class="rc-timing-track">
              <div class="rc-timing-fill" :style="{ width: rcTimingPct + '%' }"></div>
            </div>
          </div>
          <!-- Chain dots -->
          <div class="rc-chain">
            <div
              v-for="(h, i) in rcHits"
              :key="i"
              class="rc-dot"
              :class="{ hit: h, active: i === rcCurrentStep && !resolved }"
            ></div>
          </div>
        </div>

        <!-- ── FOOTER ── -->
        <div class="mg-footer">
          <div class="mg-progress-track">
            <div class="mg-progress-fill" :style="{
              width: (store.gameType === 'lockpick' ? lpProgress : store.gameType === 'safedial' ? sdProgress : rcProgress) + '%'
            }"></div>
          </div>
          <div class="mg-progress-label">
            <template v-if="store.gameType === 'lockpick'">{{ lpPins.filter(p => p.locked).length }} / {{ lpPins.length }} Pins</template>
            <template v-if="store.gameType === 'safedial'">{{ sdSolved.filter(Boolean).length }} / {{ sdTargets.length }} Codes</template>
            <template v-if="store.gameType === 'reactionchain'">{{ rcHits.filter(Boolean).length }} / {{ rcChainLength }} Treffer</template>
          </div>
        </div>

        <!-- ── RESULT OVERLAY ── -->
        <Transition name="result">
          <div v-if="resultVisible" class="mg-result" :class="{ success: resultSuccess, fail: !resultSuccess }">
            <div class="mg-result-content">
              <div class="mg-result-icon">{{ resultSuccess ? '🔓' : '🔒' }}</div>
              <div class="mg-result-text">{{ resultSuccess ? 'ERFOLG' : 'FEHLGESCHLAGEN' }}</div>
            </div>
          </div>
        </Transition>
      </div>

      <!-- Controls hint below card -->
      <div class="mg-controls">
        <template v-if="store.gameType === 'lockpick'">
          <span class="mg-ctrl"><kbd>SPACE</kbd> Pin fixieren</span>
          <span class="mg-ctrl-sep">·</span>
          <span class="mg-ctrl"><kbd>ESC</kbd> Abbrechen</span>
        </template>
        <template v-if="store.gameType === 'safedial'">
          <span class="mg-ctrl"><kbd>A</kbd> Links</span>
          <span class="mg-ctrl"><kbd>D</kbd> Rechts</span>
          <span class="mg-ctrl"><kbd>SPACE</kbd> Bestätigen</span>
        </template>
        <template v-if="store.gameType === 'reactionchain'">
          <span class="mg-ctrl"><kbd>1</kbd><kbd>2</kbd><kbd>3</kbd><kbd>4</kbd> Taste drücken wenn Feld aufleuchtet</span>
        </template>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* ══════════════════════════════════════════════════════════════
   SHARED LAYOUT
   ══════════════════════════════════════════════════════════════ */

.mg-overlay {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  z-index: 1200;
}

.mg-container {
  position: relative;
  width: 540px;
  background: rgba(15, 15, 15, 0.95);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
  overflow: hidden;
  outline: none;
  transition: outline 0.15s ease;
}

/* ── Header ── */
.mg-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.mg-brand { display: flex; align-items: center; gap: 10px; }

.mg-icon {
  width: 36px; height: 36px;
  display: flex; align-items: center; justify-content: center;
  background: rgba(var(--accent-rgb), 0.12);
  border-radius: 8px;
  color: var(--accent-color);
}

.mg-title {
  font-size: 0.85rem; font-weight: 600; color: #fff;
  letter-spacing: 1px;
}

.mg-subtitle {
  font-size: 0.7rem; color: rgba(255,255,255,0.35); margin-top: 1px;
}

.mg-stats { display: flex; gap: 18px; }

.mg-stat { text-align: right; }

.mg-stat-label {
  font-size: 0.6rem; font-weight: 500;
  letter-spacing: 1.5px; text-transform: uppercase;
  color: rgba(255,255,255,0.3);
}

.mg-stat-value {
  font-size: 1.1rem; font-weight: 700;
  color: var(--accent-color);
  font-variant-numeric: tabular-nums;
}

.mg-stat-value.warn {
  color: #f87171;
  animation: statPulse 0.6s ease-in-out infinite alternate;
}

@keyframes statPulse { to { opacity: 0.5; } }

/* ── Body ── */
.mg-body {
  padding: 20px;
  min-height: 200px;
}

/* ── Footer ── */
.mg-footer {
  display: flex; align-items: center;
  padding: 12px 20px;
  border-top: 1px solid rgba(255,255,255,0.06);
  background: rgba(0,0,0,0.25);
  gap: 16px;
}

.mg-progress-track {
  flex: 1; height: 3px;
  background: rgba(255,255,255,0.06);
  border-radius: 3px; overflow: hidden;
}

.mg-progress-fill {
  height: 100%;
  background: var(--accent-color);
  border-radius: 3px;
  transition: width 0.3s ease;
  box-shadow: 0 0 8px rgba(var(--accent-rgb), 0.4);
}

.mg-progress-label {
  font-size: 0.7rem; font-weight: 500;
  color: rgba(255,255,255,0.4);
  white-space: nowrap;
}

/* ── Controls hint ── */
.mg-controls {
  display: flex; align-items: center; gap: 16px;
}

.mg-ctrl {
  font-size: 0.7rem; color: rgba(255,255,255,0.3);
  display: flex; align-items: center; gap: 4px;
}

.mg-ctrl-sep { color: rgba(255,255,255,0.15); }

kbd {
  display: inline-flex; align-items: center; justify-content: center;
  min-width: 22px; height: 20px; padding: 0 5px;
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 4px;
  font-size: 0.65rem; font-weight: 600;
  color: rgba(255,255,255,0.5);
  font-family: inherit;
}

/* ── Result Overlay ── */
.mg-result {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  z-index: 10; border-radius: 12px;
  backdrop-filter: blur(4px);
}

.mg-result.success { background: rgba(74, 222, 128, 0.06); }
.mg-result.fail { background: rgba(248, 113, 113, 0.06); }

.mg-result-content { text-align: center; }
.mg-result-icon { font-size: 40px; margin-bottom: 8px; }

.mg-result-text {
  font-size: 1.2rem; font-weight: 700; letter-spacing: 4px;
}

.mg-result.success .mg-result-text { color: #4ade80; text-shadow: 0 0 20px rgba(74,222,128,0.5); }
.mg-result.fail .mg-result-text { color: #f87171; text-shadow: 0 0 20px rgba(248,113,113,0.5); }

/* ══════════════════════════════════════════════════════════════
   LOCKPICK
   ══════════════════════════════════════════════════════════════ */

.lp-area {
  position: relative;
  cursor: pointer;
}

.lp-shear {
  position: absolute;
  left: 0; right: 0;
  height: 1.5px;
  background: var(--accent-color);
  opacity: 0.4;
  z-index: 5;
  pointer-events: none;
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.3);
}

.lp-shear-label {
  position: absolute; right: 4px; top: -14px;
  font-size: 0.55rem; font-weight: 600;
  letter-spacing: 1.5px; text-transform: uppercase;
  color: var(--accent-color); opacity: 0.5;
}

.lp-pins {
  display: flex; justify-content: center; gap: 10px;
  height: 260px;
}

.lp-col {
  display: flex; flex-direction: column; align-items: center;
  width: 60px;
}

.lp-channel {
  width: 36px; height: 260px;
  background: rgba(0,0,0,0.35);
  border-radius: 6px;
  border: 1px solid rgba(255,255,255,0.04);
  position: relative; overflow: hidden;
}

.lp-sweet {
  position: absolute; left: 0; right: 0;
  background: rgba(74, 222, 128, 0.1);
  border-top: 1px dashed rgba(74,222,128,0.25);
  border-bottom: 1px dashed rgba(74,222,128,0.25);
  pointer-events: none;
}

.lp-pin {
  position: absolute; left: 50%; transform: translateX(-50%);
  width: 28px; border-radius: 4px;
  transition: background 0.1s ease;
}

.lp-driver {
  height: 56px;
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.06);
}

.lp-key {
  height: 48px;
  background: rgba(255,255,255,0.15);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 4px 4px 6px 6px;
}

.lp-label {
  font-size: 0.65rem; font-weight: 600;
  color: rgba(255,255,255,0.2);
  margin-top: 6px;
}

/* States */
.lp-col.active .lp-channel {
  border-color: rgba(var(--accent-rgb), 0.2);
  box-shadow: 0 0 16px rgba(var(--accent-rgb), 0.06);
}
.lp-col.active .lp-key {
  background: var(--accent-color);
  border-color: var(--accent-color);
  box-shadow: 0 0 10px rgba(var(--accent-rgb), 0.4);
}
.lp-col.active .lp-label { color: var(--accent-color); }

.lp-col.locked .lp-key {
  background: #4ade80;
  border-color: #4ade80;
  box-shadow: 0 0 10px rgba(74,222,128,0.4);
}
.lp-col.locked .lp-channel { border-color: rgba(74,222,128,0.12); }
.lp-col.locked .lp-label { color: #4ade80; }

.lp-col.failed .lp-key {
  background: #f87171;
  border-color: #f87171;
  box-shadow: 0 0 10px rgba(248,113,113,0.4);
}

/* ══════════════════════════════════════════════════════════════
   SAFEDIAL
   ══════════════════════════════════════════════════════════════ */

.sd-body {
  display: flex; flex-direction: column;
  align-items: center; gap: 16px;
}

.sd-direction {
  font-size: 0.75rem; font-weight: 600;
  letter-spacing: 2px; text-transform: uppercase;
  padding: 5px 14px; border-radius: 6px;
  background: rgba(var(--accent-rgb), 0.08);
  border: 1px solid rgba(var(--accent-rgb), 0.15);
  color: var(--accent-color);
  transition: all 0.2s ease;
  min-width: 150px; text-align: center;
}

.sd-direction.left { color: #60a5fa; border-color: rgba(96,165,250,0.15); background: rgba(96,165,250,0.06); }
.sd-direction.right { color: #c084fc; border-color: rgba(192,132,252,0.15); background: rgba(192,132,252,0.06); }

.sd-canvas-wrap {
  position: relative; width: 300px; height: 300px;
}

.sd-canvas {
  width: 300px; height: 300px;
  filter: drop-shadow(0 0 20px rgba(var(--accent-rgb), 0.08));
}

.sd-marker {
  position: absolute; top: -3px; left: 50%;
  transform: translateX(-50%);
  width: 0; height: 0;
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 14px solid var(--accent-color);
  filter: drop-shadow(0 0 6px rgba(var(--accent-rgb), 0.5));
  z-index: 5;
}

.sd-combo {
  display: flex; align-items: center; gap: 6px;
}

.sd-num {
  width: 40px; height: 40px;
  display: flex; align-items: center; justify-content: center;
  font-size: 1rem; font-weight: 700;
  border-radius: 8px;
  background: rgba(0,0,0,0.3);
  border: 1.5px solid rgba(255,255,255,0.06);
  color: rgba(255,255,255,0.25);
  transition: all 0.25s ease;
}

.sd-num.active {
  border-color: var(--accent-color);
  color: var(--accent-color);
  background: rgba(var(--accent-rgb), 0.06);
  box-shadow: 0 0 12px rgba(var(--accent-rgb), 0.12);
}

.sd-num.solved {
  border-color: #4ade80; color: #4ade80;
  background: rgba(74,222,128,0.06);
  box-shadow: 0 0 10px rgba(74,222,128,0.12);
}

.sd-sep { color: rgba(255,255,255,0.15); font-size: 1rem; }

/* ══════════════════════════════════════════════════════════════
   REACTION CHAIN
   ══════════════════════════════════════════════════════════════ */

.rc-body {
  display: flex; flex-direction: column;
  align-items: center; gap: 20px;
}

.rc-grid { display: flex; gap: 12px; }

.rc-cell {
  width: 100px; height: 110px;
  border-radius: 12px;
  background: rgba(0,0,0,0.3);
  border: 2px solid rgba(255,255,255,0.04);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 8px; cursor: pointer;
  transition: all 0.12s ease;
  position: relative; overflow: hidden;
}

.rc-letter {
  font-size: 1.6rem; font-weight: 700;
  color: rgba(255,255,255,0.15);
  transition: all 0.12s ease;
}

.rc-label {
  font-size: 0.55rem; font-weight: 500;
  letter-spacing: 1.5px; text-transform: uppercase;
  color: rgba(255,255,255,0.15);
  transition: all 0.12s ease;
}

.rc-cell.lit {
  border-color: var(--cell-color);
  box-shadow: 0 0 24px color-mix(in srgb, var(--cell-color) 35%, transparent),
              inset 0 0 24px color-mix(in srgb, var(--cell-color) 10%, transparent);
}

.rc-cell.lit .rc-letter {
  color: var(--cell-color);
  text-shadow: 0 0 16px var(--cell-color);
  transform: scale(1.1);
}

.rc-cell.lit .rc-label { color: var(--cell-color); opacity: 0.8; }

.rc-cell.hit {
  border-color: #4ade80;
  box-shadow: 0 0 24px rgba(74,222,128,0.35);
}
.rc-cell.hit .rc-letter { color: #4ade80; text-shadow: 0 0 16px rgba(74,222,128,0.5); }

.rc-cell.miss {
  border-color: #f87171;
  box-shadow: 0 0 24px rgba(248,113,113,0.35);
}
.rc-cell.miss .rc-letter { color: #f87171; text-shadow: 0 0 16px rgba(248,113,113,0.5); }

/* Timing bar */
.rc-timing-wrap {
  width: 100%; position: relative; height: 24px;
}

.rc-timing-label {
  position: absolute; right: 0; top: -2px;
  font-size: 0.55rem; font-weight: 600;
  letter-spacing: 1.5px; text-transform: uppercase;
  color: rgba(255,255,255,0.2);
}

.rc-timing-track {
  width: 100%; height: 5px;
  background: rgba(255,255,255,0.04);
  border-radius: 5px; overflow: hidden;
  position: absolute; top: 50%; transform: translateY(-50%);
}

.rc-timing-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent-color), #f87171);
  border-radius: 5px;
  transition: width 0.05s linear;
}

/* Chain dots */
.rc-chain {
  display: flex; gap: 4px; flex-wrap: wrap; justify-content: center;
}

.rc-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: rgba(255,255,255,0.1);
  transition: all 0.2s ease;
}

.rc-dot.hit {
  background: #4ade80;
  box-shadow: 0 0 6px rgba(74,222,128,0.4);
}

.rc-dot.active {
  background: var(--accent-color);
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.4);
  animation: dotPulse 0.8s ease-in-out infinite alternate;
}

@keyframes dotPulse { to { transform: scale(1.4); } }

/* ══════════════════════════════════════════════════════════════
   TRANSITIONS
   ══════════════════════════════════════════════════════════════ */

.mg-enter-active { transition: opacity 0.25s ease-out; }
.mg-leave-active { transition: opacity 0.2s ease-in; }
.mg-enter-from, .mg-leave-to { opacity: 0; }

.mg-enter-active .mg-container { transition: transform 0.25s ease-out, opacity 0.25s ease-out; }
.mg-leave-active .mg-container { transition: transform 0.2s ease-in, opacity 0.2s ease-in; }
.mg-enter-from .mg-container, .mg-leave-to .mg-container { transform: scale(0.92); opacity: 0; }

.result-enter-active { transition: opacity 0.2s ease-out; }
.result-enter-active .mg-result-content { animation: resultPop 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.result-leave-active { transition: opacity 0.15s ease-in; }
.result-enter-from, .result-leave-to { opacity: 0; }

@keyframes resultPop {
  from { opacity: 0; transform: scale(0.5) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
