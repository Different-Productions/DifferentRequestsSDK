# A tint set in the dashboard

DifferentRequests-Server#454. Rides on the redesign (#167), which defines where the tint is drawn.

## What it is and how to trigger it

A Pro app's developer chooses the tint color in the dashboard, one color for light mode and one for
dark mode, and the SDK draws it the next time the app reads its configuration. No app update.

**The dashboard wins.** The order is: the tint chosen in the dashboard, then the
`Appearance(accent:)` the host app passes in code, then the system tint.

**Each mode has its own color.** In light mode the light color is the tint; in dark mode the dark
one is. Everything the tint already colors follows: a voted tile, the New request button, the
current tab, Vote and Follow, links and spinners.

**The label on it stays readable.** `ColorRole.onTint` measures the tint as it is drawn in the
current mode, so each of the two colors gets its own answer: white where white reaches 4.5 to 1,
black where it does not.

**It is checked once, where it arrives.** `DashboardTint(config:)` reads the contract's `Tint` when
`GetConfig` answers. It is a tint only if the plan includes the app's own look, both colors are
present, and every component is 255 or under. Anything else is no tint, and the app draws the color
from its code.

**A Free app draws none.** The server sends a Free app no tint, and the SDK would not read one: the
check starts with `appearance_enabled`.

**The font is still the app's.** The dashboard chooses a color only. `Appearance.font` is drawn as
before.

Trigger: in the dashboard, open **Appearance**, choose **A color you choose here**, set both colors
and **Save**. Then open Requests in the app after its next launch.

## Expectations

| When it works | What the person sees |
|---|---|
| Pro app, a tint saved, light mode | The voted tile, New request and the current tab in the light color |
| The same app in dark mode | The same three in the dark color |
| A light tint, such as yellow | Black labels on it |
| A dark tint, such as navy | White labels on it |
| Pro app, **App's own color** saved | The accent passed in code, or the system tint when the app passes `.standard` |
| Free app | The SDK's own look, as before |
| The host awaited `hub.configure()` at launch | The right color on the first frame of every screen |
| A screen opened before the configuration answers | A spinner and nothing else: no tint, no tabs, no badge. The screen draws once the answer arrives |

**No screen is drawn in a color it might lose.** `WornLook` draws a screen only once the
configuration has answered, so a launch never shows the accent from code and then swaps in the
dashboard's. `DifferentRequestsHub.configure()` is the launch read, awaited before the host's first
window, so the answer is normally held before anybody opens a screen.

| When it fails | What happens |
|---|---|
| The configuration read failed | "Requests couldn't load" with the reason and **Try again**, in place of the screen. Nothing is drawn in a guessed color |
| A tint with one color missing, or a component over 255 | Read as no tint. The accent passed in code is drawn |
| A server on a contract older than 0.42.0 | No tint arrives. The accent passed in code is drawn |

Nothing is shown to the person using the app in either case.

## Flow chart

```
host app launch: await hub.configure()                 DifferentRequestsHub.swift
  └─ appConfig: AppConfigStore                         Stores/AppConfigStore.swift
       load() ── client.config() ── GetConfig
         ├─ config = answer.config
         └─ dashboardTint = DashboardTint(config:)     State/DashboardTint.swift
               appearanceEnabled, hasTint, hasLight, hasDark
               Color(dashboardColor:) × 2              Views/Color+DashboardColor.swift
                    a component over 255 ──▶ no tint
        │
        ▼
every screen: .worn(by: hub)                           Views/View+WornBy.swift
  └─ WornLook                                          Views/WornLook.swift
       appConfig.badge .unread / .reading ─▶ ProgressView, untinted; .task loads
       appConfig.badge .failed ─▶ LoadFailure, Try again re-reads   Views/LoadFailure.swift
       appConfig.badge .bought / .carried ─▶ the screen, worn:
       @Environment(\.colorScheme)
       .tint(hub.tintDrawn(in: colorScheme))           DifferentRequestsHub.swift
            ├─ appConfig.dashboardTint ─▶ light or dark, by the mode being drawn
            └─ none ─▶ appearanceDrawn.accent          the host app's, or the SDK's own on Free
       .fontDesign(hub.appearanceDrawn.font)
        │
        ▼
ColorRole.tint, ColorRole.onTint                       Views/ColorRole.swift
  onTint measures the tint as resolved in this mode    Views/LuminanceWeight.swift
```

## Platform differences

None. `tint`, `colorScheme` and `Color(.sRGB, …)` are the same on iOS and macOS.

## What was walked

There is no test target. Walked on 2026-10-09 in the example app (`DemoConfig.appearance`: purple,
rounded) on an iPhone 17 Pro simulator, iOS 26.0, against a local server on the development table,
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

Not walked: a Free app that holds a tint saved while it was on Pro, because moving a walk app
between plans is not a press a dashboard user makes without paying. The server sends such an app
no tint, and `DashboardTint(config:)` would not read one. Nor a tint with a missing color or a
component over 255, which the dashboard cannot write. Nor macOS, which was built and not run.

Seen on the walk: the plus on New request is drawn by the system's prominent toolbar button, which
picks its own label color. It was white on `1F8A4C`, where the SDK's own rule gives black.
