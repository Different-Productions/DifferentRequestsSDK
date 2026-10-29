import SwiftUI

/// On macOS inside ``DifferentRequestsView``, no navigation bar, title strip or system Back above the
/// screen: its buttons, Back included, sit in its own row, and the segmented control names the
/// section.
struct SheetBarHidden: ViewModifier {

  @Environment(\.requestsSheet) private var requestsSheet

  func body(content: Content) -> some View {
    #if os(macOS)
    if requestsSheet.inside {
      content
        .navigationBarBackButtonHidden()
        .toolbar(removing: .title)
        .toolbarVisibility(.hidden, for: .windowToolbar, .automatic)
    } else {
      content
    }
    #else
    content
    #endif
  }
}
