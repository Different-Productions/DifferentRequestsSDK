# ``DifferentRequests``

A feature request board, inside your app.

## Overview

Your users ask for things, vote on what other people asked for, and read what
shipped — without leaving your app and without making an account. You build one
``DifferentRequestsHub`` at launch, hold it, and hand it to the screens.

Every type this SDK sends and receives is generated from the wire contract, so
the board here and the board your API serves cannot describe different things.

### Quick start

```swift
import DifferentRequests
import SwiftUI

@main
struct MyApp: App {
  // Built once, held for the life of the app. A SwiftUI view is rebuilt on
  // every redraw above it, and the board's page cannot be.
  private let requests = DifferentRequestsHub(
    client: DifferentRequestsClient(appKey: "your-app-key", baseURL: SecureBaseURL(service: .production)),
    emptyBoard: EmptyBoard(),
    notificationPermission: .askedBySdk
  )

  var body: some Scene {
    WindowGroup {
      // Tabs, each with its own NavigationStack. Do not wrap it in one.
      DifferentRequestsView(hub: requests)
    }
  }
}
```

Reading the board needs only your app key. Voting, asking and commenting act on
behalf of a person, so they need a session — see <doc:GettingStarted>.

## Topics

### Essentials

- <doc:GettingStarted>
- ``DifferentRequestsHub``
- ``DifferentRequestsClient``
- ``DifferentRequestsError``
- ``DifferentRequestsFault``

### Your app's choices

- ``EmptyBoard``
- ``NotificationPermission``

### Screens

- ``DifferentRequestsView``
- ``RequestDetailView``
- ``SubmitRequestView``
- ``RoadmapView``
- ``ChangelogView``
- ``InboxView``

### Pieces

- ``StatusBadge``
- ``VoteControl``

### Pointing it somewhere

- ``SecureBaseURL``
- ``DifferentRequestsService``
- ``LastCall``
