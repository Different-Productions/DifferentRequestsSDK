# DifferentRequests SDK

Feature request management for iOS and macOS apps. Let your users submit, vote on, and browse
feature requests directly inside your app.

## Installation

Add the package in Xcode: **File > Add Package Dependencies**

```
https://github.com/Different-Productions/DifferentRequestsSDK
```

Or in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/Different-Productions/DifferentRequestsSDK", branch: "master"),
]
```

`master` speaks protobuf to the current API and is not tagged yet. The newest tag, `0.6.2`, is the
JSON client that came before it and does not talk to that API.

## Quick Start

Build one hub where your app builds everything else it keeps, and hand it to the screens. The
screens hold no state of their own — SwiftUI throws them away and rebuilds them on every redraw, and
the board, the search text and the half-typed request have to survive that.

```swift
import DifferentRequests
import SwiftUI

@main
struct MyApp: App {
  // 1. Built once, held for the life of the app.
  private let requests = DifferentRequestsHub(client: .make(appKey: "your-app-key"))

  var body: some Scene {
    WindowGroup {
      // 2. The NavigationStack is yours. Every SDK screen needs one.
      NavigationStack {
        DifferentRequestsView(hub: requests)
      }
    }
  }
}
```

Reading the board needs only the app key. Voting, asking and commenting act on behalf of a person,
so they need a session — exchange your own identifier for one at launch:

```swift
do {
  let signedIn = try await requests.client.createSession(
    externalID: currentUser.id,
    email: currentUser.email,
    displayName: currentUser.name,
    traits: ["tier": currentUser.tier]
  )
  logger.info("DifferentRequests: signed in as \(signedIn.user.id)")
} catch {
  logger.error("DifferentRequests: \(error.localizedDescription)")
}
```

The same `externalID` returns the same person on a new device, which is what carries someone's votes
across a reinstall. `Example/DifferentRequestsExample/DifferentRequestsExample/Session.swift` is
this, with the failure shown on screen instead of logged.

## Get Your App Key

Sign up at [app.differentrequests.com](https://app.differentrequests.com), create an organization,
and copy your app key. It identifies your app to the API — it is not a per-person credential, which
is what `createSession` is for.

## Drop-in Views

Every one of these takes the hub you built, and every one of them belongs inside a `NavigationStack`
your app owns — that stack is what gives them a title bar, a search field, and somewhere to push to.

- **`DifferentRequestsView(hub:)`** — The board: ranked by demand, searchable, paged, votable, and
  the way in to asking for something new from every state it can be in
- **`RequestDetailView(hub:requestID:)`** — One request, its thread, its vote and its follow. Open it
  straight from a notification or a deep link
- **`RoadmapView(hub:)`** — Planned, building, shipped, as a section per column
- **`ChangelogView(hub:)`** — What shipped, newest first
- **`InboxView(hub:)`** — Status changes, replies and merges on what someone follows
- **`SubmitRequestView(hub:)`** — The composer sheet, if you want your own way in to it. Call
  `hub.beginSubmission()` before presenting it
- **`VoteControl(voteCount:voted:isWriting:toggle:)`** — The vote button on its own, for your own
  rows. `isWriting` is what makes it go inert while a vote is in flight, instead of taking a tap
  nothing comes of

Every one of these screens draws its four outcomes from one state on its store — reading, failed,
read-and-empty, read-and-here-it-is — and says so when a write does not land. A vote, a follow, a
comment or a notification marked read that the server refuses puts a line on screen next to the
control that was tapped. Nothing fails quietly.

`RoadmapView` and `ChangelogView` are plan-gated. Read `client.config()` once at launch and offer
them only where `roadmapEnabled` and `changelogEnabled` say so: a tab that answers `PLAN_REQUIRED`
when tapped tells someone the app is broken when nothing is.

## Client API

For custom UI, use the client directly. Every call takes and returns the contract's own types.

```swift
// A page of the board — statuses empty means everything still on it
let page = try await client.requests(statuses: [], sort: .top, query: nil, cursor: nil)

// The next page, from what the last one handed back
let next = try await client.requests(
  statuses: [], sort: .top, query: nil, cursor: page.nextCursor
)

// Search: the same rpc, the same ranking, the same page shape
let matches = try await client.requests(
  statuses: [], sort: .top, query: "dark mode", cursor: nil
)

// One request, and its thread
let one = try await client.request(id: "abc-123")
let thread = try await client.comments(requestID: one.request.id, cursor: nil)

// Write
let filed = try await client.submit(title: "Dark mode", body: "Please add dark mode")
let voted = try await client.vote(requestID: filed.request.id)
let followed = try await client.follow(requestID: filed.request.id)
let posted = try await client.comment(requestID: filed.request.id, body: "Yes please")
```

## Error Handling

The server's half of a failure is a `DRApiError` carried through unflattened, so `code` is the value
the server sent rather than a guess made from an HTTP status. That message is written for whoever is
reading a log and may name internals — the SDK's own screens never show it to anyone, and neither
should yours.

```swift
do {
  let answer = try await client.request(id: "abc-123")
  show(answer.request)
} catch let error as DifferentRequestsError {
  if let seconds = error.retryAfterSeconds {
    // The server said to wait, and said how long.
    schedule(after: seconds)
  }
  if case .api(let apiError) = error, apiError.code == .planRequired {
    // This surface is not on the tenant's plan.
  }
  logger.error("DifferentRequests: \(error.localizedDescription)")
}
```

`notAuthenticated(rpc)` is thrown before anything is sent, from the audience the contract declares
for that rpc: an rpc that acts for a person is refused locally rather than costing a round trip to
be told 401.

## Requirements

- iOS 18+
- macOS 15+
- Swift 6.0+

## Example App

See the `Example/` directory for a complete Xcode project showing how to integrate the SDK.

## License

MIT
