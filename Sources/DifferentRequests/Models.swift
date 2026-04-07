import Foundation

// MARK: - Enums

/// Sort order for request listings.
public enum SortOrder: String, Sendable {
  case recent
  case top
}

/// Status of a feature request.
public enum RequestStatus: String, Sendable {
  case open
  case planned
  case inProgress = "in_progress"
  case shipped
  case declined
}

/// Source of a feature request.
public enum RequestSource: String, Sendable {
  case sdk
  case console
}

/// Vote direction.
public enum VoteValue: Int, Sendable {
  case upvote = 1
  case downvote = -1
  case remove = 0
}

// MARK: - Models

/// A feature request.
public struct Request: Sendable, Identifiable, Hashable {
  public let id: String
  public let appId: String
  public let authorId: String?
  public let title: String
  public let body: String
  public let status: RequestStatus
  public let source: RequestSource
  public let score: Int
  public let mergedIntoId: String?
  public let declineReason: String?
  public let declineReasonId: String?
  public let declineReasonLabel: String?
  public let authorDisplayName: String
  public let authorExternalUserId: String?
  public let authorAvatarUrl: String?
  public let createdAt: Date
  public let updatedAt: Date
}

/// A paginated list of requests.
public struct PaginatedRequests: Sendable {
  public let requests: [Request]
  public let cursor: String?
  public let hasMore: Bool
}

/// An authenticated SDK user.
public struct User: Sendable {
  public let userId: String
  public let sessionToken: String
  public let externalUserId: String
  public let displayName: String
  public let avatarUrl: String?
}

/// The result of a vote operation, including the updated score.
public struct VoteResult: Sendable {
  /// The confirmed vote record, or `nil` if the vote was removed.
  public let vote: Vote?
  /// The request's updated score after this vote.
  public let newScore: Int
}

/// A recorded vote on a request.
public struct Vote: Sendable {
  public let id: String
  public let requestId: String
  public let userId: String
  public let value: Int
  public let createdAt: Date
}

/// A decline reason configured for an app.
public struct DeclineReason: Sendable, Identifiable {
  public let id: String
  public let appId: String
  public let label: String
  public let isDefault: Bool
}
