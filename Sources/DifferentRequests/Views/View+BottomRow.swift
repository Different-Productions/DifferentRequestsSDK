import SwiftUI

extension View {

  /// `row` stacked under this screen.
  func bottomRow<Row: View>(_ row: Row) -> some View {
    modifier(BottomRow(row: row))
  }
}
