# The empty board in your words

## What it is and how to trigger it

A board nobody has posted to yet is the first thing most of an app's users see of this SDK, and it
said the same three things in every app, in our voice: "What should we build?". An app on Pro sets
its own symbol, title, message and button words for that one screen. **Pro**, ruled 2026-09-25
(#58), and part of the same Pro surface as the app's own accent and font, `PLAN_SURFACE_APPEARANCE`
("the board wears your app"): it is the board looking like the app's product instead of ours.

Set once, where the hub is made, next to the appearance:

```swift
private let requests = DifferentRequestsHub(
  client: .make(appKey: "your-app-key"),
  appearance: .standard,
  emptyBoard: EmptyBoard(
    symbol: "leaf",
    title: "What would help your practice?",
    message: "Tell us what would make your sessions calmer. Others can add their vote.",
    button: "Share an idea"
  )
)
```

An app that sets none passes `EmptyBoard.standard`, named rather than defaulted, the way
`Appearance.standard` is.

A person triggers it by opening the board of an app with no requests, with nothing narrowing it.

Only that one screen. "Nothing matches" and the filter messages stay the SDK's, because they
describe what the person did, and an app rewording them would be an app writing a bug. The button
keeps its icon and still opens **New request**; only its words change. The "+" in the nav bar still
says New request.

Mockup agreed 2026-09-25: https://claude.ai/artifact/1SHTWeLUD5ApsBM388aZ1L (bottom row).

## Expectations

| When it works | What the user sees |
|---|---|
| A Pro app with its own words, board empty | The app's symbol, title and message, and a button with its words that opens New request |
| A Pro app that left one field empty (`""`) | That one field in the SDK's words, the rest in the app's |
| A Free app with its own words | The SDK's words: "What should we build?" / "Nobody has asked for anything yet. Tell us what you want and everyone can vote on it." / **New request** |
| Before the app's config has answered | The app's words, the same side the appearance errs on, so a Pro app never flashes ours |
| A search or a status filter that finds nothing | The SDK's own words for those, on every plan |
| Nobody signed in | The symbol, title and message; no button (asking belongs to a person) |

| When it fails | Exact error text the user sees |
|---|---|
| Reading the board fails | "Couldn't load" and Try again, as before; the empty screen is not drawn |

## Flow chart

```
DifferentRequestsHub(client:appearance:emptyBoard:)   DifferentRequestsHub.swift
        │ keeps emptyBoard as the app handed it
        ▼
DifferentRequestsView.empty                           Views/DifferentRequestsView.swift
        │ store.narrowing == .nothing ?
        ├─ yes ─► hub.emptyBoardDrawn                 DifferentRequestsHub.swift
        │           │ drawsHostLook (config answered and appearanceEnabled, or not answered yet)
        │           ├─ true  ─► emptyBoard.filledIn   EmptyBoard.swift (empty field → .standard's)
        │           └─ false ─► EmptyBoard.standard   EmptyBoard.swift
        │         symbol, title, message ─► ContentUnavailableView
        │         button ─► the empty state's button, somebody signed in only
        └─ no  ─► BoardNarrowing's own words          State/BoardNarrowing.swift
```

## What was walked

- 2026-09-25, iPhone 17 Pro simulator, iOS 27, the example app against development on Identity
  Walk, an app with no requests. No location route: nothing here reads location.
  - Given Pro by hand from the platform console, launched: the board read "What would make this app
    better?" / "Ask for it here, and anyone else who wants it can add a vote." with **Ask for it**
    and the sparkles symbol, the example's own words; the nav bar's "+" still read New request.
  - Pro taken back, relaunched: "What should we build?" / "Nobody has asked for anything yet. Tell us
    what you want and everyone can vote on it." with **New request**, the SDK's words.
  - On Free, a status filter that found nothing kept the SDK's filter words.
- The owner's real walk: not yet.
