import SwiftUI

/// The frame behind `sheetMinimumSize()`: a floor on macOS for a screen that
/// sizes its own sheet, and none for a screen inside ``DifferentRequestsView`` or on iOS.
struct SheetMinimumFrame: ViewModifier {

  @Environment(\.requestsSheet) private var requestsSheet

  func body(content: Content) -> some View {
    #if os(macOS)
    if requestsSheet.inside {
      content
    } else {
      content
        .frame(minWidth: SheetMinimumSize.width.points(), minHeight: SheetMinimumSize.height.points())
    }
    #else
    content
    #endif
  }
}
