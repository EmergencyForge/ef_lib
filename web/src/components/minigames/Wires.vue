<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import type { WiresParams } from '@/minigames/params'
import { sfx } from '@/composables/sfx'

// Drag each wire from the left to the matching plug on the right. On the
// harder levels the right side shows symbols only.
const props = defineProps<{ params: WiresParams; active: boolean }>()
const emit = defineEmits<{ progress: [done: number, total: number]; miss: []; win: [] }>()

const WIRES = [
  { color: '#ef4444', icon: 'fa-bolt' },
  { color: '#f97316', icon: 'fa-fire' },
  { color: '#eab308', icon: 'fa-star' },
  { color: '#22c55e', icon: 'fa-leaf' },
  { color: '#06b6d4', icon: 'fa-droplet' },
  { color: '#3b82f6', icon: 'fa-snowflake' },
  { color: '#a855f7', icon: 'fa-moon' },
  { color: '#ec4899', icon: 'fa-heart' },
]

const W = 440
const ROW = 54
const PAD = 30
const LX = 46
const RX = W - 46

const count = computed(() => Math.min(Math.max(props.params.wires, 2), WIRES.length))
const height = computed(() => PAD * 2 + (count.value - 1) * ROW)
const left = computed(() => WIRES.slice(0, count.value).map((w, i) => ({ ...w, id: i, y: PAD + i * ROW })))
const order = ref<number[]>([])
const right = computed(() => order.value.map((id, i) => ({ ...WIRES[id], id, y: PAD + i * ROW })))

const connected = ref<Set<number>>(new Set())
const drag = ref<{ id: number; x: number; y: number } | null>(null)
const sparkAt = ref<{ x: number; y: number; bad: boolean; key: number } | null>(null)
const box = ref<HTMLElement | null>(null)

function shuffle() {
  const ids = left.value.map(w => w.id)
  do {
    for (let i = ids.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [ids[i], ids[j]] = [ids[j], ids[i]]
    }
  } while (ids.every((id, i) => id === i))
  order.value = ids
}

function path(x1: number, y1: number, x2: number, y2: number) {
  const dx = (x2 - x1) * 0.45
  return `M ${x1} ${y1} C ${x1 + dx} ${y1}, ${x2 - dx} ${y2}, ${x2} ${y2}`
}

function local(e: MouseEvent) {
  const r = box.value!.getBoundingClientRect()
  return { x: (e.clientX - r.left) * (W / r.width), y: (e.clientY - r.top) * (height.value / r.height) }
}

function startDrag(id: number, e: MouseEvent) {
  if (!props.active || connected.value.has(id)) return
  const p = local(e)
  drag.value = { id, x: p.x, y: p.y }
  sfx.tick()
}

function onMove(e: MouseEvent) {
  if (!drag.value) return
  const p = local(e)
  drag.value = { ...drag.value, x: p.x, y: p.y }
}

function onUp(e: MouseEvent) {
  const d = drag.value
  if (!d) return
  drag.value = null
  const p = local(e)
  // Generous drop area around each right plug
  const target = right.value.find(r => Math.abs(p.x - RX) < 50 && Math.abs(p.y - r.y) < ROW / 2)
  if (!target) return
  const key = Date.now()
  if (target.id === d.id && !connected.value.has(d.id)) {
    connected.value = new Set(connected.value).add(d.id)
    sparkAt.value = { x: RX, y: target.y, bad: false, key }
    sfx.spark()
    sfx.set(connected.value.size * 2)
    emit('progress', connected.value.size, count.value)
    if (connected.value.size >= count.value) emit('win')
  } else if (!connected.value.has(target.id)) {
    sparkAt.value = { x: RX, y: target.y, bad: true, key }
    sfx.spark()
    emit('miss')
  }
}

onMounted(() => {
  shuffle()
  emit('progress', 0, count.value)
  window.addEventListener('mousemove', onMove)
  window.addEventListener('mouseup', onUp)
})
onUnmounted(() => {
  window.removeEventListener('mousemove', onMove)
  window.removeEventListener('mouseup', onUp)
})
</script>

<template>
  <div ref="box" class="wires" :style="{ width: W + 'px', height: height + 'px' }">
    <svg :viewBox="`0 0 ${W} ${height}`" :width="W" :height="height">
      <path
        v-for="w in left.filter(x => connected.has(x.id))"
        :key="'c' + w.id"
        class="wire done"
        :d="path(LX, w.y, RX, right.find(r => r.id === w.id)!.y)"
        :style="{ stroke: w.color, color: w.color }"
      />
      <path
        v-if="drag"
        class="wire live"
        :d="path(LX, left[drag.id].y, drag.x, drag.y)"
        :style="{ stroke: left[drag.id].color }"
      />
    </svg>

    <div
      v-for="w in left"
      :key="'l' + w.id"
      class="plug left"
      :class="{ done: connected.has(w.id) }"
      :style="{ left: LX + 'px', top: w.y + 'px', '--c': w.color }"
      @mousedown.prevent="startDrag(w.id, $event)"
    >
      <i class="fa-solid" :class="w.icon"></i>
    </div>

    <div
      v-for="w in right"
      :key="'r' + w.id"
      class="plug right"
      :class="{ done: connected.has(w.id), plain: params.symbolsOnly && !connected.has(w.id) }"
      :style="{ left: RX + 'px', top: w.y + 'px', '--c': w.color }"
    >
      <i class="fa-solid" :class="w.icon"></i>
    </div>

    <div v-if="sparkAt" :key="sparkAt.key" class="spark" :class="{ bad: sparkAt.bad }" :style="{ left: sparkAt.x + 'px', top: sparkAt.y + 'px' }"></div>
  </div>
</template>

<style scoped>
.wires { position: relative; user-select: none; }

svg { position: absolute; inset: 0; overflow: visible; }

.wire {
  fill: none;
  stroke-width: 7;
  stroke-linecap: round;
}

.wire.done { filter: drop-shadow(0 0 6px currentColor); animation: snap 0.35s var(--ease); }
.wire.live { opacity: 0.85; stroke-dasharray: 2 12; stroke-width: 6; }

@keyframes snap { from { stroke-width: 11; } }

.plug {
  position: absolute;
  width: 40px;
  height: 40px;
  margin: -20px 0 0 -20px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  color: #111113;
  font-size: 15px;
  background: var(--c);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.45), inset 0 -2px 0 rgba(0, 0, 0, 0.2), 0 0 14px -2px var(--c);
  transition: transform 0.3s var(--spring), box-shadow 0.2s ease, background 0.2s ease, color 0.2s ease;
}

.plug.left { cursor: grab; }
.plug.left:hover:not(.done) { transform: scale(1.12); }
.plug.done { transform: scale(0.9); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.45), 0 0 18px var(--c); }

.plug.plain {
  color: var(--text);
  background: rgba(10, 10, 12, 0.6);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.18), inset 0 1px 0 rgba(255, 255, 255, 0.15);
}

.spark {
  position: absolute;
  width: 70px;
  height: 70px;
  margin: -35px 0 0 -35px;
  border-radius: 50%;
  pointer-events: none;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.95), rgba(255, 220, 140, 0.6) 25%, transparent 60%);
  animation: spark 0.4s ease-out forwards;
}

.spark.bad { background: radial-gradient(circle, rgba(255, 255, 255, 0.9), rgba(var(--danger-rgb), 0.7) 25%, transparent 60%); }

@keyframes spark {
  from { transform: scale(0.3); opacity: 1; }
  to { transform: scale(1.4); opacity: 0; }
}
</style>
