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

declare module 'claude-code' {
  interface PluginState {
    'review-tracker': {
      review: Shaped<Review | null>
      changes: Shaped<PaneChange[]>
    }
  }
}
