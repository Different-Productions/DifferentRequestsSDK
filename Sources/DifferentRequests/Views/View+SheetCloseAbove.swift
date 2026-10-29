import SwiftUI

extension View {

  /// Close above this view and a margin around both, for the Mac sheet.
  func sheetCloseAbove() -> some View {
    modifier(SheetCloseAbove())
  }
}
