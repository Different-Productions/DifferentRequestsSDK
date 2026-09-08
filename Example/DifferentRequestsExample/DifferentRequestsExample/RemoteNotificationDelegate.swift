import DifferentRequests
import SwiftUI
import UIKit
import UserNotifications

/// This app's composition root, and the delegate remote notifications arrive on.
///
/// The two are one object because UIKit builds this before any window is shown and builds it with
/// no arguments — so it is both the first thing that exists and the only thing that can be handed
/// what arrives. Everything long-lived is a `let` here, made once, in dependency order.
///
/// Both halves of push only reach a delegate: the device token arrives on `UIApplicationDelegate`,
/// and what happens to a notification arrives on `UNUserNotificationCenterDelegate`. The SDK cannot
/// take either — a package does not get to be the app delegate — which is why a host app writes
/// this and why the example ships one to copy.
@MainActor
final class RemoteNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  /// Everything this app reads and writes through. Built here and nowhere else.
  let session = Session(hub: DifferentRequestsHub(client: DemoConfig.client))

  /// Where the server puts the request id. Its own key beside `aps`, because `aps` belongs to Apple
  /// and everything else in the payload belongs to the app.
  private static let requestIDKey = "requestID"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set before anything can arrive. A notification tapped from the cold-launch state is delivered
    // as soon as the center has a delegate, so installing one later loses it.
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  // MARK: - Registering

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task { await session.registerDevice(tokenData: deviceToken) }
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("Remote notification registration failed: %@", error.localizedDescription)
  }

  // MARK: - What arrives

  /// Draws a notification that lands while the app is open.
  ///
  /// Without this, iOS shows nothing at all for the app that is already frontmost — it assumes the
  /// app is showing the news itself. This one is not, so it asks for the banner.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    await session.refreshUnreadCount()
    return [.banner, .list, .sound]
  }

  /// Somebody tapped one, so the inbox opens.
  ///
  /// The inbox rather than the board: they tapped news about a request they follow, and the board is
  /// a list of everything, where they would have to find it again themselves.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let payload = response.notification.request.content.userInfo
    if let requestID = payload[Self.requestIDKey] as? String {
      NSLog("Opened from a notification about %@", requestID)
    }
    session.show(.inbox)
  }
}
