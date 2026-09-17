# The board wears your app

## What it is

The SDK's screens drawn in the host app's own accent and font, so the board reads as part of the app
it is inside rather than a widget bolted onto it.

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
question the app already knows the answer to.

## Surfaces

| Surface | Ships this? |
|---|---|
| Swift SDK | **Yes** — `Appearance`, handed to `DifferentRequestsHub(client:appearance:)`, worn by every screen |
| Web console | **none.** The console is ours and is drawn in ours |
| API (the rpcs) | **none.** Nothing about a look travels on the wire |
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
changelog and the inbox. One modifier at the top of each, so a control added later is worn without
anybody remembering to say so.

**What does not.** The "Powered by Different Requests" badge keeps its own quiet gray. It is a mark
of where the screen came from, and a mark drawn in the host app's accent reads as part of the host
app.

## Expectations

| Situation | Expected |
|---|---|
| `Appearance.standard` | The system tint and the system font, which is what shipped before this existed |
| An accent of `.purple` | Vote controls, prominent buttons, links and spinners are purple |
| `font: .rounded` | Every label on every SDK screen is rounded, at the size it already chose |
| Dynamic Type at any size | Unchanged: the family moves, the text styles do not |
| Dark mode | Unchanged: the accent is a `Color`, so it resolves per scheme like any other |
| The badge | Gray, whatever the accent is |

## The path a request takes

```
DifferentRequestsHub(client:appearance:)
  │
  └─ appearance: Appearance ── a let on the hub, read by every screen
       │
       ├─ DifferentRequestsView ─┐
       ├─ RequestDetailView      │
       ├─ SubmitRequestView      ├─ .worn(by: appearance)
       ├─ InboxView              │     ├─ .tint(appearance.accent)
       ├─ RoadmapView            │     └─ .fontDesign(appearance.font)
       └─ ChangelogView         ─┘
```

`RoadmapView` and `ChangelogView` hold the appearance as a `let` of their own rather than reading it
off the hub, because they hold their store that way too — neither keeps a hub.

## Platform differences

None. `tint` and `fontDesign` are the same on iOS and macOS.

## Which tests walk the chart

There is no test target — see the server's #144. Walked in an app built the way the documentation
says, on iPhone 17 Pro, iOS 26.2, against development.

The walk, and what it answered:

| Step | Answer |
|---|---|
| Build the hub with `Appearance(accent: .purple, font: .rounded)` | The ask button, the spinner and the filters are purple; every label is rounded |
| Read the badge | Still gray |
| Switch the simulator to dark mode | The accent resolves for the scheme; nothing is unreadable |
| Turn Dynamic Type up | Text grows as it did before; the family does not change size |
| Build it with `Appearance.standard` | Exactly what shipped before this existed |
