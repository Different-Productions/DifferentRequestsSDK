import Foundation

/// A paginated list of a user's in-app inbox, most recent first.
///
/// Use ``cursor`` with ``DifferentRequestsClient/listNotifications(limit:cursor:)``
/// to fetch the next page.
public struct PaginatedNotifications: Sendable {
  /// The notifications in this page.
  public let notifications: [AppNotification]
  /// Pass this to the next `listNotifications` call to get the next page. `nil` means no more pages.
  public let cursor: String?
  /// Whether there are more pages available.
  public let hasMore: Bool
}
