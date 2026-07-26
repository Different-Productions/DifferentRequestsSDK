import SwiftUI

/// What a surface shows in place of content it could not read.
///
/// The failure itself is never rendered. The contract states that an `ApiError`'s message is
/// written for whoever is debugging, may name internals, and must not be shown to an end user —
/// so nothing here is derived from it. A reader gets copy written for them and a way to try
/// again; a developer gets the error off the store.
struct LoadFailure: View {

  /// What "Try Again" does.
  private let retry: () async -> Void

  init(retry: @escaping () async -> Void) {
    self.retry = retry
  }

  var body: some View {
    ContentUnavailableView {
      Label("Couldn't load", systemImage: "exclamationmark.triangle")
    } description: {
      Text("Something went wrong reaching the server. Check your connection and try again.")
    } actions: {
      AsyncButton {
        await retry()
      } label: {
        Text("Try Again")
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
