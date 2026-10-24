export type MinigameType = 'lockpick' | 'safedial' | 'reactionchain' | 'wires'
export type Difficulty = 'easy' | 'medium' | 'hard' | 'extreme'

interface Common {
  time: number
  retries: number
  sound: boolean
}

export interface LockpickParams extends Common {
  pins: number
  zone: number      // height of the sweet zone in px
  speed: number
  tension: number   // width of the right tension band, 0..1
}

export interface SafeDialParams extends Common {
  codes: number
  tolerance: number // ± numbers that still count
  numbers: number
  code?: number[]   // known combination, e.g. from a note the player found
}

export interface ReactionParams extends Common {
  notes: number     // hits needed
  approach: number  // ms the ring needs to close
  window: number    // ± ms around the hit that count
  interval: number  // ms between rings
  keys: string[]
}

export interface WiresParams extends Common {
  wires: number
  symbolsOnly: boolean // right side without colours, match by symbol
}

export type Params = LockpickParams | SafeDialParams | ReactionParams | WiresParams

type Table<P> = Record<Difficulty, Omit<P, 'sound'>>

const LOCKPICK: Table<LockpickParams> = {
  easy:    { pins: 3, zone: 56, speed: 1.3, tension: 0.34, time: 40, retries: 4 },
  medium:  { pins: 5, zone: 42, speed: 1.8, tension: 0.26, time: 35, retries: 3 },
  hard:    { pins: 6, zone: 32, speed: 2.4, tension: 0.2,  time: 30, retries: 2 },
  extreme: { pins: 7, zone: 24, speed: 3.0, tension: 0.15, time: 25, retries: 1 },
}

const SAFEDIAL: Table<SafeDialParams> = {
  easy:    { codes: 2, tolerance: 1, numbers: 20, time: 45, retries: 4 },
  medium:  { codes: 3, tolerance: 1, numbers: 30, time: 45, retries: 3 },
  hard:    { codes: 3, tolerance: 0, numbers: 40, time: 40, retries: 2 },
  extreme: { codes: 4, tolerance: 0, numbers: 50, time: 40, retries: 1 },
}

const REACTION: Table<ReactionParams> = {
  easy:    { notes: 8,  approach: 1400, window: 220, interval: 900, keys: ['1', '2', '3'], time: 40, retries: 4 },
  medium:  { notes: 12, approach: 1150, window: 180, interval: 700, keys: ['1', '2', '3', '4'], time: 35, retries: 3 },
  hard:    { notes: 16, approach: 950,  window: 150, interval: 520, keys: ['1', '2', '3', '4'], time: 30, retries: 2 },
  extreme: { notes: 20, approach: 800,  window: 120, interval: 420, keys: ['1', '2', '3', '4'], time: 28, retries: 1 },
}

const WIRES: Table<WiresParams> = {
  easy:    { wires: 4, symbolsOnly: false, time: 30, retries: 4 },
  medium:  { wires: 5, symbolsOnly: false, time: 25, retries: 3 },
  hard:    { wires: 6, symbolsOnly: true,  time: 25, retries: 2 },
  extreme: { wires: 8, symbolsOnly: true,  time: 25, retries: 1 },
}

const DEFAULTS: Record<MinigameType, Table<Params>> = {
  lockpick: LOCKPICK, safedial: SAFEDIAL, reactionchain: REACTION, wires: WIRES,
}

export const TYPES = Object.keys(DEFAULTS) as MinigameType[]

/**
 * Difficulty table plus whatever the calling script overrides. Only keys the
 * table knows are taken, with the same type, so a typo in Lua cannot break a game.
 */
export function resolveParams(type: MinigameType, difficulty: Difficulty, overrides: Record<string, unknown> = {}): Params {
  const base = { ...DEFAULTS[type][difficulty] ?? DEFAULTS[type].medium, sound: true } as Record<string, unknown>
  for (const [key, value] of Object.entries(overrides)) {
    if (!(key in base)) continue
    if (Array.isArray(base[key]) ? Array.isArray(value) && value.length > 0 : typeof value === typeof base[key]) base[key] = value
  }
  if (type === 'safedial' && Array.isArray(overrides.code)) {
    base.code = overrides.code.map(Number).filter(n => Number.isFinite(n))
    base.codes = (base.code as number[]).length || base.codes
  }
  if (type === 'reactionchain') {
    base.keys = (base.keys as unknown[]).slice(0, 6).map(k => String(k).toUpperCase())
  }
  base.time = Math.max(3, Number(base.time))
  base.retries = Math.max(1, Math.round(Number(base.retries)))
  return base as unknown as Params
}
