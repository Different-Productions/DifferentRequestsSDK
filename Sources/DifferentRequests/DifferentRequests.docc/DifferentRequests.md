# ``DifferentRequests``

Feature request management for iOS apps.

## Overview

DifferentRequests lets your users submit, vote on, and browse feature requests
directly inside your app. The SDK provides both a networking client for full
control and drop-in SwiftUI views for quick integration.

### Quick Start

```swift
import DifferentRequests

let client = DifferentRequestsClient(
  apiKey: "your-api-key",
  baseURL: URL(string: "https://api.example.com")!
)

// Authenticate a user
try await client.authenticate(
  externalUserId: "user-123",
  displayName: "Jane"
)

// Present the request board
DifferentRequestsView(client: client)
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``DifferentRequestsClient``

### Views

- ``DifferentRequestsView``
- ``RequestDetailView``
- ``SubmitRequestView``
- ``VoteControl``
- ``StatusBadge``

### Models

- ``Request``
- ``PaginatedRequests``
- ``User``
- ``Vote``
- ``DeclineReason``

### Enums

- ``SortOrder``
- ``RequestStatus``
- ``RequestSource``
- ``VoteValue``

### State

- ``RequestListModel``
- ``RequestDetailModel``
- ``SubmitRequestModel``

### Errors

- ``DifferentRequestsError``
