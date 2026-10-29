import SwiftUI

/// A section's name in the Mac sheet's segmented control. The search tab is iOS's and has none.
struct ScreenTabTitle: View {

  let tab: ScreenTab

  var body: some View {
    switch tab {
    case .requests:
      Text("Requests", bundle: .module, comment: "Title of the request board")
    case .roadmap:
      Text("Roadmap", bundle: .module, comment: "Title of the roadmap screen")
    case .changelog:
      Text("What's New", bundle: .module, comment: "Tab and title of the app's release notes screen")
    case .inbox:
      Text("Inbox", bundle: .module, comment: "Tab and title of the screen listing updates on requests")
    case .search, .unspecified, .UNRECOGNIZED:
      EmptyView()
    }
  }
}
