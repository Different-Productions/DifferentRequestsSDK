import Foundation

/// A paginated list of published changelog entries, most recent first.
///
/// Use ``cursor`` with ``DifferentRequestsClient/listChangelog(limit:cursor:)``
/// to fetch the next page.
public struct PaginatedChangelogEntries: Sendable {
  /// The entries in this page.
  public let entries: [ChangelogEntry]
  /// Pass this to the next `listChangelog` call to get the next page. `nil` means no more pages.
  public let cursor: String?
  /// Whether there are more pages available.
  public let hasMore: Bool
}
