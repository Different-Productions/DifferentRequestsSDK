import SwiftUI

/// On macOS, Close at the sheet's top-leading corner with the tabs below it, inset from every edge.
///
/// A tab view in a Mac sheet draws none of its tabs' toolbars, so Close sits in the sheet's body
/// and the screens inside are told not to draw their own.
struct SheetCloseAbove: ViewModifier {

  func body(content: Content) -> some View {
    VStack(alignment: .leading, spacing: Spacing.medium.points()) {
      SheetCloseButton()
      content
        .environment(\.requestsSheet, RequestsSheetPresence(inside: true))
    }
    .padding(Spacing.large.points())
    // A Mac control's default size is 28 pt, which the system draws at the large control size.
    .controlSize(.large)
  }
}
