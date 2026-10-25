<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { locale, t } from '@/i18n'

// Dates travel as 'YYYY-MM-DD' strings, so they compare as text and need no time zone
const props = defineProps<{ modelValue: string; open: boolean; min?: string; max?: string; placeholder?: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string]; toggle: [] }>()

const pad = (n: number) => String(n).padStart(2, '0')
const iso = (y: number, m: number, d: number) => `${y}-${pad(m + 1)}-${pad(d)}`
const tag = computed(() => (locale.value === 'en' ? 'en-GB' : 'de-DE'))

const now = new Date()
const today = iso(now.getFullYear(), now.getMonth(), now.getDate())

function parse(value: string) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value || '')
  return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null
}

const view = ref({ y: now.getFullYear(), m: now.getMonth() })
watch(() => props.open, open => {
  const d = parse(props.modelValue) || parse(props.min || '') || now
  if (open) view.value = { y: d.getFullYear(), m: d.getMonth() }
}, { immediate: true })

function shift(by: number) {
  const d = new Date(view.value.y, view.value.m + by, 1)
  view.value = { y: d.getFullYear(), m: d.getMonth() }
}

const display = computed(() => {
  const d = parse(props.modelValue)
  return d ? new Intl.DateTimeFormat(tag.value, { day: '2-digit', month: '2-digit', year: 'numeric' }).format(d) : ''
})

const heading = computed(() => new Intl.DateTimeFormat(tag.value, { month: 'long', year: 'numeric' }).format(new Date(view.value.y, view.value.m, 1)))

// 1 Jan 2024 was a Monday
const weekdays = computed(() => {
  const f = new Intl.DateTimeFormat(tag.value, { weekday: 'short' })
  return Array.from({ length: 7 }, (_, i) => f.format(new Date(2024, 0, 1 + i)).replace('.', '').slice(0, 2))
})

const days = computed(() => {
  const { y, m } = view.value
  const lead = (new Date(y, m, 1).getDay() + 6) % 7
  const count = new Date(y, m + 1, 0).getDate()
  const cells: Array<{ day: number; value: string; outside: boolean }> = []
  for (let i = lead; i > 0; i--) {
    const d = new Date(y, m, 1 - i)
    cells.push({ day: d.getDate(), value: '', outside: true })
  }
  for (let d = 1; d <= count; d++) cells.push({ day: d, value: iso(y, m, d), outside: false })
  for (let d = 1; cells.length % 7; d++) cells.push({ day: d, value: '', outside: true })
  return cells
})

const allowed = (value: string) => (!props.min || value >= props.min) && (!props.max || value <= props.max)

function pick(value: string) {
  if (!value || !allowed(value)) return
  emit('update:modelValue', value)
  emit('toggle')
}
</script>

<template>
  <div class="dp">
    <button type="button" class="dp-field" :class="{ open }" @click="emit('toggle')">
      <i class="fa-regular fa-calendar dp-icon"></i>
      <span v-if="display">{{ display }}</span>
      <span v-else class="dp-placeholder">{{ placeholder || t('Datum wählen') }}</span>
      <i class="fa-solid fa-chevron-down dp-chevron"></i>
    </button>

    <Transition name="dp">
      <div v-if="open" class="dp-cal">
        <div class="dp-head">
          <span class="dp-month">{{ heading }}</span>
          <button type="button" class="dp-nav" @click="shift(-1)"><i class="fa-solid fa-chevron-left"></i></button>
          <button type="button" class="dp-nav" @click="shift(1)"><i class="fa-solid fa-chevron-right"></i></button>
        </div>
        <div class="dp-grid">
          <span v-for="w in weekdays" :key="w" class="dp-wd">{{ w }}</span>
          <button
            v-for="(c, i) in days"
            :key="i"
            type="button"
            class="dp-day"
            :class="{ outside: c.outside, on: c.value && c.value === modelValue, now: c.value === today }"
            :disabled="c.outside || !allowed(c.value)"
            @click="pick(c.value)"
          >{{ c.day }}</button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.dp-field {
  width: 100%;
  height: 40px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  border: none;
  border-radius: var(--radius-ctl);
  background: var(--well);
  box-shadow: var(--well-rim);
  color: var(--text);
  font: inherit;
  font-size: 14px;
  font-variant-numeric: tabular-nums;
  text-align: left;
  cursor: pointer;
  transition: box-shadow 0.15s ease;
}

.dp-field.open {
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.35), inset 0 0 0 1px var(--accent-color), 0 0 0 3px rgba(var(--accent-rgb), 0.2);
}

.dp-icon,
.dp-placeholder {
  color: var(--text-3);
}

.dp-chevron {
  margin-left: auto;
  font-size: 11px;
  color: var(--text-3);
  transition: transform 0.25s var(--ease);
}

.dp-field.open .dp-chevron {
  transform: rotate(180deg);
}

.dp-cal {
  margin-top: 8px;
  padding: 12px;
  border-radius: 14px;
  background: var(--fill-1);
  box-shadow: var(--ctl-rim);
  transform-origin: top left;
}

.dp-head {
  display: flex;
  align-items: center;
  gap: 2px;
  margin-bottom: 8px;
}

.dp-month {
  margin-right: auto;
  padding-left: 4px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text);
}

.dp-nav {
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 8px;
  background: none;
  color: var(--text-3);
  font-size: 11px;
  cursor: pointer;
}

.dp-nav:hover {
  background: var(--fill-2);
  color: var(--text);
}

.dp-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  text-align: center;
}

.dp-wd {
  height: 22px;
  font-size: 10.5px;
  line-height: 22px;
  color: var(--text-3);
}

.dp-day {
  height: 32px;
  border: none;
  border-radius: 8px;
  background: none;
  color: var(--text-2);
  font: inherit;
  font-size: 12.5px;
  font-variant-numeric: tabular-nums;
  cursor: pointer;
  transition: background 0.12s ease, color 0.12s ease;
}

.dp-day:hover:not(:disabled) {
  background: var(--fill-2);
  color: var(--text);
}

.dp-day:disabled {
  color: rgba(255, 255, 255, 0.2);
  cursor: default;
}

.dp-day.now {
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.3);
}

.dp-day.on {
  background: var(--accent-color);
  color: var(--on-accent);
  font-weight: 600;
  box-shadow: 0 0 12px rgba(var(--accent-rgb), 0.5);
}

.dp-enter-active {
  transition: opacity 0.2s ease, transform 0.4s var(--spring);
}

.dp-leave-active {
  transition: opacity 0.12s var(--exit), transform 0.12s var(--exit);
}

.dp-enter-from,
.dp-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.96);
}
</style>
