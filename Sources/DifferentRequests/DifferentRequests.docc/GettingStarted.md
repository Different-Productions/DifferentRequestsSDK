# Getting Started

From an empty project to a board your users can post to.

## Overview

Four steps: add the package, build the hub, sign your person in, show a screen.
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
    from: "0.11.0"
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
  client: .make(appKey: "your-app-key"),
  appearance: .standard
)
```

``Appearance/standard`` is the SDK's own look. Pass an ``Appearance`` with your
app's accent and a system font design to have every screen wear your app instead.

A SwiftUI view is a value that is thrown away and rebuilt whenever anything
above it redraws. A hub built inside a view would take the board's page, the
search text and a half-written request with it every time.

Production is where it points when you say nothing. A staging server takes a
``SecureBaseURL``, which refuses anything that is not `https` rather than
letting an app ship talking over plain text:

```swift
@main
struct MyApp: App {
  private let requests = DifferentRequestsHub(
    client: .make(
      appKey: "your-app-key",
      baseURL: SecureBaseURL(literal: "https://staging.example.com")
    ),
    appearance: .standard
  )

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        DifferentRequestsView(hub: requests)
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
app, not a person — which is what ``DifferentRequestsClient/createSession(externalID:email:displayName:traits:proof:)``
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
    traits: ["plan": currentUser.plan],
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
  traits: ["plan": currentUser.plan],
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

Every screen takes the hub, and every screen belongs inside a `NavigationStack`
your app owns — that stack is what gives it a title bar, a search field, and
somewhere to push a request's detail onto.

```swift
struct FeatureRequestsScreen: View {
  let requests: DifferentRequestsHub

  var body: some View {
    NavigationStack {
      DifferentRequestsView(hub: requests)
    }
  }
}
```

That is the board: a ranking control, status filters, search, pull to refresh,
infinite scroll, voting, and a composer. ``RoadmapView``, ``ChangelogView`` and
``InboxView`` are the other three, and all four take the same hub.

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

## Handle errors

Every client method throws ``DifferentRequestsError``. The one worth branching
on is `api`, which carries what the server actually said:

```swift
do {
  let answer = try await requests.client.request(id: "req_4f2a")
  print(answer.request.title)
} catch let error as DifferentRequestsError {
  switch error {
  case .api(let refusal):
    // What the server refused, and why. Written for you, not for your users.
    logger.error("DifferentRequests refused: \(refusal.message)")
  case .networkError:
    // Worth a retry. Everything else is not.
    logger.error("DifferentRequests could not be reached")
  default:
    logger.error("DifferentRequests: \(error.localizedDescription)")
  }
}
```

The screens in this package already do this. You only need it when you are
calling the client yourself.
