/// Who asks the person for notification permission: the SDK, or the host app.
///
/// Set once on ``DifferentRequestsHub``. Either way the host app's delegate still receives the
/// device token and registers it through
/// ``DifferentRequestsClient/registerDevice(tokenData:environment:)``.
///
/// - ``askedBySdk``: after a person's first vote or follow, the SDK offers its "Get notified when
///   this request changes?" card, and **Turn on notifications** brings up Apple's prompt.
/// - ``askedByApp``: the host app asks for permission itself, when it chooses. The SDK never offers
///   its card and never brings up Apple's prompt.
extension NotificationPermission {

  /// Whether the SDK may offer its card and bring up Apple's prompt. Only a host app that chose
  /// ``askedBySdk`` lets it.
  func sdkAsks() -> Bool {
    switch self {
    case .askedBySdk:
      return true
    case .askedByApp, .unspecified, .UNRECOGNIZED:
      return false
    }
  }
}
