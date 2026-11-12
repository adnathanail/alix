// What the row shows, read once per refresh. A figure the engine doesn't have
// yet (before the first response, or off a subscription) is absent.
export type Line = {
  repo: string
  branch?: string
  tokens?: number
  // Tokens at which the session compacts: the autoCompactWindow setting, else
  // the model's whole context window.
  compactAt: number
  costUsd?: number
  model: string
  quotaPercent?: number
  // Epoch milliseconds.
  quotaResetsAt?: number
}

// Lines added and removed by Edit and Write calls this session.
export type LinesChanged = { added: number; removed: number }

declare module 'claude-code' {
  interface PluginState {
    statusline: { line: Shaped<Line | null>; lines: Shaped<LinesChanged> }
  }
}
