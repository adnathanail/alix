import { expect, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

// Engine answers for one measurement: repo "nix-darwin" on branch "main",
// 45k of 200k tokens, $1.23, Opus, 37% of the 5-hour window, and git
// reporting 10 lines added and 4 removed (no untracked files).
function engine(on: On) {
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.cwd', () => ({ value: '/src/nix-darwin' }))
  on('session.repo', () => ({ value: { root: '/src/nix-darwin', remote: null, internal: false, name: null } }))
  on('session.model', () => ({ value: 'Opus' }))
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      context: { tokens: 45_000, window: 200_000, percent: 22 },
      rateLimits: [{ kind: 'five_hour', percentUsed: 37 }],
      cost: { usd: 1.23 },
    },
  }))
  on('clock.now', () => ({ value: 0 }))
  // No autoCompactWindow set: the row measures against the model's window.
  on('settings.read', () => ({ value: {} }))
  on('process.run', (_, e) => {
    const args = e.argv.join(' ')
    const stdout = args.includes('rev-parse')
      ? '/src/nix-darwin\n'
      : args.includes('diff --numstat')
        ? '10\t4\tfile.nix\n'
        : args.includes('branch')
          ? 'main\n'
          : ''

    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  // The engine's own hint line, which the row sits above.
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>? for shortcuts</Text>
  })
}

const HINT = {
  plugin: 'statusline',
  component: 'PromptHint',
  requestId: 'hint',
  surface: 'terminal',
  props: { isDraft: false, isWorking: false, hint: '? for shortcuts' },
} as const

// Every Text drawn, joined: the row's parts and separators, then the hint.
// The full row is 64 cells:
// nix-darwin | (main) | 45.0k tokens | $1.23 | +10 -4 | Opus | 37%
async function drawnAt($: Engine, columns: number): Promise<string> {
  const ui = await $.ui.mount({ ...HINT, viewport: { columns, rows: 40 } })
  const texts = (await ui.findAll({ type: 'Text' })).map(t => t.text ?? '').join('')
  await ui.unmount()

  return texts
}

async function started($: Engine, on: On) {
  engine(on)
  await $.session.start({ cwd: '/src/nix-darwin', surface: 'terminal', isInteractive: true })
}

test('a wide terminal shows every part, above the hint', async ($, on) => {
  await started($, on)

  const row = await drawnAt($, 200)
  expect(row).toContain('nix-darwin | (main) | 45.0k tokens | $1.23 | +10 -4 | Opus | 37%')
  expect(row).toContain('? for shortcuts')
})

test('a row that just fits keeps every part', async ($, on) => {
  await started($, on)

  expect(await drawnAt($, 64)).toContain('$1.23')
})

test('parts drop in order as the terminal narrows: cost, model, lines', async ($, on) => {
  await started($, on)

  expect(await drawnAt($, 63)).toContain('nix-darwin | (main) | 45.0k tokens | +10 -4 | Opus | 37%')
  expect(await drawnAt($, 55)).toContain('nix-darwin | (main) | 45.0k tokens | +10 -4 | 37%')
  expect(await drawnAt($, 48)).toContain('nix-darwin | (main) | 45.0k tokens | 37%')
})

test('past the last drop, the rest stays and wraps', async ($, on) => {
  await started($, on)

  const narrow = await drawnAt($, 20)
  for (const part of ['nix-darwin', '(main)', '45.0k tokens', '37%']) {
    expect(narrow).toContain(part)
  }
  for (const part of ['$1.23', 'Opus', '+10']) {
    expect(narrow).not.toContain(part)
  }
})
