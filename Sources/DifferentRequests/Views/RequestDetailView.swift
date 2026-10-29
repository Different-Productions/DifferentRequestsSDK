import SwiftUI

/// One request: what was asked for, where it sits, and what has been said about it.
///
/// Pushed from a list, or opened straight from a notification or a deep link:
///
/// ```swift
/// NavigationStack {
///   RequestDetailView(hub: requests, requestID: id)
/// }
/// ```
///
/// The bar carries no title: the request's own title is the heading. A duplicate answers here and
/// says where the vote went, and a request that has gone says so, which is a different screen from
/// one that could not be reached.
///
/// The screen owns its store as `@State`, so it keeps its thread, its place in it and the comment
/// being written while the list that pushed it redraws, and the store is freed when the screen is
/// popped.
public struct RequestDetailView: View {

  /// What the screen reads from, and what a push from here is built against.
  private let hub: DifferentRequestsHub

  /// This screen's own store, alive exactly as long as the screen is on the navigation stack.
  @State private var store: RequestDetailStore

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - requestID: Which request to show.
  public init(hub: DifferentRequestsHub, requestID: String) {
    self.hub = hub
    self._store = State(
      initialValue: RequestDetailStore(
        client: hub.client,
        detail: RequestDetailState(requestID: requestID),
        notificationOffer: hub.notificationOffer,
        firstVoteNote: hub.firstVoteNote
      )
    )
  }

  public var body: some View {
    RequestContent(hub: hub, store: store)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text(verbatim: ""))
      .backRow()
      .worn(by: hub)
      .sheetMinimumSize()
      // One request fills the sheet, so its comment field sits at the bottom edge.
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarVisibility(.hidden, for: .tabBar)
      #endif
      .onDisappear {
        hub.firstVoteNote.putAway()
      }
      .task(id: hub.news.lastHeard(aboutRequest: store.detail.requestID)) {
        await hub.whoIsHere.read()
        // Read when there is nothing, and again when this request changed after the copy here
        // arrived: on appearing, and the moment news about it lands while it is up.
        if store.hasRead() == false {
          await store.load()
        } else if hub.news.hasNews(about: store.detail) {
          await store.load()
        }
      }
  }
}
