import DifferentRequests
import SwiftUI
import UserNotifications

/// This app's composition root, and the delegate remote notifications arrive on.
///
/// The two are one object because the system builds the app delegate before any window is shown and
/// builds it with no arguments — so it is both the first thing that exists and the only thing that
/// can be handed what arrives. Everything long-lived is a `let` here, made once, in dependency order.
///
/// Both halves of push only reach a delegate: the device token arrives on the app delegate
/// (`UIApplicationDelegate` on iOS, `NSApplicationDelegate` on macOS, one file each), and what
/// happens to a notification arrives on `UNUserNotificationCenterDelegate`. The SDK cannot take
/// either — a package does not get to be the app delegate — which is why a host app writes this and
/// why the example ships one to copy.
@MainActor
final class RemoteNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

  /// Everything this app reads and writes through. Built here and nowhere else.
  let session: Session

  /// Reads the environment once, then builds the client, the hub and the session from what it said.
  ///
  /// The signing secret goes straight to the backend that holds it and into nothing else.
  override init() {
    let environment = ProcessInfo.processInfo.environment
    let settings = DemoSettings(environment: environment)
    session = Session(
      hub: DifferentRequestsHub(
        client: DifferentRequestsClient(appKey: settings.appKey, baseURL: settings.baseURL),
        emptyBoard: settings.emptyBoard,
        notificationPermission: .askedBySdk
      ),
      backend: DemoBackend(signingSecret: DemoVariable.signingSecret.setting(in: environment)),
      settings: settings
    )
    super.init()
  }

  /// Where the server puts the request id. Its own key beside `aps`, because `aps` belongs to Apple
  /// and everything else in the payload belongs to the app.
  private static let requestIDKey = "requestID"

  /// Set before anything can arrive. A notification tapped from the cold-launch state is delivered
  /// as soon as the center has a delegate, so installing one later loses it.
  func becomeNotificationDelegate() {
    UNUserNotificationCenter.current().delegate = self
  }

  func receivedDeviceToken(_ deviceToken: Data) {
    Task { await session.registerDevice(tokenData: deviceToken) }
  }

  func failedToRegister(_ error: any Error) {
    NSLog("Remote notification registration failed: %@", error.localizedDescription)
  }

  // MARK: - What arrives

  /// Draws a notification that lands while the app is open.
  ///
  /// Without this, the system shows nothing at all for the app that is already frontmost — it
  /// assumes the app is showing the news itself. This one is not, so it asks for the banner.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    await heardAbout(notification)
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
    session.show(.inbox)
    await heardAbout(response.notification)
  }

  /// Tells the SDK the request a push is about changed, so a screen already showing it reads again
  /// and the inbox and its badge read the update.
  private func heardAbout(_ notification: UNNotification) async {
    if let requestID = notification.request.content.userInfo[Self.requestIDKey] as? String {
      await session.hub.heardThatARequestChanged(requestID: requestID)
    }
  }
}
