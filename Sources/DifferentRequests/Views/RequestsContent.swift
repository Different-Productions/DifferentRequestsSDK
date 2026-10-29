import SwiftUI

/// What the Requests screen draws under its title: one of four outcomes, from the board's read
/// status and the requests it holds.
///
/// The list is drawn whenever there are requests, reading or not, so a refresh keeps the list that
/// runs it.
struct RequestsContent: View {

  /// What holds the board.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var requestsScreen: RequestsScreenState

  var body: some View {
    if hub.board.board.requests.isEmpty == false {
      RequestsList(hub: hub)
    } else {
      switch hub.board.status.state {
      case .none, .reading:
        ProgressView()
      case .failed(let trouble):
        LoadFailure(
          content: LoadFailureContent(
            title: String(localized: "Requests couldn't load", bundle: .module, comment: "Heading when the Requests screen failed to load"),
            trouble: trouble
          )
        ) {
          await hub.board.load()
        }
      case .loaded:
        RequestsEmpty(hub: hub, requestsScreen: $requestsScreen)
      }
    }
  }
}
