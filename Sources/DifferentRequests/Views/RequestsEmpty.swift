import SwiftUI

/// The Requests screen with nothing on it, which is four situations: no requests at all, a search
/// that found none, a status filter that left none, and both.
///
/// Only the board with nothing narrowing it is the host app's to word. The others describe what the
/// reader did, in the SDK's words.
struct RequestsEmpty: View {

  /// What holds the board, the host app's words, and who is signed in.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var requestsScreen: RequestsScreenState

  var body: some View {
    switch hub.board.narrowing() {
    case .nothing, .unspecified, .UNRECOGNIZED:
      ContentUnavailableView {
        Label(hub.emptyBoardDrawn().title, systemImage: hub.emptyBoardDrawn().symbol)
      } description: {
        Text(hub.emptyBoardDrawn().message)
      } actions: {
        if hub.whoIsHere.somebodyIsHere() {
          NewRequestButton(
            hub: hub,
            label: NewRequestButtonContent(title: hub.emptyBoardDrawn().button),
            requestsScreen: $requestsScreen
          )
          .labelStyle(.titleOnly)
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
        }
      }
    case .query, .statuses, .queryAndStatuses:
      ContentUnavailableView {
        Label(hub.board.narrowing().emptyTitle(), systemImage: hub.board.narrowing().emptyIcon())
      } description: {
        Text(hub.board.narrowing().emptyMessage())
      } actions: {
        NarrowedEmptyActions(hub: hub, requestsScreen: $requestsScreen)
      }
    }
  }
}
