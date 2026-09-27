import SwiftUI
import DifferentRequests

/// The scene, and nothing else.
///
/// The composition root is ``RemoteNotificationDelegate``: the system builds it before any window is
/// shown, and a notification tapped from a cold launch is delivered to it before this scene exists.
/// So the client, the hub and the session are built there, and read from here.
///
/// The hub is what makes the SDK's screens keep their state. They are values SwiftUI throws away
/// and builds again on every redraw above them, so what they read from has to be older than they
/// are — which is why it is held for the life of the process rather than by a view.
@main
struct DifferentRequestsExampleApp: App {
  #if os(iOS)
  @UIApplicationDelegateAdaptor(RemoteNotificationDelegate.self) private var composition
  #else
  @NSApplicationDelegateAdaptor(RemoteNotificationDelegate.self) private var composition
  #endif

  var body: some Scene {
    WindowGroup {
      RootView(session: composition.session)
    }
  }
}
