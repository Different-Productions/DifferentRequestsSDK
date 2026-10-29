# The board wears your app

## What it is

The SDK's screens drawn in a color and font the app's developer chose on the dashboard's Appearance
page, so the board reads as part of the app it is inside rather than a widget bolted onto it. **A Pro
surface** (`PLAN_SURFACE_APPEARANCE`, contract 0.38.0, server #251): on Free, the screens are drawn
in the SDK's own look whatever was saved.

Two things and no more: the color controls are tinted with, and which of the system's families
everything is set in.

**Why not a full theme.** A theme is a hundred ways to make text unreadable, and every one of them
is found by a customer's users rather than by the developer who set it. An accent and a family
cannot: the system decides contrast, sizes and weights, and Dynamic Type still works.

**Why not a font the app ships.** SwiftUI applies a named typeface by replacing the whole font,
which takes each label's size and weight with it — a board where a title, a vote count and a caption
are all one size. `fontDesign` keeps text styles intact, so that is the half of it worth having.

**Chosen in the dashboard, never in code.** Since contract 0.43.0 the host app passes no look. The
config the SDK already reads carries all of it: `appearance_enabled` (whether the plan includes it),
`tint` (contract 0.42.0, `a-tint-set-in-the-dashboard.md`) and `font_family` (contract 0.43.0, the
contract's `a-font-family-set-in-the-dashboard.md`). With nothing chosen, or on a plan without it,
the board is the system tint and the system's default family.

**Before the config answers, no screen is drawn.** A spinner stands in, untinted, so nobody sees a
look the answer then replaces. `hub.configure()` is the launch read the host awaits before its
first window, so the answer is normally held before a screen opens.

## Surfaces

| Surface | Ships this? |
|---|---|
| Swift SDK | **Draws it** — every screen wears the config's look with `.worn(by: hub)`. Nothing in the host app's code |
| API (the rpcs) | **Reads it** — `GetConfig` answers `appearance_enabled` (server #251), `tint` and `font_family` |
| Web console | **Chooses it** — the color and the font, on its Appearance page. The console itself is drawn in ours |
| Push notifications | **none** — Apple draws those |

## How to find it, trigger it, and what happens

**Set it.** In the dashboard, open **Appearance**, choose a color for light and dark mode and one of
**Default**, **Rounded**, **Serif** or **Mono**, and **Save**. The app draws it the next time it
calls `hub.configure()`, with no app update.

**What wears it.** Every screen the SDK ships: the board, a request, the composer, the roadmap, the
changelog and the inbox. One modifier at the top of each, reading the hub as it draws,
so a control added later is worn without anybody remembering to say so, and the look follows the
config the moment it answers.

**What does not.** The "Powered by Different Requests" badge keeps its own quiet gray.

## Expectations

| Situation | Expected |
|---|---|
| A Pro app, navy and yellow and **Rounded** saved | Vote controls, prominent buttons, links and spinners are navy in light mode and yellow in dark; every label is rounded |
| A Pro app, nothing saved | The system tint and the system font |
| A Free app, the same look saved | The system tint and the system font, once the config has answered |
| A font family this build does not know | The system font |
| Any app, before the config has answered | A spinner, untinted, in place of the screen |
| Any app, the config read failed | "Requests couldn't load", the reason, and **Try again**, in place of the screen |
| Dynamic Type at any size | Unchanged: the family moves, the text styles do not |
| The badge | Gray, whatever the tint is |

Nothing is refused and nothing is shown to the person using the app: on Free the board is simply
drawn in the SDK's own look.

## The path a request takes

```
DifferentRequestsHub(client:emptyBoard:notificationPermission:)
  └─ appConfig: AppConfigStore ── GetConfig, read by hub.configure() at launch
       │
       ▼
WornLook                                             Views/WornLook.swift
  switch appConfig.badge            (how far the config read got)
    .unread / .reading ─► ProgressView, untinted; .task → load()
    .failed ─► LoadFailure "Requests couldn't load", Try again → load()
    .bought / .carried ─► the screen, worn:
       │
       ├─ DifferentRequestsView ─┐
       ├─ RequestDetailView      │
       ├─ SubmitRequestView      ├─ .worn(by: hub)      View+WornBy.swift → WornLook.swift
       ├─ InboxView              │     ├─ .tint(hub.tintDrawn(in: colorScheme))
       ├─ RoadmapView            │     │     config.dashboardTint(in:), or Color.accentColor
       └─ ChangelogView         ─┘     └─ .fontDesign(hub.fontDrawn())
                                             config.appearanceEnabled
                                               ? config.fontFamily.fontDesign()   DRFontFamily+Design.swift
                                               : .default
```

Every screen reads the hub as it draws. `AppConfigStore` is `@Observable`, so the screens redraw when
the config answers; no screen keeps a copy of the look.

## UI map

```
Pro app, navy + Rounded saved       Free app, navy + Rounded saved
┌──────────────────────────┐        ┌──────────────────────────┐
│ Requests            (+)  │ navy   │ Requests            (+)  │ system blue
│ ▲ 14  Dark mode          │ rounded│ ▲ 14  Dark mode          │ system font
│ ▲  9  Apple Watch app    │        │ ▲  9  Apple Watch app    │
│                          │        │ Powered by Different Req.│ ← the badge, gray
└──────────────────────────┘        └──────────────────────────┘
```

Before the config answers, a spinner stands in for the screen, so no look is drawn and then replaced.

## Platform differences

None. `tint` and `fontDesign` are the same on iOS and macOS.

## Which tests walk the chart

Not walked yet: the font family chosen in the dashboard (contract 0.43.0), and the board with no
look passed in code. The walks below are from when the example app passed purple and rounded.

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
