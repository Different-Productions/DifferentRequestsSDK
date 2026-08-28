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
    from: "0.8.0"
  ),
]
```

## Build the hub

``DifferentRequestsHub`` is what every screen reads from, and your app owns it.
Build one where you build everything else you keep, and hold it for the life of
the process.

```swift
import DifferentRequests

let requests = DifferentRequestsHub(client: .make(appKey: "your-app-key"))
```

A SwiftUI view is a value that is thrown away and rebuilt whenever anything
above it redraws. A hub built inside a view would take the board's page, the
search text and a half-written request with it every time.

Pointing at a staging server takes a base URL, built without force-unwrapping so
a malformed string is a handled error rather than a crash:

```swift
func makeStagingHub(appKey: String) throws -> DifferentRequestsHub {
  guard let baseURL = URL(string: "https://staging.example.com") else {
    throw URLError(.badURL)
  }
  return DifferentRequestsHub(client: .make(appKey: appKey, baseURL: baseURL))
}
```

Your app key is not a secret. It ships inside your binary and identifies the
app, not a person — which is what ``DifferentRequestsClient/createSession(externalID:email:displayName:traits:)``
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
    traits: ["plan": currentUser.plan]
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
