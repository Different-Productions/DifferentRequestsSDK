import Foundation
import UserNotifications

/// Push-notification permission helper.
///
/// The SDK does not own `UIApplicationDelegate` lifecycle — that belongs to
/// the host app. This type only wraps the permission prompt; it does not
/// register the device with APNs.
///
/// Integration contract:
/// 1. After the user is authenticated (``DifferentRequestsClient/authenticate(externalUserId:displayName:avatarUrl:email:traits:)``),
///    call ``requestPushAuthorization()``.
/// 2. If it returns `true`, the host app must itself call
///    `UIApplication.shared.registerForRemoteNotifications()` — this is a
///    UIApplication-level call the SDK cannot make on the host app's behalf.
/// 3. When APNs hands the token back via the host app's own
///    `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
///    delegate callback, forward that `Data` to
///    ``DifferentRequestsClient/registerDevice(tokenData:)``.
public enum PushNotifications {
  /// Requests alert/badge/sound push notification authorization from the user.
  ///
  /// This only requests permission — it does not call
  /// `UIApplication.shared.registerForRemoteNotifications()`. The host app
  /// must make that call itself after this method returns `true`.
  ///
  /// A deliberate denial and a failed request are distinct outcomes: a denial
  /// is a normal `false` return, whereas a request that could not complete
  /// throws. Collapsing both into `false` would hide transient failures a
  /// caller may want to retry, so they are kept separate here.
  ///
  /// - Returns: `true` if the user granted permission, `false` if the user
  ///   denied it.
  /// - Throws: The error thrown by the system authorization request when it
  ///   could not be completed.
  public static func requestPushAuthorization() async throws -> Bool {
    let center = UNUserNotificationCenter.current()
    return try await requestAuthorization {
      try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
  }

  /// The authorization core with its system dependency injected, so the
  /// grant/deny/throw contract is exercisable without a real
  /// `UNUserNotificationCenter`. Returns the granted flag unchanged and lets a
  /// request failure propagate rather than masking it as a denial.
  static func requestAuthorization(
    _ request: () async throws -> Bool
  ) async throws -> Bool {
    try await request()
  }
}
