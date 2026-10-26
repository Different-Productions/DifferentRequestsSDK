# Empty Roadmap and What's New

## What it is and how to trigger it

Owner ruling 2026-09-26, piece 32. A Roadmap with nothing on it says **"Nothing planned yet"** —
"When the team plans something, it shows up here." A What's New with nothing in it says **"Nothing
new yet"** — "When the app gets something new, you'll read about it here." Under either, **See
requests** opens the app's requests list, but only when the host app gave the screen a way there.

The way there is a binding, a public parameter on both screens:

```swift
RoadmapView(hub: requests, isShowingRequests: $isShowingRequests)
ChangelogView(hub: requests, isShowingRequests: $isShowingRequests)
```

**See requests** sets it to `true`. `RoadmapView(hub:)` and `ChangelogView(hub:)` draw no button.
The SDK's own sheet builds both that way, because Requests is the tab beside them.

The server answers a roadmap with every column even when all are empty, so `RoadmapStore` reads a
roadmap whose every column has a `totalCount` of 0 as empty. Before this, an empty roadmap drew three
headers each saying "No requests here yet."

Trigger: open Roadmap or What's New on an app whose plan has them (Pro) and nothing planned or
published.

## Expectations

| When it works | What the user sees |
|---|---|
| Empty Roadmap, host passed a binding | Map picture, "Nothing planned yet", "When the team plans something, it shows up here.", **See requests** |
| Empty What's New, host passed a binding | Sparkles, "Nothing new yet", "When the app gets something new, you'll read about it here.", **See requests** |
| Taps **See requests** | The host's requests list opens (in the example, the sheet swaps to the board) |
| The Roadmap or What's New tab of the SDK's sheet | The same words, no button; Requests is the tab beside it |
| A roadmap with anything on it | The columns, as before |

| When it fails | Exact error text the user sees |
|---|---|
| The read fails | "Roadmap couldn't load" or "What's New couldn't load" with **Try again** |

## Flow chart

```
Host: RoadmapView(hub:, isShowingRequests:)        RootView.swift (example)
        |
        v
RoadmapStore.readColumns()                          RoadmapStore.swift
   every column totalCount == 0 ? .empty : ReadState(page: columns)
        |
        v
RoadmapView.columns  case .empty                    RoadmapView.swift
ChangelogView.entries case .empty                   ChangelogView.swift
   ContentUnavailableView + actions:
     if let isShowingRequests -> SeeRequestsButton  SeeRequestsButton.swift
        |  isShowingRequests = true
        v
Host opens its requests list                        RootView.swift  session.show(.requests)
```

The SDK's own tabs: `DifferentRequestsView.swift` builds both with `init(hub:)`, which has no
**See requests**.

## What was walked

- 2026-09-26, iPhone simulator "DR Calls Walk", iOS 27, local server, a newly provisioned Pro app
  ("Empty Walk") with nothing on it: Roadmap from the example's list showed the three empty column
  headers — the store fix above came from that — then, rebuilt, "Nothing planned yet" with **See
  requests**. Tapping it swapped the sheet to the board ("What would make this app better?").
  **…** › Roadmap from the board: same words, no button, back button. What's New from the list:
  "Nothing new yet" with **See requests**.
- 2026-10-09, iOS 26.0 simulator, the two screens as tabs of the SDK's sheet on a Pro app ("Calls
  Walk"): both opened with the close button and no **See requests**. Neither was empty there, so the
  empty words inside a tab were not seen.
- The owner's real walk: not yet.
