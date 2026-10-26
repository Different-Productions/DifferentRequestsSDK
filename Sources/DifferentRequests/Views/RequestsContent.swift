import SwiftUI

/// What the Requests screen draws under its title: one of four outcomes, from the board's one read
/// state.
struct RequestsContent: View {

  /// What holds the board.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var isComposing: Bool

  var body: some View {
    switch hub.board.read {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(
        title: String(localized: "Requests couldn't load", bundle: .module, comment: "Heading when the Requests screen failed to load"),
        error: error
      ) {
        await hub.board.load()
      }
    case .empty:
      RequestsEmpty(hub: hub, isComposing: $isComposing)
    case .loaded, .refreshing:
      RequestsList(hub: hub)
    }
  }
}
