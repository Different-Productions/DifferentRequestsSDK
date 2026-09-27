/// Who asks the person for notification permission: the SDK, or the host app.
///
/// Set once on ``DifferentRequestsHub``. Either way the host app's delegate still receives the
/// device token and registers it through
/// ``DifferentRequestsClient/registerDevice(tokenData:environment:)``.
public enum NotificationPermission: Sendable, Equatable {

  /// After a person's first vote or follow, the SDK offers its "Get told when this changes?" card,
  /// and **Turn on** brings up Apple's prompt.
  case askedBySDK

  /// The host app asks for permission itself, when it chooses. The SDK never offers its card and
  /// never brings up Apple's prompt.
  case askedByApp
}
