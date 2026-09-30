# Being told when a request changes

## What it is and how to trigger it

Two pieces from the owner's rulings of 2026-09-26, both said once to a person who has just shown
they care about a request:

- **Piece 22, the notification card.** After a person's first vote or follow, a card asks
  **"Get told when this changes?"** — "We'll send a notification when it's planned, shipped or
  someone replies." — with **Not now** and **Turn on**. **Turn on** brings up Apple's own
  notification prompt. Either answer is remembered on this phone, and the card never comes back.
- **Piece 33, the one-time line.** After the first vote on this phone, the request's own screen
  says **"You'll be told when this changes."** under the vote and follow buttons, until the person
  leaves that screen. It is never said again on this phone.

Trigger: vote for a request (on the board, or on its own screen), or follow one on its own screen.

**The host app decides who asks for notification permission**, set once on `DifferentRequestsHub`
the way `appearance` and `emptyBoard` are:

- `notificationPermission: .askedBySDK` — the SDK offers the card and brings up Apple's prompt, as
  below. The Example app passes this.
- `notificationPermission: .askedByApp` — the app asks for permission itself, when it chooses. The
  SDK never offers the card and never brings up Apple's prompt. Backlog passes this.

With `.askedBySDK`, the card is offered only when all of these hold: the app's plan sends notifications
(`DRAppConfig.pushEnabled`), the card was never answered on this phone, and Apple has not asked
this app yet (`authorizationStatus == .notDetermined`). The host app no longer prompts on launch;
it registers for remote notifications only where they are already allowed, and still hands the
token to `registerDevice(tokenData:environment:)` from its delegate.

## Expectations

| When it works | What the user sees |
|---|---|
| First vote on a request's screen | The vote lands, "You'll be told when this changes." appears under the buttons, and the card appears in its own section below |
| First follow on a request's screen | The card appears below the request |
| First vote from a board row | The card appears in the list, right under that row |
| Taps **Not now** | The card goes, and never comes back on this phone |
| Taps **Turn on** | The card goes and Apple's "Would like to send you notifications" prompt comes up. **Allow** registers for remote notifications; the token reaches the host app's delegate |
| Leaves the request's screen | The one-time line is gone, and is not said again on this phone |
| Votes again, on any request, later | No line. No card if it was answered, or if Apple already asked |
| The app's plan sends no notifications | No card, ever. The one-time line still shows: the inbox tells them too |
| The host app passed `.askedByApp` | No card and no Apple prompt from the SDK, ever. The one-time line still shows |

| When it fails | Exact error text the user sees |
|---|---|
| Apple's prompt could not be asked (`requestAuthorization` threw) | "Notifications couldn't be turned on. You can turn them on in Settings." with **OK** |
| The vote or follow itself did not land | No card and no line; the write's own notice under the buttons, as before |

## Flow chart

```
Vote / Follow tapped                        RequestDetailView.swift · DifferentRequestsView.swift
        |
        v
RequestDetailStore.toggleVote / toggleFollow   RequestDetailStore.swift
BoardStore.toggleVote                           BoardStore.swift
        |  the write landed and the answer says voted / following
        v
FirstVoteNote.voted(requestID:)          (votes on a request's screen only)   FirstVoteNote.swift
        |  UserDefaults "DifferentRequests.firstVoteNoted" false?
        |     yes -> set true, requestID = this one -> the line is drawn
        v
NotificationOffer.votedOrFollowed(requestID:)                                 NotificationOffer.swift
        |  permission == .askedBySDK (from the hub)             NotificationPermission.swift
        |     .askedByApp -> stop: no card, no prompt
        |  no card up · AppConfigStore.config.pushEnabled ·
        |  UserDefaults "DifferentRequests.notificationOfferAnswered" false ·
        |  UNUserNotificationCenter settings .notDetermined
        v
state = .offered(requestID:)                                                  NotificationOfferState.swift
        |
        v
NotificationOfferCard                                                         NotificationOfferCard.swift
   Not now  -> decline(): answered = true, state = .hidden
   Turn on  -> accept():  answered = true, state = .hidden
                 requestAuthorization([.alert, .badge, .sound])
                   granted -> UIApplication / NSApplication.registerForRemoteNotifications()
                   threw   -> state = .failed(NotificationOfferFailure)       NotificationOfferFailure.swift
        |
        v
Host app delegate receives the token -> registerDevice   RemoteNotificationDelegate.swift · Session.swift
```

Both stores are built once by `DifferentRequestsHub.swift`, with `UserDefaults.standard`, which
`PrivacyInfo.xcprivacy` declares under reason `CA92.1`. The hub hands `NotificationOffer` the
`NotificationPermission` the host app passed to its `init`.

## What was walked

- 2026-09-26, iPhone simulator "DR Calls Walk", iOS 27, local server, freshly installed so Apple had
  not asked yet. On a Pro app, opened "Walk: a plan filed without touching the box" and voted: the
  count went to 1, **Following** turned on, "You'll be told when this changes." appeared under the
  buttons, and the card appeared below. **Turn on** brought up Apple's "Would Like to Send You
  Notifications"; **Allow** — the app's log then said `Registered device dev_170d…`. Left and
  reopened the request: no line, no card.
- Same simulator, reinstalled, a newly provisioned empty Pro app ("Empty Walk"): filed a request,
  took the vote back and cast it again from the board row — the card appeared right under that row.
  **Not now** put it away. Quit, relaunched, voted again from the row: no card.
- A newly provisioned Free app ("Badge Walk"): a vote from the row drew no card, because Free sends no
  notifications.
- 2026-09-26, fresh iPhone 18 Pro simulator "DR Permission Walk", iOS 27, SDK 0.13.0, development
  server, a newly provisioned Pro app ("Permission Walk"). With `.askedBySDK`: filed "Dark mode for
  the walk", took the vote back and voted again from the row, and the card appeared under the row.
  Reinstalled with the Example set to `.askedByApp`: the vote went 1 → 0 → 1 from the row, and no
  card appeared and no Apple prompt came up.
- The owner's real walk: not yet.
