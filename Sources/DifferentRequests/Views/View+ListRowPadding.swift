import SwiftUI

extension View {

  /// The insets of a request or inbox row: 12 pt above and below on iOS, 8 pt on macOS, where a row
  /// is clicked rather than tapped and holds 13 pt text.
  func listRowPadding() -> some View {
    #if os(macOS)
    listRowInsets(
      EdgeInsets(
        top: Spacing.xSmall.points(),
        leading: Spacing.small.points(),
        bottom: Spacing.xSmall.points(),
        trailing: Spacing.small.points()
      )
    )
    #else
    listRowInsets(
      EdgeInsets(
        top: Spacing.small.points(),
        leading: Spacing.medium.points(),
        bottom: Spacing.small.points(),
        trailing: Spacing.medium.points()
      )
    )
    #endif
  }
}
