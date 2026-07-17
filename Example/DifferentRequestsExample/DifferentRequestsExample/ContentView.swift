import SwiftUI
import DifferentRequests

struct ContentView: View {
  // Paste your app's API key from the DifferentRequests console.
  // Do not commit a real key — keep it in a local, untracked file or build setting.
  @State private var client = DifferentRequestsClient(apiKey: "dr_YOUR_API_KEY")
  @State private var isReady = false

  var body: some View {
    if isReady {
      DifferentRequestsView(client: client)
    } else {
      ProgressView()
        .task {
          do {
            // Authenticate your user — use your app's real user ID and name
            let user = try await client.authenticate(
              externalUserId: "user-123",
              displayName: "Jane Appleseed",
              avatarUrl: nil,
              email: nil,
              traits: nil
            )
            print("Authenticated as \(user.displayName)")
            isReady = true
          } catch {
            print("Auth failed: \(error)")
          }
        }
    }
  }
}

#Preview {
  ContentView()
}
