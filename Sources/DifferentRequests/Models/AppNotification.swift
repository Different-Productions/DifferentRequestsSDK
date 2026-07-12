import Foundation

/// An in-app notification, raised by the async fan-out worker off a status
/// change or a new comment on a request the user follows.
///
/// Named `AppNotification`, not `Notification`, to avoid colliding with
/// Foundation's own `Notification` (the NSNotificationCenter type), which
/// every file in this SDK already has in scope via `import Foundation`.
///
/// Never written synchronously by whatever triggered it — expect a short,
/// unspecified delay between the underlying event and this appearing in
/// ``DifferentRequestsClient/listNotifications(limit:cursor:)``.
public struct AppNotification: Sendable, Identifiable, Equatable {
  /// Unique identifier.
  public let id: String
  /// The request this notification is about.
  public let requestId: String
  /// What kind of event raised this notification.
  public let type: NotificationType
  /// New status — present only for a ``NotificationType/statusChange`` notification.
  public let status: String?
  /// Source comment — present only for a ``NotificationType/comment``/``NotificationType/officialReply`` notification.
  public let commentId: String?
  /// Whether the caller has marked this notification read.
  public let read: Bool
  /// When the underlying event happened.
  public let createdAt: Date
}
