import Foundation

/// A paginated list of requests.
///
/// Use ``cursor`` with ``DifferentRequestsClient/listRequests(sort:status:limit:cursor:)``
/// to fetch the next page.
public struct PaginatedRequests: Sendable {
  /// The requests in this page.
  public let requests: [Request]
  /// Pass this to the next `listRequests` call to get the next page. `nil` means no more pages.
  public let cursor: String?
  /// Whether there are more pages available.
  public let hasMore: Bool
}
