import SwiftUI

/// The Requests screen: what people asked for, ranked, with filter and sort, New request and the
/// close button in its bar. The root of a tab's own navigation stack.
///
/// New request is reachable from every state the board can be in, because a board full of other
/// people's requests is where someone finds out theirs is not on it. The form is pushed, never
/// presented, so only one sheet is ever up. When a request has been filed and the form has gone,
/// that request's own screen is pushed in its place.
struct RequestsScreen: View {

  /// What the screen reads from, and what its pushes are built against.
  let hub: DifferentRequestsHub

  /// Whether the new request form is pushed, and the request just filed while its own screen is.
  @State private var requestsScreen = RequestsScreenState()

  var body: some View {
    RequestsContent(hub: hub, requestsScreen: $requestsScreen)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("Requests", bundle: .module, comment: "Title of the request board"))
      #if os(macOS)
      .topRow(RequestsBar(hub: hub, requestsScreen: $requestsScreen))
      #else
      .toolbar {
        RequestsToolbar(hub: hub, requestsScreen: $requestsScreen)
      }
      #endif
      .sheetCloseButton()
      .task(id: hub.board.board.query) {
        await hub.board.search()
      }
      .task(id: hub.news.news) {
        await hub.board.readAgainIfNewer()
      }
      .navigationDestination(isPresented: $requestsScreen.composing) {
        SubmitRequestView(hub: hub)
      }
      .navigationDestination(item: openedRequestID()) { requestID in
        RequestDetailView(hub: hub, requestID: requestID)
      }
      .onChange(of: requestsScreen.composing) {
        if requestsScreen.composing == false, hub.submission.draft.hasSubmitted {
          requestsScreen.openedRequestID = hub.submission.draft.submitted.id
          hub.submission.putAwaySubmitted()
        }
      }
  }

  /// The pushed request's id, or none while no request is pushed: empty in the screen's state.
  private func openedRequestID() -> Binding<String?> {
    Binding {
      if requestsScreen.openedRequestID.isEmpty {
        return nil
      }
      return requestsScreen.openedRequestID
    } set: { requestID in
      if let requestID {
        requestsScreen.openedRequestID = requestID
      } else {
        requestsScreen.openedRequestID = ""
      }
    }
  }
}
