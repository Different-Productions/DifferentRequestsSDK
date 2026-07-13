import Foundation

/// A feature request submitted by a user or created by the team.
///
/// Requests are the core entity in DifferentRequests. They have a title,
/// body, status, score (from votes), and metadata about the author.
public struct Request: Sendable, Identifiable {
  /// Unique identifier.
  public let id: String
  /// The app this request belongs to.
  public let appId: String
  /// The author's user ID, or `nil` for console-created requests.
  public let authorId: String?
  /// The request title.
  public let title: String
  /// The full request description.
  public let body: String
  /// Current status in the triage workflow.
  public let status: RequestStatus
  /// Whether this was submitted via SDK or created in the console.
  public let source: RequestSource
  /// Net vote score (upvotes minus downvotes).
  ///
  /// Mutable so a vote can be reconciled in place from the server's returned
  /// score without refetching the whole list.
  public var score: Int

  /// The current user's own vote on this request (1, -1), or `nil` if they
  /// haven't voted or the client isn't authenticated. Mutable for the same
  /// in-place reconciliation as `score`.
  public var myVote: Int?
  /// Pinned to the top of its roadmap column.
  public let roadmapPinned: Bool
  /// Manual sort position within its roadmap column, ascending.
  public let roadmapOrder: Int
  /// Whether this request appears on the public roadmap.
  public let roadmapVisible: Bool
  /// If merged, the ID of the request this was merged into.
  public let mergedIntoId: String?
  /// Legacy decline reason text.
  public let declineReason: String?
  /// ID of the decline reason, if declined.
  public let declineReasonId: String?
  /// Human-readable decline reason label.
  public let declineReasonLabel: String?
  /// Display name of the author.
  public let authorDisplayName: String
  /// The author's external user ID from your system.
  public let authorExternalUserId: String?
  /// URL to the author's avatar image.
  public let authorAvatarUrl: String?
  /// When the request was created.
  public let createdAt: Date
  /// When the request was last updated.
  public let updatedAt: Date
}
