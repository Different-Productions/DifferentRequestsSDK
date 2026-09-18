# The board wears your app

## What it is

The SDK's screens drawn in the host app's own accent and font, so the board reads as part of the app
it is inside rather than a widget bolted onto it. **A Pro surface** (`PLAN_SURFACE_APPEARANCE`,
contract 0.38.0, server #251): on Free, the screens are drawn in the SDK's own look whatever the host
app passes.

Two things and no more: the color controls are tinted with, and which of the system's families
everything is set in.

**Why not a full theme.** A theme is a hundred ways to make text unreadable, and every one of them
is found by a customer's users rather than by the developer who set it. An accent and a family
cannot: the system decides contrast, sizes and weights, and Dynamic Type still works.

**Why not a font the app ships.** SwiftUI applies a named typeface by replacing the whole font,
which takes each label's size and weight with it — a board where a title, a vote count and a caption
are all one size. `fontDesign` keeps text styles intact, so that is the half of it worth having.

**Why it is handed over rather than fetched.** It is the host app's own look. Reading it from the
console would make a color change a deploy of ours, and a round trip on every launch, to answer a
question the app already knows the answer to. What *is* fetched is whether the app's plan includes
it: `appearance_enabled` on the config the SDK already reads.

**Before the config answers**, the host app's look is drawn — the same side the badge errs on, so an
app paying for its look never sees ours.

## Surfaces

| Surface | Ships this? |
|---|---|
| Swift SDK | **Yes** — `Appearance`, handed to `DifferentRequestsHub(client:appearance:)`; every screen wears `hub.appearanceDrawn` |
| API (the rpcs) | **Reads it** — `GetConfig` answers `appearance_enabled` (server #251) |
| Web console | **none.** The console is ours and is drawn in ours |
| Push notifications | **none** — Apple draws those |

## How to find it, trigger it, and what happens

**Set it.** Where the hub is built:

```swift
let requests = DifferentRequestsHub(
  client: .make(appKey: "your-app-key"),
  appearance: Appearance(accent: .purple, font: .rounded)
)
```

`Appearance.standard` is the SDK's own look. It is named rather than implied by a default parameter,
so an app that has not thought about it says so at the call site.

**What wears it.** Every screen the SDK ships: the board, a request, the composer, the roadmap, the
changelog and the inbox. One modifier at the top of each, reading `hub.appearanceDrawn` as it draws,
so a control added later is worn without anybody remembering to say so, and the look follows the
config the moment it answers.

**What does not.** The "Powered by Different Requests" badge keeps its own quiet gray.

## Expectations

| Situation | Expected |
|---|---|
| A Pro app, `Appearance(accent: .purple, font: .rounded)` | Vote controls, prominent buttons, links and spinners are purple; every label is rounded |
| A Free app, the same appearance passed | The system tint and the system font, once the config has answered |
| Any app, before the config has answered | The appearance passed |
| Any app, the config read failed | The appearance passed — a failed read never takes a paying app's look away |
| `Appearance.standard`, any plan | The system tint and the system font |
| Dynamic Type at any size | Unchanged: the family moves, the text styles do not |
| Dark mode | Unchanged: the accent is a `Color`, so it resolves per scheme like any other |
| The badge | Gray, whatever the accent is |

Nothing is refused and nothing is shown to the person using the app: on Free the board is simply
drawn in the SDK's own look.

## The path a request takes

```
DifferentRequestsHub(client:appearance:)
  ├─ appearance: Appearance ── what the host app asked for
  └─ appConfig: AppConfigStore ── GetConfig, read by the board and the inbox (.task → load())
       │
       ▼
hub.appearanceDrawn                                  DifferentRequestsHub.swift
  switch appConfig.badge            (how far the config read got)
    .bought / .carried ─► config.appearanceEnabled ? appearance : .standard
    .unread / .reading / .failed ─► appearance
       │
       ├─ DifferentRequestsView ─┐
       ├─ RequestDetailView      │
       ├─ SubmitRequestView      ├─ .worn(by: hub.appearanceDrawn)      WornBy.swift
       ├─ InboxView              │     ├─ .tint(accent)
       ├─ RoadmapView            │     └─ .fontDesign(font)
       └─ ChangelogView         ─┘
```

Every screen reads the hub as it draws. `AppConfigStore` is `@Observable`, so the screens redraw when
the config answers; no screen keeps a copy of the look.

## UI map

```
Pro app, purple + rounded           Free app, purple + rounded passed
┌──────────────────────────┐        ┌──────────────────────────┐
│ Requests            (+)  │ purple │ Requests            (+)  │ system blue
│ ▲ 14  Dark mode          │ rounded│ ▲ 14  Dark mode          │ system font
│ ▲  9  Apple Watch app    │        │ ▲  9  Apple Watch app    │
│                          │        │ Powered by Different Req.│ ← the badge, gray
└──────────────────────────┘        └──────────────────────────┘
```

No in-flight state of its own: before the config answers, the passed look is drawn.

## Platform differences

None. `tint` and `fontDesign` are the same on iOS and macOS.

## Which tests walk the chart

There is no test target — see the server's #144. Walked in the example app on a simulator, against
development:

| Step | Answer |
|---|---|
| Example app (`DemoConfig.appearance`: purple, rounded) against Identity Walk on **Free** | The board in the system blue and the system font, "Powered by Different Requests" under the title. More menu: Inbox only |
| `Entitle` Identity Walk `pro`, relaunch | **Done** and **…** purple, text rounded, no badge. The example's list gains Roadmap and What's new |
| The push permission prompt | Not seen on either plan — this simulator may already hold an answer for the app, so the `pushEnabled` gate is read in code, not proven on screen |

iPhone 17 Pro simulator, iOS 26.4, against development, 2026-09-18. Both apps put back on Free after.

Walked before plans decided the look (0.9.x): purple and rounded everywhere, the badge gray, dark
mode and Dynamic Type unchanged, and `Appearance.standard` exactly what shipped before.
