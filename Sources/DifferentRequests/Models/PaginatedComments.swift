import Foundation

/// A paginated list of comments, oldest first.
///
/// Use ``cursor`` with ``DifferentRequestsClient/listComments(requestId:limit:cursor:)``
/// to fetch the next page.
public struct PaginatedComments: Sendable {
  /// The comments in this page.
  public let comments: [Comment]
  /// Pass this to the next `listComments` call to get the next page. `nil` means no more pages.
  public let cursor: String?
  /// Whether there are more pages available.
  public let hasMore: Bool
}
