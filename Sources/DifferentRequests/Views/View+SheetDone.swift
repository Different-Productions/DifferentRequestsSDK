import SwiftUI

extension View {

  /// Done in the toolbar when this screen is the first screen of a sheet; nothing when pushed.
  func sheetDoneButton() -> some View {
    modifier(SheetDone())
  }
}
