import SwiftUI

extension View {

  /// The system close button in the toolbar when this screen is the first screen of a sheet;
  /// nothing when pushed.
  func sheetCloseButton() -> some View {
    modifier(SheetClose())
  }
}
