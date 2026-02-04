import { onMounted, onUnmounted } from 'vue'

export interface NuiMessage<T = unknown> {
  action: string
  data: T
}

type NuiHandler<T = unknown> = (data: T) => void

const handlers = new Map<string, Set<NuiHandler>>()

function handleMessage(event: MessageEvent<NuiMessage>) {
  const { action, data } = event.data

  if (!action) return

  const actionHandlers = handlers.get(action)
  if (actionHandlers) {
    actionHandlers.forEach(handler => handler(data))
  }
}

// Initialize global message listener
if (typeof window !== 'undefined') {
  window.addEventListener('message', handleMessage)
}

/**
 * Send a callback response to the FiveM client
 */
export async function fetchNui<T = unknown>(eventName: string, data?: unknown): Promise<T> {
  const resourceName = (window as any).GetParentResourceName?.() || 'ef_lib'

  const response = await fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data ?? {})
  })

  return response.json()
}

/**
 * Register a handler for NUI messages
 */
export function useNuiEvent<T = unknown>(action: string, handler: NuiHandler<T>) {
  onMounted(() => {
    if (!handlers.has(action)) {
      handlers.set(action, new Set())
    }
    handlers.get(action)!.add(handler as NuiHandler)
  })

  onUnmounted(() => {
    const actionHandlers = handlers.get(action)
    if (actionHandlers) {
      actionHandlers.delete(handler as NuiHandler)
      if (actionHandlers.size === 0) {
        handlers.delete(action)
      }
    }
  })
}

/**
 * Check if running inside FiveM NUI
 */
export function isInGame(): boolean {
  return typeof (window as any).GetParentResourceName === 'function'
}

/**
 * Debug helper - simulate NUI message in browser
 */
export function debugNuiMessage<T = unknown>(action: string, data: T) {
  window.dispatchEvent(new MessageEvent('message', {
    data: { action, data }
  }))
}
