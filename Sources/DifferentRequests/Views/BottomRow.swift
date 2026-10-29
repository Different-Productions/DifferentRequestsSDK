import SwiftUI

/// A row stacked under a screen, so the list above it ends at it rather than scrolling beneath it.
struct BottomRow<Row: View>: ViewModifier {

  /// The row, already padded.
  let row: Row

  func body(content: Content) -> some View {
    VStack(spacing: 0) {
      content
      row
    }
  }
}
