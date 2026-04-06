# Getting Started

Add feature requests to your iOS app in minutes.

## Overview

This guide walks you through adding DifferentRequests to your app,
authenticating users, and presenting the built-in request board.

## Add the Package

In Xcode, go to **File → Add Package Dependencies** and enter:

```
https://github.com/Different-Productions/DifferentRequestsSDK
```

Select the `DifferentRequests` library and add it to your target.

Or in `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/Different-Productions/DifferentRequestsSDK",
    from: "0.0.1"
  ),
]
```

## Create a Client

Initialize the client with your API key and server URL. You can find both
in the DifferentRequests console at
[requests.different.productions](https://requests.different.productions).

```swift
import DifferentRequests

let client = DifferentRequestsClient(
  apiKey: "your-api-key",
  baseURL: URL(string: "https://kstb23efj8.execute-api.us-east-1.amazonaws.com")!
)
```

## Authenticate a User

Before a user can submit requests or vote, call ``DifferentRequestsClient/authenticate(externalUserId:displayName:avatarUrl:)``:

```swift
try await client.authenticate(
  externalUserId: currentUser.id,
  displayName: currentUser.name
)
```

The session token is stored internally and injected into subsequent requests
automatically.

## Present the Request Board

The simplest integration is a single view:

```swift
struct FeatureRequestsScreen: View {
  let client: DifferentRequestsClient

  var body: some View {
    DifferentRequestsView(client: client)
  }
}
```

This gives you a full-featured request board with:
- Sortable list (recent / top)
- Status filters (open, planned, in progress, shipped, declined)
- Pull to refresh and infinite scroll
- Voting controls
- Submit new request with duplicate search

## Use the Client Directly

For custom UI, call the client methods directly:

```swift
// List requests
let page = try await client.listRequests(sort: .top, limit: 10)
for request in page.requests {
  print("\(request.title): \(request.score) votes")
}

// Submit a request
let newRequest = try await client.submitRequest(
  title: "Dark mode",
  body: "Add a dark mode option to the app."
)

// Vote
let vote = try await client.vote(requestId: newRequest.id, value: .upvote)
```

## Handle Errors

All client methods throw ``DifferentRequestsError``:

```swift
do {
  let request = try await client.getRequest(id: "abc-123")
} catch DifferentRequestsError.notFound(let message) {
  print("Not found: \(message)")
} catch DifferentRequestsError.rateLimited(let retryAfter) {
  print("Rate limited. Retry in \(retryAfter) seconds.")
} catch DifferentRequestsError.merged(let targetId) {
  print("Request was merged into \(targetId)")
}
```
