import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { ItemStatus, PaneChange, Review, ReviewItem } from '../types'

const PANE = 'review-tracker'

// Change a tag when its value's fields change: it declines what an earlier
// version stored, which outlives a reload.
const review = atom({ plugin: 'review-tracker', key: 'review' } as const, null, {
  shape: 'review-1',
})
// Statuses the user changed in the pane since Claude last read the list.
const changes = atom({ plugin: 'review-tracker', key: 'changes' } as const, [], {
  shape: 'changes-1',
})

// Records a press in the pane, one entry per item: its status before the first
// unreported press and after the last, dropped once they match again.
function withChange(list: PaneChange[], n: number, from: ItemStatus, to: ItemStatus): PaneChange[] {
  const earlier = list.find(c => c.n === n)
  const others = list.filter(c => c.n !== n)
  const change = { n, from: earlier?.from ?? from, to }

  return change.from === change.to ? others : [...others, change]
}

const STATUSES: readonly ItemStatus[] = ['open', 'doing', 'done', 'skipped']

const MARKS: Record<ItemStatus, string> = {
  open: '[ ]',
  doing: '[~]',
  done: '[x]',
  skipped: '[-]',
}

function nextStatus(status: ItemStatus): ItemStatus {
  return STATUSES[(STATUSES.indexOf(status) + 1) % STATUSES.length] ?? 'open'
}

function summary(r: Review): string {
  const finished = r.items.filter(i => i.status === 'done' || i.status === 'skipped').length

  return `${finished}/${r.items.length} finished`
}

function asText(r: Review | null): string {
  if (r === null) {
    return 'No review is being tracked.'
  }
  const lines = r.items.map(
    i => `${i.n}. ${i.status}: ${i.text}${i.note ? ` (note: ${i.note})` : ''}`,
  )

  return [`${r.title} (${summary(r)})`, ...lines].join('\n')
}

function openPane($: EngineInterface) {
  return $.ui.open({ id: PANE, title: 'Review' })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'review-tracker',
      description: 'Show the review tracker pane; `/review-tracker clear` clears it',
    })
    await $.tool.register({
      name: 'review_set',
      description:
        'Start tracking a review in the review tracker pane beside the chat. ' +
        'Call this whenever you give the user a numbered list of review findings, ' +
        'issues or comments they will work through, with the same numbers and a ' +
        'short one-line text for each. It replaces any review already tracked.',
      inputSchema: {
        type: 'object',
        properties: {
          title: { type: 'string', description: 'What was reviewed, e.g. "PR #212 review"' },
          items: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                n: { type: 'integer', description: 'The item number as given to the user' },
                text: { type: 'string', description: 'A one-line summary of the item' },
              },
              required: ['n', 'text'],
            },
          },
        },
        required: ['title', 'items'],
      },
      isDeferred: false,
    })
    await $.tool.register({
      name: 'review_mark',
      description:
        'Update the status of items in the tracked review: "doing" when you start on one, ' +
        '"done" once it is dealt with, "skipped" when the user decides not to act on it ' +
        '(with a note saying why), "open" to reopen. The user can also change statuses ' +
        'in the pane; the result lists every item as it now stands, so call it with no ' +
        'updates to read the current state.',
      inputSchema: {
        type: 'object',
        properties: {
          updates: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                n: { type: 'integer' },
                status: { type: 'string', enum: [...STATUSES] },
                note: { type: 'string', description: 'Replaces the item\'s note; empty clears it' },
              },
              required: ['n'],
            },
          },
        },
      },
      isDeferred: false,
    })

    return next(e)
  })

  on('command.run', { command: 'review-tracker' }, async ($, e) => {
    if (e.args.trim() === 'clear') {
      await update($, review, () => null)
      await update($, changes, () => [])

      return { text: 'Review tracker cleared.' }
    }
    await openPane($)

    return { text: 'Review tracker opened.' }
  })

  on('tool.call', { tool: 'mcp__review-tracker__review_set' }, async ($, e) => {
    const input = e as unknown as { title: string; items: { n: number; text: string }[] }
    const items: ReviewItem[] = input.items.map(i => ({ n: i.n, text: i.text, status: 'open' }))
    const r: Review = { title: input.title, items }
    await update($, review, () => r)
    await update($, changes, () => [])
    await openPane($)

    return { result: `Tracking ${items.length} items in the review pane.` }
  })

  on('tool.call', { tool: 'mcp__review-tracker__review_mark' }, async ($, e) => {
    const input = e as unknown as {
      updates?: { n: number; status?: ItemStatus; note?: string }[]
    }
    const current = await read($, review)
    if (current === null) {
      return { deny: 'No review is being tracked; call review_set first.' }
    }
    const unknown = (input.updates ?? []).filter(u => !current.items.some(i => i.n === u.n))
    if (unknown.length > 0) {
      return { deny: `No item numbered ${unknown.map(u => u.n).join(', ')}.\n${asText(current)}` }
    }
    const updated = await update($, review, r =>
      r === null
        ? r
        : {
            ...r,
            items: r.items.map(item => {
              const u = (input.updates ?? []).find(one => one.n === item.n)
              if (u === undefined) {
                return item
              }
              const note = u.note === undefined ? item.note : u.note || undefined

              return { ...item, status: u.status ?? item.status, note }
            }),
          },
    )
    // The result lists every status, the user's changes included.
    await update($, changes, () => [])

    return { result: asText(updated) }
  })

  on('prompt.submit', async ($, e, next) => {
    const pending = await read($, changes)
    const r = await read($, review)
    if (e.command !== undefined || pending.length === 0 || r === null) {
      return next(e)
    }
    await update($, changes, () => [])
    const lines = pending.map(c => `- item ${c.n}: ${c.from} → ${c.to}`)
    const told = [
      'Since you last read the review tracker, the user changed these statuses in its pane:',
      ...lines,
      '',
      'The tracked review as it now stands:',
      asText(r),
    ].join('\n')

    return next({ ...e, context: [...(e.context ?? []), told] })
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const r = await read($, review)

    if (r === null) {
      return (
        <Box flexDirection="column">
          <Text dimColor>No review is being tracked.</Text>
          <Text dimColor>Ask Claude for a review and it will appear here.</Text>
        </Box>
      )
    }

    const cycle = async (item: ReviewItem) => {
      const to = nextStatus(item.status)
      await update($, review, cur =>
        cur === null
          ? cur
          : { ...cur, items: cur.items.map(i => (i.n === item.n ? { ...i, status: to } : i)) },
      )
      await update($, changes, list => withChange(list, item.n, item.status, to))
    }

    return (
      <Box flexDirection="column">
        <Text bold>{r.title}</Text>
        <Text dimColor>{summary(r)} · press an item to change its status</Text>
        {r.items.map(item => {
          const isFinished = item.status === 'done' || item.status === 'skipped'

          return (
            <Box flexDirection="column">
              <Button key={`item-${item.n}`} onPress={() => cycle(item)}>
                <Text
                  dimColor={isFinished}
                  strikethrough={item.status === 'skipped'}
                  color={item.status === 'doing' ? 'yellow' : item.status === 'done' ? 'green' : undefined}
                >
                  {MARKS[item.status]} {item.n}. {item.text}
                </Text>
              </Button>
              {item.note && <Text dimColor>    {item.note}</Text>}
            </Box>
          )
        })}
      </Box>
    )
  })
}
