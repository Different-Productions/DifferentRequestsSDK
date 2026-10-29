# Being told when a request changes

## What it is and how to trigger it

Two pieces from the owner's rulings of 2026-09-26, both said once to a person who has just shown
they care about a request:

- **Piece 22, the notification card.** After a person's first vote or follow, a card asks
  **"Get notified when this request changes?"** — "You'll get a notification when this request is
  planned, shipped or replied to." — with one button, **Turn on notifications**, which brings up
  Apple's own notification prompt, and a Dismiss button in its corner. Owner ruling 2026-10-09
  (#167): **Not now** is gone, because the card's button should lead only to the system's question.
  Either answer is remembered on this phone, and the card never comes back.
- **Piece 33, the one-time line.** After the first vote on this phone, the request's own screen
  says **"You'll get an update in Inbox when this request changes."** under the vote and follow
  buttons, until the person leaves that screen. It is never said again on this phone.

Trigger: vote for a request (on the board, or on its own screen), or follow one on its own screen.

**The host app decides who asks for notification permission**, set once on `DifferentRequestsHub`
the way `emptyBoard` is:

- `notificationPermission: .askedBySdk` — the SDK offers the card and brings up Apple's prompt, as
  below. The Example app passes this.
- `notificationPermission: .askedByApp` — the app asks for permission itself, when it chooses. The
  SDK never offers the card and never brings up Apple's prompt. Backlog passes this.

With `.askedBySdk`, the card is offered only when all of these hold: the app's plan sends notifications
(`DRAppConfig.pushEnabled`), the card was never answered on this phone, and Apple has not asked
this app yet (`authorizationStatus == .notDetermined`). The host app no longer prompts on launch;
it registers for remote notifications only where they are already allowed, and still hands the
token to `registerDevice(tokenData:environment:)` from its delegate.

## Expectations

| When it works | What the user sees |
|---|---|
| First vote on a request's screen | The vote lands, "You'll get an update in Inbox when this request changes." appears under the buttons, and the card appears in its own section below |
| First follow on a request's screen | The card appears below the request |
| First vote from a board row | The card appears in the list, right under that row |
| Taps the card's Dismiss button | The card goes, and never comes back on this phone |
| Taps **Turn on notifications** | The card goes and Apple's "Would like to send you notifications" prompt comes up. **Allow** registers for remote notifications; the token reaches the host app's delegate |
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
        |  permission.sdkAsks() (from the hub)          NotificationPermission+Asking.swift
        |     .askedByApp -> stop: no card, no prompt
        |  no card up · AppConfigStore.config.pushEnabled ·
        |  UserDefaults "DifferentRequests.notificationOfferAnswered" false ·
        |  UNUserNotificationCenter settings .notDetermined
        v
state.card = .offered(requestID)         proto/differentrequests_sdk_state.proto  NotificationOfferState
        |
        v
NotificationOfferCard                                                         NotificationOfferCard.swift
   Dismiss (DismissButton.swift) -> decline(): answered = true, state = NotificationOfferState()
   Turn on notifications  -> accept():  answered = true, state = NotificationOfferState()
                 requestAuthorization([.alert, .badge, .sound])
                   granted -> UIApplication / NSApplication.registerForRemoteNotifications()
                   threw   -> state.card = .failed(NotificationOfferFailure)  proto: NotificationOfferFailure
        |
        v
Host app delegate receives the token -> registerDevice   RemoteNotificationDelegate.swift · Session.swift
```

## When the news lands

A push, or an inbox read, says a request changed. Every screen holding that request reads it
again, and every Inbox badge draws one count.

| When it works | What the user sees |
|---|---|
| A push lands while the request's own screen is up | The screen reads again: the new status and the team's reply appear without leaving it |
| A push lands, then they go back to Requests | The row shows the new status and comment count |
| A push lands with the sheet up | The Inbox tab's badge goes up by one, and the Inbox list shows the update |
| Any moment | The host app's Inbox row, the sheet's Inbox tab and Mark all as read all read one count |

```
Push lands (willPresent / didReceive)            RemoteNotificationDelegate.swift
        |  await hub.heardThatARequestChanged(requestID:)
        v
NewsAboutRequests.heard(aboutRequest:at: now)    Stores/NewsAboutRequests.swift  (@Observable, NewsState)
        |                                        also written by InboxStore.record (createdAt)
        |                                        and BoardStore.toggleVote (row copied at the same instant)
        +--> RequestDetailView .task(id: news.lastHeard(requestID))
        |       hasNews(about: detail): heard > detail.readAt (stamped when the read was sent)
        |       -> RequestDetailStore.load()
        +--> RequestsScreen .task(id: news.news)
        |       BoardStore.readAgainIfNewer(): any heard > board.copiedAt[id] (stamped when sent)
        |       -> BoardStore.load(), whole board, so rank and narrowing come from the server
        v
hub.loadInbox() -> InboxStore.load()             DifferentRequestsHub.swift · Stores/InboxStore.swift
        |  a read already in flight sets inbox.askedAgain and reads again when it lands
        v
inbox.unreadCount == hub.unreadCount()           read by RequestsTabView .badge, MarkAllReadButton,
                                                 and the example's Session.badgeCount (home row)
```

Nothing is written while a body is built: a body reads the news only to key a task, and the
re-read runs in that task. `BoardState.copied_at` and `InboxState.asked_again` are in
`proto/differentrequests_sdk_screens.proto`.

`NotificationOffer` and `FirstVoteNote` are built once by `DifferentRequestsHub.swift`, with `UserDefaults.standard`, which
`PrivacyInfo.xcprivacy` declares under reason `CA92.1`. The hub hands `NotificationOffer` the
`NotificationPermission` the host app passed to its `init`.

## What was walked

- 2026-09-26, iPhone simulator "DR Calls Walk", iOS 27, local server, freshly installed so Apple had
  not asked yet. On a Pro app, opened "Walk: a plan filed without touching the box" and voted: the
  count went to 1, **Following** turned on, "You'll get an update in Inbox when this request
  changes." appeared under the buttons, and the card appeared below. **Turn on notifications**
  brought up Apple's "Would Like to Send You Notifications"; **Allow** — the app's log then said `Registered device dev_170d…`. Left and
  reopened the request: no line, no card.
- Same simulator, reinstalled, a newly provisioned empty Pro app ("Empty Walk"): filed a request,
  took the vote back and cast it again from the board row — the card appeared right under that row.
  **Not now** put it away. Quit, relaunched, voted again from the row: no card.
- A newly provisioned Free app ("Badge Walk"): a vote from the row drew no card, because Free sends no
  notifications.
- 2026-09-26, fresh iPhone 18 Pro simulator "DR Permission Walk", iOS 27, SDK 0.13.0, development
  server, a newly provisioned Pro app ("Permission Walk"). With `.askedBySdk`: filed "Dark mode for
  the walk", took the vote back and voted again from the row, and the card appeared under the row.
  Reinstalled with the Example set to `.askedByApp`: the vote went 1 → 0 → 1 from the row, and no
  card appeared and no Apple prompt came up.
- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server, a Pro app ("Calls
  Walk"): a vote on a request's own screen drew the card with one button and a Dismiss button, and
  the one-time line under Vote and Follow. **Turn on notifications** put the card away and brought
  up Apple's prompt. The card's Dismiss button was not tapped.
- The owner's real walk: not yet.
