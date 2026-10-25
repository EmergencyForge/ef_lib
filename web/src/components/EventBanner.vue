<script setup lang="ts">
import { ref } from 'vue'
import { useNuiEvent } from '@/composables/useNui'
import { resolveIconClass } from '@/composables/icons'

interface BannerData {
  title: string
  message?: string
  icon?: string
  stats?: Array<{ label: string; value: string | number }>
  duration?: number
}

// One at a time, the rest wait, so two promotions in a row are both seen
const queue: BannerData[] = []
const banner = ref<BannerData | null>(null)
const session = ref(0)
let busy = false

function next() {
  const data = queue.shift()
  busy = !!data
  if (!data) return
  const s = ++session.value
  banner.value = data
  setTimeout(() => {
    if (session.value !== s) return
    banner.value = null
    // Let the leave transition finish before the next one comes in
    setTimeout(() => { if (session.value === s) next() }, 450)
  }, data.duration || 5000)
}

useNuiEvent('showBanner', (data: BannerData) => {
  queue.push(data)
  if (!busy) next()
})
</script>

<template>
  <Transition name="bn">
    <div v-if="banner" :key="session" class="bn glass">
      <div class="bn-medal"><i :class="resolveIconClass(banner.icon || 'fa-medal')"></i></div>
      <div class="bn-title">{{ banner.title }}</div>
      <div v-if="banner.message" class="bn-message">{{ banner.message }}</div>
      <div v-if="banner.stats?.length" class="bn-stats">
        <span v-for="(s, i) in banner.stats" :key="i" :style="{ animationDelay: `${0.6 + i * 0.09}s` }">
          {{ s.label }} <b>{{ s.value }}</b>
        </span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.bn {
  position: fixed;
  top: 22vh;
  left: 50%;
  z-index: 950;
  width: 420px;
  margin-left: -210px;
  padding: 26px 24px 22px;
  border-radius: 22px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  pointer-events: none;
}

/* Light sweep once over the card */
.bn::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(105deg, transparent 35%, rgba(255, 255, 255, 0.14) 50%, transparent 65%);
  transform: translateX(-100%);
  animation: bn-sweep 1.2s ease 0.5s both;
}

.bn-medal {
  width: 58px;
  height: 58px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  font-size: 22px;
  color: var(--on-accent);
  background: var(--accent-color);
  background-image: linear-gradient(180deg, rgba(255, 255, 255, 0.3), rgba(255, 255, 255, 0) 70%);
  box-shadow: 0 0 0 6px rgba(var(--accent-rgb), 0.15), 0 0 30px rgba(var(--accent-rgb), 0.6), inset 0 1px 0 rgba(255, 255, 255, 0.45);
  animation: bn-pop 0.6s var(--spring) 0.2s both;
}

.bn-title {
  margin-top: 14px;
  font-size: 22px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text);
}

.bn-message {
  margin-top: 4px;
  font-size: 13.5px;
  color: var(--text-2);
}

.bn-stats {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin-top: 16px;
}

.bn-stats span {
  padding: 6px 12px;
  border-radius: 10px;
  background: var(--fill-2);
  box-shadow: var(--ctl-rim);
  font-size: 12.5px;
  color: var(--text-2);
  animation: bn-fade 0.5s ease both;
}

.bn-stats b {
  margin-left: 2px;
  color: var(--text);
  font-variant-numeric: tabular-nums;
}

@keyframes bn-sweep {
  to { transform: translateX(100%); }
}

@keyframes bn-pop {
  from { opacity: 0; transform: translateY(14px) scale(0.9); }
}

@keyframes bn-fade {
  from { opacity: 0; transform: translateY(6px); }
}

.bn-enter-active {
  transition: opacity 0.4s ease, transform 0.8s var(--spring), filter 0.5s ease;
}

.bn-leave-active {
  transition: opacity 0.4s var(--exit), transform 0.4s var(--exit);
}

.bn-enter-from {
  opacity: 0;
  transform: translateY(-20px) scale(0.92);
  filter: blur(10px);
}

.bn-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(0.98);
}
</style>
