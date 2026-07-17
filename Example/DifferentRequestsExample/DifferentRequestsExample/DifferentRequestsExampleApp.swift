import SwiftUI
import DifferentRequests

@main
struct DifferentRequestsExampleApp: App {
  @UIApplicationDelegateAdaptor(PushRegistrationDelegate.self) private var pushDelegate
  @State private var session = Session(client: DifferentRequestsClient(apiKey: DemoConfig.apiKey))

  var body: some Scene {
    WindowGroup {
      RootView(session: session, pushDelegate: pushDelegate)
    }
  }
}
