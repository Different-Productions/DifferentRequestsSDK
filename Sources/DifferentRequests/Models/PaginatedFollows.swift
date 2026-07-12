import Foundation

/// A paginated list of a user's followed requests, most recently followed first.
///
/// Use ``cursor`` with ``DifferentRequestsClient/listFollowedRequests(cursor:limit:)``
/// to fetch the next page.
public struct PaginatedFollows: Sendable {
  /// The follows in this page.
  public let follows: [Follow]
  /// Pass this to the next `listFollowedRequests` call to get the next page. `nil` means no more pages.
  public let cursor: String?
  /// Whether there are more pages available.
  public let hasMore: Bool
}
