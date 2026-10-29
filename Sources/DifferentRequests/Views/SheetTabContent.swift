import SwiftUI

/// The screen for one section of the Mac sheet, in its own navigation stack.
struct SheetTabContent: View {

  /// What every screen reads from.
  let hub: DifferentRequestsHub

  /// The section being shown.
  let tab: ScreenTab

  var body: some View {
    switch tab {
    case .requests:
      NavigationStack {
        RequestsScreen(hub: hub)
          .sheetBarHidden()
      }
    case .roadmap:
      NavigationStack {
        RoadmapView(hub: hub)
          .sheetBarHidden()
      }
    case .changelog:
      NavigationStack {
        ChangelogView(hub: hub)
          .sheetBarHidden()
      }
    case .inbox:
      NavigationStack {
        InboxView(hub: hub)
          .sheetBarHidden()
      }
    case .search, .unspecified, .UNRECOGNIZED:
      EmptyView()
    }
  }
}
