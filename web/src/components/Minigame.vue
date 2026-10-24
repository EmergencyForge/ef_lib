<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick, computed } from 'vue'
import { useMinigameStore, type Difficulty } from '@/stores/minigame'
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

// Only end-on-overlay-click when both mousedown and mouseup happen on the
// overlay itself, so a drag started inside the minigame doesn't fail it.
let overlayMouseDown = false

function onOverlayMouseDown(e: MouseEvent) {
  overlayMouseDown = e.target === e.currentTarget
}

function onOverlayClick(e: MouseEvent) {
  if (overlayMouseDown && e.target === e.currentTarget) endGame(false)
  overlayMouseDown = false
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
  ctx.fillStyle = 'rgba(16, 16, 18, 0.7)'
  ctx.fill()
  ctx.strokeStyle = 'rgba(255,255,255,0.14)'
  ctx.lineWidth = 1.5
  ctx.stroke()

  // Dial face
  // Light falls in from the top left, like the glass panels
  const grad = ctx.createRadialGradient(CX - 120, CY - 140, 20, CX, CY, outerR)
  grad.addColorStop(0, 'rgba(58, 58, 64, 0.85)')
  grad.addColorStop(1, 'rgba(20, 20, 23, 0.9)')
  ctx.beginPath()
  ctx.arc(CX, CY, innerR + 45, 0, Math.PI * 2)
  ctx.fillStyle = grad
  ctx.fill()

  // Numbers and ticks
  const degreesPerNum = 360 / cfg.numbers
  const accentCSS = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#f0500a'

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

      ctx.font = `${isTarget ? '700' : '500'} ${isTarget ? '18px' : '13px'} Geist, 'Segoe UI', sans-serif`
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
  ctx.fillStyle = 'rgba(10, 10, 12, 0.85)'
  ctx.fill()
  ctx.strokeStyle = 'rgba(255,255,255,0.1)'
  ctx.lineWidth = 1
  ctx.stroke()

  // Current number
  ctx.font = "700 64px Geist, 'Segoe UI', sans-serif"
  ctx.fillStyle = 'rgba(255,255,255,0.85)'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText(String(sdCurrentNumber.value), CX, CY - 6)

  ctx.font = "500 11px Geist, 'Segoe UI', sans-serif"
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
    <div v-if="store.visible" class="mg-overlay" @mousedown="onOverlayMouseDown" @click="onOverlayClick">
      <div class="mg-container glass">

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
            <i :class="sdDirections[sdCurrentCode] === -1 ? 'fa-solid fa-rotate-left' : 'fa-solid fa-rotate-right'"></i>
            {{ sdDirections[sdCurrentCode] === -1 ? 'Links drehen' : 'Rechts drehen' }}
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
              <div class="mg-result-icon"><i :class="resultSuccess ? 'fa-solid fa-lock-open' : 'fa-solid fa-lock'"></i></div>
              <div class="mg-result-text">{{ resultSuccess ? 'Geschafft' : 'Fehlgeschlagen' }}</div>
            </div>
          </div>
        </Transition>
      </div>

      <!-- Controls hint below card -->
      <div class="mg-controls">
        <template v-if="store.gameType === 'lockpick'">
          <span class="mg-ctrl"><kbd class="kbd">SPACE</kbd> Pin fixieren</span>
          <span class="mg-ctrl-sep">·</span>
          <span class="mg-ctrl"><kbd class="kbd">ESC</kbd> Abbrechen</span>
        </template>
        <template v-if="store.gameType === 'safedial'">
          <span class="mg-ctrl"><kbd class="kbd">A</kbd> Links</span>
          <span class="mg-ctrl"><kbd class="kbd">D</kbd> Rechts</span>
          <span class="mg-ctrl"><kbd class="kbd">SPACE</kbd> Bestätigen</span>
        </template>
        <template v-if="store.gameType === 'reactionchain'">
          <span class="mg-ctrl"><kbd class="kbd">1</kbd><kbd class="kbd">2</kbd><kbd class="kbd">3</kbd><kbd class="kbd">4</kbd> Taste drücken wenn Feld aufleuchtet</span>
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
  background: radial-gradient(circle at center, rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.55));
}

.mg-container {
  width: 540px;
  padding: 8px;
  overflow: hidden;
  outline: none;
  transition: outline 0.15s ease;
}

/* ── Header ── */
.mg-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 12px 14px;
}

.mg-brand { display: flex; align-items: center; gap: 12px; }

.mg-icon {
  width: 38px; height: 38px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 50%;
  background: rgba(var(--accent-rgb), 0.18);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.2);
  color: var(--accent-color);
}

.mg-title {
  font-size: 16px; font-weight: 600; color: var(--text);
  letter-spacing: -0.01em;
}

.mg-subtitle {
  font-size: 12px; color: var(--text-3); margin-top: 1px;
}

.mg-stats { display: flex; gap: 8px; }

.mg-stat {
  min-width: 72px;
  padding: 6px 12px;
  border-radius: var(--radius-ctl);
  background: var(--well);
  box-shadow: var(--well-rim);
  text-align: right;
}

.mg-stat-label {
  font-size: 11px;
  color: var(--text-3);
}

.mg-stat-value {
  font-size: 17px; font-weight: 600;
  color: var(--text);
  font-variant-numeric: tabular-nums;
}

.mg-stat-value.warn {
  color: var(--danger);
  animation: statPulse 0.6s ease-in-out infinite alternate;
}

@keyframes statPulse { to { opacity: 0.5; } }

/* ── Body ── */
.mg-body {
  margin: 0 4px;
  padding: 20px;
  min-height: 200px;
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.2);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.05);
}

/* ── Footer ── */
.mg-footer {
  display: flex; align-items: center;
  padding: 14px 12px 6px;
  gap: 16px;
}

.mg-progress-track {
  flex: 1; height: 6px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
  overflow: hidden;
}

.mg-progress-fill {
  height: 100%;
  border-radius: inherit;
  background: var(--accent-color);
  background-image: linear-gradient(180deg, rgba(255, 255, 255, 0.35), rgba(255, 255, 255, 0) 60%);
  box-shadow: 0 0 8px rgba(var(--accent-rgb), 0.5);
  transition: width 0.3s var(--ease);
}

.mg-progress-label {
  font-size: 12px; font-weight: 500;
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

.mg-ctrl-sep { color: var(--text-3); }

/* ── Result Overlay ── */
.mg-result {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  z-index: 10;
  border-radius: inherit;
  /* Blurs the card itself, which is inside the NUI page and therefore works */
  backdrop-filter: blur(8px);
}

.mg-result.success { background: rgba(10, 30, 16, 0.55); }
.mg-result.fail { background: rgba(36, 12, 12, 0.55); }

.mg-result-content { text-align: center; }

.mg-result-icon {
  width: 64px; height: 64px;
  margin: 0 auto 12px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 50%;
  font-size: 26px;
}

.mg-result.success .mg-result-icon {
  color: var(--ok);
  background: rgba(var(--ok-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--ok-rgb), 0.4), 0 0 32px rgba(var(--ok-rgb), 0.25);
}

.mg-result.fail .mg-result-icon {
  color: var(--danger);
  background: rgba(var(--danger-rgb), 0.16);
  box-shadow: inset 0 0 0 1px rgba(var(--danger-rgb), 0.4), 0 0 32px rgba(var(--danger-rgb), 0.25);
}

.mg-result-text {
  font-size: 20px; font-weight: 600; letter-spacing: -0.01em;
}

.mg-result.success .mg-result-text { color: var(--ok); }
.mg-result.fail .mg-result-text { color: var(--danger); }

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
  opacity: 0.5;
  z-index: 5;
  pointer-events: none;
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.4);
}

.lp-shear-label {
  position: absolute; right: 4px; top: -16px;
  font-size: 11px; font-weight: 500;
  color: var(--accent-color); opacity: 0.8;
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
  border-radius: var(--radius-pill);
  background: rgba(0, 0, 0, 0.35);
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.4), inset 0 0 0 1px rgba(255, 255, 255, 0.05);
  position: relative; overflow: hidden;
  transition: box-shadow 0.15s ease;
}

.lp-sweet {
  position: absolute; left: 0; right: 0;
  background: rgba(var(--ok-rgb), 0.12);
  border-top: 1px dashed rgba(var(--ok-rgb), 0.35);
  border-bottom: 1px dashed rgba(var(--ok-rgb), 0.35);
  pointer-events: none;
}

.lp-pin {
  position: absolute; left: 50%; transform: translateX(-50%);
  width: 26px;
  border-radius: 13px;
  transition: background 0.1s ease;
}

.lp-driver {
  height: 56px;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.15);
}

.lp-key {
  height: 48px;
  background: rgba(255, 255, 255, 0.22);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.35);
}

.lp-label {
  font-size: 12px; font-weight: 500;
  color: var(--text-3);
  margin-top: 8px;
}

/* States */
.lp-col.active .lp-channel {
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.4), inset 0 0 0 1px rgba(var(--accent-rgb), 0.5), 0 0 16px rgba(var(--accent-rgb), 0.15);
}
.lp-col.active .lp-key {
  background: var(--accent-color);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 0 10px rgba(var(--accent-rgb), 0.5);
}
.lp-col.active .lp-label { color: var(--accent-color); }

.lp-col.locked .lp-key {
  background: var(--ok);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 0 10px rgba(var(--ok-rgb), 0.4);
}
.lp-col.locked .lp-channel { box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.4), inset 0 0 0 1px rgba(var(--ok-rgb), 0.3); }
.lp-col.locked .lp-label { color: var(--ok); }

.lp-col.failed .lp-key {
  background: var(--danger);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4), 0 0 10px rgba(var(--danger-rgb), 0.4);
}

/* ══════════════════════════════════════════════════════════════
   SAFEDIAL
   ══════════════════════════════════════════════════════════════ */

.sd-body {
  display: flex; flex-direction: column;
  align-items: center; gap: 16px;
}

.sd-direction {
  display: flex; align-items: center; justify-content: center; gap: 8px;
  min-width: 160px;
  padding: 6px 16px;
  border-radius: var(--radius-pill);
  background: rgba(var(--accent-rgb), 0.14);
  box-shadow: inset 0 0 0 1px rgba(var(--accent-rgb), 0.35);
  color: var(--accent-color);
  font-size: 13px; font-weight: 500;
  transition: background 0.2s ease, color 0.2s ease, box-shadow 0.2s ease;
}

.sd-direction.left { color: var(--info); background: rgba(var(--info-rgb), 0.14); box-shadow: inset 0 0 0 1px rgba(var(--info-rgb), 0.35); }
.sd-direction.right { color: #c084fc; background: rgba(192, 132, 252, 0.14); box-shadow: inset 0 0 0 1px rgba(192, 132, 252, 0.35); }

.sd-canvas-wrap {
  position: relative; width: 300px; height: 300px;
}

.sd-canvas {
  width: 300px; height: 300px;
  filter: drop-shadow(0 8px 24px rgba(0, 0, 0, 0.45));
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
  width: 42px; height: 42px;
  display: flex; align-items: center; justify-content: center;
  font-size: 16px; font-weight: 600;
  font-variant-numeric: tabular-nums;
  border-radius: var(--radius-ctl);
  background: var(--well);
  box-shadow: var(--well-rim);
  color: var(--text-3);
  transition: background 0.25s ease, color 0.25s ease, box-shadow 0.25s ease;
}

.sd-num.active {
  color: var(--text);
  background: rgba(var(--accent-rgb), 0.2);
  box-shadow: inset 0 0 0 1px var(--accent-color), 0 0 12px rgba(var(--accent-rgb), 0.25);
}

.sd-num.solved {
  color: var(--ok);
  background: rgba(var(--ok-rgb), 0.12);
  box-shadow: inset 0 0 0 1px rgba(var(--ok-rgb), 0.5);
}

.sd-sep { color: var(--text-3); font-size: 16px; }

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
  border-radius: 14px;
  background: var(--fill-1);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08), inset 0 0 0 1px rgba(255, 255, 255, 0.05);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 8px; cursor: pointer;
  transition: box-shadow 0.12s ease, background 0.12s ease;
  position: relative; overflow: hidden;
}

.rc-letter {
  font-size: 26px; font-weight: 600;
  color: var(--text-3);
  transition: color 0.12s ease, transform 0.12s ease;
}

.rc-label {
  font-size: 11px; font-weight: 500;
  color: var(--text-3);
  transition: color 0.12s ease;
}

/* currentColor instead of color-mix(), which Chromium 103 lacks */
.rc-cell.lit {
  color: var(--cell-color);
  background: rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 0 0 2px currentColor, inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 0 24px -6px currentColor;
}

.rc-cell.lit .rc-letter {
  color: var(--cell-color);
  transform: scale(1.1);
}

.rc-cell.lit .rc-label { color: var(--cell-color); }

.rc-cell.hit {
  background: rgba(var(--ok-rgb), 0.1);
  box-shadow: inset 0 0 0 2px var(--ok), 0 0 24px rgba(var(--ok-rgb), 0.3);
}
.rc-cell.hit .rc-letter { color: var(--ok); }

.rc-cell.miss {
  background: rgba(var(--danger-rgb), 0.1);
  box-shadow: inset 0 0 0 2px var(--danger), 0 0 24px rgba(var(--danger-rgb), 0.3);
}
.rc-cell.miss .rc-letter { color: var(--danger); }

/* Timing bar */
.rc-timing-wrap {
  width: 100%; position: relative; height: 26px;
}

.rc-timing-label {
  position: absolute; right: 0; top: -4px;
  font-size: 11px; font-weight: 500;
  color: var(--text-3);
}

.rc-timing-track {
  width: 100%; height: 6px;
  border-radius: var(--radius-pill);
  background: var(--well);
  box-shadow: var(--well-rim);
  overflow: hidden;
  position: absolute; bottom: 0;
}

.rc-timing-fill {
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, var(--accent-color), var(--danger));
  transition: width 0.05s linear;
}

/* Chain dots */
.rc-chain {
  display: flex; gap: 5px; flex-wrap: wrap; justify-content: center;
}

.rc-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: var(--fill-3);
  transition: background 0.2s ease, box-shadow 0.2s ease;
}

.rc-dot.hit {
  background: var(--ok);
  box-shadow: 0 0 6px rgba(var(--ok-rgb), 0.5);
}

.rc-dot.active {
  background: var(--accent-color);
  box-shadow: 0 0 6px rgba(var(--accent-rgb), 0.5);
  animation: dotPulse 0.8s ease-in-out infinite alternate;
}

@keyframes dotPulse { to { transform: scale(1.4); } }

/* ══════════════════════════════════════════════════════════════
   TRANSITIONS
   ══════════════════════════════════════════════════════════════ */

.mg-enter-active { transition: opacity 0.25s ease-out; }
.mg-leave-active { transition: opacity 0.2s ease-in; }
.mg-enter-from, .mg-leave-to { opacity: 0; }

.mg-enter-active .mg-container { transition: transform 0.3s var(--ease), opacity 0.25s ease-out; }
.mg-leave-active .mg-container { transition: transform 0.2s ease-in, opacity 0.2s ease-in; }
.mg-enter-from .mg-container, .mg-leave-to .mg-container { transform: scale(0.94); opacity: 0; }

.result-enter-active { transition: opacity 0.2s ease-out; }
.result-enter-active .mg-result-content { animation: resultPop 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.result-leave-active { transition: opacity 0.15s ease-in; }
.result-enter-from, .result-leave-to { opacity: 0; }

@keyframes resultPop {
  from { opacity: 0; transform: scale(0.5) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
