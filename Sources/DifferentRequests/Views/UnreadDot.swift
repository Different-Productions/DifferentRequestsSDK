import SwiftUI

/// The mark at the leading end of an inbox row: a dot in the tint on an unread update, and the same
/// width left empty on a read one, so every row's text starts on one edge. A mark, never a button.
struct UnreadDot: View {

  /// Whether the update has not been read.
  let isUnread: Bool

  var body: some View {
    if isUnread {
      Image(systemName: "circle.fill")
        .imageScale(.small)
        .textRole(.meta)
        .foregroundStyle(ColorRole.tint)
        .accessibilityHidden(true)
    } else {
      Image(systemName: "circle.fill")
        .imageScale(.small)
        .textRole(.meta)
        .hidden()
    }
  }
}
