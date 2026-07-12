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
  /// - Returns: `true` if the user granted permission, `false` if denied or
  ///   the request failed.
  public static func requestPushAuthorization() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
      return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    } catch {
      return false
    }
  }
}
