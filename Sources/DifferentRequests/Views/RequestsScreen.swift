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

  /// Whether the new request form is pushed.
  @State private var isComposing = false

  /// The request just filed, while its own screen is pushed.
  @State private var openedRequestID: String?

  var body: some View {
    RequestsContent(hub: hub, isComposing: $isComposing)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("Requests", bundle: .module, comment: "Title of the request board"))
      .toolbar {
        RequestsToolbar(hub: hub, isComposing: $isComposing)
      }
      .sheetCloseButton()
      .task(id: hub.board.query) {
        await hub.board.search()
      }
      .navigationDestination(isPresented: $isComposing) {
        SubmitRequestView(hub: hub)
      }
      .navigationDestination(item: $openedRequestID) { requestID in
        RequestDetailView(hub: hub, requestID: requestID)
      }
      .onChange(of: isComposing) {
        if isComposing == false, let filed = hub.submission.submitted {
          openedRequestID = filed.id
          hub.submission.putAwaySubmitted()
        }
      }
  }
}
