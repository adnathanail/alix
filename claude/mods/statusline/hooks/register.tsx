import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Line, LinesChanged } from '../types'

// A coloured row above the prompt: repo | branch | context tokens | cost |
// lines added/removed | model | 5-hour quota.

const line = atom({ plugin: 'statusline', key: 'line' } as const, null, { shape: 'line-1' })
const lines = atom({ plugin: 'statusline', key: 'lines' } as const, { added: 0, removed: 0 }, { shape: 'lines-1' })

const COLOURS = {
  separator: '#5a5a5a',
  repo: '#e6c83c',
  branch: '#3cc8dc',
  cost: '#e6c83c',
  added: '#46c85a',
  removed: '#dc463c',
  model: '#c85ac8',
  quota: '#828282',
}

// Green at empty, yellow at half, red at the compaction point.
function contextColour(percent: number): string {
  const p = Math.min(Math.max(percent, 0), 100)
  const [from, to, f] =
    p <= 50
      ? [[0, 200, 80], [220, 200, 0], p / 50]
      : [[220, 200, 0], [220, 40, 20], (p - 50) / 50]
  const hex = from.map((c, i) => Math.round(c + ((to[i] ?? c) - c) * f).toString(16).padStart(2, '0'))

  return `#${hex.join('')}`
}

type Patch = readonly { lines: readonly string[] }[]

// Counts a diff's added and removed lines, as the status line's
// total_lines_added and total_lines_removed do.
function countPatch(patch: Patch): LinesChanged {
  let added = 0
  let removed = 0
  for (const hunk of patch) {
    for (const l of hunk.lines) {
      if (l.startsWith('+')) added += 1
      else if (l.startsWith('-')) removed += 1
    }
  }

  return { added, removed }
}

function basename(path: string): string {
  return path.replace(/\/+$/, '').split('/').pop() || path
}

async function measure($: EngineInterface): Promise<Line> {
  const [cwd, repo, model, usage, compactSetting] = await Promise.all([
    $.session.cwd(),
    $.session.repo(),
    $.session.model(),
    $.session.usage(),
    $.settings.read({ key: 'autoCompactWindow' }),
  ])

  const git = await $.process
    .run(['git', '--no-optional-locks', 'branch', '--show-current'], { cwd, timeoutMs: 2000 })
    .catch(() => undefined)
  const branch = git?.exitCode === 0 ? git.stdout.trim() || undefined : undefined

  const fiveHour = usage.rateLimits.find(r => r.kind === 'five_hour')

  return {
    repo: basename(repo?.root ?? cwd),
    branch,
    tokens: usage.context.tokens,
    compactAt: typeof compactSetting === 'number' ? compactSetting : usage.context.window,
    costUsd: usage.cost?.usd,
    model,
    quotaPercent: fiveHour?.percentUsed,
    quotaResetsAt: fiveHour?.resetsAt ? Date.parse(fiveHour.resetsAt) : undefined,
  }
}

async function refresh($: EngineInterface): Promise<void> {
  const next = await measure($)
  await update($, line, () => next)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await refresh($)

    return result
  })

  // New figures from a response (context, cost, quota).
  on('session.measure', async ($, e, next) => {
    const result = await next(e)
    await refresh($)

    return result
  })

  // Edits and writes: count the lines their diffs changed.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)

    if ((e.tool === 'Edit' || e.tool === 'Write') && 'result' in result && result.result && !result.isError) {
      const patch = (result.result as { structuredPatch?: Patch }).structuredPatch ?? []
      const counted = countPatch(patch)
      if (counted.added > 0 || counted.removed > 0) {
        await update($, lines, total => ({
          added: total.added + counted.added,
          removed: total.removed + counted.removed,
        }))
      }
    }

    return result
  })

  // A turn may have switched branch or model.
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($)

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const current = await read($, line)
    const changed = await read($, lines)

    if (e.props.hasSurvey || current === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const now = await $.clock.now()

    // Each part is one or more coloured pieces; parts are separated by " | ".
    type Piece = { text: string; colour: string; bold?: boolean }
    const parts: { key: string; pieces: Piece[] }[] = []
    const add = (key: string, ...pieces: Piece[]) => parts.push({ key, pieces })

    add('repo', { text: current.repo, colour: COLOURS.repo, bold: true })
    if (current.branch) {
      add('branch', { text: `(${current.branch})`, colour: COLOURS.branch, bold: true })
    }
    const tokens = current.tokens ?? 0
    const percent = current.compactAt > 0 ? (tokens / current.compactAt) * 100 : 0
    add('context', { text: `${(tokens / 1000).toFixed(1)}k tokens`, colour: contextColour(percent) })
    add('cost', { text: `$${(current.costUsd ?? 0).toFixed(2)}`, colour: COLOURS.cost })
    add(
      'lines',
      { text: `+${changed.added}`, colour: COLOURS.added },
      { text: ` -${changed.removed}`, colour: COLOURS.removed },
    )
    add('model', { text: current.model, colour: COLOURS.model })
    if (current.quotaPercent !== undefined) {
      const hours =
        current.quotaResetsAt !== undefined
          ? ` (${Math.max(0, (current.quotaResetsAt - now) / 3_600_000).toFixed(1)}h)`
          : ''
      add('quota', { text: `${Math.round(current.quotaPercent)}%${hours}`, colour: COLOURS.quota })
    }

    return (
      <Box>
        {parts.flatMap((part, i) => [
          ...(i > 0 ? [<Text key={`sep-${part.key}`} color={COLOURS.separator} dimColor>{' | '}</Text>] : []),
          ...part.pieces.map((piece, j) => (
            <Text key={`${part.key}-${j}`} color={piece.colour} bold={piece.bold}>
              {piece.text}
            </Text>
          )),
        ])}
      </Box>
    )
  })
}
