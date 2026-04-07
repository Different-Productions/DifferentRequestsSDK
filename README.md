# DifferentRequests SDK

Feature request management for iOS apps. Let your users submit, vote on, and browse feature requests directly inside your app.

## Installation

Add the package in Xcode: **File > Add Package Dependencies**

```
https://github.com/Different-Productions/DifferentRequestsSDK
```

Or in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/Different-Productions/DifferentRequestsSDK", from: "0.1.0"),
]
```

## Quick Start

```swift
import DifferentRequests

// 1. Create the client with your API key
let client = DifferentRequestsClient(apiKey: "your-api-key")

// 2. Authenticate your user
try await client.authenticate(
  externalUserId: currentUser.id,
  displayName: currentUser.name
)

// 3. Show the request board
DifferentRequestsView(client: client)
```

That's it. Your users can now browse, submit, and vote on feature requests.

## Get Your API Key

Sign up at [requests.different.productions](https://requests.different.productions), create an organization, and copy your API key.

## Drop-in Views

The SDK provides ready-to-use SwiftUI views:

- **`DifferentRequestsView`** — Full request board with sort, filter, search, pagination, and voting
- **`RequestDetailView`** — Single request with full detail and voting
- **`SubmitRequestView`** — Form with title, description, and duplicate detection
- **`VoteControl`** — Reusable upvote/downvote component

## Client API

For custom UI, use the client directly:

```swift
// List requests
let page = try await client.listRequests(sort: .top, limit: 10)

// Submit a request
let request = try await client.submitRequest(title: "Dark mode", body: "Please add dark mode")

// Vote
let result = try await client.vote(requestId: request.id, value: .upvote)

// Search
let matches = try await client.searchRequests(query: "dark mode")
```

## Error Handling

```swift
do {
  let request = try await client.getRequest(id: "abc-123")
} catch let error as DifferentRequestsError {
  switch error {
  case .notAuthenticated:
    // Call authenticate() first
  case .notFound(let message):
    // Request doesn't exist
  case .rateLimited(let retryAfter):
    // Wait retryAfter seconds
  case .merged(let targetId):
    // Request was merged into targetId
  default:
    break
  }
}
```

## Requirements

- iOS 18+
- macOS 15+
- Swift 6.0+

## Example App

See the `Example/` directory for a complete Xcode project showing how to integrate the SDK.

## License

MIT
