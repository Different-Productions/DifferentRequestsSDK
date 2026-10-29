import SwiftUI

/// Marks every inbox update read. Always shown, so the command never moves; unavailable while
/// nothing is unread or while that write is in flight. Sentence case on iOS, title case on macOS.
struct MarkAllReadButton: View {

  /// What holds the inbox the write changes.
  let hub: DifferentRequestsHub

  var body: some View {
    AsyncButton {
      await hub.inbox.markAllRead()
    } label: {
      #if os(macOS)
      Text("Mark All as Read", bundle: .module, comment: "Mac button that marks every inbox update read")
      #else
      Text("Mark all as read", bundle: .module, comment: "Button that marks every inbox update read")
      #endif
    }
    .tint(Color.primary)
    .disabled(hub.unreadCount() == 0 || hub.inbox.write.isWriting())
  }
}
