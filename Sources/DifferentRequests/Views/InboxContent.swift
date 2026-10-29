import SwiftUI

/// What the Inbox draws under its title: one of four outcomes from the inbox's read status and the
/// notifications it holds, and the empty one for nobody signed in, whose inbox holds nothing.
///
/// The list is drawn whenever there are notifications, reading or not, so a refresh keeps the list
/// that runs it.
struct InboxContent: View {

  /// What holds the inbox and who is signed in.
  let hub: DifferentRequestsHub

  var body: some View {
    if hub.whoIsHere.somebodyIsHere() {
      if hub.inbox.inbox.notifications.isEmpty == false {
        InboxList(hub: hub)
      } else {
        switch hub.inbox.status.state {
        case .none, .reading:
          ProgressView()
        case .failed(let trouble):
          LoadFailure(
            content: LoadFailureContent(
              title: String(localized: "Inbox couldn't load", bundle: .module, comment: "Heading when the Inbox screen failed to load"),
              trouble: trouble
            )
          ) {
            await hub.inbox.load()
          }
        case .loaded:
          InboxEmpty()
        }
      }
    } else {
      InboxEmpty()
    }
  }
}
