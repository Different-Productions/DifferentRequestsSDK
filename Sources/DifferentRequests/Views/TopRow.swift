import SwiftUI

/// A screen's row of buttons stacked above the screen, so the list under it starts below it.
///
/// A row laid over a list with `safeAreaInset` is counted twice by the list inside the Mac sheet,
/// which draws an empty band the row's height under it.
struct TopRow<Row: View>: ViewModifier {

  /// The buttons, already padded.
  let row: Row

  func body(content: Content) -> some View {
    VStack(spacing: 0) {
      row
      content
    }
  }
}
