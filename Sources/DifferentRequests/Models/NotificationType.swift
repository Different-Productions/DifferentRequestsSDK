import Foundation

/// Kind of event a notification was raised for.
public enum NotificationType: String, Sendable {
  /// A followed request's status changed (e.g. shipped).
  case statusChange = "status_change"
  /// A new comment on a followed request.
  case comment
  /// An official team reply on a followed request.
  case officialReply = "official_reply"
  /// A changelog entry published, resolving a followed request.
  case changelogPublished = "changelog_published"
}
