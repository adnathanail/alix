import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Line } from '../types'

// A coloured row under the prompt, above the engine's hint line: repo | branch | context tokens | cost |
// lines added/removed | model | 5-hour quota.

const line = atom({ plugin: 'statusline', key: 'line' } as const, null, { shape: 'line-2' })

// Untracked files counted at most; past this the count covers the first ones.
const MAX_UNTRACKED = 500

// When the row is wider than the terminal, these parts are dropped in this
// order until it fits. If it still doesn't, the remaining parts wrap onto
// further lines, each part kept whole.
const DROP_ORDER = ['cost', 'model', 'lines']

const SEPARATOR = ' | '

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

// Uncommitted lines in the repository holding `cwd`, or undefined outside
// one (or before its first commit, when there is no HEAD to diff against).
async function gitLines($: EngineInterface, cwd: string): Promise<{ added: number; removed: number } | undefined> {
  const git = (args: string[], dir: string) =>
    $.process.run(['git', '--no-optional-locks', ...args], { cwd: dir, timeoutMs: 5000 }).catch(() => undefined)

  const top = await git(['rev-parse', '--show-toplevel'], cwd)
  if (top?.exitCode !== 0) return undefined
  const root = top.stdout.trim()

  // Tracked changes, staged or not. Binary files read "-\t-" and count as 0.
  const diff = await git(['diff', '--numstat', 'HEAD'], root)
  if (diff?.exitCode !== 0) return undefined
  let added = 0
  let removed = 0
  for (const row of diff.stdout.split('\n')) {
    const [plus, minus] = row.split('\t')
    added += Number(plus) || 0
    removed += Number(minus) || 0
  }

  // Untracked files are all additions; git diff leaves them out.
  const others = await git(['ls-files', '--others', '--exclude-standard', '-z'], root)
  const files = others?.exitCode === 0 ? others.stdout.split('\0').filter(Boolean).slice(0, MAX_UNTRACKED) : []
  if (files.length > 0) {
    const wc = await $.process.run(['wc', '-l', '--', ...files], { cwd: root, timeoutMs: 5000 }).catch(() => undefined)
    // wc prints one row per file, then a total row when given several.
    const rows = (wc?.stdout ?? '').trim().split('\n')
    const total = files.length > 1 ? rows[rows.length - 1] : rows[0]
    added += Number(total?.trim().split(/\s+/)[0]) || 0
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
  const lines = await gitLines($, cwd)

  return {
    repo: basename(repo?.root ?? cwd),
    branch,
    tokens: usage.context.tokens,
    compactAt: typeof compactSetting === 'number' ? compactSetting : usage.context.window,
    costUsd: usage.cost?.usd,
    model,
    quotaPercent: fiveHour?.percentUsed,
    quotaResetsAt: fiveHour?.resetsAt ? Date.parse(fiveHour.resetsAt) : undefined,
    added: lines?.added,
    removed: lines?.removed,
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

  // Tools that can change files: re-read the line counts and branch.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)

    if (['Edit', 'Write', 'NotebookEdit', 'Bash'].includes(String(e.tool))) {
      await refresh($)
    }

    return result
  })

  // A turn may have switched branch or model.
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($)

    return result
  })

  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const current = await read($, line)

    if (current === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const now = await $.clock.now()

    // Each part is one or more coloured pieces; parts are separated by " | ".
    type Piece = { text: string; colour: string; bold?: boolean }
    let parts: { key: string; pieces: Piece[] }[] = []
    const add = (key: string, ...pieces: Piece[]) => parts.push({ key, pieces })

    add('repo', { text: current.repo, colour: COLOURS.repo, bold: true })
    if (current.branch) {
      add('branch', { text: `(${current.branch})`, colour: COLOURS.branch, bold: true })
    }
    const tokens = current.tokens ?? 0
    const percent = current.compactAt > 0 ? (tokens / current.compactAt) * 100 : 0
    add('context', { text: `${(tokens / 1000).toFixed(1)}k tokens`, colour: contextColour(percent) })
    add('cost', { text: `$${(current.costUsd ?? 0).toFixed(2)}`, colour: COLOURS.cost })
    if (current.added !== undefined && current.removed !== undefined) {
      add(
        'lines',
        { text: `+${current.added}`, colour: COLOURS.added },
        { text: ` -${current.removed}`, colour: COLOURS.removed },
      )
    }
    add('model', { text: current.model, colour: COLOURS.model })
    if (current.quotaPercent !== undefined) {
      const hours =
        current.quotaResetsAt !== undefined
          ? ` (${Math.max(0, (current.quotaResetsAt - now) / 3_600_000).toFixed(1)}h)`
          : ''
      add('quota', { text: `${Math.round(current.quotaPercent)}%${hours}`, colour: COLOURS.quota })
    }

    // Width in cells, counting code points (the row's text is narrow
    // characters), with a separator between each pair of parts.
    const width = (list: typeof parts) =>
      list.reduce((sum, part) => sum + part.pieces.reduce((n, p) => n + [...p.text].length, 0), 0) +
      SEPARATOR.length * Math.max(0, list.length - 1)
    const columns = e.viewport?.columns
    if (columns !== undefined) {
      for (const key of DROP_ORDER) {
        if (width(parts) <= columns) break
        parts = parts.filter(part => part.key !== key)
      }
    }

    const hint = await next(e)

    return (
      <Box flexDirection="column">
        <Box key="status" flexWrap="wrap">
          {parts.map((part, i) => (
            // One unbreakable unit per part, its separator leading, so a wrap
            // falls between parts rather than inside one.
            <Box key={part.key} flexShrink={0}>
              {i > 0 ? <Text key="sep" color={COLOURS.separator} dimColor>{SEPARATOR}</Text> : null}
              {part.pieces.map((piece, j) => (
                <Text key={`piece-${j}`} color={piece.colour} bold={piece.bold}>
                  {piece.text}
                </Text>
              ))}
            </Box>
          ))}
        </Box>
        <Box key="hint">{hint}</Box>
      </Box>
    )
  })
}
