# The badge a free app carries

## What it is

"Powered by Different Requests", one row after the last request on the Requests screen, in an app
whose plan is Free. Paying makes it disappear, and that is the first thing $10 a month buys.

Three decisions shape it, and all three were taken against a mockup before any code:

**After the last request, as a row of the list.** Since 2026-10-09 (#167). Apple's rule is "Ensure
branding always defers to content", and under the title it pushed the first request down. It is a
44 pt row with a chevron, so it reads as something that opens, and it scrolls with the list. It is
not pinned over the content.

**A tap says what this is, in the app user's words.** Owner ruling 2026-09-26, piece 24: the badge
pushes a **"What is this?"** page onto the same stack, never a second sheet: "[App name] uses Different Requests to hear what you want
next.", then **Ask**, **Follow**, and **Your requests go to the team behind [App name].** "What you
write is never sold or shared." — with **About Different Requests** at the bottom. The app name is
`DRAppConfig.app.name`, or "This app" when it is empty.

**About Different Requests opens the browser.** Since 2026-10-09 (#167) it is a row that opens the
site in the browser. Until then it raised Safari as a sheet over the page, which was a sheet over
the SDK's own sheet, and Apple's rule is "Display only one sheet at a time".

**The Requests tab only.** One place. On every screen it starts reading as watermarking.

## Surfaces

| Surface | Ships this? |
|---|---|
| Requests (`RequestsScreen`, inside `DifferentRequestsView`) | **Yes**: the row after the last request |
| Inbox (`InboxView`) | **none** since 2026-10-09 |
| Roadmap, changelog, request detail | **none** — deliberately. Both are Pro surfaces anyway, so a badge there would only ever draw for an app that cannot open them |
| New request form (`SubmitRequestView`) | **none** — a mark on a form is an advertisement |
| Server | **Reads it** — since contract 0.38.0 the flag is `badge_removed`, which gates `PLAN_SURFACE_BADGE_REMOVAL` like every other Pro surface; `show_badge` is gone (server #251) |
| Console | **none** |

## How to find it, trigger it, and what happens

**Seeing it.** Open the Requests tab in an app whose key resolves to a Free app and scroll to the
end of the list. Under the last request sits a row with the words `Powered by Different Requests`
and a chevron. A board with no requests on it draws no row.

**Not seeing it.** The same screen in an app on Pro. Nothing is drawn and nothing reserves space.

**Tapping it.** "What is this?" is pushed, with the back button. Its **About
Different Requests** row opens `https://differentrequests.com` in the browser, on both platforms.

**Before the answer arrives.** No screen at all: `WornLook` draws a spinner until the configuration
answers, so the badge is in place on the screen's first frame. `hub.configure()`, awaited at launch,
is normally that answer.

## Expectations

### What it does

| Situation | Expected |
|---|---|
| Free app, Requests tab, at least one request | The row, after the last request |
| Free app, Requests tab, no requests | Nothing drawn |
| Pro app | Nothing drawn, no reserved space |
| The configuration has not answered yet | Nothing drawn |
| The configuration read **failed** | Nothing drawn, and the store will ask again |
| Read once per launch | Yes. The client answers a repeat `config` from its first read, so both screens asking costs one round trip |
| VoiceOver | One button, labeled `Powered by Different Requests`, hinted `Opens a page about Different Requests.` |

### What it refuses

| Situation | Expected | Why |
|---|---|---|
| Drawing on a failed read | Never | The two mistakes are not the same size. A badge missing for a moment costs nothing; one on an app paying to be rid of it is a support ticket from a customer who is right |
| A sheet over the SDK's sheet | Never | The page is pushed and the site opens in the browser |
| Guessing from `badgeRemoved` alone | Never | ``BadgeState`` carries how far the asking got, not just the answer |

## The code path

```
DifferentRequestsView ............................... Views/DifferentRequestsView.swift
  │
  ├─ .task { await hub.appConfig.load() }
  │    │
  │    └─ AppConfigStore.load() ...................... Stores/AppConfigStore.swift
  │         ├─ badge.needsReading() == false → return   ← answered already, or reading
  │         ├─ badge = .reading
  │         ├─ try await client.config()
  │         │    └─ throws → badge = .failed(error)   ← draws nothing, retryable
  │         ├─ config = answer.config                 ← also decides which surfaces are reachable
  │         └─ badge = BadgeState(response:) ......... State/BadgeState+Config.swift
  │              └─ config.badgeRemoved ? .bought : .carried
  │
  └─ RequestsScreen → RequestsContent → RequestsList .. Views/RequestsList.swift
       │
       └─ appConfig.badge.isCarried() == false → no section at all
          appConfig.badge.isCarried() == true → Section { PoweredByRow } .. Views/PoweredByRow.swift
            ├─ label: the words, footnote; the list draws the chevron
            └─ tap → push
                 └─ PoweredByPage(appConfig:) ................... Views/PoweredByPage.swift
                      "What is this?" · appConfig.config.app.name, or "This app"
                      About Different Requests → Link → the browser
```

The store is on the hub, not on the screen, because the plan also decides the look every screen is
drawn in.

## The screens

The mockup's Requests screen draws the row: `projects/different-requests/documents/2026-10-09-sdk-redesign-mockup.html`
in the Second Brain. On Pro the row is absent, not blank.

## Platform differences

| | |
|---|---|
| **iOS 26 and macOS 26** | The same words, the same placement, and the same `Link` to the browser |

## Which tests walk the chart

There is no test target — see the server's #144. Walked in the example app on a simulator, against
development.

The walk, and what it answered:

| Step | Answer |
|---|---|
| Open a Free app's board | "Powered by Different Requests" under the title, words only |
| Move that app to Pro with `Entitle` and relaunch | Nothing is drawn |
| Open the board with the network down | Nothing is drawn — an answer that never came is not a Free app |
| Tap the badge on iOS | The site opens over the app and returns where it was |
| 2026-09-26: tap the badge on a newly provisioned Free app ("Badge Walk"), iOS 27 simulator | "What is this?" with "Badge Walk uses Different Requests to hear what you want next." and "Your requests go to the team behind Badge Walk." |
| Tap **About Different Requests** | differentrequests.com in a Safari sheet over the page; closing it returns to the page, and **Done** returns to the board |
| 2026-10-09, iOS 26.0 simulator, a Free app ("Walk Provisioned App") | The row sits 12 pt under the last request, 370 by 44 pt, with a chevron. Tapping it pushed "What is this?" with a back button. A Pro app ("Calls Walk") drew no row. The rows above this one walked the badge under the title, which this replaced |
| macOS | Builds; not walked — the Mac walk waits for the owner's go-ahead |

