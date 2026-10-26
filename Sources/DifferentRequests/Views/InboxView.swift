import SwiftUI

/// What a reader has been told: status changes, replies, and duplicates on requests they follow.
///
/// ```swift
/// NavigationStack {
///   InboxView(hub: requests)
/// }
/// ```
///
/// An update is read by opening it, by its row's swipe action, or by Mark all as read. The unread
/// dot is a mark and takes no tap.
public struct InboxView: View {

  /// What the screen reads from, and what a push from a row is built against.
  private let hub: DifferentRequestsHub

  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
  }

  public var body: some View {
    InboxContent(hub: hub)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("Inbox", bundle: .module, comment: "Tab and title of the screen listing updates on requests"))
      .worn(by: hub)
      .sheetCloseButton()
      .sheetMinimumSize()
      .toolbar {
        if hub.inbox.unreadCount > 0 {
          ToolbarItem(placement: .primaryAction) {
            AsyncButton {
              await hub.inbox.markAllRead()
            } label: {
              Text("Mark all as read", bundle: .module, comment: "Button that marks every inbox update read")
            }
            .tint(Color.primary)
            .disabled(hub.inbox.write.isWriting)
          }
        }
      }
      .task {
        // Every appearance: an inbox is what changed while somebody was elsewhere, so coming back
        // to it is when it is out of date. A read already in flight is not started twice.
        await hub.appConfig.load()
        await hub.whoIsHere.read()
        if hub.whoIsHere.somebodyIsHere {
          await hub.inbox.load()
        }
      }
  }
}
