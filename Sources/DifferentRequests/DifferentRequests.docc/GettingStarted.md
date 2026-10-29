# Getting Started

From an empty project to a board your users can post to.

## Overview

Four steps: add the package, build and configure the hub, sign your person in, show a screen.
Only the last two involve any decisions.

## Add the package

In Xcode: **File → Add Package Dependencies**, and enter:

```
https://github.com/Different-Productions/DifferentRequestsSDK
```

Or in `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/Different-Productions/DifferentRequestsSDK",
    from: "0.16.0"
  ),
]
```

## Build the hub

``DifferentRequestsHub`` is what every screen reads from, and your app owns it.
Build one where you build everything else you keep, and hold it for the life of
the process.

```swift
import DifferentRequests

let requests = DifferentRequestsHub(
  client: DifferentRequestsClient(appKey: "your-app-key", baseURL: SecureBaseURL(service: .production)),
  emptyBoard: EmptyBoard(),
  notificationPermission: .askedBySdk
)
```

Then await ``DifferentRequestsHub/configure()`` at launch. It reads what your
app includes: the screens on your plan, the badge, and the color and font chosen
in the dashboard. No screen draws until that has answered, so nobody sees a color or a
tab that then changes:

```swift
WindowGroup {
  ContentView(requests: requests)
    .task {
      await requests.configure()
    }
}
```

The board's color and font are set on the dashboard's Appearance page, not in
code. On a plan that includes Appearance, they reach every user the next time
your app calls `configure()`, with no app update. Until then, and on a plan
without it, every screen is drawn in the system color and the system's default
font.

`EmptyBoard()` is the SDK's own words for a board with nothing on it. Pass an
``EmptyBoard`` with your own symbol, title, message and button words instead; a
field you leave empty keeps the SDK's.

``NotificationPermission/askedBySdk`` lets the SDK ask for notification permission
after a person's first vote or follow. If your app asks for permission itself, pass
``NotificationPermission/askedByApp`` and the SDK never prompts.

A SwiftUI view is a value that is thrown away and rebuilt whenever anything
above it redraws. A hub built inside a view would take the board's page, the
search text and a half-written request with it every time.

``SecureBaseURL/init(service:)``, given ``DifferentRequestsService/production``, is the live service. A staging server takes a
``SecureBaseURL`` of its own, which refuses anything that is not `https` rather
than letting an app ship talking over plain text:

```swift
@main
struct MyApp: App {
  private let requests = DifferentRequestsHub(
    client: DifferentRequestsClient(
      appKey: "your-app-key",
      baseURL: SecureBaseURL(literal: "https://staging.example.com")
    ),
    emptyBoard: EmptyBoard(),
    notificationPermission: .askedBySdk
  )

  var body: some Scene {
    WindowGroup {
      DifferentRequestsView(hub: requests)
        .task {
          await requests.configure()
        }
    }
  }
}
```

The address is a literal because that is where it belongs: `App` requires a
non-throwing `init()`, and a mistyped constant is a mistake to fix before the
build ships, which is what the trap at launch reports. Where the address
arrives at runtime instead, ``SecureBaseURL/init(_:)`` throws and you handle it.

Your app key is not a secret. It ships inside your binary and identifies the
app, not a person — which is what ``DifferentRequestsClient/createSession(externalID:email:displayName:proof:)``
is for.

## Sign your person in

Reading the board needs only the app key. Voting, asking and commenting act on
behalf of somebody, so they need a session. **Your app already knows who its
users are** — hand over your own identifier rather than making them sign up
again:

```swift
do {
  let signedIn = try await requests.client.createSession(
    externalID: currentUser.id,
    email: currentUser.email,
    displayName: currentUser.name,
    proof: nil
  )
  logger.info("DifferentRequests: signed in as \(signedIn.user.id)")
} catch {
  logger.error("DifferentRequests: \(error.localizedDescription)")
}
```

The same `externalID` returns the same person on a new device, which is what
carries someone's votes across a reinstall. Email and display name are both
optional: pass `nil` for either and the board still works, with requests from
that person rendering as anonymous.

The session token is held by the client and sent on every call that needs one.

**A refusal here is yours to read, never your user's.** The message says what to
fix — a missing proof, an expired one, a key that has been replaced — and none
of it is something the person holding the phone can act on. Log it. The board
still reads with the app key alone, and asking, voting and commenting are not
offered until somebody is signed in.

## Vouch for a person

`proof: nil` is right until you ask for a signing secret. Your app key names
your app, not a person: it ships inside your binary, so anybody who installs
your app can read it and ask for a session as anyone whose identifier they can
guess.

Give your app a signing secret — Console, your app, Key — and your own backend
says who each person is. **Once an app has a secret, every session for it needs
a proof**, the people who already have accounts included.

Sign the identifier and an expiry with the secret, **on your backend**, and hand
the app what comes back. Anywhere that can do HMAC-SHA256 can do this:

```swift
let expiresAt = Int(Date().addingTimeInterval(300).timeIntervalSince1970)
let signature = HMAC<SHA256>.authenticationCode(
  for: Data("\(externalID)\n\(expiresAt)".utf8),
  using: SymmetricKey(data: Data(signingSecret.utf8))
)
```

Spell those bytes URL-safe base64 — standard base64 with `-` for `+`, `_` for
`/`, and the padding dropped — and send both halves down to the app, which
carries them as they are:

```swift
let signedIn = try await requests.client.createSession(
  externalID: currentUser.id,
  email: currentUser.email,
  displayName: currentUser.name,
  proof: DRIdentityProof(
    signature: vouched.signature,
    expiresAt: Date(timeIntervalSince1970: TimeInterval(vouched.expiresAt))
  )
)
```

A proof lasts as long as you say, up to an hour. Sign a fresh one when somebody
opens your app rather than storing one on the device: the secret never reaches
the device, so the app cannot make one and nothing on it is worth stealing.

## Show a screen

Every screen takes the hub. ``DifferentRequestsView`` is all of them at once:
tabs for Requests and Inbox, and for Roadmap and What's New where your plan
includes them, each with its own `NavigationStack`. Present it in a sheet, and do not wrap it in a stack.

```swift
.sheet(isPresented: $isShowingRequests) {
  DifferentRequestsView(hub: requests)
}
```

The Requests tab is the board: filter and sort in one menu, search, pull to
refresh, infinite scroll, voting, and the new request form. ``RoadmapView``,
``ChangelogView`` and ``InboxView`` can also be shown alone, each inside a
`NavigationStack` your app owns, and take the same hub.

## Open it without the wait

The board's first page is a round trip, so a screen that starts one when it
appears shows a spinner for the length of it. If you know it is about to be
opened — a settings row, a button pinned to a screen — read it while the reader
is still looking at something else:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  Task { await requests.readTheBoardBeforeItIsShown() }
}
```

It draws rows on the first frame after that. Call it as often as you like: a
board already read is not read again.

## Tell it when a push arrives

Every push carries the request it is about under `requestID`. Hand it to
``DifferentRequestsHub/heardThatARequestChanged(requestID:)`` when a push lands
and when someone taps one, and a request already open, the board and the Inbox
badge read the change at once.

```swift
func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification
) async -> UNNotificationPresentationOptions {
  if let requestID = notification.request.content.userInfo["requestID"] as? String {
    await requests.heardThatARequestChanged(requestID: requestID)
  }
  return [.banner, .list, .sound]
}
```

## Handle errors

Every client method throws ``DifferentRequestsError``. Branch on its
``DifferentRequestsError/reason``. The one worth reading closely is
``DifferentRequestsFault/api``, where ``DifferentRequestsError/apiError`` holds
what the server actually said. ``DifferentRequestsError/message`` describes any
failure for your logs:

```swift
do {
  let answer = try await requests.client.request(id: "req_4f2a")
  print(answer.request.title)
} catch let error as DifferentRequestsError {
  switch error.reason {
  case .api:
    // What the server refused, and why. Written for you, not for your users.
    logger.error("DifferentRequests refused: \(error.apiError.message)")
  case .networkError:
    // Worth a retry. Everything else is not.
    logger.error("DifferentRequests could not be reached")
  case .unspecified, .notAuthenticated, .unreadableError, .decodingFailed,
    .incompleteResponse, .canceled, .notAnHTTPResponse, .invalidBaseURL,
    .unspellableMethod, .UNRECOGNIZED:
    logger.error("DifferentRequests: \(error.message)")
  }
}
```

``DifferentRequestsError/isNotFound()``, ``DifferentRequestsError/isRefusal()``
and ``DifferentRequestsError/retryAfterSeconds()`` answer the three questions a
retry depends on, from the server's own answer.

The screens in this package already do this. You only need it when you are
calling the client yourself.
