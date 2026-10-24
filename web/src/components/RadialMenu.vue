<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRadialStore } from '@/stores/radial'
import { useNuiEvent, fetchNui } from '@/composables/useNui'

const store = useRadialStore()
const wheelRef = ref<HTMLElement | null>(null)

// ─── Geometry ───
const VIEW = 500
const CENTER = VIEW / 2
const OUTER_R = 220
const INNER_R = 75
const LABEL_R = (OUTER_R + INNER_R) / 2

function resolveIconClass(icon: string): string {
  if (!icon) return ''
  if (/^fa-(solid|regular|brands|light|thin|duotone) /.test(icon)) return icon
  if (icon.startsWith('fa-')) return 'fa-solid ' + icon
  return 'fa-solid fa-' + icon
}

interface SliceGeom {
  index: number
  path: string
  labelX: number
  labelY: number
}

const slices = computed<SliceGeom[]>(() => {
  const n = store.items.length
  if (n === 0) return []

  // Single item → full ring as one slice (no path math edge-case)
  if (n === 1) {
    const path = `
      M ${CENTER + OUTER_R} ${CENTER}
      A ${OUTER_R} ${OUTER_R} 0 1 1 ${CENTER - OUTER_R} ${CENTER}
      A ${OUTER_R} ${OUTER_R} 0 1 1 ${CENTER + OUTER_R} ${CENTER}
      Z
      M ${CENTER + INNER_R} ${CENTER}
      A ${INNER_R} ${INNER_R} 0 1 0 ${CENTER - INNER_R} ${CENTER}
      A ${INNER_R} ${INNER_R} 0 1 0 ${CENTER + INNER_R} ${CENTER}
      Z
    `
    return [{ index: 0, path, labelX: CENTER, labelY: CENTER - LABEL_R }]
  }

  const sliceAngle = (Math.PI * 2) / n
  // Start at top, so slice 0 is centered on top
  const half = sliceAngle / 2

  return store.items.map((_, i) => {
    const startAngle = -Math.PI / 2 - half + i * sliceAngle
    const endAngle = startAngle + sliceAngle

    const x1 = CENTER + OUTER_R * Math.cos(startAngle)
    const y1 = CENTER + OUTER_R * Math.sin(startAngle)
    const x2 = CENTER + OUTER_R * Math.cos(endAngle)
    const y2 = CENTER + OUTER_R * Math.sin(endAngle)
    const x3 = CENTER + INNER_R * Math.cos(endAngle)
    const y3 = CENTER + INNER_R * Math.sin(endAngle)
    const x4 = CENTER + INNER_R * Math.cos(startAngle)
    const y4 = CENTER + INNER_R * Math.sin(startAngle)

    const largeArc = sliceAngle > Math.PI ? 1 : 0

    const path = `
      M ${x1} ${y1}
      A ${OUTER_R} ${OUTER_R} 0 ${largeArc} 1 ${x2} ${y2}
      L ${x3} ${y3}
      A ${INNER_R} ${INNER_R} 0 ${largeArc} 0 ${x4} ${y4}
      Z
    `

    const midAngle = startAngle + sliceAngle / 2
    const labelX = CENTER + LABEL_R * Math.cos(midAngle)
    const labelY = CENTER + LABEL_R * Math.sin(midAngle)

    return { index: i, path, labelX, labelY }
  })
})

// ─── Mouse-to-slice mapping ───
// Measure the actual wheel element so dead-zone size and center match the
// rendered SVG exactly (the CSS uses min(80vmin, 600px), not the full viewport).
interface WheelGeo { cx: number; cy: number; scale: number }

function getWheelGeometry(): WheelGeo | null {
  const el = wheelRef.value
  if (!el) return null
  const rect = el.getBoundingClientRect()
  const size = Math.min(rect.width, rect.height)
  if (size <= 0) return null
  return {
    cx: rect.left + rect.width / 2,
    cy: rect.top + rect.height / 2,
    scale: size / VIEW,
  }
}

function isInDeadZone(e: MouseEvent): boolean {
  const geo = getWheelGeometry()
  if (!geo) return false
  const dx = e.clientX - geo.cx
  const dy = e.clientY - geo.cy
  const dist = Math.sqrt(dx * dx + dy * dy)
  return dist < INNER_R * geo.scale
}

function onMouseMove(e: MouseEvent) {
  if (!store.visible) return
  const n = store.items.length
  if (n === 0) return

  const geo = getWheelGeometry()
  if (!geo) return

  const dx = e.clientX - geo.cx
  const dy = e.clientY - geo.cy
  const dist = Math.sqrt(dx * dx + dy * dy)

  if (dist < INNER_R * geo.scale) {
    store.setActive(null)
    return
  }

  // atan2: 0 = right, -PI/2 = up
  // Normalize so that "up" = 0, increasing clockwise
  let angle = Math.atan2(dy, dx) + Math.PI / 2
  if (angle < 0) angle += Math.PI * 2

  // First slice centered on top → shift by half slice
  const sliceAngle = (Math.PI * 2) / n
  const shifted = (angle + sliceAngle / 2) % (Math.PI * 2)
  const idx = Math.floor(shifted / sliceAngle) % n

  store.setActive(idx)
}

// ─── Click handler: drill into submenu / back / fire action ───
function onMouseDown(e: MouseEvent) {
  if (!store.visible || e.button !== 0) return

  // Click in center
  if (isInDeadZone(e)) {
    if (store.history.length > 0) {
      // Inside a submenu → go back one level
      store.drillBack()
    } else if (store.persistent) {
      // Top level + persistent mode → close explicitly
      fetchNui('radialResult', { id: null, closed: true })
      store.close()
    }
    e.preventDefault()
    e.stopPropagation()
    return
  }

  const idx = store.activeIndex
  if (idx === null) return
  const item = store.items[idx]

  e.preventDefault()
  e.stopPropagation()

  if (item.submenu && item.submenu.length > 0) {
    // Click on a slice with submenu → drill in
    store.drillInto(item.submenu)
  } else if (item.keepOpen) {
    // Trigger but keep the radial open (cursor mode)
    fetchNui('radialResult', { id: item.id, closed: false })
    store.setPersistent(true)
  } else {
    // Click on an end-item → fire action and close
    fetchNui('radialResult', { id: item.id, closed: true })
    store.close()
  }
}

// ─── ESC closes from persistent mode ───
function onKeyDown(e: KeyboardEvent) {
  if (!store.visible) return
  if (e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    fetchNui('radialResult', { id: null, closed: true })
    store.close()
  }
}

// ─── NUI bridge ───
useNuiEvent('openRadial', (data: { items: any[] }) => {
  store.open(data)
})

// Lua-triggered close (key released). Decide here whether to actually close
// or to enter persistent mode based on the active item's keepOpen flag.
useNuiEvent('closeRadial', () => {
  // Already in persistent mode? Ignore — only ESC / center-click closes.
  if (store.persistent) return

  const idx = store.activeIndex
  const selected = idx !== null ? store.items[idx] : null

  if (selected?.keepOpen) {
    // Enter persistent mode: fire the action, but stay open
    fetchNui('radialResult', { id: selected.id, closed: false })
    store.setPersistent(true)
    return
  }

  fetchNui('radialResult', { id: selected?.id ?? null, closed: true })
  store.close()
})

onMounted(() => {
  window.addEventListener('mousemove', onMouseMove)
  window.addEventListener('mousedown', onMouseDown, true)
  window.addEventListener('keydown', onKeyDown, true)
})

onUnmounted(() => {
  window.removeEventListener('mousemove', onMouseMove)
  window.removeEventListener('mousedown', onMouseDown, true)
  window.removeEventListener('keydown', onKeyDown, true)
})
</script>

<template>
  <Transition name="radial" :duration="{ enter: 600, leave: 160 }">
    <div v-if="store.visible" class="radial-overlay">
      <div class="radial-wheel" ref="wheelRef">
        <div class="radial-disc glass"></div>
        <svg class="radial-svg" :viewBox="`0 0 ${VIEW} ${VIEW}`" preserveAspectRatio="xMidYMid meet">
          <path
            v-for="slice in slices"
            :key="slice.index"
            :d="slice.path"
            class="slice"
            :class="{ active: store.activeIndex === slice.index }"
          />
        </svg>
        <div class="radial-hole"></div>

        <div class="radial-labels">
        <div
          v-for="slice in slices"
          :key="slice.index"
          class="label"
          :class="{ active: store.activeIndex === slice.index }"
          :style="{
            left: `${(slice.labelX / VIEW) * 100}%`,
            top:  `${(slice.labelY / VIEW) * 100}%`,
            '--i': slice.index,
          }"
        >
          <i v-if="store.items[slice.index].icon" :class="resolveIconClass(store.items[slice.index].icon!)"></i>
          <span class="label-text">{{ store.items[slice.index].label }}</span>
          <i v-if="store.items[slice.index].submenu?.length" class="submenu-indicator fa-solid fa-ellipsis"></i>
        </div>
        </div>

        <!-- Center: back arrow when inside a submenu -->
        <div v-if="store.history.length > 0" class="radial-center">
          <i class="fa-solid fa-angle-left"></i>
          <span class="center-text">Zurück</span>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.radial-overlay {
  position: fixed;
  inset: 0;
  z-index: 1200;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at center, rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.5));
  pointer-events: none;
}

.radial-wheel {
  position: relative;
  width: min(80vmin, 600px);
  height: min(80vmin, 600px);
}

/* Disc and hole follow OUTER_R / INNER_R of the SVG (220 and 75 of 500) */
.radial-disc {
  position: absolute;
  inset: 6%;
  border-radius: 50%;
}

.radial-hole {
  position: absolute;
  inset: 35%;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.28);
  box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.45), inset 0 0 0 1px rgba(255, 255, 255, 0.1), 0 1px 0 rgba(255, 255, 255, 0.08);
}

.radial-svg {
  position: relative;
  width: 100%;
  height: 100%;
  display: block;
}

.slice {
  fill: transparent;
  stroke: rgba(255, 255, 255, 0.06);
  stroke-width: 1;
  transition: fill 0.12s ease, stroke 0.12s ease;
}

.slice.active {
  fill: rgba(var(--accent-rgb), 0.32);
  stroke: rgba(var(--accent-rgb), 0.55);
}

.radial-labels {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.label {
  position: absolute;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  color: var(--text-2);
  transition: color 0.12s ease, transform 0.2s var(--ease);
  pointer-events: none;
}

.label i {
  font-size: clamp(18px, 3vmin, 24px);
  line-height: 1;
}

.label-text {
  font-size: clamp(11px, 1.5vmin, 14px);
  font-weight: 500;
  white-space: nowrap;
}

.label.active {
  color: var(--text);
  transform: translate(-50%, -50%) scale(1.08);
}

.label.active i {
  color: #ffffff;
}

.submenu-indicator {
  margin-top: 1px;
  font-size: clamp(8px, 1.1vmin, 10px);
  letter-spacing: 1px;
  color: var(--text-3);
}

.label.active .submenu-indicator {
  color: var(--text-2);
}

/* Center back-arrow (visible only inside submenus) */
.radial-center {
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: var(--text-2);
  pointer-events: none;
}

.radial-center i {
  font-size: clamp(16px, 2.4vmin, 22px);
  line-height: 1;
}

.center-text {
  font-size: clamp(10px, 1.3vmin, 12px);
  font-weight: 500;
}

/* ─── Transitions ─── */
.radial-enter-active {
  transition: opacity 0.2s ease;
}

.radial-leave-active {
  transition: opacity 0.16s var(--exit);
}

.radial-enter-active .radial-wheel {
  transition: transform 0.45s var(--spring), opacity 0.2s ease;
}

.radial-leave-active .radial-wheel {
  transition: transform 0.16s var(--exit), opacity 0.16s var(--exit);
}

/* Labels follow the wheel around, one slice after another */
.radial-enter-active .label {
  transition: opacity 0.3s ease, transform 0.45s var(--spring);
  transition-delay: calc(var(--i) * 25ms + 60ms);
}

.radial-enter-from .label {
  opacity: 0;
  transform: translate(-50%, -50%) scale(0.7);
}

.radial-enter-from,
.radial-leave-to {
  opacity: 0;
}

.radial-enter-from .radial-wheel {
  transform: scale(0.85) rotate(-6deg);
  opacity: 0;
}

.radial-leave-to .radial-wheel {
  transform: scale(0.95);
  opacity: 0;
}
</style>
