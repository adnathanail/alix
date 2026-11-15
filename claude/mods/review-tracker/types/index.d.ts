export type ItemStatus = 'open' | 'doing' | 'done' | 'skipped'

export type ReviewItem = {
  n: number
  text: string
  status: ItemStatus
  note?: string
}

export type Review = { title: string; items: ReviewItem[] }

// A status the user changed in the pane, which Claude has not yet been told of.
export type PaneChange = { n: number; from: ItemStatus; to: ItemStatus }

// An item pressed in the pane moments ago, drawn in the section it was in
// (finished or not) until its hold ends.
export type HeldItem = { n: number; isFinished: boolean }

declare module 'claude-code' {
  interface PluginState {
    'review-tracker': {
      review: Shaped<Review | null>
      changes: Shaped<PaneChange[]>
      held: Shaped<HeldItem[]>
    }
  }
}
