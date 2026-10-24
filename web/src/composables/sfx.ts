// Minigame sounds synthesised with Web Audio, so the resource ships no audio files.

let ctx: AudioContext | null = null
let master: GainNode | null = null
let enabled = true

export function setSoundEnabled(on: boolean) {
  enabled = on
}

function audio(): AudioContext | null {
  if (!enabled) return null
  if (!ctx) {
    ctx = new AudioContext()
    master = ctx.createGain()
    master.gain.value = 0.6
    master.connect(ctx.destination)
  }
  if (ctx.state === 'suspended') ctx.resume()
  return ctx
}

interface ToneOpts { type?: OscillatorType; gain?: number; to?: number; delay?: number }

function tone(freq: number, dur: number, { type = 'sine', gain = 0.12, to, delay = 0 }: ToneOpts = {}) {
  const a = audio()
  if (!a || !master) return
  const t = a.currentTime + delay
  const osc = a.createOscillator()
  const g = a.createGain()
  osc.type = type
  osc.frequency.setValueAtTime(freq, t)
  if (to) osc.frequency.exponentialRampToValueAtTime(to, t + dur)
  g.gain.setValueAtTime(0, t)
  g.gain.linearRampToValueAtTime(gain, t + 0.005)
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur)
  osc.connect(g).connect(master)
  osc.start(t)
  osc.stop(t + dur + 0.02)
}

function noise(dur: number, { gain = 0.2, freq = 3000, delay = 0 } = {}) {
  const a = audio()
  if (!a || !master) return
  const t = a.currentTime + delay
  const buf = a.createBuffer(1, Math.ceil(a.sampleRate * dur), a.sampleRate)
  const data = buf.getChannelData(0)
  for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length)
  const src = a.createBufferSource()
  src.buffer = buf
  const bp = a.createBiquadFilter()
  bp.type = 'bandpass'
  bp.frequency.value = freq
  const g = a.createGain()
  g.gain.value = gain
  src.connect(bp).connect(g).connect(master)
  src.start(t)
}

export const sfx = {
  tick: () => tone(2600, 0.018, { type: 'square', gain: 0.025 }),
  click: () => { noise(0.035, { gain: 0.35, freq: 2800 }); tone(1150, 0.05, { type: 'triangle', gain: 0.1 }) },
  set: (step = 0) => {
    const f = 660 * Math.pow(2, step / 12)
    noise(0.03, { gain: 0.25, freq: 3500 })
    tone(f, 0.09, { type: 'triangle', gain: 0.11 })
    tone(f * 1.5, 0.12, { type: 'sine', gain: 0.06, delay: 0.04 })
  },
  slip: () => { tone(520, 0.28, { type: 'sawtooth', gain: 0.06, to: 110 }); noise(0.08, { gain: 0.2, freq: 1500 }) },
  miss: () => tone(190, 0.22, { type: 'square', gain: 0.05, to: 110 }),
  hit: (perfect = false) => tone(perfect ? 1320 : 990, 0.08, { type: 'triangle', gain: 0.11 }),
  spark: () => { noise(0.12, { gain: 0.35, freq: 5200 }); tone(1800, 0.06, { type: 'square', gain: 0.03, to: 900 }) },
  win: () => [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.16, { type: 'triangle', gain: 0.09, delay: i * 0.07 })),
  lose: () => [330, 262, 196].forEach((f, i) => tone(f, 0.2, { type: 'triangle', gain: 0.08, delay: i * 0.09 })),
}
