import Foundation

/// Sort order for request listings.
///
/// Used with ``DifferentRequestsClient/listRequests(sort:status:limit:cursor:)``
/// to control how requests are ordered.
public enum SortOrder: String, Sendable {
  /// Most recently created first.
  case recent
  /// Highest score first.
  case top
}
