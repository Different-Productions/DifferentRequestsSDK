import SwiftUI
import DifferentRequests

@main
struct DifferentRequestsExampleApp: App {
  @UIApplicationDelegateAdaptor(PushRegistrationDelegate.self) private var pushDelegate
  /// Built through the factory rather than an initializer that constructs its own dependencies, so
  /// the URLSession and its timeouts are the SDK's stated defaults rather than this app's guess.
  @State private var session = Session(client: .make(appKey: DemoConfig.appKey))

  var body: some Scene {
    WindowGroup {
      RootView(session: session, pushDelegate: pushDelegate)
    }
  }
}
