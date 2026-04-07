import Foundation

/// Vote direction for ``DifferentRequestsClient/vote(requestId:value:)``.
public enum VoteValue: Int, Sendable {
  /// Upvote (+1).
  case upvote = 1
  /// Downvote (-1).
  case downvote = -1
  /// Remove an existing vote.
  case remove = 0
}
