import SwiftUI
import DifferentRequests

/// The app's composition root: the client, the SDK's hub, and this app's own session, each built
/// exactly once here and in that order. Nothing further down builds any of them.
///
/// The hub is what makes the SDK's screens keep their state. They are values SwiftUI throws away
/// and builds again on every redraw above them, so what they read from has to be older than they
/// are — held here, for as long as the app runs.
///
/// The client comes from the factory rather than from an initializer that constructs its own
/// dependencies, so the URLSession and its timeouts are the SDK's stated defaults rather than this
/// app's guess.
@main
struct DifferentRequestsExampleApp: App {
  @UIApplicationDelegateAdaptor(PushRegistrationDelegate.self) private var pushDelegate

  private let session = Session(hub: DifferentRequestsHub(client: .make(appKey: DemoConfig.appKey)))

  var body: some Scene {
    WindowGroup {
      RootView(session: session, pushDelegate: pushDelegate)
    }
  }
}
