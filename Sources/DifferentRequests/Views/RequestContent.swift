import SwiftUI

/// What a request's screen draws: one of four outcomes from the request's read status and the
/// answer it holds. Gone and unreachable are two of them, because a request the server says is not
/// there has nothing to try again for.
///
/// The request is drawn whenever one is held, reading or not, so a refresh keeps the screen that
/// runs it.
struct RequestContent: View {

  /// What holds who is signed in and the notification card.
  let hub: DifferentRequestsHub

  /// The request's own store.
  let store: RequestDetailStore

  var body: some View {
    if store.answer.hasRequest {
      RequestLoaded(hub: hub, store: store, request: store.answer.request)
    } else {
      switch store.status.state {
      case .none, .reading:
        ProgressView()
      case .failed(let trouble):
        LoadFailure(
          content: LoadFailureContent(
            title: String(localized: "This request couldn't load", bundle: .module, comment: "Heading when one request failed to load"),
            trouble: trouble
          )
        ) {
          await store.load()
        }
      case .loaded:
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
      }
    }
  }
}
