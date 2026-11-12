import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'review-tracker',
  component: 'Pane',
  requestId: 'review-tracker',
  props: {
    title: 'Review',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 20 },
    view: {},
  },
} as const

test('set, mark and press an item', async ($, on) => {
  on('command.register', () => ({ value: { command: 'review-tracker' } }))
  on('tool.register', (_, e) => ({ value: { tool: `mcp__review-tracker__${e.name}` } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.tool.call({
    tool: 'mcp__review-tracker__review_set',
    title: 'PR review',
    items: [{ n: 1, text: 'Fix the race' }, { n: 2, text: 'Rename foo' }],
  })
  const marked = await $.tool.call({
    tool: 'mcp__review-tracker__review_mark',
    updates: [{ n: 1, status: 'done' }, { n: 2, status: 'skipped', note: 'out of scope' }],
  })
  expect(String(marked.result)).toContain('2. skipped: Rename foo (note: out of scope)')

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /2\/2 finished/ }))).toBeTruthy()
  await ui.press({ key: 'item-2' })
  expect((await ui.find({ type: 'Text', text: /\[ \] 2\. Rename foo/ }))).toBeTruthy()
  await ui.unmount()
})

test('a press in the pane reaches the next prompt once', async ($, on) => {
  const contexts: (readonly string[] | undefined)[] = []
  on('command.register', () => ({ value: { command: 'review-tracker' } }))
  on('tool.register', (_, e) => ({ value: { tool: `mcp__review-tracker__${e.name}` } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.submit', (_, e) => {
    contexts.push(e.context)
    return { text: e.text }
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.tool.call({
    tool: 'mcp__review-tracker__review_set',
    title: 'PR review',
    items: [{ n: 1, text: 'Fix the race' }, { n: 2, text: 'Rename foo' }],
  })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'item-2' }) // open → doing
  await ui.press({ key: 'item-2' }) // doing → done
  await ui.press({ key: 'item-1' }) // open → doing
  await ui.press({ key: 'item-1' }) // doing → done
  await ui.press({ key: 'item-1' }) // done → skipped
  await ui.press({ key: 'item-1' }) // skipped → open: back where it was
  await ui.unmount()

  await $.prompt.submit({ text: 'next' })
  await $.prompt.submit({ text: 'again' })

  const [first, second] = contexts
  expect(first?.length).toBe(1)
  expect(first?.[0]).toContain('- item 2: open → done')
  expect(first?.[0]).not.toContain('item 1:')
  expect(second).toBeUndefined()
})
