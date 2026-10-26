import SwiftUI

/// What stands in for a screen until the app's configuration has answered: an untinted spinner
/// while it is read, and "Requests couldn't load" with Try again when the read failed.
struct ConfigPending: View {

  let hub: DifferentRequestsHub

  var body: some View {
    switch hub.appConfig.badge {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
          await hub.appConfig.load()
        }
    case .failed(let error):
      LoadFailure(
        title: String(localized: "Requests couldn't load", bundle: .module, comment: "Heading when the Requests screen failed to load"),
        error: error
      ) {
        await hub.appConfig.load()
      }
    case .bought, .carried:
      EmptyView()
    }
  }
}
