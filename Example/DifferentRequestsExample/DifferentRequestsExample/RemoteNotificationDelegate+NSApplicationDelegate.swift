#if os(macOS)
import AppKit

extension RemoteNotificationDelegate: NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    becomeNotificationDelegate()
  }

  func application(
    _ application: NSApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    receivedDeviceToken(deviceToken)
  }

  func application(
    _ application: NSApplication,
    didFailToRegisterForRemoteNotificationsWithError error: any Error
  ) {
    failedToRegister(error)
  }
}
#endif
