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

**Handed over, and since contract 0.42.0 also chosen in the dashboard.** The look passed in code is
the host app's own, and it is drawn with no round trip. What is fetched is whether the app's plan
includes it, `appearance_enabled` on the config the SDK already reads, and the tint a developer
chose in the dashboard, which wins over the accent passed here (`a-tint-set-in-the-dashboard.md`).
The font is only ever the one passed in code.

**Before the config answers, no screen is drawn.** A spinner stands in, untinted, so nobody sees a
look the answer then replaces. `hub.configure()` is the launch read the host awaits before its
first window, so the answer is normally held before a screen opens.

## Surfaces

| Surface | Ships this? |
|---|---|
| Swift SDK | **Yes** — `Appearance`, handed to `DifferentRequestsHub(client:appearance:emptyBoard:)`; every screen wears the hub's look with `.worn(by: hub)` |
| API (the rpcs) | **Reads it** — `GetConfig` answers `appearance_enabled` (server #251) |
| Web console | **Chooses a tint that wins over the accent**, on its Appearance tab (`a-tint-set-in-the-dashboard.md`). The console itself is drawn in ours |
| Push notifications | **none** — Apple draws those |

## How to find it, trigger it, and what happens

**Set it.** Where the hub is built:

```swift
let requests = DifferentRequestsHub(
  client: DifferentRequestsClient(appKey: "your-app-key", baseURL: .production),
  appearance: Appearance(accent: .purple, font: .rounded),
  emptyBoard: .standard
)
```

`Appearance.standard` is the SDK's own look. It is named rather than implied by a default parameter,
so an app that has not thought about it says so at the call site.

**What wears it.** Every screen the SDK ships: the board, a request, the composer, the roadmap, the
changelog and the inbox. One modifier at the top of each, reading the hub as it draws,
so a control added later is worn without anybody remembering to say so, and the look follows the
config the moment it answers.

**What does not.** The "Powered by Different Requests" badge keeps its own quiet gray.

## Expectations

| Situation | Expected |
|---|---|
| A Pro app, `Appearance(accent: .purple, font: .rounded)` | Vote controls, prominent buttons, links and spinners are purple; every label is rounded |
| A Free app, the same appearance passed | The system tint and the system font, once the config has answered |
| Any app, before the config has answered | A spinner, untinted, in place of the screen |
| Any app, the config read failed | "Requests couldn't load", the reason, and **Try again**, in place of the screen |
| `Appearance.standard`, any plan | The system tint and the system font |
| Dynamic Type at any size | Unchanged: the family moves, the text styles do not |
| Dark mode | Unchanged: the accent is a `Color`, so it resolves per scheme like any other |
| The badge | Gray, whatever the accent is |

Nothing is refused and nothing is shown to the person using the app: on Free the board is simply
drawn in the SDK's own look.

## The path a request takes

```
DifferentRequestsHub(client:appearance:emptyBoard:)
  ├─ appearance: Appearance ── what the host app asked for
  └─ appConfig: AppConfigStore ── GetConfig, read by hub.configure() at launch
       │
       ▼
WornLook                                             Views/WornLook.swift
  switch appConfig.badge            (how far the config read got)
    .unread / .reading ─► ProgressView, untinted; .task → load()
    .failed ─► LoadFailure "Requests couldn't load", Try again → load()
    .bought / .carried ─► the screen, in hub.appearanceDrawn:
       config.appearanceEnabled ? appearance : .standard
       │
       ├─ DifferentRequestsView ─┐
       ├─ RequestDetailView      │
       ├─ SubmitRequestView      ├─ .worn(by: hub)      View+WornBy.swift → WornLook.swift
       ├─ InboxView              │     ├─ .tint(hub.tintDrawn(in: colorScheme))
       ├─ RoadmapView            │     │     the dashboard's tint, or appearanceDrawn.accent
       └─ ChangelogView         ─┘     └─ .fontDesign(hub.appearanceDrawn.font)
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

Before the config answers, a spinner stands in for the screen, so no look is drawn and then replaced.

## Platform differences

None. `tint` and `fontDesign` are the same on iOS and macOS.

## Which tests walk the chart

There is no test target — see the server's #144. Walked in the example app on a simulator, against
development:

| Step | Answer |
|---|---|
| Example app (`DemoConfig.appearance`: purple, rounded) against Identity Walk on **Free** | The board in the system blue and the system font, "Powered by Different Requests" under the title. More menu: Inbox only |
| `Entitle` Identity Walk `pro`, relaunch | **Done** and **…** purple, text rounded, no badge. The example's list gains Roadmap and What's New |
| The push permission prompt | Not seen on either plan — this simulator may already hold an answer for the app, so the `pushEnabled` gate is read in code, not proven on screen |

iPhone 17 Pro simulator, iOS 26.4, against development, 2026-09-18. Both apps put back on Free after.

Walked before plans decided the look (0.9.x): purple and rounded everywhere, the badge gray, dark
mode and Dynamic Type unchanged, and `Appearance.standard` exactly what shipped before.
