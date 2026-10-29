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
      #if os(macOS)
      .topRow(
        HStack {
          Spacer()
          MarkAllReadButton(hub: hub)
        }
        .padding(Spacing.small.points())
      )
      #else
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          MarkAllReadButton(hub: hub)
        }
      }
      #endif
      .worn(by: hub)
      .sheetCloseButton()
      .sheetMinimumSize()
      .task {
        // Every appearance: an inbox is what changed while somebody was elsewhere, so coming back
        // to it is when it is out of date. A read in flight reads again when it lands instead.
        await hub.appConfig.load()
        await hub.loadInbox()
      }
  }
}
