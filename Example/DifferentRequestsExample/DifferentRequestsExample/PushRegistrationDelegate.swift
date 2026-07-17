import UIKit

/// Bridges APNs registration callbacks (which only reach a `UIApplicationDelegate`)
/// back into the SwiftUI world.
///
/// The host app owns `UIApplicationDelegate`, not the SDK, so the raw device
/// token has to be captured here and handed to whatever wants it. `RootView`
/// sets `tokenHandler` once the ``Session`` exists.
final class PushRegistrationDelegate: NSObject, UIApplicationDelegate {
  /// Invoked with the raw APNs token once the system provides it.
  var tokenHandler: ((Data) -> Void)?

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if let tokenHandler {
      tokenHandler(deviceToken)
    }
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("Remote notification registration failed: %@", error.localizedDescription)
  }
}
