import SwiftUI

extension View {

  /// `row` stacked above this screen.
  func topRow<Row: View>(_ row: Row) -> some View {
    modifier(TopRow(row: row))
  }
}
