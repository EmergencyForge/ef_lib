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
    <div v-if="banner" :key="session" class="bn panel">
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
  width: 360px;
  margin-left: -180px;
  padding: 20px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  pointer-events: none;
}

.bn-medal {
  width: 44px;
  height: 44px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  font-size: 18px;
  color: var(--on-accent);
  background: var(--accent-color);
  animation: bn-pop 0.6s var(--spring) 0.2s both;
}

.bn-title {
  margin-top: 12px;
  font-size: 18px;
  font-weight: 600;
  color: var(--text);
}

.bn-message {
  margin-top: 4px;
  font-size: 13px;
  color: var(--text-2);
}

.bn-stats {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 6px;
  margin-top: 14px;
}

.bn-stats span {
  padding: 4px 10px;
  border-radius: var(--radius-ctl);
  background: var(--surface-3);
  font-size: 12px;
  color: var(--text-2);
  animation: bn-fade 0.5s ease both;
}

.bn-stats b {
  margin-left: 2px;
  color: var(--text);
  font-variant-numeric: tabular-nums;
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
