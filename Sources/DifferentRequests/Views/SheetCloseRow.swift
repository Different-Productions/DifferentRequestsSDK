import SwiftUI

/// The Mac's Close at the leading edge of a row, drawn only where the screen is a sheet's first.
struct SheetCloseRow: View {

  /// Whether this screen is the first of a sheet that does not draw Close itself.
  let content: SheetCloseRowContent

  var body: some View {
    if content.shown {
      HStack {
        SheetCloseButton()
        Spacer()
      }
      .padding(Spacing.large.points())
    }
  }
}
