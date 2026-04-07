import Foundation

/// A recorded vote on a request.
public struct Vote: Sendable {
  /// Unique identifier.
  public let id: String
  /// The request this vote is on.
  public let requestId: String
  /// The user who voted.
  public let userId: String
  /// The vote value: 1 (upvote), -1 (downvote).
  public let value: Int
  /// When the vote was cast.
  public let createdAt: Date
}
