# ``DifferentRequests``

Feature request management for iOS apps.

## Overview

DifferentRequests lets your users submit, vote on, and browse feature requests
directly inside your app. The SDK provides both a networking client for full
control and drop-in SwiftUI views for quick integration.

### Quick Start

```swift
import DifferentRequests

let client = DifferentRequestsClient(apiKey: "your-api-key")

try await client.authenticate(
  externalUserId: "user-123",
  displayName: "Jane"
)

DifferentRequestsView(client: client)
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``DifferentRequestsClient``
- ``DifferentRequestsError``

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
- ``VoteResult``
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
