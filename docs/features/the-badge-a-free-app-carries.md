# The badge a free app carries

## What it is

"Powered by Different Requests", under the title on the board and the inbox, in an app whose plan
is Free. Paying makes it disappear, and that is the first thing $10 a month buys.

Three decisions shape it, and all three were taken against a mockup before any code:

**Under the title, not pinned to the bottom.** It is a mark of where the screen came from rather
than an advertisement laid over somebody else's product. A developer who resents it least is the
one most likely to leave it there long enough to pay for its removal.

**A tap opens Safari over the app, not instead of it.** `openURL` hands the reader to Safari and
they have to find their way back — out of an app that is not ours, following a link we put there.
A sheet is dismissed and they are where they were.

**Board and inbox only.** The two screens a reader returns to. On all five it starts reading as
watermarking.

## Surfaces

| Surface | Ships this? |
|---|---|
| Board (`DifferentRequestsView`) | **Yes** — under the title |
| Inbox (`InboxView`) | **Yes** — under the title |
| Roadmap, changelog, request detail | **none** — deliberately. Both are Pro surfaces anyway, so a badge there would only ever draw for an app that cannot open them |
| Composer (`SubmitRequestView`) | **none** — a sheet, and a mark on a form is an advertisement |
| Server | **none** — `show_badge` was already in the contract and already set. Nothing changed |
| Console | **none** |

## How to find it, trigger it, and what happens

**Seeing it.** Open the board or the inbox in an app whose key resolves to a Free app. Under the
navigation title sits a small mark and the words `Powered by Different Requests`.

**Not seeing it.** The same screens in an app on Pro. Nothing is drawn and nothing reserves space.

**Tapping it.** On iOS a Safari sheet rises over the app on `https://differentrequests.com`, and
dismissing it returns the reader exactly where they were. On macOS the default browser opens,
because there is no in-app browser on macOS and opening one is what a Mac app does.

**Before the answer arrives.** Nothing. The badge appears when the configuration answers, which is
the first round trip either screen makes.

## Expectations

### What it does

| Situation | Expected |
|---|---|
| Free app, board or inbox | The badge, under the title |
| Pro app | Nothing drawn, no reserved space |
| The configuration has not answered yet | Nothing drawn |
| The configuration read **failed** | Nothing drawn, and the store will ask again |
| Read once per launch | Yes. The client answers a repeat `config` from its first read, so both screens asking costs one round trip |
| VoiceOver | One button, labelled `Powered by Different Requests`, hinted `Opens the Different Requests website` |

### What it refuses

| Situation | Expected | Why |
|---|---|---|
| Drawing on a failed read | Never | The two mistakes are not the same size. A badge missing for a moment costs nothing; one on an app paying to be rid of it is a support ticket from a customer who is right |
| Leaving the host app on iOS | Never | The sheet is `SFSafariViewController`. `openURL` is the macOS path only |
| Guessing from `showBadge` alone | Never | ``BadgeState`` carries how far the asking got, not just the answer |

## The code path

```
DifferentRequestsView / InboxView
  │
  ├─ .task { await hub.badge.load() }
  │    │
  │    └─ BadgeStore.load() .......................... Stores/BadgeStore.swift
  │         ├─ state.needsReading == false → return   ← answered already, or reading
  │         ├─ state = .reading
  │         ├─ try await client.config()
  │         │    └─ throws → state = .failed(error)   ← draws nothing, retryable
  │         └─ state = BadgeState(response:)
  │              └─ config.showBadge ? .carried : .bought
  │
  └─ PoweredByBadge(badge: hub.badge) ............... Views/PoweredByBadge.swift
       │
       └─ badge.state.isCarried == false → nothing at all
          badge.state.isCarried == true  → Button
            ├─ label: chevron on the accent + the words
            └─ tap
                 ├─ iOS   → isShowingHome = true
                 │            └─ .sheet { SafariSheet(url:) } .. Views/SafariSheet.swift
                 │                 └─ SFSafariViewController
                 └─ macOS → openURL(home)
```

The store is on the hub, not on either screen. Two screens draw it, and a second copy of the answer
is a second thing to keep in step.

## The screens

```
┌─────────────────────────────────┐
│ Requests                    [+] │  ← navigationTitle, toolbar
│ ▲ Powered by Different Requests │  ← here. caption2, tertiary + secondary
├─────────────────────────────────┤
│ [ Top ] [ Open ] [ Planned ]    │  ← BoardFilterBar
├─────────────────────────────────┤
│ ▲12  Dark mode        PLANNED   │
│ ▲ 9  Filter by tag    OPEN      │
└─────────────────────────────────┘

On Pro the second row is absent — not blank, absent. Nothing reserves the space, so a paying app's
board is its own from the title down.
```

## Platform differences

| | |
|---|---|
| **iOS 18+** | `SFSafariViewController` in a `.sheet`, `.ignoresSafeArea()`. The reader never leaves the host app |
| **macOS 15+** | `openURL`. `SFSafariViewController` is UIKit and does not exist here; `SafariSheet.swift` is inside `#if os(iOS)` in full |
| **Both** | The same mark, the same words, the same placement. Only what a tap does differs |

This is the first platform conditional in the package. It is here because the platforms genuinely
differ, not because one of them was awkward.

## Tests that walk this

| Test | What of the path it walks |
|---|---|
| `BadgeTests.aFreeAppCarriesIt` | `showBadge: true` → drawn |
| `BadgeTests.aPayingAppDoesNot` | `showBadge: false` → not drawn |
| `BadgeTests.nothingIsDrawnUntilTheAnswerArrives` | `.unread`, `.reading` and `.failed` all draw nothing — the one that protects a paying customer |
| `BadgeTests.onlyAFailedReadIsRetried` | A failure is asked again; an answer is not |
| `BadgeTests.aFailedReadDrawsNothing` | A real `BadgeStore` against an unreachable base URL: no badge, still retryable |
