import SwiftUI

/// An inbox with nothing in it, which is also what one belonging to nobody holds.
struct InboxEmpty: View {

  var body: some View {
    ContentUnavailableView {
      Label {
        Text("No updates yet", bundle: .module, comment: "Heading on an empty inbox")
      } icon: {
        Image(systemName: "tray")
      }
    } description: {
      Text(
        "Vote for or follow a request, and you'll get updates here when it changes.",
        bundle: .module,
        comment: "Message on an empty inbox"
      )
    }
  }
}
