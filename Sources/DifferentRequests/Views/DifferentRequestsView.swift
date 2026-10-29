import SwiftUI

/// Everything the SDK draws, as tabs: Requests and Inbox always, Roadmap and What's New where the
/// app's plan includes them, with the system search button beside them.
///
/// Presented over the host app, reading from the hub the host built once:
///
/// ```swift
/// .sheet(isPresented: $isShowingRequests) {
///   DifferentRequestsView(hub: requests)
/// }
/// ```
///
/// Each tab brings its own `NavigationStack`, so do not put this inside one.
///
/// A tab exists only once the app's configuration says its plan includes the screen. An unread
/// configuration includes neither, so no tab appears and then goes away.
///
/// Search is the Requests list narrowed by what is typed. The text is cleared on leaving search, so
/// the Requests tab is always the whole board.
///
/// On macOS the sections are a segmented control on a box with Close above it, and search is a
/// field inside Requests, because a Mac sheet draws none of its tabs' toolbars.
public struct DifferentRequestsView: View {

  /// What every tab reads from.
  let hub: DifferentRequestsHub

  /// - Parameter hub: What the host app built once and holds. Every screen's state lives on it.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
  }

  public var body: some View {
    Group {
      #if os(macOS)
      SheetTabs(hub: hub)
        .sheetCloseAbove()
      #else
      RequestsTabView(hub: hub)
      #endif
    }
    .wornAsTabs(by: hub)
    .sheetMinimumSize()
    .task {
      await hub.appConfig.load()
      // The Inbox tab's badge is the hub's unread count, which the inbox reads with its first page.
      await hub.loadInbox()
    }
  }
}
