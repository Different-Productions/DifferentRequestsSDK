# Changelog

Every released version, newest first. Versions are tags on the public repository,
`Different-Productions/DifferentRequestsSDK`.

## 0.15.1 — 2026-10-26

No source changes to make.

- Requests opened before your app's configuration has loaded, or after it failed to load, now
  has its close button. In 0.15.0 that sheet could not be closed until the configuration answered.

## 0.15.0 — 2026-10-26

The screens are redrawn from Apple's Human Interface Guidelines, on one set of named sizes, text
styles and colors.

**Four source changes to make.**

1. Stop wrapping `DifferentRequestsView` in a `NavigationStack`. It is now a tab bar, and each tab
   brings its own stack. Present it in a sheet as before.
2. `SubmitRequestView` is a pushed screen and no longer brings a `NavigationStack`. If you present
   it yourself, push it: `.navigationDestination(isPresented:) { SubmitRequestView(hub:) }`. It
   draws its own Cancel and Send.
3. `RoadmapView(hub:)` and `ChangelogView(hub:)` replace passing `nil` for `isShowingRequests`.
   Passing a binding still gives an empty screen its **See requests** button.
4. Await `requests.configure()` at launch, before your first window. It reads your plan's
   screens, the badge and the dashboard's tint. No screen draws until it has answered, so a screen
   opened first shows a spinner, never a color or a tab that then changes.

- `DifferentRequestsView` holds Requests and Inbox as tabs, and Roadmap and What's New where your
  plan includes them, with the system search button beside them. The More menu is gone.
- Filter and sort are one bar button with a system menu. The chip bar is gone.
- Voting on a row is a tile that fills with your accent once voted, and flips the moment it is
  tapped. On a request's own screen, Vote and Follow are two buttons of one size.
- Status is a symbol and a word in the label color, never a colored pill.
- Screens you present alone draw the system close button where they drew Done.
- The notification card has one button, which opens Apple's prompt, and a Dismiss button.
- After Send, the new request's own screen opens. The "Your request is posted" strip is gone.
- "Powered by Different Requests" is one row after the last request, on Requests only. Its page is
  pushed, and its link opens the browser.
- A label drawn on your accent is black or white, whichever measures 4.5 to 1 against it.
- A Pro app's tint can be chosen in the dashboard's Appearance tab, one color for light mode and
  one for dark mode. It wins over `Appearance(accent:)` and reaches the app the next time it calls
  `configure()`, with no app update. Needs contract 0.42.0.
- In the Inbox, an unread update has a dot and a heavier headline, and the dot is no longer a
  button. An update is read by opening it, by its swipe action, or by Mark all as read. The Inbox
  tab shows the unread count.
- The Roadmap heads each status with its name and a spelled-out count, and shows votes as words.
- What's New draws each update as one card, with a row per request it answers.
- An empty board's own symbol is `bubble.left.fill`. `EmptyBoard(symbol:…)` still sets yours.

## 0.14.0 — 2026-09-30

**Two source changes to make.**

1. Remove `traits:` from `DifferentRequestsClient.createSession(externalID:email:displayName:traits:proof:)`.
   It is now `createSession(externalID:email:displayName:proof:)`. The SDK sends nothing about
   your users' standing inside your app.
2. `DifferentRequestsClient.make(appKey:)` and `make(appKey:baseURL:)` are replaced by
   `init(appKey:baseURL:)`. Write `DifferentRequestsClient(appKey: "…", baseURL: .production)`,
   or pass your staging `SecureBaseURL`. `init(appKey:baseURL:session:)` is gone too: the client
   owns its own `URLSession`.

- The privacy manifest no longer declares "Other data", because the SDK no longer sends any.

## 0.13.0 — 2026-09-26

**One source change to make.**

1. `DifferentRequestsHub` takes `notificationPermission:`. Pass `.askedBySDK` to keep the SDK's
   "Get told when this changes?" card and Apple's prompt, or `.askedByApp` if your app asks for
   permission itself. With `.askedByApp` the SDK never prompts.

## 0.12.0 — 2026-09-26

**Three source changes to make.**

1. `DifferentRequestsHub` takes `emptyBoard:`. Pass `.standard` to keep our words, or an
   `EmptyBoard` with your own.
2. `RoadmapView` and `ChangelogView` take `isShowingRequests:`. Pass a binding that opens your
   requests list, and an empty screen offers **See requests**; pass `nil` for no button.
3. Remove your own Done from Inbox, Roadmap and What's New. They draw one when they are the first
   screen of a sheet, and none when pushed.

- On Pro, the board with nothing on it says what your app wants it to: `EmptyBoard(symbol:title:
  message:button:)`, set once on the hub beside `appearance`. A field left empty uses ours. On Free,
  ours are drawn whatever you set. Searches and filters that find nothing keep our words.
- Every word the SDK draws follows the phone's language: Arabic, French, German, Italian, Japanese,
  Polish, Portuguese (Brazil) and Spanish, with English for the rest. Words your app sends (request
  titles, release notes, your `EmptyBoard`) are drawn as you wrote them.
- **The SDK now asks for notification permission itself.** After a person's first vote or follow,
  on a plan that sends notifications, a "Get told when this changes?" card offers Not now and Turn
  on; Turn on shows Apple's prompt and registers for remote notifications. Stop prompting at launch,
  keep registering where notifications are already allowed, and keep passing the token to
  `registerDevice`. The answer is remembered on the phone in `UserDefaults`, which the privacy
  manifest now declares (reason `CA92.1`).
- After the first vote on a phone, the request says "You'll be told when this changes."
- After sending, the board says "Your request is posted. You're following it." for a few seconds.
- The board sorts from a small menu; the chips only filter by status.
- "Powered by Different Requests" opens a "What is this?" page for your users.
- An empty Roadmap says "Nothing planned yet" instead of three empty columns.
- Every button says its words in sentence case: "Try again", "Show all", "Mark all as read".
- On macOS, the SDK's screens have a minimum size, so a sheet no longer collapses its list.

## 0.11.0 — 2026-09-18

**No source change to make.** What changes is what a Free app is drawn with.

- Your accent and font are a Pro feature. On Free the screens are drawn in the SDK's own look,
  whatever `Appearance` you pass; on Pro, yours, exactly as before. Until the app's configuration has
  answered, yours is drawn.
- The badge reads the contract's `badgeRemoved`, which replaces `showBadge`. **Update from 0.10.0**:
  0.10.0 reads the old flag, which a server on contract 0.38.0 no longer sends, so it draws no badge
  on a Free app.
- `DRAppConfig` names every Pro surface. `pushEnabled` says whether the server will send push
  notifications, and the example app asks for permission only when it will.

## 0.10.0 — 2026-09-17

**One source change to make: `createSession` takes a `proof`.** Pass `nil` until you ask for a
signing secret; nothing else about signing somebody in changes.

- Your own backend can vouch for a person. Give your app a signing secret in the console, sign the
  identifier and an expiry with it, and hand the app what comes back — `DRIdentityProof(signature:
  expiresAt:)` is what carries it. Once an app has a secret, every session for it needs a proof.
- A refused sign-in is written where a developer reads it and drawn nowhere: the reasons are all the
  integration's, and the board still reads with the app key alone.
- The example app signs its own proof from `DIFFERENT_REQUESTS_SIGNING_SECRET`, standing in for a
  backend, and carries on with nobody signed in when the server refuses.

## 0.9.0 — 2026-09-17

**One source change to make: `DifferentRequestsHub(client:)` is now
`DifferentRequestsHub(client:appearance:)`.** Pass `.standard` for the look 0.8.0 had, or an
`Appearance` with your app's accent and a system font design.

- Every screen wears the host app's accent and font design, set once on the hub.
- A control that acts for a person is offered only when somebody is signed in, so a board with no
  session no longer offers a request that can only fail.
- The composer counts against the title limit the contract declares, and a request the server read
  and refused says what to change instead of "try again".
- The board's filter offers only the statuses a board shows.
- A request opened from a notification reads itself again instead of showing the copy it already
  had.
- A request filed a moment ago says so rather than "in 1 second", one vote reads "1 vote", and
  opening a notification marks it read.
- The badge sits under the board's title instead of pinned over the bottom, and the board draws a
  Done button only where something presented it.
- The documentation lives at differentrequests.com/docs; the README points there.
- Pins contract 0.36.0.
- The SDK and the contract moved to private repositories. Host apps fetch the public copy, which
  holds every release tag at the same commit, so nothing about `.package(url:from:)` changes.
- The example app demonstrates the SDK rather than its own screens, and a read is no longer canceled
  by its own answer.
- The SDK ships a privacy manifest declaring what it collects, and refuses a plain `http` base URL.
- `describeIntegration()` says what the SDK is pointed at, for a diagnostics screen.
- A status and a notification are drawn with the words the contract carries, so this package and the
  console cannot name the same thing differently.
- The board survives one request it cannot read, instead of failing whole.
- A free app carries the "Powered by Different Requests" badge.

## 0.8.0 — 2026-08-28

- A duplicate says what it is, and names the request it was folded into.
- The documentation describes the SDK that exists.

## 0.7.0 — 2026-08-28

**A total break from 0.6.x. Every method was renamed and every model type replaced.** There is no
shim, and 0.6.x does not talk to the current API at all. Move by deleting the old integration and
following the Quick start in the README again.

- The SDK speaks the wire contract instead of describing it a second time in JSON. Every type it
  sends and receives is generated from that contract.
- The host app builds one `DifferentRequestsHub` and hands it to the screens, so a page, a search
  and a half-written request survive a redraw above them.
- The screens the contract describes: board, request detail, composer, roadmap, changelog and inbox.
- A screen asks what the app's plan includes before it draws a surface that needs it, instead of
  drawing one that is refused when tapped.
- A refusal reaches the person who made it: one state per store, and a write that does not land puts
  a line next to the control that was tapped.
- The board can be read before it is shown, so it draws rows on the first frame.
- MIT license stated in the package, as the README already promised.

## 0.6.2 — 2026-07-17

The last JSON client. It does not talk to the current API.
