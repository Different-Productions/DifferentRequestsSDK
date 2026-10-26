import SwiftUI

/// What the Inbox draws under its title: one of four outcomes from the inbox's one read state, and
/// the empty one for nobody signed in, whose inbox holds nothing.
struct InboxContent: View {

  /// What holds the inbox and who is signed in.
  let hub: DifferentRequestsHub

  var body: some View {
    if hub.whoIsHere.somebodyIsHere {
      switch hub.inbox.read {
      case .unread, .reading:
        ProgressView()
      case .failed(let error):
        LoadFailure(
          title: String(localized: "Inbox couldn't load", bundle: .module, comment: "Heading when the Inbox screen failed to load"),
          error: error
        ) {
          await hub.inbox.load()
        }
      case .empty:
        InboxEmpty()
      case .loaded, .refreshing:
        InboxList(hub: hub)
      }
    } else {
      InboxEmpty()
    }
  }
}
