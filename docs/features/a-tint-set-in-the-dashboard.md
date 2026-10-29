# A tint set in the dashboard

DifferentRequests-Server#454. Rides on the redesign (#167), which defines where the tint is drawn.

## What it is and how to trigger it

A Pro app's developer chooses the tint color in the dashboard, one color for light mode and one for
dark mode, and the SDK draws it the next time the app reads its configuration. No app update.

**The dashboard owns it.** The order is: the tint chosen in the dashboard, then the system tint
(`Color.accentColor`). The host app passes no color in code.

**Each mode has its own color.** In light mode the light color is the tint; in dark mode the dark
one is. Everything the tint already colors follows: a voted tile, the New request button, the
current tab, Vote and Follow, links and spinners.

**The label on it stays readable.** `ColorRole.onTint` measures the tint as it is drawn in the
current mode, so each of the two colors gets its own answer: white where white reaches 4.5 to 1,
black where it does not.

**It is checked where it is drawn.** `DRAppConfig.dashboardTint(in:)` reads the contract's `Tint`
from the configuration `GetConfig` answered with. It is a tint only if the plan includes the app's own look, both colors are
present, and every component is 255 or under. Anything else is no tint, and the app draws the
system tint.

**A Free app draws none.** The server sends a Free app no tint, and the SDK would not read one: the
check starts with `appearance_enabled`.

**The font comes from the dashboard too**, beside the tint, since contract 0.43.0
(`the-board-wears-your-app.md`).

Trigger: in the dashboard, open **Appearance**, choose **A color you choose**, set both colors
and **Save**. Then open Requests in the app after its next launch.

## Expectations

| When it works | What the person sees |
|---|---|
| Pro app, a tint saved, light mode | The voted tile, New request and the current tab in the light color |
| The same app in dark mode | The same three in the dark color |
| A light tint, such as yellow | Black labels on it |
| A dark tint, such as navy | White labels on it |
| Pro app, **System color** saved | The system tint |
| Free app | The SDK's own look, as before |
| The host awaited `hub.configure()` at launch | The right color on the first frame of every screen |
| A screen opened before the configuration answers | A spinner and nothing else: no tint, no tabs, no badge. The screen draws once the answer arrives |

**No screen is drawn in a color it might lose.** `WornLook` draws a screen only once the
configuration has answered, so a launch never shows the system tint and then swaps in the
dashboard's. `DifferentRequestsHub.configure()` is the launch read, awaited before the host's first
window, so the answer is normally held before anybody opens a screen.

| When it fails | What happens |
|---|---|
| The configuration read failed | "Requests couldn't load" with the reason and **Try again**, in place of the screen, with the sheet's close button. Nothing is drawn in a guessed color |
| A tint with one color missing, or a component over 255 | Read as no tint. The system tint is drawn |
| A server on a contract older than 0.42.0 | No tint arrives. The system tint is drawn |

Nothing is shown to the person using the app in either case.

## Flow chart

```
host app launch: await hub.configure()                 DifferentRequestsHub.swift
  └─ appConfig: AppConfigStore                         Stores/AppConfigStore.swift
       load() ── client.config() ── GetConfig
         ├─ config = answer.config
         └─ badge = BadgeState(response:)
        │
        ▼
every screen: .worn(by: hub)                           Views/View+WornBy.swift
  └─ WornLook                                          Views/WornLook.swift
       appConfig.badge.state unset / .reading / .failed ─▶ ConfigPending       Views/ConfigPending.swift
            unset / .reading ─▶ ProgressView, untinted; .task loads
            .failed ─▶ LoadFailure, Try again re-reads          Views/LoadFailure.swift
       the tab bar: TabsWornLook puts ConfigPending in a stack   Views/TabsWornLook.swift
            with the sheet's close button, since the tabs have no stack of their own
       appConfig.badge.state .bought / .carried ─▶ the screen, worn:
       @Environment(\.colorScheme)
       .tint(hub.tintDrawn(in: colorScheme))           DifferentRequestsHub.swift
            ├─ appConfig.config.dashboardTint(in:) ─▶ light or dark    Views/DRAppConfig+DashboardTint.swift
            │     appearanceEnabled, hasTint, hasLight, hasDark
            │     Color(dashboardColor:) × 2          Views/Color+DashboardColor.swift
            │     a component over 255 ──▶ no tint
            └─ none ─▶ Color.accentColor               the system tint
       .fontDesign(hub.fontDrawn())                    the-board-wears-your-app.md
        │
        ▼
ColorRole.tint, ColorRole.onTint                       Views/ColorRole+ShapeStyle.swift
  onTint measures the tint as resolved in this mode    Views/LuminanceWeight+Weight.swift
```

## Platform differences

None. `tint`, `colorScheme` and `Color(.sRGB, …)` are the same on iOS and macOS.

## What was walked

Not walked yet: **System color** saved with no color passed in code, which now draws the system
tint where the walks below drew purple.

There is no test target. Walked on 2026-10-09 in the example app (which then passed purple and
rounded in code) on an iPhone 17 Pro simulator, iOS 26.0, against a local server on the development table,
with the contract's `app-tint` branch in place of a tag. Trail Notes is Pro; Walk Provisioned App is
Free. Each change was made in the dashboard's Appearance tab, and the app was launched again after
it. Pictures are in `~/Developer/Screenshots/DifferentRequests/2026-10-09 dashboard tint build/app/`.

| Step | Answer |
|---|---|
| Trail Notes, **App's own color** saved. Open Requests in light and dark mode | Voted tiles, New request and the Requests tab in purple, the color from code |
| Save `1F8A4C` for light mode and `30D158` for dark mode. Launch again, open Requests | Light mode: the three in `1F8A4C`. Dark mode: the three in `30D158`. Tile labels black on both, which is what 4.5 to 1 gives for each |
| Save `123A7A` and `FFE600` | Light mode: navy tiles with white labels. Dark mode: yellow tiles with black labels |
| Save **App's own color**. Launch again | Purple again |
| Launch as Walk Provisioned App, Free | The system blue and the system font in both modes, two tabs, "Powered by Different Requests" |

Not walked on that day: a Free app that holds a tint saved while it was on Pro (walked on
2026-10-26, below). Nor a tint with a missing color or a
component over 255, which the dashboard cannot write. Nor macOS, which was built and not run.

Seen on the walk: the plus on New request is drawn by the system's prominent toolbar button, which
picks its own label color. It was white on `1F8A4C`, where the SDK's own rule gives black.

Walked on 2026-10-26 against development (`api-dev`), iPhone 17 Pro simulator, iOS 27.0:

| Step | Answer |
|---|---|
| Save `123A7A` and `FFE600` on the dashboard's Appearance tab, launch, open Requests | Light mode: navy on the first frame, four tabs. Dark mode: yellow, with a black plus |
| Launch with the server unreachable, open Requests | "Requests couldn't load", "You're offline. Check your connection and try again.", **Try again**, and the close button |
| Tap the close button | The sheet closes |

Walked on 2026-10-26 against development with SDK 0.15.1, on the "DifferentRequests iPad" and
"DifferentRequests" simulators, iOS 27.0. Pictures are in
`~/Developer/Screenshots/DifferentRequests/2026-10-26 dev walk/`.

| Step | Answer |
|---|---|
| iPad, `123A7A` and `FFE600` saved, launch, open Requests in light mode | Navy New request and Requests tab from the first frame, four tabs and Search |
| The same in dark mode | Yellow New request and Requests tab, black plus |
| Take Trail Notes' Pro gift back in the platform console, the tint still saved. iPhone, launch, open Requests | The system blue in light and dark mode from the first frame. Requests, Inbox and Search only |
| Give the gift back | The platform console shows Pro until 2026-10-31 and "Your colors and font: on" |

Not walked: macOS. The Mac example app can only be opened by clicking on the owner's screen.
