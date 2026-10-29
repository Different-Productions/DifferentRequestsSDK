import DifferentRequestsProtos
import SwiftUI

/// The mark at the leading end of an inbox row: a dot in the tint on an unread update, and the same
/// width left empty on a read one, so every row's text starts on one edge. A mark, never a button.
struct UnreadDot: View {

  /// The update, unread until it carries a read stamp.
  let notification: DRNotification

  var body: some View {
    if notification.hasReadAt {
      Image(systemName: "circle.fill")
        .imageScale(.small)
        .textRole(.meta)
        .hidden()
    } else {
      Image(systemName: "circle.fill")
        .imageScale(.small)
        .textRole(.meta)
        .foregroundStyle(ColorRole.tint)
        .accessibilityHidden(true)
    }
  }
}
