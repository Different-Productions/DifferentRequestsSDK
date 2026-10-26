import SwiftUI

/// What a request's screen draws: one of four outcomes from the request's one read state. Gone and
/// unreachable are two of them, because a request the server says is not there has nothing to try
/// again for.
struct RequestContent: View {

  /// What holds who is signed in and the notification card.
  let hub: DifferentRequestsHub

  /// The request's own store.
  let store: RequestDetailStore

  var body: some View {
    switch store.read {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(
        title: String(localized: "This request couldn't load", bundle: .module, comment: "Heading when one request failed to load"),
        error: error
      ) {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label {
          Text("This request is gone", bundle: .module, comment: "Heading when a request no longer exists")
        } icon: {
          Image(systemName: "questionmark.folder")
        }
      } description: {
        Text(
          "It was removed, or the link that got you here is out of date.",
          bundle: .module,
          comment: "Message when a request no longer exists"
        )
      }
    case .loaded(let request), .refreshing(let request):
      RequestLoaded(hub: hub, store: store, request: request)
    }
  }
}
